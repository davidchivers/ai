from __future__ import annotations

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

EVENTS_PATH = SCENE_DIR / "central_loss_verified_death_events.csv"
GENRE_PANEL_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
CITY_PANEL_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"

OUT_WINDOW = SCENE_DIR / "central_loss_post_emergence_event_window.csv"
OUT_RELATIVE = SCENE_DIR / "central_loss_post_emergence_relative_year_summary.csv"
OUT_SUMMARY_MD = SCENE_DIR / "central_loss_post_emergence_summary.md"


def classify_emergence_timing(terminal_year: int, emergence_year: float | int | None) -> str:
    if pd.isna(emergence_year):
        return "no_emergence_record"
    emergence_year = int(emergence_year)
    if terminal_year < emergence_year:
        return "pre_emergence"
    if terminal_year == emergence_year:
        return "emergence_year"
    return "post_emergence"


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
    genre_panel = pd.read_csv(GENRE_PANEL_PATH, low_memory=False)
    city_panel = pd.read_csv(CITY_PANEL_PATH, low_memory=False)
    emergence = pd.read_csv(EMERGENCE_PATH, low_memory=False)[
        ["city_country", "genre_family", "emergence_year"]
    ].copy()

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

    event_support = (
        support.groupby(["member_name", "city_country", "genre_family", "terminal_year"], as_index=False)
        .agg(
            pre_years_available=("relative_year", lambda s: int((s < 0).sum())),
            post_years_available=("relative_year", lambda s: int((s > 0).sum())),
            event_year_available=("relative_year", lambda s: int((s == 0).any())),
        )
    )

    events = events.merge(
        event_support,
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

    city_merge = city_panel.rename(columns={"snapshot_year": "calendar_year"}).copy()
    window = window.merge(
        city_merge,
        left_on=["city_country", "snapshot_year"],
        right_on=["city_country", "calendar_year"],
        how="left",
        suffixes=("", "_city"),
    )

    keep_cols = [
        "member_name",
        "event_date",
        "terminal_year",
        "city_country",
        "genre_family",
        "snapshot_year",
        "relative_year",
        "genre_active_bands",
        "genre_multi_band_musicians",
        "genre_active_musicians",
        "n_active_bands",
        "bands_formed",
        "spawn_bands_formed",
        "spawn_share_formed",
        "founder_pedigree_mean",
        "n_multi_band_musicians_total",
    ]
    window = window[keep_cols].sort_values(
        ["member_name", "terminal_year", "relative_year"]
    )
    window.to_csv(OUT_WINDOW, index=False)

    relative = (
        window.groupby("relative_year", as_index=False)
        .agg(
            n_event_rows=("member_name", "count"),
            n_unique_events=("member_name", "nunique"),
            mean_genre_active_bands=("genre_active_bands", "mean"),
            mean_genre_multi_band_musicians=("genre_multi_band_musicians", "mean"),
            mean_genre_active_musicians=("genre_active_musicians", "mean"),
            mean_city_active_bands=("n_active_bands", "mean"),
            mean_city_band_starts=("bands_formed", "mean"),
            mean_city_spawn_bands_formed=("spawn_bands_formed", "mean"),
            mean_city_spawn_share=("spawn_share_formed", "mean"),
            mean_city_founder_pedigree=("founder_pedigree_mean", "mean"),
            mean_city_multi_band_musicians=("n_multi_band_musicians_total", "mean"),
        )
    )
    relative.to_csv(OUT_RELATIVE, index=False)

    metrics = {
        "genre_active_bands": "Focal active bands",
        "genre_multi_band_musicians": "Focal multi-band musicians",
        "bands_formed": "City total band starts",
        "spawn_bands_formed": "City spawning flow",
        "spawn_share_formed": "City spawning share",
    }

    lines = [
        "# Central loss post-emergence summary",
        "",
        "## Scope",
        "",
        f"- Verified death events in clean file: `{len(events):,}`",
        f"- Post-emergence deaths with a usable short post window: `{len(analysis_events):,}`",
        "- This summary is descriptive only and uses the subset with at least `3` pre years, the event year, and at least `1` post year.",
        "",
        "## Included events",
        "",
    ]
    for row in analysis_events.sort_values(["terminal_year", "member_name"]).itertuples(index=False):
        lines.append(
            f"- `{row.member_name}` in `{row.city_country} x {row.genre_family} x {int(row.terminal_year)}`"
        )

    lines.extend(
        [
            "",
            "## Relative-year means",
            "",
            "| Relative year | Events | Focal active bands | Focal multi-band musicians | City band starts | City spawning flow | City spawning share |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in relative.itertuples(index=False):
        lines.append(
            f"| {int(row.relative_year)} | {int(row.n_unique_events)} | "
            f"{format_float(row.mean_genre_active_bands)} | "
            f"{format_float(row.mean_genre_multi_band_musicians)} | "
            f"{format_float(row.mean_city_band_starts)} | "
            f"{format_float(row.mean_city_spawn_bands_formed)} | "
            f"{format_float(row.mean_city_spawn_share)} |"
        )

    lines.extend(["", "## Pre versus post averages", ""])
    for column, label in metrics.items():
        pre_mean = summarize_period(window, [-3, -2, -1], column)
        post_mean = summarize_period(window, [0, 1], column)
        delta = post_mean - pre_mean if not (pd.isna(pre_mean) or pd.isna(post_mean)) else float("nan")
        lines.append(
            f"- `{label}`: pre `[-3,-1] = {format_float(pre_mean)}`, post `[0,+1] = {format_float(post_mean)}`, delta = `{format_float(delta)}`."
        )

    OUT_SUMMARY_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_WINDOW}")
    print(f"Wrote {OUT_RELATIVE}")
    print(f"Wrote {OUT_SUMMARY_MD}")


if __name__ == "__main__":
    main()
