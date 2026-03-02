#!/usr/bin/env python3
"""Backfill nativity fields from ACS API for county-year panel rows.

Uses ACS 5-year tables with year-specific fallbacks:
- 2014+: B05013 (foreign-born female by 5-year age bins) — direct
- 2010-2013: B06001 (foreign-born by 10-year age bins, both sexes)
             + B06003 (foreign-born by sex) to impute female share
- All years: B01001 for total female 15-44

Output updated in place:
- data/raw/population_immigration_county_year.csv
"""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd
import requests


YEARS = list(range(2010, 2019))

# B01001 female 15-44 bins (available all years)
TOTAL_FEMALE_1544_VARS = [
    "B01001_030E",  # 15-17
    "B01001_031E",  # 18-19
    "B01001_032E",  # 20
    "B01001_033E",  # 21
    "B01001_034E",  # 22-24
    "B01001_035E",  # 25-29
    "B01001_036E",  # 30-34
    "B01001_037E",  # 35-39
    "B01001_038E",  # 40-44
]

# B05013 foreign-born female 15-44 bins (available 2014+)
FOREIGN_FEMALE_1544_VARS_B05013 = [
    "B05013_025E",  # 15-19
    "B05013_026E",  # 20-24
    "B05013_027E",  # 25-29
    "B05013_028E",  # 30-34
    "B05013_029E",  # 35-39
    "B05013_030E",  # 40-44
]

# B06001 foreign-born by age, both sexes (available 2010+, fallback for 2010-2013)
FOREIGN_BY_AGE_VARS_B06001 = [
    "B06001_052E",  # foreign born, 18-24
    "B06001_053E",  # foreign born, 25-34
    "B06001_054E",  # foreign born, 35-44
]

# B06003 foreign-born by sex (available 2010+, for female-share imputation)
FOREIGN_BY_SEX_VARS_B06003 = [
    "B06003_013E",  # foreign born, total
    "B06003_015E",  # foreign born, female
]

# Cutoff: B05013 available from this year onward
B05013_FIRST_YEAR = 2014


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Backfill nativity fields in population_immigration_county_year.csv from ACS API."
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Path to project root (default: parent of code/).",
    )
    return parser.parse_args()


def _fetch_json(url: str) -> list:
    """Fetch Census API JSON with error handling."""
    resp = requests.get(url, timeout=120)
    resp.raise_for_status()
    return resp.json()


def fetch_acs_year_direct(year: int) -> pd.DataFrame:
    """Fetch using B05013 (direct foreign-born female bins). For 2014+."""
    vars_all = TOTAL_FEMALE_1544_VARS + FOREIGN_FEMALE_1544_VARS_B05013
    get_vars = ",".join(["NAME"] + vars_all)
    url = (
        f"https://api.census.gov/data/{year}/acs/acs5"
        f"?get={get_vars}&for=county:*&in=state:*"
    )
    data = _fetch_json(url)
    cols = data[0]
    rows = data[1:]
    df = pd.DataFrame(rows, columns=cols)
    df["year"] = year

    for c in vars_all:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    df["fips"] = df["state"] + df["county"]
    df["female_pop_15_44_acs"] = df[TOTAL_FEMALE_1544_VARS].sum(axis=1, min_count=1)
    df["foreign_born_female_pop_15_44_acs"] = df[FOREIGN_FEMALE_1544_VARS_B05013].sum(
        axis=1, min_count=1
    )
    return _finalize_acs_df(df)


def fetch_acs_year_imputed(year: int) -> pd.DataFrame:
    """Fetch using B06001 + B06003 (imputed female share). For 2010-2013."""
    vars_all = (
        TOTAL_FEMALE_1544_VARS
        + FOREIGN_BY_AGE_VARS_B06001
        + FOREIGN_BY_SEX_VARS_B06003
    )
    get_vars = ",".join(["NAME"] + vars_all)
    url = (
        f"https://api.census.gov/data/{year}/acs/acs5"
        f"?get={get_vars}&for=county:*&in=state:*"
    )
    data = _fetch_json(url)
    cols = data[0]
    rows = data[1:]
    df = pd.DataFrame(rows, columns=cols)
    df["year"] = year

    for c in vars_all:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    df["fips"] = df["state"] + df["county"]
    df["female_pop_15_44_acs"] = df[TOTAL_FEMALE_1544_VARS].sum(axis=1, min_count=1)

    # Foreign-born total (both sexes) covering approx ages 18-44
    fb_both_sexes = df[FOREIGN_BY_AGE_VARS_B06001].sum(axis=1, min_count=1)

    # Female share among foreign-born
    fb_total = pd.to_numeric(df["B06003_013E"], errors="coerce")
    fb_female = pd.to_numeric(df["B06003_015E"], errors="coerce")
    female_share = fb_female / fb_total.replace(0, pd.NA)

    # Impute: foreign-born females 18-44 = both-sexes * female_share
    # Note: B06001 covers 18-44 not 15-44; this is a minor approximation
    # for ages 15-17 which are a small share of foreign-born women of
    # childbearing age.
    df["foreign_born_female_pop_15_44_acs"] = fb_both_sexes * female_share

    return _finalize_acs_df(df)


def _finalize_acs_df(df: pd.DataFrame) -> pd.DataFrame:
    """Compute derived columns and return standardised output."""
    df["native_female_pop_15_44_acs"] = (
        df["female_pop_15_44_acs"] - df["foreign_born_female_pop_15_44_acs"]
    )
    df.loc[df["native_female_pop_15_44_acs"] < 0, "native_female_pop_15_44_acs"] = 0
    df["foreign_born_share_15_44_acs"] = (
        df["foreign_born_female_pop_15_44_acs"] / df["female_pop_15_44_acs"]
    )
    df.loc[df["female_pop_15_44_acs"] <= 0, "foreign_born_share_15_44_acs"] = pd.NA

    keep = df[
        [
            "fips",
            "year",
            "female_pop_15_44_acs",
            "native_female_pop_15_44_acs",
            "foreign_born_female_pop_15_44_acs",
            "foreign_born_share_15_44_acs",
        ]
    ].copy()
    return keep


def fetch_acs_year(year: int) -> pd.DataFrame:
    """Route to direct or imputed fetch depending on table availability."""
    if year >= B05013_FIRST_YEAR:
        print(f"  {year}: using B05013 (direct)")
        return fetch_acs_year_direct(year)
    else:
        print(f"  {year}: using B06001+B06003 (imputed female share)")
        return fetch_acs_year_imputed(year)


def backfill(pop_path: Path) -> tuple[int, int]:
    pop = pd.read_csv(pop_path, dtype=str)
    pop["fips"] = pop["fips"].fillna("").astype(str).str.zfill(5)
    pop["year"] = pd.to_numeric(pop["year"], errors="coerce").astype("Int64")

    print("Fetching ACS data by year...")
    acs_parts = [fetch_acs_year(y) for y in YEARS]
    acs = pd.concat(acs_parts, ignore_index=True)
    acs["fips"] = acs["fips"].astype(str).str.zfill(5)
    acs["year"] = pd.to_numeric(acs["year"], errors="coerce").astype("Int64")

    merged = pop.merge(acs, how="left", on=["fips", "year"])

    # Fill/overwrite target nativity fields with ACS values when available.
    merged["female_pop_15_44"] = merged["female_pop_15_44_acs"].combine_first(
        pd.to_numeric(merged["female_pop_15_44"], errors="coerce")
    )
    merged["native_female_pop_15_44"] = merged["native_female_pop_15_44_acs"].combine_first(
        pd.to_numeric(merged["native_female_pop_15_44"], errors="coerce")
    )
    merged["foreign_born_female_pop_15_44"] = merged[
        "foreign_born_female_pop_15_44_acs"
    ].combine_first(pd.to_numeric(merged["foreign_born_female_pop_15_44"], errors="coerce"))
    merged["foreign_born_share_15_44"] = merged["foreign_born_share_15_44_acs"].combine_first(
        pd.to_numeric(merged["foreign_born_share_15_44"], errors="coerce")
    )

    # Clean temporary columns
    drop_cols = [c for c in merged.columns if c.endswith("_acs")]
    merged = merged.drop(columns=drop_cols)

    # Convert numeric columns back to CSV-friendly format
    num_cols = [
        "female_pop_15_44",
        "native_female_pop_15_44",
        "foreign_born_female_pop_15_44",
        "foreign_born_share_15_44",
        "net_migration_rate",
        "international_migration_rate",
    ]
    for c in num_cols:
        if c in merged.columns:
            merged[c] = pd.to_numeric(merged[c], errors="coerce")

    filled_native = merged["native_female_pop_15_44"].notna().sum()
    filled_foreign = merged["foreign_born_female_pop_15_44"].notna().sum()

    merged.to_csv(pop_path, index=False)
    return int(filled_native), int(filled_foreign)


def write_log(log_path: Path, native_count: int, foreign_count: int) -> None:
    lines = [
        "# ACS nativity backfill log",
        "",
        "- Source: ACS 5-year Census API",
        f"- Years requested: {YEARS[0]} to {YEARS[-1]}",
        "- Tables used:",
        "  - `B01001` for total female age 15-44 (all years)",
        "  - `B05013` for foreign-born female age 15-44 (2014+, direct)",
        "  - `B06001` + `B06003` for foreign-born female 18-44 (2010-2013, imputed female share)",
        "- Note: 2010-2013 uses B06001 (10-year age bins, both sexes) with B06003 female-share",
        "  imputation. Age range is 18-44 (not 15-44); ages 15-17 are a minor omission.",
        f"- Rows with non-missing `native_female_pop_15_44`: {native_count}",
        f"- Rows with non-missing `foreign_born_female_pop_15_44`: {foreign_count}",
    ]
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    pop_path = project_root / "data" / "raw" / "population_immigration_county_year.csv"
    if not pop_path.exists():
        raise FileNotFoundError(f"Missing file: {pop_path}")

    native_count, foreign_count = backfill(pop_path)
    log_path = project_root / "notes" / "build" / "us_population_nativity_backfill_log.md"
    write_log(log_path, native_count, foreign_count)

    print(f"Updated: {pop_path}")
    print(f"native_nonmissing_rows={native_count}")
    print(f"foreign_nonmissing_rows={foreign_count}")
    print(f"Log: {log_path}")


if __name__ == "__main__":
    main()
