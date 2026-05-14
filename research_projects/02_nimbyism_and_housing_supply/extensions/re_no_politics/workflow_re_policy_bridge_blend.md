# Policy-bridge blend workflow

This workflow fills the missing rung between the stable fixed-price policy bridge and the unstable by-period-price policy bridge.

## Goal

- start from the stable fixed benchmark policy-reference path at `2.0`
- gradually reintroduce current-price feedback
- locate the blend frontier where the policy bridge stops being numerically well behaved

## Blend object

- policy-reference path:
  `(1 - alpha) * 2.0 + alpha * current_price_path`
- `alpha = 0`:
  fixed-price benchmark
- `alpha = 1`:
  pure by-period-price bridge

## Files

- `run_transition_re_policy_bridge_blend_sweep.m`
- `run_transition_re_policy_bridge_blend_sweep.ps1`
- `run_transition_re_policy_bridge_blend_ladder.m`
- `run_transition_re_policy_bridge_blend_ladder.ps1`
- `workflow_re_policy_bridge_blend_ladder.md`
- `transition_re_policy_bridge_blend_report.md`

## Current read

- refined full-horizon sweep:
  - `alpha = 0.00`, `0.01`, `0.015` are stable
  - `alpha = 0.02` is the first unstable tested full-horizon case
  - by `alpha = 0.05`, the full-horizon case is materially worse again
- matched-budget `k`-ladder:
  - `alpha = 1.00` is stable through `k = 3` and fails at `k = 4`
  - `alpha = 0.05` is stable through `k = 4`
  - `alpha = 0.02` is stable through at least `k = 5`
  - `alpha = 0.00`, `0.01`, `0.015` stay stable through the full ladder `k = 9`
