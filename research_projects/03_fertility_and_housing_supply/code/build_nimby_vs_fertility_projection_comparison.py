from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

from nimby_fertility_transition_bridge import BridgeParams, simulate_projection_bridge


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


def set_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titleweight": "bold",
            "axes.titlesize": 10.5,
            "axes.labelsize": 9.5,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 8.5,
        }
    )


def build_summary(nimby: pd.DataFrame, fertility: pd.DataFrame) -> pd.DataFrame:
    merged = nimby[["year", "scenario", "price_index"]].merge(
        fertility[["year", "scenario", "price_index", "fertility_rate", "young_homeownership_proxy"]],
        on=["year", "scenario"],
        how="inner",
        suffixes=("_nimby", "_fertility"),
    )
    merged["price_gap"] = merged["price_index_fertility"] - merged["price_index_nimby"]

    rows = []
    for scenario, group in merged.groupby("scenario", sort=False):
        row = {"scenario": scenario}
        for year in (2050, 2100):
            g = group[group["year"] == year].iloc[0]
            row[f"nimby_price_index_{year}"] = float(g["price_index_nimby"])
            row[f"fertility_price_index_{year}"] = float(g["price_index_fertility"])
            row[f"price_gap_{year}"] = float(g["price_gap"])
        row["fertility_rate_2050"] = float(group[group["year"] == 2050]["fertility_rate"].iloc[0])
        row["fertility_rate_2100"] = float(group[group["year"] == 2100]["fertility_rate"].iloc[0])
        row["young_homeownership_proxy_2050"] = float(group[group["year"] == 2050]["young_homeownership_proxy"].iloc[0])
        row["young_homeownership_proxy_2100"] = float(group[group["year"] == 2100]["young_homeownership_proxy"].iloc[0])
        rows.append(row)
    return pd.DataFrame(rows)


def write_note(summary: pd.DataFrame) -> None:
    medium = summary[summary["scenario"] == "medium_immigration"].iloc[0]
    lines = [
        "# Future demographic projection comparison",
        "",
        "This note compares a NIMBY proxy and a fertility bridge built on the same projected age",
        "weights. Both sides are bridge objects driven by the upstream forecast age shares. The",
        "NIMBY side shuts off the fertility-demand channel, while the",
        "fertility side keeps births and children-at-home in the demand block.",
        "",
        "## Medium-immigration read",
        "",
        f"- NIMBY price index in 2050: `{medium['nimby_price_index_2050']:.3f}`",
        f"- Fertility price index in 2050: `{medium['fertility_price_index_2050']:.3f}`",
        f"- NIMBY price index in 2100: `{medium['nimby_price_index_2100']:.3f}`",
        f"- Fertility price index in 2100: `{medium['fertility_price_index_2100']:.3f}`",
        f"- Fertility-side young-homeownership proxy in 2100: `{medium['young_homeownership_proxy_2100']:.3f}`",
        "",
        "## Scope note",
        "",
        "- This is a projection bridge, not a unified forecast solver.",
        "- It is still informative about whether the fertility channel amplifies or dampens the",
        "  price effects of projected aging under the same demographic scenarios.",
        "",
    ]
    (BUILD / "nimby_vs_fertility_projection_comparison.md").write_text("\n".join(lines), encoding="utf-8")


def plot(nimby: pd.DataFrame, fertility: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(12.5, 8.0), constrained_layout=True)
    c_nimby = "#111111"
    c_fertility = "#b24c2a"
    scenario_meta = [
        ("low_immigration", "A. Low immigration"),
        ("medium_immigration", "B. Medium immigration"),
        ("high_immigration", "C. High immigration"),
    ]

    for ax, (scenario, title) in zip(axes.flat[:3], scenario_meta):
        nimby_s = nimby[nimby["scenario"] == scenario].sort_values("year")
        fertility_s = fertility[fertility["scenario"] == scenario].sort_values("year")
        ax.plot(nimby_s["year"], nimby_s["price_index"], color=c_nimby, lw=2.1, label="NIMBY proxy")
        ax.plot(fertility_s["year"], fertility_s["price_index"], color=c_fertility, lw=2.1, label="Fertility bridge")
        ax.axvline(2020, color="#777777", lw=1.0, ls="--")
        ax.set_title(title)
        ax.set_xlabel("Year")
        ax.set_ylabel("House-price index")
        ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    medium = fertility[fertility["scenario"] == "medium_immigration"].sort_values("year")
    fert_rate_index = medium["fertility_rate"] / float(medium["fertility_rate"].iloc[0])
    young_access_index = medium["young_homeownership_proxy"] / float(medium["young_homeownership_proxy"].iloc[0])
    ax.plot(medium["year"], fert_rate_index, color=c_fertility, lw=2.1, label="Fertility-rate index")
    ax.plot(medium["year"], young_access_index, color="#275d8c", lw=2.0, ls="--", label="Young access proxy")
    ax.axvline(2020, color="#777777", lw=1.0, ls="--")
    ax.set_title("D. Medium-scenario family outcomes")
    ax.set_xlabel("Year")
    ax.set_ylabel("Index")
    ax.legend(frameon=False, loc="best")

    fig.suptitle("Future demographic projections: NIMBY versus fertility bridge", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_projection_comparison.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_projection_comparison.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    age_path = pd.read_csv(BUILD / "nimby_projection_age_groups_all_scenarios.csv")
    nimby = simulate_projection_bridge(age_path, BridgeParams(), mode="nimby_proxy")
    fertility = simulate_projection_bridge(age_path, BridgeParams(), mode="fertility")
    nimby.to_csv(BUILD / "nimby_projection_bridge.csv", index=False)
    fertility.to_csv(BUILD / "nimby_vs_fertility_projection_bridge.csv", index=False)
    summary = build_summary(nimby, fertility)
    summary.to_csv(BUILD / "nimby_vs_fertility_projection_summary.csv", index=False)
    write_note(summary)
    plot(nimby, fertility)


if __name__ == "__main__":
    main()
