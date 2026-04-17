from __future__ import annotations

import json
import math
from collections import Counter, defaultdict, deque
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib import patheffects
from matplotlib.lines import Line2D


PROJECT_ROOT = Path(__file__).resolve().parents[1]
VIEW_PATH = (
    PROJECT_ROOT
    / "data"
    / "processed"
    / "scene_networks"
    / "cytoscape"
    / "helsinki_black_metal_connector_core_view.json"
)
OUTPUT_PATH = (
    PROJECT_ROOT
    / "data"
    / "processed"
    / "scene_networks"
    / "figures"
    / "helsinki_black_metal_connector_core_component_labels.png"
)

BACKGROUND_COLOR = "#f8f5ef"
TEXT_COLOR = "#2f2f2f"
SUBTITLE_COLOR = "#5a5a5a"


def load_view() -> dict:
    with VIEW_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def build_components(nodes: list[dict], edges: list[dict]) -> list[list[str]]:
    adjacency: dict[str, set[str]] = defaultdict(set)
    for node in nodes:
        node_id = str(node["data"]["id"])
        adjacency[node_id]
    for edge in edges:
        source = str(edge["data"]["source"])
        target = str(edge["data"]["target"])
        adjacency[source].add(target)
        adjacency[target].add(source)

    seen: set[str] = set()
    components: list[list[str]] = []
    for node_id in sorted(adjacency):
        if node_id in seen:
            continue
        queue: deque[str] = deque([node_id])
        seen.add(node_id)
        component: list[str] = []
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


def panel_title(component_nodes: list[dict]) -> str:
    band_counts = Counter(str(node["data"].get("primary_band", "")) for node in component_nodes)
    top_bands = [band for band, _ in band_counts.most_common(3)]
    return " / ".join(top_bands)


def label_offset(position: np.ndarray, center: np.ndarray) -> tuple[float, float]:
    direction = position - center
    norm = float(np.linalg.norm(direction))
    if norm == 0:
        return 0.0, 0.06
    unit = direction / norm
    return float(unit[0] * 0.055), float(unit[1] * 0.055)


def draw_component(ax: plt.Axes, component_nodes: list[dict], component_edges: list[dict]) -> None:
    positions = {
        str(node["data"]["id"]): np.array([float(node["position"]["x"]), float(node["position"]["y"])], dtype=float)
        for node in component_nodes
    }
    coords = np.array(list(positions.values()), dtype=float)
    center = coords.mean(axis=0)
    coords -= center
    max_abs = float(np.abs(coords).max())
    scale = 1.0 if max_abs == 0 else 0.86 / max_abs
    scaled_positions = {node_id: (value - center) * scale for node_id, value in positions.items()}

    for edge in component_edges:
        data = edge["data"]
        source = scaled_positions[str(data["source"])]
        target = scaled_positions[str(data["target"])]
        ax.plot(
            [source[0], target[0]],
            [source[1], target[1]],
            color=str(data.get("edge_color_hex", "#d8cec2")),
            linewidth=float(data.get("edge_width_seed", 1.0)),
            alpha=float(data.get("edge_opacity_seed", 120.0)) / 255.0,
            solid_capstyle="round",
            zorder=1,
        )

    node_order = sorted(component_nodes, key=lambda node: float(node["data"].get("is_multi_band_connector", 0.0)))
    for node in node_order:
        data = node["data"]
        position = scaled_positions[str(data["id"])]
        ax.scatter(
            [position[0]],
            [position[1]],
            s=float(data.get("node_size_seed", 30.0)) * 9.5,
            color=str(data.get("band_color_hex", "#4f86c6")),
            edgecolor=str(data.get("border_color_hex", "#fffaf0")),
            linewidth=float(data.get("border_width_seed", 1.3)),
            alpha=0.98,
            zorder=3,
        )

    local_center = np.array([0.0, 0.0], dtype=float)
    for node in component_nodes:
        data = node["data"]
        position = scaled_positions[str(data["id"])]
        dx_value, dy_value = label_offset(position, local_center)
        font_size = 10.2 if float(data.get("is_multi_band_connector", 0.0)) >= 1 else 8.6
        font_weight = "bold" if float(data.get("is_multi_band_connector", 0.0)) >= 1 else "normal"
        text = ax.text(
            position[0] + dx_value,
            position[1] + dy_value,
            str(data.get("label", data.get("name", ""))),
            ha="center",
            va="center",
            fontsize=font_size,
            fontweight=font_weight,
            color=TEXT_COLOR,
            zorder=4,
        )
        text.set_path_effects(
            [patheffects.withStroke(linewidth=3.8, foreground=BACKGROUND_COLOR, alpha=0.98)]
        )

    ax.set_xlim(-1.05, 1.05)
    ax.set_ylim(-1.0, 1.0)
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_facecolor(BACKGROUND_COLOR)
    for spine in ax.spines.values():
        spine.set_visible(False)
    ax.set_title(panel_title(component_nodes), fontsize=11.5, color=TEXT_COLOR, pad=7)


def legend_handles(view_nodes: list[dict]) -> list[Line2D]:
    band_counts = Counter(str(node["data"].get("primary_band", "")) for node in view_nodes)
    top_bands = [band for band, _ in band_counts.most_common(6)]
    band_color_lookup = {
        band: next(str(node["data"].get("band_color_hex", "#4f86c6")) for node in view_nodes if str(node["data"].get("primary_band", "")) == band)
        for band in top_bands
    }
    handles = [
        Line2D(
            [0],
            [0],
            marker="o",
            color="none",
            markerfacecolor=band_color_lookup[band],
            markeredgecolor="#fffaf0",
            markersize=8,
            label=band,
        )
        for band in top_bands
    ]
    handles.extend(
        [
            Line2D(
                [0],
                [0],
                marker="o",
                color="none",
                markerfacecolor="#b0b0b0",
                markeredgecolor="#1b1b1b",
                markeredgewidth=2.2,
                markersize=8,
                label="Connector outline",
            ),
            Line2D([0], [0], color="#8f7f6d", linewidth=2.2, label="Repeated tie"),
            Line2D([0], [0], color="#d8cec2", linewidth=1.2, label="Single tie"),
        ]
    )
    return handles


def main() -> None:
    view = load_view()
    nodes = view["elements"]["nodes"]
    edges = view["elements"]["edges"]

    components = build_components(nodes, edges)
    node_lookup = {str(node["data"]["id"]): node for node in nodes}
    edges_by_component: list[list[dict]] = []
    nodes_by_component: list[list[dict]] = []
    for component in components:
        component_set = set(component)
        nodes_by_component.append([node_lookup[node_id] for node_id in component])
        edges_by_component.append(
            [
                edge
                for edge in edges
                if str(edge["data"]["source"]) in component_set and str(edge["data"]["target"]) in component_set
            ]
        )

    fig, axes = plt.subplots(2, 3, figsize=(18.5, 12.0))
    fig.patch.set_facecolor(BACKGROUND_COLOR)
    for ax in axes.ravel():
        ax.set_facecolor(BACKGROUND_COLOR)

    for idx, ax in enumerate(axes.ravel()):
        if idx < len(nodes_by_component):
            draw_component(ax, nodes_by_component[idx], edges_by_component[idx])
        else:
            ax.axis("off")

    fig.suptitle(
        "Helsinki black metal connector core, 2010",
        x=0.08,
        y=0.965,
        ha="left",
        fontsize=24,
        fontweight="bold",
        color=TEXT_COLOR,
    )
    fig.text(
        0.08,
        0.93,
        "Cytoscape force-directed layout, broken into connected components so every musician name is readable.",
        ha="left",
        fontsize=11.5,
        color=SUBTITLE_COLOR,
    )

    fig.tight_layout(rect=(0.02, 0.05, 1.0, 0.92))
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUTPUT_PATH, dpi=300)
    plt.close(fig)
    print(f"Wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
