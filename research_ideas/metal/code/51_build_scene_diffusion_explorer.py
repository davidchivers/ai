from __future__ import annotations

import argparse
import html
import importlib.util
import json
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
DIFFUSION_DIR = SCENE_DIR / "diffusion"
MAP_SCRIPT_PATH = Path(__file__).with_name("48_build_scene_diffusion_map.py")
BAND_SCRIPT_PATH = Path(__file__).with_name("49_build_band_genre_world_animation.py")
DETAIL_SAMPLE_LIMIT = 8

DEFAULT_GENRES = [
    "black_metal",
    "death_metal",
    "thrash_metal",
    "heavy_metal",
]

DEFAULT_SELECTED_GENRES = [
    "black_metal",
    "death_metal",
]

REGION_PRESETS = {
    "north_world": {
        "label": "North world",
        "lat_range": [-25, 85],
        "lon_range": [-130, 175],
    },
    "europe": {
        "label": "Europe",
        "lat_range": [34, 72],
        "lon_range": [-15, 45],
    },
    "north_america": {
        "label": "North America",
        "lat_range": [12, 72],
        "lon_range": [-170, -50],
    },
    "latin_america": {
        "label": "Latin America",
        "lat_range": [-58, 33],
        "lon_range": [-120, -30],
    },
}

GENRE_STYLES = {
    "black_metal": {
        "label": "Black metal",
        "pre_color": "#7C8A99",
        "emerged_color": "#4EA8DE",
    },
    "death_metal": {
        "label": "Death metal",
        "pre_color": "#8F4A52",
        "emerged_color": "#FF3B30",
    },
    "thrash_metal": {
        "label": "Thrash metal",
        "pre_color": "#8A6B3F",
        "emerged_color": "#F4A261",
    },
    "heavy_metal": {
        "label": "Heavy metal",
        "pre_color": "#6D5A8D",
        "emerged_color": "#B794F4",
    },
}


def load_map_module():
    spec = importlib.util.spec_from_file_location("scene_diffusion_map_module", MAP_SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load diffusion map helpers from {MAP_SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_band_module():
    spec = importlib.util.spec_from_file_location("scene_band_module", BAND_SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load band helpers from {BAND_SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def genre_label(genre_family: str) -> str:
    return genre_family.replace("_", " ")


def safe_json(value: object) -> str:
    return json.dumps(value, separators=(",", ":")).replace("</", "<\\/")


def build_band_details(
    genres: list[str],
    years: list[int],
    geography_audit: pd.DataFrame,
) -> dict[str, dict[str, object]]:
    band_module = load_band_module()
    bands = pd.read_csv(band_module.BAND_PANEL_PATH, dtype=str, keep_default_na=False)

    bands["formed_year"] = pd.to_numeric(bands["formed_year"], errors="coerce")
    bands = bands.loc[bands["formed_year"].notna()].copy()
    bands["formed_year"] = bands["formed_year"].astype(int)
    for column in ["city_country", "genre_family", "active_status_raw", "band_name", "country", "city", "countryiso3code"]:
        bands[column] = bands[column].map(band_module.normalize_text)

    bands = bands.loc[bands["genre_family"].isin(genres)].copy()
    bands = bands.merge(
        geography_audit[["city_country", "exclude_city_baseline_i"]],
        on="city_country",
        how="left",
    )
    bands = bands.loc[bands["exclude_city_baseline_i"].fillna(0) == 0].copy()

    year_set = set(years)
    rows: list[dict[str, object]] = []
    for band in bands.itertuples(index=False):
        active_spans = band_module.parse_active_spans(band.active_status_raw)
        if not active_spans:
            active_spans = [(int(band.formed_year), int(band.formed_year))]

        active_years: set[int] = set()
        for start, end in active_spans:
            start_year = max(int(start), int(band.formed_year))
            end_year = max(year_set) if end is None else min(int(end), max(year_set))
            if end_year < start_year:
                end_year = start_year
            active_years.update(range(start_year, end_year + 1))

        active_years = {year for year in active_years if year in year_set}
        if not active_years and int(band.formed_year) in year_set:
            active_years = {int(band.formed_year)}

        for year in active_years:
            rows.append(
                {
                    "genre_family": band.genre_family,
                    "city_country": band.city_country,
                    "snapshot_year": int(year),
                    "band_name": band.band_name,
                    "formed_year": int(band.formed_year),
                }
            )

    if not rows:
        return {}

    active_bands = pd.DataFrame(rows).sort_values(
        ["genre_family", "city_country", "snapshot_year", "formed_year", "band_name"]
    )
    grouped = (
        active_bands.groupby(["genre_family", "city_country", "snapshot_year"], as_index=False)
        .agg(
            sample_bands=("band_name", lambda s: list(s.head(DETAIL_SAMPLE_LIMIT))),
            sample_total=("band_name", "nunique"),
        )
        .sort_values(["genre_family", "snapshot_year", "city_country"])
    )

    details: dict[str, dict[str, object]] = {}
    for row in grouped.itertuples(index=False):
        sample_bands = [str(name) for name in row.sample_bands]
        details[f"{row.genre_family}|{int(row.snapshot_year)}|{row.city_country}"] = {
            "sample_bands": sample_bands,
            "sample_total": int(row.sample_total),
            "sample_more_count": max(int(row.sample_total) - len(sample_bands), 0),
        }
    return details


def build_explorer_payload(
    genres: list[str],
    selected_genres: list[str],
) -> tuple[dict[str, object], dict[str, object], dict[str, object], dict[str, object]]:
    map_module = load_map_module()
    first_appearance = pd.read_csv(map_module.FIRST_APPEARANCE_PATH, dtype=str, keep_default_na=False)
    richer_features = pd.read_csv(map_module.RICHER_FEATURES_PATH, dtype=str, keep_default_na=False)
    geography_audit = pd.read_csv(map_module.GEOGRAPHY_AUDIT_PATH, dtype=str, keep_default_na=False)

    geography_audit["exclude_city_baseline_i"] = pd.to_numeric(
        geography_audit["exclude_city_baseline_i"], errors="coerce"
    ).fillna(0)
    first_appearance = first_appearance.merge(
        geography_audit[["city_country", "exclude_city_baseline_i"]],
        on="city_country",
        how="left",
    )
    first_appearance = first_appearance.loc[first_appearance["exclude_city_baseline_i"].fillna(0) == 0].copy()
    all_years = sorted(
        pd.to_numeric(richer_features["snapshot_year"], errors="coerce").dropna().astype(int).unique().tolist()
    )
    band_details = build_band_details(genres, all_years, geography_audit)

    payload: dict[str, dict[str, dict[str, dict[str, list[object]]]]] = {}
    stats: dict[str, dict[str, dict[str, int]]] = {}
    years: set[int] = set()

    for genre in genres:
        first_genre = first_appearance.loc[first_appearance["genre_family"] == genre].copy()
        first_genre["emergence_year"] = pd.to_numeric(first_genre["emergence_year"], errors="coerce")
        first_genre = first_genre.loc[first_genre["emergence_year"].notna()].copy()
        coordinates = map_module.build_coordinate_crosswalk(first_genre)
        panel, yearly_summary = map_module.build_diffusion_panel(genre, first_appearance, richer_features, coordinates)

        panel = panel[
            [
                "snapshot_year",
                "genre_family",
                "stage",
                "latitude",
                "longitude",
                "marker_size",
                "genre_active_bands",
                "hover_size_bucket",
                "hover_first_band_year",
                "hover_emergence_year",
                "hover_total_bands",
                "city_country",
            ]
        ].copy()
        panel["latitude"] = panel["latitude"].round(3)
        panel["longitude"] = panel["longitude"].round(3)
        panel["snapshot_year"] = panel["snapshot_year"].astype(int)
        panel["marker_size"] = panel["marker_size"].astype(int)
        panel["genre_active_bands"] = panel["genre_active_bands"].astype(int)
        panel["hover_first_band_year"] = panel["hover_first_band_year"].astype(int)
        panel["hover_emergence_year"] = panel["hover_emergence_year"].astype(int)
        panel["hover_total_bands"] = panel["hover_total_bands"].astype(int)

        for year, year_df in panel.groupby("snapshot_year"):
            year_key = str(int(year))
            years.add(int(year))
            payload.setdefault(year_key, {}).setdefault(genre, {})
            for stage, stage_df in year_df.groupby("stage"):
                payload[year_key][genre][stage] = {
                    "lat": stage_df["latitude"].tolist(),
                    "lon": stage_df["longitude"].tolist(),
                    "size": stage_df["marker_size"].tolist(),
                    "customdata": stage_df[
                        [
                            "city_country",
                            "genre_family",
                            "stage",
                            "snapshot_year",
                            "genre_active_bands",
                            "hover_size_bucket",
                            "hover_first_band_year",
                            "hover_emergence_year",
                            "hover_total_bands",
                        ]
                    ].values.tolist(),
                }

        genre_stats = (
            yearly_summary.rename(
                columns={
                    "active_city_ct": "active_city_genre_cells",
                    "active_band_ct": "active_bands",
                    "cumulative_emerged_cities": "cumulative_emerged_city_genre_cells",
                }
            )[
                [
                    "snapshot_year",
                    "active_city_genre_cells",
                    "active_bands",
                    "cumulative_emerged_city_genre_cells",
                ]
            ]
            .copy()
        )
        stats[genre] = {
            str(int(row.snapshot_year)): {
                "active_city_genre_cells": int(row.active_city_genre_cells),
                "active_bands": int(row.active_bands),
                "cumulative_emerged_city_genre_cells": int(row.cumulative_emerged_city_genre_cells),
            }
            for row in genre_stats.itertuples(index=False)
        }

    years_sorted = sorted(years)
    default_year = 2010 if 2010 in years_sorted else years_sorted[min(len(years_sorted) - 1, len(years_sorted) // 2)]
    config = {
        "years": years_sorted,
        "default_year": default_year,
        "genres": genres,
        "default_selected_genres": [genre for genre in selected_genres if genre in genres],
        "genre_styles": GENRE_STYLES,
        "region_presets": REGION_PRESETS,
        "default_region": "north_world",
    }
    return payload, stats, band_details, config


def build_explorer_html(
    payload: dict[str, object],
    stats: dict[str, object],
    config: dict[str, object],
    detail_dirname: str,
    output_path: Path,
) -> None:
    genre_controls_html = "\n".join(
        [
            (
                f'<label class="genre-chip">'
                f'<input class="genre-toggle" type="checkbox" value="{genre}"'
                f'{" checked" if genre in config["default_selected_genres"] else ""}>'
                f'<span>{GENRE_STYLES[genre]["label"]}</span>'
                f"</label>"
            )
            for genre in config["genres"]
        ]
    )
    region_buttons_html = "\n".join(
        [
            (
                f'<button class="region-button{" active" if key == config["default_region"] else ""}" '
                f'data-region="{key}">{value["label"]}</button>'
            )
            for key, value in REGION_PRESETS.items()
        ]
    )

    html_text = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Metal scene diffusion explorer</title>
  <script src="https://cdn.plot.ly/plotly-3.3.1.min.js"></script>
  <style>
    :root {{
      --bg: #050505;
      --panel: #0f0f10;
      --panel-2: #141416;
      --text: #f3f4f6;
      --muted: #a1a1aa;
      --line: #26272b;
      --accent: #c1121f;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: radial-gradient(circle at top, #19191c 0%, var(--bg) 55%);
      color: var(--text);
      font-family: Georgia, "Times New Roman", serif;
    }}
    .page {{
      max-width: 1500px;
      margin: 0 auto;
      padding: 18px 18px 28px;
    }}
    .topbar {{
      display: grid;
      grid-template-columns: 1.4fr 1fr 1.2fr;
      gap: 14px;
      align-items: start;
      margin-bottom: 14px;
    }}
    .panel {{
      background: rgba(15, 15, 16, 0.92);
      border: 1px solid var(--line);
      border-radius: 14px;
      padding: 14px 15px;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
    }}
    .panel h1,
    .panel h2 {{
      margin: 0 0 8px;
      font-size: 15px;
      font-weight: 700;
      letter-spacing: 0.04em;
      text-transform: uppercase;
    }}
    .meta {{
      color: var(--muted);
      font-size: 14px;
      line-height: 1.45;
    }}
    .genre-grid {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }}
    .genre-chip {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 7px 10px;
      border: 1px solid var(--line);
      border-radius: 999px;
      background: var(--panel-2);
      cursor: pointer;
      user-select: none;
      font-size: 14px;
    }}
    .genre-chip input {{
      margin: 0;
      accent-color: var(--accent);
    }}
    .button-row {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }}
    .region-button,
    .transport-button {{
      border: 1px solid var(--line);
      background: var(--panel-2);
      color: var(--text);
      padding: 8px 11px;
      border-radius: 999px;
      cursor: pointer;
      font-size: 14px;
    }}
    .region-button.active,
    .transport-button.active {{
      background: #1d1d22;
      border-color: #4b5563;
    }}
    .year-wrap {{
      display: flex;
      align-items: center;
      gap: 10px;
      margin-top: 12px;
    }}
    .year-slider {{
      width: 100%;
      accent-color: var(--accent);
    }}
    .year-label {{
      min-width: 56px;
      text-align: right;
      font-size: 24px;
      font-weight: 700;
      letter-spacing: 0.03em;
    }}
    .summary {{
      margin-bottom: 12px;
      color: var(--muted);
      font-size: 14px;
      line-height: 1.5;
    }}
    #map {{
      height: 78vh;
      min-height: 700px;
      background: transparent;
      border: 1px solid var(--line);
      border-radius: 18px;
      overflow: hidden;
    }}
    .main-grid {{
      display: grid;
      grid-template-columns: minmax(0, 1fr) 340px;
      gap: 14px;
      align-items: start;
    }}
    .detail-panel {{
      min-height: 220px;
      position: sticky;
      top: 16px;
    }}
    .detail-title {{
      margin: 0 0 10px;
      font-size: 16px;
      font-weight: 700;
      line-height: 1.3;
    }}
    .detail-meta {{
      display: grid;
      grid-template-columns: 1fr;
      gap: 8px;
      color: var(--muted);
      font-size: 14px;
      line-height: 1.45;
    }}
    .detail-list {{
      margin: 12px 0 0;
      padding-left: 18px;
      color: var(--text);
      font-size: 14px;
      line-height: 1.45;
    }}
    .detail-more {{
      margin-top: 10px;
      color: var(--muted);
      font-size: 13px;
    }}
    @media (max-width: 1180px) {{
      .topbar {{
        grid-template-columns: 1fr;
      }}
      .main-grid {{
        grid-template-columns: 1fr;
      }}
      #map {{
        height: 70vh;
        min-height: 560px;
      }}
      .detail-panel {{
        position: static;
      }}
    }}
  </style>
</head>
<body>
  <div class="page">
    <div class="topbar">
      <section class="panel">
        <h1>Metal scene diffusion explorer</h1>
        <div class="meta">
          Toggle genres on and off, then use the focus buttons to zoom toward Europe, North America,
          or Latin America. Spot size reflects active bands in that city-year, not just new starts.
        </div>
      </section>
      <section class="panel">
        <h2>Genres</h2>
        <div class="genre-grid">
          {genre_controls_html}
        </div>
      </section>
      <section class="panel">
        <h2>Focus and time</h2>
        <div class="button-row">
          {region_buttons_html}
        </div>
        <div class="button-row" style="margin-top: 10px;">
          <button class="transport-button" id="playButton">Play</button>
          <button class="transport-button" id="pauseButton">Pause</button>
        </div>
        <div class="year-wrap">
          <input class="year-slider" id="yearSlider" type="range" min="0" max="{len(config["years"]) - 1}" step="1">
          <div class="year-label" id="yearLabel"></div>
        </div>
      </section>
    </div>
    <div class="summary panel" id="summaryBar"></div>
    <div class="main-grid">
      <div id="map"></div>
      <aside class="panel detail-panel" id="detailPanel">
        <div class="detail-title">Node details</div>
        <div class="detail-meta">
          Click a city node to inspect that exact genre-year cell.
          The side panel will show the city, year, scene stage, and a sample of bands active there in that year.
        </div>
      </aside>
    </div>
  </div>
  <script>
    const payload = {safe_json(payload)};
    const yearlyStats = {safe_json(stats)};
    const config = {safe_json(config)};
    const stageOrder = ["Active before emergence", "Emerged local scene"];
    const stageOpacity = {{
      "Active before emergence": 0.42,
      "Emerged local scene": 0.86,
    }};

    let currentYear = config.default_year;
    let currentRegion = config.default_region;
    let currentValidYears = config.years.slice();
    let playTimer = null;
    const detailDirname = "{detail_dirname}";
    let detailCache = {{}};

    const mapEl = document.getElementById("map");
    const yearSlider = document.getElementById("yearSlider");
    const yearLabel = document.getElementById("yearLabel");
    const summaryBar = document.getElementById("summaryBar");
    const detailPanel = document.getElementById("detailPanel");
    const genreToggles = Array.from(document.querySelectorAll(".genre-toggle"));
    const regionButtons = Array.from(document.querySelectorAll(".region-button"));
    const playButton = document.getElementById("playButton");
    const pauseButton = document.getElementById("pauseButton");

    yearSlider.value = "0";

    function genreLabel(genre) {{
      return config.genre_styles[genre].label;
    }}

    function selectedGenres() {{
      return genreToggles.filter((toggle) => toggle.checked).map((toggle) => toggle.value);
    }}

    function escapeHtml(value) {{
      return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
    }}

    function detailKey(genre, year, cityCountry) {{
      return `${{genre}}|${{year}}|${{cityCountry}}`;
    }}

    function setDetailPlaceholder(message) {{
      detailPanel.innerHTML = `
        <div class="detail-title">Node details</div>
        <div class="detail-meta">${{message}}</div>
      `;
    }}

    function detailBucketKey(genre, year) {{
      return `${{genre}}|${{year}}`;
    }}

    function detailFileUrl(genre, year) {{
      return `${{detailDirname}}/${{genre}}_${{year}}.json`;
    }}

    async function loadDetailBucket(genre, year) {{
      const bucketKey = detailBucketKey(genre, year);
      if (detailCache[bucketKey]) {{
        return detailCache[bucketKey];
      }}
      try {{
        const response = await fetch(detailFileUrl(genre, year));
        if (!response.ok) {{
          throw new Error("detail file missing");
        }}
        const data = await response.json();
        detailCache[bucketKey] = data;
        return data;
      }} catch (_error) {{
        detailCache[bucketKey] = {{}};
        return detailCache[bucketKey];
      }}
    }}

    async function renderDetailFromCustomdata(customdata) {{
      if (!customdata || customdata.length < 9) {{
        setDetailPlaceholder("Click a city node to inspect that exact genre-year cell.");
        return;
      }}
      const [cityCountry, genre, stage, year, activeBands, sizeBucket, firstBandYear, emergenceYear, totalBands] = customdata;
      setDetailPlaceholder(`Loading node details for <strong>${{escapeHtml(cityCountry)}}</strong>...`);
      const bucket = await loadDetailBucket(genre, year);
      const detail = bucket[cityCountry] || {{
        sample_bands: [],
        sample_total: 0,
        sample_more_count: 0,
      }};
      const listHtml = detail.sample_bands.length
        ? detail.sample_bands.map((name) => `<li>${{escapeHtml(name)}}</li>`).join("")
        : "<li>No active band names available for this city-year.</li>";
      const moreHtml = detail.sample_more_count > 0
        ? `<div class="detail-more">Plus ${{detail.sample_more_count.toLocaleString()}} more active bands in this city-year.</div>`
        : "";

      detailPanel.innerHTML = `
        <div class="detail-title">${{escapeHtml(cityCountry)}}</div>
        <div class="detail-meta">
          <div><strong>Genre:</strong> ${{escapeHtml(genreLabel(genre))}}</div>
          <div><strong>Year:</strong> ${{year}}</div>
          <div><strong>Stage:</strong> ${{escapeHtml(stage)}}</div>
          <div><strong>Active bands:</strong> ${{Number(activeBands).toLocaleString()}} (${{escapeHtml(sizeBucket)}} size bucket)</div>
          <div><strong>First local band:</strong> ${{firstBandYear}}</div>
          <div><strong>Scene emergence:</strong> ${{emergenceYear}}</div>
          <div><strong>Total bands in this city-genre cell:</strong> ${{Number(totalBands).toLocaleString()}}</div>
          <div><strong>Sample of active bands in this year:</strong></div>
        </div>
        <ol class="detail-list">${{listHtml}}</ol>
        ${{moreHtml}}
      `;
    }}

    function pointInRegion(lat, lon, region) {{
      return lat >= region.lat_range[0] &&
             lat <= region.lat_range[1] &&
             lon >= region.lon_range[0] &&
             lon <= region.lon_range[1];
    }}

    function yearHasVisibleData(yearKey, genres, regionKey) {{
      const region = config.region_presets[regionKey];
      for (const genre of genres) {{
        const yearPayload = payload[yearKey] && payload[yearKey][genre] ? payload[yearKey][genre] : null;
        if (!yearPayload) continue;
        for (const stage of stageOrder) {{
          const stagePayload = yearPayload[stage];
          if (!stagePayload || !stagePayload.lat || !stagePayload.lat.length) continue;
          for (let i = 0; i < stagePayload.lat.length; i += 1) {{
            if (pointInRegion(stagePayload.lat[i], stagePayload.lon[i], region)) {{
              return true;
            }}
          }}
        }}
      }}
      return false;
    }}

    function availableYears(genres, regionKey) {{
      return config.years.filter((year) => yearHasVisibleData(String(year), genres, regionKey));
    }}

    function syncYearControl(genres) {{
      currentValidYears = availableYears(genres, currentRegion);
      if (!currentValidYears.length) {{
        yearSlider.disabled = true;
        yearSlider.min = "0";
        yearSlider.max = "0";
        yearSlider.value = "0";
        yearLabel.textContent = "--";
        return false;
      }}
      if (!currentValidYears.includes(currentYear)) {{
        currentYear = currentValidYears[0];
      }}
      yearSlider.disabled = currentValidYears.length <= 1;
      yearSlider.min = "0";
      yearSlider.max = String(currentValidYears.length - 1);
      yearSlider.value = String(currentValidYears.indexOf(currentYear));
      yearLabel.textContent = String(currentYear);
      return true;
    }}

    function buildTraces(yearKey, genres) {{
      const traces = [];
      for (const genre of genres) {{
        const yearPayload = payload[yearKey] && payload[yearKey][genre] ? payload[yearKey][genre] : null;
        if (!yearPayload) continue;
        for (const stage of stageOrder) {{
          const stagePayload = yearPayload[stage];
          if (!stagePayload || !stagePayload.lat || !stagePayload.lat.length) continue;
          const colorKey = stage === "Emerged local scene" ? "emerged_color" : "pre_color";
          traces.push({{
            type: "scattergeo",
            mode: "markers",
            name: `${{genreLabel(genre)}} - ${{stage === "Emerged local scene" ? "emerged" : "pre-scene"}}`,
            lat: stagePayload.lat,
            lon: stagePayload.lon,
            customdata: stagePayload.customdata,
            hovertemplate:
              "<b>%{{customdata[0]}}</b><br>" +
              "genre: %{{customdata[1]}}<br>" +
              "active bands: %{{customdata[4]}} (%{{customdata[5]}})<br>" +
              "first local band: %{{customdata[6]}}<br>" +
              "scene emergence: %{{customdata[7]}}<br>" +
              "total bands in cell: %{{customdata[8]}}<br>" +
              "stage: %{{customdata[2]}}<extra></extra>",
            marker: {{
              size: stagePayload.size,
              color: config.genre_styles[genre][colorKey],
              opacity: stageOpacity[stage],
              line: {{ color: "#E5E7EB", width: 0.25 }},
            }},
          }});
        }}
      }}
      return traces;
    }}

    function summarizeYear(yearKey, genres) {{
      let activeCityGenreCells = 0;
      let activeBands = 0;
      let cumulativeEmergedCells = 0;
      for (const genre of genres) {{
        const genreStats = yearlyStats[genre] && yearlyStats[genre][yearKey] ? yearlyStats[genre][yearKey] : null;
        if (!genreStats) continue;
        activeCityGenreCells += genreStats.active_city_genre_cells;
        activeBands += genreStats.active_bands;
        cumulativeEmergedCells += genreStats.cumulative_emerged_city_genre_cells;
      }}
      return {{
        activeCityGenreCells,
        activeBands,
        cumulativeEmergedCells,
      }};
    }}

    function stopPlayback() {{
      if (playTimer !== null) {{
        window.clearInterval(playTimer);
        playTimer = null;
      }}
      playButton.classList.remove("active");
      pauseButton.classList.add("active");
    }}

    function render() {{
      const genres = selectedGenres();
      const region = config.region_presets[currentRegion];
      const hasYears = syncYearControl(genres);

      if (!genres.length) {{
        setDetailPlaceholder("No genres are selected. Turn at least one genre on to draw the map.");
        Plotly.react(mapEl, [], {{
          paper_bgcolor: "#050505",
          plot_bgcolor: "#050505",
          font: {{ color: "#F3F4F6" }},
          margin: {{ l: 12, r: 12, t: 54, b: 8 }},
          title: {{ text: "Metal scene diffusion explorer", x: 0.02, xanchor: "left" }},
          geo: {{
            projection: {{ type: "equirectangular" }},
            showframe: false,
            bgcolor: "#050505",
            showland: true,
            landcolor: "#0E0E0E",
            showcountries: true,
            countrycolor: "#3A3A3A",
            showcoastlines: true,
            coastlinecolor: "#2A2A2A",
            showocean: true,
            oceancolor: "#111111",
            showlakes: true,
            lakecolor: "#111111",
            lataxis: {{ range: region.lat_range }},
            lonaxis: {{ range: region.lon_range }},
          }},
        }}, {{ responsive: true, displayModeBar: true, scrollZoom: true }});
        summaryBar.innerHTML = "No genres are selected. Turn at least one genre on to draw the map.";
        return;
      }}

      if (!hasYears) {{
        setDetailPlaceholder(`No visible data for ${{genres.map(genreLabel).join(", ")}} in ${{region.label}}.`);
        Plotly.react(mapEl, [], {{
          paper_bgcolor: "#050505",
          plot_bgcolor: "#050505",
          font: {{ color: "#F3F4F6" }},
          margin: {{ l: 12, r: 12, t: 54, b: 8 }},
          title: {{ text: "Metal scene diffusion explorer", x: 0.02, xanchor: "left" }},
          geo: {{
            projection: {{ type: "equirectangular" }},
            showframe: false,
            bgcolor: "#050505",
            showland: true,
            landcolor: "#0E0E0E",
            showcountries: true,
            countrycolor: "#3A3A3A",
            showcoastlines: true,
            coastlinecolor: "#2A2A2A",
            showocean: true,
            oceancolor: "#111111",
            showlakes: true,
            lakecolor: "#111111",
            lataxis: {{ range: region.lat_range }},
            lonaxis: {{ range: region.lon_range }},
          }},
        }}, {{ responsive: true, displayModeBar: true, scrollZoom: true }});
        summaryBar.innerHTML = `No visible data for <strong>${{genres.map(genreLabel).join(", ")}}</strong> in <strong>${{region.label}}</strong>.`;
        return;
      }}

      const yearKey = String(currentYear);
      const traces = buildTraces(yearKey, genres);
      const summary = summarizeYear(yearKey, genres);

      summaryBar.innerHTML =
        `Showing <strong>${{genres.map(genreLabel).join(", ")}}</strong> in <strong>${{region.label}}</strong>. ` +
        `The map now contains <strong>${{summary.activeCityGenreCells.toLocaleString()}}</strong> active city-genre cells, ` +
        `<strong>${{summary.activeBands.toLocaleString()}}</strong> active bands, and ` +
        `<strong>${{summary.cumulativeEmergedCells.toLocaleString()}}</strong> cumulative emerged city-genre cells at year <strong>${{yearKey}}</strong>.`;

      Plotly.react(
        mapEl,
        traces,
        {{
          paper_bgcolor: "#050505",
          plot_bgcolor: "#050505",
          font: {{ color: "#F3F4F6" }},
          margin: {{ l: 12, r: 12, t: 54, b: 8 }},
          title: {{
            text: "Metal scene diffusion explorer",
            x: 0.02,
            xanchor: "left",
          }},
          legend: {{
            bgcolor: "rgba(5,5,5,0.72)",
            bordercolor: "#2A2A2A",
            borderwidth: 1,
            orientation: "h",
            yanchor: "bottom",
            y: 0.01,
            xanchor: "left",
            x: 0.01,
          }},
          geo: {{
            projection: {{ type: "equirectangular" }},
            showframe: false,
            bgcolor: "#050505",
            showland: true,
            landcolor: "#0E0E0E",
            showcountries: true,
            countrycolor: "#3A3A3A",
            showcoastlines: true,
            coastlinecolor: "#2A2A2A",
            showocean: true,
            oceancolor: "#111111",
            showlakes: true,
            lakecolor: "#111111",
            lataxis: {{ range: region.lat_range }},
            lonaxis: {{ range: region.lon_range }},
          }},
        }},
        {{
          responsive: true,
          displayModeBar: true,
          scrollZoom: true,
        }}
      );

      if (!mapEl.dataset.clickBound) {{
        mapEl.on("plotly_click", (eventData) => {{
          const point = eventData && eventData.points && eventData.points.length ? eventData.points[0] : null;
          if (!point) return;
          renderDetailFromCustomdata(point.customdata);
        }});
        mapEl.dataset.clickBound = "1";
      }}
    }}

    genreToggles.forEach((toggle) => {{
      toggle.addEventListener("change", render);
    }});

    regionButtons.forEach((button) => {{
      button.addEventListener("click", () => {{
        currentRegion = button.dataset.region;
        regionButtons.forEach((candidate) => candidate.classList.remove("active"));
        button.classList.add("active");
        render();
      }});
    }});

    yearSlider.addEventListener("input", () => {{
      if (!currentValidYears.length) return;
      currentYear = currentValidYears[Number(yearSlider.value)];
      render();
    }});

    playButton.addEventListener("click", () => {{
      stopPlayback();
      if (!currentValidYears.length) return;
      playButton.classList.add("active");
      pauseButton.classList.remove("active");
      playTimer = window.setInterval(() => {{
        if (!currentValidYears.length) return;
        const currentIndex = currentValidYears.indexOf(currentYear);
        const nextIndex = (currentIndex + 1) % currentValidYears.length;
        currentYear = currentValidYears[nextIndex];
        yearSlider.value = String(nextIndex);
        render();
      }}, 900);
    }});

    pauseButton.addEventListener("click", stopPlayback);
    pauseButton.classList.add("active");
    render();
  </script>
</body>
</html>
"""
    output_path.write_text(html_text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build an interactive multi-genre scene diffusion explorer.")
    parser.add_argument(
        "--genres",
        nargs="+",
        default=DEFAULT_GENRES,
        help="Genre families to include in the explorer.",
    )
    parser.add_argument(
        "--default-selected",
        nargs="+",
        default=DEFAULT_SELECTED_GENRES,
        help="Genres checked by default when the explorer opens.",
    )
    args = parser.parse_args()

    DIFFUSION_DIR.mkdir(parents=True, exist_ok=True)
    output_path = DIFFUSION_DIR / "metal_scene_diffusion_explorer.html"
    detail_dir = DIFFUSION_DIR / "metal_scene_diffusion_explorer_band_details"
    payload, stats, band_details, config = build_explorer_payload(args.genres, args.default_selected)
    detail_dir.mkdir(parents=True, exist_ok=True)
    for existing_file in detail_dir.glob("*.json"):
        existing_file.unlink()

    detail_buckets: dict[tuple[str, str], dict[str, dict[str, object]]] = {}
    for key, value in band_details.items():
        genre, year, city_country = key.split("|", 2)
        detail_buckets.setdefault((genre, year), {})[city_country] = value

    for (genre, year), bucket in detail_buckets.items():
        bucket_path = detail_dir / f"{genre}_{year}.json"
        bucket_path.write_text(json.dumps(bucket, separators=(",", ":")), encoding="utf-8")

    build_explorer_html(payload, stats, config, detail_dir.name, output_path)
    print(f"Wrote diffusion explorer: {output_path}")
    print(f"Wrote band detail directory: {detail_dir}")


if __name__ == "__main__":
    main()
