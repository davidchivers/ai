"""
21_build_city_networks.py

For every city with N+ bands, build the band-band projection via shared
members and compute network topology statistics.

Input:
    data/processed/scene_networks/full_musician_band_edges.csv
    (or any file in the same schema)

Outputs:
    data/processed/scene_networks/city_network_stats.csv
    data/processed/scene_networks/city_network_summary.md
    data/processed/scene_networks/city_band_band_edges.csv

Usage:
    python code/21_build_city_networks.py [--min-bands 10] [--input <edge_file>]
"""

import argparse
import csv
import os
from collections import defaultdict


DEFAULT_INPUT = os.path.join(
    os.path.dirname(__file__),
    "..",
    "data",
    "processed",
    "scene_networks",
    "full_musician_band_edges.csv",
)
OUT_DIR = os.path.join(
    os.path.dirname(__file__),
    "..",
    "data",
    "processed",
    "scene_networks",
)

os.makedirs(OUT_DIR, exist_ok=True)


def compute_clustering(band, band_band_edges_set, neighbour_map):
    """Compute local clustering coefficient for a band."""
    neighbours = neighbour_map.get(band, set())
    if len(neighbours) < 2:
        return 0.0

    neighbour_edges = 0
    neighbour_list = list(neighbours)
    for i in range(len(neighbour_list)):
        for j in range(i + 1, len(neighbour_list)):
            pair = tuple(sorted([neighbour_list[i], neighbour_list[j]]))
            if pair in band_band_edges_set:
                neighbour_edges += 1

    possible = len(neighbours) * (len(neighbours) - 1) / 2
    return neighbour_edges / possible if possible > 0 else 0.0


def build_city_network(city_bands, musician_to_city_bands):
    """Build band-band projection for a city's local musician-band mapping."""
    city_band_set = set(city_bands.keys())

    band_band_edges = defaultdict(set)
    for musician, bands in musician_to_city_bands.items():
        if len(bands) < 2:
            continue
        bands_list = sorted(bands)
        for i in range(len(bands_list)):
            for j in range(i + 1, len(bands_list)):
                pair = (bands_list[i], bands_list[j])
                band_band_edges[pair].add(musician)

    n_bands = len(city_band_set)
    n_edges = len(band_band_edges)

    neighbour_map = defaultdict(set)
    for band_a, band_b in band_band_edges:
        neighbour_map[band_a].add(band_b)
        neighbour_map[band_b].add(band_a)

    band_degree = {}
    for band in city_band_set:
        band_degree[band] = len(neighbour_map.get(band, set()))

    avg_degree = sum(band_degree.values()) / n_bands if n_bands > 0 else 0.0
    max_degree = max(band_degree.values()) if band_degree else 0

    max_edges = n_bands * (n_bands - 1) / 2
    density = n_edges / max_edges if max_edges > 0 else 0.0

    edge_set = set(band_band_edges.keys())
    clustering_vals = []
    for band in city_band_set:
        clustering_vals.append(compute_clustering(band, edge_set, neighbour_map))
    avg_clustering = sum(clustering_vals) / len(clustering_vals) if clustering_vals else 0.0

    n_bridge = sum(1 for bands in musician_to_city_bands.values() if len(bands) >= 2)
    n_musicians = len(musician_to_city_bands)
    bridge_pct = 100 * n_bridge / n_musicians if n_musicians > 0 else 0.0

    visited = set()
    n_components = 0
    largest_component = 0
    for start in city_band_set:
        if start in visited:
            continue
        n_components += 1
        queue = [start]
        component_size = 0
        while queue:
            node = queue.pop(0)
            if node in visited:
                continue
            visited.add(node)
            component_size += 1
            for neighbour in neighbour_map.get(node, set()):
                if neighbour not in visited:
                    queue.append(neighbour)
        largest_component = max(largest_component, component_size)

    return {
        "n_bands": n_bands,
        "n_musicians": n_musicians,
        "n_edges": n_edges,
        "density": density,
        "avg_degree": avg_degree,
        "max_degree": max_degree,
        "avg_clustering": avg_clustering,
        "n_bridge_musicians": n_bridge,
        "bridge_pct": bridge_pct,
        "n_components": n_components,
        "largest_component": largest_component,
        "largest_component_pct": 100 * largest_component / n_bands if n_bands > 0 else 0.0,
    }, band_band_edges


def normalize_city_country(city, country):
    city = city.strip()
    country = country.strip()
    if not city:
        return ""
    return f"{city}, {country}" if country else city


def first_pass_city_bands(input_path):
    """Count unique bands per city to identify eligible cities."""
    city_band_ids = defaultdict(set)

    with open(input_path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            band_id = (row.get("band_id") or "").strip()
            city = (row.get("city") or "").strip()
            country = (row.get("country") or "").strip()
            city_country = normalize_city_country(city, country)
            if city_country and band_id:
                city_band_ids[city_country].add(band_id)

    return city_band_ids


def second_pass_city_data(input_path, eligible_cities):
    """Build city-local band metadata and musician-band mappings."""
    city_bands = {city: {} for city in eligible_cities}
    city_musician_to_bands = {city: defaultdict(set) for city in eligible_cities}
    unique_musicians = set()

    with open(input_path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            band_id = (row.get("band_id") or "").strip()
            city = (row.get("city") or "").strip()
            country = (row.get("country") or "").strip()
            city_country = normalize_city_country(city, country)
            if city_country not in eligible_cities or not band_id:
                continue

            member_id = (row.get("member_id") or "").strip()
            member_name = (row.get("member_name") or "").strip()
            musician_key = member_id if member_id else member_name
            if not musician_key:
                continue

            city_bands[city_country][band_id] = {
                "band_name": (row.get("band_name") or "").strip(),
                "formed_year": (row.get("formed_year") or "").strip(),
                "genre_raw": (row.get("genre_raw") or "").strip(),
            }
            city_musician_to_bands[city_country][musician_key].add(band_id)
            unique_musicians.add(musician_key)

    return city_bands, city_musician_to_bands, unique_musicians


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default=DEFAULT_INPUT,
        help="Path to musician-band edge CSV",
    )
    parser.add_argument(
        "--min-bands",
        type=int,
        default=10,
        help="Minimum bands in a city to include (default: 10)",
    )
    args = parser.parse_args()

    print(f"First pass over {args.input}...")
    city_band_ids = first_pass_city_bands(args.input)
    eligible_cities = {
        city for city, bands in city_band_ids.items() if len(bands) >= args.min_bands
    }

    print(f"  Found {len(city_band_ids)} unique cities.")
    print(f"  Cities with {args.min_bands}+ bands: {len(eligible_cities)}")

    print("Second pass to build city-local musician mappings...")
    city_bands, city_musician_to_bands, unique_musicians = second_pass_city_data(
        args.input, eligible_cities
    )
    print(f"  Unique musicians in eligible cities: {len(unique_musicians)}")

    results = []
    all_edges = []

    eligible_sorted = sorted(eligible_cities)
    for idx, city_country in enumerate(eligible_sorted, start=1):
        if idx % 500 == 0 or idx == 1 or idx == len(eligible_sorted):
            print(f"  Building city {idx} / {len(eligible_sorted)}: {city_country}")

        stats, edges = build_city_network(
            city_bands[city_country], city_musician_to_bands[city_country]
        )

        country = city_country.split(", ")[-1] if ", " in city_country else ""
        city = city_country.split(", ")[0] if ", " in city_country else city_country

        results.append(
            {
                "city": city,
                "country": country,
                "city_country": city_country,
                **stats,
            }
        )

        for (band_a, band_b), members in edges.items():
            all_edges.append(
                {
                    "city": city_country,
                    "band_a": band_a,
                    "band_b": band_b,
                    "shared_members": "; ".join(sorted(members)),
                    "n_shared": len(members),
                }
            )

    out_stats = os.path.join(OUT_DIR, "city_network_stats.csv")
    print(f"Writing {out_stats}...")
    with open(out_stats, "w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "city",
            "country",
            "city_country",
            "n_bands",
            "n_musicians",
            "n_edges",
            "density",
            "avg_degree",
            "max_degree",
            "avg_clustering",
            "n_bridge_musicians",
            "bridge_pct",
            "n_components",
            "largest_component",
            "largest_component_pct",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)

    out_edges = os.path.join(OUT_DIR, "city_band_band_edges.csv")
    print(f"Writing {out_edges}...")
    with open(out_edges, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["city", "band_a", "band_b", "shared_members", "n_shared"],
        )
        writer.writeheader()
        writer.writerows(all_edges)

    out_summary = os.path.join(OUT_DIR, "city_network_summary.md")
    print(f"Writing {out_summary}...")
    results_sorted = sorted(results, key=lambda row: (-row["density"], -row["n_bands"], row["city_country"]))

    with open(out_summary, "w", encoding="utf-8") as handle:
        handle.write("# City-Level Network Statistics\n\n")
        handle.write(f"Minimum bands per city: {args.min_bands}\n")
        handle.write(f"Eligible cities: {len(results)}\n\n")
        handle.write("## Top 30 cities by network density\n\n")
        handle.write("| City | Country | Bands | Edges | Density | Avg Clust | Bridge % | Largest Component % |\n")
        handle.write("|------|---------|-------|-------|---------|-----------|----------|--------------------|\n")
        for row in results_sorted[:30]:
            handle.write(
                f"| {row['city']} | {row['country']} | {row['n_bands']} | "
                f"{row['n_edges']} | {row['density']:.3f} | "
                f"{row['avg_clustering']:.3f} | {row['bridge_pct']:.1f} | "
                f"{row['largest_component_pct']:.1f} |\n"
            )

        handle.write("\n## Distribution summary\n\n")
        if results:
            densities = [row["density"] for row in results]
            clusterings = [row["avg_clustering"] for row in results]
            bridges = [row["bridge_pct"] for row in results]
            handle.write(
                f"- Density: min={min(densities):.3f}, "
                f"median={sorted(densities)[len(densities) // 2]:.3f}, "
                f"max={max(densities):.3f}\n"
            )
            handle.write(
                f"- Avg clustering: min={min(clusterings):.3f}, "
                f"median={sorted(clusterings)[len(clusterings) // 2]:.3f}, "
                f"max={max(clusterings):.3f}\n"
            )
            handle.write(
                f"- Bridge musician %: min={min(bridges):.1f}, "
                f"median={sorted(bridges)[len(bridges) // 2]:.1f}, "
                f"max={max(bridges):.1f}\n"
            )

    print(f"Done. {len(results)} cities processed.")


if __name__ == "__main__":
    main()
