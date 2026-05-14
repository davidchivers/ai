from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import CHECKPOINTS, INPUT_SUMMARY, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_stock import (
    build_scenarios,
    extract_metrics,
    update_population,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_snapshot_state_transition_permits_starts_stock_calibrated"
T = 21
CAL_WINDOW = range(1, 6)
ACTIVE_CHECKPOINTS = [t for t in CHECKPOINTS if t <= T - 1]
SEARCH_PATH = BUILD / f"{OUTPUT_STEM}_search.csv"
STATIONARY_BENCHMARK_TIMING_SEARCH_PATH = BUILD / "annual_stationary_benchmark_timing_calibration_search.csv"

# Census-facing targets:
# - Starts were 6.8% less than permits in 2022 => starts / permits = 0.932
# - Completions were 10.5% less than starts in 2022 => completions / starts = 0.895
# - Census housing-unit methodology assumes a six-month lag from permit issue to completion
STARTS_PERMITS_TARGET = 0.932
COMPLETIONS_STARTS_TARGET = 0.895
PERMIT_TO_COMPLETION_LAG_YEARS = 0.50


@dataclass(frozen=True)
class StartsStockParams:
    theta0: float = 0.18
    theta_old: float = 0.55
    theta_young: float = 0.35
    permit_ss: float = 0.020
    permit_floor: float = 0.004
    permit_inertia: float = 0.60
    permit_gap_gain: float = 0.055
    permit_theta_gain: float = 0.030
    permit_price_gain: float = 0.012
    stock_delta: float = 0.020
    price_gap_gain: float = 0.30
    price_damping: float = 0.35
    q_min: float = 0.40
    q_max: float = 5.00
    demand_young_gain: float = 0.10
    demand_crunch_gain: float = 0.00
    demand_mid_owner_gain: float = 0.00
    start_hazard: float = 0.70
    completion_hazard: float = 0.70
    permit_inventory_years: float = 0.50
    uc_inventory_years: float = 1.00


def params_from_search_row(row: pd.Series) -> StartsStockParams:
    return StartsStockParams(
        start_hazard=float(row["start_hazard"]),
        completion_hazard=float(row["completion_hazard"]),
        permit_inventory_years=float(row["permit_inventory_years"]),
        uc_inventory_years=float(row["uc_inventory_years"]),
    )


def calibration_search_path(context: str | None = None) -> Path:
    if context in (None, "", "baseline_d05_stock"):
        return SEARCH_PATH
    if context == "stationary_benchmark_timing":
        return STATIONARY_BENCHMARK_TIMING_SEARCH_PATH
    raise ValueError(f"Unknown calibration context: {context}")


def resolve_calibrated_params(summary: pd.DataFrame | None = None, context: str | None = None) -> StartsStockParams:
    search_path = calibration_search_path(context)
    if search_path.exists():
        table = pd.read_csv(search_path)
        if table.empty:
            raise ValueError(f"Calibration search table is empty: {search_path}")
        if "selected" in table.columns and table["selected"].astype(bool).any():
            return params_from_search_row(table.loc[table["selected"].astype(bool)].iloc[0])
        return params_from_search_row(table.sort_values("loss").iloc[0])

    if summary is None:
        raise FileNotFoundError(
            f"Missing calibration search table {search_path} and no summary was provided to re-run calibration."
        )

    if context not in (None, "", "baseline_d05_stock"):
        raise FileNotFoundError(
            f"Missing calibration search table {search_path} for context '{context}'. Rebuild that context-specific calibration first."
        )

    params, _ = calibrate(summary)
    return params


def demand_index(metrics: dict[str, float], refs: dict[str, float], drift_ratio: float, t: int, params: StartsStockParams) -> float:
    demand_trend = drift_ratio**t
    demand_component = (
        1.0
        + params.demand_young_gain * (metrics["young_mass_share"] - refs["young_mass_share"])
        + params.demand_crunch_gain * (metrics["young_crunch_25_34"] - refs["young_crunch_25_34"])
        + params.demand_mid_owner_gain * (metrics["owner_35_44"] - refs["owner_35_44"])
    )
    return max(0.25, demand_trend * demand_component)


def theta_from_metrics(metrics: dict[str, float], params: StartsStockParams) -> float:
    theta_raw = params.theta0 + params.theta_old * metrics["old_owner_share"] - params.theta_young * metrics["young_owner_25_34"]
    return float(np.clip(theta_raw, 0.0, 0.95))


def permit_update(permits_t: float, theta_t: float, demand_t: float, stock_t: float, q_effective: float, params: StartsStockParams) -> float:
    permit_target = (
        params.permit_ss
        + params.permit_gap_gain * (demand_t - stock_t)
        - params.permit_theta_gain * (theta_t - params.theta0)
        + params.permit_price_gain * np.log(max(q_effective, 1.0e-6))
    )
    return max(params.permit_floor, params.permit_inertia * permits_t + (1.0 - params.permit_inertia) * permit_target)


def implied_q_next(q_current: float, demand_t: float, stock_next: float, params: StartsStockParams) -> float:
    return float(
        np.clip(
            np.exp(np.log(max(q_current, 1.0e-6)) + params.price_damping * params.price_gap_gain * (demand_t - stock_next)),
            params.q_min,
            params.q_max,
        )
    )


def initialize_inventories(params: StartsStockParams) -> tuple[float, float]:
    permit_inventory = params.permit_inventory_years * params.permit_ss
    uc_inventory = params.uc_inventory_years * params.permit_ss
    return permit_inventory, uc_inventory


def simulate(summary: pd.DataFrame, scenario, params: StartsStockParams, T: int) -> pd.DataFrame:
    pop = summary.loc[:, ["renter_no_debt", "renter_with_debt", "owner_with_mortgage", "owner_outright"]].to_numpy(dtype=float)
    pop = pop * summary["block_mass"].to_numpy(dtype=float)[:, None]
    refs = extract_metrics(pop)

    q = np.zeros(T + 1, dtype=float)
    q[0] = 1.0
    permits = np.zeros(T + 1, dtype=float)
    starts = np.zeros(T + 1, dtype=float)
    completions = np.zeros(T + 1, dtype=float)
    stock = np.zeros(T + 1, dtype=float)
    theta = np.zeros(T, dtype=float)
    demand = np.zeros(T, dtype=float)
    permit_inventory = np.zeros(T + 1, dtype=float)
    uc_inventory = np.zeros(T + 1, dtype=float)

    stock[0] = 1.0
    permits[0] = params.permit_ss
    permit_inventory[0], uc_inventory[0] = initialize_inventories(params)
    starts[0] = min(permit_inventory[0], params.start_hazard * permit_inventory[0])
    completions[0] = min(uc_inventory[0], params.completion_hazard * uc_inventory[0])

    records: list[dict[str, float | int | str]] = []
    for t in range(T):
        metrics = extract_metrics(pop)
        theta[t] = theta_from_metrics(metrics, params)
        demand[t] = demand_index(metrics, refs, scenario.price_ratio, t, params)

        records.append(
            {
                "scenario": scenario.name,
                "t": t,
                "q": float(q[t]),
                "theta": float(theta[t]),
                "permits": float(permits[t]),
                "starts": float(starts[t]),
                "completions": float(completions[t]),
                "permit_inventory": float(permit_inventory[t]),
                "uc_inventory": float(uc_inventory[t]),
                "stock": float(stock[t]),
                "starts_permits_ratio": float(starts[t] / max(permits[t], 1.0e-9)),
                "completions_starts_ratio": float(completions[t] / max(starts[t], 1.0e-9)),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
                "mortgaged_owner_35_44": metrics["mortgage_35_44"],
            }
        )

        permits[t + 1] = permit_update(permits[t], theta[t], demand[t], stock[t], q[t], params)

        available_authorized = permit_inventory[t] + permits[t + 1]
        starts[t + 1] = min(available_authorized, params.start_hazard * available_authorized)
        permit_inventory[t + 1] = max(0.0, available_authorized - starts[t + 1])

        available_uc = uc_inventory[t] + starts[t + 1]
        completions[t + 1] = min(available_uc, params.completion_hazard * available_uc)
        uc_inventory[t + 1] = max(0.0, available_uc - completions[t + 1])

        stock[t + 1] = max(0.50, (1.0 - params.stock_delta) * stock[t] + completions[t + 1])
        q[t + 1] = implied_q_next(q[t], demand[t], stock[t + 1], params)
        pop = update_population(summary, pop, scenario, q[t], t)

    return pd.DataFrame.from_records(records)


def calibration_loss(frame: pd.DataFrame, params: StartsStockParams) -> float:
    sub = frame.loc[frame["t"].isin(CAL_WINDOW)]
    starts_permits = float(sub["starts_permits_ratio"].mean())
    completions_starts = float(sub["completions_starts_ratio"].mean())
    permit_inventory_years = float((sub["permit_inventory"] / sub["permits"].replace(0.0, np.nan)).mean())
    lag_penalty = (permit_inventory_years - PERMIT_TO_COMPLETION_LAG_YEARS) ** 2
    return (
        (starts_permits - STARTS_PERMITS_TARGET) ** 2
        + (completions_starts - COMPLETIONS_STARTS_TARGET) ** 2
        + 0.25 * lag_penalty
    )


def calibrate(summary: pd.DataFrame) -> tuple[StartsStockParams, pd.DataFrame]:
    base_scenario = build_scenarios()[0]
    candidates: list[dict[str, float]] = []
    for start_hazard in np.arange(0.45, 0.96, 0.05):
        for completion_hazard in np.arange(0.35, 0.96, 0.05):
            for permit_inventory_years in np.arange(0.25, 1.01, 0.05):
                for uc_inventory_years in np.arange(0.50, 1.76, 0.10):
                    params = StartsStockParams(
                        start_hazard=float(start_hazard),
                        completion_hazard=float(completion_hazard),
                        permit_inventory_years=float(permit_inventory_years),
                        uc_inventory_years=float(uc_inventory_years),
                    )
                    frame = simulate(summary, base_scenario, params, T=8)
                    loss = calibration_loss(frame, params)
                    sub = frame.loc[frame["t"].isin(CAL_WINDOW)]
                    candidates.append(
                        {
                            "start_hazard": float(start_hazard),
                            "completion_hazard": float(completion_hazard),
                            "permit_inventory_years": float(permit_inventory_years),
                            "uc_inventory_years": float(uc_inventory_years),
                            "avg_starts_permits_ratio_t1_t5": float(sub["starts_permits_ratio"].mean()),
                            "avg_completions_starts_ratio_t1_t5": float(sub["completions_starts_ratio"].mean()),
                            "avg_permit_inventory_years_t1_t5": float((sub["permit_inventory"] / sub["permits"].replace(0.0, np.nan)).mean()),
                            "loss": float(loss),
                        }
                    )

    table = pd.DataFrame(candidates).sort_values("loss").reset_index(drop=True)
    best = table.iloc[0]
    params = StartsStockParams(
        start_hazard=float(best["start_hazard"]),
        completion_hazard=float(best["completion_hazard"]),
        permit_inventory_years=float(best["permit_inventory_years"]),
        uc_inventory_years=float(best["uc_inventory_years"]),
    )
    return params, table


def summarize_against_baseline(frames: list[pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame]:
    combined = pd.concat(frames, ignore_index=True)
    baseline = combined.loc[combined["scenario"] == "baseline_d05_stock_data"].set_index("t")
    rows: list[dict[str, float | int | str]] = []
    peaks: list[dict[str, float | int | str]] = []

    for scenario_name in combined["scenario"].drop_duplicates():
        frame = combined.loc[combined["scenario"] == scenario_name].set_index("t")
        for t in ACTIVE_CHECKPOINTS:
            f = frame.loc[t]
            b = baseline.loc[t]
            rows.append(
                {
                    "scenario": scenario_name,
                    "t": int(t),
                    "q": float(f["q"]),
                    "permits": float(f["permits"]),
                    "starts": float(f["starts"]),
                    "completions": float(f["completions"]),
                    "stock": float(f["stock"]),
                    "starts_permits_ratio": float(f["starts_permits_ratio"]),
                    "completions_starts_ratio": float(f["completions_starts_ratio"]),
                    "young_owner_25_34": float(f["young_owner_25_34"]),
                    "young_mortgaged_owner_25_34": float(f["young_mortgaged_owner_25_34"]),
                    "q_gap_vs_baseline": float(f["q"] - b["q"]),
                    "young_mortgage_gap_vs_baseline": float(
                        f["young_mortgaged_owner_25_34"] - b["young_mortgaged_owner_25_34"]
                    ),
                }
            )
        if scenario_name != "baseline_d05_stock_data":
            aligned = frame.join(
                baseline[["q", "young_mortgaged_owner_25_34"]],
                rsuffix="_baseline",
            )
            aligned["young_mortgage_gap"] = (
                aligned["young_mortgaged_owner_25_34"] - aligned["young_mortgaged_owner_25_34_baseline"]
            )
            peak_t = int(aligned["young_mortgage_gap"].idxmax())
            peaks.append(
                {
                    "scenario": scenario_name,
                    "peak_t_young_mortgage_gap": peak_t,
                    "peak_young_mortgage_gap": float(aligned.loc[peak_t, "young_mortgage_gap"]),
                    "young_mortgage_gap_t5": float(aligned.loc[5, "young_mortgage_gap"]),
                    "young_mortgage_gap_t20": float(aligned.loc[20, "young_mortgage_gap"]),
                    "q_gap_t20": float(aligned.loc[20, "q"] - aligned.loc[20, "q_baseline"]),
                }
            )

    return (
        pd.DataFrame(rows).sort_values(["scenario", "t"]).reset_index(drop=True),
        pd.DataFrame(peaks),
    )


def rename_scenario(scenario_name: str) -> str:
    return {
        "baseline_d05_stock": "baseline_d05_stock_data",
        "benchmark_d05_stock": "benchmark_d05_stock_data",
        "robustness_d05_stock": "robustness_d05_stock_data",
    }[scenario_name]


def write_note(path: Path, params: StartsStockParams, calibration_table: pd.DataFrame, summary: pd.DataFrame, peaks: pd.DataFrame) -> None:
    best = calibration_table.iloc[0]
    lines = [
        "# Annual permits-starts-stock block: data calibration",
        "",
        "This note replaces the earlier stylized permits/backlog/stock block with a more data-facing annual construction block that tracks:",
        "",
        "- permits",
        "- units authorized but not yet started",
        "- starts",
        "- units under construction",
        "- completions",
        "- housing stock",
        "",
        "## Official calibration targets",
        "",
        "- Census New Residential Construction relationships note for 2022:",
        f"  - starts / permits target: `{STARTS_PERMITS_TARGET:.3f}`",
        f"  - completions / starts target: `{COMPLETIONS_STARTS_TARGET:.3f}`",
        "- Census housing-unit methodology:",
        f"  - permit-to-completion lag anchor: `{PERMIT_TO_COMPLETION_LAG_YEARS:.2f}` years",
        "- sources:",
        "  - Census NRC relationships note",
        "  - Census housing-unit methodology note",
        "",
        "## Calibrated construction parameters",
        "",
        f"- start hazard: `{params.start_hazard:.2f}`",
        f"- completion hazard: `{params.completion_hazard:.2f}`",
        f"- initial authorized-not-started inventory (years of permit flow): `{params.permit_inventory_years:.2f}`",
        f"- initial under-construction inventory (years of permit flow): `{params.uc_inventory_years:.2f}`",
        "",
        "Best-fit target match over `t = 1-5`:",
        "",
        f"- starts / permits: `{best['avg_starts_permits_ratio_t1_t5']:.3f}`",
        f"- completions / starts: `{best['avg_completions_starts_ratio_t1_t5']:.3f}`",
        f"- permit-inventory years: `{best['avg_permit_inventory_years_t1_t5']:.3f}`",
        "",
        "## Scenario checkpoints",
        "",
        "| Scenario | t | q | Permits | Starts | Completions | Stock | Starts / permits | Completions / starts | Young mortgaged-owner 25-34 | Young mortgage gap vs baseline |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in summary.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | {row.q:.3f} | {row.permits:.3f} | {row.starts:.3f} | {row.completions:.3f} | {row.stock:.3f} | "
            f"{row.starts_permits_ratio:.3f} | {row.completions_starts_ratio:.3f} | {row.young_mortgaged_owner_25_34:.3f} | {row.young_mortgage_gap_vs_baseline:.3f} |"
        )
    lines.extend(
        [
            "",
            "## Peak support effects",
            "",
            "| Scenario | Peak t | Peak young mortgage gap | Young mortgage gap t=5 | Young mortgage gap t=20 | q gap t=20 |",
            "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for row in peaks.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.peak_t_young_mortgage_gap} | {row.peak_young_mortgage_gap:.3f} | {row.young_mortgage_gap_t5:.3f} | {row.young_mortgage_gap_t20:.3f} | {row.q_gap_t20:.3f} |"
        )
    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is more data-facing than the earlier stylized permits/backlog/stock bridge because it explicitly tracks starts and under-construction inventory.",
            "- The calibrated block is disciplined by official Census flow relationships rather than only by qualitative timing intuition.",
            "- If this block also preserves the annual ownership mechanism while keeping construction ratios in the right region, it is the better base for any future annual RE work.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")
    summary = load_initial_cross_section(INPUT_SUMMARY)
    params, calibration_table = calibrate(summary)

    scenarios = build_scenarios()
    renamed_frames: list[pd.DataFrame] = []
    for scenario in scenarios:
        frame = simulate(summary, scenario, params, T=T)
        frame["scenario"] = rename_scenario(scenario.name)
        renamed_frames.append(frame)

    combined = pd.concat(renamed_frames, ignore_index=True)
    combined.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    calibration_table.to_csv(BUILD / f"{OUTPUT_STEM}_search.csv", index=False)
    summary_table, peaks = summarize_against_baseline(renamed_frames)
    summary_table.to_csv(BUILD / f"{OUTPUT_STEM}_summary.csv", index=False)
    peaks.to_csv(BUILD / f"{OUTPUT_STEM}_peaks.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", params, calibration_table, summary_table, peaks)


if __name__ == "__main__":
    main()
