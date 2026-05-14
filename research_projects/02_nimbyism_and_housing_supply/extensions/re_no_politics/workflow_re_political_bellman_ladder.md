# Political Bellman k-step ladder

This is the fertility-style continuation workflow for the full-political
transition Bellman branch.

## Goal

Do not jump straight to the full `T = 9` transition from scratch.
Instead:

1. solve the bounded political Bellman wrapper at `k = 1`
2. warm-start `k = 2` from the `k = 1` political solution
3. continue one horizon at a time up to `k = 9`

This is the closest analogue to the fertility ladder:
start from the easier short-horizon object and extend the horizon
gradually rather than attacking the full path cold.

## Current implementation

- solver:
  `solve_transition_political_bellman_nimby.m`
- ladder runner:
  `run_transition_political_bellman_k_step_ladder.m`
- PowerShell wrapper:
  `run_transition_political_bellman_k_step_ladder.ps1`

## Default branch

- political target:
  equal-weight vote
- update mode:
  joint housing plus politics
- political update weight:
  `0.005`
- ladder budget:
  `1` outer political iteration per `k`

## What gets warm-started

- `k = 1` starts from the no-politics transition path prefix
- each later `k` starts from the previous political final path
  plus the no-politics tail for the new period

## Outputs

- ladder summary:
  `transition_political_bellman_<tag>_ladder_summary.csv`
- ladder results:
  `transition_political_bellman_<tag>_ladder_results.mat`
- per-`k` bounded packets:
  `transition_political_bellman_<tag>_k<k>_summary.csv`
  `transition_political_bellman_<tag>_k<k>_results.mat`

## Current read

The first full run with tag `joint_eqvote_ladder` reached all `k = 1..9`
without crashing or hitting the imposed price bounds.

That does not mean the political fixed point is solved.
It means the full-political Bellman ladder is now operational on the
whole sample and can be pushed with more outer iterations or alternative
update rules.
