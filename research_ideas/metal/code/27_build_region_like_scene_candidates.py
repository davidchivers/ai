"""
27_build_region_like_scene_candidates.py

Summarize region-like scene cases from a sidecar timing run that keeps
region-like units but still excludes malformed labels.

Expected inputs:
    data/processed/scene_networks/community_vs_label_timing_region_like_sidecar.csv
    data/processed/scene_networks/city_geography_audit.csv

Outputs:
    data/processed/scene_networks/region_like_scene_candidates.csv
    data/processed/scene_networks/region_like_scene_candidates.md

Usage:
    python code/27_build_region_like_scene_candidates.py
"""

from __future__ import annotations

import csv
import os
from collections import Counter


DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "processed", "scene_networks")
TIMING_FILE = os.path.join(DATA_DIR, "community_vs_label_timing_region_like_sidecar.csv")
AUDIT_FILE = os.path.join(DATA_DIR, "city_geography_audit.csv")
OUT_CSV = os.path.join(DATA_DIR, "region_like_scene_candidates.csv")
OUT_MD = os.path.join(DATA_DIR, "region_like_scene_candidates.md")


def safe_int(value: str) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def safe_float(value: str) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def load_audit() -> dict[str, dict[str, str]]:
    with open(AUDIT_FILE, "r", encoding="utf-8", newline="") as handle:
        return {row["city_country"]: row for row in csv.DictReader(handle)}


def load_region_rows(audit_rows: dict[str, dict[str, str]]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    with open(TIMING_FILE, "r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            audit_row = audit_rows.get(row["city_country"])
            if not audit_row or safe_int(audit_row.get("region_like_i")) != 1:
                continue
            rows.append(
                {
                    "city": row["city"],
                    "country": row["country"],
                    "city_country": row["city_country"],
                    "genre_family": row["genre_family"],
                    "timing_status": row["timing_status"],
                    "lead_years": safe_int(row["lead_years"]),
                    "community_detect_year": safe_int(row["community_detect_year"]),
                    "emergence_year": safe_int(row["emergence_year"]),
                    "label_year_active_bands": safe_int(row["label_year_active_bands"]),
                    "detection_genre_bands": safe_int(row["detection_genre_bands"]),
                    "detection_genre_share": f"{safe_float(row['detection_genre_share']):.3f}",
                    "n_bands_total": safe_int(audit_row.get("n_bands")),
                    "density": f"{safe_float(audit_row.get('density')):.6f}",
                    "region_flag_source": (
                        "admin_keyword"
                        if safe_int(audit_row.get("flag_admin_keyword_i")) == 1
                        else "exact_admin_label"
                    ),
                }
            )
    rows.sort(
        key=lambda row: (
            0 if row["timing_status"] == "community_precedes_label" else 1 if row["timing_status"] == "community_same_year_as_label" else 2,
            -int(row["lead_years"]),
            str(row["city_country"]),
            str(row["genre_family"]),
        )
    )
    return rows


def write_csv(rows: list[dict[str, object]]) -> None:
    with open(OUT_CSV, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "city",
                "country",
                "city_country",
                "genre_family",
                "timing_status",
                "lead_years",
                "community_detect_year",
                "emergence_year",
                "label_year_active_bands",
                "detection_genre_bands",
                "detection_genre_share",
                "n_bands_total",
                "density",
                "region_flag_source",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def write_md(rows: list[dict[str, object]]) -> None:
    status_counts = Counter(str(row["timing_status"]) for row in rows)
    with open(OUT_MD, "w", encoding="utf-8") as handle:
        handle.write("# Region-like scene candidates\n\n")
        handle.write("- Source timing file: `community_vs_label_timing_region_like_sidecar.csv`\n")
        handle.write("- Interpretation: region-like units are kept out of the city baseline and summarized separately here\n")
        handle.write(f"- Region-like timing rows: `{len(rows)}`\n")
        handle.write(
            f"- `community_precedes_label`: `{status_counts['community_precedes_label']}`\n"
        )
        handle.write(
            f"- `community_same_year_as_label`: `{status_counts['community_same_year_as_label']}`\n"
        )
        handle.write(
            f"- `community_not_detected_by_label`: `{status_counts['community_not_detected_by_label']}`\n\n"
        )

        handle.write("## Top region-like precedes or same-year cases\n\n")
        handle.write("| Unit | Genre | Status | Lead | Total unit bands |\n")
        handle.write("|------|-------|--------|------|------------------|\n")
        shown = 0
        for row in rows:
            if row["timing_status"] == "community_not_detected_by_label":
                continue
            handle.write(
                f"| {row['city_country']} | {row['genre_family']} | {row['timing_status']} | "
                f"{row['lead_years']} | {row['n_bands_total']} |\n"
            )
            shown += 1
            if shown >= 40:
                break

        handle.write("\n## All region-like timing rows\n\n")
        handle.write("| Unit | Genre | Status | Lead | Flag source |\n")
        handle.write("|------|-------|--------|------|-------------|\n")
        for row in rows[:120]:
            handle.write(
                f"| {row['city_country']} | {row['genre_family']} | {row['timing_status']} | "
                f"{row['lead_years']} | {row['region_flag_source']} |\n"
            )


def main() -> None:
    audit_rows = load_audit()
    rows = load_region_rows(audit_rows)
    write_csv(rows)
    write_md(rows)


if __name__ == "__main__":
    main()
