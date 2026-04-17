from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "genre_analysis" / "genre_family_yearly_counts.csv"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "all_genre_families_over_time.png"
SUMMARY_PATH = OUTPUT_DIR / "all_genre_families_over_time_summary.md"

TOP_HIGHLIGHT_N = 7


def title_case_family(value: str) -> str:
    return str(value).title()


def build_complete_panel(yearly: pd.DataFrame) -> pd.DataFrame:
    years = np.arange(int(yearly["entry_year"].min()), int(yearly["entry_year"].max()) + 1)
    families = sorted(yearly["genre_family"].unique())
    grid = pd.MultiIndex.from_product([families, years], names=["genre_family", "entry_year"]).to_frame(index=False)
    merged = grid.merge(yearly, on=["genre_family", "entry_year"], how="left")
    merged["bands_started"] = merged["bands_started"].fillna(0.0)
    merged["bands_started_rolling_5yr"] = (
        merged.groupby("genre_family")["bands_started"]
        .transform(lambda series: series.rolling(window=5, min_periods=1).mean())
    )
    return merged


def write_summary(panel: pd.DataFrame, highlighted: list[str]) -> None:
    family_total = panel["genre_family"].nunique()
    highlighted_table = (
        panel.groupby("genre_family", as_index=False)
        .agg(
            total_starts=("bands_started", "sum"),
            peak_roll5=("bands_started_rolling_5yr", "max"),
            first_active_year=("bands_started", lambda s: int(panel.loc[s.index, "entry_year"][s.gt(0)].min())),
        )
        .sort_values("total_starts", ascending=False)
    )
    highlighted_table = highlighted_table.loc[highlighted_table["genre_family"].isin(highlighted)].copy()
    highlighted_table["genre_family"] = highlighted_table["genre_family"].map(title_case_family)

    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Full genre proliferation figure summary\n\n")
        handle.write(
            f"The figure plots all `{family_total}` broad genre families over time using the "
            "`5`-year rolling mean of band starts.\n\n"
        )
        handle.write("## Highlighted families\n\n")
        handle.write(highlighted_table.to_markdown(index=False))


def plot_figure(panel: pd.DataFrame, highlighted: list[str]) -> None:
    years = sorted(panel["entry_year"].unique())
    color_map = plt.get_cmap("tab10")
    colors = {family: color_map(i % 10) for i, family in enumerate(highlighted)}

    fig, ax = plt.subplots(figsize=(13, 8))

    for family, family_df in panel.groupby("genre_family"):
        line_color = colors.get(family, "#c6c6c6")
        line_width = 2.3 if family in highlighted else 1.0
        alpha = 0.95 if family in highlighted else 0.5
        zorder = 3 if family in highlighted else 1
        ax.plot(
            family_df["entry_year"],
            family_df["bands_started_rolling_5yr"],
            color=line_color,
            linewidth=line_width,
            alpha=alpha,
            zorder=zorder,
        )

    highlight_end = (
        panel.loc[panel["genre_family"].isin(highlighted)]
        .sort_values(["genre_family", "entry_year"])
        .groupby("genre_family", as_index=False)
        .tail(1)
        .sort_values("bands_started_rolling_5yr", ascending=False)
        .reset_index(drop=True)
    )
    offsets = np.linspace(16, -16, len(highlight_end))
    for offset, row in zip(offsets, highlight_end.itertuples(index=False)):
        ax.annotate(
            title_case_family(row.genre_family),
            xy=(row.entry_year, row.bands_started_rolling_5yr),
            xytext=(8, float(offset)),
            textcoords="offset points",
            fontsize=10,
            color=colors[row.genre_family],
            weight="bold",
            ha="left",
            va="center",
        )

    ax.set_title("Broad metal genre proliferation over time", fontsize=15, weight="bold")
    ax.set_xlabel("Band entry year")
    ax.set_ylabel("Band starts (5-year rolling mean)")
    ax.grid(alpha=0.22, linewidth=0.6)
    ax.set_xlim(min(years), max(years) + 4)

    note = (
        "All broad families are shown. Only the largest few are highlighted and labelled.\n"
        "Bands can belong to more than one broad family, so families are not mutually exclusive."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=220)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    yearly = pd.read_csv(INPUT_PATH)
    panel = build_complete_panel(yearly)

    ranking = (
        panel.groupby("genre_family", as_index=False)
        .agg(total_starts=("bands_started", "sum"))
        .sort_values(["total_starts", "genre_family"], ascending=[False, True])
    )
    highlighted = ranking.head(TOP_HIGHLIGHT_N)["genre_family"].tolist()

    plot_figure(panel, highlighted)
    write_summary(panel, highlighted)
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
