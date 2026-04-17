from __future__ import annotations

import math
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import patheffects
from matplotlib.lines import Line2D
from matplotlib.patches import Patch


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
HELSINKI_DIR = SCENE_DIR / "helsinki_long_window"
FIGURE_DIR = SCENE_DIR / "figures"
RAW_EDGE_PATH = SCENE_DIR / "full_musician_band_edges.csv"

WINDOW_SLUG = "helsinki_finland_2000_2004"
CORE_SLUG = f"{WINDOW_SLUG}_core3_giant"
NODES_PATH = HELSINKI_DIR / f"{CORE_SLUG}_nodes.csv"
EDGES_PATH = HELSINKI_DIR / f"{CORE_SLUG}_edges.csv"
PNG_PATH = FIGURE_DIR / f"{CORE_SLUG}_named_nodes_network.png"
SVG_PATH = FIGURE_DIR / f"{CORE_SLUG}_named_nodes_network.svg"
SUMMARY_PATH = HELSINKI_DIR / f"{CORE_SLUG}_named_nodes_network_summary.md"

BACKGROUND_COLOR = "#f7f4ee"
TEXT_COLOR = "#231f1d"
MUTED_TEXT_COLOR = "#6b645d"
EDGE_COLOR = "#a99c90"
REPEATED_EDGE_COLOR = "#40362f"
BORDER_COLOR = "#f1ebe3"
TOP5_RING_COLOR = "#b5653a"

COLOR_MAP = {
    "3 bands": "#c9d9d2",
    "4 bands": "#90b5aa",
    "5 bands": "#4f8f84",
    "6+ bands": "#1f5b53",
}
START_YEAR = 2000
END_YEAR = 2004
TOP5_FILL_COLOR = "#b5653a"


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


def overlaps_window(row: pd.Series) -> bool:
    first_year = pd.to_numeric(row["first_year_in_band"], errors="coerce")
    last_year = pd.to_numeric(row["last_year_in_band"], errors="coerce")
    if pd.notna(first_year) and first_year > END_YEAR:
        return False
    if pd.notna(last_year) and last_year < START_YEAR:
        return False
    return True


def band_bucket(band_count: int) -> str:
    if band_count >= 6:
        return "6+ bands"
    return f"{band_count} bands"


def fruchterman_reingold_layout(
    nodes: pd.DataFrame,
    edges: pd.DataFrame,
    iterations: int = 320,
    seed: int = 13,
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
    area = max(45.0, 4.1 * n_nodes)
    k_value = math.sqrt(area / n_nodes)
    temperature = 1.05
    gravity = 0.05

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
            attractive = ((distance * distance) / k_value) * (1.0 + 0.28 * max(weight - 1.0, 0.0))
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
        positions *= 8.8 / max_abs
    return {node_id: positions[idx] for idx, node_id in enumerate(node_ids)}


def top_people(nodes: pd.DataFrame, count: int = 5) -> pd.DataFrame:
    return nodes.sort_values(
        ["degree", "weighted_degree", "band_count", "label"],
        ascending=[False, False, False, True],
    ).head(count)


def load_role_lookup(member_ids: list[int]) -> dict[int, str]:
    if not member_ids:
        return {}
    wanted = set(int(member_id) for member_id in member_ids)
    chunks: list[pd.DataFrame] = []
    usecols = [
        "member_id",
        "role",
        "city",
        "country",
        "first_year_in_band",
        "last_year_in_band",
    ]
    for chunk in pd.read_csv(
        RAW_EDGE_PATH,
        usecols=usecols,
        chunksize=200_000,
        engine="python",
        on_bad_lines="skip",
    ):
        chunk["member_id"] = pd.to_numeric(chunk["member_id"], errors="coerce")
        chunk = chunk.loc[
            chunk["member_id"].isin(wanted)
            & chunk["city"].astype(str).eq("Helsinki")
            & chunk["country"].astype(str).eq("Finland")
        ].copy()
        if chunk.empty:
            continue
        chunk = chunk.loc[chunk.apply(overlaps_window, axis=1)].copy()
        if not chunk.empty:
            chunks.append(chunk)
    if not chunks:
        return {}
    roles = pd.concat(chunks, ignore_index=True)
    lookup: dict[int, str] = {}
    for member_id, group in roles.groupby("member_id"):
        parts: list[str] = []
        for role_text in group["role"].dropna().astype(str):
            for part in role_text.split(";"):
                clean = " ".join(part.split())
                if clean and clean not in parts:
                    parts.append(clean)
        lookup[int(member_id)] = ", ".join(parts[:3]) if parts else ""
    return lookup


def draw_graph(nodes: pd.DataFrame, edges: pd.DataFrame) -> pd.DataFrame:
    configure_style()
    anchors = fruchterman_reingold_layout(nodes, edges)
    top5 = top_people(nodes, count=5).copy()
    top5_ids = set(top5["id"].astype(int).tolist())
    role_lookup = load_role_lookup(top5["id"].astype(int).tolist())
    top5["roles"] = top5["id"].map(lambda value: role_lookup.get(int(value), ""))

    fig = plt.figure(figsize=(19.2, 12.8))
    gs = fig.add_gridspec(1, 2, width_ratios=[5.4, 1.75], wspace=0.04)
    ax = fig.add_subplot(gs[0, 0])
    side = fig.add_subplot(gs[0, 1])
    fig.patch.set_facecolor(BACKGROUND_COLOR)
    ax.set_facecolor(BACKGROUND_COLOR)
    side.set_facecolor(BACKGROUND_COLOR)

    for row in edges.itertuples(index=False):
        source = anchors[int(row.source)]
        target = anchors[int(row.target)]
        repeated = int(row.repeated_tie_i) >= 1
        ax.plot(
            [source[0], target[0]],
            [source[1], target[1]],
            color=REPEATED_EDGE_COLOR if repeated else EDGE_COLOR,
            linewidth=2.35 if repeated else 1.35,
            alpha=0.94 if repeated else 0.72,
            solid_capstyle="round",
            zorder=1,
        )

    for row in nodes.itertuples(index=False):
        node_id = int(row.id)
        pos = anchors[node_id]
        bucket = band_bucket(int(row.band_count))
        fill = COLOR_MAP[bucket]
        size = 22 + 10 * math.sqrt(max(float(row.degree), 1.0))
        key_person = node_id in top5_ids
        ax.scatter(
            [pos[0]],
            [pos[1]],
            s=size * (1.5 if key_person else 1.08),
            color=TOP5_FILL_COLOR if key_person else fill,
            edgecolor=TEXT_COLOR if key_person else BORDER_COLOR,
            linewidth=1.6 if key_person else 0.9,
            alpha=0.95 if key_person else 0.88,
            zorder=3,
        )

    fig.suptitle(
        "Helsinki musician collaboration network, 2000-2004",
        x=0.05,
        y=0.975,
        ha="left",
        fontsize=23,
        fontweight="bold",
        color=TEXT_COLOR,
    )
    fig.text(
        0.05,
        0.944,
        "Each circle is a musician. A link means two musicians played together in at least one Helsinki metal band during the five-year window.",
        ha="left",
        fontsize=10.8,
        color=MUTED_TEXT_COLOR,
    )

    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)

    coords = np.array(list(anchors.values()), dtype=float)
    if coords.size:
        min_x, min_y = coords.min(axis=0)
        max_x, max_y = coords.max(axis=0)
        pad_x = 1.4
        pad_y = 1.2
        ax.set_xlim(min_x - pad_x, max_x + pad_x)
        ax.set_ylim(min_y - pad_y, max_y + pad_y)

    side.axis("off")
    side.text(
        0.0,
        0.98,
        "Top 5 By Unique Collaborators",
        ha="left",
        va="top",
        fontsize=12.0,
        fontweight="bold",
        color=TEXT_COLOR,
        transform=side.transAxes,
    )

    y_pos = 0.91
    for idx, row in enumerate(top5.itertuples(index=False), start=1):
        bucket = band_bucket(int(row.band_count))
        side.scatter(
            [0.015],
            [y_pos - 0.01],
            s=115,
            color=TOP5_FILL_COLOR,
            edgecolors=TEXT_COLOR,
            linewidths=1.6,
            transform=side.transAxes,
            clip_on=False,
            zorder=3,
        )
        line = f"{row.label}"
        detail = f"{int(row.degree)} collaborators | {int(row.band_count)} bands"
        roles = row.roles
        side.text(
            0.06,
            y_pos,
            line,
            ha="left",
            va="top",
            fontsize=10.2,
            fontweight="bold",
            color=TEXT_COLOR,
            transform=side.transAxes,
        )
        side.text(
            0.06,
            y_pos - 0.035,
            detail,
            ha="left",
            va="top",
            fontsize=9.2,
            color=MUTED_TEXT_COLOR,
            transform=side.transAxes,
        )
        side.text(
            0.06,
            y_pos - 0.066,
            roles if roles else "Instrument mix unavailable",
            ha="left",
            va="top",
            fontsize=8.7,
            color=MUTED_TEXT_COLOR,
            transform=side.transAxes,
        )
        y_pos -= 0.125

    side.text(
        0.0,
        0.33,
        "Node Color",
        ha="left",
        va="top",
        fontsize=11.2,
        fontweight="bold",
        color=TEXT_COLOR,
        transform=side.transAxes,
    )

    handles = [Patch(facecolor=TOP5_FILL_COLOR, edgecolor=TEXT_COLOR, label="Top 5 highlighted")]
    handles.extend(
        [Patch(facecolor=COLOR_MAP[label], edgecolor=BORDER_COLOR, label=label) for label in ["3 bands", "4 bands", "5 bands", "6+ bands"]]
    )
    side.legend(
        handles=handles,
        loc="upper left",
        bbox_to_anchor=(0.0, 0.295),
        frameon=False,
        fontsize=9.3,
        handlelength=1.2,
        handletextpad=0.6,
        borderaxespad=0.0,
    )

    side.text(
        0.0,
        0.20,
        "Color shows how many Helsinki bands\neach musician played in during\n2000-2004.",
        ha="left",
        va="top",
        fontsize=9.0,
        color=MUTED_TEXT_COLOR,
        transform=side.transAxes,
    )

    side.text(
        0.0,
        0.11,
        "Edge Key",
        ha="left",
        va="top",
        fontsize=11.2,
        fontweight="bold",
        color=TEXT_COLOR,
        transform=side.transAxes,
    )
    edge_handles = [
        Line2D([0], [0], color=EDGE_COLOR, linewidth=1.8, label="Shared one band"),
        Line2D([0], [0], color=REPEATED_EDGE_COLOR, linewidth=2.8, label="Shared multiple bands"),
    ]
    side.legend(
        handles=edge_handles,
        loc="upper left",
        bbox_to_anchor=(0.0, 0.085),
        frameon=False,
        fontsize=9.2,
        handlelength=2.2,
        handletextpad=0.6,
        borderaxespad=0.0,
    )

    FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(PNG_PATH, dpi=280, bbox_inches="tight")
    fig.savefig(SVG_PATH, bbox_inches="tight")
    plt.close(fig)
    return top5


def write_summary(nodes: pd.DataFrame, edges: pd.DataFrame, top5: pd.DataFrame) -> None:
    repeated = int(edges["repeated_tie_i"].sum()) if not edges.empty else 0
    lines = [
        "# Helsinki collaborator-circle network, 2000-2004",
        "",
        f"- Source nodes: `{NODES_PATH.name}`",
        f"- Source edges: `{EDGES_PATH.name}`",
        f"- Nodes shown: `{len(nodes)}`",
        f"- Edges shown: `{len(edges)}`",
        f"- Repeated ties: `{repeated}`",
        "",
        "## Top 5 by unique collaborators",
        "",
    ]
    for row in top5.itertuples(index=False):
        lines.append(
            f"- `{row.label}`: `{int(row.degree)}` collaborators, `{int(row.band_count)}` bands, `{row.roles}`"
        )
    lines.extend(
        [
            "",
            "## Read",
            "",
            "- Every musician in the core is shown as a circle rather than a text label.",
            "- Node color marks how many Helsinki bands the musician played in during the five-year window.",
            "- The sidebar ranks the five most connected musicians by unique collaborators and lists their instruments.",
            "- Darker thicker edges mark pairs who shared multiple Helsinki bands; lighter edges mark pairs who shared one band.",
        ]
    )
    SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    nodes, edges = load_data()
    top10 = draw_graph(nodes, edges)
    write_summary(nodes, edges, top10)
    print(f"Wrote {PNG_PATH}")
    print(f"Wrote {SVG_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
