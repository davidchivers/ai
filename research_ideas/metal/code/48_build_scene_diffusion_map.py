from __future__ import annotations

import argparse
import math
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

import geonamescache
import pandas as pd
import plotly.express as px
import pycountry


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
FIRST_APPEARANCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
RICHER_FEATURES_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
GEOGRAPHY_AUDIT_PATH = SCENE_DIR / "city_geography_audit.csv"
DIFFUSION_DIR = SCENE_DIR / "diffusion"

COUNTRY_ALIAS_TO_ISO2 = {
    "usa": "US",
    "united states": "US",
    "uk": "GB",
    "united kingdom": "GB",
    "england": "GB",
    "turkiye": "TR",
    "turkey": "TR",
    "korea rep": "KR",
    "egypt arab rep": "EG",
    "venezuela rb": "VE",
    "slovak republic": "SK",
    "czech republic": "CZ",
    "russian federation": "RU",
    "macedonia": "MK",
}

CITY_ALIASES = {
    ("antwerp", "BE"): ["antwerpen"],
    ("bruges", "BE"): ["brugge"],
    ("busan", "KR"): ["pusan"],
    ("brooklyn new york city", "US"): ["brooklyn"],
    ("east jakarta", "ID"): ["jakarta"],
    ("barquisimeto", "VE"): ["barquisimeto"],
    ("caracas", "VE"): ["caracas"],
    ("cairo", "EG"): ["cairo"],
}

SELECTED_YEARS = [1990, 1995, 2000, 2005, 2010, 2015, 2020]
MAP_PROJECTION = "equirectangular"
MAP_LAT_RANGE = [-25, 85]
MAP_LON_RANGE = [-130, 175]


def normalize_text(value: object) -> str:
    if value is None:
        return ""
    text = str(value).strip()
    return "" if text.lower() == "nan" else text


def normalize_key(value: object) -> str:
    text = normalize_text(value)
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii").lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def country_to_iso2(country_name: str) -> str:
    key = normalize_key(country_name)
    if key in COUNTRY_ALIAS_TO_ISO2:
        return COUNTRY_ALIAS_TO_ISO2[key]
    try:
        return pycountry.countries.lookup(country_name).alpha_2
    except LookupError:
        return ""


def city_candidate_keys(city_name: str, iso2: str) -> list[tuple[str, str]]:
    keys: list[str] = []
    cleaned = normalize_key(city_name)
    if cleaned:
        keys.append(cleaned)

    if "(" in city_name:
        left = normalize_key(city_name.split("(", 1)[0])
        if left:
            keys.append(left)
    if "/" in city_name:
        for piece in city_name.split("/"):
            piece_key = normalize_key(piece)
            if piece_key:
                keys.append(piece_key)

    alias_key = (cleaned, iso2)
    for alias in CITY_ALIASES.get(alias_key, []):
        alias_norm = normalize_key(alias)
        if alias_norm:
            keys.append(alias_norm)

    deduped: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for key in keys:
        pair = (key, iso2)
        if pair not in seen:
            seen.add(pair)
            deduped.append(pair)
    return deduped


def build_geonames_index() -> dict[tuple[str, str], list[dict[str, object]]]:
    gc = geonamescache.GeonamesCache()
    city_index: dict[tuple[str, str], list[dict[str, object]]] = defaultdict(list)

    for row in gc.get_cities().values():
        names = [row.get("name", "")]
        names.extend(row.get("alternatenames", []))
        for name in names:
            name_key = normalize_key(name)
            if not name_key:
                continue
            city_index[(name_key, row["countrycode"])].append(row)

    for key, matches in city_index.items():
        matches.sort(key=lambda item: int(item.get("population") or 0), reverse=True)
        city_index[key] = matches

    return city_index


def build_coordinate_crosswalk(first_appearance: pd.DataFrame) -> pd.DataFrame:
    city_index = build_geonames_index()
    rows: list[dict[str, object]] = []

    for city_country, city, country in (
        first_appearance[["city_country", "city", "country"]].drop_duplicates().itertuples(index=False, name=None)
    ):
        iso2 = country_to_iso2(country)
        match = None
        matched_key = ""
        if iso2:
            for key in city_candidate_keys(city, iso2):
                candidates = city_index.get(key, [])
                if candidates:
                    match = candidates[0]
                    matched_key = key[0]
                    break

        rows.append(
            {
                "city_country": city_country,
                "city": city,
                "country": country,
                "country_iso2": iso2,
                "coord_match_i": int(match is not None),
                "matched_key": matched_key,
                "matched_geonames_name": match.get("name", "") if match else "",
                "latitude": float(match["latitude"]) if match else math.nan,
                "longitude": float(match["longitude"]) if match else math.nan,
                "matched_population": int(match.get("population") or 0) if match else 0,
            }
        )

    crosswalk = pd.DataFrame(rows).sort_values(["coord_match_i", "country", "city"], ascending=[False, True, True])
    return crosswalk


def build_diffusion_panel(
    genre_family: str,
    first_appearance: pd.DataFrame,
    richer_features: pd.DataFrame,
    coordinates: pd.DataFrame,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    first_subset = first_appearance.loc[first_appearance["genre_family"] == genre_family].copy()
    richer_subset = richer_features.loc[richer_features["genre_family"] == genre_family].copy()

    first_subset["first_band_year"] = pd.to_numeric(first_subset["first_band_year"], errors="coerce")
    first_subset["emergence_year"] = pd.to_numeric(first_subset["emergence_year"], errors="coerce")
    first_subset["total_bands"] = pd.to_numeric(first_subset["total_bands"], errors="coerce")
    richer_subset["snapshot_year"] = pd.to_numeric(richer_subset["snapshot_year"], errors="coerce")
    richer_subset["genre_active_bands"] = pd.to_numeric(richer_subset["genre_active_bands"], errors="coerce")

    first_subset = first_subset.loc[first_subset["emergence_year"].notna()].copy()
    first_subset["emergence_year"] = first_subset["emergence_year"].astype(int)
    first_subset = first_subset.merge(
        coordinates[["city_country", "coord_match_i", "latitude", "longitude", "matched_geonames_name"]],
        on="city_country",
        how="left",
    )
    first_subset = first_subset.loc[first_subset["coord_match_i"] == 1].copy()

    matched_cities = first_subset[["city_country"]].drop_duplicates()
    panel = richer_subset.merge(matched_cities, on="city_country", how="inner")
    panel = panel.merge(
        first_subset[
            [
                "city_country",
                "city",
                "country",
                "first_band_year",
                "emergence_year",
                "total_bands",
                "latitude",
                "longitude",
                "matched_geonames_name",
            ]
        ].drop_duplicates(),
        on="city_country",
        how="left",
    )
    panel = panel.loc[panel["genre_active_bands"] > 0].copy()
    panel["stage"] = panel["snapshot_year"].apply(
        lambda year: "Emerged local scene" if year >= panel.loc[panel["snapshot_year"] == year, "emergence_year"].iloc[0] else ""
    )
    panel["stage"] = panel.apply(
        lambda row: "Emerged local scene" if row["snapshot_year"] >= row["emergence_year"] else "Active before emergence",
        axis=1,
    )
    # Use stepped marker sizes so big hubs read as bigger without swallowing the map.
    panel["hover_size_bucket"] = pd.cut(
        panel["genre_active_bands"],
        bins=[0, 1, 4, 9, 19, 39, math.inf],
        labels=["1", "2-4", "5-9", "10-19", "20-39", "40+"],
        include_lowest=True,
    ).astype(str)
    panel["marker_size"] = pd.cut(
        panel["genre_active_bands"],
        bins=[0, 1, 4, 9, 19, 39, math.inf],
        labels=[4, 6, 8, 10, 12, 14],
        include_lowest=True,
    ).astype(int)
    panel["hover_total_bands"] = panel["total_bands"].fillna(0).astype(int)
    panel["hover_first_band_year"] = panel["first_band_year"].fillna(0).astype(int)
    panel["hover_emergence_year"] = panel["emergence_year"].fillna(0).astype(int)
    panel = panel.sort_values(["snapshot_year", "genre_active_bands"], ascending=[True, False])

    yearly_summary = (
        panel.groupby("snapshot_year", as_index=False)
        .agg(
            active_city_ct=("city_country", "nunique"),
            active_band_ct=("genre_active_bands", "sum"),
        )
        .sort_values("snapshot_year")
    )

    cumulative = (
        first_subset.groupby("emergence_year", as_index=False)
        .agg(new_emerged_cities=("city_country", "nunique"))
        .sort_values("emergence_year")
    )
    cumulative["cumulative_emerged_cities"] = cumulative["new_emerged_cities"].cumsum()
    yearly_summary = yearly_summary.merge(
        cumulative[["emergence_year", "new_emerged_cities", "cumulative_emerged_cities"]],
        left_on="snapshot_year",
        right_on="emergence_year",
        how="left",
    ).drop(columns=["emergence_year"])
    yearly_summary["new_emerged_cities"] = yearly_summary["new_emerged_cities"].fillna(0).astype(int)
    yearly_summary["cumulative_emerged_cities"] = yearly_summary["cumulative_emerged_cities"].ffill().fillna(0).astype(int)
    return panel, yearly_summary


def genre_label(genre_family: str) -> str:
    return genre_family.replace("_", " ").title()


def build_map_html(panel: pd.DataFrame, genre_family: str, output_path: Path) -> None:
    color_map = {
        "Active before emergence": "#8C929A",
        "Emerged local scene": "#C1121F",
    }
    title_text = f"{genre_family.replace('_', ' ').title()} diffusion across city scenes over time"
    fig = px.scatter_geo(
        panel,
        lat="latitude",
        lon="longitude",
        animation_frame="snapshot_year",
        color="stage",
        size="marker_size",
        size_max=12,
        hover_name="city_country",
        hover_data={
            "genre_active_bands": True,
            "hover_size_bucket": True,
            "hover_first_band_year": True,
            "hover_emergence_year": True,
            "hover_total_bands": True,
            "latitude": False,
            "longitude": False,
            "snapshot_year": False,
            "marker_size": False,
            "stage": False,
        },
        color_discrete_map=color_map,
        projection=MAP_PROJECTION,
        title=title_text,
    )
    fig.update_traces(marker=dict(line=dict(width=0.35, color="#E5E7EB"), opacity=0.82))
    fig.update_layout(
        template="plotly_dark",
        legend_title_text="Local stage",
        margin=dict(l=20, r=20, t=65, b=20),
        paper_bgcolor="#050505",
        plot_bgcolor="#050505",
        font=dict(color="#F3F4F6"),
        legend=dict(
            bgcolor="rgba(5,5,5,0.7)",
            bordercolor="#2A2A2A",
            borderwidth=1,
        ),
        geo=dict(
            projection=dict(type=MAP_PROJECTION),
            showframe=False,
            showland=True,
            bgcolor="#050505",
            landcolor="#0E0E0E",
            showcountries=True,
            countrycolor="#3A3A3A",
            showcoastlines=True,
            coastlinecolor="#2A2A2A",
            showocean=True,
            oceancolor="#111111",
            showlakes=True,
            lakecolor="#111111",
            lataxis=dict(range=MAP_LAT_RANGE),
            lonaxis=dict(range=MAP_LON_RANGE),
        ),
    )
    fig.write_html(output_path, include_plotlyjs="cdn", auto_play=False)


def build_compare_map_html(
    panel: pd.DataFrame,
    primary_genre: str,
    compare_genre: str,
    output_path: Path,
) -> None:
    compare_panel = panel.copy()
    legend_key_map = {
        (primary_genre, "Active before emergence"): f"{genre_label(primary_genre)} pre-scene",
        (primary_genre, "Emerged local scene"): f"{genre_label(primary_genre)} emerged",
        (compare_genre, "Active before emergence"): f"{genre_label(compare_genre)} pre-scene",
        (compare_genre, "Emerged local scene"): f"{genre_label(compare_genre)} emerged",
    }
    color_map = {
        f"{genre_label(primary_genre)} pre-scene": "#7C8A99",
        f"{genre_label(primary_genre)} emerged": "#4EA8DE",
        f"{genre_label(compare_genre)} pre-scene": "#8F4A52",
        f"{genre_label(compare_genre)} emerged": "#FF3B30",
    }
    compare_panel["legend_key"] = compare_panel.apply(
        lambda row: legend_key_map[(row["genre_family"], row["stage"])],
        axis=1,
    )

    title_text = f"{genre_label(primary_genre)} vs {genre_label(compare_genre)} diffusion across city scenes over time"
    fig = px.scatter_geo(
        compare_panel,
        lat="latitude",
        lon="longitude",
        animation_frame="snapshot_year",
        color="legend_key",
        size="marker_size",
        size_max=12,
        hover_name="city_country",
        hover_data={
            "genre_family": True,
            "genre_active_bands": True,
            "hover_size_bucket": True,
            "hover_first_band_year": True,
            "hover_emergence_year": True,
            "hover_total_bands": True,
            "latitude": False,
            "longitude": False,
            "snapshot_year": False,
            "marker_size": False,
            "stage": True,
            "legend_key": False,
        },
        color_discrete_map=color_map,
        projection=MAP_PROJECTION,
        title=title_text,
    )
    fig.update_traces(marker=dict(line=dict(width=0.3, color="#E5E7EB"), opacity=0.74))
    fig.update_layout(
        template="plotly_dark",
        legend_title_text="Genre and stage",
        margin=dict(l=20, r=20, t=65, b=20),
        paper_bgcolor="#050505",
        plot_bgcolor="#050505",
        font=dict(color="#F3F4F6"),
        legend=dict(
            bgcolor="rgba(5,5,5,0.7)",
            bordercolor="#2A2A2A",
            borderwidth=1,
        ),
        geo=dict(
            projection=dict(type=MAP_PROJECTION),
            showframe=False,
            showland=True,
            bgcolor="#050505",
            landcolor="#0E0E0E",
            showcountries=True,
            countrycolor="#3A3A3A",
            showcoastlines=True,
            coastlinecolor="#2A2A2A",
            showocean=True,
            oceancolor="#111111",
            showlakes=True,
            lakecolor="#111111",
            lataxis=dict(range=MAP_LAT_RANGE),
            lonaxis=dict(range=MAP_LON_RANGE),
        ),
    )
    fig.write_html(output_path, include_plotlyjs="cdn", auto_play=False)


def write_summary(
    genre_family: str,
    coordinates: pd.DataFrame,
    first_subset: pd.DataFrame,
    panel: pd.DataFrame,
    yearly_summary: pd.DataFrame,
    summary_path: Path,
    html_path: Path,
    coords_path: Path,
    panel_path: Path,
) -> None:
    matched_ct = int(coordinates["coord_match_i"].sum())
    total_ct = int(len(coordinates))
    earliest = (
        first_subset[["city_country", "first_band_year", "emergence_year", "total_bands"]]
        .sort_values(["emergence_year", "first_band_year", "city_country"])
        .head(12)
    )
    peaks = (
        panel.groupby("city_country", as_index=False)
        .agg(peak_active_bands=("genre_active_bands", "max"), emergence_year=("emergence_year", "first"))
        .sort_values(["peak_active_bands", "emergence_year"], ascending=[False, True])
        .head(12)
    )

    lines = [
        f"# {genre_family.replace('_', ' ').title()} scene diffusion summary",
        "",
        "## Output files",
        f"- animated map: `{html_path.relative_to(PROJECT_ROOT).as_posix()}`",
        f"- coordinate crosswalk: `{coords_path.relative_to(PROJECT_ROOT).as_posix()}`",
        f"- matched city-year panel: `{panel_path.relative_to(PROJECT_ROOT).as_posix()}`",
        "",
        "## Prototype scope",
        f"- genre family: `{genre_family}`",
        "- unit on the map: geography-clean cities that eventually reach local scene emergence",
        "- yearly marker size: active local bands in the focal genre",
        "- yearly color split: active before emergence versus emerged local scene",
        "",
        "## Coordinate coverage",
        f"- matched cities: `{matched_ct}` of `{total_ct}` (`{matched_ct / total_ct:.1%}`)",
        f"- matched yearly active city observations: `{len(panel):,}`",
        f"- year range on map: `{int(panel['snapshot_year'].min())}` to `{int(panel['snapshot_year'].max())}`",
        "",
        "## Early emerged hubs",
        "",
        "| City | First band year | Emergence year | Total bands |",
        "| --- | ---: | ---: | ---: |",
    ]
    for row in earliest.itertuples(index=False):
        lines.append(
            f"| {row.city_country} | {int(row.first_band_year)} | {int(row.emergence_year)} | {int(row.total_bands)} |"
        )

    lines.extend(
        [
            "",
            "## Peak active-band hubs in the matched panel",
            "",
            "| City | Peak active bands | Emergence year |",
            "| --- | ---: | ---: |",
        ]
    )
    for row in peaks.itertuples(index=False):
        lines.append(f"| {row.city_country} | {int(row.peak_active_bands)} | {int(row.emergence_year)} |")

    selected_rows = yearly_summary.loc[yearly_summary["snapshot_year"].isin(SELECTED_YEARS)].copy()
    lines.extend(
        [
            "",
            "## Diffusion snapshots",
            "",
            "| Year | Active matched cities | Active matched bands | Cumulative emerged cities |",
            "| --- | ---: | ---: | ---: |",
        ]
    )
    for row in selected_rows.itertuples(index=False):
        lines.append(
            f"| {int(row.snapshot_year)} | {int(row.active_city_ct)} | {int(row.active_band_ct)} | {int(row.cumulative_emerged_cities)} |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "This first object is descriptive rather than causal. It is useful because it shows the genre",
            "spreading through a sequence of local scene formations rather than as a single birthplace story.",
            "The right next empirical step, if this branch is kept, is not a map refinement. It is an",
            "exposure panel that asks whether later city-genre emergence tracks prior external exposure to",
            "already-emerged same-genre hubs, ideally in a distance-weighted form.",
        ]
    )
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build a first animated city-scene diffusion map for one genre.")
    parser.add_argument("--genre", default="black_metal", help="Genre family to visualize.")
    parser.add_argument(
        "--compare-genre",
        default="",
        help="Optional second genre family to overlay in a separate comparison HTML.",
    )
    args = parser.parse_args()

    DIFFUSION_DIR.mkdir(parents=True, exist_ok=True)
    genre_slug = args.genre
    coords_path = DIFFUSION_DIR / f"{genre_slug}_city_coordinates.csv"
    panel_path = DIFFUSION_DIR / f"{genre_slug}_scene_diffusion_panel.csv"
    html_path = DIFFUSION_DIR / f"{genre_slug}_scene_diffusion_map.html"
    summary_path = DIFFUSION_DIR / f"{genre_slug}_scene_diffusion_summary.md"
    compare_slug = normalize_text(args.compare_genre)
    compare_html_path = None
    if compare_slug:
        compare_html_path = DIFFUSION_DIR / f"{genre_slug}_vs_{compare_slug}_scene_diffusion_map.html"

    first_appearance = pd.read_csv(FIRST_APPEARANCE_PATH, dtype=str, keep_default_na=False)
    richer_features = pd.read_csv(RICHER_FEATURES_PATH, dtype=str, keep_default_na=False)
    geography_audit = pd.read_csv(GEOGRAPHY_AUDIT_PATH, dtype=str, keep_default_na=False)

    geography_audit["exclude_city_baseline_i"] = pd.to_numeric(
        geography_audit["exclude_city_baseline_i"], errors="coerce"
    ).fillna(0)
    first_appearance = first_appearance.merge(
        geography_audit[["city_country", "exclude_city_baseline_i"]],
        on="city_country",
        how="left",
    )
    first_appearance = first_appearance.loc[first_appearance["exclude_city_baseline_i"].fillna(0) == 0].copy()

    first_genre = first_appearance.loc[first_appearance["genre_family"] == genre_slug].copy()
    first_genre["emergence_year"] = pd.to_numeric(first_genre["emergence_year"], errors="coerce")
    first_genre = first_genre.loc[first_genre["emergence_year"].notna()].copy()

    coordinates = build_coordinate_crosswalk(first_genre)
    panel, yearly_summary = build_diffusion_panel(genre_slug, first_appearance, richer_features, coordinates)
    first_matched = (
        first_genre.merge(coordinates[["city_country", "coord_match_i"]], on="city_country", how="left")
        .loc[lambda df: df["coord_match_i"] == 1]
        .copy()
    )

    coordinates.to_csv(coords_path, index=False)
    panel.to_csv(panel_path, index=False)
    build_map_html(panel, genre_slug, html_path)
    if compare_slug:
        compare_first_genre = first_appearance.loc[first_appearance["genre_family"] == compare_slug].copy()
        compare_first_genre["emergence_year"] = pd.to_numeric(compare_first_genre["emergence_year"], errors="coerce")
        compare_first_genre = compare_first_genre.loc[compare_first_genre["emergence_year"].notna()].copy()
        compare_coordinates = build_coordinate_crosswalk(compare_first_genre)
        compare_panel, _ = build_diffusion_panel(compare_slug, first_appearance, richer_features, compare_coordinates)
        combined_panel = pd.concat([panel, compare_panel], ignore_index=True)
        build_compare_map_html(combined_panel, genre_slug, compare_slug, compare_html_path)
    write_summary(genre_slug, coordinates, first_matched, panel, yearly_summary, summary_path, html_path, coords_path, panel_path)

    print(f"Wrote coordinate crosswalk: {coords_path}")
    print(f"Wrote diffusion panel: {panel_path}")
    print(f"Wrote animated map: {html_path}")
    if compare_html_path is not None:
        print(f"Wrote comparison map: {compare_html_path}")
    print(f"Wrote summary: {summary_path}")


if __name__ == "__main__":
    main()
