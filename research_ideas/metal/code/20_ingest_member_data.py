"""
20_ingest_member_data.py

Ingest the Metal Archives member or lineup dump and produce a clean
musician-band edge list ready for network construction.

Supported input schemas:
    Current delivered schema:
        band_id, person_id, member_name, current_member,
        role_description, date_from, date_to

    Older fallback schema:
        band_id, member_id, member_name, role, years_active

Outputs:
    data/processed/scene_networks/full_musician_band_edges.csv
    data/processed/scene_networks/full_member_ingest_summary.md

Usage:
    python code/20_ingest_member_data.py <path_to_member_dump.csv>
    python code/20_ingest_member_data.py <path_to_member_dump.zip>
"""

import csv
import os
import re
import sys
import zipfile
from collections import defaultdict


BAND_FILE = os.path.join(
    os.path.dirname(__file__),
    "..",
    "data",
    "processed",
    "metal_archives_all_metal_band_clean.csv",
)
OUT_DIR = os.path.join(
    os.path.dirname(__file__),
    "..",
    "data",
    "processed",
    "scene_networks",
)
OUT_EDGES = os.path.join(OUT_DIR, "full_musician_band_edges.csv")
OUT_SUMMARY = os.path.join(OUT_DIR, "full_member_ingest_summary.md")

os.makedirs(OUT_DIR, exist_ok=True)


def normalize_text(value):
    return value.strip() if value else ""


def extract_year(value):
    """Extract a 4-digit year from values like '1990' or '1990-01-01'."""
    value = normalize_text(value)
    if not value:
        return None
    match = re.search(r"(19|20)\d{2}", value)
    if match:
        return int(match.group(0))
    return None


def parse_years(years_str):
    """Parse older years_active strings like '1988-1993, 2004-present'."""
    years_str = normalize_text(years_str)
    if years_str in ("", "N/A", "?"):
        return []

    stints = []
    for part in years_str.split(","):
        part = part.strip()
        match = re.match(r"(\d{4})\s*[-\u2013]\s*(\d{4}|present|\?)", part, re.IGNORECASE)
        if match:
            start = int(match.group(1))
            end_str = match.group(2).lower()
            end = None if end_str in ("present", "?") else int(end_str)
            stints.append((start, end))
            continue

        match = re.match(r"(\d{4})", part)
        if match:
            year = int(match.group(1))
            stints.append((year, year))

    return stints


def extract_city(notes_str):
    """Extract city from notes field like 'location=Tampa, Florida; status=...'."""
    notes_str = normalize_text(notes_str)
    if not notes_str:
        return ""
    match = re.search(r"location=([^;]+)", notes_str)
    if match:
        loc = match.group(1).strip()
        parts = [part.strip() for part in loc.split(",")]
        return parts[0] if parts else ""
    return ""


def open_member_reader(member_file):
    """Return (reader, fieldnames, handle) for CSV or ZIP input."""
    lower = member_file.lower()

    if lower.endswith(".zip"):
        archive = zipfile.ZipFile(member_file, "r")
        csv_names = [name for name in archive.namelist() if name.lower().endswith(".csv")]
        if not csv_names:
            archive.close()
            raise ValueError(f"No CSV found inside archive: {member_file}")

        entry_name = csv_names[0]
        raw_handle = archive.open(entry_name, "r")
        reader = csv.DictReader(
            (line.decode("utf-8-sig", errors="replace") for line in raw_handle)
        )
        return reader, reader.fieldnames, (raw_handle, archive)

    text_handle = open(member_file, "r", encoding="utf-8-sig", newline="")
    reader = csv.DictReader(text_handle)
    return reader, reader.fieldnames, text_handle


def close_member_reader(handle):
    if isinstance(handle, tuple):
        raw_handle, archive = handle
        raw_handle.close()
        archive.close()
    else:
        handle.close()


def detect_columns(fieldnames):
    mapping = {
        "band_id": None,
        "member_id": None,
        "member_name": None,
        "role": None,
        "years_active": None,
        "current_member": None,
        "date_from": None,
        "date_to": None,
    }

    for col in fieldnames or []:
        cl = col.lower().strip()
        if cl in ("band_id", "bandid", "source_id_primary"):
            mapping["band_id"] = col
        elif cl in ("member_id", "memberid", "artist_id", "artistid", "person_id", "personid"):
            mapping["member_id"] = col
        elif cl in ("member_name", "membername", "artist_name", "artistname", "name"):
            mapping["member_name"] = col
        elif cl in ("role", "instrument", "instruments", "role_description"):
            mapping["role"] = col
        elif cl in ("years_active", "yearsactive", "years", "period"):
            mapping["years_active"] = col
        elif cl in ("current_member", "currentmember"):
            mapping["current_member"] = col
        elif cl in ("date_from", "start_date", "from_date"):
            mapping["date_from"] = col
        elif cl in ("date_to", "end_date", "to_date"):
            mapping["date_to"] = col

    return mapping


def main():
    if len(sys.argv) < 2:
        print("Usage: python code/20_ingest_member_data.py <path_to_member_dump.csv|zip>")
        sys.exit(1)

    member_file = sys.argv[1]

    print("Loading band reference file...")
    band_ref = {}
    with open(BAND_FILE, "r", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            band_id = normalize_text(row.get("source_id_primary", ""))
            if not band_id:
                continue
            band_ref[band_id] = {
                "band_name": normalize_text(row.get("band_name_raw", "")),
                "country": normalize_text(row.get("country_std", "")),
                "countryiso3code": normalize_text(row.get("countryiso3code", "")),
                "city": extract_city(row.get("notes", "")),
                "formed_year": normalize_text(row.get("formed_year", "")),
                "genre_raw": normalize_text(row.get("genre_raw", "")),
            }
    print(f"  Loaded {len(band_ref)} bands from reference file.")

    print(f"Reading member dump from {member_file}...")
    raw_rows = 0
    duplicate_rows_collapsed = 0
    matched_bands = set()
    unmatched_bands = set()
    grouped = {}

    reader, fieldnames, handle = open_member_reader(member_file)
    try:
        mapping = detect_columns(fieldnames)
        bid_col = mapping["band_id"]
        mid_col = mapping["member_id"]
        mname_col = mapping["member_name"]
        role_col = mapping["role"]
        years_col = mapping["years_active"]
        current_col = mapping["current_member"]
        date_from_col = mapping["date_from"]
        date_to_col = mapping["date_to"]

        if not bid_col:
            print(f"ERROR: Cannot find band_id column. Available: {fieldnames}")
            sys.exit(1)
        if not mname_col and not mid_col:
            print(f"ERROR: Cannot find member_name or member_id column. Available: {fieldnames}")
            sys.exit(1)

        schema_mode = "role_level_dates" if (date_from_col or date_to_col or current_col) else "years_active"

        print(
            "  Column mapping: "
            f"band_id={bid_col}, member_id={mid_col}, member_name={mname_col}, "
            f"role={role_col}, years_active={years_col}, current_member={current_col}, "
            f"date_from={date_from_col}, date_to={date_to_col}"
        )

        for row in reader:
            raw_rows += 1

            band_id = normalize_text(row.get(bid_col, ""))
            member_id = normalize_text(row.get(mid_col, "")) if mid_col else ""
            member_name = normalize_text(row.get(mname_col, "")) if mname_col else ""
            role = normalize_text(row.get(role_col, "")) if role_col else ""
            years_active = normalize_text(row.get(years_col, "")) if years_col else ""
            current_member = normalize_text(row.get(current_col, "")) if current_col else ""
            date_from = normalize_text(row.get(date_from_col, "")) if date_from_col else ""
            date_to = normalize_text(row.get(date_to_col, "")) if date_to_col else ""

            person_key = member_id if member_id else member_name
            if not band_id or not person_key:
                continue

            ref = band_ref.get(band_id)
            if ref:
                matched_bands.add(band_id)
            else:
                unmatched_bands.add(band_id)

            key = (band_id, person_key)
            if key in grouped:
                duplicate_rows_collapsed += 1
            if key not in grouped:
                grouped[key] = {
                    "band_id": band_id,
                    "member_id": member_id,
                    "member_names": set(),
                    "roles": set(),
                    "years_active_raw_values": set(),
                    "row_count": 0,
                    "current_member_values": set(),
                    "first_year_candidates": [],
                    "last_year_candidates": [],
                    "has_ongoing_role": False,
                    "has_unknown_past_end": False,
                    "band_name": ref["band_name"] if ref else "",
                    "country": ref["country"] if ref else "",
                    "countryiso3code": ref["countryiso3code"] if ref else "",
                    "city": ref["city"] if ref else "",
                    "formed_year": ref["formed_year"] if ref else "",
                    "genre_raw": ref["genre_raw"] if ref else "",
                }

            group = grouped[key]
            group["row_count"] += 1
            if member_name:
                group["member_names"].add(member_name)
            if role:
                group["roles"].add(role)
            if current_member:
                group["current_member_values"].add(current_member)

            if schema_mode == "years_active":
                if years_active:
                    group["years_active_raw_values"].add(years_active)
                for start_year, end_year in parse_years(years_active):
                    if start_year is not None:
                        group["first_year_candidates"].append(start_year)
                    if end_year is not None:
                        group["last_year_candidates"].append(end_year)
                    elif years_active:
                        group["has_ongoing_role"] = True
            else:
                span_bits = [role or "role_unknown", date_from or "?", date_to or "?"]
                group["years_active_raw_values"].add(" / ".join(span_bits))

                start_year = extract_year(date_from)
                end_year = extract_year(date_to)
                if start_year is not None:
                    group["first_year_candidates"].append(start_year)
                if end_year is not None:
                    group["last_year_candidates"].append(end_year)
                elif current_member == "1":
                    group["has_ongoing_role"] = True
                elif current_member == "0" and not date_to:
                    group["has_unknown_past_end"] = True

        edges = []
        for group in grouped.values():
            first_year = (
                str(min(group["first_year_candidates"]))
                if group["first_year_candidates"] else ""
            )
            if group["has_ongoing_role"] or group["has_unknown_past_end"]:
                last_year = ""
            elif group["last_year_candidates"]:
                last_year = str(max(group["last_year_candidates"]))
            else:
                last_year = ""

            member_name = "; ".join(sorted(group["member_names"])) if group["member_names"] else ""
            roles = "; ".join(sorted(group["roles"])) if group["roles"] else ""
            years_active_raw = " | ".join(sorted(group["years_active_raw_values"]))
            current_member = (
                "1" if "1" in group["current_member_values"]
                else ("0" if "0" in group["current_member_values"] else "")
            )

            edges.append({
                "band_id": group["band_id"],
                "member_id": group["member_id"],
                "member_name": member_name,
                "role": roles,
                "years_active_raw": years_active_raw,
                "current_member": current_member,
                "role_rows_ct": group["row_count"],
                "first_year_in_band": first_year,
                "last_year_in_band": last_year,
                "band_name": group["band_name"],
                "country": group["country"],
                "countryiso3code": group["countryiso3code"],
                "city": group["city"],
                "formed_year": group["formed_year"],
                "genre_raw": group["genre_raw"],
            })
    finally:
        close_member_reader(handle)

    print(f"  Read {raw_rows} raw member-role rows.")
    print(f"  Collapsed to {len(edges)} unique member-band edges.")
    print(f"  Matched bands: {len(matched_bands)}")
    print(f"  Unmatched bands: {len(unmatched_bands)}")

    print(f"Writing {OUT_EDGES}...")
    with open(OUT_EDGES, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "band_id",
                "member_id",
                "member_name",
                "role",
                "years_active_raw",
                "current_member",
                "role_rows_ct",
                "first_year_in_band",
                "last_year_in_band",
                "band_name",
                "country",
                "countryiso3code",
                "city",
                "formed_year",
                "genre_raw",
            ],
        )
        writer.writeheader()
        writer.writerows(edges)

    unique_musicians = set()
    musician_band_counts = defaultdict(set)
    for edge in edges:
        musician_key = edge["member_id"] if edge["member_id"] else edge["member_name"]
        unique_musicians.add(musician_key)
        musician_band_counts[musician_key].add(edge["band_id"])

    multi_band = sum(1 for bands in musician_band_counts.values() if len(bands) >= 2)
    multi_band_pct = 100 * multi_band / len(unique_musicians) if unique_musicians else 0.0

    print(f"Writing {OUT_SUMMARY}...")
    with open(OUT_SUMMARY, "w", encoding="utf-8") as handle:
        handle.write("# Metal Archives Member Data Ingest Summary\n\n")
        handle.write("Date: 2026-03-26\n\n")
        handle.write("## Counts\n\n")
        handle.write(f"- Raw member-role rows: {raw_rows}\n")
        handle.write(f"- Unique member-band edges: {len(edges)}\n")
        handle.write(f"- Collapsed duplicate role rows: {duplicate_rows_collapsed}\n")
        handle.write(f"- Unique musicians: {len(unique_musicians)}\n")
        handle.write(f"- Matched bands (in band reference): {len(matched_bands)}\n")
        handle.write(f"- Unmatched bands: {len(unmatched_bands)}\n")
        handle.write(f"- Musicians in 2+ bands: {multi_band} ({multi_band_pct:.1f}%)\n\n")

        handle.write("## Ingest mode\n\n")
        handle.write(f"- Detected schema mode: `{schema_mode}`\n")
        if schema_mode == "role_level_dates":
            handle.write("- Role-level rows were collapsed to one edge per `band_id x member_id`\n")
            handle.write("- `first_year_in_band` is the earliest known `date_from`\n")
            handle.write("- `last_year_in_band` is blank for ongoing or unknown-ended memberships\n\n")
        else:
            handle.write("- Parsed older `years_active` strings directly\n\n")

        handle.write("## Column mapping\n\n")
        handle.write(f"- band_id: `{bid_col}`\n")
        handle.write(f"- member_id: `{mid_col}`\n")
        handle.write(f"- member_name: `{mname_col}`\n")
        handle.write(f"- role: `{role_col}`\n")
        handle.write(f"- years_active: `{years_col}`\n")
        handle.write(f"- current_member: `{current_col}`\n")
        handle.write(f"- date_from: `{date_from_col}`\n")
        handle.write(f"- date_to: `{date_to_col}`\n")

    print("Done.")


if __name__ == "__main__":
    main()
