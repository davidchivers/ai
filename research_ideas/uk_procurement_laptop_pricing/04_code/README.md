# code pipeline overview

This folder contains non-executing stubs for a reproducible pipeline. No scraping or data collection is performed by default.

## intended pipeline order
1. `01_collect_public_contracts_stub.py`
2. `02_parse_contract_attachments_stub.py`
3. `03_collect_market_prices_stub.py`
4. `04_match_skus_stub.py`
5. `05_construct_analysis_panel_stub.py`
6. `06_run_analysis_stub.py`

## required manual inputs
- API keys or credentials (if any) for official APIs.
- Seed list of notice IDs and/or search queries.
- Curated market price sources and archival snapshots.
- Local folder containing downloaded attachment PDFs/XLSX files.

## expected data folders (user-managed)
- `../02_data/raw_notices/` (optional)
- `../02_data/raw_attachments/` (optional)
- `../02_data/intermediate/` (optional)
- `../02_data/final/` (optional)

## constraints
- These scripts intentionally include placeholder functions and pseudocode.
- They are templates for implementation and testing, not production scrapers.
