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
BAND_PANEL_PATH = PROJECT_ROOT / "data" / "processed" / "band_success" / "band_birth_panel.csv"
GEOGRAPHY_AUDIT_PATH = SCENE_DIR / "city_geography_audit.csv"
OUT_DIR = SCENE_DIR / "band_world_animation"

ANIMATION_END_YEAR = 2022

COUNTRY_ISO3_ALIAS = {
    "Czechia": "CZE",
    "Russian Federation": "RUS",
    "United States": "USA",
    "United Kingdom": "GBR",
    "Korea, Rep.": "KOR",
    "Korea, Republic of": "KOR",
    "Venezuela, RB": "VEN",
    "Egypt, Arab Rep.": "EGY",
    "Turkiye": "TUR",
    "Turkey": "TUR",
    "Bosnia and Herzegovina": "BIH",
    "North Macedonia": "MKD",
    "Macedonia": "MKD",
}

CITY_ALIASES = {
    ("brooklyn", "US"): ["brooklyn new york city"],
    ("busan", "KR"): ["pusan"],
    ("antwerp", "BE"): ["antwerpen"],
    ("bruges", "BE"): ["brugge"],
    ("east jakarta", "ID"): ["jakarta"],
    ("barquisimeto", "VE"): ["barquisimeto"],
    ("cairo", "EG"): ["cairo"],
    ("sofia", "BG"): ["sofija"],
}

FRAME_STEP_YEARS = 3
MAP_PROJECTION = "equirectangular"
MAP_LAT_RANGE = [-58, 85]
MAP_LON_RANGE = [-180, 180]


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


def country_to_iso2(country_name: str, iso3: str) -> str:
    iso3_clean = normalize_text(iso3)
    if iso3_clean in COUNTRY_ISO3_ALIAS:
        iso3_clean = COUNTRY_ISO3_ALIAS[iso3_clean]
    try:
        if iso3_clean:
            country = pycountry.countries.get(alpha_3=iso3_clean)
            if country:
                return country.alpha_2
    except LookupError:
        pass

    name = normalize_text(country_name)
    try:
        country = pycountry.countries.lookup(name)
        return country.alpha_2
    except LookupError:
        return ""


def parse_active_spans(value: object) -> list[tuple[int, int | None]]:
    text = normalize_text(value)
    if text in {"", "N/A", "?"}:
        return []

    spans: list[tuple[int, int | None]] = []
    for part in text.split(","):
        part = part.strip()
        match = re.match(r"(\d{4})\s*[-\u2013]\s*(\d{4}|present|\?)", part, re.IGNORECASE)
        if match:
            start = int(match.group(1))
            end_token = match.group(2).lower()
            end = None if end_token in {"present", "?"} else int(end_token)
            spans.append((start, end))
            continue

        match = re.match(r"(\d{4})", part)
        if match:
            year = int(match.group(1))
            spans.append((year, year))

    return spans


def build_geonames_index() -> dict[tuple[str, str], list[dict[str, object]]]:
    gc = geonamescache.GeonamesCache()
    index: dict[tuple[str, str], list[dict[str, object]]] = defaultdict(list)

    for row in gc.get_cities().values():
        names = [row.get("name", "")]
        names.extend(row.get("alternatenames", [])[:12])
        for name in names:
            key = normalize_key(name)
            if key:
                index[(key, row["countrycode"])].append(row)

    for key, values in index.items():
        values.sort(key=lambda row: int(row.get("population") or 0), reverse=True)

    return index


def city_candidates(city: str, iso2: str) -> list[tuple[str, str]]:
    key = normalize_key(city)
    candidates: list[tuple[str, str]] = []
    if key:
        candidates.append((key, iso2))
    if "(" in city:
        left = normalize_key(city.split("(", 1)[0])
        if left:
            candidates.append((left, iso2))
    if "/" in city:
        for piece in city.split("/"):
            piece_key = normalize_key(piece)
            if piece_key:
                candidates.append((piece_key, iso2))
    for alias in CITY_ALIASES.get((key, iso2), []):
        alias_key = normalize_key(alias)
        if alias_key:
            candidates.append((alias_key, iso2))

    deduped: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for candidate in candidates:
        if candidate not in seen:
            seen.add(candidate)
            deduped.append(candidate)
    return deduped


def build_coordinate_crosswalk(bands: pd.DataFrame) -> pd.DataFrame:
    index = build_geonames_index()
    rows: list[dict[str, object]] = []

    unique_locations = bands[["city_country", "city", "country", "countryiso3code"]].drop_duplicates()
    for row in unique_locations.itertuples(index=False):
        iso2 = country_to_iso2(row.country, row.countryiso3code)
        match = None
        matched_key = ""
        if iso2:
            for candidate in city_candidates(row.city, iso2):
                matches = index.get(candidate, [])
                if matches:
                    match = matches[0]
                    matched_key = candidate[0]
                    break

        rows.append(
            {
                "city_country": row.city_country,
                "city": row.city,
                "country": row.country,
                "countryiso3code": row.countryiso3code,
                "country_iso2": iso2,
                "coord_match_i": int(match is not None),
                "matched_key": matched_key,
                "matched_city_name": match.get("name", "") if match else "",
                "latitude": float(match["latitude"]) if match else math.nan,
                "longitude": float(match["longitude"]) if match else math.nan,
                "matched_population": int(match.get("population") or 0) if match else 0,
            }
        )

    coords = pd.DataFrame(rows).sort_values(["coord_match_i", "country", "city"], ascending=[False, True, True])
    return coords


def build_band_year_panel(
    bands: pd.DataFrame,
    coordinates: pd.DataFrame,
    frame_step_years: int,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    max_year = ANIMATION_END_YEAR
    min_year = int(bands["formed_year"].min())
    frame_years = list(range(min_year, max_year + 1, frame_step_years))
    if frame_years[-1] != max_year:
        frame_years.append(max_year)

    band_rows: list[dict[str, object]] = []
    for band in bands.itertuples(index=False):
        active_spans = parse_active_spans(band.active_status_raw)
        if not active_spans:
            active_spans = [(int(band.formed_year), int(band.formed_year))]

        active_years: set[int] = set()
        for start, end in active_spans:
            start_year = max(int(start), int(band.formed_year))
            end_year = max_year if end is None else min(int(end), max_year)
            if end_year < start_year:
                end_year = start_year
            active_years.update(range(start_year, end_year + 1))

        active_years = {year for year in active_years if year in frame_years}
        if not active_years:
            active_years = {int(band.formed_year)}

        formed_decade = int(band.formed_year // 10 * 10)
        if formed_decade < 1970:
            formed_decade_label = "pre-1970"
        else:
            formed_decade_label = f"{formed_decade}s"

        for year in sorted(active_years):
            band_rows.append(
                {
                    "band_id": band.band_id,
                    "band_name": band.band_name,
                    "band_name_norm": band.band_name_norm,
                    "city_country": band.city_country,
                    "city": band.city,
                    "country": band.country,
                    "countryiso3code": band.countryiso3code,
                    "formed_year": int(band.formed_year),
                    "formed_decade_label": formed_decade_label,
                    "frame_year": year,
                    "band_age_years": year - int(band.formed_year),
                    "active_span_raw": band.active_status_raw,
                }
            )

    panel = pd.DataFrame(band_rows)
    panel = panel.merge(
        coordinates[
            [
                "city_country",
                "coord_match_i",
                "matched_key",
                "matched_city_name",
                "latitude",
                "longitude",
                "matched_population",
            ]
        ],
        on="city_country",
        how="left",
    )
    panel = panel.loc[panel["coord_match_i"] == 1].copy()
    panel = panel.loc[panel["latitude"].notna() & panel["longitude"].notna()].copy()
    panel = panel.drop_duplicates(["band_id", "frame_year"]).copy()

    yearly_summary = (
        panel.groupby("frame_year", as_index=False)
        .agg(
            active_band_ct=("band_id", "nunique"),
            active_city_ct=("city_country", "nunique"),
            active_country_ct=("countryiso3code", "nunique"),
        )
        .sort_values("frame_year")
    )

    yearly_summary["new_active_band_ct"] = yearly_summary["active_band_ct"].diff().fillna(yearly_summary["active_band_ct"])
    yearly_summary["new_active_band_ct"] = yearly_summary["new_active_band_ct"].clip(lower=0).astype(int)
    return panel, yearly_summary


def build_animation_html(panel: pd.DataFrame, genre_family: str, output_path: Path) -> None:
    palette = {
        "1960s": "#8ecae6",
        "1970s": "#219ebc",
        "1980s": "#023047",
        "1990s": "#ffb703",
        "2000s": "#fb8500",
        "2010s": "#d62828",
        "2020s": "#6a4c93",
        "pre-1970": "#adb5bd",
    }

    title = f"{genre_family.replace('_', ' ').title()} band diffusion across the world"
    fig = px.scatter_geo(
        panel,
        lat="latitude",
        lon="longitude",
        animation_frame="frame_year",
        animation_group="band_id",
        color="formed_decade_label",
        color_discrete_map=palette,
        hover_name="band_name",
        hover_data={
            "city_country": True,
            "country": True,
            "formed_year": True,
            "band_age_years": True,
            "matched_city_name": True,
            "frame_year": False,
            "latitude": False,
            "longitude": False,
            "coord_match_i": False,
            "matched_key": False,
            "matched_population": False,
            "active_span_raw": False,
            "band_id": False,
            "band_name_norm": False,
            "countryiso3code": False,
        },
        size=None,
        projection=MAP_PROJECTION,
        title=title,
    )
    fig.update_traces(marker=dict(size=4, opacity=0.58, line=dict(width=0.25, color="white")))
    fig.update_layout(
        template="plotly_white",
        legend_title_text="Band formation decade",
        margin=dict(l=18, r=18, t=70, b=18),
        geo=dict(
            projection=dict(type=MAP_PROJECTION),
            showframe=False,
            showland=True,
            landcolor="#f6f1e8",
            showcountries=True,
            countrycolor="#bababa",
            showcoastlines=True,
            coastlinecolor="#bababa",
            showocean=True,
            oceancolor="#eef6fb",
            showlakes=True,
            lakecolor="#eef6fb",
            lataxis=dict(range=MAP_LAT_RANGE),
            lonaxis=dict(range=MAP_LON_RANGE),
        ),
    )
    fig.write_html(output_path, include_plotlyjs="cdn", auto_play=False)


def write_summary(
    genre_family: str,
    panel: pd.DataFrame,
    yearly_summary: pd.DataFrame,
    coordinates: pd.DataFrame,
    retained_band_total: int,
    summary_path: Path,
    html_path: Path,
    panel_path: Path,
    coords_path: Path,
    yearly_path: Path,
    frame_step_years: int,
) -> None:
    matched_city_count = int(coordinates["coord_match_i"].sum())
    total_city_count = int(len(coordinates))
    start_year = int(panel["frame_year"].min())
    end_year = int(panel["frame_year"].max())
    rows = []
    for row in yearly_summary.head(5).itertuples(index=False):
        rows.append(
            f"| {int(row.frame_year)} | {int(row.active_band_ct)} | {int(row.active_city_ct)} | {int(row.active_country_ct)} |"
        )

    city_frame = (
        panel.groupby(["city_country", "frame_year"], as_index=False)
        .agg(active_bands=("band_id", "nunique"))
        .sort_values(["city_country", "frame_year"])
    )
    peak_idx = city_frame.groupby("city_country")["active_bands"].idxmax()
    top_hubs = city_frame.loc[peak_idx].copy()
    top_hubs["country"] = top_hubs["city_country"].str.split(", ").str[-1]
    top_hubs = top_hubs.sort_values(["active_bands", "frame_year"], ascending=[False, True]).head(12)

    lines = [
        f"# {genre_family.replace('_', ' ').title()} band world animation summary",
        "",
        "## Output files",
        f"- animated map: `{html_path.relative_to(PROJECT_ROOT).as_posix()}`",
        f"- band-year panel: `{panel_path.relative_to(PROJECT_ROOT).as_posix()}`",
        f"- coordinate crosswalk: `{coords_path.relative_to(PROJECT_ROOT).as_posix()}`",
        f"- yearly summary: `{yearly_path.relative_to(PROJECT_ROOT).as_posix()}`",
        "",
        "## Prototype scope",
        f"- genre family: `{genre_family}`",
        f"- frame step: `{frame_step_years}` years",
        "- unit on the map: one active band dot per active snapshot year",
        "- active-year construction: parsed from `active_status_raw` using the same year-span logic as the member ingest helper",
        "- open-ended spans like `present` or `?` are treated as active through `2022`, which is the end of the current data window",
        "",
        "## Coverage",
        f"- bands retained after the geography-clean filter: `{retained_band_total:,}`",
        f"- geography-clean city matches: `{matched_city_count}` of `{total_city_count}` (`{matched_city_count / total_city_count:.1%}`)",
        f"- matched band-year observations on the animation grid: `{len(panel):,}`",
        f"- year range on the map: `{start_year}` to `{end_year}`",
        "",
        "## Early yearly snapshots",
        "",
        "| Year | Active bands | Active cities | Active countries |",
        "| --- | ---: | ---: | ---: |",
    ]
    lines.extend(rows)

    lines.extend(
        [
            "",
            "## Top city hubs",
            "",
            "| City | Peak active bands | Peak year | Country |",
            "| --- | ---: | ---: | --- |",
        ]
    )
    for row in top_hubs.itertuples(index=False):
        lines.append(
            f"| {row.city_country} | {int(row.active_bands)} | {int(row.frame_year)} | {row.country} |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "This prototype is good enough to keep if the animated HTML opens cleanly and the frames are",
            "readable. It is not a causal design. It is a visualization of the spread of active bands",
            "through time and space using the band-level activity spans already stored in the cleaned",
            "birth panel.",
            "",
            "If the figure stays in the project, the next empirical step should be a diffusion exposure",
            "panel, not a more elaborate animation. The useful question is whether later local scene",
            "emergence tracks prior exposure to already-active same-genre hubs.",
        ]
    )
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build a band-level world animation for a metal genre.")
    parser.add_argument("--genre", default="black_metal", help="Genre family to animate.")
    parser.add_argument("--frame-step", type=int, default=FRAME_STEP_YEARS, help="Year step between frames.")
    args = parser.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    genre_slug = args.genre
    coords_path = OUT_DIR / f"{genre_slug}_band_world_animation_coordinates.csv"
    panel_path = OUT_DIR / f"{genre_slug}_band_world_animation_panel.csv"
    yearly_path = OUT_DIR / f"{genre_slug}_band_world_animation_yearly_summary.csv"
    html_path = OUT_DIR / f"{genre_slug}_band_world_animation.html"
    summary_path = OUT_DIR / f"{genre_slug}_band_world_animation_summary.md"

    bands = pd.read_csv(BAND_PANEL_PATH, dtype=str, keep_default_na=False)
    geography_audit = pd.read_csv(GEOGRAPHY_AUDIT_PATH, dtype=str, keep_default_na=False)

    bands["formed_year"] = pd.to_numeric(bands["formed_year"], errors="coerce")
    bands = bands.loc[bands["formed_year"].notna()].copy()
    bands["formed_year"] = bands["formed_year"].astype(int)
    bands["countryiso3code"] = bands["countryiso3code"].map(normalize_text)
    bands["country"] = bands["country"].map(normalize_text)
    bands["city"] = bands["city"].map(normalize_text)
    bands["city_country"] = bands["city_country"].map(normalize_text)
    bands["genre_family"] = bands["genre_family"].map(normalize_text)
    bands["active_status_raw"] = bands["active_status_raw"].map(normalize_text)
    bands["band_name"] = bands["band_name"].map(normalize_text)
    bands["band_name_norm"] = bands["band_name_norm"].map(normalize_text)
    bands = bands.loc[bands["genre_family"] == genre_slug].copy()

    geography_audit["exclude_city_baseline_i"] = pd.to_numeric(
        geography_audit["exclude_city_baseline_i"], errors="coerce"
    ).fillna(0)
    bands = bands.merge(
        geography_audit[["city_country", "exclude_city_baseline_i"]],
        on="city_country",
        how="left",
    )
    bands = bands.loc[bands["exclude_city_baseline_i"].fillna(0) == 0].copy()

    coordinates = build_coordinate_crosswalk(bands)
    panel, yearly_summary = build_band_year_panel(bands, coordinates, args.frame_step)
    retained_band_total = int(bands["band_id"].nunique())

    coordinates.to_csv(coords_path, index=False)
    panel.to_csv(panel_path, index=False)
    yearly_summary.to_csv(yearly_path, index=False)
    build_animation_html(panel, genre_slug, html_path)
    write_summary(
        genre_slug,
        panel,
        yearly_summary,
        coordinates,
        retained_band_total,
        summary_path,
        html_path,
        panel_path,
        coords_path,
        yearly_path,
        args.frame_step,
    )

    print(f"Wrote coordinate crosswalk: {coords_path}")
    print(f"Wrote band-year panel: {panel_path}")
    print(f"Wrote yearly summary: {yearly_path}")
    print(f"Wrote animated map: {html_path}")
    print(f"Wrote summary: {summary_path}")


if __name__ == "__main__":
    main()
