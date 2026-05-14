# Original 5-year transition solver stabilization workflow

Bounded overnight packet for the original 5-year historical political Bellman lane.

## Objective

Stabilize the second outer political update without reopening horizon discovery.

## Branch order

1. Attach to the in-flight `k = 6` targeted line-search run if it already exists.
2. If that primary `k = 6` run improves on the old one-iteration smoke, deepen to `k = 6`, `3` iterations.
3. If it does not improve, try one smaller-weight `k = 6` targeted retry.
4. If any `k = 6` targeted branch beats the old `k = 6` smoke benchmark, escalate once to `k = 14`, `2` iterations.
5. Stop cleanly and write status if no targeted branch improves, or when the time budget is exhausted.

## Benchmarks

- `k = 6` smoke reference: `max |vote| = 0.0278386148549857`
- `k = 14` smoke reference: `max |vote| = 0.0343491536712217`

## Outputs

- live root:
  `truth/original_5yr_transition_solver_stabilization_live/`
- workflow runner:
  `run_original_5yr_transition_solver_stabilization_overnight.ps1`
- supervisor:
  `watch_original_5yr_transition_solver_stabilization_supervisor.ps1`
- reporter:
  `watch_original_5yr_transition_solver_stabilization_reporter.ps1`
