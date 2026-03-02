# US population + policy ingest log

- Population/migration source files:
  - `msa pop change 2010 to 2018 combined.csv`
  - `age state.csv`
- Policy source file:
  - `addedpermits.dta`
- Population/immigration rows written: 16425
- Policy rows written: 41865
- Population year range: 2010 to 2018
- Policy year range: 1940 to 2018

## Mapping notes

- `female_pop_15_44` is state-year female age 15-44 from `age state.csv`
  mapped to county rows via state FIPS.
- `net_migration_rate` and `international_migration_rate` are migration flows
  divided by annual population estimates from the MSA/county population-change file.
- Nativity-specific female population fields are left blank due source limitations
  in the legacy NIMBY files currently used.
- Policy timing is a proxy: `reform_year` is first metro-year with observed permit
  activity in `addedpermits.dta`; `event_time = year - reform_year`.
- `exposure_intensity` is average `unitspercapita` in the first five years from reform onset.
