from __future__ import annotations

import importlib.util
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
ANALYZE_PATH = PROJECT_ROOT / "code" / "05_analyze_genre_trends.py"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "atomic_genre_tag_proliferation_over_time.png"
SUMMARY_PATH = OUTPUT_DIR / "atomic_genre_tag_proliferation_over_time_summary.md"


def load_genre_module():
    spec = importlib.util.spec_from_file_location("metal_genre_trends", ANALYZE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def build_atomic_tag_panel() -> pd.DataFrame:
    genre_module = load_genre_module()
    bands = pd.read_csv(INPUT_PATH, usecols=["genre_raw", "entry_year"], dtype={"genre_raw": "string"})
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce")
    bands = bands.loc[bands["entry_year"].notna() & bands["genre_raw"].notna()].copy()
    bands["entry_year"] = bands["entry_year"].astype(int)

    token_cache, _ = genre_module.build_genre_cache(bands["genre_raw"])

    records: list[dict[str, object]] = []
    for row in bands.itertuples(index=False):
        for token in token_cache.get(str(row.genre_raw), []):
            records.append({"atomic_genre_tag": token, "entry_year": int(row.entry_year)})

    panel = pd.DataFrame(records)
    panel = (
        panel.groupby(["atomic_genre_tag", "entry_year"], as_index=False)
        .size()
        .rename(columns={"size": "band_count"})
        .sort_values(["atomic_genre_tag", "entry_year"])
        .reset_index(drop=True)
    )
    return panel


def build_proliferation_series(panel: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    tag_first_year = (
        panel.groupby("atomic_genre_tag", as_index=False)["entry_year"]
        .min()
        .rename(columns={"entry_year": "first_active_year"})
    )
    births = (
        tag_first_year.groupby("first_active_year", as_index=False)
        .size()
        .rename(columns={"first_active_year": "entry_year", "size": "new_atomic_tags"})
    )
    years = pd.DataFrame({"entry_year": range(int(panel["entry_year"].min()), int(panel["entry_year"].max()) + 1)})
    births = years.merge(births, on="entry_year", how="left").fillna({"new_atomic_tags": 0})
    births["new_atomic_tags"] = births["new_atomic_tags"].astype(int)
    births["new_atomic_tags_rolling_5yr"] = births["new_atomic_tags"].rolling(window=5, min_periods=1).mean()
    births["cumulative_atomic_tags"] = births["new_atomic_tags"].cumsum()
    return tag_first_year, births


def write_summary(tag_first_year: pd.DataFrame, births: pd.DataFrame) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Atomic genre-tag proliferation summary\n\n")
        handle.write(
            f"This figure tracks the proliferation of parsed atomic genre tags rather than only the "
            f"`18` broad families. The sample contains `{len(tag_first_year)}` distinct atomic tags "
            "with usable first appearance years.\n\n"
        )
        handle.write("## Cumulative atomic tags\n\n")
        for year in [1970, 1980, 1990, 2000, 2010, 2022]:
            value = int(births.loc[births["entry_year"].eq(year), "cumulative_atomic_tags"].iloc[0])
            handle.write(f"- `{year}`: `{value}` cumulative atomic tags\n")
        peak_row = births.loc[births["new_atomic_tags_rolling_5yr"].idxmax()]
        handle.write("\n## Peak creation window\n\n")
        handle.write(
            f"- Peak `5`-year rolling atomic-tag creation occurs around `{int(peak_row['entry_year'])}` "
            f"at `{peak_row['new_atomic_tags_rolling_5yr']:.1f}` new tags per year.\n"
        )


def plot_figure(births: pd.DataFrame) -> None:
    fig, ax1 = plt.subplots(figsize=(12.5, 7.5))
    ax1.bar(
        births["entry_year"],
        births["new_atomic_tags"],
        color="#9aa0a6",
        alpha=0.7,
        width=0.9,
        label="New atomic tags",
    )
    ax1.plot(
        births["entry_year"],
        births["new_atomic_tags_rolling_5yr"],
        color="#1f4e79",
        linewidth=2.5,
        label="New atomic tags (5-year rolling mean)",
    )
    ax1.set_xlabel("Band entry year")
    ax1.set_ylabel("New atomic genre tags")
    ax1.grid(alpha=0.20, linewidth=0.6)

    ax2 = ax1.twinx()
    ax2.plot(
        births["entry_year"],
        births["cumulative_atomic_tags"],
        color="#8c1d40",
        linewidth=2.5,
        linestyle="--",
        label="Cumulative atomic tags",
    )
    ax2.set_ylabel("Cumulative atomic genre tags")

    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, frameon=False, loc="upper left")
    ax1.set_title("Genre-tag proliferation over time", fontsize=15, weight="bold")

    note = (
        "Atomic tags are parsed from raw genre strings by splitting compound labels and propagating\n"
        "missing suffixes such as 'metal'. This is the finer-margin proliferation object, not just broad families."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=220)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    panel = build_atomic_tag_panel()
    tag_first_year, births = build_proliferation_series(panel)
    plot_figure(births)
    write_summary(tag_first_year, births)
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
