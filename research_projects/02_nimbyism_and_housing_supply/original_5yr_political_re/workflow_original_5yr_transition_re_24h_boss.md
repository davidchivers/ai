# Original 5-year RE 24-hour boss workflow

Fail-safe 24-hour control workflow for the full-horizon political RE solve.

## Objective

Use this machine and Hamilton in parallel for a bounded 24-hour push without
stopping when one branch family fails. The goal is to keep at least one local
branch and one Hamilton branch busy until either:

- the political RE path materially improves, or
- the full 24-hour budget is exhausted

## Boss logic

The boss controller owns two queues:

### Local queue

1. Attach to the current coarse lobe search if already running.
2. If it completes, launch a finer lobe refinement around its best candidate.
3. Then launch the Dynare reduced-path branch from the best local seed.
4. If Dynare improves the seed, launch a reduced-path Jacobian follow-up from that Dynare seed.

### Hamilton queue

1. Attach to the current reduced-path Jacobian packet if already running.
2. When that packet finishes, summarize the best result.
3. If the packet does not improve enough, launch an aggressive Jacobian packet
   with larger trust regions and deeper outer iterations.
4. If the Dynare local branch improves the seed, launch a new exploratory packet from that Dynare seed.

## Non-stop rule

Branch failure is not a workflow stop.

- local branch failure -> move to next local branch
- Hamilton packet failure -> move to next Hamilton packet
- packet/job exhaustion -> only stop when both local and Hamilton queues are exhausted

## Current interpretation

The old seed-hunting family has likely reached a plateau. The boss now treats
Dynare as the next real algorithm-class change, not as another small local
mask tweak. Dynare is solving a reduced active-set coefficient system and then
passing the resulting candidate path back through the full Bellman transition
object for validation.

## Deliverables

- live machine-readable state
- live human-readable report
- automatic relaunch if the boss process exits unexpectedly
- 24-hour keep-awake guard on this machine

## Live root

- `truth/original_5yr_transition_re_24h_boss_live/`
