"""
22_build_genre_emergence.py

For each city, date when each genre tag first appears using the genre strings
from the band data. Produces a city-genre-year panel of first appearances.

Input:
    data/processed/metal_archives_all_metal_band_clean.csv

Outputs:
    data/processed/scene_networks/city_genre_first_appearance.csv
    data/processed/scene_networks/city_genre_emergence_summary.md

Usage:
    python code/22_build_genre_emergence.py [--min-bands 5]
"""

import csv
import os
import re
import argparse
from collections import defaultdict

# --- Config ---
BAND_FILE = os.path.join(os.path.dirname(__file__), "..",
    "data", "processed", "metal_archives_all_metal_band_clean.csv")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..",
    "data", "processed", "scene_networks")

os.makedirs(OUT_DIR, exist_ok=True)

# --- Genre family mapping ---
# Map raw genre fragments to broad families (same as existing project convention)
GENRE_FAMILIES = {
    "black metal": "black_metal",
    "death metal": "death_metal",
    "doom metal": "doom_metal",
    "folk metal": "folk_metal",
    "gothic metal": "gothic_metal",
    "grindcore": "grindcore",
    "groove metal": "groove_metal",
    "heavy metal": "heavy_metal",
    "industrial metal": "industrial_metal",
    "melodic death metal": "melodic_death_metal",
    "metalcore": "metalcore",
    "power metal": "power_metal",
    "progressive metal": "progressive_metal",
    "sludge metal": "sludge_metal",
    "speed metal": "speed_metal",
    "stoner metal": "stoner_metal",
    "symphonic metal": "symphonic_metal",
    "thrash metal": "thrash_metal",
    "viking metal": "viking_metal",
    "post-metal": "post_metal",
    "post-black metal": "post_black_metal",
    "deathcore": "deathcore",
    "nu metal": "nu_metal",
    "drone metal": "drone_metal",
    "avant-garde metal": "avant_garde_metal",
    "technical death metal": "technical_death_metal",
    "brutal death metal": "brutal_death_metal",
    "atmospheric black metal": "atmospheric_black_metal",
    "depressive black metal": "depressive_black_metal",
}

# Sort by length descending so longer matches take priority
GENRE_FAMILY_KEYS = sorted(GENRE_FAMILIES.keys(), key=len, reverse=True)


def extract_city(notes_str):
    """Extract city from notes field."""
    if not notes_str:
        return ""
    m = re.search(r'location=([^;]+)', notes_str)
    if m:
        loc = m.group(1).strip()
        parts = [p.strip() for p in loc.split(',')]
        return parts[0] if parts else ""
    return ""


def parse_genre_families(genre_raw):
    """Extract broad genre families from a raw genre string."""
    if not genre_raw:
        return set()
    g = genre_raw.lower()
    families = set()
    for key in GENRE_FAMILY_KEYS:
        if key in g:
            families.add(GENRE_FAMILIES[key])
    # If nothing matched, try just "metal"
    if not families and "metal" in g:
        families.add("other_metal")
    return families


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--min-bands", type=int, default=5,
                        help="Min bands in a city-genre to count as emergence (default: 5)")
    args = parser.parse_args()

    print("Loading band data...")

    # city_country -> genre_family -> list of formed_years
    city_genre_years = defaultdict(lambda: defaultdict(list))
    # Also track city-level counts
    city_band_count = defaultdict(int)

    with open(BAND_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            city = extract_city(row.get("notes", ""))
            country = row.get("country_std", "").strip()
            formed = row.get("formed_year", "").strip()

            if not city or not formed:
                continue
            try:
                yr = int(formed)
            except ValueError:
                continue

            city_country = f"{city}, {country}" if country else city
            city_band_count[city_country] += 1

            families = parse_genre_families(row.get("genre_raw", ""))
            for fam in families:
                city_genre_years[city_country][fam].append(yr)

    print(f"  Cities with bands: {len(city_band_count)}")
    print(f"  City-genre combinations: {sum(len(v) for v in city_genre_years.values())}")

    # --- Build first-appearance panel ---
    rows = []
    for city_country in sorted(city_genre_years.keys()):
        city_name = city_country.split(", ")[0] if ", " in city_country else city_country
        country = city_country.split(", ")[-1] if ", " in city_country else ""

        for genre_fam, years in sorted(city_genre_years[city_country].items()):
            years_sorted = sorted(years)
            first_year = years_sorted[0]
            total_bands = len(years_sorted)

            # Year when Nth band appears (threshold for "emergence")
            emergence_year = years_sorted[args.min_bands - 1] if len(years_sorted) >= args.min_bands else None

            # Growth trajectory: bands by 5-year windows
            bands_by_5yr = defaultdict(int)
            for y in years_sorted:
                window = (y // 5) * 5
                bands_by_5yr[window] += 1

            # Peak 5-year window
            peak_window = max(bands_by_5yr.items(), key=lambda x: x[1]) if bands_by_5yr else (None, 0)

            rows.append({
                "city": city_name,
                "country": country,
                "city_country": city_country,
                "genre_family": genre_fam,
                "first_band_year": first_year,
                "emergence_year": emergence_year if emergence_year else "",
                "total_bands": total_bands,
                "peak_5yr_window": peak_window[0] if peak_window[0] else "",
                "peak_5yr_count": peak_window[1],
                "total_city_bands": city_band_count[city_country],
            })

    # --- Write first-appearance CSV ---
    out_csv = os.path.join(OUT_DIR, "city_genre_first_appearance.csv")
    print(f"Writing {out_csv}...")
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "city", "country", "city_country", "genre_family",
            "first_band_year", "emergence_year", "total_bands",
            "peak_5yr_window", "peak_5yr_count", "total_city_bands",
        ])
        writer.writeheader()
        writer.writerows(rows)

    # --- Write summary ---
    out_summary = os.path.join(OUT_DIR, "city_genre_emergence_summary.md")
    print(f"Writing {out_summary}...")

    # Find notable genre emergences
    emerged = [r for r in rows if r["emergence_year"]]
    emerged_sorted = sorted(emerged, key=lambda x: (x["emergence_year"], x["city_country"]))

    with open(out_summary, "w", encoding="utf-8") as f:
        f.write("# City-Genre Emergence Panel\n\n")
        f.write(f"Emergence threshold: {args.min_bands} bands in city-genre cell\n")
        f.write(f"Total city-genre rows: {len(rows)}\n")
        f.write(f"City-genre cells reaching emergence: {len(emerged)}\n\n")

        f.write("## Earliest genre emergences (first 50)\n\n")
        f.write("| City | Country | Genre | First Band | Emergence Year | Total Bands |\n")
        f.write("|------|---------|-------|-----------|----------------|-------------|\n")
        for r in emerged_sorted[:50]:
            f.write(f"| {r['city']} | {r['country']} | {r['genre_family']} | "
                    f"{r['first_band_year']} | {r['emergence_year']} | {r['total_bands']} |\n")

        # Genre emergence counts by decade
        f.write("\n## Genre emergences by decade\n\n")
        decade_counts = defaultdict(int)
        for r in emerged:
            decade = (int(r["emergence_year"]) // 10) * 10
            decade_counts[decade] += 1
        for d in sorted(decade_counts.keys()):
            f.write(f"- {d}s: {decade_counts[d]}\n")

    print(f"Done. {len(rows)} city-genre rows, {len(emerged)} reaching emergence threshold.")


if __name__ == "__main__":
    main()
