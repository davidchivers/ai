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

OUT_MATCHES = SCENE_DIR / "central_loss_matched_controls.csv"
OUT_RELATIVE = SCENE_DIR / "central_loss_matched_relative_year_summary.csv"
OUT_EVENT_COMPARISON = SCENE_DIR / "central_loss_matched_event_comparison.csv"
OUT_SUMMARY = SCENE_DIR / "central_loss_matched_control_summary.md"

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
MATCH_YEARS = [-3, -2, -1, 0, 1]
CONTROL_COUNT = 3


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
        formed_year = getattr(row, "formed_year", pd.NA)
        if pd.isna(formed_year):
            continue
        try:
            formed_year = int(float(formed_year))
        except (TypeError, ValueError):
            continue
        city_country = normalize_city_country(city, getattr(row, "country_std", ""))
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


def compute_distance(treated: pd.Series, control: pd.Series, metrics: list[str]) -> float:
    distance = 0.0
    for metric in metrics:
        t = float(treated[metric])
        c = float(control[metric])
        scale = max(abs(t), 1.0)
        distance += abs(c - t) / scale
    return distance


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

    treated_events = events.loc[
        events["emergence_timing"].eq("post_emergence")
        & events["usable_for_short_post_window"].eq(1)
    ].copy()

    panel = genre_panel.merge(
        city_panel,
        on=["city_country", "snapshot_year"],
        how="left",
        suffixes=("", "_city"),
    ).merge(
        emergence,
        on=["city_country", "genre_family"],
        how="left",
    ).merge(
        local_starts,
        on=["city_country", "genre_family", "snapshot_year"],
        how="left",
    )
    panel["local_genre_band_starts"] = panel["local_genre_band_starts"].fillna(0.0)

    death_lookup = (
        events.groupby(["city_country", "genre_family"])["terminal_year"]
        .apply(list)
        .to_dict()
    )

    match_rows: list[dict[str, object]] = []
    comparison_rows: list[dict[str, object]] = []
    relative_rows: list[dict[str, object]] = []

    match_metrics = [
        "pre_local_genre_band_starts",
        "pre_genre_active_bands",
        "pre_genre_multi_band_musicians",
    ]

    for event in treated_events.itertuples(index=False):
        treated_window = panel.loc[
            panel["city_country"].eq(event.city_country)
            & panel["genre_family"].eq(event.genre_family)
            & panel["snapshot_year"].between(int(event.terminal_year) - 3, int(event.terminal_year) + 1)
        ].copy()
        if treated_window["snapshot_year"].nunique() < len(MATCH_YEARS):
            continue
        treated_window["relative_year"] = treated_window["snapshot_year"] - int(event.terminal_year)
        treated_window = treated_window.loc[treated_window["relative_year"].isin(MATCH_YEARS)].copy()

        treated_pre = {
            "pre_local_genre_band_starts": summarize_period(treated_window, [-3, -2, -1], "local_genre_band_starts"),
            "pre_genre_active_bands": summarize_period(treated_window, [-3, -2, -1], "genre_active_bands"),
            "pre_genre_multi_band_musicians": summarize_period(treated_window, [-3, -2, -1], "genre_multi_band_musicians"),
        }
        treated_pre = pd.Series(treated_pre)

        candidates: list[dict[str, object]] = []
        genre_frame = panel.loc[
            panel["genre_family"].eq(event.genre_family)
            & panel["city_country"].ne(event.city_country)
        ].copy()

        for candidate_city in sorted(genre_frame["city_country"].dropna().unique()):
            candidate_window = genre_frame.loc[
                genre_frame["city_country"].eq(candidate_city)
                & genre_frame["snapshot_year"].between(int(event.terminal_year) - 3, int(event.terminal_year) + 1)
            ].copy()
            if candidate_window["snapshot_year"].nunique() < len(MATCH_YEARS):
                continue
            candidate_emergence = candidate_window["emergence_year"].dropna()
            if candidate_emergence.empty or int(event.terminal_year) <= int(candidate_emergence.iloc[0]):
                continue

            death_years = death_lookup.get((candidate_city, event.genre_family), [])
            if any(abs(int(year) - int(event.terminal_year)) <= 1 for year in death_years):
                continue

            candidate_window["relative_year"] = candidate_window["snapshot_year"] - int(event.terminal_year)
            candidate_window = candidate_window.loc[candidate_window["relative_year"].isin(MATCH_YEARS)].copy()

            pre = pd.Series(
                {
                    "pre_local_genre_band_starts": summarize_period(candidate_window, [-3, -2, -1], "local_genre_band_starts"),
                    "pre_genre_active_bands": summarize_period(candidate_window, [-3, -2, -1], "genre_active_bands"),
                    "pre_genre_multi_band_musicians": summarize_period(candidate_window, [-3, -2, -1], "genre_multi_band_musicians"),
                }
            )
            if pre.isna().any():
                continue

            distance = compute_distance(treated_pre, pre, match_metrics)
            candidates.append(
                {
                    "treated_member_name": event.member_name,
                    "treated_city_country": event.city_country,
                    "treated_terminal_year": int(event.terminal_year),
                    "genre_family": event.genre_family,
                    "control_city_country": candidate_city,
                    "match_distance": distance,
                    "pre_local_genre_band_starts": pre["pre_local_genre_band_starts"],
                    "pre_genre_active_bands": pre["pre_genre_active_bands"],
                    "pre_genre_multi_band_musicians": pre["pre_genre_multi_band_musicians"],
                }
            )

        if not candidates:
            continue

        matches = (
            pd.DataFrame(candidates)
            .sort_values(["match_distance", "control_city_country"])
            .head(CONTROL_COUNT)
            .reset_index(drop=True)
        )
        matches["match_rank"] = matches.index + 1
        match_rows.extend(matches.to_dict("records"))

        control_cities = matches["control_city_country"].tolist()
        control_window = panel.loc[
            panel["genre_family"].eq(event.genre_family)
            & panel["city_country"].isin(control_cities)
            & panel["snapshot_year"].between(int(event.terminal_year) - 3, int(event.terminal_year) + 1)
        ].copy()
        control_window["relative_year"] = control_window["snapshot_year"] - int(event.terminal_year)
        control_window = control_window.loc[control_window["relative_year"].isin(MATCH_YEARS)].copy()

        treated_rel = (
            treated_window.groupby("relative_year", as_index=False)
            .agg(
                treated_local_genre_band_starts=("local_genre_band_starts", "mean"),
                treated_genre_active_bands=("genre_active_bands", "mean"),
                treated_genre_multi_band_musicians=("genre_multi_band_musicians", "mean"),
                treated_city_band_starts=("bands_formed", "mean"),
                treated_city_spawn_bands_formed=("spawn_bands_formed", "mean"),
            )
        )
        control_rel = (
            control_window.groupby("relative_year", as_index=False)
            .agg(
                control_local_genre_band_starts=("local_genre_band_starts", "mean"),
                control_genre_active_bands=("genre_active_bands", "mean"),
                control_genre_multi_band_musicians=("genre_multi_band_musicians", "mean"),
                control_city_band_starts=("bands_formed", "mean"),
                control_city_spawn_bands_formed=("spawn_bands_formed", "mean"),
            )
        )
        rel = treated_rel.merge(control_rel, on="relative_year", how="outer").sort_values("relative_year")
        rel["treated_member_name"] = event.member_name
        rel["treated_city_country"] = event.city_country
        rel["treated_terminal_year"] = int(event.terminal_year)
        rel["genre_family"] = event.genre_family
        relative_rows.extend(rel.to_dict("records"))

        treated_pre_starts = summarize_period(treated_window, [-3, -2, -1], "local_genre_band_starts")
        treated_post_starts = summarize_period(treated_window, [0, 1], "local_genre_band_starts")
        control_pre_starts = summarize_period(control_window, [-3, -2, -1], "local_genre_band_starts")
        control_post_starts = summarize_period(control_window, [0, 1], "local_genre_band_starts")

        treated_pre_spawn = summarize_period(treated_window, [-3, -2, -1], "spawn_bands_formed")
        treated_post_spawn = summarize_period(treated_window, [0, 1], "spawn_bands_formed")
        control_pre_spawn = summarize_period(control_window, [-3, -2, -1], "spawn_bands_formed")
        control_post_spawn = summarize_period(control_window, [0, 1], "spawn_bands_formed")

        comparison_rows.append(
            {
                "treated_member_name": event.member_name,
                "treated_city_country": event.city_country,
                "treated_terminal_year": int(event.terminal_year),
                "genre_family": event.genre_family,
                "matched_controls": "; ".join(control_cities),
                "treated_pre_local_genre_band_starts": treated_pre_starts,
                "treated_post_local_genre_band_starts": treated_post_starts,
                "control_pre_local_genre_band_starts": control_pre_starts,
                "control_post_local_genre_band_starts": control_post_starts,
                "did_local_genre_band_starts": (treated_post_starts - treated_pre_starts)
                - (control_post_starts - control_pre_starts),
                "treated_pre_spawn_bands_formed": treated_pre_spawn,
                "treated_post_spawn_bands_formed": treated_post_spawn,
                "control_pre_spawn_bands_formed": control_pre_spawn,
                "control_post_spawn_bands_formed": control_post_spawn,
                "did_spawn_bands_formed": (treated_post_spawn - treated_pre_spawn)
                - (control_post_spawn - control_pre_spawn),
                "n_controls": len(control_cities),
            }
        )

    matches_df = pd.DataFrame(match_rows).sort_values(
        ["treated_terminal_year", "treated_member_name", "match_rank"]
    )
    matches_df.to_csv(OUT_MATCHES, index=False)

    relative_df = pd.DataFrame(relative_rows).sort_values(
        ["treated_terminal_year", "treated_member_name", "relative_year"]
    )
    relative_df.to_csv(OUT_RELATIVE, index=False)

    comparison_df = pd.DataFrame(comparison_rows).sort_values(
        ["treated_terminal_year", "treated_member_name"]
    )
    comparison_df.to_csv(OUT_EVENT_COMPARISON, index=False)

    pooled_relative = (
        relative_df.groupby("relative_year", as_index=False)
        .agg(
            n_events=("treated_member_name", "nunique"),
            treated_local_genre_band_starts=("treated_local_genre_band_starts", "mean"),
            control_local_genre_band_starts=("control_local_genre_band_starts", "mean"),
            treated_city_spawn_bands_formed=("treated_city_spawn_bands_formed", "mean"),
            control_city_spawn_bands_formed=("control_city_spawn_bands_formed", "mean"),
        )
    )

    lines = [
        "# Central loss matched-control summary",
        "",
        "## Scope",
        "",
        f"- Treated post-emergence events with usable window: `{len(comparison_df):,}`",
        f"- Controls per event target: `{CONTROL_COUNT}`",
        "- This is a descriptive matched-control prototype, not a causal estimate.",
        "",
        "## Pooled relative-year means",
        "",
        "| Relative year | Events | Treated focal band starts | Control focal band starts | Treated city spawning flow | Control city spawning flow |",
        "| --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in pooled_relative.itertuples(index=False):
        lines.append(
            f"| {int(row.relative_year)} | {int(row.n_events)} | "
            f"{format_float(row.treated_local_genre_band_starts)} | "
            f"{format_float(row.control_local_genre_band_starts)} | "
            f"{format_float(row.treated_city_spawn_bands_formed)} | "
            f"{format_float(row.control_city_spawn_bands_formed)} |"
        )

    if not comparison_df.empty:
        mean_did_starts = comparison_df["did_local_genre_band_starts"].mean()
        mean_did_spawn = comparison_df["did_spawn_bands_formed"].mean()
        negative_share_starts = (comparison_df["did_local_genre_band_starts"] < 0).mean()
        negative_share_spawn = (comparison_df["did_spawn_bands_formed"] < 0).mean()
        lines.extend(
            [
                "",
                "## Average matched differences",
                "",
                f"- `Focal genre band starts` average DID-style change: `{format_float(mean_did_starts)}`, share negative = `{format_float(negative_share_starts)}`.",
                f"- `City spawning flow` average DID-style change: `{format_float(mean_did_spawn)}`, share negative = `{format_float(negative_share_spawn)}`.",
                "",
                "## Event-level focal band-start comparison",
                "",
                "| Event | Matched controls | Treated delta | Control delta | DID-style delta |",
                "| --- | --- | ---: | ---: | ---: |",
            ]
        )
        for row in comparison_df.itertuples(index=False):
            event_label = f"{row.treated_member_name} ({row.treated_city_country} x {row.genre_family} x {int(row.treated_terminal_year)})"
            treated_delta = row.treated_post_local_genre_band_starts - row.treated_pre_local_genre_band_starts
            control_delta = row.control_post_local_genre_band_starts - row.control_pre_local_genre_band_starts
            lines.append(
                f"| {event_label} | {row.matched_controls} | {format_float(treated_delta)} | "
                f"{format_float(control_delta)} | {format_float(row.did_local_genre_band_starts)} |"
            )

    OUT_SUMMARY.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_MATCHES}")
    print(f"Wrote {OUT_RELATIVE}")
    print(f"Wrote {OUT_EVENT_COMPARISON}")
    print(f"Wrote {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
