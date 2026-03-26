from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

SNAPSHOT_PATH = SCENE_DIR / "city_year_network_snapshots.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"

OUTPUT_COEF_PATH = SCENE_DIR / "scene_cluster_regression_results.csv"
OUTPUT_SUMMARY_PATH = SCENE_DIR / "scene_cluster_regression_summary.md"

FORECAST_HORIZONS = [3, 5, 7, 10]
EVENT_FE_WINDOWS = [3, 5]
BASELINE_EVENT_FE_WINDOW = 3


def rolling_min_periods(window: int) -> int:
    return max(2, window - 1)


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame]:
    snapshots = pd.read_csv(SNAPSHOT_PATH)
    emergence = pd.read_csv(EMERGENCE_PATH)

    snapshots["snapshot_year"] = pd.to_numeric(snapshots["snapshot_year"], errors="coerce").astype(int)
    for column in [
        "n_active_bands",
        "n_active_musicians",
        "density",
        "bridge_pct",
        "n_nontrivial_communities",
        "largest_component",
        "modularity_q",
    ]:
        snapshots[column] = pd.to_numeric(snapshots[column], errors="coerce")

    for column in ["first_band_year", "emergence_year"]:
        emergence[column] = pd.to_numeric(emergence[column], errors="coerce")

    return snapshots, emergence


def build_predictor_frame(snapshots: pd.DataFrame) -> pd.DataFrame:
    frame = snapshots.sort_values(["city_country", "snapshot_year"]).copy()

    rolling_source_columns = [
        "bridge_pct",
        "density",
        "modularity_q",
        "n_nontrivial_communities",
        "n_active_bands",
        "largest_component",
    ]
    for window in EVENT_FE_WINDOWS:
        min_periods = rolling_min_periods(window)
        for column in rolling_source_columns:
            frame[f"roll{window}_{column}"] = frame.groupby("city_country")[column].transform(
                lambda s, w=window, m=min_periods: s.shift(1).rolling(w, min_periods=m).mean()
            )

    frame["log_active_bands"] = np.log1p(frame["n_active_bands"])
    for window in EVENT_FE_WINDOWS:
        frame[f"roll{window}_log_active_bands"] = np.log1p(frame[f"roll{window}_n_active_bands"])
        frame[f"roll{window}_largest_component_share"] = (
            frame[f"roll{window}_largest_component"]
            / frame[f"roll{window}_n_active_bands"].replace(0, np.nan)
        )

    keep_columns = [
        "city_country",
        "snapshot_year",
        "bridge_pct",
        "density",
        "modularity_q",
        "n_nontrivial_communities",
        "n_active_bands",
        "log_active_bands",
    ]
    for window in EVENT_FE_WINDOWS:
        keep_columns.extend(
            [
                f"roll{window}_bridge_pct",
                f"roll{window}_density",
                f"roll{window}_modularity_q",
                f"roll{window}_n_nontrivial_communities",
                f"roll{window}_log_active_bands",
                f"roll{window}_largest_component_share",
            ]
        )
    return frame[keep_columns].copy()


def build_city_genre_panel(predictors: pd.DataFrame, emergence: pd.DataFrame) -> pd.DataFrame:
    snapshot_cities = set(predictors["city_country"].unique())
    emergence = emergence.loc[emergence["city_country"].isin(snapshot_cities)].copy()

    genre_families = sorted(emergence["genre_family"].dropna().unique())
    city_year = predictors[["city_country", "snapshot_year"]].drop_duplicates().copy()
    city_year["__key"] = 1
    genre_frame = pd.DataFrame({"genre_family": genre_families, "__key": 1})
    panel = city_year.merge(genre_frame, on="__key", how="inner").drop(columns="__key")

    emergence_small = emergence[
        ["city_country", "genre_family", "first_band_year", "emergence_year"]
    ].copy()
    panel = panel.merge(emergence_small, on=["city_country", "genre_family"], how="left")
    panel = panel.merge(predictors, on=["city_country", "snapshot_year"], how="left")

    panel["emerge_this_year"] = (
        panel["emergence_year"].notna() & panel["emergence_year"].eq(panel["snapshot_year"])
    ).astype(int)
    panel["not_yet_emerged"] = panel["emergence_year"].isna() | (
        panel["snapshot_year"] < panel["emergence_year"]
    )
    panel["not_yet_emerged_before_or_in_year"] = panel["emergence_year"].isna() | (
        panel["snapshot_year"] <= panel["emergence_year"]
    )

    return panel


def format_float(value: float, digits: int = 4) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def fit_seeded_horizon_lpm(panel: pd.DataFrame, horizon_years: int) -> tuple[pd.DataFrame, dict[str, object]]:
    max_snapshot_year = int(panel["snapshot_year"].max())
    sample = panel.loc[
        panel["not_yet_emerged"]
        & panel["first_band_year"].notna()
        & (panel["snapshot_year"] >= panel["first_band_year"])
        & (panel["snapshot_year"] <= max_snapshot_year - horizon_years)
    ].copy()

    sample["emerge_within_horizon"] = (
        sample["emergence_year"].notna()
        & (sample["emergence_year"] > sample["snapshot_year"])
        & (sample["emergence_year"] <= sample["snapshot_year"] + horizon_years)
    ).astype(int)

    predictor_columns = ["bridge_pct", "density", "modularity_q", "log_active_bands"]
    for column in predictor_columns:
        sample[f"z_{column}"] = zscore(sample[column])

    formula = (
        "emerge_within_horizon ~ z_bridge_pct + z_density + z_modularity_q "
        "+ z_log_active_bands + C(genre_family) + C(snapshot_year)"
    )
    result = smf.ols(formula, data=sample).fit(
        cov_type="cluster",
        cov_kwds={"groups": sample["city_country"]},
    )

    spec_id = f"seeded_horizon_lpm_{horizon_years}y"
    rows = []
    for term in ["z_bridge_pct", "z_density", "z_modularity_q", "z_log_active_bands"]:
        rows.append(
            {
                "spec_id": spec_id,
                "spec_family": "forecast",
                "outcome": f"emerge_within_{horizon_years}y",
                "predictor": term,
                "coefficient": float(result.params[term]),
                "std_error": float(result.bse[term]),
                "p_value": float(result.pvalues[term]),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emerge_within_horizon"].sum()),
                "event_rate": float(sample["emerge_within_horizon"].mean()),
                "fixed_effects": "genre + year",
                "clustering": "city",
                "predictor_note": "z-scored current-year network metrics",
                "forecast_horizon_years": horizon_years,
                "rolling_window_years": "",
            }
        )

    metadata = {
        "spec_id": spec_id,
        "title": f"Seeded {horizon_years}-year forecast LPM",
        "outcome": f"Genre emerges within {horizon_years} years",
        "sample_note": "Seeded city-genre risk set: years after first band and before emergence",
        "fixed_effects": "genre + year",
        "clustering": "city",
        "n_obs": int(result.nobs),
        "event_count": int(sample["emerge_within_horizon"].sum()),
        "event_rate": float(sample["emerge_within_horizon"].mean()),
        "r_squared": float(result.rsquared),
        "forecast_horizon_years": horizon_years,
        "rolling_window_years": "",
    }
    return pd.DataFrame(rows), metadata


def fit_seeded_event_fe(panel: pd.DataFrame, rolling_years: int) -> tuple[pd.DataFrame, dict[str, object]]:
    sample = panel.loc[
        panel["not_yet_emerged_before_or_in_year"]
        & panel["first_band_year"].notna()
        & (panel["snapshot_year"] >= panel["first_band_year"])
    ].copy()

    rolling_columns = [
        f"roll{rolling_years}_bridge_pct",
        f"roll{rolling_years}_density",
        f"roll{rolling_years}_modularity_q",
        f"roll{rolling_years}_n_nontrivial_communities",
        f"roll{rolling_years}_log_active_bands",
    ]
    sample = sample.loc[sample[f"roll{rolling_years}_bridge_pct"].notna()].copy()

    for column in rolling_columns:
        sample[f"z_{column}"] = zscore(sample[column])

    sample["cell_id"] = sample["city_country"].astype(str) + " || " + sample["genre_family"].astype(str)
    sample = sample.set_index(["cell_id", "snapshot_year"]).sort_index()
    cluster_frame = pd.DataFrame(
        {"city_cluster": sample.reset_index()["cell_id"].str.split(" \\|\\| ").str[0].values},
        index=sample.index,
    )

    exog_columns = [
        f"z_roll{rolling_years}_bridge_pct",
        f"z_roll{rolling_years}_density",
        f"z_roll{rolling_years}_modularity_q",
        f"z_roll{rolling_years}_n_nontrivial_communities",
        f"z_roll{rolling_years}_log_active_bands",
    ]
    model = PanelOLS(
        sample["emerge_this_year"],
        sample[exog_columns],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    )
    result = model.fit(cov_type="clustered", clusters=cluster_frame)

    spec_id = f"seeded_event_fe_variety_roll{rolling_years}"
    rows: list[dict[str, object]] = []
    for term in exog_columns:
        rows.append(
            {
                "spec_id": spec_id,
                "spec_family": "event_fe",
                "outcome": "emerge_this_year",
                "predictor": term,
                "coefficient": float(result.params[term]),
                "std_error": float(result.std_errors[term]),
                "p_value": float(result.pvalues[term]),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emerge_this_year"].sum()),
                "event_rate": float(sample["emerge_this_year"].mean()),
                "fixed_effects": "city-genre + year",
                "clustering": "city",
                "predictor_note": f"z-scored {rolling_years}-year lagged rolling means",
                "forecast_horizon_years": "",
                "rolling_window_years": rolling_years,
            }
        )

    metadata = {
        "spec_id": spec_id,
        "title": f"Seeded exact-year FE, organizational variety, roll-{rolling_years}",
        "outcome": "Genre emerges this year",
        "sample_note": "Seeded city-genre panel with lagged rolling predictors and city-genre FE",
        "fixed_effects": "city-genre + year",
        "clustering": "city",
        "n_obs": int(result.nobs),
        "event_count": int(sample["emerge_this_year"].sum()),
        "event_rate": float(sample["emerge_this_year"].mean()),
        "r_squared": float(result.rsquared),
        "forecast_horizon_years": "",
        "rolling_window_years": rolling_years,
    }
    return pd.DataFrame(rows), metadata


def significance_stars(p_value: float) -> str:
    if p_value < 0.01:
        return "***"
    if p_value < 0.05:
        return "**"
    if p_value < 0.10:
        return "*"
    return ""


def write_summary(results: pd.DataFrame, metadata_rows: list[dict[str, object]]) -> None:
    spec_order = [row["spec_id"] for row in metadata_rows]

    with OUTPUT_SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Scene Cluster Regression Summary\n\n")
        handle.write(
            "This file reports the scene-cluster regression baseline plus the first horizon and "
            "smoothing robustness checks built from the city-year network snapshots and the "
            "city-genre emergence panel.\n\n"
        )
        handle.write("## Specification Overview\n\n")
        handle.write("| Spec | Outcome | Fixed effects | Cluster | N | Events | Event rate | R-squared |\n")
        handle.write("|------|---------|---------------|---------|---|--------|------------|-----------|\n")
        for meta in metadata_rows:
            handle.write(
                f"| {meta['title']} | {meta['outcome']} | {meta['fixed_effects']} | "
                f"{meta['clustering']} | {meta['n_obs']} | {meta['event_count']} | "
                f"{meta['event_rate']:.3f} | {meta['r_squared']:.4f} |\n"
            )

        for spec_id in spec_order:
            meta = next(row for row in metadata_rows if row["spec_id"] == spec_id)
            spec_results = results.loc[results["spec_id"].eq(spec_id)].copy()
            handle.write(f"\n## {meta['title']}\n\n")
            handle.write(f"- Outcome: {meta['outcome']}\n")
            handle.write(f"- Sample: {meta['sample_note']}\n")
            handle.write(f"- Fixed effects: {meta['fixed_effects']}\n")
            handle.write(f"- Clustered SE: {meta['clustering']}\n\n")
            handle.write("| Predictor | Coef | SE | P-value |\n")
            handle.write("|-----------|------|----|---------|\n")
            for _, row in spec_results.iterrows():
                coef_label = f"{row['coefficient']:.4f}{significance_stars(float(row['p_value']))}"
                handle.write(
                    f"| {row['predictor']} | {coef_label} | {row['std_error']:.4f} | "
                    f"{row['p_value']:.4f} |\n"
                )

        handle.write("\n## Current Read\n\n")

        def get(spec_id: str, predictor: str) -> float:
            return float(
                results.loc[
                    results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "coefficient"
                ].iloc[0]
            )

        def get_p(spec_id: str, predictor: str) -> float:
            return float(
                results.loc[
                    results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "p_value"
                ].iloc[0]
            )

        horizon_lines = []
        for horizon in FORECAST_HORIZONS:
            spec_id = f"seeded_horizon_lpm_{horizon}y"
            horizon_lines.append(
                f"`{horizon}`y: size `{format_float(get(spec_id, 'z_log_active_bands'))}`, "
                f"density `{format_float(get(spec_id, 'z_density'))}`, "
                f"modularity `{format_float(get(spec_id, 'z_modularity_q'))}`, "
                f"bridge `{format_float(get(spec_id, 'z_bridge_pct'))}`"
            )
        handle.write(
            "- Across the seeded forecast horizons, the same basic pattern survives and strengthens "
            "with a longer look-ahead window: "
            + "; ".join(horizon_lines)
            + ".\n"
        )

        fe_roll3_spec = f"seeded_event_fe_variety_roll{BASELINE_EVENT_FE_WINDOW}"
        fe_roll5_spec = "seeded_event_fe_variety_roll5"
        handle.write(
            f"- In the stricter exact-year fixed-effects panel, the bridge-musician headline does not "
            f"survive. With `roll-{BASELINE_EVENT_FE_WINDOW}` smoothing, "
            f"`z_roll{BASELINE_EVENT_FE_WINDOW}_bridge_pct = "
            f"{format_float(get(fe_roll3_spec, f'z_roll{BASELINE_EVENT_FE_WINDOW}_bridge_pct'))}` "
            f"and `z_roll{BASELINE_EVENT_FE_WINDOW}_n_nontrivial_communities = "
            f"{format_float(get(fe_roll3_spec, f'z_roll{BASELINE_EVENT_FE_WINDOW}_n_nontrivial_communities'))}`. "
            f"With `roll-5` smoothing, `z_roll5_bridge_pct = "
            f"{format_float(get(fe_roll5_spec, 'z_roll5_bridge_pct'))}` and "
            f"`z_roll5_n_nontrivial_communities = "
            f"{format_float(get(fe_roll5_spec, 'z_roll5_n_nontrivial_communities'))}`.\n"
        )
        handle.write(
            f"- The robust scene terms are therefore local thickness and organizational variety. "
            f"Scene size stays strongly positive in both FE windows "
            f"(`roll-{BASELINE_EVENT_FE_WINDOW}`: "
            f"`{format_float(get(fe_roll3_spec, f'z_roll{BASELINE_EVENT_FE_WINDOW}_log_active_bands'))}`, "
            f"`roll-5`: `{format_float(get(fe_roll5_spec, 'z_roll5_log_active_bands'))}`), "
            f"and nontrivial community count also stays positive "
            f"(`roll-{BASELINE_EVENT_FE_WINDOW}` p = "
            f"{format_float(get_p(fe_roll3_spec, f'z_roll{BASELINE_EVENT_FE_WINDOW}_n_nontrivial_communities'))}, "
            f"`roll-5` p = {format_float(get_p(fe_roll5_spec, 'z_roll5_n_nontrivial_communities'))}).\n"
        )
        handle.write(
            "- Interpretation after the first robustness pass: the scene-cluster design no longer "
            "depends on a single annual horizon. The medium-run signal is stable, but it points to "
            "thickness and subcommunity variety rather than to bridge musicians as the central "
            "mechanism.\n"
        )
        handle.write(
            "- This is still a predictive design, not a causal identification strategy. The main value is "
            "that the scene branch now has a real panel regression and a first robustness layer, "
            "rather than only cross-sectional or threshold-count evidence.\n"
        )


def main() -> None:
    snapshots, emergence = load_inputs()
    predictors = build_predictor_frame(snapshots)
    panel = build_city_genre_panel(predictors, emergence)

    result_frames: list[pd.DataFrame] = []
    metadata_rows: list[dict[str, object]] = []

    for horizon in FORECAST_HORIZONS:
        horizon_results, horizon_metadata = fit_seeded_horizon_lpm(panel, horizon)
        result_frames.append(horizon_results)
        metadata_rows.append(horizon_metadata)

    for window in EVENT_FE_WINDOWS:
        fe_results, fe_metadata = fit_seeded_event_fe(panel, window)
        result_frames.append(fe_results)
        metadata_rows.append(fe_metadata)

    results = pd.concat(result_frames, ignore_index=True)

    results.to_csv(OUTPUT_COEF_PATH, index=False)
    write_summary(results, metadata_rows)

    print(f"Wrote {OUTPUT_COEF_PATH}")
    print(f"Wrote {OUTPUT_SUMMARY_PATH}")


if __name__ == "__main__":
    main()
