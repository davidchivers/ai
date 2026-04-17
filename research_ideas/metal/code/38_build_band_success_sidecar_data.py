from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data" / "processed"
SCENE_DIR = DATA_DIR / "scene_networks"
OUT_DIR = DATA_DIR / "band_success"

BAND_PATH = DATA_DIR / "metal_archives_all_metal_band_clean.csv"
SCENE_NETWORK_PATH = SCENE_DIR / "city_year_network_snapshots.csv"
SCENE_OVERALL_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
SCENE_GENRE_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
SUCCESS_CORE_PATH = DATA_DIR / "blockbuster_album_country_hits_core.csv"

BIRTH_PANEL_PATH = OUT_DIR / "band_birth_panel.csv"
SCENE_AT_BIRTH_PATH = OUT_DIR / "band_scene_at_birth_panel.csv"
SUCCESS_OUTCOME_PATH = OUT_DIR / "band_success_outcomes.csv"
MATCH_DIAGNOSTIC_PATH = OUT_DIR / "band_success_match_diagnostics.csv"
PILOT_BIN_PATH = OUT_DIR / "band_success_descriptive_pilot.csv"
COVERAGE_AUDIT_PATH = OUT_DIR / "band_success_coverage_audit.csv"
DESIGN_AUDIT_PATH = OUT_DIR / "band_success_design_audit.md"
SUMMARY_PATH = OUT_DIR / "band_success_sidecar_summary.md"

GENRE_FAMILIES = {
    "atmospheric black metal": "atmospheric_black_metal",
    "avant-garde metal": "avant_garde_metal",
    "brutal death metal": "brutal_death_metal",
    "depressive black metal": "depressive_black_metal",
    "melodic death metal": "melodic_death_metal",
    "technical death metal": "technical_death_metal",
    "black metal": "black_metal",
    "death metal": "death_metal",
    "doom metal": "doom_metal",
    "drone metal": "drone_metal",
    "folk metal": "folk_metal",
    "gothic metal": "gothic_metal",
    "grindcore": "grindcore",
    "groove metal": "groove_metal",
    "heavy metal": "heavy_metal",
    "industrial metal": "industrial_metal",
    "metalcore": "metalcore",
    "nu metal": "nu_metal",
    "post-black metal": "post_black_metal",
    "post-metal": "post_metal",
    "power metal": "power_metal",
    "progressive metal": "progressive_metal",
    "sludge metal": "sludge_metal",
    "speed metal": "speed_metal",
    "stoner metal": "stoner_metal",
    "symphonic metal": "symphonic_metal",
    "thrash metal": "thrash_metal",
    "viking metal": "viking_metal",
    "deathcore": "deathcore",
}
GENRE_FAMILY_KEYS = sorted(GENRE_FAMILIES.keys(), key=len, reverse=True)

SUCCESS_NAME_OVERRIDES = {
    ("rhapsody", "ITA"): ("rhapsody of fire", "Rhapsody of Fire"),
}

SUCCESS_EXCLUSION_KEYS = {
    ("disturbed", "USA"),
    ("slipknot", "USA"),
}

NUMERIC_ZERO_FILL_COLUMNS = [
    "prebirth_n_active_bands",
    "prebirth_n_nontrivial_communities",
    "prebirth_n_multi_band_musicians_total",
    "prebirth_bands_formed",
    "prebirth_spawn_bands_formed",
    "prebirth_spawn_share_formed",
    "prebirth_founder_pedigree_mean",
    "prebirth_log_active_bands",
    "prebirth_log_multi_band_musicians_total",
    "prebirth_log_spawn_bands_formed",
    "prebirth_roll5_log_active_bands",
    "prebirth_roll5_n_nontrivial_communities",
    "prebirth_roll5_log_multi_band_musicians_total",
    "prebirth_roll5_log_spawn_bands_formed",
    "prebirth_roll5_spawn_share_formed",
    "prebirth_roll5_founder_pedigree_mean",
    "prebirth_n_active_musicians",
    "prebirth_n_active_edges",
    "prebirth_density",
    "prebirth_bridge_pct",
    "prebirth_n_communities",
    "prebirth_largest_community",
    "prebirth_largest_component",
    "prebirth_modularity_q",
    "prebirth_strongest_supported_genre_bands",
    "prebirth_strongest_supported_genre_share",
    "prebirth_genre_active_bands",
    "prebirth_genre_active_musicians",
    "prebirth_genre_multi_band_musicians",
    "prebirth_genre_broker_musicians",
    "prebirth_genre_broker_share",
    "prebirth_genre_multi_band_share",
    "prebirth_genre_active_guitar_musicians",
    "prebirth_genre_active_drums_musicians",
    "prebirth_genre_active_bass_musicians",
    "prebirth_genre_active_vocals_musicians",
    "prebirth_genre_active_keyboards_musicians",
    "prebirth_log_genre_active_bands",
    "prebirth_log_genre_active_musicians",
    "prebirth_log_genre_multi_band_musicians",
    "prebirth_log_genre_broker_musicians",
    "prebirth_log_genre_active_guitar_musicians",
    "prebirth_log_genre_active_drums_musicians",
    "prebirth_log_genre_active_bass_musicians",
    "prebirth_log_genre_active_vocals_musicians",
    "prebirth_log_genre_active_keyboards_musicians",
    "prebirth_roll5_log_genre_active_bands",
    "prebirth_roll5_log_genre_active_musicians",
    "prebirth_roll5_log_genre_multi_band_musicians",
    "prebirth_roll5_log_genre_broker_musicians",
    "prebirth_roll5_genre_broker_share",
    "prebirth_roll5_genre_multi_band_share",
    "prebirth_roll5_log_genre_active_guitar_musicians",
    "prebirth_roll5_log_genre_active_drums_musicians",
    "prebirth_roll5_log_genre_active_bass_musicians",
    "prebirth_roll5_log_genre_active_vocals_musicians",
    "prebirth_roll5_log_genre_active_keyboards_musicians",
]


def extract_city(notes_str: str) -> str:
    if not isinstance(notes_str, str) or not notes_str.strip():
        return ""
    match = re.search(r"location=([^;]+)", notes_str)
    if not match:
        return ""
    parts = [part.strip() for part in match.group(1).split(",")]
    return parts[0] if parts else ""


def normalize_text(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, float) and np.isnan(value):
        return ""
    return str(value).strip()


def normalize_city_country(city: object, country: object) -> str:
    city_text = normalize_text(city)
    country_text = normalize_text(country)
    if not city_text:
        return ""
    return f"{city_text}, {country_text}" if country_text else city_text


def normalize_band_name(name: object) -> str:
    text = normalize_text(name).lower()
    if not text:
        return ""
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def parse_genre_families_ordered(genre_raw: object) -> list[str]:
    text = normalize_text(genre_raw).lower()
    if not text:
        return []
    matches: list[tuple[int, int, str]] = []
    for key in GENRE_FAMILY_KEYS:
        index = text.find(key)
        if index >= 0:
            matches.append((index, -len(key), GENRE_FAMILIES[key]))
    matches.sort()
    ordered: list[str] = []
    seen: set[str] = set()
    for _, _, family in matches:
        if family not in seen:
            ordered.append(family)
            seen.add(family)
    if not ordered and "metal" in text:
        ordered.append("other_metal")
    return ordered


def load_band_birth_panel() -> tuple[pd.DataFrame, dict[str, int]]:
    bands = pd.read_csv(BAND_PATH, dtype=str, keep_default_na=False)
    stats = {
        "raw_bands": int(len(bands)),
        "with_formed_year": int(pd.to_numeric(bands["formed_year"], errors="coerce").notna().sum()),
        "with_city": int(bands["notes"].map(extract_city).astype(bool).sum()),
    }

    bands["band_id"] = bands["source_id_primary"].map(normalize_text)
    bands["band_name"] = bands["band_name_raw"].map(normalize_text)
    bands["band_name_clean"] = bands["band_name_clean"].map(normalize_text)
    bands["band_name_norm"] = bands["band_name_clean"].map(normalize_band_name)
    bands["city"] = bands["notes"].map(extract_city)
    bands["country"] = bands["country_std"].map(normalize_text)
    bands["countryiso3code"] = bands["countryiso3code"].map(normalize_text)
    bands["city_country"] = bands.apply(
        lambda row: normalize_city_country(row["city"], row["country"]),
        axis=1,
    )
    bands["formed_year"] = pd.to_numeric(bands["formed_year"], errors="coerce")
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce")
    bands["genre_family_list"] = bands["genre_raw"].map(parse_genre_families_ordered)
    bands["genre_family"] = bands["genre_family_list"].map(lambda values: values[0] if values else "")
    bands["genre_family_list"] = bands["genre_family_list"].map("|".join)
    bands["n_genre_families"] = bands["genre_family_list"].map(lambda text: 0 if not text else text.count("|") + 1)
    bands["formed_decade"] = (bands["formed_year"] // 10) * 10
    bands["scene_measure_year"] = bands["formed_year"] - 1

    birth_panel = bands.loc[
        bands["band_id"].ne("")
        & bands["band_name_norm"].ne("")
        & bands["city_country"].ne("")
        & bands["countryiso3code"].ne("")
        & bands["genre_family"].ne("")
        & bands["formed_year"].notna()
    ].copy()

    birth_panel["formed_year"] = birth_panel["formed_year"].astype(int)
    birth_panel["entry_year"] = birth_panel["entry_year"].where(birth_panel["entry_year"].notna(), np.nan)
    birth_panel["formed_decade"] = birth_panel["formed_decade"].astype(int)
    birth_panel["scene_measure_year"] = birth_panel["scene_measure_year"].astype(int)
    birth_panel["unsigned_i"] = pd.to_numeric(birth_panel["unsigned_i"], errors="coerce").fillna(0).astype(int)

    birth_panel = birth_panel[
        [
            "band_id",
            "band_name",
            "band_name_clean",
            "band_name_norm",
            "country",
            "countryiso3code",
            "city",
            "city_country",
            "formed_year",
            "formed_decade",
            "scene_measure_year",
            "entry_year",
            "entry_year_source",
            "genre_raw",
            "genre_family",
            "genre_family_list",
            "n_genre_families",
            "label_status_raw",
            "unsigned_i",
            "active_status_raw",
            "source_url",
            "notes",
        ]
    ].sort_values(["formed_year", "country", "band_name_norm", "band_id"])

    stats["with_primary_genre_family"] = int(bands["genre_family"].ne("").sum())
    stats["birth_panel_rows"] = int(len(birth_panel))
    stats["multi_family_birth_panel_rows"] = int((birth_panel["n_genre_families"] > 1).sum())
    stats["unique_city_country"] = int(birth_panel["city_country"].nunique())
    stats["unique_genre_family"] = int(birth_panel["genre_family"].nunique())
    return birth_panel, stats


def load_scene_features() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    overall = pd.read_csv(SCENE_OVERALL_PATH)
    network = pd.read_csv(SCENE_NETWORK_PATH)
    genre = pd.read_csv(SCENE_GENRE_PATH)

    overall = overall.rename(columns={"snapshot_year": "scene_measure_year"})
    network = network.rename(columns={"snapshot_year": "scene_measure_year"})
    genre = genre.rename(columns={"snapshot_year": "scene_measure_year"})

    overall_rename = {
        column: f"prebirth_{column}"
        for column in overall.columns
        if column not in {"city_country", "scene_measure_year"}
    }
    network_rename = {
        "n_active_musicians": "prebirth_n_active_musicians",
        "n_active_edges": "prebirth_n_active_edges",
        "density": "prebirth_density",
        "bridge_pct": "prebirth_bridge_pct",
        "n_communities": "prebirth_n_communities",
        "largest_community": "prebirth_largest_community",
        "largest_component": "prebirth_largest_component",
        "modularity_q": "prebirth_modularity_q",
        "strongest_supported_genre": "prebirth_strongest_supported_genre",
        "strongest_supported_genre_bands": "prebirth_strongest_supported_genre_bands",
        "strongest_supported_genre_share": "prebirth_strongest_supported_genre_share",
    }
    genre_rename = {
        column: f"prebirth_{column}"
        for column in genre.columns
        if column not in {"city_country", "scene_measure_year", "genre_family"}
    }

    overall = overall.rename(columns=overall_rename)
    network = network.rename(columns=network_rename)
    genre = genre.rename(columns=genre_rename)

    overall = overall[["city_country", "scene_measure_year", *overall_rename.values()]]
    network = network[["city_country", "scene_measure_year", *network_rename.values()]]
    genre = genre[["city_country", "scene_measure_year", "genre_family", *genre_rename.values()]]
    return overall, network, genre


def build_scene_at_birth_panel(birth_panel: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
    overall, network, genre = load_scene_features()

    panel = birth_panel.merge(
        overall.assign(prebirth_overall_scene_exact_match_i=1),
        on=["city_country", "scene_measure_year"],
        how="left",
    )
    panel = panel.merge(
        network.assign(prebirth_network_scene_exact_match_i=1),
        on=["city_country", "scene_measure_year"],
        how="left",
    )
    panel = panel.merge(
        genre.assign(prebirth_genre_scene_exact_match_i=1),
        on=["city_country", "scene_measure_year", "genre_family"],
        how="left",
    )

    for indicator in [
        "prebirth_overall_scene_exact_match_i",
        "prebirth_network_scene_exact_match_i",
        "prebirth_genre_scene_exact_match_i",
    ]:
        panel[indicator] = panel[indicator].fillna(0).astype(int)

    for column in NUMERIC_ZERO_FILL_COLUMNS:
        if column in panel.columns:
            panel[column] = pd.to_numeric(panel[column], errors="coerce").fillna(0.0)

    if "prebirth_strongest_supported_genre" in panel.columns:
        panel["prebirth_strongest_supported_genre"] = (
            panel["prebirth_strongest_supported_genre"].fillna("").astype(str)
        )

    panel["prebirth_any_scene_match_i"] = (
        (panel["prebirth_overall_scene_exact_match_i"] == 1)
        | (panel["prebirth_network_scene_exact_match_i"] == 1)
    ).astype(int)

    stats = {
        "overall_scene_exact_matches": int(panel["prebirth_overall_scene_exact_match_i"].sum()),
        "network_scene_exact_matches": int(panel["prebirth_network_scene_exact_match_i"].sum()),
        "genre_scene_exact_matches": int(panel["prebirth_genre_scene_exact_match_i"].sum()),
        "rows_with_any_positive_overall_scene": int((panel["prebirth_n_active_bands"] > 0).sum()),
        "rows_with_any_positive_genre_scene": int((panel["prebirth_genre_active_bands"] > 0).sum()),
    }
    return panel, stats


def build_success_aggregate() -> pd.DataFrame:
    success = pd.read_csv(SUCCESS_CORE_PATH, dtype=str, keep_default_na=False)
    success["home_market_i"] = pd.to_numeric(success["home_market_i"], errors="coerce").fillna(0).astype(int)
    success["top10_flag"] = pd.to_numeric(success["top10_flag"], errors="coerce").fillna(0).astype(int)
    success["hit_year"] = pd.to_numeric(success["hit_year"], errors="coerce")
    success = success.loc[(success["home_market_i"] == 1) & success["hit_year"].notna()].copy()
    success["hit_year"] = success["hit_year"].astype(int)
    success["artist_name_norm"] = success["artist_name"].map(normalize_band_name)
    success["artist_countryiso3code"] = success["artist_countryiso3code"].map(normalize_text)
    success["success_artist_name"] = success["artist_name"].map(normalize_text)
    success["success_key"] = list(zip(success["artist_name_norm"], success["artist_countryiso3code"]))
    success["artist_name_norm"] = success["success_key"].map(
        lambda key: SUCCESS_NAME_OVERRIDES.get(key, (key[0], ""))[0]
    )
    success["success_artist_name"] = success.apply(
        lambda row: SUCCESS_NAME_OVERRIDES.get(
            (row["success_key"][0], row["artist_countryiso3code"]),
            (row["artist_name_norm"], row["success_artist_name"]),
        )[1],
        axis=1,
    )
    success = success.loc[
        ~success.apply(
            lambda row: (row["artist_name_norm"], row["artist_countryiso3code"]) in SUCCESS_EXCLUSION_KEYS,
            axis=1,
        )
    ].copy()
    success["certification_i"] = success["certification_level"].map(lambda value: int(normalize_text(value) != ""))

    grouped = (
        success.groupby(["artist_name_norm", "artist_countryiso3code"], dropna=False)
        .agg(
            success_artist_name=("success_artist_name", "first"),
            first_home_market_presence_year=("hit_year", "min"),
            first_home_market_certification_year=(
                "hit_year",
                lambda values: min(
                    success.loc[values.index, "hit_year"][success.loc[values.index, "certification_i"] == 1]
                )
                if int(success.loc[values.index, "certification_i"].sum()) > 0
                else np.nan,
            ),
            first_home_market_top10_year=(
                "hit_year",
                lambda values: min(
                    success.loc[values.index, "hit_year"][success.loc[values.index, "top10_flag"] == 1]
                )
                if int(success.loc[values.index, "top10_flag"].sum()) > 0
                else np.nan,
            ),
            home_market_presence_rows=("hit_year", "size"),
            home_market_certification_rows=("certification_i", "sum"),
            home_market_top10_rows=("top10_flag", "sum"),
        )
        .reset_index()
    )
    grouped["first_success_reference_year"] = grouped[
        [
            "first_home_market_presence_year",
            "first_home_market_certification_year",
            "first_home_market_top10_year",
        ]
    ].min(axis=1)
    return grouped


def build_success_match(
    birth_panel: pd.DataFrame,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, dict[str, int]]:
    success_aggregate = build_success_aggregate()
    candidates = birth_panel.merge(
        success_aggregate,
        left_on=["band_name_norm", "countryiso3code"],
        right_on=["artist_name_norm", "artist_countryiso3code"],
        how="inner",
    )

    if candidates.empty:
        outcomes = birth_panel[["band_id", "band_name", "countryiso3code", "formed_year"]].copy()
        diagnostics = pd.DataFrame(columns=["success_artist_name"])
        coverage_audit = success_aggregate.copy()
        coverage_audit["coverage_status"] = "missing_birth_panel_match"
        coverage_audit["matched_band_name"] = pd.NA
        coverage_audit["matched_city_country"] = pd.NA
        coverage_audit["matched_formed_year"] = pd.NA
        coverage_audit["matched_gap_years"] = pd.NA
        stats = {
            "home_market_success_artists": int(len(success_aggregate)),
            "matched_success_artists": 0,
            "ambiguous_success_artists": 0,
            "matched_birth_panel_rows": 0,
        }
        return outcomes, diagnostics, coverage_audit, stats

    candidates["reference_gap_years"] = candidates["first_success_reference_year"] - candidates["formed_year"]
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

    diagnostics = (
        candidates.groupby(["artist_name_norm", "artist_countryiso3code"], dropna=False)
        .agg(
            success_artist_name=("success_artist_name", "first"),
            first_success_reference_year=("first_success_reference_year", "first"),
            candidate_band_rows=("band_id", "size"),
            chosen_band_id=("band_id", "first"),
            chosen_band_name=("band_name", "first"),
            chosen_city_country=("city_country", "first"),
            chosen_formed_year=("formed_year", "first"),
            chosen_reference_gap_years=("reference_gap_years", "first"),
            any_nonnegative_gap_i=("valid_pre_hit_candidate_i", "max"),
        )
        .reset_index()
    )
    diagnostics["ambiguous_match_i"] = (diagnostics["candidate_band_rows"] > 1).astype(int)

    coverage_audit = success_aggregate.merge(
        diagnostics[
            [
                "artist_name_norm",
                "artist_countryiso3code",
                "chosen_band_name",
                "chosen_city_country",
                "chosen_formed_year",
                "chosen_reference_gap_years",
            ]
        ],
        on=["artist_name_norm", "artist_countryiso3code"],
        how="left",
    )
    coverage_audit["coverage_status"] = np.where(
        coverage_audit["chosen_band_name"].notna(),
        "matched_birth_panel",
        "missing_birth_panel_match",
    )
    coverage_audit = coverage_audit.rename(
        columns={
            "chosen_band_name": "matched_band_name",
            "chosen_city_country": "matched_city_country",
            "chosen_formed_year": "matched_formed_year",
            "chosen_reference_gap_years": "matched_gap_years",
        }
    )
    coverage_audit = coverage_audit[
        [
            "artist_name_norm",
            "artist_countryiso3code",
            "success_artist_name",
            "first_home_market_presence_year",
            "first_home_market_certification_year",
            "first_home_market_top10_year",
            "home_market_presence_rows",
            "home_market_certification_rows",
            "home_market_top10_rows",
            "coverage_status",
            "matched_band_name",
            "matched_city_country",
            "matched_formed_year",
            "matched_gap_years",
        ]
    ].sort_values(["artist_countryiso3code", "success_artist_name"])

    chosen = candidates.drop_duplicates(["artist_name_norm", "artist_countryiso3code"], keep="first").copy()

    outcomes = birth_panel[["band_id", "band_name", "band_name_norm", "countryiso3code", "formed_year"]].copy()
    chosen_columns = [
        "band_id",
        "success_artist_name",
        "first_home_market_presence_year",
        "first_home_market_certification_year",
        "first_home_market_top10_year",
        "home_market_presence_rows",
        "home_market_certification_rows",
        "home_market_top10_rows",
    ]
    outcomes = outcomes.merge(chosen[chosen_columns], on="band_id", how="left")

    for outcome_name, year_column in [
        ("presence", "first_home_market_presence_year"),
        ("certification", "first_home_market_certification_year"),
        ("top10", "first_home_market_top10_year"),
    ]:
        outcomes[year_column] = pd.to_numeric(outcomes[year_column], errors="coerce")
        gap_column = f"home_market_{outcome_name}_gap_years"
        flag_column = f"later_home_market_{outcome_name}_i"
        outcomes[gap_column] = outcomes[year_column] - outcomes["formed_year"]
        outcomes[flag_column] = ((outcomes[gap_column] >= 0) & outcomes[year_column].notna()).astype(int)

    count_columns = [
        "home_market_presence_rows",
        "home_market_certification_rows",
        "home_market_top10_rows",
    ]
    for column in count_columns:
        outcomes[column] = pd.to_numeric(outcomes[column], errors="coerce").fillna(0).astype(int)

    outcomes["home_market_success_match_i"] = outcomes["success_artist_name"].notna().astype(int)

    outcomes = outcomes[
        [
            "band_id",
            "band_name",
            "band_name_norm",
            "countryiso3code",
            "formed_year",
            "success_artist_name",
            "home_market_success_match_i",
            "home_market_presence_rows",
            "first_home_market_presence_year",
            "home_market_presence_gap_years",
            "later_home_market_presence_i",
            "home_market_certification_rows",
            "first_home_market_certification_year",
            "home_market_certification_gap_years",
            "later_home_market_certification_i",
            "home_market_top10_rows",
            "first_home_market_top10_year",
            "home_market_top10_gap_years",
            "later_home_market_top10_i",
        ]
    ].sort_values(["home_market_success_match_i", "later_home_market_presence_i", "band_name_norm"], ascending=[False, False, True])

    stats = {
        "home_market_success_artists": int(len(success_aggregate)),
        "matched_success_artists": int(len(diagnostics)),
        "ambiguous_success_artists": int(diagnostics["ambiguous_match_i"].sum()),
        "matched_birth_panel_rows": int(outcomes["home_market_success_match_i"].sum()),
        "presence_success_rows": int(outcomes["later_home_market_presence_i"].sum()),
        "certification_success_rows": int(outcomes["later_home_market_certification_i"].sum()),
        "top10_success_rows": int(outcomes["later_home_market_top10_i"].sum()),
    }
    return outcomes, diagnostics, coverage_audit, stats


def overall_scene_bin(value: float) -> str:
    if value <= 0:
        return "0"
    if value < 5:
        return "1-4"
    if value < 10:
        return "5-9"
    if value < 20:
        return "10-19"
    return "20+"


def genre_scene_bin(value: float) -> str:
    if value <= 0:
        return "0"
    if value == 1:
        return "1"
    if value < 5:
        return "2-4"
    return "5+"


def build_pilot_bins(scene_panel: pd.DataFrame, outcomes: pd.DataFrame) -> pd.DataFrame:
    pilot = scene_panel.merge(
        outcomes[
            [
                "band_id",
                "later_home_market_presence_i",
                "later_home_market_certification_i",
                "later_home_market_top10_i",
            ]
        ],
        on="band_id",
        how="left",
    )
    for column in [
        "later_home_market_presence_i",
        "later_home_market_certification_i",
        "later_home_market_top10_i",
    ]:
        pilot[column] = pd.to_numeric(pilot[column], errors="coerce").fillna(0).astype(int)

    pilot["overall_scene_bin"] = pilot["prebirth_n_active_bands"].map(overall_scene_bin)
    pilot["genre_scene_bin"] = pilot["prebirth_genre_active_bands"].map(genre_scene_bin)

    rows: list[dict[str, object]] = []
    for dimension, order in [
        ("overall_scene_bin", ["0", "1-4", "5-9", "10-19", "20+"]),
        ("genre_scene_bin", ["0", "1", "2-4", "5+"]),
    ]:
        grouped = (
            pilot.groupby(dimension, dropna=False)
            .agg(
                n_bands=("band_id", "size"),
                presence_rate=("later_home_market_presence_i", "mean"),
                certification_rate=("later_home_market_certification_i", "mean"),
                top10_rate=("later_home_market_top10_i", "mean"),
                mean_prebirth_active_bands=("prebirth_n_active_bands", "mean"),
                mean_prebirth_genre_active_bands=("prebirth_genre_active_bands", "mean"),
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
                    "n_bands": int(row["n_bands"]),
                    "presence_rate": float(row["presence_rate"]),
                    "certification_rate": float(row["certification_rate"]),
                    "top10_rate": float(row["top10_rate"]),
                    "mean_prebirth_active_bands": float(row["mean_prebirth_active_bands"]),
                    "mean_prebirth_genre_active_bands": float(row["mean_prebirth_genre_active_bands"]),
                }
            )
    return pd.DataFrame(rows)


def write_design_audit(
    scene_panel: pd.DataFrame,
    outcomes: pd.DataFrame,
    diagnostics: pd.DataFrame,
    coverage_audit: pd.DataFrame,
) -> None:
    audited_countries = sorted(coverage_audit["artist_countryiso3code"].dropna().astype(str).unique().tolist())
    audited_scene = scene_panel.merge(
        outcomes[
            [
                "band_id",
                "home_market_presence_gap_years",
                "home_market_top10_gap_years",
                "later_home_market_presence_i",
                "later_home_market_top10_i",
            ]
        ],
        on="band_id",
        how="left",
    )
    for column in [
        "later_home_market_presence_i",
        "later_home_market_top10_i",
    ]:
        audited_scene[column] = pd.to_numeric(audited_scene[column], errors="coerce").fillna(0).astype(int)

    audited_scene = audited_scene.loc[audited_scene["countryiso3code"].isin(audited_countries)].copy()
    gap_series = pd.to_numeric(diagnostics["chosen_reference_gap_years"], errors="coerce").dropna()

    horizon_lines: list[str] = []
    for horizon in [5, 10, 15, 20]:
        presence_within = (
            pd.to_numeric(audited_scene["home_market_presence_gap_years"], errors="coerce").between(0, horizon, inclusive="both")
        ).fillna(False)
        top10_within = (
            pd.to_numeric(audited_scene["home_market_top10_gap_years"], errors="coerce").between(0, horizon, inclusive="both")
        ).fillna(False)
        horizon_lines.append(
            f"- within `{horizon}` years of founding: `{int(presence_within.sum())}` presence cases and `{int(top10_within.sum())}` top-10 cases"
        )

    cohort_lines: list[str] = []
    for start_year in [1980, 1990, 1995, 2000, 2005]:
        cohort = audited_scene.loc[audited_scene["formed_year"] >= start_year].copy()
        cohort_lines.append(
            f"- founded `>= {start_year}`: `{len(cohort):,}` bands and `{int(cohort['later_home_market_presence_i'].sum())}` presence cases"
        )

    matched_lines = [
        f"- `{row.success_artist_name}` (`{row.artist_countryiso3code}`): formed `{int(row.chosen_formed_year)}`, first observed home-market success `{int(row.first_success_reference_year)}`, gap `{int(row.chosen_reference_gap_years)}` years"
        for row in diagnostics.sort_values("chosen_formed_year").itertuples(index=False)
    ]

    lines = [
        "# Band success design audit",
        "",
        "## Coverage scope",
        "",
        f"- audited home-market countries in the current sidecar: `{', '.join(audited_countries)}`",
        f"- matched success artists on the birth panel: `{int((coverage_audit['coverage_status'] == 'matched_birth_panel').sum())}`",
        f"- success artists still missing a usable birth-panel match: `{int((coverage_audit['coverage_status'] == 'missing_birth_panel_match').sum())}`",
        "",
        "## Timing gap audit",
        "",
        f"- median observed gap from founding to first home-market success: `{gap_series.median():.1f}` years",
        f"- minimum observed gap: `{int(gap_series.min())}` years",
        f"- maximum observed gap: `{int(gap_series.max())}` years",
        *horizon_lines,
        "",
        "## Cohort coverage",
        "",
        *cohort_lines,
        "",
        "## Matched success bands",
        "",
        *matched_lines,
        "",
        "## Design implication",
        "",
        "The current sidecar is now meaningfully wider, but the timing pattern still warns against a",
        "naive full-sample birth regression. Many matched successes are legacy bands with long lags",
        "between founding and the first observed home-market success signal. The next disciplined",
        "version should therefore use a bounded design such as success within a fixed horizon or a",
        "later-cohort restriction, rather than interpreting the full all-band birth panel at face value.",
    ]
    DESIGN_AUDIT_PATH.write_text("\n".join(lines), encoding="utf-8")


def write_summary(
    birth_stats: dict[str, int],
    scene_stats: dict[str, int],
    success_stats: dict[str, int],
    pilot_bins: pd.DataFrame,
    diagnostics: pd.DataFrame,
) -> None:
    overall_bins = pilot_bins.loc[pilot_bins["dimension"] == "overall_scene_bin"].copy()
    genre_bins = pilot_bins.loc[pilot_bins["dimension"] == "genre_scene_bin"].copy()

    def pilot_table(frame: pd.DataFrame, label: str) -> list[str]:
        lines = [f"### {label}", "", "| Bin | Bands | Presence rate | Certification rate | Top-10 rate |", "| --- | ---: | ---: | ---: | ---: |"]
        for _, row in frame.iterrows():
            lines.append(
                "| {bin_label} | {n_bands:,} | {presence:.2%} | {certification:.2%} | {top10:.2%} |".format(
                    bin_label=row["bin_label"],
                    n_bands=int(row["n_bands"]),
                    presence=float(row["presence_rate"]),
                    certification=float(row["certification_rate"]),
                    top10=float(row["top10_rate"]),
                )
            )
        lines.append("")
        return lines

    lines = [
        "# Band success sidecar summary",
        "",
        "## Sample construction",
        "",
        f"- Raw Metallum rows inspected: `{birth_stats['raw_bands']:,}`",
        f"- Rows with usable formed year: `{birth_stats['with_formed_year']:,}`",
        f"- Rows with recoverable city from notes: `{birth_stats['with_city']:,}`",
        f"- Rows with at least one broad genre-family match: `{birth_stats['with_primary_genre_family']:,}`",
        f"- Final `band_birth_panel` rows: `{birth_stats['birth_panel_rows']:,}`",
        f"- Multi-family birth-panel rows: `{birth_stats['multi_family_birth_panel_rows']:,}`",
        f"- Unique cities in birth panel: `{birth_stats['unique_city_country']:,}`",
        f"- Unique broad genre families in birth panel: `{birth_stats['unique_genre_family']:,}`",
        "",
        "## Pre-birth scene merge",
        "",
        f"- Exact overall scene matches at `formed_year - 1`: `{scene_stats['overall_scene_exact_matches']:,}`",
        f"- Exact network snapshot matches at `formed_year - 1`: `{scene_stats['network_scene_exact_matches']:,}`",
        f"- Exact target-genre scene matches at `formed_year - 1`: `{scene_stats['genre_scene_exact_matches']:,}`",
        f"- Rows with positive pre-birth overall active bands after zero-fill: `{scene_stats['rows_with_any_positive_overall_scene']:,}`",
        f"- Rows with positive pre-birth target-genre active bands after zero-fill: `{scene_stats['rows_with_any_positive_genre_scene']:,}`",
        "",
        "## Home-market success coverage",
        "",
        f"- Unique curated home-market success artists in the current core file: `{success_stats['home_market_success_artists']:,}`",
        f"- Success artists matched onto the birth panel: `{success_stats['matched_success_artists']:,}`",
        f"- Ambiguous name-country success matches: `{success_stats['ambiguous_success_artists']:,}`",
        f"- Birth-panel rows flagged with later home-market presence: `{success_stats['presence_success_rows']:,}`",
        f"- Birth-panel rows flagged with later home-market certification: `{success_stats['certification_success_rows']:,}`",
        f"- Birth-panel rows flagged with later home-market top-10: `{success_stats['top10_success_rows']:,}`",
        f"- Median gap from band founding to first observed home-market success among matched cases: `{pd.to_numeric(diagnostics['chosen_reference_gap_years'], errors='coerce').median():.1f}` years",
        "",
        "## Descriptive pilot",
        "",
        "The pilot bins bands by pre-birth scene thickness using `formed_year - 1` scene conditions.",
        "",
    ]
    lines.extend(pilot_table(overall_bins, "Later success by overall local scene thickness"))
    lines.extend(pilot_table(genre_bins, "Later success by target-genre local scene thickness"))

    SUMMARY_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    birth_panel, birth_stats = load_band_birth_panel()
    birth_panel.to_csv(BIRTH_PANEL_PATH, index=False)

    scene_panel, scene_stats = build_scene_at_birth_panel(birth_panel)
    scene_panel.to_csv(SCENE_AT_BIRTH_PATH, index=False)

    outcomes, diagnostics, coverage_audit, success_stats = build_success_match(birth_panel)
    outcomes.to_csv(SUCCESS_OUTCOME_PATH, index=False)
    diagnostics.to_csv(MATCH_DIAGNOSTIC_PATH, index=False)
    coverage_audit.to_csv(COVERAGE_AUDIT_PATH, index=False)

    pilot_bins = build_pilot_bins(scene_panel, outcomes)
    pilot_bins.to_csv(PILOT_BIN_PATH, index=False)

    write_design_audit(scene_panel, outcomes, diagnostics, coverage_audit)
    write_summary(birth_stats, scene_stats, success_stats, pilot_bins, diagnostics)

    print(f"Wrote {BIRTH_PANEL_PATH}")
    print(f"Wrote {SCENE_AT_BIRTH_PATH}")
    print(f"Wrote {SUCCESS_OUTCOME_PATH}")
    print(f"Wrote {MATCH_DIAGNOSTIC_PATH}")
    print(f"Wrote {COVERAGE_AUDIT_PATH}")
    print(f"Wrote {PILOT_BIN_PATH}")
    print(f"Wrote {DESIGN_AUDIT_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
