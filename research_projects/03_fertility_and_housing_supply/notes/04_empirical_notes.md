# 04 empirical notes

Last updated: 2026-03-09

## Purpose

This note defines the exact US panel-data build for testing the model implication:
a demographic shock can tighten future housing politics and reduce later fertility through
housing costs/supply.

## Core empirical target

Current empirical position after the live natality pull:

1. Main outcome family: first-birth timing.
2. Current usable outcomes:
   - `first_birth_rate_15_44`
   - `mean_age_first_birth`
   - `share_first_birth_30_plus`
3. `gfr_15_44` is now an archival legacy outcome only, not the active baseline.
4. The current workable regression bridge is state-year because the modern fertility data are
   county-year while the legacy housing files are metro-year.

Decision for the main empirical path:

1. Do not use the current historical metro `gfr_15_44` panel as the paper's baseline panel.
2. Use a modern natality-based source as the main fertility build.
3. Keep the historical metro `gfr_15_44` sample only for provisional sign checks while the
   modern build is being assembled.

Outcome path to estimate:

1. Immediate fertility response around housing-policy/supply shocks.
2. Medium-run fertility response after cohort and housing-political adjustment.

Current reduced-form estimand in the existing panel:

$$
Fertility_{it} = \sum_{k \neq -1}\beta_k\mathbf{1}\{EventTime_{it}=k\}
 + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

with immigration-composition controls and cohort decomposition.

## Candidate pivot: maternal age at first birth

One empirical option is to move away from overall fertility as the headline outcome and
instead target timing more directly through maternal age at first birth.

Reason:

1. The model mechanism is mainly about delay caused by housing costs, housing access,
   and family-sized housing constraints.
2. Age at first birth is closer to that mechanism than overall `gfr_15_44`.
3. A delay outcome may be easier to interpret if housing shocks shift birth timing before
   they materially change completed fertility.

Working interpretation:

1. Headline outcome candidate: maternal age at first birth.
2. Supporting timing outcomes: first-birth shares by maternal age bin and first-birth rates
   by geography-year.
3. `gfr_15_44` remains useful as a secondary outcome or robustness outcome rather than the
   only primary target.

Current implementation status:

1. The natality build now exists.
2. `data/raw/cdc_fertility_county_year.csv` is populated from CDC WONDER first-birth counts
   by county, year, and maternal age group for `2007-2024`.
3. The remaining bottleneck is no longer fertility construction; it is geography alignment
   with the legacy housing and policy files.

## Candidate outcome definitions for a first-birth design

Preferred outcome family if the natality source supports it:

1. `mean_age_first_birth`: mean maternal age among first births in geography-year.
2. `median_age_first_birth`: median maternal age among first births, if cell size permits.
3. `share_first_birth_30_plus`: share of first births to mothers age 30+.
4. Age-bin shares for first births:
   - `share_first_birth_15_19`
   - `share_first_birth_20_24`
   - `share_first_birth_25_29`
   - `share_first_birth_30_34`
   - `share_first_birth_35_44`
5. `first_birth_rate_15_44`: first births per 1,000 women ages 15--44, if denominators can
   be constructed consistently.

Interpretation note:

1. Mean or median age at first birth is conditional on having a first birth.
2. For that reason, a timing design should ideally report both:
   - conditional timing measures (mean/median age at first birth)
   - extensive-margin timing measures (age-bin first-birth shares or first-birth rates)

## Data requirements for the pivot

To implement maternal age at first birth as a real panel outcome, the fertility source needs:

1. Maternal age at birth.
2. Birth order or parity sufficient to isolate first births.
3. Geography identifiers that can be mapped consistently to county, `cbsa`, or state.
4. Coverage by year that overlaps the housing-policy panel.

Most likely source path:

1. CDC/NCHS natality data with maternal age and live-birth-order information.
2. Practical first route: CDC WONDER natality summary extracts.
3. County-level microdata are restricted in the post-2005 public vital statistics files,
   so the first unrestricted build may need to rely on summary extracts rather than raw
   county microdata.
4. If county detail is too sparse or unavailable, use `cbsa`-year or state-year as the
   first empirical implementation.

## Source decision after local audit

The source decision is now:

1. Main path: modern CDC natality-based build.
2. Archival path only: legacy weighted metro birth-rate files from the old NIMBY workflow.

Reason:

1. The old local fertility files only support aggregate historical birth-rate series.
2. They do not contain maternal-age-at-birth or birth-order variables needed for a
   first-birth timing design.
3. They do not align with the modern nativity/population block in the current panel.

Reference:

1. `notes/build/fertility_source_decision.md`

## Estimation idea under the first-birth-timing pivot

If this pivot is adopted, the baseline dynamic specification becomes:

$$
FirstBirthTiming_{it} = \sum_{k \neq -1}\beta_k\mathbf{1}\{EventTime_{it}=k\}
 + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

where `FirstBirthTiming_{it}` could be mean maternal age at first birth, the share of first
births occurring at ages 30+, or an age-bin first-birth share.

Interpretation:

1. Positive estimates for age-at-first-birth outcomes imply delayed first births.
2. Positive estimates for older-age first-birth shares and negative estimates for younger-age
   first-birth shares imply delayed family formation.
3. Results should still be shown alongside migration/nativity controls because age at first
   birth can also move through compositional changes.

## Working recommendation

Current recommendation for the empirical design:

1. Reframe the project around first-birth timing rather than overall fertility alone.
2. Use mean or median age at first birth only as a supporting summary.
3. Put more weight on:
   - `share_first_birth_30_plus`
   - age-bin first-birth shares
   - first-birth rates, if denominators can be built consistently
4. Keep `gfr_15_44` in the analysis as a secondary outcome and fallback if the timing build
   proves too costly or too sparse.
5. Build the main fertility source from modern natality data rather than extending the
   current historical metro-weighted birth-rate series.
6. Treat the current state-year bridge as a temporary exploratory design while fixing the
   county-versus-metro geography mismatch on the housing side.

## Exact panel design (US)

Desired target design:

1. Unit: county-year or `cbsa`-year.
2. Years: overlap to be determined by the housing-side geography fix.
3. Index key: `fips` or `cbsa`, plus `year`.
4. Compatibility key fields kept for project-02 merges: `metarea`, `metareano`.
5. Fallback aggregation rule: collapse to `cbsa`-year or state-year using summed counts and
   population-weighted rates when direct local matching fails.

Current workable bridge:

1. Unit: state-year.
2. Years with usable rent/unemployment overlap:
   - `2010-2017` for `first_birth_rate_15_44`
   - `2007-2017` for age-at-first-birth timing outcomes
3. Construction:
   - fertility and population aggregated from county data
   - housing and unemployment aggregated from metro-year legacy inputs
4. Reference output:
   - `notes/build/exploratory_state_year_panel.csv`

## Variables: required minimum set

### A. Fertility outcomes

1. `asfr_15_19`, `asfr_20_24`, `asfr_25_29`, `asfr_30_34`, `asfr_35_39`, `asfr_40_44`
2. `gfr_15_44` (general fertility rate)
3. `first_birth_proxy` (share first births, where available)
4. `first_births_total`
5. `first_birth_rate_15_44`
6. `mean_age_first_birth` (candidate headline outcome if natality microdata build is feasible)
7. `median_age_first_birth` (robustness, if cell sizes permit)
8. `share_first_birth_30_plus` and age-bin first-birth shares
9. `completed_fertility_proxy` (cohort proxy from age-specific panels)

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

### Strategy 1 (baseline): reduced-form staggered reform event study

$$
Fertility_{it} = \sum_{k \neq -1}\beta_k\mathbf{1}\{EventTime_{it}=k\}
+ \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

For the current panel this can use `gfr_15_44`.
If the timing pivot is implemented, replace `Fertility_{it}` with a first-birth timing outcome.

Use Sun-Abraham or Callaway-Sant'Anna implementation.

### Strategy 2 (preferred IV path): reform exposure IV for housing outcomes

First stage:

$$
Housing_{it} = \pi (Reform_t \times Exposure_i) + \eta_i + \tau_t + X_{it}'\Lambda + u_{it}
$$

Second stage:

$$
Timing_{it} = \beta \widehat{Housing}_{it} + \eta_i + \tau_t + X_{it}'\Gamma + e_{it}
$$

Candidate `Exposure_i` measures:

1. baseline renter share
2. baseline multifamily share
3. predicted reform bite from pre-period housing stock or zoning composition
4. predetermined local supply inelasticity

Reason:

1. This is the closest IV to the intended local policy channel.
2. It instruments housing supply/cost movements rather than fertility directly.
3. The main threat is that `Exposure_i` may capture other local trends correlated with delayed
   family formation.

### Strategy 3: close-election political IV

First stage:

$$
Supply_{it} = \pi ProHousingWin_{it} + f(Margin_{it}) + \eta_i + \tau_t + u_{it}
$$

Second stage:

$$
Timing_{it} = \beta \widehat{Supply}_{it} + f(Margin_{it}) + \eta_i + \tau_t + e_{it}
$$

Interpretation:

1. Attractive if local political timing is sharp and close elections are available.
2. Main threat is that elections may move other local policies besides housing.

### Strategy 4: geographic-supply interaction IV

Use predetermined supply constraints interacted with broader housing-demand shocks for
housing-cost instrumented effects.

Interpretation:

1. This may generate a stronger first stage.
2. The exclusion restriction is weaker because aggregate demand shocks can affect fertility
   through labor markets and income as well as housing.

## IV recommendation

1. Start with reduced-form event studies before committing to IV.
2. Instrument housing costs or housing supply, not fertility directly.
3. Prefer the reform-exposure IV if reform timing and exposure intensity can be coded well.
4. Use close-election or geographic-supply interaction IV only if the reform-exposure design
   is not feasible or the first stage is too weak.

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
4. Whether to keep `gfr_15_44` as the primary outcome or pivot to maternal age at first birth as the headline empirical target.
5. If the pivot is adopted, whether the first implementation should be county-year, `cbsa`-year, or state-year given likely first-birth cell sparsity.
6. Whether IV work should begin with reform exposure, close-election politics, or supply-elasticity interactions.
