from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data" / "processed"
BAND_SUCCESS_DIR = DATA_DIR / "band_success"

SCENE_AT_BIRTH_PATH = BAND_SUCCESS_DIR / "band_scene_at_birth_panel.csv"
SUCCESS_CORE_PATH = DATA_DIR / "blockbuster_album_country_hits_core.csv"

LADDER_OUTCOMES_PATH = BAND_SUCCESS_DIR / "band_upgrading_ladder_outcomes.csv"
COHORT_PANEL_PATH = BAND_SUCCESS_DIR / "city_genre_birth_cohort_upgrading_panel.csv"
COHORT_PILOT_PATH = BAND_SUCCESS_DIR / "city_genre_birth_cohort_upgrading_pilot.csv"
SUMMARY_PATH = BAND_SUCCESS_DIR / "band_upgrading_ladder_summary.md"

SUCCESS_NAME_OVERRIDES = {
    ("rhapsody", "ITA"): ("rhapsody of fire", "Rhapsody of Fire"),
}

SUCCESS_EXCLUSION_KEYS = {
    ("disturbed", "USA"),
    ("slipknot", "USA"),
}


def normalize_text(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, float) and np.isnan(value):
        return ""
    return str(value).strip()


def normalize_band_name(value: object) -> str:
    text = normalize_text(value).lower()
    if not text:
        return ""
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def conditional_min(group: pd.DataFrame, mask: pd.Series, value_column: str) -> float:
    subset = group.loc[mask, value_column]
    subset = pd.to_numeric(subset, errors="coerce").dropna()
    return float(subset.min()) if not subset.empty else np.nan


def build_success_artist_aggregate() -> tuple[pd.DataFrame, list[str]]:
    hits = pd.read_csv(SUCCESS_CORE_PATH, dtype=str, keep_default_na=False)
    hits["home_market_i"] = pd.to_numeric(hits["home_market_i"], errors="coerce").fillna(0).astype(int)
    hits["foreign_market_i"] = pd.to_numeric(hits["foreign_market_i"], errors="coerce").fillna(0).astype(int)
    hits["top10_flag"] = pd.to_numeric(hits["top10_flag"], errors="coerce").fillna(0).astype(int)
    hits["hit_year"] = pd.to_numeric(hits["hit_year"], errors="coerce")
    hits = hits.loc[hits["hit_year"].notna()].copy()
    hits["hit_year"] = hits["hit_year"].astype(int)
    hits["certification_i"] = hits["certification_level"].map(lambda value: int(normalize_text(value) != ""))
    hits["artist_name_norm"] = hits["artist_name"].map(normalize_band_name)
    hits["artist_countryiso3code"] = hits["artist_countryiso3code"].map(normalize_text)
    hits["success_artist_name"] = hits["artist_name"].map(normalize_text)

    def apply_name_override(row: pd.Series) -> pd.Series:
        key = (row["artist_name_norm"], row["artist_countryiso3code"])
        override = SUCCESS_NAME_OVERRIDES.get(key)
        if override is None:
            return row
        row["artist_name_norm"] = override[0]
        row["success_artist_name"] = override[1]
        return row

    hits = hits.apply(apply_name_override, axis=1)
    hits = hits.loc[
        ~hits.apply(
            lambda row: (row["artist_name_norm"], row["artist_countryiso3code"]) in SUCCESS_EXCLUSION_KEYS,
            axis=1,
        )
    ].copy()

    grouped_rows: list[dict[str, object]] = []
    for (artist_name_norm, countryiso3code), group in hits.groupby(
        ["artist_name_norm", "artist_countryiso3code"],
        dropna=False,
    ):
        has_home = bool((group["home_market_i"] == 1).any())
        if not has_home:
            continue
        grouped_rows.append(
            {
                "artist_name_norm": artist_name_norm,
                "artist_countryiso3code": countryiso3code,
                "success_artist_name": group["success_artist_name"].iloc[0],
                "first_home_market_presence_year": conditional_min(group, group["home_market_i"] == 1, "hit_year"),
                "first_home_market_certification_year": conditional_min(
                    group,
                    (group["home_market_i"] == 1) & (group["certification_i"] == 1),
                    "hit_year",
                ),
                "first_home_market_top10_year": conditional_min(
                    group,
                    (group["home_market_i"] == 1) & (group["top10_flag"] == 1),
                    "hit_year",
                ),
                "first_foreign_market_presence_year": conditional_min(
                    group,
                    group["foreign_market_i"] == 1,
                    "hit_year",
                ),
                "first_foreign_market_top10_year": conditional_min(
                    group,
                    (group["foreign_market_i"] == 1) & (group["top10_flag"] == 1),
                    "hit_year",
                ),
                "home_market_presence_rows": int((group["home_market_i"] == 1).sum()),
                "home_market_certification_rows": int(
                    ((group["home_market_i"] == 1) & (group["certification_i"] == 1)).sum()
                ),
                "home_market_top10_rows": int(((group["home_market_i"] == 1) & (group["top10_flag"] == 1)).sum()),
                "foreign_market_presence_rows": int((group["foreign_market_i"] == 1).sum()),
                "foreign_market_top10_rows": int(
                    ((group["foreign_market_i"] == 1) & (group["top10_flag"] == 1)).sum()
                ),
                "foreign_market_count": int(group.loc[group["foreign_market_i"] == 1, "market_code"].nunique()),
            }
        )

    aggregate = pd.DataFrame(grouped_rows).sort_values(["artist_countryiso3code", "success_artist_name"])
    audited_countries = sorted(aggregate["artist_countryiso3code"].dropna().astype(str).unique().tolist())
    return aggregate, audited_countries


def match_artists_to_birth_panel(scene_panel: pd.DataFrame, success_aggregate: pd.DataFrame) -> pd.DataFrame:
    candidates = scene_panel.merge(
        success_aggregate,
        left_on=["band_name_norm", "countryiso3code"],
        right_on=["artist_name_norm", "artist_countryiso3code"],
        how="inner",
    )
    if candidates.empty:
        return scene_panel.copy()

    candidates["reference_gap_years"] = (
        pd.to_numeric(candidates["first_home_market_presence_year"], errors="coerce")
        - pd.to_numeric(candidates["formed_year"], errors="coerce")
    )
    candidates["valid_pre_hit_candidate_i"] = (candidates["reference_gap_years"] >= 0).astype(int)
    candidates["gap_rank"] = np.where(
        candidates["reference_gap_years"] >= 0,
        candidates["reference_gap_years"],
        10_000 + candidates["reference_gap_years"].abs(),
    )
    candidates = candidates.sort_values(
        [
            "artist_name_norm",
            "artist_countryiso3code",
            "valid_pre_hit_candidate_i",
            "gap_rank",
            "formed_year",
            "band_id",
        ],
        ascending=[True, True, False, True, True, True],
    )
    chosen = candidates.drop_duplicates(["artist_name_norm", "artist_countryiso3code"], keep="first").copy()

    band_stage = scene_panel.copy()
    merge_columns = [
        "band_id",
        "success_artist_name",
        "first_home_market_presence_year",
        "first_home_market_certification_year",
        "first_home_market_top10_year",
        "first_foreign_market_presence_year",
        "first_foreign_market_top10_year",
        "home_market_presence_rows",
        "home_market_certification_rows",
        "home_market_top10_rows",
        "foreign_market_presence_rows",
        "foreign_market_top10_rows",
        "foreign_market_count",
    ]
    band_stage = band_stage.merge(chosen[merge_columns], on="band_id", how="left")
    return band_stage


def add_stage_variables(band_stage: pd.DataFrame) -> pd.DataFrame:
    for year_column in [
        "first_home_market_presence_year",
        "first_home_market_certification_year",
        "first_home_market_top10_year",
        "first_foreign_market_presence_year",
        "first_foreign_market_top10_year",
    ]:
        band_stage[year_column] = pd.to_numeric(band_stage[year_column], errors="coerce")

    band_stage["home_market_validation_year"] = band_stage[
        ["first_home_market_certification_year", "first_home_market_top10_year"]
    ].min(axis=1)

    for gap_name, year_column in [
        ("home_market_presence_gap_years", "first_home_market_presence_year"),
        ("home_market_validation_gap_years", "home_market_validation_year"),
        ("foreign_market_presence_gap_years", "first_foreign_market_presence_year"),
        ("foreign_market_top10_gap_years", "first_foreign_market_top10_year"),
    ]:
        band_stage[gap_name] = band_stage[year_column] - pd.to_numeric(band_stage["formed_year"], errors="coerce")

    band_stage["later_home_market_presence_i"] = (
        band_stage["home_market_presence_gap_years"].between(0, np.inf, inclusive="both").fillna(False).astype(int)
    )
    band_stage["later_home_market_validation_i"] = (
        band_stage["home_market_validation_gap_years"].between(0, np.inf, inclusive="both").fillna(False).astype(int)
    )
    band_stage["later_foreign_market_presence_i"] = (
        band_stage["foreign_market_presence_gap_years"].between(0, np.inf, inclusive="both").fillna(False).astype(int)
    )
    band_stage["later_foreign_market_top10_i"] = (
        band_stage["foreign_market_top10_gap_years"].between(0, np.inf, inclusive="both").fillna(False).astype(int)
    )
    band_stage["home_to_foreign_crossover_i"] = (
        (band_stage["later_home_market_presence_i"] == 1)
        & (band_stage["later_foreign_market_presence_i"] == 1)
    ).astype(int)
    band_stage["validated_then_foreign_i"] = (
        band_stage["home_market_validation_year"].notna()
        & band_stage["first_foreign_market_presence_year"].notna()
        & (band_stage["first_foreign_market_presence_year"] >= band_stage["home_market_validation_year"])
    ).astype(int)

    for horizon in [10, 15, 20]:
        band_stage[f"home_market_validation_within_{horizon}y_i"] = (
            band_stage["home_market_validation_gap_years"].between(0, horizon, inclusive="both").fillna(False).astype(int)
        )
        band_stage[f"foreign_market_presence_within_{horizon}y_i"] = (
            band_stage["foreign_market_presence_gap_years"].between(0, horizon, inclusive="both").fillna(False).astype(int)
        )
        band_stage[f"validated_then_foreign_within_{horizon}y_i"] = (
            (band_stage["validated_then_foreign_i"] == 1)
            & band_stage["foreign_market_presence_gap_years"].between(0, horizon, inclusive="both").fillna(False)
        ).astype(int)

    band_stage["upgrading_stage_label"] = "no_observed_market_validation"
    band_stage.loc[band_stage["later_home_market_presence_i"] == 1, "upgrading_stage_label"] = "home_market_presence"
    band_stage.loc[band_stage["later_home_market_validation_i"] == 1, "upgrading_stage_label"] = "home_market_validation"
    band_stage.loc[band_stage["later_foreign_market_presence_i"] == 1, "upgrading_stage_label"] = "foreign_market_crossover"
    return band_stage


def build_cohort_panel(band_stage: pd.DataFrame, audited_countries: list[str]) -> pd.DataFrame:
    cohort_source = band_stage.loc[band_stage["countryiso3code"].isin(audited_countries)].copy()
    cohort_source["unsigned_proxy_i"] = pd.to_numeric(cohort_source["unsigned_i"], errors="coerce").fillna(0).astype(int)
    cohort_source["signed_proxy_i"] = 1 - cohort_source["unsigned_proxy_i"]

    group_columns = ["city_country", "countryiso3code", "genre_family", "formed_year"]
    cohort = (
        cohort_source.groupby(group_columns, dropna=False)
        .agg(
            cohort_bands_born=("band_id", "size"),
            cohort_bands_born_unsigned_proxy=("unsigned_proxy_i", "sum"),
            cohort_bands_born_signed_proxy=("signed_proxy_i", "sum"),
            any_home_market_presence_i=("later_home_market_presence_i", "max"),
            any_home_market_validation_i=("later_home_market_validation_i", "max"),
            any_foreign_market_presence_i=("later_foreign_market_presence_i", "max"),
            any_home_to_foreign_crossover_i=("home_to_foreign_crossover_i", "max"),
            any_validated_then_foreign_i=("validated_then_foreign_i", "max"),
            any_home_market_validation_within_10y_i=("home_market_validation_within_10y_i", "max"),
            any_home_market_validation_within_15y_i=("home_market_validation_within_15y_i", "max"),
            any_home_market_validation_within_20y_i=("home_market_validation_within_20y_i", "max"),
            any_validated_then_foreign_within_10y_i=("validated_then_foreign_within_10y_i", "max"),
            any_validated_then_foreign_within_15y_i=("validated_then_foreign_within_15y_i", "max"),
            any_validated_then_foreign_within_20y_i=("validated_then_foreign_within_20y_i", "max"),
            prebirth_n_active_bands=("prebirth_n_active_bands", "first"),
            prebirth_genre_active_bands=("prebirth_genre_active_bands", "first"),
            prebirth_genre_multi_band_musicians=("prebirth_genre_multi_band_musicians", "first"),
            prebirth_spawn_bands_formed=("prebirth_spawn_bands_formed", "first"),
            prebirth_roll5_log_active_bands=("prebirth_roll5_log_active_bands", "first"),
            prebirth_roll5_log_genre_active_bands=("prebirth_roll5_log_genre_active_bands", "first"),
            prebirth_roll5_log_genre_multi_band_musicians=("prebirth_roll5_log_genre_multi_band_musicians", "first"),
            prebirth_roll5_log_spawn_bands_formed=("prebirth_roll5_log_spawn_bands_formed", "first"),
        )
        .reset_index()
        .sort_values(["countryiso3code", "formed_year", "city_country", "genre_family"])
    )
    return cohort


def active_band_bin(value: float) -> str:
    if value <= 0:
        return "0"
    if value < 5:
        return "1-4"
    if value < 10:
        return "5-9"
    if value < 20:
        return "10-19"
    return "20+"


def genre_band_bin(value: float) -> str:
    if value <= 0:
        return "0"
    if value == 1:
        return "1"
    if value < 5:
        return "2-4"
    return "5+"


def build_cohort_pilot(cohort: pd.DataFrame) -> pd.DataFrame:
    cohort = cohort.copy()
    cohort["overall_scene_bin"] = cohort["prebirth_n_active_bands"].map(active_band_bin)
    cohort["genre_scene_bin"] = cohort["prebirth_genre_active_bands"].map(genre_band_bin)

    rows: list[dict[str, object]] = []
    for dimension, order in [
        ("overall_scene_bin", ["0", "1-4", "5-9", "10-19", "20+"]),
        ("genre_scene_bin", ["0", "1", "2-4", "5+"]),
    ]:
        grouped = (
            cohort.groupby(dimension, dropna=False)
            .agg(
                n_cohorts=("city_country", "size"),
                validation_within_15_rate=("any_home_market_validation_within_15y_i", "mean"),
                crossover_within_20_rate=("any_validated_then_foreign_within_20y_i", "mean"),
            )
            .reset_index()
        )
        grouped[dimension] = pd.Categorical(grouped[dimension], categories=order, ordered=True)
        grouped = grouped.sort_values(dimension)
        for _, row in grouped.iterrows():
            rows.append(
                {
                    "dimension": dimension,
                    "bin_label": row[dimension],
                    "n_cohorts": int(row["n_cohorts"]),
                    "validation_within_15_rate": float(row["validation_within_15_rate"]),
                    "crossover_within_20_rate": float(row["crossover_within_20_rate"]),
                }
            )
    return pd.DataFrame(rows)


def write_summary(
    success_aggregate: pd.DataFrame,
    band_stage: pd.DataFrame,
    cohort: pd.DataFrame,
    cohort_pilot: pd.DataFrame,
    audited_countries: list[str],
) -> None:
    matched = band_stage.loc[band_stage["home_market_success_match_i"] == 1].copy()
    gap_series = pd.to_numeric(matched["home_market_presence_gap_years"], errors="coerce").dropna()

    stage_counts = {
        "home_presence": int(matched["later_home_market_presence_i"].sum()),
        "home_validation": int(matched["later_home_market_validation_i"].sum()),
        "foreign_presence": int(matched["later_foreign_market_presence_i"].sum()),
        "validated_then_foreign": int(matched["validated_then_foreign_i"].sum()),
    }

    horizon_lines: list[str] = []
    for horizon in [10, 15, 20]:
        horizon_lines.append(
            f"- within `{horizon}` years: `{int(matched[f'home_market_validation_within_{horizon}y_i'].sum())}` home-market validation cases and `{int(matched[f'validated_then_foreign_within_{horizon}y_i'].sum())}` validated-then-foreign cases"
        )

    pilot_blocks: list[str] = []
    for dimension, title in [
        ("overall_scene_bin", "Cohort winner rates by overall local scene thickness"),
        ("genre_scene_bin", "Cohort winner rates by target-genre local thickness"),
    ]:
        frame = cohort_pilot.loc[cohort_pilot["dimension"] == dimension].copy()
        pilot_blocks.extend(
            [
                f"### {title}",
                "",
                "| Bin | Cohorts | Home validation within 15y | Validation then foreign within 20y |",
                "| --- | ---: | ---: | ---: |",
            ]
        )
        for _, row in frame.iterrows():
            pilot_blocks.append(
                "| {bin_label} | {n_cohorts:,} | {val_rate:.2%} | {cross_rate:.2%} |".format(
                    bin_label=row["bin_label"],
                    n_cohorts=int(row["n_cohorts"]),
                    val_rate=float(row["validation_within_15_rate"]),
                    cross_rate=float(row["crossover_within_20_rate"]),
                )
            )
        pilot_blocks.append("")

    matched_lines = [
        f"- `{row.band_name}` (`{row.countryiso3code}`): home `{int(row.first_home_market_presence_year)}`; validation `{int(row.home_market_validation_year) if not np.isnan(row.home_market_validation_year) else 'n/a'}`; foreign `{int(row.first_foreign_market_presence_year) if not np.isnan(row.first_foreign_market_presence_year) else 'n/a'}`"
        for row in matched.sort_values(["formed_year", "band_name"]).itertuples(index=False)
    ]

    lines = [
        "# Band upgrading ladder summary",
        "",
        "This file reframes the sidecar away from the vague idea of a `breakout band` and toward a",
        "staged upgrading ladder built from the current audited market file.",
        "",
        "## Ladder definition",
        "",
        "- stage 1: `home_market_presence`",
        "  any audited home-market chart or certification visibility",
        "- stage 2: `home_market_validation`",
        "  audited home-market top-10 or certification visibility",
        "- stage 3: `foreign_market_crossover`",
        "  any audited foreign-market visibility",
        "- stronger crossover object:",
        "  `validated_then_foreign`, where foreign-market visibility occurs after or at the home-validation year",
        "",
        "## Coverage",
        "",
        f"- audited home-market countries in the current ladder: `{', '.join(audited_countries)}`",
        f"- success artists with audited home-market rows: `{len(success_aggregate):,}`",
        f"- matched onto the band birth panel: `{len(matched):,}`",
        f"- median gap from founding to first home-market presence: `{gap_series.median():.1f}` years",
        "",
        "## Matched band counts by ladder stage",
        "",
        f"- home-market presence: `{stage_counts['home_presence']}`",
        f"- home-market validation: `{stage_counts['home_validation']}`",
        f"- foreign-market presence: `{stage_counts['foreign_presence']}`",
        f"- validated then foreign: `{stage_counts['validated_then_foreign']}`",
        *horizon_lines,
        "",
        "## Cohort object",
        "",
        "The new cohort panel aggregates to `city x genre_family x formed_year` inside the audited",
        "home-market countries. This is the cleaner unit for the sidecar because the paper's main",
        "question is about whether scenes produce winners, not whether a single band was ever observed",
        "to succeed decades later.",
        "",
        f"- audited cohort rows: `{len(cohort):,}`",
        f"- cohorts producing any home-market validation within 15 years: `{int(cohort['any_home_market_validation_within_15y_i'].sum())}`",
        f"- cohorts producing validated-then-foreign crossover within 20 years: `{int(cohort['any_validated_then_foreign_within_20y_i'].sum())}`",
        "",
        *pilot_blocks,
        "## Matched ladder bands",
        "",
        *matched_lines,
        "",
        "## Read",
        "",
        "The sidecar is easier to think about in this ladder form than in the old `ever successful`",
        "form. But the current audit still does not justify a full regression yet. The right next",
        "design is a bounded cohort outcome such as `did this city-genre founding cohort produce a",
        "home-market validated band within 15 years?`, with foreign crossover as a second-stage outcome.",
        "The current `unsigned_i` field can still be used in that cohort object as a rough current",
        "independence proxy, but it should not be interpreted as a clean historical contract-status",
        "measure.",
    ]
    SUMMARY_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    scene_panel = pd.read_csv(SCENE_AT_BIRTH_PATH, low_memory=False)
    success_aggregate, audited_countries = build_success_artist_aggregate()
    band_stage = match_artists_to_birth_panel(scene_panel, success_aggregate)
    band_stage["home_market_success_match_i"] = band_stage["success_artist_name"].notna().astype(int)
    band_stage = add_stage_variables(band_stage)
    cohort = build_cohort_panel(band_stage, audited_countries)
    cohort_pilot = build_cohort_pilot(cohort)

    band_stage.to_csv(LADDER_OUTCOMES_PATH, index=False)
    cohort.to_csv(COHORT_PANEL_PATH, index=False)
    cohort_pilot.to_csv(COHORT_PILOT_PATH, index=False)
    write_summary(success_aggregate, band_stage, cohort, cohort_pilot, audited_countries)

    print(f"Wrote {LADDER_OUTCOMES_PATH}")
    print(f"Wrote {COHORT_PANEL_PATH}")
    print(f"Wrote {COHORT_PILOT_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
