# Compiled full-horizon away workflow

This is the bounded 12-hour workflow for the compiled NIMBY RE sidecar.
It is designed for the current full-horizon bracket-refinement task, not as a
general frontier scanner.

## Objective

Refine the compiled retry-aware full-horizon bracket around the current live
read:

- stable at `alpha = 0.18083671212196353`
- unstable at `alpha = 0.18083722352981568`

The workflow keeps the current best stable `k = 8` and `k = 9` price paths,
probes one midpoint at a time, and updates the bracket only when a new result
is actually classified.

Current live status:

- the live session `tr_full_horizon_away_live` has already reached the target
  bracket width
- the saved handoff and state files can still be resumed safely, but the
  default behavior now stops immediately because the target width is already met

## Entry point

Run:

```powershell
.\run_transition_re_full_horizon_away_workflow.ps1 -Hours 12
```

The runner resumes automatically from:

- `truth/tr_full_horizon_away_live/workflow_state.json`

## What it does

1. Uses the validated compiled retry-aware wrapper, not the MATLAB solver.
2. Builds small input packs by cloning the current `k = 8` and `k = 9`
   minimal templates and overwriting only:
   - `policy_reference_blend_weight`
   - `price_path.csv`
   - `re_initial_price_path.csv`
3. Runs `k = 8` first.
4. Runs `k = 9` only if `k = 8` is stable and there is still time and disk
   headroom.
5. Keeps compact probe artifacts only:
   - retry-aware summary
   - attempt summary
   - selected final price path
6. Deletes the bulky transient input/output probe folders after compaction.

## Stopping rules

- Stop when the 12-hour budget is reached, reserving time for handoff.
- Stop when the bracket width is below the target tolerance.
- Stop when free space on `C:` falls below the configured guard.
- Stop after the configured maximum number of probes for that invocation.

## Key outputs

Inside `truth/tr_full_horizon_away_live/`:

- `workflow_state.json`
- `workflow_log.csv`
- `workflow_handoff.md`
- `s/stable_k8_selected_final_price_path.csv`
- `s/stable_k9_selected_final_price_path.csv`
- `r/p*/`

## Operational note

This workflow assumes the current machine remains disk-constrained. The
transient retry-aware output trees are the expensive part, so the runner is
deliberately compact-first and deletes those transient folders after each
probe is harvested.
