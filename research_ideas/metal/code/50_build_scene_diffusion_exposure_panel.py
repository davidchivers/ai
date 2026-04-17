from __future__ import annotations

import argparse
import math
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

import geonamescache
import numpy as np
import pandas as pd
import pycountry
import statsmodels.formula.api as smf


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
FIRST_APPEARANCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
RICHER_FEATURES_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
GEOGRAPHY_AUDIT_PATH = SCENE_DIR / "city_geography_audit.csv"
DIFFUSION_DIR = SCENE_DIR / "diffusion"

COUNTRY_ALIAS_TO_ISO2 = {
    "usa": "US",
    "united states": "US",
    "uk": "GB",
    "united kingdom": "GB",
    "england": "GB",
    "turkiye": "TR",
    "turkey": "TR",
    "korea rep": "KR",
    "egypt arab rep": "EG",
    "venezuela rb": "VE",
    "slovak republic": "SK",
    "czech republic": "CZ",
    "russian federation": "RU",
    "macedonia": "MK",
}

CITY_ALIASES = {
    ("antwerp", "BE"): ["antwerpen"],
    ("bruges", "BE"): ["brugge"],
    ("busan", "KR"): ["pusan"],
    ("brooklyn new york city", "US"): ["brooklyn"],
    ("east jakarta", "ID"): ["jakarta"],
    ("barquisimeto", "VE"): ["barquisimeto"],
    ("caracas", "VE"): ["caracas"],
    ("cairo", "EG"): ["cairo"],
}

DISTANCE_SCALE_KM = 1000.0


def normalize_text(value: object) -> str:
    if value is None:
        return ""
    text = str(value).strip()
    return "" if text.lower() == "nan" else text


def normalize_key(value: object) -> str:
    text = normalize_text(value)
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii").lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def country_to_iso2(country_name: str) -> str:
    key = normalize_key(country_name)
    if key in COUNTRY_ALIAS_TO_ISO2:
        return COUNTRY_ALIAS_TO_ISO2[key]
    try:
        return pycountry.countries.lookup(country_name).alpha_2
    except LookupError:
        return ""


def city_candidate_keys(city_name: str, iso2: str) -> list[tuple[str, str]]:
    keys: list[str] = []
    cleaned = normalize_key(city_name)
    if cleaned:
        keys.append(cleaned)
    if "(" in city_name:
        left = normalize_key(city_name.split("(", 1)[0])
        if left:
            keys.append(left)
    if "/" in city_name:
        for piece in city_name.split("/"):
            piece_key = normalize_key(piece)
            if piece_key:
                keys.append(piece_key)
    for alias in CITY_ALIASES.get((cleaned, iso2), []):
        alias_norm = normalize_key(alias)
        if alias_norm:
            keys.append(alias_norm)

    deduped: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for key in keys:
        pair = (key, iso2)
        if pair not in seen:
            seen.add(pair)
            deduped.append(pair)
    return deduped


def build_geonames_index() -> dict[tuple[str, str], list[dict[str, object]]]:
    gc = geonamescache.GeonamesCache()
    index: dict[tuple[str, str], list[dict[str, object]]] = defaultdict(list)
    for row in gc.get_cities().values():
        names = [row.get("name", "")]
        names.extend(row.get("alternatenames", []))
        for name in names:
            key = normalize_key(name)
            if key:
                index[(key, row["countrycode"])].append(row)
    for key, values in index.items():
        values.sort(key=lambda item: int(item.get("population") or 0), reverse=True)
    return index


def build_coordinate_crosswalk(first_subset: pd.DataFrame) -> pd.DataFrame:
    index = build_geonames_index()
    rows: list[dict[str, object]] = []
    for city_country, city, country in first_subset[["city_country", "city", "country"]].drop_duplicates().itertuples(index=False, name=None):
        iso2 = country_to_iso2(country)
        match = None
        matched_key = ""
        if iso2:
            for candidate in city_candidate_keys(city, iso2):
                matches = index.get(candidate, [])
                if matches:
                    match = matches[0]
                    matched_key = candidate[0]
                    break
        rows.append(
            {
                "city_country": city_country,
                "coord_match_i": int(match is not None),
                "matched_key": matched_key,
                "latitude": float(match["latitude"]) if match else math.nan,
                "longitude": float(match["longitude"]) if match else math.nan,
            }
        )
    return pd.DataFrame(rows)


def haversine_matrix(origin_lat: np.ndarray, origin_lon: np.ndarray, dest_lat: np.ndarray, dest_lon: np.ndarray) -> np.ndarray:
    radius_km = 6371.0
    o_lat = np.radians(origin_lat)[:, None]
    o_lon = np.radians(origin_lon)[:, None]
    d_lat = np.radians(dest_lat)[None, :]
    d_lon = np.radians(dest_lon)[None, :]
    delta_lat = d_lat - o_lat
    delta_lon = d_lon - o_lon
    a = np.sin(delta_lat / 2.0) ** 2 + np.cos(o_lat) * np.cos(d_lat) * np.sin(delta_lon / 2.0) ** 2
    c = 2.0 * np.arcsin(np.sqrt(a))
    return radius_km * c


def zscore(series: pd.Series) -> pd.Series:
    std = series.std()
    if pd.isna(std) or std == 0:
        return pd.Series(np.zeros(len(series)), index=series.index)
    return (series - series.mean()) / std


def build_exposure_panel(genre_family: str) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    first = pd.read_csv(FIRST_APPEARANCE_PATH, dtype=str, keep_default_na=False)
    richer = pd.read_csv(RICHER_FEATURES_PATH, dtype=str, keep_default_na=False)
    geography = pd.read_csv(GEOGRAPHY_AUDIT_PATH, dtype=str, keep_default_na=False)
    geography["exclude_city_baseline_i"] = pd.to_numeric(geography["exclude_city_baseline_i"], errors="coerce").fillna(0)

    first = first.loc[first["genre_family"] == genre_family].copy()
    first = first.merge(geography[["city_country", "exclude_city_baseline_i"]], on="city_country", how="left")
    first = first.loc[first["exclude_city_baseline_i"].fillna(0) == 0].copy()
    first["first_band_year"] = pd.to_numeric(first["first_band_year"], errors="coerce")
    first["emergence_year"] = pd.to_numeric(first["emergence_year"], errors="coerce")
    first["total_bands"] = pd.to_numeric(first["total_bands"], errors="coerce")

    coords = build_coordinate_crosswalk(first)
    first = first.merge(coords, on="city_country", how="left")
    first = first.loc[first["coord_match_i"] == 1].copy()

    richer = richer.loc[richer["genre_family"] == genre_family].copy()
    richer["snapshot_year"] = pd.to_numeric(richer["snapshot_year"], errors="coerce")
    richer["genre_active_bands"] = pd.to_numeric(richer["genre_active_bands"], errors="coerce")
    richer = richer.merge(
        first[["city_country", "city", "country", "first_band_year", "emergence_year", "latitude", "longitude", "total_bands"]],
        on="city_country",
        how="inner",
    )
    richer = richer.loc[richer["snapshot_year"].notna()].copy()
    richer["snapshot_year"] = richer["snapshot_year"].astype(int)
    richer = richer.sort_values(["city_country", "snapshot_year"]).reset_index(drop=True)

    # At-risk sample: after first local band appears and before local emergence resolves.
    risk = richer.loc[richer["snapshot_year"] >= richer["first_band_year"]].copy()
    risk = risk.loc[(risk["emergence_year"].isna()) | (risk["snapshot_year"] <= risk["emergence_year"])].copy()
    risk["emergence_this_year_i"] = (risk["snapshot_year"] == risk["emergence_year"]).fillna(False).astype(int)

    # Build lagged local controls.
    risk["lag_log_local_active_bands"] = (
        risk.groupby("city_country")["genre_active_bands"].shift(1).fillna(0.0).map(lambda value: math.log1p(float(value)))
    )
    risk["lag_local_active_bands"] = risk.groupby("city_country")["genre_active_bands"].shift(1).fillna(0.0)

    city_frame = first[["city_country", "latitude", "longitude", "emergence_year"]].drop_duplicates().reset_index(drop=True)
    risk_cities = city_frame[["city_country", "latitude", "longitude"]].copy()
    hub_cities = city_frame.loc[city_frame["emergence_year"].notna(), ["city_country", "latitude", "longitude", "emergence_year"]].copy()
    hub_cities["emergence_year"] = hub_cities["emergence_year"].astype(int)

    distance_km = haversine_matrix(
        risk_cities["latitude"].to_numpy(),
        risk_cities["longitude"].to_numpy(),
        hub_cities["latitude"].to_numpy(),
        hub_cities["longitude"].to_numpy(),
    )
    distance_weights = np.exp(-distance_km / DISTANCE_SCALE_KM)

    risk_city_to_idx = {city: idx for idx, city in enumerate(risk_cities["city_country"])}
    hub_city_to_idx = {city: idx for idx, city in enumerate(hub_cities["city_country"])}

    hub_year = (
        richer.loc[richer["city_country"].isin(hub_city_to_idx.keys()), ["city_country", "snapshot_year", "genre_active_bands"]]
        .copy()
        .rename(columns={"genre_active_bands": "hub_active_bands"})
    )
    hub_year["lag_hub_active_bands"] = hub_year.groupby("city_country")["hub_active_bands"].shift(1).fillna(0.0)
    hub_active_lookup = {
        year: np.zeros(len(hub_cities), dtype=float)
        for year in sorted(risk["snapshot_year"].unique())
    }
    for row in hub_year.itertuples(index=False):
        if row.snapshot_year in hub_active_lookup:
            hub_active_lookup[row.snapshot_year][hub_city_to_idx[row.city_country]] = float(row.lag_hub_active_bands)

    risk["lag_exposure_emerged_hubs"] = 0.0
    risk["lag_exposure_emerged_active_bands"] = 0.0
    risk["lag_nearest_emerged_hub_km"] = np.nan

    emerged_years = hub_cities["emergence_year"].to_numpy()
    for year in sorted(risk["snapshot_year"].unique()):
        emerged_mask = emerged_years < year
        if not emerged_mask.any():
            continue
        weight_slice = distance_weights[:, emerged_mask]
        exposure_hubs = weight_slice.sum(axis=1)
        active_vector = hub_active_lookup[year][emerged_mask]
        exposure_bands = weight_slice @ active_vector
        nearest = np.where(emerged_mask.any(), distance_km[:, emerged_mask].min(axis=1), np.nan)

        year_mask = risk["snapshot_year"] == year
        city_indices = risk.loc[year_mask, "city_country"].map(risk_city_to_idx).to_numpy()
        risk.loc[year_mask, "lag_exposure_emerged_hubs"] = exposure_hubs[city_indices]
        risk.loc[year_mask, "lag_exposure_emerged_active_bands"] = exposure_bands[city_indices]
        risk.loc[year_mask, "lag_nearest_emerged_hub_km"] = nearest[city_indices]

    risk["z_lag_exposure_emerged_hubs"] = zscore(risk["lag_exposure_emerged_hubs"])
    risk["z_lag_exposure_emerged_active_bands"] = zscore(risk["lag_exposure_emerged_active_bands"])
    risk["z_lag_log_local_active_bands"] = zscore(risk["lag_log_local_active_bands"])
    return risk, first, hub_cities


def fit_models(panel: pd.DataFrame) -> pd.DataFrame:
    sample = panel.loc[panel["snapshot_year"] > panel["first_band_year"]].copy()
    sample["year_str"] = sample["snapshot_year"].astype(str)
    formulas = {
        "local_only": "emergence_this_year_i ~ z_lag_log_local_active_bands + C(year_str)",
        "hubs_only": "emergence_this_year_i ~ z_lag_exposure_emerged_hubs + C(year_str)",
        "bands_only": "emergence_this_year_i ~ z_lag_exposure_emerged_active_bands + C(year_str)",
        "local_plus_hubs": "emergence_this_year_i ~ z_lag_log_local_active_bands + z_lag_exposure_emerged_hubs + C(year_str)",
        "local_plus_bands": "emergence_this_year_i ~ z_lag_log_local_active_bands + z_lag_exposure_emerged_active_bands + C(year_str)",
    }
    rows: list[dict[str, object]] = []
    for spec_id, formula in formulas.items():
        model = smf.ols(formula, data=sample).fit(
            cov_type="cluster",
            cov_kwds={"groups": sample["city_country"]},
        )
        for term in [
            "z_lag_log_local_active_bands",
            "z_lag_exposure_emerged_hubs",
            "z_lag_exposure_emerged_active_bands",
        ]:
            if term not in model.params.index:
                continue
            rows.append(
                {
                    "spec_id": spec_id,
                    "term": term,
                    "coefficient": float(model.params[term]),
                    "std_error": float(model.bse[term]),
                    "p_value": float(model.pvalues[term]),
                    "n_obs": int(model.nobs),
                    "event_count": int(sample["emergence_this_year_i"].sum()),
                    "mean_outcome": float(sample["emergence_this_year_i"].mean()),
                    "r_squared": float(model.rsquared),
                }
            )
    return pd.DataFrame(rows)


def build_bins(panel: pd.DataFrame) -> pd.DataFrame:
    sample = panel.loc[panel["snapshot_year"] > panel["first_band_year"]].copy()
    sample["exposure_bin"] = pd.qcut(
        sample["lag_exposure_emerged_active_bands"].rank(method="first"),
        5,
        labels=["Q1", "Q2", "Q3", "Q4", "Q5"],
    )
    out = (
        sample.groupby("exposure_bin", observed=False, as_index=False)
        .agg(
            n_obs=("city_country", "size"),
            event_rate=("emergence_this_year_i", "mean"),
            mean_local_active_bands=("lag_local_active_bands", "mean"),
            mean_hub_band_exposure=("lag_exposure_emerged_active_bands", "mean"),
        )
    )
    return out


def write_summary(
    genre_family: str,
    panel: pd.DataFrame,
    first: pd.DataFrame,
    results: pd.DataFrame,
    bins: pd.DataFrame,
    summary_path: Path,
    panel_path: Path,
    results_path: Path,
    bins_path: Path,
) -> None:
    sample = panel.loc[panel["snapshot_year"] > panel["first_band_year"]].copy()
    first_emerged = (
        first.loc[first["emergence_year"].notna(), ["city_country", "first_band_year", "emergence_year", "total_bands"]]
        .sort_values(["emergence_year", "first_band_year", "city_country"])
        .head(12)
    )
    lines = [
        f"# {genre_family.replace('_', ' ').title()} diffusion exposure summary",
        "",
        "## Output files",
        f"- exposure panel: `{panel_path.relative_to(PROJECT_ROOT).as_posix()}`",
        f"- model results: `{results_path.relative_to(PROJECT_ROOT).as_posix()}`",
        f"- exposure bins: `{bins_path.relative_to(PROJECT_ROOT).as_posix()}`",
        "",
        "## Design",
        "- sample: geography-clean city-genre-years with matched coordinates",
        "- at-risk period: from first local band year until local emergence year, or through the sample end if no emergence occurs",
        "- outcome: `emergence_this_year_i`",
        "- key external regressors:",
        f"  - `lag_exposure_emerged_hubs`: distance-weighted stock of already-emerged same-genre hubs using `exp(-distance/{int(DISTANCE_SCALE_KM)}km)`",
        "  - `lag_exposure_emerged_active_bands`: distance-weighted lagged same-genre active-band stock in already-emerged hubs",
        "- local control:",
        "  - lagged local same-genre active-band stock",
        "",
        "## Sample",
        f"- matched city cells in genre: `{first['city_country'].nunique():,}`",
        f"- at-risk city-year observations: `{len(sample):,}`",
        f"- emergence events in at-risk sample: `{int(sample['emergence_this_year_i'].sum()):,}`",
        f"- year range: `{int(sample['snapshot_year'].min())}` to `{int(sample['snapshot_year'].max())}`",
        "",
        "## Earliest emerged hubs in the matched sample",
        "",
        "| City | First band year | Emergence year | Total bands |",
        "| --- | ---: | ---: | ---: |",
    ]
    for row in first_emerged.itertuples(index=False):
        lines.append(f"| {row.city_country} | {int(row.first_band_year)} | {int(row.emergence_year)} | {int(row.total_bands)} |")

    lines.extend(
        [
            "",
            "## Exposure-bin emergence rates",
            "",
            "| Exposure bin | Observations | Emergence rate | Mean lagged local bands | Mean hub-band exposure |",
            "| --- | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in bins.itertuples(index=False):
        lines.append(
            f"| {row.exposure_bin} | {int(row.n_obs)} | {row.event_rate:.4f} | {row.mean_local_active_bands:.2f} | {row.mean_hub_band_exposure:.3f} |"
        )

    lines.extend(["", "## Model results", ""])
    if results.empty:
        lines.append("No model results were produced.")
    else:
        lines.extend(
            [
                "| Spec | Term | Coefficient | Std. error | P-value | N |",
                "| --- | --- | ---: | ---: | ---: | ---: |",
            ]
        )
        for row in results.itertuples(index=False):
            lines.append(
                f"| {row.spec_id} | {row.term} | {row.coefficient:.4f} | {row.std_error:.4f} | {row.p_value:.4f} | {int(row.n_obs)} |"
            )

    lines.extend(
        [
            "",
            "## Read",
            "This is the first serious diffusion object in the project. It goes beyond maps by asking",
            "whether later local scene emergence tracks prior external exposure to already-emerged hubs.",
            "The branch is still exploratory and genre-specific, so the coefficients should be read as a",
            "first reduced-form diagnostic rather than a final design. If the external exposure terms stay",
            "informative after local scene thickness is controlled for, this branch is worth broadening",
            "beyond `black_metal`.",
        ]
    )
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build a first scene-diffusion exposure panel for one genre family.")
    parser.add_argument("--genre", default="black_metal", help="Genre family to analyze.")
    args = parser.parse_args()

    DIFFUSION_DIR.mkdir(parents=True, exist_ok=True)
    panel_path = DIFFUSION_DIR / f"{args.genre}_diffusion_exposure_panel.csv"
    results_path = DIFFUSION_DIR / f"{args.genre}_diffusion_exposure_results.csv"
    bins_path = DIFFUSION_DIR / f"{args.genre}_diffusion_exposure_bins.csv"
    summary_path = DIFFUSION_DIR / f"{args.genre}_diffusion_exposure_summary.md"

    panel, first, _ = build_exposure_panel(args.genre)
    results = fit_models(panel)
    bins = build_bins(panel)

    panel.to_csv(panel_path, index=False)
    results.to_csv(results_path, index=False)
    bins.to_csv(bins_path, index=False)
    write_summary(args.genre, panel, first, results, bins, summary_path, panel_path, results_path, bins_path)

    print(f"Wrote exposure panel: {panel_path}")
    print(f"Wrote model results: {results_path}")
    print(f"Wrote exposure bins: {bins_path}")
    print(f"Wrote summary: {summary_path}")


if __name__ == "__main__":
    main()
