from __future__ import annotations

from pathlib import Path

import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, Scenario, load_initial_cross_section, simulate_scenario


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_vs_five_year_transition_mirror"
T = 21
DRIFT = 1.05
CHECKPOINTS = (0, 2, 5, 10, 20)
FIVE_YEAR_CHECKPOINTS = (0, 5, 10, 20)


def build_scenarios() -> list[Scenario]:
    return [
        Scenario("drift_baseline", DRIFT, 0.0, 0.0, 0, 0, False),
        Scenario(
            "annual_benchmark",
            DRIFT,
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
            "annual_robustness",
            DRIFT,
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


def summarize(frames: dict[str, pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame]:
    base = frames["drift_baseline"].set_index("t")
    rows: list[dict[str, float | int | str]] = []
    peaks: list[dict[str, float | int | str]] = []

    for name, frame in frames.items():
        indexed = frame.set_index("t")
        for t in CHECKPOINTS:
            row = indexed.loc[t]
            base_row = base.loc[t]
            rows.append(
                {
                    "scenario": name,
                    "t": int(t),
                    "young_owner_25_34": float(row["young_owner_share_25_34"]),
                    "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_share_25_34"]),
                    "owner_35_44": float(row["owner_share_35_44"]),
                    "mortgaged_owner_35_44": float(row["mortgaged_owner_share_35_44"]),
                    "young_owner_gap_vs_drift": float(row["young_owner_share_25_34"] - base_row["young_owner_share_25_34"]),
                    "young_mortgage_gap_vs_drift": float(
                        row["young_mortgaged_owner_share_25_34"] - base_row["young_mortgaged_owner_share_25_34"]
                    ),
                }
            )

        annual_window = indexed.loc[1:5]
        peak_idx = int(annual_window["young_mortgaged_owner_share_25_34"].idxmax())
        peak_row = indexed.loc[peak_idx]
        five_row = indexed.loc[5]
        peaks.append(
            {
                "scenario": name,
                "peak_t_within_first_five_years": peak_idx,
                "peak_young_mortgaged_owner_25_34": float(peak_row["young_mortgaged_owner_share_25_34"]),
                "t5_young_mortgaged_owner_25_34": float(five_row["young_mortgaged_owner_share_25_34"]),
                "peak_to_t5_gap": float(
                    peak_row["young_mortgaged_owner_share_25_34"] - five_row["young_mortgaged_owner_share_25_34"]
                ),
            }
        )

    return pd.DataFrame(rows), pd.DataFrame(peaks)


def write_note(path: Path, summary: pd.DataFrame, peaks: pd.DataFrame) -> None:
    lines = [
        "# Annual vs five-year transition mirror",
        "",
        "This note takes the frozen annual transition calibration and asks what a coarser five-year view would see.",
        "It does not solve a new five-year model. It samples the annual transition at five-year checkpoints to show what the coarser timing structure smooths over.",
        "",
        "## Setup",
        "",
        "- central drift environment: permanent `+5%` annual housing drift",
        "- scenarios:",
        "  - `drift_baseline`",
        "  - `annual_benchmark`: qualification `0.25`, family help `0.15`",
        "  - `annual_robustness`: qualification `0.40`, family help `0.30`",
        "- annual checkpoints reported: `t = 0, 2, 5, 10, 20`",
        "- five-year mirror checkpoints: `t = 0, 5, 10, 20`",
        "",
    ]

    for scenario in summary["scenario"].drop_duplicates():
        sub = summary.loc[summary["scenario"] == scenario]
        lines.extend(
            [
                f"## `{scenario}`",
                "",
                "| t | Young owner 25-34 | Young mortgaged-owner 25-34 | Owner 35-44 | Mortgaged-owner 35-44 | Young owner gap vs drift | Young mortgage gap vs drift |",
                "|---:|---:|---:|---:|---:|---:|---:|",
            ]
        )
        for row in sub.itertuples(index=False):
            lines.append(
                f"| {row.t} | {row.young_owner_25_34:.3f} | {row.young_mortgaged_owner_25_34:.3f} | "
                f"{row.owner_35_44:.3f} | {row.mortgaged_owner_35_44:.3f} | "
                f"{row.young_owner_gap_vs_drift:.3f} | {row.young_mortgage_gap_vs_drift:.3f} |"
            )
        lines.append("")

    lines.extend(
        [
            "## What the five-year mirror smooths over",
            "",
            "Five-year checkpoints only see `t = 0, 5, 10, 20`.",
            "That means they miss the within-window annual path in the early housing-access crunch years.",
            "",
            "| Scenario | Peak t inside years 1-5 | Peak young mortgaged-owner 25-34 | t=5 young mortgaged-owner 25-34 | Peak minus t=5 |",
            "|---|---:|---:|---:|---:|",
        ]
    )
    for row in peaks.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.peak_t_within_first_five_years} | {row.peak_young_mortgaged_owner_25_34:.3f} | "
            f"{row.t5_young_mortgaged_owner_25_34:.3f} | {row.peak_to_t5_gap:.3f} |"
        )

    benchmark_t2 = summary.loc[
        (summary["scenario"] == "annual_benchmark") & (summary["t"] == 2),
        "young_mortgage_gap_vs_drift",
    ].iloc[0]
    benchmark_t5 = summary.loc[
        (summary["scenario"] == "annual_benchmark") & (summary["t"] == 5),
        "young_mortgage_gap_vs_drift",
    ].iloc[0]
    robustness_t2 = summary.loc[
        (summary["scenario"] == "annual_robustness") & (summary["t"] == 2),
        "young_mortgage_gap_vs_drift",
    ].iloc[0]
    robustness_t5 = summary.loc[
        (summary["scenario"] == "annual_robustness") & (summary["t"] == 5),
        "young_mortgage_gap_vs_drift",
    ].iloc[0]

    lines.extend(
        [
            "",
            "## Read",
            "",
            f"- In the annual benchmark path, the young mortgaged-owner gain versus drift is already `{benchmark_t2:+.3f}` by `t = 2` and reaches `{benchmark_t5:+.3f}` by `t = 5`.",
            f"- In the annual robustness path, that same gain is `{robustness_t2:+.3f}` by `t = 2` and `{robustness_t5:+.3f}` by `t = 5`.",
            "- So the coarser five-year view gets the direction right, but it compresses the first few years of adjustment into one block.",
            "- That is the main lesson: the annual branch is most informative about the early housing-access crunch, while the five-year branch is better for longer-run equilibrium logic.",
            "- In terms of mechanisms, the annual transition still says:",
            "  - help-to-buy / qualification does most of the work",
            "  - family deposit help is an amplifier",
            "  - rising prices / drift are the background pressure that makes those entry margins matter",
        ]
    )

    path = path
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    summary = load_initial_cross_section(INPUT_SUMMARY)
    frames = {scenario.name: simulate_scenario(summary, scenario, T=T) for scenario in build_scenarios()}
    table, peaks = summarize(frames)

    table.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    peaks.to_csv(BUILD / f"{OUTPUT_STEM}_peaks.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", table, peaks)


if __name__ == "__main__":
    main()
