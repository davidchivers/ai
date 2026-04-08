from __future__ import annotations

from dataclasses import replace
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from nimby_fertility_transition_bridge import BridgeParams, simulate_baby_boom, summarize_transition


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


def replication_error(reference: pd.DataFrame, candidate: pd.DataFrame, columns: list[str]) -> float:
    common = reference.loc[:, columns].to_numpy(dtype=float) - candidate.loc[:, columns].to_numpy(dtype=float)
    return float(np.nanmax(np.abs(common)))


def run_sweep() -> tuple[pd.DataFrame, pd.DataFrame]:
    params = BridgeParams()
    rows: list[dict[str, float | str]] = []

    sweep_specs = [
        ("shock_size", [0.10, 0.20, 0.30]),
        ("price_fertility_semi_elasticity", [0.10, 0.20, 0.30]),
        ("family_demand_scale", [0.50, 1.00, 1.50]),
    ]

    for sweep_name, values in sweep_specs:
        for value in values:
            scenario_params = params
            boom_amp = 0.10

            if sweep_name == "shock_size":
                boom_amp = float(value)
            elif sweep_name == "price_fertility_semi_elasticity":
                scenario_params = replace(params, f_price_semi_elasticity=float(value))
            elif sweep_name == "family_demand_scale":
                scenario_params = replace(
                    params,
                    d_birth=params.d_birth * float(value),
                    n_home_demand=params.n_home_demand * float(value),
                )

            fert_base = simulate_baby_boom(scenario_params, mode="fertility", boom_amp=0.0)
            fert_shock = simulate_baby_boom(scenario_params, mode="fertility", boom_amp=boom_amp)
            old_base = simulate_baby_boom(scenario_params, mode="old_proxy", boom_amp=0.0)
            old_shock = simulate_baby_boom(scenario_params, mode="old_proxy", boom_amp=boom_amp)

            fert_summary = summarize_transition(fert_base, fert_shock)
            old_summary = summarize_transition(old_base, old_shock)

            rows.append(
                {
                    "sweep": sweep_name,
                    "value": float(value),
                    "model": "fertility_extension",
                    **fert_summary,
                }
            )
            rows.append(
                {
                    "sweep": sweep_name,
                    "value": float(value),
                    "model": "nimby_proxy",
                    **old_summary,
                }
            )

    summary = pd.DataFrame(rows)

    ref_new = pd.read_csv(BUILD / "comparison_new_policy.csv")
    ref_old = pd.read_csv(BUILD / "comparison_old_policy.csv")
    baseline_fert = simulate_baby_boom(params, mode="fertility", boom_amp=0.10)
    baseline_old = simulate_baby_boom(params, mode="old_proxy", boom_amp=0.10)

    checks = pd.DataFrame(
        [
            {
                "check": "python_bridge_matches_matlab_fertility_policy",
                "max_abs_error": replication_error(
                    ref_new,
                    baseline_fert,
                    ["price", "births", "fertility_rate", "young_share", "old_share", "theta", "average_age", "n_home"],
                ),
            },
            {
                "check": "python_bridge_matches_matlab_old_proxy_policy",
                "max_abs_error": replication_error(
                    ref_old,
                    baseline_old,
                    ["price", "births", "fertility_rate", "young_share", "old_share", "theta", "average_age", "n_home"],
                ),
            },
        ]
    )

    return summary, checks


def write_note(summary: pd.DataFrame, checks: pd.DataFrame) -> None:
    lines = [
        "# Baby-boom transition robustness",
        "",
        "This note runs a bounded robustness sweep around the current project-03 transition bridge.",
        "The direct upstream NIMBY IRF is available only for the benchmark `+10%` shock, so the",
        "robustness pass uses the in-project NIMBY proxy and fertility extension under matched",
        "parameter changes.",
        "",
        "## Replication check",
        "",
        f"- Fertility bridge max absolute error against MATLAB benchmark policy run: `{checks.loc[0, 'max_abs_error']:.3e}`",
        f"- NIMBY-proxy bridge max absolute error against MATLAB benchmark policy run: `{checks.loc[1, 'max_abs_error']:.3e}`",
        "",
        "## Main read",
        "",
    ]

    for sweep_name, label in [
        ("shock_size", "Shock size"),
        ("price_fertility_semi_elasticity", "Price-fertility sensitivity"),
        ("family_demand_scale", "Family-demand strength"),
    ]:
        subset = summary[(summary["sweep"] == sweep_name) & (summary["model"] == "fertility_extension")].sort_values("value")
        nimby_subset = summary[(summary["sweep"] == sweep_name) & (summary["model"] == "nimby_proxy")].sort_values("value")
        lines.extend(
            [
                f"### {label}",
                "",
                f"- Fertility-extension post-price response range: `{subset['post_price_response'].min():.3f}` to `{subset['post_price_response'].max():.3f}`",
                f"- NIMBY-proxy post-price response range: `{nimby_subset['post_price_response'].min():.3f}` to `{nimby_subset['post_price_response'].max():.3f}`",
                f"- Fertility-extension young-homeownership trough range: `{subset['young_homeownership_trough'].min():.4f}` to `{subset['young_homeownership_trough'].max():.4f}`",
                "",
            ]
        )

    (BUILD / "nimby_vs_fertility_transition_robustness.md").write_text("\n".join(lines), encoding="utf-8")


def plot(summary: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 3, figsize=(12.5, 7.5), constrained_layout=True)
    c_fert = "#b24c2a"
    c_nimby = "#111111"

    sweep_meta = [
        ("shock_size", "A. Shock size", "Shock size"),
        ("price_fertility_semi_elasticity", "B. Price-fertility sensitivity", "Semi-elasticity"),
        ("family_demand_scale", "C. Family-demand strength", "Scale"),
    ]

    for col, (sweep_name, title, xlabel) in enumerate(sweep_meta):
        subset = summary[summary["sweep"] == sweep_name].sort_values(["model", "value"])
        fert = subset[subset["model"] == "fertility_extension"].sort_values("value")
        nimby = subset[subset["model"] == "nimby_proxy"].sort_values("value")

        ax = axes[0, col]
        ax.plot(nimby["value"], nimby["post_price_response"], color=c_nimby, lw=2.0, marker="o", label="NIMBY proxy")
        ax.plot(fert["value"], fert["post_price_response"], color=c_fert, lw=2.0, marker="o", label="Fertility extension")
        ax.set_title(title)
        ax.set_xlabel(xlabel)
        ax.set_ylabel("Post-boom price response")
        ax.legend(frameon=False, loc="best")

        ax = axes[1, col]
        ax.plot(nimby["value"], nimby["young_homeownership_trough"], color=c_nimby, lw=2.0, marker="o", label="NIMBY proxy")
        ax.plot(fert["value"], fert["young_homeownership_trough"], color=c_fert, lw=2.0, marker="o", label="Fertility extension")
        ax.axhline(0.0, color="#777777", lw=1.0, ls="--")
        ax.set_xlabel(xlabel)
        ax.set_ylabel("Young-homeownership trough")
        ax.legend(frameon=False, loc="best")

    fig.suptitle("Baby-boom robustness: fertility extension versus NIMBY proxy", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_transition_robustness.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_transition_robustness.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    summary, checks = run_sweep()
    summary.to_csv(BUILD / "nimby_vs_fertility_transition_robustness.csv", index=False)
    checks.to_csv(BUILD / "nimby_vs_fertility_transition_robustness_checks.csv", index=False)
    write_note(summary, checks)
    plot(summary)


if __name__ == "__main__":
    main()
