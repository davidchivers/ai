from __future__ import annotations

from importlib.machinery import SourceFileLoader
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
COUNTRY_GENRE_DIR = PROJECT_ROOT / "data" / "processed" / "country_genre_analysis"

OUTPUT_RESULTS_PATH = COUNTRY_GENRE_DIR / "breakout_branch_screen_sweep.csv"
OUTPUT_SUMMARY_PATH = COUNTRY_GENRE_DIR / "breakout_branch_screen_sweep.md"

audit_mod = SourceFileLoader(
    "breakout_audit", str(PROJECT_ROOT / "code" / "73_audit_breakout_event_candidates.py")
).load_module()
panel_mod = SourceFileLoader(
    "breakout_panel", str(PROJECT_ROOT / "code" / "72_build_breakout_event_panel.py")
).load_module()


SCREENS = [
    {"screen_id": "top10", "require_top10": True, "peak_cutoff": None},
    {"screen_id": "peak15", "require_top10": False, "peak_cutoff": 15},
    {"screen_id": "peak20", "require_top10": False, "peak_cutoff": 20},
    {"screen_id": "peak25", "require_top10": False, "peak_cutoff": 25},
    {"screen_id": "peak30", "require_top10": False, "peak_cutoff": 30},
]


def summarize_period(frame: pd.DataFrame, start_year: int, end_year: int, column: str) -> float:
    subset = frame.loc[frame["relative_event_year"].between(start_year, end_year), column]
    if subset.empty:
        return 0.0
    return float(subset.mean())


def build_screen_result(valid_genres: set[str], screen: dict[str, object]) -> dict[str, object]:
    candidates = audit_mod.load_core_candidates(
        valid_genres=valid_genres,
        peak_cutoff=screen["peak_cutoff"],
        require_top10=screen["require_top10"],
    )
    audit = audit_mod.build_candidate_audit(candidates)
    retained = audit_mod.build_retained_event_file(audit, f"sweep_{screen['screen_id']}")

    city_lookup = panel_mod.load_city_lookup()
    overall, genre, emergence = panel_mod.load_scene_frames()
    starts = panel_mod.build_local_genre_starts()

    panel = panel_mod.build_event_panel(retained, city_lookup, overall, genre, emergence, starts)
    capability = panel_mod.build_capability_file(panel)[
        ["event_id", "city_country", "pre_shock_capability_score", "pre_shock_subthreshold_i"]
    ].copy()
    capability["capability_group"] = capability["pre_shock_capability_score"].gt(0).map(
        {True: "positive_capability", False: "zero_capability"}
    )

    merged = panel.merge(capability, on=["event_id", "city_country"], how="left")
    merged = merged.loc[merged["pre_shock_subthreshold_i"].eq(1)].copy()

    positive = merged.loc[merged["capability_group"].eq("positive_capability")].copy()
    zero = merged.loc[merged["capability_group"].eq("zero_capability")].copy()

    positive_city_events = int(positive[["event_id", "city_country"]].drop_duplicates().shape[0])
    zero_city_events = int(zero[["event_id", "city_country"]].drop_duplicates().shape[0])

    pre_positive_starts = summarize_period(positive, -5, -1, "local_genre_band_starts")
    pre_zero_starts = summarize_period(zero, -5, -1, "local_genre_band_starts")
    post_positive_starts = summarize_period(positive, 0, 5, "local_genre_band_starts")
    post_zero_starts = summarize_period(zero, 0, 5, "local_genre_band_starts")

    positive_counts = (
        positive[["event_id", "city_country"]]
        .drop_duplicates()
        .groupby("event_id", as_index=False)
        .size()
        .rename(columns={"size": "positive_city_count"})
    )
    if positive_counts.empty:
        dominant_event_id = ""
        dominant_event_positive_cities = 0
    else:
        dominant = positive_counts.sort_values(["positive_city_count", "event_id"], ascending=[False, True]).iloc[0]
        dominant_event_id = str(dominant["event_id"])
        dominant_event_positive_cities = int(dominant["positive_city_count"])

    return {
        "screen_id": screen["screen_id"],
        "require_top10": int(bool(screen["require_top10"])),
        "peak_cutoff": screen["peak_cutoff"] if screen["peak_cutoff"] is not None else pd.NA,
        "candidate_rows": int(len(candidates)),
        "retained_events": int(len(retained)),
        "positive_city_events": positive_city_events,
        "zero_city_events": zero_city_events,
        "pre_positive_band_starts": pre_positive_starts,
        "pre_zero_band_starts": pre_zero_starts,
        "post_positive_band_starts": post_positive_starts,
        "post_zero_band_starts": post_zero_starts,
        "pretrend_ratio": (pre_positive_starts / pre_zero_starts) if pre_zero_starts > 0 else pd.NA,
        "post_ratio": (post_positive_starts / post_zero_starts) if post_zero_starts > 0 else pd.NA,
        "dominant_event_id": dominant_event_id,
        "dominant_event_positive_cities": dominant_event_positive_cities,
    }


def write_summary(results: pd.DataFrame) -> None:
    results = results.sort_values("retained_events", ascending=False).reset_index(drop=True)
    best_support = results.sort_values(
        ["positive_city_events", "retained_events", "screen_id"], ascending=[False, False, True]
    ).iloc[0]
    best_balance = results.sort_values(
        ["pretrend_ratio", "positive_city_events", "screen_id"], ascending=[True, False, True]
    ).iloc[0]

    lines: list[str] = []
    lines.append("# Breakout branch screen sweep")
    lines.append("")
    lines.append("- Purpose: compare strict and relaxed chart-entry screens on support versus descriptive imbalance.")
    lines.append("- Common branch logic across screens:")
    lines.append("  - live scene-panel genre families")
    lines.append("  - non-`heavy_metal` rows")
    lines.append("  - first breakout rows only")
    lines.append("  - retained only when pre-shock focal capability is non-flat and event-window starts are nonzero enough to pass the operational rule")
    lines.append("")
    lines.append("## Main read")
    lines.append("")
    lines.append(
        f"- Best support comes from `{best_support['screen_id']}`: "
        f"`retained_events={int(best_support['retained_events'])}`, "
        f"`positive_city_events={int(best_support['positive_city_events'])}`."
    )
    lines.append(
        f"- Best pretrend balance comes from `{best_balance['screen_id']}` on the crude ratio metric, "
        f"but even there the positive-capability margin is already far above the zero-capability margin before the breakout."
    )
    lines.append(
        "- No screen in the current treatment build simultaneously delivers broad support and a convincing descriptive pretrend profile."
    )
    lines.append("")
    lines.append("## Screen table")
    lines.append("")
    lines.append("| Screen | Top10 only | Peak cutoff | Candidate rows | Retained events | Positive city-events | Zero city-events | Pre positive starts | Pre zero starts | Post positive starts | Post zero starts | Dominant event | Dominant positive cities |")
    lines.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|")
    for row in results.sort_values(["require_top10", "peak_cutoff", "screen_id"]).itertuples(index=False):
        peak_display = "" if pd.isna(row.peak_cutoff) else int(row.peak_cutoff)
        lines.append(
            f"| {row.screen_id} | {row.require_top10} | {peak_display} | {int(row.candidate_rows)} | "
            f"{int(row.retained_events)} | {int(row.positive_city_events)} | {int(row.zero_city_events)} | "
            f"{row.pre_positive_band_starts:.4f} | {row.pre_zero_band_starts:.4f} | "
            f"{row.post_positive_band_starts:.4f} | {row.post_zero_band_starts:.4f} | "
            f"{row.dominant_event_id} | {int(row.dominant_event_positive_cities)} |"
        )

    OUTPUT_SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    _, genre, emergence = panel_mod.load_scene_frames()
    valid_genres = set(genre["genre_family"].dropna().astype(str).unique()).union(
        set(emergence["genre_family"].dropna().astype(str).unique())
    )

    results = pd.DataFrame([build_screen_result(valid_genres, screen) for screen in SCREENS])
    OUTPUT_RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    results.to_csv(OUTPUT_RESULTS_PATH, index=False)
    write_summary(results)

    print(f"Wrote {OUTPUT_RESULTS_PATH}")
    print(f"Wrote {OUTPUT_SUMMARY_PATH}")


if __name__ == "__main__":
    main()
