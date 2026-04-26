# Original 5-year joint supply-wedge branch with smoothed politics

This is a side branch for testing whether the hard political sign flip is the
main numerical kink in the transition RE problem.

## Architecture

The architecture is unchanged:

- outer unknown: a low-dimensional wedge path `z_t`
- inner block: clear the housing side conditional on `z_t`
- outer residual: political vote residual on the resulting path

## What changes

The baseline branch uses:

- `sign(V^{dp} - V)`

The smoothed branch uses:

- `response = tanh((V^{dp} - V) / (2 * sigma))`

This keeps the same zero crossing, preserves a centered response in `[-1, 1]`,
and admits a permit-probability interpretation:

- `approval_probability = (1 + response) / 2`

## Entry points

- MATLAB:
  `run_original_5yr_transition_joint_supply_wedge_smoothed_politics.m`
- PowerShell:
  `run_original_5yr_transition_joint_supply_wedge_smoothed_politics.ps1`

## Current evidence

The current smooth branch has taught us something useful:

- smoothing materially helps at short horizons
- `sigma = 0.20` clearly dominated `0.10` at `k = 2`
- the relaxed acceptance rule improves the quality of accepted short-horizon
  points
- the branch stays strong through `k = 4`
- the branch then deteriorates by `k = 6`
- it remains informative through `k = 10`
- the real bad zone is now `k = 12`

So the immediate question is no longer "does smoothing help at all?" It does.
The current question is where the tail failure is coming from and whether the
late-horizon collapse is mainly a tail-seeding / tail-flexibility problem
rather than a short-horizon smoothing problem.

## Active workflow

Use a tail-focused workflow.

### Step 1: keep the completed `sigma = 0.20` ladder as the reference path

Treat the completed `sigma = 0.20` relaxed ladder as the baseline pattern:

- `k = 2`: very good
- `k = 4`: very good
- `k = 6`: materially worse
- `k = 8`: still weak
- `k = 10`: improved relative to `k = 8`
- `k = 12`: bad zone

This is the object every next experiment should be compared against.

### Step 2: stop restarting from the front of the ladder

Do not keep relearning `k = 2` and `k = 4`.

The main branch should now start from the accepted late-horizon state, not from
the short-horizon seed. In practice this means:

- seed from the accepted `k = 10` price path
- seed from the accepted `k = 10` wedge path
- freeze the accepted `k = 10` wedge path when testing `k = 11` and `k = 12`
- run a local tail schedule `k = [11, 12]` for the frozen-prefix diagnostic
- search only the new tail periods, not the already accepted prefix

The reason is concrete: a direct `k = [10, 11, 12]` rerun with a new three-block
basis re-projects the accepted `k = 10` wedge into a different basis and starts
from a worse political residual before the tail is even tested. The frozen-prefix
mode avoids that confound.

### Step 3: make the tail run the main lane

The main local tail run should use:

- `sigma = 0.20`
- `k_schedule = [11, 12]`
- accepted `k = 10` price and wedge seeds
- `prefix_lock_length = 10`
- unlocked tail periods forced into the active political residual
- relaxed acceptance rule
- a tail-only basis, currently `basis_count = 2` over periods `11` and `12`
- more than one outer iteration if RAM allows

This is the main diagnostic now because it directly tests whether the late
collapse is due to poor tail initialization / coarse tail flexibility.

### Step 4: use higher smoothing only as a control

Only after the tail-focused `sigma = 0.20` run lands should we run a bounded
control such as:

- `sigma = 0.40`
- same accepted `k = 10` price and wedge seeds
- same `k_schedule = [10, 11, 12]`

Interpretation:

- if the `0.40` control materially delays or reduces the `k = 12` blow-up,
  then "not smooth enough" is still part of the problem
- if it does not, then the dominant issue is probably the long-horizon fixed
  point or the tail continuation itself

### Step 5: if tail seeding and extra smoothness still fail, switch to homotopy

At that point the next tool is not another full relaunch from `k = 2`. It is a
tail-only continuation device such as:

- a political-strength homotopy at fixed `k = 10`, `11`, or `12`
- or extra outer iterations specifically in the tail run

### Step 6: Hamilton is only for the local tail winner

Hamilton should only be used for the single branch that has already shown it can
survive locally through `k = 12`.

Do not use Hamilton for a wide cross-product of:

- multiple sigmas
- multiple basis counts
- multiple aggressive fallback variants
- restarts from `k = 2`

## Practical queue implied by this workflow

1. Use the accepted `k = 10` price and wedge paths as the tail seed.
2. Run a local `sigma = 0.20` frozen-prefix tail schedule on `k = [11, 12]`.
3. Treat any frozen-prefix run with `reduced_vote_l2 = 0` as invalid unless the
   unlocked tail residual is explicitly active.
4. Run a local `sigma = 0.40` tail-focused control on the same seed and
   schedule.
5. If neither clears `k = 12`, switch to a tail-only homotopy or extra-outer
   iteration branch.
6. Only after that, send the single best local tail branch to Hamilton.
