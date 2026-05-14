# Fixed-price local sweep report

Generated: 2026-04-08

## Goal

Refine the fixed-price policy-bridge result after the coarse sweep showed that `2.0` was the only
stable value on the grid `{1.85, 1.90, 1.95, 2.00, 2.05, 2.10, 2.15}`.

The question is whether the stable branch is:

- a true single-point knife-edge at `2.0`, or
- a narrow neighborhood around the benchmark calibration price

## Coarse sweep

Saved outputs:

- `transition_re_policy_bridge_fixed_price_sweep_summary.csv`
- `transition_re_policy_bridge_fixed_price_sweep_paths.csv`
- `transition_re_policy_bridge_fixed_price_sweep_results.mat`
- `transition_re_policy_bridge_fixed_price_report.md`

Read:

- stable:
  - `2.00`
- unstable:
  - `1.85`, `1.90`, `1.95`, `2.05`, `2.10`, `2.15`

So the stable branch is not a broad benchmark neighborhood.

## Local sweep near 2.0

Saved outputs:

- `transition_re_policy_bridge_fixed_price_local_sweep_summary.csv`
- `transition_re_policy_bridge_fixed_price_local_sweep_paths.csv`
- `transition_re_policy_bridge_fixed_price_local_sweep_results.mat`

Read:

- stable:
  - `1.995`
  - `1.998`
  - `1.999`
  - `2.000`
  - `2.001`
  - `2.002`
- unstable:
  - `2.005`

This shows that the stable branch is not literally a single point, but the upper edge is very
tight.

## Lower-edge sweeps

Saved outputs:

- `transition_re_policy_bridge_fixed_price_lower_edge_sweep_summary.csv`
- `transition_re_policy_bridge_fixed_price_lower_edge_sweep_paths.csv`
- `transition_re_policy_bridge_fixed_price_lower_edge_sweep_results.mat`
- `transition_re_policy_bridge_fixed_price_lower_bracket_sweep_summary.csv`
- `transition_re_policy_bridge_fixed_price_lower_bracket_sweep_paths.csv`
- `transition_re_policy_bridge_fixed_price_lower_bracket_sweep_results.mat`

Read:

- stable:
  - `1.970`
  - `1.980`
  - `1.985`
- unstable:
  - `1.960`
  - `1.965`

So the lower edge is looser than the upper edge.

## Current bracket

On the tested grid, the fixed-price bridge is stable for:

- approximately `[1.970, 2.002]`

and unstable at the nearest tested outside points:

- `1.965`
- `2.003`

## Interpretation

- The fixed-price bridge is stronger than a generic clipped-current-price rule.
- It is also not an exact single scalar at `2.0`.
- The best current reduced-form interpretation is a narrow benchmark-price neighborhood centered on
  the calibration price, with a much sharper upper edge than lower edge.
- Inference:
  because this neighborhood is centered on the benchmark price used in the no-politics steady-state
  construction, the result looks closer to a benchmark-anchored policy proxy than to a broadly
  robust expectations rule.
