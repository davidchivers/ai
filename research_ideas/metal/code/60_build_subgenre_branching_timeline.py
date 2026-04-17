from __future__ import annotations

import importlib.util
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
ANALYZE_PATH = PROJECT_ROOT / "code" / "05_analyze_genre_trends.py"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "subgenre_branching_timeline.png"
SVG_PATH = OUTPUT_DIR / "subgenre_branching_timeline.svg"
SUMMARY_PATH = OUTPUT_DIR / "subgenre_branching_timeline_summary.md"


REPRESENTATIVE_BRANCHES: list[tuple[str, list[tuple[str, float]]]] = [
    (
        "heavy metal",
        [
            ("epic heavy metal", 0.35),
            ("melodic heavy metal", -0.38),
            ("progressive heavy metal", 0.68),
        ],
    ),
    (
        "thrash metal",
        [
            ("technical thrash metal", 0.42),
            ("blackened thrash metal", -0.42),
            ("melodic thrash metal", 0.78),
        ],
    ),
    (
        "death metal",
        [
            ("melodic death metal", 0.34),
            ("technical death metal", -0.34),
            ("progressive death metal", 0.72),
            ("brutal death metal", -0.72),
        ],
    ),
    (
        "doom metal",
        [
            ("epic doom metal", 0.35),
            ("funeral doom metal", -0.38),
            ("atmospheric doom metal", 0.72),
        ],
    ),
    (
        "black metal",
        [
            ("melodic black metal", 0.34),
            ("symphonic black metal", -0.34),
            ("atmospheric black metal", 0.72),
            ("depressive black metal", -0.72),
        ],
    ),
]


def load_genre_module():
    spec = importlib.util.spec_from_file_location("metal_genre_trends", ANALYZE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def title_case_family(value: str) -> str:
    return str(value).title()


def build_first_year_table() -> pd.DataFrame:
    genre_module = load_genre_module()
    bands = pd.read_csv(INPUT_PATH, usecols=["genre_raw", "entry_year"], dtype={"genre_raw": "string"})
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce")
    bands = bands.loc[bands["entry_year"].notna() & bands["genre_raw"].notna()].copy()
    bands["entry_year"] = bands["entry_year"].astype(int)

    token_cache, _ = genre_module.build_genre_cache(bands["genre_raw"])
    rows: list[dict[str, object]] = []
    for row in bands.itertuples(index=False):
        tags = token_cache.get(str(row.genre_raw), [])
        for tag in tags:
            families = genre_module.assign_broad_families([tag])
            for family in families:
                rows.append({"family": family, "tag": tag, "entry_year": int(row.entry_year)})

    tag_panel = pd.DataFrame(rows)
    summary = (
        tag_panel.groupby(["family", "tag"], as_index=False)
        .agg(first_year=("entry_year", "min"), band_count=("entry_year", "size"))
        .sort_values(["family", "first_year", "band_count", "tag"], ascending=[True, True, False, True])
        .reset_index(drop=True)
    )
    return summary


def build_plot_table(summary: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for family, branches in REPRESENTATIVE_BRANCHES:
        family_row = summary.loc[summary["tag"].eq(family)]
        if family_row.empty:
            continue
        family_first_year = int(family_row.iloc[0]["first_year"])
        rows.append(
            {
                "family": family,
                "tag": family,
                "first_year": family_first_year,
                "band_count": int(family_row.iloc[0]["band_count"]),
                "offset": 0.0,
                "main_family_i": 1,
            }
        )
        for tag, offset in branches:
            match = summary.loc[(summary["family"].eq(family)) & (summary["tag"].eq(tag))]
            if match.empty:
                continue
            rows.append(
                {
                    "family": family,
                    "tag": tag,
                    "first_year": int(match.iloc[0]["first_year"]),
                    "band_count": int(match.iloc[0]["band_count"]),
                    "offset": float(offset),
                    "main_family_i": 0,
                }
            )
    return pd.DataFrame(rows)


def write_summary(plot_table: pd.DataFrame) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Subgenre branching timeline summary\n\n")
        handle.write(
            "This is an illustrative branching timeline, not a literal genealogy. It uses actual first "
            "appearance years from the parsed Metallum genre descriptors and highlights a small set of "
            "representative later subgenres.\n\n"
        )
        for family, family_df in plot_table.groupby("family", sort=False):
            handle.write(f"## {title_case_family(family)}\n\n")
            display = family_df.copy()
            display["tag"] = display["tag"].map(title_case_family)
            display = display[["tag", "first_year", "band_count"]].sort_values(["first_year", "band_count"], ascending=[True, False])
            handle.write(display.to_markdown(index=False))
            handle.write("\n\n")


def plot_timeline(plot_table: pd.DataFrame) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    families = [family for family, _ in REPRESENTATIVE_BRANCHES if family in set(plot_table["family"])]
    y_positions = {family: (len(families) - idx - 1) * 1.9 for idx, family in enumerate(families)}
    colors = {
        "heavy metal": "#58508d",
        "thrash metal": "#bc5090",
        "death metal": "#ff6361",
        "doom metal": "#ffa600",
        "black metal": "#2f4b7c",
    }

    x_min = int(plot_table["first_year"].min()) - 1
    x_max = int(plot_table["first_year"].max()) + 12

    fig, ax = plt.subplots(figsize=(13.5, 8.5))

    for family in families:
        family_rows = plot_table.loc[plot_table["family"].eq(family)].copy()
        base_y = y_positions[family]
        color = colors.get(family, "#444444")
        family_start = int(family_rows.loc[family_rows["main_family_i"].eq(1), "first_year"].iloc[0])

        ax.hlines(base_y, family_start, x_max - 2.0, color=color, linewidth=2.8, alpha=0.95)
        ax.text(
            family_start - 0.5,
            base_y,
            f"{title_case_family(family)} ({family_start})",
            ha="right",
            va="center",
            fontsize=11,
            fontweight="bold",
            color=color,
        )

        branches = family_rows.loc[family_rows["main_family_i"].eq(0)].sort_values(["first_year", "offset"])
        for row in branches.itertuples(index=False):
            branch_y = base_y + row.offset
            branch_x = row.first_year
            label_x = branch_x + 1.9
            ax.plot([branch_x, branch_x + 0.7, label_x - 0.15], [base_y, branch_y, branch_y], color=color, linewidth=1.8)
            ax.scatter([branch_x], [base_y], color=color, s=20, zorder=3)
            ax.text(
                label_x,
                branch_y,
                f"{title_case_family(row.tag)} ({int(row.first_year)})",
                ha="left",
                va="center",
                fontsize=10,
                color=color,
            )

    ax.set_title("Illustrative branching of metal subgenres", fontsize=16, weight="bold")
    ax.set_xlabel("First appearance year in the data")
    ax.set_yticks([])
    ax.set_xlim(x_min, x_max)
    ax.grid(axis="x", alpha=0.22, linewidth=0.6)
    for spine in ["left", "right", "top"]:
        ax.spines[spine].set_visible(False)

    note = (
        "Representative later subgenres only. Dates are first appearances in the parsed Metallum labels.\n"
        "The figure is illustrative: it shows later differentiation within broad families, not a literal parent-child tree."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=220)
    fig.savefig(SVG_PATH)
    plt.close(fig)


def main() -> None:
    summary = build_first_year_table()
    plot_table = build_plot_table(summary)
    plot_timeline(plot_table)
    write_summary(plot_table)
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SVG_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
