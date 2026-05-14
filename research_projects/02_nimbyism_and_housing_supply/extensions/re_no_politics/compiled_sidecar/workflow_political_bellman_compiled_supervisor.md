# Political Bellman Compiled Supervisor

This watcher keeps the compiled political Bellman smoke packet current
without needing repeated prompts.

## Scope

- rebuild the compiled sidecar when the source tree changes
- export the no-politics price prefix from the saved MATLAB result file
- run the compiled `T = 4` fixed-step political wrapper
- run the compiled `T = 9` diagonal-secant political wrapper
- validate both smoke runs against the stored MATLAB summaries when possible

## Start

```powershell
.\start_political_bellman_compiled_supervisor.ps1
```

## Live state

- `truth\political_bellman_compiled_supervisor_live\watcher_log.txt`
- `truth\political_bellman_compiled_supervisor_live\watcher_state.json`
- `truth\political_bellman_compiled_supervisor_live\latest_run.txt`

## Stop

```powershell
.\stop_political_bellman_compiled_supervisor.ps1
```

## Current stopping rule

- keep rerunning on source changes
- do not broaden beyond the compiled political wrapper smoke packet
- treat the remaining MATLAB parity gap as a follow-up task, not a blocker for the watcher
