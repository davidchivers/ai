# 04 empirical notes

Last updated: 2026-03-02

## Purpose

This note defines the exact US panel-data build for testing the model implication:
a demographic shock can tighten future housing politics and reduce later fertility through
housing costs/supply.

## Core empirical target

Baseline outcome lock for panel v1:

1. Primary outcome: `gfr_15_44` (births per 1,000 women ages 15--44).
2. Main reporting scale: level effects on `gfr_15_44`.
3. Robustness scale: `ln_gfr_15_44 = log(gfr_15_44 + 1)`.

Outcome path to estimate:

1. Immediate fertility response around housing-policy/supply shocks.
2. Medium-run fertility response after cohort and housing-political adjustment.

Primary dynamic estimand:

$$
Fertility_{it} = \sum_{k \neq -1}\beta_k\mathbf{1}\{EventTime_{it}=k\}
 + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

with immigration-composition controls and cohort decomposition.

## Exact panel design (US)

Baseline panel lock:

1. Unit: county-year.
2. Years: 2005--2023 in baseline estimation (chosen to align fertility, housing, and nativity-composition coverage).
3. Index key: `fips` (or `cbsa`) and `year`.
4. Compatibility key fields kept for project-02 merges: `metarea`, `metareano`.
5. Fallback aggregation rule (only if thin county cells bind): collapse to `cbsa`-year using population-weighted rates and summed counts.

## Variables: required minimum set

### A. Fertility outcomes

1. `asfr_15_19`, `asfr_20_24`, `asfr_25_29`, `asfr_30_34`, `asfr_35_39`, `asfr_40_44`
2. `gfr_15_44` (general fertility rate)
3. `first_birth_proxy` (share first births, where available)
4. `completed_fertility_proxy` (cohort proxy from age-specific panels)

### B. Housing supply and costs

1. `permits_total_pc`
2. `permits_mf_pc` (multifamily permit rate)
3. `permits_sf_pc` (single-family permit rate)
4. `housing_stock_growth`
5. `real_house_price_index`
6. `real_rent_index`
7. `price_to_income`

### C. Policy and treatment timing

1. `reform_date`
2. `event_time`
3. `treated`
4. `exposure_intensity` (pre-period housing stock composition or predicted reform bite)

### D. Demographic composition and immigration

1. `female_pop_15_44`
2. `native_female_pop_15_44`
3. `foreign_born_female_pop_15_44`
4. `foreign_born_share_15_44`
5. `net_migration_rate`
6. `international_migration_rate`

### E. Controls

1. `unemployment_rate`
2. `real_income_pc`
3. `college_share`
4. `marriage_rate` (if available)
5. `housing_demand_shifter` (population growth, employment growth)

## Data sources (baseline)

Fertility:

1. CDC NVSS natality microdata and/or published county/state fertility tables.
2. National Center for Health Statistics population denominators where needed.

Population and immigration composition:

1. Census Population Estimates Program (PEP).
2. ACS 1-year/5-year tables for nativity and age-by-sex composition.

Housing:

1. Census Building Permits Survey.
2. FHFA house price index.
3. Rent indices from BLS/CPI or alternative harmonized rent source.

Macro controls:

1. BLS (labor market).
2. BEA (income).

## Immigration-aware decomposition (mandatory)

For each geography-year, decompose fertility change:

$$
\Delta Fertility_{it}
= \underbrace{\Delta Fertility^{within}_{it}}_{\text{within native/foreign groups}}
+ \underbrace{\Delta Fertility^{composition}_{it}}_{\text{nativity cohort shares}}
$$

Required fields (to be present in the assembled analysis panel, even if not in the first raw scaffold):

1. `births_native_15_44`
2. `births_foreign_15_44`
3. `gfr_native_15_44`
4. `gfr_foreign_15_44`
5. `within_nativity_component`
6. `composition_nativity_component`

Construction logic:

1. Define shares:
   - `s_native_it = native_female_pop_15_44_it / female_pop_15_44_it`
   - `s_foreign_it = foreign_born_female_pop_15_44_it / female_pop_15_44_it`
2. Define group-specific fertility rates:
   - `gfr_native_15_44_it = births_native_15_44_it / native_female_pop_15_44_it * 1000`
   - `gfr_foreign_15_44_it = births_foreign_15_44_it / foreign_born_female_pop_15_44_it * 1000`
3. Exact two-group decomposition (Laspeyres-style in lagged shares/rates):
   - `within_nativity_component_it = s_native_i,t-1 * (gfr_native_it - gfr_native_i,t-1) + s_foreign_i,t-1 * (gfr_foreign_it - gfr_foreign_i,t-1)`
   - `composition_nativity_component_it = (s_native_it - s_native_i,t-1) * gfr_native_i,t-1 + (s_foreign_it - s_foreign_i,t-1) * gfr_foreign_i,t-1`

Implementation requirements:

1. Compute fertility rates separately for native-born and foreign-born where feasible.
2. Include nativity-share controls and migration-flow controls in baseline regressions.
3. Report treatment effects with and without composition adjustment.

## Identification sequence

### Strategy 1 (baseline): staggered reform event study

$$
Fertility_{it} = \sum_{k \neq -1}\beta_k\mathbf{1}\{EventTime_{it}=k\}
+ \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

with Sun-Abraham or Callaway-Sant'Anna implementation.

### Strategy 2: close-election political design

First stage:

$$
Supply_{it} = \pi ProHousingWin_{it} + f(Margin_{it}) + \eta_i + \tau_t + u_{it}
$$

Second stage:

$$
Fertility_{it} = \beta \widehat{Supply}_{it} + f(Margin_{it}) + \eta_i + \tau_t + e_{it}
$$

### Strategy 3: geographic-supply IV

Use predetermined supply constraints for housing-cost instrumented effects.

## Build order (next implementation)

1. Construct harmonized key map (`fips`, `year`) and geography crosswalk.
2. Build fertility outcomes table.
3. Merge housing and policy timing table.
4. Merge immigration/nativity composition table.
5. Add controls and create final analysis panel.
6. Produce a data-quality report (missingness, breaks, geography changes).

## Output files to create next

1. `data/processed/us_fertility_housing_panel_v1.csv` (or parquet)
2. `notes/build/us_panel_data_dictionary.md`
3. `notes/build/us_panel_missingness_report.md`

## Open empirical decisions

1. County-cell suppression threshold for fallback aggregation to `cbsa`-year (for example minimum female-pop or minimum births count).
2. Exact treatment of zero-birth cells in transformed outcomes (`ln_gfr_15_44` robustness).
3. Whether policy timing is coded at state level then mapped to local exposure intensity.
