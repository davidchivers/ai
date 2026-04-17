from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
DIFFUSION_DIR = SCENE_DIR / "diffusion"

EXPOSURE_PANEL_PATH = DIFFUSION_DIR / "black_metal_diffusion_exposure_panel.csv"
BROADBAND_PANEL_PATH = DIFFUSION_DIR / "black_metal_city_broadband_2019_2025_radius15km.csv"

RESULTS_PATH = DIFFUSION_DIR / "black_metal_city_broadband_probe_results.csv"
SUMMARY_PATH = DIFFUSION_DIR / "black_metal_city_broadband_probe_summary.md"


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def weighted_average(values: pd.Series, weights: pd.Series) -> float:
    values = pd.to_numeric(values, errors="coerce")
    weights = pd.to_numeric(weights, errors="coerce").fillna(0.0)
    mask = values.notna()
    if not mask.any():
        return np.nan
    values = values.loc[mask]
    weights = weights.loc[mask]
    if weights.sum() <= 0:
        return float(values.mean())
    return float(np.average(values, weights=weights))


def load_exposure_panel() -> pd.DataFrame:
    panel = pd.read_csv(EXPOSURE_PANEL_PATH)
    panel["snapshot_year"] = pd.to_numeric(panel["snapshot_year"], errors="coerce").astype(int)
    panel["emergence_this_year_i"] = pd.to_numeric(panel["emergence_this_year_i"], errors="coerce").fillna(0).astype(int)
    for column in ["lag_log_local_active_bands", "lag_exposure_emerged_hubs"]:
        panel[column] = pd.to_numeric(panel[column], errors="coerce")
    return panel


def build_annual_broadband_panel() -> pd.DataFrame:
    broadband = pd.read_csv(BROADBAND_PANEL_PATH)
    broadband["year"] = pd.to_numeric(broadband["year"], errors="coerce").astype(int)
    broadband["tests_sum"] = pd.to_numeric(broadband["tests_sum"], errors="coerce").fillna(0.0)

    annual = (
        broadband.groupby(["city_country", "year"], as_index=False)
        .apply(
            lambda group: pd.Series(
                {
                    "annual_tests_sum": float(group["tests_sum"].sum()),
                    "annual_devices_sum": float(pd.to_numeric(group["devices_sum"], errors="coerce").fillna(0.0).sum()),
                    "annual_avg_download_kbps": weighted_average(group["avg_download_kbps"], group["tests_sum"]),
                    "annual_avg_upload_kbps": weighted_average(group["avg_upload_kbps"], group["tests_sum"]),
                    "annual_avg_latency_ms": weighted_average(group["avg_latency_ms"], group["tests_sum"]),
                }
            ),
            include_groups=False,
        )
        .reset_index()
    )

    annual["lag_annual_avg_download_kbps"] = annual.groupby("city_country")["annual_avg_download_kbps"].shift(1)
    annual["lag_annual_avg_upload_kbps"] = annual.groupby("city_country")["annual_avg_upload_kbps"].shift(1)
    annual["lag_annual_avg_latency_ms"] = annual.groupby("city_country")["annual_avg_latency_ms"].shift(1)
    annual["lag_log_annual_download_kbps"] = np.log1p(annual["lag_annual_avg_download_kbps"])
    annual["lag_log_annual_upload_kbps"] = np.log1p(annual["lag_annual_avg_upload_kbps"])
    annual["lag_log_annual_latency_ms"] = np.log1p(annual["lag_annual_avg_latency_ms"])
    return annual


def prepare_sample() -> pd.DataFrame:
    panel = load_exposure_panel()
    annual = build_annual_broadband_panel()
    panel = panel.merge(
        annual,
        left_on=["city_country", "snapshot_year"],
        right_on=["city_country", "year"],
        how="left",
    )
    sample = panel.loc[
        panel["snapshot_year"].between(2020, 2022)
        & panel["lag_log_local_active_bands"].notna()
        & panel["lag_exposure_emerged_hubs"].notna()
        & panel["lag_log_annual_download_kbps"].notna()
    ].copy()
    sample["city_id"] = sample["city_country"].astype(str)
    return sample


def fit_spec(sample: pd.DataFrame, spec_id: str, extra_terms: list[str]) -> tuple[pd.DataFrame, dict[str, object]]:
    sample = sample.copy()
    base_terms = ["lag_log_local_active_bands", "lag_exposure_emerged_hubs"]
    all_terms = base_terms + extra_terms
    z_terms: list[str] = []

    for column in all_terms:
        z_name = f"z_{column}"
        sample[z_name] = zscore(sample[column])
        z_terms.append(z_name)

    if "lag_log_annual_download_kbps" in extra_terms:
        sample["z_local_x_broadband"] = sample["z_lag_log_local_active_bands"] * sample["z_lag_log_annual_download_kbps"]
        sample["z_hub_x_broadband"] = sample["z_lag_exposure_emerged_hubs"] * sample["z_lag_log_annual_download_kbps"]
        if "z_local_x_broadband" not in z_terms:
            z_terms.extend(["z_local_x_broadband", "z_hub_x_broadband"])

    sample = sample.set_index(["city_id", "snapshot_year"]).sort_index()
    clusters = pd.DataFrame({"city_cluster": sample.reset_index()["city_id"].values}, index=sample.index)

    result = PanelOLS(
        sample["emergence_this_year_i"],
        sample[z_terms],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=clusters)

    rows = []
    for predictor in z_terms:
        rows.append(
            {
                "spec_id": spec_id,
                "predictor": predictor,
                "coefficient": float(result.params.get(predictor, np.nan)),
                "std_error": float(result.std_errors.get(predictor, np.nan)),
                "p_value": float(result.pvalues.get(predictor, np.nan)),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emergence_this_year_i"].sum()),
                "event_rate": float(sample["emergence_this_year_i"].mean()),
                "r_squared": float(result.rsquared),
                "n_cities": int(sample.reset_index()["city_id"].nunique()),
            }
        )

    meta = {
        "spec_id": spec_id,
        "n_obs": int(result.nobs),
        "event_count": int(sample["emergence_this_year_i"].sum()),
        "event_rate": float(sample["emergence_this_year_i"].mean()),
        "r_squared": float(result.rsquared),
        "n_cities": int(sample.reset_index()["city_id"].nunique()),
    }
    return pd.DataFrame(rows), meta


def format_coef(results: pd.DataFrame, predictor: str) -> str:
    row = results.loc[results["predictor"].eq(predictor)]
    if row.empty:
        return "n/a"
    row = row.iloc[0]
    stars = "***" if row["p_value"] < 0.01 else "**" if row["p_value"] < 0.05 else "*" if row["p_value"] < 0.10 else ""
    return f"{row['coefficient']:.4f}{stars}"


def write_summary(results: pd.DataFrame, meta_rows: list[dict[str, object]]) -> None:
    meta_map = {row["spec_id"]: row for row in meta_rows}
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Black metal city broadband probe\n\n")
        handle.write(
            "This is a late-period probe using actual city-level fixed-broadband data aggregated from "
            "Ookla Open Data. The sample is restricted to black-metal city-years where the at-risk "
            "diffusion panel still exists and lagged annual city broadband is available.\n\n"
        )
        handle.write("## Specifications\n\n")
        handle.write("- `late_baseline_2020_2022`: local thickness and hub exposure only.\n")
        handle.write("- `late_broadband_level_2020_2022`: adds lagged annual log download speed.\n")
        handle.write("- `late_broadband_interaction_2020_2022`: adds lagged annual log download speed plus interactions with local thickness and hub exposure.\n")

        handle.write("\n## Sample\n\n")
        for spec_id in [
            "late_baseline_2020_2022",
            "late_broadband_level_2020_2022",
            "late_broadband_interaction_2020_2022",
        ]:
            meta = meta_map[spec_id]
            handle.write(
                f"- `{spec_id}`: N = `{meta['n_obs']}`, cities = `{meta['n_cities']}`, "
                f"events = `{meta['event_count']}`, event rate = `{meta['event_rate']:.4f}`, "
                f"R-squared = `{meta['r_squared']:.4f}`.\n"
            )

        handle.write("\n## Headline coefficients\n\n")
        for spec_id in [
            "late_baseline_2020_2022",
            "late_broadband_level_2020_2022",
            "late_broadband_interaction_2020_2022",
        ]:
            spec = results.loc[results["spec_id"].eq(spec_id)].copy()
            handle.write(f"### {spec_id}\n\n")
            handle.write(f"- Local thickness: `{format_coef(spec, 'z_lag_log_local_active_bands')}`\n")
            handle.write(f"- Hub exposure: `{format_coef(spec, 'z_lag_exposure_emerged_hubs')}`\n")
            handle.write(f"- Broadband level: `{format_coef(spec, 'z_lag_log_annual_download_kbps')}`\n")
            handle.write(f"- Local thickness x broadband: `{format_coef(spec, 'z_local_x_broadband')}`\n")
            handle.write(f"- Hub exposure x broadband: `{format_coef(spec, 'z_hub_x_broadband')}`\n\n")

        interaction = results.loc[results["spec_id"].eq("late_broadband_interaction_2020_2022")].copy()
        handle.write("## Read\n\n")
        handle.write(
            "- This is a genuinely city-level broadband probe, unlike the earlier country-year internet smoke test.\n"
        )
        handle.write(
            "- The sample is very late and very short, so this should be treated as exploratory only.\n"
        )
        handle.write(
            f"- The key test is whether `local thickness x broadband` and `hub exposure x broadband` "
            f"point in opposite directions. In this run they are "
            f"`{format_coef(interaction, 'z_local_x_broadband')}` and "
            f"`{format_coef(interaction, 'z_hub_x_broadband')}` respectively.\n"
        )


def main() -> None:
    sample = prepare_sample()
    result_frames = []
    meta_rows = []
    for spec_id, extras in [
        ("late_baseline_2020_2022", []),
        ("late_broadband_level_2020_2022", ["lag_log_annual_download_kbps"]),
        ("late_broadband_interaction_2020_2022", ["lag_log_annual_download_kbps"]),
    ]:
        results, meta = fit_spec(sample, spec_id, extras)
        result_frames.append(results)
        meta_rows.append(meta)

    combined = pd.concat(result_frames, ignore_index=True)
    combined.to_csv(RESULTS_PATH, index=False)
    write_summary(combined, meta_rows)

    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
