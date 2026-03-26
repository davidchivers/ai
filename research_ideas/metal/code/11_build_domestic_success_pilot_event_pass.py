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

CASE_YEARS_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_case_years.csv"
WINDOWS_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_event_windows.csv"
EVENT_STUDY_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_event_study.csv"
SUMMARY_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_event_pass_summary.md"
FIGURE_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_share_gap_event_study.png"

PRE_WINDOW_YEARS = 3
POST_WINDOW_YEARS = 3
RELATIVE_YEARS = list(range(-PRE_WINDOW_YEARS, POST_WINDOW_YEARS))

OUTCOME_SPECS = {
    "all": {
        "genre_count_column": "bands_started",
        "country_total_column": "bands_formed_all_metal_ct",
        "label": "All bands",
    },
    "unsigned": {
        "genre_count_column": "bands_started_unsigned",
        "country_total_column": "bands_formed_all_metal_unsigned_ct",
        "label": "Unsigned bands",
    },
    "signed": {
        "genre_count_column": "bands_started_signed",
        "country_total_column": "bands_formed_all_metal_signed_ct",
        "label": "Signed bands",
    },
}


def safe_share(numerator: pd.Series, denominator: pd.Series) -> pd.Series:
    numerator = pd.to_numeric(numerator, errors="coerce").fillna(0.0).astype(float)
    denominator = pd.to_numeric(denominator, errors="coerce").fillna(0.0).astype(float)
    return pd.Series(
        np.where(denominator > 0, numerator / denominator, np.nan),
        index=numerator.index,
        dtype="float64",
    )


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    family_panel = pd.read_csv(FAMILY_PANEL_PATH).fillna(pd.NA)
    country_year = pd.read_csv(COUNTRY_YEAR_PATH).fillna(pd.NA)
    pilot_cases = pd.read_csv(PILOT_CASES_PATH).fillna(pd.NA)

    family_numeric_columns = [
        "entry_year",
        "bands_started",
        "bands_started_unsigned",
        "bands_started_signed",
    ]
    for column in family_numeric_columns:
        family_panel[column] = pd.to_numeric(family_panel[column], errors="coerce")

    country_year_numeric_columns = [
        "year",
        "bands_formed_all_metal_ct",
        "bands_formed_all_metal_unsigned_ct",
        "bands_formed_all_metal_signed_ct",
    ]
    for column in country_year_numeric_columns:
        country_year[column] = pd.to_numeric(country_year[column], errors="coerce")

    pilot_cases["domestic_success_year"] = pd.to_numeric(
        pilot_cases["domestic_success_year"], errors="coerce"
    ).astype("Int64")

    return family_panel, country_year, pilot_cases


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
        year_frame = pd.DataFrame(
            {"year": list(range(hit_year - PRE_WINDOW_YEARS, hit_year + POST_WINDOW_YEARS))}
        )
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
        year_frame["relative_year"] = year_frame["year"] - hit_year

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
        case_frame[fill_zero_columns] = case_frame[fill_zero_columns].fillna(0)

        for outcome_key, spec in OUTCOME_SPECS.items():
            genre_count_column = spec["genre_count_column"]
            country_total_column = spec["country_total_column"]
            world_genre_column = f"world_{genre_count_column}"
            if outcome_key == "all":
                world_genre_column = "world_genre_bands_started"
                world_total_column = "world_all_metal_bands_started"
            elif outcome_key == "unsigned":
                world_genre_column = "world_genre_bands_started_unsigned"
                world_total_column = "world_all_metal_bands_started_unsigned"
            else:
                world_genre_column = "world_genre_bands_started_signed"
                world_total_column = "world_all_metal_bands_started_signed"

            case_frame[f"rest_genre_bands_started_{outcome_key}"] = (
                case_frame[world_genre_column] - case_frame[genre_count_column]
            )
            case_frame[f"rest_all_metal_bands_started_{outcome_key}"] = (
                case_frame[world_total_column] - case_frame[country_total_column]
            )
            case_frame[f"country_genre_share_{outcome_key}"] = safe_share(
                case_frame[genre_count_column], case_frame[country_total_column]
            )
            case_frame[f"rest_genre_share_{outcome_key}"] = safe_share(
                case_frame[f"rest_genre_bands_started_{outcome_key}"],
                case_frame[f"rest_all_metal_bands_started_{outcome_key}"],
            )
            case_frame[f"share_gap_{outcome_key}"] = (
                case_frame[f"country_genre_share_{outcome_key}"]
                - case_frame[f"rest_genre_share_{outcome_key}"]
            )

        case_frames.append(case_frame)

    case_years = pd.concat(case_frames, ignore_index=True)
    return case_years.sort_values(["pilot_case_id", "year"]).reset_index(drop=True)


def build_event_windows(case_years: pd.DataFrame) -> pd.DataFrame:
    max_year = int(case_years["year"].max())
    rows: list[dict[str, object]] = []
    for case_id, frame in case_years.groupby("pilot_case_id", sort=True):
        frame = frame.sort_values("year").reset_index(drop=True)
        hit_year = int(frame["domestic_success_year"].iloc[0])
        row: dict[str, object] = {
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
            "post_window_complete_i": int((hit_year + POST_WINDOW_YEARS - 1) <= max_year),
            "window_pre": f"{hit_year - PRE_WINDOW_YEARS}-{hit_year - 1}",
            "window_post": f"{hit_year}-{hit_year + POST_WINDOW_YEARS - 1}",
        }

        pre = frame.loc[frame["relative_year"].between(-PRE_WINDOW_YEARS, -1)].copy()
        post = frame.loc[frame["relative_year"].between(0, POST_WINDOW_YEARS - 1)].copy()

        for outcome_key, spec in OUTCOME_SPECS.items():
            count_column = spec["genre_count_column"]
            row[f"pre_{outcome_key}_count_mean"] = pre[count_column].mean()
            row[f"post_{outcome_key}_count_mean"] = post[count_column].mean()
            row[f"delta_{outcome_key}_count_mean"] = (
                row[f"post_{outcome_key}_count_mean"] - row[f"pre_{outcome_key}_count_mean"]
            )
            row[f"pre_{outcome_key}_count_total"] = pre[count_column].sum()
            row[f"post_{outcome_key}_count_total"] = post[count_column].sum()
            row[f"delta_{outcome_key}_count_total"] = (
                row[f"post_{outcome_key}_count_total"] - row[f"pre_{outcome_key}_count_total"]
            )
            row[f"pre_share_gap_{outcome_key}_mean"] = pre[f"share_gap_{outcome_key}"].mean()
            row[f"post_share_gap_{outcome_key}_mean"] = post[f"share_gap_{outcome_key}"].mean()
            row[f"delta_share_gap_{outcome_key}_mean"] = (
                row[f"post_share_gap_{outcome_key}_mean"] - row[f"pre_share_gap_{outcome_key}_mean"]
            )

        rows.append(row)

    event_windows = pd.DataFrame(rows)
    return event_windows.sort_values(
        ["delta_share_gap_all_mean", "delta_share_gap_unsigned_mean", "country_name"],
        ascending=[False, False, True],
    ).reset_index(drop=True)


def build_event_study(case_years: pd.DataFrame) -> pd.DataFrame:
    complete = case_years.copy()
    rows: list[dict[str, object]] = []
    for relative_year, frame in complete.groupby("relative_year", sort=True):
        row: dict[str, object] = {
            "relative_year": int(relative_year),
            "case_ct": int(frame["pilot_case_id"].nunique()),
        }
        for outcome_key in OUTCOME_SPECS:
            row[f"mean_count_{outcome_key}"] = frame[
                OUTCOME_SPECS[outcome_key]["genre_count_column"]
            ].mean()
            row[f"mean_share_gap_{outcome_key}"] = frame[f"share_gap_{outcome_key}"].mean()
        rows.append(row)
    event_study = pd.DataFrame(rows)
    return event_study.sort_values("relative_year").reset_index(drop=True)


def plot_event_study(event_study: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(11, 6))
    color_map = {"all": "#0b7285", "unsigned": "#e67700", "signed": "#5c940d"}
    for outcome_key, spec in OUTCOME_SPECS.items():
        ax.plot(
            event_study["relative_year"],
            event_study[f"mean_share_gap_{outcome_key}"] * 100,
            marker="o",
            linewidth=2.2,
            color=color_map[outcome_key],
            label=spec["label"],
        )
    ax.axvline(0, color="black", linewidth=0.9, alpha=0.5)
    ax.axhline(0, color="black", linewidth=0.8, alpha=0.3)
    ax.set_title(
        "Domestic-success pilot: mean genre-share-gap event profile",
        fontsize=14,
        weight="bold",
    )
    ax.set_xlabel("Years relative to domestic success event")
    ax.set_ylabel("Country-minus-rest-of-world genre share gap (pp)")
    ax.grid(alpha=0.25, linewidth=0.6)
    ax.legend(frameon=False)
    note = (
        "Pilot cases only. Broad genre families and visible domestic success events.\n"
        "Shares compare each country's genre share with the rest-of-world share in the same genre family."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.06, 1, 1))
    fig.savefig(FIGURE_OUTPUT_PATH, dpi=200)
    plt.close(fig)


def pct_point_text(value: object) -> str:
    if value is None or pd.isna(value):
        return "NA"
    return f"{float(value) * 100:.1f}"


def build_summary(case_years: pd.DataFrame, event_windows: pd.DataFrame, event_study: pd.DataFrame) -> str:
    case_table = event_windows[
        [
            "country_name",
            "genre_family",
            "artist_name",
            "domestic_success_year",
            "event_type",
            "source_tier",
            "delta_share_gap_all_mean",
            "delta_share_gap_unsigned_mean",
            "delta_share_gap_signed_mean",
        ]
    ].copy()
    for column in [
        "delta_share_gap_all_mean",
        "delta_share_gap_unsigned_mean",
        "delta_share_gap_signed_mean",
    ]:
        case_table[column] = case_table[column].map(pct_point_text)

    pooled_table = event_study[
        [
            "relative_year",
            "case_ct",
            "mean_share_gap_all",
            "mean_share_gap_unsigned",
            "mean_share_gap_signed",
        ]
    ].copy()
    for column in ["mean_share_gap_all", "mean_share_gap_unsigned", "mean_share_gap_signed"]:
        pooled_table[column] = pooled_table[column].map(pct_point_text)

    strongest_all = event_windows.sort_values(
        ["delta_share_gap_all_mean", "delta_share_gap_unsigned_mean"],
        ascending=[False, False],
    ).iloc[0]
    strongest_unsigned = event_windows.sort_values(
        ["delta_share_gap_unsigned_mean", "delta_share_gap_all_mean"],
        ascending=[False, False],
    ).iloc[0]
    strongest_signed = event_windows.sort_values(
        ["delta_share_gap_signed_mean", "delta_share_gap_all_mean"],
        ascending=[False, False],
    ).iloc[0]
    positive_all_cases = int((event_windows["delta_share_gap_all_mean"] > 0).sum())
    negative_all_cases = int((event_windows["delta_share_gap_all_mean"] < 0).sum())
    pooled_pre_all = event_study.loc[event_study["relative_year"] < 0, "mean_share_gap_all"].mean()
    pooled_post_all = event_study.loc[event_study["relative_year"] >= 0, "mean_share_gap_all"].mean()

    lines: list[str] = []
    lines.append("# Domestic-success pilot event pass")
    lines.append("")
    lines.append("## Locked pilot choices")
    lines.append("")
    lines.append("- Main descriptive event baseline: `presence` style visible domestic success.")
    lines.append("- Genre baseline: broad `genre_family` cells, not narrower parsed tags.")
    lines.append("- Outcome margins: `all`, `unsigned`, and `signed` band starts.")
    lines.append("- Comparison object: each country's genre share versus the rest-of-world share in the same genre family.")
    lines.append("")
    lines.append("## Current pilot cases")
    lines.append("")
    lines.append(f"- Pilot cases: `{case_years['pilot_case_id'].nunique()}`")
    lines.append(
        f"- Relative years kept: `{RELATIVE_YEARS[0]}` to `{RELATIVE_YEARS[-1]}` around the domestic-success year"
    )
    lines.append(
        f"- Case-year rows written: `{len(case_years)}`"
    )
    lines.append("")
    lines.append("## First read")
    lines.append("")
    lines.append(
        f"- Strongest all-band share-gap improvement: `{strongest_all['artist_name']}` in `{strongest_all['country_name']}` "
        f"(`{strongest_all['genre_family']}`), with a post-minus-pre gap change of `{pct_point_text(strongest_all['delta_share_gap_all_mean'])}` percentage points."
    )
    lines.append(
        f"- Strongest unsigned share-gap improvement: `{strongest_unsigned['artist_name']}` in `{strongest_unsigned['country_name']}` "
        f"(`{strongest_unsigned['genre_family']}`), with a post-minus-pre gap change of `{pct_point_text(strongest_unsigned['delta_share_gap_unsigned_mean'])}` percentage points."
    )
    lines.append(
        f"- Strongest signed share-gap improvement: `{strongest_signed['artist_name']}` in `{strongest_signed['country_name']}` "
        f"(`{strongest_signed['genre_family']}`), with a post-minus-pre gap change of `{pct_point_text(strongest_signed['delta_share_gap_signed_mean'])}` percentage points."
    )
    lines.append(
        f"- Case-level read is mixed rather than uniformly positive: `{positive_all_cases}` pilot cases improve on the all-band share-gap margin and `{negative_all_cases}` deteriorate."
    )
    lines.append(
        f"- The pooled all-band share gap drifts from `{pct_point_text(pooled_pre_all)}` percentage points in the pre-period mean to `{pct_point_text(pooled_post_all)}` in the post-period mean, so the average pilot path is not yet a clean success signal."
    )
    lines.append(
        "- The unsigned margin is the most useful mechanism read in this pilot because it is the clearest place where lowered entry barriers should show up first."
    )
    lines.append(
        "- This is still descriptive. The case file mixes source tiers, first-in-cell status is not fully proven for every pilot row, and the pilot does not yet absorb full country-year and genre-year fixed effects."
    )
    lines.append("")
    lines.append("## Case-level share-gap changes")
    lines.append("")
    lines.append(case_table.to_markdown(index=False))
    lines.append("")
    lines.append("## Pooled event profile")
    lines.append("")
    lines.append(pooled_table.to_markdown(index=False))
    lines.append("")
    lines.append("## Outputs")
    lines.append("")
    lines.append("- `domestic_success_pilot_case_years.csv`")
    lines.append("- `domestic_success_pilot_event_windows.csv`")
    lines.append("- `domestic_success_pilot_event_study.csv`")
    lines.append("- `domestic_success_pilot_share_gap_event_study.png`")
    lines.append("")
    lines.append("## Interpretation")
    lines.append("")
    lines.append(
        "- This is the first real `country x genre_family x year` pass in the project, but it is still a pilot and not yet a full estimating specification."
    )
    lines.append(
        "- If the unsigned margin looks informative here, the next clean step is a broader domestic-success treatment file and then a residualized panel with country-genre, country-year, and genre-year structure."
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    family_panel, country_year, pilot_cases = load_inputs()
    case_years = build_case_years(
        family_panel=family_panel,
        country_year=country_year,
        pilot_cases=pilot_cases,
    )
    event_windows = build_event_windows(case_years=case_years)
    event_study = build_event_study(case_years=case_years)
    plot_event_study(event_study=event_study)
    summary = build_summary(case_years=case_years, event_windows=event_windows, event_study=event_study)

    case_years.to_csv(CASE_YEARS_OUTPUT_PATH, index=False)
    event_windows.to_csv(WINDOWS_OUTPUT_PATH, index=False)
    event_study.to_csv(EVENT_STUDY_OUTPUT_PATH, index=False)
    SUMMARY_OUTPUT_PATH.write_text(summary, encoding="utf-8")

    print(f"Pilot cases: {pilot_cases['pilot_case_id'].nunique()}")
    print(f"Case-year rows: {len(case_years)}")
    print(f"Wrote: {CASE_YEARS_OUTPUT_PATH}")
    print(f"Wrote: {WINDOWS_OUTPUT_PATH}")
    print(f"Wrote: {EVENT_STUDY_OUTPUT_PATH}")
    print(f"Wrote: {SUMMARY_OUTPUT_PATH}")
    print(f"Wrote: {FIGURE_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
