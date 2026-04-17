from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.path import Path as MplPath
from matplotlib.patches import PathPatch


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "rooted_subgenre_timeline.png"
SVG_PATH = OUTPUT_DIR / "rooted_subgenre_timeline.svg"
SUMMARY_PATH = OUTPUT_DIR / "rooted_subgenre_timeline_summary.md"


ROOT = {"label": "Heavy metal", "year": 1962, "y": 0.0, "color": "#4d4d4d"}

FAMILIES = [
    {"key": "doom", "label": "Doom metal", "year": 1969, "y": -1.5, "color": "#ffa600"},
    {"key": "thrash", "label": "Thrash metal", "year": 1976, "y": 1.6, "color": "#bc5090"},
    {"key": "death", "label": "Death metal", "year": 1977, "y": 3.0, "color": "#ff6361"},
    {"key": "black", "label": "Black metal", "year": 1977, "y": -3.0, "color": "#2f4b7c"},
]

SUBGENRES = {
    "doom": [
        {"label": "Funeral doom", "year": 1988, "y": -2.4, "major": True},
        {"label": "Atmospheric doom", "year": 1988, "y": -0.8, "major": False},
        {"label": "Melodic doom", "year": 1989, "y": -1.0, "major": False},
    ],
    "thrash": [
        {"label": "Progressive thrash", "year": 1978, "y": 2.2, "major": False},
        {"label": "Technical thrash", "year": 1982, "y": 1.0, "major": False},
        {"label": "Melodic thrash", "year": 1987, "y": 2.8, "major": False},
    ],
    "death": [
        {"label": "Melodic death", "year": 1984, "y": 3.9, "major": True},
        {"label": "Technical death", "year": 1984, "y": 2.2, "major": True},
        {"label": "Progressive death", "year": 1984, "y": 4.8, "major": False},
        {"label": "Brutal death", "year": 1987, "y": 1.3, "major": True},
    ],
    "black": [
        {"label": "Melodic black", "year": 1985, "y": -2.1, "major": False},
        {"label": "Symphonic black", "year": 1988, "y": -3.9, "major": True},
        {"label": "Atmospheric black", "year": 1990, "y": -4.8, "major": True},
        {"label": "Depressive black", "year": 1993, "y": -5.6, "major": True},
    ],
}


def curved_branch(ax, x0: float, y0: float, x1: float, y1: float, color: str, lw: float, alpha: float = 1.0) -> None:
    bend = max((x1 - x0) * 0.35, 1.4)
    verts = [
        (x0, y0),
        (x0 + bend, y0),
        (x1 - bend, y1),
        (x1, y1),
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


def write_summary() -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Rooted subgenre timeline summary\n\n")
        handle.write(
            "This is an illustrative rooted timeline rather than a literal causal tree. It keeps the "
            "timeline aesthetic but makes `heavy metal` the visual trunk, with later broad families "
            "and selected subgenres branching away from it.\n\n"
        )
        handle.write("## Broad family branches\n\n")
        for family in FAMILIES:
            handle.write(f"- `{family['label']}`: `{family['year']}`\n")
        handle.write("\n## Selected later subgenres\n\n")
        for family in FAMILIES:
            for node in SUBGENRES.get(family["key"], []):
                handle.write(f"- `{node['label']}`: `{node['year']}`\n")


def plot() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(13.5, 8.5))

    x_min = 1960
    x_max = 2004

    # Root trunk.
    ax.plot(
        [ROOT["year"], x_max],
        [ROOT["y"], ROOT["y"]],
        color=ROOT["color"],
        lw=5.0,
        solid_capstyle="round",
        alpha=0.95,
    )

    # Family branches from the root.
    for family in FAMILIES:
        curved_branch(
            ax,
            ROOT["year"] + 0.2,
            ROOT["y"],
            family["year"],
            family["y"],
            family["color"],
            lw=4.2,
            alpha=0.95,
        )
        ax.plot(
            [family["year"], x_max],
            [family["y"], family["y"]],
            color=family["color"],
            lw=3.2,
            solid_capstyle="round",
            alpha=0.95,
        )
        ax.scatter([family["year"]], [family["y"]], s=34, color=family["color"], zorder=4)

        for node in SUBGENRES.get(family["key"], []):
            curved_branch(
                ax,
                family["year"] + 0.2,
                family["y"],
                node["year"],
                node["y"],
                family["color"],
                lw=2.2 if node["major"] else 1.4,
                alpha=0.72 if node["major"] else 0.38,
            )
            ax.plot(
                [node["year"], x_max],
                [node["y"], node["y"]],
                color=family["color"],
                lw=1.9 if node["major"] else 1.0,
                solid_capstyle="round",
                alpha=0.72 if node["major"] else 0.32,
            )
            ax.scatter(
                [node["year"]],
                [node["y"]],
                s=18 if node["major"] else 10,
                color=family["color"],
                zorder=4,
                alpha=0.95 if node["major"] else 0.65,
            )

    # Labels: root + family trunks + major subgenres only.
    ax.text(
        ROOT["year"] - 0.6,
        ROOT["y"],
        f"{ROOT['label']} ({ROOT['year']})",
        ha="right",
        va="center",
        fontsize=12,
        fontweight="bold",
        color=ROOT["color"],
    )
    for family in FAMILIES:
        ax.text(
            family["year"] + 0.7,
            family["y"] + (0.16 if family["y"] >= 0 else -0.16),
            f"{family['label']} ({family['year']})",
            ha="left",
            va="center",
            fontsize=11,
            fontweight="bold",
            color=family["color"],
        )
        for node in SUBGENRES.get(family["key"], []):
            if not node["major"]:
                continue
            ax.text(
                node["year"] + 0.6,
                node["y"] + (0.12 if node["y"] >= family["y"] else -0.12),
                f"{node['label']} ({node['year']})",
                ha="left",
                va="center",
                fontsize=10,
                color=family["color"],
            )

    ax.set_title("Illustrative timeline of metal subgenre branching", fontsize=16, weight="bold")
    ax.set_xlabel("First appearance year in the data")
    ax.set_xlim(x_min, x_max)
    ax.set_ylim(-6.4, 5.6)
    ax.set_yticks([])
    ax.grid(axis="x", alpha=0.20, linewidth=0.6)
    for spine in ["left", "right", "top"]:
        ax.spines[spine].set_visible(False)

    note = (
        "Illustrative timeline, not a literal causal genealogy. The aim is to show later differentiation\n"
        "while keeping a single rooted trunk rather than separate equal families."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=220)
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
