"""01_download_stub.py

Pipeline stub: define data source manifest and expected raw inputs.
This script intentionally does not download data yet.
"""

from pathlib import Path
import json


def build_manifest() -> dict:
    """Return a structured manifest of required datasets."""
    return {
        "project": "triple_lock_relative_prices",
        "status": "stub_no_download",
        "datasets": [
            {
                "name": "ons_cpi_coicop",
                "source": "ONS",
                "expected_frequency": "monthly",
                "geography": "national_or_regional",
                "raw_file": "TODO_set_after_manual_download",
            },
            {
                "name": "ons_lcf_age_weights",
                "source": "ONS",
                "expected_frequency": "annual",
                "geography": "national",
                "raw_file": "TODO_set_after_manual_download",
            },
            {
                "name": "ons_population_by_age",
                "source": "ONS",
                "expected_frequency": "annual",
                "geography": "region_or_la",
                "raw_file": "TODO_set_after_manual_download",
            },
            {
                "name": "uk_state_pension_uprating",
                "source": "DWP/ONS/official_publications",
                "expected_frequency": "annual",
                "geography": "national",
                "raw_file": "TODO_set_after_manual_download",
            },
        ],
    }


def main() -> None:
    code_dir = Path(__file__).resolve().parent
    out = code_dir / "download_manifest_stub.json"
    out.write_text(json.dumps(build_manifest(), indent=2), encoding="utf-8")
    print(f"Wrote manifest stub: {out}")


if __name__ == "__main__":
    main()
