from __future__ import annotations

import re
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
SCENE_DIR = PROCESSED_DIR / "scene_networks"

EVENTS_PATH = SCENE_DIR / "central_loss_verified_death_events.csv"
GENRE_PANEL_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
CITY_PANEL_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
BAND_PATH = PROCESSED_DIR / "metal_archives_all_metal_band_clean.csv"

OUT_WINDOW = SCENE_DIR / "central_loss_outcome_prototype_window.csv"
OUT_EVENT_DELTAS = SCENE_DIR / "central_loss_outcome_event_deltas.csv"
OUT_RELATIVE = SCENE_DIR / "central_loss_outcome_relative_year.csv"
OUT_SUMMARY = SCENE_DIR / "central_loss_outcome_prototype_summary.md"

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


def extract_city(notes_str: str) -> str:
    if not isinstance(notes_str, str) or not notes_str:
        return ""
    match = re.search(r"location=([^;]+)", notes_str)
    if not match:
        return ""
    parts = [part.strip() for part in match.group(1).strip().split(",")]
    return parts[0] if parts else ""


def normalize_city_country(city: str, country: str) -> str:
    city = "" if pd.isna(city) else str(city).strip()
    country = "" if pd.isna(country) else str(country).strip()
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


def classify_emergence_timing(terminal_year: int, emergence_year: float | int | None) -> str:
    if pd.isna(emergence_year):
        return "no_emergence_record"
    emergence_year = int(emergence_year)
    if terminal_year < emergence_year:
        return "pre_emergence"
    if terminal_year == emergence_year:
        return "emergence_year"
    return "post_emergence"


def build_local_genre_starts() -> pd.DataFrame:
    bands = pd.read_csv(BAND_PATH, low_memory=False)
    rows: list[dict[str, object]] = []
    for row in bands.itertuples(index=False):
        city = extract_city(getattr(row, "notes", ""))
        country = getattr(row, "country_std", "")
        formed_year = getattr(row, "formed_year", pd.NA)
        if pd.isna(formed_year):
            continue
        try:
            formed_year = int(float(formed_year))
        except (TypeError, ValueError):
            continue
        city_country = normalize_city_country(city, country)
        if not city_country:
            continue
        for genre_family in parse_genre_families(getattr(row, "genre_raw", "")):
            rows.append(
                {
                    "city_country": city_country,
                    "genre_family": genre_family,
                    "snapshot_year": formed_year,
                }
            )
    starts = (
        pd.DataFrame(rows)
        .groupby(["city_country", "genre_family", "snapshot_year"], as_index=False)
        .size()
        .rename(columns={"size": "local_genre_band_starts"})
    )
    return starts


def summarize_period(frame: pd.DataFrame, years: list[int], column: str) -> float:
    subset = frame.loc[frame["relative_year"].isin(years), column].dropna()
    if subset.empty:
        return float("nan")
    return float(subset.mean())


def format_float(value: float) -> str:
    if pd.isna(value):
        return ""
    return f"{value:.3f}"


def main() -> None:
    events = pd.read_csv(EVENTS_PATH, low_memory=False)
    emergence = pd.read_csv(EMERGENCE_PATH, low_memory=False)[
        ["city_country", "genre_family", "emergence_year"]
    ].copy()
    genre_panel = pd.read_csv(GENRE_PANEL_PATH, low_memory=False)
    city_panel = pd.read_csv(CITY_PANEL_PATH, low_memory=False)
    local_starts = build_local_genre_starts()

    events = events.merge(emergence, on=["city_country", "genre_family"], how="left")
    events["emergence_timing"] = events.apply(
        lambda row: classify_emergence_timing(int(row["terminal_year"]), row["emergence_year"]),
        axis=1,
    )

    support = genre_panel.merge(
        events[["member_name", "terminal_year", "city_country", "genre_family"]],
        on=["city_country", "genre_family"],
        how="inner",
    ).copy()
    support["relative_year"] = support["snapshot_year"] - support["terminal_year"]
    support = support.loc[support["relative_year"].between(-5, 3)].copy()
    availability = (
        support.groupby(["member_name", "city_country", "genre_family", "terminal_year"], as_index=False)
        .agg(
            pre_years_available=("relative_year", lambda s: int((s < 0).sum())),
            post_years_available=("relative_year", lambda s: int((s > 0).sum())),
            event_year_available=("relative_year", lambda s: int((s == 0).any())),
        )
    )
    events = events.merge(
        availability,
        on=["member_name", "city_country", "genre_family", "terminal_year"],
        how="left",
    )
    events["usable_for_short_post_window"] = (
        events["pre_years_available"].fillna(0).ge(3)
        & events["event_year_available"].fillna(0).eq(1)
        & events["post_years_available"].fillna(0).ge(1)
    ).astype(int)

    analysis_events = events.loc[
        events["emergence_timing"].eq("post_emergence")
        & events["usable_for_short_post_window"].eq(1)
    ].copy()

    window = genre_panel.merge(
        analysis_events[
            [
                "member_name",
                "terminal_year",
                "city_country",
                "genre_family",
                "event_date",
            ]
        ],
        on=["city_country", "genre_family"],
        how="inner",
    ).copy()
    window["relative_year"] = window["snapshot_year"] - window["terminal_year"]
    window = window.loc[window["relative_year"].between(-5, 3)].copy()
    window = window.merge(
        city_panel,
        on=["city_country", "snapshot_year"],
        how="left",
        suffixes=("", "_city"),
    )
    window = window.merge(
        local_starts,
        on=["city_country", "genre_family", "snapshot_year"],
        how="left",
    )
    window["local_genre_band_starts"] = window["local_genre_band_starts"].fillna(0.0)

    keep_cols = [
        "member_name",
        "event_date",
        "terminal_year",
        "city_country",
        "genre_family",
        "snapshot_year",
        "relative_year",
        "local_genre_band_starts",
        "genre_active_bands",
        "genre_multi_band_musicians",
        "genre_active_musicians",
        "bands_formed",
        "spawn_bands_formed",
        "spawn_share_formed",
        "founder_pedigree_mean",
        "n_active_bands",
        "n_multi_band_musicians_total",
    ]
    window = window[keep_cols].sort_values(
        ["member_name", "terminal_year", "relative_year"]
    )
    window.to_csv(OUT_WINDOW, index=False)

    relative = (
        window.groupby("relative_year", as_index=False)
        .agg(
            n_unique_events=("member_name", "nunique"),
            mean_local_genre_band_starts=("local_genre_band_starts", "mean"),
            mean_genre_active_bands=("genre_active_bands", "mean"),
            mean_genre_multi_band_musicians=("genre_multi_band_musicians", "mean"),
            mean_city_band_starts=("bands_formed", "mean"),
            mean_city_spawn_bands_formed=("spawn_bands_formed", "mean"),
            mean_city_spawn_share=("spawn_share_formed", "mean"),
        )
    )
    relative.to_csv(OUT_RELATIVE, index=False)

    event_rows: list[dict[str, object]] = []
    metrics = [
        "local_genre_band_starts",
        "genre_active_bands",
        "genre_multi_band_musicians",
        "bands_formed",
        "spawn_bands_formed",
        "spawn_share_formed",
    ]
    for keys, frame in window.groupby(
        ["member_name", "terminal_year", "city_country", "genre_family"], dropna=False
    ):
        row = {
            "member_name": keys[0],
            "terminal_year": keys[1],
            "city_country": keys[2],
            "genre_family": keys[3],
        }
        for metric in metrics:
            pre = summarize_period(frame, [-3, -2, -1], metric)
            post = summarize_period(frame, [0, 1], metric)
            row[f"pre_{metric}"] = pre
            row[f"post_{metric}"] = post
            row[f"delta_{metric}"] = post - pre if not (pd.isna(pre) or pd.isna(post)) else float("nan")
        event_rows.append(row)

    event_deltas = pd.DataFrame(event_rows).sort_values(["terminal_year", "member_name"])
    event_deltas.to_csv(OUT_EVENT_DELTAS, index=False)

    lines = [
        "# Central loss outcome prototype",
        "",
        "## Scope",
        "",
        f"- Verified death events in clean file: `{len(events):,}`",
        f"- Post-emergence deaths with a usable short post window: `{len(analysis_events):,}`",
        "- This is a descriptive prototype for post-emergence margins, not a causal estimate.",
        "",
        "## Relative-year means",
        "",
        "| Relative year | Events | Focal genre band starts | Focal active bands | Focal multi-band musicians | City band starts | City spawning flow | City spawning share |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in relative.itertuples(index=False):
        lines.append(
            f"| {int(row.relative_year)} | {int(row.n_unique_events)} | "
            f"{format_float(row.mean_local_genre_band_starts)} | "
            f"{format_float(row.mean_genre_active_bands)} | "
            f"{format_float(row.mean_genre_multi_band_musicians)} | "
            f"{format_float(row.mean_city_band_starts)} | "
            f"{format_float(row.mean_city_spawn_bands_formed)} | "
            f"{format_float(row.mean_city_spawn_share)} |"
        )

    lines.extend(["", "## Average pre versus post deltas", ""])
    labels = {
        "local_genre_band_starts": "Focal genre band starts",
        "genre_active_bands": "Focal active bands",
        "genre_multi_band_musicians": "Focal multi-band musicians",
        "bands_formed": "City band starts",
        "spawn_bands_formed": "City spawning flow",
        "spawn_share_formed": "City spawning share",
    }
    for metric, label in labels.items():
        pre_mean = event_deltas[f"pre_{metric}"].mean()
        post_mean = event_deltas[f"post_{metric}"].mean()
        delta_mean = event_deltas[f"delta_{metric}"].mean()
        negative_share = (event_deltas[f"delta_{metric}"] < 0).mean()
        lines.append(
            f"- `{label}`: pre `[-3,-1] = {format_float(pre_mean)}`, post `[0,+1] = {format_float(post_mean)}`, "
            f"mean delta = `{format_float(delta_mean)}`, share negative = `{format_float(negative_share)}`."
        )

    lines.extend(
        [
            "",
            "## Event-level focal band-start deltas",
            "",
            "| Event | Pre focal band starts | Post focal band starts | Delta |",
            "| --- | ---: | ---: | ---: |",
        ]
    )
    for row in event_deltas.itertuples(index=False):
        label = f"{row.member_name} ({row.city_country} x {row.genre_family} x {int(row.terminal_year)})"
        lines.append(
            f"| {label} | {format_float(row.pre_local_genre_band_starts)} | "
            f"{format_float(row.post_local_genre_band_starts)} | "
            f"{format_float(row.delta_local_genre_band_starts)} |"
        )

    OUT_SUMMARY.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_WINDOW}")
    print(f"Wrote {OUT_EVENT_DELTAS}")
    print(f"Wrote {OUT_RELATIVE}")
    print(f"Wrote {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
