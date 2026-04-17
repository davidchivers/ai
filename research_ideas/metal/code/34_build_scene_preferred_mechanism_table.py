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

OUTPUT_TABLE_PATH = SCENE_DIR / "scene_cluster_preferred_mechanism_table.csv"
OUTPUT_SUMMARY_PATH = SCENE_DIR / "scene_cluster_preferred_mechanism_table.md"

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

DISPLAY_LABELS = {
    "log_active_bands": "Overall active bands",
    "n_nontrivial_communities": "Nontrivial communities",
    "log_multi_band_musicians_total": "Overall multi-band musicians",
    "log_spawn_bands_formed": "Local spawning flow",
    "spawn_share_formed": "Spawn share",
    "log_genre_active_bands": "Target-genre active bands",
    "log_genre_broker_musicians": "Target-genre broker musicians",
    "genre_broker_share": "Target-genre broker share",
    "log_genre_multi_band_musicians": "Target-genre multi-band musicians",
    "genre_multi_band_share": "Target-genre multi-band share",
}


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
        "log_active_bands",
        "log_multi_band_musicians_total",
        "log_spawn_bands_formed",
    ]:
        if column in overall.columns:
            overall[column] = pd.to_numeric(overall[column], errors="coerce")

    for column in [
        "genre_active_bands",
        "genre_multi_band_musicians",
        "genre_broker_musicians",
        "genre_broker_share",
        "genre_multi_band_share",
        "log_genre_active_bands",
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
    predictors: list[str],
    spec_note: str,
) -> tuple[pd.DataFrame, dict[str, object]]:
    required_predictors = [f"roll{rolling_window}_{value}" for value in predictors]

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
    for predictor in predictors:
        column_name = f"roll{rolling_window}_{predictor}"
        z_name = f"z_{column_name}"
        if z_name not in result.params.index:
            rows.append(
                {
                    "spec_id": spec_id,
                    "rolling_window_years": rolling_window,
                    "predictor": predictor,
                    "coefficient": np.nan,
                    "std_error": np.nan,
                    "p_value": np.nan,
                    "n_obs": int(result.nobs),
                    "event_count": int(sample["emerge_this_year"].sum()),
                    "event_rate": float(sample["emerge_this_year"].mean()),
                    "r_squared": float(result.rsquared),
                    "fixed_effects": "city-genre + year",
                    "clustering": "city",
                    "spec_note": spec_note,
                    "dropped_i": 1,
                }
            )
            continue
        rows.append(
            {
                "spec_id": spec_id,
                "rolling_window_years": rolling_window,
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


def format_coef_se(coef: float, se: float, p_value: float) -> str:
    if pd.isna(coef):
        return ""
    return f"{coef:.4f}{significance_stars(p_value)} ({se:.4f})"


def format_stat(value: float, digits: int = 4) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def write_summary(results: pd.DataFrame, metadata_rows: list[dict[str, object]]) -> None:
    preferred_core = "preferred_core_roll5_fe"
    preferred_extension = "preferred_composition_roll5_fe"
    core_roll3 = "preferred_core_roll3_fe"
    core_no_total = "preferred_core_roll5_no_total_switchers_fe"
    broker_reference = "preferred_broker_reference_roll5_fe"

    display_rows = [
        "log_active_bands",
        "n_nontrivial_communities",
        "log_multi_band_musicians_total",
        "log_spawn_bands_formed",
        "spawn_share_formed",
        "log_genre_active_bands",
        "log_genre_broker_musicians",
        "genre_broker_share",
        "log_genre_multi_band_musicians",
        "genre_multi_band_share",
    ]

    def row(spec_id: str, predictor: str) -> pd.Series | None:
        subset = results.loc[
            results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor)
        ]
        if subset.empty:
            return None
        return subset.iloc[0]

    with OUTPUT_SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Scene preferred mechanism table\n\n")
        handle.write(
            "This file locks the preferred headline presentation for the scene branch. The chosen "
            "format is a paired `roll-5` exact-year FE table: a core counts-only panel for the "
            "stable unconditional mechanisms, plus a composition extension that adds the share "
            "terms and the broker-count conditional read.\n\n"
        )

        handle.write("## Chosen presentation\n\n")
        handle.write("| Predictor | Panel A: core counts-only | Panel B: composition extension |\n")
        handle.write("|-----------|---------------------------|-------------------------------|\n")
        for predictor in display_rows:
            row_a = row(preferred_core, predictor)
            row_b = row(preferred_extension, predictor)
            value_a = (
                format_coef_se(float(row_a["coefficient"]), float(row_a["std_error"]), float(row_a["p_value"]))
                if row_a is not None
                else ""
            )
            value_b = (
                format_coef_se(float(row_b["coefficient"]), float(row_b["std_error"]), float(row_b["p_value"]))
                if row_b is not None
                else ""
            )
            handle.write(f"| {DISPLAY_LABELS[predictor]} | {value_a} | {value_b} |\n")

        core_meta = next(meta for meta in metadata_rows if meta["spec_id"] == preferred_core)
        extension_meta = next(meta for meta in metadata_rows if meta["spec_id"] == preferred_extension)
        handle.write(
            f"| N | {core_meta['n_obs']} | {extension_meta['n_obs']} |\n"
        )
        handle.write(
            f"| Events | {core_meta['event_count']} | {extension_meta['event_count']} |\n"
        )
        handle.write(
            f"| Event rate | {core_meta['event_rate']:.4f} | {extension_meta['event_rate']:.4f} |\n"
        )
        handle.write(
            f"| R-squared | {core_meta['r_squared']:.4f} | {extension_meta['r_squared']:.4f} |\n"
        )

        handle.write("\n## Selection rationale\n\n")
        handle.write(
            "- Panel A is the headline mechanism panel because the cleanest stable unconditional "
            "terms are local spawning flow, target-genre active bands, and target-genre multi-band "
            "musicians.\n"
        )
        handle.write(
            "- Panel B stays adjacent to Panel A because the negative share terms are substantively "
            "important and the broker result changes sign once broker concentration is held fixed.\n"
        )
        handle.write(
            "- This paired presentation is more defensible than a single counts-only table, which "
            "would hide the composition result, and more defensible than a single counts-plus-shares "
            "table, which would overstate broker count as an unconditional headline.\n"
        )

        core_roll3_row = row(core_roll3, "log_genre_multi_band_musicians")
        core_roll5_row = row(preferred_core, "log_genre_multi_band_musicians")
        core_no_total_row = row(core_no_total, "log_genre_multi_band_musicians")
        broker_core_row = row(broker_reference, "log_genre_broker_musicians")
        broker_extension_row = row(preferred_extension, "log_genre_broker_musicians")
        broker_share_row = row(preferred_extension, "genre_broker_share")

        handle.write("\n## Current read\n\n")
        handle.write(
            f"- In the preferred core panel, local spawning flow is "
            f"`{format_stat(float(row(preferred_core, 'log_spawn_bands_formed')['coefficient']))}` and "
            f"target-genre active bands are "
            f"`{format_stat(float(row(preferred_core, 'log_genre_active_bands')['coefficient']))}`.\n"
        )
        handle.write(
            f"- Target-genre multi-band musician depth is "
            f"`{format_stat(float(core_roll5_row['coefficient']))}` in the preferred core panel, "
            f"`{format_stat(float(core_roll3_row['coefficient']))}` in the `roll-3` robustness panel, "
            f"and `{format_stat(float(core_no_total_row['coefficient']))}` when the overall switcher "
            f"control is removed.\n"
        )
        handle.write(
            f"- The broker term is not stable enough to headline alone, which is why it is omitted "
            f"from Panel A: in the counts-only broker reference panel it is "
            f"`{format_stat(float(broker_core_row['coefficient']))}`, but it becomes "
            f"`{format_stat(float(broker_extension_row['coefficient']))}` in the composition "
            f"extension once `broker share` enters at "
            f"`{format_stat(float(broker_share_row['coefficient']))}`.\n"
        )
        handle.write(
            "- The resulting paper read is that thicker target-genre stocks and local spinout or "
            "switcher depth predict emergence, while concentration-heavy compositions are negative. "
            "Broker musicians belong in the paper as a conditional composition result, not yet as a "
            "standalone unconditional stock headline.\n"
        )


def main() -> None:
    overall, genre, emergence = load_inputs()
    overall, genre = add_rolling_features(overall, genre)
    panel = build_panel(overall, genre, emergence)

    specs = [
        (
            "preferred_core_roll5_fe",
            5,
            [
                "log_active_bands",
                "n_nontrivial_communities",
                "log_multi_band_musicians_total",
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_multi_band_musicians",
            ],
            "Preferred core exact-year FE, roll-5 counts only",
        ),
        (
            "preferred_composition_roll5_fe",
            5,
            [
                "log_active_bands",
                "n_nontrivial_communities",
                "log_multi_band_musicians_total",
                "log_spawn_bands_formed",
                "spawn_share_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "genre_broker_share",
                "log_genre_multi_band_musicians",
                "genre_multi_band_share",
            ],
            "Preferred composition exact-year FE, roll-5 paired extension",
        ),
        (
            "preferred_core_roll3_fe",
            3,
            [
                "log_active_bands",
                "n_nontrivial_communities",
                "log_multi_band_musicians_total",
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_multi_band_musicians",
            ],
            "Preferred core exact-year FE, roll-3 robustness",
        ),
        (
            "preferred_core_roll5_no_total_switchers_fe",
            5,
            [
                "log_active_bands",
                "n_nontrivial_communities",
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_multi_band_musicians",
            ],
            "Preferred core exact-year FE, roll-5 without overall switcher control",
        ),
        (
            "preferred_broker_reference_roll5_fe",
            5,
            [
                "log_active_bands",
                "n_nontrivial_communities",
                "log_multi_band_musicians_total",
                "log_spawn_bands_formed",
                "log_genre_active_bands",
                "log_genre_broker_musicians",
                "log_genre_multi_band_musicians",
            ],
            "Counts-only broker reference exact-year FE, roll-5",
        ),
    ]

    result_frames: list[pd.DataFrame] = []
    metadata_rows: list[dict[str, object]] = []
    for spec_id, rolling_window, predictors, spec_note in specs:
        result_frame, metadata = fit_panel_spec(
            panel=panel,
            spec_id=spec_id,
            rolling_window=rolling_window,
            predictors=predictors,
            spec_note=spec_note,
        )
        result_frames.append(result_frame)
        metadata_rows.append(metadata)

    results = pd.concat(result_frames, ignore_index=True)
    results["display_label"] = results["predictor"].map(DISPLAY_LABELS)
    results.to_csv(OUTPUT_TABLE_PATH, index=False)
    write_summary(results=results, metadata_rows=metadata_rows)

    print(f"Wrote {OUTPUT_TABLE_PATH}")
    print(f"Wrote {OUTPUT_SUMMARY_PATH}")


if __name__ == "__main__":
    main()
