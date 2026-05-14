from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import (
    CHECKPOINTS,
    INPUT_SUMMARY,
    Scenario,
    adjust_matrix,
    load_initial_cross_section,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_snapshot_state_transition_permits_stock"
T = 80

STATE_ORDER = (
    "renter_no_debt",
    "renter_with_debt",
    "owner_with_mortgage",
    "owner_outright",
)


@dataclass(frozen=True)
class SupplyStockParams:
    theta0: float = 0.18
    theta_old: float = 0.55
    theta_young: float = 0.35
    permit_ss: float = 0.020
    permit_floor: float = 0.004
    permit_inertia: float = 0.60
    permit_gap_gain: float = 0.055
    permit_theta_gain: float = 0.030
    permit_price_gain: float = 0.012
    completion_hazard: float = 0.28
    stock_delta: float = 0.020
    price_gap_gain: float = 0.30
    price_damping: float = 0.35
    q_min: float = 0.40
    q_max: float = 5.00
    demand_young_gain: float = 0.10
    demand_crunch_gain: float = 0.00
    demand_mid_owner_gain: float = 0.00


def build_scenarios() -> list[Scenario]:
    return [
        Scenario("baseline_d05_stock", 1.05, 0.0, 0.0, 0, 0, False),
        Scenario(
            "benchmark_d05_stock",
            1.05,
            0.15,
            0.25,
            0,
            0,
            True,
            support_center=0.18,
            support_width=0.04,
            mid_age_scale=0.80,
        ),
        Scenario(
            "robustness_d05_stock",
            1.05,
            0.30,
            0.40,
            0,
            0,
            True,
            support_center=0.18,
            support_width=0.04,
            mid_age_scale=0.80,
        ),
    ]


def extract_metrics(pop: np.ndarray) -> dict[str, float]:
    block_mass = pop.sum(axis=1)
    total = float(block_mass.sum())
    if total <= 0.0:
        raise ValueError("Population mass vanished in permits-stock transition simulation.")

    young_owner_25_34 = float((pop[0, 2] + pop[0, 3]) / max(block_mass[0], 1.0e-9))
    young_mortgage_25_34 = float(pop[0, 2] / max(block_mass[0], 1.0e-9))
    young_crunch_25_34 = float((pop[0, 1] + pop[0, 2]) / max(block_mass[0], 1.0e-9))
    owner_35_44 = float((pop[1, 2] + pop[1, 3]) / max(block_mass[1], 1.0e-9))
    mortgage_35_44 = float(pop[1, 2] / max(block_mass[1], 1.0e-9))
    old_owner_share = float((pop[2:, 2] + pop[2:, 3]).sum() / max(block_mass[2:].sum(), 1.0e-9))
    young_mass_share = float((block_mass[0] + block_mass[1]) / total)
    aggregate_owner_share = float((pop[:, 2] + pop[:, 3]).sum() / total)
    aggregate_mortgaged_owner_share = float(pop[:, 2].sum() / total)
    return {
        "total_mass": total,
        "young_owner_25_34": young_owner_25_34,
        "young_mortgage_25_34": young_mortgage_25_34,
        "young_crunch_25_34": young_crunch_25_34,
        "owner_35_44": owner_35_44,
        "mortgage_35_44": mortgage_35_44,
        "old_owner_share": old_owner_share,
        "young_mass_share": young_mass_share,
        "aggregate_owner_share": aggregate_owner_share,
        "aggregate_mortgaged_owner_share": aggregate_mortgaged_owner_share,
    }


def update_population(
    summary: pd.DataFrame,
    pop: np.ndarray,
    scenario: Scenario,
    q_t: float,
    t: int,
) -> np.ndarray:
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    entrant_mix = summary.loc[summary["age_block"] == "25-34", STATE_ORDER].iloc[0].to_numpy(dtype=float)

    base_matrices = {
        "25-34": np.array(
            [[0.84, 0.07, 0.08, 0.01], [0.05, 0.78, 0.15, 0.02], [0.01, 0.03, 0.87, 0.09], [0.00, 0.00, 0.01, 0.99]],
            dtype=float,
        ),
        "35-44": np.array(
            [[0.86, 0.04, 0.08, 0.02], [0.05, 0.77, 0.14, 0.04], [0.01, 0.02, 0.80, 0.17], [0.00, 0.00, 0.01, 0.99]],
            dtype=float,
        ),
        "45-54": np.array(
            [[0.89, 0.03, 0.06, 0.02], [0.05, 0.81, 0.10, 0.04], [0.01, 0.01, 0.72, 0.26], [0.00, 0.00, 0.005, 0.995]],
            dtype=float,
        ),
        "55-64": np.array(
            [[0.91, 0.02, 0.04, 0.03], [0.05, 0.84, 0.07, 0.04], [0.01, 0.01, 0.64, 0.34], [0.00, 0.00, 0.003, 0.997]],
            dtype=float,
        ),
        "65-80": np.array(
            [[0.93, 0.02, 0.02, 0.03], [0.04, 0.86, 0.05, 0.05], [0.00, 0.01, 0.58, 0.41], [0.00, 0.00, 0.002, 0.998]],
            dtype=float,
        ),
    }

    post = np.zeros_like(pop)
    for i, age_block in enumerate(age_blocks):
        matrix = adjust_matrix(
            base_matrices[age_block],
            age_block=age_block,
            price_ratio=q_t,
            deposit_help_weight=scenario.deposit_help_weight,
            qualification_weight=scenario.qualification_weight,
            deposit_help_horizon=scenario.deposit_help_horizon,
            qualification_horizon=scenario.qualification_horizon,
            targeted_support=scenario.targeted_support,
            support_center=scenario.support_center,
            support_width=scenario.support_width,
            mid_age_scale=scenario.mid_age_scale,
            t=t,
        )
        post[i, :] = pop[i, :] @ matrix

    new_pop = np.zeros_like(pop)
    outflows = np.zeros_like(pop)
    for i in range(len(age_blocks)):
        outflows[i, :] = post[i, :] / widths[i]
        new_pop[i, :] += post[i, :] - outflows[i, :]

    for i in range(1, len(age_blocks)):
        new_pop[i, :] += outflows[i - 1, :]

    entrant_mass = float(outflows[-1, :].sum())
    new_pop[0, :] += entrant_mass * entrant_mix
    return new_pop


def simulate_scenario(summary: pd.DataFrame, scenario: Scenario, params: SupplyStockParams, T: int) -> pd.DataFrame:
    pop = summary.loc[:, STATE_ORDER].to_numpy(dtype=float) * summary["block_mass"].to_numpy(dtype=float)[:, None]
    refs = extract_metrics(pop)

    q = np.zeros(T + 1, dtype=float)
    q[0] = 1.0
    permits = np.zeros(T + 1, dtype=float)
    completions = np.zeros(T + 1, dtype=float)
    stock = np.zeros(T + 1, dtype=float)
    theta = np.zeros(T, dtype=float)
    demand = np.zeros(T, dtype=float)
    backlog = np.zeros(T + 1, dtype=float)

    stock[0] = 1.0
    permits[0] = params.permit_ss
    completions[0] = params.stock_delta * stock[0]
    backlog[0] = completions[0] / params.completion_hazard

    records: list[dict[str, float | int | str]] = []
    for t in range(T):
        metrics = extract_metrics(pop)
        demand_trend = scenario.price_ratio**t
        demand_component = (
            1.0
            + params.demand_young_gain * (metrics["young_mass_share"] - refs["young_mass_share"])
            + params.demand_crunch_gain * (metrics["young_crunch_25_34"] - refs["young_crunch_25_34"])
            + params.demand_mid_owner_gain * (metrics["owner_35_44"] - refs["owner_35_44"])
        )
        demand[t] = max(0.25, demand_trend * demand_component)

        theta_raw = params.theta0 + params.theta_old * metrics["old_owner_share"] - params.theta_young * metrics["young_owner_25_34"]
        theta[t] = float(np.clip(theta_raw, 0.0, 0.95))

        stock_gap = demand[t] - stock[t]
        permit_target = (
            params.permit_ss
            + params.permit_gap_gain * stock_gap
            - params.permit_theta_gain * (theta[t] - params.theta0)
            + params.permit_price_gain * np.log(max(q[t], 1.0e-6))
        )
        permits[t + 1] = max(
            params.permit_floor,
            params.permit_inertia * permits[t] + (1.0 - params.permit_inertia) * permit_target,
        )

        completions[t + 1] = max(params.permit_floor, params.completion_hazard * backlog[t])
        backlog[t + 1] = max(0.0, backlog[t] + permits[t + 1] - completions[t + 1])
        stock[t + 1] = max(0.50, (1.0 - params.stock_delta) * stock[t] + completions[t + 1])

        log_q_next = np.log(max(q[t], 1.0e-6)) + params.price_damping * params.price_gap_gain * stock_gap
        q[t + 1] = float(np.clip(np.exp(log_q_next), params.q_min, params.q_max))

        records.append(
            {
                "scenario": scenario.name,
                "t": t,
                "q": float(q[t]),
                "demand_index": float(demand[t]),
                "theta": float(theta[t]),
                "permits": float(permits[t]),
                "completions": float(completions[t]),
                "backlog": float(backlog[t]),
                "stock": float(stock[t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "young_crunch_25_34": metrics["young_crunch_25_34"],
                "owner_35_44": metrics["owner_35_44"],
                "mortgaged_owner_35_44": metrics["mortgage_35_44"],
                "aggregate_owner_share": metrics["aggregate_owner_share"],
                "aggregate_mortgaged_owner_share": metrics["aggregate_mortgaged_owner_share"],
            }
        )

        pop = update_population(summary, pop, scenario, q[t], t)

    return pd.DataFrame.from_records(records)


def build_summary(frames: list[pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame]:
    combined = pd.concat(frames, ignore_index=True)
    baseline = combined.loc[combined["scenario"] == "baseline_d05_stock"].set_index("t")

    rows: list[dict[str, float | int | str]] = []
    for scenario_name in combined["scenario"].drop_duplicates():
        frame = combined.loc[combined["scenario"] == scenario_name].set_index("t")
        for t in CHECKPOINTS:
            f = frame.loc[t]
            b = baseline.loc[t]
            rows.append(
                {
                    "scenario": scenario_name,
                    "t": int(t),
                    "q": float(f["q"]),
                    "theta": float(f["theta"]),
                    "permits": float(f["permits"]),
                    "completions": float(f["completions"]),
                    "stock": float(f["stock"]),
                    "young_owner_25_34": float(f["young_owner_25_34"]),
                    "young_mortgaged_owner_25_34": float(f["young_mortgaged_owner_25_34"]),
                    "owner_35_44": float(f["owner_35_44"]),
                    "mortgaged_owner_35_44": float(f["mortgaged_owner_35_44"]),
                    "q_gap_vs_baseline": float(f["q"] - b["q"]),
                    "young_owner_gap_vs_baseline": float(f["young_owner_25_34"] - b["young_owner_25_34"]),
                    "young_mortgage_gap_vs_baseline": float(
                        f["young_mortgaged_owner_25_34"] - b["young_mortgaged_owner_25_34"]
                    ),
                    "permits_gap_vs_baseline": float(f["permits"] - b["permits"]),
                    "stock_gap_vs_baseline": float(f["stock"] - b["stock"]),
                }
            )

    peak_rows: list[dict[str, float | int | str]] = []
    for scenario_name in combined["scenario"].drop_duplicates():
        if scenario_name == "baseline_d05_stock":
            continue
        frame = combined.loc[combined["scenario"] == scenario_name].set_index("t")
        aligned = frame.join(
            baseline[["q", "young_owner_25_34", "young_mortgaged_owner_25_34", "permits", "stock"]],
            rsuffix="_baseline",
        )
        aligned["q_gap"] = aligned["q"] - aligned["q_baseline"]
        aligned["young_owner_gap"] = aligned["young_owner_25_34"] - aligned["young_owner_25_34_baseline"]
        aligned["young_mortgage_gap"] = (
            aligned["young_mortgaged_owner_25_34"] - aligned["young_mortgaged_owner_25_34_baseline"]
        )
        aligned["permits_gap"] = aligned["permits"] - aligned["permits_baseline"]
        aligned["stock_gap"] = aligned["stock"] - aligned["stock_baseline"]
        peak_t = int(aligned["young_mortgage_gap"].idxmax())
        peak_rows.append(
            {
                "scenario": scenario_name,
                "peak_t_young_mortgage_gap": peak_t,
                "peak_young_mortgage_gap": float(aligned.loc[peak_t, "young_mortgage_gap"]),
                "q_gap_at_peak": float(aligned.loc[peak_t, "q_gap"]),
                "permits_gap_at_peak": float(aligned.loc[peak_t, "permits_gap"]),
                "stock_gap_at_peak": float(aligned.loc[peak_t, "stock_gap"]),
                "q_at_t5": float(aligned.loc[5, "q"]),
                "young_mortgage_gap_t5": float(aligned.loc[5, "young_mortgage_gap"]),
                "young_mortgage_gap_t20": float(aligned.loc[20, "young_mortgage_gap"]),
                "q_gap_t20": float(aligned.loc[20, "q_gap"]),
            }
        )

    summary = pd.DataFrame(rows).sort_values(["scenario", "t"]).reset_index(drop=True)
    peaks = pd.DataFrame(peak_rows)
    return summary, peaks


def write_note(path: Path, summary: pd.DataFrame, peaks: pd.DataFrame) -> None:
    bench = peaks.loc[peaks["scenario"] == "benchmark_d05_stock"].iloc[0]
    robust = peaks.loc[peaks["scenario"] == "robustness_d05_stock"].iloc[0]
    lines = [
        "# Annual snapshot transition with permits and stock",
        "",
        "This note replaces the thin annual price bridge with a first stock-flow block:",
        "",
        "- politics / age composition -> `theta_t`",
        "- `theta_t`, prices, and demand -> permits",
        "- permit backlog -> completions",
        "- completions -> housing stock",
        "- stock relative to demand -> prices",
        "",
        "This is the first direct implementation of the `votes -> permits -> completions/stock -> prices` idea on the annual snapshot transition object.",
        "",
        "## Scenarios",
        "",
        "- `baseline_d05_stock`: permanent background drift pressure only",
        "- `benchmark_d05_stock`: benchmark help-to-buy + light family help",
        "- `robustness_d05_stock`: stronger data-leaning support regime",
        "",
        "## Checkpoints",
        "",
        "| Scenario | t | q | theta | permits | stock | Young owner 25-34 | Young mortgaged-owner 25-34 | q gap vs baseline | Young mortgage gap vs baseline |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in summary.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | {row.q:.3f} | {row.theta:.3f} | {row.permits:.3f} | {row.stock:.3f} | "
            f"{row.young_owner_25_34:.3f} | {row.young_mortgaged_owner_25_34:.3f} | {row.q_gap_vs_baseline:.3f} | {row.young_mortgage_gap_vs_baseline:.3f} |"
        )
    lines.extend(
        [
            "",
            "## Peak mortgage-gap effects",
            "",
            "| Scenario | Peak t | Peak young mortgage gap | q gap at peak | Permits gap at peak | Stock gap at peak | Young mortgage gap t=5 | Young mortgage gap t=20 | q gap t=20 |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in peaks.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.peak_t_young_mortgage_gap} | {row.peak_young_mortgage_gap:.3f} | "
            f"{row.q_gap_at_peak:.3f} | {row.permits_gap_at_peak:.3f} | {row.stock_gap_at_peak:.3f} | "
            f"{row.young_mortgage_gap_t5:.3f} | {row.young_mortgage_gap_t20:.3f} | {row.q_gap_t20:.3f} |"
        )
    lines.extend(
        [
            "",
            "## Read",
            "",
            "- The important change is that prices no longer move straight off one reduced-form supply term.",
            "- Politics now affect permit flow first, completions arrive with a lag through the backlog, and prices clear against stock.",
            f"- In this first pass, benchmark support raises young mortgaged-owner share by about `{bench['young_mortgage_gap_t5']:.3f}` at `t = 5` and `{bench['young_mortgage_gap_t20']:.3f}` at `t = 20`, while leaving price slightly below baseline by `t = 20` (`{bench['q_gap_t20']:.3f}`).",
            f"- The stronger robustness regime raises young mortgaged-owner share by about `{robust['young_mortgage_gap_t5']:.3f}` at `t = 5` and `{robust['young_mortgage_gap_t20']:.3f}` at `t = 20`, with a somewhat larger negative price gap by `t = 20` (`{robust['q_gap_t20']:.3f}`).",
            "- So the stock-flow middle layer is doing something economically different from the thin bridge: support now works mainly by lowering political tightness and lifting stock gradually, not by direct price wedges.",
            "- This is still a first-pass annual stock-flow block, not yet a full data-estimated permits model.",
            "- Under a permanent `+5%` annual demand-pressure trend, the price path still eventually hits the upper numerical cap, so the sensible read window remains `t = 0-20` rather than the very long run.",
            "- The next step is therefore to keep this permits/stock structure and only reopen bounded RE on top of this upgraded block, not on the old thin bridge.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")
    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = SupplyStockParams()
    frames = [simulate_scenario(summary, scenario, params, T=T) for scenario in build_scenarios()]
    combined = pd.concat(frames, ignore_index=True)
    combined.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    summary_table, peaks = build_summary(frames)
    summary_table.to_csv(BUILD / f"{OUTPUT_STEM}_summary.csv", index=False)
    peaks.to_csv(BUILD / f"{OUTPUT_STEM}_peaks.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", summary_table, peaks)


if __name__ == "__main__":
    main()
