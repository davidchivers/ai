# 05 research plan

Last updated: 2026-03-13
Status: active empirical build; live natality panel and state-year bridge are in place, legacy
source imports are now portable across `D:` and Dropbox roots, and the refreshed structural
comparison remains diagnostic rather than a reason to delay empirical cleanup

## A. Chosen question and estimand

Question:
Do housing supply restrictions and higher housing costs delay family formation, as measured
by the timing of first births?

Working empirical target:

1. Lead outcome family: first-birth timing.
2. Supporting outcomes:
   - age-specific first-birth shares
   - first-birth rates where denominators can be built consistently
   - modern `gfr_15_44` as a secondary robustness outcome
3. Historical metro `gfr_15_44` is no longer the main panel choice; it is only a provisional
   reduced-form comparison sample.

Primary estimand (working empirical phase):
Dynamic treatment effect of housing-policy/supply shocks on first-birth timing outcomes:

$$
\beta_k \text{ in } Y_{it} = \sum_{k \neq -1}\beta_k 1\{EventTime_{it}=k\} + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

where `Y_{it}` is a first-birth timing measure such as:

1. mean maternal age at first birth
2. share of first births to mothers age 30+
3. age-bin first-birth shares

Interpretation:

1. Positive effects on older-age first-birth outcomes imply delayed family formation.
2. Mean age at first birth is informative but conditional, so it should not stand alone.

## B. Model choice

Current stance:

1. Keep the project-02 political housing-supply model in the background as motivation.
2. Do not make further model integration the binding constraint for the empirical paper design.
3. Treat the refreshed reduced-form versus old-proxy versus structural-FOC comparison as a
   diagnostic note, and wait for updated MATLAB files before revisiting deeper model-code
   alignment.

Reason:
The immediate value is in establishing a credible empirical design for delay in family
formation. The model remains useful for mechanism and framing, but it is not the current
work bottleneck.

## C. Empirical strategy

Chosen strategy sequence:

1. Build a timing-focused outcome panel from natality data with maternal age and first-birth
   identification.
2. Estimate reduced-form event-study and DiD specifications around housing-policy/supply
   shocks.
3. Estimate first stages for housing supply/cost outcomes.
4. Move to IV only if the first stage is credible and the exclusion restriction is
   defensible.

Baseline reduced-form equation:

$$
Timing_{it} = \sum_{k \neq -1}\beta_k 1\{EventTime_{it}=k\} + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

with migration/nativity controls and composition adjustments where feasible.

## D. IV menu

Preferred IV direction:
Instrument housing costs or housing supply, not fertility directly.

Option 1: housing reform exposure IV

1. Instrument: `reform_t x exposure_i`
2. Candidate `exposure_i` variables:
   - baseline renter share
   - baseline multifamily share
   - predicted reform bite from pre-period zoning/supply composition
   - predetermined supply inelasticity
3. Use: instrument `real_rent_index`, `price_to_income`, or permit growth.
4. Strength: closest match to the policy channel.
5. Main threat: exposure may proxy for other local trends.

Option 2: supply elasticity interaction IV

1. Instrument: aggregate housing-demand shock_t x local supply elasticity_i
2. Use: instrument local housing costs.
3. Strength: likely stronger first stage.
4. Main threat: national-demand shocks can affect fertility through labor markets or income.

Option 3: close-election political IV

1. Instrument: narrow pro-housing political wins.
2. Use: instrument later permits, housing supply, or housing costs.
3. Strength: attractive if local political timing is sharp and plausibly quasi-random.
4. Main threat: election outcomes may shift other local policies that also affect fertility.

Working recommendation:

1. Start with reduced-form event studies.
2. Prioritize Option 1 if reform timing and local exposure can be coded cleanly.
3. Treat Options 2 and 3 as backups unless the data make one clearly stronger.

## E. Data decision and fallback

Primary target data stack:

1. Natality data with maternal age and birth-order/parity information.
2. Housing cost/supply measures:
   - rents
   - house prices
   - permits/new units
   - policy timing where available
3. Migration and immigration flows for cohort accounting.

Preferred geography-time:

1. End goal: county-year or `cbsa`-year.
2. Current workable bridge: state-year.
3. Reason: fertility now exists at county-year, but the legacy housing/control files are
   metro-year and do not yet align locally.

Locked source decision:

1. Main path: modern natality-based fertility build.
2. Do not extend the old historical metro birth-rate series into the baseline design.
3. Use the historical metro sample only for sign checks already documented in
   `notes/build/exploratory_regression_summary.md`.

Immigration handling requirement:

1. Keep nativity-composition controls in the baseline design.
2. Report whether estimated timing shifts survive composition adjustment.

Fallback:
If first-birth timing cannot be built cleanly at local level, retain `gfr_15_44` as the
main outcome for the first pass and keep first-birth timing as a second-stage extension.

## F. Next 3 tasks

1. Fix geography alignment on the housing side:
   - county-to-metro/CBSA crosswalk, or
   - a replacement county/CBSA housing panel
2. Use the temporary state-year bridge to expand reduced-form timing regressions:
   - weights
   - alternative timing outcomes
   - specification checks
3. Decide whether the paper temporarily proceeds with state-year evidence or waits for the
   cleaner local-geometry merge before locking the baseline design
