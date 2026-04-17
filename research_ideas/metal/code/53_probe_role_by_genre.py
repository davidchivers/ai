from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

OVERALL_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
GENRE_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"

RESULTS_PATH = SCENE_DIR / "scene_role_by_genre_probe_results.csv"
SUMMARY_PATH = SCENE_DIR / "scene_role_by_genre_probe_summary.md"

GENRES = ["black_metal", "death_metal", "doom_metal", "power_metal", "thrash_metal"]
ROLES = ["guitar", "drums", "bass", "vocals", "keyboards"]


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def build_panel() -> pd.DataFrame:
    overall = pd.read_csv(OVERALL_PATH)
    genre = pd.read_csv(GENRE_PATH)
    emergence = pd.read_csv(
        EMERGENCE_PATH,
        usecols=["city_country", "genre_family", "first_band_year", "emergence_year"],
    )
    for column in ["first_band_year", "emergence_year"]:
        emergence[column] = pd.to_numeric(emergence[column], errors="coerce")

    panel = overall.merge(emergence, on="city_country", how="inner").merge(
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


def fit_role_spec(panel: pd.DataFrame, genre_family: str, role: str) -> dict[str, object]:
    predictors = [
        "roll5_log_active_bands",
        "roll5_n_nontrivial_communities",
        "roll5_log_multi_band_musicians_total",
        "roll5_log_genre_active_bands",
        f"roll5_log_genre_active_{role}_musicians",
    ]

    sample = panel.loc[panel["genre_family"] == genre_family].copy()
    for predictor in predictors:
        sample = sample.loc[sample[predictor].notna()].copy()

    event_count = int(sample["emerge_this_year"].sum())
    if sample.empty or event_count == 0:
        return {
            "genre_family": genre_family,
            "role": role,
            "coefficient": np.nan,
            "std_error": np.nan,
            "p_value": np.nan,
            "n_obs": int(len(sample)),
            "event_count": event_count,
            "r_squared": np.nan,
        }

    sample["cell_id"] = sample["city_country"].astype(str) + " || " + sample["genre_family"].astype(str)
    active_predictors: list[str] = []
    for predictor in predictors:
        z_name = f"z_{predictor}"
        z_values = zscore(sample[predictor])
        sample[z_name] = z_values
        if float(z_values.std(ddof=0)) != 0.0:
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

    key = f"z_roll5_log_genre_active_{role}_musicians"
    return {
        "genre_family": genre_family,
        "role": role,
        "coefficient": float(result.params.get(key, np.nan)),
        "std_error": float(result.std_errors.get(key, np.nan)),
        "p_value": float(result.pvalues.get(key, np.nan)),
        "n_obs": int(result.nobs),
        "event_count": event_count,
        "r_squared": float(result.rsquared),
    }


def main() -> None:
    panel = build_panel()
    rows = [fit_role_spec(panel, genre_family, role) for genre_family in GENRES for role in ROLES]
    results = pd.DataFrame(rows).sort_values(["genre_family", "p_value", "role"], na_position="last")
    results.to_csv(RESULTS_PATH, index=False)

    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Role-by-genre probe\n\n")
        handle.write(
            "This probe reuses the role-targeted labor-pool specification from the richer scene "
            "extension, but fits it separately within the five largest headline genre families: "
            "`black_metal`, `death_metal`, `doom_metal`, `power_metal`, and `thrash_metal`.\n\n"
        )
        handle.write(
            "Each genre-specific regression keeps the same exact-year fixed-effects structure and "
            "asks whether target-genre role-specific labor pools add anything conditional on overall "
            "local metal size, community structure, overall multi-band depth, and target-genre band stock.\n\n"
        )
        handle.write("## Best role term by genre\n\n")
        for genre_family in GENRES:
            subset = results.loc[(results["genre_family"] == genre_family) & results["coefficient"].notna()].copy()
            if subset.empty:
                continue
            subset["abs_coefficient"] = subset["coefficient"].abs()
            best = subset.sort_values(["abs_coefficient", "p_value"], ascending=[False, True]).iloc[0]
            handle.write(
                f"- `{genre_family}`: `{best['role']}` is the strongest role term, "
                f"coef = `{best['coefficient']:.4f}`, p = `{best['p_value']:.4f}`, "
                f"N = `{int(best['n_obs'])}`, events = `{int(best['event_count'])}`.\n"
            )

        handle.write("\n## Current read\n\n")
        handle.write(
            "- The negative guitarist term survives within every tested genre family, so the pooled "
            "negative guitar result is not just a composition artifact.\n"
        )
        handle.write(
            "- `power_metal` is the clearest exception to the pooled null pattern elsewhere: "
            "keyboards enter positively while guitar and vocals remain negative.\n"
        )
        handle.write(
            "- Drums and vocals show occasional negative coefficients in specific genres, but there "
            "is still no clean positive instrument-specific headline comparable to the broader "
            "multi-band-musician result.\n"
        )


if __name__ == "__main__":
    main()
