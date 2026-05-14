#!/usr/bin/env python3
"""Build the first England local-authority greenbelt and fertility panel."""

from __future__ import annotations

import io
import json
import math
from pathlib import Path

import pandas as pd
import requests
import statsmodels.formula.api as smf


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw" / "england"
PROCESSED_DIR = ROOT / "data" / "processed"
BUILD_DIR = ROOT / "notes" / "build"

GREENBELT_URL = (
    "https://assets.publishing.service.gov.uk/media/68e619b3ef1c2f72bc1e4ebd/"
    "Live_Tables_-_Green_Belt_Statistics_2024-25.ods"
)
NOMIS_BIRTH_RATES_URL = "https://www.nomisweb.co.uk/api/v01/dataset/NM_207_1.data.csv"
NOMIS_BIRTH_AGE_URL = "https://www.nomisweb.co.uk/api/v01/dataset/NM_205_1.data.csv"
UKHPI_AVERAGE_PRICE_URL = (
    "https://publicdata.landregistry.gov.uk/market-trend-data/house-price-index-data/"
    "Average-prices-2025-12.csv?utm_medium=GOV.UK&utm_source=datadownload&"
    "utm_campaign=average_price&utm_term=9.30_18_02_26"
)
UKHPI_INDEX_URL = (
    "https://publicdata.landregistry.gov.uk/market-trend-data/house-price-index-data/"
    "Indices-2025-12.csv?utm_medium=GOV.UK&utm_source=datadownload&"
    "utm_campaign=index&utm_term=9.30_18_02_26"
)

GREENBELT_CURRENT_FILE = RAW_DIR / "greenbelt_statistics_2024_25.ods"
NOMIS_BIRTH_RATES_FILE = RAW_DIR / "nomis_birth_rates_local_authority.csv"
NOMIS_BIRTH_AGE_FILE = RAW_DIR / "nomis_births_by_age_local_authority.csv"
UKHPI_AVERAGE_PRICE_FILE = RAW_DIR / "uk_hpi_average_prices.csv"
UKHPI_INDEX_FILE = RAW_DIR / "uk_hpi_indices.csv"
METADATA_FILE = RAW_DIR / "england_greenbelt_panel_metadata.json"

PANEL_FILE = PROCESSED_DIR / "england_greenbelt_fertility_panel_v1.csv"
NOTE_FILE = BUILD_DIR / "england_greenbelt_fertility_panel_v1.md"
SUMMARY_FILE = BUILD_DIR / "england_greenbelt_fertility_panel_v1_summary.csv"


CURRENT_CODE_PREFIXES = ("E06", "E07", "E08", "E09")
MANUAL_PREDECESSOR_MAP = {
    "E06000058": ["E06000028", "E07000048", "E06000029"],  # Bournemouth, Christchurch and Poole
    "E06000060": ["E07000004", "E07000005", "E07000006", "E07000007"],  # Buckinghamshire
    "E06000059": ["E07000049", "E07000051"],  # Dorset (positive-greenbelt predecessors only)
    "E06000065": ["E07000164", "E07000165", "E07000167", "E07000169"],  # North Yorkshire
    "E06000066": ["E07000187"],  # Somerset (positive-greenbelt predecessor)
}


def fetch_binary(url: str) -> bytes:
    response = requests.get(url, timeout=180)
    response.raise_for_status()
    return response.content


def fetch_csv_text(url: str) -> pd.DataFrame:
    response = requests.get(url, timeout=180)
    response.raise_for_status()
    return pd.read_csv(io.StringIO(response.text))


def is_current_england_la(code: object) -> bool:
    text = str(code)
    return len(text) == 9 and text.startswith(CURRENT_CODE_PREFIXES)


def first_non_null(series: pd.Series):
    series = series.dropna()
    if series.empty:
        return pd.NA
    return series.iloc[0]


def geography_priority(series: pd.Series) -> pd.Series:
    text = series.fillna("").astype(str)
    return (
        text.str.contains("April 2023", case=False, regex=False).astype(int) * 2
        + text.str.contains("April 2021", case=False, regex=False).astype(int)
    )


def label_to_year(label: object) -> int | None:
    text = str(label)
    if "_" in text:
        try:
            return 2000 + int(text.split("_")[-1])
        except ValueError:
            return None
    try:
        return int(float(text))
    except ValueError:
        return None


def pull_nomis_dataset(base_url: str) -> pd.DataFrame:
    chunk_size = 25000
    offset = 0
    frames: list[pd.DataFrame] = []

    while True:
        url = f"{base_url}?recordoffset={offset}"
        chunk = pd.read_csv(url)
        if chunk.empty:
            break
        frames.append(chunk)
        record_count = int(chunk["RECORD_COUNT"].iloc[0])
        offset += len(chunk)
        if offset >= record_count:
            break

    return pd.concat(frames, ignore_index=True)


def clean_greenbelt_area_sheet(sheet: str) -> pd.DataFrame:
    df = pd.read_excel(GREENBELT_CURRENT_FILE, sheet_name=sheet, engine="odf", header=2)
    df = df[df["Authority name"].notna()].copy()
    df = df[df["Authority code"].apply(is_current_england_la)].copy()
    return df.reset_index(drop=True)


def load_greenbelt_panel() -> tuple[pd.DataFrame, pd.DataFrame]:
    area = clean_greenbelt_area_sheet("Area_by_LA")
    area = area.rename(
        columns={
            "Authority name": "area_name",
            "Authority code": "area_code",
            "Area of land designated as Green Belt": "greenbelt_area_ha_current",
            "Total area as at 31 December 2023 [note 5]": "total_area_ha_current",
            "Percentage of total land area designated as Green Belt": "greenbelt_share_pct_current",
        }
    )
    area["greenbelt_area_ha_current"] = pd.to_numeric(
        area["greenbelt_area_ha_current"].replace("-", 0),
        errors="coerce",
    ).fillna(0.0)
    area["total_area_ha_current"] = pd.to_numeric(area["total_area_ha_current"], errors="coerce")
    area["greenbelt_share_pct_current"] = pd.to_numeric(
        area["greenbelt_share_pct_current"].replace("-", 0),
        errors="coerce",
    ).fillna(0.0)
    area = (
        area.groupby(["area_code", "area_name"], as_index=False)
        .agg(
            greenbelt_area_ha_current=("greenbelt_area_ha_current", "sum"),
            total_area_ha_current=("total_area_ha_current", "first"),
        )
    )
    area["greenbelt_share_frac_current"] = area["greenbelt_area_ha_current"] / area["total_area_ha_current"]
    area["greenbelt_share_pct_current"] = area["greenbelt_share_frac_current"] * 100.0

    series = pd.read_excel(
        GREENBELT_CURRENT_FILE,
        sheet_name="Time_series_by_LA",
        engine="odf",
        header=2,
    )
    series = series[series["Authority name"].notna()].copy()
    series = series[series["Authority code"].apply(is_current_england_la)].copy()
    series = series.rename(
        columns={
            "Authority name": "area_name",
            "Authority code": "area_code",
            "Green Belt name": "greenbelt_name",
        }
    )

    id_cols = ["area_name", "area_code", "greenbelt_name"]
    year_cols = [col for col in series.columns if col not in id_cols]
    long = series.melt(
        id_vars=id_cols,
        value_vars=year_cols,
        var_name="greenbelt_stock_label",
        value_name="greenbelt_area_ha",
    )
    long["year"] = long["greenbelt_stock_label"].map(label_to_year)
    long["greenbelt_area_ha"] = pd.to_numeric(long["greenbelt_area_ha"], errors="coerce")
    long = long[long["year"].between(2014, 2025)].copy()
    long = (
        long.groupby(["area_code", "area_name", "year"], as_index=False)
        .agg(greenbelt_area_ha=("greenbelt_area_ha", "sum"))
    )

    years = pd.DataFrame({"year": sorted(long["year"].dropna().unique())})
    full_grid = area[["area_code", "area_name"]].merge(years, how="cross")
    greenbelt = full_grid.merge(
        long[["area_code", "year", "greenbelt_area_ha"]],
        on=["area_code", "year"],
        how="left",
    ).merge(
        area[
            [
                "area_code",
                "total_area_ha_current",
                "greenbelt_area_ha_current",
                "greenbelt_share_pct_current",
                "greenbelt_share_frac_current",
            ]
        ],
        on="area_code",
        how="left",
    )

    # First backfill current-code missing history from same-name legacy-code rows.
    source_by_code = long[["area_code", "year", "greenbelt_area_ha"]].copy()
    for _, current in area[["area_code", "area_name"]].drop_duplicates().iterrows():
        same_name_sources = long[
            (long["area_name"] == current["area_name"]) & (long["area_code"] != current["area_code"])
        ][["year", "greenbelt_area_ha"]]
        if same_name_sources.empty:
            continue
        source = (
            same_name_sources.groupby("year", as_index=False)
            .agg(greenbelt_area_ha_fill=("greenbelt_area_ha", "sum"))
        )
        mask = greenbelt["area_code"].eq(current["area_code"]) & greenbelt["greenbelt_area_ha"].isna()
        greenbelt = greenbelt.merge(
            source,
            on="year",
            how="left",
        )
        greenbelt.loc[mask, "greenbelt_area_ha"] = greenbelt.loc[mask, "greenbelt_area_ha_fill"]
        greenbelt = greenbelt.drop(columns=["greenbelt_area_ha_fill"])

    # Then backfill new unitaries from predecessor sums where name matching is not enough.
    for current_code, predecessor_codes in MANUAL_PREDECESSOR_MAP.items():
        source = (
            source_by_code[source_by_code["area_code"].isin(predecessor_codes)]
            .groupby("year", as_index=False)
            .agg(greenbelt_area_ha_fill=("greenbelt_area_ha", "sum"))
        )
        if source.empty:
            continue
        mask = greenbelt["area_code"].eq(current_code) & greenbelt["greenbelt_area_ha"].isna()
        greenbelt = greenbelt.merge(source, on="year", how="left")
        greenbelt.loc[mask, "greenbelt_area_ha"] = greenbelt.loc[mask, "greenbelt_area_ha_fill"]
        greenbelt = greenbelt.drop(columns=["greenbelt_area_ha_fill"])

    zero_codes = set(
        area.loc[area["greenbelt_area_ha_current"].fillna(0).eq(0), "area_code"].astype(str)
    )
    zero_mask = greenbelt["area_code"].astype(str).isin(zero_codes)
    greenbelt.loc[zero_mask & greenbelt["greenbelt_area_ha"].isna(), "greenbelt_area_ha"] = 0.0

    greenbelt["greenbelt_share_frac"] = greenbelt["greenbelt_area_ha"] / greenbelt["total_area_ha_current"]
    greenbelt["greenbelt_share_pct"] = greenbelt["greenbelt_share_frac"] * 100.0
    return greenbelt, area


def load_nomis_birth_rates() -> pd.DataFrame:
    raw = pd.read_csv(NOMIS_BIRTH_RATES_FILE)
    df = raw[raw["GEOGRAPHY_CODE"].apply(is_current_england_la)].copy()
    df["year"] = pd.to_numeric(df["DATE_NAME"], errors="coerce")
    df = df[df["year"].between(2013, 2024)]
    df = df[df["MEASURES_NAME"] == "Value"].copy()
    df["geometry_priority"] = geography_priority(df["GEOGRAPHY_TYPE"])
    df = df.sort_values(
        ["year", "GEOGRAPHY_CODE", "MEASURE_NAME", "geometry_priority"],
        ascending=[True, True, True, False],
    )
    df = df.drop_duplicates(subset=["year", "GEOGRAPHY_CODE", "MEASURE_NAME"])

    keep_measures = {
        "Live births": "live_births_total",
        "Crude birth rate": "crude_birth_rate",
        "General fertility rate (GFR)": "general_fertility_rate",
        "Total fertility rate (TFR)": "total_fertility_rate",
        "Standardised mean age of mother": "mean_age_mother_standardised",
        "Age specific fertility rate : Aged under 20": "asfr_under_20",
        "Age specific fertility rate : Aged 20-24": "asfr_20_24",
        "Age specific fertility rate : Aged 25-29": "asfr_25_29",
        "Age specific fertility rate : Aged 30-34": "asfr_30_34",
        "Age specific fertility rate : Aged 35-39": "asfr_35_39",
        "Age specific fertility rate : Aged 40-44": "asfr_40_44",
        "Age specific fertility rate : Aged 45 and over": "asfr_45_plus",
    }
    df = df[df["MEASURE_NAME"].isin(keep_measures)].copy()
    df["variable"] = df["MEASURE_NAME"].map(keep_measures)
    df["OBS_VALUE"] = pd.to_numeric(df["OBS_VALUE"], errors="coerce")

    wide = (
        df.pivot_table(
            index=["year", "GEOGRAPHY_CODE", "GEOGRAPHY_NAME"],
            columns="variable",
            values="OBS_VALUE",
            aggfunc="first",
        )
        .reset_index()
        .rename(columns={"GEOGRAPHY_CODE": "area_code", "GEOGRAPHY_NAME": "area_name"})
    )
    return wide


def load_nomis_birth_age() -> pd.DataFrame:
    raw = pd.read_csv(NOMIS_BIRTH_AGE_FILE)
    df = raw[raw["GEOGRAPHY_CODE"].apply(is_current_england_la)].copy()
    df["year"] = pd.to_numeric(df["DATE_NAME"], errors="coerce")
    df = df[df["year"].between(2013, 2024)]
    df = df[df["MEASURES_NAME"] == "Value"].copy()
    df["geometry_priority"] = geography_priority(df["GEOGRAPHY_TYPE"])
    df = df.sort_values(
        ["year", "GEOGRAPHY_CODE", "AGE_OF_MOTHER_NAME", "geometry_priority"],
        ascending=[True, True, True, False],
    )
    df = df.drop_duplicates(subset=["year", "GEOGRAPHY_CODE", "AGE_OF_MOTHER_NAME"])

    age_map = {
        "Total": "births_total",
        "Mother aged under 20": "births_under_20",
        "Mother aged under 18": "births_under_18",
        "Mother aged 20-24": "births_20_24",
        "Mother aged 25-29": "births_25_29",
        "Mother aged 30-34": "births_30_34",
        "Mother aged 35-39": "births_35_39",
        "Mother aged 40-44": "births_40_44",
        "Mother aged 45 and over": "births_45_plus",
        "Age of mother unknown or not stated": "births_age_unknown",
    }
    df = df[df["AGE_OF_MOTHER_NAME"].isin(age_map)].copy()
    df["variable"] = df["AGE_OF_MOTHER_NAME"].map(age_map)
    df["OBS_VALUE"] = pd.to_numeric(df["OBS_VALUE"], errors="coerce")

    wide = (
        df.pivot_table(
            index=["year", "GEOGRAPHY_CODE", "GEOGRAPHY_NAME"],
            columns="variable",
            values="OBS_VALUE",
            aggfunc="first",
        )
        .reset_index()
        .rename(columns={"GEOGRAPHY_CODE": "area_code", "GEOGRAPHY_NAME": "area_name"})
    )

    num_cols = [col for col in wide.columns if col.startswith("births_")]
    for col in num_cols:
        wide[col] = pd.to_numeric(wide[col], errors="coerce")

    wide["share_births_30_plus"] = (
        wide[["births_30_34", "births_35_39", "births_40_44", "births_45_plus"]]
        .sum(axis=1, min_count=1)
        / wide["births_total"]
    )
    wide["share_births_35_plus"] = (
        wide[["births_35_39", "births_40_44", "births_45_plus"]].sum(axis=1, min_count=1)
        / wide["births_total"]
    )
    wide["share_births_under_25"] = (
        wide[["births_under_20", "births_20_24"]].sum(axis=1, min_count=1) / wide["births_total"]
    )
    return wide


def load_ukhpi_panel() -> pd.DataFrame:
    avg = pd.read_csv(UKHPI_AVERAGE_PRICE_FILE)
    idx = pd.read_csv(UKHPI_INDEX_FILE)

    for df in (avg, idx):
        df["year"] = pd.to_datetime(df["Date"], errors="coerce").dt.year
        df["Area_Code"] = df["Area_Code"].astype(str)

    avg = avg[avg["Area_Code"].apply(is_current_england_la)].copy()
    idx = idx[idx["Area_Code"].apply(is_current_england_la)].copy()
    avg = avg[avg["year"].between(2013, 2025)]
    idx = idx[idx["year"].between(2013, 2025)]

    avg_annual = (
        avg.groupby(["year", "Area_Code", "Region_Name"], as_index=False)
        .agg(
            ukhpi_average_price=("Average_Price", "mean"),
            ukhpi_annual_change_avg=("Annual_Change", "mean"),
        )
        .rename(columns={"Area_Code": "area_code", "Region_Name": "area_name"})
    )
    idx_annual = (
        idx.groupby(["year", "Area_Code"], as_index=False)
        .agg(ukhpi_index=("Index", "mean"))
        .rename(columns={"Area_Code": "area_code"})
    )
    return avg_annual.merge(idx_annual, on=["year", "area_code"], how="left")


def build_panel() -> tuple[pd.DataFrame, dict[str, float | int]]:
    greenbelt, greenbelt_area = load_greenbelt_panel()
    birth_rates = load_nomis_birth_rates()
    birth_age = load_nomis_birth_age()
    ukhpi = load_ukhpi_panel()

    panel = birth_rates.merge(birth_age, on=["year", "area_code", "area_name"], how="outer")
    panel = panel.merge(ukhpi, on=["year", "area_code"], how="left", suffixes=("", "_ukhpi"))
    panel["area_name"] = panel["area_name"].fillna(panel["area_name_ukhpi"])
    panel = panel.drop(columns=["area_name_ukhpi"], errors="ignore")
    panel = panel.merge(greenbelt, on=["year", "area_code"], how="left", suffixes=("", "_greenbelt"))
    panel["area_name"] = panel["area_name"].fillna(panel["area_name_greenbelt"])
    panel = panel.drop(columns=["area_name_greenbelt"], errors="ignore")
    panel = (
        panel.sort_values(["year", "area_code"])
        .groupby(["year", "area_code"], as_index=False)
        .agg({col: first_non_null for col in panel.columns if col not in {"year", "area_code"}})
    )
    non_numeric_ids = {"area_code", "area_name"}
    for col in panel.columns:
        if col not in non_numeric_ids:
            panel[col] = pd.to_numeric(panel[col], errors="coerce")

    panel = panel.sort_values(["area_code", "year"]).reset_index(drop=True)
    panel["ln_ukhpi_average_price"] = panel["ukhpi_average_price"].where(
        panel["ukhpi_average_price"] > 0
    ).map(math.log)

    complete = panel[
        panel[
            [
                "live_births_total",
                "general_fertility_rate",
                "total_fertility_rate",
                "mean_age_mother_standardised",
                "share_births_30_plus",
                "ukhpi_average_price",
                "greenbelt_share_pct",
            ]
        ].notna().all(axis=1)
    ].copy()

    price_model = smf.ols(
        "ln_ukhpi_average_price ~ greenbelt_share_pct + C(year)",
        data=complete,
    ).fit(cov_type="cluster", cov_kwds={"groups": complete["area_code"]})
    timing_model = smf.ols(
        "share_births_30_plus ~ greenbelt_share_pct + C(year)",
        data=complete,
    ).fit(cov_type="cluster", cov_kwds={"groups": complete["area_code"]})
    overlap_years = panel["year"].between(2014, 2024)
    overlap_missing = panel.loc[overlap_years & panel["greenbelt_share_pct"].isna()].copy()

    summary = {
        "panel_rows": int(len(panel)),
        "panel_areas": int(panel["area_code"].nunique()),
        "panel_year_min": int(panel["year"].min()),
        "panel_year_max": int(panel["year"].max()),
        "complete_rows": int(len(complete)),
        "complete_areas": int(complete["area_code"].nunique()),
        "complete_year_min": int(complete["year"].min()),
        "complete_year_max": int(complete["year"].max()),
        "greenbelt_rows": int(len(greenbelt)),
        "greenbelt_positive_current_areas": int(
            greenbelt_area["greenbelt_area_ha_current"].gt(0).sum()
        ),
        "greenbelt_missing_rows_overlap": int(len(overlap_missing)),
        "greenbelt_missing_areas_overlap": int(overlap_missing["area_code"].nunique()),
        "birth_rates_rows": int(len(birth_rates)),
        "birth_age_rows": int(len(birth_age)),
        "ukhpi_rows": int(len(ukhpi)),
        "price_coef": float(price_model.params["greenbelt_share_pct"]),
        "price_p_value": float(price_model.pvalues["greenbelt_share_pct"]),
        "timing_coef": float(timing_model.params["greenbelt_share_pct"]),
        "timing_p_value": float(timing_model.pvalues["greenbelt_share_pct"]),
    }
    return panel, summary


def write_note(summary: dict[str, float | int]) -> None:
    lines = [
        "# England greenbelt and fertility panel v1",
        "",
        "This is the first England local-authority panel that matches the planning/greenbelt design",
        "outlined in `notes/build/uk_greenbelt_planning_shock_workflow.md`.",
        "",
        "## Official sources used",
        "",
        f"- Greenbelt live tables: `{GREENBELT_URL}`",
        f"- NOMIS local birth rates: `{NOMIS_BIRTH_RATES_URL}`",
        f"- NOMIS local births by age of mother: `{NOMIS_BIRTH_AGE_URL}`",
        f"- UK HPI average prices: `{UKHPI_AVERAGE_PRICE_URL}`",
        f"- UK HPI indices: `{UKHPI_INDEX_URL}`",
        "",
        "## Panel contents",
        "",
        "- local-authority live births, crude birth rate, GFR, TFR, and standardised mean age of mother",
        "- local-authority births by age of mother and derived timing shares such as `share_births_30_plus`",
        "- local-authority annualized UK HPI average price and index",
        "- local-authority greenbelt area and greenbelt share",
        "",
        "## Coverage",
        "",
        f"- merged panel rows: `{summary['panel_rows']}`",
        f"- merged panel local authorities: `{summary['panel_areas']}`",
        f"- merged panel year range: `{summary['panel_year_min']}`-`{summary['panel_year_max']}`",
        f"- complete rows with births, prices, and greenbelt: `{summary['complete_rows']}`",
        f"- complete-sample local authorities: `{summary['complete_areas']}`",
        f"- complete-sample year range: `{summary['complete_year_min']}`-`{summary['complete_year_max']}`",
        f"- greenbelt rows before merge: `{summary['greenbelt_rows']}`",
        f"- current local authorities with positive greenbelt exposure: `{summary['greenbelt_positive_current_areas']}`",
        f"- rows still missing greenbelt history in the `2014`-`2024` overlap: `{summary['greenbelt_missing_rows_overlap']}` across `{summary['greenbelt_missing_areas_overlap']}` authorities",
        "",
        "## First descriptive read",
        "",
        f"- The price-validation check is positive but imprecise: in a year-fixed-effects panel, the coefficient on `greenbelt_share_pct` in `ln(price)` is `{summary['price_coef']:.4f}` (`p = {summary['price_p_value']:.3f}`).",
        f"- The timing margin is cleaner in this first pass: the coefficient on `greenbelt_share_pct` in `share_births_30_plus` is `{summary['timing_coef']:.4f}` (`p = {summary['timing_p_value']:.3f}`).",
        "- These are descriptive validation checks, not a final causal design.",
        "",
        "## Important limitation",
        "",
        "- Greenbelt history comes from the current live-tables workbook with current-code rows plus legacy rows.",
        "  Zero-greenbelt authorities are filled as zero through time, but some reorganized authorities with",
        "  positive greenbelt exposure can still have missing pre-reorganization history in the current-code merge.",
        "- The NOMIS fertility side is timing-of-childbearing, not first births by parity.",
        "",
        "## Output",
        "",
        f"- processed panel: `{PANEL_FILE.relative_to(ROOT)}`",
        f"- summary table: `{SUMMARY_FILE.relative_to(ROOT)}`",
        "",
    ]
    NOTE_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    GREENBELT_CURRENT_FILE.write_bytes(fetch_binary(GREENBELT_URL))
    pull_nomis_dataset(NOMIS_BIRTH_RATES_URL).to_csv(NOMIS_BIRTH_RATES_FILE, index=False)
    pull_nomis_dataset(NOMIS_BIRTH_AGE_URL).to_csv(NOMIS_BIRTH_AGE_FILE, index=False)
    fetch_csv_text(UKHPI_AVERAGE_PRICE_URL).to_csv(UKHPI_AVERAGE_PRICE_FILE, index=False)
    fetch_csv_text(UKHPI_INDEX_URL).to_csv(UKHPI_INDEX_FILE, index=False)

    (METADATA_FILE).write_text(
        json.dumps(
            {
                "greenbelt_url": GREENBELT_URL,
                "nomis_birth_rates_url": NOMIS_BIRTH_RATES_URL,
                "nomis_birth_age_url": NOMIS_BIRTH_AGE_URL,
                "ukhpi_average_price_url": UKHPI_AVERAGE_PRICE_URL,
                "ukhpi_index_url": UKHPI_INDEX_URL,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    panel, summary = build_panel()
    panel.to_csv(PANEL_FILE, index=False)
    pd.DataFrame([summary]).to_csv(SUMMARY_FILE, index=False)
    write_note(summary)
    print(PANEL_FILE)


if __name__ == "__main__":
    main()
