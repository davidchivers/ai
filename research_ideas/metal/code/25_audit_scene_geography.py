"""
25_audit_scene_geography.py

Audit city labels in the metal scene-network branch and build a reusable
baseline exclusion file for awkward geography units.

Outputs:
    data/processed/scene_networks/city_geography_audit.csv
    data/processed/scene_networks/city_geography_audit_summary.md
    data/processed/scene_networks/region_like_scene_units.csv
    data/processed/scene_networks/region_like_scene_units.md

Usage:
    python code/25_audit_scene_geography.py
"""

from __future__ import annotations

import csv
import os
import re
import unicodedata
from collections import defaultdict


DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "processed", "scene_networks")
NETWORK_FILE = os.path.join(DATA_DIR, "city_network_stats.csv")
SNAPSHOT_FILE = os.path.join(DATA_DIR, "city_year_network_snapshots.csv")
TIMING_FILE = os.path.join(DATA_DIR, "community_vs_label_timing.csv")
OUT_AUDIT = os.path.join(DATA_DIR, "city_geography_audit.csv")
OUT_SUMMARY = os.path.join(DATA_DIR, "city_geography_audit_summary.md")
OUT_REGION_UNITS = os.path.join(DATA_DIR, "region_like_scene_units.csv")
OUT_REGION_SUMMARY = os.path.join(DATA_DIR, "region_like_scene_units.md")


ADMIN_KEYWORDS = {
    "province",
    "state",
    "region",
    "oblast",
    "county",
    "prefecture",
    "municipality",
    "district",
    "comarca",
    "territory",
}

KNOWN_ADMIN_LABELS = {
    "alabama",
    "alaska",
    "aargau",
    "arizona",
    "arkansas",
    "baden wurttemberg",
    "basque country",
    "bavaria",
    "brandenburg",
    "british columbia",
    "brittany",
    "catalonia",
    "california",
    "connecticut",
    "colorado",
    "devon",
    "florida",
    "galicia",
    "georgia",
    "gotland",
    "hesse",
    "idaho",
    "illinois",
    "indiana",
    "iowa",
    "kansas",
    "kentucky",
    "lower saxony",
    "lower austria",
    "louisiana",
    "maine",
    "maryland",
    "massachusetts",
    "mecklenburg vorpommern",
    "michigan",
    "minnesota",
    "mississippi",
    "missouri",
    "montana",
    "new england",
    "new hampshire",
    "new jersey",
    "new south wales",
    "nebraska",
    "nevada",
    "new mexico",
    "north holland",
    "north brabant",
    "north carolina",
    "north rhine westphalia",
    "nova scotia",
    "ohio",
    "ontario",
    "occitanie",
    "oklahoma",
    "orange county",
    "oregon",
    "pennsylvania",
    "prince edward island",
    "provence alpes cote d azur",
    "rhineland palatinate",
    "saarland",
    "saxony anhalt",
    "schleswig holstein",
    "sicily",
    "south carolina",
    "south wales",
    "state of mexico",
    "tasmania",
    "tennessee",
    "texas",
    "thuringia",
    "tuscany",
    "tyrol",
    "utrecht province",
    "utah",
    "veneto",
    "virginia",
    "washington",
    "wales",
    "west flanders",
    "west midlands",
    "west virginia",
    "west yorkshire",
    "westchester county",
    "wisconsin",
    "wyoming",
    "ile de france",
    "saxony",
    "south holland",
    "buenos aires province",
    "bay area",
    "transylvania",
}

KNOWN_ADMIN_EXACT_EXCEPTIONS = {
    ("ontario", "united states"),
}


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


def normalize_key(text: str) -> str:
    text = text or ""
    text = text.lower()
    text = (
        unicodedata.normalize("NFKD", text)
        .encode("ascii", "ignore")
        .decode("ascii")
    )
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return " ".join(text.split())


def city_flags(city: str, country: str) -> dict[str, int]:
    norm = normalize_key(city)
    country_norm = normalize_key(country)
    tokens = set(norm.split())

    has_admin_keyword = int(bool(tokens & ADMIN_KEYWORDS))
    exact_admin_label = int(
        norm in KNOWN_ADMIN_LABELS
        and (norm, country_norm) not in KNOWN_ADMIN_EXACT_EXCEPTIONS
    )
    has_slash = int("/" in city)
    has_na = int(norm in {"n a", "na"} or city.strip().upper() == "N/A")
    has_parentheses = int("(" in city or ")" in city)
    looks_multi_place = int(" / " in city or ";" in city)

    return {
        "flag_admin_keyword_i": has_admin_keyword,
        "flag_exact_admin_label_i": exact_admin_label,
        "flag_slash_i": has_slash,
        "flag_na_i": has_na,
        "flag_parentheses_i": has_parentheses,
        "flag_multi_place_i": looks_multi_place,
    }


def classify_unit(flags: dict[str, int]) -> dict[str, object]:
    region_like_i = int(flags["flag_admin_keyword_i"] or flags["flag_exact_admin_label_i"])
    malformed_label_i = int(flags["flag_na_i"] or flags["flag_slash_i"] or flags["flag_multi_place_i"])

    if malformed_label_i:
        unit_type = "missing_or_multi_place"
    elif region_like_i:
        unit_type = "region_like"
    else:
        unit_type = "city_like"

    return {
        "region_like_i": region_like_i,
        "malformed_label_i": malformed_label_i,
        "unit_type": unit_type,
        "exclude_bad_label_only_i": malformed_label_i,
        "exclude_city_baseline_i": int(region_like_i or malformed_label_i),
        # Keep the legacy column name because 24_test_community_precedes_label.py
        # already consumes it and older docs reference it.
        "exclude_baseline_i": int(region_like_i or malformed_label_i),
    }


def merge_city_row(
    rows: dict[str, dict[str, object]],
    city_country: str,
    city: str,
    country: str,
    n_bands: int,
    density: float,
    bridge_pct: float,
) -> None:
    current = rows.get(city_country)
    if current is None:
        rows[city_country] = {
            "city": city,
            "country": country,
            "n_bands": n_bands,
            "density": density,
            "bridge_pct": bridge_pct,
        }
        return

    current["city"] = current["city"] or city
    current["country"] = current["country"] or country
    current["n_bands"] = max(int(current["n_bands"]), n_bands)
    current["density"] = max(float(current["density"]), density)
    current["bridge_pct"] = max(float(current["bridge_pct"]), bridge_pct)


def load_city_universe() -> dict[str, dict[str, object]]:
    rows = {}
    if os.path.exists(NETWORK_FILE):
        with open(NETWORK_FILE, "r", encoding="utf-8", newline="") as handle:
            for row in csv.DictReader(handle):
                merge_city_row(
                    rows=rows,
                    city_country=row["city_country"].strip(),
                    city=row["city"].strip(),
                    country=row["country"].strip(),
                    n_bands=safe_int(row["n_bands"]),
                    density=safe_float(row["density"]),
                    bridge_pct=safe_float(row["bridge_pct"]),
                )

    if os.path.exists(SNAPSHOT_FILE):
        with open(SNAPSHOT_FILE, "r", encoding="utf-8", newline="") as handle:
            for row in csv.DictReader(handle):
                merge_city_row(
                    rows=rows,
                    city_country=row["city_country"].strip(),
                    city=row["city"].strip(),
                    country=row["country"].strip(),
                    n_bands=safe_int(row.get("n_active_bands")),
                    density=safe_float(row.get("density")),
                    bridge_pct=safe_float(row.get("bridge_pct")),
                )
    return rows


def load_timing_summary() -> dict[str, dict[str, object]]:
    summary: dict[str, dict[str, object]] = defaultdict(
        lambda: {
            "timing_rows": 0,
            "precedes_rows": 0,
            "same_year_rows": 0,
            "undetected_rows": 0,
            "max_lead_years": 0,
        }
    )

    with open(TIMING_FILE, "r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            city_country = row["city_country"].strip()
            summary[city_country]["timing_rows"] += 1
            status = row["timing_status"].strip()
            if status == "community_precedes_label":
                summary[city_country]["precedes_rows"] += 1
                summary[city_country]["max_lead_years"] = max(
                    summary[city_country]["max_lead_years"],
                    safe_int(row["lead_years"]),
                )
            elif status == "community_same_year_as_label":
                summary[city_country]["same_year_rows"] += 1
            elif status == "community_not_detected_by_label":
                summary[city_country]["undetected_rows"] += 1

    return summary


def main() -> None:
    network = load_city_universe()
    timing = load_timing_summary()

    audit_rows = []
    for city_country, network_row in sorted(network.items()):
        city = network_row["city"]
        flags = city_flags(city, str(network_row["country"]))
        unit_meta = classify_unit(flags)
        small_dense = int(network_row["n_bands"] <= 20 and network_row["density"] >= 0.50)

        timing_row = timing.get(city_country, {})
        audit_rows.append(
            {
                "city": city,
                "country": network_row["country"],
                "city_country": city_country,
                "n_bands": network_row["n_bands"],
                "density": f"{network_row['density']:.6f}",
                "bridge_pct": f"{network_row['bridge_pct']:.3f}",
                **flags,
                **unit_meta,
                "flag_small_dense_i": small_dense,
                "timing_rows": timing_row.get("timing_rows", 0),
                "precedes_rows": timing_row.get("precedes_rows", 0),
                "same_year_rows": timing_row.get("same_year_rows", 0),
                "undetected_rows": timing_row.get("undetected_rows", 0),
                "max_lead_years": timing_row.get("max_lead_years", 0),
            }
        )

    with open(OUT_AUDIT, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "city",
                "country",
                "city_country",
                "n_bands",
                "density",
                "bridge_pct",
                "flag_admin_keyword_i",
                "flag_exact_admin_label_i",
                "flag_slash_i",
                "flag_na_i",
                "flag_parentheses_i",
                "flag_multi_place_i",
                "region_like_i",
                "malformed_label_i",
                "unit_type",
                "exclude_bad_label_only_i",
                "exclude_city_baseline_i",
                "flag_small_dense_i",
                "timing_rows",
                "precedes_rows",
                "same_year_rows",
                "undetected_rows",
                "max_lead_years",
                "exclude_baseline_i",
            ],
        )
        writer.writeheader()
        writer.writerows(audit_rows)

    region_like_rows = [row for row in audit_rows if row["region_like_i"] == 1]
    malformed_rows = [row for row in audit_rows if row["malformed_label_i"] == 1]
    excluded = [row for row in audit_rows if row["exclude_city_baseline_i"] == 1]
    region_like_sorted = sorted(
        region_like_rows,
        key=lambda row: (
            row["precedes_rows"],
            row["timing_rows"],
            row["n_bands"],
            row["city_country"],
        ),
        reverse=True,
    )
    malformed_sorted = sorted(
        malformed_rows,
        key=lambda row: (
            row["precedes_rows"],
            row["timing_rows"],
            row["n_bands"],
            row["city_country"],
        ),
        reverse=True,
    )
    dense_small = sorted(
        [row for row in audit_rows if row["flag_small_dense_i"] == 1],
        key=lambda row: (float(row["density"]), row["n_bands"], row["city_country"]),
        reverse=True,
    )

    with open(OUT_SUMMARY, "w", encoding="utf-8") as handle:
        handle.write("# Scene geography audit\n\n")
        handle.write(
            "- Audit universe: union of `city_network_stats.csv` and "
            "`city_year_network_snapshots.csv`\n"
        )
        handle.write(f"- Cities in audit universe: `{len(audit_rows)}`\n")
        handle.write(f"- `region_like` labels: `{len(region_like_rows)}`\n")
        handle.write(f"- `missing_or_multi_place` labels: `{len(malformed_rows)}`\n")
        handle.write(f"- City-baseline exclusions: `{len(excluded)}`\n")
        handle.write(
            f"- Small-city high-density flags (`n_bands <= 20`, `density >= 0.50`): "
            f"`{sum(row['flag_small_dense_i'] for row in audit_rows)}`\n\n"
        )

        handle.write("## Unit logic\n\n")
        handle.write("- `city_like`: usable in the city baseline\n")
        handle.write("- `region_like`: keep conceptually, but treat as a separate wider-unit object\n")
        handle.write("- `missing_or_multi_place`: malformed labels that should stay out of both baselines\n\n")

        handle.write("## Highest-impact region-like labels\n\n")
        handle.write("| City | Country | Bands | Precedes rows | Timing rows | Max lead |\n")
        handle.write("|------|---------|-------|---------------|-------------|----------|\n")
        for row in region_like_sorted[:40]:
            handle.write(
                f"| {row['city']} | {row['country']} | {row['n_bands']} | "
                f"{row['precedes_rows']} | {row['timing_rows']} | {row['max_lead_years']} |\n"
            )

        handle.write("\n## Highest-impact malformed labels\n\n")
        handle.write("| City | Country | Bands | Timing rows |\n")
        handle.write("|------|---------|-------|-------------|\n")
        for row in malformed_sorted[:25]:
            handle.write(
                f"| {row['city']} | {row['country']} | {row['n_bands']} | "
                f"{row['timing_rows']} |\n"
            )

        handle.write("\n## Small high-density labels to inspect separately\n\n")
        handle.write("| City | Country | Bands | Density | Precedes rows |\n")
        handle.write("|------|---------|-------|---------|---------------|\n")
        for row in dense_small[:40]:
            handle.write(
                f"| {row['city']} | {row['country']} | {row['n_bands']} | "
                f"{float(row['density']):.3f} | {row['precedes_rows']} |\n"
            )

    with open(OUT_REGION_UNITS, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "city",
                "country",
                "city_country",
                "unit_type",
                "n_bands",
                "density",
                "bridge_pct",
                "timing_rows",
                "precedes_rows",
                "same_year_rows",
                "undetected_rows",
                "max_lead_years",
                "flag_admin_keyword_i",
                "flag_exact_admin_label_i",
            ],
        )
        writer.writeheader()
        writer.writerows(
            [
                {
                    key: row[key]
                    for key in [
                        "city",
                        "country",
                        "city_country",
                        "unit_type",
                        "n_bands",
                        "density",
                        "bridge_pct",
                        "timing_rows",
                        "precedes_rows",
                        "same_year_rows",
                        "undetected_rows",
                        "max_lead_years",
                        "flag_admin_keyword_i",
                        "flag_exact_admin_label_i",
                    ]
                }
                for row in region_like_sorted
            ]
        )

    with open(OUT_REGION_SUMMARY, "w", encoding="utf-8") as handle:
        handle.write("# Region-like scene units\n\n")
        handle.write("- Interpretation: these are wider-area labels kept out of the city baseline but retained as a side object\n")
        handle.write(f"- Region-like units in audit universe: `{len(region_like_rows)}`\n")
        handle.write(
            f"- Region-like units with any timing rows in the current file: "
            f"`{sum(int(row['timing_rows']) > 0 for row in region_like_rows)}`\n\n"
        )
        handle.write("| Unit | Country | Bands | Timing rows | Precedes rows | Same-year rows | Max lead |\n")
        handle.write("|------|---------|-------|-------------|---------------|----------------|----------|\n")
        for row in region_like_sorted[:60]:
            handle.write(
                f"| {row['city']} | {row['country']} | {row['n_bands']} | {row['timing_rows']} | "
                f"{row['precedes_rows']} | {row['same_year_rows']} | {row['max_lead_years']} |\n"
            )


if __name__ == "__main__":
    main()
