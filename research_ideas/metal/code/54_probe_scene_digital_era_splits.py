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

RESULTS_PATH = SCENE_DIR / "scene_digital_era_split_results.csv"
SUMMARY_PATH = SCENE_DIR / "scene_digital_era_split_summary.md"

ROLLING_WINDOW = 5
PREDICTORS = [
    "log_active_bands",
    "n_nontrivial_communities",
    "log_multi_band_musicians_total",
    "log_spawn_bands_formed",
    "log_genre_active_bands",
    "log_genre_multi_band_musicians",
]

DISPLAY_LABELS = {
    "log_active_bands": "Overall active bands",
    "n_nontrivial_communities": "Nontrivial communities",
    "log_multi_band_musicians_total": "Overall multi-band musicians",
    "log_spawn_bands_formed": "Local spawning flow",
    "log_genre_active_bands": "Target-genre active bands",
    "log_genre_multi_band_musicians": "Target-genre multi-band musicians",
}

PERIODS = [
    ("pre_1995", None, 1994, "Pre-digital baseline (<=1994)"),
    ("transition_1995_2004", 1995, 2004, "Digital transition (1995-2004)"),
    ("mature_2005_2014", 2005, 2014, "Mature digital era (2005-2014)"),
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
        "log_active_bands",
        "log_multi_band_musicians_total",
        "log_spawn_bands_formed",
    ]:
        if column in overall.columns:
            overall[column] = pd.to_numeric(overall[column], errors="coerce")

    for column in [
        "genre_active_bands",
        "genre_multi_band_musicians",
        "log_genre_active_bands",
        "log_genre_multi_band_musicians",
    ]:
        if column in genre.columns:
            genre[column] = pd.to_numeric(genre[column], errors="coerce")

    for column in ["first_band_year", "emergence_year"]:
        emergence[column] = pd.to_numeric(emergence[column], errors="coerce")

    overall = overall.fillna(
        {
            "n_multi_band_musicians_total": 0.0,
            "spawn_bands_formed": 0.0,
        }
    )
    genre = genre.fillna(
        {
            "genre_active_bands": 0.0,
            "genre_multi_band_musicians": 0.0,
        }
    )

    overall["log_active_bands"] = np.log1p(overall["n_active_bands"])
    overall["log_multi_band_musicians_total"] = np.log1p(overall["n_multi_band_musicians_total"])
    overall["log_spawn_bands_formed"] = np.log1p(overall["spawn_bands_formed"])

    genre["log_genre_active_bands"] = np.log1p(genre["genre_active_bands"])
    genre["log_genre_multi_band_musicians"] = np.log1p(genre["genre_multi_band_musicians"])

    return overall, genre, emergence


def add_rolling_features(overall: pd.DataFrame, genre: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    overall = overall.sort_values(["city_country", "snapshot_year"]).reset_index(drop=True).copy()
    genre = genre.sort_values(["city_country", "genre_family", "snapshot_year"]).reset_index(drop=True).copy()

    min_periods = rolling_min_periods(ROLLING_WINDOW)
    for column in ["log_active_bands", "n_nontrivial_communities", "log_multi_band_musicians_total", "log_spawn_bands_formed"]:
        overall[f"roll{ROLLING_WINDOW}_{column}"] = overall.groupby("city_country")[column].transform(
            lambda series, w=ROLLING_WINDOW, m=min_periods: series.shift(1).rolling(w, min_periods=m).mean()
        )

    for column in ["log_genre_active_bands", "log_genre_multi_band_musicians"]:
        genre[f"roll{ROLLING_WINDOW}_{column}"] = genre.groupby(["city_country", "genre_family"])[column].transform(
            lambda series, w=ROLLING_WINDOW, m=min_periods: series.shift(1).rolling(w, min_periods=m).mean()
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


def fit_period_spec(panel: pd.DataFrame, period_id: str, year_min: int | None, year_max: int | None, title: str) -> tuple[pd.DataFrame, dict[str, object]]:
    sample = panel.copy()
    if year_min is not None:
        sample = sample.loc[sample["snapshot_year"] >= year_min].copy()
    if year_max is not None:
        sample = sample.loc[sample["snapshot_year"] <= year_max].copy()

    required_predictors = [f"roll{ROLLING_WINDOW}_{predictor}" for predictor in PREDICTORS]
    for predictor in required_predictors:
        sample = sample.loc[sample[predictor].notna()].copy()

    sample["cell_id"] = sample["city_country"].astype(str) + " || " + sample["genre_family"].astype(str)

    active_predictors: list[str] = []
    for predictor in required_predictors:
        z_name = f"z_{predictor}"
        z_values = zscore(sample[predictor])
        if float(z_values.std(ddof=0)) == 0.0:
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
    for predictor in PREDICTORS:
        z_name = f"z_roll{ROLLING_WINDOW}_{predictor}"
        rows.append(
            {
                "period_id": period_id,
                "period_title": title,
                "year_min": year_min,
                "year_max": year_max,
                "predictor": predictor,
                "coefficient": float(result.params.get(z_name, np.nan)),
                "std_error": float(result.std_errors.get(z_name, np.nan)),
                "p_value": float(result.pvalues.get(z_name, np.nan)),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emerge_this_year"].sum()),
                "event_rate": float(sample["emerge_this_year"].mean()),
                "r_squared": float(result.rsquared),
            }
        )

    metadata = {
        "period_id": period_id,
        "period_title": title,
        "year_min": year_min,
        "year_max": year_max,
        "n_obs": int(result.nobs),
        "event_count": int(sample["emerge_this_year"].sum()),
        "event_rate": float(sample["emerge_this_year"].mean()),
        "r_squared": float(result.rsquared),
    }
    return pd.DataFrame(rows), metadata


def format_stat(value: float, digits: int = 4) -> str:
    if pd.isna(value):
        return "n/a"
    return f"{value:.{digits}f}"


def write_summary(results: pd.DataFrame, metadata_rows: list[dict[str, object]]) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Scene digital-era split probe\n\n")
        handle.write(
            "This probe reuses the preferred `roll-5` exact-year fixed-effects scene specification, "
            "but splits the sample into three broad periods to ask whether the main local-scene "
            "coefficients weaken as digital access frictions fall.\n\n"
        )
        handle.write("## Sample periods\n\n")
        for meta in metadata_rows:
            year_label = []
            if meta["year_min"] is None:
                year_label.append(f"<= {meta['year_max']}")
            elif meta["year_max"] is None:
                year_label.append(f">= {meta['year_min']}")
            else:
                year_label.append(f"{meta['year_min']}-{meta['year_max']}")
            handle.write(
                f"- `{meta['period_title']}`: years `{''.join(year_label)}`, "
                f"N = `{meta['n_obs']}`, events = `{meta['event_count']}`, "
                f"event rate = `{meta['event_rate']:.4f}`.\n"
            )

        handle.write("\n## Headline coefficients by period\n\n")
        handle.write("| Predictor | <=1994 | 1995-2004 | 2005-2014 |\n")
        handle.write("|-----------|--------|-----------|-----------|\n")
        for predictor in PREDICTORS:
            values: list[str] = []
            for period_id, _, _, _ in PERIODS:
                row = results.loc[(results["period_id"] == period_id) & (results["predictor"] == predictor)].iloc[0]
                coef = row["coefficient"]
                pval = row["p_value"]
                stars = "***" if pval < 0.01 else "**" if pval < 0.05 else "*" if pval < 0.10 else ""
                values.append(f"{coef:.4f}{stars}")
            handle.write(f"| {DISPLAY_LABELS[predictor]} | {' | '.join(values)} |\n")

        def coef(period_id: str, predictor: str) -> float:
            return float(
                results.loc[(results["period_id"] == period_id) & (results["predictor"] == predictor), "coefficient"].iloc[0]
            )

        handle.write("\n## Current read\n\n")
        handle.write(
            f"- `Local spawning flow` is `{format_stat(coef('pre_1995', 'log_spawn_bands_formed'))}` "
            f"before 1995, `{format_stat(coef('transition_1995_2004', 'log_spawn_bands_formed'))}` "
            f"in 1995-2004, and `{format_stat(coef('mature_2005_2014', 'log_spawn_bands_formed'))}` "
            f"in 2005-2014.\n"
        )
        handle.write(
            f"- `Target-genre active bands` is `{format_stat(coef('pre_1995', 'log_genre_active_bands'))}`, "
            f"`{format_stat(coef('transition_1995_2004', 'log_genre_active_bands'))}`, and "
            f"`{format_stat(coef('mature_2005_2014', 'log_genre_active_bands'))}` across the same periods.\n"
        )
        handle.write(
            f"- `Target-genre multi-band musicians` is `{format_stat(coef('pre_1995', 'log_genre_multi_band_musicians'))}`, "
            f"`{format_stat(coef('transition_1995_2004', 'log_genre_multi_band_musicians'))}`, and "
            f"`{format_stat(coef('mature_2005_2014', 'log_genre_multi_band_musicians'))}` across the same periods.\n"
        )
        handle.write(
            "- These period splits are descriptive robustness checks, not a clean estimate of the "
            "causal effect of digitization. They are useful mainly for seeing whether the local "
            "scene coefficients attenuate once online access becomes more important.\n"
        )


def main() -> None:
    overall, genre, emergence = load_inputs()
    overall, genre = add_rolling_features(overall, genre)
    panel = build_panel(overall, genre, emergence)

    result_frames: list[pd.DataFrame] = []
    metadata_rows: list[dict[str, object]] = []
    for period_id, year_min, year_max, title in PERIODS:
        result_frame, metadata = fit_period_spec(panel, period_id, year_min, year_max, title)
        result_frames.append(result_frame)
        metadata_rows.append(metadata)

    results = pd.concat(result_frames, ignore_index=True)
    results["display_label"] = results["predictor"].map(DISPLAY_LABELS)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(results, metadata_rows)

    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
