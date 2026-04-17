from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
DIFFUSION_PANEL_PATH = SCENE_DIR / "diffusion" / "black_metal_diffusion_exposure_panel.csv"
BAND_CLEAN_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"

LV_ROOT = PROJECT_ROOT.parent / "learning_by_viewing" / "music"
COUNTRY_INTERNET_PATH = (
    LV_ROOT / "data" / "strategy_8_music_pilot" / "processed" / "country_year_treatment_panel.csv"
)

RESULTS_PATH = SCENE_DIR / "diffusion" / "black_metal_internet_diffusion_smoke_results.csv"
SUMMARY_PATH = SCENE_DIR / "diffusion" / "black_metal_internet_diffusion_smoke_summary.md"


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def load_country_lookup() -> pd.DataFrame:
    bands = pd.read_csv(BAND_CLEAN_PATH, usecols=["country_std", "countryiso3code"])
    bands = bands.dropna().drop_duplicates()
    bands = bands.rename(columns={"country_std": "country"})
    bands = bands.sort_values(["country", "countryiso3code"]).drop_duplicates(subset=["country"], keep="first")
    return bands


def load_panel() -> pd.DataFrame:
    panel = pd.read_csv(DIFFUSION_PANEL_PATH)
    panel["snapshot_year"] = pd.to_numeric(panel["snapshot_year"], errors="coerce").astype(int)
    panel["emergence_this_year_i"] = pd.to_numeric(panel["emergence_this_year_i"], errors="coerce").fillna(0).astype(int)
    for column in [
        "lag_log_local_active_bands",
        "lag_exposure_emerged_hubs",
        "lag_exposure_emerged_active_bands",
        "lag_nearest_emerged_hub_km",
    ]:
        if column in panel.columns:
            panel[column] = pd.to_numeric(panel[column], errors="coerce")
    return panel


def load_country_internet() -> pd.DataFrame:
    internet = pd.read_csv(
        COUNTRY_INTERNET_PATH,
        usecols=["countryiso3code", "year", "internet_ct_l1", "fixed_broadband_ct"],
    )
    internet["year"] = pd.to_numeric(internet["year"], errors="coerce").astype(int)
    for column in ["internet_ct_l1", "fixed_broadband_ct"]:
        internet[column] = pd.to_numeric(internet[column], errors="coerce")
    internet = internet.sort_values(["countryiso3code", "year"]).reset_index(drop=True)
    internet["fixed_broadband_ct_l1"] = internet.groupby("countryiso3code")["fixed_broadband_ct"].shift(1)
    return internet


def prepare_analysis_panel() -> pd.DataFrame:
    panel = load_panel()
    country_lookup = load_country_lookup()
    internet = load_country_internet()

    panel = panel.merge(country_lookup, on="country", how="left")
    panel = panel.merge(
        internet,
        left_on=["countryiso3code", "snapshot_year"],
        right_on=["countryiso3code", "year"],
        how="left",
    )
    return panel


def fit_spec(sample: pd.DataFrame, spec_id: str, extra_terms: list[str]) -> tuple[pd.DataFrame, dict[str, object]]:
    sample = sample.copy()
    sample["city_id"] = sample["city_country"].astype(str)

    base_vars = ["lag_log_local_active_bands", "lag_exposure_emerged_hubs"]
    all_vars = base_vars + extra_terms

    z_vars: list[str] = []
    for column in all_vars:
        z_name = f"z_{column}"
        sample[z_name] = zscore(sample[column])
        z_vars.append(z_name)

    if "internet_ct_l1" in extra_terms:
        sample["z_local_x_internet"] = sample["z_lag_log_local_active_bands"] * sample["z_internet_ct_l1"]
        sample["z_hub_x_internet"] = sample["z_lag_exposure_emerged_hubs"] * sample["z_internet_ct_l1"]
        z_vars.extend(["z_local_x_internet", "z_hub_x_internet"])
    if "fixed_broadband_ct_l1" in extra_terms:
        sample["z_local_x_broadband"] = sample["z_lag_log_local_active_bands"] * sample["z_fixed_broadband_ct_l1"]
        sample["z_hub_x_broadband"] = sample["z_lag_exposure_emerged_hubs"] * sample["z_fixed_broadband_ct_l1"]
        z_vars.extend(["z_local_x_broadband", "z_hub_x_broadband"])

    sample = sample.set_index(["city_id", "snapshot_year"]).sort_index()
    clusters = pd.DataFrame({"city_cluster": sample.reset_index()["city_id"].values}, index=sample.index)

    result = PanelOLS(
        sample["emergence_this_year_i"],
        sample[z_vars],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=clusters)

    rows = []
    for name in z_vars:
        rows.append(
            {
                "spec_id": spec_id,
                "predictor": name,
                "coefficient": float(result.params.get(name, np.nan)),
                "std_error": float(result.std_errors.get(name, np.nan)),
                "p_value": float(result.pvalues.get(name, np.nan)),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emergence_this_year_i"].sum()),
                "event_rate": float(sample["emergence_this_year_i"].mean()),
                "r_squared": float(result.rsquared),
                "n_cities": int(sample.reset_index()["city_id"].nunique()),
                "n_countries": int(sample.reset_index()["city_id"].map(lambda x: x.split(",")[-1].strip()).nunique()),
            }
        )

    meta = {
        "spec_id": spec_id,
        "n_obs": int(result.nobs),
        "event_count": int(sample["emergence_this_year_i"].sum()),
        "event_rate": float(sample["emergence_this_year_i"].mean()),
        "r_squared": float(result.rsquared),
    }
    return pd.DataFrame(rows), meta


def format_coef(df: pd.DataFrame, predictor: str) -> str:
    row = df.loc[df["predictor"].eq(predictor)]
    if row.empty:
        return "n/a"
    row = row.iloc[0]
    coef = row["coefficient"]
    p = row["p_value"]
    stars = "***" if p < 0.01 else "**" if p < 0.05 else "*" if p < 0.10 else ""
    return f"{coef:.4f}{stars}"


def write_summary(results: pd.DataFrame, meta_rows: list[dict[str, object]]) -> None:
    spec_map = {meta["spec_id"]: meta for meta in meta_rows}
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Black metal internet diffusion smoke test\n\n")
        handle.write(
            "This is a quick smoke test of whether country-year internet access and broadband access "
            "change the relationship between local thickness, hub exposure, and later black-metal "
            "scene emergence. The unit is still the city-year diffusion panel for black metal, but "
            "internet variables are only available at the country-year level.\n\n"
        )
        handle.write("## Specifications\n\n")
        handle.write("- `internet_baseline_1995plus`: baseline hub-exposure spec on the internet-available sample.\n")
        handle.write("- `internet_interaction_1995plus`: adds `internet_ct_l1` and interactions with local thickness and hub exposure.\n")
        handle.write("- `broadband_baseline_1999plus`: baseline hub-exposure spec on the broadband-available sample.\n")
        handle.write("- `broadband_interaction_1999plus`: adds `fixed_broadband_ct_l1` and interactions with local thickness and hub exposure.\n")

        handle.write("\n## Sample sizes\n\n")
        for spec_id in [
            "internet_baseline_1995plus",
            "internet_interaction_1995plus",
            "broadband_baseline_1999plus",
            "broadband_interaction_1999plus",
        ]:
            meta = spec_map[spec_id]
            handle.write(
                f"- `{spec_id}`: N = `{meta['n_obs']}`, events = `{meta['event_count']}`, "
                f"event rate = `{meta['event_rate']:.4f}`, R-squared = `{meta['r_squared']:.4f}`.\n"
            )

        handle.write("\n## Headline coefficients\n\n")
        for spec_id in [
            "internet_baseline_1995plus",
            "internet_interaction_1995plus",
            "broadband_baseline_1999plus",
            "broadband_interaction_1999plus",
        ]:
            spec = results.loc[results["spec_id"].eq(spec_id)].copy()
            handle.write(f"### {spec_id}\n\n")
            handle.write(
                f"- Local thickness: `{format_coef(spec, 'z_lag_log_local_active_bands')}`\n"
            )
            handle.write(
                f"- Hub exposure: `{format_coef(spec, 'z_lag_exposure_emerged_hubs')}`\n"
            )
            if "internet" in spec_id:
                handle.write(f"- Internet level: `{format_coef(spec, 'z_internet_ct_l1')}`\n")
                handle.write(
                    f"- Local thickness x internet: `{format_coef(spec, 'z_local_x_internet')}`\n"
                )
                handle.write(
                    f"- Hub exposure x internet: `{format_coef(spec, 'z_hub_x_internet')}`\n"
                )
            if "broadband" in spec_id:
                handle.write(f"- Broadband level: `{format_coef(spec, 'z_fixed_broadband_ct_l1')}`\n")
                handle.write(
                    f"- Local thickness x broadband: `{format_coef(spec, 'z_local_x_broadband')}`\n"
                )
                handle.write(
                    f"- Hub exposure x broadband: `{format_coef(spec, 'z_hub_x_broadband')}`\n"
                )
            handle.write("\n")

        internet_spec = results.loc[results["spec_id"].eq("internet_interaction_1995plus")].copy()
        broadband_spec = results.loc[results["spec_id"].eq("broadband_interaction_1999plus")].copy()
        handle.write("## Current read\n\n")
        handle.write(
            "- This is a smoke test only. Internet and broadband are country-year variables merged onto "
            "city-year scene outcomes, so the design is far from clean causal identification.\n"
        )
        handle.write(
            f"- In the internet interaction spec, the `hub exposure x internet` term is "
            f"`{format_coef(internet_spec, 'z_hub_x_internet')}`, while the `local thickness x internet` "
            f"term is `{format_coef(internet_spec, 'z_local_x_internet')}`.\n"
        )
        handle.write(
            f"- In the broadband interaction spec, the `hub exposure x broadband` term is "
            f"`{format_coef(broadband_spec, 'z_hub_x_broadband')}`, while the `local thickness x broadband` "
            f"term is `{format_coef(broadband_spec, 'z_local_x_broadband')}`.\n"
        )
        handle.write(
            "- The useful question is whether external hub exposure becomes more predictive as "
            "internet access rises, relative to purely local thickness. This smoke test is just the "
            "first pass at that question.\n"
        )


def main() -> None:
    panel = prepare_analysis_panel()

    internet_sample = panel.loc[
        panel["snapshot_year"].ge(1995)
        & panel["internet_ct_l1"].notna()
        & panel["lag_log_local_active_bands"].notna()
        & panel["lag_exposure_emerged_hubs"].notna()
    ].copy()
    broadband_sample = panel.loc[
        panel["snapshot_year"].ge(1999)
        & panel["fixed_broadband_ct_l1"].notna()
        & panel["lag_log_local_active_bands"].notna()
        & panel["lag_exposure_emerged_hubs"].notna()
    ].copy()

    result_frames = []
    meta_rows = []

    for spec_id, sample, extras in [
        ("internet_baseline_1995plus", internet_sample, []),
        ("internet_interaction_1995plus", internet_sample, ["internet_ct_l1"]),
        ("broadband_baseline_1999plus", broadband_sample, []),
        ("broadband_interaction_1999plus", broadband_sample, ["fixed_broadband_ct_l1"]),
    ]:
        res, meta = fit_spec(sample, spec_id, extras)
        result_frames.append(res)
        meta_rows.append(meta)

    results = pd.concat(result_frames, ignore_index=True)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(results, meta_rows)

    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
