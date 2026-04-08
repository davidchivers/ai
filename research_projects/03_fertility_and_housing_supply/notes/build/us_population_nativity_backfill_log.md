# ACS nativity backfill log

- Source: ACS 5-year Census API
- Years requested: 2010 to 2018
- Tables used:
  - `B01001` for total female age 15-44 (all years)
  - `B05013` for foreign-born female age 15-44 (2014+, direct)
  - `B06001` + `B06003` for foreign-born female 18-44 (2010-2013, imputed female share)
- Note: 2010-2013 uses B06001 (10-year age bins, both sexes) with B06003 female-share
  imputation. Age range is 18-44 (not 15-44); ages 15-17 are a minor omission.
- Rows with non-missing `native_female_pop_15_44`: 16411
- Rows with non-missing `foreign_born_female_pop_15_44`: 16411
