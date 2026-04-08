from __future__ import annotations

from dataclasses import replace
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from nimby_fertility_transition_bridge import (
    BridgeParams,
    simulate_persistent_nimby_shock_transition,
    simulate_projection_nimby_shock,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

SHOCK_LABEL = "persistent_theta0_plus_0p05"


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


def build_summary(
    transition_base: pd.DataFrame,
    transition_shock: pd.DataFrame,
    projection_base: pd.DataFrame,
    projection_shock: pd.DataFrame,
) -> pd.DataFrame:
    rows: list[dict[str, float | str]] = []
    for horizon in (10, 20, 40, 79):
        base_row = transition_base.loc[transition_base["t"] == horizon].iloc[0]
        shock_row = transition_shock.loc[transition_shock["t"] == horizon].iloc[0]
        rows.append(
            {
                "block": "transition",
                "scenario": "stylized_transition",
                "horizon": horizon,
                "base_price_index": float(base_row["price_index"]),
                "shock_price_index": float(shock_row["price_index"]),
                "price_gap": float(shock_row["price_index"] - base_row["price_index"]),
                "base_fertility_rate": float(base_row["fertility_rate"]),
                "shock_fertility_rate": float(shock_row["fertility_rate"]),
                "fertility_gap": float(shock_row["fertility_rate"] - base_row["fertility_rate"]),
            }
        )

    for scenario, group in projection_base.groupby("scenario", sort=False):
        shock_group = projection_shock[projection_shock["scenario"] == scenario]
        for year in (2050, 2100):
            base_row = group.loc[group["year"] == year].iloc[0]
            shock_row = shock_group.loc[shock_group["year"] == year].iloc[0]
            rows.append(
                {
                    "block": "projection",
                    "scenario": scenario,
                    "horizon": int(year),
                    "base_price_index": float(base_row["price_index"]),
                    "shock_price_index": float(shock_row["price_index"]),
                    "price_gap": float(shock_row["price_index"] - base_row["price_index"]),
                    "base_fertility_rate": float(base_row["fertility_rate"]),
                    "shock_fertility_rate": float(shock_row["fertility_rate"]),
                    "fertility_gap": float(shock_row["fertility_rate"] - base_row["fertility_rate"]),
                }
            )
    return pd.DataFrame(rows)


def write_note(summary: pd.DataFrame) -> None:
    medium_2050 = summary[
        (summary["block"] == "projection")
        & (summary["scenario"] == "medium_immigration")
        & (summary["horizon"] == 2050)
    ].iloc[0]
    medium_2100 = summary[
        (summary["block"] == "projection")
        & (summary["scenario"] == "medium_immigration")
        & (summary["horizon"] == 2100)
    ].iloc[0]
    transition_40 = summary[
        (summary["block"] == "transition") & (summary["scenario"] == "stylized_transition") & (summary["horizon"] == 40)
    ].iloc[0]
    transition_79 = summary[
        (summary["block"] == "transition") & (summary["scenario"] == "stylized_transition") & (summary["horizon"] == 79)
    ].iloc[0]

    lines = [
        "# Persistent NIMBY shock and fertility",
        "",
        "This note studies a simple supply-tightening counterfactual in the fertility model.",
        "The shock is a permanent increase in baseline political tightness, implemented as",
        "`theta0 + 0.05` from the first post-baseline period onward.",
        "",
        "## Stylized transition read",
        "",
        f"- At horizon `t = 40`, the house-price index is `{transition_40['shock_price_index']:.3f}` under the NIMBY shock versus `{transition_40['base_price_index']:.3f}` in baseline.",
        f"- At horizon `t = 40`, the fertility rate is `{transition_40['shock_fertility_rate']:.3f}` under the NIMBY shock versus `{transition_40['base_fertility_rate']:.3f}` in baseline.",
        f"- At horizon `t = 79`, the house-price index is `{transition_79['shock_price_index']:.3f}` under the NIMBY shock versus `{transition_79['base_price_index']:.3f}` in baseline.",
        f"- At horizon `t = 79`, the fertility rate is `{transition_79['shock_fertility_rate']:.3f}` under the NIMBY shock versus `{transition_79['base_fertility_rate']:.3f}` in baseline.",
        "",
        "## Medium-immigration projection read",
        "",
        f"- In `2050`, the projected house-price index is `{medium_2050['shock_price_index']:.3f}` under the NIMBY shock versus `{medium_2050['base_price_index']:.3f}` in baseline.",
        f"- In `2050`, the projected fertility rate is `{medium_2050['shock_fertility_rate']:.3f}` under the NIMBY shock versus `{medium_2050['base_fertility_rate']:.3f}` in baseline.",
        f"- In `2100`, the projected house-price index is `{medium_2100['shock_price_index']:.3f}` under the NIMBY shock versus `{medium_2100['base_price_index']:.3f}` in baseline.",
        f"- In `2100`, the projected fertility rate is `{medium_2100['shock_fertility_rate']:.3f}` under the NIMBY shock versus `{medium_2100['base_fertility_rate']:.3f}` in baseline.",
        "",
        "## Interpretation",
        "",
        "- A persistent NIMBY shift raises housing pressure and lowers fertility over time.",
        "- Unlike the earlier aging bridge, this object directly answers the mechanism question:",
        "  if housing remains too tight for a long time, realized fertility falls.",
        "- The projection remains a bridge rather than a full forecast solver, but the shared-2020",
        "  starting point makes it informative about the sign and magnitude of a persistent NIMBY shift.",
        "",
    ]
    (BUILD / "nimby_shock_fertility_counterfactual.md").write_text("\n".join(lines), encoding="utf-8")


def plot(
    transition_base: pd.DataFrame,
    transition_shock: pd.DataFrame,
    projection_base: pd.DataFrame,
    projection_shock: pd.DataFrame,
) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(12.5, 8.0), constrained_layout=True)
    c_base = "#111111"
    c_shock = "#b24c2a"

    ax = axes[0, 0]
    ax.plot(transition_base["t"], transition_base["price_index"], color=c_base, lw=2.1, label="Baseline")
    ax.plot(transition_shock["t"], transition_shock["price_index"], color=c_shock, lw=2.1, label="NIMBY shock")
    ax.axvline(1, color="#777777", lw=1.0, ls="--")
    ax.set_title("A. Stylized transition: house prices")
    ax.set_xlabel("Model period")
    ax.set_ylabel("House-price index")
    ax.legend(frameon=False, loc="best")

    ax = axes[0, 1]
    ax.plot(transition_base["t"], transition_base["fertility_rate"], color=c_base, lw=2.1, label="Baseline")
    ax.plot(transition_shock["t"], transition_shock["fertility_rate"], color=c_shock, lw=2.1, label="NIMBY shock")
    ax.axvline(1, color="#777777", lw=1.0, ls="--")
    ax.set_title("B. Stylized transition: fertility")
    ax.set_xlabel("Model period")
    ax.set_ylabel("Fertility rate")
    ax.legend(frameon=False, loc="best")

    medium_base = projection_base[projection_base["scenario"] == "medium_immigration"].sort_values("year")
    medium_shock = projection_shock[projection_shock["scenario"] == "medium_immigration"].sort_values("year")

    ax = axes[1, 0]
    ax.plot(medium_base["year"], medium_base["price_index"], color=c_base, lw=2.1, label="Baseline")
    ax.plot(medium_shock["year"], medium_shock["price_index"], color=c_shock, lw=2.1, label="NIMBY shock")
    ax.axvline(2020, color="#777777", lw=1.0, ls="--")
    ax.set_title("C. Medium-immigration projection: house prices")
    ax.set_xlabel("Year")
    ax.set_ylabel("House-price index")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    ax.plot(medium_base["year"], medium_base["fertility_rate"], color=c_base, lw=2.1, label="Baseline")
    ax.plot(medium_shock["year"], medium_shock["fertility_rate"], color=c_shock, lw=2.1, label="NIMBY shock")
    ax.axvline(2020, color="#777777", lw=1.0, ls="--")
    ax.set_title("D. Medium-immigration projection: fertility")
    ax.set_xlabel("Year")
    ax.set_ylabel("Fertility rate")
    ax.legend(frameon=False, loc="best")

    fig.suptitle("Persistent NIMBY shock: housing pressure and fertility", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_shock_fertility_counterfactual.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_shock_fertility_counterfactual.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    base_params = BridgeParams()
    shock_params = replace(base_params, theta0=base_params.theta0 + 0.05)

    transition_base, transition_shock = simulate_persistent_nimby_shock_transition(
        base_params, shock_params, shock_start=1
    )
    transition_base["price_index"] = np.exp(transition_base["price"] - float(transition_base["price"].iloc[0]))
    transition_shock["price_index"] = np.exp(transition_shock["price"] - float(transition_shock["price"].iloc[0]))
    transition_base["case"] = "baseline"
    transition_shock["case"] = SHOCK_LABEL
    transition = pd.concat([transition_base, transition_shock], ignore_index=True)
    transition.to_csv(BUILD / "nimby_shock_transition_series.csv", index=False)

    age_path = pd.read_csv(BUILD / "nimby_projection_age_groups_all_scenarios.csv")
    projection_base, projection_shock = simulate_projection_nimby_shock(
        age_path, base_params, shock_params, mode="fertility", shock_start_year=2021
    )
    projection_base["case"] = "baseline"
    projection_shock["case"] = SHOCK_LABEL
    projection = pd.concat([projection_base, projection_shock], ignore_index=True)
    projection.to_csv(BUILD / "nimby_shock_projection_series.csv", index=False)

    summary = build_summary(transition_base, transition_shock, projection_base, projection_shock)
    summary.to_csv(BUILD / "nimby_shock_fertility_counterfactual_summary.csv", index=False)
    write_note(summary)
    plot(transition_base, transition_shock, projection_base, projection_shock)


if __name__ == "__main__":
    main()
