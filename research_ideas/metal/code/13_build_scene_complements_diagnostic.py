from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
OUTPUT_DIR = PROCESSED_DIR / "country_genre_analysis"

FAMILY_PANEL_PATH = OUTPUT_DIR / "country_genre_family_year_panel.csv"
COUNTRY_YEAR_PATH = PROCESSED_DIR / "metal_archives_all_metal_country_year_panel.csv"
PILOT_CASES_PATH = OUTPUT_DIR / "domestic_success_pilot_cases.csv"
EVENT_WINDOWS_PATH = OUTPUT_DIR / "domestic_success_pilot_event_windows.csv"

CASE_YEARS_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_scene_complements_case_years.csv"
CASE_METRICS_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_scene_complements_case_metrics.csv"
RANKING_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_scene_complements_rankings.csv"
SUMMARY_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_scene_complements_summary.md"
FIGURE_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_scene_complements_scatter.png"

PRE_WINDOW_YEARS = 3
TREND_WINDOW_YEARS = 5


def safe_share(numerator: pd.Series, denominator: pd.Series) -> pd.Series:
    numerator = pd.to_numeric(numerator, errors="coerce").fillna(0.0).astype(float)
    denominator = pd.to_numeric(denominator, errors="coerce").fillna(0.0).astype(float)
    return pd.Series(
        np.where(denominator > 0, numerator / denominator, np.nan),
        index=numerator.index,
        dtype="float64",
    )


def compute_slope(frame: pd.DataFrame, value_column: str) -> float:
    usable = frame.loc[frame[value_column].notna(), ["year", value_column]].copy()
    usable = usable.dropna()
    if usable.shape[0] < 2:
        return float("nan")
    x = usable["year"].astype(float).to_numpy()
    y = usable[value_column].astype(float).to_numpy()
    if np.allclose(x, x[0]):
        return float("nan")
    return float(np.polyfit(x, y, deg=1)[0])


def percentile_score(values: pd.Series) -> pd.Series:
    ranked = values.rank(method="average", pct=True)
    if ranked.notna().any():
        return ranked.astype(float)
    return pd.Series(np.nan, index=values.index, dtype="float64")


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    family_panel = pd.read_csv(FAMILY_PANEL_PATH).fillna(pd.NA)
    country_year = pd.read_csv(COUNTRY_YEAR_PATH).fillna(pd.NA)
    pilot_cases = pd.read_csv(PILOT_CASES_PATH).fillna(pd.NA)
    event_windows = pd.read_csv(EVENT_WINDOWS_PATH).fillna(pd.NA)

    family_panel["entry_year"] = pd.to_numeric(family_panel["entry_year"], errors="coerce").astype(int)
    for column in [
        "bands_started",
        "bands_started_unsigned",
        "bands_started_signed",
        "all_metal_bands_started",
        "all_metal_bands_started_unsigned",
        "all_metal_bands_started_signed",
        "genre_share_of_country_year",
        "genre_share_of_country_year_unsigned",
        "genre_share_of_country_year_signed",
    ]:
        family_panel[column] = pd.to_numeric(family_panel[column], errors="coerce")

    for column in [
        "year",
        "bands_formed_all_metal_ct",
        "bands_formed_all_metal_unsigned_ct",
        "bands_formed_all_metal_signed_ct",
    ]:
        country_year[column] = pd.to_numeric(country_year[column], errors="coerce")

    pilot_cases["domestic_success_year"] = pd.to_numeric(
        pilot_cases["domestic_success_year"], errors="coerce"
    ).astype("Int64")

    return family_panel, country_year, pilot_cases, event_windows


def build_case_years(
    family_panel: pd.DataFrame,
    country_year: pd.DataFrame,
    pilot_cases: pd.DataFrame,
) -> pd.DataFrame:
    family_world = (
        family_panel.groupby(["genre_family", "entry_year"], as_index=False)[
            ["bands_started", "bands_started_unsigned", "bands_started_signed"]
        ]
        .sum()
        .rename(
            columns={
                "entry_year": "year",
                "bands_started": "world_genre_bands_started",
                "bands_started_unsigned": "world_genre_bands_started_unsigned",
                "bands_started_signed": "world_genre_bands_started_signed",
            }
        )
    )
    world_totals = (
        country_year.groupby("year", as_index=False)[
            [
                "bands_formed_all_metal_ct",
                "bands_formed_all_metal_unsigned_ct",
                "bands_formed_all_metal_signed_ct",
            ]
        ]
        .sum()
        .rename(
            columns={
                "bands_formed_all_metal_ct": "world_all_metal_bands_started",
                "bands_formed_all_metal_unsigned_ct": "world_all_metal_bands_started_unsigned",
                "bands_formed_all_metal_signed_ct": "world_all_metal_bands_started_signed",
            }
        )
    )

    country_totals = country_year[
        [
            "countryiso3code",
            "country_name",
            "year",
            "bands_formed_all_metal_ct",
            "bands_formed_all_metal_unsigned_ct",
            "bands_formed_all_metal_signed_ct",
        ]
    ].copy()

    family_counts = family_panel[
        [
            "countryiso3code",
            "country_std",
            "entry_year",
            "genre_family",
            "bands_started",
            "bands_started_unsigned",
            "bands_started_signed",
        ]
    ].copy().rename(columns={"entry_year": "year"})

    case_frames: list[pd.DataFrame] = []
    for case in pilot_cases.itertuples(index=False):
        if pd.isna(case.domestic_success_year):
            continue

        hit_year = int(case.domestic_success_year)
        country_years = country_totals.loc[
            country_totals["countryiso3code"].eq(case.countryiso3code), "year"
        ].dropna()
        if country_years.empty:
            continue

        start_year = int(country_years.min())
        year_frame = pd.DataFrame({"year": list(range(start_year, hit_year + 1))})
        year_frame["pilot_case_id"] = case.pilot_case_id
        year_frame["countryiso3code"] = case.countryiso3code
        year_frame["country_name"] = case.country_name
        year_frame["genre_family"] = case.genre_family
        year_frame["artist_name"] = case.artist_name
        year_frame["release_or_track_name"] = case.release_or_track_name
        year_frame["domestic_success_year"] = hit_year
        year_frame["event_type"] = case.event_type
        year_frame["event_tier"] = case.event_tier
        year_frame["source_tier"] = case.source_tier
        year_frame["source_name"] = case.source_name

        case_totals = country_totals.loc[
            country_totals["countryiso3code"].eq(case.countryiso3code)
        ].copy()
        case_family = family_counts.loc[
            family_counts["countryiso3code"].eq(case.countryiso3code)
            & family_counts["genre_family"].eq(case.genre_family)
        ].copy()

        case_frame = (
            year_frame.merge(case_totals, on=["countryiso3code", "country_name", "year"], how="left")
            .merge(case_family, on=["countryiso3code", "genre_family", "year"], how="left")
            .merge(family_world, on=["genre_family", "year"], how="left")
            .merge(world_totals, on="year", how="left")
        )

        fill_zero_columns = [
            "bands_formed_all_metal_ct",
            "bands_formed_all_metal_unsigned_ct",
            "bands_formed_all_metal_signed_ct",
            "bands_started",
            "bands_started_unsigned",
            "bands_started_signed",
            "world_genre_bands_started",
            "world_genre_bands_started_unsigned",
            "world_genre_bands_started_signed",
            "world_all_metal_bands_started",
            "world_all_metal_bands_started_unsigned",
            "world_all_metal_bands_started_signed",
        ]
        case_frame[fill_zero_columns] = case_frame[fill_zero_columns].fillna(0.0)

        case_frame["country_genre_share_all"] = safe_share(
            case_frame["bands_started"], case_frame["bands_formed_all_metal_ct"]
        )
        case_frame["country_genre_share_unsigned"] = safe_share(
            case_frame["bands_started_unsigned"],
            case_frame["bands_formed_all_metal_unsigned_ct"],
        )
        case_frame["country_genre_share_signed"] = safe_share(
            case_frame["bands_started_signed"],
            case_frame["bands_formed_all_metal_signed_ct"],
        )

        case_frame["rest_genre_bands_started_all"] = (
            case_frame["world_genre_bands_started"] - case_frame["bands_started"]
        )
        case_frame["rest_genre_bands_started_unsigned"] = (
            case_frame["world_genre_bands_started_unsigned"] - case_frame["bands_started_unsigned"]
        )
        case_frame["rest_genre_bands_started_signed"] = (
            case_frame["world_genre_bands_started_signed"] - case_frame["bands_started_signed"]
        )
        case_frame["rest_all_metal_bands_started_all"] = (
            case_frame["world_all_metal_bands_started"] - case_frame["bands_formed_all_metal_ct"]
        )
        case_frame["rest_all_metal_bands_started_unsigned"] = (
            case_frame["world_all_metal_bands_started_unsigned"]
            - case_frame["bands_formed_all_metal_unsigned_ct"]
        )
        case_frame["rest_all_metal_bands_started_signed"] = (
            case_frame["world_all_metal_bands_started_signed"]
            - case_frame["bands_formed_all_metal_signed_ct"]
        )

        case_frame["rest_genre_share_all"] = safe_share(
            case_frame["rest_genre_bands_started_all"],
            case_frame["rest_all_metal_bands_started_all"],
        )
        case_frame["rest_genre_share_unsigned"] = safe_share(
            case_frame["rest_genre_bands_started_unsigned"],
            case_frame["rest_all_metal_bands_started_unsigned"],
        )
        case_frame["rest_genre_share_signed"] = safe_share(
            case_frame["rest_genre_bands_started_signed"],
            case_frame["rest_all_metal_bands_started_signed"],
        )

        case_frame["share_gap_all"] = (
            case_frame["country_genre_share_all"] - case_frame["rest_genre_share_all"]
        )
        case_frame["share_gap_unsigned"] = (
            case_frame["country_genre_share_unsigned"] - case_frame["rest_genre_share_unsigned"]
        )
        case_frame["share_gap_signed"] = (
            case_frame["country_genre_share_signed"] - case_frame["rest_genre_share_signed"]
        )
        case_frame["relative_year"] = case_frame["year"] - hit_year

        case_frames.append(case_frame)

    return pd.concat(case_frames, ignore_index=True).sort_values(
        ["pilot_case_id", "year"]
    ).reset_index(drop=True)


def classify_case(depth_score: float, growth_score: float) -> str:
    if pd.isna(depth_score) or pd.isna(growth_score):
        return "mixed"
    if depth_score >= 0.6 and growth_score < 0.5:
        return "mature_scene_milestone_candidate"
    if growth_score >= 0.6 and depth_score < 0.6:
        return "rising_scene_breakthrough_candidate"
    if depth_score >= 0.6 and growth_score >= 0.6:
        return "deep_and_still_thickening"
    return "mixed"


def build_case_metrics(case_years: pd.DataFrame, event_windows: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for case_id, frame in case_years.groupby("pilot_case_id", sort=True):
        frame = frame.sort_values("year").reset_index(drop=True)
        hit_year = int(frame["domestic_success_year"].iloc[0])
        pre_window = frame.loc[frame["year"].between(hit_year - PRE_WINDOW_YEARS, hit_year - 1)].copy()
        trend_window = frame.loc[frame["year"].between(hit_year - TREND_WINDOW_YEARS, hit_year - 1)].copy()
        pre_positive = frame.loc[(frame["year"] <= hit_year) & frame["bands_started"].gt(0)].copy()
        first_observed_year = int(pre_positive["year"].min()) if not pre_positive.empty else pd.NA
        pre_peak = frame.loc[frame["year"].lt(hit_year)].copy()
        if not pre_peak.empty:
            pre_peak_idx = pre_peak["bands_started"].astype(float).idxmax()
            pre_peak_year = int(pre_peak.loc[pre_peak_idx, "year"])
            pre_peak_count = float(pre_peak.loc[pre_peak_idx, "bands_started"])
        else:
            pre_peak_year = pd.NA
            pre_peak_count = np.nan

        event_row = frame.loc[frame["year"].eq(hit_year)].copy()
        event_all_count = float(event_row["bands_started"].iloc[0]) if not event_row.empty else np.nan
        event_unsigned_count = (
            float(event_row["bands_started_unsigned"].iloc[0]) if not event_row.empty else np.nan
        )

        rows.append(
            {
                "pilot_case_id": case_id,
                "countryiso3code": frame["countryiso3code"].iloc[0],
                "country_name": frame["country_name"].iloc[0],
                "genre_family": frame["genre_family"].iloc[0],
                "artist_name": frame["artist_name"].iloc[0],
                "release_or_track_name": frame["release_or_track_name"].iloc[0],
                "domestic_success_year": hit_year,
                "event_type": frame["event_type"].iloc[0],
                "event_tier": frame["event_tier"].iloc[0],
                "source_tier": frame["source_tier"].iloc[0],
                "source_name": frame["source_name"].iloc[0],
                "first_observed_year": first_observed_year,
                "years_since_first_observed": (
                    float(hit_year - first_observed_year) if first_observed_year is not pd.NA else np.nan
                ),
                "pre_peak_year": pre_peak_year,
                "years_since_pre_peak": (
                    float(hit_year - pre_peak_year) if pre_peak_year is not pd.NA else np.nan
                ),
                "pre_peak_all_count": pre_peak_count,
                "event_year_all_count": event_all_count,
                "event_year_unsigned_count": event_unsigned_count,
                "pre_all_count_slope_5y": compute_slope(trend_window, "bands_started"),
                "pre_unsigned_count_slope_5y": compute_slope(trend_window, "bands_started_unsigned"),
                "pre_share_gap_all_slope_5y": compute_slope(trend_window, "share_gap_all"),
                "pre_share_gap_unsigned_slope_5y": compute_slope(trend_window, "share_gap_unsigned"),
                "pre_window_year_count": int(pre_window.shape[0]),
            }
        )

    metrics = pd.DataFrame(rows)
    metrics = metrics.merge(
        event_windows[
            [
                "pilot_case_id",
                "pre_all_count_mean",
                "pre_unsigned_count_mean",
                "pre_signed_count_mean",
                "pre_share_gap_all_mean",
                "pre_share_gap_unsigned_mean",
                "pre_share_gap_signed_mean",
                "post_all_count_mean",
                "delta_all_count_mean",
                "delta_share_gap_all_mean",
                "delta_share_gap_unsigned_mean",
                "delta_share_gap_signed_mean",
            ]
        ],
        on="pilot_case_id",
        how="left",
    )

    depth_components = [
        "years_since_first_observed",
        "pre_all_count_mean",
        "pre_unsigned_count_mean",
        "pre_share_gap_all_mean",
    ]
    growth_components = [
        "pre_all_count_slope_5y",
        "pre_unsigned_count_slope_5y",
        "pre_share_gap_all_slope_5y",
    ]

    for column in depth_components + growth_components:
        metrics[f"{column}_pct"] = percentile_score(metrics[column])

    metrics["scene_depth_score"] = metrics[[f"{column}_pct" for column in depth_components]].mean(axis=1)
    metrics["scene_growth_score"] = metrics[[f"{column}_pct" for column in growth_components]].mean(axis=1)
    metrics["maturity_minus_growth_score"] = (
        metrics["scene_depth_score"] - metrics["scene_growth_score"]
    )
    metrics["scene_complements_label"] = metrics.apply(
        lambda row: classify_case(
            depth_score=float(row["scene_depth_score"]),
            growth_score=float(row["scene_growth_score"]),
        ),
        axis=1,
    )

    metrics["late_coding_heuristic_rank"] = (
        metrics["maturity_minus_growth_score"].rank(method="first", ascending=False).astype(int)
    )

    return metrics.sort_values("late_coding_heuristic_rank").reset_index(drop=True)


def plot_case_scatter(metrics: pd.DataFrame) -> None:
    label_colors = {
        "mature_scene_milestone_candidate": "#c92a2a",
        "rising_scene_breakthrough_candidate": "#2b8a3e",
        "deep_and_still_thickening": "#1c7ed6",
        "mixed": "#495057",
    }

    fig, ax = plt.subplots(figsize=(9.5, 6))
    for label, frame in metrics.groupby("scene_complements_label", sort=False):
        ax.scatter(
            frame["scene_depth_score"],
            frame["scene_growth_score"],
            s=90,
            alpha=0.9,
            color=label_colors.get(label, "#495057"),
            label=label.replace("_", " "),
        )
        for row in frame.itertuples(index=False):
            short_label = f"{row.artist_name} ({row.countryiso3code})"
            ax.text(
                float(row.scene_depth_score) + 0.012,
                float(row.scene_growth_score) + 0.012,
                short_label,
                fontsize=8.5,
            )

    ax.axvline(0.6, color="black", linewidth=0.8, alpha=0.25, linestyle="--")
    ax.axhline(0.6, color="black", linewidth=0.8, alpha=0.25, linestyle="--")
    ax.set_xlim(0, 1.05)
    ax.set_ylim(0, 1.05)
    ax.set_xlabel("Scene depth score before coded breakout")
    ax.set_ylabel("Pre-breakthrough growth score")
    ax.set_title("Domestic-success pilot: scene depth versus pre-breakthrough growth", weight="bold")
    ax.grid(alpha=0.2, linewidth=0.6)
    ax.legend(frameon=False, fontsize=8.5)

    note = (
        "Scores are percentile-rank heuristics within the 10 current pilot cases.\n"
        "High depth plus low growth is suggestive of a mature-scene milestone rather than a clean first shock."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=8.5)
    fig.tight_layout(rect=(0, 0.06, 1, 1))
    fig.savefig(FIGURE_OUTPUT_PATH, dpi=200)
    plt.close(fig)


def build_summary(metrics: pd.DataFrame) -> str:
    top_maturity = metrics.nlargest(3, "maturity_minus_growth_score")[
        [
            "country_name",
            "genre_family",
            "artist_name",
            "domestic_success_year",
            "scene_depth_score",
            "scene_growth_score",
            "scene_complements_label",
        ]
    ].copy()
    for column in ["scene_depth_score", "scene_growth_score"]:
        top_maturity[column] = top_maturity[column].astype(float).round(3)

    top_growth = metrics.nlargest(3, "scene_growth_score")[
        [
            "country_name",
            "genre_family",
            "artist_name",
            "domestic_success_year",
            "pre_all_count_slope_5y",
            "pre_unsigned_count_slope_5y",
            "pre_share_gap_all_slope_5y",
            "scene_complements_label",
        ]
    ].copy()
    for column in [
        "pre_all_count_slope_5y",
        "pre_unsigned_count_slope_5y",
        "pre_share_gap_all_slope_5y",
    ]:
        top_growth[column] = top_growth[column].astype(float).round(3)

    metrics_table = metrics[
        [
            "country_name",
            "genre_family",
            "artist_name",
            "domestic_success_year",
            "first_observed_year",
            "years_since_first_observed",
            "pre_all_count_mean",
            "pre_unsigned_count_mean",
            "pre_share_gap_all_mean",
            "pre_all_count_slope_5y",
            "scene_depth_score",
            "scene_growth_score",
            "scene_complements_label",
        ]
    ].copy()
    for column in [
        "years_since_first_observed",
        "pre_all_count_mean",
        "pre_unsigned_count_mean",
        "pre_share_gap_all_mean",
        "pre_all_count_slope_5y",
        "scene_depth_score",
        "scene_growth_score",
    ]:
        metrics_table[column] = metrics_table[column].astype(float).round(3)

    mature_ct = int(metrics["scene_complements_label"].eq("mature_scene_milestone_candidate").sum())
    thickening_ct = int(metrics["scene_complements_label"].eq("deep_and_still_thickening").sum())
    rising_ct = int(metrics["scene_complements_label"].eq("rising_scene_breakthrough_candidate").sum())
    mixed_ct = int(metrics["scene_complements_label"].eq("mixed").sum())

    return "\n".join(
        [
            "# Scene-complements diagnostic",
            "",
            "## Purpose",
            "",
            "This pass treats the current domestic-success pilot as a scene-thickening diagnostic rather than only as a post-breakthrough shock design.",
            "It asks whether the coded breakout rows already look like deep or rising scenes before the event year.",
            "",
            "## Diagnostic scope",
            "",
            f"- Pilot cases: `{metrics.shape[0]}`",
            f"- Pre-window definition: `t-{PRE_WINDOW_YEARS}` to `t-1`",
            f"- Trend window definition: `t-{TREND_WINDOW_YEARS}` to `t-1`",
            "- Heuristic scores are percentile-rank summaries within the current treated-case set, not causal estimates.",
            "",
            "## First read",
            "",
            f"- Mature-scene milestone candidates: `{mature_ct}`",
            f"- Deep-and-still-thickening cases: `{thickening_ct}`",
            f"- Rising-scene breakthrough candidates: `{rising_ct}`",
            f"- Mixed cases: `{mixed_ct}`",
            "- Practical interpretation:",
            "  if a case has high scene depth before the coded event and weak pre-breakthrough growth, it is more likely to be a late-coded scene milestone than a clean domestic shock.",
            "",
            "## Highest maturity-minus-growth cases",
            "",
            top_maturity.to_markdown(index=False),
            "",
            "## Strongest pre-breakthrough growth cases",
            "",
            top_growth.to_markdown(index=False),
            "",
            "## All case metrics",
            "",
            metrics_table.to_markdown(index=False),
            "",
            "## Interpretation",
            "",
            "This is a bounded diagnostic pass, not a final breakout-prediction design.",
            "It does not use an exhaustive audited treatment file for untreated country-genre cells, so it should not yet be read as a true hazard model of breakout success.",
            "Its immediate use is to rank the current pilot rows by how compatible they are with a scene-complements story and to identify which rows are weakest for the original post-breakthrough shock design.",
            "",
            "## Outputs",
            "",
            f"- `{CASE_YEARS_OUTPUT_PATH.name}`",
            f"- `{CASE_METRICS_OUTPUT_PATH.name}`",
            f"- `{RANKING_OUTPUT_PATH.name}`",
            f"- `{FIGURE_OUTPUT_PATH.name}`",
        ]
    )


def main() -> None:
    family_panel, country_year, pilot_cases, event_windows = load_inputs()
    case_years = build_case_years(
        family_panel=family_panel,
        country_year=country_year,
        pilot_cases=pilot_cases,
    )
    metrics = build_case_metrics(case_years=case_years, event_windows=event_windows)
    rankings = metrics[
        [
            "late_coding_heuristic_rank",
            "country_name",
            "genre_family",
            "artist_name",
            "domestic_success_year",
            "years_since_first_observed",
            "pre_all_count_mean",
            "pre_unsigned_count_mean",
            "pre_share_gap_all_mean",
            "scene_depth_score",
            "scene_growth_score",
            "maturity_minus_growth_score",
            "scene_complements_label",
        ]
    ].copy()

    case_years.to_csv(CASE_YEARS_OUTPUT_PATH, index=False)
    metrics.to_csv(CASE_METRICS_OUTPUT_PATH, index=False)
    rankings.to_csv(RANKING_OUTPUT_PATH, index=False)
    plot_case_scatter(metrics=metrics)
    SUMMARY_OUTPUT_PATH.write_text(build_summary(metrics), encoding="utf-8")

    print(f"Wrote case-year panel to {CASE_YEARS_OUTPUT_PATH}")
    print(f"Wrote case metrics to {CASE_METRICS_OUTPUT_PATH}")
    print(f"Wrote ranking file to {RANKING_OUTPUT_PATH}")
    print(f"Wrote summary to {SUMMARY_OUTPUT_PATH}")
    print(f"Wrote figure to {FIGURE_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
