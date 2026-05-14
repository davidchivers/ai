# Political RE overnight workflow

This is the bounded overnight packet for the NIMBY political RE branch.

## Objective

Keep one clean milestone chain running overnight without prompts:

1. refresh the bounded political-path packet
2. refresh the bounded joint price-vote packet
3. run the vote-weight robustness sweep
4. snapshot the outputs and write one overnight summary

The point is not to solve the full political RE fixed point overnight.
The point is to keep the bounded antagonism packet moving and leave a clean handoff in the morning.

## What it runs

The workflow runs, in order:

1. `run_transition_re_political_path_workflow.ps1`
2. `run_transition_re_joint_price_vote_workflow.ps1`
3. `run_transition_re_joint_price_vote_weight_sweep_workflow.ps1`

The overseer launches the workflow hidden, restarts it if the child process dies,
and stops when one clean milestone chain completes or the overnight time budget is hit.

## Live state

Live watcher state goes under:

- `truth/political_re_overnight_live/watcher_log.txt`
- `truth/political_re_overnight_live/watcher_state.json`
- `truth/political_re_overnight_live/active_run.txt`
- `truth/political_re_overnight_live/latest_run.txt`

Per-run summaries go under:

- `truth/political_re_overnight_live/r/`

Each run directory contains:

- `status.txt`
- `manifest.csv`
- `summary.md`
- copied stage artifacts for the political path, joint price-vote packet, and vote-weight sweep

## Start

```powershell
.\start_political_re_overnight.ps1
```

## Stop

```powershell
.\stop_political_re_overnight.ps1
```

## Stop rules

- stop after one clean milestone chain
- stop if the overnight time budget is exhausted
- stop if the child process fails too many times
- do not broaden scope beyond the bounded `T = 4` political packet

## Deliverables

- refreshed bounded political-path packet
- refreshed bounded joint price-vote packet
- vote-weight robustness sweep packet
- one overnight summary with a manifest and copied artifacts

## Non-goals

- no full 2010-2018 political RE frontier search
- no paper drafting
- no branch switching or git push
