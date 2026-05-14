# 2026-05-11 T80 Model Grid Workflow

Purpose: test defensible economic branches in parallel without another blind local rescue loop.

## First-Wave Scope

- Report horizon: T80.
- Political timing: `VoteShiftMode = block_vote`, `VoteBlockLength = 4`.
- RE object: full price-path rational expectations with basis-Broyden updates.
- Terminal object: terminal fixed point.
- Ghost tail: 20, 40, or 80 hidden years.
- Post-report demographics: return linearly from the report-end age distribution to the reference steady-state age distribution over the hidden tail.
- Pass-throughs: `0.006` and `0.012`.
- Time-to-build proxy: existing lagged pass-through map with lags `0`, `1`, `2`, and `4`.

The current solver implements the time-to-build branch as a delayed price/pass-through map, not a full housing-stock construction pipeline. Treat it as a first-pass delivery-lag robustness test. A true stock-state pipeline is a larger model change and should be its own second-stage branch if this proxy is promising or if the paper needs it.

## Files

- `model_grid_0511.csv`: RE first-wave grid, one row per Hamilton array task.
- `model_grid_existing_comparators_0511.csv`: completed no-RE comparator rows from jobs `17074451` and `17078002`.
- `run_t80_model_grid_0511.m`: parameterized MATLAB runner.
- `bb80modelgrid_re_0511.slurm`: Slurm array launcher for RE rows.
- `rank_model_grid_0511.py`: post-run ranker and report generator.

## Verdict Rules

- `paper_safe`: `max_abs_path_gap <= 0.0002`.
- `usable`: `max_abs_path_gap <= 0.001`.
- `survivor`: `0.001 < max_abs_path_gap <= 0.003`.
- `dead`: no summary, failed row, or best gap above `0.003`.

If any RE row is `usable`, stop broad search and inspect. If only survivors exist, expand only the best two model families. If all rows are dead, stop and make a larger modelling decision rather than adding more local variants.
