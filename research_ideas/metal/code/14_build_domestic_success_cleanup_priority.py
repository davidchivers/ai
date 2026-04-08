"""
14_build_domestic_success_cleanup_priority.py

Build a reproducible cleanup-priority table for the current domestic-success
pilot and derive a stricter shock-clean case file for reruns.

Inputs:
    data/processed/country_genre_analysis/domestic_success_pilot_cases.csv
    data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_case_metrics.csv
    data/processed/country_genre_analysis/scene_qualitative_evidence_source_map.csv

Outputs:
    data/processed/country_genre_analysis/domestic_success_cleanup_priority.csv
    data/processed/country_genre_analysis/domestic_success_cleanup_priority.md
    data/processed/country_genre_analysis/domestic_success_pilot_cases_shock_clean.csv

Usage:
    python code/14_build_domestic_success_cleanup_priority.py
"""

from __future__ import annotations

import csv
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "country_genre_analysis"

PILOT_CASES_PATH = OUTPUT_DIR / "domestic_success_pilot_cases.csv"
METRICS_PATH = OUTPUT_DIR / "domestic_success_pilot_scene_complements_case_metrics.csv"
QUAL_MAP_PATH = OUTPUT_DIR / "scene_qualitative_evidence_source_map.csv"

PRIORITY_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_cleanup_priority.csv"
SUMMARY_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_cleanup_priority.md"
SHOCK_CLEAN_CASES_PATH = OUTPUT_DIR / "domestic_success_pilot_cases_shock_clean.csv"


def classify_action(row: pd.Series) -> str:
    scene_label = str(row["scene_complements_label"])
    years_since_first = float(row["years_since_first_observed"])
    source_tier = str(row["source_tier"])
    event_tier = str(row["event_tier"])

    if scene_label in {"mature_scene_milestone_candidate", "deep_and_still_thickening"}:
        return "drop_from_shock_baseline"
    if scene_label == "rising_scene_breakthrough_candidate":
        if source_tier == "source_a" and event_tier == "tier_1":
            return "keep_in_shock_clean"
        return "provisional_keep_in_shock_clean"
    if scene_label == "mixed":
        if years_since_first >= 30 or event_tier == "tier_2":
            return "replace_or_redate_before_use"
        if years_since_first <= 20 and source_tier == "source_a" and event_tier == "tier_1":
            return "keep_in_shock_clean"
        return "manual_review_before_use"
    return "manual_review_before_use"


def decision_reason(row: pd.Series) -> str:
    scene_label = str(row["scene_complements_label"])
    years_since_first = int(float(row["years_since_first_observed"]))
    source_tier = str(row["source_tier"])
    event_tier = str(row["event_tier"])
    qual_source_ct = int(row["qualitative_source_ct"])

    if row["recommended_action"] == "drop_from_shock_baseline":
        return (
            f"{scene_label}; {years_since_first} years since first observed; "
            f"qualitative memo also points to a scene-first interpretation"
        )
    if row["recommended_action"] == "replace_or_redate_before_use":
        return (
            f"mixed case but late-coded ({years_since_first} years since first observed) "
            f"or weak event tier ({event_tier})"
        )
    if row["recommended_action"] == "keep_in_shock_clean":
        return (
            f"best current shock candidate under the pilot rules; "
            f"{scene_label}; source tier {source_tier}; qualitative sources {qual_source_ct}"
        )
    if row["recommended_action"] == "provisional_keep_in_shock_clean":
        return (
            f"good scene-timing candidate but source quality is weaker ({source_tier}); "
            f"keep only as provisional"
        )
    return (
        f"mixed evidence; {years_since_first} years since first observed; "
        f"needs manual re-dating or replacement before a causal read"
    )


def action_rank(action: str) -> int:
    order = {
        "keep_in_shock_clean": 0,
        "provisional_keep_in_shock_clean": 1,
        "manual_review_before_use": 2,
        "replace_or_redate_before_use": 3,
        "drop_from_shock_baseline": 4,
    }
    return order.get(action, 9)


def build_priority_table(
    pilot_cases: pd.DataFrame,
    case_metrics: pd.DataFrame,
    qualitative_map: pd.DataFrame,
) -> pd.DataFrame:
    qual_counts = (
        qualitative_map.groupby("pilot_case_id", as_index=False)
        .agg(
            qualitative_source_ct=("source_title", "size"),
            qualitative_design_reads=("design_read", lambda values: " | ".join(sorted(set(str(v) for v in values)))),
        )
    )

    merged = pilot_cases.merge(
        case_metrics[
            [
                "pilot_case_id",
                "first_observed_year",
                "years_since_first_observed",
                "scene_depth_score",
                "scene_growth_score",
                "maturity_minus_growth_score",
                "scene_complements_label",
                "late_coding_heuristic_rank",
            ]
        ],
        on="pilot_case_id",
        how="left",
    ).merge(
        qual_counts,
        on="pilot_case_id",
        how="left",
    )

    merged["qualitative_source_ct"] = merged["qualitative_source_ct"].fillna(0).astype(int)
    merged["qualitative_design_reads"] = merged["qualitative_design_reads"].fillna("")
    merged["recommended_action"] = merged.apply(classify_action, axis=1)
    merged["shock_clean_keep_i"] = merged["recommended_action"].isin(
        ["keep_in_shock_clean", "provisional_keep_in_shock_clean"]
    ).astype(int)
    merged["decision_reason"] = merged.apply(decision_reason, axis=1)
    merged["recommended_review_order"] = merged["recommended_action"].map(action_rank).astype(int)

    merged = merged.sort_values(
        [
            "recommended_review_order",
            "late_coding_heuristic_rank",
            "country_name",
            "genre_family",
        ],
        ascending=[True, True, True, True],
    ).reset_index(drop=True)
    return merged


def load_qualitative_map() -> pd.DataFrame:
    rows: list[dict[str, str]] = []
    with open(QUAL_MAP_PATH, "r", encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        header = next(reader, None)
        if header is None:
            return pd.DataFrame(
                columns=[
                    "scene_key",
                    "pilot_case_id",
                    "source_type",
                    "source_title",
                    "source_url",
                    "qualitative_takeaway",
                    "design_read",
                ]
            )

        for raw_row in reader:
            if not raw_row:
                continue
            if len(raw_row) == 7:
                row = raw_row
            else:
                url_idx = next(
                    (
                        idx
                        for idx in range(4, len(raw_row))
                        if str(raw_row[idx]).startswith("http")
                    ),
                    None,
                )
                if url_idx is None:
                    continue
                row = [
                    raw_row[0],
                    raw_row[1],
                    raw_row[2],
                    ",".join(raw_row[3:url_idx]).strip(),
                    raw_row[url_idx],
                    raw_row[url_idx + 1] if url_idx + 1 < len(raw_row) else "",
                    ",".join(raw_row[url_idx + 2 :]).strip() if url_idx + 2 < len(raw_row) else "",
                ]

            rows.append(
                {
                    "scene_key": row[0],
                    "pilot_case_id": row[1],
                    "source_type": row[2],
                    "source_title": row[3],
                    "source_url": row[4],
                    "qualitative_takeaway": row[5],
                    "design_read": row[6],
                }
            )
    return pd.DataFrame(rows).fillna(pd.NA)


def build_summary(priority_table: pd.DataFrame) -> str:
    action_counts = priority_table["recommended_action"].value_counts().to_dict()
    keep_rows = priority_table.loc[priority_table["shock_clean_keep_i"].eq(1)].copy()
    drop_rows = priority_table.loc[
        priority_table["recommended_action"].eq("drop_from_shock_baseline")
    ].copy()
    replace_rows = priority_table.loc[
        priority_table["recommended_action"].eq("replace_or_redate_before_use")
    ].copy()

    lines: list[str] = []
    lines.append("# Domestic-success cleanup priority")
    lines.append("")
    lines.append("- Scope: current `10`-case domestic-success pilot")
    lines.append("- Purpose: separate rows that still look usable for a shock-style design from rows that now look scene-milestone or late-coded")
    lines.append(f"- `keep_in_shock_clean`: `{action_counts.get('keep_in_shock_clean', 0)}`")
    lines.append(f"- `provisional_keep_in_shock_clean`: `{action_counts.get('provisional_keep_in_shock_clean', 0)}`")
    lines.append(f"- `manual_review_before_use`: `{action_counts.get('manual_review_before_use', 0)}`")
    lines.append(f"- `replace_or_redate_before_use`: `{action_counts.get('replace_or_redate_before_use', 0)}`")
    lines.append(f"- `drop_from_shock_baseline`: `{action_counts.get('drop_from_shock_baseline', 0)}`")
    lines.append("")
    lines.append("## Shock-clean keep set")
    lines.append("")
    lines.append("| Country | Genre | Artist | Action | Reason |")
    lines.append("|---------|-------|--------|--------|--------|")
    for row in keep_rows.itertuples(index=False):
        lines.append(
            f"| {row.country_name} | {row.genre_family} | {row.artist_name} | {row.recommended_action} | {row.decision_reason} |"
        )
    lines.append("")
    lines.append("## Drop from shock baseline")
    lines.append("")
    lines.append("| Country | Genre | Artist | Scene label |")
    lines.append("|---------|-------|--------|-------------|")
    for row in drop_rows.itertuples(index=False):
        lines.append(
            f"| {row.country_name} | {row.genre_family} | {row.artist_name} | {row.scene_complements_label} |"
        )
    lines.append("")
    lines.append("## Replace or redate before use")
    lines.append("")
    lines.append("| Country | Genre | Artist | Why |")
    lines.append("|---------|-------|--------|-----|")
    for row in replace_rows.itertuples(index=False):
        lines.append(
            f"| {row.country_name} | {row.genre_family} | {row.artist_name} | {row.decision_reason} |"
        )
    lines.append("")
    lines.append("## Interpretation")
    lines.append("")
    lines.append("- The current shock-clean file is intentionally small. That is a feature, not a bug: the project needs fewer but more credible treatment rows.")
    lines.append("- Mature-scene or deep-complements rows are still useful for the scene-milestone branch, but they should not anchor the domestic-shock baseline.")
    lines.append("- Mixed late-coded rows should be replaced by earlier and cleaner domestic breakthroughs rather than defended as-is.")
    return "\n".join(lines) + "\n"


def main() -> None:
    pilot_cases = pd.read_csv(PILOT_CASES_PATH).fillna(pd.NA)
    case_metrics = pd.read_csv(METRICS_PATH).fillna(pd.NA)
    qualitative_map = load_qualitative_map()

    priority_table = build_priority_table(
        pilot_cases=pilot_cases,
        case_metrics=case_metrics,
        qualitative_map=qualitative_map,
    )
    shock_clean = pilot_cases.loc[
        pilot_cases["pilot_case_id"].isin(
            priority_table.loc[priority_table["shock_clean_keep_i"].eq(1), "pilot_case_id"]
        )
    ].copy()

    priority_table.to_csv(PRIORITY_OUTPUT_PATH, index=False)
    shock_clean.to_csv(SHOCK_CLEAN_CASES_PATH, index=False)
    SUMMARY_OUTPUT_PATH.write_text(build_summary(priority_table), encoding="utf-8")

    print(f"Pilot rows reviewed: {len(priority_table)}")
    print(f"Shock-clean keep rows: {len(shock_clean)}")
    print(f"Wrote: {PRIORITY_OUTPUT_PATH}")
    print(f"Wrote: {SUMMARY_OUTPUT_PATH}")
    print(f"Wrote: {SHOCK_CLEAN_CASES_PATH}")


if __name__ == "__main__":
    main()
