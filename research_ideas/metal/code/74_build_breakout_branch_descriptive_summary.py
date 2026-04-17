from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
COUNTRY_GENRE_DIR = PROJECT_ROOT / "data" / "processed" / "country_genre_analysis"

PANEL_PATH = COUNTRY_GENRE_DIR / "city_genre_breakout_event_panel.csv"
CAPABILITY_PATH = COUNTRY_GENRE_DIR / "city_genre_breakout_capability.csv"

OUTPUT_EVENT_TIME_PATH = COUNTRY_GENRE_DIR / "breakout_branch_descriptive_event_time.csv"
OUTPUT_EVENT_SUMMARY_PATH = COUNTRY_GENRE_DIR / "breakout_branch_descriptive_event_summary.csv"
OUTPUT_SUMMARY_PATH = COUNTRY_GENRE_DIR / "breakout_branch_descriptive_summary.md"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build descriptive summaries for the breakout-event branch.")
    parser.add_argument("--panel-path", type=Path, default=PANEL_PATH, help="Input stacked event panel CSV.")
    parser.add_argument(
        "--capability-path",
        type=Path,
        default=CAPABILITY_PATH,
        help="Input pre-shock capability CSV.",
    )
    parser.add_argument(
        "--output-event-time-path",
        type=Path,
        default=OUTPUT_EVENT_TIME_PATH,
        help="Output event-time summary CSV.",
    )
    parser.add_argument(
        "--output-event-summary-path",
        type=Path,
        default=OUTPUT_EVENT_SUMMARY_PATH,
        help="Output event-level summary CSV.",
    )
    parser.add_argument(
        "--output-summary-path",
        type=Path,
        default=OUTPUT_SUMMARY_PATH,
        help="Output markdown summary.",
    )
    return parser.parse_args()


def load_branch_data(panel_path: Path, capability_path: Path) -> pd.DataFrame:
    panel = pd.read_csv(panel_path)
    capability = pd.read_csv(capability_path)[
        [
            "event_id",
            "city_country",
            "pre_shock_capability_score",
            "pre_shock_subthreshold_i",
        ]
    ].copy()
    capability["capability_group"] = capability["pre_shock_capability_score"].gt(0).map(
        {True: "positive_capability", False: "zero_capability"}
    )
    merged = panel.merge(capability, on=["event_id", "city_country"], how="left")
    return merged.loc[merged["pre_shock_subthreshold_i"].eq(1)].copy()


def build_event_time_summary(sample: pd.DataFrame) -> pd.DataFrame:
    summary = (
        sample.groupby(["relative_event_year", "capability_group"], as_index=False)
        .agg(
            city_event_cells=("city_country", "size"),
            mean_local_genre_band_starts=("local_genre_band_starts", "mean"),
            mean_local_genre_active_bands=("local_genre_active_bands", "mean"),
            emergence_rate=("emerge_this_year_i", "mean"),
        )
        .sort_values(["relative_event_year", "capability_group"])
        .reset_index(drop=True)
    )
    return summary


def summarize_period(frame: pd.DataFrame, start_year: int, end_year: int, outcome: str) -> float:
    subset = frame.loc[frame["relative_event_year"].between(start_year, end_year), outcome]
    if subset.empty:
        return 0.0
    return float(subset.mean())


def build_event_summary(sample: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for (event_id, capability_group), frame in sample.groupby(["event_id", "capability_group"]):
        rows.append(
            {
                "event_id": event_id,
                "capability_group": capability_group,
                "city_count": int(frame["city_country"].nunique()),
                "pre_mean_band_starts": summarize_period(frame, -5, -1, "local_genre_band_starts"),
                "post_mean_band_starts": summarize_period(frame, 0, 5, "local_genre_band_starts"),
                "pre_mean_active_bands": summarize_period(frame, -5, -1, "local_genre_active_bands"),
                "post_mean_active_bands": summarize_period(frame, 0, 5, "local_genre_active_bands"),
                "post_mean_emergence_rate": summarize_period(frame, 0, 5, "emerge_this_year_i"),
            }
        )
    return pd.DataFrame(rows).sort_values(["event_id", "capability_group"]).reset_index(drop=True)


def write_summary(event_time: pd.DataFrame, event_summary: pd.DataFrame, output_summary_path: Path) -> None:
    positive_cities = int(
        event_summary.loc[event_summary["capability_group"].eq("positive_capability"), "city_count"].sum()
    )
    zero_cities = int(
        event_summary.loc[event_summary["capability_group"].eq("zero_capability"), "city_count"].sum()
    )
    event_count = int(event_summary["event_id"].nunique())
    dominant_row = (
        event_summary.loc[event_summary["capability_group"].eq("positive_capability")]
        .sort_values(["city_count", "event_id"], ascending=[False, True])
        .iloc[0]
    )

    positive_time = event_time.loc[event_time["capability_group"].eq("positive_capability")].copy()
    zero_time = event_time.loc[event_time["capability_group"].eq("zero_capability")].copy()

    pre_positive_starts = summarize_period(positive_time, -5, -1, "mean_local_genre_band_starts")
    pre_zero_starts = summarize_period(zero_time, -5, -1, "mean_local_genre_band_starts")
    post_positive_starts = summarize_period(positive_time, 0, 5, "mean_local_genre_band_starts")
    post_zero_starts = summarize_period(zero_time, 0, 5, "mean_local_genre_band_starts")

    lines: list[str] = []
    lines.append("# Breakout branch descriptive summary")
    lines.append("")
    lines.append("- Sample: pre-shock-subthreshold cities only.")
    lines.append("- Capability split used here: `positive_capability` (`pre_shock_capability_score > 0`) versus `zero_capability`.")
    lines.append(f"- Retained events in stack: `{event_count}`")
    lines.append(f"- Positive-capability city-event cells at `t = -1`: `{positive_cities}`")
    lines.append(f"- Zero-capability city-event cells at `t = -1`: `{zero_cities}`")
    lines.append("")
    lines.append("## Key read")
    lines.append("")
    lines.append(
        f"- The branch is still extremely thin on the treated margin. Positive-capability cities total only "
        f"`{positive_cities}` city-event cells across the full `{event_count}`-event stack, versus `{zero_cities}` zero-capability cells."
    )
    lines.append(
        f"- The pre-trend concern is real. Mean local same-genre band starts are already "
        f"`{pre_positive_starts:.4f}` for positive-capability cities in event years `-5` to `-1`, "
        f"versus `{pre_zero_starts:.4f}` for zero-capability cities."
    )
    lines.append(
        f"- The post-period difference remains large, but it is not cleanly a breakout effect: "
        f"`{post_positive_starts:.4f}` versus `{post_zero_starts:.4f}` in event years `0` to `+5`."
    )
    lines.append(
        f"- One event dominates the positive-capability margin: `{dominant_row['event_id']}` contributes "
        f"`{int(dominant_row['city_count'])}` positive-capability cities by itself."
    )
    lines.append("")
    lines.append("## Workflow implication")
    lines.append("")
    lines.append(
        "- Under the branch workflow, this is not yet a green light for event-study estimation. "
        "The descriptive evidence still points to thin support, strong pre-existing differences, and partial single-event dependence."
    )
    lines.append(
        "- The safest current interpretation is that the branch remains a feasibility object. "
        "It should either add more first-breakout events with non-flat pre-shock capability or stop before regression."
    )

    output_summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    sample = load_branch_data(args.panel_path, args.capability_path)
    event_time = build_event_time_summary(sample)
    event_summary = build_event_summary(sample)

    args.output_event_time_path.parent.mkdir(parents=True, exist_ok=True)
    event_time.to_csv(args.output_event_time_path, index=False)
    event_summary.to_csv(args.output_event_summary_path, index=False)
    write_summary(event_time, event_summary, args.output_summary_path)

    print(f"Wrote {args.output_event_time_path}")
    print(f"Wrote {args.output_event_summary_path}")
    print(f"Wrote {args.output_summary_path}")


if __name__ == "__main__":
    main()
