# Reduced-form RE workflow

This workflow is the new reduced-form-first NIMBY RE rung, built to mirror the fertility sequence more closely than the structural household solver does.

## Goal

- start from a smooth aggregate operator rather than the full household-policy map
- check whether bounded RE is numerically tame on that reduced-form object
- use that as the first NIMBY rung before climbing back toward the structural transition problem

## Reduced-form operator

- benchmark source:
  `transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.mat`
- operator form:
  current log price is a linear function of
  - the young-share demographic pressure index (`share 25-44` gap from 2010)
  - the next-period log price gap relative to the benchmark price `2.0`
- tail closure:
  flat benchmark tail at price `2.0`
- admissible price box during iteration:
  `[1.75, 2.25]`

## Files

- `build_reduced_form_price_operator_from_policy_bridge.m`
- `solve_reduced_form_price_path.m`
- `run_transition_re_reduced_form_one_step.m`
- `run_transition_re_reduced_form_k_step_ladder.m`
- `run_transition_re_reduced_form_one_step.ps1`
- `run_transition_re_reduced_form_k_step_ladder.ps1`
- `run_transition_re_reduced_form_workflow.ps1`
- `transition_re_reduced_form_report.md`

## Current read

- one-step reduced-form RE is numerically tame:
  solved `2011` price about `2.0297`
- the finite-horizon reduced-form ladder is stable through the full forward horizon `k = 8`
  for all tested RE weights `{0.25, 0.50, 0.75, 1.00, 1.25}`
- at `k = 8`, the solved `2011` price ranges roughly from `2.0329` to `2.0557`
  while the solved `2018` price stays close to `2.0049`

## Interpretation

- once the harsh within-path household-policy feedback is replaced by a smooth aggregate operator,
  the bounded RE problem becomes easy
- that means the old numerical difficulty was not coming from the demographic path alone
- it was coming from the structural household-policy feedback block
