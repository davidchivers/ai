#!/usr/bin/env python3
"""Run England greenbelt exposure regressions with baseline poshness controls."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import statsmodels.formula.api as smf


ROOT = Path(__file__).resolve().parents[1]
PANEL_PATH = ROOT / "data" / "processed" / "england_greenbelt_fertility_panel_v1.csv"
CONTROLS_PATH = ROOT / "data" / "processed" / "england_greenbelt_baseline_controls_v1.csv"
BUILD_DIR = ROOT / "notes" / "build"


OUTCOMES = [
    ("ln_ukhpi_average_price", "Log local house price"),
    ("share_births_30_plus", "Share of births at age 30+"),
    ("mean_age_mother_standardised", "Standardised mean age of mother"),
    ("total_fertility_rate", "Total fertility rate"),
    ("asfr_under_20", "ASFR under 20"),
    ("asfr_30_34", "ASFR 30-34"),
]

PRE_PERIOD_YEARS = [2014, 2015, 2016, 2017, 2018]
POST_START = 2019


@dataclass(frozen=True)
class Spec:
    model_id: str
    label: str
    outcomes: tuple[str, ...]
    terms: tuple[str, ...]
    fixed_effects: tuple[str, ...]


SPECS = [
    Spec(
        model_id="exposure_post2019_area_year_fe",
        label="Greenbelt exposure x post-2019 with area and year fixed effects",
        outcomes=tuple(name for name, _ in OUTCOMES),
        terms=("gb_exposure_post2019",),
        fixed_effects=("area_code", "year"),
    ),
    Spec(
        model_id="exposure_post2019_area_region_year_fe",
        label="Greenbelt exposure x post-2019 with area and region-year fixed effects",
        outcomes=tuple(name for name, _ in OUTCOMES),
        terms=("gb_exposure_post2019",),
        fixed_effects=("area_code", "region_year"),
    ),
    Spec(
        model_id="exposure_post2019_posh_controls",
        label="Greenbelt exposure x post-2019 with area FE, region-year FE, and baseline poshness controls",
        outcomes=tuple(name for name, _ in OUTCOMES),
        terms=(
            "gb_exposure_post2019",
            "degree_share_2011_post2019",
            "owner_occ_share_2011_post2019",
            "mgr_prof_share_2011_post2019",
            "baseline_ln_price_pre_post2019",
            "baseline_share30_pre_post2019",
            "baseline_mean_age_pre_post2019",
            "baseline_tfr_pre_post2019",
        ),
        fixed_effects=("area_code", "region_year"),
    ),
]


def load_panel() -> pd.DataFrame:
    df = pd.read_csv(PANEL_PATH)
    controls = pd.read_csv(CONTROLS_PATH)
    df["year"] = pd.to_numeric(df["year"], errors="coerce")
    df = df.merge(
        controls[
            [
                "area_code",
                "region_name",
                "degree_share_2011",
                "owner_occ_share_2011",
                "mgr_prof_share_2011",
            ]
        ],
        on="area_code",
        how="left",
    )

    pre = (
        df[df["year"].isin(PRE_PERIOD_YEARS)]
        .groupby("area_code", as_index=False)
        .agg(
            greenbelt_share_pre=("greenbelt_share_pct", "mean"),
            baseline_ln_price_pre=("ln_ukhpi_average_price", "mean"),
            baseline_share30_pre=("share_births_30_plus", "mean"),
            baseline_mean_age_pre=("mean_age_mother_standardised", "mean"),
            baseline_tfr_pre=("total_fertility_rate", "mean"),
        )
    )
    df = df.merge(pre, on="area_code", how="left")
    df["post2019"] = (df["year"] >= POST_START).astype(int)
    df["region_year"] = df["region_name"].fillna("Missing") + "_" + df["year"].astype("Int64").astype(str)

    base_terms = [
        "greenbelt_share_pre",
        "degree_share_2011",
        "owner_occ_share_2011",
        "mgr_prof_share_2011",
        "baseline_ln_price_pre",
        "baseline_share30_pre",
        "baseline_mean_age_pre",
        "baseline_tfr_pre",
    ]
    for term in base_terms:
        df[f"{term}_post2019"] = df[term] * df["post2019"]
    df["gb_exposure_post2019"] = df["greenbelt_share_pre_post2019"]
    return df


def build_formula(outcome: str, spec: Spec) -> str:
    rhs_terms = list(spec.terms)
    rhs_terms.extend(f"C({fe})" for fe in spec.fixed_effects)
    return f"{outcome} ~ {' + '.join(rhs_terms)}"


def one_sd_effect(sample: pd.DataFrame, term: str, coef: float) -> float:
    if term == "gb_exposure_post2019":
        return coef * float(sample["greenbelt_share_pre"].std())
    return coef * float(sample[term].std())


def run_spec(df: pd.DataFrame, outcome: str, outcome_label: str, spec: Spec) -> list[dict[str, object]]:
    sample_cols = [
        "area_code",
        "year",
        "region_year",
        "greenbelt_share_pre",
        outcome,
        *spec.terms,
    ]
    sample = df[sample_cols].dropna().copy()
    if sample.empty or sample["area_code"].nunique() < 40:
        return []

    formula = build_formula(outcome, spec)
    result = smf.ols(formula, data=sample).fit(
        cov_type="cluster",
        cov_kwds={"groups": sample["area_code"]},
    )

    rows: list[dict[str, object]] = []
    for term in spec.terms:
        rows.append(
            {
                "model_id": spec.model_id,
                "label": spec.label,
                "outcome": outcome,
                "outcome_label": outcome_label,
                "term": term,
                "coef": float(result.params[term]),
                "std_err": float(result.bse[term]),
                "p_value": float(result.pvalues[term]),
                "one_sd_effect": one_sd_effect(sample, term, float(result.params[term])),
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
            sample_cols = [
                "area_code",
                "year",
                "region_year",
                "greenbelt_share_pre",
                outcome,
                *spec.terms,
            ]
            sample = df[sample_cols].dropna().copy()
            rows.append(
                {
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


def pick_result(results: pd.DataFrame, model_id: str, outcome: str, term: str) -> pd.Series:
    return results[
        (results["model_id"] == model_id)
        & (results["outcome"] == outcome)
        & (results["term"] == term)
    ].iloc[0]


def write_note(results: pd.DataFrame, diagnostics: pd.DataFrame) -> None:
    share30_simple = pick_result(results, "exposure_post2019_area_year_fe", "share_births_30_plus", "gb_exposure_post2019")
    share30_region = pick_result(results, "exposure_post2019_area_region_year_fe", "share_births_30_plus", "gb_exposure_post2019")
    share30_control = pick_result(results, "exposure_post2019_posh_controls", "share_births_30_plus", "gb_exposure_post2019")
    meanage_control = pick_result(results, "exposure_post2019_posh_controls", "mean_age_mother_standardised", "gb_exposure_post2019")
    price_control = pick_result(results, "exposure_post2019_posh_controls", "ln_ukhpi_average_price", "gb_exposure_post2019")
    tfr_control = pick_result(results, "exposure_post2019_posh_controls", "total_fertility_rate", "gb_exposure_post2019")
    under20_control = pick_result(results, "exposure_post2019_posh_controls", "asfr_under_20", "gb_exposure_post2019")
    asfr3034_control = pick_result(results, "exposure_post2019_posh_controls", "asfr_30_34", "gb_exposure_post2019")

    lines = [
        "# England greenbelt controlled regressions",
        "",
        "These regressions replace the raw greenbelt cross-section with a post-2019 exposure design.",
        "The identifying term is `greenbelt_share_pre x post2019`, where `greenbelt_share_pre` is the",
        "authority mean over `2014-2018`.",
        "",
        "The controlled specification adds:",
        "",
        "- local-authority fixed effects",
        "- region-year fixed effects",
        "- 2011 baseline degree share, owner-occupation share, and managers/professionals share, all interacted with `post2019`",
        "- pre-2019 baseline log house price, share of births at age 30+, mean age of mother, and TFR, all interacted with `post2019`",
        "",
        "## Main read",
        "",
        f"- For `share_births_30_plus`, the greenbelt exposure effect is `{share30_simple['one_sd_effect']:.4f}` in the area-year specification (`p = {share30_simple['p_value']:.3f}`), `{share30_region['one_sd_effect']:.4f}` with region-year fixed effects (`p = {share30_region['p_value']:.3f}`), and `{share30_control['one_sd_effect']:.4f}` after adding baseline poshness controls (`p = {share30_control['p_value']:.3f}`).",
        f"- In the fully controlled specification, the same exposure term implies `{meanage_control['one_sd_effect']:.4f}` years on standardised mean age of mother (`p = {meanage_control['p_value']:.3f}`).",
        f"- The local price validation in the controlled specification is `{price_control['one_sd_effect']:.4f}` log points (`p = {price_control['p_value']:.3f}`).",
        f"- The fertility-level effect in the controlled specification is `{tfr_control['one_sd_effect']:.4f}` on TFR (`p = {tfr_control['p_value']:.3f}`).",
        f"- The age-profile margins in the controlled specification are `{under20_control['one_sd_effect']:.4f}` on `ASFR under 20` (`p = {under20_control['p_value']:.3f}`) and `{asfr3034_control['one_sd_effect']:.4f}` on `ASFR 30-34` (`p = {asfr3034_control['p_value']:.3f}`).",
        "- The raw greenbelt timing gradient does not survive this stricter design. Once authority fixed effects, region-year fixed effects, and baseline affluent-place controls are added, the greenbelt exposure term is small and imprecise on both timing and fertility outcomes.",
        "",
        "## Interpretation",
        "",
        "- This design is stricter than the raw cross-section because time-invariant affluent-place differences are absorbed by authority fixed effects.",
        "- The remaining exposure variation comes from whether high-greenbelt authorities move differently after `2019` within regions.",
        "- In this controlled pass, the answer is mostly no: the earlier England timing gradient looks largely cross-sectional and consistent with poshness or regional composition rather than a clean post-2019 greenbelt exposure effect.",
        "- That shifts the empirical weight back toward the local-price results and away from raw greenbelt exposure as the headline England reduced form.",
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
            "## Coefficient table",
            "",
            "| Outcome | Block | Term | Coef | 1-SD effect | p-value | N | Authorities |",
            "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |",
        ]
    )

    ordered = results.sort_values(["outcome_label", "model_id", "term"]).reset_index(drop=True)
    for _, row in ordered.iterrows():
        lines.append(
            f"| {row['outcome_label']} | {row['label']} | {row['term']} | "
            f"{row['coef']:.4f} | {row['one_sd_effect']:.4f} | {row['p_value']:.3f} | "
            f"{row['n_obs']} | {row['n_areas']} |"
        )

    (BUILD_DIR / "england_greenbelt_controlled_regressions.md").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    df = load_panel()
    results = build_results(df)
    diagnostics = build_diagnostics(df)
    results.to_csv(BUILD_DIR / "england_greenbelt_controlled_regressions.csv", index=False)
    diagnostics.to_csv(BUILD_DIR / "england_greenbelt_controlled_regression_samples.csv", index=False)
    write_note(results, diagnostics)
    print(BUILD_DIR / "england_greenbelt_controlled_regressions.md")


if __name__ == "__main__":
    main()
