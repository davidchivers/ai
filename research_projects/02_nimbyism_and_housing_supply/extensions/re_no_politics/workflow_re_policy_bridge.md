# Policy bridge workflow

This is the current best simplification path for the NIMBY RE transition after the direct
fertility-style transplant, the `k = 1 -> 2` ladder failure, and the terminal-tail bridge check.

## Goal

Replace the explosive full backward-looking within-path policy map with a cheaper bridge object
that still preserves the broad housing-market accounting.

The purpose is to learn:

- whether the original `k = 2` blow-up is mainly caused by forward-looking policy feedback
- how far a simpler policy bridge survives as the horizon grows
- where that bridge fails if it does not survive the whole path

## Main idea

Keep the bounded fertility-style price update, but replace the full backward transition solve with
steady-state policy rules.

Two bridge variants are useful at `k = 2`:

- `steady_state_by_period_price`: use steady-state policies at each current-period price
- `steady_state_fixed_price_2_0`: use steady-state policies fixed at price `2.0`

These can be compared against:

- `full_backward_fixed_tail_2_0`: the dynamic benchmark with the terminal tail already fixed at
  `2.0`

## Runners

Main MATLAB runners:

- `run_transition_re_k2_policy_bridge_followup.m`
- `run_transition_re_k_step_policy_bridge_ladder.m`

PowerShell wrappers:

- `run_transition_re_k2_policy_bridge_followup.ps1`
- `run_transition_re_k_step_policy_bridge_ladder.ps1`
- `run_transition_re_policy_bridge_workflow.ps1`

Report writer:

- `write_transition_re_policy_bridge_report.ps1`

## Fixed setup

- use the same bounded fertility-style outer update:
  - log-space relaxation
  - weight `0.10`
  - price band `[0.40, 5.00]`
  - `max_iter = 25`
- fix the terminal tail at price `2.0`
- first solve `k = 1` to anchor the initial price
- use that anchored period-1 price to warm-start the longer bridge cases

## Outputs

- `transition_re_k2_policy_bridge_summary.csv`
- `transition_re_k2_policy_bridge_results.mat`
- `transition_re_k_step_policy_bridge_summary.csv`
- `transition_re_k_step_policy_bridge_results.mat`
- `transition_re_policy_bridge_report.md`
- `workflow_logs/transition_re_k2_policy_bridge_stdout.log`
- `workflow_logs/transition_re_k_step_policy_bridge_stdout.log`

## Current read

- at `k = 2`, the policy bridge changes the problem dramatically:
  - dynamic benchmark max gap is about `157.95`
  - policy-bridge max gap is about `0.00653`
- on the by-period-price bridge ladder:
  - `k = 2` remains clean
  - `k = 3` is still numerically reasonable
  - the bridge breaks again by `k = 4`
- on the fixed-price-`2.0` bridge ladder:
  - the branch stays numerically well behaved through the full `k = 9` horizon
  - final max gap is about `0.00162`
  - final price range is about `[1.9085, 2.1682]`

## Stopping rule

Do not turn this into another generic tuning campaign.

- run the `k = 2` policy bridge comparison once
- run the bridge ladder to a short bounded horizon
- if the ladder stays stable only through a few periods, stop and use that as the new diagnostic
  fact

## How to read the result

If the policy bridge stabilizes `k = 2`, then the main explosive object in the original transplant
is the forward-looking within-path policy map.

If the bridge later fails at `k = 4` or beyond, then the next simplification question becomes:

- what extra dynamic interaction enters between `k = 3` and `k = 4`?

The fixed-price ladder sharpens that interpretation further:

- letting the within-path steady-state policy map react to low current prices is what reintroduces
  the blow-up
- freezing that policy map at `2.0` is enough to keep the whole horizon stable

That is a much narrower and more useful target than the original full-horizon transplant problem.
