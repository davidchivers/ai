#!/usr/bin/env python3
"""Run first-pass England greenbelt and fertility timing regressions."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import statsmodels.formula.api as smf


ROOT = Path(__file__).resolve().parents[1]
PANEL_PATH = ROOT / "data" / "processed" / "england_greenbelt_fertility_panel_v1.csv"
BUILD_DIR = ROOT / "notes" / "build"


OUTCOMES = [
    ("ln_ukhpi_average_price", "Log local house price"),
    ("share_births_30_plus", "Share of births at age 30+"),
    ("mean_age_mother_standardised", "Standardised mean age of mother"),
    ("total_fertility_rate", "Total fertility rate"),
    ("general_fertility_rate", "General fertility rate"),
    ("asfr_under_20", "ASFR under 20"),
    ("asfr_20_24", "ASFR 20-24"),
    ("asfr_30_34", "ASFR 30-34"),
    ("asfr_35_39", "ASFR 35-39"),
]


@dataclass(frozen=True)
class Spec:
    group: str
    model_id: str
    label: str
    outcomes: tuple[str, ...]
    terms: tuple[str, ...]
    fixed_effects: tuple[str, ...]


SPECS = [
    Spec(
        group="greenbelt_year_fe",
        model_id="greenbelt_year_fe",
        label="Greenbelt exposure with year fixed effects",
        outcomes=tuple(name for name, _ in OUTCOMES),
        terms=("greenbelt_share_pct",),
        fixed_effects=("year",),
    ),
    Spec(
        group="price_year_fe",
        model_id="price_year_fe",
        label="Local price with year fixed effects",
        outcomes=(
            "share_births_30_plus",
            "mean_age_mother_standardised",
            "total_fertility_rate",
            "general_fertility_rate",
        ),
        terms=("ln_ukhpi_average_price",),
        fixed_effects=("year",),
    ),
    Spec(
        group="horse_race_year_fe",
        model_id="horse_race_year_fe",
        label="Greenbelt exposure and local price with year fixed effects",
        outcomes=(
            "share_births_30_plus",
            "mean_age_mother_standardised",
            "total_fertility_rate",
            "general_fertility_rate",
        ),
        terms=("greenbelt_share_pct", "ln_ukhpi_average_price"),
        fixed_effects=("year",),
    ),
    Spec(
        group="greenbelt_area_year_fe",
        model_id="greenbelt_area_year_fe",
        label="Greenbelt exposure with area and year fixed effects",
        outcomes=(
            "ln_ukhpi_average_price",
            "share_births_30_plus",
            "mean_age_mother_standardised",
            "total_fertility_rate",
        ),
        terms=("greenbelt_share_pct",),
        fixed_effects=("area_code", "year"),
    ),
]


def load_panel() -> pd.DataFrame:
    df = pd.read_csv(PANEL_PATH)
    df["year"] = pd.to_numeric(df["year"], errors="coerce")
    return df


def build_formula(outcome: str, spec: Spec) -> str:
    rhs_terms = list(spec.terms)
    rhs_terms.extend(f"C({fe})" for fe in spec.fixed_effects)
    return f"{outcome} ~ {' + '.join(rhs_terms)}"


def run_spec(df: pd.DataFrame, outcome: str, outcome_label: str, spec: Spec) -> list[dict[str, object]]:
    sample_cols = ["area_code", "year", outcome, *spec.terms]
    sample = df[sample_cols].dropna().copy()
    if sample.empty or sample["area_code"].nunique() < 20:
        return []

    formula = build_formula(outcome, spec)
    result = smf.ols(formula, data=sample).fit(
        cov_type="cluster",
        cov_kwds={"groups": sample["area_code"]},
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
                "n_areas": int(sample["area_code"].nunique()),
                "year_min": int(sample["year"].min()),
                "year_max": int(sample["year"].max()),
                "r_squared": float(result.rsquared),
            }
        )
    return rows


def build_results(df: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    label_map = dict(OUTCOMES)
    for spec in SPECS:
        for outcome in spec.outcomes:
            rows.extend(run_spec(df, outcome, label_map[outcome], spec))
    return pd.DataFrame(rows)


def build_diagnostics(df: pd.DataFrame) -> pd.DataFrame:
    rows = []
    label_map = dict(OUTCOMES)
    for spec in SPECS:
        for outcome in spec.outcomes:
            sample_cols = ["area_code", "year", outcome, *spec.terms]
            sample = df[sample_cols].dropna().copy()
            rows.append(
                {
                    "group": spec.group,
                    "model_id": spec.model_id,
                    "label": spec.label,
                    "outcome": outcome,
                    "outcome_label": label_map[outcome],
                    "n_obs": int(len(sample)),
                    "n_areas": int(sample["area_code"].nunique()),
                    "year_min": int(sample["year"].min()) if not sample.empty else None,
                    "year_max": int(sample["year"].max()) if not sample.empty else None,
                }
            )
    return pd.DataFrame(rows)


def format_term(term: str) -> str:
    mapping = {
        "greenbelt_share_pct": "Greenbelt share (pp)",
        "ln_ukhpi_average_price": "Log local house price",
    }
    return mapping.get(term, term)


def pick_result(results: pd.DataFrame, model_id: str, outcome: str, term: str) -> pd.Series:
    return results[
        (results["model_id"] == model_id)
        & (results["outcome"] == outcome)
        & (results["term"] == term)
    ].iloc[0]


def write_note(results: pd.DataFrame, diagnostics: pd.DataFrame) -> None:
    share30_greenbelt = pick_result(results, "greenbelt_year_fe", "share_births_30_plus", "greenbelt_share_pct")
    meanage_greenbelt = pick_result(results, "greenbelt_year_fe", "mean_age_mother_standardised", "greenbelt_share_pct")
    tfr_greenbelt = pick_result(results, "greenbelt_year_fe", "total_fertility_rate", "greenbelt_share_pct")
    price_greenbelt = pick_result(results, "greenbelt_year_fe", "ln_ukhpi_average_price", "greenbelt_share_pct")
    under20_greenbelt = pick_result(results, "greenbelt_year_fe", "asfr_under_20", "greenbelt_share_pct")
    asfr3034_greenbelt = pick_result(results, "greenbelt_year_fe", "asfr_30_34", "greenbelt_share_pct")
    share30_price = pick_result(results, "price_year_fe", "share_births_30_plus", "ln_ukhpi_average_price")
    tfr_price = pick_result(results, "price_year_fe", "total_fertility_rate", "ln_ukhpi_average_price")
    share30_horse_greenbelt = pick_result(results, "horse_race_year_fe", "share_births_30_plus", "greenbelt_share_pct")
    share30_horse_price = pick_result(results, "horse_race_year_fe", "share_births_30_plus", "ln_ukhpi_average_price")
    within_share30 = pick_result(results, "greenbelt_area_year_fe", "share_births_30_plus", "greenbelt_share_pct")
    within_price = pick_result(results, "greenbelt_area_year_fe", "ln_ukhpi_average_price", "greenbelt_share_pct")

    lines = [
        "# England greenbelt regressions",
        "",
        "These regressions use `data/processed/england_greenbelt_fertility_panel_v1.csv`.",
        "All specifications cluster standard errors by local authority.",
        "",
        "## Regression blocks",
        "",
        "- `greenbelt_year_fe`: greenbelt exposure with year fixed effects",
        "- `price_year_fe`: local house price with year fixed effects",
        "- `horse_race_year_fe`: greenbelt exposure and local house price together with year fixed effects",
        "- `greenbelt_area_year_fe`: greenbelt exposure with local-authority and year fixed effects",
        "",
        "## Main read",
        "",
        f"- In the year-fixed-effects cross-section, higher greenbelt exposure is associated with later childbearing: a one-standard-deviation increase in greenbelt share raises `share_births_30_plus` by `{share30_greenbelt['one_sd_effect']:.3f}` (`p = {share30_greenbelt['p_value']:.3f}`).",
        f"- The same greenbelt block points in the same direction for age, but less precisely: the one-standard-deviation effect on standardised mean age of mother is `{meanage_greenbelt['one_sd_effect']:.3f}` years (`p = {meanage_greenbelt['p_value']:.3f}`).",
        f"- The age-profile evidence is sharper than the aggregate-price validation: greenbelt exposure lowers `ASFR under 20` by `{under20_greenbelt['one_sd_effect']:.3f}` (`p = {under20_greenbelt['p_value']:.3f}`) and raises `ASFR 30-34` by `{asfr3034_greenbelt['one_sd_effect']:.3f}` (`p = {asfr3034_greenbelt['p_value']:.3f}`).",
        f"- The house-price validation line is positive but imprecise: the one-standard-deviation effect of greenbelt exposure on `ln(price)` is `{price_greenbelt['one_sd_effect']:.3f}` (`p = {price_greenbelt['p_value']:.3f}`).",
        f"- The fertility-level result does not line up with a simple scarcity story in this cross-section: the one-standard-deviation greenbelt effect on total fertility rate is `{tfr_greenbelt['one_sd_effect']:.3f}` (`p = {tfr_greenbelt['p_value']:.3f}`).",
        f"- Local prices themselves move exactly in the model's timing direction: a one-standard-deviation increase in `ln(price)` raises `share_births_30_plus` by `{share30_price['one_sd_effect']:.3f}` (`p = {share30_price['p_value']:.3f}`) and lowers total fertility rate by `{tfr_price['one_sd_effect']:.3f}` (`p = {tfr_price['p_value']:.3f}`).",
        f"- In the simple horse race, both greenbelt exposure and local prices retain independent timing gradients for `share_births_30_plus`: greenbelt `{share30_horse_greenbelt['one_sd_effect']:.3f}` (`p = {share30_horse_greenbelt['p_value']:.3f}`), price `{share30_horse_price['one_sd_effect']:.3f}` (`p = {share30_horse_price['p_value']:.3f}`).",
        f"- Within-authority greenbelt changes do not currently identify anything precise: the area-and-year fixed-effects coefficient is `{within_share30['coef']:.6f}` on `share_births_30_plus` (`p = {within_share30['p_value']:.3f}`) and `{within_price['coef']:.6f}` on `ln(price)` (`p = {within_price['p_value']:.3f}`).",
        "",
        "## Interpretation",
        "",
        "- The England panel is currently strongest as a timing/composition result, not yet as a clean quantity result.",
        "- Greenbelt exposure lines up with fewer younger births and more older births.",
        "- Local prices line up with later births and lower fertility more cleanly than greenbelt exposure does.",
        "- The within-authority design is weak because greenbelt exposure barely moves over time in the current panel.",
        "",
        "## Sample coverage",
        "",
    ]

    for _, row in diagnostics.iterrows():
        lines.append(
            f"- {row['outcome_label']} | {row['label']}: "
            f"`{row['n_obs']}` authority-years, `{row['n_areas']}` authorities, "
            f"`{row['year_min']}`-`{row['year_max']}`"
        )

    lines.extend(
        [
            "",
            "## Main coefficient table",
            "",
            "| Outcome | Block | Term | Coef | 1-SD effect | p-value | N | Authorities |",
            "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |",
        ]
    )

    ordered = results.sort_values(["outcome_label", "group", "term"]).reset_index(drop=True)
    for _, row in ordered.iterrows():
        lines.append(
            f"| {row['outcome_label']} | {row['label']} | {format_term(row['term'])} | "
            f"{row['coef']:.4f} | {row['one_sd_effect']:.4f} | {row['p_value']:.3f} | "
            f"{row['n_obs']} | {row['n_areas']} |"
        )

    lines.extend(
        [
            "",
            "## Caveat",
            "",
            "- These are first-pass descriptive England regressions, not yet the final planning-reform design.",
            "- The remaining geography issue is the old district codes that still survive in the NOMIS fertility pull.",
            "",
        ]
    )

    (BUILD_DIR / "england_greenbelt_regressions.md").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    df = load_panel()
    results = build_results(df)
    diagnostics = build_diagnostics(df)
    results.to_csv(BUILD_DIR / "england_greenbelt_regressions.csv", index=False)
    diagnostics.to_csv(BUILD_DIR / "england_greenbelt_regression_samples.csv", index=False)
    write_note(results, diagnostics)
    print(BUILD_DIR / "england_greenbelt_regressions.md")


if __name__ == "__main__":
    main()
