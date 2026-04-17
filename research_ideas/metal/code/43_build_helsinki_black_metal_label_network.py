from __future__ import annotations

import json
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib import patheffects


PROJECT_ROOT = Path(__file__).resolve().parents[1]
VIEW_PATH = (
    PROJECT_ROOT
    / "data"
    / "processed"
    / "scene_networks"
    / "cytoscape"
    / "helsinki_black_metal_connector_core_view.json"
)
FIGURE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks" / "figures"
PNG_OUTPUT_PATH = FIGURE_DIR / "helsinki_black_metal_musician_label_network.png"
SVG_OUTPUT_PATH = FIGURE_DIR / "helsinki_black_metal_musician_label_network.svg"
SUMMARY_PATH = (
    PROJECT_ROOT
    / "data"
    / "processed"
    / "scene_networks"
    / "helsinki_black_metal_musician_label_network_summary.md"
)

BACKGROUND_COLOR = "#f7f4ee"
TEXT_COLOR = "#232120"
MUTED_TEXT_COLOR = "#5c5752"
EDGE_COLOR = "#cec6bc"
REPEATED_EDGE_COLOR = "#74695f"
LEADER_COLOR = "#a69a8f"


@dataclass(frozen=True)
class Slot:
    center_x: float
    center_y: float
    width: float
    height: float


SLOTS = [
    Slot(center_x=-4.55, center_y=2.75, width=6.8, height=3.55),
    Slot(center_x=3.7, center_y=2.75, width=5.55, height=3.15),
    Slot(center_x=-4.45, center_y=-0.75, width=5.9, height=3.1),
    Slot(center_x=3.45, center_y=-0.75, width=5.0, height=2.95),
    Slot(center_x=-3.5, center_y=-4.0, width=4.25, height=2.15),
    Slot(center_x=3.55, center_y=-4.0, width=3.65, height=1.95),
]


def load_view() -> dict:
    with VIEW_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


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


def build_components(nodes: list[dict], edges: list[dict]) -> list[list[str]]:
    adjacency: dict[str, set[str]] = defaultdict(set)
    for node in nodes:
        adjacency[str(node["data"]["id"])]
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


def normalize_component_positions(component_nodes: list[dict], slot: Slot) -> dict[str, np.ndarray]:
    positions = {
        str(node["data"]["id"]): np.array(
            [float(node["position"]["x"]), float(node["position"]["y"])], dtype=float
        )
        for node in component_nodes
    }
    coords = np.array(list(positions.values()), dtype=float)
    center = coords.mean(axis=0)
    centered = coords - center
    min_x, min_y = centered.min(axis=0)
    max_x, max_y = centered.max(axis=0)
    span_x = max(max_x - min_x, 1.0)
    span_y = max(max_y - min_y, 1.0)
    scale = min((slot.width * 0.78) / span_x, (slot.height * 0.7) / span_y)
    slot_center = np.array([slot.center_x, slot.center_y], dtype=float)
    return {
        node_id: (value - center) * scale + slot_center
        for node_id, value in positions.items()
    }


def approximate_label_box(text: str, font_size: float) -> tuple[float, float]:
    width = 0.048 * len(text) * (font_size / 9.0) + 0.14
    height = 0.16 * (font_size / 9.0)
    return width, height


def resolve_label_positions(
    component_nodes: list[dict],
    anchors: dict[str, np.ndarray],
    slot: Slot,
) -> dict[str, np.ndarray]:
    slot_center = np.array([slot.center_x, slot.center_y], dtype=float)
    node_ids = [str(node["data"]["id"]) for node in component_nodes]
    positions: dict[str, np.ndarray] = {}
    widths: dict[str, float] = {}
    heights: dict[str, float] = {}
    forces: dict[str, np.ndarray] = {}

    for node in component_nodes:
        data = node["data"]
        node_id = str(data["id"])
        anchor = anchors[node_id]
        direction = anchor - slot_center
        norm = float(np.linalg.norm(direction))
        if norm == 0:
            direction = np.array([0.0, 1.0], dtype=float)
            norm = 1.0
        unit = direction / norm
        connector = float(data.get("is_multi_band_connector", 0.0)) >= 1
        offset = 0.12 if connector else 0.09
        positions[node_id] = anchor + unit * offset
        font_size = 9.6 if connector else 8.25
        width, height = approximate_label_box(str(data.get("label", "")), font_size)
        widths[node_id] = width
        heights[node_id] = height
        forces[node_id] = unit

    for _ in range(260):
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
                    push = direction * (0.02 + 0.25 * min(overlap_x, overlap_y))
                    positions[left_id] -= push
                    positions[right_id] += push
                    moved = True

        for node_id in node_ids:
            positions[node_id] += 0.1 * forces[node_id]
            positions[node_id] += 0.08 * (anchors[node_id] - positions[node_id])
            x_min = slot.center_x - slot.width / 2.0 + widths[node_id] / 2.0 + 0.08
            x_max = slot.center_x + slot.width / 2.0 - widths[node_id] / 2.0 - 0.08
            y_min = slot.center_y - slot.height / 2.0 + heights[node_id] / 2.0 + 0.08
            y_max = slot.center_y + slot.height / 2.0 - heights[node_id] / 2.0 - 0.08
            positions[node_id][0] = float(np.clip(positions[node_id][0], x_min, x_max))
            positions[node_id][1] = float(np.clip(positions[node_id][1], y_min, y_max))

        if not moved:
            break

    return positions


def draw_edges(ax: plt.Axes, component_edges: list[dict], anchors: dict[str, np.ndarray]) -> None:
    for edge in component_edges:
        data = edge["data"]
        source = anchors[str(data["source"])]
        target = anchors[str(data["target"])]
        repeated = float(data.get("repeated_tie_i", 0.0)) >= 1
        ax.plot(
            [source[0], target[0]],
            [source[1], target[1]],
            color=REPEATED_EDGE_COLOR if repeated else EDGE_COLOR,
            linewidth=1.7 if repeated else 0.85,
            alpha=0.7 if repeated else 0.45,
            solid_capstyle="round",
            zorder=1,
        )


def component_caption(component_nodes: list[dict]) -> tuple[str, str]:
    connectors = sum(float(node["data"].get("is_multi_band_connector", 0.0)) >= 1 for node in component_nodes)
    return (
        f"{len(component_nodes)} musicians",
        f"{connectors} multi-band connectors",
    )


def draw_labels(
    ax: plt.Axes,
    component_nodes: list[dict],
    anchors: dict[str, np.ndarray],
    label_positions: dict[str, np.ndarray],
) -> None:
    for node in component_nodes:
        data = node["data"]
        node_id = str(data["id"])
        anchor = anchors[node_id]
        label_point = label_positions[node_id]
        connector = float(data.get("is_multi_band_connector", 0.0)) >= 1
        if float(np.linalg.norm(label_point - anchor)) > 0.16:
            ax.plot(
                [anchor[0], label_point[0]],
                [anchor[1], label_point[1]],
                color=LEADER_COLOR,
                linewidth=0.55,
                alpha=0.35,
                zorder=2,
            )
        text = ax.text(
            label_point[0],
            label_point[1],
            str(data.get("label", "")),
            ha="center",
            va="center",
            fontsize=9.6 if connector else 8.25,
            fontweight="bold" if connector else "normal",
            color=TEXT_COLOR if connector else MUTED_TEXT_COLOR,
            zorder=3,
        )
        text.set_path_effects(
            [patheffects.withStroke(linewidth=3.2, foreground=BACKGROUND_COLOR, alpha=0.98)]
        )


def draw_component_title(ax: plt.Axes, slot: Slot, component_nodes: list[dict]) -> None:
    count_line, connector_line = component_caption(component_nodes)
    ax.text(
        slot.center_x,
        slot.center_y + slot.height / 2.0 + 0.15,
        count_line,
        ha="center",
        va="bottom",
        fontsize=9.6,
        fontweight="bold",
        color=TEXT_COLOR,
        zorder=4,
    )
    ax.text(
        slot.center_x,
        slot.center_y + slot.height / 2.0 - 0.03,
        connector_line,
        ha="center",
        va="bottom",
        fontsize=8.2,
        color=MUTED_TEXT_COLOR,
        zorder=4,
    )


def build_summary(nodes: list[dict], edges: list[dict], components: list[list[str]]) -> str:
    connectors = sum(float(node["data"].get("is_multi_band_connector", 0.0)) >= 1 for node in nodes)
    repeated_ties = sum(float(edge["data"].get("repeated_tie_i", 0.0)) >= 1 for edge in edges)
    lines = [
        "# Helsinki black metal musician label network",
        "",
        "- Source layout: `cytoscape/helsinki_black_metal_connector_core_view.json`",
        f"- Figure: `figures/{PNG_OUTPUT_PATH.name}`",
        f"- Musicians shown: `{len(nodes)}`",
        f"- Collaboration ties shown: `{len(edges)}`",
        f"- Multi-band connectors: `{connectors}`",
        f"- Repeated ties: `{repeated_ties}`",
        f"- Connected components: `{len(components)}`",
        "",
        "## Read",
        "",
        "- This is a musician-only text network: names are the nodes, with no visible circles or band hulls.",
        "- Thin lines show co-membership ties; darker lines mark repeated shared-band ties.",
        "- Bold labels identify musicians active in two or more local bands.",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    configure_style()
    view = load_view()
    nodes = view["elements"]["nodes"]
    edges = view["elements"]["edges"]
    components = build_components(nodes, edges)
    node_lookup = {str(node["data"]["id"]): node for node in nodes}

    fig, ax = plt.subplots(figsize=(16.8, 11.0))
    fig.patch.set_facecolor(BACKGROUND_COLOR)
    ax.set_facecolor(BACKGROUND_COLOR)

    for slot, component in zip(SLOTS, components, strict=True):
        component_set = set(component)
        component_nodes = [node_lookup[node_id] for node_id in component]
        component_edges = [
            edge
            for edge in edges
            if str(edge["data"]["source"]) in component_set and str(edge["data"]["target"]) in component_set
        ]
        anchors = normalize_component_positions(component_nodes, slot)
        label_positions = resolve_label_positions(component_nodes, anchors, slot)
        draw_edges(ax, component_edges, anchors)
        draw_labels(ax, component_nodes, anchors, label_positions)
        draw_component_title(ax, slot, component_nodes)

    connector_count = sum(float(node["data"].get("is_multi_band_connector", 0.0)) >= 1 for node in nodes)
    repeated_ties = sum(float(edge["data"].get("repeated_tie_i", 0.0)) >= 1 for edge in edges)

    fig.suptitle(
        "Helsinki black metal musician network, 2010",
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
        "A musician-only label network. Names are the nodes; ties connect musicians who were active in the same local band.",
        ha="left",
        fontsize=11.2,
        color=MUTED_TEXT_COLOR,
    )
    fig.text(
        0.055,
        0.918,
        f"{len(nodes)} musicians | {len(edges)} ties | {repeated_ties} repeated ties | {connector_count} multi-band connectors",
        ha="left",
        fontsize=10.1,
        color=MUTED_TEXT_COLOR,
    )

    ax.set_xlim(-8.25, 8.25)
    ax.set_ylim(-5.1, 5.2)
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)

    FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(PNG_OUTPUT_PATH, dpi=280, bbox_inches="tight")
    fig.savefig(SVG_OUTPUT_PATH, bbox_inches="tight")
    plt.close(fig)

    SUMMARY_PATH.write_text(build_summary(nodes, edges, components), encoding="utf-8")
    print(f"Wrote {PNG_OUTPUT_PATH}")
    print(f"Wrote {SVG_OUTPUT_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
