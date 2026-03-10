# Code-table consistency audit

## Purpose

This note checks the active benchmark self-employment code against the paper's
current calibration-table content and records the highest-value presentation
fixes for the next editor-style discussion.

Benchmark used here:

- active self-employment benchmark path: `case 147`
- code file:
  `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113_self_employment.cpp`
- current cleaner paper fragment:
  `drafts/tables/calibration_parameters_self_employment.tex`
- stale inline paper block still live in the main draft:
  `drafts/necessity_entrepreneurship.tex`

## Confirmed benchmark values in code

The active benchmark values for `case 147` are set in the `case 147` block at
lines `3179` to `3212` of the canonical self-employment source.

Core benchmark objects confirmed in code:

- `bar_m = 0.9`
- `mu = 0.68`
- `kappa = 0.035`
- `lowerincome_b = 0.4`
- `underline_c = 0.3`
- `self_employment_hiring_fixed_cost = 0.25`
- `entrepreneur_capital_loss_share = 0.25`
- `edu_rho_entr = {0.168, 0.150, 0.144}`

Additional global benchmark objects confirmed in code:

- `a_l = 0.01` at line `2709`
- `tau_pi = 0` at line `2757`
- `psi = 0` at line `2758`
- baseline entrepreneur closure grid:
  `base_edu_rho_entr = {0.168, 0.150, 0.144}` at line `2706`

## Current paper state

The standalone fragment in `drafts/tables/calibration_parameters_self_employment.tex`
is mostly aligned with the active benchmark.

The main problem is the older inline calibration table still embedded in
`drafts/necessity_entrepreneurship.tex` around lines `636` to `659`. That block
still contains stale values and stale labels from the older benchmark.

## Main discrepancies

### D1. Matching efficiency

- Paper inline table: `bar_m = 0.8` at draft line `649`
- Code benchmark: `bar_m = 0.9` at source line `3179`
- Assessment: substantive mismatch
- Recommendation: report `0.9` everywhere the active benchmark is described

### D2. Matching elasticity

- Paper inline table: `mu = [0.5,0.7]` at draft line `650`
- Code benchmark: `mu = 0.68` at source line `3180`
- Assessment: the paper currently presents a literature range rather than the
  actual benchmark value
- Recommendation: use `0.68` in the main calibration table and move the range
  discussion to the source column or surrounding text if desired

### D3. Hiring or search cost

- Paper inline table: `kappa = [0.03,0.045] * w` at draft line `651`
- Code benchmark: `kappa = 0.035` at source line `3181`
- Assessment: same issue as `mu`; current paper row reports a range instead of
  the benchmark object
- Recommendation: report `0.035` as the benchmark value and describe the
  literature range only as discipline

### D4. Tax rows are stale as calibration inputs

- Paper inline table:
  - `tau_pi = 0` at line `653`
  - `tau_y = 0.151` at line `654`
  - `lambda_p` blank and "determined in equm." at line `655`
- Code benchmark:
  - `tau_pi = 0` globally at line `2757`
  - `tau_y` is not a fixed benchmark calibration row in the active
    self-employment benchmark; it is solved endogenously in endogenous-tax runs
    or fixed only in separate robustness exercises
- Assessment: the paper currently mixes fixed parameters with equilibrium fiscal
  outcomes
- Recommendation:
  - drop `tau_y` and `lambda_p` from the benchmark calibration table
  - keep `tau_pi` only if it is needed for model transparency, otherwise drop it
    from the main table as well

### D5. UI benefit wording should match the code object

- Paper inline table: `b = 0.40 * w` with "social security benefits" at line
  `656`
- Code benchmark: `lowerincome_b = 0.4` at source line `3182`
- Assessment: conceptually close, but the paper label is loose and can be read
  as a level rather than a replacement rate
- Recommendation: write this as an unemployment-insurance replacement rate of
  `0.40`

### D6. `psi` row is technically correct but presentation-poor

- Paper inline table: `psi = 0`, description "Share" at line `657`
- Code benchmark: `psi = 0` at source line `2758`
- Assessment: value matches, label does not
- Recommendation:
  - if kept, describe it as the employer labor-tax incidence share or the
    employer share of the payroll wedge
  - for the main paper table, dropping the row is cleaner because the benchmark
    sets it to zero and it is not an active quantitative margin in the current
    experiments

### D7. Credit-spread row is stale

- Paper inline table: `Delta = 0`, description "Credit spread" at line `658`
- Code benchmark: no active benchmark credit-spread object is being calibrated in
  the `case 147` self-employment block
- Assessment: stale legacy row
- Recommendation: drop from the benchmark calibration table

### D8. Borrowing-constraint row uses the wrong object

- Paper inline table: `bar_a = 0`, description "Borrowing constraint" at line
  `659`
- Code benchmark: asset lower bound `a_l = 0.01` at source line `2709`
- Assessment: substantive mismatch in notation and value
- Recommendation:
  - replace the row with `a_l = 0.01`
  - describe it as the minimum asset grid point or borrowing-limit floor,
    depending on how aggressively the paper wants to interpret the grid lower
    bound as a borrowing constraint

### D9. Entrepreneur closure-rate wording can be tightened

- Cleaner standalone fragment: `rho_e(h) = {0.168, 0.150, 0.144}` at table line
  `30`
- Code benchmark: same values in `base_edu_rho_entr` and `case 147`
- Assessment: the values match
- Recommendation: use the user's preferred wording:
  "closure rate by `h`, scaled to mean `0.15`"
  and keep the Grashuis source note as the discipline for the education gradient

### D10. Self-employment extension rows should be the authoritative benchmark rows

- Standalone fragment currently reports:
  - `lambda_k = 0.25` at line `31`
  - `f_hire = 0.25` at line `34`
- Code benchmark matches:
  - `entrepreneur_capital_loss_share = 0.25` at source line `3203`
  - `self_employment_hiring_fixed_cost = 0.25` at source line `3198`
- Assessment: confirmed match
- Recommendation: keep these rows and make the standalone fragment, not the
  inline legacy block, the authoritative calibration table

## Bottom-line table recommendation

The benchmark main-text calibration table should show benchmark values, not a
mixture of benchmark values, literature ranges, and equilibrium fiscal outcomes.

Concretely:

- keep `bar_m = 0.9`, `mu = 0.68`, `kappa = 0.035`
- keep `b = 0.40`, `underline_c = 0.30`
- keep `rho_e(h)`, `lambda_k = 0.25`, and `f_hire = 0.25`
- replace the borrowing row with `a_l = 0.01`
- drop the stale `Delta` row
- drop the corporation-tax / income-tax rows from the benchmark calibration table
- either drop `psi` or relabel it precisely

## Fixed-tax robustness check completed today

Matched fixed-tax runs are now available for the benchmark `case 147` UI ladder
using baseline `tau_y = 0.00727962`.

Logs:

- `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_se147_fixedtax_ui040_caploss025_fhire025_m40_20260310_153848.log`
- `calibration/self_employment_baseline/runtime/data/output/case_1/run_ui_005_se147_fixedtax_ui005_caploss025_fhire025_m40_20260310_154608.log`
- `calibration/self_employment_baseline/runtime/data/output/case_1/run_ui_000_se147_fixedtax_ui000_caploss025_fhire025_m40_20260310_161010.log`

Headline outcomes:

| UI replacement | Entrepreneur share | Self-employed share among entrepreneurs | Employer share among entrepreneurs | Avg entrepreneur labor `n` | Avg entrepreneur capital `k` |
| --- | ---: | ---: | ---: | ---: | ---: |
| `0.40` | `0.15822` | `0.59518` | `0.40482` | `6.47018` | `103.789` |
| `0.05` | `0.29916` | `0.71159` | `0.28841` | `3.09455` | `59.5562` |
| `0.00` | `0.34740` | `0.75622` | `0.24378` | `2.45598` | `51.2930` |

Inference: the benchmark UI result survives under fixed tax. Lower UI still
raises entrepreneurship and shifts composition toward smaller self-employment,
so the benchmark result is not only an endogenous-fiscal-closure artifact.

## AER-style additions worth showing next

These are the highest-value additions for the next project discussion.

1. A matched endogenous-tax versus fixed-tax UI ladder table.
   Show the same rows for both closures so the insurance channel and the fiscal
   channel can be separated cleanly.
2. A compact three-panel figure for the UI ladder.
   Panel A: entrepreneur share.
   Panel B: self-employed share among entrepreneurs.
   Panel C: average entrepreneur size or capital.
3. A short fiscal-closure appendix figure.
   Plot endogenous `tau_y` in the endogenous-tax runs against the lump-sum
   transfer in the fixed-tax runs, using the same `UI = 0.40 / 0.05 / 0.00`
   ladder.
4. A benchmark-composition figure by education.
   Show whether low UI disproportionately raises self-employment for low-
   education households, because that is close to the outside-option mechanism.
5. A wealth-bin appendix table or figure.
   Report entrepreneurship, employer share, and entrepreneur size by asset bins.
   This is the most natural next robustness object if an editor pushes on the
   borrowing-constraint interpretation.

## Editorial judgment

The paper is close to having the right benchmark quantitative architecture, but
the live inline calibration block is still not publication-safe.

The main fix is not a new model run. It is:

- make the standalone self-employment calibration fragment authoritative,
- remove the stale inline table content from the main draft,
- then add one clean fixed-tax versus endogenous-tax comparison object so the
  UI mechanism is transparent.
