# Original 5-year local smoothed-politics strategy boss

This worktree runs a local-only overnight queue for the smoothed permit-response
branch.

## Queue

- `local_jointwedge_smooth_full_b3_s005`
- `local_jointwedge_smooth_full_b3_s010`
- `local_jointwedge_smooth_proxy_b3_s010`
- `local_jointwedge_smooth_full_b3_s020`

## Entry points

- Boss runner:
  `run_original_5yr_transition_local_smoothed_strategy_boss.ps1`
- Supervisor starter:
  `start_original_5yr_transition_local_smoothed_strategy_boss.ps1`
- Watchdog ensure script:
  `ensure_original_5yr_transition_local_smoothed_strategy_boss.ps1`
- Watchdog installer:
  `install_original_5yr_transition_local_smoothed_strategy_watchdog.ps1`

## Live status

- `truth/original_5yr_transition_local_smoothed_strategy_boss_live/latest_status.json`

## Fail-safe behavior

- attaches to an existing smoothed local stage if the process is already alive
- advances to the next queued stage if a stage fails without summary
- times out a stage if it exceeds its wall-clock budget
- can be restarted by the watchdog without losing the recorded queue state
