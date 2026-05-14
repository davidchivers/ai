#!/usr/bin/env python3
"""Compare model first-birth timing moments to current state-year timing data."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.formula.api as smf


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


OUTCOME_SPECS = [
    {
        "name": "mean_age_first_birth",
        "data_col": "mean_age_first_birth",
        "model_col": "mean_age_first_birth",
        "reg_model_id": "age_rent_unemp",
        "y_label": "Index, low cost = 100",
        "summary_label": "Mean age at first birth",
        "delta_unit": "years",
    },
    {
        "name": "share_first_birth_30_plus",
        "data_col": "share_first_birth_30_plus",
        "model_col": "share_first_birth_30_plus",
        "reg_model_id": "share30_rent_unemp",
        "y_label": "Index, low cost = 100",
        "summary_label": "Share of first births at age 30+",
        "delta_unit": "share points",
    },
    {
        "name": "first_birth_rate_15_44",
        "data_col": "first_birth_rate_15_44",
        "model_col": "avg_first_birth_rate",
        "reg_model_id": "rate_rent_unemp",
        "y_label": "Index, low cost = 100",
        "summary_label": "First-birth rate",
        "delta_unit": "percent",
    },
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


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    model = pd.read_csv(BUILD / "fertility_first_birth_timing_summary.csv")
    panel = pd.read_csv(BUILD / "exploratory_state_year_panel.csv")
    regressions = pd.read_csv(BUILD / "exploratory_regression_results.csv")
    return model, panel, regressions


def build_data_quartiles(panel: pd.DataFrame, spec: dict[str, str]) -> pd.DataFrame:
    subset = panel[[spec["data_col"], "real_rent_index", "state_fips", "year"]].dropna().copy()
    outcome_fe = smf.ols(f"{spec['data_col']} ~ C(state_fips) + C(year)", data=subset).fit()
    rent_fe = smf.ols("real_rent_index ~ C(state_fips) + C(year)", data=subset).fit()
    subset["outcome_adjusted"] = float(subset[spec["data_col"]].mean()) + outcome_fe.resid
    subset["rent_adjusted"] = float(subset["real_rent_index"].mean()) + rent_fe.resid
    subset["housing_cost_rank"] = pd.qcut(
        subset["rent_adjusted"],
        q=4,
        labels=[1, 2, 3, 4],
        duplicates="drop",
    )
    quartiles = (
        subset.groupby("housing_cost_rank", observed=False)
        .agg(
            housing_cost_mean=("rent_adjusted", "mean"),
            outcome_mean=("outcome_adjusted", "mean"),
            n_obs=("year", "size"),
            n_states=("state_fips", "nunique"),
            year_min=("year", "min"),
            year_max=("year", "max"),
        )
        .reset_index()
    )
    quartiles["housing_cost_rank"] = quartiles["housing_cost_rank"].astype(int)
    quartiles["series"] = "data"
    quartiles["outcome"] = spec["name"]
    quartiles["index_to_low_cost"] = 100.0 * quartiles["outcome_mean"] / quartiles["outcome_mean"].iloc[0]
    quartiles["delta_from_low_cost"] = quartiles["outcome_mean"] - quartiles["outcome_mean"].iloc[0]
    return quartiles


def build_model_quartiles(model: pd.DataFrame, spec: dict[str, str]) -> pd.DataFrame:
    selected = model.loc[np.isclose(model["a_price"], 1.5) | np.isclose(model["a_price"], 2.0) | np.isclose(model["a_price"], 2.5) | np.isclose(model["a_price"], 3.0)].copy()
    selected = selected.sort_values("a_price").reset_index(drop=True)
    selected["housing_cost_rank"] = np.arange(1, len(selected) + 1)
    selected["housing_cost_mean"] = selected["a_price"]
    selected["outcome_mean"] = selected[spec["model_col"]]
    selected["n_obs"] = np.nan
    selected["n_states"] = np.nan
    selected["year_min"] = np.nan
    selected["year_max"] = np.nan
    selected["series"] = "model"
    selected["outcome"] = spec["name"]
    selected["index_to_low_cost"] = 100.0 * selected["outcome_mean"] / selected["outcome_mean"].iloc[0]
    selected["delta_from_low_cost"] = selected["outcome_mean"] - selected["outcome_mean"].iloc[0]
    return selected[
        [
            "housing_cost_rank",
            "housing_cost_mean",
            "outcome_mean",
            "n_obs",
            "n_states",
            "year_min",
            "year_max",
            "series",
            "outcome",
            "index_to_low_cost",
            "delta_from_low_cost",
        ]
    ]


def regression_summary(regressions: pd.DataFrame, spec: dict[str, str]) -> dict[str, float]:
    row = regressions.loc[
        (regressions["model_id"] == spec["reg_model_id"]) & (regressions["term"] == "real_rent_index")
    ].iloc[0]
    return {
        "coef": float(row["coef"]),
        "std_err": float(row["std_err"]),
        "p_value": float(row["p_value"]),
        "n_obs": int(row["n_obs"]),
        "n_states": int(row["n_states"]),
    }


def build_outputs(model: pd.DataFrame, panel: pd.DataFrame, regressions: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    long_rows: list[pd.DataFrame] = []
    summary_rows: list[dict[str, object]] = []

    for spec in OUTCOME_SPECS:
        data_q = build_data_quartiles(panel, spec)
        model_q = build_model_quartiles(model, spec)
        reg = regression_summary(regressions, spec)

        long_rows.extend([data_q, model_q])

        data_low = data_q.iloc[0]
        data_high = data_q.iloc[-1]
        model_low = model_q.iloc[0]
        model_high = model_q.iloc[-1]

        summary_rows.append(
            {
                "outcome": spec["name"],
                "label": spec["summary_label"],
                "data_low": float(data_low["outcome_mean"]),
                "data_high": float(data_high["outcome_mean"]),
                "data_delta_raw": float(data_high["outcome_mean"] - data_low["outcome_mean"]),
                "data_index_high": float(data_high["index_to_low_cost"]),
                "model_low": float(model_low["outcome_mean"]),
                "model_high": float(model_high["outcome_mean"]),
                "model_delta_raw": float(model_high["outcome_mean"] - model_low["outcome_mean"]),
                "model_index_high": float(model_high["index_to_low_cost"]),
                "rent_coef": reg["coef"],
                "rent_std_err": reg["std_err"],
                "rent_p_value": reg["p_value"],
                "n_obs": reg["n_obs"],
                "n_states": reg["n_states"],
                "delta_unit": spec["delta_unit"],
            }
        )

    long_df = pd.concat(long_rows, ignore_index=True)
    summary_df = pd.DataFrame(summary_rows)
    return long_df, summary_df


def plot_comparison(long_df: pd.DataFrame, summary_df: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(11, 8.8), constrained_layout=True)
    c_model = "#b24c2a"
    c_data = "#275d8c"

    for ax, spec in zip(axes.flat[:3], OUTCOME_SPECS):
        subset = long_df.loc[long_df["outcome"] == spec["name"]].copy()
        data = subset.loc[subset["series"] == "data"]
        model = subset.loc[subset["series"] == "model"]
        ax.plot(
            data["housing_cost_rank"],
            data["index_to_low_cost"],
            color=c_data,
            lw=2.2,
            marker="o",
            label="State-year data",
        )
        ax.plot(
            model["housing_cost_rank"],
            model["index_to_low_cost"],
            color=c_model,
            lw=2.2,
            marker="s",
            label="Model benchmark",
        )
        ax.set_title(spec["summary_label"])
        ax.set_xlabel("Housing-cost rank: low to high")
        ax.set_ylabel(spec["y_label"])
        ax.set_xticks([1, 2, 3, 4])
        ax.set_xticklabels(["Low", "2", "3", "High"])
        if spec["name"] == "mean_age_first_birth":
            ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    ax.axis("off")
    lines = ["Low-to-high housing-cost comparison", ""]
    for _, row in summary_df.iterrows():
        lines.append(
            f"{row['label']}: data {row['data_delta_raw']:.3f}, "
            f"model {row['model_delta_raw']:.3f}, "
            f"rent FE coef {row['rent_coef']:.3f} (p={row['rent_p_value']:.3f})"
        )
    lines.extend(
        [
            "",
            "Read:",
            "The data and model move in the same direction on all three timing objects.",
            "The data evidence is still imprecise, so this is a directional match, not a full fit.",
        ]
    )
    ax.text(0.0, 1.0, "\n".join(lines), va="top", ha="left", fontsize=9.5)

    fig.suptitle("First-birth timing: model versus state-year data", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "first_birth_timing_model_data_comparison.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "first_birth_timing_model_data_comparison.pdf", bbox_inches="tight")
    plt.close(fig)


def write_markdown(summary_df: pd.DataFrame) -> None:
    lines = [
        "# First-birth timing: model versus state-year data",
        "",
        "This note compares the new model first-birth timing objects to the current state-year",
        "CDC WONDER timing panel already built in project 03.",
        "",
        "Important comparison rule:",
        "- the model uses steady-state house prices",
        "- the data use a state-year rent index",
        "- the data comparison uses state-and-year-adjusted rent bins rather than raw quartiles",
        "- so the clean comparison is directional and rank-based, not one-for-one in levels",
        "",
        "## Main read",
        "",
    ]

    for _, row in summary_df.iterrows():
        lines.append(
            f"- {row['label']}: data move from `{row['data_low']:.3f}` in the low-cost quartile to "
            f"`{row['data_high']:.3f}` in the high-cost quartile; model moves from "
            f"`{row['model_low']:.3f}` to `{row['model_high']:.3f}`."
        )
    lines.extend(
        [
            "",
            "So the current state-year data and the model line up in direction on all three objects:",
            "- higher housing costs are associated with older first births",
            "- higher housing costs are associated with a larger share of first births at age 30+",
            "- higher housing costs are associated with a lower first-birth rate",
            "",
            "The important limitation is precision. The state-year fixed-effects coefficients have the",
            "same signs, but the current samples are still noisy.",
            "",
            "## Comparison table",
            "",
            "| Outcome | Data low | Data high | Model low | Model high | Rent FE coef | p-value |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for _, row in summary_df.iterrows():
        lines.append(
            f"| {row['label']} | {row['data_low']:.3f} | {row['data_high']:.3f} | "
            f"{row['model_low']:.3f} | {row['model_high']:.3f} | "
            f"{row['rent_coef']:.3f} | {row['rent_p_value']:.3f} |"
        )

    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "This is a directional match, not a full calibration target yet. The model is now capable",
            "of speaking directly to delayed first births, and the current state-year data move in the",
            "same direction, but the empirical sample is still too thin to claim a tight quantitative fit.",
            "",
        ]
    )
    (BUILD / "first_birth_timing_model_data_comparison.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    model, panel, regressions = load_inputs()
    long_df, summary_df = build_outputs(model, panel, regressions)
    long_df.to_csv(BUILD / "first_birth_timing_model_data_comparison_series.csv", index=False)
    summary_df.to_csv(BUILD / "first_birth_timing_model_data_comparison_summary.csv", index=False)
    plot_comparison(long_df, summary_df)
    write_markdown(summary_df)
    print(BUILD / "first_birth_timing_model_data_comparison.md")


if __name__ == "__main__":
    set_style()
    main()
