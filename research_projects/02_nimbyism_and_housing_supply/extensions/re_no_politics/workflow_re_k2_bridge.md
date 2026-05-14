# k=2 bridge workflow

This is the bounded workflow for the next NIMBY RE simplification step after the direct
fertility-style transplant and the `k = 1 -> 2` ladder failure.

## Goal

Isolate whether the first nontrivial RE failure at `k = 2` is mainly being driven by the terminal
steady-state continuation object.

The purpose is diagnostic, not calibration. We want to learn:

- whether a simpler terminal bridge materially shrinks the second-period implied price explosion
- whether the `k = 2` failure survives even after the tail is simplified
- whether the next simplification should target the terminal block or something earlier in the map

## Main idea

Keep the bounded fertility-style solve fixed and change only how the terminal steady-state reference
is chosen.

Current default:

- use the period-2 price to construct the terminal steady-state continuation object

Bridge variants:

- `path_end_price_tail`: current default
- `initial_path_price_tail`: use the period-1 price for the terminal reference
- `fixed_price_2_0_tail`: use the baseline price `2.0` for the terminal reference

This does not yet remove the full household solve. It is the first low-risk bridge object that
tests whether the terminal tail is the main source of instability.

## Runner

Main MATLAB runner:

- `run_transition_re_k2_bridge_followup.m`

PowerShell wrapper:

- `run_transition_re_k2_bridge_followup.ps1`

Workflow wrapper:

- `run_transition_re_k2_bridge_workflow.ps1`

Report writer:

- `write_transition_re_k2_bridge_report.ps1`

## Fixed setup

- solve `k = 1` first to get the anchored period-1 price
- use that period-1 price plus the old NIMBY path's second-period value as the `k = 2` warm start
- hold the bounded fertility-style settings fixed:
  - log-space relaxation
  - weight `0.10`
  - price band `[0.40, 5.00]`
  - `max_iter = 25`

## Outputs

- `transition_re_k2_bridge_summary.csv`
- `transition_re_k2_bridge_results.mat`
- `transition_re_k2_bridge_report.md`
- `workflow_logs/transition_re_k2_bridge_stdout.log`
- `workflow_logs/transition_re_k2_bridge_stderr.log`
- `workflow_logs/transition_re_k2_bridge_workflow.log`

The summary records for each case:

- final and implied two-period price paths
- second-period housing demand, supply, and excess demand
- residual norm and max gap
- terminal reference price actually used
- runtime

## Stopping rule

Run this workflow once.

- if one bridge case materially lowers the second-period implied price and gap, use that case as
  the base for the next reduced-form bridge
- if all bridge cases remain explosive, stop and conclude that tail simplification alone is not the
  main fix

Do not broaden this into another generic tuning grid.

## How to read the result

If the best bridge case still has a huge second-period implied price and excess demand, the problem
is not just the terminal tail. The next simplification should then target the within-path mapping
itself, not just the endpoint.

If a fixed-tail case sharply reduces the second-period blow-up, then the terminal continuation
object is a meaningful part of the instability and deserves a more explicit reduced-form treatment.
