from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
SCENE_DIR = PROCESSED_DIR / "scene_networks"

BAND_PATH = PROCESSED_DIR / "metal_archives_all_metal_band_clean.csv"
EVENTS_PATH = SCENE_DIR / "external_arrival_events.csv"
MATCHES_PATH = SCENE_DIR / "external_arrival_matched_controls.csv"

OUT_WINDOWS = SCENE_DIR / "external_arrival_final_audit_event_windows.csv"
OUT_EVENT_STUDY = SCENE_DIR / "external_arrival_final_audit_event_study.csv"
OUT_SUMMARY = SCENE_DIR / "external_arrival_final_audit_summary.md"

ARRIVAL_DEFINITION = "cross_country_same_genre"
WINDOW = list(range(-5, 6))
BASELINE_RELATIVE_YEAR = -1

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


def normalize_id(value: object) -> str:
    text = normalize_text(value)
    if text.endswith(".0") and text[:-2].isdigit():
        return text[:-2]
    return text


def parse_id_set(value: object) -> frozenset[str]:
    text = normalize_text(value)
    if not text:
        return frozenset()
    return frozenset(normalize_id(token) for token in text.split("|") if normalize_id(token))


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


def require_inputs() -> None:
    missing = [path for path in [BAND_PATH, EVENTS_PATH, MATCHES_PATH] if not path.exists()]
    if missing:
        relative = "\n".join(f"- {path.relative_to(PROJECT_ROOT)}" for path in missing)
        raise FileNotFoundError(
            "External-arrival final audit cannot run until these inputs exist:\n"
            f"{relative}\n\n"
            "Restore the D-drive processed data or rerun code/83 and code/84 first."
        )


def find_band_id_column(columns: pd.Index) -> str:
    for candidate in ["band_id", "source_id_primary", "id", "ma_id"]:
        if candidate in columns:
            return candidate
    raise KeyError("Could not find a band id column in the cleaned band file.")


def build_band_starts() -> pd.DataFrame:
    bands = pd.read_csv(BAND_PATH, low_memory=False)
    band_id_column = find_band_id_column(bands.columns)
    for column in ["notes", "country_std", "formed_year", "genre_raw"]:
        if column not in bands.columns:
            raise KeyError(f"Missing required band column: {column}")

    bands["band_id_str"] = bands[band_id_column].map(normalize_id)
    bands["city"] = bands["notes"].map(extract_city)
    bands["formed_year"] = pd.to_numeric(bands["formed_year"], errors="coerce")
    bands = bands.loc[
        bands["formed_year"].notna()
        & bands["band_id_str"].ne("")
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
    return expanded[
        ["band_id_str", "city_country", "genre_family", "formed_year"]
    ].drop_duplicates()


def band_start_count(
    starts: pd.DataFrame,
    *,
    city_country: str,
    genre_family: str,
    year: int,
    exclude_band_ids: frozenset[str] = frozenset(),
) -> tuple[float, int]:
    frame = starts.loc[
        starts["city_country"].eq(city_country)
        & starts["genre_family"].eq(genre_family)
        & starts["formed_year"].eq(year)
    ]
    if frame.empty:
        return 0.0, 0
    if not exclude_band_ids:
        return float(len(frame)), 0
    kept = frame.loc[~frame["band_id_str"].isin(exclude_band_ids)]
    return float(len(kept)), int(len(frame) - len(kept))


def build_event_windows(
    events: pd.DataFrame,
    matches: pd.DataFrame,
    starts: pd.DataFrame,
) -> pd.DataFrame:
    if "arriving_band_ids" not in events.columns:
        raise KeyError(
            "external_arrival_events.csv does not contain arriving_band_ids. "
            "Rerun code/83_build_external_arrival_event_study.py after the latest patch."
        )

    treated = events.loc[
        events["arrival_definition"].eq(ARRIVAL_DEFINITION)
        & events["analysis_sample_i"].eq(1)
    ].copy()
    treated["arrival_band_id_set"] = treated["arriving_band_ids"].map(parse_id_set)
    event_lookup = treated.set_index("event_id").to_dict("index")

    rows: list[dict[str, object]] = []
    for stack_id, group in matches.groupby("stack_id", sort=False):
        event = event_lookup.get(stack_id)
        if event is None:
            continue
        arrival_year = int(event["arrival_year"])
        genre_family = normalize_text(event["genre_family"])
        exclude_ids = event["arrival_band_id_set"]

        for relative_year in WINDOW:
            year = arrival_year + relative_year
            treated_raw, _ = band_start_count(
                starts,
                city_country=normalize_text(event["city_country"]),
                genre_family=genre_family,
                year=year,
            )
            treated_clean, treated_excluded = band_start_count(
                starts,
                city_country=normalize_text(event["city_country"]),
                genre_family=genre_family,
                year=year,
                exclude_band_ids=exclude_ids,
            )
            rows.append(
                {
                    "stack_id": stack_id,
                    "group": "treated",
                    "city_country": normalize_text(event["city_country"]),
                    "genre_family": genre_family,
                    "arrival_year": arrival_year,
                    "relative_year": relative_year,
                    "snapshot_year": year,
                    "local_genre_band_starts_raw": treated_raw,
                    "local_genre_band_starts_own_band_excluded": treated_clean,
                    "own_bands_excluded": treated_excluded,
                    "control_weight": np.nan,
                }
            )

        control_count = len(group)
        for match in group.itertuples(index=False):
            for relative_year in WINDOW:
                year = arrival_year + relative_year
                control_starts, _ = band_start_count(
                    starts,
                    city_country=normalize_text(match.control_city_country),
                    genre_family=genre_family,
                    year=year,
                )
                rows.append(
                    {
                        "stack_id": stack_id,
                        "group": "control",
                        "city_country": normalize_text(match.control_city_country),
                        "genre_family": genre_family,
                        "arrival_year": arrival_year,
                        "relative_year": relative_year,
                        "snapshot_year": year,
                        "local_genre_band_starts_raw": control_starts,
                        "local_genre_band_starts_own_band_excluded": control_starts,
                        "own_bands_excluded": 0,
                        "control_weight": 1.0 / control_count if control_count else np.nan,
                    }
                )
    return pd.DataFrame(rows)


def build_matched_event_study(windows: pd.DataFrame) -> pd.DataFrame:
    treated = windows.loc[windows["group"].eq("treated")].copy()
    controls = windows.loc[windows["group"].eq("control")].copy()
    control_means = (
        controls.groupby(["stack_id", "relative_year"], as_index=False)
        .agg(
            control_starts=(
                "local_genre_band_starts_own_band_excluded",
                "mean",
            )
        )
    )
    paired = treated.merge(control_means, on=["stack_id", "relative_year"], how="inner")
    paired["treated_starts"] = paired["local_genre_band_starts_own_band_excluded"]
    paired["treated_minus_control"] = paired["treated_starts"] - paired["control_starts"]
    baseline = paired.loc[
        paired["relative_year"].eq(BASELINE_RELATIVE_YEAR),
        ["stack_id", "treated_minus_control"],
    ].rename(columns={"treated_minus_control": "baseline_treated_minus_control"})
    paired = paired.merge(baseline, on="stack_id", how="inner")
    paired["normalized_did"] = (
        paired["treated_minus_control"] - paired["baseline_treated_minus_control"]
    )

    return (
        paired.groupby("relative_year", as_index=False)
        .agg(
            events=("stack_id", "nunique"),
            mean_treated_starts=("treated_starts", "mean"),
            mean_control_starts=("control_starts", "mean"),
            mean_treated_minus_control=("treated_minus_control", "mean"),
            mean_normalized_did=("normalized_did", "mean"),
            sd_normalized_did=("normalized_did", "std"),
            share_positive_normalized_did=("normalized_did", lambda s: float((s > 0).mean())),
        )
        .assign(
            se_normalized_did=lambda df: df["sd_normalized_did"] / np.sqrt(df["events"]),
        )
    )


def fmt(value: float, digits: int = 3) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def write_summary(windows: pd.DataFrame, event_study: pd.DataFrame) -> None:
    treated = windows.loc[windows["group"].eq("treated")].copy()
    excluded_by_year = (
        treated.groupby("relative_year", as_index=False)["own_bands_excluded"].sum()
        if not treated.empty
        else pd.DataFrame(columns=["relative_year", "own_bands_excluded"])
    )
    excluded_map = {
        int(row.relative_year): int(row.own_bands_excluded)
        for row in excluded_by_year.itertuples(index=False)
    }

    post = event_study.loc[event_study["relative_year"].between(1, 3)]
    pre = event_study.loc[event_study["relative_year"].between(-5, -2)]
    event_year = event_study.loc[event_study["relative_year"].eq(0)]

    with OUT_SUMMARY.open("w", encoding="utf-8") as handle:
        handle.write("# External arrival final audit\n\n")
        handle.write(
            "This audit focuses on strict `cross_country_same_genre` arrivals. It rebuilds "
            "band-level local starts, excludes the arriving musician's own band from treated "
            "outcomes where the band ID is observed, and compares treated cells to the existing "
            "matched controls in event time with `t-1` as the baseline.\n\n"
        )
        handle.write("## Inputs\n\n")
        handle.write(f"- events: `{EVENTS_PATH.relative_to(PROJECT_ROOT)}`\n")
        handle.write(f"- matches: `{MATCHES_PATH.relative_to(PROJECT_ROOT)}`\n")
        handle.write(f"- bands: `{BAND_PATH.relative_to(PROJECT_ROOT)}`\n\n")
        handle.write("## Counts\n\n")
        handle.write(f"- matched treated stacks: `{treated['stack_id'].nunique()}`\n")
        handle.write(f"- event-window rows: `{len(windows)}`\n")
        handle.write(
            f"- arrival-associated bands removed at event year: `{excluded_map.get(0, 0)}`\n"
        )
        handle.write(
            f"- arrival-associated bands removed in years `+1` to `+3`: "
            f"`{sum(excluded_map.get(year, 0) for year in [1, 2, 3])}`\n\n"
        )
        handle.write("## Matched event-study read\n\n")
        handle.write(
            "| Relative year | Events | Treated starts | Control starts | Treated-control | Normalized DID | SE | Share positive |\n"
        )
        handle.write("|---:|---:|---:|---:|---:|---:|---:|---:|\n")
        for row in event_study.itertuples(index=False):
            handle.write(
                f"| {int(row.relative_year)} | {int(row.events)} | "
                f"{fmt(row.mean_treated_starts)} | {fmt(row.mean_control_starts)} | "
                f"{fmt(row.mean_treated_minus_control)} | {fmt(row.mean_normalized_did)} | "
                f"{fmt(row.se_normalized_did)} | {fmt(row.share_positive_normalized_did)} |\n"
            )
        handle.write("\n## Compact verdict fields\n\n")
        handle.write(
            f"- Mean normalized pre coefficient, `t=-5` to `t=-2`: "
            f"`{fmt(pre['mean_normalized_did'].mean() if not pre.empty else np.nan)}`\n"
        )
        handle.write(
            f"- Event-year normalized coefficient, `t=0`: "
            f"`{fmt(event_year['mean_normalized_did'].iloc[0] if not event_year.empty else np.nan)}`\n"
        )
        handle.write(
            f"- Mean normalized post coefficient, `t=+1` to `t=+3`: "
            f"`{fmt(post['mean_normalized_did'].mean() if not post.empty else np.nan)}`\n\n"
        )
        handle.write(
            "Promotion rule: this branch should not enter the stabilized main paper unless the "
            "own-band-excluded post effect is positive, the pre-period event-study path is not "
            "already rising, and the result is not concentrated in a few countries or genres.\n"
        )


def main() -> None:
    require_inputs()
    print("Loading strict arrival events, matched controls, and band starts...")
    events = pd.read_csv(EVENTS_PATH, low_memory=False)
    matches = pd.read_csv(MATCHES_PATH, low_memory=False)
    starts = build_band_starts()

    print("Building own-band-excluded event windows...")
    windows = build_event_windows(events, matches, starts)
    windows.to_csv(OUT_WINDOWS, index=False)

    print("Building matched event-study summary...")
    event_study = build_matched_event_study(windows)
    event_study.to_csv(OUT_EVENT_STUDY, index=False)
    write_summary(windows, event_study)
    print(f"Wrote summary to {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
