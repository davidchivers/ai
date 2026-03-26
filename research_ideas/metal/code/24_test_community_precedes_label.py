"""
24_test_community_precedes_label.py

Test whether scene-network communities are detectable before a city's
genre-family cell crosses the current Metallum emergence threshold.

Full mode builds lagged city-year snapshots from:
    - band formed years
    - musician first_year_in_band
    - musician last_year_in_band

It then:
    1. Detects communities in each city-year snapshot.
    2. Flags genre-supporting communities when a community contains
       enough bands from the same broad genre family and that family
       occupies a large enough share of the community.
    3. Compares the first such community year to the current
       `emergence_year` proxy in `city_genre_first_appearance.csv`.

Inputs:
    data/processed/scene_networks/full_musician_band_edges.csv
    data/processed/scene_networks/city_genre_first_appearance.csv
    data/processed/metal_archives_all_metal_band_clean.csv

Outputs:
    data/processed/scene_networks/city_year_network_snapshots.csv
    data/processed/scene_networks/community_vs_label_timing.csv
    data/processed/scene_networks/community_vs_label_results.md

Usage:
    python code/24_test_community_precedes_label.py
    python code/24_test_community_precedes_label.py --city-filter "tampa"
    python code/24_test_community_precedes_label.py --pilot
"""

import argparse
import csv
import os
import re
from collections import defaultdict, deque


DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "processed", "scene_networks")
BAND_FILE = os.path.join(
    os.path.dirname(__file__), "..", "data", "processed", "metal_archives_all_metal_band_clean.csv"
)
GENRE_FILE = os.path.join(DATA_DIR, "city_genre_first_appearance.csv")
DEFAULT_INPUT = os.path.join(DATA_DIR, "full_musician_band_edges.csv")

OUT_SNAPSHOTS = os.path.join(DATA_DIR, "city_year_network_snapshots.csv")
OUT_TIMING = os.path.join(DATA_DIR, "community_vs_label_timing.csv")
OUT_RESULTS = os.path.join(DATA_DIR, "community_vs_label_results.md")

os.makedirs(DATA_DIR, exist_ok=True)


GENRE_FAMILIES = {
    "atmospheric black metal": "atmospheric_black_metal",
    "avant-garde metal": "avant_garde_metal",
    "brutal death metal": "brutal_death_metal",
    "depressive black metal": "depressive_black_metal",
    "melodic death metal": "melodic_death_metal",
    "technical death metal": "technical_death_metal",
    "black metal": "black_metal",
    "death metal": "death_metal",
    "doom metal": "doom_metal",
    "drone metal": "drone_metal",
    "folk metal": "folk_metal",
    "gothic metal": "gothic_metal",
    "grindcore": "grindcore",
    "groove metal": "groove_metal",
    "heavy metal": "heavy_metal",
    "industrial metal": "industrial_metal",
    "metalcore": "metalcore",
    "nu metal": "nu_metal",
    "post-black metal": "post_black_metal",
    "post-metal": "post_metal",
    "power metal": "power_metal",
    "progressive metal": "progressive_metal",
    "sludge metal": "sludge_metal",
    "speed metal": "speed_metal",
    "stoner metal": "stoner_metal",
    "symphonic metal": "symphonic_metal",
    "thrash metal": "thrash_metal",
    "viking metal": "viking_metal",
    "deathcore": "deathcore",
}
GENRE_FAMILY_KEYS = sorted(GENRE_FAMILIES.keys(), key=len, reverse=True)


def safe_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def normalize_text(value):
    return value.strip() if value else ""


def safe_console_text(value):
    return normalize_text(value).encode("ascii", errors="replace").decode("ascii")


def extract_city(notes_str):
    notes_str = normalize_text(notes_str)
    if not notes_str:
        return ""
    match = re.search(r"location=([^;]+)", notes_str)
    if not match:
        return ""
    location = match.group(1).strip()
    parts = [part.strip() for part in location.split(",")]
    return parts[0] if parts else ""


def normalize_city_country(city, country):
    city = normalize_text(city)
    country = normalize_text(country)
    if not city:
        return ""
    return f"{city}, {country}" if country else city


def parse_genre_families(genre_raw):
    genre_raw = normalize_text(genre_raw).lower()
    if not genre_raw:
        return set()
    families = set()
    for key in GENRE_FAMILY_KEYS:
        if key in genre_raw:
            families.add(GENRE_FAMILIES[key])
    if not families and "metal" in genre_raw:
        families.add("other_metal")
    return families


def build_adjacency(bands, edges):
    adjacency = {band: set() for band in bands}
    for band_a, band_b in edges:
        if band_a in adjacency and band_b in adjacency:
            adjacency[band_a].add(band_b)
            adjacency[band_b].add(band_a)
    return adjacency


def modularity_from_partition(adjacency, communities, edge_count):
    if edge_count == 0:
        return 0.0

    total = 0.0
    for members in communities.values():
        member_list = list(members)
        for idx, band_i in enumerate(member_list):
            for band_j in member_list[idx + 1 :]:
                a_ij = 1.0 if band_j in adjacency.get(band_i, set()) else 0.0
                k_i = len(adjacency.get(band_i, set()))
                k_j = len(adjacency.get(band_j, set()))
                total += a_ij - (k_i * k_j) / (2.0 * edge_count)
    return total / (2.0 * edge_count)


def greedy_modularity(bands, edges):
    if not bands:
        return {}, 0.0
    if not edges:
        return {idx: {band} for idx, band in enumerate(sorted(bands))}, 0.0

    adjacency = build_adjacency(bands, edges)
    edge_count = len(edges)
    band_to_comm = {band: idx for idx, band in enumerate(sorted(bands))}
    communities = {idx: {band} for band, idx in band_to_comm.items()}
    next_id = len(communities)
    best_q = modularity_from_partition(adjacency, communities, edge_count)

    improved = True
    while improved:
        improved = False
        best_merge = None
        best_delta = 0.0

        candidate_pairs = set()
        for band_a, band_b in edges:
            comm_a = band_to_comm.get(band_a)
            comm_b = band_to_comm.get(band_b)
            if comm_a is not None and comm_b is not None and comm_a != comm_b:
                candidate_pairs.add((min(comm_a, comm_b), max(comm_a, comm_b)))

        for comm_a, comm_b in candidate_pairs:
            trial = dict(communities)
            merged = trial[comm_a] | trial[comm_b]
            trial[next_id] = merged
            del trial[comm_a]
            del trial[comm_b]
            trial_q = modularity_from_partition(adjacency, trial, edge_count)
            delta = trial_q - best_q
            if delta > best_delta:
                best_delta = delta
                best_merge = (comm_a, comm_b)

        if best_merge and best_delta > 1e-10:
            comm_a, comm_b = best_merge
            merged = communities[comm_a] | communities[comm_b]
            communities[next_id] = merged
            del communities[comm_a]
            del communities[comm_b]
            for band in merged:
                band_to_comm[band] = next_id
            next_id += 1
            best_q += best_delta
            improved = True

    return communities, best_q


def label_propagation_communities(bands, edges, max_iterations=30):
    if not bands:
        return {}, 0.0

    bands_sorted = sorted(bands)
    if not edges:
        return {band: {band} for band in bands_sorted}, 0.0

    adjacency = build_adjacency(bands, edges)
    labels = {band: band for band in bands_sorted}
    update_order = sorted(bands_sorted, key=lambda band: (-len(adjacency[band]), band))

    for _ in range(max_iterations):
        changed = 0
        for band in update_order:
            neighbours = adjacency.get(band, set())
            if not neighbours:
                continue

            label_counts = defaultdict(int)
            for neighbour in neighbours:
                label_counts[labels[neighbour]] += 1

            max_count = max(label_counts.values())
            best_label = min(
                label for label, count in label_counts.items() if count == max_count
            )
            if labels[band] != best_label:
                labels[band] = best_label
                changed += 1

        if changed == 0:
            break

    communities = defaultdict(set)
    for band, label in labels.items():
        communities[label].add(band)

    modularity_q = modularity_from_partition(adjacency, communities, len(edges))
    return dict(communities), modularity_q


def detect_communities(bands, edges, method):
    if method == "greedy":
        return greedy_modularity(bands, edges)
    return label_propagation_communities(bands, edges)


def largest_component_size(bands, edges):
    if not bands:
        return 0
    adjacency = build_adjacency(bands, edges)
    visited = set()
    best = 0

    for band in bands:
        if band in visited:
            continue
        queue = deque([band])
        size = 0
        while queue:
            current = queue.popleft()
            if current in visited:
                continue
            visited.add(current)
            size += 1
            for neighbour in adjacency.get(current, set()):
                if neighbour not in visited:
                    queue.append(neighbour)
        best = max(best, size)
    return best


def summarize_supported_genres(
    communities,
    band_metadata,
    community_min_genre_bands,
    genre_share_threshold,
):
    supported = {}
    strongest = None

    for members in communities.values():
        community_size = len(members)
        if community_size == 0:
            continue

        counts = defaultdict(int)
        for band_id in members:
            for genre_family in band_metadata.get(band_id, {}).get("genre_families", set()):
                counts[genre_family] += 1

        for genre_family, genre_bands in counts.items():
            genre_share = genre_bands / community_size
            if genre_bands < community_min_genre_bands:
                continue
            if genre_share < genre_share_threshold:
                continue

            candidate = {
                "community_size": community_size,
                "genre_bands": genre_bands,
                "genre_share": genre_share,
            }
            current = supported.get(genre_family)
            if current is None or (
                candidate["genre_share"],
                candidate["genre_bands"],
                candidate["community_size"],
            ) > (
                current["genre_share"],
                current["genre_bands"],
                current["community_size"],
            ):
                supported[genre_family] = candidate

            if strongest is None or (
                candidate["genre_share"],
                candidate["genre_bands"],
                candidate["community_size"],
                genre_family,
            ) > (
                strongest["genre_share"],
                strongest["genre_bands"],
                strongest["community_size"],
                strongest["genre_family"],
            ):
                strongest = {"genre_family": genre_family, **candidate}

    return supported, strongest


def load_band_reference():
    print("Loading band reference file...")
    band_reference = {}
    city_bands = defaultdict(dict)

    with open(BAND_FILE, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            band_id = normalize_text(row.get("source_id_primary", ""))
            city = extract_city(row.get("notes", ""))
            country = normalize_text(row.get("country_std", ""))
            city_country = normalize_city_country(city, country)
            formed_year = safe_int(row.get("formed_year"))
            genre_families = parse_genre_families(row.get("genre_raw", ""))

            if not band_id or not city_country or formed_year is None:
                continue

            metadata = {
                "band_id": band_id,
                "band_name": normalize_text(row.get("band_name_raw", "")),
                "city": city,
                "country": country,
                "city_country": city_country,
                "formed_year": formed_year,
                "genre_families": genre_families,
            }
            band_reference[band_id] = metadata
            city_bands[city_country][band_id] = metadata

    print(f"  Loaded {len(band_reference)} dated bands across {len(city_bands)} cities.")
    return band_reference, city_bands


def load_emergence_targets(city_filter=None):
    print("Loading genre-emergence targets...")
    targets_by_city = defaultdict(list)

    city_filter_norm = city_filter.lower() if city_filter else None

    with open(GENRE_FILE, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            emergence_year = safe_int(row.get("emergence_year"))
            city_country = normalize_text(row.get("city_country", ""))
            if emergence_year is None or not city_country:
                continue
            if city_filter_norm and city_filter_norm not in city_country.lower():
                continue

            targets_by_city[city_country].append(
                {
                    "city": normalize_text(row.get("city", "")),
                    "country": normalize_text(row.get("country", "")),
                    "city_country": city_country,
                    "genre_family": normalize_text(row.get("genre_family", "")),
                    "first_band_year": safe_int(row.get("first_band_year")),
                    "emergence_year": emergence_year,
                    "total_bands": safe_int(row.get("total_bands")) or 0,
                    "total_city_bands": safe_int(row.get("total_city_bands")) or 0,
                }
            )

    print(
        f"  Loaded {sum(len(rows) for rows in targets_by_city.values())} emerged city-genre rows "
        f"across {len(targets_by_city)} cities."
    )
    return targets_by_city


def load_member_stints(input_file, band_reference, target_cities):
    print("Loading musician-band stints for target cities...")
    stints_by_city = defaultdict(lambda: defaultdict(list))
    rows_read = 0
    rows_kept = 0

    with open(input_file, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            rows_read += 1
            band_id = normalize_text(row.get("band_id", ""))
            band_meta = band_reference.get(band_id)
            if band_meta is None:
                continue
            city_country = band_meta["city_country"]
            if city_country not in target_cities:
                continue

            musician = normalize_text(row.get("member_id", "")) or normalize_text(
                row.get("member_name", "")
            )
            if not musician:
                continue

            start_year = safe_int(row.get("first_year_in_band"))
            if start_year is None:
                start_year = band_meta["formed_year"]
            start_year = max(start_year, band_meta["formed_year"])

            end_year = safe_int(row.get("last_year_in_band"))
            if end_year is not None and end_year < start_year:
                end_year = start_year

            stints_by_city[city_country][musician].append((band_id, start_year, end_year))
            rows_kept += 1

    print(f"  Read {rows_read} edge rows and kept {rows_kept} rows in target cities.")
    return stints_by_city


def add_active_membership(active_bands_by_musician, pair_counts, musician, band_id):
    current_bands = active_bands_by_musician[musician]
    if band_id in current_bands:
        return

    for other_band in current_bands:
        pair = (band_id, other_band) if band_id < other_band else (other_band, band_id)
        pair_counts[pair] += 1
    current_bands.add(band_id)


def remove_active_membership(active_bands_by_musician, pair_counts, musician, band_id):
    current_bands = active_bands_by_musician.get(musician)
    if not current_bands or band_id not in current_bands:
        return

    for other_band in list(current_bands):
        if other_band == band_id:
            continue
        pair = (band_id, other_band) if band_id < other_band else (other_band, band_id)
        if pair in pair_counts:
            pair_counts[pair] -= 1
            if pair_counts[pair] <= 0:
                del pair_counts[pair]

    current_bands.remove(band_id)
    if not current_bands:
        del active_bands_by_musician[musician]


def build_city_snapshot_outputs(
    city_country,
    city_band_metadata,
    city_targets,
    city_stints,
    min_bands,
    community_method,
    community_min_genre_bands,
    genre_share_threshold,
):
    max_label_year = max(target["emergence_year"] for target in city_targets)

    band_events = defaultdict(list)
    year_events = defaultdict(list)
    snapshot_years = {target["emergence_year"] for target in city_targets}

    for band_id, metadata in city_band_metadata.items():
        formed_year = metadata["formed_year"]
        if formed_year <= max_label_year:
            band_events[formed_year].append(band_id)
            snapshot_years.add(formed_year)

    for musician, stints in city_stints.items():
        for band_id, start_year, end_year in stints:
            if start_year > max_label_year:
                continue

            year_events[start_year].append(("add", musician, band_id))
            snapshot_years.add(start_year)

            if end_year is not None and end_year + 1 <= max_label_year:
                year_events[end_year + 1].append(("remove", musician, band_id))
                snapshot_years.add(end_year + 1)

    years_to_process = sorted(snapshot_years)
    active_bands = set()
    active_bands_by_musician = defaultdict(set)
    pair_counts = defaultdict(int)

    target_state = {}
    for target in city_targets:
        key = target["genre_family"]
        target_state[key] = {
            **target,
            "community_detect_year": None,
            "detection_community_size": None,
            "detection_genre_bands": None,
            "detection_genre_share": None,
            "detection_city_active_bands": None,
            "detection_city_active_edges": None,
            "detection_city_active_musicians": None,
            "detection_modularity_q": None,
            "label_year_best_community_size": None,
            "label_year_best_genre_bands": None,
            "label_year_best_genre_share": None,
            "label_year_active_bands": None,
            "label_year_active_edges": None,
            "label_year_active_musicians": None,
            "label_year_modularity_q": None,
        }

    snapshot_rows = []

    for year in years_to_process:
        for band_id in band_events.get(year, []):
            active_bands.add(band_id)

        for action, musician, band_id in year_events.get(year, []):
            if action == "add":
                add_active_membership(active_bands_by_musician, pair_counts, musician, band_id)
            else:
                remove_active_membership(active_bands_by_musician, pair_counts, musician, band_id)

        active_band_set = {
            band_id
            for band_id in active_bands
            if city_band_metadata[band_id]["formed_year"] <= year
        }
        active_edges = {
            pair
            for pair, weight in pair_counts.items()
            if weight > 0 and pair[0] in active_band_set and pair[1] in active_band_set
        }
        active_musicians = {
            musician
            for musician, bands in active_bands_by_musician.items()
            if any(band_id in active_band_set for band_id in bands)
        }
        bridge_musicians = sum(
            1
            for musician, bands in active_bands_by_musician.items()
            if len([band_id for band_id in bands if band_id in active_band_set]) >= 2
        )

        communities = {}
        modularity_q = 0.0
        supported_genres = {}
        strongest_supported = None
        if len(active_band_set) >= min_bands:
            communities, modularity_q = detect_communities(
                active_band_set, active_edges, community_method
            )
            supported_genres, strongest_supported = summarize_supported_genres(
                communities,
                city_band_metadata,
                community_min_genre_bands,
                genre_share_threshold,
            )

        density = 0.0
        if len(active_band_set) >= 2:
            density = len(active_edges) / (len(active_band_set) * (len(active_band_set) - 1) / 2.0)

        bridge_pct = 0.0
        if active_musicians:
            bridge_pct = 100.0 * bridge_musicians / len(active_musicians)

        largest_community = max((len(members) for members in communities.values()), default=0)
        largest_component = largest_component_size(active_band_set, active_edges) if active_band_set else 0

        snapshot_rows.append(
            {
                "city": city_targets[0]["city"],
                "country": city_targets[0]["country"],
                "city_country": city_country,
                "snapshot_year": year,
                "n_active_bands": len(active_band_set),
                "n_active_musicians": len(active_musicians),
                "n_active_edges": len(active_edges),
                "density": f"{density:.6f}",
                "bridge_pct": f"{bridge_pct:.3f}",
                "n_communities": len(communities),
                "n_nontrivial_communities": sum(
                    1 for members in communities.values() if len(members) >= 2
                ),
                "largest_community": largest_community,
                "largest_component": largest_component,
                "modularity_q": f"{modularity_q:.6f}",
                "strongest_supported_genre": (
                    strongest_supported["genre_family"] if strongest_supported else ""
                ),
                "strongest_supported_genre_bands": (
                    strongest_supported["genre_bands"] if strongest_supported else ""
                ),
                "strongest_supported_genre_share": (
                    f"{strongest_supported['genre_share']:.3f}" if strongest_supported else ""
                ),
            }
        )

        for genre_family, state in target_state.items():
            best_supported = supported_genres.get(genre_family)

            if (
                state["community_detect_year"] is None
                and year <= state["emergence_year"]
                and best_supported is not None
            ):
                state["community_detect_year"] = year
                state["detection_community_size"] = best_supported["community_size"]
                state["detection_genre_bands"] = best_supported["genre_bands"]
                state["detection_genre_share"] = best_supported["genre_share"]
                state["detection_city_active_bands"] = len(active_band_set)
                state["detection_city_active_edges"] = len(active_edges)
                state["detection_city_active_musicians"] = len(active_musicians)
                state["detection_modularity_q"] = modularity_q

            if year == state["emergence_year"]:
                state["label_year_active_bands"] = len(active_band_set)
                state["label_year_active_edges"] = len(active_edges)
                state["label_year_active_musicians"] = len(active_musicians)
                state["label_year_modularity_q"] = modularity_q
                if best_supported is not None:
                    state["label_year_best_community_size"] = best_supported["community_size"]
                    state["label_year_best_genre_bands"] = best_supported["genre_bands"]
                    state["label_year_best_genre_share"] = best_supported["genre_share"]

    timing_rows = []
    for state in target_state.values():
        detect_year = state["community_detect_year"]
        lead_years = (
            state["emergence_year"] - detect_year if detect_year is not None else None
        )

        if detect_year is None:
            timing_status = "community_not_detected_by_label"
            detected_before_label = 0
        elif lead_years > 0:
            timing_status = "community_precedes_label"
            detected_before_label = 1
        elif lead_years == 0:
            timing_status = "community_same_year_as_label"
            detected_before_label = 0
        else:
            timing_status = "community_after_label"
            detected_before_label = 0

        timing_rows.append(
            {
                "city": state["city"],
                "country": state["country"],
                "city_country": state["city_country"],
                "genre_family": state["genre_family"],
                "first_band_year": state["first_band_year"] or "",
                "emergence_year": state["emergence_year"],
                "total_bands_in_city_genre": state["total_bands"],
                "total_bands_in_city": state["total_city_bands"],
                "community_detect_year": detect_year or "",
                "lead_years": lead_years if lead_years is not None else "",
                "timing_status": timing_status,
                "detected_before_label_i": detected_before_label,
                "detection_community_size": state["detection_community_size"] or "",
                "detection_genre_bands": state["detection_genre_bands"] or "",
                "detection_genre_share": (
                    f"{state['detection_genre_share']:.3f}"
                    if state["detection_genre_share"] is not None
                    else ""
                ),
                "detection_city_active_bands": state["detection_city_active_bands"] or "",
                "detection_city_active_edges": state["detection_city_active_edges"] or "",
                "detection_city_active_musicians": state["detection_city_active_musicians"] or "",
                "detection_modularity_q": (
                    f"{state['detection_modularity_q']:.6f}"
                    if state["detection_modularity_q"] is not None
                    else ""
                ),
                "label_year_best_community_size": state["label_year_best_community_size"] or "",
                "label_year_best_genre_bands": state["label_year_best_genre_bands"] or "",
                "label_year_best_genre_share": (
                    f"{state['label_year_best_genre_share']:.3f}"
                    if state["label_year_best_genre_share"] is not None
                    else ""
                ),
                "label_year_active_bands": state["label_year_active_bands"] or "",
                "label_year_active_edges": state["label_year_active_edges"] or "",
                "label_year_active_musicians": state["label_year_active_musicians"] or "",
                "label_year_modularity_q": (
                    f"{state['label_year_modularity_q']:.6f}"
                    if state["label_year_modularity_q"] is not None
                    else ""
                ),
            }
        )

    return snapshot_rows, timing_rows


def write_results_summary(
    timing_rows,
    snapshot_rows,
    community_method,
    min_bands,
    community_min_genre_bands,
    genre_share_threshold,
):
    status_counts = defaultdict(int)
    for row in timing_rows:
        status_counts[row["timing_status"]] += 1

    precedes_rows = [
        row for row in timing_rows if row["timing_status"] == "community_precedes_label"
    ]
    same_year_rows = [
        row for row in timing_rows if row["timing_status"] == "community_same_year_as_label"
    ]
    undetected_rows = [
        row for row in timing_rows if row["timing_status"] == "community_not_detected_by_label"
    ]

    lead_values = sorted(int(row["lead_years"]) for row in precedes_rows if row["lead_years"] != "")
    median_lead = lead_values[len(lead_values) // 2] if lead_values else None

    top_precedes = sorted(
        precedes_rows,
        key=lambda row: (
            int(row["lead_years"]),
            float(row["detection_genre_share"]),
            int(row["detection_genre_bands"]),
            row["city_country"],
            row["genre_family"],
        ),
        reverse=True,
    )

    weakest_undetected = sorted(
        undetected_rows,
        key=lambda row: (
            int(row["label_year_active_bands"]) if row["label_year_active_bands"] else 0,
            int(row["total_bands_in_city_genre"]),
            row["city_country"],
            row["genre_family"],
        ),
        reverse=True,
    )

    with open(OUT_RESULTS, "w", encoding="utf-8") as handle:
        handle.write("# Community vs label timing\n\n")
        handle.write("## Configuration\n\n")
        handle.write(f"- Community method: `{community_method}`\n")
        handle.write(f"- Minimum active city bands per snapshot: `{min_bands}`\n")
        handle.write(
            f"- Minimum genre bands inside a supporting community: `{community_min_genre_bands}`\n"
        )
        handle.write(f"- Minimum genre share inside a supporting community: `{genre_share_threshold:.2f}`\n\n")

        handle.write("## Counts\n\n")
        handle.write(f"- City-year snapshots written: `{len(snapshot_rows)}`\n")
        handle.write(f"- City-genre timing rows written: `{len(timing_rows)}`\n")
        handle.write(
            f"- `community_precedes_label`: `{status_counts['community_precedes_label']}`\n"
        )
        handle.write(
            f"- `community_same_year_as_label`: `{status_counts['community_same_year_as_label']}`\n"
        )
        handle.write(
            f"- `community_not_detected_by_label`: `{status_counts['community_not_detected_by_label']}`\n"
        )
        if median_lead is not None:
            handle.write(f"- Median lead among precedes cases: `{median_lead}` years\n")
            handle.write(f"- Max lead among precedes cases: `{max(lead_values)}` years\n")
        handle.write("\n")

        handle.write("## Current read\n\n")
        if timing_rows:
            handle.write(
                f"- Communities are detectable before the current label proxy in "
                f"`{status_counts['community_precedes_label']}` of `{len(timing_rows)}` "
                "city-genre cases.\n"
            )
            handle.write(
                f"- A further `{len(same_year_rows)}` cases first line up in the same year as the label proxy.\n"
            )
            handle.write(
                f"- `{len(undetected_rows)}` cases still do not show a qualifying pre-label community by the label year.\n"
            )
        handle.write(
            "- This is still a project-internal timing proxy: the label year is the Metallum-based "
            "city-genre emergence threshold from `22_build_genre_emergence.py`, not a newspaper or "
            "fan-zine text timestamp.\n"
        )
        handle.write(
            "- Membership gaps inside a musician-band edge are not fully observed once the raw dump is "
            "collapsed to earliest start and latest end, so long hiatuses can still make some links look "
            "too persistent.\n"
        )

        handle.write("\n## Top precedes cases\n\n")
        handle.write(
            "| City | Country | Genre | Label year | Community year | Lead | Genre share | Genre bands | City bands |\n"
        )
        handle.write(
            "|------|---------|-------|------------|----------------|------|-------------|-------------|-----------|\n"
        )
        for row in top_precedes[:25]:
            handle.write(
                f"| {row['city']} | {row['country']} | {row['genre_family']} | "
                f"{row['emergence_year']} | {row['community_detect_year']} | {row['lead_years']} | "
                f"{row['detection_genre_share']} | {row['detection_genre_bands']} | "
                f"{row['detection_city_active_bands']} |\n"
            )

        handle.write("\n## Large undetected-by-label cases\n\n")
        handle.write(
            "| City | Country | Genre | Label year | Label-year city bands | Label-year best genre share | Total genre bands |\n"
        )
        handle.write(
            "|------|---------|-------|------------|-----------------------|-----------------------------|------------------|\n"
        )
        for row in weakest_undetected[:25]:
            handle.write(
                f"| {row['city']} | {row['country']} | {row['genre_family']} | "
                f"{row['emergence_year']} | {row['label_year_active_bands']} | "
                f"{row['label_year_best_genre_share']} | {row['total_bands_in_city_genre']} |\n"
            )

        handle.write("\n## Interpretation\n\n")
        handle.write(
            "The full-data branch now has a reusable lagged city-year network object. That moves the "
            "scene-network design past static cross-sections and into actual timing comparisons.\n\n"
        )
        handle.write(
            "The right next read is not just the headline share of precedes cases. It is to audit "
            "whether those cases are concentrated in plausible scene units and whether the strongest "
            "undetected cases are geography-clean failures, weak genre proxies, or member-coverage "
            "problems.\n"
        )


def run_full(
    input_file,
    min_bands,
    community_method,
    community_min_genre_bands,
    genre_share_threshold,
    city_filter,
    max_cities,
):
    band_reference, city_bands = load_band_reference()
    targets_by_city = load_emergence_targets(city_filter=city_filter)

    targets_by_city = {
        city_country: rows
        for city_country, rows in targets_by_city.items()
        if city_country in city_bands
    }

    if max_cities is not None:
        selected_cities = sorted(targets_by_city.keys())[:max_cities]
        targets_by_city = {
            city_country: targets_by_city[city_country] for city_country in selected_cities
        }

    target_cities = set(targets_by_city.keys())
    if not target_cities:
        print("No eligible city-genre targets found for the current filter.")
        return

    stints_by_city = load_member_stints(input_file, band_reference, target_cities)

    all_snapshot_rows = []
    all_timing_rows = []
    cities_sorted = sorted(target_cities)

    for idx, city_country in enumerate(cities_sorted, start=1):
        if idx == 1 or idx % 25 == 0 or idx == len(cities_sorted):
            print(
                f"Processing city {idx} / {len(cities_sorted)}: "
                f"{safe_console_text(city_country)}"
            )

        snapshot_rows, timing_rows = build_city_snapshot_outputs(
            city_country=city_country,
            city_band_metadata=city_bands[city_country],
            city_targets=targets_by_city[city_country],
            city_stints=stints_by_city.get(city_country, {}),
            min_bands=min_bands,
            community_method=community_method,
            community_min_genre_bands=community_min_genre_bands,
            genre_share_threshold=genre_share_threshold,
        )
        all_snapshot_rows.extend(snapshot_rows)
        all_timing_rows.extend(timing_rows)

    print(f"Writing {OUT_SNAPSHOTS}...")
    with open(OUT_SNAPSHOTS, "w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "city",
            "country",
            "city_country",
            "snapshot_year",
            "n_active_bands",
            "n_active_musicians",
            "n_active_edges",
            "density",
            "bridge_pct",
            "n_communities",
            "n_nontrivial_communities",
            "largest_community",
            "largest_component",
            "modularity_q",
            "strongest_supported_genre",
            "strongest_supported_genre_bands",
            "strongest_supported_genre_share",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_snapshot_rows)

    print(f"Writing {OUT_TIMING}...")
    with open(OUT_TIMING, "w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "city",
            "country",
            "city_country",
            "genre_family",
            "first_band_year",
            "emergence_year",
            "total_bands_in_city_genre",
            "total_bands_in_city",
            "community_detect_year",
            "lead_years",
            "timing_status",
            "detected_before_label_i",
            "detection_community_size",
            "detection_genre_bands",
            "detection_genre_share",
            "detection_city_active_bands",
            "detection_city_active_edges",
            "detection_city_active_musicians",
            "detection_modularity_q",
            "label_year_best_community_size",
            "label_year_best_genre_bands",
            "label_year_best_genre_share",
            "label_year_active_bands",
            "label_year_active_edges",
            "label_year_active_musicians",
            "label_year_modularity_q",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_timing_rows)

    print(f"Writing {OUT_RESULTS}...")
    write_results_summary(
        timing_rows=all_timing_rows,
        snapshot_rows=all_snapshot_rows,
        community_method=community_method,
        min_bands=min_bands,
        community_min_genre_bands=community_min_genre_bands,
        genre_share_threshold=genre_share_threshold,
    )
    print("Done.")


def run_pilot():
    pilot_files = [
        ("Norwegian Black Metal", os.path.join(DATA_DIR, "norwegian_bm_musician_band_edges.csv")),
        ("Tampa Death Metal", os.path.join(DATA_DIR, "tampa_dm_musician_band_edges.csv")),
        (
            "Gothenburg Melodic Death Metal",
            os.path.join(DATA_DIR, "gothenburg_mdm_musician_band_edges.csv"),
        ),
    ]

    results = []

    for scene_name, edge_file in pilot_files:
        if not os.path.exists(edge_file):
            print(f"Skipping {scene_name}: {edge_file} not found.")
            continue

        print(f"\n--- {scene_name} ---")
        musician_to_bands = defaultdict(set)
        band_info = {}

        with open(edge_file, "r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                musician = normalize_text(row.get("musician", ""))
                band = normalize_text(row.get("band", ""))
                if not musician or not band:
                    continue
                musician_to_bands[musician].add(band)
                band_info.setdefault(
                    band,
                    {
                        "city": normalize_text(row.get("city", "")),
                        "formed_year": normalize_text(row.get("formed_year", "")),
                    },
                )

        band_band_edges = set()
        for bands in musician_to_bands.values():
            band_list = sorted(bands)
            for idx, band_a in enumerate(band_list):
                for band_b in band_list[idx + 1 :]:
                    band_band_edges.add((band_a, band_b))

        communities, modularity_q = greedy_modularity(set(band_info.keys()), band_band_edges)
        print(f"  Bands: {len(band_info)}")
        print(f"  Communities detected: {len(communities)}")
        print(f"  Modularity Q: {modularity_q:.3f}")

        for community_id, members in sorted(communities.items(), key=lambda item: -len(item[1])):
            years = [
                safe_int(band_info[band]["formed_year"])
                for band in members
                if safe_int(band_info[band]["formed_year"]) is not None
            ]
            earliest_year = min(years) if years else ""
            results.append(
                {
                    "scene": scene_name,
                    "community_id": community_id,
                    "n_bands": len(members),
                    "earliest_band_year": earliest_year,
                    "bands": "; ".join(sorted(members)),
                    "modularity_q": f"{modularity_q:.3f}",
                }
            )

    out_pilot = os.path.join(DATA_DIR, "community_detection_pilot_results.csv")
    with open(out_pilot, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "scene",
                "community_id",
                "n_bands",
                "earliest_band_year",
                "bands",
                "modularity_q",
            ],
        )
        writer.writeheader()
        writer.writerows(results)

    out_summary = os.path.join(DATA_DIR, "community_detection_pilot_summary.md")
    with open(out_summary, "w", encoding="utf-8") as handle:
        handle.write("# Community detection pilot\n\n")
        handle.write(
            "Pilot scenes use the small Wikipedia-derived networks and the original greedy modularity "
            "routine.\n\n"
        )
        for scene_name, _ in pilot_files:
            scene_rows = [row for row in results if row["scene"] == scene_name]
            if not scene_rows:
                continue
            handle.write(f"## {scene_name}\n\n")
            handle.write(f"- Modularity Q: {scene_rows[0]['modularity_q']}\n")
            handle.write(f"- Communities detected: {len(scene_rows)}\n\n")
            handle.write("| Community | Bands | Earliest year | Members |\n")
            handle.write("|-----------|-------|---------------|---------|\n")
            for row in sorted(scene_rows, key=lambda item: -item["n_bands"]):
                handle.write(
                    f"| {row['community_id']} | {row['n_bands']} | {row['earliest_band_year']} | "
                    f"{row['bands']} |\n"
                )
            handle.write("\n")

    print("Pilot outputs written.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pilot", action="store_true", help="Run on Wikipedia pilot scenes")
    parser.add_argument("--input", default=DEFAULT_INPUT, help="Path to full musician-band edge CSV")
    parser.add_argument(
        "--min-bands",
        type=int,
        default=5,
        help="Minimum active city bands required to evaluate a snapshot",
    )
    parser.add_argument(
        "--community-method",
        choices=["label_prop", "greedy"],
        default="label_prop",
        help="Community detection method for full mode",
    )
    parser.add_argument(
        "--community-min-genre-bands",
        type=int,
        default=3,
        help="Minimum same-genre bands required inside a supporting community",
    )
    parser.add_argument(
        "--genre-share-threshold",
        type=float,
        default=0.5,
        help="Minimum genre share required inside a supporting community",
    )
    parser.add_argument(
        "--city-filter",
        default="",
        help="Optional lowercase substring filter on city_country for faster targeted runs",
    )
    parser.add_argument(
        "--max-cities",
        type=int,
        default=None,
        help="Optional cap on the number of cities processed after filtering",
    )
    args = parser.parse_args()

    if args.pilot:
        run_pilot()
        return

    if not os.path.exists(args.input):
        raise FileNotFoundError(f"Full edge file not found: {args.input}")

    run_full(
        input_file=args.input,
        min_bands=args.min_bands,
        community_method=args.community_method,
        community_min_genre_bands=args.community_min_genre_bands,
        genre_share_threshold=args.genre_share_threshold,
        city_filter=args.city_filter or None,
        max_cities=args.max_cities,
    )


if __name__ == "__main__":
    main()
