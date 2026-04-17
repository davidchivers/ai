from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
COUNTRY_YEAR_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_country_year_panel.csv"
COUNTRY_GENRE_PATH = PROJECT_ROOT / "data" / "processed" / "country_genre_analysis" / "country_genre_family_year_panel.csv"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "country_genre_analysis"

BALANCED_PANEL_PATH = OUTPUT_DIR / "selected_country_genre_year_balanced_1995_2014.csv"
RESULTS_PATH = OUTPUT_DIR / "country_genre_internet_event_study_results.csv"
SUMMARY_PATH = OUTPUT_DIR / "country_genre_internet_event_study_summary.md"

SELECTED_GENRES = [
    "black metal",
    "death metal",
    "thrash metal",
    "heavy metal",
    "power metal",
]

START_YEAR = 1995
END_YEAR = 2014
INTERNET_THRESHOLD = 5.0
EVENT_TIMES = [-5, -4, -3, -2, 0, 1, 2, 3, 4, 5]

OUTCOMES = [
    {
        "outcome_id": "log_genre_starts",
        "display_label": "Log genre-family starts",
        "source_column": "bands_started",
        "transform": "log1p",
    },
    {
        "outcome_id": "genre_share_of_country_year",
        "display_label": "Genre share of country-year metal starts",
        "source_column": "genre_share_of_country_year",
        "transform": "level",
    },
]


def dummy_name(event_time: int) -> str:
    return f"event_{event_time:+d}".replace("+", "p").replace("-", "m")


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame]:
    country_year = pd.read_csv(COUNTRY_YEAR_PATH)
    country_genre = pd.read_csv(COUNTRY_GENRE_PATH)

    country_year["year"] = pd.to_numeric(country_year["year"], errors="coerce").astype(int)
    country_year["internet_ct"] = pd.to_numeric(country_year["internet_ct"], errors="coerce")
    country_year["bands_formed_all_metal_ct"] = pd.to_numeric(
        country_year["bands_formed_all_metal_ct"], errors="coerce"
    ).fillna(0.0)

    country_genre["entry_year"] = pd.to_numeric(country_genre["entry_year"], errors="coerce").astype(int)
    for column in [
        "bands_started",
        "genre_share_of_country_year",
    ]:
        country_genre[column] = pd.to_numeric(country_genre[column], errors="coerce")

    return country_year, country_genre


def classify_country_events(country_year: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for countryiso3code, panel in country_year.sort_values(["countryiso3code", "year"]).groupby("countryiso3code"):
        country_name = panel["country_name"].dropna().iloc[0]
        observed = panel.loc[panel["internet_ct"].notna(), ["year", "internet_ct"]].copy()
        if observed.empty:
            continue
        above_threshold = observed.loc[observed["internet_ct"] >= INTERNET_THRESHOLD].copy()
        if above_threshold.empty:
            rows.append(
                {
                    "countryiso3code": countryiso3code,
                    "country_name": country_name,
                    "event_year": np.nan,
                    "event_status": "never_reaches_threshold",
                }
            )
            continue

        first_above_year = int(above_threshold["year"].min())
        prior = observed.loc[observed["year"] < first_above_year].copy()
        if (prior["internet_ct"] < INTERNET_THRESHOLD).any() and START_YEAR <= first_above_year <= END_YEAR:
            rows.append(
                {
                    "countryiso3code": countryiso3code,
                    "country_name": country_name,
                    "event_year": first_above_year,
                    "event_status": "clean_event",
                }
            )
        else:
            rows.append(
                {
                    "countryiso3code": countryiso3code,
                    "country_name": country_name,
                    "event_year": np.nan,
                    "event_status": "ambiguous_or_pre_sample",
                }
            )
    return pd.DataFrame(rows)


def build_balanced_panel(country_year: pd.DataFrame, country_genre: pd.DataFrame, event_status: pd.DataFrame) -> pd.DataFrame:
    sample_countries = sorted(
        event_status.loc[event_status["event_status"] != "ambiguous_or_pre_sample", "countryiso3code"].unique()
    )
    year_frame = list(range(START_YEAR, END_YEAR + 1))

    full_index = pd.MultiIndex.from_product(
        [sample_countries, SELECTED_GENRES, year_frame],
        names=["countryiso3code", "genre_family", "year"],
    )
    balanced = pd.DataFrame(index=full_index).reset_index()

    country_lookup = (
        country_year[["countryiso3code", "country_name"]]
        .drop_duplicates()
        .rename(columns={"country_name": "country_std"})
    )
    balanced = balanced.merge(country_lookup, on="countryiso3code", how="left")

    observed = country_genre.loc[
        country_genre["genre_family"].isin(SELECTED_GENRES),
        ["countryiso3code", "country_std", "entry_year", "genre_family", "bands_started", "genre_share_of_country_year"],
    ].copy()
    observed = observed.rename(columns={"entry_year": "year"})

    balanced = balanced.merge(
        observed,
        on=["countryiso3code", "country_std", "genre_family", "year"],
        how="left",
    )
    balanced["bands_started"] = balanced["bands_started"].fillna(0.0)

    country_totals = country_year.loc[
        country_year["year"].between(START_YEAR, END_YEAR),
        ["countryiso3code", "year", "bands_formed_all_metal_ct"],
    ].copy()
    balanced = balanced.merge(country_totals, on=["countryiso3code", "year"], how="left")
    balanced["bands_formed_all_metal_ct"] = balanced["bands_formed_all_metal_ct"].fillna(0.0)

    # A genre share is only meaningful in country-years with any metal activity.
    balanced["genre_share_of_country_year"] = balanced["genre_share_of_country_year"].fillna(0.0)
    balanced.loc[balanced["bands_formed_all_metal_ct"].eq(0), "genre_share_of_country_year"] = np.nan

    balanced = balanced.merge(event_status, on=["countryiso3code"], how="left", suffixes=("", "_event"))
    balanced = balanced.drop(columns=["country_name_event"], errors="ignore")
    balanced["event_time"] = balanced["year"] - balanced["event_year"]
    return balanced


def build_estimation_sample(balanced: pd.DataFrame, outcome: dict[str, str], genre_family: str) -> pd.DataFrame:
    sample = balanced.loc[
        balanced["genre_family"].eq(genre_family)
        & (
            balanced["event_status"].eq("never_reaches_threshold")
            | balanced["event_time"].between(-5, 5)
        )
    ].copy()

    if outcome["transform"] == "log1p":
        sample["outcome_value"] = np.log1p(sample[outcome["source_column"]].fillna(0.0))
    else:
        sample["outcome_value"] = sample[outcome["source_column"]]

    sample = sample.loc[sample["outcome_value"].notna()].copy()
    sample["treated_i"] = sample["event_status"].eq("clean_event").astype(int)
    return sample


def fit_genre_spec(sample: pd.DataFrame, genre_family: str, outcome: dict[str, str], event_status: pd.DataFrame) -> pd.DataFrame:
    sample = sample.copy()
    support_counts: dict[int, int] = {}
    active_terms: list[str] = []
    for event_time in EVENT_TIMES:
        column = dummy_name(event_time)
        sample[column] = (
            sample["treated_i"].eq(1) & sample["event_time"].eq(event_time)
        ).astype(int)
        support_counts[event_time] = int(sample[column].sum())
        if support_counts[event_time] > 0:
            active_terms.append(column)

    sample["cell_id"] = sample["countryiso3code"].astype(str) + " || " + sample["genre_family"].astype(str)
    sample = sample.set_index(["cell_id", "year"]).sort_index()
    clusters = pd.DataFrame(
        {"country_cluster": sample.reset_index()["cell_id"].str.split(" \\|\\| ").str[0].values},
        index=sample.index,
    )

    result = PanelOLS(
        sample["outcome_value"],
        sample[active_terms],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=clusters)

    rows: list[dict[str, object]] = []
    for event_time in EVENT_TIMES:
        column = dummy_name(event_time)
        rows.append(
            {
                "genre_family": genre_family,
                "outcome_id": outcome["outcome_id"],
                "outcome_label": outcome["display_label"],
                "event_time": event_time,
                "coefficient": float(result.params.get(column, np.nan)),
                "std_error": float(result.std_errors.get(column, np.nan)),
                "p_value": float(result.pvalues.get(column, np.nan)),
                "support_count": int(support_counts[event_time]),
                "n_obs": int(result.nobs),
                "clean_event_countries": int(event_status["event_status"].eq("clean_event").sum()),
                "control_countries": int(event_status["event_status"].eq("never_reaches_threshold").sum()),
                "dropped_ambiguous_countries": int(event_status["event_status"].eq("ambiguous_or_pre_sample").sum()),
                "r_squared": float(result.rsquared),
            }
        )
    return pd.DataFrame(rows)


def format_coef(results: pd.DataFrame, genre_family: str, outcome_id: str, event_time: int) -> str:
    row = results.loc[
        (results["genre_family"] == genre_family)
        & (results["outcome_id"] == outcome_id)
        & (results["event_time"] == event_time)
    ]
    if row.empty:
        return "n/a"
    row = row.iloc[0]
    if pd.isna(row["coefficient"]):
        return "n/a"
    stars = "***" if row["p_value"] < 0.01 else "**" if row["p_value"] < 0.05 else "*" if row["p_value"] < 0.10 else ""
    return f"{row['coefficient']:.4f}{stars}"


def write_summary(results: pd.DataFrame, balanced: pd.DataFrame, event_status: pd.DataFrame) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Country-genre internet event-study probe\n\n")
        handle.write(
            "This probe zero-fills a balanced `country x genre-family x year` panel for a small set of "
            "major genres and then reuses the strongest country-level internet event: the first year a "
            "country reaches `5%` internet adoption. The goal is to see whether the broad country internet "
            "signal is really concentrated in specific genre families.\n\n"
        )
        handle.write("## Design\n\n")
        handle.write(f"- Genres: `{', '.join(SELECTED_GENRES)}`.\n")
        handle.write(f"- Years: `{START_YEAR}-{END_YEAR}`.\n")
        handle.write(f"- Internet event: first clean crossing of `{INTERNET_THRESHOLD:.0f}%` internet adoption.\n")
        handle.write(
            f"- Clean event countries = `{int(event_status['event_status'].eq('clean_event').sum())}`, "
            f"never-treated controls = `{int(event_status['event_status'].eq('never_reaches_threshold').sum())}`, "
            f"ambiguous or pre-sample countries dropped = `{int(event_status['event_status'].eq('ambiguous_or_pre_sample').sum())}`.\n"
        )
        handle.write(
            f"- Balanced panel rows written: `{len(balanced)}` in "
            f"`{BALANCED_PANEL_PATH.name}`.\n"
        )

        handle.write("\n## Headline coefficients for genre starts\n\n")
        for genre_family in SELECTED_GENRES:
            handle.write(
                f"- `{genre_family}`: "
                f"`t=-2: {format_coef(results, genre_family, 'log_genre_starts', -2)}`, "
                f"`t=0: {format_coef(results, genre_family, 'log_genre_starts', 0)}`, "
                f"`t=+1: {format_coef(results, genre_family, 'log_genre_starts', 1)}`, "
                f"`t=+3: {format_coef(results, genre_family, 'log_genre_starts', 3)}`, "
                f"`t=+5: {format_coef(results, genre_family, 'log_genre_starts', 5)}`.\n"
            )

        handle.write("\n## Headline coefficients for genre share\n\n")
        for genre_family in SELECTED_GENRES:
            handle.write(
                f"- `{genre_family}`: "
                f"`t=-2: {format_coef(results, genre_family, 'genre_share_of_country_year', -2)}`, "
                f"`t=0: {format_coef(results, genre_family, 'genre_share_of_country_year', 0)}`, "
                f"`t=+1: {format_coef(results, genre_family, 'genre_share_of_country_year', 1)}`, "
                f"`t=+3: {format_coef(results, genre_family, 'genre_share_of_country_year', 3)}`, "
                f"`t=+5: {format_coef(results, genre_family, 'genre_share_of_country_year', 5)}`.\n"
            )

        handle.write("\n## Current read\n\n")
        handle.write(
            "- The broad country-level internet result does not map cleanly into a genre-share result. "
            "Across all five genres, the share margin is weak or null.\n"
        )
        handle.write(
            "- On genre-start levels, `death metal`, `thrash metal`, `heavy metal`, and `power metal` all "
            "show positive post-event coefficients by later horizons, but the pattern is gradual rather than "
            "an immediate clean jump.\n"
        )
        handle.write(
            "- `Black metal` shows the strongest positive post-event coefficients, but it also has a positive "
            "pretrend at `t=-2`. That makes it the most visually suggestive case and also the least clean.\n"
        )
        handle.write(
            "- So the country internet result looks broad-based at the level of later genre starts, but not in "
            "a way that isolates one clear genre family or a clean genre-composition shift.\n"
        )


def main() -> None:
    country_year, country_genre = load_inputs()
    event_status = classify_country_events(country_year)
    balanced = build_balanced_panel(country_year, country_genre, event_status)
    BALANCED_PANEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    balanced.to_csv(BALANCED_PANEL_PATH, index=False)

    result_frames: list[pd.DataFrame] = []
    for genre_family in SELECTED_GENRES:
        for outcome in OUTCOMES:
            sample = build_estimation_sample(balanced, outcome, genre_family)
            result_frames.append(fit_genre_spec(sample, genre_family, outcome, event_status))

    results = pd.concat(result_frames, ignore_index=True)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(results, balanced, event_status)

    print(f"Wrote {BALANCED_PANEL_PATH}")
    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
