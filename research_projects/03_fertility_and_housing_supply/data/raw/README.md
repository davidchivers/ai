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

## Current ingest status (2026-03-09)

- `cdc_fertility_county_year.csv` is now populated from a direct CDC WONDER natality pull
  covering first births by county, year, and mother's age group for `2007-2024`.
- Direct pull path:
  - `code/12_pull_cdc_wonder_first_births.py`
  - output: `data/raw/cdc_wonder_first_births_export.csv`
- Import path:
  - `code/11_import_cdc_wonder_first_births.py`
  - output: `data/raw/cdc_fertility_county_year.csv`
- There is now also a direct state-year CDC timing extract for target review / graphing:
  - raw export: `data/raw/cdc_wonder_first_births_state_year_export.csv`
  - imported panel: `data/raw/cdc_fertility_state_year.csv`
  - review note: `notes/build/cdc_first_birth_timing_target_review.md`
- The old NIMBY metro-level fertility proxy remains superseded for the main empirical path.
- `housing_county_year.csv` and `controls_county_year.csv` are now populated from legacy NIMBY
  `addedpermits.dta` via:
  - `code/07_import_nimby_housing_controls_to_raw.py`
- These housing/control ingests populate:
  - housing: `permits_total_pc` (from `unitspercapita`), `real_rent_index` (from `rent`),
    and population-growth-based demand shifters
  - controls: `unemployment_rate` (from `unemp`)
- `population_immigration_county_year.csv` is populated from the legacy county file and now has
  nativity fields backfilled from the ACS API via `code/09_backfill_nativity_from_acs_api.py`.
- `policy_reforms_county_year.csv` remains the legacy metro-year proxy file.

## Minimum expected columns by file

Identifier note:

- Preferred canonical ids in this project: `fips`, `cbsa`, `metarea`, `metareano`, `state_fips`, `year`.
- The build script also accepts NIMBY-style aliases such as `STCOU`, `CBSA`, `statefips`, `met2013`, and `YEAR`.

### `cdc_fertility_county_year.csv`

- `fips`, `cbsa`, `metarea`, `metareano`, `state_fips`, `year`
- `asfr_15_19`, `asfr_20_24`, `asfr_25_29`, `asfr_30_34`, `asfr_35_39`, `asfr_40_44`
- `gfr_15_44`, `first_birth_proxy`, `completed_fertility_proxy`
- `first_births_total`, `first_birth_rate_15_44`
- `mean_age_first_birth`, `median_age_first_birth`
- `share_first_birth_15_19`, `share_first_birth_20_24`, `share_first_birth_25_29`
- `share_first_birth_30_34`, `share_first_birth_35_44`, `share_first_birth_30_plus`

## CDC WONDER first-birth timing import

Preferred workflow:

1. Run `code/12_pull_cdc_wonder_first_births.py`
2. This writes `data/raw/cdc_wonder_first_births_export.csv`
3. Run `code/11_import_cdc_wonder_first_births.py`
4. This writes `data/raw/cdc_fertility_county_year.csv`

Optional direct state-year workflow:

1. Run `code/12_pull_cdc_wonder_first_births.py --geography state_year`
2. This writes `data/raw/cdc_wonder_first_births_state_year_export.csv`
3. Run `code/11_import_cdc_wonder_first_births.py --output-path data/raw/cdc_fertility_state_year.csv`

Fallback workflow:

1. Save a manual CDC WONDER export as `data/raw/cdc_wonder_first_births_export.csv`
2. Run `code/11_import_cdc_wonder_first_births.py`

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
