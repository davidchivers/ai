#!/usr/bin/env python3
"""Build an annual mean-age-at-first-birth comparison: data vs annual model."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.formula.api as smf


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

PANEL_PATH = BUILD / "exploratory_state_year_panel.csv"
ANNUAL_CANDIDATES_PATH = BUILD / "fertility_annual_timing_stock_micro_screen_candidates.csv"
ANNUAL_PATHS_PATH = BUILD / "fertility_annual_timing_stock_micro_screen_candidate_paths.csv"
TARGET_RANKING_PATH = BUILD / "cdc_first_birth_timing_target_review_target_ranking.csv"

OUT_MD = BUILD / "annual_mean_age_first_birth_model_data_comparison.md"
OUT_PNG = BUILD / "annual_mean_age_first_birth_model_data_comparison.png"
OUT_PDF = BUILD / "annual_mean_age_first_birth_model_data_comparison.pdf"
OUT_SERIES = BUILD / "annual_mean_age_first_birth_model_data_comparison_series.csv"
OUT_SUMMARY = BUILD / "annual_mean_age_first_birth_model_data_comparison_summary.csv"


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


def load_annual_candidate() -> tuple[pd.Series, pd.DataFrame]:
    candidates = pd.read_csv(ANNUAL_CANDIDATES_PATH)
    paths = pd.read_csv(ANNUAL_PATHS_PATH)

    usable = candidates.loc[(candidates["primary_pass"] == 1) & (candidates["sign_pass"] == 1)].copy()
    if usable.empty:
        usable = candidates.copy()

    usable = usable.sort_values(["score", "eval_mean_age_first_birth"]).reset_index(drop=True)
    candidate = usable.iloc[0]
    candidate_id = int(candidate["candidate_id"])
    candidate_paths = paths.loc[paths["candidate_id"] == candidate_id].copy()
    candidate_paths = candidate_paths.sort_values("a_price").reset_index(drop=True)
    candidate_paths["normalized_rank"] = np.linspace(1.0, 4.0, len(candidate_paths))
    candidate_paths["series"] = "annual_model"
    candidate_paths["index_to_low_cost"] = (
        100.0 * candidate_paths["mean_age_first_birth"] / candidate_paths["mean_age_first_birth"].iloc[0]
    )
    return candidate, candidate_paths


def build_data_quartiles(panel: pd.DataFrame) -> pd.DataFrame:
    subset = panel[["mean_age_first_birth", "real_rent_index", "state_fips", "year"]].dropna().copy()
    outcome_fe = smf.ols("mean_age_first_birth ~ C(state_fips) + C(year)", data=subset).fit()
    rent_fe = smf.ols("real_rent_index ~ C(state_fips) + C(year)", data=subset).fit()
    subset["outcome_adjusted"] = float(subset["mean_age_first_birth"].mean()) + outcome_fe.resid
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
            mean_age_first_birth=("outcome_adjusted", "mean"),
            n_obs=("year", "size"),
            n_states=("state_fips", "nunique"),
            year_min=("year", "min"),
            year_max=("year", "max"),
        )
        .reset_index()
    )
    quartiles["housing_cost_rank"] = quartiles["housing_cost_rank"].astype(int)
    quartiles["normalized_rank"] = quartiles["housing_cost_rank"].astype(float)
    quartiles["series"] = "state_year_data"
    quartiles["index_to_low_cost"] = (
        100.0 * quartiles["mean_age_first_birth"] / quartiles["mean_age_first_birth"].iloc[0]
    )
    return quartiles


def load_target_mean_age() -> float:
    ranking = pd.read_csv(TARGET_RANKING_PATH)
    row = ranking.loc[ranking["object"] == "mean_age_first_birth"]
    if row.empty:
        raise ValueError("Could not find annual mean-age target in CDC ranking file.")
    return float(row.iloc[0]["recent_mean"])


def build_outputs() -> tuple[pd.Series, pd.DataFrame, pd.DataFrame, float, pd.DataFrame]:
    panel = pd.read_csv(PANEL_PATH)
    candidate, model_paths = load_annual_candidate()
    data_quartiles = build_data_quartiles(panel)
    target_mean_age = load_target_mean_age()

    series_rows = pd.concat(
        [
            data_quartiles[
                [
                    "series",
                    "normalized_rank",
                    "housing_cost_mean",
                    "mean_age_first_birth",
                    "index_to_low_cost",
                    "n_obs",
                    "n_states",
                    "year_min",
                    "year_max",
                ]
            ].rename(columns={"housing_cost_mean": "housing_cost_proxy"}),
            model_paths[
                [
                    "series",
                    "normalized_rank",
                    "a_price",
                    "mean_age_first_birth",
                    "index_to_low_cost",
                ]
            ].rename(columns={"a_price": "housing_cost_proxy"}),
        ],
        ignore_index=True,
    )

    summary = pd.DataFrame(
        [
            {
                "object": "data_low",
                "value": float(data_quartiles["mean_age_first_birth"].iloc[0]),
            },
            {
                "object": "data_high",
                "value": float(data_quartiles["mean_age_first_birth"].iloc[-1]),
            },
            {
                "object": "annual_model_low",
                "value": float(model_paths["mean_age_first_birth"].iloc[0]),
            },
            {
                "object": "annual_model_high",
                "value": float(model_paths["mean_age_first_birth"].iloc[-1]),
            },
            {
                "object": "annual_cdc_target",
                "value": target_mean_age,
            },
        ]
    )

    return candidate, data_quartiles, model_paths, target_mean_age, series_rows, summary


def plot_comparison(
    candidate: pd.Series,
    data_quartiles: pd.DataFrame,
    model_paths: pd.DataFrame,
    target_mean_age: float,
) -> None:
    fig, axes = plt.subplots(1, 2, figsize=(11.2, 5.2), constrained_layout=True)
    c_data = "#275d8c"
    c_model = "#b24c2a"
    c_target = "#6f6f6f"

    ax = axes[0]
    ax.plot(
        data_quartiles["normalized_rank"],
        data_quartiles["mean_age_first_birth"],
        color=c_data,
        lw=2.2,
        marker="o",
        label="State-year data",
    )
    ax.plot(
        model_paths["normalized_rank"],
        model_paths["mean_age_first_birth"],
        color=c_model,
        lw=2.2,
        marker="s",
        label="Annual model candidate",
    )
    ax.axhline(target_mean_age, color=c_target, lw=1.4, ls="--", label="CDC pooled 2020-2024 target")
    ax.set_title("Mean age at first birth")
    ax.set_xlabel("Housing-cost rank: low to high")
    ax.set_ylabel("Years")
    ax.set_xticks([1, 2, 3, 4])
    ax.set_xticklabels(["Low", "2", "3", "High"])
    ax.legend(frameon=False, loc="best")

    ax = axes[1]
    ax.plot(
        data_quartiles["normalized_rank"],
        data_quartiles["index_to_low_cost"],
        color=c_data,
        lw=2.2,
        marker="o",
        label="State-year data",
    )
    ax.plot(
        model_paths["normalized_rank"],
        model_paths["index_to_low_cost"],
        color=c_model,
        lw=2.2,
        marker="s",
        label="Annual model candidate",
    )
    ax.set_title("Indexed slope, low cost = 100")
    ax.set_xlabel("Housing-cost rank: low to high")
    ax.set_ylabel("Index")
    ax.set_xticks([1, 2, 3, 4])
    ax.set_xticklabels(["Low", "2", "3", "High"])

    fig.suptitle("Annual mean age at first birth: data versus annual model", fontsize=14, fontweight="bold")
    fig.savefig(OUT_PNG, dpi=220, bbox_inches="tight")
    fig.savefig(OUT_PDF, bbox_inches="tight")
    plt.close(fig)


def write_markdown(
    candidate: pd.Series,
    data_quartiles: pd.DataFrame,
    model_paths: pd.DataFrame,
    target_mean_age: float,
) -> None:
    data_low = float(data_quartiles["mean_age_first_birth"].iloc[0])
    data_high = float(data_quartiles["mean_age_first_birth"].iloc[-1])
    model_low = float(model_paths["mean_age_first_birth"].iloc[0])
    model_high = float(model_paths["mean_age_first_birth"].iloc[-1])

    lines = [
        "# Annual mean age at first birth: data versus annual model",
        "",
        "This note replaces the old 5-year comparison with the current annual annual-model candidate.",
        "",
        f"Annual candidate used: `{candidate['label']}`",
        "",
        "Comparison rule:",
        "- the data are state-year mean age at first birth from the current CDC-based panel",
        "- the data are grouped into state-and-year-adjusted rent quartiles",
        "- the annual model path is the current usable annual candidate from the timing-stock micro screen",
        "- the annual model prices are mapped onto the same low-to-high rank scale for plotting",
        "",
        "## Main read",
        "",
        f"- Data move from `{data_low:.3f}` in the low-cost quartile to `{data_high:.3f}` in the high-cost quartile.",
        f"- The annual model candidate moves from `{model_low:.3f}` at the low-price end to `{model_high:.3f}` at the high-price end.",
        f"- The direct pooled annual CDC target is `{target_mean_age:.3f}`.",
        "",
        "So the annual model candidate now speaks directly to the annual timing object, not the old 5-year benchmark object.",
        "The model still sits too high in levels, but this is the correct annual comparison layer.",
        "",
        "## Data table",
        "",
        "| Series | Rank | Housing-cost proxy | Mean age first birth | Index to low cost |",
        "| --- | ---: | ---: | ---: | ---: |",
    ]

    for _, row in data_quartiles.iterrows():
        lines.append(
            f"| State-year data | {int(row['housing_cost_rank'])} | {row['housing_cost_mean']:.4f} | "
            f"{row['mean_age_first_birth']:.3f} | {row['index_to_low_cost']:.3f} |"
        )

    for _, row in model_paths.iterrows():
        lines.append(
            f"| Annual model candidate | {row['normalized_rank']:.2f} | {row['a_price']:.2f} | "
            f"{row['mean_age_first_birth']:.3f} | {row['index_to_low_cost']:.3f} |"
        )

    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    candidate, data_quartiles, model_paths, target_mean_age, series_rows, summary = build_outputs()
    series_rows.to_csv(OUT_SERIES, index=False)
    summary.to_csv(OUT_SUMMARY, index=False)
    plot_comparison(candidate, data_quartiles, model_paths, target_mean_age)
    write_markdown(candidate, data_quartiles, model_paths, target_mean_age)
    print(OUT_MD)


if __name__ == "__main__":
    set_style()
    main()
