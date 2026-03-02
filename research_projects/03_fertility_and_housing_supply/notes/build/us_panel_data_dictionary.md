# US panel data dictionary

- Generated: 2026-03-01 16:32:54
- Panel file: data/processed/us_fertility_housing_panel_v1.csv

## Key identifiers

| variable | type | description |
| --- | --- | --- |
| fips | string | county FIPS code (preferred local key) |
| cbsa | string | CBSA code (fallback local key) |
| metarea | string | NIMBY-project metro identifier (legacy compatibility) |
| metareano | string | NIMBY-project metro numeric identifier (legacy compatibility) |
| state_fips | string | state FIPS code |
| year | int | calendar year |

## Fertility outcomes

| variable | type | description |
| --- | --- | --- |
| asfr_15_19 | float | age-specific fertility rate, ages 15-19 |
| asfr_20_24 | float | age-specific fertility rate, ages 20-24 |
| asfr_25_29 | float | age-specific fertility rate, ages 25-29 |
| asfr_30_34 | float | age-specific fertility rate, ages 30-34 |
| asfr_35_39 | float | age-specific fertility rate, ages 35-39 |
| asfr_40_44 | float | age-specific fertility rate, ages 40-44 |
| gfr_15_44 | float | general fertility rate, ages 15-44 |
| first_birth_proxy | float | first-birth share/proxy where available |
| completed_fertility_proxy | float | cohort-completed fertility proxy |

## Housing outcomes

| variable | type | description |
| --- | --- | --- |
| permits_total_pc | float | total permits per capita |
| permits_mf_pc | float | multifamily permits per capita |
| permits_sf_pc | float | single-family permits per capita |
| housing_stock_growth | float | annual housing stock growth rate |
| real_house_price_index | float | real house price index |
| real_rent_index | float | real rent index |
| price_to_income | float | price to income ratio |

## Policy timing

| variable | type | description |
| --- | --- | --- |
| reform_date | string | policy reform effective date |
| event_time | int | years relative to reform date |
| treated | int | treated indicator (0/1) |
| exposure_intensity | float | ex-ante reform bite/intensity |

## Demographics and immigration

| variable | type | description |
| --- | --- | --- |
| female_pop_15_44 | float | female population ages 15-44 |
| native_female_pop_15_44 | float | native-born female population ages 15-44 |
| foreign_born_female_pop_15_44 | float | foreign-born female population ages 15-44 |
| foreign_born_share_15_44 | float | foreign-born share in female 15-44 population |
| net_migration_rate | float | net migration rate |
| international_migration_rate | float | international migration rate |

## Controls and metadata

| variable | type | description |
| --- | --- | --- |
| unemployment_rate | float | unemployment rate |
| real_income_pc | float | real income per capita |
| college_share | float | share college educated |
| marriage_rate | float | marriage rate (if available) |
| housing_demand_shifter | float | demand shifter summary variable |
| source_fertility | string | source tag for fertility fields |
| source_housing | string | source tag for housing fields |
| source_population | string | source tag for population/immigration fields |
| source_controls | string | source tag for controls |
| qa_passed | int | quality check pass flag (0/1) |

## Build note

This is a schema scaffold. Data rows are not loaded yet.
