# US fertility ingest log

- Source file: C:\Users\Dave_\AI\research_projects\03_fertility_and_housing_supply\data\raw\cdc_wonder_first_births_export.csv
- Geography level: county_year
- Rows written: 10890
- Year range: 2007 to 2024

## Notes

- Importer: `code/11_import_cdc_wonder_first_births.py`
- Output is designed for first-birth timing analysis from a manual CDC WONDER export.
- `mean_age_first_birth` and `median_age_first_birth` are computed from grouped age cells,
  so they are exact only when the export uses single-year ages.
- Under-15 first births are folded into the youngest bin; ages above 34 are folded into
  the top timing bin used in the current schema.
- `first_birth_rate_15_44` is left blank at ingest and can be derived after merging female
  population denominators.
