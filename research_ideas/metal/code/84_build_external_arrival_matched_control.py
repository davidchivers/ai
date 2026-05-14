from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
SCENE_DIR = PROCESSED_DIR / "scene_networks"

BAND_PATH = PROCESSED_DIR / "metal_archives_all_metal_band_clean.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
EVENTS_PATH = SCENE_DIR / "external_arrival_events.csv"

OUT_MATCHES = SCENE_DIR / "external_arrival_matched_controls.csv"
OUT_COMPARISON = SCENE_DIR / "external_arrival_matched_event_comparison.csv"
OUT_SUMMARY = SCENE_DIR / "external_arrival_matched_control_summary.md"

ARRIVAL_DEFINITION = "cross_country_same_genre"
CONTROL_COUNT = 5
WINDOW_EXCLUSION_RADIUS = 3

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


def normalize_text(value: object) -> str:
    if pd.isna(value):
        return ""
    return str(value).strip()


def extract_city(notes_str: object) -> str:
    text = normalize_text(notes_str)
    if "location=" not in text:
        return ""
    return text.split("location=", 1)[1].split(";", 1)[0].split(",", 1)[0].strip()


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
        .rename(columns={"formed_year": "year", "size": "starts"})
    )
    return starts


def build_start_lookup(starts: pd.DataFrame) -> dict[tuple[str, str], dict[int, float]]:
    lookup: dict[tuple[str, str], dict[int, float]] = {}
    for (city_country, genre_family), group in starts.groupby(["city_country", "genre_family"]):
        lookup[(city_country, genre_family)] = dict(zip(group["year"].astype(int), group["starts"].astype(float)))
    return lookup


def build_cumulative_lookup(starts: pd.DataFrame) -> dict[tuple[str, str], tuple[np.ndarray, np.ndarray]]:
    lookup: dict[tuple[str, str], tuple[np.ndarray, np.ndarray]] = {}
    starts = starts.sort_values(["city_country", "genre_family", "year"]).copy()
    for key, group in starts.groupby(["city_country", "genre_family"], sort=False):
        years = group["year"].to_numpy(dtype=int)
        cumsum = group["starts"].cumsum().to_numpy(dtype=int)
        lookup[key] = (years, cumsum)
    return lookup


def starts_for_years(
    lookup: dict[tuple[str, str], dict[int, float]],
    city_country: str,
    genre_family: str,
    years: list[int],
) -> float:
    year_lookup = lookup.get((city_country, genre_family), {})
    return float(np.mean([year_lookup.get(year, 0.0) for year in years]))


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


def cell_has_near_arrival(
    arrivals_by_cell: dict[tuple[str, str], list[int]],
    city_country: str,
    genre_family: str,
    year: int,
) -> bool:
    years = arrivals_by_cell.get((city_country, genre_family), [])
    return any(abs(arrival_year - year) <= WINDOW_EXCLUSION_RADIUS for arrival_year in years)


def build_matches() -> tuple[pd.DataFrame, pd.DataFrame]:
    events = pd.read_csv(EVENTS_PATH, low_memory=False)
    starts = build_local_starts()
    start_lookup = build_start_lookup(starts)
    cumulative_lookup = build_cumulative_lookup(starts)
    emergence = pd.read_csv(EMERGENCE_PATH, low_memory=False)
    emergence["emergence_year"] = pd.to_numeric(emergence["emergence_year"], errors="coerce")

    treated = events.loc[
        events["arrival_definition"].eq(ARRIVAL_DEFINITION)
        & events["analysis_sample_i"].eq(1)
    ].copy()

    same_definition_events = events.loc[events["arrival_definition"].eq(ARRIVAL_DEFINITION)].copy()
    arrivals_by_cell = (
        same_definition_events.groupby(["city_country", "genre_family"])["arrival_year"]
        .apply(lambda s: sorted(pd.to_numeric(s, errors="coerce").dropna().astype(int).tolist()))
        .to_dict()
    )

    candidate_cells = emergence.loc[
        emergence["city_country"].notna()
        & emergence["genre_family"].notna()
        & emergence["country"].notna()
    ].copy()

    match_rows: list[dict[str, object]] = []
    comparison_rows: list[dict[str, object]] = []

    for event in treated.itertuples(index=False):
        event_year = int(event.arrival_year)
        pre_years = [event_year - 3, event_year - 2, event_year - 1]
        post_years = [event_year + 1, event_year + 2, event_year + 3]
        treated_pre = starts_for_years(start_lookup, event.city_country, event.genre_family, pre_years)
        treated_post = starts_for_years(start_lookup, event.city_country, event.genre_family, post_years)
        treated_prior = int(event.prior_cumulative_bands)

        pool = candidate_cells.loc[
            candidate_cells["genre_family"].eq(event.genre_family)
            & candidate_cells["country"].eq(event.country)
            & candidate_cells["city_country"].ne(event.city_country)
        ].copy()
        candidates: list[dict[str, object]] = []
        for candidate in pool.itertuples(index=False):
            emergence_year = getattr(candidate, "emergence_year")
            if pd.isna(emergence_year) or event_year >= int(emergence_year):
                continue
            prior = cumulative_before(cumulative_lookup, candidate.city_country, event.genre_family, event_year)
            if prior < 1 or prior > 4:
                continue
            if cell_has_near_arrival(arrivals_by_cell, candidate.city_country, event.genre_family, event_year):
                continue
            pre = starts_for_years(start_lookup, candidate.city_country, event.genre_family, pre_years)
            post = starts_for_years(start_lookup, candidate.city_country, event.genre_family, post_years)
            distance = abs(prior - treated_prior) + abs(pre - treated_pre)
            candidates.append(
                {
                    "control_city_country": candidate.city_country,
                    "control_emergence_year": emergence_year,
                    "control_prior_cumulative_bands": prior,
                    "control_pre_starts": pre,
                    "control_post_p1_p3_starts": post,
                    "match_distance": distance,
                }
            )
        if not candidates:
            continue

        chosen = (
            pd.DataFrame(candidates)
            .sort_values(["match_distance", "control_city_country"])
            .head(CONTROL_COUNT)
            .reset_index(drop=True)
        )
        stack_id = str(event.event_id)
        for rank, row in enumerate(chosen.itertuples(index=False), start=1):
            match_rows.append(
                {
                    "stack_id": stack_id,
                    "arrival_definition": ARRIVAL_DEFINITION,
                    "treated_city_country": event.city_country,
                    "treated_country": event.country,
                    "genre_family": event.genre_family,
                    "arrival_year": event_year,
                    "match_rank": rank,
                    **row._asdict(),
                }
            )
        control_pre = float(chosen["control_pre_starts"].mean())
        control_post = float(chosen["control_post_p1_p3_starts"].mean())
        comparison_rows.append(
            {
                "stack_id": stack_id,
                "treated_city_country": event.city_country,
                "treated_country": event.country,
                "genre_family": event.genre_family,
                "arrival_year": event_year,
                "treated_prior_cumulative_bands": treated_prior,
                "treated_pre_starts": treated_pre,
                "treated_post_p1_p3_starts": treated_post,
                "treated_change": treated_post - treated_pre,
                "control_count": int(len(chosen)),
                "control_pre_starts": control_pre,
                "control_post_p1_p3_starts": control_post,
                "control_change": control_post - control_pre,
                "did_change": (treated_post - treated_pre) - (control_post - control_pre),
                "mean_match_distance": float(chosen["match_distance"].mean()),
            }
        )

    return pd.DataFrame(match_rows), pd.DataFrame(comparison_rows)


def fmt(value: float, digits: int = 3) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def write_summary(matches: pd.DataFrame, comparisons: pd.DataFrame) -> None:
    with OUT_SUMMARY.open("w", encoding="utf-8") as handle:
        handle.write("# External arrival matched-control prototype\n\n")
        handle.write(
            "This prototype focuses on the strict `cross_country_same_genre` arrival definition. "
            "Each treated `city x genre` event is matched to up to five same-country, same-genre "
            "control cells in the same calendar year, with `1-4` prior cumulative bands and no "
            "nearby strict arrival event. Matching uses prior cumulative bands and mean local starts "
            "over `t-3` to `t-1`.\n\n"
        )
        if comparisons.empty:
            handle.write("No matched events were recovered.\n")
            return
        handle.write("## Counts\n\n")
        handle.write(f"- Treated events with at least one matched control: `{comparisons['stack_id'].nunique()}`\n")
        handle.write(f"- Matched control rows: `{len(matches)}`\n")
        handle.write(f"- Mean controls per treated event: `{len(matches) / comparisons['stack_id'].nunique():.2f}`\n\n")
        handle.write("## Headline matched read\n\n")
        handle.write(
            f"- Treated mean pre starts: `{fmt(comparisons['treated_pre_starts'].mean())}`\n"
        )
        handle.write(
            f"- Treated mean post `+1` to `+3` starts: `{fmt(comparisons['treated_post_p1_p3_starts'].mean())}`\n"
        )
        handle.write(
            f"- Treated mean change: `{fmt(comparisons['treated_change'].mean())}`\n"
        )
        handle.write(
            f"- Control mean pre starts: `{fmt(comparisons['control_pre_starts'].mean())}`\n"
        )
        handle.write(
            f"- Control mean post `+1` to `+3` starts: `{fmt(comparisons['control_post_p1_p3_starts'].mean())}`\n"
        )
        handle.write(
            f"- Control mean change: `{fmt(comparisons['control_change'].mean())}`\n"
        )
        handle.write(
            f"- Mean DID-style change: `{fmt(comparisons['did_change'].mean())}`\n"
        )
        handle.write(
            f"- Share of event-level DID changes above zero: `{fmt((comparisons['did_change'] > 0).mean())}`\n\n"
        )
        handle.write("## Current read\n\n")
        handle.write(
            "- This is still a descriptive matched-control screen, not a finished causal design. "
            "It helps separate post-arrival growth from the general behavior of same-country, "
            "same-genre cells that were also below the threshold.\n"
        )
        handle.write(
            "- The next robustness check should remove the arriving musician's own band from the "
            "treated event-year and post-year entry counts where possible.\n"
        )


def main() -> None:
    print("Building strict external-arrival matched controls...")
    matches, comparisons = build_matches()
    matches.to_csv(OUT_MATCHES, index=False)
    comparisons.to_csv(OUT_COMPARISON, index=False)
    write_summary(matches, comparisons)
    print(f"Matched treated events: {comparisons['stack_id'].nunique() if not comparisons.empty else 0}")
    print(f"Wrote summary to {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
