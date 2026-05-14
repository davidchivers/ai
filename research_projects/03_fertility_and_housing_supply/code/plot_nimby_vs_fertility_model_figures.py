from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.io as sio


ROOT = Path(__file__).resolve().parents[1]
CODE = ROOT / "code"
BUILD = ROOT / "notes" / "build"


def support_share(pref: np.ndarray) -> np.ndarray:
    return np.clip(0.5 * (pref + 1.0), 0.0, 1.0)


def heatmap_by_income_age(dens: np.ndarray, pref: np.ndarray) -> np.ndarray:
    support = support_share(pref)
    _, _, k_n, age_n = dens.shape
    out = np.full((k_n, age_n), np.nan)
    for age in range(age_n):
        for iz in range(k_n):
            weights = dens[:, :, iz, age]
            mass = weights.sum()
            if mass > 0:
                out[iz, age] = np.sum(weights * support[:, :, iz, age]) / mass
    return out


def heatmap_by_housing_age(dens: np.ndarray, pref: np.ndarray, n_bins: int = 5) -> np.ndarray:
    support = support_share(pref)
    _, j_n, _, age_n = dens.shape
    edges = np.linspace(0, j_n, n_bins + 1, dtype=int)
    out = np.full((n_bins, age_n), np.nan)
    for age in range(age_n):
        for b in range(n_bins):
            lo = edges[b]
            hi = edges[b + 1]
            weights = dens[:, lo:hi, :, age]
            values = support[:, lo:hi, :, age]
            mass = weights.sum()
            if mass > 0:
                out[b, age] = np.sum(weights * values) / mass
    return out


def support_by_age(dens: np.ndarray, pref: np.ndarray) -> np.ndarray:
    support = support_share(pref)
    age_n = dens.shape[3]
    out = np.full(age_n, np.nan)
    for age in range(age_n):
        weights = dens[:, :, :, age]
        mass = weights.sum()
        if mass > 0:
            out[age] = np.sum(weights * support[:, :, :, age]) / mass
    return out


def mean_children_by_age(home_dist: np.ndarray) -> np.ndarray:
    child_grid = np.arange(home_dist.shape[1])
    return home_dist @ child_grid


def load_state_mats() -> tuple[dict, dict]:
    upstream = sio.loadmat(CODE / "SS_function.mat", squeeze_me=True, struct_as_record=False)
    fertility = sio.loadmat(CODE / "SS_fertility.mat", squeeze_me=True, struct_as_record=False)
    return upstream, fertility


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


def plot_household_support_figure() -> None:
    upstream, fertility = load_state_mats()

    dens_n = upstream["dens4"]
    pref_n = upstream["pref4"].astype(float)
    dens_f = fertility["dens4"]
    pref_f = fertility["pref4"].astype(float)

    ages = np.asarray(fertility["diagnostics"].ages).astype(int)
    birth_rate = np.asarray(fertility["diagnostics"].birth_rate_by_age).astype(float)
    home_dist = np.asarray(fertility["diagnostics"].home_dist_by_age).astype(float)
    mean_home = mean_children_by_age(home_dist)
    any_home = 1.0 - home_dist[:, 0]

    income_n = heatmap_by_income_age(dens_n, pref_n)
    income_f = heatmap_by_income_age(dens_f, pref_f)
    housing_n = heatmap_by_housing_age(dens_n, pref_n)
    housing_f = heatmap_by_housing_age(dens_f, pref_f)
    age_support_n = support_by_age(dens_n, pref_n)
    age_support_f = support_by_age(dens_f, pref_f)

    fig, axes = plt.subplots(3, 2, figsize=(11, 12), constrained_layout=True)
    cmap = "RdYlBu_r"
    vmin, vmax = 0.0, 1.0

    im = axes[0, 0].imshow(income_n, aspect="auto", origin="lower", cmap=cmap, vmin=vmin, vmax=vmax)
    axes[0, 0].set_title("A. NIMBY benchmark: support by income state and age")
    axes[0, 0].set_xticks(range(len(ages)))
    axes[0, 0].set_xticklabels(ages, rotation=45)
    axes[0, 0].set_yticks(range(income_n.shape[0]))
    axes[0, 0].set_yticklabels(range(1, income_n.shape[0] + 1))
    axes[0, 0].set_xlabel("Age")
    axes[0, 0].set_ylabel("Income state")

    axes[0, 1].imshow(income_f, aspect="auto", origin="lower", cmap=cmap, vmin=vmin, vmax=vmax)
    axes[0, 1].set_title("B. Fertility benchmark: support by income state and age")
    axes[0, 1].set_xticks(range(len(ages)))
    axes[0, 1].set_xticklabels(ages, rotation=45)
    axes[0, 1].set_yticks(range(income_f.shape[0]))
    axes[0, 1].set_yticklabels(range(1, income_f.shape[0] + 1))
    axes[0, 1].set_xlabel("Age")
    axes[0, 1].set_ylabel("Income state")

    axes[1, 0].imshow(housing_n, aspect="auto", origin="lower", cmap=cmap, vmin=vmin, vmax=vmax)
    axes[1, 0].set_title("C. NIMBY benchmark: support by housing rank and age")
    axes[1, 0].set_xticks(range(len(ages)))
    axes[1, 0].set_xticklabels(ages, rotation=45)
    axes[1, 0].set_yticks(range(housing_n.shape[0]))
    axes[1, 0].set_yticklabels(["Low", "2", "3", "4", "High"])
    axes[1, 0].set_xlabel("Age")
    axes[1, 0].set_ylabel("Housing rank")

    axes[1, 1].imshow(housing_f, aspect="auto", origin="lower", cmap=cmap, vmin=vmin, vmax=vmax)
    axes[1, 1].set_title("D. Fertility benchmark: support by housing rank and age")
    axes[1, 1].set_xticks(range(len(ages)))
    axes[1, 1].set_xticklabels(ages, rotation=45)
    axes[1, 1].set_yticks(range(housing_f.shape[0]))
    axes[1, 1].set_yticklabels(["Low", "2", "3", "4", "High"])
    axes[1, 1].set_xlabel("Age")
    axes[1, 1].set_ylabel("Housing rank")

    axes[2, 0].plot(ages, age_support_n, color="#111111", lw=2.2, marker="o", label="NIMBY benchmark")
    axes[2, 0].plot(ages, age_support_f, color="#b24c2a", lw=2.2, marker="o", label="Fertility benchmark")
    axes[2, 0].axhline(0.5, color="#666666", lw=1.0, ls="--")
    axes[2, 0].set_title("E. Average support for higher house prices by age")
    axes[2, 0].set_xlabel("Age")
    axes[2, 0].set_ylabel("Support share")
    axes[2, 0].set_ylim(0, 1)
    axes[2, 0].legend(frameon=False, loc="best")

    axes[2, 1].plot(ages, birth_rate, color="#b24c2a", lw=2.2, marker="o", label="Birth rate")
    axes[2, 1].plot(ages, any_home, color="#275d8c", lw=2.0, marker="s", label="Any child at home")
    axes[2, 1].plot(ages, mean_home, color="#3c7d3c", lw=2.0, marker="^", label="Mean children at home")
    axes[2, 1].set_title("F. Fertility benchmark: age profiles of family states")
    axes[2, 1].set_xlabel("Age")
    axes[2, 1].set_ylabel("Rate / share / count")
    axes[2, 1].legend(frameon=False, loc="best")

    cbar = fig.colorbar(im, ax=axes[:2, :], shrink=0.82, location="right")
    cbar.set_label("Share supporting higher house prices")
    fig.suptitle("Household support for higher house prices", fontsize=14, fontweight="bold")

    fig.savefig(BUILD / "nimby_vs_fertility_household_support.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_household_support.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_benchmark_figure() -> None:
    common = pd.read_csv(BUILD / "fertility_vs_nimby_common_price_grid.csv")
    summary = pd.read_csv(BUILD / "fertility_vs_nimby_benchmark_summary.csv")

    nimby = summary.loc[summary["model"] == "nimby"].iloc[0]
    fertility = summary.loc[summary["model"] == "fertility"].iloc[0]

    fig, axes = plt.subplots(2, 2, figsize=(11, 8.6), constrained_layout=True)
    c_nimby = "#111111"
    c_fertility = "#b24c2a"
    c_blue = "#275d8c"
    c_green = "#3c7d3c"
    c_gold = "#b48a00"
    c_purple = "#6c5b7b"
    c_gray = "#666666"

    ax = axes[0, 0]
    ax.plot(common["a_price"], common["nimby_vote"], color=c_nimby, lw=2.2, marker="o", label="NIMBY benchmark")
    ax.plot(common["a_price"], common["fertility_vote"], color=c_fertility, lw=2.2, marker="o", label="Fertility benchmark")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.axvline(nimby["refined_price"], color=c_nimby, lw=1.0, ls=":")
    ax.axvline(fertility["refined_price"], color=c_fertility, lw=1.0, ls=":")
    ax.set_title("A. Raw political support across the common price grid")
    ax.set_xlabel("House price")
    ax.set_ylabel("Raw support")
    ax.legend(frameon=False, loc="best")

    ax = axes[0, 1]
    ax.plot(common["a_price"], common["nimby_vote_per_mass"], color=c_nimby, lw=2.2, marker="o", label="NIMBY benchmark")
    ax.plot(common["a_price"], common["fertility_vote_per_mass"], color=c_fertility, lw=2.2, marker="o", label="Fertility benchmark")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.axvline(nimby["refined_price"], color=c_nimby, lw=1.0, ls=":")
    ax.axvline(fertility["refined_price"], color=c_fertility, lw=1.0, ls=":")
    ax.set_title("B. Support per unit mass")
    ax.set_xlabel("House price")
    ax.set_ylabel("Support / mass")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 0]
    ax.plot(common["a_price"], common["fertility_birth_rate"], color=c_fertility, lw=2.4, marker="o", label="Birth rate")
    ax.plot(common["a_price"], common["fertility_home_any_40"], color=c_blue, lw=2.0, marker="s", label="Any child at home, age 40")
    ax.plot(common["a_price"], common["fertility_home_any_50"], color=c_green, lw=2.0, marker="^", label="Any child at home, age 50")
    ax.set_title("C. Family-state objects across the common price grid")
    ax.set_xlabel("House price")
    ax.set_ylabel("Rate / share")
    ax.set_ylim(0, 1)
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    ax.plot(common["a_price"], common["fertility_parity_0"], color=c_blue, lw=2.1, marker="o", label="0 children")
    ax.plot(common["a_price"], common["fertility_parity_1"], color=c_green, lw=2.1, marker="s", label="1 child")
    ax.plot(common["a_price"], common["fertility_parity_2"], color=c_gold, lw=2.1, marker="^", label="2 children")
    ax.plot(common["a_price"], common["fertility_parity_3plus"], color=c_purple, lw=2.1, marker="d", label="3+ children")
    ax.set_title("D. Completed fertility at age 50")
    ax.set_xlabel("House price")
    ax.set_ylabel("Share")
    ax.set_ylim(0, 1)
    ax.legend(frameon=False, loc="best", ncol=2)

    fig.suptitle("Steady-state benchmark comparison", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_benchmark_objects.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_benchmark_objects.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_first_birth_timing_figure() -> None:
    common = pd.read_csv(BUILD / "fertility_vs_nimby_common_price_grid.csv")
    profiles = pd.read_csv(BUILD / "fertility_first_birth_timing_profiles.csv")
    summary = pd.read_csv(BUILD / "fertility_vs_nimby_benchmark_summary.csv")

    fert = summary.loc[summary["model"] == "fertility"].iloc[0]
    benchmark_price = float(fert["refined_price"])

    fig, axes = plt.subplots(2, 2, figsize=(11, 8.8), constrained_layout=True)
    palette = ["#275d8c", "#3c7d3c", "#b48a00", "#b24c2a"]
    selected_prices = sorted(profiles["a_price"].unique())

    ax = axes[0, 0]
    for color, price in zip(palette, selected_prices):
        subset = profiles.loc[np.isclose(profiles["a_price"], price)].copy()
        subset = subset[np.isfinite(subset["first_birth_hazard"])]
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
        common["a_price"],
        common["fertility_mean_age_first_birth"],
        color="#b24c2a",
        lw=2.4,
        marker="o",
        label="Mean age",
    )
    ax.plot(
        common["a_price"],
        common["fertility_median_age_first_birth"],
        color="#275d8c",
        lw=2.0,
        marker="s",
        ls="--",
        label="Median age",
    )
    ax.axvline(benchmark_price, color="#666666", lw=1.0, ls=":")
    ax.set_title("B. Age at first birth rises with house prices")
    ax.set_xlabel("House price")
    ax.set_ylabel("Age")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 0]
    ax.plot(
        common["a_price"],
        common["fertility_share_first_birth_30_plus"],
        color="#3c7d3c",
        lw=2.4,
        marker="o",
    )
    ax.axvline(benchmark_price, color="#666666", lw=1.0, ls=":")
    ax.set_title("C. Older first births become more common")
    ax.set_xlabel("House price")
    ax.set_ylabel("Share of first births at age 30+")
    ax.set_ylim(0, 1)

    ax = axes[1, 1]
    ax.plot(
        common["a_price"],
        common["fertility_first_birth_rate"],
        color="#b24c2a",
        lw=2.4,
        marker="o",
        label="First-birth rate",
    )
    ax.plot(
        common["a_price"],
        common["fertility_birth_rate"],
        color="#275d8c",
        lw=2.0,
        marker="s",
        ls="--",
        label="All-birth rate",
    )
    ax.axvline(benchmark_price, color="#666666", lw=1.0, ls=":")
    ax.set_title("D. Delay comes with fewer first births")
    ax.set_xlabel("House price")
    ax.set_ylabel("Rate")
    ax.legend(frameon=False, loc="best")

    fig.suptitle("First-birth timing in the fertility benchmark", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_first_birth_timing.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_first_birth_timing.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    plot_household_support_figure()
    plot_benchmark_figure()
    plot_first_birth_timing_figure()


if __name__ == "__main__":
    main()
