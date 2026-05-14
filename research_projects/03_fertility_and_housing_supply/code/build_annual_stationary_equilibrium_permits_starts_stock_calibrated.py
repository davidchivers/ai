from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, Scenario, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    StartsStockParams,
    resolve_calibrated_params,
    simulate,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_stationary_equilibrium_permits_starts_stock_calibrated"
T = 300
TAIL_WINDOW = 20
ACTIVE_CHECKPOINTS = [0, 1, 2, 5, 10, 20, 40, 80, 120, 200, 299]


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


def stationary_tail_summary(frame: pd.DataFrame, tail_window: int) -> dict[str, float | str]:
    tail = frame.tail(tail_window).copy()
    q_delta = tail["q"].diff().abs().dropna()
    permits_delta = tail["permits"].diff().abs().dropna()
    starts_delta = tail["starts"].diff().abs().dropna()
    completions_delta = tail["completions"].diff().abs().dropna()
    stock_delta = tail["stock"].diff().abs().dropna()
    young_owner_delta = tail["young_owner_25_34"].diff().abs().dropna()
    young_mortgage_delta = tail["young_mortgaged_owner_25_34"].diff().abs().dropna()
    owner_35_44_delta = tail["owner_35_44"].diff().abs().dropna()
    mortgage_35_44_delta = tail["mortgaged_owner_35_44"].diff().abs().dropna()

    max_delta = max(
        float(q_delta.max()),
        float(permits_delta.max()),
        float(starts_delta.max()),
        float(completions_delta.max()),
        float(stock_delta.max()),
        float(young_owner_delta.max()),
        float(young_mortgage_delta.max()),
        float(owner_35_44_delta.max()),
        float(mortgage_35_44_delta.max()),
    )

    return {
        "scenario": str(frame["scenario"].iloc[0]),
        "tail_window": int(tail_window),
        "q_t_end": float(frame["q"].iloc[-1]),
        "q_avg_last_tail": float(tail["q"].mean()),
        "q_max_abs_delta_last_tail": float(q_delta.max()),
        "permits_avg_last_tail": float(tail["permits"].mean()),
        "permits_max_abs_delta_last_tail": float(permits_delta.max()),
        "starts_avg_last_tail": float(tail["starts"].mean()),
        "starts_max_abs_delta_last_tail": float(starts_delta.max()),
        "completions_avg_last_tail": float(tail["completions"].mean()),
        "completions_max_abs_delta_last_tail": float(completions_delta.max()),
        "stock_avg_last_tail": float(tail["stock"].mean()),
        "stock_max_abs_delta_last_tail": float(stock_delta.max()),
        "young_owner_25_34_avg_last_tail": float(tail["young_owner_25_34"].mean()),
        "young_owner_25_34_max_abs_delta_last_tail": float(young_owner_delta.max()),
        "young_mortgaged_owner_25_34_avg_last_tail": float(tail["young_mortgaged_owner_25_34"].mean()),
        "young_mortgaged_owner_25_34_max_abs_delta_last_tail": float(young_mortgage_delta.max()),
        "owner_35_44_avg_last_tail": float(tail["owner_35_44"].mean()),
        "owner_35_44_max_abs_delta_last_tail": float(owner_35_44_delta.max()),
        "mortgaged_owner_35_44_avg_last_tail": float(tail["mortgaged_owner_35_44"].mean()),
        "mortgaged_owner_35_44_max_abs_delta_last_tail": float(mortgage_35_44_delta.max()),
        "max_abs_delta_any_last_tail": max_delta,
        "appears_stationary": int(max_delta < 1.0e-4),
    }


def build_checkpoint_table(combined: pd.DataFrame, checkpoints: list[int]) -> pd.DataFrame:
    baseline = combined.loc[combined["scenario"] == "baseline_d00_stock_data"].set_index("t")
    rows: list[dict[str, float | int | str]] = []
    for scenario_name, frame in combined.groupby("scenario", sort=False):
        frame = frame.set_index("t")
        for t in checkpoints:
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
                    "young_owner_25_34": float(f["young_owner_25_34"]),
                    "young_mortgaged_owner_25_34": float(f["young_mortgaged_owner_25_34"]),
                    "owner_35_44": float(f["owner_35_44"]),
                    "mortgaged_owner_35_44": float(f["mortgaged_owner_35_44"]),
                    "q_gap_vs_baseline": float(f["q"] - b["q"]),
                    "young_mortgage_gap_vs_baseline": float(
                        f["young_mortgaged_owner_25_34"] - b["young_mortgaged_owner_25_34"]
                    ),
                    "owner_35_44_gap_vs_baseline": float(f["owner_35_44"] - b["owner_35_44"]),
                }
            )
    return pd.DataFrame(rows).sort_values(["scenario", "t"]).reset_index(drop=True)


def write_note(path: Path, params: StartsStockParams, checkpoints: pd.DataFrame, stationary: pd.DataFrame) -> None:
    lines = [
        "# Annual stationary equilibrium on calibrated permits-starts-stock block",
        "",
        "This note checks whether the calibrated annual construction-flow block has a well-defined **stationary annual equilibrium** once the permanent `+5%` drift is removed.",
        "",
        "The point is to see whether the annual branch can support a genuine full-RE annual baseline instead of only finite-horizon transition exercises with an eventually binding price cap.",
        "",
        "## Setup",
        "",
        "- scenarios use the frozen annual support rules but set `price_ratio = 1.00`",
        "- construction-flow parameters stay at the calibrated Census-facing values:",
        f"  - `start_hazard = {params.start_hazard:.2f}`",
        f"  - `completion_hazard = {params.completion_hazard:.2f}`",
        f"  - permit inventory years `= {params.permit_inventory_years:.2f}`",
        f"  - under-construction inventory years `= {params.uc_inventory_years:.2f}`",
        f"- horizon: `T = {T}`",
        f"- stationarity window: last `{TAIL_WINDOW}` periods",
        "",
        "## Checkpoints",
        "",
        "| Scenario | t | q | Permits | Starts | Completions | Stock | Young mortgaged-owner 25-34 | q gap vs baseline | Young mortgage gap vs baseline |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]

    for row in checkpoints.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.q:.3f}` | `{row.permits:.3f}` | `{row.starts:.3f}` | `{row.completions:.3f}` | "
            f"`{row.stock:.3f}` | `{row.young_mortgaged_owner_25_34:.3f}` | `{row.q_gap_vs_baseline:.3f}` | `{row.young_mortgage_gap_vs_baseline:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Tail-window stationarity diagnostics",
            "",
            "| Scenario | q avg last tail | q max abs delta | Stock avg last tail | Stock max abs delta | Young mortgage 25-34 avg last tail | Young mortgage max abs delta | Max abs delta any variable | Appears stationary |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in stationary.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q_avg_last_tail:.6f}` | `{row.q_max_abs_delta_last_tail:.6g}` | "
            f"`{row.stock_avg_last_tail:.6f}` | `{row.stock_max_abs_delta_last_tail:.6g}` | "
            f"`{row.young_mortgaged_owner_25_34_avg_last_tail:.6f}` | `{row.young_mortgaged_owner_25_34_max_abs_delta_last_tail:.6g}` | "
            f"`{row.max_abs_delta_any_last_tail:.6g}` | `{int(row.appears_stationary)}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- If these no-drift paths settle numerically, the annual model has a plausible stationary annual endpoint.",
            "- That would let the paper frame full annual RE as transitions around a stationary annual equilibrium rather than as a permanently trending path with an arbitrary long-run cap.",
            "- If they do not settle, the next closure candidates are mean-reverting demand pressure or a balanced-growth stationarization, not deeper RE on the current drifting block.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()

    frames = [simulate(summary, scenario, params, T=T) for scenario in scenarios]
    combined = pd.concat(frames, ignore_index=True)
    checkpoints = build_checkpoint_table(combined, ACTIVE_CHECKPOINTS)
    stationary = pd.DataFrame([stationary_tail_summary(frame, TAIL_WINDOW) for frame in frames])

    combined.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    checkpoints.to_csv(BUILD / f"{OUTPUT_STEM}_checkpoints.csv", index=False)
    stationary.to_csv(BUILD / f"{OUTPUT_STEM}_stationary_summary.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", params, checkpoints, stationary)


if __name__ == "__main__":
    main()
