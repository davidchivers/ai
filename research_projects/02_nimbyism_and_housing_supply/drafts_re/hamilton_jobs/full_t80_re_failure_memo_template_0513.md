# Full T80 RE Failure Memo Template

Use this only if the safeguarded packet `17145335` finishes without a usable full-T80 RE row.

## Bottom Line

We attempted a full 80-year rational-expectations transition for the published baby-boom model. The strongest full-T80 candidate before the final safeguarded polish was `w80_b60hold_bl70`, with `max_abs_path_gap = 0.00101892245727956` at outer `4`, just above the `0.001` usable threshold and far above the `0.0002` paper-safe threshold. If `17145335` does not clear `0.001`, the conclusion is that the current full-T80 nonlinear RE formulation did not deliver a defensible headline figure.

## What Was Tried

- Old baseline and direct full-T80 attempts.
- T20/T40/T60 continuation into T80.
- Broad T80 grids, bridge/polish packets, and failsafe residual-focus packets.
- Alternative routes: bounded-horizon expectations, projected/basis paths, local-linear diagnostics, partial-equilibrium diagnostics, secular and official-projection RE.
- Stationary old-model RE benchmarks.
- Final distinct attempt: safeguarded log-price fixed-point/homotopy polish from the best full-T80 survivor, with best-anchor reset and capped trust-region updates.

## What Can Still Be Used

- Bounded 40-year expectations row `bound40_baby_rss_l4` is usable but is not full T80 perfect-foresight RE.
- Stationary old-model RE results at pass-through `0.006` suggest economically tiny steady-state price effects, but they are not transition RE.
- The no-RE T80 comparator remains valid for the original paper route.
- The diagnostic RE-vs-no-RE figure for `w80_b60hold_bl70` can be used internally to understand the shape, but must not be presented as a solved full-RE result unless explicitly labeled as a survivor/diagnostic.

## Prepared Next Solver, Not Submitted

If the user wants one more full-RE attempt after this closeout, the next genuinely different route is already prepared but not submitted:

- `run_re_lm_0513.m`
- `bb80relm_0513.slurm`
- `next_full_t80_re_solver_design_0513.md`

This is a sequential black-box LM/Gauss-Newton residual-minimization driver around the best full-T80 survivor. It should only be submitted after an explicit checkpoint decision, because it is computationally expensive and is not another broad grid.

## Paper-Safe Wording If No Full T80 Row Clears

> We explored full perfect-foresight rational-expectations transition paths for the 80-year baby-boom experiment. Across continuation, bridge, basis-projection, residual-focus, and safeguarded fixed-point searches, the best full-T80 candidates remained just above our pre-specified numerical acceptance threshold. We therefore do not report a full-T80 RE transition figure as a headline result. Instead, we treat bounded-horizon expectations and stationary RE calculations as robustness/mechanism exercises, distinct from the original no-RE transition.

## Final Evidence To Fill In

- Final safeguarded ranked file: `truth/re_safeguard_0513/re_wide_ranked_0512.csv`
- Best final row:
- Best final gap:
- Best final verdict:
- Timed-out or failed rows:
- Final decision:
