# Policy-bridge k = 4 edge robustness report

## Goal

Check whether the current retry-aware local `k = 4` alpha edge is mainly:

- a consequence of the current `max_abs_gap < 0.05` filter, or
- a consequence of the old `25 + 25` retry-aware iteration budget.

## Runner

- Diagnostic runner:
  `run_transition_re_policy_bridge_k4_edge_robustness.m`
- Canonical outputs:
  - `transition_re_policy_bridge_k4_edge_robustness_summary.csv`
  - `transition_re_policy_bridge_k4_edge_robustness_attempts.csv`

## Boundary points tested

- stable-side edge point from the current retry-aware bracket:
  `alpha = 0.190899658203125`
- unstable-side edge point from the current retry-aware bracket:
  `alpha = 0.19090576171875`

For each point, compare:

- existing retry-aware classification with `25 + 25` iterations
- longer retry-aware classification with `50 + 50` iterations

## Main result

- Stable-side point `alpha = 0.190899658203125`:
  - existing `25 + 25` retry-aware packet:
    stable
    max gap about `0.03190`
    requires the second attempt
  - longer `50 + 50` retry-aware packet:
    still stable
    max gap remains about `0.03190`
    now reaches the same final path in the first `50`-iteration attempt without retry
- Unstable-side point `alpha = 0.19090576171875`:
  - existing `25 + 25` retry-aware packet:
    unstable
    max gap about `0.79470`
  - longer `50 + 50` retry-aware packet:
    still unstable after retry
    max gap improves to about `0.26158`
    retry path hits the upper price bound `5.0`

## Filter sensitivity

Using the final packets from the robustness runner:

- Stable-side `alpha = 0.190899658203125`:
  - passes `max_abs_gap < 0.05`
  - passes `max_abs_gap < 0.10`
  - fails a materially tighter `max_abs_gap < 0.03`
- Unstable-side `alpha = 0.19090576171875`:
  - fails `max_abs_gap < 0.05`
  - fails `max_abs_gap < 0.10`

## Interpretation

- The local retry-aware `k = 4` edge is not an artifact of the old `25 + 25` iteration budget.
- The stable-side point remains stable under a longer budget and is not just barely passing the
  current `0.05` rule because of under-iteration.
- The unstable-side point is not a near miss against the `0.05` rule either:
  even after `50 + 50` iterations it still fails a looser `0.10` gap cutoff.
- So the remaining knife-edge around
  `0.190899658203125 / 0.19090576171875`
  is best read as a solver-basin change under the current object, with only the stable-side point
  being sensitive to a much tighter cutoff like `0.03`.
