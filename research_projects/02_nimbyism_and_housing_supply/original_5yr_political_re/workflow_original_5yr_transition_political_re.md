# Original 5-Year Transition Political RE Workflow

This is the bounded unattended workflow for the original 5-year dynamic
political Bellman lane.

## Objective

Use the original 5-year political steady-state Bellman kernel and the
historical US age path to build the first climbable bounded transition RE
ladder starting in `1950`.

## Current implementation choice

- Dynamic lane: MATLAB
- C lane: steady-state political object only, already parity-checked

So this workflow runs the dynamic original-timing outer loop in MATLAB while
keeping the compiled C side as the validated steady-state reference.

## Historical demographic source

- Workbook:
  `US Age Share Fine Grained.xlsx`
- Sheet:
  `Share`
- Years used:
  `1950, 1955, ..., 2015`
- Model bins:
  `25-29, 30-34, ..., 85-89, 90+`

## Workflow tree

1. Historical-path validation
   - Build the original-timing demographic path from the workbook.
   - Confirm the workflow is using the `1950` start rather than the temporary
     `2010 -> 2015` smoke path.

2. `k = 1` historical smoke
   - Run one political iteration on the `1950` steady-state benchmark.
   - Confirm zero housing gap and the expected nonzero vote residual.

3. `k = 2` historical baseline
   - Run `1950 -> 1955` with the conservative fixed-step update.

4. `k = 2` update-rule sweep
   - Fixed-step, baseline weight
   - Fixed-step, faster weight
   - Diagonal-secant update

5. Select best `k = 2` branch
   - Rank by smallest `max_abs_vote`
   - Break ties using `max_abs_gap`

6. If `k = 2` is numerically well behaved, climb to `k = 3`
   - First smoke run
   - Then a short continuation run on the best `k = 2` update rule

7. If `k = 3` remains well behaved, probe `k = 4`
   - One bounded smoke run only

## Stop rules

- Stop if the historical workbook cannot be read.
- Stop if a stage fails in a way that blocks the next rung.
- Stop if the elapsed wall-clock time hits the configured time budget.
- Stop before broadening scope beyond this original 5-year dynamic lane.

## Deliverables

- Live status:
  `truth/original_5yr_transition_political_live/latest_status.json`
- Live report:
  `truth/original_5yr_transition_political_live/latest_report.md`
- Per-run folder:
  `truth/original_5yr_transition_political_live/r/<run_id>/`
- Stage outputs:
  summary CSVs, vote paths, price paths, and a final JSON summary

## Supervisor behavior

- The supervisor may relaunch the bounded workflow if it exits without a clean
  terminal state.
- It does not imply indefinite remote execution.
- It is a local process and depends on this machine staying awake.
