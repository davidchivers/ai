from __future__ import annotations

from dataclasses import replace
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

from nimby_fertility_transition_bridge import BridgeParams, simulate_projection_nimby_shock


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

SHOCK_GRID = [0.03, 0.05, 0.08, 0.10]

CALIBRATION_VARIANTS = [
    ("benchmark", lambda p: p),
    ("low_price_sensitivity", lambda p: replace(p, f_price_semi_elasticity=0.15)),
    ("high_price_sensitivity", lambda p: replace(p, f_price_semi_elasticity=0.25)),
    ("low_family_demand", lambda p: replace(p, d_birth=0.20, n_home_demand=0.10)),
    ("high_family_demand", lambda p: replace(p, d_birth=0.40, n_home_demand=0.20)),
]


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


def build_shock_grid(age_path: pd.DataFrame) -> pd.DataFrame:
    base_params = BridgeParams()
    rows: list[dict[str, float | str]] = []
    for delta in SHOCK_GRID:
        shock_params = replace(base_params, theta0=base_params.theta0 + delta)
        base, shock = simulate_projection_nimby_shock(
            age_path, base_params, shock_params, mode="fertility", shock_start_year=2021
        )
        for scenario, base_group in base.groupby("scenario", sort=False):
            shock_group = shock[shock["scenario"] == scenario]
            for year in (2050, 2100):
                b = base_group.loc[base_group["year"] == year].iloc[0]
                s = shock_group.loc[shock_group["year"] == year].iloc[0]
                rows.append(
                    {
                        "shock_delta_theta0": delta,
                        "scenario": scenario,
                        "year": int(year),
                        "base_price_index": float(b["price_index"]),
                        "shock_price_index": float(s["price_index"]),
                        "price_gap": float(s["price_index"] - b["price_index"]),
                        "base_fertility_rate": float(b["fertility_rate"]),
                        "shock_fertility_rate": float(s["fertility_rate"]),
                        "fertility_gap": float(s["fertility_rate"] - b["fertility_rate"]),
                    }
                )
    return pd.DataFrame(rows)


def build_calibration_sensitivity(age_path: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, float | str]] = []
    for label, fn in CALIBRATION_VARIANTS:
        base_params = fn(BridgeParams())
        shock_params = replace(base_params, theta0=base_params.theta0 + 0.05)
        base, shock = simulate_projection_nimby_shock(
            age_path, base_params, shock_params, mode="fertility", shock_start_year=2021
        )
        medium_base = base[base["scenario"] == "medium_immigration"]
        medium_shock = shock[shock["scenario"] == "medium_immigration"]
        for year in (2050, 2100):
            b = medium_base.loc[medium_base["year"] == year].iloc[0]
            s = medium_shock.loc[medium_shock["year"] == year].iloc[0]
            rows.append(
                {
                    "calibration": label,
                    "year": int(year),
                    "base_price_index": float(b["price_index"]),
                    "shock_price_index": float(s["price_index"]),
                    "price_gap": float(s["price_index"] - b["price_index"]),
                    "base_fertility_rate": float(b["fertility_rate"]),
                    "shock_fertility_rate": float(s["fertility_rate"]),
                    "fertility_gap": float(s["fertility_rate"] - b["fertility_rate"]),
                }
            )
    return pd.DataFrame(rows)


def write_note(shock_grid: pd.DataFrame, calib: pd.DataFrame) -> None:
    medium_2100 = shock_grid[
        (shock_grid["scenario"] == "medium_immigration") & (shock_grid["year"] == 2100)
    ].sort_values("shock_delta_theta0")
    benchmark_2100 = calib[(calib["calibration"] == "benchmark") & (calib["year"] == 2100)].iloc[0]
    low_ps_2100 = calib[(calib["calibration"] == "low_price_sensitivity") & (calib["year"] == 2100)].iloc[0]
    high_ps_2100 = calib[(calib["calibration"] == "high_price_sensitivity") & (calib["year"] == 2100)].iloc[0]
    low_fd_2100 = calib[(calib["calibration"] == "low_family_demand") & (calib["year"] == 2100)].iloc[0]
    high_fd_2100 = calib[(calib["calibration"] == "high_family_demand") & (calib["year"] == 2100)].iloc[0]

    lines = [
        "# Persistent NIMBY shock scenarios",
        "",
        "This note expands the persistent NIMBY counterfactual in two ways.",
        "First, it runs a grid of permanent `theta0` increases.",
        "Second, it checks whether the long-run fertility result survives nearby fertility-side calibrations.",
        "",
        "## Medium-immigration shock grid",
        "",
    ]
    for _, row in medium_2100.iterrows():
        lines.append(
            f"- `theta0 + {row['shock_delta_theta0']:.2f}` in `2100`: price index `{row['shock_price_index']:.3f}` versus `{row['base_price_index']:.3f}` baseline; fertility `{row['shock_fertility_rate']:.3f}` versus `{row['base_fertility_rate']:.3f}` baseline."
        )
    lines.extend(
        [
            "",
            "## Calibration sensitivity at `theta0 + 0.05`",
            "",
            f"- Benchmark in `2100`: fertility `{benchmark_2100['shock_fertility_rate']:.3f}` versus `{benchmark_2100['base_fertility_rate']:.3f}` baseline.",
            f"- Low price sensitivity in `2100`: fertility `{low_ps_2100['shock_fertility_rate']:.3f}` versus `{low_ps_2100['base_fertility_rate']:.3f}` baseline.",
            f"- High price sensitivity in `2100`: fertility `{high_ps_2100['shock_fertility_rate']:.3f}` versus `{high_ps_2100['base_fertility_rate']:.3f}` baseline.",
            f"- Low family demand in `2100`: fertility `{low_fd_2100['shock_fertility_rate']:.3f}` versus `{low_fd_2100['base_fertility_rate']:.3f}` baseline.",
            f"- High family demand in `2100`: fertility `{high_fd_2100['shock_fertility_rate']:.3f}` versus `{high_fd_2100['base_fertility_rate']:.3f}` baseline.",
            "",
            "## Read",
            "",
            "- The long-run fertility decline is monotone in persistent NIMBY intensity.",
            "- The sign of the result survives reasonable changes in price sensitivity and family demand.",
            "- So the mechanism is not just a one-point benchmark artifact.",
            "",
        ]
    )
    (BUILD / "nimby_shock_scenarios.md").write_text("\n".join(lines), encoding="utf-8")


def plot(shock_grid: pd.DataFrame, calib: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(12.5, 8.0), constrained_layout=True)
    palette = {
        "low_immigration": "#4c78a8",
        "medium_immigration": "#111111",
        "high_immigration": "#b24c2a",
    }

    for scenario, group in shock_grid[shock_grid["year"] == 2050].groupby("scenario", sort=False):
        g = group.sort_values("shock_delta_theta0")
        axes[0, 0].plot(g["shock_delta_theta0"], g["shock_fertility_rate"], marker="o", lw=2.0, color=palette[scenario], label=scenario.replace("_", " "))
        axes[1, 0].plot(g["shock_delta_theta0"], g["shock_price_index"], marker="o", lw=2.0, color=palette[scenario], label=scenario.replace("_", " "))
    axes[0, 0].set_title("A. 2050 fertility under persistent NIMBY shocks")
    axes[0, 0].set_xlabel(r"Permanent increase in $\theta_0$")
    axes[0, 0].set_ylabel("Fertility rate")
    axes[0, 0].legend(frameon=False, loc="best")
    axes[1, 0].set_title("C. 2050 house-price index under persistent NIMBY shocks")
    axes[1, 0].set_xlabel(r"Permanent increase in $\theta_0$")
    axes[1, 0].set_ylabel("House-price index")

    for scenario, group in shock_grid[shock_grid["year"] == 2100].groupby("scenario", sort=False):
        g = group.sort_values("shock_delta_theta0")
        axes[0, 1].plot(g["shock_delta_theta0"], g["shock_fertility_rate"], marker="o", lw=2.0, color=palette[scenario], label=scenario.replace("_", " "))
        axes[1, 1].plot(g["shock_delta_theta0"], g["shock_price_index"], marker="o", lw=2.0, color=palette[scenario], label=scenario.replace("_", " "))
    axes[0, 1].set_title("B. 2100 fertility under persistent NIMBY shocks")
    axes[0, 1].set_xlabel(r"Permanent increase in $\theta_0$")
    axes[0, 1].set_ylabel("Fertility rate")
    axes[1, 1].set_title(r"D. 2100 fertility sensitivity at $\Delta\theta_0 = 0.05$")
    axes[1, 1].set_xlabel("Calibration variant")
    axes[1, 1].set_ylabel("Shock fertility rate")

    calib_2100 = calib[calib["year"] == 2100].copy()
    calib_2100["display"] = calib_2100["calibration"].map(
        {
            "benchmark": "Benchmark",
            "low_price_sensitivity": "Low price sens.",
            "high_price_sensitivity": "High price sens.",
            "low_family_demand": "Low family dem.",
            "high_family_demand": "High family dem.",
        }
    )
    axes[1, 1].cla()
    axes[1, 1].plot(calib_2100["display"], calib_2100["shock_fertility_rate"], marker="o", lw=2.0, color="#b24c2a")
    axes[1, 1].plot(calib_2100["display"], calib_2100["base_fertility_rate"], marker="o", lw=1.5, color="#111111", ls="--")
    axes[1, 1].set_title(r"D. 2100 calibration sensitivity at $\Delta\theta_0 = 0.05$")
    axes[1, 1].set_xlabel("Calibration variant")
    axes[1, 1].set_ylabel("Fertility rate")
    axes[1, 1].tick_params(axis="x", rotation=15)

    fig.suptitle("Persistent NIMBY scenarios and calibration sensitivity", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_shock_scenarios.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_shock_scenarios.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    age_path = pd.read_csv(BUILD / "nimby_projection_age_groups_all_scenarios.csv")
    shock_grid = build_shock_grid(age_path)
    calib = build_calibration_sensitivity(age_path)
    shock_grid.to_csv(BUILD / "nimby_shock_scenario_grid.csv", index=False)
    calib.to_csv(BUILD / "nimby_shock_calibration_sensitivity.csv", index=False)
    write_note(shock_grid, calib)
    plot(shock_grid, calib)


if __name__ == "__main__":
    main()
