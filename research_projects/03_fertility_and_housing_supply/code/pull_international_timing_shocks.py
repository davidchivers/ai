#!/usr/bin/env python3
"""Pull official OECD/BIS housing and rate series for the international timing panel."""

from __future__ import annotations

import io
import json
import zipfile
from pathlib import Path

import pandas as pd
import requests


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw" / "international"
PROCESSED_DIR = ROOT / "data" / "processed"
BUILD_DIR = ROOT / "notes" / "build"

EUROSTAT_PANEL = PROCESSED_DIR / "international_first_birth_timing_eu.csv"

OECD_RHPI_URL = (
    "https://sdmx.oecd.org/public/rest/data/"
    "OECD.SDD.TPS,DSD_RHPI@DF_RHPI_ALL,1.0/all?startPeriod=1960&format=csvfile"
)
OECD_FINMARK_URL = (
    "https://sdmx.oecd.org/public/rest/data/"
    "OECD.SDD.STES,DSD_STES@DF_FINMARK,4.0/all?startPeriod=1960&format=csvfile"
)
BIS_SPP_URL = "https://data.bis.org/static/bulk/WS_SPP_csv_flat.zip"


ISO3_TO_ISO2 = {
    "AUT": "AT",
    "BEL": "BE",
    "BGR": "BG",
    "CHE": "CH",
    "CYP": "CY",
    "CZE": "CZ",
    "DEU": "DE",
    "DNK": "DK",
    "ESP": "ES",
    "EST": "EE",
    "FIN": "FI",
    "FRA": "FR",
    "GBR": "UK",
    "GRC": "EL",
    "HRV": "HR",
    "HUN": "HU",
    "IRL": "IE",
    "ISL": "IS",
    "ITA": "IT",
    "LTU": "LT",
    "LUX": "LU",
    "LVA": "LV",
    "MLT": "MT",
    "NLD": "NL",
    "NOR": "NO",
    "POL": "PL",
    "PRT": "PT",
    "ROU": "RO",
    "SVK": "SK",
    "SVN": "SI",
    "SWE": "SE",
    "TUR": "TR",
}


def fetch_text_csv(url: str) -> pd.DataFrame:
    response = requests.get(url, timeout=180)
    response.raise_for_status()
    return pd.read_csv(io.StringIO(response.text))


def load_eurostat_panel() -> pd.DataFrame:
    df = pd.read_csv(EUROSTAT_PANEL)
    df["country_code"] = df["country_code"].astype(str)
    df["year"] = df["year"].astype(int)
    return df


def pull_oecd_house_prices(valid_codes: set[str]) -> tuple[pd.DataFrame, pd.DataFrame]:
    raw = fetch_text_csv(OECD_RHPI_URL)

    growth = raw[
        (raw["REF_AREA_TYPE"] == "COU")
        & (raw["MEASURE"] == "RHPI")
        & (raw["FREQ"] == "A")
        & (raw["UNIT_MEASURE"] == "PA")
        & (raw["ADJUSTMENT"] == "N")
        & (raw["TRANSFORMATION"] == "GY")
        & (raw["VINTAGE"] == "_T")
        & (raw["DWELLINGS"] == "_T")
    ].copy()
    growth["country_code"] = growth["REF_AREA"].map(ISO3_TO_ISO2)
    growth["year"] = pd.to_numeric(growth["TIME_PERIOD"], errors="coerce")
    growth["oecd_house_price_growth_pct"] = pd.to_numeric(growth["OBS_VALUE"], errors="coerce")
    growth = growth[growth["country_code"].isin(valid_codes)]
    growth = growth[["country_code", "year", "oecd_house_price_growth_pct"]]

    level = raw[
        (raw["REF_AREA_TYPE"] == "COU")
        & (raw["MEASURE"] == "RHPI")
        & (raw["FREQ"] == "A")
        & (raw["UNIT_MEASURE"] == "IX")
        & (raw["ADJUSTMENT"] == "N")
        & (raw["TRANSFORMATION"] == "_Z")
        & (raw["VINTAGE"] == "_T")
        & (raw["DWELLINGS"] == "_T")
    ].copy()
    level["country_code"] = level["REF_AREA"].map(ISO3_TO_ISO2)
    level["year"] = pd.to_numeric(level["TIME_PERIOD"], errors="coerce")
    level["oecd_house_price_index"] = pd.to_numeric(level["OBS_VALUE"], errors="coerce")
    level = level[level["country_code"].isin(valid_codes)]
    level = level[["country_code", "year", "oecd_house_price_index"]]

    panel = growth.merge(level, on=["country_code", "year"], how="outer")
    panel = panel.sort_values(["country_code", "year"]).reset_index(drop=True)
    return raw, panel


def pull_oecd_rates(valid_codes: set[str]) -> tuple[pd.DataFrame, pd.DataFrame]:
    raw = fetch_text_csv(OECD_FINMARK_URL)
    rates = raw[
        (raw["FREQ"] == "A")
        & (raw["MEASURE"].isin(["IR3TIB", "IRLT"]))
        & (raw["UNIT_MEASURE"] == "PA")
        & (raw["ACTIVITY"] == "_Z")
        & (raw["ADJUSTMENT"] == "_Z")
        & (raw["TRANSFORMATION"] == "_Z")
        & (raw["TIME_HORIZ"] == "_Z")
        & (raw["METHODOLOGY"] == "N")
    ].copy()
    rates["country_code"] = rates["REF_AREA"].map(ISO3_TO_ISO2)
    rates["year"] = pd.to_numeric(rates["TIME_PERIOD"], errors="coerce")
    rates["value"] = pd.to_numeric(rates["OBS_VALUE"], errors="coerce")
    rates = rates[rates["country_code"].isin(valid_codes)]
    rates["series"] = rates["MEASURE"].map(
        {
            "IR3TIB": "oecd_short_rate_pct",
            "IRLT": "oecd_long_rate_pct",
        }
    )
    panel = (
        rates.pivot_table(
            index=["country_code", "year"],
            columns="series",
            values="value",
            aggfunc="first",
        )
        .reset_index()
        .sort_values(["country_code", "year"])
        .reset_index(drop=True)
    )
    return raw, panel


def pull_bis_house_prices(valid_codes: set[str]) -> tuple[pd.DataFrame, pd.DataFrame]:
    response = requests.get(BIS_SPP_URL, timeout=180)
    response.raise_for_status()
    archive = zipfile.ZipFile(io.BytesIO(response.content))
    csv_name = archive.namelist()[0]
    raw = pd.read_csv(archive.open(csv_name))

    bis = raw.copy()
    bis["country_code"] = bis["REF_AREA:Reference area"].str.split(":").str[0]
    bis["freq_code"] = bis["FREQ:Frequency"].str.split(":").str[0]
    bis["value_code"] = bis["VALUE:Value"].str.split(":").str[0]
    bis["unit_code"] = bis["UNIT_MEASURE:Unit of measure"].str.split(":").str[0]
    bis["year"] = pd.to_numeric(
        bis["TIME_PERIOD:Time period or range"].astype(str).str[:4],
        errors="coerce",
    )
    bis["obs_value"] = pd.to_numeric(bis["OBS_VALUE:Observation Value"], errors="coerce")
    bis = bis[
        (bis["freq_code"] == "Q")
        & (bis["value_code"].isin(["N", "R"]))
        & (bis["unit_code"] == "771")
        & (bis["country_code"].isin(valid_codes))
    ].copy()
    bis["series"] = bis["value_code"].map(
        {
            "N": "bis_nominal_house_price_growth_pct",
            "R": "bis_real_house_price_growth_pct",
        }
    )
    panel = (
        bis.pivot_table(
            index=["country_code", "year"],
            columns="series",
            values="obs_value",
            aggfunc="mean",
        )
        .reset_index()
        .sort_values(["country_code", "year"])
        .reset_index(drop=True)
    )
    return raw, panel


def write_note(
    merged: pd.DataFrame,
    eurostat: pd.DataFrame,
    oecd_house: pd.DataFrame,
    oecd_rates: pd.DataFrame,
    bis_panel: pd.DataFrame,
) -> None:
    overlap = merged[
        merged[
            [
                "oecd_house_price_growth_pct",
                "oecd_short_rate_pct",
                "oecd_long_rate_pct",
                "bis_real_house_price_growth_pct",
                "bis_nominal_house_price_growth_pct",
            ]
        ].notna().any(axis=1)
    ].copy()
    lines = [
        "# International timing shock panel",
        "",
        "Official sources used:",
        f"- OECD RHPI API: `{OECD_RHPI_URL}`",
        f"- OECD financial market API: `{OECD_FINMARK_URL}`",
        f"- BIS bulk download: `{BIS_SPP_URL}`",
        "",
        "## Shock variables added",
        "",
        "- `oecd_house_price_growth_pct`: annual OECD house-price growth (`RHPI`, `PA`, `GY`)",
        "- `oecd_house_price_index`: annual OECD house-price index (`RHPI`, `IX`)",
        "- `oecd_short_rate_pct`: annual OECD short-term interest rate (`IR3TIB`)",
        "- `oecd_long_rate_pct`: annual OECD long-term interest rate (`IRLT`)",
        "- `bis_nominal_house_price_growth_pct`: annualized mean of BIS quarterly nominal y/y house-price growth",
        "- `bis_real_house_price_growth_pct`: annualized mean of BIS quarterly real y/y house-price growth",
        "",
        "## Coverage",
        "",
        f"- Eurostat timing panel rows: `{len(eurostat)}`",
        f"- Eurostat timing panel countries: `{eurostat['country_code'].nunique()}`",
        f"- OECD house-price rows after filter: `{len(oecd_house)}`",
        f"- OECD rates rows after filter: `{len(oecd_rates)}`",
        f"- BIS annualized rows after filter: `{len(bis_panel)}`",
        f"- merged timing-plus-shocks rows with at least one shock: `{len(overlap)}`",
        f"- merged countries with at least one shock: `{overlap['country_code'].nunique()}`",
        "",
        "## Interpretation",
        "",
        "- This is the first international shock layer for the timing panel.",
        "- OECD provides clean annual house-price and interest-rate series on official APIs.",
        "- BIS adds broader property-price coverage, but only as annualized quarterly growth rates in the current bridge.",
        "- The merged panel is appropriate for first-pass descriptive country-year timing regressions before any richer HFD timing extension.",
        "",
    ]
    (BUILD_DIR / "international_timing_shocks_v1.md").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    eurostat = load_eurostat_panel()
    valid_codes = set(eurostat["country_code"].dropna().astype(str).unique())

    oecd_house_raw, oecd_house = pull_oecd_house_prices(valid_codes)
    oecd_rates_raw, oecd_rates = pull_oecd_rates(valid_codes)
    bis_raw, bis_panel = pull_bis_house_prices(valid_codes)

    merged = eurostat.merge(oecd_house, on=["country_code", "year"], how="left")
    merged = merged.merge(oecd_rates, on=["country_code", "year"], how="left")
    merged = merged.merge(bis_panel, on=["country_code", "year"], how="left")
    merged = merged.sort_values(["country_code", "year"]).reset_index(drop=True)

    oecd_house.to_csv(RAW_DIR / "oecd_house_prices_annual.csv", index=False)
    oecd_rates.to_csv(RAW_DIR / "oecd_interest_rates_annual.csv", index=False)
    bis_panel.to_csv(RAW_DIR / "bis_house_prices_annualized.csv", index=False)
    merged.to_csv(PROCESSED_DIR / "international_first_birth_timing_shocks_v1.csv", index=False)

    (RAW_DIR / "international_timing_shocks_metadata.json").write_text(
        json.dumps(
            {
                "oecd_house_price_url": OECD_RHPI_URL,
                "oecd_finmark_url": OECD_FINMARK_URL,
                "bis_url": BIS_SPP_URL,
                "shock_columns": [
                    "oecd_house_price_growth_pct",
                    "oecd_house_price_index",
                    "oecd_short_rate_pct",
                    "oecd_long_rate_pct",
                    "bis_nominal_house_price_growth_pct",
                    "bis_real_house_price_growth_pct",
                ],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    write_note(merged, eurostat, oecd_house, oecd_rates, bis_panel)
    print(PROCESSED_DIR / "international_first_birth_timing_shocks_v1.csv")


if __name__ == "__main__":
    main()
