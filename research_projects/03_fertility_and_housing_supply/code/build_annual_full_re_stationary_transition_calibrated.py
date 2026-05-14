from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, Scenario, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    resolve_calibrated_params,
    simulate,
)
from build_annual_full_path_re_permits_starts_stock_calibrated import (
    initial_state,
    solve_full_path,
    update_construction,
)
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    demand_index,
    extract_metrics,
    permit_update,
    theta_from_metrics,
    update_population,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
STATIONARY_T = 300
STATIONARY_TAIL = 20


def build_stationary_scenarios() -> list[Scenario]:
    return [
        Scenario("baseline_d00_stock_data", 1.00, 0.0, 0.0, 0, 0, False),
        Scenario(
            "benchmark_d00_stock_data",
            1.00,
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
            "robustness_d00_stock_data",
            1.00,
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


def stationary_targets(summary: pd.DataFrame, params, scenarios: list[Scenario]) -> pd.DataFrame:
    rows: list[dict[str, float | str]] = []
    for scenario in scenarios:
        frame = simulate(summary, scenario, params, T=STATIONARY_T)
        tail = frame.tail(STATIONARY_TAIL)
        rows.append(
            {
                "scenario": scenario.name,
                "q_ss": float(tail["q"].mean()),
                "permits_ss": float(tail["permits"].mean()),
                "starts_ss": float(tail["starts"].mean()),
                "completions_ss": float(tail["completions"].mean()),
                "stock_ss": float(tail["stock"].mean()),
                "young_mortgage_ss": float(tail["young_mortgaged_owner_25_34"].mean()),
                "owner_35_44_ss": float(tail["owner_35_44"].mean()),
            }
        )
    return pd.DataFrame(rows)


def simulate_stationary_re_path(summary: pd.DataFrame, scenario, params, q_path: np.ndarray) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        metrics = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics, params)
        demand_t = demand_index(metrics, refs, scenario.price_ratio, t, params)

        records.append(
            {
                "scenario": f"{scenario.name}_T{horizon}_full_re_stationary",
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


def build_checkpoint_table(
    re_paths: pd.DataFrame,
    anchors: pd.DataFrame,
    stationary: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    anchor_map = anchors.set_index(["scenario", "t"])
    stationary_map = stationary.set_index("scenario")
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_T{horizon}_full_re_stationary"

    for _, row in re_paths.loc[re_paths["t"].isin(checkpoints)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        anchor = anchor_map.loc[(base_name, int(row["t"]))]
        ss = stationary_map.loc[base_name]
        rows.append(
            {
                "scenario": row["scenario"],
                "anchor_scenario": base_name,
                "t": int(row["t"]),
                "q": float(row["q"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "owner_35_44": float(row["owner_35_44"]),
                "q_gap_vs_no_re_anchor": float(row["q"] - anchor["q"]),
                "young_mortgage_gap_vs_no_re_anchor": float(
                    row["young_mortgaged_owner_25_34"] - anchor["young_mortgaged_owner_25_34"]
                ),
                "q_gap_vs_stationary": float(row["q"] - ss["q_ss"]),
                "young_mortgage_gap_vs_stationary": float(
                    row["young_mortgaged_owner_25_34"] - ss["young_mortgage_ss"]
                ),
                "owner_35_44_gap_vs_stationary": float(row["owner_35_44"] - ss["owner_35_44_ss"]),
            }
        )

    return pd.DataFrame(rows)


def write_note(
    path: Path,
    fixed_points: pd.DataFrame,
    checkpoints: pd.DataFrame,
    stationary: pd.DataFrame,
    horizon: int,
) -> None:
    lines = [
        f"# Annual full RE around stationary annual equilibrium (T={horizon})",
        "",
        "This note rebuilds the annual full-RE object around the new **stationary annual equilibrium** instead of around the old permanently drifting path.",
        "",
        "The object is now:",
        "",
        "- observed `t = 0` snapshot",
        "- no permanent demand drift",
        "- calibrated permits -> starts -> completions -> stock block",
        "- full RE price path `q_1 ... q_T`",
        "- comparison against both the no-RE transition anchor and the stationary annual endpoint",
        "",
        "## Stationary annual endpoints",
        "",
        "| Scenario | q_ss | Permits_ss | Starts_ss | Completions_ss | Stock_ss | Young mortgaged-owner 25-34_ss | Owner 35-44_ss |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]

    for row in stationary.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q_ss:.3f}` | `{row.permits_ss:.3f}` | `{row.starts_ss:.3f}` | `{row.completions_ss:.3f}` | "
            f"`{row.stock_ss:.3f}` | `{row.young_mortgage_ss:.3f}` | `{row.owner_35_44_ss:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Full-RE path excerpts",
            "",
            "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 | q_ss |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    ss_map = stationary.set_index("scenario")
    for row in fixed_points.itertuples(index=False):
        q80 = f"{row.q80:.3f}" if not pd.isna(row.q80) else "nan"
        q40 = f"{row.q40:.3f}" if not pd.isna(row.q40) else "nan"
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | "
            f"`{q40}` | `{q80}` | `{ss_map.loc[row.scenario, 'q_ss']:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints",
            "",
            "| Scenario | t | q | q gap vs no-RE anchor | q gap vs stationary | Young mortgaged-owner 25-34 | Young mortgage gap vs no-RE anchor | Young mortgage gap vs stationary |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in checkpoints.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.q:.3f}` | `{row.q_gap_vs_no_re_anchor:.3f}` | `{row.q_gap_vs_stationary:.3f}` | "
            f"`{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_no_re_anchor:.3f}` | `{row.young_mortgage_gap_vs_stationary:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first annual full-RE transition that is genuinely anchored to a stationary annual endpoint.",
            "- If the early `t = 5-20` RE path remains close to the no-RE transition while the long run converges toward the stationary endpoint, then the paper can honestly describe the annual branch as a full-RE annualised model rather than only as a bounded-RE transition exercise.",
            "- The remaining question after this note is no longer whether full RE is conceptually available. It is how prominently to feature the stationary endpoint versus the short-horizon transition facts in the paper exposition.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in [5, 10, 20, 40, 80] if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    stationary = stationary_targets(summary, params, scenarios)

    anchor_frames = []
    re_frames = []
    fixed_rows: list[dict[str, float | str]] = []

    for scenario in scenarios:
        anchor = simulate(summary, scenario, params, T=horizon + 1)
        anchor_frames.append(anchor)

        q_path, _, _ = solve_full_path(summary, scenario, params, horizon)
        re_frame = simulate_stationary_re_path(summary, scenario, params, q_path)
        re_frames.append(re_frame)

        fixed_rows.append(
            {
                "scenario": scenario.name,
                "q1": float(q_path[0]),
                "q5": float(q_path[4]) if horizon >= 5 else np.nan,
                "q10": float(q_path[9]) if horizon >= 10 else np.nan,
                "q20": float(q_path[19]) if horizon >= 20 else np.nan,
                "q40": float(q_path[39]) if horizon >= 40 else np.nan,
                "q80": float(q_path[79]) if horizon >= 80 else np.nan,
            }
        )

    anchors = pd.concat(anchor_frames, ignore_index=True)
    re_paths = pd.concat(re_frames, ignore_index=True)
    fixed_points = pd.DataFrame(fixed_rows)
    checkpoint_table = build_checkpoint_table(re_paths, anchors, stationary, checkpoints, horizon)

    stem = f"annual_full_re_stationary_transition_calibrated_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    anchors.to_csv(BUILD / f"{stem}_anchors.csv", index=False)
    re_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    checkpoint_table.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    stationary.to_csv(BUILD / f"{stem}_stationary_targets.csv", index=False)
    write_note(BUILD / f"{stem}.md", fixed_points, checkpoint_table, stationary, horizon)


if __name__ == "__main__":
    main()
