#!/usr/bin/env python3
"""Import population/immigration and policy proxy blocks from legacy NIMBY sources.

Population/migration source files:
- msa pop change 2010 to 2018 combined.csv
- age state.csv

Policy proxy source file:
- addedpermits.dta

Notes:
- Nativity-specific female population fields are not directly available in these legacy files.
- Policy timing is constructed as a legacy proxy from first observed permit activity by metro.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import pandas as pd


POP_COLS = [
    "fips",
    "cbsa",
    "metarea",
    "metareano",
    "state_fips",
    "year",
    "female_pop_15_44",
    "native_female_pop_15_44",
    "foreign_born_female_pop_15_44",
    "foreign_born_share_15_44",
    "net_migration_rate",
    "international_migration_rate",
]

POLICY_COLS = [
    "fips",
    "cbsa",
    "metarea",
    "metareano",
    "state_fips",
    "year",
    "reform_date",
    "event_time",
    "treated",
    "exposure_intensity",
]

YEARS_POP = list(range(2010, 2019))
YEARS_POLICY_MIN = 1940


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import population/immigration and policy proxy blocks from legacy NIMBY files."
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


def _blank_df(columns: list[str], n: int) -> pd.DataFrame:
    out = pd.DataFrame(index=range(n), columns=columns)
    return out.fillna("")


def _state_from_metarea_label(text: str) -> str:
    m = re.search(r",\s*([a-z]{2})\s*$", str(text).lower())
    return m.group(1).upper() if m else ""


def build_state_female_1544(age_state_csv: Path) -> pd.DataFrame:
    age_bins = ["15to19", "20to24", "25to29", "30to34", "35to39", "40to44"]
    needed_cols = ["GEO.id2"] + [
        f"est7{y}sex2_age{b}" for y in YEARS_POP for b in age_bins
    ]

    age = pd.read_csv(
        age_state_csv,
        encoding="latin1",
        usecols=lambda c: c in needed_cols,
        low_memory=False,
    )
    age["state_fips_num"] = pd.to_numeric(age["GEO.id2"], errors="coerce")
    age = age.dropna(subset=["state_fips_num"]).copy()
    age["state_fips"] = age["state_fips_num"].astype(int).astype(str).str.zfill(2)

    rows: list[pd.DataFrame] = []
    for y in YEARS_POP:
        cols = [f"est7{y}sex2_age{b}" for b in age_bins]
        available = [c for c in cols if c in age.columns]
        if not available:
            continue
        tmp = age[["state_fips"] + available].copy()
        for c in available:
            tmp[c] = pd.to_numeric(tmp[c], errors="coerce")
        tmp["female_pop_15_44"] = tmp[available].sum(axis=1, min_count=1)
        tmp["year"] = y
        rows.append(tmp[["state_fips", "year", "female_pop_15_44"]])

    if not rows:
        return pd.DataFrame(columns=["state_fips", "year", "female_pop_15_44"])
    out = pd.concat(rows, ignore_index=True)
    out = out.drop_duplicates(subset=["state_fips", "year"], keep="last")
    return out


def build_population_block(msa_csv: Path, state_female: pd.DataFrame) -> pd.DataFrame:
    msa = pd.read_csv(msa_csv, encoding="latin1", low_memory=False)
    county = msa[msa["STCOU"].notna()].copy()

    county["fips_num"] = pd.to_numeric(county["STCOU"], errors="coerce")
    county["cbsa_num"] = pd.to_numeric(county["CBSA"], errors="coerce")
    county = county.dropna(subset=["fips_num", "cbsa_num"])

    county["fips"] = county["fips_num"].astype(int).astype(str).str.zfill(5)
    county["cbsa"] = county["cbsa_num"].astype(int).astype(str)
    county["state_fips"] = county["fips"].str.slice(0, 2)
    county["metarea"] = county["NAME"].astype(str).str.strip()
    county["metareano"] = county["cbsa"]

    rows: list[pd.DataFrame] = []
    for y in YEARS_POP:
        pop_col = f"POPESTIMATE{y}"
        net_col = f"NETMIG{y}"
        intl_col = f"INTERNATIONALMIG{y}"
        if pop_col not in county.columns:
            continue
        tmp = county[
            ["fips", "cbsa", "metarea", "metareano", "state_fips", pop_col, net_col, intl_col]
        ].copy()
        tmp["year"] = y
        tmp[pop_col] = pd.to_numeric(tmp[pop_col], errors="coerce")
        tmp[net_col] = pd.to_numeric(tmp[net_col], errors="coerce")
        tmp[intl_col] = pd.to_numeric(tmp[intl_col], errors="coerce")
        tmp = tmp.dropna(subset=[pop_col])
        tmp = tmp[tmp[pop_col] > 0]
        tmp["net_migration_rate"] = tmp[net_col] / tmp[pop_col]
        tmp["international_migration_rate"] = tmp[intl_col] / tmp[pop_col]
        rows.append(
            tmp[
                [
                    "fips",
                    "cbsa",
                    "metarea",
                    "metareano",
                    "state_fips",
                    "year",
                    "net_migration_rate",
                    "international_migration_rate",
                ]
            ]
        )

    if rows:
        pop = pd.concat(rows, ignore_index=True)
    else:
        pop = pd.DataFrame(
            columns=[
                "fips",
                "cbsa",
                "metarea",
                "metareano",
                "state_fips",
                "year",
                "net_migration_rate",
                "international_migration_rate",
            ]
        )

    pop = pop.merge(state_female, how="left", on=["state_fips", "year"])

    out = _blank_df(POP_COLS, len(pop))
    for c in ["fips", "cbsa", "metarea", "metareano", "state_fips", "year"]:
        out[c] = pop[c]
    out["female_pop_15_44"] = pd.to_numeric(pop["female_pop_15_44"], errors="coerce").round(3)
    out["net_migration_rate"] = pd.to_numeric(pop["net_migration_rate"], errors="coerce").round(8)
    out["international_migration_rate"] = (
        pd.to_numeric(pop["international_migration_rate"], errors="coerce").round(8)
    )

    # Nativity fields remain blank due source limitation.
    out = out.drop_duplicates(subset=["fips", "year"], keep="last")
    out = out.sort_values(["fips", "year"]).reset_index(drop=True)
    return out


def build_policy_block(addedpermits_dta: Path) -> pd.DataFrame:
    df = pd.read_stata(addedpermits_dta, convert_categoricals=True)
    keep_cols = ["metarea", "metareano", "year", "unitspercapita", "totalunits"]
    data = df[keep_cols].copy()
    data["metarea"] = data["metarea"].astype(str).str.strip()
    data["metareano"] = pd.to_numeric(data["metareano"], errors="coerce")
    data["year"] = pd.to_numeric(data["year"], errors="coerce")
    data["unitspercapita"] = pd.to_numeric(data["unitspercapita"], errors="coerce")
    data["totalunits"] = pd.to_numeric(data["totalunits"], errors="coerce")
    data = data.dropna(subset=["metarea", "year"]).copy()
    data = data[data["year"] >= YEARS_POLICY_MIN]
    data["year"] = data["year"].astype(int)
    data = data.sort_values(["metarea", "year"])

    data["activity_observed"] = data["unitspercapita"].notna() | data["totalunits"].notna()
    onset = (
        data[data["activity_observed"]]
        .groupby("metarea", as_index=False)["year"]
        .min()
        .rename(columns={"year": "reform_year"})
    )
    data = data.merge(onset, on="metarea", how="left")

    # Exposure proxy: average permits intensity in first five available years from onset.
    base = data.copy()
    base = base[base["reform_year"].notna()]
    base = base[
        (base["year"] >= base["reform_year"]) & (base["year"] <= base["reform_year"] + 4)
    ]
    expo = (
        base.groupby("metarea", as_index=False)["unitspercapita"]
        .mean()
        .rename(columns={"unitspercapita": "exposure_intensity"})
    )
    data = data.merge(expo, on="metarea", how="left")

    out = _blank_df(POLICY_COLS, len(data))
    out["metarea"] = data["metarea"]
    out["metareano"] = (
        data["metareano"].round().astype("Int64").astype(str).replace("<NA>", "")
    )
    out["year"] = data["year"]
    out["state_fips"] = data["metarea"].map(_state_from_metarea_label)

    reform_year = pd.to_numeric(data["reform_year"], errors="coerce")
    out["reform_date"] = reform_year.map(
        lambda x: f"{int(x):04d}-01-01" if pd.notna(x) else ""
    )
    out["event_time"] = (
        pd.to_numeric(data["year"], errors="coerce") - reform_year
    ).round().astype("Int64").astype(str).replace("<NA>", "")
    out["treated"] = reform_year.notna().astype(int)
    out["exposure_intensity"] = pd.to_numeric(
        data["exposure_intensity"], errors="coerce"
    ).round(8)

    out = out.drop_duplicates(subset=["metarea", "year"], keep="last")
    out = out.sort_values(["metarea", "year"]).reset_index(drop=True)
    return out


def write_log(
    path: Path,
    pop_rows: int,
    policy_rows: int,
    pop_year_min: int,
    pop_year_max: int,
    policy_year_min: int,
    policy_year_max: int,
) -> None:
    lines = [
        "# US population + policy ingest log",
        "",
        "- Population/migration source files:",
        "  - `msa pop change 2010 to 2018 combined.csv`",
        "  - `age state.csv`",
        "- Policy source file:",
        "  - `addedpermits.dta`",
        f"- Population/immigration rows written: {pop_rows}",
        f"- Policy rows written: {policy_rows}",
        f"- Population year range: {pop_year_min} to {pop_year_max}",
        f"- Policy year range: {policy_year_min} to {policy_year_max}",
        "",
        "## Mapping notes",
        "",
        "- `female_pop_15_44` is state-year female age 15-44 from `age state.csv`",
        "  mapped to county rows via state FIPS.",
        "- `net_migration_rate` and `international_migration_rate` are migration flows",
        "  divided by annual population estimates from the MSA/county population-change file.",
        "- Nativity-specific female population fields are left blank due source limitations",
        "  in the legacy NIMBY files currently used.",
        "- Policy timing is a proxy: `reform_year` is first metro-year with observed permit",
        "  activity in `addedpermits.dta`; `event_time = year - reform_year`.",
        "- `exposure_intensity` is average `unitspercapita` in the first five years from reform onset.",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _year_range(series: pd.Series) -> tuple[int, int]:
    s = pd.to_numeric(series, errors="coerce").dropna()
    if s.empty:
        return (-1, -1)
    return (int(s.min()), int(s.max()))


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    source_dir = args.source_dir.resolve()

    age_state_csv = source_dir / "age state.csv"
    msa_change_csv = source_dir / "msa pop change 2010 to 2018 combined.csv"
    addedpermits_dta = source_dir / "addedpermits.dta"

    for p in [age_state_csv, msa_change_csv, addedpermits_dta]:
        if not p.exists():
            raise FileNotFoundError(f"Missing source file: {p}")

    state_female = build_state_female_1544(age_state_csv)
    pop = build_population_block(msa_change_csv, state_female)
    policy = build_policy_block(addedpermits_dta)

    raw_dir = project_root / "data" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)

    pop_path = raw_dir / "population_immigration_county_year.csv"
    policy_path = raw_dir / "policy_reforms_county_year.csv"
    pop.to_csv(pop_path, index=False)
    policy.to_csv(policy_path, index=False)

    pop_y0, pop_y1 = _year_range(pop["year"])
    pol_y0, pol_y1 = _year_range(policy["year"])
    log_path = project_root / "notes" / "build" / "us_population_policy_ingest_log.md"
    write_log(
        path=log_path,
        pop_rows=len(pop),
        policy_rows=len(policy),
        pop_year_min=pop_y0,
        pop_year_max=pop_y1,
        policy_year_min=pol_y0,
        policy_year_max=pol_y1,
    )

    print(f"Wrote: {pop_path} (rows={len(pop)})")
    print(f"Wrote: {policy_path} (rows={len(policy)})")
    print(f"Log: {log_path}")


if __name__ == "__main__":
    main()
