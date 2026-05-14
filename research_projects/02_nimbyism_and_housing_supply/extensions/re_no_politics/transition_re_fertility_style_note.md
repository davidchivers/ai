# Fertility-style RE transplant note

This note records the direct attempt to port the fertility project's
whole-path fixed-point logic into the NIMBY no-politics RE transition
workspace.

## What was added

- `solve_transition_re_no_politics.m` now supports a separate outer-loop mode:
  - `params.outer_iteration_mode = 'fertility_style'`
- the new mode replaces candidate search with a whole-path relaxation update:
  - guess full future price path
  - run one backward-forward transition pass
  - compute implied full future price path
  - relax the guessed path toward the implied path
- dedicated runner:
  - `run_demographic_forecast_re_no_politics_fertility_style.m`
- bounded-horizon ladder runner:
  - `run_transition_re_no_politics_k_step_ladder.m`
- dedicated output file:
  - `transition_re_no_politics_fertility_style_results.mat`
- bounded-horizon output files:
  - `transition_re_no_politics_k_step_ladder_summary.csv`
  - `transition_re_no_politics_k_step_ladder_results.mat`

## Current tested specification

- warm start: `transition_re_no_politics_results.final_price_path`
- outer-loop mode: `fertility_style`
- relaxation space: `log`
- relaxation weight: `0.10`
- price band: `[0.40, 5.00]`
- max iterations: `25`

## Read from the current run

From `run_demographic_forecast_re_no_politics_fertility_style`:

- iterations completed: `25`
- final max absolute RE price gap: `694.6074`
- final max absolute update: `0.0001`
- final accepted update label: `fertility_style_relaxation`
- final price range: `[0.4000, 5.0000]`
- worst excess-demand period: `t = 4`
- worst excess demand: about `13.3398`

## Read from the bounded-horizon ladder

From `run_transition_re_no_politics_k_step_ladder(3)`:

- `k = 1` solves immediately:
  - final price path: `[2.0003]`
  - residual norm: `0`
  - max gap: `0`
- `k = 2` already reproduces the same instability:
  - final price path: `[2.0003, 5.0000]`
  - implied price path at the same iterate: `[2.0003, 164.3896]`
  - residual norm: about `3.4928`
  - max gap: about `159.3896`
  - worst excess-demand period: `t = 2`
  - worst excess demand: about `3.0610`
- the ladder therefore stops at `k = 2` because the bounded second-period price hits the imposed
  upper limit while the RE gap remains large

## Interpretation

- The direct fertility-style transplant does **not** converge cleanly in the
  NIMBY transition solver.
- Starting from `k = 1` and extending the horizon does not rescue the method:
  the one-period problem is trivial, but the failure appears as soon as the
  model has to price one step ahead.
- Without path bounds, the relaxed path can wander into absurd terminal-price
  regions before drifting back.
- With fertility-style bounds added, the path instead saturates at the imposed
  floor/ceiling, so the run stops because updates become tiny, not because the
  RE fixed point is solved.
- This is useful evidence: the old NIMBY bottleneck is not just a bad local
  candidate-search rule. The full-path fixed-point map itself is much harsher
  here than in the fertility annual branch.

## Practical implication

- Keep this branch as a separate diagnostic, not as the new default RE solver.
- Keep the k-step ladder with it: the ladder is useful because it localizes the
  failure to the move from `k = 1` to `k = 2`.
- If we want a cleaner NIMBY RE object using the fertility intuition, the next
  step should be a **simplified bridge object** rather than another direct
  transplant of the full household transition map.
