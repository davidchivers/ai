# Focus-objective workflow for the transition RE solver

This workflow is the next bounded step after the completed candidate-selection and validation runs.

## Goal

Use a small, explicit worst-period workflow to decide whether the solver can improve the focus
region itself rather than only lowering the global residual norm.

## Why this workflow exists

The current challenger `aggressive_p2_b8_hybrid_relaxed` wins on residual norm and persistence, but
the saved candidate-history diagnostics show that its selected improvements come from the global
rule, not the focus-region rule. That is why it is not yet safe to replace the control benchmark.

## Orchestrator

Run:

- `run_transition_re_focus_objective_workflow.ps1`

What it does:

1. writes `transition_re_objective_tradeoff_report.md`
2. runs `run_transition_re_focus_objective_followup`
3. refreshes `transition_re_followup_report.md`

## Stage outputs

Diagnostic report:

- `transition_re_objective_tradeoff_report.md`
- `workflow_logs/objective_tradeoff_report_stdout.log`
- `workflow_logs/objective_tradeoff_report_stderr.log`

Focus-objective follow-up:

- `transition_re_focus_objective_summary.csv`
- `transition_re_focus_objective_results.mat`
- `workflow_logs/focus_objective_followup_stdout.log`
- `workflow_logs/focus_objective_followup_stderr.log`

Workflow log:

- `workflow_logs/transition_re_focus_objective_workflow.log`

## Focus-objective cases

The run is intentionally narrow. It tests only a few cases:

- relaxed focus mode around the config-11 control profile
- relaxed focus mode around the aggressive `p2_b8` profile
- looser focus slack around the aggressive profile
- wider targeted-region focus around the aggressive profile
- one hybrid "gap guard" case to check whether focus can matter while retaining a global fallback

## Stopping rule

Stop after one clean milestone:

- if a focus-objective case beats the current control on max gap or clearly improves the focus
  region without sacrificing persistence, use that as the next benchmark
- otherwise, stop and use the report outputs to decide whether to resume code review or redesign the
  objective again
