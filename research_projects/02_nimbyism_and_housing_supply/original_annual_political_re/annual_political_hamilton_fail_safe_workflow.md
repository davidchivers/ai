# Annual Political Hamilton Fail-Safe Workflow

## Why the previous job timed out

The `16893451` Hamilton array reached the 6-hour Slurm limit before writing candidate
summaries. The logs did not show a model error. They showed that MATLAB was using the
slow `.m` fallback for at least one CompEcon routine instead of the compiled C/MEX
version.

So the timeout is a runtime/setup failure, not evidence against the political
pass-through mechanism.

## Current workflow

1. Ship the full CompEcon `CEtools` folder, including `.mexa64` Linux binaries, C source
   files, and `private/` routines.
2. Submit a thin `T = 20` ladder first: one candidate per Slurm task.
3. Require each task to write its own `summary_all.csv`.
4. Only after real `T = 20` summaries exist, promote usable/survivor candidates to
   `T = 40`.
5. Do not submit `T = 80` until `T = 40` writes usable summaries.

## Active first-stage candidates

These are the best local broad-grid representatives by vote scale:

| vote scale | rho | phi | gamma | reason |
|---:|---:|---:|---:|---|
| 0.015 | 0 | 0.06 | 1.00 | best local `T = 12` row for scale |
| 0.020 | 0 | 0.15 | 0.50 | best local `T = 12` row for scale |
| 0.030 | 0 | 0.10 | 1.00 | best local `T = 12` row for scale |

## Commands

Submit the first stage:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T20
```

Check status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\check_annual_political_hamilton_thin_ladder.ps1
```

If `T = 20` produces summaries, submit `T = 40`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T40
```

If `T = 40` produces usable summaries and a long-horizon check is needed, submit `T = 80`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80
```

If `T = 80` is close but not strictly usable, use the one-parameter refinement rather
than adding separate political knobs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Refine -PeriodIter 4
```

This fixes `rho = 0`, fixes `vote_scale = 0.020`, fixes `gamma = 1`, and varies only
`eta = phi`, which is the effective political-pressure-to-log-price pass-through.

For lag robustness, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Lag -PeriodIter 1
```

This uses the same eta grid, but pressure in year `t` only affects the next year's
price/supply environment.

For longer institutional lags, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Lag5 -PeriodIter 1
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Lag10 -PeriodIter 1
```

These test 5-year and 10-year delays using the usable eta region from the one-year lag
check.

For death/terminal-age robustness, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Death -PeriodIter 2
```

This checks baseline terminal voting, half terminal-age voting weight, and dropping the
terminal age before voting over a narrow eta grid.

## Decision rule

- `usable`: keep and promote.
- `survivor`: promote if there are too few usable rows.
- `dead`: do not promote unless all rows die and the failure is clearly numerical rather
  than economic.
- `timeout with no summary`: runtime failure; first check MEX path and walltime before
  changing economics.
