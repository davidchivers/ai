from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    StartsStockParams,
    build_scenarios,
    demand_index,
    extract_metrics,
    implied_q_next,
    initialize_inventories,
    permit_update,
    rename_scenario,
    resolve_calibrated_params,
    simulate,
    theta_from_metrics,
    update_population,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_CHECKPOINTS = [5, 10, 20, 40]


def initial_state(summary: pd.DataFrame, params: StartsStockParams, horizon: int) -> tuple[np.ndarray, dict[str, np.ndarray], dict[str, float]]:
    pop0 = summary.loc[:, ["renter_no_debt", "renter_with_debt", "owner_with_mortgage", "owner_outright"]].to_numpy(dtype=float)
    pop0 = pop0 * summary["block_mass"].to_numpy(dtype=float)[:, None]
    refs = extract_metrics(pop0)

    arrays = {
        "q": np.zeros(horizon + 1, dtype=float),
        "permits": np.zeros(horizon + 1, dtype=float),
        "starts": np.zeros(horizon + 1, dtype=float),
        "completions": np.zeros(horizon + 1, dtype=float),
        "stock": np.zeros(horizon + 1, dtype=float),
        "permit_inventory": np.zeros(horizon + 1, dtype=float),
        "uc_inventory": np.zeros(horizon + 1, dtype=float),
    }
    arrays["q"][0] = 1.0
    arrays["stock"][0] = 1.0
    arrays["permits"][0] = params.permit_ss
    arrays["permit_inventory"][0], arrays["uc_inventory"][0] = initialize_inventories(params)
    arrays["starts"][0] = min(arrays["permit_inventory"][0], params.start_hazard * arrays["permit_inventory"][0])
    arrays["completions"][0] = min(arrays["uc_inventory"][0], params.completion_hazard * arrays["uc_inventory"][0])
    return pop0, arrays, refs


def update_construction(arrays: dict[str, np.ndarray], t: int, params: StartsStockParams) -> None:
    available_authorized = arrays["permit_inventory"][t] + arrays["permits"][t + 1]
    arrays["starts"][t + 1] = min(available_authorized, params.start_hazard * available_authorized)
    arrays["permit_inventory"][t + 1] = max(0.0, available_authorized - arrays["starts"][t + 1])

    available_uc = arrays["uc_inventory"][t] + arrays["starts"][t + 1]
    arrays["completions"][t + 1] = min(available_uc, params.completion_hazard * available_uc)
    arrays["uc_inventory"][t + 1] = max(0.0, available_uc - arrays["completions"][t + 1])

    arrays["stock"][t + 1] = max(
        0.50,
        (1.0 - params.stock_delta) * arrays["stock"][t] + arrays["completions"][t + 1],
    )


def full_path_implied(
    summary: pd.DataFrame,
    scenario,
    params: StartsStockParams,
    q_guesses: np.ndarray,
) -> tuple[np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    current_q = arrays["q"][0]

    extras = {
        "theta": [],
        "permits": [],
        "starts": [],
        "completions": [],
        "stock": [],
        "young_mortgage": [],
    }

    for t in range(horizon):
        metrics_t = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics_t, params)
        demand_t = demand_index(metrics_t, refs, scenario.price_ratio, t, params)

        arrays["permits"][t + 1] = permit_update(arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_guesses[t], params)
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario, q_guesses[t], t)
        metrics_next = extract_metrics(pop)
        demand_next = demand_index(metrics_next, refs, scenario.price_ratio, t + 1, params)
        current_q = implied_q_next(current_q, demand_next, arrays["stock"][t + 1], params)
        q_implied[t] = current_q

        extras["theta"].append(float(theta_t))
        extras["permits"].append(float(arrays["permits"][t + 1]))
        extras["starts"].append(float(arrays["starts"][t + 1]))
        extras["completions"].append(float(arrays["completions"][t + 1]))
        extras["stock"].append(float(arrays["stock"][t + 1]))
        extras["young_mortgage"].append(float(metrics_next["young_mortgage_25_34"]))

    return q_implied, extras


def solve_full_path(
    summary: pd.DataFrame,
    scenario,
    params: StartsStockParams,
    horizon: int,
) -> tuple[np.ndarray, dict[str, list[float]], np.ndarray]:
    anchor = simulate(summary, scenario, params, T=horizon + 1)
    q_guess = anchor["q"].to_numpy(dtype=float)[1 : horizon + 1]
    q_implied, extras = full_path_implied(summary, scenario, params, q_guess)

    for _ in range(600):
        q_implied, extras = full_path_implied(summary, scenario, params, q_guess)
        q_new = 0.60 * q_guess + 0.40 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, extras = full_path_implied(summary, scenario, params, q_guess)
            break
        q_guess = q_new

    return q_implied, extras, anchor["q"].to_numpy(dtype=float)[1 : horizon + 1]


def simulate_re_path(summary: pd.DataFrame, scenario, params: StartsStockParams, q_path: np.ndarray) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []
    scenario_name = f"{rename_scenario(scenario.name)}_T{horizon}_full_re"

    for t in range(horizon + 1):
        metrics = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics, params)
        demand_t = demand_index(metrics, refs, scenario.price_ratio, t, params)

        records.append(
            {
                "scenario": scenario_name,
                "t": t,
                "q": float(arrays["q"][t]),
                "theta": float(theta_t),
                "permits": float(arrays["permits"][t]),
                "starts": float(arrays["starts"][t]),
                "completions": float(arrays["completions"][t]),
                "stock": float(arrays["stock"][t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
            }
        )

        if t == horizon:
            break

        q_effective = q_path[t]
        arrays["permits"][t + 1] = permit_update(arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_effective, params)
        update_construction(arrays, t, params)
        pop = update_population(summary, pop, scenario, q_effective, t)
        arrays["q"][t + 1] = q_effective

    return pd.DataFrame.from_records(records)


def build_checkpoint_table(paths: pd.DataFrame, anchors: pd.DataFrame, horizon: int, checkpoints: list[int]) -> pd.DataFrame:
    anchor_map = anchors.set_index(["scenario", "t"])
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_T{horizon}_full_re"
    for _, row in paths.loc[paths["t"].isin(checkpoints)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        anchor = anchor_map.loc[(base_name, int(row["t"]))]
        rows.append(
            {
                "scenario": row["scenario"],
                "anchor_scenario": base_name,
                "t": int(row["t"]),
                "q": float(row["q"]),
                "starts": float(row["starts"]),
                "completions": float(row["completions"]),
                "stock": float(row["stock"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "q_gap_vs_stock_anchor": float(row["q"] - anchor["q"]),
                "young_mortgage_gap_vs_stock_anchor": float(
                    row["young_mortgaged_owner_25_34"] - anchor["young_mortgaged_owner_25_34"]
                ),
            }
        )
    return pd.DataFrame(rows)


def write_note(
    path: Path,
    fixed_points: pd.DataFrame,
    checkpoints: pd.DataFrame,
    horizon: int,
) -> None:
    lines = [
        f"# Annual full-path RE on calibrated permits-starts-stock transition (T={horizon})",
        "",
        f"This note solves the entire annual price path `q_1 ... q_{horizon}` on the calibrated construction-flow block rather than stopping at a short bounded horizon.",
        "",
        "## Fixed-point path excerpts",
        "",
        "| Scenario | q1 | q5 | q10 | q20 | q40 | max |",
        "|---|---:|---:|---:|---:|---:|---:|",
    ]
    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | "
            f"`{row.q20:.3f}` | `{row.q40:.3f}` | `{row.qmax:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to calibrated stock-flow anchor",
            "",
            "| Scenario | t | q | q gap vs anchor | Young mortgaged-owner 25-34 | Young mortgage gap vs anchor |",
            "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for row in checkpoints.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.q:.3f}` | `{row.q_gap_vs_stock_anchor:.3f}` | "
            f"`{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_stock_anchor:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first genuine longer finite-path full-RE solve on the calibrated annual construction-flow block.",
            "- If early `t=5` and `t=10` moments stay close to the shorter `k=3/5` cases, then the annual RE result is robust to extending the horizon.",
            "- If the longer horizon mainly adds a larger later price premium while leaving ownership composition almost unchanged, then the main-text hierarchy should stay with the short bounded cases and treat the longer solve as appendix only.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=40)
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in DEFAULT_CHECKPOINTS if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_scenarios()

    anchor_frames = []
    for scenario in scenarios:
        frame = simulate(summary, scenario, params, T=horizon + 1)
        frame["scenario"] = rename_scenario(scenario.name)
        anchor_frames.append(frame)
    anchors = pd.concat(anchor_frames, ignore_index=True)

    fixed_rows: list[dict[str, float | str]] = []
    re_frames: list[pd.DataFrame] = []
    for scenario in scenarios:
        q_path, extras, q_anchor = solve_full_path(summary, scenario, params, horizon)
        renamed = rename_scenario(scenario.name)
        fixed_rows.append(
            {
                "scenario": renamed,
                "q1": float(q_path[0]),
                "q5": float(q_path[4]) if horizon >= 5 else np.nan,
                "q10": float(q_path[9]) if horizon >= 10 else np.nan,
                "q20": float(q_path[19]) if horizon >= 20 else np.nan,
                "q40": float(q_path[39]) if horizon >= 40 else np.nan,
                "qmax": float(np.max(q_path)),
                "anchor_q1": float(q_anchor[0]),
                "anchor_q20": float(q_anchor[19]) if horizon >= 20 else np.nan,
                "anchor_q40": float(q_anchor[39]) if horizon >= 40 else np.nan,
            }
        )
        re_frames.append(simulate_re_path(summary, scenario, params, q_path))

    fixed_points = pd.DataFrame(fixed_rows)
    re_paths = pd.concat(re_frames, ignore_index=True)
    checkpoints_frame = build_checkpoint_table(re_paths, anchors, horizon, checkpoints)

    stem = f"annual_full_path_re_permits_starts_stock_calibrated_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    re_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    checkpoints_frame.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    write_note(BUILD / f"{stem}.md", fixed_points, checkpoints_frame, horizon)


if __name__ == "__main__":
    main()
