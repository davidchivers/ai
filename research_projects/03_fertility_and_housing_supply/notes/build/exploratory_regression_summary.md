# Exploratory regression summary

These regressions use a state-year exploratory panel built from the raw source files.
The reason is mechanical: the new fertility data are county-year, while the legacy
housing and policy files are metro-year, so direct local-key overlap is zero in the
current processed panel.

## Panel diagnostics

- State-year panel rows: 918
- Distinct states: 51
- Overall year span: 2007 to 2024
- First-birth coverage: 2007 to 2024
- Female-population coverage: 2010 to 2018
- Rent coverage: 2007 to 2017
- Permits coverage: 2007 to 2012
- Overlap of `first_birth_rate_15_44` with denominators: 459 rows
- Overlap of `first_birth_rate_15_44` with rents and unemployment: 92 rows
- Overlap of `mean_age_first_birth` with rents and unemployment: 221 rows
- Overlap of `share_first_birth_30_plus` with rents and unemployment: 221 rows
- Overlap of `first_birth_rate_15_44` with permits: 45 rows

Main caveats:
- fertility is aggregated from county first-birth counts identified in CDC WONDER, so the
  sample over-represents large counties rather than all counties in a state.
- housing and unemployment series are state-year averages of legacy metro-year inputs.
- permits coverage is much thinner than rent coverage, so those coefficients are especially tentative.

## Regression results

| model_id | term | coef | std_err | p_value | n_obs | n_states | years |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| rate_rent_unemp | real_rent_index | -9.3056 | 7.0324 | 0.1857 | 92 | 43 | 2010-2017 |
| rate_rent_unemp | unemployment_rate | -14.8254 | 29.9413 | 0.6205 | 92 | 43 | 2010-2017 |
| age_rent_unemp | real_rent_index | 1.0007 | 0.8932 | 0.2626 | 221 | 43 | 2007-2017 |
| age_rent_unemp | unemployment_rate | 2.7337 | 2.8117 | 0.3309 | 221 | 43 | 2007-2017 |
| share30_rent_unemp | real_rent_index | 0.0267 | 0.0591 | 0.6516 | 221 | 43 | 2007-2017 |
| share30_rent_unemp | unemployment_rate | 0.0917 | 0.1494 | 0.5392 | 221 | 43 | 2007-2017 |
| rate_permits | permits_total_pc | 11.2604 | 103.4317 | 0.9133 | 45 | 22 | 2010-2012 |
| age_permits | permits_total_pc | -3.2397 | 2.0549 | 0.1149 | 111 | 22 | 2007-2012 |

## Readout

- `rate_rent_unemp` uses the cleanest overlap sample for first-birth rates, but it only runs from 2010 to 2017.
- `age_rent_unemp` and `share30_rent_unemp` use a wider 2007 to 2017 overlap because they do not need population denominators.
- `rate_permits` and `age_permits` are based on a thin permits sample and should be treated as a rough sign check only.
