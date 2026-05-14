from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

CDC_SHAPE_PATH = BUILD / "cdc_first_birth_timing_target_review_25plus_target_comparison.csv"
TIMING_CANDIDATES_PATH = BUILD / "fertility_annual_timing_stock_micro_screen_candidates.csv"
POLITICAL_SHAPE_CANDIDATES_PATH = BUILD / "fertility_annual_political_shape_screen_candidates.csv"

OUT_CSV = BUILD / "annual_first_birth_shape_comparison.csv"
OUT_MD = BUILD / "annual_first_birth_shape_comparison.md"
OUT_PNG = BUILD / "annual_first_birth_shape_comparison.png"
OUT_PDF = BUILD / "annual_first_birth_shape_comparison.pdf"

TIMING_LABEL = "max_front_loaded | phi0 1.120 | child 0.020 | cost 0.050 | kappa 0.16 | lambda 0.10"
POLITICAL_SHAPE_LABEL = "older-tail smooth shape | theta_r 0.40 | housingmax 15.0"

BIN_LABELS = ["25-29", "30-34", "35-39", "40-44+"]
BIN_COLS = [
    "eval_share_first_birth_25_29",
    "eval_share_first_birth_30_34",
    "eval_share_first_birth_35_39",
    "eval_share_first_birth_40_44_plus",
]


def set_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titleweight": "bold",
            "axes.titlesize": 11,
            "axes.labelsize": 10,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 9,
        }
    )


def load_shape_target() -> pd.Series:
    target = pd.read_csv(CDC_SHAPE_PATH).set_index("bucket")
    return pd.Series(
        [float(target.loc[label, "share_25_plus"]) for label in BIN_LABELS],
        index=BIN_LABELS,
        name="CDC pooled 2020-2024",
    )


def load_candidate(path: Path, label: str, series_name: str) -> tuple[pd.Series, dict[str, float]]:
    df = pd.read_csv(path)
    row = df.loc[df["label"] == label]
    if row.empty:
        raise ValueError(f"Could not find candidate row: {label}")
    row = row.iloc[0]
    shares = pd.Series([float(row[col]) for col in BIN_COLS], index=BIN_LABELS, name=series_name)
    meta = {
        "mean_age_first_birth": float(row["eval_mean_age_first_birth"]),
        "median_age_first_birth": float(row["eval_median_age_first_birth"]),
        "share_first_birth_30_plus": float(row["eval_share_first_birth_30_plus"]),
        "childless_share_at_50": float(row["eval_childless_share_at_50"]),
    }
    return shares, meta


def build_table() -> tuple[pd.DataFrame, dict[str, dict[str, float]]]:
    target = load_shape_target()
    timing_shares, timing_meta = load_candidate(
        TIMING_CANDIDATES_PATH,
        TIMING_LABEL,
        "Old annual timing candidate",
    )
    political_shares, political_meta = load_candidate(
        POLITICAL_SHAPE_CANDIDATES_PATH,
        POLITICAL_SHAPE_LABEL,
        "Political-shape row",
    )

    table = pd.DataFrame(
        {
            "bucket": BIN_LABELS,
            "cdc_pooled_2020_2024": target.values,
            "old_annual_timing_candidate": timing_shares.values,
            "political_shape_row": political_shares.values,
        }
    )
    meta = {
        "Old annual timing candidate": timing_meta,
        "Political-shape row": political_meta,
    }
    return table, meta


def write_markdown(table: pd.DataFrame, meta: dict[str, dict[str, float]]) -> None:
    lines = [
        "# Annual first-birth shape comparison",
        "",
        "This note compares the pooled CDC `2020-2024` first-birth timing shape within ages `25+`",
        "against two annual model rows:",
        f"- Old annual timing candidate: `{TIMING_LABEL}`",
        f"- Political-shape row: `{POLITICAL_SHAPE_LABEL}`",
        "",
        "## Main read",
        "",
        "- The old annual timing candidate is still too concentrated in `25-29` and too thin in `35-39`, even though its summary timing moments looked usable under the old rule.",
        "- The political-shape row shifts births earlier, but overshoots badly by piling too much mass into `25-29` and collapsing the late bins.",
        "- The key miss is not the tiny top bin alone; it is the full grouped timing shape.",
        "",
        "## Shape table",
        "",
        "| Bucket | CDC pooled 2020-2024 | Old annual timing candidate | Political-shape row |",
        "| --- | ---: | ---: | ---: |",
    ]

    for _, row in table.iterrows():
        lines.append(
            f"| {row['bucket']} | {row['cdc_pooled_2020_2024']:.3f} | "
            f"{row['old_annual_timing_candidate']:.3f} | {row['political_shape_row']:.3f} |"
        )

    lines.extend(
        [
            "",
            "## Summary moments",
            "",
            "| Row | Mean age | Median age | Share 30+ | Childless at 50 |",
            "| --- | ---: | ---: | ---: | ---: |",
        ]
    )

    for label, vals in meta.items():
        lines.append(
            f"| {label} | {vals['mean_age_first_birth']:.2f} | {vals['median_age_first_birth']:.0f} | "
            f"{vals['share_first_birth_30_plus']:.3f} | {vals['childless_share_at_50']:.3f} |"
        )

    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_figure(table: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(8.6, 5.2), constrained_layout=True)
    x = np.arange(len(BIN_LABELS))
    width = 0.23

    colors = {
        "cdc_pooled_2020_2024": "#2f5c85",
        "old_annual_timing_candidate": "#b24c2a",
        "political_shape_row": "#7a9a3a",
    }

    ax.bar(
        x - width,
        table["cdc_pooled_2020_2024"],
        width=width,
        color=colors["cdc_pooled_2020_2024"],
        label="CDC pooled 2020-2024",
    )
    ax.bar(
        x,
        table["old_annual_timing_candidate"],
        width=width,
        color=colors["old_annual_timing_candidate"],
        label="Old annual timing candidate",
    )
    ax.bar(
        x + width,
        table["political_shape_row"],
        width=width,
        color=colors["political_shape_row"],
        label="Political-shape row",
    )

    ax.set_xticks(x, BIN_LABELS)
    ax.set_ylim(0, 0.9)
    ax.set_ylabel("Share of first births within ages 25+")
    ax.set_title("Annual first-birth timing shape: data vs model")
    ax.legend(frameon=False, loc="upper right")

    fig.savefig(OUT_PNG, dpi=220, bbox_inches="tight")
    fig.savefig(OUT_PDF, bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    table, meta = build_table()
    table.to_csv(OUT_CSV, index=False)
    write_markdown(table, meta)
    make_figure(table)


if __name__ == "__main__":
    set_style()
    main()
