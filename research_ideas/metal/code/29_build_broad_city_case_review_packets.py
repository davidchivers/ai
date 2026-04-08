"""
29_build_broad_city_case_review_packets.py

Build reusable review packets for the broad surviving city-scene cases.
The goal is to move from a shortlist of city-genre names to concrete
network evidence that can be inspected case by case.

Inputs:
    data/processed/scene_networks/broad_city_precedes_case_shortlist.csv
    data/processed/scene_networks/community_vs_label_timing.csv
    data/processed/scene_networks/full_musician_band_edges.csv
    data/processed/metal_archives_all_metal_band_clean.csv

Outputs:
    data/processed/scene_networks/broad_city_case_review_summary.csv
    data/processed/scene_networks/broad_city_case_review_supporting_bands.csv
    data/processed/scene_networks/broad_city_case_review_bridge_musicians.csv
    data/processed/scene_networks/broad_city_case_review_packets.md

Usage:
    python code/29_build_broad_city_case_review_packets.py
"""

from __future__ import annotations

import csv
import importlib.util
import os
from collections import Counter, defaultdict


CODE_DIR = os.path.dirname(__file__)
PROJECT_DIR = os.path.join(CODE_DIR, "..")
DATA_DIR = os.path.join(PROJECT_DIR, "data", "processed", "scene_networks")
SHORTLIST_FILE = os.path.join(DATA_DIR, "broad_city_precedes_case_shortlist.csv")
TIMING_FILE = os.path.join(DATA_DIR, "community_vs_label_timing.csv")
EDGE_FILE = os.path.join(DATA_DIR, "full_musician_band_edges.csv")

OUT_SUMMARY_CSV = os.path.join(DATA_DIR, "broad_city_case_review_summary.csv")
OUT_BANDS_CSV = os.path.join(DATA_DIR, "broad_city_case_review_supporting_bands.csv")
OUT_BRIDGES_CSV = os.path.join(DATA_DIR, "broad_city_case_review_bridge_musicians.csv")
OUT_MD = os.path.join(DATA_DIR, "broad_city_case_review_packets.md")


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


def load_scene_module():
    module_path = os.path.join(CODE_DIR, "24_test_community_precedes_label.py")
    spec = importlib.util.spec_from_file_location("scene24", module_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def load_shortlist() -> list[dict[str, str]]:
    with open(SHORTLIST_FILE, "r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def load_timing_lookup() -> dict[tuple[str, str], dict[str, str]]:
    lookup: dict[tuple[str, str], dict[str, str]] = {}
    with open(TIMING_FILE, "r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            lookup[(row["city_country"], row["genre_family"])] = row
    return lookup


def load_member_names(scene_mod, band_reference, target_cities: set[str]) -> dict[str, str]:
    member_names: dict[str, str] = {}
    with open(EDGE_FILE, "r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            band_id = scene_mod.normalize_text(row.get("band_id", ""))
            band_meta = band_reference.get(band_id)
            if band_meta is None or band_meta["city_country"] not in target_cities:
                continue

            member_id = scene_mod.normalize_text(row.get("member_id", "")) or scene_mod.normalize_text(
                row.get("member_name", "")
            )
            member_name = scene_mod.normalize_text(row.get("member_name", ""))
            if member_id and member_name and member_id not in member_names:
                member_names[member_id] = member_name
    return member_names


def build_snapshot(scene_mod, city_band_metadata, city_stints, snapshot_year: int):
    band_events = defaultdict(list)
    year_events = defaultdict(list)

    for band_id, metadata in city_band_metadata.items():
        formed_year = metadata["formed_year"]
        if formed_year <= snapshot_year:
            band_events[formed_year].append(band_id)

    for musician, stints in city_stints.items():
        for band_id, start_year, end_year in stints:
            if start_year > snapshot_year:
                continue
            year_events[start_year].append(("add", musician, band_id))
            if end_year is not None and end_year + 1 <= snapshot_year:
                year_events[end_year + 1].append(("remove", musician, band_id))

    years = sorted(set(band_events) | set(year_events))
    active_bands = set()
    active_bands_by_musician = defaultdict(set)
    pair_counts = defaultdict(int)

    for year in years:
        if year > snapshot_year:
            break

        for band_id in band_events.get(year, []):
            active_bands.add(band_id)

        for action, musician, band_id in year_events.get(year, []):
            if action == "add":
                scene_mod.add_active_membership(active_bands_by_musician, pair_counts, musician, band_id)
            else:
                scene_mod.remove_active_membership(active_bands_by_musician, pair_counts, musician, band_id)

    active_band_set = {
        band_id for band_id in active_bands if city_band_metadata[band_id]["formed_year"] <= snapshot_year
    }
    active_edges = {
        pair
        for pair, weight in pair_counts.items()
        if weight > 0 and pair[0] in active_band_set and pair[1] in active_band_set
    }

    return active_band_set, active_edges, active_bands_by_musician


def select_supported_community(scene_mod, city_band_metadata, active_band_set, active_edges, genre_family: str):
    communities, modularity_q = scene_mod.detect_communities(active_band_set, active_edges, "label_prop")
    best_members = None
    best_summary = None

    for members in communities.values():
        counts = Counter()
        for band_id in members:
            counts.update(city_band_metadata[band_id]["genre_families"])

        genre_bands = counts.get(genre_family, 0)
        community_size = len(members)
        genre_share = genre_bands / community_size if community_size else 0.0
        if genre_bands < 4 or genre_share < 0.67:
            continue

        candidate = {
            "community_size": community_size,
            "genre_bands": genre_bands,
            "genre_share": genre_share,
        }
        score = (candidate["genre_share"], candidate["genre_bands"], candidate["community_size"])
        current_score = None
        if best_summary is not None:
            current_score = (
                best_summary["genre_share"],
                best_summary["genre_bands"],
                best_summary["community_size"],
            )
        if best_summary is None or score > current_score:
            best_members = set(members)
            best_summary = candidate

    return best_members, best_summary, modularity_q


def classify_topology(bridge_musician_ct: int, max_bridge_band_span: int, community_size: int) -> str:
    if bridge_musician_ct <= 1 and max_bridge_band_span >= community_size:
        return "single_bridge_risk"
    if bridge_musician_ct >= 3 and max_bridge_band_span <= max(community_size - 1, 2):
        return "multi_bridge_support"
    return "hub_bridge_mixed"


def classify_timing(lead_years: int) -> str:
    if lead_years >= 6:
        return "long_lead"
    if lead_years >= 3:
        return "mid_lead"
    return "short_lead"


def build_case_outputs(
    scene_mod,
    shortlist_rows: list[dict[str, str]],
    timing_lookup: dict[tuple[str, str], dict[str, str]],
):
    band_reference, city_bands = scene_mod.load_band_reference()
    target_cities = {row["city_country"] for row in shortlist_rows}
    stints_by_city = scene_mod.load_member_stints(EDGE_FILE, band_reference, target_cities)
    member_names = load_member_names(scene_mod, band_reference, target_cities)

    summary_rows: list[dict[str, object]] = []
    supporting_band_rows: list[dict[str, object]] = []
    bridge_rows: list[dict[str, object]] = []

    for row in shortlist_rows:
        city_country = row["city_country"]
        genre_family = row["genre_family"]
        timing_row = timing_lookup[(city_country, genre_family)]
        detection_year = safe_int(row["community_detect_year"])
        lead_years = safe_int(row["lead_years"])

        active_band_set, active_edges, active_bands_by_musician = build_snapshot(
            scene_mod=scene_mod,
            city_band_metadata=city_bands[city_country],
            city_stints=stints_by_city[city_country],
            snapshot_year=detection_year,
        )
        community_members, community_summary, modularity_q = select_supported_community(
            scene_mod=scene_mod,
            city_band_metadata=city_bands[city_country],
            active_band_set=active_band_set,
            active_edges=active_edges,
            genre_family=genre_family,
        )
        if not community_members or not community_summary:
            raise RuntimeError(f"No supporting community recovered for {city_country} / {genre_family}")

        community_edges = [
            pair for pair in active_edges if pair[0] in community_members and pair[1] in community_members
        ]
        max_possible_edges = community_summary["community_size"] * (community_summary["community_size"] - 1) / 2.0
        community_density = len(community_edges) / max_possible_edges if max_possible_edges else 0.0

        bridge_musicians = []
        for member_id, bands in active_bands_by_musician.items():
            in_community = sorted(community_members.intersection(bands))
            if len(in_community) < 2:
                continue
            bridge_musicians.append(
                {
                    "member_id": member_id,
                    "member_name": member_names.get(member_id, member_id),
                    "n_community_bands": len(in_community),
                    "n_city_active_bands": len([band_id for band_id in bands if band_id in active_band_set]),
                    "community_band_ids": in_community,
                }
            )
        bridge_musicians.sort(
            key=lambda item: (-item["n_community_bands"], str(item["member_name"]), str(item["member_id"]))
        )

        max_bridge_band_span = max((item["n_community_bands"] for item in bridge_musicians), default=0)
        topology_read = classify_topology(
            bridge_musician_ct=len(bridge_musicians),
            max_bridge_band_span=max_bridge_band_span,
            community_size=community_summary["community_size"],
        )
        timing_read = classify_timing(lead_years)

        supporting_bands = []
        for band_id in sorted(
            community_members,
            key=lambda current: (
                0 if genre_family in city_bands[city_country][current]["genre_families"] else 1,
                city_bands[city_country][current]["formed_year"],
                city_bands[city_country][current]["band_name"].lower(),
            ),
        ):
            band_meta = city_bands[city_country][band_id]
            community_degree = sum(
                1 for pair in community_edges if band_id == pair[0] or band_id == pair[1]
            )
            supporting_bands.append(
                {
                    "city_country": city_country,
                    "genre_family": genre_family,
                    "review_tier": row["review_tier"],
                    "detection_year": detection_year,
                    "band_id": band_id,
                    "band_name": band_meta["band_name"],
                    "formed_year": band_meta["formed_year"],
                    "in_target_genre_i": int(genre_family in band_meta["genre_families"]),
                    "genre_families": ";".join(sorted(band_meta["genre_families"])),
                    "community_degree": community_degree,
                }
            )
        supporting_band_rows.extend(supporting_bands)

        for bridge in bridge_musicians:
            bridge_rows.append(
                {
                    "city_country": city_country,
                    "genre_family": genre_family,
                    "detection_year": detection_year,
                    "member_id": bridge["member_id"],
                    "member_name": bridge["member_name"],
                    "n_community_bands": bridge["n_community_bands"],
                    "n_city_active_bands": bridge["n_city_active_bands"],
                    "community_bands": "; ".join(
                        city_bands[city_country][band_id]["band_name"] for band_id in bridge["community_band_ids"]
                    ),
                }
            )

        summary_rows.append(
            {
                "city": row["city"],
                "country": row["country"],
                "city_country": city_country,
                "genre_family": genre_family,
                "review_tier": row["review_tier"],
                "lead_years": lead_years,
                "detection_year": detection_year,
                "emergence_year": safe_int(row["emergence_year"]),
                "detection_city_active_bands": safe_int(timing_row["detection_city_active_bands"]),
                "label_year_active_bands": safe_int(timing_row["label_year_active_bands"]),
                "active_band_growth_to_label": safe_int(timing_row["label_year_active_bands"])
                - safe_int(timing_row["detection_city_active_bands"]),
                "community_size": community_summary["community_size"],
                "genre_bands_in_supporting_community": community_summary["genre_bands"],
                "genre_share_in_supporting_community": f"{community_summary['genre_share']:.3f}",
                "community_edge_count": len(community_edges),
                "community_edge_density": f"{community_density:.3f}",
                "bridge_musician_ct": len(bridge_musicians),
                "max_bridge_band_span": max_bridge_band_span,
                "active_city_edges_at_detection": len(active_edges),
                "active_city_bands_at_detection_rebuilt": len(active_band_set),
                "modularity_q_at_detection": f"{modularity_q:.3f}",
                "topology_read": topology_read,
                "timing_read": timing_read,
                "supporting_bands": "; ".join(band["band_name"] for band in supporting_bands),
            }
        )

    summary_rows.sort(
        key=lambda item: (
            0 if item["review_tier"] == "strong_keep_candidate" else 1,
            0 if item["topology_read"] == "multi_bridge_support" else 1 if item["topology_read"] == "hub_bridge_mixed" else 2,
            -safe_int(str(item["lead_years"])),
            str(item["city_country"]),
        )
    )
    supporting_band_rows.sort(
        key=lambda item: (
            item["city_country"],
            item["genre_family"],
            item["formed_year"],
            item["band_name"].lower(),
        )
    )
    bridge_rows.sort(
        key=lambda item: (
            item["city_country"],
            item["genre_family"],
            -safe_int(str(item["n_community_bands"])),
            item["member_name"].lower(),
        )
    )
    return summary_rows, supporting_band_rows, bridge_rows


def write_csv(path: str, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with open(path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows([{field: row.get(field, "") for field in fieldnames} for row in rows])


def write_md(
    summary_rows: list[dict[str, object]],
    supporting_band_rows: list[dict[str, object]],
    bridge_rows: list[dict[str, object]],
) -> None:
    bands_by_case = defaultdict(list)
    for row in supporting_band_rows:
        bands_by_case[(str(row["city_country"]), str(row["genre_family"]))].append(row)

    bridges_by_case = defaultdict(list)
    for row in bridge_rows:
        bridges_by_case[(str(row["city_country"]), str(row["genre_family"]))].append(row)

    topology_counts = Counter(str(row["topology_read"]) for row in summary_rows)
    timing_counts = Counter(str(row["timing_read"]) for row in summary_rows)

    with open(OUT_MD, "w", encoding="utf-8") as handle:
        handle.write("# Broad city case review packets\n\n")
        handle.write("- Scope: `broad_scene_case` shortlist reconstructed at each case's detection year\n")
        handle.write("- Interpretation: this is local network evidence for manual validation, not a final historical truth claim\n")
        handle.write(f"- Cases reviewed: `{len(summary_rows)}`\n")
        handle.write(f"- `multi_bridge_support`: `{topology_counts['multi_bridge_support']}`\n")
        handle.write(f"- `hub_bridge_mixed`: `{topology_counts['hub_bridge_mixed']}`\n")
        handle.write(f"- `single_bridge_risk`: `{topology_counts['single_bridge_risk']}`\n")
        handle.write(f"- `long_lead`: `{timing_counts['long_lead']}`\n")
        handle.write(f"- `mid_lead`: `{timing_counts['mid_lead']}`\n")
        handle.write(f"- `short_lead`: `{timing_counts['short_lead']}`\n\n")

        handle.write("## Summary table\n\n")
        handle.write("| City | Genre | Lead | Supporting bands | Bridge musicians | Topology read | Timing read |\n")
        handle.write("|------|-------|------|------------------|------------------|---------------|-------------|\n")
        for row in summary_rows:
            handle.write(
                f"| {row['city_country']} | {row['genre_family']} | {row['lead_years']} | "
                f"{row['community_size']} | {row['bridge_musician_ct']} | {row['topology_read']} | "
                f"{row['timing_read']} |\n"
            )

        for row in summary_rows:
            case_key = (str(row["city_country"]), str(row["genre_family"]))
            case_bands = bands_by_case[case_key]
            case_bridges = bridges_by_case[case_key]

            handle.write(f"\n## {row['city_country']} - {row['genre_family']}\n\n")
            handle.write(f"- Review tier: `{row['review_tier']}`\n")
            handle.write(
                f"- Timing: detection year `{row['detection_year']}`, label year `{row['emergence_year']}`, "
                f"lead `{row['lead_years']}` years (`{row['timing_read']}`)\n"
            )
            handle.write(
                f"- City scale at detection: `{row['detection_city_active_bands']}` active bands and "
                f"`{row['active_city_edges_at_detection']}` active shared-member edges\n"
            )
            handle.write(
                f"- Supporting community: `{row['community_size']}` bands, "
                f"`{row['genre_bands_in_supporting_community']}` target-genre bands, "
                f"genre share `{row['genre_share_in_supporting_community']}`, "
                f"community density `{row['community_edge_density']}`\n"
            )
            handle.write(
                f"- Bridge structure: `{row['bridge_musician_ct']}` musicians active in `2+` community bands; "
                f"largest span `{row['max_bridge_band_span']}` (`{row['topology_read']}`)\n"
            )
            handle.write(
                f"- City growth to label year: `{row['label_year_active_bands']}` active city bands by label year "
                f"(change of `{row['active_band_growth_to_label']}` from detection year)\n\n"
            )

            handle.write("Supporting bands:\n")
            for band in case_bands:
                target_flag = "target" if safe_int(str(band["in_target_genre_i"])) == 1 else "non-target"
                handle.write(
                    f"- `{band['band_name']}` (`{band['formed_year']}`; {target_flag}; "
                    f"community degree `{band['community_degree']}`)\n"
                )

            if case_bridges:
                handle.write("Bridge musicians:\n")
                for bridge in case_bridges[:6]:
                    handle.write(
                        f"- `{bridge['member_name']}` links `{bridge['n_community_bands']}` community bands: "
                        f"{bridge['community_bands']}\n"
                    )
            else:
                handle.write("Bridge musicians:\n")
                handle.write("- None recovered at detection year\n")


def main() -> None:
    scene_mod = load_scene_module()
    shortlist_rows = load_shortlist()
    timing_lookup = load_timing_lookup()
    summary_rows, supporting_band_rows, bridge_rows = build_case_outputs(
        scene_mod=scene_mod,
        shortlist_rows=shortlist_rows,
        timing_lookup=timing_lookup,
    )

    write_csv(
        OUT_SUMMARY_CSV,
        summary_rows,
        [
            "city",
            "country",
            "city_country",
            "genre_family",
            "review_tier",
            "lead_years",
            "detection_year",
            "emergence_year",
            "detection_city_active_bands",
            "label_year_active_bands",
            "active_band_growth_to_label",
            "community_size",
            "genre_bands_in_supporting_community",
            "genre_share_in_supporting_community",
            "community_edge_count",
            "community_edge_density",
            "bridge_musician_ct",
            "max_bridge_band_span",
            "active_city_edges_at_detection",
            "active_city_bands_at_detection_rebuilt",
            "modularity_q_at_detection",
            "topology_read",
            "timing_read",
            "supporting_bands",
        ],
    )
    write_csv(
        OUT_BANDS_CSV,
        supporting_band_rows,
        [
            "city_country",
            "genre_family",
            "review_tier",
            "detection_year",
            "band_id",
            "band_name",
            "formed_year",
            "in_target_genre_i",
            "genre_families",
            "community_degree",
        ],
    )
    write_csv(
        OUT_BRIDGES_CSV,
        bridge_rows,
        [
            "city_country",
            "genre_family",
            "detection_year",
            "member_id",
            "member_name",
            "n_community_bands",
            "n_city_active_bands",
            "community_bands",
        ],
    )
    write_md(summary_rows, supporting_band_rows, bridge_rows)


if __name__ == "__main__":
    main()
