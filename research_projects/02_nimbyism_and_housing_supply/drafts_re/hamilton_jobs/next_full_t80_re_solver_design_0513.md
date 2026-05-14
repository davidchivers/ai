# Next Full-T80 RE Solver Design If Safeguarded Packet Misses

Purpose: define a genuinely different next attempt only if `17145335` finishes without a usable full-T80 RE row. Do not launch this while `17145335` is live.

## Why A Different Formulation Is Needed

The best full-T80 survivor before the safeguarded packet was `w80_b60hold_bl70`, gap `0.00101892245727956` at outer `4`. That is close enough that the issue is not broad parameter search. The residual pattern is concentrated near early report periods, with additional hidden-tail mismatch. Another blind grid is low value.

## Proposed Method: Black-Box Residual Minimization In Log Prices

Treat the existing annual RE solver as a black-box map:

`F(x) = log(generated_price_path(x) / reference_price)`

where `x = log(guessed_price_path / reference_price)`.

Solve for `r(x) = F(x) - x = 0` by minimizing the report-window residual:

`min_c || W_report r(B c) ||_infinity` or a smoothed `L2` surrogate, with a strict final gate on `max_abs_path_gap`.

The unknowns are low-dimensional coefficients `c`, but the basis must be more flexible than the previous smooth hump basis:

- level and slope,
- early-window spline knots over periods `1-12`,
- mid-window hump/timing terms,
- terminal/tail terms for periods `80-120`,
- optional one or two local residual-correction knots at the largest observed residual periods.

## Algorithm

1. Start from the best full-T80 survivor path, not from no-RE or bounded-horizon rows.
2. Build basis `B` around that path in log-price deviations.
3. Evaluate residual at current coefficients.
4. Estimate a finite-difference Jacobian column-by-column for the small coefficient vector.
5. Take a Levenberg-Marquardt or trust-region Gauss-Newton step:
   `delta = argmin ||W (r + J delta)||_2^2 + lambda ||delta||_2^2`.
6. Accept a step only if the actual evaluated `max_abs_path_gap` falls.
7. If rejected, shrink trust region and increase damping.
8. Stop when `max_abs_path_gap <= 0.001`, `<= 0.0002`, or no accepted improvement remains.

## Defensibility

This is not a relaxation or grid search. It is a direct numerical solve of the RE fixed-point residual, using the same economic model and the same full-T80 target. The only approximation is the finite-dimensional parameterization of the price path; the result is accepted only if the full path residual satisfies the pre-specified gate.

## Guardrails

- Do not relabel bounded-horizon, partial-equilibrium, local-linear, or diagnostic rows as full RE.
- Do not use a survivor figure as headline unless `max_abs_path_gap <= 0.001`.
- Keep no-RE comparator fixed at `nore80bv4_006`.
- Use the existing `build_re_vs_nore_figure_0513.py` only after a usable full-T80 row exists.
- Use C: only for tiny text scripts; all heavy evaluation remains on Hamilton.

## Minimal Packet Shape

If needed, submit a small sequential Hamilton job, not a broad array:

- row A: finite-difference LM from `w80_b60hold_bl70` outer `4`, early-window basis,
- row B: same with extra tail basis,
- row C: same from any best safeguarded survivor if it improves on `w80_b60hold_bl70`.

Each row should write every accepted evaluation to a compact CSV with coefficient vector, actual gap, accepted/rejected flag, and max residual period.

## Prepared Files

- `run_re_lm_0513.m`: sequential black-box LM driver. It evaluates candidate log-price paths by calling the existing full annual RE solver for one outer iteration, estimates finite-difference Jacobian columns in a small path basis, and accepts only actual residual improvements.
- The LM driver also writes a compatible ranking grid at
  `truth/re_lm_0513/lm80_from_w80_b60hold_o4_grid.csv`, so any later success
  can be ranked with `rank_re_wide_0512.py` and passed through the same guarded
  figure builder rather than hand-labeled.
- `bb80relm_0513.slurm`: future fallback wrapper. Do not submit while `bb80safe13`
  / job `17145335` is live. The wrapper ranks the generated LM rows under
  `truth/re_lm_0513/ranked` after MATLAB exits, then runs the guarded closeout
  helper against those ranked rows. If a usable row exists, the closeout helper
  builds the RE-vs-no-RE figure and validation table under `truth/re_lm_0513/figure`.
  If not, it writes `truth/re_lm_0513/full_t80_re_lm_failure_memo_0513.md`.
