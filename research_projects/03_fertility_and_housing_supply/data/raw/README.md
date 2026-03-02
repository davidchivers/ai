# Raw data inputs for US panel build

Place source files in this folder using the exact filenames below.

The builder script:

- `code/05_build_us_panel_from_sources.ps1`

reads these files:

1. `cdc_fertility_county_year.csv`
2. `housing_county_year.csv`
3. `policy_reforms_county_year.csv`
4. `population_immigration_county_year.csv`
5. `controls_county_year.csv`

If a file is missing, the build still runs and logs the gap in:

- `notes/build/us_panel_source_coverage.md`

## Current ingest status (2026-03-02)

- `cdc_fertility_county_year.csv` is now populated from legacy NIMBY data
  (`merged_birthrates_migrationweights.dta`) via:
  - `code/06_import_nimby_birthrates_to_raw.py`
- This ingest populates `gfr_15_44` as a legacy weighted birth-rate proxy and keeps
  age-specific fertility fields blank for now.
- `housing_county_year.csv` and `controls_county_year.csv` are now populated from legacy NIMBY
  `addedpermits.dta` via:
  - `code/07_import_nimby_housing_controls_to_raw.py`
- These housing/control ingests populate:
  - housing: `permits_total_pc` (from `unitspercapita`), `real_rent_index` (from `rent`),
    and population-growth-based demand shifters
  - controls: `unemployment_rate` (from `unemp`)
- `policy_reforms_county_year.csv` and `population_immigration_county_year.csv` remain template
  headers until dedicated source extracts are loaded.

## Minimum expected columns by file

Identifier note:

- Preferred canonical ids in this project: `fips`, `cbsa`, `metarea`, `metareano`, `state_fips`, `year`.
- The build script also accepts NIMBY-style aliases such as `STCOU`, `CBSA`, `statefips`, `met2013`, and `YEAR`.

### `cdc_fertility_county_year.csv`

- `fips`, `cbsa`, `metarea`, `metareano`, `state_fips`, `year`
- `asfr_15_19`, `asfr_20_24`, `asfr_25_29`, `asfr_30_34`, `asfr_35_39`, `asfr_40_44`
- `gfr_15_44`, `first_birth_proxy`, `completed_fertility_proxy`

### `housing_county_year.csv`

- `fips`, `year`
- `cbsa`, `state_fips`
- `permits_total_pc`, `permits_mf_pc`, `permits_sf_pc`, `housing_stock_growth`
- `real_house_price_index`, `real_rent_index`, `price_to_income`, `housing_demand_shifter`

### `policy_reforms_county_year.csv`

- `fips`, `cbsa`, `metarea`, `metareano`, `state_fips`, `year`
- `reform_date`, `event_time`, `treated`, `exposure_intensity`

### `population_immigration_county_year.csv`

- `fips`, `cbsa`, `metarea`, `metareano`, `state_fips`, `year`
- `female_pop_15_44`, `native_female_pop_15_44`, `foreign_born_female_pop_15_44`
- `foreign_born_share_15_44`, `net_migration_rate`, `international_migration_rate`

### `controls_county_year.csv`

- `fips`, `cbsa`, `metarea`, `metareano`, `state_fips`, `year`
- `unemployment_rate`, `real_income_pc`, `college_share`, `marriage_rate`
