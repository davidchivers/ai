from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.path import Path as MplPath
from matplotlib.patches import PathPatch
import matplotlib.patheffects as pe


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "rooted_subgenre_alluvial.png"
SVG_PATH = OUTPUT_DIR / "rooted_subgenre_alluvial.svg"
SUMMARY_PATH = OUTPUT_DIR / "rooted_subgenre_alluvial_summary.md"


ROOT = {
    "label": "Heavy metal",
    "year": 1962,
    "y": 0.0,
    "color": "#545454",
    "width": 0.58,
}

FAMILIES = [
    {"key": "doom", "label": "Doom metal", "year": 1969, "y": -1.7, "color": "#f2a541", "width": 0.30},
    {"key": "thrash", "label": "Thrash metal", "year": 1976, "y": 1.7, "color": "#c44569", "width": 0.36},
    {"key": "death", "label": "Death metal", "year": 1977, "y": 3.15, "color": "#ff6b5a", "width": 0.44},
    {"key": "black", "label": "Black metal", "year": 1977, "y": -3.25, "color": "#2e5b88", "width": 0.41},
]

SUBGENRES = {
    "doom": [
        {"label": "Funeral doom metal", "year": 1988, "y": -2.55, "major": True, "width": 0.13},
        {"label": "Atmospheric doom metal", "year": 1988, "y": -0.90, "major": False, "width": 0.09},
        {"label": "Melodic doom metal", "year": 1989, "y": -1.15, "major": False, "width": 0.08},
    ],
    "thrash": [
        {"label": "Progressive thrash metal", "year": 1978, "y": 2.45, "major": False, "width": 0.09},
        {"label": "Technical thrash metal", "year": 1982, "y": 1.02, "major": False, "width": 0.08},
        {"label": "Melodic thrash metal", "year": 1987, "y": 3.05, "major": False, "width": 0.09},
    ],
    "death": [
        {"label": "Melodic death metal", "year": 1984, "y": 4.15, "major": True, "width": 0.17},
        {"label": "Technical death metal", "year": 1984, "y": 2.10, "major": True, "width": 0.13},
        {"label": "Progressive death metal", "year": 1984, "y": 5.05, "major": False, "width": 0.09},
        {"label": "Brutal death metal", "year": 1987, "y": 1.20, "major": True, "width": 0.14},
    ],
    "black": [
        {"label": "Melodic black metal", "year": 1985, "y": -2.20, "major": False, "width": 0.09},
        {"label": "Symphonic black metal", "year": 1988, "y": -4.15, "major": True, "width": 0.13},
        {"label": "Atmospheric black metal", "year": 1990, "y": -5.05, "major": True, "width": 0.14},
        {"label": "Depressive black metal", "year": 1993, "y": -5.95, "major": True, "width": 0.12},
    ],
}


def ribbon_between(
    ax,
    x0: float,
    y0: float,
    w0: float,
    x1: float,
    y1: float,
    w1: float,
    color: str,
    alpha: float,
) -> None:
    bend = max((x1 - x0) * 0.34, 1.4)
    top_verts = [
        (x0, y0 + w0 / 2),
        (x0 + bend, y0 + w0 / 2),
        (x1 - bend, y1 + w1 / 2),
        (x1, y1 + w1 / 2),
    ]
    bottom_verts = [
        (x1, y1 - w1 / 2),
        (x1 - bend, y1 - w1 / 2),
        (x0 + bend, y0 - w0 / 2),
        (x0, y0 - w0 / 2),
    ]
    verts = top_verts + bottom_verts + [(x0, y0 + w0 / 2)]
    codes = [
        MplPath.MOVETO,
        MplPath.CURVE4,
        MplPath.CURVE4,
        MplPath.CURVE4,
        MplPath.LINETO,
        MplPath.CURVE4,
        MplPath.CURVE4,
        MplPath.CURVE4,
        MplPath.CLOSEPOLY,
    ]
    patch = PathPatch(
        MplPath(verts, codes),
        facecolor=color,
        edgecolor="none",
        alpha=alpha,
    )
    ax.add_patch(patch)


def horizontal_ribbon(
    ax,
    x0: float,
    x1: float,
    y: float,
    width: float,
    color: str,
    alpha: float,
) -> None:
    patch = plt.Polygon(
        [
            (x0, y + width / 2),
            (x1, y + width / 2),
            (x1, y - width / 2),
            (x0, y - width / 2),
        ],
        closed=True,
        facecolor=color,
        edgecolor="none",
        alpha=alpha,
    )
    ax.add_patch(patch)


def write_summary() -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Rooted subgenre alluvial summary\n\n")
        handle.write(
            "This figure keeps the rooted timeline idea but draws the branches as ribbons rather than "
            "thin lines. The aim is to make the visual read more like an alluvial or subway-map hybrid: "
            "one `heavy metal` trunk, then broader family streams, then thinner later offshoots.\n\n"
        )
        handle.write("## Broad family branches\n\n")
        for family in FAMILIES:
            handle.write(f"- `{family['label']}`: `{family['year']}`\n")
        handle.write("\n## Highlighted later branches\n\n")
        for family in FAMILIES:
            for node in SUBGENRES.get(family["key"], []):
                if node["major"]:
                    handle.write(f"- `{node['label']}`: `{node['year']}`\n")


def plot() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(14.0, 8.8))

    x_min = 1960
    x_max = 2004

    horizontal_ribbon(
        ax,
        ROOT["year"],
        x_max,
        ROOT["y"],
        ROOT["width"],
        ROOT["color"],
        alpha=0.56,
    )

    for family in FAMILIES:
        ribbon_between(
            ax,
            ROOT["year"] + 0.15,
            ROOT["y"],
            ROOT["width"] * 0.92,
            family["year"],
            family["y"],
            family["width"],
            family["color"],
            alpha=0.42,
        )
        horizontal_ribbon(
            ax,
            family["year"],
            x_max,
            family["y"],
            family["width"],
            family["color"],
            alpha=0.50,
        )

        for node in SUBGENRES.get(family["key"], []):
            ribbon_between(
                ax,
                family["year"] + 0.15,
                family["y"],
                family["width"] * 0.92,
                node["year"],
                node["y"],
                node["width"],
                family["color"],
                alpha=0.24 if node["major"] else 0.14,
            )
            horizontal_ribbon(
                ax,
                node["year"],
                x_max,
                node["y"],
                node["width"],
                family["color"],
                alpha=0.24 if node["major"] else 0.12,
            )

    label_style = {
        "bbox": {
            "boxstyle": "round,pad=0.2",
            "facecolor": "white",
            "edgecolor": "none",
            "alpha": 0.88,
        },
        "path_effects": [pe.withStroke(linewidth=1.2, foreground="white")],
        "zorder": 5,
    }

    ax.text(
        ROOT["year"] - 0.55,
        ROOT["y"],
        f"{ROOT['label']} ({ROOT['year']})",
        ha="right",
        va="center",
        fontsize=13,
        fontweight="bold",
        color=ROOT["color"],
        **label_style,
    )

    for family in FAMILIES:
        ax.text(
            family["year"] + 0.8,
            family["y"] + (0.18 if family["y"] > 0 else -0.18),
            f"{family['label']} ({family['year']})",
            ha="left",
            va="center",
            fontsize=11.2,
            fontweight="bold",
            color=family["color"],
            **label_style,
        )
        for node in SUBGENRES[family["key"]]:
            if not node["major"]:
                continue
            ax.text(
                node["year"] + 0.7,
                node["y"] + (0.12 if node["y"] >= family["y"] else -0.12),
                f"{node['label']} ({node['year']})",
                ha="left",
                va="center",
                fontsize=10,
                color=family["color"],
                **label_style,
            )

    ax.set_title("Illustrative rooted timeline of metal subgenre branching", fontsize=16, weight="bold")
    ax.set_xlabel("First appearance year in the data")
    ax.set_xlim(x_min, x_max)
    ax.set_ylim(-6.6, 5.8)
    ax.set_yticks([])
    ax.grid(axis="x", alpha=0.16, linewidth=0.6)
    for spine in ["left", "right", "top"]:
        ax.spines[spine].set_visible(False)

    note = (
        "Illustrative timeline rather than a literal genealogy. The figure is meant to show how later metal\n"
        "subgenres branch out of earlier trunks, not to claim a unique historical parent for every label."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=240)
    fig.savefig(SVG_PATH)
    plt.close(fig)


def main() -> None:
    plot()
    write_summary()
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SVG_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
