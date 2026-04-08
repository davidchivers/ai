# 24-hour workflow for the 5-year RE transition experiment

This workflow is for unattended runs on the current 5-year RE price solver.

## Goal

Use the machine time to do the things that are already informative and robust:

1. save a fresh baseline one-iteration diagnostic run,
2. rerun the tuning grid if needed under the current code,
3. preserve logs so the next session starts from outputs rather than guesses.

## Sequence

### Stage 1. Baseline transition diagnostic

Run:

- `run_demographic_forecast_re_no_politics`

Purpose:

- confirms the transition data and transition-matrix inputs still resolve,
- saves `transition_re_no_politics_results.mat`,
- reports the current accepted update, residual norm, and targeted periods/blocks.

### Stage 2. Parameter tuning sweep

Run:

- `run_transition_re_tuning_grid`

Purpose:

- compares a small grid of dampings / smoothing weights / local-correction settings,
- saves `transition_re_tuning_summary.csv`,
- saves `transition_re_tuning_results.mat`,
- provides a ranked table for the next coding session.

### Stage 3. Review point for the next session

Read in this order:

1. `transition_re_tuning_summary.csv`
2. `transition_re_tuning_stdout.log`
3. `transition_re_no_politics_results.mat`

Decision rule:

- if the best rows are still effectively `current_path`, keep working on solver structure / runtime,
- if local or block updates are being accepted consistently, increase block sweeps gradually,
- if runtime dominates everything, focus on caching / reuse before adding new solver logic.

## Current interpretation

The model is not stuck conceptually. The open problem is numerical: the 5-year RE transition solve is expensive, and the right direction is sequential local updates rather than more whole-path tuning.
