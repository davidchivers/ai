# House-Price Compiled Supervisor

This workflow keeps the NIMBY compiled house-price pipeline moving without
interactive prompts.

## Objective

Watch the compiled-sidecar source tree and rerun a bounded validation packet
whenever the Bellman, transition-pass, transition-RE, or exporter layer
changes.

## What it runs

The supervisor workflow runs, in order:

1. `build.ps1`
2. `run_steady_state_cli.ps1`
3. `validate_steady_state.ps1`
4. `run_steady_state_sweep_cli.ps1`
5. `run_transition_pass_cli.ps1`
6. `validate_transition_pass.ps1`
7. `run_transition_re_cli.ps1`
8. `validate_transition_re.ps1`

Outputs go under:

- `truth/house_price_compiled_supervisor_live/r/`

Live watcher state goes under:

- `truth/house_price_compiled_supervisor_live/watcher_log.txt`
- `truth/house_price_compiled_supervisor_live/watcher_state.json`
- `truth/house_price_compiled_supervisor_live/latest_run.txt`

## Start

```powershell
.\start_house_price_compiled_supervisor.ps1
```

## Stop

```powershell
.\stop_house_price_compiled_supervisor.ps1
```

## Stop rule

- The watcher does not ask for prompts.
- It waits for a quiet window after file changes, then launches one hidden
  supervisor run.
- If more changes arrive during a run, it queues exactly one rerun after the
  current run finishes.
- It exits when `stop_house_price_compiled_supervisor.ps1` is called.

## Scope

Watched inputs:

- `src/`
- `include/`
- `matlab/`
- root-level `*.ps1`
- root-level `README.md`
- root-level `CMakeLists.txt`

Not watched:

- `truth/`
- `build/`

That keeps output churn from retriggering the workflow.
