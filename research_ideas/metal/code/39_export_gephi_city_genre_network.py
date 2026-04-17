from __future__ import annotations

import argparse
import csv
import re
import unicodedata
from collections import Counter
from itertools import combinations
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
EDGE_PATH = SCENE_DIR / "full_musician_band_edges.csv"
OUT_DIR = SCENE_DIR / "gephi_exports"

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


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return value.strip("_")


def normalize_text(value: object) -> str:
    if value is None:
        return ""
    normalized = unicodedata.normalize("NFKD", str(value))
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    return " ".join(ascii_text.split())


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export a city-genre musician collaboration network for Gephi."
    )
    parser.add_argument("--city", default="Helsinki")
    parser.add_argument("--country", default="Finland")
    parser.add_argument("--genre-family", default="death_metal")
    parser.add_argument("--year", type=int, default=2005)
    return parser.parse_args()


def parse_genre_families(genre_raw: object) -> list[str]:
    text = str(genre_raw).lower()
    families: list[str] = []
    for key in GENRE_FAMILY_KEYS:
        if key in text:
            families.append(GENRE_FAMILIES[key])
    if not families and "metal" in text:
        families.append("other_metal")
    return sorted(set(families))


def is_active_in_year(row: pd.Series, year: int) -> bool:
    first_year = pd.to_numeric(row["first_year_in_band"], errors="coerce")
    last_year = pd.to_numeric(row["last_year_in_band"], errors="coerce")
    return bool(
        (pd.notna(first_year) and first_year <= year and (pd.isna(last_year) or last_year >= year))
        or (pd.isna(first_year) and pd.notna(last_year) and last_year >= year)
    )


def load_active_edges(city: str, country: str, genre_family: str, year: int) -> pd.DataFrame:
    usecols = [
        "band_id",
        "member_id",
        "member_name",
        "role",
        "first_year_in_band",
        "last_year_in_band",
        "band_name",
        "country",
        "city",
        "genre_raw",
    ]
    chunks: list[pd.DataFrame] = []
    for chunk in pd.read_csv(
        EDGE_PATH,
        usecols=usecols,
        chunksize=100_000,
        engine="python",
        on_bad_lines="skip",
    ):
        chunk = chunk.loc[
            chunk["city"].astype(str).eq(city)
            & chunk["country"].astype(str).eq(country)
        ].copy()
        if chunk.empty:
            continue
        chunk["genre_families"] = chunk["genre_raw"].map(parse_genre_families)
        chunk = chunk.loc[chunk["genre_families"].map(lambda values: genre_family in values)].copy()
        if chunk.empty:
            continue
        chunk["active_i"] = chunk.apply(lambda row: is_active_in_year(row, year), axis=1)
        chunk = chunk.loc[chunk["active_i"].eq(True)].copy()
        if not chunk.empty:
            chunks.append(chunk)

    if not chunks:
        raise ValueError(f"No active edges found for {city}, {country} / {genre_family} / {year}.")

    edges = pd.concat(chunks, ignore_index=True)
    edges["band_id"] = pd.to_numeric(edges["band_id"], errors="coerce").astype(int)
    edges["member_id"] = pd.to_numeric(edges["member_id"], errors="coerce").astype(int)
    return edges.drop_duplicates(subset=["band_id", "member_id", "role"]).reset_index(drop=True)


def build_node_table(active_edges: pd.DataFrame) -> pd.DataFrame:
    role_strings = (
        active_edges.groupby("member_id")["role"]
        .agg(lambda values: "; ".join(sorted(set(normalize_text(value) for value in values if normalize_text(value)))))
        .to_dict()
    )
    band_lists = (
        active_edges.groupby("member_id")["band_name"]
        .agg(lambda values: sorted(set(normalize_text(value) for value in values if normalize_text(value))))
        .to_dict()
    )
    genre_lists = (
        active_edges.groupby("member_id")["genre_raw"]
        .agg(lambda values: sorted(set(normalize_text(value) for value in values if normalize_text(value))))
        .to_dict()
    )

    node_rows: list[dict[str, object]] = []
    for member_id, group in active_edges.groupby("member_id"):
        band_counter = Counter(normalize_text(value) for value in group["band_name"] if normalize_text(value))
        primary_band = sorted(band_counter.items(), key=lambda item: (-item[1], item[0]))[0][0]
        node_rows.append(
            {
                "id": int(member_id),
                "label": normalize_text(group["member_name"].iloc[0]),
                "city": normalize_text(group["city"].iloc[0]),
                "country": normalize_text(group["country"].iloc[0]),
                "primary_band": primary_band,
                "band_count": len(band_lists[int(member_id)]),
                "bands": " | ".join(band_lists[int(member_id)]),
                "roles": role_strings[int(member_id)],
                "raw_genres": " | ".join(genre_lists[int(member_id)]),
                "is_multi_band_connector": int(len(band_lists[int(member_id)]) >= 2),
            }
        )

    nodes = pd.DataFrame(node_rows).sort_values(
        ["is_multi_band_connector", "band_count", "label", "id"],
        ascending=[False, False, True, True],
    )
    return nodes.reset_index(drop=True)


def build_edge_table(active_edges: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for band_id, group in active_edges.groupby("band_id"):
        band_name = normalize_text(group["band_name"].iloc[0])
        member_rows = (
            group[["member_id", "member_name"]]
            .drop_duplicates()
            .sort_values(["member_name", "member_id"])
        )
        member_ids = member_rows["member_id"].astype(int).tolist()
        member_names = member_rows["member_name"].map(normalize_text).tolist()
        lookup = dict(zip(member_ids, member_names, strict=True))
        for source_id, target_id in combinations(member_ids, 2):
            source_id, target_id = sorted((int(source_id), int(target_id)))
            rows.append(
                {
                    "source": source_id,
                    "target": target_id,
                    "shared_band": band_name,
                    "shared_band_id": int(band_id),
                    "pair_label": f"{lookup[source_id]} <> {lookup[target_id]}",
                }
            )

    if not rows:
        return pd.DataFrame(
            columns=[
                "source",
                "target",
                "weight",
                "shared_band_count",
                "shared_bands",
                "pair_label",
                "repeated_tie_i",
            ]
        )

    collapsed = (
        pd.DataFrame(rows)
        .groupby(["source", "target"], as_index=False)
        .agg(
            weight=("shared_band", "count"),
            shared_band_count=("shared_band", "count"),
            shared_bands=("shared_band", lambda values: " | ".join(sorted(set(values)))),
            pair_label=("pair_label", "first"),
        )
    )
    collapsed["repeated_tie_i"] = (collapsed["weight"] >= 2).astype(int)
    collapsed["edge_width_seed"] = collapsed["weight"].map(lambda value: 1.0 + 1.6 * float(value))
    return collapsed.sort_values(["weight", "source", "target"], ascending=[False, True, True]).reset_index(drop=True)


def add_style_seed_columns(nodes: pd.DataFrame, edges: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    nodes = nodes.copy()
    edges = edges.copy()

    degree_lookup = {int(node_id): 0 for node_id in nodes["id"]}
    weighted_degree_lookup = {int(node_id): 0.0 for node_id in nodes["id"]}

    for row in edges.itertuples(index=False):
        source_id = int(row.source)
        target_id = int(row.target)
        degree_lookup[source_id] += 1
        degree_lookup[target_id] += 1
        weighted_degree_lookup[source_id] += float(row.weight)
        weighted_degree_lookup[target_id] += float(row.weight)

    nodes["degree_seed"] = nodes["id"].map(lambda value: degree_lookup.get(int(value), 0))
    nodes["weighted_degree_seed"] = nodes["id"].map(
        lambda value: weighted_degree_lookup.get(int(value), 0.0)
    )
    nodes["node_size_seed"] = (
        12
        + 6 * nodes["band_count"].astype(float)
        + 3 * nodes["weighted_degree_seed"].astype(float)
    ).round(2)
    nodes["label_priority"] = (
        10
        + 20 * nodes["is_multi_band_connector"].astype(float)
        + 3 * nodes["band_count"].astype(float)
        + 2 * nodes["weighted_degree_seed"].astype(float)
    ).round(2)
    priority_cutoff = max(1, min(18, len(nodes) // 6))
    nodes["label_show_i"] = 0
    top_nodes = nodes.sort_values(
        ["label_priority", "weighted_degree_seed", "label"],
        ascending=[False, False, True],
    ).head(priority_cutoff)
    nodes.loc[nodes["id"].isin(top_nodes["id"]), "label_show_i"] = 1

    return nodes, edges


def write_summary(
    city: str,
    country: str,
    genre_family: str,
    year: int,
    nodes: pd.DataFrame,
    edges: pd.DataFrame,
    node_path: Path,
    edge_path: Path,
    summary_path: Path,
    recipe_path: Path,
) -> None:
    top_bands = (
        nodes.groupby("primary_band")["id"]
        .count()
        .sort_values(ascending=False)
        .head(8)
    )
    repeated_ties = int(edges["repeated_tie_i"].sum()) if not edges.empty else 0
    lines = [
        "# Gephi export summary",
        "",
        f"- Case: `{city}, {country}` / `{genre_family}` / `{year}`",
        f"- Node file: `{node_path.name}`",
        f"- Edge file: `{edge_path.name}`",
        f"- Gephi recipe: `{recipe_path.name}`",
        f"- Active musicians: `{len(nodes):,}`",
        f"- Collaboration edges: `{len(edges):,}`",
        f"- Repeated ties: `{repeated_ties:,}`",
        f"- Multi-band connectors: `{int(nodes['is_multi_band_connector'].sum()):,}`",
        "",
        "## Why this case is a better Gephi candidate",
        "",
        "- This is a genuinely thick local scene rather than a tiny pre-emergence microcase.",
        "- Node colors can be mapped to `primary_band` in Gephi.",
        "- Edge thickness can be mapped to `weight`.",
        "- The graph is large enough to look like a real scene map, but still small enough to style by hand.",
        "",
        "## Largest primary-band groups in the export",
        "",
        "| Primary band | Musicians |",
        "| --- | ---: |",
    ]
    for band_name, count in top_bands.items():
        lines.append(f"| {band_name} | {int(count)} |")
    lines.extend(
        [
            "",
            "## Suggested Gephi import and styling",
            "",
            "1. Import the node and edge CSV files as an undirected graph.",
            "2. Run `ForceAtlas 2` with edge-weight influence on and prevent overlap on.",
            "3. Size nodes by `node_size_seed` or `weighted_degree_seed` after import.",
            "4. Color nodes by `primary_band` or by modularity class if Gephi finds clearer communities.",
            "5. Map edge thickness to `edge_width_seed` or `weight` and keep light transparency on weak ties.",
            "6. Show labels only for rows where `label_show_i = 1`, then export to `SVG` or `PDF`.",
        ]
    )
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_recipe(
    city: str,
    country: str,
    genre_family: str,
    year: int,
    node_path: Path,
    edge_path: Path,
    recipe_path: Path,
) -> None:
    lines = [
        "# Gephi recipe",
        "",
        f"Case: `{city}, {country}` / `{genre_family}` / `{year}`",
        "",
        "## Files",
        "",
        f"- Nodes: `{node_path.name}`",
        f"- Edges: `{edge_path.name}`",
        "",
        "## Import",
        "",
        "1. Open Gephi and create a new project.",
        "2. Import the edge CSV first as an `Undirected` graph.",
        "3. Import the node CSV into the existing workspace and merge on `id`.",
        "4. Confirm that Gephi reads `weight` as a numeric edge attribute.",
        "",
        "## Statistics",
        "",
        "1. Run `Average Degree`.",
        "2. Run `Modularity` if you want a community-color alternative to `primary_band`.",
        "",
        "## Layout",
        "",
        "1. Start with `ForceAtlas 2`.",
        "2. Suggested starting settings:",
        "   Scaling: `18`",
        "   Gravity: `1.5`",
        "   Strong gravity: `On`",
        "   LinLog mode: `On`",
        "   Prevent overlap: `On`",
        "   Edge weight influence: `1.0`",
        "3. Let the graph settle, then stop when the band-colored pockets are separated but still connected.",
        "",
        "## Styling",
        "",
        "1. Node color:",
        "   Use `Appearance > Nodes > Partition > primary_band` for the band-affiliation map.",
        "   Or use `Modularity Class` if the algorithm finds cleaner communities.",
        "2. Node size:",
        "   Use `Appearance > Nodes > Ranking > node_size_seed`.",
        "   Suggested range: `18` to `70`.",
        "3. Edge width:",
        "   Use `Appearance > Edges > Ranking > edge_width_seed`.",
        "   Suggested range: `0.2` to `3.5`.",
        "4. Edge color:",
        "   Keep a single muted grey or brown tone and lower opacity in `Preview`.",
        "5. Labels:",
        "   Filter or manually label only nodes with `label_show_i = 1`.",
        "   Prioritize connector names and the highest `weighted_degree_seed` nodes.",
        "",
        "## Export target",
        "",
        "1. Use `Preview` to soften edges and increase label readability.",
        "2. Export to `SVG` first if you want to clean labels later.",
        "3. Export to `PDF` for the paper draft once the layout is fixed.",
        "",
        "## Practical note",
        "",
        "This case was chosen because it is large enough to look like a real local labor-market network in Gephi, unlike the much smaller Pittsburgh pre-emergence case.",
    ]
    recipe_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    city_slug = slugify(args.city)
    country_slug = slugify(args.country)
    genre_slug = slugify(args.genre_family)
    base_slug = f"{city_slug}_{country_slug}_{genre_slug}_{args.year}"

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    active_edges = load_active_edges(args.city, args.country, args.genre_family, args.year)
    nodes = build_node_table(active_edges)
    edges = build_edge_table(active_edges)
    nodes, edges = add_style_seed_columns(nodes, edges)

    node_path = OUT_DIR / f"{base_slug}_nodes.csv"
    edge_path = OUT_DIR / f"{base_slug}_edges.csv"
    summary_path = OUT_DIR / f"{base_slug}_summary.md"
    recipe_path = OUT_DIR / f"{base_slug}_gephi_recipe.md"

    nodes.to_csv(node_path, index=False, quoting=csv.QUOTE_MINIMAL)
    edges.to_csv(edge_path, index=False, quoting=csv.QUOTE_MINIMAL)
    write_recipe(
        args.city,
        args.country,
        args.genre_family,
        args.year,
        node_path,
        edge_path,
        recipe_path,
    )
    write_summary(
        args.city,
        args.country,
        args.genre_family,
        args.year,
        nodes,
        edges,
        node_path,
        edge_path,
        summary_path,
        recipe_path,
    )

    print(f"Wrote {node_path}")
    print(f"Wrote {edge_path}")
    print(f"Wrote {recipe_path}")
    print(f"Wrote {summary_path}")


if __name__ == "__main__":
    main()
