from __future__ import annotations

import re
from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

BAND_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
OVERALL_FEATURE_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
GENRE_FEATURE_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"

OUTPUT_RESULTS_PATH = SCENE_DIR / "scene_threshold_response_results.csv"
OUTPUT_SUMMARY_PATH = SCENE_DIR / "scene_threshold_response_summary.md"

THRESHOLDS = [3, 4, 5, 6, 8]
BASELINE_THRESHOLD = 5
ROLLING_WINDOW = 5

CORE_PREDICTORS = [
    "roll5_log_active_bands",
    "roll5_n_nontrivial_communities",
    "roll5_log_multi_band_musicians_total",
    "roll5_log_spawn_bands_formed",
    "roll5_log_genre_active_bands",
    "roll5_log_genre_multi_band_musicians",
]

SPECIFICITY_PREDICTORS = CORE_PREDICTORS + ["roll5_log_genre_active_musicians"]

GENRE_FAMILIES = {
    "atmospheric black metal": "atmospheric_black_metal",
    "avant-garde metal": "avant_garde_metal",
    "brutal death metal": "brutal_death_metal",
    "depressive black metal": "depressive_black_metal",
    "melodic death metal": "melodic_death_metal",
    "technical death metal": "technical_death_metal",
    "black metal": "black_metal",
    "death metal": "death_metal",
    "doom metal": "doom_metal",
    "drone metal": "drone_metal",
    "folk metal": "folk_metal",
    "gothic metal": "gothic_metal",
    "grindcore": "grindcore",
    "groove metal": "groove_metal",
    "heavy metal": "heavy_metal",
    "industrial metal": "industrial_metal",
    "metalcore": "metalcore",
    "nu metal": "nu_metal",
    "post-black metal": "post_black_metal",
    "post-metal": "post_metal",
    "power metal": "power_metal",
    "progressive metal": "progressive_metal",
    "sludge metal": "sludge_metal",
    "speed metal": "speed_metal",
    "stoner metal": "stoner_metal",
    "symphonic metal": "symphonic_metal",
    "thrash metal": "thrash_metal",
    "viking metal": "viking_metal",
    "deathcore": "deathcore",
}
GENRE_FAMILY_KEYS = sorted(GENRE_FAMILIES.keys(), key=len, reverse=True)


def rolling_min_periods(window: int) -> int:
    return max(2, window - 1)


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def extract_city(notes_str: str) -> str:
    if not isinstance(notes_str, str) or not notes_str:
        return ""
    match = re.search(r"location=([^;]+)", notes_str)
    if not match:
        return ""
    parts = [part.strip() for part in match.group(1).strip().split(",")]
    return parts[0] if parts else ""


def normalize_city_country(city: str, country: str) -> str:
    city = (city or "").strip()
    country = (country or "").strip()
    if not city:
        return ""
    return f"{city}, {country}" if country else city


def parse_genre_families(genre_raw: str) -> tuple[str, ...]:
    text = (genre_raw or "").strip().lower()
    if not text:
        return tuple()

    families: list[str] = []
    for key in GENRE_FAMILY_KEYS:
        if key in text:
            families.append(GENRE_FAMILIES[key])
    if not families and "metal" in text:
        families.append("other_metal")
    return tuple(sorted(set(families)))


def significance_stars(p_value: float) -> str:
    if pd.isna(p_value):
        return ""
    if p_value < 0.01:
        return "***"
    if p_value < 0.05:
        return "**"
    if p_value < 0.10:
        return "*"
    return ""


def format_coef_se(coef: float, se: float, p_value: float) -> str:
    if pd.isna(coef):
        return ""
    return f"{coef:.4f}{significance_stars(p_value)} ({se:.4f})"


def format_stat(value: float, digits: int = 4) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def load_feature_inputs() -> tuple[pd.DataFrame, pd.DataFrame]:
    overall = pd.read_csv(OVERALL_FEATURE_PATH)
    genre = pd.read_csv(GENRE_FEATURE_PATH)

    for frame in [overall, genre]:
        frame["snapshot_year"] = pd.to_numeric(frame["snapshot_year"], errors="coerce").astype(int)

    for column in [
        "n_active_bands",
        "n_nontrivial_communities",
        "n_multi_band_musicians_total",
        "spawn_bands_formed",
    ]:
        overall[column] = pd.to_numeric(overall[column], errors="coerce").fillna(0.0)

    for column in [
        "genre_active_bands",
        "genre_active_musicians",
        "genre_multi_band_musicians",
    ]:
        genre[column] = pd.to_numeric(genre[column], errors="coerce").fillna(0.0)

    overall = overall.sort_values(["city_country", "snapshot_year"]).reset_index(drop=True).copy()
    genre = genre.sort_values(["city_country", "genre_family", "snapshot_year"]).reset_index(drop=True).copy()

    overall["log_active_bands"] = np.log1p(overall["n_active_bands"])
    overall["log_multi_band_musicians_total"] = np.log1p(overall["n_multi_band_musicians_total"])
    overall["log_spawn_bands_formed"] = np.log1p(overall["spawn_bands_formed"])

    genre["log_genre_active_bands"] = np.log1p(genre["genre_active_bands"])
    genre["log_genre_active_musicians"] = np.log1p(genre["genre_active_musicians"])
    genre["log_genre_multi_band_musicians"] = np.log1p(genre["genre_multi_band_musicians"])

    min_periods = rolling_min_periods(ROLLING_WINDOW)
    for column in [
        "log_active_bands",
        "n_nontrivial_communities",
        "log_multi_band_musicians_total",
        "log_spawn_bands_formed",
    ]:
        overall[f"roll{ROLLING_WINDOW}_{column}"] = overall.groupby("city_country")[column].transform(
            lambda series, w=ROLLING_WINDOW, m=min_periods: series.shift(1).rolling(w, min_periods=m).mean()
        )

    for column in [
        "log_genre_active_bands",
        "log_genre_active_musicians",
        "log_genre_multi_band_musicians",
    ]:
        genre[f"roll{ROLLING_WINDOW}_{column}"] = genre.groupby(["city_country", "genre_family"])[column].transform(
            lambda series, w=ROLLING_WINDOW, m=min_periods: series.shift(1).rolling(w, min_periods=m).mean()
        )

    return overall, genre


def load_band_timing_frame(eligible_cities: set[str]) -> pd.DataFrame:
    bands = pd.read_csv(BAND_PATH)
    bands["city"] = bands["notes"].map(extract_city)
    bands["formed_year"] = pd.to_numeric(bands["formed_year"], errors="coerce")
    bands = bands.loc[bands["city"].ne("") & bands["formed_year"].notna()].copy()
    bands["formed_year"] = bands["formed_year"].astype(int)
    bands["country_std"] = bands["country_std"].fillna("")
    bands["city_country"] = bands.apply(
        lambda row: normalize_city_country(str(row["city"]), str(row["country_std"])),
        axis=1,
    )
    bands = bands.loc[bands["city_country"].isin(eligible_cities)].copy()
    bands["genre_families"] = bands["genre_raw"].map(parse_genre_families)

    rows: list[dict[str, object]] = []
    for row in bands[["city_country", "formed_year", "genre_families"]].itertuples(index=False):
        for genre_family in row.genre_families:
            rows.append(
                {
                    "city_country": str(row.city_country),
                    "genre_family": str(genre_family),
                    "formed_year": int(row.formed_year),
                }
            )

    return pd.DataFrame(rows)


def build_threshold_objects(
    band_timing: pd.DataFrame,
    cell_year_master: pd.DataFrame,
    threshold: int,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    grouped = band_timing.groupby(["city_country", "genre_family"])["formed_year"]
    emergence = grouped.agg(["min", "count"]).reset_index().rename(
        columns={"min": "first_band_year", "count": "total_bands"}
    )
    emergence["emergence_year"] = grouped.apply(
        lambda years, t=threshold: sorted(years.tolist())[t - 1] if len(years) >= t else np.nan
    ).values

    yearly_counts = (
        band_timing.groupby(["city_country", "genre_family", "formed_year"])
        .size()
        .reset_index(name="bands_formed")
    )
    lag_counts = cell_year_master.merge(
        yearly_counts,
        left_on=["city_country", "genre_family", "snapshot_year"],
        right_on=["city_country", "genre_family", "formed_year"],
        how="left",
    ).drop(columns="formed_year")
    lag_counts["bands_formed"] = lag_counts["bands_formed"].fillna(0).astype(int)
    lag_counts = lag_counts.sort_values(["city_country", "genre_family", "snapshot_year"]).copy()
    lag_counts["cum_formed"] = lag_counts.groupby(["city_country", "genre_family"])["bands_formed"].cumsum()
    lag_counts["lag_cum_formed"] = (
        lag_counts.groupby(["city_country", "genre_family"])["cum_formed"].shift(1).fillna(0).astype(int)
    )

    return emergence, lag_counts[
        ["city_country", "genre_family", "snapshot_year", "lag_cum_formed", "cum_formed"]
    ].copy()


def build_panel(
    overall: pd.DataFrame,
    genre: pd.DataFrame,
    emergence: pd.DataFrame,
    lag_counts: pd.DataFrame,
) -> pd.DataFrame:
    emergence_small = emergence[
        ["city_country", "genre_family", "first_band_year", "emergence_year", "total_bands"]
    ].copy()

    panel = overall.merge(emergence_small, on="city_country", how="inner").merge(
        genre,
        on=["city_country", "snapshot_year", "genre_family"],
        how="left",
    ).merge(
        lag_counts,
        on=["city_country", "genre_family", "snapshot_year"],
        how="left",
    )

    panel["emerge_this_year"] = (
        panel["emergence_year"].notna() & panel["emergence_year"].eq(panel["snapshot_year"])
    ).astype(int)
    panel = panel.loc[
        panel["first_band_year"].notna()
        & (panel["snapshot_year"] >= panel["first_band_year"])
        & (panel["emergence_year"].isna() | (panel["snapshot_year"] <= panel["emergence_year"]))
    ].copy()
    return panel


def fit_panel_spec(
    panel: pd.DataFrame,
    predictors: list[str],
    spec_id: str,
    spec_family: str,
    spec_note: str,
    threshold: int,
    sample_rule: str,
) -> tuple[pd.DataFrame, dict[str, object]]:
    sample = panel.copy()
    for predictor in predictors:
        sample = sample.loc[sample[predictor].notna()].copy()

    sample["cell_id"] = sample["city_country"].astype(str) + " || " + sample["genre_family"].astype(str)
    active_predictors: list[str] = []
    for predictor in predictors:
        z_name = f"z_{predictor}"
        sample[z_name] = zscore(sample[predictor])
        active_predictors.append(z_name)

    sample = sample.set_index(["cell_id", "snapshot_year"]).sort_index()
    clusters = pd.DataFrame(
        {"city_cluster": sample.reset_index()["cell_id"].str.split(" \\|\\| ").str[0].values},
        index=sample.index,
    )

    result = PanelOLS(
        sample["emerge_this_year"],
        sample[active_predictors],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=clusters)

    rows: list[dict[str, object]] = []
    for predictor in predictors:
        z_name = f"z_{predictor}"
        rows.append(
            {
                "spec_id": spec_id,
                "spec_family": spec_family,
                "spec_note": spec_note,
                "threshold_bands": threshold,
                "sample_rule": sample_rule,
                "predictor": predictor,
                "coefficient": float(result.params[z_name]),
                "std_error": float(result.std_errors[z_name]),
                "p_value": float(result.pvalues[z_name]),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emerge_this_year"].sum()),
                "event_rate": float(sample["emerge_this_year"].mean()),
                "r_squared": float(result.rsquared),
                "fixed_effects": "city-genre + year",
                "clustering": "city",
            }
        )

    metadata = {
        "spec_id": spec_id,
        "spec_family": spec_family,
        "spec_note": spec_note,
        "threshold_bands": threshold,
        "sample_rule": sample_rule,
        "n_obs": int(result.nobs),
        "event_count": int(sample["emerge_this_year"].sum()),
        "event_rate": float(sample["emerge_this_year"].mean()),
        "r_squared": float(result.rsquared),
    }
    return pd.DataFrame(rows), metadata


def write_summary(
    results: pd.DataFrame,
    metadata_rows: list[dict[str, object]],
    threshold_counts: pd.DataFrame,
) -> None:
    def row(spec_id: str, predictor: str) -> pd.Series:
        subset = results.loc[
            results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor)
        ]
        return subset.iloc[0]

    threshold_meta = {meta["threshold_bands"]: meta for meta in metadata_rows if meta["spec_family"] == "threshold"}
    drop_neighborhood_meta = next(meta for meta in metadata_rows if meta["spec_id"] == "threshold5_drop_lag_cum_eq4")
    far_below_meta = next(meta for meta in metadata_rows if meta["spec_id"] == "threshold5_lag_cum_le2")
    specificity_meta = next(meta for meta in metadata_rows if meta["spec_id"] == "threshold5_specificity_active_pool")

    threshold_results = results.loc[results["spec_family"].eq("threshold")].copy()

    def threshold_range_text(predictor: str) -> str:
        subset = threshold_results.loc[threshold_results["predictor"].eq(predictor), "coefficient"]
        return f"`{subset.min():.4f}` and `{subset.max():.4f}`"

    with OUTPUT_SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Scene threshold-response package\n\n")
        handle.write(
            "This file answers the threshold-mechanics objection directly around the live preferred "
            "exact-year fixed-effects scene specification. It holds the `roll-5` FE design fixed "
            "and varies three things: the emergence cutoff, the distance of the risk set from the "
            "cutoff, and whether focal overlapping-worker depth still matters once broader focal "
            "labor-pool size is held fixed.\n\n"
        )

        handle.write("## Threshold counts by cutoff\n\n")
        handle.write("| Threshold | City-genre cells reaching cutoff | FE sample N | FE events |\n")
        handle.write("|-----------|--------------------------------|-------------|-----------|\n")
        for threshold in THRESHOLDS:
            count_row = threshold_counts.loc[threshold_counts["threshold_bands"].eq(threshold)].iloc[0]
            meta = threshold_meta[threshold]
            handle.write(
                f"| {threshold} | {int(count_row['emerged_cells'])} | {meta['n_obs']} | {meta['event_count']} |\n"
            )

        handle.write("\n## Threshold robustness\n\n")
        handle.write(
            "| Threshold | Local spawning flow | Target-genre active bands | "
            "Target-genre multi-band musicians |\n"
        )
        handle.write("|-----------|---------------------|---------------------------|-------------------------------|\n")
        for threshold in THRESHOLDS:
            spec_id = f"threshold_{threshold}_core"
            handle.write(
                f"| {threshold} | "
                f"{format_coef_se(float(row(spec_id, 'roll5_log_spawn_bands_formed')['coefficient']), float(row(spec_id, 'roll5_log_spawn_bands_formed')['std_error']), float(row(spec_id, 'roll5_log_spawn_bands_formed')['p_value']))} | "
                f"{format_coef_se(float(row(spec_id, 'roll5_log_genre_active_bands')['coefficient']), float(row(spec_id, 'roll5_log_genre_active_bands')['std_error']), float(row(spec_id, 'roll5_log_genre_active_bands')['p_value']))} | "
                f"{format_coef_se(float(row(spec_id, 'roll5_log_genre_multi_band_musicians')['coefficient']), float(row(spec_id, 'roll5_log_genre_multi_band_musicians')['std_error']), float(row(spec_id, 'roll5_log_genre_multi_band_musicians')['p_value']))} |\n"
            )

        handle.write("\n## Restricted risk-set checks under the fifth-band definition\n\n")
        handle.write(
            "| Sample rule | Local spawning flow | Target-genre active bands | "
            "Target-genre multi-band musicians | N | Events |\n"
        )
        handle.write("|-------------|---------------------|---------------------------|-------------------------------|---|--------|\n")
        baseline_spec = "threshold_5_core"
        for spec_id, label, meta in [
            (baseline_spec, "Full fifth-band risk set", threshold_meta[5]),
            ("threshold5_drop_lag_cum_eq4", "Drop rows one band below the cutoff (`lag cumulative formed != 4`)", drop_neighborhood_meta),
            ("threshold5_lag_cum_le2", "Keep only cells with `lag cumulative formed <= 2`", far_below_meta),
        ]:
            handle.write(
                f"| {label} | "
                f"{format_coef_se(float(row(spec_id, 'roll5_log_spawn_bands_formed')['coefficient']), float(row(spec_id, 'roll5_log_spawn_bands_formed')['std_error']), float(row(spec_id, 'roll5_log_spawn_bands_formed')['p_value']))} | "
                f"{format_coef_se(float(row(spec_id, 'roll5_log_genre_active_bands')['coefficient']), float(row(spec_id, 'roll5_log_genre_active_bands')['std_error']), float(row(spec_id, 'roll5_log_genre_active_bands')['p_value']))} | "
                f"{format_coef_se(float(row(spec_id, 'roll5_log_genre_multi_band_musicians')['coefficient']), float(row(spec_id, 'roll5_log_genre_multi_band_musicians')['std_error']), float(row(spec_id, 'roll5_log_genre_multi_band_musicians')['p_value']))} | "
                f"{meta['n_obs']} | {meta['event_count']} |\n"
            )

        handle.write("\n## Focal labor-pool specificity check\n\n")
        handle.write(
            "This is the falsification-style check in the current package. The specification keeps "
            "the preferred fifth-band FE design but adds lagged target-genre active musicians. If "
            "the result were only about broad focal labor-pool size, the overlap term should be "
            "subsumed by total focal active musicians.\n\n"
        )
        handle.write("| Predictor | Coefficient |\n")
        handle.write("|-----------|-------------|\n")
        for predictor in [
            "roll5_log_genre_active_bands",
            "roll5_log_genre_active_musicians",
            "roll5_log_genre_multi_band_musicians",
        ]:
            handle.write(
                f"| {predictor} | "
                f"{format_coef_se(float(row('threshold5_specificity_active_pool', predictor)['coefficient']), float(row('threshold5_specificity_active_pool', predictor)['std_error']), float(row('threshold5_specificity_active_pool', predictor)['p_value']))} |\n"
            )
        handle.write(
            f"| N | {specificity_meta['n_obs']} |\n"
            f"| Events | {specificity_meta['event_count']} |\n"
            f"| $R^2$ | {specificity_meta['r_squared']:.4f} |\n"
        )

        handle.write("\n## Current read\n\n")
        handle.write(
            f"- The main threshold result is not pinned to the fifth-band cutoff. Across thresholds "
            f"`3`, `4`, `5`, `6`, and `8`, local spawning flow stays positive between "
            f"{threshold_range_text('roll5_log_spawn_bands_formed')}, target-genre active bands "
            f"stay positive between {threshold_range_text('roll5_log_genre_active_bands')}, and "
            f"target-genre multi-band musicians stay positive between "
            f"{threshold_range_text('roll5_log_genre_multi_band_musicians')}.\n"
        )
        handle.write(
            f"- The more demanding risk-set checks are more sobering. Dropping rows one band below "
            f"the cutoff leaves all three headline coefficients positive, but materially smaller: "
            f"spawning flow falls to "
            f"`{format_stat(float(row('threshold5_drop_lag_cum_eq4', 'roll5_log_spawn_bands_formed')['coefficient']))}`, "
            f"target-genre active bands to "
            f"`{format_stat(float(row('threshold5_drop_lag_cum_eq4', 'roll5_log_genre_active_bands')['coefficient']))}`, "
            f"and target-genre multi-band musicians to "
            f"`{format_stat(float(row('threshold5_drop_lag_cum_eq4', 'roll5_log_genre_multi_band_musicians')['coefficient']))}`.\n"
        )
        handle.write(
            f"- When the sample is restricted to cells still well below the cutoff "
            f"(`lag cumulative formed <= 2`), the same terms attenuate sharply. The paper should "
            f"therefore be read as strongest on late-stage local niche consolidation rather than "
            f"on the earliest seed stage of scene formation.\n"
        )
        handle.write(
            f"- The focal labor-pool specificity check still supports the recombination margin. "
            f"Conditional on target-genre active bands and total target-genre active musicians, "
            f"target-genre multi-band musicians remain positive at "
            f"`{format_stat(float(row('threshold5_specificity_active_pool', 'roll5_log_genre_multi_band_musicians')['coefficient']))}`, "
            f"while total target-genre active musicians turn negative at "
            f"`{format_stat(float(row('threshold5_specificity_active_pool', 'roll5_log_genre_active_musicians')['coefficient']))}`. "
            f"That is consistent with overlap or recombination inside the niche rather than with a "
            f"generic focal headcount story.\n"
        )


def main() -> None:
    overall, genre = load_feature_inputs()
    eligible_cities = set(overall["city_country"].dropna().unique())
    band_timing = load_band_timing_frame(eligible_cities=eligible_cities)
    cell_year_master = genre[["city_country", "genre_family", "snapshot_year"]].drop_duplicates().copy()

    result_frames: list[pd.DataFrame] = []
    metadata_rows: list[dict[str, object]] = []
    threshold_count_rows: list[dict[str, int]] = []

    baseline_panel: pd.DataFrame | None = None
    baseline_lag_counts: pd.DataFrame | None = None

    for threshold in THRESHOLDS:
        emergence, lag_counts = build_threshold_objects(
            band_timing=band_timing,
            cell_year_master=cell_year_master,
            threshold=threshold,
        )
        threshold_count_rows.append(
            {
                "threshold_bands": threshold,
                "emerged_cells": int(emergence["emergence_year"].notna().sum()),
            }
        )
        panel = build_panel(overall=overall, genre=genre, emergence=emergence, lag_counts=lag_counts)

        results, metadata = fit_panel_spec(
            panel=panel,
            predictors=CORE_PREDICTORS,
            spec_id=f"threshold_{threshold}_core",
            spec_family="threshold",
            spec_note=f"Preferred core FE under emergence threshold {threshold}",
            threshold=threshold,
            sample_rule="full threshold-specific at-risk sample",
        )
        result_frames.append(results)
        metadata_rows.append(metadata)

        if threshold == BASELINE_THRESHOLD:
            baseline_panel = panel.copy()
            baseline_lag_counts = lag_counts.copy()

    if baseline_panel is None or baseline_lag_counts is None:
        raise RuntimeError("Baseline threshold panel was not constructed.")

    risk_results, risk_metadata = fit_panel_spec(
        panel=baseline_panel.loc[baseline_panel["lag_cum_formed"].ne(BASELINE_THRESHOLD - 1)].copy(),
        predictors=CORE_PREDICTORS,
        spec_id="threshold5_drop_lag_cum_eq4",
        spec_family="risk_set",
        spec_note="Fifth-band FE after dropping rows one band below the cutoff",
        threshold=BASELINE_THRESHOLD,
        sample_rule="drop lag cumulative formed == 4",
    )
    result_frames.append(risk_results)
    metadata_rows.append(risk_metadata)

    far_below_results, far_below_metadata = fit_panel_spec(
        panel=baseline_panel.loc[baseline_panel["lag_cum_formed"].le(2)].copy(),
        predictors=CORE_PREDICTORS,
        spec_id="threshold5_lag_cum_le2",
        spec_family="risk_set",
        spec_note="Fifth-band FE keeping cells well below the cutoff",
        threshold=BASELINE_THRESHOLD,
        sample_rule="keep lag cumulative formed <= 2",
    )
    result_frames.append(far_below_results)
    metadata_rows.append(far_below_metadata)

    specificity_results, specificity_metadata = fit_panel_spec(
        panel=baseline_panel,
        predictors=SPECIFICITY_PREDICTORS,
        spec_id="threshold5_specificity_active_pool",
        spec_family="falsification",
        spec_note="Fifth-band FE with target-genre active-musician specificity check",
        threshold=BASELINE_THRESHOLD,
        sample_rule="full fifth-band at-risk sample",
    )
    result_frames.append(specificity_results)
    metadata_rows.append(specificity_metadata)

    results = pd.concat(result_frames, ignore_index=True)
    threshold_counts = pd.DataFrame(threshold_count_rows)

    results.to_csv(OUTPUT_RESULTS_PATH, index=False)
    write_summary(results=results, metadata_rows=metadata_rows, threshold_counts=threshold_counts)

    print(f"Wrote {OUTPUT_RESULTS_PATH}")
    print(f"Wrote {OUTPUT_SUMMARY_PATH}")


if __name__ == "__main__":
    main()
