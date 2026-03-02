#!/usr/bin/env python3
"""Import legacy NIMBY housing/control series into project-03 raw inputs.

Source: addedpermits.dta from the legacy NIMBY data directory.
Mappings are conservative and documented in the ingest log.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import pandas as pd


HOUSING_COLS = [
    "fips",
    "cbsa",
    "metarea",
    "metareano",
    "state_fips",
    "year",
    "permits_total_pc",
    "permits_mf_pc",
    "permits_sf_pc",
    "housing_stock_growth",
    "real_house_price_index",
    "real_rent_index",
    "price_to_income",
    "housing_demand_shifter",
]

CONTROLS_COLS = [
    "fips",
    "cbsa",
    "metarea",
    "metareano",
    "state_fips",
    "year",
    "unemployment_rate",
    "real_income_pc",
    "college_share",
    "marriage_rate",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import legacy NIMBY housing/control data to project-03 raw CSV inputs."
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Path to project root (default: parent of code/).",
    )
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path(r"C:\Users\Dave_\Dropbox\Zac and David\Data"),
        help="Directory containing legacy NIMBY data files.",
    )
    return parser.parse_args()


def parse_state_from_metarea(text: str) -> str:
    # Example: "4. abilene, tx" -> "TX" (kept as text state marker; not numeric FIPS).
    match = re.search(r",\s*([a-z]{2})\s*$", text.lower())
    return match.group(1).upper() if match else ""


def build_housing(df: pd.DataFrame) -> pd.DataFrame:
    data = df[
        ["metarea", "metareano", "year", "unitspercapita", "citypop", "rent"]
    ].copy()
    data["metarea"] = data["metarea"].astype(str).str.strip()
    data["year"] = pd.to_numeric(data["year"], errors="coerce")
    data["metareano"] = pd.to_numeric(data["metareano"], errors="coerce")
    data["unitspercapita"] = pd.to_numeric(data["unitspercapita"], errors="coerce")
    data["citypop"] = pd.to_numeric(data["citypop"], errors="coerce")
    data["rent"] = pd.to_numeric(data["rent"], errors="coerce")

    # Keep rows where at least one housing signal exists.
    keep_mask = data[["unitspercapita", "citypop", "rent"]].notna().any(axis=1)
    data = data[keep_mask].copy()
    data = data.dropna(subset=["metarea", "year"])
    data["year"] = data["year"].astype(int)
    data = data.sort_values(["metarea", "year"])

    # Demand shifter proxy: city population growth within metro.
    data["citypop_lag"] = data.groupby("metarea")["citypop"].shift(1)
    data["housing_stock_growth"] = (data["citypop"] - data["citypop_lag"]) / data["citypop_lag"]

    out = pd.DataFrame(index=data.index, columns=HOUSING_COLS)
    out = out.fillna("")
    out["metarea"] = data["metarea"]
    out["metareano"] = data["metareano"].round().astype("Int64").astype(str).replace("<NA>", "")
    out["year"] = data["year"]
    out["permits_total_pc"] = data["unitspercapita"].round(8)
    out["real_rent_index"] = data["rent"].round(8)
    out["housing_stock_growth"] = data["housing_stock_growth"].round(8)
    out["housing_demand_shifter"] = data["housing_stock_growth"].round(8)
    out["state_fips"] = data["metarea"].map(parse_state_from_metarea)
    out = out.drop_duplicates(subset=["metarea", "year"], keep="last")
    out = out.sort_values(["metarea", "year"]).reset_index(drop=True)
    return out


def build_controls(df: pd.DataFrame) -> pd.DataFrame:
    data = df[["metarea", "metareano", "year", "unemp"]].copy()
    data["metarea"] = data["metarea"].astype(str).str.strip()
    data["year"] = pd.to_numeric(data["year"], errors="coerce")
    data["metareano"] = pd.to_numeric(data["metareano"], errors="coerce")
    data["unemp"] = pd.to_numeric(data["unemp"], errors="coerce")
    data = data.dropna(subset=["metarea", "year", "unemp"])
    data["year"] = data["year"].astype(int)
    data = data.sort_values(["metarea", "year"])

    out = pd.DataFrame(index=data.index, columns=CONTROLS_COLS)
    out = out.fillna("")
    out["metarea"] = data["metarea"]
    out["metareano"] = data["metareano"].round().astype("Int64").astype(str).replace("<NA>", "")
    out["year"] = data["year"]
    out["unemployment_rate"] = data["unemp"].round(8)
    out["state_fips"] = data["metarea"].map(parse_state_from_metarea)
    out = out.drop_duplicates(subset=["metarea", "year"], keep="last")
    out = out.sort_values(["metarea", "year"]).reset_index(drop=True)
    return out


def write_log(path: Path, housing_rows: int, controls_rows: int, year_min: int, year_max: int) -> None:
    lines = [
        "# US housing/controls ingest log",
        "",
        "- Source file: addedpermits.dta",
        f"- Housing rows written: {housing_rows}",
        f"- Controls rows written: {controls_rows}",
        f"- Year range in ingested rows: {year_min} to {year_max}",
        "",
        "## Mapping notes",
        "",
        "- `permits_total_pc` <- `unitspercapita` (legacy NIMBY field).",
        "- `real_rent_index` <- `rent` (legacy rental-cost proxy).",
        "- `housing_stock_growth` and `housing_demand_shifter` <- metro-year growth in `citypop`.",
        "- `unemployment_rate` <- `unemp`.",
        "- `state_fips` currently stores two-letter state abbreviations parsed from `metarea` labels.",
        "- `permits_mf_pc`, `permits_sf_pc`, `real_house_price_index`, `price_to_income`,",
        "  `real_income_pc`, `college_share`, and `marriage_rate` remain blank in this ingest step.",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    source_dir = args.source_dir.resolve()

    source_file = source_dir / "addedpermits.dta"
    if not source_file.exists():
        raise FileNotFoundError(f"Missing source file: {source_file}")

    df = pd.read_stata(source_file, convert_categoricals=True)
    housing = build_housing(df)
    controls = build_controls(df)

    raw_dir = project_root / "data" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    housing_path = raw_dir / "housing_county_year.csv"
    controls_path = raw_dir / "controls_county_year.csv"
    housing.to_csv(housing_path, index=False)
    controls.to_csv(controls_path, index=False)

    years = pd.to_numeric(
        pd.concat([housing["year"], controls["year"]], ignore_index=True),
        errors="coerce",
    ).dropna()
    year_min = int(years.min()) if not years.empty else -1
    year_max = int(years.max()) if not years.empty else -1

    log_path = project_root / "notes" / "build" / "us_housing_controls_ingest_log.md"
    write_log(
        path=log_path,
        housing_rows=len(housing),
        controls_rows=len(controls),
        year_min=year_min,
        year_max=year_max,
    )

    print(f"Wrote: {housing_path} (rows={len(housing)})")
    print(f"Wrote: {controls_path} (rows={len(controls)})")
    print(f"Log: {log_path}")


if __name__ == "__main__":
    main()
