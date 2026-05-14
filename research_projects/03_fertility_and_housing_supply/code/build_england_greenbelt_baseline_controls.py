#!/usr/bin/env python3
"""Build baseline England local-authority controls for the greenbelt design."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import requests


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw" / "england"
PROCESSED_DIR = ROOT / "data" / "processed"
BUILD_DIR = ROOT / "notes" / "build"

REGION_LOOKUP_URL = (
    "https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/"
    "3959874c514b470e9dd160acdc00c97a/csv?layers=0"
)
QS501_URL = (
    "https://www.nomisweb.co.uk/api/v01/dataset/nm_554_1.bulk.csv?"
    "time=latest&measures=20100&rural_urban=total&geography=TYPE464"
)
KS402_URL = (
    "https://www.nomisweb.co.uk/api/v01/dataset/nm_1507_1.bulk.csv?"
    "time=latest&measures=20100&geography=TYPE464"
)
QS606_URL = (
    "https://www.nomisweb.co.uk/api/v01/dataset/nm_1569_1.bulk.csv?"
    "time=latest&measures=20100&geography=TYPE464"
)

REGION_LOOKUP_FILE = RAW_DIR / "ons_lad24_to_region_lookup.csv"
QS501_FILE = RAW_DIR / "nomis_qs501ew_local_authority_2011.csv"
KS402_FILE = RAW_DIR / "nomis_ks402uk_local_authority_2011.csv"
QS606_FILE = RAW_DIR / "nomis_qs606uk_local_authority_2011.csv"

OUTPUT_FILE = PROCESSED_DIR / "england_greenbelt_baseline_controls_v1.csv"
NOTE_FILE = BUILD_DIR / "england_greenbelt_baseline_controls_v1.md"

CURRENT_CODE_PREFIXES = ("E06", "E07", "E08", "E09")
MANUAL_PREDECESSOR_MAP = {
    "E06000058": ["E06000028", "E07000048", "E06000029"],
    "E06000060": ["E07000004", "E07000005", "E07000006", "E07000007"],
    "E06000059": ["E07000049", "E07000051"],
    "E06000065": ["E07000164", "E07000165", "E07000167", "E07000169"],
    "E06000066": ["E07000187", "E07000188", "E07000189", "E07000246"],
}


def fetch_to_path(url: str, path: Path) -> None:
    response = requests.get(url, timeout=180)
    response.raise_for_status()
    path.write_bytes(response.content)


def ensure_sources() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    for url, path in (
        (REGION_LOOKUP_URL, REGION_LOOKUP_FILE),
        (QS501_URL, QS501_FILE),
        (KS402_URL, KS402_FILE),
        (QS606_URL, QS606_FILE),
    ):
        fetch_to_path(url, path)


def is_current_england_la(code: object) -> bool:
    text = str(code)
    return len(text) == 9 and text.startswith(CURRENT_CODE_PREFIXES)


def build_mapping_tables(region: pd.DataFrame) -> tuple[dict[str, str], dict[str, tuple[str, str, str]]]:
    predecessor_to_current = {
        predecessor: current
        for current, predecessors in MANUAL_PREDECESSOR_MAP.items()
        for predecessor in predecessors
    }
    current_name_to_codes = (
        region.groupby("area_name", as_index=False)
        .agg(n_codes=("area_code", "nunique"))
        .merge(region[["area_code", "area_name", "region_code", "region_name"]], on="area_name", how="left")
    )
    unique_name_map = {}
    for _, row in current_name_to_codes[current_name_to_codes["n_codes"].eq(1)].iterrows():
        unique_name_map[str(row["area_name"])] = (
            str(row["area_code"]),
            str(row["region_code"]),
            str(row["region_name"]),
        )
    return predecessor_to_current, unique_name_map


def map_to_current(
    raw_code: object,
    raw_name: object,
    region_codes: set[str],
    predecessor_to_current: dict[str, str],
    unique_name_map: dict[str, tuple[str, str, str]],
) -> str | None:
    code = str(raw_code)
    name = str(raw_name)
    if code in region_codes:
        return code
    if code in predecessor_to_current:
        return predecessor_to_current[code]
    match = unique_name_map.get(name)
    if match:
        return match[0]
    return None


def load_region_lookup() -> pd.DataFrame:
    region = pd.read_csv(REGION_LOOKUP_FILE)
    region = region.rename(
        columns={
            "LAD24CD": "area_code",
            "LAD24NM": "area_name",
            "RGN24CD": "region_code",
            "RGN24NM": "region_name",
        }
    )
    region = region[region["area_code"].apply(is_current_england_la)].copy()
    return region[["area_code", "area_name", "region_code", "region_name"]].drop_duplicates()


def load_qs501(region: pd.DataFrame) -> pd.DataFrame:
    raw = pd.read_csv(QS501_FILE)
    raw = raw.rename(
        columns={
            "geography": "raw_area_name",
            "geography code": "raw_area_code",
            "Qualification: All categories: Highest level of qualification; measures: Value": "qual_total",
            "Qualification: No qualifications; measures: Value": "no_qual",
            "Qualification: Level 4 qualifications and above; measures: Value": "level4_plus",
        }
    )
    region_codes = set(region["area_code"].astype(str))
    predecessor_to_current, unique_name_map = build_mapping_tables(region)
    raw["area_code"] = raw.apply(
        lambda row: map_to_current(
            row["raw_area_code"],
            row["raw_area_name"],
            region_codes,
            predecessor_to_current,
            unique_name_map,
        ),
        axis=1,
    )
    raw = raw[raw["area_code"].notna()].copy()
    raw["qual_total"] = pd.to_numeric(raw["qual_total"], errors="coerce")
    raw["no_qual"] = pd.to_numeric(raw["no_qual"], errors="coerce")
    raw["level4_plus"] = pd.to_numeric(raw["level4_plus"], errors="coerce")
    agg = (
        raw.groupby("area_code", as_index=False)
        .agg(
            qual_total=("qual_total", "sum"),
            no_qual=("no_qual", "sum"),
            level4_plus=("level4_plus", "sum"),
            n_source_codes=("raw_area_code", "nunique"),
        )
    )
    agg["degree_share_2011"] = agg["level4_plus"] / agg["qual_total"]
    agg["no_qual_share_2011"] = agg["no_qual"] / agg["qual_total"]
    return agg


def load_ks402(region: pd.DataFrame) -> pd.DataFrame:
    raw = pd.read_csv(KS402_FILE)
    raw = raw.rename(
        columns={
            "geography": "raw_area_name",
            "geography code": "raw_area_code",
            "Tenure: All households; measures: Value": "hh_total",
            "Tenure: Owned; measures: Value": "hh_owned",
        }
    )
    region_codes = set(region["area_code"].astype(str))
    predecessor_to_current, unique_name_map = build_mapping_tables(region)
    raw["area_code"] = raw.apply(
        lambda row: map_to_current(
            row["raw_area_code"],
            row["raw_area_name"],
            region_codes,
            predecessor_to_current,
            unique_name_map,
        ),
        axis=1,
    )
    raw = raw[raw["area_code"].notna()].copy()
    raw["hh_total"] = pd.to_numeric(raw["hh_total"], errors="coerce")
    raw["hh_owned"] = pd.to_numeric(raw["hh_owned"], errors="coerce")
    agg = (
        raw.groupby("area_code", as_index=False)
        .agg(
            hh_total=("hh_total", "sum"),
            hh_owned=("hh_owned", "sum"),
            n_source_codes=("raw_area_code", "nunique"),
        )
    )
    agg["owner_occ_share_2011"] = agg["hh_owned"] / agg["hh_total"]
    return agg


def load_qs606(region: pd.DataFrame) -> pd.DataFrame:
    raw = pd.read_csv(QS606_FILE)
    raw = raw.rename(
        columns={
            "geography": "raw_area_name",
            "geography code": "raw_area_code",
            "Occupation: All categories: Occupation; measures: Value": "occ_total",
            "Occupation: 1. Managers, directors and senior officials; measures: Value": "managers",
            "Occupation: 2. Professional occupations; measures: Value": "professionals",
        }
    )
    region_codes = set(region["area_code"].astype(str))
    predecessor_to_current, unique_name_map = build_mapping_tables(region)
    raw["area_code"] = raw.apply(
        lambda row: map_to_current(
            row["raw_area_code"],
            row["raw_area_name"],
            region_codes,
            predecessor_to_current,
            unique_name_map,
        ),
        axis=1,
    )
    raw = raw[raw["area_code"].notna()].copy()
    raw["occ_total"] = pd.to_numeric(raw["occ_total"], errors="coerce")
    raw["managers"] = pd.to_numeric(raw["managers"], errors="coerce")
    raw["professionals"] = pd.to_numeric(raw["professionals"], errors="coerce")
    agg = (
        raw.groupby("area_code", as_index=False)
        .agg(
            occ_total=("occ_total", "sum"),
            managers=("managers", "sum"),
            professionals=("professionals", "sum"),
            n_source_codes=("raw_area_code", "nunique"),
        )
    )
    agg["mgr_prof_share_2011"] = (agg["managers"] + agg["professionals"]) / agg["occ_total"]
    return agg


def build_controls() -> pd.DataFrame:
    region = load_region_lookup()
    qs501 = load_qs501(region)
    ks402 = load_ks402(region)
    qs606 = load_qs606(region)
    controls = (
        region.merge(qs501, on="area_code", how="left")
        .merge(ks402, on="area_code", how="left", suffixes=("_qual", "_tenure"))
        .merge(qs606, on="area_code", how="left", suffixes=("", "_occ"))
    )
    keep = [
        "area_code",
        "area_name",
        "region_code",
        "region_name",
        "degree_share_2011",
        "no_qual_share_2011",
        "owner_occ_share_2011",
        "mgr_prof_share_2011",
    ]
    return controls[keep].sort_values("area_code").reset_index(drop=True)


def write_note(controls: pd.DataFrame) -> None:
    covered = controls[
        controls[
            [
                "degree_share_2011",
                "owner_occ_share_2011",
                "mgr_prof_share_2011",
            ]
        ].notna().all(axis=1)
    ].copy()
    lines = [
        "# England greenbelt baseline controls v1",
        "",
        "These baseline controls are designed for the England greenbelt exposure design.",
        "They use pre-period or fixed cross-sectional authority characteristics to proxy affluent-place",
        "or `poshness` differences without controlling away the current house-price mechanism.",
        "",
        "## Official sources",
        "",
        f"- Region lookup: `{REGION_LOOKUP_URL}`",
        f"- 2011 Census qualification table QS501EW: `{QS501_URL}`",
        f"- 2011 Census tenure table KS402UK: `{KS402_URL}`",
        f"- 2011 Census occupation table QS606UK: `{QS606_URL}`",
        "",
        "## Variables",
        "",
        "- `degree_share_2011`: share with level 4 qualifications and above",
        "- `no_qual_share_2011`: share with no qualifications",
        "- `owner_occ_share_2011`: share of households that are owner occupied",
        "- `mgr_prof_share_2011`: share in managers or professional occupations",
        "",
        "## Coverage",
        "",
        f"- current-code England local authorities in lookup: `{controls['area_code'].nunique()}`",
        f"- authorities with all main baseline controls: `{covered['area_code'].nunique()}`",
        "",
        "## Output",
        "",
        "- processed controls: `data/processed/england_greenbelt_baseline_controls_v1.csv`",
        "",
    ]
    NOTE_FILE.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    ensure_sources()
    controls = build_controls()
    controls.to_csv(OUTPUT_FILE, index=False)
    write_note(controls)
    print(OUTPUT_FILE)


if __name__ == "__main__":
    main()
