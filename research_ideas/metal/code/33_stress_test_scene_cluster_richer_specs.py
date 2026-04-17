from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

OVERALL_FEATURE_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
GENRE_FEATURE_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"

RESULTS_PATH = SCENE_DIR / "scene_cluster_richer_stress_test_results.csv"
SUMMARY_PATH = SCENE_DIR / "scene_cluster_richer_stress_test_summary.md"

ROLLING_WINDOWS = [3, 5]

OVERALL_RAW_COLUMNS = [
    "log_active_bands",
    "n_nontrivial_communities",
    "log_multi_band_musicians_total",
    "log_spawn_bands_formed",
    "spawn_share_formed",
]
GENRE_RAW_COLUMNS = [
    "log_genre_active_bands",
    "log_genre_broker_musicians",
    "log_genre_multi_band_musicians",
    "genre_broker_share",
    "genre_multi_band_share",
]


def rolling_min_periods(window: int) -> int:
    return max(2, window - 1)


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    overall = pd.read_csv(OVERALL_FEATURE_PATH)
    genre = pd.read_csv(GENRE_FEATURE_PATH)
    emergence = pd.read_csv(EMERGENCE_PATH)

    for frame in [overall, genre]:
        frame["snapshot_year"] = pd.to_numeric(frame["snapshot_year"], errors="coerce").astype(int)

    for column in [
        "n_active_bands",
        "n_nontrivial_communities",
        "n_multi_band_musicians_total",
        "spawn_bands_formed",
        "spawn_share_formed",
        "founder_pedigree_mean",
        "log_active_bands",
        "log_multi_band_musicians_total",
        "log_spawn_bands_formed",
    ]:
        if column in overall.columns:
            overall[column] = pd.to_numeric(overall[column], errors="coerce")

    for column in [
        "genre_active_bands",
        "genre_active_musicians",
        "genre_multi_band_musicians",
        "genre_broker_musicians",
        "genre_broker_share",
        "genre_multi_band_share",
        "log_genre_active_bands",
        "log_genre_active_musicians",
        "log_genre_multi_band_musicians",
        "log_genre_broker_musicians",
    ]:
        if column in genre.columns:
            genre[column] = pd.to_numeric(genre[column], errors="coerce")

    for column in ["first_band_year", "emergence_year"]:
        emergence[column] = pd.to_numeric(emergence[column], errors="coerce")

    overall = overall.fillna(
        {
            "n_multi_band_musicians_total": 0.0,
            "spawn_bands_formed": 0.0,
            "spawn_share_formed": 0.0,
        }
    )
    genre = genre.fillna(
        {
            "genre_active_bands": 0.0,
            "genre_multi_band_musicians": 0.0,
            "genre_broker_musicians": 0.0,
            "genre_broker_share": 0.0,
            "genre_multi_band_share": 0.0,
        }
    )

    overall["log_active_bands"] = np.log1p(overall["n_active_bands"])
    overall["log_multi_band_musicians_total"] = np.log1p(overall["n_multi_band_musicians_total"])
    overall["log_spawn_bands_formed"] = np.log1p(overall["spawn_bands_formed"])

    genre["log_genre_active_bands"] = np.log1p(genre["genre_active_bands"])
    genre["log_genre_broker_musicians"] = np.log1p(genre["genre_broker_musicians"])
    genre["log_genre_multi_band_musicians"] = np.log1p(genre["genre_multi_band_musicians"])

    return overall, genre, emergence


def add_rolling_features(overall: pd.DataFrame, genre: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    overall = overall.sort_values(["city_country", "snapshot_year"]).reset_index(drop=True).copy()
    genre = genre.sort_values(["city_country", "genre_family", "snapshot_year"]).reset_index(drop=True).copy()

    for window in ROLLING_WINDOWS:
        min_periods = rolling_min_periods(window)
        for column in OVERALL_RAW_COLUMNS:
            overall[f"roll{window}_{column}"] = overall.groupby("city_country")[column].transform(
                lambda series, w=window, m=min_periods: series.shift(1).rolling(w, min_periods=m).mean()
            )
        for column in GENRE_RAW_COLUMNS:
            genre[f"roll{window}_{column}"] = genre.groupby(["city_country", "genre_family"])[column].transform(
                lambda series, w=window, m=min_periods: series.shift(1).rolling(w, min_periods=m).mean()
            )

    return overall, genre


def build_panel(overall: pd.DataFrame, genre: pd.DataFrame, emergence: pd.DataFrame) -> pd.DataFrame:
    emergence_small = emergence[["city_country", "genre_family", "first_band_year", "emergence_year"]].copy()
    panel = overall.merge(emergence_small, on="city_country", how="inner").merge(
        genre,
        on=["city_country", "snapshot_year", "genre_family"],
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
    spec_id: str,
    rolling_window: int,
    extra_predictors: list[str],
    spec_note: str,
    include_overall_switchers: bool,
) -> tuple[pd.DataFrame, dict[str, object]]:
    base_predictors = [
        f"roll{rolling_window}_log_active_bands",
        f"roll{rolling_window}_n_nontrivial_communities",
    ]
    if include_overall_switchers:
        base_predictors.append(f"roll{rolling_window}_log_multi_band_musicians_total")
    required_predictors = base_predictors + [f"roll{rolling_window}_{value}" for value in extra_predictors]

    sample = panel.copy()
    for predictor in required_predictors:
        sample = sample.loc[sample[predictor].notna()].copy()

    sample["cell_id"] = sample["city_country"].astype(str) + " || " + sample["genre_family"].astype(str)

    active_predictors: list[str] = []
    dropped_predictors: list[str] = []
    for predictor in required_predictors:
        z_name = f"z_{predictor}"
        z_values = zscore(sample[predictor])
        if float(z_values.std(ddof=0)) == 0.0:
            dropped_predictors.append(predictor)
            continue
        sample[z_name] = z_values
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
    for predictor in required_predictors:
        z_name = f"z_{predictor}"
        if z_name not in result.params.index:
            rows.append(
                {
                    "spec_id": spec_id,
                    "rolling_window_years": rolling_window,
                    "predictor": z_name,
                    "coefficient": np.nan,
                    "std_error": np.nan,
                    "p_value": np.nan,
                    "n_obs": int(result.nobs),
                    "event_count": int(sample["emerge_this_year"].sum()),
                    "event_rate": float(sample["emerge_this_year"].mean()),
                    "fixed_effects": "city-genre + year",
                    "clustering": "city",
                    "include_overall_switchers": int(include_overall_switchers),
                    "spec_note": spec_note,
                    "dropped_i": 1,
                }
            )
            continue
        rows.append(
            {
                "spec_id": spec_id,
                "rolling_window_years": rolling_window,
                "predictor": z_name,
                "coefficient": float(result.params[z_name]),
                "std_error": float(result.std_errors[z_name]),
                "p_value": float(result.pvalues[z_name]),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emerge_this_year"].sum()),
                "event_rate": float(sample["emerge_this_year"].mean()),
                "fixed_effects": "city-genre + year",
                "clustering": "city",
                "include_overall_switchers": int(include_overall_switchers),
                "spec_note": spec_note,
                "dropped_i": 0,
            }
        )

    metadata = {
        "spec_id": spec_id,
        "title": spec_note,
        "rolling_window_years": rolling_window,
        "n_obs": int(result.nobs),
        "event_count": int(sample["emerge_this_year"].sum()),
        "event_rate": float(sample["emerge_this_year"].mean()),
        "r_squared": float(result.rsquared),
        "include_overall_switchers": include_overall_switchers,
        "dropped_predictors": dropped_predictors,
    }
    return pd.DataFrame(rows), metadata


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


def format_stat(value: float, digits: int = 4) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def write_summary(results: pd.DataFrame, metadata_rows: list[dict[str, object]]) -> None:
    def coef(spec_id: str, predictor: str) -> float:
        subset = results.loc[
            results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "coefficient"
        ]
        return float(subset.iloc[0]) if not subset.empty else np.nan

    def pval(spec_id: str, predictor: str) -> float:
        subset = results.loc[
            results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "p_value"
        ]
        return float(subset.iloc[0]) if not subset.empty else np.nan

    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Scene cluster richer stress-test summary\n\n")
        handle.write(
            "This file stress-tests the richer scene-cluster extension by reusing the saved feature "
            "files, adding `roll-3` alongside `roll-5`, and fitting compact exact-year FE tables "
            "that compare count-based mechanism terms against share-based terms.\n\n"
        )

        handle.write("## Spec grid\n\n")
        handle.write("| Spec | Window | Includes overall switcher control | N | Events | Event rate | R-squared |\n")
        handle.write("|------|--------|----------------------------------|---|--------|------------|-----------|\n")
        for meta in metadata_rows:
            handle.write(
                f"| {meta['title']} | {meta['rolling_window_years']} | "
                f"{'yes' if meta['include_overall_switchers'] else 'no'} | "
                f"{meta['n_obs']} | {meta['event_count']} | {meta['event_rate']:.4f} | "
                f"{meta['r_squared']:.4f} |\n"
            )

        for meta in metadata_rows:
            subset = results.loc[results["spec_id"].eq(meta["spec_id"])].copy()
            handle.write(f"\n### {meta['title']}\n\n")
            if meta["dropped_predictors"]:
                dropped_text = ", ".join(f"`{value}`" for value in meta["dropped_predictors"])
                handle.write(f"- Dropped zero-variance predictors: {dropped_text}\n\n")
            handle.write("| Predictor | Coef | SE | P-value |\n")
            handle.write("|-----------|------|----|---------|\n")
            for _, row in subset.iterrows():
                coef_text = (
                    f"{row['coefficient']:.4f}{significance_stars(float(row['p_value']))}"
                    if not pd.isna(row["coefficient"])
                    else "n/a"
                )
                se_text = f"{row['std_error']:.4f}" if not pd.isna(row["std_error"]) else "n/a"
                p_text = f"{row['p_value']:.4f}" if not pd.isna(row["p_value"]) else "n/a"
                handle.write(f"| {row['predictor']} | {coef_text} | {se_text} | {p_text} |\n")

        handle.write("\n## Current read\n\n")
        handle.write(
            f"- In the compact counts-only specs, local spawning flow stays positive across windows: "
            f"`z_roll3_log_spawn_bands_formed = "
            f"{format_stat(coef('compact_counts_roll3_fe', 'z_roll3_log_spawn_bands_formed'))}` and "
            f"`z_roll5_log_spawn_bands_formed = "
            f"{format_stat(coef('compact_counts_roll5_fe', 'z_roll5_log_spawn_bands_formed'))}`.\n"
        )
        handle.write(
            f"- In that same counts-only frame, target-genre active bands and target-genre multi-band "
            f"musicians remain positive, but the broker-count term is slightly negative: "
            f"`z_roll3_log_genre_active_bands = "
            f"{format_stat(coef('compact_counts_roll3_fe', 'z_roll3_log_genre_active_bands'))}`, "
            f"`z_roll5_log_genre_active_bands = "
            f"{format_stat(coef('compact_counts_roll5_fe', 'z_roll5_log_genre_active_bands'))}`, "
            f"`z_roll3_log_genre_multi_band_musicians = "
            f"{format_stat(coef('compact_counts_roll3_fe', 'z_roll3_log_genre_multi_band_musicians'))}`, "
            f"`z_roll5_log_genre_multi_band_musicians = "
            f"{format_stat(coef('compact_counts_roll5_fe', 'z_roll5_log_genre_multi_band_musicians'))}`, "
            f"while `z_roll3_log_genre_broker_musicians = "
            f"{format_stat(coef('compact_counts_roll3_fe', 'z_roll3_log_genre_broker_musicians'))}` "
            f"and `z_roll5_log_genre_broker_musicians = "
            f"{format_stat(coef('compact_counts_roll5_fe', 'z_roll5_log_genre_broker_musicians'))}`.\n"
        )
        handle.write(
            f"- When the share terms enter at `roll-5`, "
            f"`z_roll5_spawn_share_formed = "
            f"{format_stat(coef('compact_counts_shares_roll5_fe', 'z_roll5_spawn_share_formed'))}` "
            f"(p = {format_stat(pval('compact_counts_shares_roll5_fe', 'z_roll5_spawn_share_formed'))}), "
            f"`z_roll5_genre_broker_share = "
            f"{format_stat(coef('compact_counts_shares_roll5_fe', 'z_roll5_genre_broker_share'))}` "
            f"(p = {format_stat(pval('compact_counts_shares_roll5_fe', 'z_roll5_genre_broker_share'))}), "
            f"and `z_roll5_genre_multi_band_share = "
            f"{format_stat(coef('compact_counts_shares_roll5_fe', 'z_roll5_genre_multi_band_share'))}` "
            f"(p = {format_stat(pval('compact_counts_shares_roll5_fe', 'z_roll5_genre_multi_band_share'))}).\n"
        )
        handle.write(
            f"- The count terms in that same `roll-5` counts-plus-shares spec are "
            f"`z_roll5_log_spawn_bands_formed = "
            f"{format_stat(coef('compact_counts_shares_roll5_fe', 'z_roll5_log_spawn_bands_formed'))}`, "
            f"`z_roll5_log_genre_active_bands = "
            f"{format_stat(coef('compact_counts_shares_roll5_fe', 'z_roll5_log_genre_active_bands'))}`, "
            f"`z_roll5_log_genre_broker_musicians = "
            f"{format_stat(coef('compact_counts_shares_roll5_fe', 'z_roll5_log_genre_broker_musicians'))}`, "
            f"and `z_roll5_log_genre_multi_band_musicians = "
            f"{format_stat(coef('compact_counts_shares_roll5_fe', 'z_roll5_log_genre_multi_band_musicians'))}`, "
            f"so the broker-count term flips from negative to positive once broker share is held fixed.\n"
        )
        handle.write(
            f"- Dropping the overall switcher control changes the `roll-5` targeted switcher count from "
            f"`{format_stat(coef('compact_counts_roll5_fe', 'z_roll5_log_genre_multi_band_musicians'))}` "
            f"to `{format_stat(coef('compact_counts_no_total_switchers_roll5_fe', 'z_roll5_log_genre_multi_band_musicians'))}`, "
            f"which helps show whether the within-genre switcher term is only proxying for overall "
            f"multi-band density.\n"
        )
        handle.write(
            "- This remains a predictive panel design rather than a causal identification strategy. "
            "The value of the stress test is to show whether the richer scene story survives a "
            "compact specification and shorter lag window.\n"
        )


def main() -> None:
    overall, genre, emergence = load_inputs()
    overall, genre = add_rolling_features(overall, genre)
    panel = build_panel(overall, genre, emergence)

    specs = [
        (
            "compact_counts_roll3_fe",
            3,
            [
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "log_genre_multi_band_musicians",
            ],
            "Compact exact-year FE, roll-3 counts only",
            True,
        ),
        (
            "compact_counts_roll5_fe",
            5,
            [
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "log_genre_multi_band_musicians",
            ],
            "Compact exact-year FE, roll-5 counts only",
            True,
        ),
        (
            "compact_counts_shares_roll3_fe",
            3,
            [
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "log_genre_multi_band_musicians",
                "spawn_share_formed",
                "genre_broker_share",
                "genre_multi_band_share",
            ],
            "Compact exact-year FE, roll-3 counts plus shares",
            True,
        ),
        (
            "compact_counts_shares_roll5_fe",
            5,
            [
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "log_genre_multi_band_musicians",
                "spawn_share_formed",
                "genre_broker_share",
                "genre_multi_band_share",
            ],
            "Compact exact-year FE, roll-5 counts plus shares",
            True,
        ),
        (
            "compact_counts_no_total_switchers_roll3_fe",
            3,
            [
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "log_genre_multi_band_musicians",
            ],
            "Compact exact-year FE, roll-3 counts only without overall switcher control",
            False,
        ),
        (
            "compact_counts_no_total_switchers_roll5_fe",
            5,
            [
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "log_genre_multi_band_musicians",
            ],
            "Compact exact-year FE, roll-5 counts only without overall switcher control",
            False,
        ),
    ]

    result_frames: list[pd.DataFrame] = []
    metadata_rows: list[dict[str, object]] = []
    for spec_id, rolling_window, extra_predictors, spec_note, include_overall_switchers in specs:
        result_frame, metadata = fit_panel_spec(
            panel=panel,
            spec_id=spec_id,
            rolling_window=rolling_window,
            extra_predictors=extra_predictors,
            spec_note=spec_note,
            include_overall_switchers=include_overall_switchers,
        )
        result_frames.append(result_frame)
        metadata_rows.append(metadata)

    results = pd.concat(result_frames, ignore_index=True)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(results=results, metadata_rows=metadata_rows)

    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
