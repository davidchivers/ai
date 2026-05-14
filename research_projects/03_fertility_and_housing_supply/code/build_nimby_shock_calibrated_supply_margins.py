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
from resolve_zac_david_paths import resolve_zac_david_path


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


def nimby_data_dir() -> Path:
    return resolve_zac_david_path("Data")

TARGET_PRICE_RATIO = 1.15
TARGET_HORIZON = 40
PROJECTION_SCENARIO = "medium_immigration"
HISTORICAL_START_YEAR = 1956
HISTORICAL_HORIZON = 40

MARGINS = [
    {
        "key": "theta0",
        "display": r"$\theta_0$ shift",
        "description": "Higher baseline political tightness",
        "parameter_name": "delta_theta0",
        "lower": 0.0,
        "upper": 0.10,
        "build": lambda p, x: replace(p, theta0=p.theta0 + x),
        "color": "#b24c2a",
    },
    {
        "key": "eps0",
        "display": r"$\epsilon_0$ reduction",
        "description": "Lower housing-supply elasticity",
        "parameter_name": "eps0_reduction_share",
        "lower": 0.0,
        "upper": 0.70,
        "build": lambda p, x: replace(p, eps0=p.eps0 * (1.0 - x)),
        "color": "#275d8c",
    },
    {
        "key": "s0",
        "display": r"$s_0$ reduction",
        "description": "Lower baseline housing supply",
        "parameter_name": "s0_reduction_share",
        "lower": 0.0,
        "upper": 0.70,
        "build": lambda p, x: replace(p, s0=p.s0 * (1.0 - x)),
        "color": "#2d7f5e",
    },
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


def load_actual_decline() -> pd.DataFrame:
    metro = pd.read_stata(
        nimby_data_dir() / "merged_birthrates_migrationweights.dta",
        convert_categoricals=False,
    )
    metro = metro[metro["metarea"].astype(str).str.strip() == "0"].copy()
    metro = metro[["year", "weightedbirthrate"]].dropna().sort_values("year").reset_index(drop=True)
    metro["year"] = metro["year"].astype(int)
    actual = metro.loc[metro["year"] >= HISTORICAL_START_YEAR, ["year", "weightedbirthrate"]].copy()
    actual = actual.head(HISTORICAL_HORIZON).reset_index(drop=True)
    actual["t"] = np.arange(len(actual), dtype=int)
    start_value = float(actual["weightedbirthrate"].iloc[0])
    actual["fertility_index"] = actual["weightedbirthrate"] / start_value
    return actual


def transition_price_ratio(base_params: BridgeParams, shock_params: BridgeParams) -> float:
    base, shock = simulate_persistent_nimby_shock_transition(base_params, shock_params, shock_start=1)
    base_price_index = np.exp(base["price"] - float(base["price"].iloc[0]))
    shock_price_index = np.exp(shock["price"] - float(shock["price"].iloc[0]))
    horizon = min(TARGET_HORIZON, len(base_price_index) - 1)
    return float(shock_price_index.iloc[horizon] / base_price_index.iloc[horizon])


def calibrate_margin(base_params: BridgeParams, margin: dict[str, object]) -> tuple[float, BridgeParams, float]:
    lower = float(margin["lower"])
    upper = float(margin["upper"])
    build = margin["build"]

    ratio_lower = transition_price_ratio(base_params, build(base_params, lower))
    ratio_upper = transition_price_ratio(base_params, build(base_params, upper))
    if TARGET_PRICE_RATIO <= ratio_lower:
        shock_params = build(base_params, lower)
        return lower, shock_params, ratio_lower
    if TARGET_PRICE_RATIO >= ratio_upper:
        shock_params = build(base_params, upper)
        return upper, shock_params, ratio_upper

    lo = lower
    hi = upper
    ratio_lo = ratio_lower
    ratio_hi = ratio_upper
    shock_params = build(base_params, upper)
    ratio_mid = ratio_upper

    for _ in range(40):
        mid = 0.5 * (lo + hi)
        shock_params = build(base_params, mid)
        ratio_mid = transition_price_ratio(base_params, shock_params)
        if abs(ratio_mid - TARGET_PRICE_RATIO) < 1e-4 or (hi - lo) < 1e-5:
            return mid, shock_params, ratio_mid
        if ratio_mid < TARGET_PRICE_RATIO:
            lo = mid
            ratio_lo = ratio_mid
        else:
            hi = mid
            ratio_hi = ratio_mid

    if abs(ratio_lo - TARGET_PRICE_RATIO) <= abs(ratio_hi - TARGET_PRICE_RATIO):
        shock_value = lo
        shock_params = build(base_params, lo)
        ratio_mid = ratio_lo
    else:
        shock_value = hi
        shock_params = build(base_params, hi)
        ratio_mid = ratio_hi
    return shock_value, shock_params, ratio_mid


def build_transition_summary(
    base: pd.DataFrame,
    shock: pd.DataFrame,
    actual: pd.DataFrame,
    margin: dict[str, object],
    shock_value: float,
    achieved_ratio: float,
) -> tuple[dict[str, float | str], pd.DataFrame]:
    base = base.copy()
    shock = shock.copy()
    base["price_index"] = np.exp(base["price"] - float(base["price"].iloc[0]))
    shock["price_index"] = np.exp(shock["price"] - float(shock["price"].iloc[0]))
    base["fertility_index"] = base["fertility_rate"] / float(base["fertility_rate"].iloc[0])
    shock["fertility_index"] = shock["fertility_rate"] / float(shock["fertility_rate"].iloc[0])

    comparison = pd.DataFrame({"t": np.arange(len(actual), dtype=int)})
    comparison["actual_fertility_index"] = actual["fertility_index"].iloc[: len(comparison)].to_numpy()
    comparison["baseline_fertility_index"] = base["fertility_index"].iloc[: len(comparison)].to_numpy()
    comparison["shock_fertility_index"] = shock["fertility_index"].iloc[: len(comparison)].to_numpy()
    baseline_rmse = float(
        np.sqrt(np.mean((comparison["actual_fertility_index"] - comparison["baseline_fertility_index"]) ** 2))
    )
    shock_rmse = float(
        np.sqrt(np.mean((comparison["actual_fertility_index"] - comparison["shock_fertility_index"]) ** 2))
    )

    t40 = min(TARGET_HORIZON, len(base) - 1)
    t79 = min(79, len(base) - 1)
    actual_end = float(comparison["actual_fertility_index"].iloc[-1])
    baseline_end = float(comparison["baseline_fertility_index"].iloc[-1])
    shock_end = float(comparison["shock_fertility_index"].iloc[-1])
    rmse_improvement = float((baseline_rmse - shock_rmse) / baseline_rmse) if baseline_rmse > 0.0 else np.nan
    gap_closed = float((baseline_end - shock_end) / (baseline_end - actual_end)) if baseline_end != actual_end else np.nan

    summary = {
        "margin": str(margin["key"]),
        "margin_display": str(margin["display"]),
        "description": str(margin["description"]),
        "parameter_name": str(margin["parameter_name"]),
        "parameter_value": float(shock_value),
        "target_price_ratio_t40": float(TARGET_PRICE_RATIO),
        "achieved_price_ratio_t40": float(achieved_ratio),
        "baseline_price_index_t40": float(base["price_index"].iloc[t40]),
        "shock_price_index_t40": float(shock["price_index"].iloc[t40]),
        "baseline_fertility_rate_t40": float(base["fertility_rate"].iloc[t40]),
        "shock_fertility_rate_t40": float(shock["fertility_rate"].iloc[t40]),
        "baseline_price_index_t79": float(base["price_index"].iloc[t79]),
        "shock_price_index_t79": float(shock["price_index"].iloc[t79]),
        "baseline_fertility_rate_t79": float(base["fertility_rate"].iloc[t79]),
        "shock_fertility_rate_t79": float(shock["fertility_rate"].iloc[t79]),
        "historical_rmse_baseline": baseline_rmse,
        "historical_rmse_shock": shock_rmse,
        "historical_rmse_improvement_share": rmse_improvement,
        "historical_gap_closed_share_40y": gap_closed,
        "historical_start_year": int(actual["year"].iloc[0]),
        "historical_end_year": int(actual["year"].iloc[len(comparison) - 1]),
    }
    return summary, comparison


def build_projection_summary(
    projection_base: pd.DataFrame,
    projection_shock: pd.DataFrame,
    margin: dict[str, object],
) -> list[dict[str, float | str]]:
    rows: list[dict[str, float | str]] = []
    for scenario, base_group in projection_base.groupby("scenario", sort=False):
        shock_group = projection_shock[projection_shock["scenario"] == scenario]
        for year in (2050, 2100):
            b = base_group.loc[base_group["year"] == year].iloc[0]
            s = shock_group.loc[shock_group["year"] == year].iloc[0]
            rows.append(
                {
                    "margin": str(margin["key"]),
                    "margin_display": str(margin["display"]),
                    "scenario": str(scenario),
                    "year": int(year),
                    "baseline_price_index": float(b["price_index"]),
                    "shock_price_index": float(s["price_index"]),
                    "price_ratio": float(s["price_index"] / b["price_index"]),
                    "baseline_fertility_rate": float(b["fertility_rate"]),
                    "shock_fertility_rate": float(s["fertility_rate"]),
                    "fertility_gap": float(s["fertility_rate"] - b["fertility_rate"]),
                }
            )
    return rows


def write_note(
    summary: pd.DataFrame,
    projection_summary: pd.DataFrame,
    actual: pd.DataFrame,
) -> None:
    medium_2050 = projection_summary[
        (projection_summary["scenario"] == PROJECTION_SCENARIO) & (projection_summary["year"] == 2050)
    ].sort_values("margin")
    medium_2100 = projection_summary[
        (projection_summary["scenario"] == PROJECTION_SCENARIO) & (projection_summary["year"] == 2100)
    ].sort_values("margin")
    actual_end = float(actual["fertility_index"].iloc[-1])

    lines = [
        "# Calibrated persistent NIMBY shocks",
        "",
        "This note replaces the purely mechanical `theta0` grid with a target-based comparison.",
        f"Each supply-tightening shock is calibrated to raise the model house-price index by about `{100.0 * (TARGET_PRICE_RATIO - 1.0):.0f}%` after `{TARGET_HORIZON}` periods.",
        "That target is chosen to match the order of magnitude reported in the NIMBY paper, where the",
        "political-economy mechanism explains about a 15 percent increase in house prices since 1950.",
        "",
        "## Calibrated supply margins",
        "",
    ]

    for _, row in summary.sort_values("margin").iterrows():
        lines.append(
            f"- {row['margin_display']}: `{row['parameter_name']} = {row['parameter_value']:.4f}`, price ratio at `t = {TARGET_HORIZON}` is `{row['achieved_price_ratio_t40']:.3f}`, and fertility at `t = {TARGET_HORIZON}` falls from `{row['baseline_fertility_rate_t40']:.3f}` to `{row['shock_fertility_rate_t40']:.3f}`."
        )

    lines.extend(
        [
            "",
            "## Historical fertility check",
            "",
            f"- The historical comparison uses the aggregate metro fertility series from `{HISTORICAL_START_YEAR}` to `{int(actual['year'].iloc[-1])}`, normalized to `{HISTORICAL_START_YEAR} = 1`.",
            f"- Over that window, actual fertility falls to `{actual_end:.3f}` of its initial level.",
        ]
    )

    for _, row in summary.sort_values("margin").iterrows():
        lines.append(
            f"- {row['margin_display']}: shock RMSE `{row['historical_rmse_shock']:.3f}` versus baseline `{row['historical_rmse_baseline']:.3f}`; the shock closes about `{100.0 * row['historical_gap_closed_share_40y']:.1f}%` of the baseline-to-data end-gap and improves RMSE by `{100.0 * row['historical_rmse_improvement_share']:.1f}%`."
        )

    lines.extend(
        [
            "",
            "## Medium-immigration projection",
            "",
        ]
    )

    for year, group in ((2050, medium_2050), (2100, medium_2100)):
        for _, row in group.iterrows():
            lines.append(
                f"- {row['margin_display']} in `{year}`: price index `{row['shock_price_index']:.3f}` versus `{row['baseline_price_index']:.3f}` baseline; fertility `{row['shock_fertility_rate']:.3f}` versus `{row['baseline_fertility_rate']:.3f}` baseline."
            )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- The long-run fertility result survives when the same house-price target is hit through three different supply margins.",
            "- The calibrated housing-scarcity shocks move the model toward the historical postwar fertility decline, but only by a modest amount.",
            "- So the sign is not just a `theta0` artifact, but housing scarcity alone still does not explain the whole historical decline.",
            "",
        ]
    )

    (BUILD / "nimby_shock_calibrated_supply_margins.md").write_text("\n".join(lines), encoding="utf-8")


def plot(
    base_transition: pd.DataFrame,
    shock_series: list[tuple[dict[str, object], pd.DataFrame]],
    actual: pd.DataFrame,
    base_projection: pd.DataFrame,
    projection_series: list[tuple[dict[str, object], pd.DataFrame]],
) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(12.5, 8.2), constrained_layout=True)
    c_base = "#111111"
    c_actual = "#666666"

    ax = axes[0, 0]
    base_price_index = np.exp(base_transition["price"] - float(base_transition["price"].iloc[0]))
    ax.plot(base_transition["t"], base_price_index, color=c_base, lw=2.0, label="Baseline")
    for margin, shock in shock_series:
        price_index = np.exp(shock["price"] - float(shock["price"].iloc[0]))
        ax.plot(shock["t"], price_index, lw=2.0, color=str(margin["color"]), label=str(margin["display"]))
    ax.axvline(TARGET_HORIZON, color="#888888", lw=1.0, ls="--")
    ax.axhline(base_price_index.iloc[TARGET_HORIZON] * TARGET_PRICE_RATIO, color="#888888", lw=1.0, ls=":")
    ax.set_title("A. Calibrated transition price paths")
    ax.set_xlabel("Model period")
    ax.set_ylabel("House-price index")
    ax.legend(frameon=False, loc="best")

    ax = axes[0, 1]
    ax.plot(actual["year"], actual["fertility_index"], color=c_actual, lw=2.2, label="Actual postwar fertility")
    baseline_index = base_transition["fertility_rate"] / float(base_transition["fertility_rate"].iloc[0])
    actual_years = actual["year"].to_numpy(dtype=int)
    model_years = actual_years[: len(baseline_index.iloc[: len(actual)])]
    ax.plot(model_years, baseline_index.iloc[: len(model_years)], color=c_base, lw=1.8, ls="--", label="Baseline")
    for margin, shock in shock_series:
        shock_index = shock["fertility_rate"] / float(shock["fertility_rate"].iloc[0])
        ax.plot(
            model_years,
            shock_index.iloc[: len(model_years)],
            lw=2.0,
            color=str(margin["color"]),
            label=str(margin["display"]),
        )
    ax.set_title("B. Historical fertility decline check")
    ax.set_xlabel("Year")
    ax.set_ylabel(f"Index, {HISTORICAL_START_YEAR} = 1")
    ax.legend(frameon=False, loc="best")

    medium_base = base_projection[base_projection["scenario"] == PROJECTION_SCENARIO].sort_values("year")
    ax = axes[1, 0]
    ax.plot(medium_base["year"], medium_base["price_index"], color=c_base, lw=2.0, label="Baseline")
    for margin, shock in projection_series:
        medium_shock = shock[shock["scenario"] == PROJECTION_SCENARIO].sort_values("year")
        ax.plot(medium_shock["year"], medium_shock["price_index"], lw=2.0, color=str(margin["color"]), label=str(margin["display"]))
    ax.set_title("C. Medium-immigration projected house prices")
    ax.set_xlabel("Year")
    ax.set_ylabel("House-price index")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    ax.plot(medium_base["year"], medium_base["fertility_rate"], color=c_base, lw=2.0, label="Baseline")
    for margin, shock in projection_series:
        medium_shock = shock[shock["scenario"] == PROJECTION_SCENARIO].sort_values("year")
        ax.plot(
            medium_shock["year"],
            medium_shock["fertility_rate"],
            lw=2.0,
            color=str(margin["color"]),
            label=str(margin["display"]),
        )
    ax.set_title("D. Medium-immigration projected fertility")
    ax.set_xlabel("Year")
    ax.set_ylabel("Fertility rate")
    ax.legend(frameon=False, loc="best")

    fig.suptitle(
        "Calibrated persistent NIMBY shocks across supply margins",
        fontsize=14,
        fontweight="bold",
    )
    fig.savefig(BUILD / "nimby_shock_calibrated_supply_margins.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_shock_calibrated_supply_margins.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    base_params = BridgeParams()
    age_path = pd.read_csv(BUILD / "nimby_projection_age_groups_all_scenarios.csv")
    actual = load_actual_decline()

    base_transition, _ = simulate_persistent_nimby_shock_transition(base_params, base_params, shock_start=1)
    base_projection, _ = simulate_projection_nimby_shock(
        age_path, base_params, base_params, mode="fertility", shock_start_year=2021
    )

    summary_rows: list[dict[str, float | str]] = []
    projection_rows: list[dict[str, float | str]] = []
    transition_series: list[pd.DataFrame] = []
    historical_rows: list[pd.DataFrame] = []
    projection_series: list[pd.DataFrame] = []
    plotted_transition_series: list[tuple[dict[str, object], pd.DataFrame]] = []
    plotted_projection_series: list[tuple[dict[str, object], pd.DataFrame]] = []

    for margin in MARGINS:
        shock_value, shock_params, achieved_ratio = calibrate_margin(base_params, margin)
        transition_base, transition_shock = simulate_persistent_nimby_shock_transition(
            base_params, shock_params, shock_start=1
        )
        projection_base, projection_shock = simulate_projection_nimby_shock(
            age_path, base_params, shock_params, mode="fertility", shock_start_year=2021
        )

        summary_row, historical_comparison = build_transition_summary(
            transition_base, transition_shock, actual, margin, shock_value, achieved_ratio
        )
        summary_rows.append(summary_row)
        projection_rows.extend(build_projection_summary(projection_base, projection_shock, margin))

        transition_copy = transition_shock.copy()
        transition_copy["margin"] = str(margin["key"])
        transition_copy["margin_display"] = str(margin["display"])
        transition_series.append(transition_copy)
        historical_copy = historical_comparison.copy()
        historical_copy["margin"] = str(margin["key"])
        historical_rows.append(historical_copy)
        projection_copy = projection_shock.copy()
        projection_copy["margin"] = str(margin["key"])
        projection_copy["margin_display"] = str(margin["display"])
        projection_series.append(projection_copy)

        plotted_transition_series.append((margin, transition_shock))
        plotted_projection_series.append((margin, projection_shock))

    summary = pd.DataFrame(summary_rows).sort_values("margin").reset_index(drop=True)
    projection_summary = pd.DataFrame(projection_rows).sort_values(["scenario", "year", "margin"]).reset_index(drop=True)
    pd.concat(transition_series, ignore_index=True).to_csv(
        BUILD / "nimby_shock_calibrated_supply_margins_transition.csv", index=False
    )
    pd.concat(projection_series, ignore_index=True).to_csv(
        BUILD / "nimby_shock_calibrated_supply_margins_projection.csv", index=False
    )
    pd.concat(historical_rows, ignore_index=True).to_csv(
        BUILD / "nimby_shock_calibrated_supply_margins_historical.csv", index=False
    )
    summary.to_csv(BUILD / "nimby_shock_calibrated_supply_margins_summary.csv", index=False)
    projection_summary.to_csv(BUILD / "nimby_shock_calibrated_supply_margins_projection_summary.csv", index=False)

    write_note(summary, projection_summary, actual)
    plot(base_transition, plotted_transition_series, actual, base_projection, plotted_projection_series)


if __name__ == "__main__":
    main()
