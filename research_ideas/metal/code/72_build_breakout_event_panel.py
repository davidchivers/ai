from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
SCENE_DIR = PROCESSED_DIR / "scene_networks"
COUNTRY_GENRE_DIR = PROCESSED_DIR / "country_genre_analysis"

EVENT_PATH = COUNTRY_GENRE_DIR / "breakout_event_file.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
OVERALL_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
GENRE_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
BAND_PATH = PROCESSED_DIR / "metal_archives_all_metal_band_clean.csv"

OUTPUT_PANEL_PATH = COUNTRY_GENRE_DIR / "city_genre_breakout_event_panel.csv"
OUTPUT_CAPABILITY_PATH = COUNTRY_GENRE_DIR / "city_genre_breakout_capability.csv"
OUTPUT_SUMMARY_PATH = COUNTRY_GENRE_DIR / "breakout_branch_panel_summary.md"

EVENT_WINDOW = 5

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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build a stacked breakout-event city-genre panel.")
    parser.add_argument("--event-path", type=Path, default=EVENT_PATH, help="Input breakout event file.")
    parser.add_argument("--output-panel-path", type=Path, default=OUTPUT_PANEL_PATH, help="Output stacked panel CSV.")
    parser.add_argument(
        "--output-capability-path",
        type=Path,
        default=OUTPUT_CAPABILITY_PATH,
        help="Output pre-shock capability CSV.",
    )
    parser.add_argument("--output-summary-path", type=Path, default=OUTPUT_SUMMARY_PATH, help="Output markdown summary.")
    return parser.parse_args()


def extract_city(notes_str: str) -> str:
    if not isinstance(notes_str, str) or not notes_str:
        return ""
    match = re.search(r"location=([^;]+)", notes_str)
    if not match:
        return ""
    parts = [part.strip() for part in match.group(1).strip().split(",")]
    return parts[0] if parts else ""


def normalize_city_country(city: str, country: str) -> str:
    city = (city or "").strip()
    country = (country or "").strip()
    if not city:
        return ""
    return f"{city}, {country}" if country else city


def parse_genre_families(genre_raw: str) -> tuple[str, ...]:
    text = (genre_raw or "").strip().lower()
    if not text:
        return tuple()
    families: list[str] = []
    for key in GENRE_FAMILY_KEYS:
        if key in text:
            families.append(GENRE_FAMILIES[key])
    if not families and "metal" in text:
        families.append("other_metal")
    return tuple(sorted(set(families)))


def assign_capability_bins(frame: pd.DataFrame) -> pd.Series:
    if frame.empty:
        return pd.Series(dtype="object")
    scores = frame["pre_shock_capability_score"].fillna(0)
    if scores.nunique(dropna=False) <= 1:
        return pd.Series("flat_capability", index=frame.index, dtype="object")
    bins = pd.Series("low_capability", index=frame.index, dtype="object")
    positive = scores.loc[scores.gt(0)]
    if positive.empty:
        return pd.Series("flat_capability", index=frame.index, dtype="object")
    if positive.nunique(dropna=False) <= 1 or len(positive) < 3:
        bins.loc[positive.index] = "high_capability"
        return bins

    positive_median = positive.median()
    bins.loc[positive.index] = "mid_capability"
    high_mask = positive.gt(positive_median)
    bins.loc[high_mask[high_mask].index] = "high_capability"

    if not bins.eq("high_capability").any():
        top_positive_index = positive.sort_values(kind="mergesort").index[-1]
        bins.loc[top_positive_index] = "high_capability"

    return bins


def filter_supported_events(events: pd.DataFrame, valid_genres: set[str]) -> pd.DataFrame:
    supported = events["primary_genre"].isin(valid_genres)
    dropped = events.loc[~supported].copy()
    if not dropped.empty:
        dropped_ids = ", ".join(dropped["event_id"].tolist())
        print(
            "Dropped breakout events outside the live scene taxonomy: "
            f"{dropped_ids}"
        )
    filtered = events.loc[supported].copy()
    if filtered.empty:
        raise ValueError("No breakout events remain after scene-taxonomy validation.")
    return filtered.sort_values(["priority_rank", "event_id"]).reset_index(drop=True)


def load_event_file(event_path: Path) -> pd.DataFrame:
    events = pd.read_csv(event_path)
    events["priority_rank"] = pd.to_numeric(events["priority_rank"], errors="coerce").astype(int)
    events["event_year"] = pd.to_numeric(events["event_year"], errors="coerce").astype(int)
    return events.sort_values(["priority_rank", "event_id"]).reset_index(drop=True)


def load_city_lookup() -> pd.DataFrame:
    emergence = pd.read_csv(EMERGENCE_PATH)
    city_lookup = (
        emergence[["city", "country", "city_country"]]
        .dropna(subset=["city_country"])
        .drop_duplicates()
        .sort_values(["country", "city"])
        .reset_index(drop=True)
    )
    return city_lookup


def load_scene_frames() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    overall = pd.read_csv(OVERALL_PATH)
    genre = pd.read_csv(GENRE_PATH)
    emergence = pd.read_csv(EMERGENCE_PATH)

    overall["snapshot_year"] = pd.to_numeric(overall["snapshot_year"], errors="coerce").astype(int)
    genre["snapshot_year"] = pd.to_numeric(genre["snapshot_year"], errors="coerce").astype(int)

    overall = overall.rename(
        columns={
            "snapshot_year": "calendar_year",
            "n_active_bands": "city_total_active_bands",
            "bands_formed": "city_total_band_starts",
            "spawn_bands_formed": "city_total_spawn_bands_formed",
            "n_multi_band_musicians_total": "city_total_multi_band_musicians",
        }
    )[
        [
            "city_country",
            "calendar_year",
            "city_total_active_bands",
            "city_total_band_starts",
            "city_total_spawn_bands_formed",
            "city_total_multi_band_musicians",
        ]
    ]

    genre = genre.rename(
        columns={
            "snapshot_year": "calendar_year",
            "genre_active_bands": "local_genre_active_bands",
            "genre_active_musicians": "local_genre_active_musicians",
            "genre_multi_band_musicians": "local_genre_multi_band_musicians",
        }
    )[
        [
            "city_country",
            "calendar_year",
            "genre_family",
            "local_genre_active_bands",
            "local_genre_active_musicians",
            "local_genre_multi_band_musicians",
        ]
    ]

    emergence["first_band_year"] = pd.to_numeric(emergence["first_band_year"], errors="coerce")
    emergence["emergence_year"] = pd.to_numeric(emergence["emergence_year"], errors="coerce")
    emergence = emergence[
        [
            "city",
            "country",
            "city_country",
            "genre_family",
            "first_band_year",
            "emergence_year",
            "total_bands",
        ]
    ]

    return overall, genre, emergence


def build_local_genre_starts() -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    with BAND_PATH.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            city = extract_city(row.get("notes", ""))
            country = (row.get("country_std") or "").strip()
            formed_text = (row.get("formed_year") or "").strip()
            if not city or not formed_text:
                continue
            try:
                formed_year = int(float(formed_text))
            except ValueError:
                continue

            city_country = normalize_city_country(city, country)
            if not city_country:
                continue

            genre_families = parse_genre_families(row.get("genre_raw", ""))
            for genre_family in genre_families:
                rows.append(
                    {
                        "city_country": city_country,
                        "genre_family": genre_family,
                        "calendar_year": formed_year,
                    }
                )

    starts = (
        pd.DataFrame(rows)
        .groupby(["city_country", "genre_family", "calendar_year"], as_index=False)
        .size()
        .rename(columns={"size": "local_genre_band_starts"})
    )
    return starts


def build_event_panel(
    events: pd.DataFrame,
    city_lookup: pd.DataFrame,
    overall: pd.DataFrame,
    genre: pd.DataFrame,
    emergence: pd.DataFrame,
    starts: pd.DataFrame,
) -> pd.DataFrame:
    panel_parts: list[pd.DataFrame] = []

    for event in events.itertuples(index=False):
        country_cities = city_lookup.loc[city_lookup["country"].eq(event.country_name)].copy()
        years = pd.DataFrame({"relative_event_year": list(range(-EVENT_WINDOW, EVENT_WINDOW + 1))})
        years["calendar_year"] = years["relative_event_year"] + int(event.event_year)

        base = country_cities.assign(_merge_key=1).merge(years.assign(_merge_key=1), on="_merge_key", how="inner")
        base = base.drop(columns="_merge_key")
        base["event_id"] = event.event_id
        base["priority_rank"] = int(event.priority_rank)
        base["market_code"] = event.market_code
        base["country_name"] = event.country_name
        base["genre_family"] = event.primary_genre
        base["event_year"] = int(event.event_year)
        base["event_date_raw"] = event.event_date_raw
        base["timing_precision"] = event.timing_precision
        base["source_name"] = event.source_name
        base["market_exposure_type"] = event.market_exposure_type
        base["event_tier"] = event.event_tier
        panel_parts.append(base)

    panel = pd.concat(panel_parts, ignore_index=True)

    panel = panel.merge(overall, on=["city_country", "calendar_year"], how="left")
    panel = panel.merge(genre, on=["city_country", "calendar_year", "genre_family"], how="left")
    panel = panel.merge(starts, on=["city_country", "genre_family", "calendar_year"], how="left")
    panel = panel.merge(
        emergence,
        on=["city", "country", "city_country", "genre_family"],
        how="left",
    )

    zero_fill_columns = [
        "city_total_active_bands",
        "city_total_band_starts",
        "city_total_spawn_bands_formed",
        "city_total_multi_band_musicians",
        "local_genre_active_bands",
        "local_genre_active_musicians",
        "local_genre_multi_band_musicians",
        "local_genre_band_starts",
        "total_bands",
    ]
    for column in zero_fill_columns:
        panel[column] = pd.to_numeric(panel[column], errors="coerce").fillna(0)

    panel["first_band_year"] = pd.to_numeric(panel["first_band_year"], errors="coerce")
    panel["emergence_year"] = pd.to_numeric(panel["emergence_year"], errors="coerce")

    panel["has_genre_presence_yet_i"] = (
        panel["first_band_year"].notna() & panel["calendar_year"].ge(panel["first_band_year"])
    ).astype(int)
    panel["emerge_this_year_i"] = (
        panel["emergence_year"].notna() & panel["calendar_year"].eq(panel["emergence_year"])
    ).astype(int)
    panel["pre_emergence_i"] = (
        panel["emergence_year"].isna() | panel["calendar_year"].lt(panel["emergence_year"])
    ).astype(int)
    panel["already_emerged_i"] = (
        panel["emergence_year"].notna() & panel["calendar_year"].ge(panel["emergence_year"])
    ).astype(int)

    panel = panel.sort_values(
        ["priority_rank", "event_id", "city_country", "calendar_year"]
    ).reset_index(drop=True)
    return panel


def build_capability_file(panel: pd.DataFrame) -> pd.DataFrame:
    capability = panel.loc[panel["relative_event_year"].eq(-1)].copy()
    capability = capability[
        [
            "event_id",
            "priority_rank",
            "market_code",
            "country_name",
            "genre_family",
            "event_year",
            "city",
            "country",
            "city_country",
            "calendar_year",
            "local_genre_active_bands",
            "local_genre_active_musicians",
            "local_genre_multi_band_musicians",
            "city_total_spawn_bands_formed",
            "first_band_year",
            "emergence_year",
            "has_genre_presence_yet_i",
            "pre_emergence_i",
            "already_emerged_i",
        ]
    ].rename(
        columns={
            "calendar_year": "pre_shock_year",
            "local_genre_active_bands": "pre_shock_local_genre_active_bands",
            "local_genre_active_musicians": "pre_shock_local_genre_active_musicians",
            "local_genre_multi_band_musicians": "pre_shock_local_genre_multi_band_musicians",
            "city_total_spawn_bands_formed": "pre_shock_city_total_spawn_bands_formed",
        }
    )

    capability["pre_shock_capability_score"] = (
        capability["pre_shock_local_genre_active_bands"]
        + capability["pre_shock_local_genre_multi_band_musicians"]
    )
    capability["pre_shock_subthreshold_i"] = capability["already_emerged_i"].eq(0).astype(int)
    capability["capability_bin"] = capability.groupby("event_id", group_keys=False).apply(
        assign_capability_bins
    ).astype("object")
    capability["high_capability_i"] = capability["capability_bin"].eq("high_capability").astype(int)
    capability["mid_capability_i"] = capability["capability_bin"].eq("mid_capability").astype(int)
    capability["low_capability_i"] = capability["capability_bin"].eq("low_capability").astype(int)
    capability["flat_capability_i"] = capability["capability_bin"].eq("flat_capability").astype(int)

    capability = capability.sort_values(["priority_rank", "city_country"]).reset_index(drop=True)
    return capability


def write_summary(events: pd.DataFrame, panel: pd.DataFrame, capability: pd.DataFrame, output_summary_path: Path) -> None:
    event_counts = (
        panel.groupby(["priority_rank", "event_id", "market_code", "genre_family", "event_year"], as_index=False)
        .agg(
            city_count=("city_country", "nunique"),
            row_count=("city_country", "size"),
            pre_emergence_rows=("pre_emergence_i", "sum"),
            emerged_rows=("already_emerged_i", "sum"),
            genre_start_rows=("local_genre_band_starts", lambda s: int((s > 0).sum())),
        )
        .sort_values(["priority_rank", "event_id"])
    )

    subthreshold_counts = (
        capability.groupby(["priority_rank", "event_id"], as_index=False)
        .agg(
            city_count=("city_country", "nunique"),
            subthreshold_cities=("pre_shock_subthreshold_i", "sum"),
            high_capability_cities=("high_capability_i", "sum"),
            mid_capability_cities=("mid_capability_i", "sum"),
            low_capability_cities=("low_capability_i", "sum"),
            flat_capability_cities=("flat_capability_i", "sum"),
        )
        .sort_values(["priority_rank", "event_id"])
    )

    with output_summary_path.open("w", encoding="utf-8") as handle:
        handle.write("# Breakout branch panel summary\n\n")
        handle.write(f"- Breakout events retained: `{len(events)}`\n")
        handle.write(f"- Panel rows: `{len(panel)}`\n")
        handle.write(f"- Unique city-event cells: `{panel[['event_id', 'city_country']].drop_duplicates().shape[0]}`\n")
        handle.write(f"- Unique cities across stacks: `{panel['city_country'].nunique()}`\n")
        handle.write(f"- Capability rows (`t = -1`): `{len(capability)}`\n\n")

        handle.write("## Event coverage\n\n")
        handle.write("| Rank | Event | Market | Genre | Event year | Cities | Rows | Pre-emergence rows | Emerged rows | Years with genre starts |\n")
        handle.write("|---|---|---|---|---:|---:|---:|---:|---:|---:|\n")
        for row in event_counts.itertuples(index=False):
            handle.write(
                f"| {row.priority_rank} | {row.event_id} | {row.market_code} | {row.genre_family} | "
                f"{row.event_year} | {row.city_count} | {row.row_count} | {row.pre_emergence_rows} | "
                f"{row.emerged_rows} | {row.genre_start_rows} |\n"
            )

        handle.write("\n## Pre-shock capability bins\n\n")
        handle.write("| Rank | Event | Cities | Subthreshold cities | High | Mid | Low | Flat |\n")
        handle.write("|---|---|---:|---:|---:|---:|---:|---:|\n")
        for row in subthreshold_counts.itertuples(index=False):
            handle.write(
                f"| {row.priority_rank} | {row.event_id} | {row.city_count} | {row.subthreshold_cities} | "
                f"{row.high_capability_cities} | {row.mid_capability_cities} | {row.low_capability_cities} | "
                f"{row.flat_capability_cities} |\n"
            )


def main() -> None:
    args = parse_args()
    city_lookup = load_city_lookup()
    overall, genre, emergence = load_scene_frames()
    valid_genres = set(genre["genre_family"].dropna().astype(str).unique()).union(
        set(emergence["genre_family"].dropna().astype(str).unique())
    )
    events = filter_supported_events(load_event_file(args.event_path), valid_genres)
    starts = build_local_genre_starts()

    panel = build_event_panel(events, city_lookup, overall, genre, emergence, starts)
    capability = build_capability_file(panel)

    args.output_panel_path.parent.mkdir(parents=True, exist_ok=True)
    panel.to_csv(args.output_panel_path, index=False)
    capability.to_csv(args.output_capability_path, index=False)
    write_summary(events, panel, capability, args.output_summary_path)

    print(f"Wrote {args.output_panel_path}")
    print(f"Wrote {args.output_capability_path}")
    print(f"Wrote {args.output_summary_path}")


if __name__ == "__main__":
    main()
