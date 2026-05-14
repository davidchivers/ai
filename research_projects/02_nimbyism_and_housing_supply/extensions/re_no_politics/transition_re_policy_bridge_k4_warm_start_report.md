# Policy-bridge k = 4 warm-start report

## Goal

Determine whether the apparent `alpha = 0.14`, `k = 4` failure is a real boundary point or a
solver-path artifact under the current one-pass frontier workflow.

## Main diagnostic

- Dedicated runner:
  `run_transition_re_policy_bridge_k4_warm_start_diagnostics.m`
- Canonical outputs:
  - `transition_re_policy_bridge_k4_warm_start_diagnostics_summary.csv`
  - `transition_re_policy_bridge_k4_warm_start_diagnostics_paths.csv`

## Result: alpha = 0.14

- The raw one-pass frontier classification is conservative.
- Starting from the default `same_alpha_k_3` warm start:
  - `max_iter = 25` still looks unstable
    - residual norm about `0.06195`
    - max gap about `0.13429`
    - final period-4 price about `2.1017`
  - `max_iter = 50` reaches a stable path
    - residual norm about `0.00445`
    - max gap about `0.00992`
    - final period-4 price about `2.2261`
- Restarting the same `alpha = 0.14`, `k = 4` case from its own failed 25-iteration endpoint also
  reaches that stable path in about `0.3` seconds.
- Restarting from the stable `alpha = 0.13`, `k = 4` path is also stable.
- Restarting from the stable `alpha = 0.14`, `k = 5` and `k = 6` prefixes is even cleaner:
  the `k = 6` prefix case converges in `19` iterations with max gap about `0.000096`.

## Follow-up checks

- `alpha = 0.15` behaves the same way:
  - default `same_alpha_k_3` with `max_iter = 50` is stable
  - restarting from the failed `k = 4` endpoint is also stable
  - restarting from the stable `alpha = 0.14`, `k = 6` prefix is still stable
  - canonical output:
    `transition_re_policy_bridge_alpha_0_15_k4_restart_checks.csv`
- `alpha = 0.20` still looks genuinely unstable at `k = 4` under the same restart-aware checks:
  - default `same_alpha_k_3` with `max_iter = 50` stays at the lower bound `0.4`
  - restarting from the failed `k = 4` endpoint reproduces that same lower-bound outcome
  - even the stable `alpha = 0.14`, `k = 6` prefix does not rescue it
  - canonical output:
    `transition_re_policy_bridge_alpha_0_20_k4_restart_checks.csv`

## Integrated frontier reruns

- The resumable frontier runner now includes a one-step restart from the failed endpoint before it
  classifies a case as unstable.
- It also now prefers the last stable `k - 1` frontier path when it steps down in `alpha`, rather
  than inheriting a failed same-`k` higher-alpha path by default.
- Under that integrated retry-aware runner at `k = 4`:
  - `alpha = 0.15` is stable:
    `transition_re_policy_bridge_alpha_frontier_single_0_15_k4_retryaware_summary.csv`
  - `alpha = 0.175` is stable:
    `transition_re_policy_bridge_alpha_frontier_single_0_175_k4_retryaware_summary.csv`
  - `alpha = 0.1875` is stable, but close to the gap cutoff:
    max gap about `0.04782`
    `transition_re_policy_bridge_alpha_frontier_single_0_1875_k4_retryaware_summary.csv`
  - `alpha = 0.190625` is also stable:
    max gap about `0.03292`
    `transition_re_policy_bridge_alpha_frontier_single_0_190625_k4_retryaware_summary.csv`
  - `alpha = 0.1908203125` is also stable:
    max gap about `0.03204`
    `transition_re_policy_bridge_alpha_frontier_single_0_1908203125_k4_retryaware_summary.csv`
  - `alpha = 0.190869140625` is also stable:
    max gap about `0.03202`
    `transition_re_policy_bridge_alpha_frontier_single_0_190869140625_k4_retryaware_summary.csv`
  - `alpha = 0.1908935546875` is also stable:
    max gap about `0.03190`
    `transition_re_policy_bridge_alpha_frontier_single_0_1908935546875_k4_retryaware_summary.csv`
  - `alpha = 0.190899658203125` is also stable:
    max gap about `0.03190`
    `transition_re_policy_bridge_alpha_frontier_single_0_190899658203125_k4_retryaware_summary.csv`
  - `alpha = 0.19090576171875` is unstable after retry:
    max gap about `0.79470`
    `transition_re_policy_bridge_alpha_frontier_single_0_19090576171875_k4_retryaware_summary.csv`
  - `alpha = 0.19091796875` is unstable after retry:
    max gap about `0.72382`
    `transition_re_policy_bridge_alpha_frontier_single_0_19091796875_k4_retryaware_summary.csv`
  - `alpha = 0.191015625` is unstable after retry:
    max gap about `0.41349`
    `transition_re_policy_bridge_alpha_frontier_single_0_191015625_k4_retryaware_summary.csv`
  - `alpha = 0.19140625` is unstable after retry:
    max gap about `0.26158`
    `transition_re_policy_bridge_alpha_frontier_single_0_19140625_k4_retryaware_summary.csv`
  - `alpha = 0.1921875` is unstable after retry:
    max gap about `0.26161`
    `transition_re_policy_bridge_alpha_frontier_single_0_1921875_k4_retryaware_summary.csv`
  - `alpha = 0.19375` is unstable after retry:
    max gap about `0.26211`
    `transition_re_policy_bridge_alpha_frontier_single_0_19375_k4_retryaware_summary.csv`

## Interpretation

- The previously reported `alpha = 0.13995` versus `0.14000` `k = 4` cliff is not a structural
  boundary of the bounded-horizon object.
- It is a boundary of the current one-pass `25`-iteration frontier workflow started from the
  `same_alpha_k_3` path.
- Under a restart-aware interpretation:
  - `alpha = 0.14` is stable at `k = 4`
  - `alpha = 0.15` is also stable at `k = 4`
  - `alpha = 0.190899658203125` is also stable at `k = 4`
  - `alpha = 0.19090576171875`, `0.19091796875`, `0.191015625`, `0.19140625`, `0.1921875`,
    `0.19375`, and `0.20` are unstable at `k = 4`
- So the practical `k = 4` edge now moves from the old `0.13995/0.14000` statement to a
  retry-aware bracket between `alpha = 0.190899658203125` and `0.19090576171875`.
