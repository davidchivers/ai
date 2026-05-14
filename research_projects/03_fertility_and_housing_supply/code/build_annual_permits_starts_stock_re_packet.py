from __future__ import annotations

from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

K_VALUES = [3, 5, 20]
CHECKPOINTS = [5, 10, 20]


def load_checkpoint_frame(k: int) -> pd.DataFrame:
    path = BUILD / f"annual_{k}_step_re_permits_starts_stock_calibrated_checkpoints.csv"
    if not path.exists():
        raise FileNotFoundError(f"Missing checkpoint file: {path}")
    frame = pd.read_csv(path).copy()
    return frame.assign(k=k)


def load_fixed_point_frame(k: int) -> pd.DataFrame:
    path = BUILD / f"annual_{k}_step_re_permits_starts_stock_calibrated_fixed_points.csv"
    if not path.exists():
        raise FileNotFoundError(f"Missing fixed-point file: {path}")
    frame = pd.read_csv(path).copy()
    return frame.assign(k=k)


def scenario_sort_key(name: str) -> tuple[int, str]:
    order = {
        "baseline_d05_stock_data": 0,
        "benchmark_d05_stock_data": 1,
        "robustness_d05_stock_data": 2,
    }
    return (order.get(name, 99), name)


def write_note(summary: pd.DataFrame, fixed_points: pd.DataFrame, out_path: Path) -> None:
    def fmt_level(value: float) -> str:
        return " " if pd.isna(value) else f"`{value:.3f}`"

    lines = [
        "# Annual permits-starts-stock RE packet",
        "",
        "This note consolidates the calibrated annual construction-flow RE runs used for the current annual full-RE handoff packet.",
        "",
        "Included horizons:",
        "",
        "- `k = 3` main bounded-RE case",
        "- `k = 5` aggressive robustness case",
        "- `k = 20` full active-horizon stress test",
        "",
        "## Fixed-point price path excerpts",
        "",
        "| Scenario | k | q1 | q5 | q10 | q20 |",
        "|---|---:|---:|---:|---:|---:|",
    ]

    for _, row in fixed_points.iterrows():
        lines.append(
            f"| `{row['scenario']}` | `{int(row['k'])}` | {fmt_level(row['q1'])} | "
            f"{fmt_level(row['q5'])} | {fmt_level(row['q10'])} | {fmt_level(row['q20'])} |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to the calibrated non-RE anchor",
            "",
            "| Scenario | k | t | q | q gap vs anchor | Young mortgaged-owner 25-34 | Young mortgage gap vs anchor |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for _, row in summary.iterrows():
        lines.append(
            f"| `{row['scenario']}` | `{int(row['k'])}` | `{int(row['t'])}` | `{row['q']:.3f}` | "
            f"`{row['q_gap_vs_stock_anchor']:.3f}` | `{row['young_mortgaged_owner_25_34']:.3f}` | "
            f"`{row['young_mortgage_gap_vs_stock_anchor']:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- The calibrated construction-flow block keeps the annual RE solve numerically tame even at long bounded horizons.",
            "- Moving from `k = 3` to `k = 5` and `k = 20` mainly increases the price premium relative to the non-RE anchor.",
            "- Ownership composition changes stay modest; the young mortgaged-owner gap is small by `t = 5` and essentially zero by `t = 20`.",
            "- So the live paper hierarchy remains:",
            "  - `k = 3` main text",
            "  - `k = 5` robustness",
            "  - `k = 20` appendix / technical feasibility note only",
        ]
    )

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    checkpoint_frames = [load_checkpoint_frame(k) for k in K_VALUES]
    fixed_point_frames = [load_fixed_point_frame(k) for k in K_VALUES]

    checkpoints = pd.concat(checkpoint_frames, ignore_index=True)
    fixed_points = pd.concat(fixed_point_frames, ignore_index=True)

    summary = checkpoints.loc[checkpoints["t"].isin(CHECKPOINTS)].copy()
    summary = summary.sort_values(
        by=["scenario", "k", "t"],
        key=lambda col: col.map(scenario_sort_key) if col.name == "scenario" else col,
    ).reset_index(drop=True)

    fixed_rows = []
    for _, row in fixed_points.iterrows():
        fixed_rows.append(
            {
                "scenario": row["scenario"],
                "k": int(row["k"]),
                "q1": float(row.get("q1_re", row.get("q1", float("nan")))),
                "q5": float(row.get("q5_re", float("nan"))),
                "q10": float(row.get("q10_re", float("nan"))),
                "q20": float(row.get("q20_re", float("nan"))),
            }
        )
    fixed_summary = pd.DataFrame(fixed_rows)
    fixed_summary = fixed_summary.sort_values(
        by=["scenario", "k"],
        key=lambda col: col.map(scenario_sort_key) if col.name == "scenario" else col,
    ).reset_index(drop=True)

    summary.to_csv(BUILD / "annual_permits_starts_stock_re_packet.csv", index=False)
    fixed_summary.to_csv(BUILD / "annual_permits_starts_stock_re_packet_fixed_points.csv", index=False)
    write_note(summary, fixed_summary, BUILD / "annual_permits_starts_stock_re_packet.md")


if __name__ == "__main__":
    main()
