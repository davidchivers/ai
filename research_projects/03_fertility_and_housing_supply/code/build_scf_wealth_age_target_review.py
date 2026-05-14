from __future__ import annotations

import csv
import io
import statistics
import urllib.error
import urllib.request
import zipfile
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = PROJECT_ROOT / "notes" / "build"
SCF_ZIP_URL = "https://www.federalreserve.gov/econres/scf/dataviz/download/zips/scf.zip"
RECENT_YEARS = [2016, 2019, 2022]
AGE_ORDER = [
    "Less than 35",
    "35-44",
    "45-54",
    "55-64",
    "65-74",
    "75 or older",
]


TARGET_SPECS = [
    {
        "target_name": "median_transaction_accounts_to_income_under_35",
        "role": "support_liquidity",
        "unit": "ratio",
        "age_bin": "Less than 35",
        "field": "tx_to_income",
        "source": "Federal Reserve SCF age table, pooled 2016, 2019, 2022",
        "comment": (
            "Median transaction-account holdings relative to median before-tax income. "
            "Transaction-account medians are reported among holders, but holding rates in this age bin are about 98 percent."
        ),
        "model_mapping": "Young liquid-buffer support target for entrant-type shares.",
    },
    {
        "target_name": "median_transaction_accounts_to_income_35_44",
        "role": "support_liquidity",
        "unit": "ratio",
        "age_bin": "35-44",
        "field": "tx_to_income",
        "source": "Federal Reserve SCF age table, pooled 2016, 2019, 2022",
        "comment": (
            "Family-years liquid-buffer support target. "
            "Transaction-account medians are reported among holders, with holding rates around 98 percent."
        ),
        "model_mapping": "Family-years liquid-buffer support target for entrant-type shares.",
    },
    {
        "target_name": "median_net_worth_to_income_under_35",
        "role": "support_wealth",
        "unit": "ratio",
        "age_bin": "Less than 35",
        "field": "nw_to_income",
        "source": "Federal Reserve SCF age table, pooled 2016, 2019, 2022",
        "comment": "Young-household median net worth relative to median before-tax income.",
        "model_mapping": "Young balance-sheet support target; use for shape, not knife-edge levels.",
    },
    {
        "target_name": "median_net_worth_to_income_35_44",
        "role": "support_wealth",
        "unit": "ratio",
        "age_bin": "35-44",
        "field": "nw_to_income",
        "source": "Federal Reserve SCF age table, pooled 2016, 2019, 2022",
        "comment": "Family-years median net worth relative to median before-tax income.",
        "model_mapping": "Family-years balance-sheet support target; use for shape, not knife-edge levels.",
    },
    {
        "target_name": "median_net_worth_to_income_45_54",
        "role": "validation_wealth",
        "unit": "ratio",
        "age_bin": "45-54",
        "field": "nw_to_income",
        "source": "Federal Reserve SCF age table, pooled 2016, 2019, 2022",
        "comment": "Midlife validation target for the age-wealth profile.",
        "model_mapping": "Midlife validation target after young-entry fit is fixed.",
    },
    {
        "target_name": "median_net_worth_to_income_55_64",
        "role": "validation_wealth",
        "unit": "ratio",
        "age_bin": "55-64",
        "field": "nw_to_income",
        "source": "Federal Reserve SCF age table, pooled 2016, 2019, 2022",
        "comment": "Older-age validation target for the age-wealth profile.",
        "model_mapping": "Older-age validation target only; do not force early-life fit through this object.",
    },
]


def fetch_zip_bytes(url: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/123.0 Safari/537.36"
            )
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            return response.read()
    except urllib.error.HTTPError:
        cache_path = Path.home() / "AppData" / "Local" / "Temp" / "scf_dataviz.zip"
        if cache_path.exists():
            return cache_path.read_bytes()
        raise


def read_zip_csv(zip_bytes: bytes, member_name: str) -> list[dict[str, str]]:
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as archive:
        with archive.open(member_name) as handle:
            text = io.TextIOWrapper(handle, encoding="utf-8")
            return list(csv.DictReader(text))


def to_float(value: str) -> float:
    return float(value) if value not in ("", ".", None) else float("nan")


def build_year_rows(zip_bytes: bytes) -> list[dict[str, float | int | str]]:
    median_rows = read_zip_csv(zip_bytes, "interactive_bulletin_charts_agecl_median.csv")
    have_rows = read_zip_csv(zip_bytes, "interactive_bulletin_charts_agecl_have.csv")
    have_lookup = {
        (int(row["year"]), row["Category"]): row
        for row in have_rows
        if int(row["year"]) in RECENT_YEARS and row["Category"] in AGE_ORDER
    }

    out: list[dict[str, float | int | str]] = []
    for row in median_rows:
        year = int(row["year"])
        category = row["Category"]
        if year not in RECENT_YEARS or category not in AGE_ORDER:
            continue
        have_row = have_lookup[(year, category)]
        income = to_float(row["Before_Tax_Income"])
        net_worth = to_float(row["Net_Worth"])
        transaction_accounts = to_float(row["Transaction_Accounts"])
        tx_hold = to_float(have_row["Transaction_Accounts"])
        out.append(
            {
                "year": year,
                "age_bin": category,
                "median_before_tax_income_2022k": income,
                "median_net_worth_2022k": net_worth,
                "median_transaction_accounts_2022k": transaction_accounts,
                "transaction_accounts_holding_rate": tx_hold / 100.0,
                "nw_to_income": net_worth / income,
                "tx_to_income": transaction_accounts / income,
            }
        )
    out.sort(key=lambda row: (row["year"], AGE_ORDER.index(str(row["age_bin"]))))
    return out


def padded_band(values: list[float], pad: float = 0.15) -> tuple[float, float]:
    lo = min(values)
    hi = max(values)
    return lo * (1 - pad), hi * (1 + pad)


def build_recent_targets(year_rows: list[dict[str, float | int | str]]) -> list[dict[str, float | str]]:
    pooled: list[dict[str, float | str]] = []
    for spec in TARGET_SPECS:
        values = [
            float(row[spec["field"]])
            for row in year_rows
            if row["age_bin"] == spec["age_bin"]
        ]
        lower, upper = padded_band(values)
        pooled.append(
            {
                "target_name": spec["target_name"],
                "role": spec["role"],
                "unit": spec["unit"],
                "age_bin": spec["age_bin"],
                "reference": statistics.fmean(values),
                "lower": lower,
                "upper": upper,
                "source": spec["source"],
                "comment": spec["comment"],
                "model_mapping": spec["model_mapping"],
            }
        )
    return pooled


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_note(path: Path, year_rows: list[dict[str, float | int | str]], pooled_rows: list[dict[str, float | str]]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        handle.write("# SCF wealth age target review\n\n")
        handle.write(
            "Official source: Federal Reserve Survey of Consumer Finances data-visualization tables, "
            "downloaded from the Federal Reserve `scf.zip` CSV bundle.\n\n"
        )
        handle.write(
            "Years used: `2016`, `2019`, `2022`. These are recent triennial waves and all values are in `2022` dollars.\n\n"
        )
        handle.write(
            "The wealth objects below are designed for the annual branch as support and validation targets. "
            "They are not knife-edge targets. Raw dollar levels are awkward in the current normalized model, "
            "so the preferred objects are median wealth-to-income ratios by age. "
            "Transaction-account medians are reported by the SCF among holders, but holding rates are very high in every age bin used here.\n\n"
        )
        handle.write("## Recent SCF age profile\n\n")
        handle.write("| Year | Age bin | Median income | Median net worth | Median transaction accounts | Tx account holding rate | Net worth / income | Tx accounts / income |\n")
        handle.write("|---:|---|---:|---:|---:|---:|---:|---:|\n")
        for row in year_rows:
            handle.write(
                f"| {int(row['year'])} | {row['age_bin']} | "
                f"`{float(row['median_before_tax_income_2022k']):.1f}` | "
                f"`{float(row['median_net_worth_2022k']):.1f}` | "
                f"`{float(row['median_transaction_accounts_2022k']):.1f}` | "
                f"`{float(row['transaction_accounts_holding_rate']):.3f}` | "
                f"`{float(row['nw_to_income']):.3f}` | "
                f"`{float(row['tx_to_income']):.3f}` |\n"
            )
        handle.write("\n")
        handle.write("## Suggested annual wealth targets\n\n")
        handle.write("| Target | Role | Age bin | Reference | Lower | Upper |\n")
        handle.write("|---|---|---|---:|---:|---:|\n")
        for row in pooled_rows:
            handle.write(
                f"| {row['target_name']} | {row['role']} | {row['age_bin']} | "
                f"`{float(row['reference']):.3f}` | `{float(row['lower']):.3f}` | `{float(row['upper']):.3f}` |\n"
            )
        handle.write("\n")
        handle.write("## Interpretation\n\n")
        handle.write("- Use `under_35` as the closest data-side match to the model's `25-34` entrant block.\n")
        handle.write("- Treat the transaction-account targets as liquid-buffer support targets.\n")
        handle.write("- Treat the net-worth targets as age-profile shape targets, not literal dollar targets.\n")
        handle.write("- Older bins should remain validation objects unless the annual branch gets much closer on young entry first.\n")


def main() -> None:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    zip_bytes = fetch_zip_bytes(SCF_ZIP_URL)
    year_rows = build_year_rows(zip_bytes)
    pooled_rows = build_recent_targets(year_rows)

    write_csv(
        BUILD_DIR / "scf_wealth_age_target_review.csv",
        year_rows,
        [
            "year",
            "age_bin",
            "median_before_tax_income_2022k",
            "median_net_worth_2022k",
            "median_transaction_accounts_2022k",
            "transaction_accounts_holding_rate",
            "nw_to_income",
            "tx_to_income",
        ],
    )
    write_csv(
        BUILD_DIR / "scf_wealth_age_target_recent_pool.csv",
        pooled_rows,
        [
            "target_name",
            "role",
            "unit",
            "age_bin",
            "reference",
            "lower",
            "upper",
            "source",
            "comment",
            "model_mapping",
        ],
    )
    write_note(BUILD_DIR / "scf_wealth_age_target_review.md", year_rows, pooled_rows)


if __name__ == "__main__":
    main()
