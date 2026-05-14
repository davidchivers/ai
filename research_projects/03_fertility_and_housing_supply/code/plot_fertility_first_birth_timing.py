from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


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


def main() -> None:
    summary = pd.read_csv(BUILD / "fertility_first_birth_timing_summary.csv")
    profiles = pd.read_csv(BUILD / "fertility_first_birth_timing_profiles.csv")

    fig, axes = plt.subplots(2, 2, figsize=(11, 8.8), constrained_layout=True)
    palette = {
        1.50: "#275d8c",
        1.75: "#3c7d3c",
        2.50: "#b48a00",
        3.00: "#b24c2a",
    }

    ax = axes[0, 0]
    for price, color in palette.items():
        subset = profiles.loc[np.isclose(profiles["a_price"], price)].copy()
        subset = subset[np.isfinite(subset["first_birth_hazard"])]
        if subset.empty:
            continue
        ax.plot(
            subset["age"],
            subset["first_birth_hazard"],
            color=color,
            lw=2.2,
            marker="o",
            label=f"House price {price:.2f}",
        )
    ax.set_title("A. Age-specific first-birth hazard")
    ax.set_xlabel("Age")
    ax.set_ylabel("Birth hazard among childless households")
    ax.legend(frameon=False, loc="best")

    ax = axes[0, 1]
    ax.plot(
        summary["a_price"],
        summary["mean_age_first_birth"],
        color="#b24c2a",
        lw=2.4,
        marker="o",
        label="Mean age",
    )
    ax.plot(
        summary["a_price"],
        summary["median_age_first_birth"],
        color="#275d8c",
        lw=2.0,
        marker="s",
        ls="--",
        label="Median age",
    )
    ax.set_title("B. Age at first birth rises with house prices")
    ax.set_xlabel("House price")
    ax.set_ylabel("Age")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 0]
    ax.plot(
        summary["a_price"],
        summary["share_first_birth_30_plus"],
        color="#3c7d3c",
        lw=2.4,
        marker="o",
    )
    ax.set_title("C. Older first births become more common")
    ax.set_xlabel("House price")
    ax.set_ylabel("Share of first births at age 30+")
    ax.set_ylim(0, 1)

    ax = axes[1, 1]
    ax.plot(
        summary["a_price"],
        summary["avg_first_birth_rate"],
        color="#b24c2a",
        lw=2.4,
        marker="o",
        label="First-birth rate",
    )
    ax.plot(
        summary["a_price"],
        summary["avg_birth_rate"],
        color="#275d8c",
        lw=2.0,
        marker="s",
        ls="--",
        label="All-birth rate",
    )
    ax.set_title("D. Delay comes with fewer first births")
    ax.set_xlabel("House price")
    ax.set_ylabel("Rate")
    ax.legend(frameon=False, loc="best")

    fig.suptitle("First-birth timing in the fertility benchmark", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_first_birth_timing.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_first_birth_timing.pdf", bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    set_style()
    main()
