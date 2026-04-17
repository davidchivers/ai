from __future__ import annotations

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
PROCESSED_DIR = DATA_DIR / "processed"
COUNTRY_GENRE_DIR = PROCESSED_DIR / "country_genre_analysis"
SCENE_DIR = PROCESSED_DIR / "scene_networks"

SEED_PATH = DATA_DIR / "blockbuster_album_seed.csv"
CORE_PATH = PROCESSED_DIR / "blockbuster_album_country_hits_core.csv"
SOURCE_MATRIX_PATH = DATA_DIR / "source_matrix.csv"
RELAXED_EVENT_PATH = COUNTRY_GENRE_DIR / "breakout_event_file_peak20_relaxed.csv"
GENRE_PANEL_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"

OUTPUT_TARGETS_PATH = COUNTRY_GENRE_DIR / "breakout_seed_recovery_targets.csv"
OUTPUT_SUMMARY_PATH = COUNTRY_GENRE_DIR / "breakout_seed_recovery_targets.md"


def load_home_seed_status(valid_genres: set[str]) -> pd.DataFrame:
    seed = pd.read_csv(SEED_PATH)
    core = pd.read_csv(CORE_PATH)

    seed_live = seed.loc[seed["primary_genre"].isin(valid_genres) & seed["primary_genre"].ne("heavy_metal")].copy()
    core_home = core.loc[core["market_code"].eq(core["artist_countryiso3code"])].copy()

    home_counts = core_home.groupby("seed_album_id", as_index=False).agg(
        home_chart_rows=("entry_date", lambda values: int(values.notna().sum())),
        home_top10_rows=("top10_flag", lambda values: int(values.fillna(0).eq(1).sum())),
        home_best_peak=(
            "peak_position",
            lambda values: min(pd.to_numeric(values, errors="coerce").dropna())
            if pd.to_numeric(values, errors="coerce").notna().any()
            else pd.NA,
        ),
    )

    return seed_live.merge(home_counts, on="seed_album_id", how="left")


def build_provisional_capability(seed_status: pd.DataFrame) -> pd.DataFrame:
    genre = pd.read_csv(GENRE_PANEL_PATH)
    emergence = pd.read_csv(EMERGENCE_PATH, usecols=["city_country", "country", "genre_family"])
    city_lookup = emergence[["city_country", "country"]].drop_duplicates()

    genre["snapshot_year"] = pd.to_numeric(genre["snapshot_year"], errors="coerce").astype(int)

    rows: list[dict[str, object]] = []
    for row in seed_status.itertuples(index=False):
        provisional_year = int(row.release_year)
        home_country = str(row.artist_country_name)
        genre_family = str(row.primary_genre)

        country_cities = set(city_lookup.loc[city_lookup["country"].eq(home_country), "city_country"])
        subset = genre.loc[
            genre["city_country"].isin(country_cities)
            & genre["genre_family"].eq(genre_family)
            & genre["snapshot_year"].eq(provisional_year - 1)
        ].copy()

        if subset.empty:
            positive_city_count = 0
            max_score = 0.0
            mean_score = 0.0
        else:
            score = pd.to_numeric(subset["genre_active_bands"], errors="coerce").fillna(0) + pd.to_numeric(
                subset["genre_multi_band_musicians"], errors="coerce"
            ).fillna(0)
            positive_city_count = int((score > 0).sum())
            max_score = float(score.max()) if len(score) else 0.0
            mean_score = float(score.mean()) if len(score) else 0.0

        rows.append(
            {
                "seed_album_id": row.seed_album_id,
                "provisional_event_year": provisional_year,
                "provisional_positive_capability_cities": positive_city_count,
                "provisional_max_score": max_score,
                "provisional_mean_score": mean_score,
            }
        )

    return pd.DataFrame(rows)


def load_current_first_breakouts() -> pd.DataFrame:
    relaxed = pd.read_csv(RELAXED_EVENT_PATH)
    relaxed = relaxed.rename(
        columns={
            "market_code": "home_market_code",
            "primary_genre": "primary_genre",
            "event_year": "current_retained_event_year",
            "artist_name": "current_retained_artist_name",
            "album_title": "current_retained_album_title",
        }
    )
    relaxed = relaxed.sort_values(["home_market_code", "primary_genre", "current_retained_event_year"]).drop_duplicates(
        ["home_market_code", "primary_genre"], keep="first"
    )
    return relaxed[
        [
            "home_market_code",
            "primary_genre",
            "current_retained_event_year",
            "current_retained_artist_name",
            "current_retained_album_title",
        ]
    ].copy()


def build_targets() -> pd.DataFrame:
    valid_genres = set(pd.read_csv(GENRE_PANEL_PATH, usecols=["genre_family"])["genre_family"].dropna().astype(str).unique())
    seed_status = load_home_seed_status(valid_genres)
    capability = build_provisional_capability(seed_status)
    current_first = load_current_first_breakouts()
    source_matrix = pd.read_csv(SOURCE_MATRIX_PATH)[["market_code", "source_type", "source_name", "automation_difficulty", "status_note"]]

    targets = seed_status.merge(capability, on="seed_album_id", how="left")
    targets = targets.rename(columns={"artist_countryiso3code": "home_market_code"})
    targets = targets.merge(current_first, on=["home_market_code", "primary_genre"], how="left")
    targets = targets.merge(source_matrix, left_on="home_market_code", right_on="market_code", how="left")

    targets["home_chart_rows"] = targets["home_chart_rows"].fillna(0).astype(int)
    targets["home_top10_rows"] = targets["home_top10_rows"].fillna(0).astype(int)
    targets["missing_exact_home_chart_i"] = targets["home_chart_rows"].eq(0).astype(int)
    targets["missing_home_top10_i"] = targets["home_top10_rows"].eq(0).astype(int)
    targets["would_add_new_market_genre_i"] = targets["current_retained_event_year"].isna().astype(int)
    targets["would_move_first_breakout_earlier_i"] = (
        targets["current_retained_event_year"].notna()
        & targets["provisional_event_year"].lt(targets["current_retained_event_year"])
    ).astype(int)
    targets["would_change_relaxed_first_breakout_i"] = (
        targets["would_add_new_market_genre_i"].eq(1) | targets["would_move_first_breakout_earlier_i"].eq(1)
    ).astype(int)

    targets["priority_bucket"] = "low"
    targets.loc[
        targets["would_change_relaxed_first_breakout_i"].eq(1)
        & targets["provisional_positive_capability_cities"].ge(25),
        "priority_bucket",
    ] = "high"
    targets.loc[
        targets["would_change_relaxed_first_breakout_i"].eq(1)
        & targets["provisional_positive_capability_cities"].between(10, 24),
        "priority_bucket",
    ] = "medium"
    targets.loc[
        targets["would_change_relaxed_first_breakout_i"].eq(1)
        & targets["provisional_positive_capability_cities"].between(3, 9),
        "priority_bucket",
    ] = "watch"

    targets["target_reason"] = "Does not currently improve the relaxed first-breakout set."
    targets.loc[
        targets["would_add_new_market_genre_i"].eq(1),
        "target_reason",
    ] = "Could add a new home-market first breakout in a live scene family."
    targets.loc[
        targets["would_move_first_breakout_earlier_i"].eq(1),
        "target_reason",
    ] = "Could replace the current relaxed first breakout with an earlier home-market event."

    targets = targets.sort_values(
        [
            "priority_bucket",
            "would_change_relaxed_first_breakout_i",
            "provisional_positive_capability_cities",
            "release_year",
            "artist_name",
        ],
        ascending=[True, False, False, True, True],
    ).reset_index(drop=True)
    return targets


def write_summary(targets: pd.DataFrame) -> None:
    shortlist = targets.loc[
        targets["priority_bucket"].isin(["high", "medium", "watch"])
        & targets["would_change_relaxed_first_breakout_i"].eq(1)
    ].copy()
    active_targets = shortlist.loc[shortlist["priority_bucket"].isin(["high", "medium"])].copy()

    lines: list[str] = []
    lines.append("# Breakout seed recovery targets")
    lines.append("")
    lines.append("- Purpose: identify missing or weakly recovered home-market seed albums that could materially change the relaxed first-breakout branch.")
    lines.append("- Comparison baseline: `breakout_event_file_peak20_relaxed.csv`.")
    lines.append("")
    lines.append("## High-priority targets")
    lines.append("")
    high = shortlist.loc[shortlist["priority_bucket"].eq("high")]
    if high.empty:
        lines.append("None.")
    else:
        for row in high.itertuples(index=False):
            lines.append(
                f"- `{row.artist_name} - {row.album_title}` (`{row.home_market_code}`, `{row.primary_genre}`, `{int(row.release_year)}`): "
                f"`provisional_positive_capability_cities={int(row.provisional_positive_capability_cities)}`; "
                f"{row.target_reason} Current source path: `{row.source_name}` (`{row.automation_difficulty}` difficulty)."
            )

    lines.append("")
    lines.append("## Medium-priority targets")
    lines.append("")
    medium = shortlist.loc[shortlist["priority_bucket"].eq("medium")]
    if medium.empty:
        lines.append("None.")
    else:
        for row in medium.itertuples(index=False):
            lines.append(
                f"- `{row.artist_name} - {row.album_title}` (`{row.home_market_code}`, `{row.primary_genre}`, `{int(row.release_year)}`): "
                f"`provisional_positive_capability_cities={int(row.provisional_positive_capability_cities)}`; "
                f"{row.target_reason}"
            )

    lines.append("")
    lines.append("## Watch list")
    lines.append("")
    watch = shortlist.loc[shortlist["priority_bucket"].eq("watch")]
    if watch.empty:
        lines.append("None.")
    else:
        for row in watch.itertuples(index=False):
            lines.append(
                f"- `{row.artist_name} - {row.album_title}` (`{row.home_market_code}`, `{row.primary_genre}`, `{int(row.release_year)}`): "
                f"`provisional_positive_capability_cities={int(row.provisional_positive_capability_cities)}`; "
                f"{row.target_reason}"
            )

    lines.append("")
    lines.append("## Main read")
    lines.append("")
    if active_targets.empty:
        lines.append("- No live recovery targets remain under the current shortlist rule.")
    else:
        market_names = list(dict.fromkeys(active_targets["artist_country_name"].tolist()))
        if len(market_names) == 1:
            market_text = market_names[0]
        elif len(market_names) == 2:
            market_text = " and ".join(market_names)
        else:
            market_text = ", ".join(market_names[:-1]) + f", and {market_names[-1]}"

        lines.append(
            f"- The strongest expansion margin is not another chart cutoff. It is recovering earlier or missing home-market first breakouts in {market_text}."
        )

        cleaner = active_targets.loc[active_targets["automation_difficulty"].isin(["low", "medium"])].copy()
        if cleaner.empty:
            lines.append(
                "- The remaining targets all sit on relatively hard source paths, so any further branch expansion will likely require heavier manual recovery."
            )
        else:
            clean_pairs = list(dict.fromkeys(zip(cleaner["artist_country_name"], cleaner["source_name"])))
            clean_text = ", ".join(f"{country} (`{source}`)" for country, source in clean_pairs)
            if any(active_targets["artist_country_name"].eq("Brazil")) and not any(cleaner["artist_country_name"].eq("Brazil")):
                lines.append(
                    f"- The cleanest current local-source targets are {clean_text}. Brazil still looks substantively promising, but its source path remains the hardest in the current environment."
                )
            else:
                lines.append(
                    f"- The cleanest current local-source targets are {clean_text}."
                )

    OUTPUT_SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    targets = build_targets()
    OUTPUT_TARGETS_PATH.parent.mkdir(parents=True, exist_ok=True)
    targets.to_csv(OUTPUT_TARGETS_PATH, index=False)
    write_summary(targets)

    print(f"Wrote {OUTPUT_TARGETS_PATH}")
    print(f"Wrote {OUTPUT_SUMMARY_PATH}")


if __name__ == "__main__":
    main()
