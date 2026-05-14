#!/usr/bin/env python3
"""Pull Eurostat fertility indicators for international first-birth timing work."""

from __future__ import annotations

import json
from pathlib import Path

import pandas as pd
import requests


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw" / "international"
PROCESSED_DIR = ROOT / "data" / "processed"
BUILD_DIR = ROOT / "notes" / "build"
URL = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/demo_find"


INDICATORS = {
    "AGEMOTH1": "mean_age_first_birth",
    "LBIRTHR1PC": "pct_first_order_live_births",
    "AGEMOTH": "mean_age_childbirth",
    "TOTFERRT": "total_fertility_rate",
}


def fetch_root() -> dict:
    response = requests.get(URL, timeout=120)
    response.raise_for_status()
    return response.json()


def get_country_labels(root: dict) -> dict[str, str]:
    labels = root["dimension"]["geo"]["category"]["label"]
    return {code: label for code, label in labels.items() if len(code) == 2 and code.isalpha()}


def parse_series_payload(country: str, indicator: str, payload: dict) -> pd.DataFrame:
    time_index = payload["dimension"]["time"]["category"]["index"]
    rows: list[dict[str, object]] = []
    for year, idx in time_index.items():
        value = payload.get("value", {}).get(str(idx))
        if value is None:
            continue
        rows.append(
            {
                "country_code": country,
                "year": int(year),
                "indicator_code": indicator,
                "value": float(value),
            }
        )
    return pd.DataFrame(rows)


def fetch_country_indicator_series(session: requests.Session, country: str, indicator: str) -> pd.DataFrame:
    response = session.get(URL, params={"geo": country, "indic_de": indicator}, timeout=120)
    response.raise_for_status()
    return parse_series_payload(country, indicator, response.json())


def build_long_panel(country_labels: dict[str, str], updated: str) -> pd.DataFrame:
    session = requests.Session()
    parts: list[pd.DataFrame] = []
    for country in sorted(country_labels):
        for indicator in INDICATORS:
            part = fetch_country_indicator_series(session, country, indicator)
            if not part.empty:
                parts.append(part)
    long_df = pd.concat(parts, ignore_index=True)
    long_df["country_name"] = long_df["country_code"].map(country_labels)
    long_df["series"] = long_df["indicator_code"].map(INDICATORS)
    long_df["source"] = "Eurostat demo_find"
    long_df["source_updated"] = updated
    return long_df


def build_processed_panel(df: pd.DataFrame) -> pd.DataFrame:
    wide = df.pivot_table(
        index=["country_code", "country_name", "year"],
        columns="series",
        values="value",
        aggfunc="first",
    ).reset_index()
    wide = wide.sort_values(["country_code", "year"]).reset_index(drop=True)
    return wide


def write_note(raw_df: pd.DataFrame, panel_df: pd.DataFrame, updated: str) -> None:
    countries = panel_df["country_code"].nunique()
    year_min = int(panel_df["year"].min())
    year_max = int(panel_df["year"].max())
    lines = [
        "# Eurostat first-birth timing pull",
        "",
        "Official source:",
        f"- Eurostat API dataset `demo_find`: {URL}",
        "",
        f"Eurostat dataset timestamp: `{updated}`",
        "",
        "## Indicators pulled",
        "",
        "- `AGEMOTH1`: mean age of women at birth of first child",
        "- `LBIRTHR1PC`: percentage first-order live births",
        "- `AGEMOTH`: mean age of women at childbirth",
        "- `TOTFERRT`: total fertility rate",
        "",
        "## Coverage after country filter",
        "",
        f"- countries: `{countries}`",
        f"- years: `{year_min}` to `{year_max}`",
        f"- raw indicator-country-year rows: `{len(raw_df)}`",
        f"- processed country-year rows: `{len(panel_df)}`",
        "",
        "## Interpretation",
        "",
        "- This is the clean public international timing panel available immediately.",
        "- It gives a direct cross-country first-birth timing series through `mean_age_first_birth`.",
        "- It does not yet give age-bin first-birth shares such as `share_first_birth_30_plus`.",
        "- For order-specific age distributions, the next source should be the Human Fertility Database.",
        "",
    ]
    (BUILD_DIR / "international_first_birth_timing_eurostat.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    root = fetch_root()
    updated = root.get("updated", "")
    country_labels = get_country_labels(root)
    raw_long = build_long_panel(country_labels, updated=updated)
    panel = build_processed_panel(raw_long)

    raw_long.to_csv(RAW_DIR / "eurostat_demo_find_long.csv", index=False)
    panel.to_csv(PROCESSED_DIR / "international_first_birth_timing_eu.csv", index=False)
    (RAW_DIR / "eurostat_demo_find_metadata.json").write_text(
        json.dumps(
            {
                "source_url": URL,
                "updated": updated,
                "label": root.get("label"),
                "source": root.get("source"),
                "country_count": len(country_labels),
                "indicators_pulled": INDICATORS,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    write_note(raw_long, panel, updated=updated)
    print(PROCESSED_DIR / "international_first_birth_timing_eu.csv")


if __name__ == "__main__":
    main()
