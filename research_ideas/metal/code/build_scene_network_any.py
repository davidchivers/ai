"""
Build scene network from any musician-band edge CSV.
Usage: python build_scene_network_any.py <edge_csv> <scene_label>

Produces:
  - Band-band projection (shared members)
  - Basic network statistics
  - Edge list for visualisation
"""

import csv
import os
import sys
from collections import defaultdict

if len(sys.argv) < 3:
    print("Usage: python build_scene_network_any.py <edge_csv> <scene_label>")
    sys.exit(1)

EDGE_FILE = sys.argv[1]
SCENE = sys.argv[2]
OUT_DIR = os.path.dirname(EDGE_FILE)
OUT_BAND_EDGES = os.path.join(OUT_DIR, f"{SCENE}_band_band_edges.csv")
OUT_STATS = os.path.join(OUT_DIR, f"{SCENE}_network_stats.md")
OUT_MUSICIAN_STATS = os.path.join(OUT_DIR, f"{SCENE}_musician_degree.csv")

# --- Load bipartite edges ---
musician_to_bands = defaultdict(set)
band_to_musicians = defaultdict(set)
band_city = {}
band_formed = {}

with open(EDGE_FILE, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        m = row["musician"].strip()
        b = row["band"].strip()
        musician_to_bands[m].add(b)
        band_to_musicians[b].add(m)
        if b not in band_city:
            band_city[b] = row["city"].strip()
        if b not in band_formed:
            band_formed[b] = row["formed_year"].strip()

# --- Build band-band projection ---
band_band_edges = defaultdict(set)

for m, bands in musician_to_bands.items():
    bands_list = sorted(bands)
    for i in range(len(bands_list)):
        for j in range(i + 1, len(bands_list)):
            pair = (bands_list[i], bands_list[j])
            band_band_edges[pair].add(m)

# --- Write band-band edge list ---
with open(OUT_BAND_EDGES, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["band_a", "band_b", "shared_members", "n_shared", "city_a", "city_b", "formed_a", "formed_b"])
    for (a, b), members in sorted(band_band_edges.items()):
        writer.writerow([
            a, b,
            "; ".join(sorted(members)),
            len(members),
            band_city.get(a, ""),
            band_city.get(b, ""),
            band_formed.get(a, ""),
            band_formed.get(b, ""),
        ])

# --- Compute network stats ---
n_bands = len(band_to_musicians)
n_musicians = len(musician_to_bands)
n_edges = len(band_band_edges)

# Degree distribution (band level)
band_degree = defaultdict(int)
for (a, b) in band_band_edges:
    band_degree[a] += 1
    band_degree[b] += 1

for b in band_to_musicians:
    if b not in band_degree:
        band_degree[b] = 0

degrees = sorted(band_degree.items(), key=lambda x: -x[1])

# Musician degree
musician_degrees = [(m, len(bands)) for m, bands in musician_to_bands.items()]
musician_degrees.sort(key=lambda x: -x[1])

# Bridge musicians
bridges = [(m, len(bands), sorted(bands)) for m, bands in musician_to_bands.items() if len(bands) >= 2]
bridges.sort(key=lambda x: -x[1])

# Clustering coefficient
clustering_coeffs = {}
for band in band_to_musicians:
    neighbours = set()
    for (a, b) in band_band_edges:
        if a == band:
            neighbours.add(b)
        elif b == band:
            neighbours.add(a)
    if len(neighbours) < 2:
        clustering_coeffs[band] = 0.0
        continue
    neighbour_edges = 0
    neighbour_list = list(neighbours)
    for i in range(len(neighbour_list)):
        for j in range(i + 1, len(neighbour_list)):
            pair = tuple(sorted([neighbour_list[i], neighbour_list[j]]))
            if pair in band_band_edges:
                neighbour_edges += 1
    possible = len(neighbours) * (len(neighbours) - 1) / 2
    clustering_coeffs[band] = neighbour_edges / possible if possible > 0 else 0.0

avg_clustering = sum(clustering_coeffs.values()) / len(clustering_coeffs) if clustering_coeffs else 0.0
avg_degree = sum(d for _, d in degrees) / len(degrees) if degrees else 0.0
max_edges = n_bands * (n_bands - 1) / 2
density = n_edges / max_edges if max_edges > 0 else 0.0

# --- Write stats ---
with open(OUT_STATS, "w", encoding="utf-8") as f:
    f.write(f"# {SCENE.replace('_', ' ').title()} Scene: Network Statistics (Pilot)\n\n")
    f.write(f"Source: Wikipedia (hand-coded from band pages)\n")
    f.write(f"Date: 2026-03-22\n\n")
    f.write(f"## Summary\n\n")
    f.write(f"- Bands: {n_bands}\n")
    f.write(f"- Musicians: {n_musicians}\n")
    f.write(f"- Band-band edges (shared members): {n_edges}\n")
    f.write(f"- Network density: {density:.3f}\n")
    f.write(f"- Average band degree: {avg_degree:.1f}\n")
    f.write(f"- Average clustering coefficient: {avg_clustering:.3f}\n\n")

    f.write(f"## Band Degree Ranking (connections via shared members)\n\n")
    f.write(f"| Band | Degree | City | Formed |\n")
    f.write(f"|------|--------|------|--------|\n")
    for band, deg in degrees:
        f.write(f"| {band} | {deg} | {band_city.get(band, '')} | {band_formed.get(band, '')} |\n")

    f.write(f"\n## Bridge Musicians (playing in 2+ bands)\n\n")
    f.write(f"| Musician | N Bands | Bands |\n")
    f.write(f"|----------|---------|-------|\n")
    for m, n, bands in bridges:
        f.write(f"| {m} | {n} | {', '.join(bands)} |\n")

    f.write(f"\n## Clustering Coefficients by Band\n\n")
    f.write(f"| Band | Clustering | Degree |\n")
    f.write(f"|------|-----------|--------|\n")
    for band, cc in sorted(clustering_coeffs.items(), key=lambda x: -x[1]):
        f.write(f"| {band} | {cc:.3f} | {band_degree[band]} |\n")

# --- Write musician degree file ---
with open(OUT_MUSICIAN_STATS, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["musician", "n_bands", "bands"])
    for m, n in musician_degrees:
        writer.writerow([m, n, "; ".join(sorted(musician_to_bands[m]))])

print(f"Done. {n_bands} bands, {n_musicians} musicians, {n_edges} band-band edges.")
print(f"Density: {density:.3f}, Avg degree: {avg_degree:.1f}, Avg clustering: {avg_clustering:.3f}")
print(f"Bridge musicians (2+ bands): {len(bridges)}")
