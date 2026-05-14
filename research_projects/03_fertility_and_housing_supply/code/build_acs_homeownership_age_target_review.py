from __future__ import annotations

import csv
import json
import urllib.request
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = PROJECT_ROOT / "notes" / "build"
YEARS = [2019, 2021, 2022, 2023, 2024]
AGE_LABELS = [
    "15_24",
    "25_34",
    "35_44",
    "45_54",
    "55_59",
    "60_64",
    "65_74",
    "75_84",
    "85_plus",
]
OWNER_COLS = [
    "B25007_003E",
    "B25007_004E",
    "B25007_005E",
    "B25007_006E",
    "B25007_007E",
    "B25007_008E",
    "B25007_009E",
    "B25007_010E",
    "B25007_011E",
]
RENTER_COLS = [
    "B25007_013E",
    "B25007_014E",
    "B25007_015E",
    "B25007_016E",
    "B25007_017E",
    "B25007_018E",
    "B25007_019E",
    "B25007_020E",
    "B25007_021E",
]


def fetch_year(year: int) -> dict[str, float]:
    cols = ",".join(["NAME"] + OWNER_COLS + RENTER_COLS)
    url = f"https://api.census.gov/data/{year}/acs/acs1?get={cols}&for=us:1"
    with urllib.request.urlopen(url, timeout=30) as response:
        payload = json.load(response)

    values = list(map(float, payload[1][1 : 1 + len(OWNER_COLS) + len(RENTER_COLS)]))
    owner = values[: len(OWNER_COLS)]
    renter = values[len(OWNER_COLS) :]

    out: dict[str, float] = {"year": float(year)}
    for idx, label in enumerate(AGE_LABELS):
        total = owner[idx] + renter[idx]
        out[f"owner_share_{label}"] = owner[idx] / total if total else float("nan")

    owner_55_64 = owner[4] + owner[5]
    renter_55_64 = renter[4] + renter[5]
    out["owner_share_55_64"] = owner_55_64 / (owner_55_64 + renter_55_64)
    return out


def pooled_value(rows: list[dict[str, float]], key: str) -> float:
    return sum(row[key] for row in rows) / len(rows)


def write_csv(path: Path, rows: list[dict[str, float]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    yearly_rows = [fetch_year(year) for year in YEARS]

    pooled_rows = [
        {
            "target_name": "owner_share_25_34",
            "reference": pooled_value(yearly_rows, "owner_share_25_34"),
            "lower": 0.28,
            "upper": 0.54,
            "role": "support_homeownership",
        },
        {
            "target_name": "owner_share_35_44",
            "reference": pooled_value(yearly_rows, "owner_share_35_44"),
            "lower": 0.48,
            "upper": 0.72,
            "role": "support_homeownership",
        },
        {
            "target_name": "owner_share_45_54",
            "reference": pooled_value(yearly_rows, "owner_share_45_54"),
            "lower": 0.58,
            "upper": 0.80,
            "role": "support_homeownership",
        },
        {
            "target_name": "owner_share_55_64",
            "reference": pooled_value(yearly_rows, "owner_share_55_64"),
            "lower": 0.64,
            "upper": 0.84,
            "role": "validation_homeownership",
        },
        {
            "target_name": "owner_share_65_74",
            "reference": pooled_value(yearly_rows, "owner_share_65_74"),
            "lower": 0.70,
            "upper": 0.87,
            "role": "validation_homeownership",
        },
    ]

    write_csv(
        BUILD_DIR / "acs_homeownership_age_target_review.csv",
        yearly_rows,
        [
            "year",
            "owner_share_15_24",
            "owner_share_25_34",
            "owner_share_35_44",
            "owner_share_45_54",
            "owner_share_55_59",
            "owner_share_60_64",
            "owner_share_55_64",
            "owner_share_65_74",
            "owner_share_75_84",
            "owner_share_85_plus",
        ],
    )
    write_csv(
        BUILD_DIR / "acs_homeownership_age_target_recent_pool.csv",
        pooled_rows,
        ["target_name", "reference", "lower", "upper", "role"],
    )

    note_path = BUILD_DIR / "acs_homeownership_age_target_review.md"
    with note_path.open("w", encoding="utf-8") as handle:
        handle.write("# ACS homeownership age target review\n\n")
        handle.write(
            "Official source: U.S. Census Bureau ACS 1-year table `B25007` "
            "(`Tenure by Age of Householder`), national pull via the Census API.\n\n"
        )
        handle.write(
            "Years used: `2019`, `2021`, `2022`, `2023`, `2024`.\n"
            "The standard `2020` ACS 1-year release is excluded from the target pool.\n\n"
        )
        handle.write("## Annual owner-occupancy shares\n\n")
        handle.write("| Year | 25-34 | 35-44 | 45-54 | 55-64 | 65-74 |\n")
        handle.write("|---:|---:|---:|---:|---:|---:|\n")
        for row in yearly_rows:
            handle.write(
                f"| {int(row['year'])} | `{row['owner_share_25_34']:.3f}` | "
                f"`{row['owner_share_35_44']:.3f}` | `{row['owner_share_45_54']:.3f}` | "
                f"`{row['owner_share_55_64']:.3f}` | `{row['owner_share_65_74']:.3f}` |\n"
            )
        handle.write("\n")
        handle.write("## Loose annual support targets\n\n")
        handle.write(
            "These should be treated as support targets, not anchor targets.\n"
            "They are intentionally wide because the ACS object is by age of householder, while the model state is female age.\n\n"
        )
        handle.write("| Target | Role | Reference | Lower | Upper |\n")
        handle.write("|---|---|---:|---:|---:|\n")
        for row in pooled_rows:
            handle.write(
                f"| {row['target_name']} | {row['role']} | `{row['reference']:.3f}` | "
                f"`{row['lower']:.3f}` | `{row['upper']:.3f}` |\n"
            )
        handle.write("\n")
        handle.write("## Strictness choice\n\n")
        handle.write("- Scored support bins: `25-34`, `35-44`, `45-54`\n")
        handle.write("- Validation-only bins: `55-64`, `65-74`\n")
        handle.write("- Intended use: light support target in annual model screening, not a hard pass/fail requirement\n")


if __name__ == "__main__":
    main()
