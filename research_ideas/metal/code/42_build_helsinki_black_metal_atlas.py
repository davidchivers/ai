from __future__ import annotations

import json
from collections import Counter, defaultdict, deque
from dataclasses import dataclass
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib import colors as mcolors
from matplotlib import patheffects
from matplotlib.patches import FancyBboxPatch


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
PNG_OUTPUT_PATH = FIGURE_DIR / "helsinki_black_metal_connector_core_atlas.png"
SVG_OUTPUT_PATH = FIGURE_DIR / "helsinki_black_metal_connector_core_atlas.svg"
SUMMARY_PATH = (
    PROJECT_ROOT
    / "data"
    / "processed"
    / "scene_networks"
    / "helsinki_black_metal_connector_core_atlas_summary.md"
)

BACKGROUND_COLOR = "#f7f4ee"
TEXT_COLOR = "#272626"
SUBTEXT_COLOR = "#676059"
EDGE_COLOR = "#b8aea4"
REPEATED_EDGE_COLOR = "#6f6258"
NODE_EDGE_COLOR = "#fffaf0"
CONNECTOR_EDGE_COLOR = "#151515"
SLOT_EDGE_COLOR = "#ece4db"


@dataclass(frozen=True)
class Slot:
    center_x: float
    center_y: float
    width: float
    height: float


SLOTS = [
    Slot(center_x=-4.4, center_y=2.85, width=6.6, height=3.35),
    Slot(center_x=3.65, center_y=2.85, width=5.5, height=3.15),
    Slot(center_x=-4.5, center_y=-0.7, width=5.9, height=3.0),
    Slot(center_x=3.4, center_y=-0.75, width=5.1, height=2.85),
    Slot(center_x=-3.55, center_y=-4.05, width=4.25, height=2.05),
    Slot(center_x=3.55, center_y=-4.05, width=3.65, height=1.9),
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
            "font.size": 10,
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


def lighten(color: str, amount: float) -> tuple[float, float, float, float]:
    rgba = np.array(mcolors.to_rgba(color), dtype=float)
    white = np.array([1.0, 1.0, 1.0, 1.0], dtype=float)
    return tuple(rgba * (1.0 - amount) + white * amount)


def sort_band_groups(component_nodes: list[dict]) -> list[tuple[str, list[dict]]]:
    grouped: dict[str, list[dict]] = defaultdict(list)
    for node in component_nodes:
        grouped[str(node["data"].get("primary_band", ""))].append(node)
    return sorted(grouped.items(), key=lambda item: (-len(item[1]), item[0]))


def normalize_component_positions(component_nodes: list[dict], slot: Slot) -> dict[str, np.ndarray]:
    positions = {
        str(node["data"]["id"]): np.array(
            [float(node["position"]["x"]), float(node["position"]["y"])], dtype=float
        )
        for node in component_nodes
    }
    coords = np.array(list(positions.values()), dtype=float)
    coords -= coords.mean(axis=0)
    min_x, min_y = coords.min(axis=0)
    max_x, max_y = coords.max(axis=0)
    span_x = max(max_x - min_x, 1.0)
    span_y = max(max_y - min_y, 1.0)
    scale = min((slot.width * 0.73) / span_x, (slot.height * 0.63) / span_y)
    center = np.array([slot.center_x, slot.center_y], dtype=float)
    return {
        node_id: (value - coords.mean(axis=0)) * scale + center
        for node_id, value in positions.items()
    }


def band_bbox(points: np.ndarray, padding_x: float, padding_y: float) -> tuple[float, float, float, float]:
    min_x = float(points[:, 0].min()) - padding_x
    max_x = float(points[:, 0].max()) + padding_x
    min_y = float(points[:, 1].min()) - padding_y
    max_y = float(points[:, 1].max()) + padding_y
    return min_x, min_y, max_x - min_x, max_y - min_y


def draw_slot_card(ax: plt.Axes, slot: Slot) -> None:
    patch = FancyBboxPatch(
        (slot.center_x - slot.width / 2.0, slot.center_y - slot.height / 2.0),
        slot.width,
        slot.height,
        boxstyle="round,pad=0.02,rounding_size=0.22",
        facecolor=(1.0, 1.0, 1.0, 0.16),
        edgecolor=SLOT_EDGE_COLOR,
        linewidth=1.0,
        zorder=0,
    )
    ax.add_patch(patch)


def draw_band_hulls(
    ax: plt.Axes,
    band_groups: list[tuple[str, list[dict]]],
    positions: dict[str, np.ndarray],
) -> None:
    for band_name, group in band_groups:
        points = np.array([positions[str(node["data"]["id"])] for node in group], dtype=float)
        color = str(group[0]["data"].get("band_color_hex", "#7992a4"))
        pad_x = 0.34 if len(group) >= 4 else 0.28
        pad_y = 0.27 if len(group) >= 4 else 0.22
        x0, y0, width, height = band_bbox(points, padding_x=pad_x, padding_y=pad_y)
        hull = FancyBboxPatch(
            (x0, y0),
            width,
            height,
            boxstyle="round,pad=0.02,rounding_size=0.25",
            facecolor=lighten(color, 0.52),
            edgecolor=lighten(color, 0.15),
            linewidth=1.4,
            alpha=0.28,
            zorder=1,
        )
        ax.add_patch(hull)
        label_x = x0 + width / 2.0
        label_y = y0 + height + 0.12
        label = ax.text(
            label_x,
            label_y,
            band_name,
            ha="center",
            va="bottom",
            fontsize=9.1,
            fontweight="bold",
            color=lighten(color, 0.05),
            zorder=5,
        )
        label.set_path_effects(
            [patheffects.withStroke(linewidth=3.0, foreground=BACKGROUND_COLOR, alpha=0.96)]
        )


def draw_edges(ax: plt.Axes, component_edges: list[dict], positions: dict[str, np.ndarray]) -> None:
    for edge in component_edges:
        data = edge["data"]
        source = positions[str(data["source"])]
        target = positions[str(data["target"])]
        repeated = float(data.get("repeated_tie_i", 0.0)) >= 1
        ax.plot(
            [source[0], target[0]],
            [source[1], target[1]],
            color=REPEATED_EDGE_COLOR if repeated else EDGE_COLOR,
            linewidth=2.15 if repeated else 1.25,
            alpha=0.72 if repeated else 0.58,
            solid_capstyle="round",
            zorder=2,
        )


def approximate_label_box(text: str, font_size: float) -> tuple[float, float]:
    width = 0.05 * len(text) * (font_size / 9.0) + 0.18
    height = 0.16 * (font_size / 9.0)
    return width, height


def resolve_label_positions(
    component_nodes: list[dict],
    positions: dict[str, np.ndarray],
    slot: Slot,
) -> dict[str, np.ndarray]:
    center = np.array([slot.center_x, slot.center_y], dtype=float)
    node_ids = [str(node["data"]["id"]) for node in component_nodes]
    anchors: dict[str, np.ndarray] = {}
    label_positions: dict[str, np.ndarray] = {}
    widths: dict[str, float] = {}
    heights: dict[str, float] = {}

    for node in component_nodes:
        node_id = str(node["data"]["id"])
        point = positions[node_id]
        direction = point - center
        norm = float(np.linalg.norm(direction))
        if norm == 0:
            direction = np.array([0.0, 1.0], dtype=float)
            norm = 1.0
        unit = direction / norm
        connector = float(node["data"].get("is_multi_band_connector", 0.0)) >= 1
        offset = 0.16 if connector else 0.12
        anchor = point + unit * offset
        anchors[node_id] = anchor
        label_positions[node_id] = anchor.copy()
        font_size = 8.7 if connector else 7.8
        width, height = approximate_label_box(str(node["data"].get("label", "")), font_size)
        widths[node_id] = width
        heights[node_id] = height

    for _ in range(220):
        moved = False
        for left_idx, left_id in enumerate(node_ids):
            for right_id in node_ids[left_idx + 1 :]:
                delta = label_positions[right_id] - label_positions[left_id]
                overlap_x = (widths[left_id] + widths[right_id]) / 2.0 - abs(delta[0])
                overlap_y = (heights[left_id] + heights[right_id]) / 2.0 - abs(delta[1])
                if overlap_x > 0 and overlap_y > 0:
                    if float(np.linalg.norm(delta)) < 1e-9:
                        delta = np.array([0.01, 0.02], dtype=float)
                    direction = delta / float(np.linalg.norm(delta))
                    push = direction * (0.018 + 0.22 * min(overlap_x, overlap_y))
                    label_positions[left_id] -= push
                    label_positions[right_id] += push
                    moved = True

        for node_id in node_ids:
            label_positions[node_id] += 0.08 * (anchors[node_id] - label_positions[node_id])
            x_min = slot.center_x - slot.width / 2.0 + widths[node_id] / 2.0 + 0.08
            x_max = slot.center_x + slot.width / 2.0 - widths[node_id] / 2.0 - 0.08
            y_min = slot.center_y - slot.height / 2.0 + heights[node_id] / 2.0 + 0.1
            y_max = slot.center_y + slot.height / 2.0 - heights[node_id] / 2.0 - 0.1
            label_positions[node_id][0] = float(np.clip(label_positions[node_id][0], x_min, x_max))
            label_positions[node_id][1] = float(np.clip(label_positions[node_id][1], y_min, y_max))

        if not moved:
            break

    return label_positions


def draw_nodes_and_labels(
    ax: plt.Axes,
    component_nodes: list[dict],
    positions: dict[str, np.ndarray],
    slot: Slot,
) -> None:
    label_positions = resolve_label_positions(component_nodes, positions, slot)
    node_order = sorted(
        component_nodes,
        key=lambda node: float(node["data"].get("is_multi_band_connector", 0.0)),
    )

    for node in node_order:
        data = node["data"]
        node_id = str(data["id"])
        point = positions[node_id]
        connector = float(data.get("is_multi_band_connector", 0.0)) >= 1
        size = float(data.get("node_size_seed", 18.0))
        ax.scatter(
            [point[0]],
            [point[1]],
            s=size * 10.0,
            color=str(data.get("band_color_hex", "#7890a0")),
            edgecolor=CONNECTOR_EDGE_COLOR if connector else NODE_EDGE_COLOR,
            linewidth=2.4 if connector else 1.2,
            alpha=0.98,
            zorder=4,
        )

    for node in component_nodes:
        data = node["data"]
        node_id = str(data["id"])
        point = positions[node_id]
        label_point = label_positions[node_id]
        label = str(data.get("label", ""))
        connector = float(data.get("is_multi_band_connector", 0.0)) >= 1
        if float(np.linalg.norm(label_point - point)) > 0.19:
            ax.plot(
                [point[0], label_point[0]],
                [point[1], label_point[1]],
                color=lighten(str(data.get("band_color_hex", "#7890a0")), 0.25),
                linewidth=0.65,
                alpha=0.55,
                zorder=3,
            )
        text = ax.text(
            label_point[0],
            label_point[1],
            label,
            ha="center",
            va="center",
            fontsize=8.7 if connector else 7.8,
            fontweight="bold" if connector else "normal",
            color=TEXT_COLOR,
            zorder=6,
        )
        text.set_path_effects(
            [patheffects.withStroke(linewidth=3.4, foreground=BACKGROUND_COLOR, alpha=0.97)]
        )


def component_title(component_nodes: list[dict], slot: Slot, ax: plt.Axes) -> None:
    band_counts = Counter(str(node["data"].get("primary_band", "")) for node in component_nodes)
    top_two = [band for band, _ in band_counts.most_common(2)]
    title = " x ".join(top_two)
    connectors = sum(float(node["data"].get("is_multi_band_connector", 0.0)) >= 1 for node in component_nodes)
    subtitle = f"{len(component_nodes)} musicians | {connectors} connectors"
    x_left = slot.center_x - slot.width / 2.0 + 0.22
    y_top = slot.center_y + slot.height / 2.0 - 0.18
    ax.text(
        x_left,
        y_top,
        title,
        ha="left",
        va="top",
        fontsize=10.2,
        fontweight="bold",
        color=TEXT_COLOR,
        zorder=7,
    )
    ax.text(
        x_left,
        y_top - 0.22,
        subtitle,
        ha="left",
        va="top",
        fontsize=8.1,
        color=SUBTEXT_COLOR,
        zorder=7,
    )


def build_summary(nodes: list[dict], edges: list[dict], components: list[list[str]]) -> str:
    connector_count = sum(
        float(node["data"].get("is_multi_band_connector", 0.0)) >= 1 for node in nodes
    )
    repeated_ties = sum(float(edge["data"].get("repeated_tie_i", 0.0)) >= 1 for edge in edges)
    lines = [
        "# Helsinki black metal connector-core atlas",
        "",
        "- Source view: `cytoscape/helsinki_black_metal_connector_core_view.json`",
        f"- Atlas figure: `figures/{PNG_OUTPUT_PATH.name}`",
        f"- Node count: `{len(nodes)}`",
        f"- Edge count: `{len(edges)}`",
        f"- Multi-band connectors: `{connector_count}`",
        f"- Repeated ties: `{repeated_ties}`",
        f"- Connected components shown: `{len(components)}`",
        "",
        "## Read",
        "",
        "- This version treats the Helsinki connector core as a single atlas rather than a cramped one-panel hairball.",
        "- Each floating island is a connected collaboration component, with soft band hulls behind the named musicians.",
        "- Dark outlines identify musicians active in two or more local bands.",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    configure_style()
    view = load_view()
    nodes = view["elements"]["nodes"]
    edges = view["elements"]["edges"]

    node_lookup = {str(node["data"]["id"]): node for node in nodes}
    components = build_components(nodes, edges)

    fig, ax = plt.subplots(figsize=(16.5, 11.6))
    fig.patch.set_facecolor(BACKGROUND_COLOR)
    ax.set_facecolor(BACKGROUND_COLOR)

    for slot, component in zip(SLOTS, components, strict=True):
        draw_slot_card(ax, slot)
        component_set = set(component)
        component_nodes = [node_lookup[node_id] for node_id in component]
        component_edges = [
            edge
            for edge in edges
            if str(edge["data"]["source"]) in component_set and str(edge["data"]["target"]) in component_set
        ]
        positions = normalize_component_positions(component_nodes, slot)
        band_groups = sort_band_groups(component_nodes)
        draw_band_hulls(ax, band_groups, positions)
        draw_edges(ax, component_edges, positions)
        draw_nodes_and_labels(ax, component_nodes, positions, slot)
        component_title(component_nodes, slot, ax)

    connector_count = sum(
        float(node["data"].get("is_multi_band_connector", 0.0)) >= 1 for node in nodes
    )
    repeated_ties = sum(float(edge["data"].get("repeated_tie_i", 0.0)) >= 1 for edge in edges)

    fig.suptitle(
        "Helsinki black metal collaboration core, 2010",
        x=0.06,
        y=0.975,
        ha="left",
        fontsize=23,
        fontweight="bold",
        color=TEXT_COLOR,
    )
    fig.text(
        0.06,
        0.944,
        "Fifty-three musicians arranged as six connected scene islands. Soft hulls mark primary local projects; dark outlines mark multi-band connectors.",
        ha="left",
        fontsize=11.2,
        color=SUBTEXT_COLOR,
    )
    fig.text(
        0.06,
        0.918,
        f"{len(nodes)} musicians | {len(edges)} collaboration ties | {repeated_ties} repeated ties | {connector_count} connectors",
        ha="left",
        fontsize=10.2,
        color=SUBTEXT_COLOR,
    )
    fig.text(
        0.94,
        0.04,
        "Bands are empirical projects; musicians are the workers linking them.",
        ha="right",
        fontsize=9.0,
        color=SUBTEXT_COLOR,
    )

    ax.set_xlim(-8.2, 8.2)
    ax.set_ylim(-5.35, 5.2)
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
