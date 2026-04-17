from __future__ import annotations

import colorsys
import importlib.util
import re
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.path import Path as MplPath
from matplotlib.patches import PathPatch
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
ANALYZE_PATH = PROJECT_ROOT / "code" / "05_analyze_genre_trends.py"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "subgenre_split_tree.png"
SVG_PATH = OUTPUT_DIR / "subgenre_split_tree.svg"
SUMMARY_PATH = OUTPUT_DIR / "subgenre_split_tree_summary.md"

MIN_COUNT = 10
ROOT_TAG = "heavy metal"
GENERIC_ROOTS = {"metal", "various metal"}
GENERIC_COLOR = "#6f6f6f"

MANUAL_ROOT_COLORS = {
    "black metal": "#3f5873",
    "death metal": "#b35a52",
    "doom metal": "#a3833d",
    "folk metal": "#5f7f49",
    "gothic metal": "#7a617c",
    "grindcore": "#8a6646",
    "industrial metal": "#5b6b79",
    "metalcore": "#8a5976",
    "power metal": "#c08a43",
    "progressive metal": "#4b7f78",
    "speed metal": "#9a5560",
    "symphonic metal": "#6f6aa8",
    "thrash metal": "#8f4f67",
}

RULE_ROOT_COLORS = [
    ("black", "#3f5873"),
    ("death", "#b35a52"),
    ("doom", "#a3833d"),
    ("folk", "#5f7f49"),
    ("gothic", "#7a617c"),
    ("grind", "#8a6646"),
    ("industrial", "#5b6b79"),
    ("metalcore", "#8a5976"),
    ("power", "#c08a43"),
    ("progressive", "#4b7f78"),
    ("symphonic", "#6f6aa8"),
    ("thrash", "#8f4f67"),
    ("speed", "#9a5560"),
    ("nwobhm", "#9a7a56"),
    ("heavy metal", "#a86f4e"),
]

SPACE_PATTERN = re.compile(r"\s+")


def load_genre_module():
    spec = importlib.util.spec_from_file_location("metal_genre_trends", ANALYZE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def load_tag_stats() -> pd.DataFrame:
    genre_module = load_genre_module()
    bands = pd.read_csv(INPUT_PATH, usecols=["genre_raw", "entry_year"], dtype={"genre_raw": "string"})
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce")
    bands = bands.loc[bands["entry_year"].notna() & bands["genre_raw"].notna()].copy()
    bands["entry_year"] = bands["entry_year"].astype(int)

    token_cache, _ = genre_module.build_genre_cache(bands["genre_raw"])

    records: list[dict[str, object]] = []
    for row in bands.itertuples(index=False):
        for token in token_cache.get(str(row.genre_raw), []):
            records.append({"token": token, "entry_year": int(row.entry_year)})

    panel = pd.DataFrame(records)
    stats = (
        panel.groupby("token", as_index=False)
        .agg(first_year=("entry_year", "min"), band_count=("entry_year", "size"))
        .sort_values(["first_year", "band_count", "token"], ascending=[True, False, True])
        .reset_index(drop=True)
    )
    stats = stats.loc[stats["token"].str.contains("metal", case=False, na=False)].copy()
    stats = stats.loc[(stats["band_count"] >= MIN_COUNT) | stats["token"].eq(ROOT_TAG)].copy()
    return stats


def normalize_token(token: str) -> str:
    text = token.lower().replace("-", " ")
    text = SPACE_PATTERN.sub(" ", text).strip()
    return text


def infer_parents(stats: pd.DataFrame) -> dict[str, str | None]:
    normalized_lookup = {normalize_token(token): token for token in stats["token"]}
    year_lookup = dict(zip(stats["token"], stats["first_year"]))

    parents: dict[str, str | None] = {ROOT_TAG: None}
    for token in stats.sort_values(["first_year", "band_count", "token"]).loc[lambda df: ~df["token"].eq(ROOT_TAG), "token"]:
        norm = normalize_token(token)
        words = norm.split()
        parent: str | None = None
        for start_idx in range(1, len(words)):
            candidate_norm = " ".join(words[start_idx:])
            candidate = normalized_lookup.get(candidate_norm)
            if candidate is None or candidate == token:
                continue
            if int(year_lookup[candidate]) <= int(year_lookup[token]):
                parent = candidate
                break
        parents[token] = parent or ROOT_TAG
    return parents


def get_display_root(token: str, parents: dict[str, str | None]) -> str:
    node = token
    trail = [node]
    while parents.get(node) not in (None, ROOT_TAG):
        node = parents[node]  # type: ignore[index]
        trail.append(node)
    if parents.get(node) == ROOT_TAG and node in GENERIC_ROOTS and len(trail) >= 2:
        return trail[-2]
    return node


def centered_order(tokens: list[str], rank_key) -> list[str]:
    ranked = sorted(tokens, key=rank_key)
    n = len(ranked)
    if n <= 2:
        return ranked

    positions = list(range(n))
    if n % 2 == 1:
        mid = n // 2
        slot_order = [mid]
        for step in range(1, mid + 1):
            slot_order.extend([mid - step, mid + step])
    else:
        left = n // 2 - 1
        right = n // 2
        slot_order = [left, right]
        for step in range(1, left + 1):
            slot_order.extend([left - step, right + step])

    arranged = [None] * n
    for token, slot in zip(ranked, slot_order):
        arranged[slot] = token
    return [token for token in arranged if token is not None]


def curve_split(
    ax,
    x_parent: float,
    x_child: float,
    y0: float,
    y1: float,
    color: str,
    lw: float,
    alpha: float,
) -> None:
    spread = 0.9
    start_x = max(x_parent, x_child - spread)
    gap = max(x_child - start_x, 0.0)
    verts = [
        (start_x, y0),
        (start_x + gap * 0.35, y0),
        (start_x + gap * 0.78, y1),
        (x_child, y1),
    ]
    codes = [MplPath.MOVETO, MplPath.CURVE4, MplPath.CURVE4, MplPath.CURVE4]
    patch = PathPatch(
        MplPath(verts, codes),
        facecolor="none",
        edgecolor=color,
        lw=lw,
        alpha=alpha,
        capstyle="round",
        joinstyle="round",
    )
    ax.add_patch(patch)


def curve_run(ax, x0: float, x1: float, y: float, bend: float, color: str, lw: float, alpha: float) -> None:
    span = x1 - x0
    verts = [
        (x0, y),
        (x0 + span * 0.28, y + bend),
        (x0 + span * 0.72, y + bend),
        (x1, y),
    ]
    codes = [MplPath.MOVETO, MplPath.CURVE4, MplPath.CURVE4, MplPath.CURVE4]
    patch = PathPatch(
        MplPath(verts, codes),
        facecolor="none",
        edgecolor=color,
        lw=lw,
        alpha=alpha,
        capstyle="round",
        joinstyle="round",
    )
    ax.add_patch(patch)


def build_root_order(stats: pd.DataFrame, parents: dict[str, str | None]) -> dict[str, int]:
    stats_lookup = stats.set_index("token").to_dict("index")
    roots = sorted(
        {get_display_root(token, parents) for token in stats["token"] if token != ROOT_TAG},
        key=lambda token: (
            int(stats_lookup[token]["first_year"]),
            -int(stats_lookup[token]["band_count"]),
            token,
        ),
    )
    return {token: idx for idx, token in enumerate(roots)}


def build_root_palette(root_order: dict[str, int]) -> dict[str, str]:
    n = max(len(root_order), 1)
    palette: dict[str, str] = {}
    for token, idx in root_order.items():
        if token in GENERIC_ROOTS:
            palette[token] = GENERIC_COLOR
            continue
        if token in MANUAL_ROOT_COLORS:
            palette[token] = MANUAL_ROOT_COLORS[token]
            continue
        for needle, color in RULE_ROOT_COLORS:
            if needle in token:
                palette[token] = color
                break
        if token in palette:
            continue
        hue = idx / n
        rgb = colorsys.hls_to_rgb(hue, 0.49, 0.38)
        palette[token] = "#{:02x}{:02x}{:02x}".format(
            int(rgb[0] * 255),
            int(rgb[1] * 255),
            int(rgb[2] * 255),
        )
    return palette


def build_tree_positions(
    stats: pd.DataFrame,
    parents: dict[str, str | None],
    root_order: dict[str, int],
) -> tuple[dict[str, list[str]], dict[str, float], dict[str, float]]:
    children: dict[str, list[str]] = defaultdict(list)
    first_year_lookup = dict(zip(stats["token"], stats["first_year"]))
    count_lookup = dict(zip(stats["token"], stats["band_count"]))

    for child, parent in parents.items():
        if parent is None:
            continue
        children[parent].append(child)

    def sort_key(token: str) -> tuple[int, int, int, str]:
        return (
            root_order.get(get_display_root(token, parents), 999),
            int(first_year_lookup[token]),
            -int(count_lookup[token]),
            token,
        )

    for parent in list(children.keys()):
        children[parent] = centered_order(children[parent], sort_key)

    y_map: dict[str, float] = {}
    cursor = 0.0

    def assign(node: str) -> float:
        nonlocal cursor
        node_children = children.get(node, [])
        if not node_children:
            y_map[node] = cursor
            cursor += 1.0
            return y_map[node]
        child_ys = [assign(child) for child in node_children]
        y_map[node] = (child_ys[0] + child_ys[-1]) / 2.0
        return y_map[node]

    assign(ROOT_TAG)
    x_map = {token: float(year) for token, year in zip(stats["token"], stats["first_year"])}
    return children, x_map, y_map


def line_style(
    token: str,
    parents: dict[str, str | None],
    stats_lookup: dict[str, dict[str, int]],
    root_palette: dict[str, str],
) -> tuple[str, float, float]:
    if token == ROOT_TAG:
        return "#8f2d56", 0.82, 0.98
    color = root_palette[get_display_root(token, parents)]
    depth = 0
    node = token
    while parents.get(node) is not None:
        node = parents[node]  # type: ignore[index]
        depth += 1
    if depth == 1:
        return color, 0.78, 0.93
    if depth == 2:
        return color, 0.74, 0.93
    return color, 0.70, 0.93


def line_bend(token: str, parents: dict[str, str | None], y: float) -> float:
    depth = 0
    node = token
    while parents.get(node) is not None:
        node = parents[node]  # type: ignore[index]
        depth += 1
    if token == ROOT_TAG:
        return 0.14
    direction = 1.0 if y >= 0 else -1.0
    if depth == 1:
        return direction * 0.20
    if depth == 2:
        return direction * 0.14
    return direction * 0.08


def write_summary(stats: pd.DataFrame, parents: dict[str, str | None]) -> None:
    stats_lookup = stats.set_index("token").to_dict("index")
    direct_children = [token for token, parent in parents.items() if parent == ROOT_TAG and token != ROOT_TAG]
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Subgenre split tree summary\n\n")
        handle.write(
            f"This figure drops the ribbon logic and instead draws a thin branching split tree. "
            f"It keeps one `heavy metal` trunk and then lets later parsed metal labels split away over time. "
            f"The plot includes `{len(stats)}` metal-related genre descriptors with at least `{MIN_COUNT}` bands.\n\n"
        )
        handle.write("## Top-level branches from the root\n\n")
        for token in direct_children[:20]:
            row = stats_lookup[token]
            handle.write(f"- `{token}`: first year `{row['first_year']}`, bands `{row['band_count']}`\n")


def plot(stats: pd.DataFrame, parents: dict[str, str | None]) -> None:
    stats_lookup = stats.set_index("token").to_dict("index")
    root_order = build_root_order(stats, parents)
    root_palette = build_root_palette(root_order)
    children, x_map, y_map = build_tree_positions(stats, parents, root_order)
    x_max = max(x_map.values()) + 1.0
    n_leaves = sum(1 for token in stats["token"] if token not in children)

    fig_height = max(9.5, n_leaves * 0.035)
    fig, ax = plt.subplots(figsize=(14.5, fig_height))

    for token in stats["token"]:
        color, lw, alpha = line_style(token, parents, stats_lookup, root_palette)
        x0 = x_map[token]
        y = y_map[token]
        bend = line_bend(token, parents, y)
        curve_run(ax, x0, x_max, y, bend, color=color, lw=lw, alpha=alpha)
        parent = parents.get(token)
        if parent is not None:
            curve_split(
                ax,
                x_map[parent],
                x0,
                y_map[parent],
                y,
                color=color,
                lw=lw,
                alpha=alpha,
            )

    ax.set_title("Branching of metal subgenre labels over time", fontsize=15, weight="bold")
    ax.set_xlabel("First appearance year in the data")
    ax.set_xlim(min(x_map.values()) - 1.0, x_max)
    ax.set_ylim(-3.0, max(y_map.values()) + 3.0)
    ax.set_yticks([])
    ax.grid(axis="x", alpha=0.14, linewidth=0.6)
    for spine in ["left", "right", "top"]:
        ax.spines[spine].set_visible(False)

    note = (
        f"Each thin line is a parsed metal genre descriptor with at least {MIN_COUNT} bands. "
        "Each line inherits the color of its first real split after heavy metal, skipping generic labels like `metal`."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=240)
    fig.savefig(SVG_PATH)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    stats = load_tag_stats()
    parents = infer_parents(stats)
    plot(stats, parents)
    write_summary(stats, parents)
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SVG_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
