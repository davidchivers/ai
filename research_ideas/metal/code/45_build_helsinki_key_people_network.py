from __future__ import annotations

import math
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import patheffects


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
HELSINKI_DIR = SCENE_DIR / "helsinki_long_window"
FIGURE_DIR = SCENE_DIR / "figures"

WINDOW_SLUG = "helsinki_finland_2000_2004"
CORE_SLUG = f"{WINDOW_SLUG}_core3_giant"
NODES_PATH = HELSINKI_DIR / f"{CORE_SLUG}_nodes.csv"
EDGES_PATH = HELSINKI_DIR / f"{CORE_SLUG}_edges.csv"
PNG_PATH = FIGURE_DIR / f"{CORE_SLUG}_key_people_network.png"
SVG_PATH = FIGURE_DIR / f"{CORE_SLUG}_key_people_network.svg"
SUMMARY_PATH = HELSINKI_DIR / f"{CORE_SLUG}_key_people_network_summary.md"

KEY_LABEL_COUNT = 10

BACKGROUND_COLOR = "#f7f4ee"
TEXT_COLOR = "#201e1d"
MUTED_TEXT_COLOR = "#736d66"
EDGE_COLOR = "#d1c8be"
REPEATED_EDGE_COLOR = "#766a60"
NODE_COLOR = "#9d958c"
KEY_NODE_COLOR = "#3a2f28"
LEADER_COLOR = "#b3a79a"


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


def load_data() -> tuple[pd.DataFrame, pd.DataFrame]:
    nodes = pd.read_csv(NODES_PATH)
    edges = pd.read_csv(EDGES_PATH)
    nodes["id"] = pd.to_numeric(nodes["id"], errors="coerce").astype(int)
    nodes["band_count"] = pd.to_numeric(nodes["band_count"], errors="coerce").fillna(1).astype(int)
    nodes["degree"] = pd.to_numeric(nodes["degree"], errors="coerce").fillna(0).astype(int)
    nodes["weighted_degree"] = pd.to_numeric(nodes["weighted_degree"], errors="coerce").fillna(0).astype(int)
    edges["source"] = pd.to_numeric(edges["source"], errors="coerce").astype(int)
    edges["target"] = pd.to_numeric(edges["target"], errors="coerce").astype(int)
    edges["weight"] = pd.to_numeric(edges["weight"], errors="coerce").fillna(1).astype(int)
    edges["repeated_tie_i"] = pd.to_numeric(edges["repeated_tie_i"], errors="coerce").fillna(0).astype(int)
    return nodes, edges


def fruchterman_reingold_layout(
    nodes: pd.DataFrame,
    edges: pd.DataFrame,
    iterations: int = 300,
    seed: int = 11,
) -> dict[int, np.ndarray]:
    node_ids = nodes["id"].astype(int).tolist()
    index_lookup = {node_id: idx for idx, node_id in enumerate(node_ids)}
    rng = np.random.default_rng(seed)
    positions = rng.normal(loc=0.0, scale=1.0, size=(len(node_ids), 2))
    edges_idx = [
        (index_lookup[int(row.source)], index_lookup[int(row.target)], float(row.weight))
        for row in edges.itertuples(index=False)
    ]

    n_nodes = max(len(node_ids), 1)
    area = max(34.0, 3.6 * n_nodes)
    k_value = math.sqrt(area / n_nodes)
    temperature = 1.0
    gravity = 0.06

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
            attractive = ((distance * distance) / k_value) * (1.0 + 0.3 * max(weight - 1.0, 0.0))
            displacement[left_idx] -= direction * attractive
            displacement[right_idx] += direction * attractive

        displacement -= gravity * positions

        norms = np.linalg.norm(displacement, axis=1)
        for idx in range(n_nodes):
            if norms[idx] > 0:
                positions[idx] += displacement[idx] / norms[idx] * min(norms[idx], temperature)

        positions -= positions.mean(axis=0)
        temperature *= 0.973

    max_abs = float(np.abs(positions).max())
    if max_abs > 0:
        positions *= 7.6 / max_abs
    return {node_id: positions[idx] for idx, node_id in enumerate(node_ids)}


def choose_key_people(nodes: pd.DataFrame) -> pd.DataFrame:
    return nodes.sort_values(
        ["weighted_degree", "band_count", "degree", "label"],
        ascending=[False, False, False, True],
    ).head(KEY_LABEL_COUNT)


def key_font_size(weighted_degree: int) -> float:
    if weighted_degree >= 34:
        return 11.5
    if weighted_degree >= 28:
        return 10.8
    if weighted_degree >= 24:
        return 10.1
    return 9.5


def label_box_size(text: str, size: float) -> tuple[float, float]:
    width = 0.048 * len(text) * (size / 10.0) + 0.16
    height = 0.16 * (size / 10.0)
    return width, height


def resolve_key_label_positions(
    key_nodes: pd.DataFrame,
    anchors: dict[int, np.ndarray],
) -> dict[int, np.ndarray]:
    key_ids = key_nodes["id"].astype(int).tolist()
    positions: dict[int, np.ndarray] = {}
    widths: dict[int, float] = {}
    heights: dict[int, float] = {}
    radial: dict[int, np.ndarray] = {}

    for row in key_nodes.itertuples(index=False):
        node_id = int(row.id)
        anchor = anchors[node_id]
        norm = float(np.linalg.norm(anchor))
        direction = anchor / norm if norm > 0 else np.array([0.0, 1.0], dtype=float)
        positions[node_id] = anchor + direction * 0.22
        radial[node_id] = direction
        width, height = label_box_size(str(row.label), key_font_size(int(row.weighted_degree)))
        widths[node_id] = width
        heights[node_id] = height

    for _ in range(260):
        moved = False
        for left_idx, left_id in enumerate(key_ids):
            for right_id in key_ids[left_idx + 1 :]:
                delta = positions[right_id] - positions[left_id]
                overlap_x = (widths[left_id] + widths[right_id]) / 2.0 - abs(delta[0])
                overlap_y = (heights[left_id] + heights[right_id]) / 2.0 - abs(delta[1])
                if overlap_x > 0 and overlap_y > 0:
                    if float(np.linalg.norm(delta)) < 1e-9:
                        delta = np.array([0.01, 0.01], dtype=float)
                    direction = delta / float(np.linalg.norm(delta))
                    push = direction * (0.03 + 0.32 * min(overlap_x, overlap_y))
                    positions[left_id] -= push
                    positions[right_id] += push
                    moved = True

        for node_id in key_ids:
            positions[node_id] += 0.04 * radial[node_id]
            positions[node_id] += 0.05 * (anchors[node_id] - positions[node_id])

        if not moved:
            break

    coords = np.array(list(positions.values()), dtype=float)
    if coords.size:
        min_x, min_y = coords.min(axis=0)
        max_x, max_y = coords.max(axis=0)
        center = np.array([(min_x + max_x) / 2.0, (min_y + max_y) / 2.0], dtype=float)
        for node_id in key_ids:
            positions[node_id] -= center * 0.12
    return positions


def draw_graph(nodes: pd.DataFrame, edges: pd.DataFrame) -> list[str]:
    configure_style()
    anchors = fruchterman_reingold_layout(nodes, edges)
    key_nodes = choose_key_people(nodes)
    key_positions = resolve_key_label_positions(key_nodes, anchors)
    key_ids = set(key_nodes["id"].astype(int).tolist())
    key_neighbor_ids: set[int] = set()
    for row in edges.itertuples(index=False):
        source_id = int(row.source)
        target_id = int(row.target)
        if source_id in key_ids or target_id in key_ids:
            key_neighbor_ids.add(source_id)
            key_neighbor_ids.add(target_id)

    fig, ax = plt.subplots(figsize=(17.8, 12.6))
    fig.patch.set_facecolor(BACKGROUND_COLOR)
    ax.set_facecolor(BACKGROUND_COLOR)

    for row in edges.itertuples(index=False):
        source_id = int(row.source)
        target_id = int(row.target)
        source = anchors[int(row.source)]
        target = anchors[int(row.target)]
        repeated = int(row.repeated_tie_i) >= 1
        key_key = source_id in key_ids and target_id in key_ids
        key_edge = (source_id in key_ids) ^ (target_id in key_ids)
        key_neighbor_edge = (
            source_id in key_neighbor_ids and target_id in key_neighbor_ids and not key_key and not key_edge
        )
        if not (key_key or key_edge or repeated):
            continue
        ax.plot(
            [source[0], target[0]],
            [source[1], target[1]],
            color=KEY_NODE_COLOR if key_key else REPEATED_EDGE_COLOR if (key_edge or repeated) else EDGE_COLOR,
            linewidth=2.1 if key_key else 1.45 if key_edge else 0.95 if repeated else 0.55,
            alpha=0.82 if key_key else 0.68 if key_edge else 0.42 if repeated else 0.16,
            solid_capstyle="round",
            zorder=1,
        )

    for row in nodes.itertuples(index=False):
        node_id = int(row.id)
        point = anchors[node_id]
        key_person = node_id in key_ids
        key_neighbor = node_id in key_neighbor_ids
        size = 11 + 2.2 * math.sqrt(max(float(row.weighted_degree), 1.0))
        ax.scatter(
            [point[0]],
            [point[1]],
            s=size * (1.9 if key_person else 1.12 if key_neighbor else 0.85),
            color=KEY_NODE_COLOR if key_person else REPEATED_EDGE_COLOR if key_neighbor else NODE_COLOR,
            alpha=0.94 if key_person else 0.72 if key_neighbor else 0.32,
            linewidths=0,
            zorder=3 if key_person else 2,
        )

    labeled_names: list[str] = []
    for row in key_nodes.itertuples(index=False):
        node_id = int(row.id)
        anchor = anchors[node_id]
        label = key_positions[node_id]
        ax.plot(
            [anchor[0], label[0]],
            [anchor[1], label[1]],
            color=LEADER_COLOR,
            linewidth=0.48,
            alpha=0.28,
            zorder=4,
        )
        text = ax.text(
            label[0],
            label[1],
            str(row.label),
            ha="center",
            va="center",
            fontsize=key_font_size(int(row.weighted_degree)),
            fontweight="bold",
            color=TEXT_COLOR,
            zorder=5,
        )
        text.set_path_effects(
            [patheffects.withStroke(linewidth=3.2, foreground=BACKGROUND_COLOR, alpha=0.98)]
        )
        labeled_names.append(str(row.label))

    fig.suptitle(
        "Helsinki musician collaboration network, 2000-2004",
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
        "Names shown only for the most connected musicians in the 3+ bands core. Their ties are highlighted; background ties are suppressed.",
        ha="left",
        fontsize=10.8,
        color=MUTED_TEXT_COLOR,
    )
    fig.text(
        0.055,
        0.918,
        "A link means two musicians played together in at least one Helsinki metal band during the five-year window.",
        ha="left",
        fontsize=9.8,
        color=MUTED_TEXT_COLOR,
    )

    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)

    coords = np.array(list(anchors.values()), dtype=float)
    if coords.size:
        max_abs = float(np.abs(coords).max())
        span = max(8.6, max_abs + 1.8)
        ax.set_xlim(-span, span)
        ax.set_ylim(-span * 0.72, span * 0.72)

    FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(PNG_PATH, dpi=280, bbox_inches="tight")
    fig.savefig(SVG_PATH, bbox_inches="tight")
    plt.close(fig)
    return labeled_names


def write_summary(nodes: pd.DataFrame, edges: pd.DataFrame, labeled_names: list[str]) -> None:
    repeated = int(edges["repeated_tie_i"].sum()) if not edges.empty else 0
    lines = [
        "# Helsinki key-people network, 2000-2004",
        "",
        f"- Source nodes: `{NODES_PATH.name}`",
        f"- Source edges: `{EDGES_PATH.name}`",
        f"- Nodes shown: `{len(nodes)}`",
        f"- Edges shown: `{len(edges)}`",
        f"- Repeated ties: `{repeated}`",
        f"- Labeled key people: `{len(labeled_names)}`",
        "",
        "## Labeled names",
        "",
    ]
    lines.extend([f"- `{name}`" for name in labeled_names])
    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This version labels only the most connected musicians and leaves the rest as nodes.",
            "- It is intended to keep the network structure visible while avoiding full-label clutter.",
        ]
    )
    SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    nodes, edges = load_data()
    labeled_names = draw_graph(nodes, edges)
    write_summary(nodes, edges, labeled_names)
    print(f"Wrote {PNG_PATH}")
    print(f"Wrote {SVG_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
