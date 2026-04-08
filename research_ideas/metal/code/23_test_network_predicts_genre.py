"""
23_test_network_predicts_genre.py

Core mechanism test: does network topology predict genre emergence?

Merges:
    - city_network_stats.csv (network topology by city)
    - city_genre_first_appearance.csv (genre emergence dates by city)

Tests:
    1. Do cities with denser networks produce more genre emergences?
    2. Do cities with higher clustering produce genres earlier?
    3. Does bridge-musician share predict genre emergence?
    4. Controlling for city size (total bands), does network structure
       still predict emergence?

Outputs:
    data/processed/scene_networks/mechanism_test_merged.csv
    data/processed/scene_networks/mechanism_test_results.md

Usage:
    python code/23_test_network_predicts_genre.py
"""

import csv
import os
from collections import defaultdict

# --- Config ---
DATA_DIR = os.path.join(os.path.dirname(__file__), "..",
    "data", "processed", "scene_networks")
NETWORK_FILE = os.path.join(DATA_DIR, "city_network_stats.csv")
GENRE_FILE = os.path.join(DATA_DIR, "city_genre_first_appearance.csv")
OUT_MERGED = os.path.join(DATA_DIR, "mechanism_test_merged.csv")
OUT_RESULTS = os.path.join(DATA_DIR, "mechanism_test_results.md")


def safe_float(x, default=0.0):
    try:
        return float(x)
    except (ValueError, TypeError):
        return default


def safe_int(x, default=0):
    try:
        return int(x)
    except (ValueError, TypeError):
        return default


def ols_simple(x_vals, y_vals):
    """Simple OLS: y = a + b*x. Returns (a, b, r_squared, n)."""
    n = len(x_vals)
    if n < 3:
        return None, None, None, n
    x_mean = sum(x_vals) / n
    y_mean = sum(y_vals) / n
    ss_xy = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_vals, y_vals))
    ss_xx = sum((x - x_mean) ** 2 for x in x_vals)
    ss_yy = sum((y - y_mean) ** 2 for y in y_vals)
    if ss_xx == 0 or ss_yy == 0:
        return None, None, None, n
    b = ss_xy / ss_xx
    a = y_mean - b * x_mean
    r_sq = (ss_xy ** 2) / (ss_xx * ss_yy)
    return a, b, r_sq, n


def ols_residualize(x_vals, y_vals, control_vals):
    """Residualize y and x on control, then regress residual_y on residual_x."""
    n = len(x_vals)
    if n < 4:
        return None, None, None, n

    # Regress y on control
    _, b_yc, _, _ = ols_simple(control_vals, y_vals)
    if b_yc is None:
        return None, None, None, n
    c_mean = sum(control_vals) / n
    y_mean = sum(y_vals) / n
    a_yc = y_mean - b_yc * c_mean
    y_resid = [y - (a_yc + b_yc * c) for y, c in zip(y_vals, control_vals)]

    # Regress x on control
    _, b_xc, _, _ = ols_simple(control_vals, x_vals)
    if b_xc is None:
        return None, None, None, n
    x_mean = sum(x_vals) / n
    a_xc = x_mean - b_xc * c_mean
    x_resid = [x - (a_xc + b_xc * c) for x, c in zip(x_vals, control_vals)]

    # Regress residuals
    return ols_simple(x_resid, y_resid)


def sign_label(value):
    if value is None:
        return "n/a"
    if value > 0:
        return "positive"
    if value < 0:
        return "negative"
    return "zero"


def main():
    # --- Load network stats ---
    print("Loading network stats...")
    network = {}
    if not os.path.exists(NETWORK_FILE):
        print(f"  WARNING: {NETWORK_FILE} not found.")
        print(f"  This file is produced by 21_build_city_networks.py and requires")
        print(f"  the full member data. Writing skeleton results.")
        write_skeleton_results()
        return

    with open(NETWORK_FILE, "r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            city = row["city_country"].strip()
            network[city] = {k: row[k] for k in row}

    print(f"  Loaded network stats for {len(network)} cities.")

    # --- Load genre emergence ---
    print("Loading genre emergence data...")
    genre_data = defaultdict(list)
    with open(GENRE_FILE, "r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            city = row["city_country"].strip()
            genre_data[city].append(row)

    print(f"  Loaded genre data for {len(genre_data)} cities.")

    # --- Merge ---
    merged = []
    for city, net in network.items():
        genres = genre_data.get(city, [])
        n_emerged = sum(1 for g in genres if g.get("emergence_year"))
        earliest_emergence = min(
            (safe_int(g["emergence_year"], 9999) for g in genres if g.get("emergence_year")),
            default=None
        )
        total_genre_families = len(set(g["genre_family"] for g in genres))

        merged.append({
            "city_country": city,
            "city": net.get("city", ""),
            "country": net.get("country", ""),
            "n_bands": safe_int(net.get("n_bands")),
            "n_edges": safe_int(net.get("n_edges")),
            "density": safe_float(net.get("density")),
            "avg_clustering": safe_float(net.get("avg_clustering")),
            "bridge_pct": safe_float(net.get("bridge_pct")),
            "largest_component_pct": safe_float(net.get("largest_component_pct")),
            "n_genre_emergences": n_emerged,
            "earliest_emergence_year": earliest_emergence if earliest_emergence and earliest_emergence < 9999 else "",
            "total_genre_families": total_genre_families,
        })

    # --- Write merged ---
    print(f"Writing {OUT_MERGED}...")
    with open(OUT_MERGED, "w", newline="", encoding="utf-8") as f:
        fieldnames = list(merged[0].keys()) if merged else []
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(merged)

    # --- Run regressions ---
    print("Running mechanism tests...")

    # Filter to cities with at least some genre emergence data
    test_rows = [r for r in merged if r["n_bands"] >= 10]

    results = []

    # Test 1: density -> n_genre_emergences
    x = [r["density"] for r in test_rows]
    y = [r["n_genre_emergences"] for r in test_rows]
    a, b, r2, n = ols_simple(x, y)
    results.append(("Density -> Genre emergences (count)", a, b, r2, n))

    # Test 2: avg_clustering -> n_genre_emergences
    x = [r["avg_clustering"] for r in test_rows]
    a, b, r2, n = ols_simple(x, y)
    results.append(("Avg clustering -> Genre emergences (count)", a, b, r2, n))

    # Test 3: bridge_pct -> n_genre_emergences
    x = [r["bridge_pct"] for r in test_rows]
    a, b, r2, n = ols_simple(x, y)
    results.append(("Bridge musician % -> Genre emergences (count)", a, b, r2, n))

    # Test 4: density -> n_genre_emergences, controlling for n_bands
    x = [r["density"] for r in test_rows]
    c = [r["n_bands"] for r in test_rows]
    a, b, r2, n = ols_residualize(x, y, c)
    results.append(("Density -> Genre emergences (residualized on n_bands)", a, b, r2, n))

    # Test 5: avg_clustering -> n_genre_emergences, controlling for n_bands
    x = [r["avg_clustering"] for r in test_rows]
    a, b, r2, n = ols_residualize(x, y, c)
    results.append(("Avg clustering -> Genre emergences (residualized on n_bands)", a, b, r2, n))

    # Test 6: bridge_pct -> n_genre_emergences, controlling for n_bands
    x = [r["bridge_pct"] for r in test_rows]
    a, b, r2, n = ols_residualize(x, y, c)
    results.append(("Bridge % -> Genre emergences (residualized on n_bands)", a, b, r2, n))

    # --- Write results ---
    print(f"Writing {OUT_RESULTS}...")
    result_map = {label: (a, b, r2, n) for label, a, b, r2, n in results}
    strongest_resid = max(
        (
            (label, vals[2]) for label, vals in result_map.items()
            if "residualized" in label and vals[2] is not None
        ),
        key=lambda item: item[1],
        default=(None, None),
    )

    with open(OUT_RESULTS, "w", encoding="utf-8") as f:
        f.write("# Mechanism Test: Does Network Topology Predict Genre Emergence?\n\n")
        f.write(f"Cities in sample (10+ bands with network data): {len(test_rows)}\n\n")
        f.write("## Results\n\n")
        f.write("| Test | Intercept | Coefficient | R-squared | N |\n")
        f.write("|------|-----------|-------------|-----------|---|\n")
        for label, a, b, r2, n in results:
            a_str = f"{a:.3f}" if a is not None else "n/a"
            b_str = f"{b:.3f}" if b is not None else "n/a"
            r2_str = f"{r2:.3f}" if r2 is not None else "n/a"
            f.write(f"| {label} | {a_str} | {b_str} | {r2_str} | {n} |\n")

        density_raw = result_map["Density -> Genre emergences (count)"][1]
        density_resid = result_map["Density -> Genre emergences (residualized on n_bands)"][1]
        clustering_resid = result_map["Avg clustering -> Genre emergences (residualized on n_bands)"][1]
        bridge_resid = result_map["Bridge % -> Genre emergences (residualized on n_bands)"][1]

        f.write("\n## Current read\n\n")
        f.write(
            f"- Raw density association is {sign_label(density_raw)} in this run, not mechanically positive.\n"
        )
        f.write(
            f"- After residualizing on city size, density remains {sign_label(density_resid)}, "
            f"while clustering is {sign_label(clustering_resid)} and bridge share is {sign_label(bridge_resid)}.\n"
        )
        if strongest_resid[0] is not None:
            f.write(
                f"- The strongest residualized cross-sectional fit in this pass is `{strongest_resid[0]}` "
                f"with R-squared {strongest_resid[1]:.3f}.\n"
            )

        f.write("\n## Interpretation\n\n")
        f.write("These are first-pass cross-sectional diagnostics, not a causal design.\n")
        f.write("The main use is to see whether simple network structure measures still line up\n")
        f.write("with genre emergence once city size is partialled out. Mixed signs are therefore\n")
        f.write("informative rather than a failure: they can indicate that dense local cliques and\n")
        f.write("broader bridge-heavy scenes are capturing different mechanisms.\n\n")
        f.write("**Cautions:**\n")
        f.write("- These are simple OLS cross-sections, not causal estimates.\n")
        f.write("- Network stats and genre emergence are measured contemporaneously.\n")
        f.write("- The ideal test uses network topology *before* genre emergence.\n")
        f.write("- With the full member data (including years_active), we can build\n")
        f.write("  lagged network topology and test whether pre-emergence network\n")
        f.write("  structure predicts subsequent genre crystallisation.\n")

    print("Done.")


def write_skeleton_results():
    """Write placeholder results when network data is not yet available."""
    with open(OUT_RESULTS, "w", encoding="utf-8") as f:
        f.write("# Mechanism Test: Does Network Topology Predict Genre Emergence?\n\n")
        f.write("**Status: waiting for member data.**\n\n")
        f.write("The city network stats file has not been built yet.\n")
        f.write("This requires the Metal Archives member dump, which has been requested.\n\n")
        f.write("Once available, run:\n")
        f.write("1. `python code/20_ingest_member_data.py <member_dump.csv>`\n")
        f.write("2. `python code/21_build_city_networks.py`\n")
        f.write("3. `python code/23_test_network_predicts_genre.py`\n")
    print(f"Wrote skeleton to {OUT_RESULTS}")


if __name__ == "__main__":
    main()
