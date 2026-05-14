# Policy-bridge blend ladder workflow

This workflow extends the blend object in horizon length rather than only on the full 2010-2018 path.

## Goal

- keep the same blended policy-reference object
- ask how far each blend weight can be extended in `k`
- map the intermediate rung between the fixed-price bridge and the pure by-period-price bridge

## Blend object

- policy-reference path:
  `(1 - alpha) * 2.0 + alpha * current_price_path`
- `alpha = 0`:
  fixed-price benchmark
- `alpha = 1`:
  pure by-period-price bridge

## Files

- `run_transition_re_policy_bridge_blend_ladder.m`
- `run_transition_re_policy_bridge_blend_ladder.ps1`
- `run_transition_re_policy_bridge_alpha_frontier.m`
- `run_transition_re_policy_bridge_alpha_frontier.ps1`
- `transition_re_policy_bridge_blend_report.md`

## Current read

- matched-budget ladder:
  - `alpha = 1.00` stays stable through `k = 3` and fails at `k = 4`
  - `alpha = 0.05` stays stable through `k = 4`
  - `alpha = 0.02` stays stable through at least `k = 5` in the checkpointed ladder output
  - `alpha = 0.00`, `0.01`, `0.015` stay stable through the full ladder `k = 9`
- resumable coarse `alpha` frontier on grid
  `{0.00, 0.01, 0.015, 0.02, 0.03, 0.05, 0.10, 0.20, 0.50, 1.00}`:
  - `k = 1`, `2`, `3`: max stable `alpha = 1.00`
  - `k = 4`: max stable `alpha = 0.05`
  - `k = 5`: resumed cleanly from the partial run and stays at `alpha = 0.05`
- same-alpha continuation refinement:
  - local refined frontier on `{0.05, 0.06, 0.07, 0.08, 0.09, 0.10}` keeps
    `alpha = 0.10` stable through `k = 6`
  - single-alpha continuation at `alpha = 0.12` stays stable through `k = 6`
  - resumed single-alpha continuation at `alpha = 0.13` also stays stable through `k = 6`
  - the raw one-pass frontier packet flags `alpha = 0.14` as unstable at `k = 4`, but stable again
    at `k = 5` and `k = 6`
  - dedicated `k = 4` warm-start diagnostics show that this `alpha = 0.14` rejection is a
    one-pass workflow artifact rather than a structural boundary:
    the default `same_alpha_k_3` start is unstable after `25` iterations, but becomes stable after
    `50` iterations, and a single restart from the failed endpoint is also stable
  - the same restart-aware interpretation extends to `alpha = 0.15` at `k = 4`
  - `alpha = 0.20` still looks unstable at `k = 4` even after restart-aware checks
  - the frontier runner now also bakes in that interpretation directly:
    it retries one unstable case from its own failed endpoint and, when stepping down in `alpha`,
    it prefers the last stable `k - 1` frontier path over a failed same-`k` higher-alpha path
  - under that integrated retry-aware runner:
    `alpha = 0.15`, `0.175`, `0.1875`, `0.190625`, `0.1908203125`, `0.190869140625`,
    `0.1908935546875`, and `0.190899658203125` are stable at `k = 4`,
    while `alpha = 0.19090576171875`, `0.19091796875`, `0.191015625`, `0.19140625`,
    `0.1921875`, `0.19375`, and `0.20` are unstable after retry
  - current bounded-horizon read is therefore:
    under the raw one-pass same-alpha ladder, `alpha = 0.13` is the largest tested value that
    stays stable for every `k <= 6`
    under the restart-aware `k = 4` interpretation, the local edge moves up to between
    `alpha = 0.190899658203125` and `0.19090576171875`
  - new `k = 5` retry-aware continuation checks say the next horizon is materially harsher:
    `alpha = 0.19` is stable at `k = 4` but unstable at `k = 5`
    `alpha = 0.18` and `0.185` are stable at `k = 5`
    `alpha = 0.185625`, `0.18625`, and `0.1875` are unstable at `k = 5`
    so the current retry-aware `k = 5` edge lies between `alpha = 0.185` and `0.185625`
    under the same stability filter
  - local edge robustness packet:
    a dedicated runner `run_transition_re_policy_bridge_k4_edge_robustness.m` compares the
    existing `25 + 25` retry-aware classification to a longer `50 + 50` retry-aware budget at the
    same `k = 4` warm start
    at the stable-side edge point `alpha = 0.190899658203125`, the longer budget reaches the same
    final path and the same max gap about `0.03190`, but now does so in the first `50`-iteration
    attempt without needing a retry
    at the unstable-side edge point `alpha = 0.19090576171875`, the longer budget still remains
    unstable after retry:
    the max gap falls from about `0.79470` to about `0.26158`, but it still fails even a looser
    `0.10` gap cutoff and the retry path hits the upper bound `5.0`
    so the local edge is not being created by the old `25 + 25` budget, and on the unstable side
    it is not a near-miss against the `0.05` cutoff either

## Interpretation

- the full-horizon blend frontier is sharper than the `k`-ladder frontier
- shorter ladders can absorb some current-price feedback even when the full 9-period path cannot
- the instability therefore depends on horizon length as well as on the amount of current-price feedback
- the resumable frontier runner is the right object for long continuation searches because the
  `k = 4` and `k = 5` cases are expensive enough that partial runs are realistic
- the old descending-alpha coarse frontier is not a clean boundary object by itself:
  lower-alpha tests can inherit bad warm starts from unstable higher-alpha same-`k` paths
- for quantitative reading, the more reliable object is same-alpha continuation across `k`, not
  only the monotone descent from the previous frontier
- the current practical bracket for the bounded-horizon blend object is therefore much tighter than
  the old coarse packet suggested:
  the raw one-pass monotone-through-`k <= 6` edge is between `alpha = 0.13` and `0.14`, not
  between `0.05` and `0.10`
- the `k` profile is not itself monotone under the current solver and stability filter:
  `alpha = 0.14` is rejected at `k = 4` but accepted again at `k = 5` and `k = 6`, so the packet
  should be read horizon-by-horizon rather than as a clean nested stability set
- inside that horizon-by-horizon view, the raw one-pass frontier is now best interpreted as a
  conservative lower bound:
  at `k = 4`, `alpha = 0.14` and `0.15` are stable after restart-aware checks, while `alpha = 0.20`
  still fails
- the updated runner now automates that restart-aware reading for same-alpha continuation runs, so
  the local `k = 4` edge should be read from the retry-aware bracket rather than from the old
  manual `0.13995/0.14000` pinch-point packet
- the new edge-robustness packet says the remaining knife-edge is mostly about a basin change, not
  just the old iteration cap:
  the stable-side edge point passes the current `0.05` cutoff cleanly but would fail a materially
  tighter `0.03` cutoff, while the unstable-side edge point remains far outside even a `0.10`
  cutoff after the longer `50 + 50` budget
- the `k = 5` packet strengthens the broader message:
  even after the `k = 4` cliff is reclassified upward, the bounded-horizon object still gets
  harder as the horizon lengthens, and by `k = 5` the retry-aware edge has already fallen back to
  around `alpha = 0.185`
