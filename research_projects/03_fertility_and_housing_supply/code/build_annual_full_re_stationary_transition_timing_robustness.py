from __future__ import annotations

import argparse
from dataclasses import replace
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    CAL_WINDOW,
    COMPLETIONS_STARTS_TARGET,
    PERMIT_TO_COMPLETION_LAG_YEARS,
    STARTS_PERMITS_TARGET,
    StartsStockParams,
    resolve_calibrated_params,
    simulate,
)
from build_annual_full_path_re_permits_starts_stock_calibrated import solve_full_path
from build_annual_full_re_stationary_transition_calibrated import (
    build_stationary_scenarios,
    simulate_stationary_re_path,
    stationary_targets,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
DEFAULT_DURATION_SHIFT = 0.20
CHECKPOINTS = [5, 10, 20, 40, 80]
CENTRAL_SELECTION_EPS = 2.0e-5


def timing_case_params(base: StartsStockParams, duration_scale: float) -> StartsStockParams:
    return replace(
        base,
        start_hazard=float(np.clip(base.start_hazard / duration_scale, 0.05, 0.98)),
        completion_hazard=float(np.clip(base.completion_hazard / duration_scale, 0.05, 0.98)),
        permit_inventory_years=float(max(0.05, base.permit_inventory_years * duration_scale)),
        uc_inventory_years=float(max(0.10, base.uc_inventory_years * duration_scale)),
    )


def timing_cases(base: StartsStockParams, duration_shift: float) -> list[tuple[str, StartsStockParams, float]]:
    if duration_shift <= 0.0:
        raise ValueError("duration_shift must be positive.")
    return [
        ("benchmark_timing", base, 1.0),
        ("faster_timing", timing_case_params(base, 1.0 - duration_shift), 1.0 - duration_shift),
        ("slower_timing", timing_case_params(base, 1.0 + duration_shift), 1.0 + duration_shift),
    ]


def scenario_specific_calibration_loss(frame: pd.DataFrame) -> float:
    summary = summarize_calibration_window(frame)
    lag_penalty = (summary["avg_permit_inventory_years_t1_t5"] - PERMIT_TO_COMPLETION_LAG_YEARS) ** 2
    return (
        (summary["avg_starts_permits_ratio_t1_t5"] - STARTS_PERMITS_TARGET) ** 2
        + (summary["avg_completions_starts_ratio_t1_t5"] - COMPLETIONS_STARTS_TARGET) ** 2
        + 0.25 * lag_penalty
    )


def stationary_benchmark_recalibration(
    summary: pd.DataFrame,
    scenario,
    base_params: StartsStockParams,
) -> tuple[StartsStockParams, pd.DataFrame]:
    candidate_rows: list[dict[str, float]] = []

    start_grid = sorted(
        {
            round(float(x), 3)
            for x in np.concatenate(
                [
                    np.arange(max(0.55, base_params.start_hazard - 0.05), min(0.80, base_params.start_hazard + 0.051), 0.05),
                    np.array([base_params.start_hazard]),
                ]
            )
        }
    )
    completion_grid = sorted(
        {
            round(float(x), 3)
            for x in np.concatenate(
                [
                    np.arange(0.34, 0.481, 0.02),
                    np.array([base_params.completion_hazard]),
                ]
            )
        }
    )
    permit_inventory_grid = sorted(
        {
            round(float(x), 3)
            for x in np.concatenate(
                [
                    np.array([0.10, 0.125, 0.15, 0.175, 0.20, 0.225, 0.25]),
                    np.array([base_params.permit_inventory_years]),
                ]
            )
        }
    )
    uc_inventory_grid = sorted(
        {
            round(float(x), 3)
            for x in np.concatenate(
                [
                    np.array([0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.90]),
                    np.array([base_params.uc_inventory_years]),
                ]
            )
        }
    )

    for start_hazard in start_grid:
        for completion_hazard in completion_grid:
            for permit_inventory_years in permit_inventory_grid:
                for uc_inventory_years in uc_inventory_grid:
                    params = replace(
                        base_params,
                        start_hazard=float(start_hazard),
                        completion_hazard=float(completion_hazard),
                        permit_inventory_years=float(permit_inventory_years),
                        uc_inventory_years=float(uc_inventory_years),
                    )
                    frame = simulate(summary, scenario, params, T=8)
                    calibration_summary = summarize_calibration_window(frame)
                    loss = scenario_specific_calibration_loss(frame)
                    candidate_rows.append(
                        {
                            "start_hazard": params.start_hazard,
                            "completion_hazard": params.completion_hazard,
                            "permit_inventory_years": params.permit_inventory_years,
                            "uc_inventory_years": params.uc_inventory_years,
                            **calibration_summary,
                            "loss": float(loss),
                        }
                    )

    calibration_table = pd.DataFrame(candidate_rows)
    min_loss = float(calibration_table["loss"].min())
    calibration_table["loss_gap"] = calibration_table["loss"] - min_loss
    calibration_table["dist_to_base"] = np.sqrt(
        (calibration_table["start_hazard"] - base_params.start_hazard) ** 2
        + (calibration_table["completion_hazard"] - base_params.completion_hazard) ** 2
        + (calibration_table["permit_inventory_years"] - base_params.permit_inventory_years) ** 2
        + (calibration_table["uc_inventory_years"] - base_params.uc_inventory_years) ** 2
    )
    calibration_table["epsilon_optimal"] = calibration_table["loss_gap"] <= CENTRAL_SELECTION_EPS

    selection_pool = calibration_table.loc[calibration_table["epsilon_optimal"]].copy()
    if selection_pool.empty:
        selection_pool = calibration_table.copy()

    best = selection_pool.sort_values(
        ["dist_to_base", "loss", "permit_inventory_years", "uc_inventory_years", "completion_hazard"]
    ).iloc[0]

    calibration_table["selected"] = (
        (calibration_table["start_hazard"] == float(best["start_hazard"]))
        & (calibration_table["completion_hazard"] == float(best["completion_hazard"]))
        & (calibration_table["permit_inventory_years"] == float(best["permit_inventory_years"]))
        & (calibration_table["uc_inventory_years"] == float(best["uc_inventory_years"]))
    )
    calibration_table = calibration_table.sort_values(
        ["selected", "loss", "dist_to_base", "permit_inventory_years", "uc_inventory_years", "completion_hazard"],
        ascending=[False, True, True, True, True, True],
    ).reset_index(drop=True)

    best_params = replace(
        base_params,
        start_hazard=float(best["start_hazard"]),
        completion_hazard=float(best["completion_hazard"]),
        permit_inventory_years=float(best["permit_inventory_years"]),
        uc_inventory_years=float(best["uc_inventory_years"]),
    )
    return best_params, calibration_table


def summarize_calibration_window(frame: pd.DataFrame) -> dict[str, float]:
    sub = frame.loc[frame["t"].isin(CAL_WINDOW)].copy()
    starts_permits = float(sub["starts_permits_ratio"].mean())
    completions_starts = float(sub["completions_starts_ratio"].mean())
    permit_inventory_years = float((sub["permit_inventory"] / sub["permits"].replace(0.0, np.nan)).mean())
    uc_inventory_years = float((sub["uc_inventory"] / sub["starts"].replace(0.0, np.nan)).mean())
    return {
        "avg_starts_permits_ratio_t1_t5": starts_permits,
        "avg_completions_starts_ratio_t1_t5": completions_starts,
        "avg_permit_inventory_years_t1_t5": permit_inventory_years,
        "avg_uc_inventory_years_t1_t5": uc_inventory_years,
    }


def build_checkpoint_rows(
    case_name: str,
    re_frame: pd.DataFrame,
    anchor: pd.DataFrame,
    stationary_row: pd.Series,
    checkpoints: list[int],
) -> list[dict[str, float | int | str]]:
    anchor_map = anchor.set_index("t")
    rows: list[dict[str, float | int | str]] = []
    for t in checkpoints:
        re_row = re_frame.loc[re_frame["t"] == t].iloc[0]
        anchor_row = anchor_map.loc[t]
        rows.append(
            {
                "timing_case": case_name,
                "t": int(t),
                "q": float(re_row["q"]),
                "stock": float(re_row["stock"]),
                "young_mortgaged_owner_25_34": float(re_row["young_mortgaged_owner_25_34"]),
                "q_gap_vs_anchor": float(re_row["q"] - anchor_row["q"]),
                "young_mortgage_gap_vs_anchor": float(
                    re_row["young_mortgaged_owner_25_34"] - anchor_row["young_mortgaged_owner_25_34"]
                ),
                "q_gap_vs_stationary": float(re_row["q"] - stationary_row["q_ss"]),
                "young_mortgage_gap_vs_stationary": float(
                    re_row["young_mortgaged_owner_25_34"] - stationary_row["young_mortgage_ss"]
                ),
            }
        )
    return rows


def write_note(
    note_path: Path,
    case_table: pd.DataFrame,
    checkpoint_table: pd.DataFrame,
    recalibration_table: pd.DataFrame,
    horizon: int,
    duration_shift: float,
) -> None:
    shift_pct = int(round(duration_shift * 100))
    lines = [
        f"# Annual full RE stationary transition timing robustness (T={horizon})",
        "",
        "This note promotes a benchmark interpretation for the annual construction-flow block and then adds modest faster/slower timing variants around that benchmark.",
        "",
        "Important calibration rule:",
        "",
        "- The stationary benchmark timing case is recalibrated under the stationary benchmark scenario itself.",
        "- This avoids mixing a nonstationary/base calibration with the stationary benchmark transition object.",
        "- The `0.5-year` Census-style anchor is used only for the permit-stage backlog moment in the model. It is not a literal estimate of total elapsed permit-to-completion time.",
        f"- The benchmark row is selected from the epsilon-optimal ridge using a centrality rule: any row within `{CENTRAL_SELECTION_EPS:.6f}` of the minimum loss is admissible, and the benchmark picks the admissible row closest to the inherited baseline calibration.",
        "",
        "Interpretation:",
        "",
        "- `benchmark_timing` is the data-disciplined annual permits -> starts -> completions -> stock block.",
        f"- `faster_timing` shortens the benchmark timing by about `{shift_pct}%`.",
        f"- `slower_timing` lengthens the benchmark timing by about `{shift_pct}%`.",
        "- These timing cases should be read as scenario robustness around the calibrated benchmark, not as point-identified structural facts.",
        "- The completion side is only weakly identified here, so `completion_hazard` and `uc_inventory_years` should be read as a scenario-conditional reduced-form normalization rather than as portable technology parameters.",
        "",
        "## Stationary benchmark recalibration",
        "",
        "| Selected | Start hazard | Completion hazard | Permit inventory years | Under-construction years | Starts / permits (t=1-5) | Completions / starts (t=1-5) | Permit inventory years (t=1-5) | U/C inventory years (t=1-5) | Loss | Loss gap | Dist. to baseline |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]

    for row in recalibration_table.head(5).itertuples(index=False):
        lines.append(
            f"| `{'yes' if row.selected else ''}` | `{row.start_hazard:.3f}` | `{row.completion_hazard:.3f}` | `{row.permit_inventory_years:.3f}` | `{row.uc_inventory_years:.3f}` | "
            f"`{row.avg_starts_permits_ratio_t1_t5:.3f}` | `{row.avg_completions_starts_ratio_t1_t5:.3f}` | `{row.avg_permit_inventory_years_t1_t5:.3f}` | "
            f"`{row.avg_uc_inventory_years_t1_t5:.3f}` | `{row.loss:.6f}` | `{row.loss_gap:.6f}` | `{row.dist_to_base:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Timing-case summary",
            "",
            "| Timing case | Start hazard | Completion hazard | Permit inventory years | Under-construction years | Starts / permits (t=1-5) | Completions / starts (t=1-5) | U/C inventory years (t=1-5) | q1 | q5 | q10 | q20 | q40 | q80 | q_ss | Young mortgage_ss |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in case_table.itertuples(index=False):
        q40 = f"{row.q40:.3f}" if not pd.isna(row.q40) else "nan"
        q80 = f"{row.q80:.3f}" if not pd.isna(row.q80) else "nan"
        lines.append(
            f"| `{row.timing_case}` | `{row.start_hazard:.3f}` | `{row.completion_hazard:.3f}` | `{row.permit_inventory_years:.3f}` | "
            f"`{row.uc_inventory_years:.3f}` | `{row.avg_starts_permits_ratio_t1_t5:.3f}` | `{row.avg_completions_starts_ratio_t1_t5:.3f}` | `{row.avg_uc_inventory_years_t1_t5:.3f}` | "
            f"`{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | `{q40}` | `{q80}` | `{row.q_ss:.3f}` | `{row.young_mortgage_ss:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to the no-RE anchor under the same timing case",
            "",
            "| Timing case | t | q | q gap vs anchor | q gap vs stationary | Young mortgaged-owner 25-34 | Young mortgage gap vs anchor | Young mortgage gap vs stationary |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in checkpoint_table.itertuples(index=False):
        lines.append(
            f"| `{row.timing_case}` | {row.t} | `{row.q:.3f}` | `{row.q_gap_vs_anchor:.3f}` | `{row.q_gap_vs_stationary:.3f}` | "
            f"`{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_anchor:.3f}` | `{row.young_mortgage_gap_vs_stationary:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the benchmark-first sequence the project should use: benchmark timing from data first, then faster/slower robustness around that benchmark.",
            "- The benchmark case is the annual construction-flow block already disciplined by observed construction-flow moments, but the completion side is only weakly identified along a shallow hazard / under-construction-inventory ridge.",
            "- The faster/slower cases should be presented as stress tests around supply-adjustment speed, not as equally target-matched alternative calibrations or as separately identified political-delay estimates.",
            "- The economically interpretable reporting objects are the implied `t = 1-5` flow moments, especially starts / permits, completions / starts, permit inventory years, and under-construction inventory years, rather than the raw inventory-state parameters alone.",
        ]
    )
    note_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--duration-shift", type=float, default=DEFAULT_DURATION_SHIFT)
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in CHECKPOINTS if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    base_params = resolve_calibrated_params(summary)
    benchmark_scenario = next(s for s in build_stationary_scenarios() if s.name == "benchmark_d00_stock_data")
    benchmark_params, recalibration_table = stationary_benchmark_recalibration(summary, benchmark_scenario, base_params)

    case_rows: list[dict[str, float | str]] = []
    checkpoint_rows: list[dict[str, float | int | str]] = []

    for case_name, params, duration_scale in timing_cases(benchmark_params, args.duration_shift):
        stationary = stationary_targets(summary, params, [benchmark_scenario]).iloc[0]
        calibration_frame = simulate(summary, benchmark_scenario, params, T=8)
        calibration_summary = summarize_calibration_window(calibration_frame)
        anchor = simulate(summary, benchmark_scenario, params, T=horizon + 1)
        q_path, _, _ = solve_full_path(summary, benchmark_scenario, params, horizon)
        re_frame = simulate_stationary_re_path(summary, benchmark_scenario, params, q_path)

        case_rows.append(
            {
                "timing_case": case_name,
                "duration_scale": duration_scale,
                "start_hazard": params.start_hazard,
                "completion_hazard": params.completion_hazard,
                "permit_inventory_years": params.permit_inventory_years,
                "uc_inventory_years": params.uc_inventory_years,
                "avg_starts_permits_ratio_t1_t5": calibration_summary["avg_starts_permits_ratio_t1_t5"],
                "avg_completions_starts_ratio_t1_t5": calibration_summary["avg_completions_starts_ratio_t1_t5"],
                "avg_permit_inventory_years_t1_t5": calibration_summary["avg_permit_inventory_years_t1_t5"],
                "avg_uc_inventory_years_t1_t5": calibration_summary["avg_uc_inventory_years_t1_t5"],
                "q1": float(q_path[0]),
                "q5": float(q_path[4]) if horizon >= 5 else np.nan,
                "q10": float(q_path[9]) if horizon >= 10 else np.nan,
                "q20": float(q_path[19]) if horizon >= 20 else np.nan,
                "q40": float(q_path[39]) if horizon >= 40 else np.nan,
                "q80": float(q_path[79]) if horizon >= 80 else np.nan,
                "q_ss": float(stationary["q_ss"]),
                "young_mortgage_ss": float(stationary["young_mortgage_ss"]),
            }
        )
        checkpoint_rows.extend(
            build_checkpoint_rows(case_name=case_name, re_frame=re_frame, anchor=anchor, stationary_row=stationary, checkpoints=checkpoints)
        )

    case_table = pd.DataFrame(case_rows)
    checkpoint_table = pd.DataFrame(checkpoint_rows)

    stem = f"annual_full_re_stationary_transition_timing_robustness_T{horizon}"
    case_table.to_csv(BUILD / f"{stem}_cases.csv", index=False)
    checkpoint_table.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    recalibration_table.to_csv(BUILD / f"{stem}_benchmark_recalibration.csv", index=False)
    write_note(
        BUILD / f"{stem}.md",
        case_table,
        checkpoint_table,
        recalibration_table,
        horizon,
        float(args.duration_shift),
    )


if __name__ == "__main__":
    main()
