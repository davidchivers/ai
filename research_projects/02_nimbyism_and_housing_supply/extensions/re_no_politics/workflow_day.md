# Away-for-a-day workflow for the transition RE follow-up

This workflow is for unattended use while the current NIMBY transition-path calibration is already running or queued.

## Goal

Use the next day of machine time to:

1. let the candidate-selection follow-up finish cleanly,
2. refresh the readable Markdown report immediately after that stage,
3. run a short validation pack comparing the baseline control against the best non-baseline candidate,
4. refresh the report again so the next session starts from one report and a small set of canonical outputs.

## Orchestrator

Run:

- `run_transition_re_day_workflow.ps1`

What it does:

1. watches for an active `run_transition_re_candidate_selection_followup` MATLAB batch,
2. waits if that batch is already running,
3. resumes candidate selection from live checkpoints if needed,
4. refreshes `transition_re_followup_report.md`,
5. runs `run_transition_re_validation_pack`,
6. refreshes `transition_re_followup_report.md` again.

## Stage outputs

Candidate-selection follow-up:

- `transition_re_candidate_selection_summary.csv`
- `transition_re_candidate_selection_results.mat`
- `workflow_logs/candidate_selection_followup_stdout.log`
- `workflow_logs/candidate_selection_followup_stderr.log`

Validation pack:

- `transition_re_validation_summary.csv`
- `transition_re_validation_results.mat`
- `workflow_logs/validation_pack_stdout.log`
- `workflow_logs/validation_pack_stderr.log`

Readable report:

- `transition_re_followup_report.md`

Workflow log:

- `workflow_logs/transition_re_day_workflow.log`

## Decision rule embedded in the workflow

- The validation pack uses the baseline control row `config11_global_control`.
- The comparison target is the best non-baseline row from `transition_re_candidate_selection_summary.csv`.
- Both validation cases rerun at a slightly longer horizon (`max_iter = 8`) with candidate-history diagnostics enabled.

## Current interpretation before the workflow finishes

- The known bottleneck is still localized at period `3`, with pressure around the `4-6` block region.
- The candidate-selection stage is the structural test.
- The validation stage is the confirmation test.
