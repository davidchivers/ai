from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
SOURCE = Path(r"C:\Users\Dave_\Dropbox\Zac and David\Graphs\Age Share Median Projections.dta")


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


def load_projection_table() -> pd.DataFrame:
    df = pd.read_stata(SOURCE, convert_categoricals=False)
    age_cols = [c for c in df.columns if c.startswith("AGE_")]

    keep = df[["Year", *age_cols]].copy()
    keep = keep.rename(columns={"Year": "year"})
    keep["year"] = keep["year"].astype(int)

    keep["share_18_39"] = keep[[f"AGE_{age}" for age in range(18, 40)]].sum(axis=1)
    keep["share_40_59"] = keep[[f"AGE_{age}" for age in range(40, 60)]].sum(axis=1)
    keep["share_60_79"] = keep[[f"AGE_{age}" for age in range(60, 80)]].sum(axis=1)
    keep["share_80_plus"] = keep[[f"AGE_{age}" for age in range(80, 101)]].sum(axis=1)
    keep["adult_share_sum"] = (
        keep["share_18_39"] + keep["share_40_59"] + keep["share_60_79"] + keep["share_80_plus"]
    )
    return keep[
        [
            "year",
            "share_18_39",
            "share_40_59",
            "share_60_79",
            "share_80_plus",
            "adult_share_sum",
        ]
    ]


def write_note(df: pd.DataFrame) -> None:
    latest = df.iloc[-1]
    lines = [
        "# Upstream age-share projection input",
        "",
        "This file localizes the age-share projection object used for the NIMBY paper's future",
        "demographic path into the project-03 build folder.",
        "",
        f"- Source: `{SOURCE}`",
        f"- Year range: `{int(df['year'].min())}` to `{int(df['year'].max())}`",
        "- Adult age-group shares reported: `18-39`, `40-59`, `60-79`, `80+`",
        "",
        "## 2100 endpoint",
        "",
        f"- `18-39`: `{latest['share_18_39']:.3f}`",
        f"- `40-59`: `{latest['share_40_59']:.3f}`",
        f"- `60-79`: `{latest['share_60_79']:.3f}`",
        f"- `80+`: `{latest['share_80_plus']:.3f}`",
        "",
        "## Scope note",
        "",
        "- This prepares the demographic projection input locally for project 03.",
        "- It does not yet produce a fertility-side future house-price forecast, because the",
        "  project-03 transition prototype has not yet been ported to the project-02 forecast solver.",
        "",
    ]
    (BUILD / "nimby_projection_age_groups.md").write_text("\n".join(lines), encoding="utf-8")


def plot(df: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(11, 6.4), constrained_layout=True)
    colors = ["#d9c7a0", "#9ab7c9", "#d07f5f", "#4a5568"]

    ax.stackplot(
        df["year"],
        df["share_18_39"],
        df["share_40_59"],
        df["share_60_79"],
        df["share_80_plus"],
        labels=["18-39", "40-59", "60-79", "80+"],
        colors=colors,
        alpha=0.95,
    )
    ax.axvline(2020, color="#666666", lw=1.0, ls="--")
    ax.set_title("Projected adult age composition from the upstream NIMBY input")
    ax.set_xlabel("Year")
    ax.set_ylabel("Share of adult population")
    ax.legend(frameon=False, ncol=4, loc="upper center")
    fig.savefig(BUILD / "nimby_projection_age_groups.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_projection_age_groups.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    df = load_projection_table()
    df.to_csv(BUILD / "nimby_projection_age_groups.csv", index=False)
    write_note(df)
    plot(df)


if __name__ == "__main__":
    main()
