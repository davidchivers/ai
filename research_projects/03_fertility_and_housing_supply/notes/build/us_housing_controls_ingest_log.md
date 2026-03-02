# US housing/controls ingest log

- Source file: addedpermits.dta
- Housing rows written: 5708
- Controls rows written: 4667
- Year range in ingested rows: 1960 to 2017

## Mapping notes

- `permits_total_pc` <- `unitspercapita` (legacy NIMBY field).
- `real_rent_index` <- `rent` (legacy rental-cost proxy).
- `housing_stock_growth` and `housing_demand_shifter` <- metro-year growth in `citypop`.
- `unemployment_rate` <- `unemp`.
- `state_fips` currently stores two-letter state abbreviations parsed from `metarea` labels.
- `permits_mf_pc`, `permits_sf_pc`, `real_house_price_index`, `price_to_income`,
  `real_income_pc`, `college_share`, and `marriage_rate` remain blank in this ingest step.
