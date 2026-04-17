from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_country_year_panel.csv"
RESULTS_PATH = PROJECT_ROOT / "data" / "processed" / "country_internet_stock_interaction_results.csv"
SUMMARY_PATH = PROJECT_ROOT / "data" / "processed" / "country_internet_stock_interaction_summary.md"

SPECS = [
    {
        "spec_id": "internet_interaction_1995_2014",
        "display_label": "Internet interaction (1995-2014)",
        "value_column": "internet_ct_l1",
        "start_year": 1995,
        "end_year": 2014,
    },
    {
        "spec_id": "broadband_interaction_1999_2014",
        "display_label": "Broadband interaction (1999-2014)",
        "value_column": "fixed_broadband_ct",
        "start_year": 1999,
        "end_year": 2014,
    },
]

OUTCOMES = [
    {
        "outcome_id": "log_all_metal_starts",
        "display_label": "Log all-metal band starts",
        "source_column": "bands_formed_all_metal_ct",
        "transform": "log1p",
    },
    {
        "outcome_id": "log_signed_metal_starts",
        "display_label": "Log signed band starts",
        "source_column": "bands_formed_all_metal_signed_ct",
        "transform": "log1p",
    },
    {
        "outcome_id": "share_unsigned_starts",
        "display_label": "Unsigned share of starts",
        "source_column": "share_all_metal_unsigned_ct",
        "transform": "level",
    },
]


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def load_panel() -> pd.DataFrame:
    panel = pd.read_csv(INPUT_PATH)
    panel["year"] = pd.to_numeric(panel["year"], errors="coerce").astype(int)
    numeric_columns = [
        "bands_formed_all_metal_ct",
        "bands_formed_all_metal_signed_ct",
        "share_all_metal_unsigned_ct",
        "internet_ct_l1",
        "fixed_broadband_ct",
    ]
    for column in numeric_columns:
        panel[column] = pd.to_numeric(panel[column], errors="coerce")

    panel["bands_formed_all_metal_ct"] = panel["bands_formed_all_metal_ct"].fillna(0.0)
    panel["bands_formed_all_metal_signed_ct"] = panel["bands_formed_all_metal_signed_ct"].fillna(0.0)
    panel = panel.sort_values(["countryiso3code", "year"]).reset_index(drop=True)

    # This is the country-level analogue of local scene thickness: prior accumulated metal entry.
    panel["cum_prior_all_metal"] = (
        panel.groupby("countryiso3code")["bands_formed_all_metal_ct"].cumsum()
        - panel["bands_formed_all_metal_ct"]
    )
    panel["lag_log_cum_prior_all_metal"] = np.log1p(panel["cum_prior_all_metal"])
    return panel


def build_sample(panel: pd.DataFrame, spec: dict[str, object], outcome: dict[str, str]) -> pd.DataFrame:
    sample = panel.loc[panel["year"].between(int(spec["start_year"]), int(spec["end_year"]))].copy()
    if outcome["transform"] == "log1p":
        sample["outcome_value"] = np.log1p(sample[outcome["source_column"]].fillna(0.0))
    else:
        sample["outcome_value"] = sample[outcome["source_column"]]

    sample = sample.loc[
        sample["lag_log_cum_prior_all_metal"].notna()
        & sample[str(spec["value_column"])].notna()
        & sample["outcome_value"].notna()
    ].copy()

    sample["z_stock"] = zscore(sample["lag_log_cum_prior_all_metal"])
    sample["z_network"] = zscore(sample[str(spec["value_column"])])
    sample["z_stock_x_network"] = sample["z_stock"] * sample["z_network"]
    return sample


def fit_spec(sample: pd.DataFrame, spec: dict[str, object], outcome: dict[str, str]) -> pd.DataFrame:
    sample = sample.set_index(["countryiso3code", "year"]).sort_index()
    clusters = pd.DataFrame(
        {"country_cluster": sample.reset_index()["countryiso3code"].values},
        index=sample.index,
    )
    result = PanelOLS(
        sample["outcome_value"],
        sample[["z_stock", "z_network", "z_stock_x_network"]],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=clusters)

    rows: list[dict[str, object]] = []
    for predictor, display_label in [
        ("z_stock", "Lagged cumulative metal stock"),
        ("z_network", "Internet or broadband level"),
        ("z_stock_x_network", "Stock x internet or broadband"),
    ]:
        rows.append(
            {
                "spec_id": spec["spec_id"],
                "spec_label": spec["display_label"],
                "value_column": spec["value_column"],
                "sample_start_year": spec["start_year"],
                "sample_end_year": spec["end_year"],
                "outcome_id": outcome["outcome_id"],
                "outcome_label": outcome["display_label"],
                "predictor": predictor,
                "predictor_label": display_label,
                "coefficient": float(result.params.get(predictor, np.nan)),
                "std_error": float(result.std_errors.get(predictor, np.nan)),
                "p_value": float(result.pvalues.get(predictor, np.nan)),
                "n_obs": int(result.nobs),
                "n_countries": int(sample.reset_index()["countryiso3code"].nunique()),
                "r_squared": float(result.rsquared),
            }
        )
    return pd.DataFrame(rows)


def format_coef(results: pd.DataFrame, spec_id: str, outcome_id: str, predictor: str) -> str:
    row = results.loc[
        (results["spec_id"] == spec_id)
        & (results["outcome_id"] == outcome_id)
        & (results["predictor"] == predictor)
    ]
    if row.empty:
        return "n/a"
    row = row.iloc[0]
    stars = "***" if row["p_value"] < 0.01 else "**" if row["p_value"] < 0.05 else "*" if row["p_value"] < 0.10 else ""
    return f"{row['coefficient']:.4f}{stars}"


def write_summary(results: pd.DataFrame) -> None:
    spec_meta = (
        results.groupby(["spec_id", "spec_label"], as_index=False)[["n_obs", "n_countries", "r_squared"]]
        .max()
    )
    spec_meta_map = {row.spec_id: row for row in spec_meta.itertuples(index=False)}

    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Country internet stock-interaction probe\n\n")
        handle.write(
            "This probe asks whether broad internet or broadband adoption matters more in countries "
            "that already have deeper metal scenes. The thickness measure is lagged cumulative "
            "all-metal band entry, and the regressions include country and year fixed effects.\n\n"
        )
        handle.write("## Specifications\n\n")
        for spec in SPECS:
            meta = spec_meta_map[spec["spec_id"]]
            handle.write(
                f"- `{spec['display_label']}`: N = `{meta.n_obs}`, countries = `{meta.n_countries}`, "
                f"R-squared = `{meta.r_squared:.4f}`.\n"
            )

        handle.write("\n## Headline coefficients\n\n")
        for spec in SPECS:
            handle.write(f"### {spec['display_label']}\n\n")
            for outcome in OUTCOMES:
                handle.write(
                    f"- `{outcome['display_label']}`: "
                    f"`stock = {format_coef(results, spec['spec_id'], outcome['outcome_id'], 'z_stock')}`, "
                    f"`network = {format_coef(results, spec['spec_id'], outcome['outcome_id'], 'z_network')}`, "
                    f"`interaction = {format_coef(results, spec['spec_id'], outcome['outcome_id'], 'z_stock_x_network')}`.\n"
                )
            handle.write("\n")

        handle.write("## Current read\n\n")
        handle.write(
            f"- In `{SPECS[0]['display_label']}`, lagged cumulative metal stock is strongly positive for "
            f"`log all-metal band starts` and `log signed band starts`, but the "
            f"`stock x internet` interaction is `{format_coef(results, 'internet_interaction_1995_2014', 'log_all_metal_starts', 'z_stock_x_network')}` "
            f"for all-metal starts and `{format_coef(results, 'internet_interaction_1995_2014', 'log_signed_metal_starts', 'z_stock_x_network')}` "
            "for signed starts.\n"
        )
        handle.write(
            "- So the country-level data do not currently say that internet adoption disproportionately "
            "helps countries that already have thicker metal scenes. The main country internet result "
            "still comes from the threshold event-study, not from this interaction design.\n"
        )
        handle.write(
            f"- In `{SPECS[1]['display_label']}`, the broadband main effect is negative and the "
            f"`stock x broadband` interaction is also negative for `log all-metal band starts` "
            f"(`{format_coef(results, 'broadband_interaction_1999_2014', 'log_all_metal_starts', 'z_stock_x_network')}`). "
            "That is not a supportive broadband-thickness result.\n"
        )
        handle.write(
            "- The unsigned-share outcome is weak throughout. This interaction probe is therefore mostly "
            "useful as a negative result: the country-level internet pattern does not appear to be driven "
            "mainly by thicker countries pulling further ahead once they go online.\n"
        )


def main() -> None:
    panel = load_panel()
    result_frames: list[pd.DataFrame] = []
    for spec in SPECS:
        for outcome in OUTCOMES:
            sample = build_sample(panel, spec, outcome)
            result_frames.append(fit_spec(sample, spec, outcome))

    results = pd.concat(result_frames, ignore_index=True)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(results)

    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
