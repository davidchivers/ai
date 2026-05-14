# Original 5-year dual solver boss workflow

Fail-safe supervisor for the two live solver lanes we care about right now:

- local reduced-path lane on this computer
- Hamilton joint-supply-wedge lane

## Objective

Keep one local lane and one Hamilton lane moving without requiring manual
reattachment every time a branch stalls, crashes, or finishes.

## Local queue

1. Attach to the lingering `local_redjac_from_dynare` process if it is still
   genuinely alive.
2. If that lane is gone or fails without a summary, launch a clean Dynare
   reduced-path retry from the incumbent full-horizon seed.
3. Then launch a reduced-Jacobian follow-up from the Dynare retry output.

## Hamilton queue

1. Attach to the current joint-supply-wedge baseline packet if it is already
   running.
2. When that packet finishes, submit a repair packet for the configurations
   that failed in the first launch.
3. Then submit an aggressive joint-supply-wedge packet from the best available
   seed.

## Non-stop rule

Branch failure is not a workflow stop.

- local failure -> move to the next local retry stage
- Hamilton packet completion/failure -> move to the next Hamilton phase
- only stop when the full queue is exhausted, the 24-hour budget ends, or the
  RE residual is materially solved

## Live root

- `truth/original_5yr_transition_dual_solver_boss_live/`
