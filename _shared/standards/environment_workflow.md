# Environment workflow

Load this file only for shell, storage, remote-compute, Git handoff, or editor-layout work.

## Local shell and storage

- Prefer PowerShell and Windows paths for repository work.
- Use WSL selectively for Linux-only utilities, especially PDF/text extraction. Keep Stata, MATLAB, LyX, and Windows-path workflows in PowerShell.
- Follow the `C:` drive guard and `D:\AI_storage\spillover\` rules in `AGENTS.md`.
- Use underscores in new folder and file names unless the user explicitly requests another convention.

## Hamilton and remote compute

- Treat Hamilton 8 as the default Durham HPC target when the user says "Hamilton" or "the supercomputer".
- Verify live authentication before planning remote execution; a local SSH configuration does not prove that passwordless or MFA-free access works.
- Prefer Hamilton for long, parallel, calibration, simulation, or scheduler-based jobs. Prefer local execution for short smoke tests, editing, and Windows-GUI-dependent work.
- Start live checks with the relevant subset of `quota`, `squeue -u $USER`, `sinfo`, `sfree`, and `sacct -j <jobid>`.
- The queue and storage figures recorded on 2026-03-26 are historical hints, not current guarantees: `shared` and `multi` 3 days, `long` 7 days, `bigmem` 3 days, `test` 15 minutes; home 10 GB, `/nobackup` 600 GB, and project storage typically 20 GB. Verify them before relying on them.
- Bede/NICE19 is a possible GPU-oriented alternative but is not the default and may require a separate application.
- For exact account or project entitlements, use live scheduler/account data or contact Durham ARC.

## Session handoff

- When the user says "wrap it up" or equivalent, inspect Git state before stopping and recommend or perform only the in-scope commit/push action.
- Flag meaningful milestones as good push points, but do not commit or push without the relevant authorization.

## User interface preferences

- Treat the Codex app as the default place for the conversation and rendered mathematics.
- Use VS Code for folder navigation and visual PDF reading when useful.
- In VS Code, keep the activity bar at the top, keep Codex and Claude in the primary activity bar, and do not use the secondary side bar by default.
