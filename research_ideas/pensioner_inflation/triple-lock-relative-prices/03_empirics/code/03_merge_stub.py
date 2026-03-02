"""03_merge_stub.py

Pipeline stub: merge cleaned price, exposure, and pension shock datasets.
No merge is run until cleaned inputs are available.
"""

from pathlib import Path
import pandas as pd


def expected_outputs() -> dict:
    return {
        "panel_file": "analysis_panel_stub.parquet",
        "keys": ["region", "date", "category"],
        "core_vars": [
            "inflation",
            "retiree_share",
            "pension_shock",
            "services_flag",
            "nontradable_proxy_flag",
        ],
    }


def main() -> None:
    code_dir = Path(__file__).resolve().parent
    out_dir = code_dir.parent / "outputs" / "tables"
    out_dir.mkdir(parents=True, exist_ok=True)

    meta = pd.DataFrame(
        {
            "item": ["panel_file", "keys", "core_vars"],
            "value": [
                expected_outputs()["panel_file"],
                ",".join(expected_outputs()["keys"]),
                ",".join(expected_outputs()["core_vars"]),
            ],
        }
    )
    out = out_dir / "merge_stub_metadata.csv"
    meta.to_csv(out, index=False)
    print(f"Wrote merge metadata stub: {out}")


if __name__ == "__main__":
    main()
