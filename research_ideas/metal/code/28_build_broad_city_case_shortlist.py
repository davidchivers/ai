"""
28_build_broad_city_case_shortlist.py

Build a focused shortlist of the broad surviving city-scene cases that
should be hand-validated before making a branch decision.

Inputs:
    data/processed/scene_networks/surviving_precedes_case_audit.csv

Outputs:
    data/processed/scene_networks/broad_city_precedes_case_shortlist.csv
    data/processed/scene_networks/broad_city_precedes_case_shortlist.md

Usage:
    python code/28_build_broad_city_case_shortlist.py
"""

from __future__ import annotations

import csv
import os


DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "processed", "scene_networks")
INFILE = os.path.join(DATA_DIR, "surviving_precedes_case_audit.csv")
OUT_CSV = os.path.join(DATA_DIR, "broad_city_precedes_case_shortlist.csv")
OUT_MD = os.path.join(DATA_DIR, "broad_city_precedes_case_shortlist.md")


def safe_int(value: str) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def provisional_review_tier(row: dict[str, str]) -> str:
    lead = safe_int(row["lead_years"])
    label_year_bands = safe_int(row["label_year_active_bands"])
    total_bands = safe_int(row["n_bands_total"])
    if lead >= 4 and (label_year_bands >= 25 or total_bands >= 75):
        return "strong_keep_candidate"
    return "borderline_keep_candidate"


def load_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    with open(INFILE, "r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            if row["case_bucket"] != "broad_scene_case":
                continue
            rows.append(
                {
                    **row,
                    "review_tier": provisional_review_tier(row),
                    "manual_review_priority": "high",
                }
            )
    rows.sort(
        key=lambda row: (
            0 if row["review_tier"] == "strong_keep_candidate" else 1,
            -safe_int(str(row["lead_years"])),
            str(row["city_country"]),
        )
    )
    return rows


def write_csv(rows: list[dict[str, object]]) -> None:
    fieldnames = [
        "city",
        "country",
        "city_country",
        "genre_family",
        "lead_years",
        "community_detect_year",
        "emergence_year",
        "label_year_active_bands",
        "n_bands_total",
        "density",
        "review_tier",
        "manual_review_priority",
    ]
    with open(OUT_CSV, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=fieldnames,
        )
        writer.writeheader()
        writer.writerows([{key: row[key] for key in fieldnames} for row in rows])


def write_md(rows: list[dict[str, object]]) -> None:
    with open(OUT_MD, "w", encoding="utf-8") as handle:
        handle.write("# Broad city precedes shortlist\n\n")
        handle.write("- Scope: `broad_scene_case` rows from `surviving_precedes_case_audit.csv`\n")
        handle.write(f"- Broad-city cases queued for manual review: `{len(rows)}`\n")
        handle.write(
            f"- `strong_keep_candidate`: `{sum(row['review_tier'] == 'strong_keep_candidate' for row in rows)}`\n"
        )
        handle.write(
            f"- `borderline_keep_candidate`: `{sum(row['review_tier'] == 'borderline_keep_candidate' for row in rows)}`\n\n"
        )

        handle.write("## Shortlist\n\n")
        handle.write("| City | Genre | Lead | Label-year active bands | Total city bands | Review tier |\n")
        handle.write("|------|-------|------|--------------------------|------------------|-------------|\n")
        for row in rows:
            handle.write(
                f"| {row['city_country']} | {row['genre_family']} | {row['lead_years']} | "
                f"{row['label_year_active_bands']} | {row['n_bands_total']} | {row['review_tier']} |\n"
            )

        handle.write("\n## Manual review question\n\n")
        handle.write(
            "For each shortlist case, check whether the early four-band cluster looks like a real "
            "local scene nucleus rather than a thin membership artifact or coding quirk.\n"
        )


def main() -> None:
    rows = load_rows()
    write_csv(rows)
    write_md(rows)


if __name__ == "__main__":
    main()
