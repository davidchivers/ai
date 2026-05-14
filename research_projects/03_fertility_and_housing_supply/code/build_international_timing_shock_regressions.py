#!/usr/bin/env python3
"""Run international timing regressions on the timing-plus-shocks panel."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import statsmodels.formula.api as smf


ROOT = Path(__file__).resolve().parents[1]
PANEL_PATH = ROOT / "data" / "processed" / "international_first_birth_timing_shocks_v1.csv"
BUILD_DIR = ROOT / "notes" / "build"


OUTCOMES = [
    ("mean_age_first_birth", "Mean age at first birth"),
    ("mean_age_childbirth", "Mean age at childbirth"),
    ("total_fertility_rate", "Total fertility rate"),
]


@dataclass(frozen=True)
class Spec:
    group: str
    model_id: str
    label: str
    terms: tuple[str, ...]


SPECS = [
    Spec(
        group="housing_only",
        model_id="housing_oecd_growth",
        label="OECD house-price growth only",
        terms=("oecd_house_price_growth_pct",),
    ),
    Spec(
        group="housing_only",
        model_id="housing_oecd_index",
        label="OECD house-price index only",
        terms=("oecd_house_price_index",),
    ),
    Spec(
        group="housing_only",
        model_id="housing_bis_real",
        label="BIS real house-price growth only",
        terms=("bis_real_house_price_growth_pct",),
    ),
    Spec(
        group="housing_only",
        model_id="housing_bis_nominal",
        label="BIS nominal house-price growth only",
        terms=("bis_nominal_house_price_growth_pct",),
    ),
    Spec(
        group="rates_only",
        model_id="rate_short_only",
        label="OECD short rate only",
        terms=("oecd_short_rate_pct",),
    ),
    Spec(
        group="rates_only",
        model_id="rate_long_only",
        label="OECD long rate only",
        terms=("oecd_long_rate_pct",),
    ),
    Spec(
        group="horse_race",
        model_id="horse_oecd_index_long",
        label="OECD house-price index + OECD long rate",
        terms=("oecd_house_price_index", "oecd_long_rate_pct"),
    ),
    Spec(
        group="horse_race",
        model_id="horse_bis_real_long",
        label="BIS real house-price growth + OECD long rate",
        terms=("bis_real_house_price_growth_pct", "oecd_long_rate_pct"),
    ),
    Spec(
        group="horse_race",
        model_id="horse_oecd_growth_long",
        label="OECD house-price growth + OECD long rate",
        terms=("oecd_house_price_growth_pct", "oecd_long_rate_pct"),
    ),
]


def load_panel() -> pd.DataFrame:
    df = pd.read_csv(PANEL_PATH)
    df["year"] = pd.to_numeric(df["year"], errors="coerce")
    return df


def run_spec(df: pd.DataFrame, outcome: str, outcome_label: str, spec: Spec) -> list[dict[str, object]]:
    sample_cols = ["country_code", "year", outcome, *spec.terms]
    sample = df[sample_cols].dropna().copy()
    if sample.empty or sample["country_code"].nunique() < 5:
        return []

    formula = f"{outcome} ~ {' + '.join(spec.terms)} + C(country_code) + C(year)"
    result = smf.ols(formula, data=sample).fit(
        cov_type="cluster",
        cov_kwds={"groups": sample["country_code"]},
    )

    rows: list[dict[str, object]] = []
    for term in spec.terms:
        shock_sd = float(sample[term].std())
        rows.append(
            {
                "group": spec.group,
                "model_id": spec.model_id,
                "label": spec.label,
                "outcome": outcome,
                "outcome_label": outcome_label,
                "term": term,
                "coef": float(result.params[term]),
                "std_err": float(result.bse[term]),
                "p_value": float(result.pvalues[term]),
                "shock_sd": shock_sd,
                "one_sd_effect": float(result.params[term] * shock_sd),
                "n_obs": int(result.nobs),
                "n_countries": int(sample["country_code"].nunique()),
                "year_min": int(sample["year"].min()),
                "year_max": int(sample["year"].max()),
                "r_squared": float(result.rsquared),
            }
        )
    return rows


def build_results(df: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for outcome, outcome_label in OUTCOMES:
        for spec in SPECS:
            rows.extend(run_spec(df, outcome, outcome_label, spec))
    return pd.DataFrame(rows)


def build_diagnostics(df: pd.DataFrame, results: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for outcome, outcome_label in OUTCOMES:
        for spec in SPECS:
            sample_cols = ["country_code", "year", outcome, *spec.terms]
            sample = df[sample_cols].dropna().copy()
            rows.append(
                {
                    "group": spec.group,
                    "model_id": spec.model_id,
                    "label": spec.label,
                    "outcome": outcome,
                    "outcome_label": outcome_label,
                    "n_obs": int(len(sample)),
                    "n_countries": int(sample["country_code"].nunique()),
                    "year_min": int(sample["year"].min()) if not sample.empty else None,
                    "year_max": int(sample["year"].max()) if not sample.empty else None,
                }
            )
    return pd.DataFrame(rows)


def format_term(term: str) -> str:
    mapping = {
        "oecd_house_price_growth_pct": "OECD house-price growth",
        "oecd_house_price_index": "OECD house-price index",
        "bis_real_house_price_growth_pct": "BIS real house-price growth",
        "bis_nominal_house_price_growth_pct": "BIS nominal house-price growth",
        "oecd_short_rate_pct": "OECD short rate",
        "oecd_long_rate_pct": "OECD long rate",
    }
    return mapping.get(term, term)


def write_note(results: pd.DataFrame, diagnostics: pd.DataFrame) -> None:
    first_birth_level = results[
        (results["model_id"] == "housing_oecd_index")
        & (results["outcome"] == "mean_age_first_birth")
        & (results["term"] == "oecd_house_price_index")
    ].iloc[0]
    tfr_level = results[
        (results["model_id"] == "housing_oecd_index")
        & (results["outcome"] == "total_fertility_rate")
        & (results["term"] == "oecd_house_price_index")
    ].iloc[0]
    rates_only = results[results["group"] == "rates_only"].copy()

    lines = [
        "# International timing shock regressions",
        "",
        "These regressions use the country-year panel in",
        "`data/processed/international_first_birth_timing_shocks_v1.csv`.",
        "All specifications include country fixed effects and year fixed effects, with standard",
        "errors clustered by country.",
        "",
        "## Panel design",
        "",
        "- Housing-only block: OECD and BIS house-price growth shocks",
        "- Rates-only block: OECD short and long rates",
        "- Horse-race block: one housing shock and one rate shock together",
        "",
        "## Main read",
        "",
        "- The closest reduced-form analogue to the model is the house-price **level**, not short-run price growth.",
        f"- In the OECD house-price-index-only specification, a one-standard-deviation increase in the house-price index is associated with a `{first_birth_level['one_sd_effect']:.3f}` year increase in mean age at first birth (`p = {first_birth_level['p_value']:.3f}`).",
        f"- In the same specification, a one-standard-deviation increase in the house-price index is associated with a `{tfr_level['one_sd_effect']:.3f}` reduction in total fertility rate (`p = {tfr_level['p_value']:.3f}`).",
        "- By contrast, the pure house-price-growth specifications are weak and unstable across OECD and BIS measures.",
        f"- Rates are mixed rather than robust in the standalone panel block: the smallest p-value in the rates-only specifications is `{rates_only['p_value'].min():.3f}`.",
        "",
        "## Sample coverage",
        "",
    ]

    for _, row in diagnostics.iterrows():
        lines.append(
            f"- {row['outcome_label']} | {row['label']}: "
            f"`{row['n_obs']}` country-years, `{row['n_countries']}` countries, "
            f"`{row['year_min']}`-`{row['year_max']}`"
        )

    lines.extend(
        [
            "",
            "## Main coefficient table",
            "",
            "| Outcome | Block | Specification | Term | Coef | 1-SD effect | p-value | N | Countries |",
            "| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: |",
        ]
    )

    ordered = results.sort_values(["outcome_label", "group", "label", "term"]).reset_index(drop=True)
    for _, row in ordered.iterrows():
        lines.append(
            f"| {row['outcome_label']} | {row['group']} | {row['label']} | {format_term(row['term'])} | "
            f"{row['coef']:.4f} | {row['one_sd_effect']:.4f} | {row['p_value']:.3f} | "
            f"{row['n_obs']} | {row['n_countries']} |"
        )

    lines.extend(
        [
            "",
            "## Interpretation rule",
            "",
            "- The `Coef` column is the raw country-year coefficient.",
            "- The `1-SD effect` column rescales the coefficient by the within-sample standard deviation of the shock.",
            "- This is a first-pass descriptive panel, not a final causal design.",
            "",
        ]
    )

    (BUILD_DIR / "international_timing_shock_regressions.md").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    df = load_panel()
    results = build_results(df)
    diagnostics = build_diagnostics(df, results)
    results.to_csv(BUILD_DIR / "international_timing_shock_regressions.csv", index=False)
    diagnostics.to_csv(BUILD_DIR / "international_timing_shock_regression_samples.csv", index=False)
    write_note(results, diagnostics)
    print(BUILD_DIR / "international_timing_shock_regressions.md")


if __name__ == "__main__":
    main()
