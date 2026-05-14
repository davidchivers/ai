from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
SCENE_DIR = PROCESSED_DIR / "scene_networks"

MEMBER_EDGE_PATH = SCENE_DIR / "full_musician_band_edges.csv"
BAND_PATH = PROCESSED_DIR / "metal_archives_all_metal_band_clean.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
GENRE_PANEL_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"

OUT_EVENTS = SCENE_DIR / "external_arrival_events.csv"
OUT_WINDOWS = SCENE_DIR / "external_arrival_event_windows.csv"
OUT_RELATIVE = SCENE_DIR / "external_arrival_relative_year_summary.csv"
OUT_SUMMARY = SCENE_DIR / "external_arrival_event_study_summary.md"

WINDOW = list(range(-5, 6))
ANALYSIS_START_YEAR = 1988
ANALYSIS_END_YEAR = 2017

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

ARRIVAL_DEFINITIONS = {
    "cross_city_any": "Prior membership in a different city, any metal genre",
    "cross_city_same_genre": "Prior membership in a different city and the same genre family",
    "cross_country_any": "Prior membership in a different country, any metal genre",
    "cross_country_same_genre": "Prior membership in a different country and the same genre family",
}


def normalize_text(value: object) -> str:
    if pd.isna(value):
        return ""
    return str(value).strip()


def normalize_id(value: object) -> str:
    text = normalize_text(value)
    if text.endswith(".0") and text[:-2].isdigit():
        return text[:-2]
    return text


def normalize_city_country(city: object, country: object) -> str:
    city_text = normalize_text(city)
    country_text = normalize_text(country)
    if not city_text:
        return ""
    return f"{city_text}, {country_text}" if country_text else city_text


def parse_genre_families(genre_raw: object) -> tuple[str, ...]:
    text = normalize_text(genre_raw).lower()
    if not text:
        return tuple()
    families: list[str] = []
    for key in GENRE_FAMILY_KEYS:
        if key in text:
            families.append(GENRE_FAMILIES[key])
    if not families and "metal" in text:
        families.append("other_metal")
    return tuple(sorted(set(families)))


def extract_city(notes_str: object) -> str:
    text = normalize_text(notes_str)
    if not text:
        return ""
    marker = "location="
    if marker not in text:
        return ""
    location = text.split(marker, 1)[1].split(";", 1)[0]
    return location.split(",", 1)[0].strip()


def short_join(values: pd.Series, limit: int = 5) -> str:
    cleaned = [normalize_text(value) for value in values if normalize_text(value)]
    unique_values = list(dict.fromkeys(cleaned))
    shown = unique_values[:limit]
    suffix = "" if len(unique_values) <= limit else f"; +{len(unique_values) - limit} more"
    return "; ".join(shown) + suffix


def pipe_join(values: pd.Series) -> str:
    cleaned = [normalize_id(value) for value in values if normalize_id(value)]
    return "|".join(dict.fromkeys(cleaned))


def pipe_join_tokens(values: pd.Series) -> str:
    tokens: list[str] = []
    for value in values:
        for token in normalize_text(value).split("|"):
            token = token.strip()
            if token:
                tokens.append(token)
    return "|".join(dict.fromkeys(tokens))


def mark_prior_other_location(
    frame: pd.DataFrame,
    *,
    location_col: str,
    group_cols: list[str],
    output_col: str,
) -> pd.DataFrame:
    """Mark rows where the member has strictly earlier experience in another location."""
    loc_first_col = f"{output_col}_location_first_year"
    min_one_col = f"{output_col}_min_first_year"
    min_two_col = f"{output_col}_second_first_year"
    loc_first = (
        frame.groupby(group_cols + [location_col], as_index=False, dropna=False)["event_year"]
        .min()
        .rename(columns={"event_year": loc_first_col})
    )
    unique_years = (
        loc_first[group_cols + [loc_first_col]]
        .drop_duplicates()
        .sort_values(group_cols + [loc_first_col])
    )
    unique_years["_prior_year_order"] = unique_years.groupby(group_cols, dropna=False).cumcount()
    min_one = unique_years.loc[unique_years["_prior_year_order"].eq(0), group_cols + [loc_first_col]].rename(
        columns={loc_first_col: min_one_col}
    )
    min_two = unique_years.loc[unique_years["_prior_year_order"].eq(1), group_cols + [loc_first_col]].rename(
        columns={loc_first_col: min_two_col}
    )
    minima = min_one.merge(min_two, on=group_cols, how="left")
    if min_two_col not in minima:
        minima[min_two_col] = np.nan

    out = frame.merge(loc_first, on=group_cols + [location_col], how="left")
    out = out.merge(minima[group_cols + [min_one_col, min_two_col]], on=group_cols, how="left")
    min_other = np.where(
        out[loc_first_col].eq(out[min_one_col]),
        out[min_two_col],
        out[min_one_col],
    )
    out[output_col] = pd.Series(min_other, index=out.index).lt(out["event_year"]).fillna(False)
    return out.drop(columns=[loc_first_col, min_one_col, min_two_col])


def load_member_edges() -> pd.DataFrame:
    usecols = [
        "member_id",
        "member_name",
        "band_id",
        "band_name",
        "country",
        "countryiso3code",
        "city",
        "first_year_in_band",
        "formed_year",
        "genre_raw",
    ]
    edges = pd.read_csv(MEMBER_EDGE_PATH, usecols=usecols, engine="pyarrow")
    edges["first_year_in_band"] = pd.to_numeric(edges["first_year_in_band"], errors="coerce")
    edges["formed_year"] = pd.to_numeric(edges["formed_year"], errors="coerce")
    edges["event_year"] = edges["first_year_in_band"].fillna(edges["formed_year"])
    for column in ["city", "country", "countryiso3code", "member_name", "band_name", "genre_raw"]:
        edges[column] = edges[column].fillna("").astype(str).str.strip()
    edges = edges.loc[
        edges["event_year"].notna()
        & edges["member_id"].notna()
        & edges["city"].notna()
        & edges["city"].ne("")
        & edges["country"].notna()
        & edges["country"].ne("")
    ].copy()
    edges["event_year"] = edges["event_year"].astype(int)
    edges["city_country"] = edges["city"] + ", " + edges["country"]
    edges["genre_family"] = edges["genre_raw"].map(parse_genre_families)
    edges = edges.explode("genre_family").dropna(subset=["genre_family"]).copy()
    edges = edges.drop_duplicates(
        ["member_id", "band_id", "city_country", "country", "genre_family", "event_year"]
    )
    edges["member_city_genre_first_year"] = edges.groupby(
        ["member_id", "city_country", "genre_family"], dropna=False
    )["event_year"].transform("min")

    edges = mark_prior_other_location(
        edges,
        location_col="city_country",
        group_cols=["member_id"],
        output_col="cross_city_any",
    )
    edges = mark_prior_other_location(
        edges,
        location_col="city_country",
        group_cols=["member_id", "genre_family"],
        output_col="cross_city_same_genre",
    )
    edges = mark_prior_other_location(
        edges,
        location_col="country",
        group_cols=["member_id"],
        output_col="cross_country_any",
    )
    edges = mark_prior_other_location(
        edges,
        location_col="country",
        group_cols=["member_id", "genre_family"],
        output_col="cross_country_same_genre",
    )
    return edges


def build_member_arrivals(edges: pd.DataFrame) -> pd.DataFrame:
    first_entries = edges.loc[edges["event_year"].eq(edges["member_city_genre_first_year"])].copy()
    first_entries = first_entries.loc[
        first_entries[list(ARRIVAL_DEFINITIONS)].any(axis=1)
    ].copy()
    arrivals = (
        first_entries.groupby(
            [
                "member_id",
                "member_name",
                "city",
                "country",
                "countryiso3code",
                "city_country",
                "genre_family",
                "event_year",
            ],
            as_index=False,
            dropna=False,
        )
        .agg(
            arrival_band_count=("band_id", "nunique"),
            band_ids=("band_id", lambda s: pipe_join(s.astype(str))),
            band_names=("band_name", short_join),
            cross_city_any=("cross_city_any", "max"),
            cross_city_same_genre=("cross_city_same_genre", "max"),
            cross_country_any=("cross_country_any", "max"),
            cross_country_same_genre=("cross_country_same_genre", "max"),
        )
    )
    for column in ARRIVAL_DEFINITIONS:
        arrivals[column] = arrivals[column].astype(bool)
    return arrivals


def build_local_starts() -> pd.DataFrame:
    bands = pd.read_csv(BAND_PATH, low_memory=False)
    bands["city"] = bands["notes"].map(extract_city)
    bands["formed_year"] = pd.to_numeric(bands["formed_year"], errors="coerce")
    bands = bands.loc[
        bands["formed_year"].notna()
        & bands["city"].ne("")
        & bands["country_std"].notna()
        & bands["country_std"].ne("")
    ].copy()
    bands["formed_year"] = bands["formed_year"].astype(int)
    bands["city_country"] = bands.apply(
        lambda row: normalize_city_country(row["city"], row["country_std"]),
        axis=1,
    )
    bands["genre_family"] = bands["genre_raw"].map(parse_genre_families)
    expanded = bands.explode("genre_family").dropna(subset=["genre_family"]).copy()
    starts = (
        expanded.groupby(["city_country", "genre_family", "formed_year"], as_index=False)
        .size()
        .rename(columns={"formed_year": "snapshot_year", "size": "local_genre_band_starts"})
    )
    return starts


def build_cumulative_lookup(starts: pd.DataFrame) -> dict[tuple[str, str], tuple[np.ndarray, np.ndarray]]:
    lookup: dict[tuple[str, str], tuple[np.ndarray, np.ndarray]] = {}
    starts = starts.sort_values(["city_country", "genre_family", "snapshot_year"]).copy()
    for key, group in starts.groupby(["city_country", "genre_family"], sort=False):
        years = group["snapshot_year"].to_numpy(dtype=int)
        cumsum = group["local_genre_band_starts"].cumsum().to_numpy(dtype=int)
        lookup[key] = (years, cumsum)
    return lookup


def cumulative_before(
    lookup: dict[tuple[str, str], tuple[np.ndarray, np.ndarray]],
    city_country: str,
    genre_family: str,
    year: int,
) -> int:
    values = lookup.get((city_country, genre_family))
    if values is None:
        return 0
    years, cumsum = values
    idx = np.searchsorted(years, year, side="left") - 1
    if idx < 0:
        return 0
    return int(cumsum[idx])


def starts_in_year(
    starts: pd.DataFrame,
    city_country: str,
    genre_family: str,
    year: int,
) -> float:
    match = starts.loc[
        starts["city_country"].eq(city_country)
        & starts["genre_family"].eq(genre_family)
        & starts["snapshot_year"].eq(year),
        "local_genre_band_starts",
    ]
    if match.empty:
        return 0.0
    return float(match.iloc[0])


def build_cell_events(
    arrivals: pd.DataFrame,
    starts: pd.DataFrame,
    emergence: pd.DataFrame,
) -> pd.DataFrame:
    cumulative_lookup = build_cumulative_lookup(starts)
    event_frames: list[pd.DataFrame] = []
    cell_cols = ["city_country", "city", "country", "countryiso3code", "genre_family"]

    for definition in ARRIVAL_DEFINITIONS:
        subset = arrivals.loc[arrivals[definition]].copy()
        if subset.empty:
            continue
        first_year = (
            subset.groupby(["city_country", "genre_family"], as_index=False)["event_year"]
            .min()
            .rename(columns={"event_year": "arrival_year"})
        )
        first_subset = subset.merge(
            first_year,
            left_on=["city_country", "genre_family", "event_year"],
            right_on=["city_country", "genre_family", "arrival_year"],
            how="inner",
        )
        event_frame = (
            first_subset.groupby(cell_cols + ["arrival_year"], as_index=False, dropna=False)
            .agg(
                arriving_musicians=("member_id", "nunique"),
                arriving_bands=("arrival_band_count", "sum"),
                arriving_band_ids=("band_ids", pipe_join_tokens),
                example_musicians=("member_name", short_join),
                example_bands=("band_names", short_join),
            )
        )
        event_frame["arrival_definition"] = definition
        event_frame["arrival_definition_label"] = ARRIVAL_DEFINITIONS[definition]
        event_frames.append(event_frame)

    events = pd.concat(event_frames, ignore_index=True)
    events = events.merge(
        emergence[
            [
                "city_country",
                "genre_family",
                "first_band_year",
                "emergence_year",
                "total_bands",
            ]
        ],
        on=["city_country", "genre_family"],
        how="left",
    )
    events["first_band_year"] = pd.to_numeric(events["first_band_year"], errors="coerce")
    events["emergence_year"] = pd.to_numeric(events["emergence_year"], errors="coerce")
    events["total_bands"] = pd.to_numeric(events["total_bands"], errors="coerce")
    events["prior_cumulative_bands"] = [
        cumulative_before(cumulative_lookup, row.city_country, row.genre_family, int(row.arrival_year))
        for row in events.itertuples(index=False)
    ]
    events["event_year_starts"] = [
        starts_in_year(starts, row.city_country, row.genre_family, int(row.arrival_year))
        for row in events.itertuples(index=False)
    ]
    events["pre_existing_subthreshold_i"] = events["prior_cumulative_bands"].between(1, 4).astype(int)
    events["pre_emergence_i"] = (
        events["emergence_year"].notna() & events["arrival_year"].lt(events["emergence_year"])
    ).astype(int)
    events["event_year_emergence_i"] = (
        events["emergence_year"].notna() & events["arrival_year"].eq(events["emergence_year"])
    ).astype(int)
    events["post_emergence_i"] = (
        events["emergence_year"].notna() & events["arrival_year"].gt(events["emergence_year"])
    ).astype(int)
    events["emergence_within_5yr_i"] = (
        events["emergence_year"].notna()
        & events["emergence_year"].between(events["arrival_year"], events["arrival_year"] + 5)
    ).astype(int)
    events["analysis_sample_i"] = (
        events["pre_existing_subthreshold_i"].eq(1)
        & events["pre_emergence_i"].eq(1)
        & events["arrival_year"].between(ANALYSIS_START_YEAR, ANALYSIS_END_YEAR)
    ).astype(int)
    events["event_id"] = (
        events["arrival_definition"]
        + " || "
        + events["city_country"].astype(str)
        + " || "
        + events["genre_family"].astype(str)
        + " || "
        + events["arrival_year"].astype(int).astype(str)
    )
    return events.sort_values(["arrival_definition", "arrival_year", "city_country", "genre_family"])


def build_event_windows(events: pd.DataFrame, starts: pd.DataFrame) -> pd.DataFrame:
    analysis_events = events.loc[events["analysis_sample_i"].eq(1)].copy()
    if analysis_events.empty:
        return pd.DataFrame()

    rel = pd.DataFrame({"relative_year": WINDOW})
    windows = analysis_events.merge(rel, how="cross")
    windows["snapshot_year"] = windows["arrival_year"] + windows["relative_year"]
    windows = windows.merge(
        starts,
        on=["city_country", "genre_family", "snapshot_year"],
        how="left",
    )
    windows["local_genre_band_starts"] = windows["local_genre_band_starts"].fillna(0.0)
    genre_panel = pd.read_csv(GENRE_PANEL_PATH, low_memory=False)
    windows = windows.merge(
        genre_panel[
            [
                "city_country",
                "genre_family",
                "snapshot_year",
                "genre_active_bands",
                "genre_active_musicians",
                "genre_multi_band_musicians",
            ]
        ],
        on=["city_country", "genre_family", "snapshot_year"],
        how="left",
    )
    windows["emergence_this_year_i"] = (
        windows["emergence_year"].notna() & windows["snapshot_year"].eq(windows["emergence_year"])
    ).astype(int)
    windows["post_i"] = windows["relative_year"].ge(0).astype(int)
    return windows.sort_values(["arrival_definition", "event_id", "relative_year"])


def summarize_event_windows(events: pd.DataFrame, windows: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    if windows.empty:
        return pd.DataFrame(), pd.DataFrame()

    relative_summary = (
        windows.groupby(["arrival_definition", "relative_year"], as_index=False)
        .agg(
            events=("event_id", "nunique"),
            mean_local_genre_band_starts=("local_genre_band_starts", "mean"),
            mean_genre_active_bands=("genre_active_bands", "mean"),
            mean_genre_multi_band_musicians=("genre_multi_band_musicians", "mean"),
            emergence_rate=("emergence_this_year_i", "mean"),
        )
    )

    event_periods = (
        windows.assign(
            period=np.select(
                [
                    windows["relative_year"].between(-3, -1),
                    windows["relative_year"].between(0, 2),
                    windows["relative_year"].between(1, 3),
                ],
                ["pre_m3_m1", "post_0_p2", "post_p1_p3"],
                default="other",
            )
        )
        .loc[lambda df: df["period"].ne("other")]
        .groupby(["arrival_definition", "event_id", "period"], as_index=False)
        .agg(local_genre_band_starts=("local_genre_band_starts", "mean"))
        .pivot_table(
            index=["arrival_definition", "event_id"],
            columns="period",
            values="local_genre_band_starts",
            aggfunc="mean",
        )
        .reset_index()
    )
    event_periods = event_periods.merge(
        events[["arrival_definition", "event_id", "emergence_within_5yr_i"]],
        on=["arrival_definition", "event_id"],
        how="left",
    )
    for column in ["pre_m3_m1", "post_0_p2", "post_p1_p3"]:
        if column not in event_periods.columns:
            event_periods[column] = np.nan
    event_periods["change_post_0_p2_vs_pre"] = event_periods["post_0_p2"] - event_periods["pre_m3_m1"]
    event_periods["change_post_p1_p3_vs_pre"] = event_periods["post_p1_p3"] - event_periods["pre_m3_m1"]
    event_summary = (
        event_periods.groupby("arrival_definition", as_index=False)
        .agg(
            analysis_events=("event_id", "nunique"),
            mean_pre_starts=("pre_m3_m1", "mean"),
            mean_post_0_p2_starts=("post_0_p2", "mean"),
            mean_post_p1_p3_starts=("post_p1_p3", "mean"),
            mean_change_post_0_p2_vs_pre=("change_post_0_p2_vs_pre", "mean"),
            mean_change_post_p1_p3_vs_pre=("change_post_p1_p3_vs_pre", "mean"),
            share_emerge_within_5yr=("emergence_within_5yr_i", "mean"),
        )
    )
    return relative_summary, event_summary


def fmt(value: float, digits: int = 3) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def write_summary(events: pd.DataFrame, relative: pd.DataFrame, event_summary: pd.DataFrame) -> None:
    counts = (
        events.groupby("arrival_definition", as_index=False)
        .agg(
            first_arrival_events=("event_id", "nunique"),
            pre_emergence_events=("pre_emergence_i", "sum"),
            pre_existing_subthreshold_events=("pre_existing_subthreshold_i", "sum"),
            analysis_events=("analysis_sample_i", "sum"),
            event_year_emergence_events=("event_year_emergence_i", "sum"),
            post_emergence_events=("post_emergence_i", "sum"),
        )
    )
    event_summary_map = {row.arrival_definition: row for row in event_summary.itertuples(index=False)}

    with OUT_SUMMARY.open("w", encoding="utf-8") as handle:
        handle.write("# External experienced-musician arrival event-study prototype\n\n")
        handle.write(
            "This file tests the feasibility of using the first observed arrival of an experienced "
            "outside musician as a local capability shock. The data do not observe residence moves. "
            "The event is a musician's first observed membership in a local `city x genre` cell after "
            "strictly earlier band experience in another city or country.\n\n"
        )
        handle.write("## Output files\n\n")
        handle.write(f"- event file: `{OUT_EVENTS.relative_to(PROJECT_ROOT)}`\n")
        handle.write(f"- event windows: `{OUT_WINDOWS.relative_to(PROJECT_ROOT)}`\n")
        handle.write(f"- relative-year summary: `{OUT_RELATIVE.relative_to(PROJECT_ROOT)}`\n\n")
        handle.write(
            "The event file preserves full pipe-delimited `arriving_band_ids` so downstream audits "
            "can exclude the arriving musician's own band from local entry outcomes.\n\n"
        )
        handle.write("## Definitions\n\n")
        for definition, label in ARRIVAL_DEFINITIONS.items():
            handle.write(f"- `{definition}`: {label}.\n")

        handle.write("\n## Event counts\n\n")
        handle.write(
            "| Definition | First arrival events | Pre-emergence | Pre-existing subthreshold | Analysis sample | Event-year emergence | Post-emergence |\n"
        )
        handle.write("|---|---:|---:|---:|---:|---:|---:|\n")
        for row in counts.itertuples(index=False):
            handle.write(
                f"| `{row.arrival_definition}` | {int(row.first_arrival_events)} | "
                f"{int(row.pre_emergence_events)} | {int(row.pre_existing_subthreshold_events)} | "
                f"{int(row.analysis_events)} | {int(row.event_year_emergence_events)} | "
                f"{int(row.post_emergence_events)} |\n"
            )

        handle.write("\n## Analysis-sample event-window read\n\n")
        handle.write(
            "The analysis sample keeps events from `1988` to `2017` where the local cell already has "
            "`1-4` prior cumulative bands and has not yet crossed the operational emergence threshold. "
            "The post `+1` to `+3` column is the cleaner first read because it does not include the "
            "arrival year itself.\n\n"
        )
        handle.write(
            "| Definition | Events | Starts pre -3:-1 | Starts post 0:+2 | Starts post +1:+3 | Change 0:+2 | Change +1:+3 | Emerges within 5y |\n"
        )
        handle.write("|---|---:|---:|---:|---:|---:|---:|---:|\n")
        for definition in ARRIVAL_DEFINITIONS:
            row = event_summary_map.get(definition)
            if row is None:
                continue
            handle.write(
                f"| `{definition}` | {int(row.analysis_events)} | "
                f"{fmt(row.mean_pre_starts)} | {fmt(row.mean_post_0_p2_starts)} | "
                f"{fmt(row.mean_post_p1_p3_starts)} | {fmt(row.mean_change_post_0_p2_vs_pre)} | "
                f"{fmt(row.mean_change_post_p1_p3_vs_pre)} | {fmt(row.share_emerge_within_5yr)} |\n"
            )

        handle.write("\n## Current read\n\n")
        handle.write(
            "- The event-count frontier is much richer than the central-death branch, especially for "
            "`cross_city` arrivals.\n"
        )
        handle.write(
            "- The event-year outcome is mechanically risky because the arrival is often attached to a "
            "new local band. The `+1` to `+3` window is therefore the first useful descriptive margin.\n"
        )
        handle.write(
            "- This is still not a causal estimate. The next test should add matched controls or a stacked "
            "event-study with controls, and should exclude the arriving musician's own band from the "
            "entry outcome where possible.\n"
        )


def main() -> None:
    SCENE_DIR.mkdir(parents=True, exist_ok=True)
    print("Loading and classifying member edges...")
    edges = load_member_edges()
    print(f"Expanded member-edge rows: {len(edges):,}")

    print("Building member arrival rows...")
    arrivals = build_member_arrivals(edges)
    print(f"First member-city-genre rows: {len(arrivals):,}")

    print("Building local starts and cell-level events...")
    starts = build_local_starts()
    emergence = pd.read_csv(EMERGENCE_PATH, low_memory=False)
    events = build_cell_events(arrivals, starts, emergence)
    events.to_csv(OUT_EVENTS, index=False)
    print(f"Cell-level first-arrival events: {len(events):,}")

    print("Building event windows...")
    windows = build_event_windows(events, starts)
    windows.to_csv(OUT_WINDOWS, index=False)
    relative, event_summary = summarize_event_windows(events, windows)
    relative.to_csv(OUT_RELATIVE, index=False)
    write_summary(events, relative, event_summary)
    print(f"Analysis-sample event-window rows: {len(windows):,}")
    print(f"Wrote summary to {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
