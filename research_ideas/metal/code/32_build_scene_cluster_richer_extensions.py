from __future__ import annotations

import csv
import re
from collections import defaultdict
from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

EDGE_PATH = SCENE_DIR / "full_musician_band_edges.csv"
SNAPSHOT_PATH = SCENE_DIR / "city_year_network_snapshots.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"

OVERALL_FEATURE_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
GENRE_FEATURE_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
RESULTS_PATH = SCENE_DIR / "scene_cluster_richer_extension_results.csv"
SUMMARY_PATH = SCENE_DIR / "scene_cluster_richer_extension_summary.md"

ROLE_CATEGORIES = ["guitar", "drums", "bass", "vocals", "keyboards"]
ROLLING_YEARS = 5

GUITAR_PATTERN = re.compile(r"guitar")
DRUM_PATTERN = re.compile(r"drum|percussion")
BASS_PATTERN = re.compile(r"\bbass\b")
VOCAL_PATTERN = re.compile(r"vocal")
KEYBOARD_PATTERN = re.compile(r"keyboard|synth|piano|organ")

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


def normalize_city_country(city: str, country: str) -> str:
    city = (city or "").strip()
    country = (country or "").strip()
    if not city:
        return ""
    return f"{city}, {country}" if country else city


def safe_int(value: object) -> int | None:
    if value is None or (isinstance(value, float) and np.isnan(value)):
        return None
    text = str(value).strip()
    if not text:
        return None
    try:
        return int(float(text))
    except ValueError:
        return None


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def classify_roles(role_text: str) -> tuple[str, ...]:
    text = (role_text or "").lower()
    roles: list[str] = []
    if GUITAR_PATTERN.search(text):
        roles.append("guitar")
    if DRUM_PATTERN.search(text):
        roles.append("drums")
    if BASS_PATTERN.search(text):
        roles.append("bass")
    if VOCAL_PATTERN.search(text):
        roles.append("vocals")
    if KEYBOARD_PATTERN.search(text):
        roles.append("keyboards")
    return tuple(sorted(set(roles)))


def parse_genre_families(genre_raw: str) -> tuple[str, ...]:
    text = (genre_raw or "").strip().lower()
    if not text:
        return tuple()
    families = []
    for key in GENRE_FAMILY_KEYS:
        if key in text:
            families.append(GENRE_FAMILIES[key])
    if not families and "metal" in text:
        families.append("other_metal")
    return tuple(sorted(set(families)))


def new_role_counter() -> dict[str, int]:
    return {role: 0 for role in ROLE_CATEGORIES}


def empty_role_counts() -> dict[str, int]:
    return {role: 0 for role in ROLE_CATEGORIES}


def load_project_frames() -> tuple[pd.DataFrame, pd.DataFrame, dict[int, list[str]], set[str], dict[str, list[str]]]:
    snapshots = pd.read_csv(SNAPSHOT_PATH)
    emergence = pd.read_csv(EMERGENCE_PATH)

    snapshots["snapshot_year"] = pd.to_numeric(snapshots["snapshot_year"], errors="coerce").astype(int)
    snapshots["n_active_bands"] = pd.to_numeric(snapshots["n_active_bands"], errors="coerce")
    snapshots["n_nontrivial_communities"] = pd.to_numeric(
        snapshots["n_nontrivial_communities"], errors="coerce"
    )

    for column in ["first_band_year", "emergence_year"]:
        emergence[column] = pd.to_numeric(emergence[column], errors="coerce")

    city_years_by_emit_year: dict[int, list[str]] = defaultdict(list)
    for row in snapshots[["city_country", "snapshot_year"]].itertuples(index=False):
        city_years_by_emit_year[int(row.snapshot_year)].append(str(row.city_country))

    eligible_cities = set(snapshots["city_country"].dropna().unique())
    target_genres_by_city: dict[str, list[str]] = {}
    grouped = emergence.loc[emergence["city_country"].isin(eligible_cities)].groupby("city_country")
    for city_country, frame in grouped:
        target_genres_by_city[str(city_country)] = sorted(frame["genre_family"].dropna().unique())

    return snapshots, emergence, city_years_by_emit_year, eligible_cities, target_genres_by_city


def load_edge_records(
    eligible_cities: set[str],
) -> tuple[list[tuple[str, str, str, int | None, int | None, tuple[str, ...]]], dict[str, dict[str, object]]]:
    edge_records: list[tuple[str, str, str, int | None, int | None, tuple[str, ...]]] = []
    band_meta: dict[str, dict[str, object]] = {}

    with EDGE_PATH.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            city_country = normalize_city_country(row.get("city", ""), row.get("country", ""))
            if city_country not in eligible_cities:
                continue

            band_id = (row.get("band_id") or "").strip()
            musician_id = (row.get("member_id") or "").strip() or (row.get("member_name") or "").strip()
            if not band_id or not musician_id:
                continue

            start_year = safe_int(row.get("first_year_in_band"))
            end_year = safe_int(row.get("last_year_in_band"))
            formed_year = safe_int(row.get("formed_year"))
            roles = classify_roles(row.get("role", ""))
            genre_families = parse_genre_families(row.get("genre_raw", ""))

            meta = band_meta.setdefault(
                band_id,
                {
                    "city_country": city_country,
                    "formed_year": formed_year,
                    "min_member_start": start_year,
                    "genre_families": set(genre_families),
                },
            )
            if meta["formed_year"] is None and formed_year is not None:
                meta["formed_year"] = formed_year
            elif meta["formed_year"] is not None and formed_year is not None:
                meta["formed_year"] = min(int(meta["formed_year"]), formed_year)

            if start_year is not None:
                if meta["min_member_start"] is None:
                    meta["min_member_start"] = start_year
                else:
                    meta["min_member_start"] = min(int(meta["min_member_start"]), start_year)
            meta["genre_families"].update(genre_families)

            edge_records.append((city_country, musician_id, band_id, start_year, end_year, roles))

    for meta in band_meta.values():
        entry_year = meta["formed_year"] if meta["formed_year"] is not None else meta["min_member_start"]
        meta["entry_year"] = entry_year
        meta["genre_families"] = tuple(sorted(meta["genre_families"]))

    return edge_records, band_meta


def compute_spawn_pedigree_flows(
    edge_records: list[tuple[str, str, str, int | None, int | None, tuple[str, ...]]],
    band_meta: dict[str, dict[str, object]],
) -> dict[tuple[str, int], dict[str, float]]:
    founding_members_by_band: dict[str, set[str]] = defaultdict(set)
    musician_histories: dict[str, dict[str, list[tuple[int, str]]]] = defaultdict(lambda: defaultdict(list))

    for city_country, musician_id, band_id, start_year, _, _ in edge_records:
        entry_year = safe_int(band_meta[band_id].get("entry_year"))
        if entry_year is None:
            continue
        membership_start = start_year if start_year is not None else entry_year
        musician_histories[city_country][musician_id].append((entry_year, band_id))
        if membership_start <= entry_year:
            founding_members_by_band[band_id].add(musician_id)

    founder_prior_counts_by_band: dict[str, list[int]] = defaultdict(list)
    for city_histories in musician_histories.values():
        for musician_id, events in city_histories.items():
            events_sorted = sorted(events, key=lambda item: (item[0], item[1]))
            prior_bands: set[str] = set()
            index = 0
            while index < len(events_sorted):
                current_year = events_sorted[index][0]
                current_bands: list[str] = []
                while index < len(events_sorted) and events_sorted[index][0] == current_year:
                    current_bands.append(events_sorted[index][1])
                    index += 1
                prior_count = len(prior_bands)
                for band_id in current_bands:
                    if musician_id in founding_members_by_band.get(band_id, set()):
                        founder_prior_counts_by_band[band_id].append(prior_count)
                prior_bands.update(current_bands)

    flows: dict[tuple[str, int], dict[str, float]] = defaultdict(
        lambda: {
            "bands_formed": 0.0,
            "spawn_bands_formed": 0.0,
            "founder_pedigree_sum": 0.0,
            "bands_with_founder_data": 0.0,
        }
    )
    for band_id, meta in band_meta.items():
        city_country = str(meta["city_country"])
        entry_year = safe_int(meta.get("entry_year"))
        if not city_country or entry_year is None:
            continue

        founder_prior_counts = founder_prior_counts_by_band.get(band_id, [])
        spawn_i = int(any(count > 0 for count in founder_prior_counts))
        mean_prior = float(np.mean(founder_prior_counts)) if founder_prior_counts else 0.0

        row = flows[(city_country, entry_year)]
        row["bands_formed"] += 1.0
        row["spawn_bands_formed"] += float(spawn_i)
        row["founder_pedigree_sum"] += mean_prior
        row["bands_with_founder_data"] += 1.0

    return flows


def build_dynamic_feature_frames(
    city_years_by_emit_year: dict[int, list[str]],
    target_genres_by_city: dict[str, list[str]],
    edge_records: list[tuple[str, str, str, int | None, int | None, tuple[str, ...]]],
    band_meta: dict[str, dict[str, object]],
    spawn_pedigree_flows: dict[tuple[str, int], dict[str, float]],
) -> tuple[pd.DataFrame, pd.DataFrame]:
    min_year = min(city_years_by_emit_year.keys())
    max_year = max(city_years_by_emit_year.keys())

    events_by_year: dict[int, list[tuple[str, str, str, tuple[str, ...], tuple[str, ...], int]]] = defaultdict(list)
    for city_country, musician_id, band_id, start_year, end_year, roles in edge_records:
        meta = band_meta[band_id]
        entry_year = safe_int(meta.get("entry_year"))
        if entry_year is None:
            continue
        start = start_year if start_year is not None else entry_year
        end = end_year if end_year is not None else max_year
        start = max(start, min_year)
        end = min(end, max_year)
        if end < start:
            continue

        genres = tuple(meta["genre_families"])
        events_by_year[start].append((city_country, musician_id, band_id, roles, genres, 1))
        if end + 1 <= max_year:
            events_by_year[end + 1].append((city_country, musician_id, band_id, roles, genres, -1))

    def new_city_state() -> dict[str, object]:
        return {
            "band_edge_counts": {},
            "active_musicians_total": 0,
            "multi_band_musicians_total": 0,
            "genre_band_counts": defaultdict(int),
            "genre_active_musicians": defaultdict(int),
            "genre_multi_band_musicians": defaultdict(int),
            "genre_broker_musicians": defaultdict(int),
            "genre_role_counts": defaultdict(new_role_counter),
            "musicians": {},
        }

    def new_musician_state() -> dict[str, object]:
        return {
            "bands": set(),
            "genre_counts": defaultdict(int),
            "role_genre_counts": defaultdict(new_role_counter),
        }

    city_states: dict[str, dict[str, object]] = {}
    overall_rows: list[dict[str, object]] = []
    genre_rows: list[dict[str, object]] = []

    for year in range(min_year, max_year + 1):
        for city_country, musician_id, band_id, roles, genres, delta in events_by_year.get(year, []):
            state = city_states.setdefault(city_country, new_city_state())

            band_edge_counts: dict[str, int] = state["band_edge_counts"]  # type: ignore[assignment]
            old_band_edges = band_edge_counts.get(band_id, 0)
            new_band_edges = max(0, old_band_edges + delta)
            if old_band_edges == 0 and new_band_edges > 0:
                for genre_family in genres:
                    state["genre_band_counts"][genre_family] += 1  # type: ignore[index]
            elif old_band_edges > 0 and new_band_edges == 0:
                for genre_family in genres:
                    counts = state["genre_band_counts"]  # type: ignore[assignment]
                    counts[genre_family] -= 1
                    if counts[genre_family] <= 0:
                        del counts[genre_family]
            if new_band_edges == 0:
                band_edge_counts.pop(band_id, None)
            else:
                band_edge_counts[band_id] = new_band_edges

            musicians: dict[str, dict[str, object]] = state["musicians"]  # type: ignore[assignment]
            musician_state = musicians.setdefault(musician_id, new_musician_state())
            bands: set[str] = musician_state["bands"]  # type: ignore[assignment]
            genre_counts: dict[str, int] = musician_state["genre_counts"]  # type: ignore[assignment]
            role_genre_counts: dict[str, dict[str, int]] = musician_state["role_genre_counts"]  # type: ignore[assignment]

            old_total_band_count = len(bands)
            old_genre_counts = {genre_family: count for genre_family, count in genre_counts.items() if count > 0}
            old_role_counts = {
                genre_family: role_genre_counts.get(genre_family, empty_role_counts()).copy()
                for genre_family in genres
            }

            if delta == 1:
                bands.add(band_id)
                for genre_family in genres:
                    genre_counts[genre_family] += 1
                    role_counter = role_genre_counts.setdefault(genre_family, new_role_counter())
                    for role in roles:
                        role_counter[role] += 1
            else:
                bands.discard(band_id)
                for genre_family in genres:
                    if genre_family in genre_counts:
                        genre_counts[genre_family] = max(0, genre_counts[genre_family] - 1)
                        if genre_counts[genre_family] == 0:
                            del genre_counts[genre_family]
                    role_counter = role_genre_counts.get(genre_family)
                    if role_counter is not None:
                        for role in roles:
                            role_counter[role] = max(0, role_counter[role] - 1)
                        if all(value == 0 for value in role_counter.values()):
                            del role_genre_counts[genre_family]

            new_total_band_count = len(bands)
            new_genre_counts = {genre_family: count for genre_family, count in genre_counts.items() if count > 0}

            old_active_total = old_total_band_count > 0
            new_active_total = new_total_band_count > 0
            old_multi_total = old_total_band_count >= 2
            new_multi_total = new_total_band_count >= 2

            if not old_active_total and new_active_total:
                state["active_musicians_total"] = int(state["active_musicians_total"]) + 1
            elif old_active_total and not new_active_total:
                state["active_musicians_total"] = int(state["active_musicians_total"]) - 1

            if not old_multi_total and new_multi_total:
                state["multi_band_musicians_total"] = int(state["multi_band_musicians_total"]) + 1
            elif old_multi_total and not new_multi_total:
                state["multi_band_musicians_total"] = int(state["multi_band_musicians_total"]) - 1

            all_genres = set(old_genre_counts) | set(new_genre_counts)
            old_total_genres = len(old_genre_counts)
            new_total_genres = len(new_genre_counts)
            for genre_family in all_genres:
                old_count = old_genre_counts.get(genre_family, 0)
                new_count = new_genre_counts.get(genre_family, 0)

                old_has = old_count > 0
                new_has = new_count > 0
                old_multi = old_count >= 2
                new_multi = new_count >= 2
                old_broker = old_has and old_total_genres >= 2
                new_broker = new_has and new_total_genres >= 2

                active_counts = state["genre_active_musicians"]  # type: ignore[assignment]
                multi_counts = state["genre_multi_band_musicians"]  # type: ignore[assignment]
                broker_counts = state["genre_broker_musicians"]  # type: ignore[assignment]

                if not old_has and new_has:
                    active_counts[genre_family] += 1
                elif old_has and not new_has:
                    active_counts[genre_family] -= 1
                    if active_counts[genre_family] <= 0:
                        del active_counts[genre_family]

                if not old_multi and new_multi:
                    multi_counts[genre_family] += 1
                elif old_multi and not new_multi:
                    multi_counts[genre_family] -= 1
                    if multi_counts[genre_family] <= 0:
                        del multi_counts[genre_family]

                if not old_broker and new_broker:
                    broker_counts[genre_family] += 1
                elif old_broker and not new_broker:
                    broker_counts[genre_family] -= 1
                    if broker_counts[genre_family] <= 0:
                        del broker_counts[genre_family]

            for genre_family in genres:
                old_role_counter = old_role_counts.get(genre_family, empty_role_counts())
                new_role_counter_map = role_genre_counts.get(genre_family, empty_role_counts())
                city_role_counter = state["genre_role_counts"][genre_family]  # type: ignore[index]
                for role in ROLE_CATEGORIES:
                    old_has_role = old_role_counter.get(role, 0) > 0
                    new_has_role = new_role_counter_map.get(role, 0) > 0
                    if not old_has_role and new_has_role:
                        city_role_counter[role] += 1
                    elif old_has_role and not new_has_role:
                        city_role_counter[role] -= 1
                if all(value <= 0 for value in city_role_counter.values()):
                    del state["genre_role_counts"][genre_family]  # type: ignore[index]

            if not new_active_total:
                musicians.pop(musician_id, None)

        for city_country in city_years_by_emit_year.get(year, []):
            state = city_states.get(city_country)
            active_multi_band_musicians = int(state["multi_band_musicians_total"]) if state is not None else 0

            flow_row = spawn_pedigree_flows.get((city_country, year), None)
            bands_formed = float(flow_row["bands_formed"]) if flow_row is not None else 0.0
            spawn_bands_formed = float(flow_row["spawn_bands_formed"]) if flow_row is not None else 0.0
            founder_pedigree_mean = (
                float(flow_row["founder_pedigree_sum"]) / float(flow_row["bands_with_founder_data"])
                if flow_row is not None and float(flow_row["bands_with_founder_data"]) > 0
                else 0.0
            )
            overall_rows.append(
                {
                    "city_country": city_country,
                    "snapshot_year": year,
                    "n_multi_band_musicians_total": active_multi_band_musicians,
                    "bands_formed": bands_formed,
                    "spawn_bands_formed": spawn_bands_formed,
                    "spawn_share_formed": spawn_bands_formed / bands_formed if bands_formed > 0 else 0.0,
                    "founder_pedigree_mean": founder_pedigree_mean,
                }
            )

            for genre_family in target_genres_by_city.get(city_country, []):
                if state is None:
                    row = {
                        "city_country": city_country,
                        "snapshot_year": year,
                        "genre_family": genre_family,
                        "genre_active_bands": 0,
                        "genre_active_musicians": 0,
                        "genre_multi_band_musicians": 0,
                        "genre_broker_musicians": 0,
                        "genre_broker_share": 0.0,
                        "genre_multi_band_share": 0.0,
                    }
                    for role in ROLE_CATEGORIES:
                        row[f"genre_active_{role}_musicians"] = 0
                    genre_rows.append(row)
                    continue

                active_bands = int(state["genre_band_counts"].get(genre_family, 0))  # type: ignore[index]
                active_musicians = int(state["genre_active_musicians"].get(genre_family, 0))  # type: ignore[index]
                multi_band_musicians = int(state["genre_multi_band_musicians"].get(genre_family, 0))  # type: ignore[index]
                broker_musicians = int(state["genre_broker_musicians"].get(genre_family, 0))  # type: ignore[index]
                role_counts = state["genre_role_counts"].get(genre_family, empty_role_counts())  # type: ignore[index]

                row = {
                    "city_country": city_country,
                    "snapshot_year": year,
                    "genre_family": genre_family,
                    "genre_active_bands": active_bands,
                    "genre_active_musicians": active_musicians,
                    "genre_multi_band_musicians": multi_band_musicians,
                    "genre_broker_musicians": broker_musicians,
                    "genre_broker_share": broker_musicians / active_musicians if active_musicians > 0 else 0.0,
                    "genre_multi_band_share": (
                        multi_band_musicians / active_musicians if active_musicians > 0 else 0.0
                    ),
                }
                for role in ROLE_CATEGORIES:
                    row[f"genre_active_{role}_musicians"] = int(role_counts.get(role, 0))
                genre_rows.append(row)

    overall_features = pd.DataFrame(overall_rows).sort_values(["city_country", "snapshot_year"]).reset_index(drop=True)
    genre_features = pd.DataFrame(genre_rows).sort_values(
        ["city_country", "genre_family", "snapshot_year"]
    ).reset_index(drop=True)
    return overall_features, genre_features


def add_rolling_features(overall_features: pd.DataFrame, genre_features: pd.DataFrame, snapshots: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    snapshot_base = snapshots[["city_country", "snapshot_year", "n_active_bands", "n_nontrivial_communities"]].copy()
    overall = snapshot_base.merge(overall_features, on=["city_country", "snapshot_year"], how="left")
    overall = overall.fillna(
        {
            "n_multi_band_musicians_total": 0,
            "bands_formed": 0,
            "spawn_bands_formed": 0,
            "spawn_share_formed": 0.0,
            "founder_pedigree_mean": 0.0,
        }
    )
    overall["log_active_bands"] = np.log1p(overall["n_active_bands"])
    overall["log_multi_band_musicians_total"] = np.log1p(overall["n_multi_band_musicians_total"])
    overall["log_spawn_bands_formed"] = np.log1p(overall["spawn_bands_formed"])
    overall = overall.sort_values(["city_country", "snapshot_year"]).reset_index(drop=True)

    overall_roll_cols = [
        "log_active_bands",
        "n_nontrivial_communities",
        "log_multi_band_musicians_total",
        "log_spawn_bands_formed",
        "spawn_share_formed",
        "founder_pedigree_mean",
    ]
    min_periods = max(2, ROLLING_YEARS - 1)
    for column in overall_roll_cols:
        overall[f"roll{ROLLING_YEARS}_{column}"] = overall.groupby("city_country")[column].transform(
            lambda series: series.shift(1).rolling(ROLLING_YEARS, min_periods=min_periods).mean()
        )

    genre = genre_features.copy()
    for column in [
        "genre_active_bands",
        "genre_active_musicians",
        "genre_multi_band_musicians",
        "genre_broker_musicians",
    ]:
        genre[f"log_{column}"] = np.log1p(genre[column])
    for role in ROLE_CATEGORIES:
        genre[f"log_genre_active_{role}_musicians"] = np.log1p(genre[f"genre_active_{role}_musicians"])

    genre = genre.sort_values(["city_country", "genre_family", "snapshot_year"]).reset_index(drop=True)
    genre_roll_cols = [
        "log_genre_active_bands",
        "log_genre_active_musicians",
        "log_genre_multi_band_musicians",
        "log_genre_broker_musicians",
        "genre_broker_share",
        "genre_multi_band_share",
    ] + [f"log_genre_active_{role}_musicians" for role in ROLE_CATEGORIES]
    for column in genre_roll_cols:
        genre[f"roll{ROLLING_YEARS}_{column}"] = genre.groupby(["city_country", "genre_family"])[column].transform(
            lambda series: series.shift(1).rolling(ROLLING_YEARS, min_periods=min_periods).mean()
        )

    return overall, genre


def build_panel(overall_features: pd.DataFrame, genre_features: pd.DataFrame, emergence: pd.DataFrame) -> pd.DataFrame:
    emergence_small = emergence[["city_country", "genre_family", "first_band_year", "emergence_year"]].copy()
    panel = overall_features.merge(emergence_small, on="city_country", how="inner").merge(
        genre_features,
        on=["city_country", "snapshot_year", "genre_family"],
        how="left",
    )
    panel["emerge_this_year"] = (
        panel["emergence_year"].notna() & panel["emergence_year"].eq(panel["snapshot_year"])
    ).astype(int)
    panel = panel.loc[
        panel["first_band_year"].notna()
        & (panel["snapshot_year"] >= panel["first_band_year"])
        & (panel["emergence_year"].isna() | (panel["snapshot_year"] <= panel["emergence_year"]))
    ].copy()
    return panel


def fit_panel_spec(
    panel: pd.DataFrame,
    spec_id: str,
    extra_predictors: list[str],
    spec_note: str,
) -> tuple[pd.DataFrame, dict[str, object]]:
    base_predictors = [
        f"roll{ROLLING_YEARS}_log_active_bands",
        f"roll{ROLLING_YEARS}_n_nontrivial_communities",
        f"roll{ROLLING_YEARS}_log_multi_band_musicians_total",
    ]
    required_predictors = base_predictors + extra_predictors

    sample = panel.copy()
    for predictor in required_predictors:
        sample = sample.loc[sample[predictor].notna()].copy()

    sample["cell_id"] = sample["city_country"].astype(str) + " || " + sample["genre_family"].astype(str)
    active_predictors: list[str] = []
    dropped_predictors: list[str] = []
    for predictor in required_predictors:
        z_name = f"z_{predictor}"
        z_values = zscore(sample[predictor])
        if float(z_values.std(ddof=0)) == 0.0:
            dropped_predictors.append(predictor)
            continue
        sample[z_name] = z_values
        active_predictors.append(z_name)

    sample = sample.set_index(["cell_id", "snapshot_year"]).sort_index()
    clusters = pd.DataFrame(
        {"city_cluster": sample.reset_index()["cell_id"].str.split(" \\|\\| ").str[0].values},
        index=sample.index,
    )

    result = PanelOLS(
        sample["emerge_this_year"],
        sample[active_predictors],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=clusters)

    rows: list[dict[str, object]] = []
    for predictor in required_predictors:
        z_name = f"z_{predictor}"
        if z_name not in result.params.index:
            rows.append(
                {
                    "spec_id": spec_id,
                    "predictor": z_name,
                    "coefficient": np.nan,
                    "std_error": np.nan,
                    "p_value": np.nan,
                    "n_obs": int(result.nobs),
                    "event_count": int(sample["emerge_this_year"].sum()),
                    "event_rate": float(sample["emerge_this_year"].mean()),
                    "fixed_effects": "city-genre + year",
                    "clustering": "city",
                    "spec_note": spec_note,
                    "dropped_i": 1,
                }
            )
            continue
        rows.append(
            {
                "spec_id": spec_id,
                "predictor": z_name,
                "coefficient": float(result.params[z_name]),
                "std_error": float(result.std_errors[z_name]),
                "p_value": float(result.pvalues[z_name]),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emerge_this_year"].sum()),
                "event_rate": float(sample["emerge_this_year"].mean()),
                "fixed_effects": "city-genre + year",
                "clustering": "city",
                "spec_note": spec_note,
                "dropped_i": 0,
            }
        )

    metadata = {
        "spec_id": spec_id,
        "title": spec_note,
        "n_obs": int(result.nobs),
        "event_count": int(sample["emerge_this_year"].sum()),
        "event_rate": float(sample["emerge_this_year"].mean()),
        "r_squared": float(result.rsquared),
        "dropped_predictors": dropped_predictors,
    }
    return pd.DataFrame(rows), metadata


def significance_stars(p_value: float) -> str:
    if pd.isna(p_value):
        return ""
    if p_value < 0.01:
        return "***"
    if p_value < 0.05:
        return "**"
    if p_value < 0.10:
        return "*"
    return ""


def format_stat(value: float, digits: int = 4) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def write_summary(
    overall_features: pd.DataFrame,
    genre_features: pd.DataFrame,
    results: pd.DataFrame,
    metadata_rows: list[dict[str, object]],
) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Scene cluster richer extension summary\n\n")
        handle.write(
            "This file extends the scene-cluster branch with four richer predictor families: "
            "local spawning, founder pedigree, genre-targeted labor pools, and genre-targeted "
            "broker musicians.\n\n"
        )

        handle.write("## Measurement notes\n\n")
        handle.write(
            "- `spawn_bands_formed` counts bands whose founding cohort includes at least one musician "
            "with a prior local-band history in the same city.\n"
        )
        handle.write(
            "- `founder_pedigree_mean` is the average count of prior local bands among the founding "
            "members observed for bands formed in that city-year.\n"
        )
        handle.write(
            "- Genre-targeted labor-pool counts are built at `city x genre_family x year` using the "
            "same broad family parser already used in the scene-timing branch.\n"
        )
        handle.write(
            "- `genre_broker_musicians` counts local musicians active in the target genre and at least "
            "one other active genre in the same city-year.\n\n"
        )

        overall_nonzero = overall_features.loc[overall_features["bands_formed"] > 0].copy()
        handle.write("## Descriptive read\n\n")
        handle.write(
            f"- City-year rows with any observed band formation flow: `{len(overall_nonzero)}`\n"
        )
        if not overall_nonzero.empty:
            handle.write(
                f"- Mean spawn share among nonzero-formation city-years: "
                f"`{overall_nonzero['spawn_share_formed'].mean():.3f}`\n"
            )
            handle.write(
                f"- Mean founder pedigree among nonzero-formation city-years: "
                f"`{overall_nonzero['founder_pedigree_mean'].mean():.3f}` prior local bands\n"
            )
        handle.write(f"- Genre-targeted rows written: `{len(genre_features)}`\n")
        handle.write(
            f"- Mean active bands within a target genre-cell: "
            f"`{genre_features['genre_active_bands'].mean():.3f}`\n"
        )
        handle.write(
            f"- Mean broker-musician share within active target genre-cells: "
            f"`{genre_features.loc[genre_features['genre_active_musicians'] > 0, 'genre_broker_share'].mean():.3f}`\n\n"
        )

        handle.write("## FE specs\n\n")
        handle.write("| Spec | N | Events | Event rate | R-squared |\n")
        handle.write("|------|---|--------|------------|-----------|\n")
        for meta in metadata_rows:
            handle.write(
                f"| {meta['title']} | {meta['n_obs']} | {meta['event_count']} | "
                f"{meta['event_rate']:.4f} | {meta['r_squared']:.4f} |\n"
            )

        for meta in metadata_rows:
            subset = results.loc[results["spec_id"].eq(meta["spec_id"])].copy()
            handle.write(f"\n### {meta['title']}\n\n")
            if meta["dropped_predictors"]:
                dropped_text = ", ".join(f"`{value}`" for value in meta["dropped_predictors"])
                handle.write(f"- Dropped zero-variance predictors: {dropped_text}\n\n")
            handle.write("| Predictor | Coef | SE | P-value |\n")
            handle.write("|-----------|------|----|---------|\n")
            for _, row in subset.iterrows():
                coef = (
                    f"{row['coefficient']:.4f}{significance_stars(float(row['p_value']))}"
                    if not pd.isna(row["coefficient"])
                    else "n/a"
                )
                se = f"{row['std_error']:.4f}" if not pd.isna(row["std_error"]) else "n/a"
                p_value = f"{row['p_value']:.4f}" if not pd.isna(row["p_value"]) else "n/a"
                handle.write(f"| {row['predictor']} | {coef} | {se} | {p_value} |\n")

        def coef(spec_id: str, predictor: str) -> float:
            subset = results.loc[
                results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "coefficient"
            ]
            return float(subset.iloc[0]) if not subset.empty else np.nan

        def pval(spec_id: str, predictor: str) -> float:
            subset = results.loc[
                results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "p_value"
            ]
            return float(subset.iloc[0]) if not subset.empty else np.nan

        role_signal = sorted(
            [
                (
                    role,
                    abs(coef(f"genre_role_{role}_fe", f"z_roll{ROLLING_YEARS}_log_genre_active_{role}_musicians")),
                    coef(f"genre_role_{role}_fe", f"z_roll{ROLLING_YEARS}_log_genre_active_{role}_musicians"),
                    pval(f"genre_role_{role}_fe", f"z_roll{ROLLING_YEARS}_log_genre_active_{role}_musicians"),
                )
                for role in ROLE_CATEGORIES
            ],
            key=lambda item: (-np.nan_to_num(item[1], nan=-1.0), item[0]),
        )
        top_role = role_signal[0]

        handle.write("\n## Current read\n\n")
        handle.write(
            f"- In the spawning and pedigree spec, "
            f"`z_roll{ROLLING_YEARS}_log_spawn_bands_formed = "
            f"{format_stat(coef('spawn_pedigree_fe', f'z_roll{ROLLING_YEARS}_log_spawn_bands_formed'))}` "
            f"(p = {format_stat(pval('spawn_pedigree_fe', f'z_roll{ROLLING_YEARS}_log_spawn_bands_formed'))}) and "
            f"`z_roll{ROLLING_YEARS}_founder_pedigree_mean = "
            f"{format_stat(coef('spawn_pedigree_fe', f'z_roll{ROLLING_YEARS}_founder_pedigree_mean'))}` "
            f"(p = {format_stat(pval('spawn_pedigree_fe', f'z_roll{ROLLING_YEARS}_founder_pedigree_mean'))}).\n"
        )
        handle.write(
            f"- The first genre-targeted labor-pool check says "
            f"`z_roll{ROLLING_YEARS}_log_genre_active_bands = "
            f"{format_stat(coef('genre_targeted_pool_fe', f'z_roll{ROLLING_YEARS}_log_genre_active_bands'))}` "
            f"and `z_roll{ROLLING_YEARS}_log_genre_active_musicians = "
            f"{format_stat(coef('genre_targeted_pool_fe', f'z_roll{ROLLING_YEARS}_log_genre_active_musicians'))}` "
            f"in the same exact-year FE frame.\n"
        )
        handle.write(
            f"- The first broker-musician pass says "
            f"`z_roll{ROLLING_YEARS}_log_genre_broker_musicians = "
            f"{format_stat(coef('genre_targeted_broker_fe', f'z_roll{ROLLING_YEARS}_log_genre_broker_musicians'))}` "
            f"(p = {format_stat(pval('genre_targeted_broker_fe', f'z_roll{ROLLING_YEARS}_log_genre_broker_musicians'))}), "
            f"while `z_roll{ROLLING_YEARS}_genre_broker_share = "
            f"{format_stat(coef('genre_targeted_broker_fe', f'z_roll{ROLLING_YEARS}_genre_broker_share'))}` "
            f"(p = {format_stat(pval('genre_targeted_broker_fe', f'z_roll{ROLLING_YEARS}_genre_broker_share'))}).\n"
        )
        handle.write(
            f"- Within-genre switcher mass is measured separately from cross-genre brokerage. "
            f"In the target-genre switcher spec, `z_roll{ROLLING_YEARS}_log_genre_multi_band_musicians = "
            f"{format_stat(coef('genre_targeted_switcher_fe', f'z_roll{ROLLING_YEARS}_log_genre_multi_band_musicians'))}` "
            f"and `z_roll{ROLLING_YEARS}_genre_multi_band_share = "
            f"{format_stat(coef('genre_targeted_switcher_fe', f'z_roll{ROLLING_YEARS}_genre_multi_band_share'))}`.\n"
        )
        handle.write(
            f"- The strongest role-targeted labor-pool term in this first pass is `{top_role[0]}`, "
            f"with coefficient `{format_stat(top_role[2])}` and p-value `{format_stat(top_role[3])}`.\n"
        )
        handle.write(
            "- This remains a predictive panel design, not a causal identification strategy. The value "
            "of the new pass is that the scene branch now speaks more directly to spinouts, experience, "
            "and target-genre labor pools rather than only whole-city thickness.\n"
        )


def main() -> None:
    snapshots, emergence, city_years_by_emit_year, eligible_cities, target_genres_by_city = load_project_frames()
    edge_records, band_meta = load_edge_records(eligible_cities)
    spawn_pedigree_flows = compute_spawn_pedigree_flows(edge_records, band_meta)
    overall_features_raw, genre_features_raw = build_dynamic_feature_frames(
        city_years_by_emit_year=city_years_by_emit_year,
        target_genres_by_city=target_genres_by_city,
        edge_records=edge_records,
        band_meta=band_meta,
        spawn_pedigree_flows=spawn_pedigree_flows,
    )
    overall_features, genre_features = add_rolling_features(
        overall_features=overall_features_raw,
        genre_features=genre_features_raw,
        snapshots=snapshots,
    )
    panel = build_panel(overall_features, genre_features, emergence)

    overall_features.to_csv(OVERALL_FEATURE_PATH, index=False)
    genre_features.to_csv(GENRE_FEATURE_PATH, index=False)

    specs = [
        (
            "spawn_pedigree_fe",
            [
                f"roll{ROLLING_YEARS}_log_spawn_bands_formed",
                f"roll{ROLLING_YEARS}_spawn_share_formed",
                f"roll{ROLLING_YEARS}_founder_pedigree_mean",
            ],
            "Exact-year FE with local spawning and founder pedigree",
        ),
        (
            "genre_targeted_pool_fe",
            [
                f"roll{ROLLING_YEARS}_log_genre_active_bands",
                f"roll{ROLLING_YEARS}_log_genre_active_musicians",
            ],
            "Exact-year FE with target-genre labor-pool levels",
        ),
        (
            "genre_targeted_broker_fe",
            [
                f"roll{ROLLING_YEARS}_log_genre_active_bands",
                f"roll{ROLLING_YEARS}_log_genre_broker_musicians",
                f"roll{ROLLING_YEARS}_genre_broker_share",
            ],
            "Exact-year FE with target-genre broker musicians",
        ),
        (
            "genre_targeted_switcher_fe",
            [
                f"roll{ROLLING_YEARS}_log_genre_active_bands",
                f"roll{ROLLING_YEARS}_log_genre_multi_band_musicians",
                f"roll{ROLLING_YEARS}_genre_multi_band_share",
            ],
            "Exact-year FE with target-genre switcher depth",
        ),
    ]
    for role in ROLE_CATEGORIES:
        specs.append(
            (
                f"genre_role_{role}_fe",
                [
                    f"roll{ROLLING_YEARS}_log_genre_active_bands",
                    f"roll{ROLLING_YEARS}_log_genre_active_{role}_musicians",
                ],
                f"Exact-year FE with target-genre {role} labor pool",
            )
        )

    result_frames: list[pd.DataFrame] = []
    metadata_rows: list[dict[str, object]] = []
    for spec_id, extra_predictors, spec_note in specs:
        result_frame, metadata = fit_panel_spec(panel, spec_id, extra_predictors, spec_note)
        result_frames.append(result_frame)
        metadata_rows.append(metadata)

    results = pd.concat(result_frames, ignore_index=True)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(
        overall_features=overall_features,
        genre_features=genre_features,
        results=results,
        metadata_rows=metadata_rows,
    )

    print(f"Wrote {OVERALL_FEATURE_PATH}")
    print(f"Wrote {GENRE_FEATURE_PATH}")
    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
