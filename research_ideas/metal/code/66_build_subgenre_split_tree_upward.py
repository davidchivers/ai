from __future__ import annotations

import importlib.util
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BASE_SCRIPT = PROJECT_ROOT / "code" / "64_build_subgenre_split_tree.py"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "subgenre_split_tree_upward.png"
SVG_PATH = OUTPUT_DIR / "subgenre_split_tree_upward.svg"
SUMMARY_PATH = OUTPUT_DIR / "subgenre_split_tree_upward_summary.md"

LEGEND_ROOTS = [
    "doom metal",
    "power metal",
    "progressive metal",
    "thrash metal",
    "death metal",
    "black metal",
    "metalcore",
]


def load_base_module():
    spec = importlib.util.spec_from_file_location("split_tree_base", BASE_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def build_upward_positions(
    stats: pd.DataFrame,
    parents: dict[str, str | None],
    root_order: dict[str, int],
    base,
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
            root_order.get(base.get_display_root(token, parents), 999),
            int(first_year_lookup[token]),
            -int(count_lookup[token]),
            token,
        )

    for parent in list(children.keys()):
        children[parent] = sorted(children[parent], key=sort_key)

    y_map: dict[str, float] = {base.ROOT_TAG: 0.0}
    cursor = 0.0

    def assign(node: str) -> None:
        nonlocal cursor
        for child in children.get(node, []):
            cursor += 1.0
            y_map[child] = cursor
            assign(child)

    assign(base.ROOT_TAG)
    x_map = {token: float(year) for token, year in zip(stats["token"], stats["first_year"])}
    return children, x_map, y_map


def upward_bend(token: str, parents: dict[str, str | None]) -> float:
    if token == "heavy metal":
        return 0.18
    depth = 0
    node = token
    while parents.get(node) is not None:
        node = parents[node]  # type: ignore[index]
        depth += 1
    if depth == 1:
        return 0.15
    if depth == 2:
        return 0.12
    return 0.09


def add_color_key(ax, base, root_palette: dict[str, str]) -> None:
    x0 = 0.06
    y0 = 0.93
    dy = 0.043
    ax.text(
        x0,
        y0 + 0.035,
        "Selected branch colors",
        transform=ax.transAxes,
        ha="left",
        va="bottom",
        fontsize=10.5,
        fontweight="bold",
        fontfamily="serif",
        color="#222222",
    )
    for idx, token in enumerate(LEGEND_ROOTS):
        color = root_palette.get(token)
        if color is None:
            continue
        y = y0 - idx * dy
        ax.plot(
            [x0, x0 + 0.045],
            [y, y],
            transform=ax.transAxes,
            color=color,
            lw=2.4,
            alpha=0.95,
            solid_capstyle="round",
            clip_on=False,
        )
        ax.text(
            x0 + 0.055,
            y,
            token,
            transform=ax.transAxes,
            ha="left",
            va="center",
            fontsize=9.8,
            fontfamily="serif",
            color="#222222",
            bbox={
                "boxstyle": "round,pad=0.16",
                "facecolor": "white",
                "edgecolor": "none",
                "alpha": 0.88,
            },
        )


def write_summary(stats: pd.DataFrame, parents: dict[str, str | None], base) -> None:
    stats_lookup = stats.set_index("token").to_dict("index")
    direct_children = [token for token, parent in parents.items() if parent == base.ROOT_TAG and token != base.ROOT_TAG]
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Upward subgenre split tree summary\n\n")
        handle.write(
            "This variant keeps the same lexical parent logic as `subgenre_split_tree`, but forces a "
            "one-sided upward layout: `heavy metal` sits at the bottom and all descendants rise upward. "
            "Within each sibling group, earlier and larger branches are placed closer to the parent, "
            "while later or smaller offshoots appear farther above.\n\n"
        )
        handle.write("## Top-level branches from the root\n\n")
        for token in direct_children[:20]:
            row = stats_lookup[token]
            handle.write(f"- `{token}`: first year `{row['first_year']}`, bands `{row['band_count']}`\n")


def plot(stats: pd.DataFrame, parents: dict[str, str | None], base) -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.serif": ["STIX Two Text", "STIXGeneral", "CMU Serif", "Computer Modern Roman", "DejaVu Serif"],
            "mathtext.fontset": "cm",
        }
    )
    stats_lookup = stats.set_index("token").to_dict("index")
    root_order = base.build_root_order(stats, parents)
    root_palette = base.build_root_palette(root_order)
    children, x_map, y_map = build_upward_positions(stats, parents, root_order, base)
    x_max = max(x_map.values()) + 1.0

    fig_height = max(9.5, len(stats) * 0.05)
    fig, ax = plt.subplots(figsize=(14.5, fig_height))

    for token in stats["token"]:
        color, lw, alpha = base.line_style(token, parents, stats_lookup, root_palette)
        x0 = x_map[token]
        y = y_map[token]
        base.curve_run(ax, x0, x_max, y, upward_bend(token, parents), color=color, lw=lw, alpha=alpha)
        parent = parents.get(token)
        if parent is not None:
            base.curve_split(
                ax,
                x_map[parent],
                x0,
                y_map[parent],
                y,
                color=color,
                lw=lw,
                alpha=alpha,
            )

    add_color_key(ax, base, root_palette)
    ax.text(
        x_map[base.ROOT_TAG] + 0.45,
        y_map[base.ROOT_TAG] + 0.38,
        "heavy metal",
        ha="left",
        va="bottom",
        fontsize=10.5,
        fontfamily="serif",
        fontweight="bold",
        color="#8f2d56",
        bbox={
            "boxstyle": "round,pad=0.16",
            "facecolor": "white",
            "edgecolor": "none",
            "alpha": 0.9,
        },
    )

    ax.set_title(
        "Branching Tree of Metal Subgenres",
        fontsize=16,
        weight="bold",
        fontfamily="serif",
    )
    ax.set_xlabel(
        "Year Subgenre First Observed",
        fontfamily="serif",
    )
    ax.set_xlim(min(x_map.values()) - 1.0, x_max)
    ax.set_ylim(-2.0, max(y_map.values()) + 3.0)
    ax.set_yticks([])
    ax.grid(axis="x", alpha=0.14, linewidth=0.6)
    for spine in ["left", "right", "top"]:
        ax.spines[spine].set_visible(False)

    note = (
        "Illustrative subgenre tree rather than a literal genealogy. Vertical position is layout only:\n"
        "the root sits at the bottom, and later or smaller offshoots are placed farther above within each subtree."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9, fontfamily="serif")
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=240)
    fig.savefig(SVG_PATH)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    base = load_base_module()
    stats = base.load_tag_stats()
    parents = base.infer_parents(stats)
    plot(stats, parents, base)
    write_summary(stats, parents, base)
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SVG_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
