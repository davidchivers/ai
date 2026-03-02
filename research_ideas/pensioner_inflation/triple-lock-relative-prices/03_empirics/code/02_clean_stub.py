"""02_clean_stub.py

Pipeline stub: validate schema and define cleaning placeholders.
No real data transformation is executed until input files are provided.
"""

from pathlib import Path
import pandas as pd


REQUIRED_COLUMNS = {
    "cpi": ["date", "category", "inflation"],
    "population": ["year", "region", "retiree_share"],
    "pension": ["year", "uprate", "cpi", "earnings"],
}


def validate_columns(df: pd.DataFrame, required: list[str], name: str) -> None:
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"{name}: missing columns {missing}")


def main() -> None:
    code_dir = Path(__file__).resolve().parent
    print("Clean stub only. Expected manual input files are not loaded yet.")
    print(f"Working directory: {code_dir}")
    print("TODO: wire file paths, then run schema validation and harmonise dates/categories.")


if __name__ == "__main__":
    main()
