# 05 research plan

Last updated: 2026-03-01
Status: active (post MATLAB baby-boom prototype rerun)

## A. Chosen question and estimand

Question:
Does a temporary baby-boom cohort shock tighten future local housing politics and reduce
subsequent fertility through higher housing costs?

Primary estimand (empirical phase):
Dynamic treatment effect of housing-supply policy tightness on fertility rates:

$$
\beta_k \text{ in } Fertility_{it} = \sum_{k \neq -1}\beta_k 1\{EventTime_{it}=k\} + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
$$

with explicit controls or decomposition for migration/immigration cohort flows.

## B. Model choice

Chosen baseline model:

1. Keep project-02 political housing-supply mechanism.
2. Add endogenous fertility and lagged baby-boom-to-NIMBY cohort channel.
3. Use temporary baby-boom shocks as the main dynamic experiment.

Reason:
This design matches the project-02 experimental logic while adding one new channel needed
for project 03.

## C. Empirical strategy

Chosen strategy sequence:

1. Build a US panel of fertility outcomes + housing supply/cost + policy timing.
2. Estimate event-study and DiD specifications with migration/immigration adjustments.
3. Compare estimated dynamic path to model impulse-response shape (not level matching yet).

## D. Data decision and fallback

Primary target data stack:

1. US fertility outcomes by age and geography (county/MSA-year).
2. Housing cost/supply measures (prices/rents/permits/new units; policy timing where available).
3. Migration and immigration flows for cohort accounting.

Immigration handling requirement:

1. Construct native-born and foreign-born cohort shares separately where possible.
2. Decompose fertility changes into within-group fertility vs population-composition shifts.
3. Include immigration-flow controls in baseline event-study specification.

Fallback:
If full county-level harmonization is slow, start with state-year panel for proof-of-concept.

## E. Next 3 tasks

1. Build `notes/04_empirical_notes.md` section defining exact fertility outcome(s) and preferred
   geography-time unit, including immigration decomposition fields.
2. Create a data inventory table in `notes/02_literature_and_synthesis.md` with source, coverage,
   key variables, and known missingness for fertility, housing, and immigration series.
3. Add one replication script scaffold in `code/` for assembling a first panel skeleton
   (fertility + housing + immigration placeholders) and document assumptions.
