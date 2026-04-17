from __future__ import annotations

import argparse
import math
import re
import unicodedata
from itertools import combinations
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import patheffects
from matplotlib.lines import Line2D


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
FIGURE_DIR = SCENE_DIR / "figures"

SUPPORTING_BANDS_PATH = SCENE_DIR / "broad_city_case_review_supporting_bands.csv"
BRIDGE_MUSICIANS_PATH = SCENE_DIR / "broad_city_case_review_bridge_musicians.csv"
CASE_SUMMARY_PATH = SCENE_DIR / "broad_city_case_review_summary.csv"
FULL_EDGES_PATH = SCENE_DIR / "full_musician_band_edges.csv"

BACKGROUND_COLOR = "#f8f5ef"
TEXT_COLOR = "#2f2f2f"
EDGE_COLOR = "#948574"
EDGE_LIGHT_COLOR = "#cfc4b7"
CONNECTOR_EDGE_COLOR = "#1f1f1f"
NODE_EDGE_COLOR = "#fffaf0"
BAND_PALETTE = [
    "#0b7285",
    "#d17a22",
    "#7b8c3a",
    "#995d81",
    "#4f86c6",
    "#c44536",
]


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return value.strip("_")


def normalize_text(value: object) -> str:
    normalized = unicodedata.normalize("NFKD", str(value))
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    return " ".join(ascii_text.lower().split())


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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a musician-only case-study network figure for a scene case."
    )
    parser.add_argument("--city-country", default="Pittsburgh, United States")
    parser.add_argument("--genre-family", default="doom_metal")
    return parser.parse_args()


def load_case(city_country: str, genre_family: str) -> tuple[pd.DataFrame, pd.DataFrame, pd.Series]:
    supporting = pd.read_csv(SUPPORTING_BANDS_PATH)
    bridges = pd.read_csv(BRIDGE_MUSICIANS_PATH)
    summaries = pd.read_csv(CASE_SUMMARY_PATH)

    case_supporting = supporting.loc[
        supporting["city_country"].eq(city_country) & supporting["genre_family"].eq(genre_family)
    ].copy()
    case_bridges = bridges.loc[
        bridges["city_country"].eq(city_country) & bridges["genre_family"].eq(genre_family)
    ].copy()
    case_summary = summaries.loc[
        summaries["city_country"].eq(city_country) & summaries["genre_family"].eq(genre_family)
    ].copy()

    if case_supporting.empty or case_bridges.empty or case_summary.empty:
        raise ValueError(f"No case packet found for {city_country} / {genre_family}.")

    case_supporting["band_id"] = pd.to_numeric(case_supporting["band_id"], errors="coerce").astype(int)
    case_supporting["community_degree"] = pd.to_numeric(
        case_supporting["community_degree"], errors="coerce"
    ).astype(int)
    case_supporting["formed_year"] = pd.to_numeric(case_supporting["formed_year"], errors="coerce")
    case_supporting["in_target_genre_i"] = pd.to_numeric(
        case_supporting["in_target_genre_i"], errors="coerce"
    ).fillna(0).astype(int)

    case_bridges["member_id"] = pd.to_numeric(case_bridges["member_id"], errors="coerce").astype(int)
    case_bridges["n_community_bands"] = pd.to_numeric(
        case_bridges["n_community_bands"], errors="coerce"
    ).astype(int)

    return case_supporting, case_bridges, case_summary.iloc[0].copy()


def load_relevant_edges(band_ids: set[int]) -> pd.DataFrame:
    usecols = [
        "band_id",
        "band_name",
        "member_id",
        "member_name",
        "first_year_in_band",
        "last_year_in_band",
    ]
    chunks: list[pd.DataFrame] = []
    for chunk in pd.read_csv(
        FULL_EDGES_PATH,
        usecols=usecols,
        engine="python",
        on_bad_lines="skip",
        chunksize=100_000,
    ):
        chunk["band_id"] = pd.to_numeric(chunk["band_id"], errors="coerce")
        band_chunk = chunk.loc[chunk["band_id"].isin(band_ids)].copy()
        if not band_chunk.empty:
            chunks.append(band_chunk)
    if not chunks:
        raise ValueError("No edge rows found for the requested case bands.")
    frame = pd.concat(chunks, ignore_index=True)
    frame["band_id"] = pd.to_numeric(frame["band_id"], errors="coerce").astype(int)
    frame["member_id"] = pd.to_numeric(frame["member_id"], errors="coerce").astype(int)
    frame["first_year_in_band"] = pd.to_numeric(frame["first_year_in_band"], errors="coerce")
    frame["last_year_in_band"] = pd.to_numeric(frame["last_year_in_band"], errors="coerce")
    return frame


def infer_active_edges(frame: pd.DataFrame, detection_year: int) -> pd.DataFrame:
    active_mask = (
        (
            frame["first_year_in_band"].notna()
            & frame["first_year_in_band"].le(detection_year)
            & (frame["last_year_in_band"].isna() | frame["last_year_in_band"].ge(detection_year))
        )
        | (
            frame["first_year_in_band"].isna()
            & frame["last_year_in_band"].notna()
            & frame["last_year_in_band"].ge(detection_year)
        )
    )
    return frame.loc[active_mask].drop_duplicates(subset=["band_id", "member_id"]).reset_index(drop=True)


def supplement_bridge_edges(
    active_edges: pd.DataFrame,
    bridges: pd.DataFrame,
    supporting: pd.DataFrame,
) -> pd.DataFrame:
    band_lookup = {normalize_text(row.band_name): int(row.band_id) for row in supporting.itertuples(index=False)}
    band_name_lookup = {int(row.band_id): str(row.band_name) for row in supporting.itertuples(index=False)}
    bridge_name_lookup = {int(row.member_id): str(row.member_name) for row in bridges.itertuples(index=False)}
    existing_pairs = set(zip(active_edges["member_id"], active_edges["band_id"]))

    extra_rows: list[dict[str, object]] = []
    for row in bridges.itertuples(index=False):
        band_names = [token.strip() for token in str(row.community_bands).split(";") if token.strip()]
        for band_name in band_names:
            band_id = band_lookup.get(normalize_text(band_name))
            if band_id is None:
                continue
            pair = (int(row.member_id), band_id)
            if pair in existing_pairs:
                continue
            extra_rows.append(
                {
                    "band_id": band_id,
                    "band_name": band_name_lookup[band_id],
                    "member_id": int(row.member_id),
                    "member_name": bridge_name_lookup[int(row.member_id)],
                    "first_year_in_band": np.nan,
                    "last_year_in_band": np.nan,
                }
            )
            existing_pairs.add(pair)

    if extra_rows:
        active_edges = pd.concat([active_edges, pd.DataFrame(extra_rows)], ignore_index=True)

    active_edges["member_name"] = active_edges.apply(
        lambda row: bridge_name_lookup.get(int(row["member_id"]), str(row["member_name"])),
        axis=1,
    )
    return active_edges


def build_member_frame(active_edges: pd.DataFrame, supporting: pd.DataFrame) -> pd.DataFrame:
    band_meta = supporting[["band_id", "band_name", "community_degree", "in_target_genre_i"]].copy()

    members = (
        active_edges.groupby(["member_id", "member_name"], as_index=False)
        .agg(
            bands=("band_name", lambda values: sorted(set(values))),
            band_ids=("band_id", lambda values: sorted(set(int(value) for value in values))),
        )
        .sort_values(["member_name", "member_id"])
        .reset_index(drop=True)
    )
    members["n_case_bands"] = members["bands"].map(len)
    members["is_connector"] = members["n_case_bands"].ge(2)

    def choose_primary_band(band_ids: list[int]) -> str:
        candidate_rows = band_meta.loc[band_meta["band_id"].isin(band_ids)].copy()
        candidate_rows = candidate_rows.sort_values(
            ["in_target_genre_i", "community_degree", "band_name"],
            ascending=[False, False, True],
        )
        return str(candidate_rows.iloc[0]["band_name"])

    members["primary_band"] = members["band_ids"].map(choose_primary_band)
    return members


def build_edge_frame(active_edges: pd.DataFrame) -> pd.DataFrame:
    edge_rows: list[dict[str, object]] = []
    for band_name, group in active_edges.groupby("band_name"):
        member_ids = sorted(set(int(value) for value in group["member_id"]))
        for left_id, right_id in combinations(member_ids, 2):
            edge_rows.append(
                {
                    "left_id": left_id,
                    "right_id": right_id,
                    "shared_band": band_name,
                }
            )
    edges = pd.DataFrame(edge_rows)
    if edges.empty:
        return edges
    return (
        edges.groupby(["left_id", "right_id"], as_index=False)
        .agg(
            weight=("shared_band", "count"),
            shared_bands=("shared_band", lambda values: sorted(set(values))),
        )
        .sort_values(["weight", "left_id", "right_id"], ascending=[False, True, True])
        .reset_index(drop=True)
    )


def get_band_centers(supporting: pd.DataFrame) -> dict[str, np.ndarray]:
    ordered = supporting.sort_values(
        ["in_target_genre_i", "community_degree", "formed_year", "band_name"],
        ascending=[False, False, True, True],
    )
    band_names = ordered["band_name"].tolist()
    radius = 2.3
    angles = np.linspace(math.pi / 2, math.pi / 2 + 2 * math.pi, len(band_names), endpoint=False)
    return {
        str(band_name): np.array([radius * math.cos(angle), radius * math.sin(angle)], dtype=float)
        for band_name, angle in zip(band_names, angles, strict=True)
    }


def build_initial_positions(
    members: pd.DataFrame,
    band_centers: dict[str, np.ndarray],
) -> dict[int, np.ndarray]:
    positions: dict[int, np.ndarray] = {}
    for primary_band, group in members.groupby("primary_band"):
        center = band_centers[str(primary_band)]
        angles = np.linspace(0.1, 2 * math.pi + 0.1, len(group), endpoint=False)
        ring_radius = 0.28 + 0.05 * max(0, len(group) - 1)
        for angle, row in zip(angles, group.itertuples(index=False), strict=True):
            offset = np.array([ring_radius * math.cos(angle), ring_radius * math.sin(angle)], dtype=float)
            positions[int(row.member_id)] = center + offset
    return positions


def scale_positions(positions: dict[int, np.ndarray], scale: float = 3.5) -> dict[int, np.ndarray]:
    if not positions:
        return positions
    coords = np.array(list(positions.values()), dtype=float)
    max_abs = float(np.abs(coords).max())
    if max_abs == 0:
        return positions
    factor = scale / max_abs
    return {node_id: value * factor for node_id, value in positions.items()}


def resolve_layout(members: pd.DataFrame, edges: pd.DataFrame, supporting: pd.DataFrame) -> dict[int, np.ndarray]:
    node_ids = [int(value) for value in members["member_id"].tolist()]
    if len(node_ids) == 1:
        return {node_ids[0]: np.array([0.0, 0.0], dtype=float)}

    band_centers = get_band_centers(supporting)
    initial_positions = build_initial_positions(members, band_centers)
    if edges.empty:
        return scale_positions(initial_positions)

    index_lookup = {node_id: idx for idx, node_id in enumerate(node_ids)}
    positions = np.array([initial_positions[node_id] for node_id in node_ids], dtype=float)
    anchor_points = np.array(
        [
            band_centers[str(members.loc[members["member_id"].eq(node_id), "primary_band"].iloc[0])]
            for node_id in node_ids
        ],
        dtype=float,
    )
    edge_triplets = [
        (index_lookup[int(row.left_id)], index_lookup[int(row.right_id)], float(row.weight))
        for row in edges.itertuples(index=False)
    ]

    n_nodes = len(node_ids)
    area = 36.0
    k_value = math.sqrt(area / n_nodes)
    temperature = 0.42

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
            attractive = ((distance * distance) / k_value) * (1.0 + 0.4 * max(0.0, weight - 1.0))
            displacement[left_idx] -= direction * attractive
            displacement[right_idx] += direction * attractive

        displacement += 0.10 * (anchor_points - positions)
        positions -= positions.mean(axis=0)

        norms = np.linalg.norm(displacement, axis=1)
        for idx in range(n_nodes):
            if norms[idx] > 0:
                positions[idx] += displacement[idx] / norms[idx] * min(norms[idx], temperature)

        temperature *= 0.95

    return scale_positions({node_id: positions[idx] for idx, node_id in enumerate(node_ids)})


def degree_lookups(members: pd.DataFrame, edges: pd.DataFrame) -> tuple[dict[int, int], dict[int, float]]:
    degree = {int(member_id): 0 for member_id in members["member_id"]}
    weighted = {int(member_id): 0.0 for member_id in members["member_id"]}
    for row in edges.itertuples(index=False):
        left_id = int(row.left_id)
        right_id = int(row.right_id)
        degree[left_id] += 1
        degree[right_id] += 1
        weighted[left_id] += float(row.weight)
        weighted[right_id] += float(row.weight)
    return degree, weighted


def label_position(position: np.ndarray) -> tuple[float, float]:
    norm = float(np.linalg.norm(position))
    if norm == 0:
        return 0.0, 0.18
    unit = position / norm
    return float(unit[0] * 0.13), float(unit[1] * 0.13)


def band_color_map(supporting: pd.DataFrame) -> dict[str, str]:
    ordered = (
        supporting.sort_values(
            ["in_target_genre_i", "community_degree", "formed_year", "band_name"],
            ascending=[False, False, True, True],
        )["band_name"]
        .tolist()
    )
    return {
        str(band_name): BAND_PALETTE[index % len(BAND_PALETTE)]
        for index, band_name in enumerate(ordered)
    }


def draw_figure(
    supporting: pd.DataFrame,
    summary: pd.Series,
    members: pd.DataFrame,
    edges: pd.DataFrame,
    output_path: Path,
) -> None:
    positions = resolve_layout(members, edges, supporting)
    colors = band_color_map(supporting)

    degree_lookup, weighted_degree_lookup = degree_lookups(members, edges)
    members = members.copy()
    members["degree"] = members["member_id"].map(lambda value: int(degree_lookup.get(int(value), 0)))
    members["weighted_degree"] = members["member_id"].map(
        lambda value: float(weighted_degree_lookup.get(int(value), 0.0))
    )
    members["node_size"] = (
        220
        + 95 * members["weighted_degree"]
        + 120 * (members["n_case_bands"] - 1)
    )

    fig, ax = plt.subplots(figsize=(13.2, 9.0))

    for row in edges.itertuples(index=False):
        left_xy = positions[int(row.left_id)]
        right_xy = positions[int(row.right_id)]
        width = 0.9 + 1.35 * float(row.weight)
        color = EDGE_COLOR if int(row.weight) > 1 else EDGE_LIGHT_COLOR
        alpha = 0.75 if int(row.weight) > 1 else 0.45
        ax.plot(
            [left_xy[0], right_xy[0]],
            [left_xy[1], right_xy[1]],
            color=color,
            linewidth=width,
            alpha=alpha,
            solid_capstyle="round",
            zorder=1,
        )

    draw_order = members.sort_values(["is_connector", "weighted_degree"], ascending=[True, True])
    for row in draw_order.itertuples(index=False):
        xy = positions[int(row.member_id)]
        face_color = colors.get(str(row.primary_band), BAND_PALETTE[0])
        edge_color = CONNECTOR_EDGE_COLOR if bool(row.is_connector) else NODE_EDGE_COLOR
        edge_width = 2.1 if bool(row.is_connector) else 1.0
        ax.scatter(
            [xy[0]],
            [xy[1]],
            s=float(row.node_size),
            color=face_color,
            edgecolor=edge_color,
            linewidth=edge_width,
            alpha=0.96,
            zorder=3,
        )

    labeled = members.sort_values(["is_connector", "weighted_degree"], ascending=[False, False]).copy()
    if labeled.shape[0] > 14:
        labeled = labeled.head(14)

    for row in labeled.itertuples(index=False):
        xy = positions[int(row.member_id)]
        dx_value, dy_value = label_position(xy)
        text = ax.text(
            xy[0] + dx_value,
            xy[1] + dy_value,
            str(row.member_name),
            ha="center",
            va="center",
            fontsize=9.4 if bool(row.is_connector) else 8.0,
            fontweight="bold" if bool(row.is_connector) else "normal",
            zorder=4,
        )
        text.set_path_effects(
            [patheffects.withStroke(linewidth=3.1, foreground=BACKGROUND_COLOR, alpha=0.95)]
        )

    city_name = str(summary["city"])
    genre_label = str(summary["genre_family"]).replace("_", " ")
    detection_year = int(summary["detection_year"])
    repeated_ties = int(edges["weight"].gt(1).sum()) if not edges.empty else 0
    title = f"{city_name} {genre_label} musicians formed a dense local collaboration map by {detection_year}"
    subtitle = (
        "Nodes are musicians. Colors mark each musician's primary local project affiliation. "
        "Edge width increases with repeated shared-band ties."
    )
    ax.set_title(title, fontsize=15, fontweight="bold", loc="left", pad=20)
    fig.text(0.126, 0.915, subtitle, ha="left", fontsize=10, color="#4f4f4f")

    stats_text = (
        f"Detection year: {detection_year}\n"
        f"Lead to emergence: {int(summary['lead_years'])} years\n"
        f"Musicians shown: {members.shape[0]}\n"
        f"Co-worker ties: {edges.shape[0]}\n"
        f"Repeated ties: {repeated_ties}\n"
        f"Target-genre bands in cluster: {int(summary['genre_bands_in_supporting_community'])}/{int(summary['community_size'])}"
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

    band_legend_rows = supporting.sort_values(
        ["in_target_genre_i", "community_degree", "formed_year", "band_name"],
        ascending=[False, False, True, True],
    )
    active_primary_bands = set(members["primary_band"].tolist())
    band_legend_rows = band_legend_rows.loc[band_legend_rows["band_name"].isin(active_primary_bands)].copy()
    legend_items: list[Line2D] = [
        Line2D(
            [0],
            [0],
            marker="o",
            color="none",
            markerfacecolor=colors[str(row.band_name)],
            markeredgecolor=NODE_EDGE_COLOR,
            markersize=10,
            label=str(row.band_name),
        )
        for row in band_legend_rows.itertuples(index=False)
    ]
    legend_items.extend(
        [
            Line2D(
                [0],
                [0],
                marker="o",
                color="none",
                markerfacecolor="#9d9d9d",
                markeredgecolor=CONNECTOR_EDGE_COLOR,
                markeredgewidth=2.0,
                markersize=10,
                label="Multi-band connector outline",
            ),
            Line2D([0], [0], color=EDGE_COLOR, linewidth=2.4, label="Repeated shared-band tie"),
            Line2D([0], [0], color=EDGE_LIGHT_COLOR, linewidth=1.2, label="Single shared-band tie"),
        ]
    )
    ax.legend(
        handles=legend_items,
        loc="lower center",
        bbox_to_anchor=(0.5, -0.04),
        frameon=False,
        fontsize=8.8,
        ncol=4,
        columnspacing=1.4,
        handletextpad=0.5,
    )

    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_aspect("equal")
    ax.set_xlim(-4.5, 4.5)
    ax.set_ylim(-4.2, 4.4)
    for spine in ax.spines.values():
        spine.set_visible(False)

    fig.tight_layout(rect=(0.0, 0.05, 1.0, 0.92))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=240)
    plt.close(fig)


def write_summary(
    summary: pd.Series,
    supporting: pd.DataFrame,
    members: pd.DataFrame,
    edges: pd.DataFrame,
    output_path: Path,
    summary_path: Path,
) -> None:
    connector_names = members.loc[members["is_connector"], "member_name"].tolist()
    repeated_ties = int(edges["weight"].gt(1).sum()) if not edges.empty else 0
    active_primary_bands = set(members["primary_band"].tolist())
    band_labels = supporting.sort_values(
        ["in_target_genre_i", "community_degree", "formed_year", "band_name"],
        ascending=[False, False, True, True],
    )
    band_labels = band_labels.loc[band_labels["band_name"].isin(active_primary_bands), "band_name"].tolist()

    lines = [
        "# Musician-only scene case-study network figure",
        "",
        f"- Figure: `figures/{output_path.name}`",
        f"- Case: `{summary['city_country']}` / `{summary['genre_family']}`",
        f"- Detection year: `{int(summary['detection_year'])}`",
        f"- Musicians shown: `{members.shape[0]}`",
        f"- Co-worker ties shown: `{edges.shape[0]}`",
        f"- Repeated pair ties: `{repeated_ties}`",
        f"- Connectors highlighted by outline: `{len(connector_names)}`",
        "",
        "## Why this version is better",
        "",
        "- The figure is now a weighted musician map rather than a band-bubble diagram.",
        "- Colors mark each musician's primary local project affiliation, which is closer to the clustered visual grammar used in category-network figures.",
        "- Edge width now carries the main overlap information directly: thicker lines mean repeated shared-band ties.",
        f"- The local project palette for this case is `{', '.join(band_labels)}`.",
        f"- The main connector set remains `{', '.join(connector_names)}`.",
    ]
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    configure_style()
    args = parse_args()

    supporting, bridges, summary = load_case(args.city_country, args.genre_family)
    raw_edges = load_relevant_edges(set(supporting["band_id"].tolist()))
    active_edges = infer_active_edges(raw_edges, int(summary["detection_year"]))
    active_edges = supplement_bridge_edges(active_edges, bridges, supporting)
    members = build_member_frame(active_edges, supporting)
    edges = build_edge_frame(active_edges)

    city_slug = slugify(str(summary["city"]))
    genre_slug = slugify(str(summary["genre_family"]))
    output_path = FIGURE_DIR / f"{city_slug}_{genre_slug}_musician_network.png"
    summary_path = SCENE_DIR / f"{city_slug}_{genre_slug}_musician_network_summary.md"

    draw_figure(supporting, summary, members, edges, output_path)
    write_summary(summary, supporting, members, edges, output_path, summary_path)

    print(f"Wrote {output_path}")
    print(f"Wrote {summary_path}")


if __name__ == "__main__":
    main()
