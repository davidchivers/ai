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


def load_tables() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    nimby = pd.read_csv(BUILD / "nimby_baby_boom_reference_full.csv")
    fert_base = pd.read_csv(BUILD / "comparison_new_baseline.csv")
    fert_shock = pd.read_csv(BUILD / "comparison_new_policy.csv")
    nimby = nimby.replace([np.inf, -np.inf], np.nan)
    return nimby, fert_base, fert_shock


def build_fertility_transition(fert_base: pd.DataFrame, fert_shock: pd.DataFrame) -> pd.DataFrame:
    out = fert_shock.copy()
    out["birthrate_index"] = fert_shock["births"] / fert_base["births"]
    out["average_age_dev"] = fert_shock["average_age"] - fert_base["average_age"]
    base_price_index = np.exp(fert_base["price"] - fert_base["price"].iloc[0])
    shock_price_index = np.exp(fert_shock["price"] - fert_shock["price"].iloc[0])
    out["house_price_index"] = shock_price_index
    out["house_price_dev"] = shock_price_index - base_price_index
    out["fertility_rate_dev"] = fert_shock["fertility_rate"] - fert_base["fertility_rate"]
    out["n_home_dev"] = fert_shock["n_home"] - fert_base["n_home"]
    out["young_homeownership_proxy_dev"] = fert_shock["young_homeownership_proxy"] - fert_base["young_homeownership_proxy"]
    out["old_homeownership_proxy_dev"] = fert_shock["old_homeownership_proxy"] - fert_base["old_homeownership_proxy"]
    out["aggregate_homeownership_proxy_dev"] = fert_shock["aggregate_homeownership_proxy"] - fert_base["aggregate_homeownership_proxy"]

    for generation in ("boom", "parent", "child"):
        own_col = f"{generation}_generation_homeownership_proxy_level"
        burden_col = f"{generation}_generation_housing_burden_proxy_level"
        out[f"{generation}_generation_homeownership_proxy_index"] = fert_shock[own_col] / fert_base[own_col]
        out[f"{generation}_generation_housing_burden_proxy_index"] = fert_shock[burden_col] / fert_base[burden_col]
    return out


def write_summary(nimby: pd.DataFrame, fert: pd.DataFrame) -> None:
    post_mask = fert["t"] >= 40
    boom_mask = (fert["t"] >= 0) & (fert["t"] <= 9)

    summary = pd.DataFrame(
        [
            {
                "nimby_post_price_response": nimby.loc[post_mask, "house_price_index"].div(nimby["house_price_index"].iloc[0]).sub(1).mean(),
                "fertility_post_price_response": fert.loc[post_mask, "house_price_dev"].mean(),
                "nimby_peak_price_response": nimby["house_price_index"].div(nimby["house_price_index"].iloc[0]).sub(1).max(),
                "fertility_peak_price_response": fert["house_price_dev"].max(),
                "nimby_peak_young_homeownership_response": nimby["young_homeownership_dev"].max(),
                "fertility_peak_young_homeownership_response": fert["young_homeownership_proxy_dev"].max(),
                "nimby_peak_old_homeownership_response": nimby["old_homeownership_dev"].max(),
                "fertility_peak_old_homeownership_response": fert["old_homeownership_proxy_dev"].max(),
                "fertility_peak_boom_generation_burden_index": fert["boom_generation_housing_burden_proxy_index"].max(),
                "fertility_peak_child_generation_burden_index": fert["child_generation_housing_burden_proxy_index"].max(skipna=True),
                "fertility_boom_fertility_rate_response": fert.loc[boom_mask, "fertility_rate_dev"].mean(),
                "fertility_post_fertility_rate_response": fert.loc[post_mask, "fertility_rate_dev"].mean(),
                "fertility_peak_children_at_home_response": fert["n_home_dev"].max(),
            }
        ]
    )
    summary.to_csv(BUILD / "nimby_vs_fertility_baby_boom_summary.csv", index=False)


def plot_recreated_nimby(nimby: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(11, 8.2), constrained_layout=True)
    c_main = "#111111"

    ax = axes[0, 0]
    ax.plot(nimby["t"], nimby["birthrate_index"], color=c_main, lw=2.2)
    ax.set_title("A. Birthrate")
    ax.set_xlabel("Time")
    ax.set_ylabel("Index")

    ax = axes[0, 1]
    ax.plot(nimby["t"], nimby["average_age"], color=c_main, lw=2.2)
    ax.set_title("B. Average age")
    ax.set_xlabel("Time")
    ax.set_ylabel("Years")

    ax = axes[1, 0]
    ax.plot(nimby["t"], nimby["house_price_index"], color=c_main, lw=2.2)
    ax.set_title("C. Smoothed house price")
    ax.set_xlabel("Time")
    ax.set_ylabel("Index")

    ax = axes[1, 1]
    ax.plot(nimby["t"], nimby["young_homeownership"], color=c_main, lw=2.2)
    ax.set_title("D. Young homeownership")
    ax.set_xlabel("Time")
    ax.set_ylabel("Share")

    fig.suptitle("Temporary birthrate increase: recreated NIMBY transition", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_baby_boom_recreated.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_baby_boom_recreated.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_comparison(nimby: pd.DataFrame, fert: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 3, figsize=(13, 8.4), constrained_layout=True)
    c_nimby = "#111111"
    c_fertility = "#b24c2a"
    c_blue = "#275d8c"
    c_gray = "#666666"

    ax = axes[0, 0]
    ax.plot(nimby["t"], nimby["birthrate_index"], color=c_nimby, lw=2.2, label="NIMBY")
    ax.plot(nimby["t"], nimby["birthrate_index"], color=c_fertility, lw=2.2, ls="--", label="Fertility extension")
    ax.set_title("A. Common imposed baby-boom shock")
    ax.set_xlabel("Time")
    ax.set_ylabel("Index")
    ax.legend(frameon=False, loc="best")

    ax = axes[0, 1]
    ax.plot(nimby["t"], nimby["average_age_dev"], color=c_nimby, lw=2.2, label="NIMBY")
    ax.plot(fert["t"], fert["average_age_dev"], color=c_fertility, lw=2.2, label="Fertility extension")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("B. Average-age deviation from baseline")
    ax.set_xlabel("Time")
    ax.set_ylabel("Years")
    ax.legend(frameon=False, loc="best")

    ax = axes[0, 2]
    ax.plot(nimby["t"], nimby["house_price_dev"], color=c_nimby, lw=2.2, label="NIMBY")
    ax.plot(fert["t"], fert["house_price_dev"], color=c_fertility, lw=2.2, label="Fertility extension")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("C. House-price response")
    ax.set_xlabel("Time")
    ax.set_ylabel("Deviation from baseline level")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 0]
    ax.plot(nimby["t"], nimby["young_homeownership_dev"], color=c_nimby, lw=2.2, label="NIMBY")
    ax.plot(fert["t"], fert["young_homeownership_proxy_dev"], color=c_fertility, lw=2.2, label="Fertility proxy")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("D. Young homeownership response")
    ax.set_xlabel("Time")
    ax.set_ylabel("Deviation from baseline share")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    ax.plot(nimby["t"], nimby["old_homeownership_dev"], color=c_nimby, lw=2.2, label="NIMBY")
    ax.plot(fert["t"], fert["old_homeownership_proxy_dev"], color=c_fertility, lw=2.2, label="Fertility proxy")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("E. Old homeownership response")
    ax.set_xlabel("Time")
    ax.set_ylabel("Deviation from baseline share")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 2]
    ax.plot(fert["t"], fert["fertility_rate_dev"], color=c_fertility, lw=2.2, label="Fertility-rate response")
    ax.plot(fert["t"], fert["n_home_dev"], color=c_blue, lw=2.0, ls="--", label="Children-at-home response")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("F. Additional family response in the fertility extension")
    ax.set_xlabel("Time")
    ax.set_ylabel("Deviation from baseline")
    ax.legend(frameon=False, loc="best")

    fig.suptitle("Temporary birthrate increase: NIMBY versus fertility transition", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_baby_boom_transition.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_baby_boom_transition.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_generation_comparison(nimby: pd.DataFrame, fert: pd.DataFrame) -> None:
    fig, axes = plt.subplots(1, 3, figsize=(13, 3.9), constrained_layout=True)
    c_nimby = "#111111"
    c_fertility = "#b24c2a"
    c_gray = "#666666"
    labels = {
        "boom": "A. Boom generation",
        "parent": "B. Parent generation",
        "child": "C. Child generation",
    }

    for ax, generation in zip(axes, ("boom", "parent", "child")):
        nimby_col = f"{generation}_generation_homeownership_index"
        fert_col = f"{generation}_generation_homeownership_proxy_index"
        ax.plot(nimby["t"], nimby[nimby_col], color=c_nimby, lw=2.2, label="NIMBY")
        ax.plot(fert["t"], fert[fert_col], color=c_fertility, lw=2.2, label="Fertility proxy")
        ax.axhline(1.0, color=c_gray, lw=1.0, ls="--")
        ax.set_title(labels[generation])
        ax.set_xlabel("Time")
        ax.set_ylabel("Index")
        ax.legend(frameon=False, loc="best")

    fig.suptitle(
        "Temporary birthrate increase: cohort homeownership access",
        fontsize=14,
        fontweight="bold",
    )
    fig.savefig(BUILD / "nimby_vs_fertility_generation_homeownership.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_generation_homeownership.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    nimby, fert_base, fert_shock = load_tables()
    fert = build_fertility_transition(fert_base, fert_shock)
    fert.to_csv(BUILD / "nimby_vs_fertility_transition_proxy_series.csv", index=False)
    write_summary(nimby, fert)
    plot_recreated_nimby(nimby)
    plot_comparison(nimby, fert)
    plot_generation_comparison(nimby, fert)


if __name__ == "__main__":
    main()
