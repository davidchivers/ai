#!/usr/bin/env python3
"""Import legacy NIMBY fertility data into project-03 raw panel input format.

Default source priority:
1) merged_birthrates_migrationweights.dta (metro-year weighted birth rates)
2) birthrates_updated.dta (state-year birth rates, fallback)
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Tuple

import pandas as pd


RAW_COLUMNS = [
    "fips",
    "cbsa",
    "metarea",
    "metareano",
    "state_fips",
    "year",
    "asfr_15_19",
    "asfr_20_24",
    "asfr_25_29",
    "asfr_30_34",
    "asfr_35_39",
    "asfr_40_44",
    "gfr_15_44",
    "first_birth_proxy",
    "completed_fertility_proxy",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import NIMBY fertility data to project-03 raw fertility CSV."
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


def to_blank_frame(n: int) -> pd.DataFrame:
    out = pd.DataFrame(index=range(n), columns=RAW_COLUMNS)
    return out.fillna("")


def extract_metareano(metarea: str) -> str:
    match = re.match(r"^\s*(\d+)\s*\.", metarea)
    if not match:
        return ""
    return match.group(1)


def build_from_metro_dta(path: Path) -> Tuple[pd.DataFrame, str]:
    df = pd.read_stata(path, convert_categoricals=True)
    needed = {"metarea", "year", "weightedbirthrate"}
    missing = needed - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns in {path.name}: {sorted(missing)}")

    keep = df[["metarea", "year", "weightedbirthrate"]].copy()
    keep["metarea"] = keep["metarea"].astype(str).str.strip()
    keep["year"] = pd.to_numeric(keep["year"], errors="coerce")
    keep["weightedbirthrate"] = pd.to_numeric(keep["weightedbirthrate"], errors="coerce")
    keep = keep.dropna(subset=["metarea", "year", "weightedbirthrate"])
    keep = keep[keep["metarea"] != ""]
    keep["year"] = keep["year"].astype(int)
    keep = keep.drop_duplicates(subset=["metarea", "year"], keep="last")
    keep = keep.sort_values(["metarea", "year"]).reset_index(drop=True)

    out = to_blank_frame(len(keep))
    out["metarea"] = keep["metarea"]
    out["metareano"] = keep["metarea"].map(extract_metareano)
    out["year"] = keep["year"]
    out["gfr_15_44"] = keep["weightedbirthrate"].round(6)

    return out, "merged_birthrates_migrationweights.dta"


def build_from_state_dta(path: Path) -> Tuple[pd.DataFrame, str]:
    df = pd.read_stata(path)
    needed = {"statefips", "year", "birthrate"}
    missing = needed - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns in {path.name}: {sorted(missing)}")

    keep = df[["statefips", "year", "birthrate"]].copy()
    keep["statefips"] = pd.to_numeric(keep["statefips"], errors="coerce")
    keep["year"] = pd.to_numeric(keep["year"], errors="coerce")
    keep["birthrate"] = pd.to_numeric(keep["birthrate"], errors="coerce")
    keep = keep.dropna(subset=["statefips", "year", "birthrate"])
    keep["statefips"] = keep["statefips"].astype(int)
    keep["year"] = keep["year"].astype(int)
    keep = keep.drop_duplicates(subset=["statefips", "year"], keep="last")
    keep = keep.sort_values(["statefips", "year"]).reset_index(drop=True)

    out = to_blank_frame(len(keep))
    out["state_fips"] = keep["statefips"].astype(str).str.zfill(2)
    out["metarea"] = keep["statefips"].map(lambda x: f"state_{x:02d}")
    out["metareano"] = keep["statefips"].astype(str)
    out["year"] = keep["year"]
    out["gfr_15_44"] = keep["birthrate"].round(6)

    return out, "birthrates_updated.dta"


def write_ingest_log(path: Path, source_name: str, row_count: int, year_min: int, year_max: int) -> None:
    lines = [
        "# US fertility ingest log",
        "",
        f"- Source file: {source_name}",
        f"- Rows written: {row_count}",
        f"- Year range: {year_min} to {year_max}",
        "",
        "## Notes",
        "",
        "- `gfr_15_44` is populated from legacy weighted/state birth-rate series.",
        "- Age-specific fertility columns remain blank in this ingest step.",
        "- Geography keys currently come from legacy `metarea` coding.",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    source_dir = args.source_dir.resolve()

    metro_path = source_dir / "merged_birthrates_migrationweights.dta"
    state_path = source_dir / "birthrates_updated.dta"
    output_path = project_root / "data" / "raw" / "cdc_fertility_county_year.csv"
    ingest_log = project_root / "notes" / "build" / "us_fertility_ingest_log.md"

    if metro_path.exists():
        out, source_name = build_from_metro_dta(metro_path)
    elif state_path.exists():
        out, source_name = build_from_state_dta(state_path)
    else:
        raise FileNotFoundError(
            "Could not find either merged_birthrates_migrationweights.dta or birthrates_updated.dta"
            f" in {source_dir}"
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(output_path, index=False)

    year_series = pd.to_numeric(out["year"], errors="coerce").dropna()
    year_min = int(year_series.min()) if not year_series.empty else -1
    year_max = int(year_series.max()) if not year_series.empty else -1
    write_ingest_log(
        path=ingest_log,
        source_name=source_name,
        row_count=len(out),
        year_min=year_min,
        year_max=year_max,
    )

    print(f"Wrote: {output_path}")
    print(f"Rows: {len(out)}")
    print(f"Source: {source_name}")
    print(f"Years: {year_min} to {year_max}")
    print(f"Log: {ingest_log}")


if __name__ == "__main__":
    main()
