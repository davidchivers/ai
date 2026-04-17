from __future__ import annotations

import argparse
from importlib.machinery import SourceFileLoader
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
COUNTRY_GENRE_DIR = PROCESSED_DIR / "country_genre_analysis"
SCENE_DIR = PROCESSED_DIR / "scene_networks"

CORE_PATH = PROCESSED_DIR / "blockbuster_album_country_hits_core.csv"
SEED_PATH = PROJECT_ROOT / "data" / "blockbuster_album_seed.csv"

OUTPUT_AUDIT_PATH = COUNTRY_GENRE_DIR / "breakout_event_candidate_audit.csv"
OUTPUT_SUMMARY_PATH = COUNTRY_GENRE_DIR / "breakout_event_candidate_audit.md"
OUTPUT_RETAINED_EVENT_PATH = COUNTRY_GENRE_DIR / "breakout_event_file.csv"


breakout_panel = SourceFileLoader(
    "breakout_panel", str(PROJECT_ROOT / "code" / "72_build_breakout_event_panel.py")
).load_module()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Audit breakout-event candidates against the live scene panel.")
    parser.add_argument("--peak-cutoff", type=int, default=None, help="Keep rows with peak_position <= cutoff.")
    parser.add_argument(
        "--require-top10",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Require top10_flag == 1. Use --no-require-top10 to allow a broader chart cutoff.",
    )
    parser.add_argument(
        "--event-tier-label",
        default="operational_first_pass_candidate",
        help="Value to assign to retained rows in the recommended event file.",
    )
    parser.add_argument(
        "--audit-path",
        type=Path,
        default=OUTPUT_AUDIT_PATH,
        help="CSV output for the full candidate audit.",
    )
    parser.add_argument(
        "--summary-path",
        type=Path,
        default=OUTPUT_SUMMARY_PATH,
        help="Markdown output for the audit summary.",
    )
    parser.add_argument(
        "--retained-event-path",
        type=Path,
        default=OUTPUT_RETAINED_EVENT_PATH,
        help="CSV output for rows retained into the operational event file.",
    )
    return parser.parse_args()


def load_core_candidates(valid_genres: set[str], peak_cutoff: int | None, require_top10: bool) -> pd.DataFrame:
    core = pd.read_csv(CORE_PATH)
    seed = pd.read_csv(SEED_PATH, usecols=["seed_album_id", "primary_genre", "seed_inclusion_rule"])
    core = core.merge(seed, on="seed_album_id", how="left", suffixes=("", "_seed"))

    candidates = core.loc[
        core["entry_date"].notna() & core["primary_genre"].isin(valid_genres) & core["primary_genre"].ne("heavy_metal")
    ].copy()
    candidates["peak_position_num"] = pd.to_numeric(candidates["peak_position"], errors="coerce")
    if require_top10:
        candidates = candidates.loc[candidates["top10_flag"].fillna(0).eq(1)].copy()
    if peak_cutoff is not None:
        candidates = candidates.loc[candidates["peak_position_num"].le(peak_cutoff)].copy()

    candidates["event_year"] = pd.to_numeric(candidates["hit_year"], errors="coerce").astype(int)
    candidates["event_id"] = (
        candidates["market_code"].astype(str).str.lower()
        + "_"
        + candidates["primary_genre"].astype(str)
        + "_"
        + candidates["event_year"].astype(str)
        + "_"
        + candidates["album_title"].astype(str).str.lower().str.replace(r"[^a-z0-9]+", "_", regex=True).str.strip("_")
    )
    candidates["timing_precision"] = candidates["entry_date"].astype(str).apply(
        lambda value: "week" if str(value).startswith("W") else "day"
    )
    candidates["event_tier"] = "audit_candidate"
    candidates["screen_read"] = "candidate audit row"

    candidates = (
        candidates[
            [
                "event_id",
                "market_code",
                "country_name",
                "primary_genre",
                "artist_name",
                "album_title",
                "event_year",
                "entry_date",
                "timing_precision",
                "source_name",
                "market_exposure_type",
                "seed_inclusion_rule",
                "peak_position",
                "weeks_on_chart",
                "event_tier",
                "screen_read",
            ]
        ]
        .drop_duplicates()
        .sort_values(["market_code", "primary_genre", "event_year", "artist_name", "album_title"])
        .reset_index(drop=True)
    )

    candidates["first_chart_breakout_i"] = (
        candidates.groupby(["market_code", "primary_genre"]).cumcount().eq(0).astype(int)
    )
    return candidates


def build_candidate_audit(candidates: pd.DataFrame) -> pd.DataFrame:
    city_lookup = breakout_panel.load_city_lookup()
    overall, genre, emergence = breakout_panel.load_scene_frames()
    starts = breakout_panel.build_local_genre_starts()

    events = candidates.copy()
    events["priority_rank"] = range(1, len(events) + 1)
    events = events.rename(columns={"entry_date": "event_date_raw"})

    panel = breakout_panel.build_event_panel(events, city_lookup, overall, genre, emergence, starts)
    capability = breakout_panel.build_capability_file(panel)

    panel_summary = (
        panel.groupby(["event_id", "market_code", "genre_family", "event_year"], as_index=False)
        .agg(
            city_count=("city_country", "nunique"),
            years_with_genre_starts=("local_genre_band_starts", lambda values: int((values > 0).sum())),
            total_genre_starts=("local_genre_band_starts", "sum"),
        )
        .rename(columns={"genre_family": "primary_genre"})
    )

    capability_summary = (
        capability.groupby("event_id", as_index=False)
        .agg(
            positive_capability_cities=("pre_shock_capability_score", lambda values: int((values > 0).sum())),
            high_capability_cities=("high_capability_i", "sum"),
            mid_capability_cities=("mid_capability_i", "sum"),
            low_capability_cities=("low_capability_i", "sum"),
            flat_capability_cities=("flat_capability_i", "sum"),
            max_capability_score=("pre_shock_capability_score", "max"),
        )
    )

    audit = candidates.merge(
        panel_summary,
        on=["event_id", "market_code", "primary_genre", "event_year"],
        how="left",
    ).merge(
        capability_summary,
        on="event_id",
        how="left",
    )

    audit["operational_recommendation"] = "park"
    audit.loc[
        audit["first_chart_breakout_i"].eq(1)
        & audit["positive_capability_cities"].ge(3)
        & audit["years_with_genre_starts"].ge(8),
        "operational_recommendation",
    ] = "retain_operational_first_pass"
    audit.loc[
        audit["first_chart_breakout_i"].eq(1)
        & audit["operational_recommendation"].ne("retain_operational_first_pass")
        & audit["positive_capability_cities"].eq(0),
        "operational_recommendation",
    ] = "park_flat_capability"
    audit.loc[
        audit["first_chart_breakout_i"].eq(0)
        & audit["positive_capability_cities"].gt(0)
        & audit["years_with_genre_starts"].gt(0),
        "operational_recommendation",
    ] = "later_repeat_not_first_breakout"

    audit["audit_note"] = ""
    audit.loc[
        audit["operational_recommendation"].eq("retain_operational_first_pass"),
        "audit_note",
    ] = "First chart-led breakout with some pre-shock focal capability and nonzero event-window starts."
    audit.loc[
        audit["operational_recommendation"].eq("park_flat_capability"),
        "audit_note",
    ] = "First breakout row exists, but the live scene panel shows zero positive pre-shock focal capability."
    audit.loc[
        audit["operational_recommendation"].eq("later_repeat_not_first_breakout"),
        "audit_note",
    ] = "Operationally non-flat, but this is a later repeat rather than the first breakout for the market-genre."
    audit.loc[
        audit["operational_recommendation"].eq("park"),
        "audit_note",
    ] = "Does not meet the first-pass branch screen under the current workflow."

    return audit.sort_values(
        ["operational_recommendation", "market_code", "primary_genre", "event_year", "artist_name"],
        ascending=[True, True, True, True, True],
    ).reset_index(drop=True)


def build_retained_event_file(audit: pd.DataFrame, event_tier_label: str) -> pd.DataFrame:
    retained = audit.loc[audit["operational_recommendation"].eq("retain_operational_first_pass")].copy()
    retained = retained.sort_values(["event_year", "market_code", "primary_genre", "artist_name", "album_title"]).reset_index(
        drop=True
    )
    retained["priority_rank"] = range(1, len(retained) + 1)
    retained["event_tier"] = event_tier_label
    retained["screen_read"] = retained["audit_note"]
    retained = retained.rename(columns={"entry_date": "event_date_raw"})
    return retained[
        [
            "event_id",
            "priority_rank",
            "market_code",
            "country_name",
            "primary_genre",
            "artist_name",
            "album_title",
            "event_year",
            "event_date_raw",
            "timing_precision",
            "source_name",
            "market_exposure_type",
            "event_tier",
            "screen_read",
        ]
    ].copy()


def write_summary(audit: pd.DataFrame, summary_path: Path, require_top10: bool, peak_cutoff: int | None) -> None:
    retained = audit.loc[audit["operational_recommendation"].eq("retain_operational_first_pass")].copy()
    parked_first = audit.loc[
        audit["first_chart_breakout_i"].eq(1)
        & audit["operational_recommendation"].ne("retain_operational_first_pass")
    ].copy()
    later_repeats = audit.loc[audit["operational_recommendation"].eq("later_repeat_not_first_breakout")].copy()

    lines: list[str] = []
    lines.append("# Breakout event candidate audit")
    lines.append("")
    scope_parts = ["live scene-panel genre families", "non-`heavy_metal` coding", "dated chart-entry rows"]
    if require_top10:
        scope_parts.insert(0, "top-10 rows")
    if peak_cutoff is not None:
        scope_parts.insert(0, f"peak-position <= {peak_cutoff} rows")
    lines.append(f"- Scope: {', '.join(scope_parts)}.")
    lines.append(f"- Candidate rows audited: `{len(audit)}`")
    lines.append(f"- First-breakout rows retained for the operational branch: `{len(retained)}`")
    lines.append("")
    lines.append("## Retained operational first-pass events")
    lines.append("")
    if retained.empty:
        lines.append("None.")
    else:
        for row in retained.itertuples(index=False):
            lines.append(
                f"- `{row.market_code} x {row.primary_genre} x {row.event_year}` via "
                f"`{row.artist_name} - {row.album_title}`: "
                f"`positive_capability_cities={int(row.positive_capability_cities)}`, "
                f"`years_with_genre_starts={int(row.years_with_genre_starts)}`."
            )

    lines.append("")
    lines.append("## First-breakout rows parked")
    lines.append("")
    if parked_first.empty:
        lines.append("None.")
    else:
        for row in parked_first.itertuples(index=False):
            lines.append(
                f"- `{row.market_code} x {row.primary_genre} x {row.event_year}` via "
                f"`{row.artist_name} - {row.album_title}`: "
                f"`recommendation={row.operational_recommendation}`, "
                f"`positive_capability_cities={int(row.positive_capability_cities)}`, "
                f"`years_with_genre_starts={int(row.years_with_genre_starts)}`."
            )

    lines.append("")
    lines.append("## Later repeats parked")
    lines.append("")
    if later_repeats.empty:
        lines.append("None.")
    else:
        for row in later_repeats.itertuples(index=False):
            lines.append(
                f"- `{row.market_code} x {row.primary_genre} x {row.event_year}` via "
                f"`{row.artist_name} - {row.album_title}`: "
                f"later repeat with `positive_capability_cities={int(row.positive_capability_cities)}` and "
                f"`years_with_genre_starts={int(row.years_with_genre_starts)}`."
            )

    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    _, genre, emergence = breakout_panel.load_scene_frames()
    valid_genres = set(genre["genre_family"].dropna().astype(str).unique()).union(
        set(emergence["genre_family"].dropna().astype(str).unique())
    )
    candidates = load_core_candidates(valid_genres, args.peak_cutoff, args.require_top10)
    audit = build_candidate_audit(candidates)
    retained_events = build_retained_event_file(audit, args.event_tier_label)

    args.audit_path.parent.mkdir(parents=True, exist_ok=True)
    audit.to_csv(args.audit_path, index=False)
    retained_events.to_csv(args.retained_event_path, index=False)
    write_summary(audit, args.summary_path, args.require_top10, args.peak_cutoff)

    print(f"Wrote {args.audit_path}")
    print(f"Wrote {args.retained_event_path}")
    print(f"Wrote {args.summary_path}")


if __name__ == "__main__":
    main()
