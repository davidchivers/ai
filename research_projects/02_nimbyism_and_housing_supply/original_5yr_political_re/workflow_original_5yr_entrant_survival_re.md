# Entrant-survival demographic RE workflow

This is the bounded workflow for testing Zac's demographic simplification.
It replaces the imposed full age-distribution path with a parsimonious law of
motion:

- age-25 entrants are the primitive demographic path
- existing cohorts age forward mechanically
- fixed five-year survival rates capture deaths
- hard-sign politics in the first pass; smoothed politics if the hard sign fails at
  short horizons

## Why this workflow exists

The previous smoothed-tail workflow suggested that smoothing the voting kink is
not enough. A more basic issue may be that the transition was being asked to
track a high-dimensional imposed age-distribution path. This workflow tests
whether the RE problem becomes easier when the demographic forcing process is
one primitive entrant path plus mechanical cohort aging.

## Demographic law of motion

For model age bins `25, 30, ..., 90`, the path is:

```text
N_{25,t+1} = entrants_{t+1}
N_{a+5,t+1} = s_a N_{a,t}
N_{90,t+1} = s_{85} N_{85,t} + s_{90} N_{90,t}
```

where `s_a` is a fixed five-year survival probability. The solver still sees
an age distribution each period, but the exogenous demographic object is now
the entrant path rather than a separately imposed full vector of cohort masses.

## First-pass local queue: hard sign

Run locally before any Hamilton upload.

1. `entrant_survival_flat`
   - sanity check: no entrant shock, only mechanical aging and deaths
   - hard political sign rule
   - short horizon first
2. `entrant_survival_boom`
   - temporary baby-boom entrant path
   - hard political sign rule
   - short horizon first
3. `entrant_survival_decline`
   - secular decline in age-25 entrants
   - hard political sign rule
   - short horizon first

Initial local settings:

- `k_schedule = [2, 4, 6]`
- `max_k = 6`
- `max_outer_iter = 1`
- `basis_count = 2`
- `housing_clear_max_iter = 2`
- political response mode: `hard_sign`

## Decision rule before adding smoothing

Do not stop the current hard-sign flat run in the middle of the `k = 4` outer
step. Let that step finish or hit its timeout.

Then apply this rule:

- if final `k = 4` max vote residual falls materially below the stage-init
  value of about `0.10`, keep the hard-sign queue going through `k = 6`
- if final `k = 4` max vote residual remains around `0.10` or worse, stop the
  hard-sign queue before spending time on boom/decline hard-sign variants
- in that case, switch to entrant-survival plus smoothed politics, starting with
  `sigma = 0.20` on the same short queue

The interpretation is that entrant-survival is already helping the housing/price
side. If hard voting still binds at `k = 4`, smoothing should be treated as a
secondary numerical aid layered onto the simpler demographic law of motion, not
as a replacement for it.

If a scenario survives through `k = 6` with materially better behavior than the
full historical path, extend that scenario locally to:

- `k_schedule = [8, 10, 12, 14]`
- `max_k = 14`

## Stopping rule

Stop the hard-sign queue early if the flat scenario fails the `k = 4` decision
rule above. Otherwise, stop after the short hard-sign local queue if all three
scenarios fail by `k = 6`.

Political smoothing is allowed only after the entrant-survival simplification
has been tested enough to show that the demographic side is mechanically easier
but the hard political sign remains the binding margin.

## Active local queue: entrant survival plus smoothing

The hard-sign flat path gave useful evidence but not enough reason to keep
spending time on hard-sign boom/decline variants: `k = 2` was good
(`final_max_abs_vote = 0.0544`), while the `k = 4` stage-init vote residual was
again near `0.10`. The active local queue therefore layers political smoothing
onto the simpler demographic law:

- political response mode: `smooth_tanh`
- political response scale: `sigma = 0.20`
- scenarios: `entrant_survival_flat`, `entrant_survival_boom`,
  `entrant_survival_decline`
- `k_schedule = [2, 4, 6]`
- `max_k = 6`
- `max_outer_iter = 1`
- `basis_count = 2`
- `housing_clear_max_iter = 2`

The first smoothed queue showed that the model can find good short-horizon
points, but the update/search routine can waste time moving away from them.
Flat `k = 4` opened at `vote = 0.00232`, `gap = 0.00880`; boom `k = 4`
opened at `vote = 0.00257`, `gap = 0.00665`. Both are good enough for the
ladder objective.

The active replacement queue now uses a stage-init-only probe mode for smoothed
politics:

```text
evaluate the stage-init point
record vote, housing gap, merit
accept it and move to the next rung
```

The first clean probe target is the flat scenario. Do not rerun the
already-completed smooth `k = 2` rung; seed from it and start at `k = 4`:

- saved seed price: `truth/seeds/flat_s020_k02_price.csv`
- saved seed wedge: `truth/seeds/flat_s020_k02_wedge.csv`
- `k_schedule = [4, 6, 8, 10, 12, 14]`
- run tag: `local_entsurv_smooth_probe_s020_flat_k4_14`

Verified behavior:

- `k = 4` probe accepted from stage-init with `vote = 0.00232`,
  `gap = 0.00880`, and `merit = 3.24e-5`
- the flat probe completed through `k = 14`
- result profile:
  `k = 4` vote `0.00232`, gap `0.00880`;
  `k = 6` vote `0.04048`, gap `0.01385`;
  `k = 8` vote `0.03400`, gap `0.00512`;
  `k = 10` vote `0.15609`, gap `0.00920`;
  `k = 12` vote `0.15808`, gap `0.00669`;
  `k = 14` vote `0.15808`, gap `0.00677`

Decision rule:

- because flat reached `k = 14`, do not keep broad laddering as the next move
- the first bad rung is `k = 10`: the vote residual jumps from roughly `0.03-0.04`
  at `k = 6/8` to roughly `0.156` at `k = 10`
- housing gaps stay small at `k = 10-14`, so treat the next issue as political/tail-side
  unless a targeted diagnostic proves otherwise
- next primary diagnostic: run a targeted `k = 10` strict solve or tail-political
  diagnostic from the good `k = 8` probe seed
- next fallback diagnostic: a smaller housing grid (`J = 10`, `housingmax = 25`) only if
  the targeted `k = 10` check points back to market clearing

## Active diagnostic: ghost tail at k = 10

The current hypothesis is that the `k = 10` political spike is partly an artificial
terminal-horizon effect: old households near the end of the reported transition see too
little continuation value because the path ends just as survival/death risk becomes
important.

The diagnostic therefore solves a longer internal path while scoring only the first
10 periods:

```text
reported horizon K = 10
internal horizon H = K + G
ghost tails G = 0, 2, 4, 6
objective/scoring window = periods 1..10
```

Implementation:

- the continuation solver now accepts an optional `objective_horizon`
- when `objective_horizon = 10` and `H > 10`, wedge updates and political residual scoring
  use only periods `1..10`
- ghost-tail periods remain in the inner household/housing transition solve, so agents in
  period 10 still see future prices and survival states
- ghost-tail wedge controls are fixed at the neutral continuation value rather than being
  targeted directly

Active scripts:

- `run_original_5yr_ghost_tail_diagnostic.ps1`
- `start_original_5yr_ghost_tail_diagnostic.ps1`
- `watch_original_5yr_ghost_tail_diagnostic.ps1`
- `start_original_5yr_ghost_tail_diagnostic_watchdog.ps1`
- live status: `truth/ghost_tail_k10_live/latest_status.json`
- watchdog status: `truth/ghost_tail_k10_live/watchdog_status.json`

Fail-safe rule:

- the watchdog checks every five minutes
- it does not launch a duplicate while the ghost-tail runner or MATLAB process is alive
- if both disappear before `latest_status.json` says completed, it relaunches the bounded
  queue, which skips any stage with an already-written summary
- the watchdog is bounded and exits after completion, stop-file detection, or its max-hours
  guard

Decision rule:

- if first-10-period residuals fall and stabilize as `G` increases, formalize the auxiliary
  continuation tail as the transition solution method
- if first-10-period residuals do not respond to `G`, the issue is not mainly terminal
  truncation; move back to old-age political closure or the smaller housing-grid diagnostic

## Current entry points

- Demographic builder:
  `build_original_5yr_demographic_entrant_survival_path.m`
- Hard-sign joint wedge runner:
  `run_original_5yr_joint_wedge_hard.m`
- Hard-sign local PowerShell runner:
  `run_original_5yr_joint_wedge_entrant_survival_hard.ps1`
- Smoothed local PowerShell queue:
  `run_original_5yr_entrant_survival_smooth_local_queue.ps1`
- Smoothed queue starter:
  `start_original_5yr_entrant_survival_smooth_local_queue.ps1`
