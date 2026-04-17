from __future__ import annotations

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

EVENTS_PATH = SCENE_DIR / "central_loss_verified_death_events.csv"
PANEL_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"

OUT_EVENT_SUMMARY = SCENE_DIR / "central_loss_event_preview.csv"
OUT_WINDOW = SCENE_DIR / "central_loss_event_window_preview.csv"
OUT_SUMMARY_MD = SCENE_DIR / "central_loss_event_preview_summary.md"


def classify_emergence_timing(terminal_year: int, emergence_year: float | int | None) -> str:
    if pd.isna(emergence_year):
        return "no_emergence_record"
    emergence_year = int(emergence_year)
    if terminal_year < emergence_year:
        return "pre_emergence"
    if terminal_year == emergence_year:
        return "emergence_year"
    return "post_emergence"


def main() -> None:
    events = pd.read_csv(EVENTS_PATH, low_memory=False)
    panel = pd.read_csv(PANEL_PATH, low_memory=False)
    emergence = pd.read_csv(EMERGENCE_PATH, low_memory=False)

    emergence = emergence[
        ["city_country", "genre_family", "first_band_year", "emergence_year", "total_bands", "peak_5yr_count"]
    ].copy()
    events = events.merge(emergence, on=["city_country", "genre_family"], how="left")
    events["emergence_timing"] = events.apply(
        lambda row: classify_emergence_timing(row["terminal_year"], row["emergence_year"]),
        axis=1,
    )

    window = panel.merge(
        events[
            [
                "member_name",
                "event_date",
                "terminal_year",
                "city_country",
                "genre_family",
                "emergence_year",
                "emergence_timing",
            ]
        ],
        on=["city_country", "genre_family"],
        how="inner",
    ).copy()
    window["relative_year"] = window["snapshot_year"] - window["terminal_year"]
    window = window.loc[window["relative_year"].between(-5, 3)].copy()

    support = (
        window.groupby(["member_name", "city_country", "genre_family", "terminal_year"], as_index=False)
        .agg(
            pre_years_available=("relative_year", lambda s: int((s < 0).sum())),
            post_years_available=("relative_year", lambda s: int((s > 0).sum())),
            event_year_available=("relative_year", lambda s: int((s == 0).any())),
            min_relative_year=("relative_year", "min"),
            max_relative_year=("relative_year", "max"),
            pre_event_band_stock=("genre_active_bands", lambda s: float(s.loc[window.loc[s.index, "relative_year"] == -1].iloc[0]) if any(window.loc[s.index, "relative_year"] == -1) else float("nan")),
            event_year_band_stock=("genre_active_bands", lambda s: float(s.loc[window.loc[s.index, "relative_year"] == 0].iloc[0]) if any(window.loc[s.index, "relative_year"] == 0) else float("nan")),
        )
    )

    event_summary = events.merge(
        support,
        on=["member_name", "city_country", "genre_family", "terminal_year"],
        how="left",
    )
    event_summary["usable_for_short_post_window"] = (
        event_summary["pre_years_available"].fillna(0).ge(3)
        & event_summary["event_year_available"].fillna(0).eq(1)
        & event_summary["post_years_available"].fillna(0).ge(1)
    ).astype(int)

    window.to_csv(OUT_WINDOW, index=False)
    event_summary.to_csv(OUT_EVENT_SUMMARY, index=False)

    lines = [
        "# Central loss event preview summary",
        "",
        "## Counts",
        "",
        f"- Verified death events: `{len(event_summary):,}`",
        f"- Events with `3+` pre years, event year, and `1+` post year in the live panel: `{int(event_summary['usable_for_short_post_window'].sum()):,}`",
        "",
        "## Emergence timing read",
        "",
    ]
    timing_counts = event_summary["emergence_timing"].value_counts(dropna=False)
    for key, value in timing_counts.items():
        lines.append(f"- `{key}`: `{int(value)}`")

    lines.extend(
        [
            "",
            "## Event table",
            "",
            "| Musician | Terminal year | City-country | Genre | Emergence timing | Emergence year | Pre years | Post years | Usable short post window |",
            "| --- | ---: | --- | --- | --- | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in event_summary.itertuples(index=False):
        emergence_year = "" if pd.isna(row.emergence_year) else int(row.emergence_year)
        pre_years = "" if pd.isna(row.pre_years_available) else int(row.pre_years_available)
        post_years = "" if pd.isna(row.post_years_available) else int(row.post_years_available)
        lines.append(
            f"| {row.member_name} | {int(row.terminal_year)} | {row.city_country} | {row.genre_family} | {row.emergence_timing} | {emergence_year} | {pre_years} | {post_years} | {int(row.usable_for_short_post_window)} |"
        )

    OUT_SUMMARY_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_EVENT_SUMMARY}")
    print(f"Wrote {OUT_WINDOW}")
    print(f"Wrote {OUT_SUMMARY_MD}")


if __name__ == "__main__":
    main()
