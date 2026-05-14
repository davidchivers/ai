# Policy bridge floor sweep workflow

This follow-up starts from the current policy-bridge result and asks a narrower question than the
original fertility-style transplant:

- can the within-path steady-state policy bridge react to current prices at all
- or does it only work when that policy map is anchored away from the low-price tail

## Goal

Treat the fixed-price bridge as an anchored-expectations hypothesis and test how much of that
anchor can be relaxed.

The specific question is:

- what is the lowest floor on the by-period policy-reference path that still keeps the full
  2010-2018 horizon numerically well behaved

## Main idea

Keep the same bounded fertility-style outer update and the same fixed terminal tail at `2.0`.

Then compare:

- `steady_state_fixed_price_2_0_benchmark`
- `steady_state_by_period_price_unclipped`
- `steady_state_by_period_price_floor_f`
  for a grid of floor values `f`

The only new seam is that the within-path policy-reference prices can be clipped from below before
the steady-state policy objects are loaded.

## Runner

- MATLAB runner:
  `run_transition_re_policy_bridge_floor_sweep.m`
- PowerShell runner:
  `run_transition_re_policy_bridge_floor_sweep.ps1`
- PowerShell workflow wrapper:
  `run_transition_re_policy_bridge_floor_workflow.ps1`
- Report writer:
  `write_transition_re_policy_bridge_floor_report.ps1`

## Fixed setup

- full 2010-2018 horizon
- fertility-style outer loop
- log-space relaxation weight `0.10`
- price band `[0.40, 5.00]`
- fixed terminal tail at `2.0`
- warm start from the full-horizon fixed-price-`2.0` bridge path when available

## Outputs

- `transition_re_policy_bridge_floor_sweep_summary.csv`
- `transition_re_policy_bridge_floor_sweep_paths.csv`
- `transition_re_policy_bridge_floor_sweep_results.mat`
- `transition_re_policy_bridge_floor_report.md`

## How to read the result

If an unclipped by-period bridge fails but a modest floor restores stability, then the fixed-price
bridge is best interpreted as a reduced-form expectations object with a benchmark-price anchor,
not as a purely ad hoc numerical patch.

The key object then becomes:

- households update with current prices within a reasonable band
- but the low-price tail is not allowed to drag the policy map into the explosive region
