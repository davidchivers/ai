#!/usr/bin/env python3
"""Import a manual CDC WONDER first-birth export into the project fertility schema.

The expected input is a CSV or tab-delimited text export with births grouped by:
- geography (county of residence or state)
- year
- mother's age group

The export should already be filtered to first births. If a live-birth-order column is
present, this importer keeps first births only.
"""

from __future__ import annotations

import argparse
import csv
import io
import re
from pathlib import Path

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
    "first_births_total",
    "first_birth_rate_15_44",
    "mean_age_first_birth",
    "median_age_first_birth",
    "share_first_birth_15_19",
    "share_first_birth_20_24",
    "share_first_birth_25_29",
    "share_first_birth_30_34",
    "share_first_birth_35_44",
    "share_first_birth_30_plus",
    "completed_fertility_proxy",
]

AGE_BIN_COLUMNS = [
    "share_first_birth_15_19",
    "share_first_birth_20_24",
    "share_first_birth_25_29",
    "share_first_birth_30_34",
    "share_first_birth_35_44",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import a CDC WONDER first-birth export into cdc_fertility_county_year.csv."
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Path to project root (default: parent of code/).",
    )
    parser.add_argument(
        "--input-path",
        type=Path,
        default=None,
        help="Path to manual CDC WONDER export. Defaults to data/raw/cdc_wonder_first_births_export.csv.",
    )
    parser.add_argument(
        "--output-path",
        type=Path,
        default=None,
        help="Output CSV path. Defaults to data/raw/cdc_fertility_county_year.csv under project root.",
    )
    parser.add_argument(
        "--ingest-log-path",
        type=Path,
        default=None,
        help="Ingest log path. Defaults to notes/build/us_fertility_ingest_log.md under project root.",
    )
    return parser.parse_args()


def detect_delimiter(sample: str) -> str:
    try:
        return csv.Sniffer().sniff(sample, delimiters=",\t;|").delimiter
    except csv.Error:
        return ","


def load_wonder_table(path: Path) -> pd.DataFrame:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    lines = text.splitlines()
    header_index = None
    for idx, line in enumerate(lines):
        lowered = line.lower()
        if "birth" in lowered and ("year" in lowered or "month" in lowered):
            header_index = idx
            break
    if header_index is None:
        raise ValueError("Could not find a CDC WONDER-style header row with Births and Year/Month.")

    table_text = "\n".join(lines[header_index:]) + "\n"
    delimiter = detect_delimiter("\n".join(lines[header_index : header_index + 5]))
    df = pd.read_csv(io.StringIO(table_text), sep=delimiter, dtype=str)
    df = df.dropna(axis=1, how="all")
    df.columns = [str(c).strip() for c in df.columns]
    return df


def find_column(columns: list[str], patterns: list[str]) -> str | None:
    for pattern in patterns:
        regex = re.compile(pattern, flags=re.IGNORECASE)
        for col in columns:
            if regex.search(col):
                return col
    return None


def clean_numeric(series: pd.Series) -> pd.Series:
    cleaned = (
        series.fillna("")
        .astype(str)
        .str.replace(",", "", regex=False)
        .str.replace(r"[^\d.\-]", "", regex=True)
    )
    cleaned = cleaned.replace("", pd.NA)
    return pd.to_numeric(cleaned, errors="coerce")


def is_first_birth(value: str) -> bool:
    lowered = str(value).strip().lower()
    return bool(re.search(r"(^1$|^1st\b|first)", lowered))


def infer_age_bucket(label: str) -> tuple[str | None, float | None]:
    text = str(label).strip().lower()
    if not text or text in {"nan", "all ages", "all"}:
        return None, None

    if "under" in text or re.search(r"\b10-14\b", text):
        return "share_first_birth_15_19", 14.0

    match = re.search(r"(\d+)\s*-\s*(\d+)", text)
    if match:
        lo = int(match.group(1))
        hi = int(match.group(2))
        midpoint = (lo + hi) / 2.0
    else:
        single_match = re.search(r"\b(\d{1,2})\b", text)
        if not single_match:
            return None, None
        lo = hi = int(single_match.group(1))
        midpoint = float(lo)

    if hi <= 19:
        return "share_first_birth_15_19", midpoint
    if hi <= 24:
        return "share_first_birth_20_24", midpoint
    if hi <= 29:
        return "share_first_birth_25_29", midpoint
    if hi <= 34:
        return "share_first_birth_30_34", midpoint
    return "share_first_birth_35_44", midpoint


def normalize_geo_fields(df: pd.DataFrame) -> tuple[pd.DataFrame, str]:
    columns = list(df.columns)
    county_col = find_column(columns, [r"county of residence$", r"^county$"])
    county_code_col = find_column(columns, [r"county of residence code$", r"^county code$"])
    state_col = find_column(columns, [r"state of residence$", r"^state$"])
    state_code_col = find_column(columns, [r"state of residence code$", r"^state code$"])
    year_col = find_column(columns, [r"^year$"])
    births_col = find_column(columns, [r"^births$"])
    age_col = find_column(columns, [r"age of mother", r"mother.?s age", r"mother age"])
    order_col = find_column(columns, [r"live birth order", r"birth order", r"order of birth"])

    required = {
        "year": year_col,
        "births": births_col,
        "age": age_col,
    }
    missing = [name for name, col in required.items() if col is None]
    if missing:
        raise ValueError(f"Missing required CDC WONDER columns: {', '.join(missing)}")

    out = df.copy()
    out["year"] = clean_numeric(out[year_col]).astype("Int64")
    out["births"] = clean_numeric(out[births_col])
    out["age_raw"] = out[age_col].fillna("").astype(str).str.strip()

    if order_col is not None:
        out = out[out[order_col].map(is_first_birth)]

    out = out[out["year"].notna() & out["births"].notna()].copy()
    out = out[out["births"] > 0].copy()

    if county_col is not None or county_code_col is not None:
        geography_level = "county_year"
        county_name = out[county_col].fillna("").astype(str).str.strip() if county_col is not None else pd.Series("", index=out.index)
        county_code = out[county_code_col].fillna("").astype(str).str.strip() if county_code_col is not None else pd.Series("", index=out.index)
        county_code = county_code.str.replace(r"[^\d]", "", regex=True).str.zfill(5)
        county_code = county_code.where(county_code.str.len() == 5, "")

        state_name = out[state_col].fillna("").astype(str).str.strip() if state_col is not None else pd.Series("", index=out.index)
        state_code = out[state_code_col].fillna("").astype(str).str.strip() if state_code_col is not None else pd.Series("", index=out.index)
        state_code = state_code.str.replace(r"[^\d]", "", regex=True)
        state_code = state_code.where(state_code.str.len() == 2, "")
        state_code = state_code.where(state_code.ne("") & state_code.ne("00"), county_code.str.slice(0, 2))

        metarea = county_name
        needs_suffix = (~metarea.str.contains(",", regex=False)) & state_name.ne("")
        metarea = metarea.where(~needs_suffix, metarea + ", " + state_name)

        out["fips"] = county_code
        out["state_fips"] = state_code
        out["metarea"] = metarea
    elif state_col is not None or state_code_col is not None:
        geography_level = "state_year"
        state_name = out[state_col].fillna("").astype(str).str.strip() if state_col is not None else pd.Series("", index=out.index)
        state_code = out[state_code_col].fillna("").astype(str).str.strip() if state_code_col is not None else pd.Series("", index=out.index)
        state_code = state_code.str.replace(r"[^\d]", "", regex=True)
        state_code = state_code.where(state_code.str.len() == 2, "")
        metarea = state_name.where(state_name != "", "state_" + state_code)
        out["fips"] = ""
        out["state_fips"] = state_code
        out["metarea"] = metarea
    else:
        raise ValueError("Could not find county or state geography columns in the CDC WONDER export.")

    out["cbsa"] = ""
    out["metareano"] = ""
    out = out[~out["metarea"].str.lower().str.contains(r"all counties|all states|united states", na=False)].copy()
    return out, geography_level


def summarize_group(group: pd.DataFrame) -> dict[str, str]:
    bin_counts = {col: 0.0 for col in AGE_BIN_COLUMNS}
    weighted_sum = 0.0
    total = float(group["births"].sum())

    for row in group.itertuples(index=False):
        bucket = getattr(row, "age_bucket")
        midpoint = getattr(row, "age_midpoint")
        births = float(getattr(row, "births"))
        if bucket is None:
            continue
        bin_counts[bucket] += births
        if midpoint is not None:
            weighted_sum += midpoint * births

    mean_age = weighted_sum / total if total > 0 else None

    ordered = (
        group[["age_midpoint", "births"]]
        .dropna()
        .sort_values("age_midpoint")
        .groupby("age_midpoint", as_index=False)["births"]
        .sum()
    )
    median_age = None
    if total > 0 and not ordered.empty:
        threshold = total / 2.0
        cum = ordered["births"].cumsum()
        idx = cum.ge(threshold).idxmax()
        median_age = float(ordered.loc[idx, "age_midpoint"])

    out = {col: "" for col in RAW_COLUMNS}
    first_row = group.iloc[0]
    out["fips"] = first_row["fips"]
    out["cbsa"] = first_row["cbsa"]
    out["metarea"] = first_row["metarea"]
    out["metareano"] = first_row["metareano"]
    out["state_fips"] = first_row["state_fips"]
    out["year"] = str(int(first_row["year"]))
    out["first_births_total"] = f"{total:.0f}"
    if mean_age is not None:
        out["mean_age_first_birth"] = f"{mean_age:.6f}"
    if median_age is not None:
        out["median_age_first_birth"] = f"{median_age:.6f}"

    if total > 0:
        for col, count in bin_counts.items():
            out[col] = f"{count / total:.6f}"
        share_30_plus = (
            bin_counts["share_first_birth_30_34"] + bin_counts["share_first_birth_35_44"]
        ) / total
        out["share_first_birth_30_plus"] = f"{share_30_plus:.6f}"
    return out


def write_ingest_log(
    path: Path,
    source_path: Path,
    geography_level: str,
    row_count: int,
    year_min: int | None,
    year_max: int | None,
) -> None:
    lines = [
        "# US fertility ingest log",
        "",
        f"- Source file: {source_path}",
        f"- Geography level: {geography_level}",
        f"- Rows written: {row_count}",
        f"- Year range: {year_min} to {year_max}",
        "",
        "## Notes",
        "",
        "- Importer: `code/11_import_cdc_wonder_first_births.py`",
        "- Output is designed for first-birth timing analysis from a manual CDC WONDER export.",
        "- `mean_age_first_birth` and `median_age_first_birth` are computed from grouped age cells,",
        "  so they are exact only when the export uses single-year ages.",
        "- Under-15 first births are folded into the youngest bin; ages above 34 are folded into",
        "  the top timing bin used in the current schema.",
        "- `first_birth_rate_15_44` is left blank at ingest and can be derived after merging female",
        "  population denominators.",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    input_path = (
        args.input_path.resolve()
        if args.input_path is not None
        else (project_root / "data" / "raw" / "cdc_wonder_first_births_export.csv")
    )
    output_path = (
        args.output_path.resolve()
        if args.output_path is not None
        else (project_root / "data" / "raw" / "cdc_fertility_county_year.csv")
    )
    ingest_log_path = (
        args.ingest_log_path.resolve()
        if args.ingest_log_path is not None
        else (project_root / "notes" / "build" / "us_fertility_ingest_log.md")
    )

    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    raw = load_wonder_table(input_path)
    normalized, geography_level = normalize_geo_fields(raw)

    age_info = normalized["age_raw"].map(infer_age_bucket)
    normalized["age_bucket"] = age_info.map(lambda x: x[0])
    normalized["age_midpoint"] = age_info.map(lambda x: x[1])
    normalized = normalized[normalized["age_bucket"].notna()].copy()

    group_cols = ["fips", "cbsa", "metarea", "metareano", "state_fips", "year"]
    output_rows = []
    for _, group in normalized.groupby(group_cols, dropna=False, sort=True):
        output_rows.append(summarize_group(group))

    out = pd.DataFrame(output_rows, columns=RAW_COLUMNS)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(output_path, index=False)

    year_series = pd.to_numeric(out["year"], errors="coerce").dropna()
    year_min = int(year_series.min()) if not year_series.empty else None
    year_max = int(year_series.max()) if not year_series.empty else None
    write_ingest_log(
        path=ingest_log_path,
        source_path=input_path,
        geography_level=geography_level,
        row_count=len(out),
        year_min=year_min,
        year_max=year_max,
    )

    print(f"Wrote: {output_path}")
    print(f"Rows: {len(out)}")
    print(f"Years: {year_min} to {year_max}")
    print(f"Geography: {geography_level}")
    print(f"Log: {ingest_log_path}")


if __name__ == "__main__":
    main()
