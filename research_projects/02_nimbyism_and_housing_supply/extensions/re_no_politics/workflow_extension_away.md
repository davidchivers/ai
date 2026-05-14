# Extension away workflow

This is the bounded day-scale workflow for the current RE and coalition extension packet.

## Objective

Use one away session to produce:

- one final qualitative RE continuation run
- one benchmark-based coalition sensitivity run
- refreshed reports for both branches

## Phase order

1. Finish the coarse RE `lambda` continuation workflow.
2. Refresh the transition RE follow-up report.
3. Run the benchmark-based coalition sensitivity workflow.
4. Write the coalition benchmark report.
5. Stop.

## Why this order

- The RE branch is already live and should finish first.
- The coalition branch is conceptually separate but still inside the same extension workspace.
- Running it second gives one clean benchmark-comparison deliverable rather than opening another
  search branch.

## Deliverables

- `transition_re_lambda_continuation_summary.csv`
- `transition_re_lambda_continuation_results.mat`
- `transition_re_followup_report.md`
- `coalition_benchmark_summary.csv`
- `coalition_benchmark_results.mat`
- `coalition_benchmark_report.md`

## Orchestrator

Use:

- `run_extension_away_workflow.ps1`

The workflow will:

- attach to the running lambda batch if it is already live
- otherwise start or resume it
- then run the coalition benchmark comparison
- then refresh the relevant reports

## Stopping rule

Stop after these two long-compute branches and their reports are complete.

Do not broaden into a new RE solver family or a dynamic coalition model in the same away packet.
