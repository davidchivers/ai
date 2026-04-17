from __future__ import annotations

import math
from collections import defaultdict, deque
from itertools import combinations
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import patheffects


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
EDGE_PATH = SCENE_DIR / "full_musician_band_edges.csv"
OUT_DIR = SCENE_DIR / "helsinki_long_window"
FIGURE_DIR = SCENE_DIR / "figures"

CITY = "Helsinki"
COUNTRY = "Finland"
START_YEAR = 2000
END_YEAR = 2004
CORE_MIN_BANDS = 3

BACKGROUND_COLOR = "#f7f4ee"
TEXT_COLOR = "#22201f"
MUTED_TEXT_COLOR = "#5b5650"
EDGE_COLOR = "#d1c8be"
REPEATED_EDGE_COLOR = "#73675d"
LEADER_COLOR = "#aca094"


def slug(value: str) -> str:
    return value.strip().lower().replace(" ", "_")


SLUG = f"{slug(CITY)}_{slug(COUNTRY)}_{START_YEAR}_{END_YEAR}"
FULL_NODES_PATH = OUT_DIR / f"{SLUG}_all_musicians_nodes.csv"
FULL_EDGES_PATH = OUT_DIR / f"{SLUG}_all_musicians_edges.csv"
CORE_NODES_PATH = OUT_DIR / f"{SLUG}_core{CORE_MIN_BANDS}_giant_nodes.csv"
CORE_EDGES_PATH = OUT_DIR / f"{SLUG}_core{CORE_MIN_BANDS}_giant_edges.csv"
SUMMARY_PATH = OUT_DIR / f"{SLUG}_summary.md"
PNG_PATH = FIGURE_DIR / f"{SLUG}_core{CORE_MIN_BANDS}_giant_label_network.png"
SVG_PATH = FIGURE_DIR / f"{SLUG}_core{CORE_MIN_BANDS}_giant_label_network.svg"


def configure_style() -> None:
    plt.rcParams.update(
        {
            "figure.facecolor": BACKGROUND_COLOR,
            "axes.facecolor": BACKGROUND_COLOR,
            "savefig.facecolor": BACKGROUND_COLOR,
            "font.family": "DejaVu Sans",
            "text.color": TEXT_COLOR,
        }
    )


def overlaps_window(row: pd.Series, start_year: int, end_year: int) -> bool:
    first_year = pd.to_numeric(row["first_year_in_band"], errors="coerce")
    last_year = pd.to_numeric(row["last_year_in_band"], errors="coerce")
    if pd.notna(first_year) and first_year > end_year:
        return False
    if pd.notna(last_year) and last_year < start_year:
        return False
    return True


def load_city_edges() -> pd.DataFrame:
    usecols = [
        "band_id",
        "member_id",
        "member_name",
        "band_name",
        "city",
        "country",
        "first_year_in_band",
        "last_year_in_band",
    ]
    chunks: list[pd.DataFrame] = []
    for chunk in pd.read_csv(
        EDGE_PATH,
        usecols=usecols,
        chunksize=200_000,
        engine="python",
        on_bad_lines="skip",
    ):
        chunk = chunk.loc[
            chunk["city"].astype(str).eq(CITY) & chunk["country"].astype(str).eq(COUNTRY)
        ].copy()
        if not chunk.empty:
            chunks.append(chunk)
    if not chunks:
        raise ValueError(f"No musician-band rows found for {CITY}, {COUNTRY}.")
    data = pd.concat(chunks, ignore_index=True)
    data["band_id"] = pd.to_numeric(data["band_id"], errors="coerce")
    data["member_id"] = pd.to_numeric(data["member_id"], errors="coerce")
    data = data.dropna(subset=["band_id", "member_id"]).copy()
    data["band_id"] = data["band_id"].astype(int)
    data["member_id"] = data["member_id"].astype(int)
    data = data.loc[data.apply(lambda row: overlaps_window(row, START_YEAR, END_YEAR), axis=1)].copy()
    return data.drop_duplicates(subset=["band_id", "member_id"]).reset_index(drop=True)


def build_network(active_edges: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    band_counts = active_edges.groupby("member_id")["band_id"].nunique().to_dict()
    name_lookup = active_edges.groupby("member_id")["member_name"].first().to_dict()
    band_lookup = (
        active_edges.groupby("member_id")["band_name"]
        .agg(lambda values: " | ".join(sorted({str(v) for v in values if str(v).strip()})))
        .to_dict()
    )

    edge_weights: defaultdict[tuple[int, int], int] = defaultdict(int)
    shared_band_lookup: defaultdict[tuple[int, int], set[str]] = defaultdict(set)
    for band_id, group in active_edges.groupby("band_id"):
        band_name = str(group["band_name"].iloc[0])
        member_ids = sorted(group["member_id"].astype(int).unique().tolist())
        for source_id, target_id in combinations(member_ids, 2):
            pair = (source_id, target_id)
            edge_weights[pair] += 1
            shared_band_lookup[pair].add(band_name)

    degree_lookup: defaultdict[int, int] = defaultdict(int)
    weighted_degree_lookup: defaultdict[int, int] = defaultdict(int)
    for (source_id, target_id), weight in edge_weights.items():
        degree_lookup[source_id] += 1
        degree_lookup[target_id] += 1
        weighted_degree_lookup[source_id] += weight
        weighted_degree_lookup[target_id] += weight

    node_rows = []
    for member_id in sorted(name_lookup):
        node_rows.append(
            {
                "id": int(member_id),
                "label": str(name_lookup[member_id]),
                "band_count": int(band_counts.get(member_id, 1)),
                "degree": int(degree_lookup.get(member_id, 0)),
                "weighted_degree": int(weighted_degree_lookup.get(member_id, 0)),
                "bands": str(band_lookup.get(member_id, "")),
            }
        )
    edge_rows = []
    for (source_id, target_id), weight in edge_weights.items():
        edge_rows.append(
            {
                "source": int(source_id),
                "target": int(target_id),
                "weight": int(weight),
                "repeated_tie_i": int(weight >= 2),
                "shared_bands": " | ".join(sorted(shared_band_lookup[(source_id, target_id)])),
            }
        )

    nodes = pd.DataFrame(node_rows).sort_values(
        ["band_count", "weighted_degree", "label"], ascending=[False, False, True]
    )
    edges = pd.DataFrame(edge_rows).sort_values(
        ["weight", "source", "target"], ascending=[False, True, True]
    )
    return nodes.reset_index(drop=True), edges.reset_index(drop=True)


def connected_components(node_ids: list[int], edges: pd.DataFrame) -> list[list[int]]:
    adjacency: dict[int, set[int]] = defaultdict(set)
    for node_id in node_ids:
        adjacency[int(node_id)]
    for row in edges.itertuples(index=False):
        source_id = int(row.source)
        target_id = int(row.target)
        adjacency[source_id].add(target_id)
        adjacency[target_id].add(source_id)

    seen: set[int] = set()
    components: list[list[int]] = []
    for node_id in sorted(adjacency):
        if node_id in seen:
            continue
        queue: deque[int] = deque([node_id])
        seen.add(node_id)
        component: list[int] = []
        while queue:
            current = queue.popleft()
            component.append(current)
            for neighbor in sorted(adjacency[current]):
                if neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
        components.append(component)
    components.sort(key=len, reverse=True)
    return components


def filter_core(nodes: pd.DataFrame, edges: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    keep_ids = set(nodes.loc[nodes["band_count"].ge(CORE_MIN_BANDS), "id"].astype(int).tolist())
    core_nodes = nodes.loc[nodes["id"].isin(keep_ids)].copy()
    core_edges = edges.loc[edges["source"].isin(keep_ids) & edges["target"].isin(keep_ids)].copy()
    components = connected_components(core_nodes["id"].astype(int).tolist(), core_edges)
    giant_ids = set(components[0]) if components else set()
    giant_nodes = core_nodes.loc[core_nodes["id"].isin(giant_ids)].copy()
    giant_edges = core_edges.loc[
        core_edges["source"].isin(giant_ids) & core_edges["target"].isin(giant_ids)
    ].copy()
    return (
        giant_nodes.sort_values(["band_count", "weighted_degree", "label"], ascending=[False, False, True]).reset_index(drop=True),
        giant_edges.sort_values(["weight", "source", "target"], ascending=[False, True, True]).reset_index(drop=True),
    )


def fruchterman_reingold_layout(
    nodes: pd.DataFrame,
    edges: pd.DataFrame,
    iterations: int = 280,
    seed: int = 7,
) -> dict[int, np.ndarray]:
    node_ids = nodes["id"].astype(int).tolist()
    index_lookup = {node_id: idx for idx, node_id in enumerate(node_ids)}
    rng = np.random.default_rng(seed)
    positions = rng.normal(loc=0.0, scale=0.85, size=(len(node_ids), 2))
    edges_idx = [
        (index_lookup[int(row.source)], index_lookup[int(row.target)], float(row.weight))
        for row in edges.itertuples(index=False)
    ]

    n_nodes = max(len(node_ids), 1)
    area = max(25.0, 2.8 * n_nodes)
    k_value = math.sqrt(area / n_nodes)
    temperature = 0.9
    gravity = 0.08

    for _ in range(iterations):
        displacement = np.zeros_like(positions)

        for left in range(n_nodes):
            delta = positions[left] - positions
            distance = np.linalg.norm(delta, axis=1)
            distance[left] = 1.0
            repulsive = (k_value * k_value) / distance
            repulsion = (delta / distance[:, None]) * repulsive[:, None]
            repulsion[left] = 0.0
            displacement[left] += repulsion.sum(axis=0)

        for left_idx, right_idx, weight in edges_idx:
            delta = positions[left_idx] - positions[right_idx]
            distance = float(np.linalg.norm(delta))
            if distance == 0:
                delta = np.array([0.01, 0.0], dtype=float)
                distance = 0.01
            direction = delta / distance
            attractive = ((distance * distance) / k_value) * (1.0 + 0.35 * max(weight - 1.0, 0.0))
            displacement[left_idx] -= direction * attractive
            displacement[right_idx] += direction * attractive

        displacement -= gravity * positions

        norms = np.linalg.norm(displacement, axis=1)
        for idx in range(n_nodes):
            if norms[idx] > 0:
                positions[idx] += displacement[idx] / norms[idx] * min(norms[idx], temperature)

        positions -= positions.mean(axis=0)
        temperature *= 0.972

    max_abs = float(np.abs(positions).max())
    if max_abs > 0:
        positions *= 6.4 / max_abs
    return {node_id: positions[idx] for idx, node_id in enumerate(node_ids)}


def font_size(weighted_degree: float) -> float:
    if weighted_degree >= 12:
        return 9.9
    if weighted_degree >= 8:
        return 8.9
    if weighted_degree >= 5:
        return 8.0
    return 7.1


def label_box_size(text: str, size: float) -> tuple[float, float]:
    width = 0.041 * len(text) * (size / 9.0) + 0.11
    height = 0.14 * (size / 9.0)
    return width, height


def resolve_label_positions(
    nodes: pd.DataFrame,
    anchors: dict[int, np.ndarray],
) -> dict[int, np.ndarray]:
    node_ids = nodes["id"].astype(int).tolist()
    positions = {node_id: anchors[node_id].copy() for node_id in node_ids}
    widths: dict[int, float] = {}
    heights: dict[int, float] = {}
    radial: dict[int, np.ndarray] = {}
    for row in nodes.itertuples(index=False):
        node_id = int(row.id)
        size = font_size(float(row.weighted_degree))
        width, height = label_box_size(str(row.label), size)
        widths[node_id] = width
        heights[node_id] = height
        anchor = anchors[node_id]
        norm = float(np.linalg.norm(anchor))
        direction = anchor / norm if norm > 0 else np.array([0.0, 1.0], dtype=float)
        radial[node_id] = direction

    for _ in range(300):
        moved = False
        for left_idx, left_id in enumerate(node_ids):
            for right_id in node_ids[left_idx + 1 :]:
                delta = positions[right_id] - positions[left_id]
                overlap_x = (widths[left_id] + widths[right_id]) / 2.0 - abs(delta[0])
                overlap_y = (heights[left_id] + heights[right_id]) / 2.0 - abs(delta[1])
                if overlap_x > 0 and overlap_y > 0:
                    if float(np.linalg.norm(delta)) < 1e-9:
                        delta = np.array([0.01, 0.01], dtype=float)
                    direction = delta / float(np.linalg.norm(delta))
                    push = direction * (0.02 + 0.28 * min(overlap_x, overlap_y))
                    positions[left_id] -= push
                    positions[right_id] += push
                    moved = True

        for node_id in node_ids:
            positions[node_id] += 0.035 * radial[node_id]
            positions[node_id] += 0.06 * (anchors[node_id] - positions[node_id])

        if not moved:
            break

    coords = np.array(list(positions.values()), dtype=float)
    if coords.size:
        min_x, min_y = coords.min(axis=0)
        max_x, max_y = coords.max(axis=0)
        center = np.array([(min_x + max_x) / 2.0, (min_y + max_y) / 2.0], dtype=float)
        for node_id in node_ids:
            positions[node_id] -= center
    return positions


def draw_graph(nodes: pd.DataFrame, edges: pd.DataFrame) -> None:
    configure_style()
    anchors = fruchterman_reingold_layout(nodes, edges)
    labels = resolve_label_positions(nodes, anchors)
    node_lookup = nodes.set_index("id")

    fig, ax = plt.subplots(figsize=(17.2, 12.2))
    fig.patch.set_facecolor(BACKGROUND_COLOR)
    ax.set_facecolor(BACKGROUND_COLOR)

    for row in edges.itertuples(index=False):
        source = anchors[int(row.source)]
        target = anchors[int(row.target)]
        repeated = int(row.repeated_tie_i) >= 1
        ax.plot(
            [source[0], target[0]],
            [source[1], target[1]],
            color=REPEATED_EDGE_COLOR if repeated else EDGE_COLOR,
            linewidth=1.0 if repeated else 0.5,
            alpha=0.50 if repeated else 0.22,
            solid_capstyle="round",
            zorder=1,
        )

    for row in nodes.itertuples(index=False):
        node_id = int(row.id)
        anchor = anchors[node_id]
        label = labels[node_id]
        label_dist = float(np.linalg.norm(label - anchor))
        if label_dist > 0.12:
            ax.plot(
                [anchor[0], label[0]],
                [anchor[1], label[1]],
                color=LEADER_COLOR,
                linewidth=0.38,
                alpha=0.18,
                zorder=2,
            )
        degree = float(row.weighted_degree)
        text = ax.text(
            label[0],
            label[1],
            str(row.label),
            ha="center",
            va="center",
            fontsize=font_size(degree),
            fontweight="bold" if degree >= 8 else "normal",
            color=TEXT_COLOR if degree >= 5 else MUTED_TEXT_COLOR,
            zorder=3,
        )
        text.set_path_effects(
            [patheffects.withStroke(linewidth=3.0, foreground=BACKGROUND_COLOR, alpha=0.98)]
        )

    fig.suptitle(
        f"Helsinki musician collaboration network, {START_YEAR}-{END_YEAR}",
        x=0.055,
        y=0.975,
        ha="left",
        fontsize=23,
        fontweight="bold",
        color=TEXT_COLOR,
    )
    fig.text(
        0.055,
        0.944,
        f"Names are musicians. A link means they played together in at least one Helsinki metal band during {START_YEAR}-{END_YEAR}.",
        ha="left",
        fontsize=10.5,
        color=MUTED_TEXT_COLOR,
    )
    fig.text(
        0.055,
        0.918,
        f"Readable preview shown here: giant component of the `{CORE_MIN_BANDS}+ bands` core.",
        ha="left",
        fontsize=9.6,
        color=MUTED_TEXT_COLOR,
    )

    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)

    all_coords = np.array(list(labels.values()), dtype=float)
    if all_coords.size:
        max_abs = float(np.abs(all_coords).max())
        span = max(7.4, max_abs + 1.6)
        ax.set_xlim(-span, span)
        ax.set_ylim(-span * 0.72, span * 0.72)

    FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(PNG_PATH, dpi=260, bbox_inches="tight")
    fig.savefig(SVG_PATH, bbox_inches="tight")
    plt.close(fig)


def write_summary(
    full_nodes: pd.DataFrame,
    full_edges: pd.DataFrame,
    core_nodes: pd.DataFrame,
    core_edges: pd.DataFrame,
) -> None:
    full_components = connected_components(full_nodes["id"].astype(int).tolist(), full_edges)
    core_components = connected_components(core_nodes["id"].astype(int).tolist(), core_edges)
    repeated_full = int(full_edges["repeated_tie_i"].sum()) if not full_edges.empty else 0
    repeated_core = int(core_edges["repeated_tie_i"].sum()) if not core_edges.empty else 0
    lines = [
        f"# Helsinki musician collaboration network, {START_YEAR}-{END_YEAR}",
        "",
        f"- City: `{CITY}, {COUNTRY}`",
        f"- Window: `{START_YEAR}-{END_YEAR}`",
        f"- Full all-musician network:",
        f"  - musicians: `{len(full_nodes)}`",
        f"  - edges: `{len(full_edges)}`",
        f"  - connected components: `{len(full_components)}`",
        f"  - giant component: `{len(full_components[0]) if full_components else 0}`",
        f"  - repeated ties: `{repeated_full}`",
        f"- Readable preview core:",
        f"  - filter: musicians in `{CORE_MIN_BANDS}+` Helsinki bands during the window",
        f"  - nodes after filter and giant-component trim: `{len(core_nodes)}`",
        f"  - edges: `{len(core_edges)}`",
        f"  - connected components before giant trim: `{len(core_components)}`",
        f"  - repeated ties in preview: `{repeated_core}`",
        "",
        "## Outputs",
        "",
        f"- Full nodes: `{FULL_NODES_PATH.name}`",
        f"- Full edges: `{FULL_EDGES_PATH.name}`",
        f"- Core preview nodes: `{CORE_NODES_PATH.name}`",
        f"- Core preview edges: `{CORE_EDGES_PATH.name}`",
        f"- Preview PNG: `figures/{PNG_PATH.name}`",
        f"- Preview SVG: `figures/{SVG_PATH.name}`",
    ]
    SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    active_edges = load_city_edges()
    full_nodes, full_edges = build_network(active_edges)
    core_nodes, core_edges = filter_core(full_nodes, full_edges)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    full_nodes.to_csv(FULL_NODES_PATH, index=False)
    full_edges.to_csv(FULL_EDGES_PATH, index=False)
    core_nodes.to_csv(CORE_NODES_PATH, index=False)
    core_edges.to_csv(CORE_EDGES_PATH, index=False)
    write_summary(full_nodes, full_edges, core_nodes, core_edges)
    draw_graph(core_nodes, core_edges)

    print(f"Wrote {FULL_NODES_PATH}")
    print(f"Wrote {FULL_EDGES_PATH}")
    print(f"Wrote {CORE_NODES_PATH}")
    print(f"Wrote {CORE_EDGES_PATH}")
    print(f"Wrote {SUMMARY_PATH}")
    print(f"Wrote {PNG_PATH}")
    print(f"Wrote {SVG_PATH}")


if __name__ == "__main__":
    main()
