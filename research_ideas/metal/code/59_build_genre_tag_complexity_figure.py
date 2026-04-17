from __future__ import annotations

import importlib.util
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
ANALYZE_PATH = PROJECT_ROOT / "code" / "05_analyze_genre_trends.py"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "genre_tag_complexity_over_time.png"
SUMMARY_PATH = OUTPUT_DIR / "genre_tag_complexity_over_time_summary.md"


def load_genre_module():
    spec = importlib.util.spec_from_file_location("metal_genre_trends", ANALYZE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def build_band_tag_panel() -> pd.DataFrame:
    genre_module = load_genre_module()
    bands = pd.read_csv(INPUT_PATH, usecols=["genre_raw", "entry_year"], dtype={"genre_raw": "string"})
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce")
    bands = bands.loc[bands["entry_year"].notna() & bands["genre_raw"].notna()].copy()
    bands["entry_year"] = bands["entry_year"].astype(int)

    token_cache, _ = genre_module.build_genre_cache(bands["genre_raw"])
    bands["atomic_tag_count"] = bands["genre_raw"].map(lambda raw: len(token_cache.get(str(raw), [])))
    bands = bands.loc[bands["atomic_tag_count"].gt(0)].copy()
    return bands


def build_yearly_series(bands: pd.DataFrame) -> pd.DataFrame:
    yearly = (
        bands.groupby("entry_year", as_index=False)
        .agg(
            bands_total=("atomic_tag_count", "size"),
            avg_atomic_tags=("atomic_tag_count", "mean"),
            share_2plus=("atomic_tag_count", lambda s: (s >= 2).mean()),
            share_3plus=("atomic_tag_count", lambda s: (s >= 3).mean()),
            share_4plus=("atomic_tag_count", lambda s: (s >= 4).mean()),
        )
        .sort_values("entry_year")
        .reset_index(drop=True)
    )
    for column in ["avg_atomic_tags", "share_2plus", "share_3plus", "share_4plus"]:
        yearly[f"{column}_rolling_5yr"] = yearly[column].rolling(window=5, min_periods=1).mean()
    return yearly


def write_summary(bands: pd.DataFrame, yearly: pd.DataFrame) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Genre-tag complexity over time\n\n")
        handle.write(
            "This figure tracks how many parsed atomic genre tags are attached to bands over time, "
            "using the cleaned Metallum genre strings.\n\n"
        )
        handle.write(f"- Bands with usable entry year and at least one parsed tag: `{len(bands)}`\n")
        handle.write(f"- Mean atomic tags per band in the full sample: `{bands['atomic_tag_count'].mean():.2f}`\n")
        handle.write(f"- Median atomic tags per band in the full sample: `{bands['atomic_tag_count'].median():.0f}`\n")
        for year in [1980, 1990, 2000, 2010, 2022]:
            row = yearly.loc[yearly["entry_year"].eq(year)]
            if row.empty:
                continue
            row = row.iloc[0]
            handle.write(
                f"- `{year}`: mean tags `{row['avg_atomic_tags']:.2f}`, "
                f"`2+` share `{row['share_2plus']:.3f}`, `3+` share `{row['share_3plus']:.3f}`\n"
            )


def plot_figure(yearly: pd.DataFrame) -> None:
    fig, ax1 = plt.subplots(figsize=(12.5, 7.5))

    ax1.plot(
        yearly["entry_year"],
        yearly["avg_atomic_tags_rolling_5yr"],
        color="#8c1d40",
        linewidth=2.8,
        label="Average atomic tags per band",
    )
    ax1.set_xlabel("Band entry year")
    ax1.set_ylabel("Average atomic tags per band")
    ax1.grid(alpha=0.22, linewidth=0.6)

    ax2 = ax1.twinx()
    ax2.plot(
        yearly["entry_year"],
        yearly["share_2plus_rolling_5yr"],
        color="#1f4e79",
        linewidth=2.3,
        label="Share with 2+ tags",
    )
    ax2.plot(
        yearly["entry_year"],
        yearly["share_3plus_rolling_5yr"],
        color="#2a7f62",
        linewidth=2.3,
        label="Share with 3+ tags",
    )
    ax2.plot(
        yearly["entry_year"],
        yearly["share_4plus_rolling_5yr"],
        color="#b86b00",
        linewidth=2.3,
        label="Share with 4+ tags",
    )
    ax2.set_ylabel("Share of bands")
    ax2.set_ylim(0, min(1.0, yearly["share_2plus_rolling_5yr"].max() * 1.15))

    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, frameon=False, loc="upper left")
    ax1.set_title("Genre-tag complexity over time", fontsize=15, weight="bold")

    note = (
        "Atomic tags are parsed from raw genre strings. The figure shows the finer combinatorial margin:\n"
        "how many different genre descriptors bands carry, not just how many broad families exist."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=220)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bands = build_band_tag_panel()
    yearly = build_yearly_series(bands)
    plot_figure(yearly)
    write_summary(bands, yearly)
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
