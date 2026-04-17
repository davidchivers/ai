from __future__ import annotations

import argparse
import math
import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
FIGURE_DIR = SCENE_DIR / "figures"

SUPPORTING_BANDS_PATH = SCENE_DIR / "broad_city_case_review_supporting_bands.csv"
BRIDGE_MUSICIANS_PATH = SCENE_DIR / "broad_city_case_review_bridge_musicians.csv"
CASE_SUMMARY_PATH = SCENE_DIR / "broad_city_case_review_summary.csv"
FULL_EDGES_PATH = SCENE_DIR / "full_musician_band_edges.csv"

BACKGROUND_COLOR = "#f8f5ef"
EDGE_COLOR = "#b7aea1"
TARGET_BAND_COLOR = "#0b7285"
SUPPORT_BAND_COLOR = "#c44536"
BRIDGE_MUSICIAN_COLOR = "#c77d1a"
SINGLE_MUSICIAN_COLOR = "#d0d7de"
LABEL_COLOR = "#2f2f2f"


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return value.strip("_")


def configure_style() -> None:
    plt.rcParams.update(
        {
            "axes.facecolor": BACKGROUND_COLOR,
            "figure.facecolor": BACKGROUND_COLOR,
            "savefig.facecolor": BACKGROUND_COLOR,
            "font.size": 10,
            "axes.edgecolor": BACKGROUND_COLOR,
            "axes.labelcolor": LABEL_COLOR,
            "text.color": LABEL_COLOR,
        }
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a case-study bipartite network figure for a scene case."
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
        raise ValueError(f"No case-review packet found for {city_country} / {genre_family}.")

    case_supporting["band_id"] = pd.to_numeric(case_supporting["band_id"], errors="coerce").astype(int)
    case_supporting["community_degree"] = pd.to_numeric(case_supporting["community_degree"], errors="coerce").astype(int)
    case_supporting["formed_year"] = pd.to_numeric(case_supporting["formed_year"], errors="coerce")
    case_supporting["in_target_genre_i"] = pd.to_numeric(case_supporting["in_target_genre_i"], errors="coerce").fillna(0).astype(int)

    case_bridges["member_id"] = pd.to_numeric(case_bridges["member_id"], errors="coerce").astype(int)
    case_bridges["n_community_bands"] = pd.to_numeric(case_bridges["n_community_bands"], errors="coerce").astype(int)

    summary = case_summary.iloc[0].copy()
    return case_supporting, case_bridges, summary


def load_relevant_edges(band_ids: set[int]) -> pd.DataFrame:
    usecols = [
        "band_id",
        "band_name",
        "member_id",
        "member_name",
        "first_year_in_band",
        "last_year_in_band",
        "role",
    ]
    chunks: list[pd.DataFrame] = []
    for chunk in pd.read_csv(
        FULL_EDGES_PATH,
        usecols=usecols,
        engine="python",
        on_bad_lines="skip",
        chunksize=100_000,
    ):
        band_chunk = chunk.loc[pd.to_numeric(chunk["band_id"], errors="coerce").isin(band_ids)].copy()
        if not band_chunk.empty:
            chunks.append(band_chunk)
    if not chunks:
        raise ValueError("No member-band rows found for the selected case.")
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
    active = frame.loc[active_mask].copy()
    active = active.drop_duplicates(subset=["band_id", "member_id"]).reset_index(drop=True)
    return active


def supplement_bridge_edges(
    active_edges: pd.DataFrame,
    bridges: pd.DataFrame,
    supporting: pd.DataFrame,
) -> pd.DataFrame:
    band_lookup = supporting.set_index("band_name")[["band_id"]].to_dict("index")
    existing_pairs = set(zip(active_edges["band_id"], active_edges["member_id"]))
    extra_rows: list[dict[str, object]] = []

    for row in bridges.itertuples(index=False):
        band_names = [token.strip() for token in str(row.community_bands).split(";") if token.strip()]
        for band_name in band_names:
            if band_name not in band_lookup:
                continue
            band_id = int(band_lookup[band_name]["band_id"])
            pair = (band_id, int(row.member_id))
            if pair in existing_pairs:
                continue
            extra_rows.append(
                {
                    "band_id": band_id,
                    "band_name": band_name,
                    "member_id": int(row.member_id),
                    "member_name": str(row.member_name),
                    "first_year_in_band": np.nan,
                    "last_year_in_band": np.nan,
                    "role": "",
                }
            )
            existing_pairs.add(pair)

    if extra_rows:
        active_edges = pd.concat([active_edges, pd.DataFrame(extra_rows)], ignore_index=True)

    return active_edges


def build_membership(active_edges: pd.DataFrame) -> pd.DataFrame:
    member_band_counts = (
        active_edges.groupby(["member_id", "member_name"], as_index=False)
        .agg(active_case_bands=("band_id", "nunique"))
    )
    return active_edges.merge(member_band_counts, on=["member_id", "member_name"], how="left")


def get_band_positions(supporting: pd.DataFrame) -> dict[str, tuple[float, float]]:
    ordered = supporting.sort_values(["community_degree", "formed_year", "band_name"], ascending=[False, True, True])
    band_names = ordered["band_name"].tolist()
    band_degrees = ordered["community_degree"].tolist()

    positions: dict[str, tuple[float, float]] = {}
    if len(band_names) >= 4 and band_degrees[0] >= band_degrees[1] + 2:
        center_band = band_names[0]
        positions[center_band] = (0.0, 0.0)
        others = band_names[1:]
        radius = 2.5
        angles = np.linspace(math.pi / 2, math.pi / 2 + 2 * math.pi, len(others), endpoint=False)
        for band_name, angle in zip(others, angles, strict=True):
            positions[band_name] = (radius * math.cos(angle), radius * math.sin(angle))
        return positions

    radius = 2.6
    angles = np.linspace(math.pi / 2, math.pi / 2 + 2 * math.pi, len(band_names), endpoint=False)
    for band_name, angle in zip(band_names, angles, strict=True):
        positions[band_name] = (radius * math.cos(angle), radius * math.sin(angle))
    return positions


def assign_member_positions(
    membership: pd.DataFrame,
    bridge_ids: set[int],
    band_positions: dict[str, tuple[float, float]],
) -> dict[int, tuple[float, float]]:
    positions: dict[int, tuple[float, float]] = {}

    active_by_member = (
        membership.groupby(["member_id", "member_name"], as_index=False)
        .agg(bands=("band_name", lambda values: sorted(set(values))))
        .sort_values(["member_name", "member_id"])
        .reset_index(drop=True)
    )

    bridge_members = active_by_member.loc[
        active_by_member["member_id"].isin(bridge_ids) | active_by_member["bands"].map(len).ge(2)
    ].copy()
    single_members = active_by_member.loc[
        ~(active_by_member["member_id"].isin(bridge_ids) | active_by_member["bands"].map(len).ge(2))
    ].copy()

    grouped_bridge: dict[tuple[str, ...], list[tuple[int, str]]] = {}
    for row in bridge_members.itertuples(index=False):
        grouped_bridge.setdefault(tuple(row.bands), []).append((int(row.member_id), str(row.member_name)))

    for bands_key, members in grouped_bridge.items():
        coords = np.array([band_positions[band_name] for band_name in bands_key], dtype=float)
        centroid = coords.mean(axis=0)
        if len(bands_key) == 2:
            vector = coords[1] - coords[0]
            norm = np.linalg.norm(vector)
            if norm == 0:
                perp = np.array([0.0, 1.0])
            else:
                perp = np.array([-vector[1], vector[0]]) / norm
            offsets = np.linspace(-0.35, 0.35, len(members))
            for offset, (member_id, _) in zip(offsets, members, strict=True):
                positions[member_id] = tuple(centroid + offset * perp)
        else:
            angles = np.linspace(math.pi / 2, math.pi / 2 + 2 * math.pi, len(members), endpoint=False)
            radius = 0.42 if len(bands_key) >= 3 else 0.28
            for angle, (member_id, _) in zip(angles, members, strict=True):
                offset = np.array([radius * math.cos(angle), radius * math.sin(angle)])
                positions[member_id] = tuple(centroid + offset)

    single_lookup = membership.groupby("band_name")["member_id"].apply(lambda values: sorted(set(values))).to_dict()
    for band_name, member_ids in single_lookup.items():
        pure_single_ids = [member_id for member_id in member_ids if member_id in set(single_members["member_id"])]
        if not pure_single_ids:
            continue
        base = np.array(band_positions[band_name], dtype=float)
        angles = np.linspace(0.0, 2 * math.pi, len(pure_single_ids), endpoint=False)
        for angle, member_id in zip(angles, pure_single_ids, strict=True):
            offset = np.array([0.95 * math.cos(angle), 0.95 * math.sin(angle)])
            positions[int(member_id)] = tuple(base + offset)

    return positions


def draw_case_figure(
    supporting: pd.DataFrame,
    bridges: pd.DataFrame,
    summary: pd.Series,
    membership: pd.DataFrame,
    output_path: Path,
) -> None:
    band_positions = get_band_positions(supporting)
    bridge_ids = set(bridges["member_id"].astype(int).tolist())
    member_positions = assign_member_positions(membership, bridge_ids, band_positions)

    band_lookup = supporting.set_index("band_id").to_dict("index")
    bridge_name_lookup = bridges.set_index("member_id")["member_name"].to_dict()
    member_name_lookup = membership.drop_duplicates(subset=["member_id"]).set_index("member_id")["member_name"].to_dict()

    fig, ax = plt.subplots(figsize=(12.5, 8.5))

    for row in membership.drop_duplicates(subset=["band_id", "member_id"]).itertuples(index=False):
        band_xy = band_positions[str(row.band_name)]
        member_xy = member_positions[int(row.member_id)]
        ax.plot(
            [band_xy[0], member_xy[0]],
            [band_xy[1], member_xy[1]],
            color=EDGE_COLOR,
            linewidth=1.3,
            alpha=0.75,
            zorder=1,
        )

    non_bridge_members = membership.loc[
        ~membership["member_id"].isin(bridge_ids)
    ].drop_duplicates(subset=["member_id"])
    bridge_members = membership.loc[
        membership["member_id"].isin(bridge_ids)
    ].drop_duplicates(subset=["member_id"])

    if not non_bridge_members.empty:
        ax.scatter(
            [member_positions[int(member_id)][0] for member_id in non_bridge_members["member_id"]],
            [member_positions[int(member_id)][1] for member_id in non_bridge_members["member_id"]],
            s=180,
            color=SINGLE_MUSICIAN_COLOR,
            edgecolor="#7d8590",
            linewidth=0.8,
            zorder=2,
        )

    if not bridge_members.empty:
        ax.scatter(
            [member_positions[int(member_id)][0] for member_id in bridge_members["member_id"]],
            [member_positions[int(member_id)][1] for member_id in bridge_members["member_id"]],
            s=360,
            color=BRIDGE_MUSICIAN_COLOR,
            edgecolor="#6b4f1d",
            linewidth=1.0,
            zorder=3,
        )

    target_bands = supporting.loc[supporting["in_target_genre_i"].eq(1)].copy()
    support_bands = supporting.loc[supporting["in_target_genre_i"].eq(0)].copy()

    if not target_bands.empty:
        ax.scatter(
            [band_positions[str(band_name)][0] for band_name in target_bands["band_name"]],
            [band_positions[str(band_name)][1] for band_name in target_bands["band_name"]],
            s=[1500 + 280 * int(value) for value in target_bands["community_degree"]],
            color=TARGET_BAND_COLOR,
            edgecolor="#114b5f",
            linewidth=1.5,
            zorder=4,
        )
    if not support_bands.empty:
        ax.scatter(
            [band_positions[str(band_name)][0] for band_name in support_bands["band_name"]],
            [band_positions[str(band_name)][1] for band_name in support_bands["band_name"]],
            s=[1500 + 280 * int(value) for value in support_bands["community_degree"]],
            color=SUPPORT_BAND_COLOR,
            edgecolor="#7a2e2e",
            linewidth=1.5,
            zorder=4,
        )

    for row in supporting.itertuples(index=False):
        x_value, y_value = band_positions[str(row.band_name)]
        formed_label = f"{int(row.formed_year)}" if pd.notna(row.formed_year) else "?"
        ax.text(
            x_value,
            y_value - 0.48,
            f"{row.band_name}\n({formed_label})",
            ha="center",
            va="top",
            fontsize=10,
            fontweight="bold",
            zorder=5,
        )

    for member_id in bridge_members["member_id"]:
        x_value, y_value = member_positions[int(member_id)]
        label = bridge_name_lookup.get(int(member_id), member_name_lookup.get(int(member_id), str(member_id)))
        ax.text(
            x_value,
            y_value + 0.22,
            label,
            ha="center",
            va="bottom",
            fontsize=8.7,
            zorder=5,
        )

    city_name = str(summary["city"])
    genre_family = str(summary["genre_family"]).replace("_", " ")
    detection_year = int(summary["detection_year"])
    title = f"{city_name} {genre_family} already formed a dense local worker-project cluster in {detection_year}"
    subtitle = (
        "Band nodes are projects; musician nodes are workers active in the five-band supporting community. "
        "Highlighted worker nodes are multi-band connectors."
    )
    ax.set_title(title, fontsize=15, fontweight="bold", loc="left", pad=18)
    fig.text(0.126, 0.91, subtitle, ha="left", fontsize=10, color="#4f4f4f")

    stats_text = (
        f"Detection year: {detection_year}\n"
        f"Lead: {int(summary['lead_years'])} years\n"
        f"Supporting bands: {int(summary['community_size'])}\n"
        f"Target-genre bands: {int(summary['genre_bands_in_supporting_community'])}\n"
        f"Bridge musicians: {int(summary['bridge_musician_ct'])}\n"
        f"City active bands: {int(summary['detection_city_active_bands'])}"
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

    legend_items = [
        Line2D([0], [0], marker="o", color="none", markerfacecolor=TARGET_BAND_COLOR, markeredgecolor="#114b5f", markersize=12, label="Target-genre band"),
        Line2D([0], [0], marker="o", color="none", markerfacecolor=SUPPORT_BAND_COLOR, markeredgecolor="#7a2e2e", markersize=12, label="Linked support band"),
        Line2D([0], [0], marker="o", color="none", markerfacecolor=BRIDGE_MUSICIAN_COLOR, markeredgecolor="#6b4f1d", markersize=10, label="Multi-band connector"),
        Line2D([0], [0], marker="o", color="none", markerfacecolor=SINGLE_MUSICIAN_COLOR, markeredgecolor="#7d8590", markersize=9, label="Single-band member"),
    ]
    ax.legend(handles=legend_items, loc="lower left", frameon=False, fontsize=9)

    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_aspect("equal")
    ax.set_xlim(-4.0, 4.0)
    ax.set_ylim(-3.7, 3.7)
    for spine in ax.spines.values():
        spine.set_visible(False)

    fig.tight_layout(rect=(0.0, 0.0, 1.0, 0.92))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=240)
    plt.close(fig)


def write_summary(
    supporting: pd.DataFrame,
    bridges: pd.DataFrame,
    summary: pd.Series,
    membership: pd.DataFrame,
    figure_path: Path,
    summary_path: Path,
) -> None:
    central_band = supporting.sort_values(["community_degree", "band_name"], ascending=[False, True]).iloc[0]
    bridge_lookup = bridges.sort_values(["n_community_bands", "member_name"], ascending=[False, True]).copy()
    bridge_names = bridge_lookup["member_name"].tolist()
    lines = [
        "# Scene case-study network figure",
        "",
        f"- Figure: `figures/{figure_path.name}`",
        f"- Case: `{summary['city_country']}` / `{summary['genre_family']}`",
        f"- Detection year: `{int(summary['detection_year'])}`",
        f"- Lead: `{int(summary['lead_years'])}` years",
        f"- Supporting bands shown: `{int(summary['community_size'])}`",
        f"- Active worker nodes shown: `{membership['member_id'].nunique()}`",
        f"- Multi-band connectors highlighted: `{int(summary['bridge_musician_ct'])}`",
        "",
        "## Why this case works",
        "",
        f"- `{central_band['band_name']}` is the central local project in the reconstructed community, with degree `{int(central_band['community_degree'])}`.",
        f"- The local cluster already contains `{int(summary['genre_bands_in_supporting_community'])}` target-genre bands out of `{int(summary['community_size'])}` supporting bands.",
        f"- The worker-project graph highlights repeated collaboration rather than only band counts: the top visible connectors are `{', '.join(bridge_names[:4])}`.",
        "- This is the right paper-facing visual because it shows localized labor pooling and recombination directly.",
    ]
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    configure_style()
    args = parse_args()

    supporting, bridges, summary = load_case(args.city_country, args.genre_family)
    detection_year = int(summary["detection_year"])

    raw_edges = load_relevant_edges(set(supporting["band_id"].tolist()))
    active_edges = infer_active_edges(raw_edges, detection_year)
    active_edges = supplement_bridge_edges(active_edges, bridges, supporting)
    membership = build_membership(active_edges)

    city_slug = slugify(str(summary["city"]))
    genre_slug = slugify(str(summary["genre_family"]))
    figure_path = FIGURE_DIR / f"{city_slug}_{genre_slug}_case_network.png"
    summary_path = SCENE_DIR / f"{city_slug}_{genre_slug}_case_network_summary.md"

    draw_case_figure(supporting, bridges, summary, membership, figure_path)
    write_summary(supporting, bridges, summary, membership, figure_path, summary_path)

    print(f"Wrote {figure_path}")
    print(f"Wrote {summary_path}")


if __name__ == "__main__":
    main()
