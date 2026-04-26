# Smoothed tail fail-safe workflow

This is the bounded fail-safe lane for the smoothed political tail tests. It is
meant to keep the current local workflow moving without reviving the old broad,
popup-heavy boss setup.

## Design goals

- keep the active local smoothed tail job alive if it is already running
- relaunch the fail-safe runner hidden if the supervisor disappears
- avoid duplicate MATLAB jobs
- move through a short bounded queue, then stop and hand off to review
- write machine-readable status and a human-readable note in one live folder

## Live folder

- `truth/original_5yr_transition_smoothed_tail_fail_safe_live`

Key files:

- `latest_status.json`
- `latest_report.md`
- `workflow_log.txt`
- `supervisor_status.json`
- `supervisor_log.txt`
- `final_result.json`
- `queue_review_needed.md`
- `next_best_candidate.json`

## Queue

1. `local_smoothtail_full_s020_k10_12_b3_i1_light`
   - current fair light rerun on `sigma = 0.20`
   - record any old result if present, but do not relaunch this stale broad run
2. `local_smoothtail_tailactive_s020_k11_12_b2_i1`
   - freeze the accepted old `k = 10` wedge path exactly
   - search only the new tail periods `11` and `12`
   - force unlocked tail periods into the political residual so `reduced_vote_l2 = 0`
     cannot falsely pass the diagnostic
   - keep `sigma = 0.20`
3. `local_smoothtail_tailactive_s020_k13_14_b2_i1_fromk12`
   - run only if stage 2 writes a real `k = 12` price and wedge seed
   - freeze the accepted `k = 12` prefix and append periods `13` and `14`
4. `local_smoothtail_tailactive_s040_k11_12_b2_i1`
   - higher-smoothing control with `sigma = 0.40`
   - run only if the `sigma = 0.20` lane has not already reached `k = 14`
5. `local_smoothtail_tailactive_s040_k13_14_b2_i1_fromk12`
   - run only if the `sigma = 0.40` lane writes a real `k = 12` seed
6. `local_smoothtail_tailactive_s020_k11_b1_h4_i1`
   - if neither smoothing lane reaches `k = 12`, retry only `k = 11`
   - use a one-block tail wedge and deeper housing clearing
   - this is a diagnostic, not another broad search

The frozen-prefix stages are now the decisive diagnostic. The previous direct
jump reran `k = 10` in a new three-block basis, which accidentally moved the
accepted prefix and made the run worse before it reached the tail. The new mode
keeps the known-good first ten periods fixed and asks a cleaner question: can
the solver append periods `11` and `12`? The tail-active version is now the
canonical diagnostic because the first frozen-prefix attempt exposed a zero
reduced residual when the unlocked tail period was not included in the active
political residual.

The longer overnight version is conditional rather than open-ended. It climbs
to `k = 13` and `k = 14` only from an actual `k = 12` seed. If no `k = 12` seed
is produced, it does one narrow robustness/diagnostic pass and then stops.

If the queue exhausts without a clean tail winner, the fail-safe lane writes a
review prompt and points to the next strategic move:

- `terminal_closure_then_stacked_joint_residual_solve`

## How to start

Run:

- `start_original_5yr_transition_smoothed_tail_fail_safe_supervisor.ps1`

The starter launches the supervisor hidden. The supervisor in turn launches the
runner hidden only if it is missing.

## How it stops

The workflow is intentionally bounded.

It stops when:

- the queue finishes and writes `final_result.json`
- `stop.txt` appears in the live folder
- the supervisor or runner hits its configured max-hours guard

This keeps the local machine busy on the current smoothed-tail decision round
without turning into an endless search loop.
