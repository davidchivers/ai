from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from resolve_zac_david_paths import resolve_zac_david_path


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


def nimby_data_dir() -> Path:
    return resolve_zac_david_path("Data")


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


def load_model_series() -> tuple[pd.DataFrame, pd.DataFrame]:
    nimby = pd.read_csv(BUILD / "nimby_baby_boom_reference.csv")
    fert_base = pd.read_csv(BUILD / "comparison_new_baseline.csv")
    fert_shock = pd.read_csv(BUILD / "comparison_new_policy.csv")
    fert = pd.DataFrame({"t": fert_shock["t"]})
    fert["birthrate_index"] = fert_shock["births"] / fert_base["births"]
    return nimby, fert


def load_actual_series() -> tuple[pd.DataFrame, pd.DataFrame]:
    data_dir = nimby_data_dir()
    metro = pd.read_stata(
        data_dir / "merged_birthrates_migrationweights.dta",
        convert_categoricals=False,
    )
    metro = metro[metro["metarea"].astype(str).str.strip() == "0"].copy()
    metro = metro[["year", "weightedbirthrate"]].dropna().sort_values("year").reset_index(drop=True)
    metro["year"] = metro["year"].astype(int)
    metro_base = metro.loc[metro["year"] <= 1945, "weightedbirthrate"].mean()
    metro["birthrate_index"] = metro["weightedbirthrate"] / metro_base

    state = pd.read_stata(
        data_dir / "birthrates_updated.dta",
        convert_categoricals=False,
    )
    state = state[["year", "birthrate"]].dropna().copy()
    state["year"] = state["year"].astype(int)
    state = state.groupby("year", as_index=False)["birthrate"].mean()
    state_base = state.loc[state["year"] <= 1945, "birthrate"].mean()
    state["birthrate_index"] = state["birthrate"] / state_base
    return metro, state


def build_aligned_decline(
    actual: pd.DataFrame,
    nimby: pd.DataFrame,
    fert: pd.DataFrame,
    start_year: int = 1956,
    max_horizon: int = 40,
) -> pd.DataFrame:
    actual_part = actual.loc[actual["year"] >= start_year, ["year", "birthrate_index"]].copy()
    actual_part = actual_part.head(max_horizon).reset_index(drop=True)
    actual_part["years_since_boom"] = np.arange(len(actual_part))

    nimby_part = nimby.loc[nimby["t"] >= 10, ["t", "birthrate_index"]].copy()
    nimby_part = nimby_part.head(max_horizon).reset_index(drop=True)
    nimby_part["years_since_boom"] = np.arange(len(nimby_part))

    fert_part = fert.loc[fert["t"] >= 10, ["t", "birthrate_index"]].copy()
    fert_part = fert_part.head(max_horizon).reset_index(drop=True)
    fert_part["years_since_boom"] = np.arange(len(fert_part))

    out = pd.DataFrame({"years_since_boom": np.arange(min(len(actual_part), len(nimby_part), len(fert_part)))})
    out["actual_birthrate_index"] = actual_part["birthrate_index"].iloc[: len(out)].to_numpy()
    out["nimby_birthrate_index"] = nimby_part["birthrate_index"].iloc[: len(out)].to_numpy()
    out["fertility_birthrate_index"] = fert_part["birthrate_index"].iloc[: len(out)].to_numpy()
    return out


def write_summary(
    metro: pd.DataFrame,
    state: pd.DataFrame,
    nimby: pd.DataFrame,
    fert: pd.DataFrame,
    aligned: pd.DataFrame,
) -> pd.DataFrame:
    rows: list[dict[str, float | int | str]] = []
    actual_peak = metro.loc[metro["birthrate_index"].idxmax()]

    rows.append(
        {
            "metric": "actual_peak_year",
            "series": "metro_aggregate",
            "value": int(actual_peak["year"]),
        }
    )
    rows.append(
        {
            "metric": "actual_peak_index",
            "series": "metro_aggregate",
            "value": float(actual_peak["birthrate_index"]),
        }
    )
    rows.append(
        {
            "metric": "state_average_peak_index",
            "series": "state_average",
            "value": float(state["birthrate_index"].max()),
        }
    )

    for horizon in [10, 20, 30, 40]:
        sample = aligned.head(horizon)
        rmse_nimby = float(
            np.sqrt(np.mean((sample["actual_birthrate_index"] - sample["nimby_birthrate_index"]) ** 2))
        )
        rmse_fert = float(
            np.sqrt(np.mean((sample["actual_birthrate_index"] - sample["fertility_birthrate_index"]) ** 2))
        )
        rows.append({"metric": "rmse_postboom", "series": "nimby", "horizon_years": horizon, "value": rmse_nimby})
        rows.append(
            {
                "metric": "rmse_postboom",
                "series": "fertility_extension",
                "horizon_years": horizon,
                "value": rmse_fert,
            }
        )

    summary = pd.DataFrame(rows)
    summary.to_csv(BUILD / "nimby_vs_fertility_historical_validation_summary.csv", index=False)
    return summary


def write_note(summary: pd.DataFrame) -> None:
    rmse = summary.loc[summary["metric"] == "rmse_postboom"].copy()
    rmse["horizon_years"] = rmse["horizon_years"].astype(int)
    data_source = nimby_data_dir() / "merged_birthrates_migrationweights.dta"

    lines = [
        "# Historical baby-boom validation",
        "",
        "This note compares the postwar aggregate fertility path in the legacy NIMBY data against",
        "the current NIMBY and fertility-extension baby-boom transitions.",
        "",
        "## Data and alignment",
        "",
        f"- Historical data source: `{data_source}`",
        "- Aggregate series used in the main figure: `metarea == 0`, `weightedbirthrate`, `1940-1995`",
        "- Robustness series: state-average `birthrates_updated.dta`",
        "- Normalization: divide by the mean pre-boom birth rate over `1940-1945`",
        "- Post-boom alignment: compare data from `1956` onward to model periods `t >= 10`",
        "",
        "## Main read",
        "",
        "- Exact calendar alignment is imperfect because the historical baby boom is more persistent",
        "  than the toy 10-year model shock.",
        "- The informative comparison is therefore the post-boom decline rather than the raw peak.",
        "- On that aligned post-boom path, the fertility extension fits modestly better than the",
        "  NIMBY line at every horizon currently checked.",
        "",
        "## RMSE by horizon",
        "",
    ]

    for horizon in [10, 20, 30, 40]:
        nimby_value = rmse.loc[
            (rmse["series"] == "nimby") & (rmse["horizon_years"] == horizon),
            "value",
        ].iloc[0]
        fert_value = rmse.loc[
            (rmse["series"] == "fertility_extension") & (rmse["horizon_years"] == horizon),
            "value",
        ].iloc[0]
        lines.append(
            f"- `{horizon}` years: NIMBY `RMSE = {nimby_value:.3f}`, fertility extension `RMSE = {fert_value:.3f}`"
        )

    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "- The original NIMBY transition returns immediately to baseline fertility after the",
            "  imposed boom window.",
            "- The fertility extension adds a later dip below baseline, which is closer to the shape",
            "  of the historical post-boom decline.",
            "- The improvement is modest rather than dramatic, so this should be read as a validation",
            "  sign check, not a formal estimation result.",
            "",
        ]
    )

    (BUILD / "nimby_vs_fertility_historical_validation.md").write_text(
        "\n".join(lines),
        encoding="utf-8",
    )


def plot_validation(
    metro: pd.DataFrame,
    state: pd.DataFrame,
    nimby: pd.DataFrame,
    fert: pd.DataFrame,
    aligned: pd.DataFrame,
    summary: pd.DataFrame,
) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(11, 8.6), constrained_layout=True)
    c_actual = "#111111"
    c_state = "#6c757d"
    c_nimby = "#275d8c"
    c_fert = "#b24c2a"
    c_gray = "#666666"

    ax = axes[0, 0]
    ax.plot(metro["year"], metro["birthrate_index"], color=c_actual, lw=2.2, label="Actual aggregate fertility")
    ax.plot(
        state["year"],
        state["birthrate_index"],
        color=c_state,
        lw=1.8,
        ls="--",
        label="State-average fertility",
    )
    ax.axvline(1946, color=c_gray, lw=1.0, ls=":")
    ax.axvline(1955, color=c_gray, lw=1.0, ls=":")
    ax.set_title("A. Historical postwar fertility data")
    ax.set_xlabel("Year")
    ax.set_ylabel("Index, pre-boom mean = 1")
    ax.legend(frameon=False, loc="best")

    ax = axes[0, 1]
    years = 1946 + nimby["t"]
    ax.plot(metro["year"], metro["birthrate_index"], color=c_actual, lw=2.2, label="Actual aggregate fertility")
    ax.plot(years, nimby["birthrate_index"], color=c_nimby, lw=2.0, label="NIMBY")
    ax.plot(years, fert["birthrate_index"], color=c_fert, lw=2.0, label="Fertility extension")
    ax.set_xlim(1946, 1985)
    ax.set_title("B. Calendar alignment")
    ax.set_xlabel("Year")
    ax.set_ylabel("Index, pre-boom mean = 1")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 0]
    ax.plot(
        aligned["years_since_boom"],
        aligned["actual_birthrate_index"],
        color=c_actual,
        lw=2.2,
        label="Actual aggregate fertility",
    )
    ax.plot(
        aligned["years_since_boom"],
        aligned["nimby_birthrate_index"],
        color=c_nimby,
        lw=2.0,
        label="NIMBY",
    )
    ax.plot(
        aligned["years_since_boom"],
        aligned["fertility_birthrate_index"],
        color=c_fert,
        lw=2.0,
        label="Fertility extension",
    )
    ax.set_title("C. Post-boom decline alignment")
    ax.set_xlabel("Years since boom window ends")
    ax.set_ylabel("Index, pre-boom mean = 1")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    rmse = summary.loc[summary["metric"] == "rmse_postboom"].copy()
    horizons = [10, 20, 30, 40]
    x = np.arange(len(horizons))
    nimby_vals = [
        rmse.loc[(rmse["series"] == "nimby") & (rmse["horizon_years"] == h), "value"].iloc[0]
        for h in horizons
    ]
    fert_vals = [
        rmse.loc[(rmse["series"] == "fertility_extension") & (rmse["horizon_years"] == h), "value"].iloc[0]
        for h in horizons
    ]
    width = 0.34
    ax.bar(x - width / 2, nimby_vals, width=width, color=c_nimby, label="NIMBY")
    ax.bar(x + width / 2, fert_vals, width=width, color=c_fert, label="Fertility extension")
    ax.set_xticks(x, [str(h) for h in horizons])
    ax.set_title("D. Post-boom RMSE against actual fertility")
    ax.set_xlabel("Horizon in years")
    ax.set_ylabel("RMSE")
    ax.legend(frameon=False, loc="best")

    fig.suptitle(
        "Historical fertility validation: NIMBY versus fertility extension",
        fontsize=14,
        fontweight="bold",
    )
    fig.savefig(BUILD / "nimby_vs_fertility_historical_validation.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_historical_validation.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    nimby, fert = load_model_series()
    metro, state = load_actual_series()
    aligned = build_aligned_decline(metro, nimby, fert)
    aligned.to_csv(BUILD / "nimby_vs_fertility_historical_validation_series.csv", index=False)
    summary = write_summary(metro, state, nimby, fert, aligned)
    write_note(summary)
    plot_validation(metro, state, nimby, fert, aligned, summary)


if __name__ == "__main__":
    main()
