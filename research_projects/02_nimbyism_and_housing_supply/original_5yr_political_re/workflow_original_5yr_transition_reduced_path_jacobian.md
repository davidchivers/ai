# Original 5-year reduced-path Jacobian workflow

Separate solver branch for the full `k = 14` political RE transition problem.

## Objective

Replace the exhausted targeted line-search family with a lower-dimensional
outer solver that:

- keeps the existing transition/Bellman block as the truth engine
- parameterizes the log price path with a small basis
- estimates a finite-difference Jacobian on the active political residuals
- applies a damped least-squares step inside a trust region

## Why this branch exists

The current `k = 14` line-search family is stable but inert:

- full horizon does not blow up
- the housing gap stays small
- but the same `max |vote|` point keeps repeating

So this branch targets the actual bottleneck:

- full-horizon outer-update design

## Default workflow

1. Start from the best stable seeded full-horizon path already on disk.
2. Build a reduced basis over the `14`-period log price path.
3. Fix the incumbent active political periods from the current vote path.
4. Estimate a finite-difference Jacobian for those active residuals with respect to the basis coefficients.
5. Solve a damped least-squares step.
6. Apply a trust region and evaluate a small candidate scale ladder.
7. Accept only if the active-set merit improves without materially worsening the full-horizon gap.
8. Iterate a few times, then stop cleanly.

## Initial packet

Recommended first packet:

- basis count `3`
- basis count `4`
- basis count `5`
- all at `k = 14`
- seeded from the stable continuation path
- run in parallel on Hamilton

## Compute split

- Hamilton: reduced-path Jacobian packet
- local machine: keep the legacy line-search lane alive only if RAM stays acceptable

Practical rule:

- if free RAM falls below roughly `1.5 GB`, pause the old local lane before launching any second local MATLAB worker
- otherwise keep the old lane running locally and use Hamilton for the new branch

## Key files

- `run_original_5yr_transition_reduced_path_jacobian.m`
- `run_original_5yr_transition_reduced_path_jacobian.ps1`
- `submit_original_5yr_hamilton_reduced_path_packet.ps1`
