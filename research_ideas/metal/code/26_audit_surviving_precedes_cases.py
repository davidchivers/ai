"""
26_audit_surviving_precedes_cases.py

Build a reusable audit table for the surviving community-precedes-label
cases under the current strict geography-clean baseline.

Outputs:
    data/processed/scene_networks/surviving_precedes_case_audit.csv
    data/processed/scene_networks/surviving_precedes_case_audit.md

Usage:
    python code/26_audit_surviving_precedes_cases.py
"""

from __future__ import annotations

import csv
import os
from collections import Counter


DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "processed", "scene_networks")
TIMING_FILE = os.path.join(DATA_DIR, "community_vs_label_timing.csv")
AUDIT_FILE = os.path.join(DATA_DIR, "city_geography_audit.csv")
OUT_CSV = os.path.join(DATA_DIR, "surviving_precedes_case_audit.csv")
OUT_MD = os.path.join(DATA_DIR, "surviving_precedes_case_audit.md")


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


def load_city_audit() -> dict[str, dict[str, str]]:
    with open(AUDIT_FILE, "r", encoding="utf-8", newline="") as handle:
        return {row["city_country"]: row for row in csv.DictReader(handle)}


def classify_case(total_bands: int, label_year_bands: int, density: float, small_dense_i: int) -> str:
    # Heuristic buckets for follow-up review, not a causal truth claim.
    if small_dense_i or total_bands <= 25 or label_year_bands <= 12 or density >= 0.50:
        return "fragile_case"
    if total_bands >= 50 or label_year_bands >= 25:
        return "broad_scene_case"
    return "mid_scene_case"


def load_surviving_cases(city_audit: dict[str, dict[str, str]]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    with open(TIMING_FILE, "r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            if row["timing_status"] != "community_precedes_label":
                continue
            audit_row = city_audit.get(row["city_country"], {})
            total_bands = safe_int(audit_row.get("n_bands"))
            label_year_bands = safe_int(row.get("label_year_active_bands"))
            density = safe_float(audit_row.get("density"))
            small_dense_i = safe_int(audit_row.get("flag_small_dense_i"))
            case_bucket = classify_case(
                total_bands=total_bands,
                label_year_bands=label_year_bands,
                density=density,
                small_dense_i=small_dense_i,
            )
            fragility_reason = []
            if small_dense_i:
                fragility_reason.append("small_dense_flag")
            if total_bands <= 25:
                fragility_reason.append("small_total_city")
            if label_year_bands <= 12:
                fragility_reason.append("small_label_year_city")
            if density >= 0.50:
                fragility_reason.append("high_density")

            rows.append(
                {
                    "city": row["city"],
                    "country": row["country"],
                    "city_country": row["city_country"],
                    "genre_family": row["genre_family"],
                    "lead_years": safe_int(row["lead_years"]),
                    "community_detect_year": safe_int(row["community_detect_year"]),
                    "emergence_year": safe_int(row["emergence_year"]),
                    "detection_genre_bands": safe_int(row["detection_genre_bands"]),
                    "detection_genre_share": f"{safe_float(row['detection_genre_share']):.3f}",
                    "detection_city_active_bands": safe_int(row["detection_city_active_bands"]),
                    "label_year_active_bands": label_year_bands,
                    "total_bands_in_city": safe_int(row["total_bands_in_city"]),
                    "total_bands_in_city_genre": safe_int(row["total_bands_in_city_genre"]),
                    "n_bands_total": total_bands,
                    "density": f"{density:.6f}",
                    "flag_small_dense_i": small_dense_i,
                    "timing_rows_city": safe_int(audit_row.get("timing_rows")),
                    "precedes_rows_city": safe_int(audit_row.get("precedes_rows")),
                    "case_bucket": case_bucket,
                    "fragility_reason": ";".join(fragility_reason),
                }
            )

    rows.sort(key=lambda r: (-int(r["lead_years"]), str(r["city_country"])))
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
                "lead_years",
                "community_detect_year",
                "emergence_year",
                "detection_genre_bands",
                "detection_genre_share",
                "detection_city_active_bands",
                "label_year_active_bands",
                "total_bands_in_city",
                "total_bands_in_city_genre",
                "n_bands_total",
                "density",
                "flag_small_dense_i",
                "timing_rows_city",
                "precedes_rows_city",
                "case_bucket",
                "fragility_reason",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def write_md(rows: list[dict[str, object]]) -> None:
    bucket_counts = Counter(str(row["case_bucket"]) for row in rows)
    genre_counts = Counter(str(row["genre_family"]) for row in rows)
    lead_ge_6 = sum(int(row["lead_years"]) >= 6 for row in rows)
    label_year_small = sum(int(row["label_year_active_bands"]) <= 12 for row in rows)
    genre_band_counts = Counter(int(row["detection_genre_bands"]) for row in rows)

    with open(OUT_MD, "w", encoding="utf-8") as handle:
        handle.write("# Surviving precedes case audit\n\n")
        handle.write("- Scope: current strict geography-clean baseline from `24_test_community_precedes_label.py`\n")
        handle.write(f"- Surviving `community_precedes_label` cases: `{len(rows)}`\n")
        handle.write(f"- `broad_scene_case`: `{bucket_counts['broad_scene_case']}`\n")
        handle.write(f"- `mid_scene_case`: `{bucket_counts['mid_scene_case']}`\n")
        handle.write(f"- `fragile_case`: `{bucket_counts['fragile_case']}`\n")
        handle.write(f"- Cases with lead `>= 6`: `{lead_ge_6}`\n")
        handle.write(f"- Cases with `label_year_active_bands <= 12`: `{label_year_small}`\n")
        handle.write(
            f"- Detection genre-band counts among surviving cases: "
            + ", ".join(f"`{k}` bands = `{v}`" for k, v in sorted(genre_band_counts.items()))
            + "\n"
        )
        handle.write(
            f"- Dominant genre among survivors: `{genre_counts.most_common(1)[0][0]}` "
            f"with `{genre_counts.most_common(1)[0][1]}` cases\n\n"
        )

        handle.write("## Broad scene cases\n\n")
        handle.write("| City | Genre | Lead | Label-year active bands | Total city bands |\n")
        handle.write("|------|-------|------|--------------------------|------------------|\n")
        for row in rows:
            if row["case_bucket"] != "broad_scene_case":
                continue
            handle.write(
                f"| {row['city_country']} | {row['genre_family']} | {row['lead_years']} | "
                f"{row['label_year_active_bands']} | {row['n_bands_total']} |\n"
            )

        handle.write("\n## Fragile cases\n\n")
        handle.write("| City | Genre | Lead | Fragility reason |\n")
        handle.write("|------|-------|------|------------------|\n")
        for row in rows:
            if row["case_bucket"] != "fragile_case":
                continue
            handle.write(
                f"| {row['city_country']} | {row['genre_family']} | {row['lead_years']} | "
                f"{row['fragility_reason'] or 'n/a'} |\n"
            )

        handle.write("\n## All surviving cases\n\n")
        handle.write("| City | Genre | Lead | Bucket |\n")
        handle.write("|------|-------|------|--------|\n")
        for row in rows:
            handle.write(
                f"| {row['city_country']} | {row['genre_family']} | {row['lead_years']} | "
                f"{row['case_bucket']} |\n"
            )


def main() -> None:
    city_audit = load_city_audit()
    rows = load_surviving_cases(city_audit)
    write_csv(rows)
    write_md(rows)


if __name__ == "__main__":
    main()
