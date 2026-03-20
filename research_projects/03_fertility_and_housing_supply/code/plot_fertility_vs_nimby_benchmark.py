from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


def main() -> None:
    common = pd.read_csv(BUILD / "fertility_vs_nimby_common_price_grid.csv")
    summary = pd.read_csv(BUILD / "fertility_vs_nimby_benchmark_summary.csv")

    nimby = summary.loc[summary["model"] == "nimby"].iloc[0]
    fertility = summary.loc[summary["model"] == "fertility"].iloc[0]

    plt.rcParams.update(
        {
            "font.family": "serif",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titleweight": "bold",
            "axes.labelsize": 11,
            "axes.titlesize": 12,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
            "legend.fontsize": 9,
        }
    )

    fig, axes = plt.subplots(3, 2, figsize=(11, 12), constrained_layout=True)

    c_nimby = "#111111"
    c_fertility = "#b24c2a"
    c_blue = "#275d8c"
    c_green = "#3c7d3c"
    c_gold = "#b48a00"
    c_purple = "#6c5b7b"
    c_gray = "#666666"

    ax = axes[0, 0]
    ax.plot(common["a_price"], common["nimby_vote"], color=c_nimby, lw=2.2, marker="o", label="Original NIMBY")
    ax.plot(common["a_price"], common["fertility_vote"], color=c_fertility, lw=2.2, marker="o", label="Fertility extension")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.axvline(nimby["refined_price"], color=c_nimby, lw=1.0, ls=":")
    ax.axvline(fertility["refined_price"], color=c_fertility, lw=1.0, ls=":")
    ax.set_title("A. Raw political support for higher prices")
    ax.set_xlabel("House price")
    ax.set_ylabel("Raw support")
    ax.legend(frameon=False, loc="upper right")

    ax = axes[0, 1]
    ax.plot(common["a_price"], common["nimby_vote_per_mass"], color=c_nimby, lw=2.2, marker="o", label="Original NIMBY")
    ax.plot(common["a_price"], common["fertility_vote_per_mass"], color=c_fertility, lw=2.2, marker="o", label="Fertility extension")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.axvline(nimby["refined_price"], color=c_nimby, lw=1.0, ls=":")
    ax.axvline(fertility["refined_price"], color=c_fertility, lw=1.0, ls=":")
    ax.set_title("B. Support per unit mass")
    ax.set_xlabel("House price")
    ax.set_ylabel("Support / mass")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 0]
    ax.plot(common["a_price"], common["nimby_debt"], color=c_nimby, lw=2.2, marker="o", label="Original NIMBY")
    ax.plot(common["a_price"], common["fertility_debt"], color=c_fertility, lw=2.2, marker="o", label="Fertility extension")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("C. Aggregate debt stock")
    ax.set_xlabel("House price")
    ax.set_ylabel("Debt stock")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    ax.plot(common["a_price"], common["nimby_mass"], color=c_nimby, lw=2.2, marker="o", label="Original NIMBY")
    ax.plot(common["a_price"], common["fertility_mass"], color=c_fertility, lw=2.2, marker="o", label="Fertility extension")
    ax.set_title("D. Stationary household mass")
    ax.set_xlabel("House price")
    ax.set_ylabel("Mass")
    ax.legend(frameon=False, loc="best")

    ax = axes[2, 0]
    ax.plot(common["a_price"], common["fertility_birth_rate"], color=c_fertility, lw=2.4, marker="o", label="Birth rate")
    ax.plot(common["a_price"], common["fertility_home_any_40"], color=c_blue, lw=2.0, marker="s", label="Any child at home, age 40")
    ax.plot(common["a_price"], common["fertility_home_any_50"], color=c_green, lw=2.0, marker="^", label="Any child at home, age 50")
    ax.set_title("E. Birth rates and children at home")
    ax.set_xlabel("House price")
    ax.set_ylabel("Share / rate")
    ax.set_ylim(0, 1)
    ax.legend(frameon=False, loc="upper right")

    ax = axes[2, 1]
    ax.plot(common["a_price"], common["fertility_parity_0"], color=c_blue, lw=2.1, marker="o", label="0 children")
    ax.plot(common["a_price"], common["fertility_parity_1"], color=c_green, lw=2.1, marker="s", label="1 child")
    ax.plot(common["a_price"], common["fertility_parity_2"], color=c_gold, lw=2.1, marker="^", label="2 children")
    ax.plot(common["a_price"], common["fertility_parity_3plus"], color=c_purple, lw=2.1, marker="d", label="3+ children")
    ax.set_title("F. Completed fertility by house price")
    ax.set_xlabel("House price")
    ax.set_ylabel("Share")
    ax.set_ylim(0, 1)
    ax.legend(frameon=False, loc="upper right", ncol=2)

    fig.suptitle("Comparison with the NIMBY benchmark", fontsize=14, fontweight="bold")

    out_png = BUILD / "fertility_vs_nimby_benchmark_panels.png"
    out_pdf = BUILD / "fertility_vs_nimby_benchmark_panels.pdf"
    fig.savefig(out_png, dpi=220, bbox_inches="tight")
    fig.savefig(out_pdf, bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    main()
