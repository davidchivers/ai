#!/usr/bin/env python3
"""Run exploratory regressions on a state-year first-birth timing panel.

This script aggregates the county first-birth pull and county ACS denominators
to state-year, then merges those outcomes to state-aggregated metro housing and
labor-market proxies from the legacy NIMBY inputs.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import statsmodels.formula.api as smf


STATE_ABBR_TO_FIPS = {
    "AL": "01",
    "AK": "02",
    "AZ": "04",
    "AR": "05",
    "CA": "06",
    "CO": "08",
    "CT": "09",
    "DE": "10",
    "DC": "11",
    "FL": "12",
    "GA": "13",
    "HI": "15",
    "ID": "16",
    "IL": "17",
    "IN": "18",
    "IA": "19",
    "KS": "20",
    "KY": "21",
    "LA": "22",
    "ME": "23",
    "MD": "24",
    "MA": "25",
    "MI": "26",
    "MN": "27",
    "MS": "28",
    "MO": "29",
    "MT": "30",
    "NE": "31",
    "NV": "32",
    "NH": "33",
    "NJ": "34",
    "NM": "35",
    "NY": "36",
    "NC": "37",
    "ND": "38",
    "OH": "39",
    "OK": "40",
    "OR": "41",
    "PA": "42",
    "RI": "44",
    "SC": "45",
    "SD": "46",
    "TN": "47",
    "TX": "48",
    "UT": "49",
    "VT": "50",
    "VA": "51",
    "WA": "53",
    "WV": "54",
    "WI": "55",
    "WY": "56",
}

FERTILITY_NUMERIC = [
    "year",
    "first_births_total",
    "mean_age_first_birth",
    "share_first_birth_30_plus",
]
POPULATION_NUMERIC = [
    "year",
    "female_pop_15_44",
    "native_female_pop_15_44",
    "foreign_born_female_pop_15_44",
    "net_migration_rate",
    "international_migration_rate",
]
HOUSING_NUMERIC = [
    "year",
    "permits_total_pc",
    "real_rent_index",
    "housing_stock_growth",
    "housing_demand_shifter",
]
CONTROLS_NUMERIC = [
    "year",
    "unemployment_rate",
]


@dataclass
class ModelSpec:
    model_id: str
    label: str
    formula: str
    sample_mask: pd.Series
    terms: list[str]


def load_csv(path: Path, numeric_columns: list[str]) -> pd.DataFrame:
    df = pd.read_csv(path, low_memory=False)
    for column in numeric_columns:
        if column in df.columns:
            df[column] = pd.to_numeric(df[column], errors="coerce")
    return df


def build_state_year_panel(project_root: Path) -> pd.DataFrame:
    raw_dir = project_root / "data" / "raw"
    fertility = load_csv(raw_dir / "cdc_fertility_county_year.csv", FERTILITY_NUMERIC)
    population = load_csv(raw_dir / "population_immigration_county_year.csv", POPULATION_NUMERIC)
    housing = load_csv(raw_dir / "housing_county_year.csv", HOUSING_NUMERIC)
    controls = load_csv(raw_dir / "controls_county_year.csv", CONTROLS_NUMERIC)

    fertility["state_fips"] = fertility["state_fips"].fillna("").astype(str).str.zfill(2)
    population["state_fips"] = population["state_fips"].fillna("").astype(str).str.zfill(2)
    housing["state_fips"] = (
        housing["state_fips"].fillna("").astype(str).str.strip().str.upper().map(STATE_ABBR_TO_FIPS)
    )
    controls["state_fips"] = (
        controls["state_fips"].fillna("").astype(str).str.strip().str.upper().map(STATE_ABBR_TO_FIPS)
    )

    fertility = fertility.dropna(subset=["year"])
    population = population.dropna(subset=["year"])
    housing = housing.dropna(subset=["year"])
    controls = controls.dropna(subset=["year"])

    fertility = fertility[fertility["state_fips"].ne("")]
    population = population[population["state_fips"].ne("")]
    housing = housing[housing["state_fips"].notna()]
    controls = controls[controls["state_fips"].notna()]

    fertility["weighted_age"] = fertility["mean_age_first_birth"] * fertility["first_births_total"]
    fertility["weighted_share_30_plus"] = (
        fertility["share_first_birth_30_plus"] * fertility["first_births_total"]
    )
    fertility_state = fertility.groupby(["state_fips", "year"], as_index=False).agg(
        first_births_total=("first_births_total", "sum"),
        weighted_age=("weighted_age", "sum"),
        weighted_share_30_plus=("weighted_share_30_plus", "sum"),
        n_counties_with_fertility=("fips", "nunique"),
    )
    fertility_state["mean_age_first_birth"] = (
        fertility_state["weighted_age"] / fertility_state["first_births_total"]
    )
    fertility_state["share_first_birth_30_plus"] = (
        fertility_state["weighted_share_30_plus"] / fertility_state["first_births_total"]
    )
    fertility_state = fertility_state.drop(columns=["weighted_age", "weighted_share_30_plus"])

    population_state = population.groupby(["state_fips", "year"], as_index=False).agg(
        female_pop_15_44=("female_pop_15_44", "sum"),
        native_female_pop_15_44=("native_female_pop_15_44", "sum"),
        foreign_born_female_pop_15_44=("foreign_born_female_pop_15_44", "sum"),
        net_migration_rate=("net_migration_rate", "mean"),
        international_migration_rate=("international_migration_rate", "mean"),
        n_counties_with_population=("fips", "nunique"),
    )
    population_state["foreign_born_share_15_44"] = (
        population_state["foreign_born_female_pop_15_44"] / population_state["female_pop_15_44"]
    )

    housing_state = housing.groupby(["state_fips", "year"], as_index=False).agg(
        permits_total_pc=("permits_total_pc", "mean"),
        real_rent_index=("real_rent_index", "mean"),
        housing_stock_growth=("housing_stock_growth", "mean"),
        housing_demand_shifter=("housing_demand_shifter", "mean"),
        n_metros_housing=("metarea", "nunique"),
    )
    controls_state = controls.groupby(["state_fips", "year"], as_index=False).agg(
        unemployment_rate=("unemployment_rate", "mean"),
        n_metros_controls=("metarea", "nunique"),
    )

    panel = fertility_state.merge(population_state, how="left", on=["state_fips", "year"])
    panel["first_birth_rate_15_44"] = 1000.0 * panel["first_births_total"] / panel["female_pop_15_44"]
    panel = panel.merge(housing_state, how="left", on=["state_fips", "year"])
    panel = panel.merge(controls_state, how="left", on=["state_fips", "year"])
    panel = panel.sort_values(["state_fips", "year"]).reset_index(drop=True)
    return panel


def run_model(df: pd.DataFrame, spec: ModelSpec) -> list[dict[str, object]]:
    sample = df.loc[spec.sample_mask].copy()
    result = smf.ols(spec.formula, data=sample).fit(
        cov_type="cluster",
        cov_kwds={"groups": sample["state_fips"]},
    )

    rows: list[dict[str, object]] = []
    for term in spec.terms:
        if term not in result.params.index:
            continue
        rows.append(
            {
                "model_id": spec.model_id,
                "label": spec.label,
                "term": term,
                "coef": float(result.params[term]),
                "std_err": float(result.bse[term]),
                "p_value": float(result.pvalues[term]),
                "n_obs": int(result.nobs),
                "n_states": int(sample["state_fips"].nunique()),
                "year_min": int(sample["year"].min()),
                "year_max": int(sample["year"].max()),
                "r_squared": float(result.rsquared),
            }
        )
    return rows


def build_specs(df: pd.DataFrame) -> list[ModelSpec]:
    rent_unemp_rate = df[["first_birth_rate_15_44", "real_rent_index", "unemployment_rate"]].notna().all(axis=1)
    rent_unemp_age = df[["mean_age_first_birth", "real_rent_index", "unemployment_rate"]].notna().all(axis=1)
    rent_unemp_share = df[["share_first_birth_30_plus", "real_rent_index", "unemployment_rate"]].notna().all(axis=1)
    permits_rate = df[["first_birth_rate_15_44", "permits_total_pc"]].notna().all(axis=1)
    permits_age = df[["mean_age_first_birth", "permits_total_pc"]].notna().all(axis=1)

    return [
        ModelSpec(
            model_id="rate_rent_unemp",
            label="State and year FE: first-birth rate on rents and unemployment",
            formula="first_birth_rate_15_44 ~ real_rent_index + unemployment_rate + C(state_fips) + C(year)",
            sample_mask=rent_unemp_rate,
            terms=["real_rent_index", "unemployment_rate"],
        ),
        ModelSpec(
            model_id="age_rent_unemp",
            label="State and year FE: mean age at first birth on rents and unemployment",
            formula="mean_age_first_birth ~ real_rent_index + unemployment_rate + C(state_fips) + C(year)",
            sample_mask=rent_unemp_age,
            terms=["real_rent_index", "unemployment_rate"],
        ),
        ModelSpec(
            model_id="share30_rent_unemp",
            label="State and year FE: share age 30+ among first births on rents and unemployment",
            formula="share_first_birth_30_plus ~ real_rent_index + unemployment_rate + C(state_fips) + C(year)",
            sample_mask=rent_unemp_share,
            terms=["real_rent_index", "unemployment_rate"],
        ),
        ModelSpec(
            model_id="rate_permits",
            label="State and year FE: first-birth rate on permits",
            formula="first_birth_rate_15_44 ~ permits_total_pc + C(state_fips) + C(year)",
            sample_mask=permits_rate,
            terms=["permits_total_pc"],
        ),
        ModelSpec(
            model_id="age_permits",
            label="State and year FE: mean age at first birth on permits",
            formula="mean_age_first_birth ~ permits_total_pc + C(state_fips) + C(year)",
            sample_mask=permits_age,
            terms=["permits_total_pc"],
        ),
    ]


def panel_diagnostics(df: pd.DataFrame) -> dict[str, object]:
    diagnostics = {
        "row_count": int(len(df)),
        "n_states_total": int(df["state_fips"].nunique()),
        "year_min": int(df["year"].min()),
        "year_max": int(df["year"].max()),
        "overlap_rate_pop": int(df[["first_birth_rate_15_44", "female_pop_15_44"]].notna().all(axis=1).sum()),
        "overlap_rate_rent_unemp": int(
            df[["first_birth_rate_15_44", "real_rent_index", "unemployment_rate"]].notna().all(axis=1).sum()
        ),
        "overlap_age_rent_unemp": int(
            df[["mean_age_first_birth", "real_rent_index", "unemployment_rate"]].notna().all(axis=1).sum()
        ),
        "overlap_share30_rent_unemp": int(
            df[["share_first_birth_30_plus", "real_rent_index", "unemployment_rate"]].notna().all(axis=1).sum()
        ),
        "overlap_rate_permits": int(df[["first_birth_rate_15_44", "permits_total_pc"]].notna().all(axis=1).sum()),
        "fertility_year_min": int(df.loc[df["first_births_total"].notna(), "year"].min()),
        "fertility_year_max": int(df.loc[df["first_births_total"].notna(), "year"].max()),
        "population_year_min": int(df.loc[df["female_pop_15_44"].notna(), "year"].min()),
        "population_year_max": int(df.loc[df["female_pop_15_44"].notna(), "year"].max()),
        "housing_year_min": int(df.loc[df["real_rent_index"].notna(), "year"].min()),
        "housing_year_max": int(df.loc[df["real_rent_index"].notna(), "year"].max()),
        "permits_year_min": int(df.loc[df["permits_total_pc"].notna(), "year"].min()),
        "permits_year_max": int(df.loc[df["permits_total_pc"].notna(), "year"].max()),
    }
    return diagnostics


def format_float(value: float) -> str:
    return f"{value:.4f}"


def write_markdown(
    output_path: Path,
    diagnostics: dict[str, object],
    results: pd.DataFrame,
) -> None:
    lines = [
        "# Exploratory regression summary",
        "",
        "These regressions use a state-year exploratory panel built from the raw source files.",
        "The reason is mechanical: the new fertility data are county-year, while the legacy",
        "housing and policy files are metro-year, so direct local-key overlap is zero in the",
        "current processed panel.",
        "",
        "## Panel diagnostics",
        "",
        f"- State-year panel rows: {diagnostics['row_count']}",
        f"- Distinct states: {diagnostics['n_states_total']}",
        f"- Overall year span: {diagnostics['year_min']} to {diagnostics['year_max']}",
        f"- First-birth coverage: {diagnostics['fertility_year_min']} to {diagnostics['fertility_year_max']}",
        f"- Female-population coverage: {diagnostics['population_year_min']} to {diagnostics['population_year_max']}",
        f"- Rent coverage: {diagnostics['housing_year_min']} to {diagnostics['housing_year_max']}",
        f"- Permits coverage: {diagnostics['permits_year_min']} to {diagnostics['permits_year_max']}",
        f"- Overlap of `first_birth_rate_15_44` with denominators: {diagnostics['overlap_rate_pop']} rows",
        f"- Overlap of `first_birth_rate_15_44` with rents and unemployment: {diagnostics['overlap_rate_rent_unemp']} rows",
        f"- Overlap of `mean_age_first_birth` with rents and unemployment: {diagnostics['overlap_age_rent_unemp']} rows",
        f"- Overlap of `share_first_birth_30_plus` with rents and unemployment: {diagnostics['overlap_share30_rent_unemp']} rows",
        f"- Overlap of `first_birth_rate_15_44` with permits: {diagnostics['overlap_rate_permits']} rows",
        "",
        "Main caveats:",
        "- fertility is aggregated from county first-birth counts identified in CDC WONDER, so the",
        "  sample over-represents large counties rather than all counties in a state.",
        "- housing and unemployment series are state-year averages of legacy metro-year inputs.",
        "- permits coverage is much thinner than rent coverage, so those coefficients are especially tentative.",
        "",
        "## Regression results",
        "",
        "| model_id | term | coef | std_err | p_value | n_obs | n_states | years |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |",
    ]

    for _, row in results.iterrows():
        years = f"{int(row['year_min'])}-{int(row['year_max'])}"
        lines.append(
            f"| {row['model_id']} | {row['term']} | {format_float(row['coef'])} | "
            f"{format_float(row['std_err'])} | {format_float(row['p_value'])} | "
            f"{int(row['n_obs'])} | {int(row['n_states'])} | {years} |"
        )

    lines.extend(
        [
            "",
            "## Readout",
            "",
            "- `rate_rent_unemp` uses the cleanest overlap sample for first-birth rates, but it only runs from 2010 to 2017.",
            "- `age_rent_unemp` and `share30_rent_unemp` use a wider 2007 to 2017 overlap because they do not need population denominators.",
            "- `rate_permits` and `age_permits` are based on a thin permits sample and should be treated as a rough sign check only.",
        ]
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    output_dir = project_root / "notes" / "build"
    panel_path = output_dir / "exploratory_state_year_panel.csv"
    csv_path = output_dir / "exploratory_regression_results.csv"
    md_path = output_dir / "exploratory_regression_summary.md"

    df = build_state_year_panel(project_root)
    diagnostics = panel_diagnostics(df)
    specs = build_specs(df)

    rows: list[dict[str, object]] = []
    for spec in specs:
        rows.extend(run_model(df, spec))

    results = pd.DataFrame(rows)
    output_dir.mkdir(parents=True, exist_ok=True)
    df.to_csv(panel_path, index=False)
    results.to_csv(csv_path, index=False)
    write_markdown(md_path, diagnostics=diagnostics, results=results)

    print(f"Wrote: {panel_path}")
    print(f"Wrote: {csv_path}")
    print(f"Wrote: {md_path}")


if __name__ == "__main__":
    main()
