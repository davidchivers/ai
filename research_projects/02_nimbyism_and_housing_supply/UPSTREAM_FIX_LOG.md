# UPSTREAM_FIX_LOG
Project: 02_Nimbyism_and_Housing_Supply

Use this log for any code/math fixes that should be considered by downstream projects.

## Template
- Date:
- Area/File:
- Issue type: (code bug / math derivation / calibration / notation)
- Fix summary:
- Impact on results:
- Should port to 03_Fertility_and_Housing_Supply?: Yes/No
- Porting notes:

## Logged issues

- Date: 2026-03-16
- Area/File: `code/steadystate/SolveSS_iter.m` (same pattern also appears in related steady-state copies)
- Issue type: code bug
- Fix summary: In the younger-age non-perturbation block, the rent formula still divides by
  `r_price * d_a_price`, which leaks the price-perturbation scaling into the baseline branch.
  The no-politics extension copy corrects this locally by using `r_price` in the non-perturbation
  branch.
- Impact on results: Not yet quantified. This may distort rental consumption and value comparisons
  in baseline steady-state solves for non-terminal ages.
- Should port to 03_Fertility_and_Housing_Supply?: Yes
- Porting notes: Review all solver variants that retain the same pattern before applying an
  upstream fix, then re-run the steady-state objects used by project 03.
