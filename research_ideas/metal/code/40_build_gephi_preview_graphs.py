from __future__ import annotations

import math
from collections import defaultdict, deque
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import patheffects
from matplotlib.lines import Line2D


PROJECT_ROOT = Path(__file__).resolve().parents[1]
EXPORT_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks" / "gephi_exports"

BACKGROUND_COLOR = "#f8f5ef"
TEXT_COLOR = "#2f2f2f"
EDGE_COLOR = "#8f7f6d"
EDGE_LIGHT_COLOR = "#d8cec2"
NODE_EDGE_COLOR = "#fffaf0"
CONNECTOR_EDGE_COLOR = "#1b1b1b"
PALETTE = [
    "#0b7285",
    "#d17a22",
    "#7b8c3a",
    "#995d81",
    "#4f86c6",
    "#c44536",
    "#5f7c8a",
    "#a37c27",
    "#557a46",
    "#a14e6b",
]

CASE_SPECS = [
    {
        "slug": "helsinki_finland_death_metal_2005",
        "title": "Helsinki death metal collaboration map, 2005",
        "subtitle": "Large local labor-market snapshot with broad scale but weak overlap across clusters.",
    },
    {
        "slug": "helsinki_finland_black_metal_2010",
        "title": "Helsinki black metal collaboration map, 2010",
        "subtitle": "Smaller than the death-metal map, but denser in repeated ties and connector overlap.",
    },
]


def configure_style() -> None:
    plt.rcParams.update(
        {
            "axes.facecolor": BACKGROUND_COLOR,
            "figure.facecolor": BACKGROUND_COLOR,
            "savefig.facecolor": BACKGROUND_COLOR,
            "font.size": 10,
            "text.color": TEXT_COLOR,
            "axes.labelcolor": TEXT_COLOR,
        }
    )


def band_color_map(primary_bands: list[str]) -> dict[str, str]:
    ordered = sorted(primary_bands)
    return {band_name: PALETTE[index % len(PALETTE)] for index, band_name in enumerate(ordered)}


def get_band_centers(primary_bands: list[str], radius: float) -> dict[str, np.ndarray]:
    n_bands = max(1, len(primary_bands))
    if n_bands == 1:
        return {primary_bands[0]: np.array([0.0, 0.0], dtype=float)}
    angles = np.linspace(math.pi / 2, math.pi / 2 + 2 * math.pi, n_bands, endpoint=False)
    return {
        band_name: np.array([radius * math.cos(angle), radius * math.sin(angle)], dtype=float)
        for band_name, angle in zip(primary_bands, angles, strict=True)
    }


def build_initial_positions(nodes: pd.DataFrame, band_centers: dict[str, np.ndarray]) -> dict[int, np.ndarray]:
    positions: dict[int, np.ndarray] = {}
    for primary_band, group in nodes.groupby("primary_band"):
        center = band_centers[str(primary_band)]
        angles = np.linspace(0.25, 2 * math.pi + 0.25, len(group), endpoint=False)
        radius = 0.22 + 0.06 * max(0, len(group) - 1)
        for angle, row in zip(angles, group.itertuples(index=False), strict=True):
            offset = np.array([radius * math.cos(angle), radius * math.sin(angle)], dtype=float)
            positions[int(row.id)] = center + offset
    return positions


def scale_positions(positions: dict[int, np.ndarray], scale: float = 4.15) -> dict[int, np.ndarray]:
    if not positions:
        return positions
    coords = np.array(list(positions.values()), dtype=float)
    max_abs = float(np.abs(coords).max())
    if max_abs <= 0:
        return positions
    factor = scale / max_abs
    return {node_id: value * factor for node_id, value in positions.items()}


def build_components(nodes: pd.DataFrame, edges: pd.DataFrame) -> list[list[int]]:
    adjacency: dict[int, set[int]] = defaultdict(set)
    for node_id in nodes["id"].astype(int).tolist():
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


def subset_to_ids(nodes: pd.DataFrame, edges: pd.DataFrame, node_ids: set[int]) -> tuple[pd.DataFrame, pd.DataFrame]:
    sub_nodes = nodes.loc[nodes["id"].isin(node_ids)].copy()
    sub_edges = edges.loc[edges["source"].isin(node_ids) & edges["target"].isin(node_ids)].copy()
    return sub_nodes.reset_index(drop=True), sub_edges.reset_index(drop=True)


def filter_connector_core(nodes: pd.DataFrame, edges: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, int]:
    connector_ids = set(nodes.loc[nodes["is_multi_band_connector"].eq(1), "id"].astype(int).tolist())
    if not connector_ids:
        return nodes.copy(), edges.copy(), len(build_components(nodes, edges))

    kept_node_ids: set[int] = set()
    kept_component_count = 0
    for component in build_components(nodes, edges):
        component_set = set(component)
        if component_set & connector_ids:
            kept_component_count += 1
            kept_node_ids.update(component_set)
    return (*subset_to_ids(nodes, edges, kept_node_ids), kept_component_count)


def component_anchor_points(n_components: int) -> list[np.ndarray]:
    if n_components <= 1:
        return [np.array([0.0, 0.0], dtype=float)]
    radius = 1.7 if n_components <= 4 else 2.05 if n_components <= 6 else 2.35
    angles = np.linspace(math.pi / 2, math.pi / 2 + 2 * math.pi, n_components, endpoint=False)
    return [np.array([radius * math.cos(angle), radius * math.sin(angle)], dtype=float) for angle in angles]


def component_layout(sub_nodes: pd.DataFrame, sub_edges: pd.DataFrame, anchor: np.ndarray) -> dict[int, np.ndarray]:
    node_ids = [int(value) for value in sub_nodes["id"].tolist()]
    if len(node_ids) == 1:
        return {node_ids[0]: anchor.copy()}

    primary_bands = sorted(sub_nodes["primary_band"].astype(str).unique().tolist())
    band_radius = 0.35 + 0.12 * min(4, len(primary_bands) - 1)
    band_centers = get_band_centers(primary_bands, radius=band_radius)
    initial_positions = build_initial_positions(sub_nodes, band_centers)

    index_lookup = {node_id: idx for idx, node_id in enumerate(node_ids)}
    positions = np.array([initial_positions[node_id] for node_id in node_ids], dtype=float)
    anchor_points = np.array(
        [
            band_centers[str(sub_nodes.loc[sub_nodes["id"].eq(node_id), "primary_band"].iloc[0])]
            for node_id in node_ids
        ],
        dtype=float,
    )
    edge_triplets = [
        (index_lookup[int(row.source)], index_lookup[int(row.target)], float(row.weight))
        for row in sub_edges.itertuples(index=False)
    ]

    n_nodes = len(node_ids)
    area = max(7.0, 2.6 * n_nodes)
    k_value = math.sqrt(area / n_nodes)
    temperature = 0.34 if n_nodes <= 12 else 0.4

    for _ in range(260):
        displacement = np.zeros_like(positions)

        for left in range(n_nodes):
            delta = positions[left] - positions
            distance = np.linalg.norm(delta, axis=1)
            distance[left] = 1.0
            force = (k_value * k_value) / distance
            repulsion = (delta / distance[:, None]) * force[:, None]
            repulsion[left] = 0.0
            displacement[left] += repulsion.sum(axis=0)

        for left_idx, right_idx, weight in edge_triplets:
            delta = positions[left_idx] - positions[right_idx]
            distance = float(np.linalg.norm(delta))
            if distance == 0:
                delta = np.array([0.01, 0.0], dtype=float)
                distance = 0.01
            direction = delta / distance
            attractive = ((distance * distance) / k_value) * (1.0 + 0.6 * max(0.0, weight - 1.0))
            displacement[left_idx] -= direction * attractive
            displacement[right_idx] += direction * attractive

        displacement += 0.16 * (anchor_points - positions)
        positions -= positions.mean(axis=0)

        norms = np.linalg.norm(displacement, axis=1)
        for idx in range(n_nodes):
            if norms[idx] > 0:
                positions[idx] += displacement[idx] / norms[idx] * min(norms[idx], temperature)

        temperature *= 0.968

    cluster_extent = 0.58 + 0.14 * math.sqrt(n_nodes)
    coords = np.array([positions.min(axis=0), positions.max(axis=0)], dtype=float)
    max_abs = float(np.abs(coords).max())
    if max_abs > 0:
        positions *= cluster_extent / max_abs
    positions += anchor
    return {node_id: positions[idx] for idx, node_id in enumerate(node_ids)}


def resolve_layout(nodes: pd.DataFrame, edges: pd.DataFrame) -> dict[int, np.ndarray]:
    components = build_components(nodes, edges)
    anchors = component_anchor_points(len(components))
    positions: dict[int, np.ndarray] = {}
    for component, anchor in zip(components, anchors, strict=True):
        sub_nodes, sub_edges = subset_to_ids(nodes, edges, set(component))
        positions.update(component_layout(sub_nodes, sub_edges, anchor=anchor))
    return scale_positions(positions)


def label_position(position: np.ndarray) -> tuple[float, float]:
    norm = float(np.linalg.norm(position))
    if norm == 0:
        return 0.0, 0.18
    unit = position / norm
    return float(unit[0] * 0.12), float(unit[1] * 0.12)


def load_case(slug: str) -> tuple[pd.DataFrame, pd.DataFrame]:
    nodes = pd.read_csv(EXPORT_DIR / f"{slug}_nodes.csv")
    edges = pd.read_csv(EXPORT_DIR / f"{slug}_edges.csv")
    nodes["id"] = pd.to_numeric(nodes["id"], errors="coerce").astype(int)
    nodes["band_count"] = pd.to_numeric(nodes["band_count"], errors="coerce").fillna(1).astype(int)
    nodes["is_multi_band_connector"] = pd.to_numeric(
        nodes["is_multi_band_connector"], errors="coerce"
    ).fillna(0).astype(int)
    nodes["node_size_seed"] = pd.to_numeric(nodes["node_size_seed"], errors="coerce").fillna(20.0)
    nodes["weighted_degree_seed"] = pd.to_numeric(
        nodes["weighted_degree_seed"], errors="coerce"
    ).fillna(0.0)
    nodes["label_show_i"] = pd.to_numeric(nodes["label_show_i"], errors="coerce").fillna(0).astype(int)
    edges["source"] = pd.to_numeric(edges["source"], errors="coerce").astype(int)
    edges["target"] = pd.to_numeric(edges["target"], errors="coerce").astype(int)
    edges["weight"] = pd.to_numeric(edges["weight"], errors="coerce").fillna(1.0)
    edges["edge_width_seed"] = pd.to_numeric(edges["edge_width_seed"], errors="coerce").fillna(1.2)
    edges["repeated_tie_i"] = pd.to_numeric(edges["repeated_tie_i"], errors="coerce").fillna(0).astype(int)
    return nodes, edges


def legend_handles(colors: dict[str, str], nodes: pd.DataFrame) -> list[Line2D]:
    top_bands = nodes.groupby("primary_band")["id"].count().sort_values(ascending=False).head(6)
    items = [
        Line2D(
            [0],
            [0],
            marker="o",
            color="none",
            markerfacecolor=colors[band_name],
            markeredgecolor=NODE_EDGE_COLOR,
            markersize=9,
            label=band_name,
        )
        for band_name in top_bands.index.tolist()
    ]
    items.extend(
        [
            Line2D(
                [0],
                [0],
                marker="o",
                color="none",
                markerfacecolor="#9d9d9d",
                markeredgecolor=CONNECTOR_EDGE_COLOR,
                markeredgewidth=2.0,
                markersize=9,
                label="Connector outline",
            ),
            Line2D([0], [0], color=EDGE_COLOR, linewidth=2.4, label="Repeated tie"),
            Line2D([0], [0], color=EDGE_LIGHT_COLOR, linewidth=1.3, label="Single tie"),
        ]
    )
    return items


def draw_case(spec: dict[str, str], connector_core_only: bool) -> dict[str, object]:
    nodes, edges = load_case(spec["slug"])
    component_count = len(build_components(nodes, edges))

    if connector_core_only:
        nodes, edges, kept_component_count = filter_connector_core(nodes, edges)
        mode_label = "Connector-core map"
        subtitle = "Only connected components with multi-band bridges are kept so recombination is visible."
        output_name = f"{spec['slug']}_connector_core_preview.png"
        title = spec["title"].replace("collaboration map", "connector-core map")
        component_count = kept_component_count
    else:
        mode_label = "Full scene map"
        subtitle = spec["subtitle"]
        output_name = f"{spec['slug']}_preview.png"
        title = spec["title"]

    positions = resolve_layout(nodes, edges)
    colors = band_color_map(sorted(nodes["primary_band"].astype(str).unique().tolist()))

    fig, ax = plt.subplots(figsize=(13.4, 9.2))

    for row in edges.itertuples(index=False):
        left_xy = positions[int(row.source)]
        right_xy = positions[int(row.target)]
        color = EDGE_COLOR if int(row.repeated_tie_i) == 1 else EDGE_LIGHT_COLOR
        alpha = 0.84 if int(row.repeated_tie_i) == 1 else 0.46
        ax.plot(
            [left_xy[0], right_xy[0]],
            [left_xy[1], right_xy[1]],
            color=color,
            linewidth=float(row.edge_width_seed),
            alpha=alpha,
            solid_capstyle="round",
            zorder=1,
        )

    draw_nodes = nodes.sort_values(
        ["is_multi_band_connector", "weighted_degree_seed"],
        ascending=[True, True],
    )
    for row in draw_nodes.itertuples(index=False):
        xy = positions[int(row.id)]
        ax.scatter(
            [xy[0]],
            [xy[1]],
            s=float(row.node_size_seed) * 12.0,
            color=colors[str(row.primary_band)],
            edgecolor=CONNECTOR_EDGE_COLOR if int(row.is_multi_band_connector) == 1 else NODE_EDGE_COLOR,
            linewidth=2.2 if int(row.is_multi_band_connector) == 1 else 0.9,
            alpha=0.98,
            zorder=3,
        )

    label_nodes = nodes.loc[nodes["label_show_i"].eq(1)].copy()
    if connector_core_only:
        label_nodes = label_nodes.sort_values(
            ["is_multi_band_connector", "weighted_degree_seed", "label"],
            ascending=[False, False, True],
        ).head(16)
    for row in label_nodes.itertuples(index=False):
        xy = positions[int(row.id)]
        dx_value, dy_value = label_position(xy)
        text = ax.text(
            xy[0] + dx_value,
            xy[1] + dy_value,
            str(row.label),
            ha="center",
            va="center",
            fontsize=9.8 if int(row.is_multi_band_connector) == 1 else 8.3,
            fontweight="bold" if int(row.is_multi_band_connector) == 1 else "normal",
            zorder=4,
        )
        text.set_path_effects(
            [patheffects.withStroke(linewidth=3.1, foreground=BACKGROUND_COLOR, alpha=0.97)]
        )

    repeated_ties = int(edges["repeated_tie_i"].sum()) if not edges.empty else 0
    ax.set_title(title, fontsize=16, fontweight="bold", loc="left", pad=20)
    fig.text(0.126, 0.92, subtitle, ha="left", fontsize=10, color="#4f4f4f")

    stats_text = (
        f"Mode: {mode_label}\n"
        f"Musicians: {len(nodes):,}\n"
        f"Collaboration edges: {len(edges):,}\n"
        f"Repeated ties: {repeated_ties:,}\n"
        f"Multi-band connectors: {int(nodes['is_multi_band_connector'].sum()):,}\n"
        f"Connected components: {component_count:,}"
    )
    ax.text(
        0.02,
        0.98,
        stats_text,
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=9,
        bbox={"boxstyle": "round,pad=0.5", "facecolor": "#fffdf8", "edgecolor": "#d9d2c5"},
    )

    ax.legend(
        handles=legend_handles(colors, nodes),
        loc="lower center",
        bbox_to_anchor=(0.5, -0.04),
        frameon=False,
        fontsize=8.7,
        ncol=4,
        columnspacing=1.3,
        handletextpad=0.5,
    )

    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_aspect("equal")
    ax.set_xlim(-5.0, 5.0)
    ax.set_ylim(-4.8, 4.9)
    for spine in ax.spines.values():
        spine.set_visible(False)

    output_path = EXPORT_DIR / output_name
    fig.tight_layout(rect=(0.0, 0.05, 1.0, 0.93))
    fig.savefig(output_path, dpi=220)
    plt.close(fig)

    return {
        "slug": spec["slug"],
        "title": title,
        "mode": mode_label,
        "output_path": output_path,
        "n_nodes": int(len(nodes)),
        "n_edges": int(len(edges)),
        "repeated_ties": repeated_ties,
        "n_connectors": int(nodes["is_multi_band_connector"].sum()),
        "component_count": int(component_count),
    }


def write_summary(results: list[dict[str, object]]) -> None:
    summary_path = EXPORT_DIR / "helsinki_gephi_preview_comparison.md"
    lines = [
        "# Helsinki network preview comparison",
        "",
        "This file compares the static preview renders built from the Gephi export packages.",
        "",
        "| Case | Mode | Preview | Musicians | Edges | Repeated ties | Connectors | Components |",
        "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for result in results:
        lines.append(
            "| {title} | {mode} | `{preview}` | {nodes:,} | {edges:,} | {repeated:,} | {connectors:,} | {components:,} |".format(
                title=result["title"],
                mode=result["mode"],
                preview=result["output_path"].name,
                nodes=int(result["n_nodes"]),
                edges=int(result["n_edges"]),
                repeated=int(result["repeated_ties"]),
                connectors=int(result["n_connectors"]),
                components=int(result["component_count"]),
            )
        )
    lines.extend(
        [
            "",
            "## Current read",
            "",
            "- The full-scene maps are informative diagnostics, but both are fragmented because a city-year network contains many disconnected band cliques.",
            "- The connector-core maps read much better as paper objects because they keep only the components that actually contain multi-band bridges.",
            "- `Helsinki / black_metal / 2010` is the strongest thick-scene visual: even after trimming to the connector core it still has substantial scale and visibly richer overlap than the death-metal case.",
            "- `Helsinki / death_metal / 2005` remains useful as a contrast case for thickness without much cross-cluster overlap.",
        ]
    )
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    configure_style()
    results: list[dict[str, object]] = []
    for spec in CASE_SPECS:
        results.append(draw_case(spec, connector_core_only=False))
        results.append(draw_case(spec, connector_core_only=True))
    write_summary(results)
    for result in results:
        print(f"Wrote {result['output_path']}")
    print(f"Wrote {EXPORT_DIR / 'helsinki_gephi_preview_comparison.md'}")


if __name__ == "__main__":
    main()
