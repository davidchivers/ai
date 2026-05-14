# Lambda continuation workflow for the RE extension

This is the bounded numerical workflow to use if we want one more RE exercise for intuition while
avoiding another broad tuning campaign.

## Goal

Trace how the RE transition behaves as the demographic transition is gradually turned on.

The purpose is not a tightly converged new benchmark. The purpose is to learn:

- whether the qualitative RE story changes materially as the full demographic transition is restored
- where the numerical difficulty starts
- whether the period-`3` bottleneck only appears near the full-shock case

## Continuation parameter

Let `lambda` scale the demographic transition around the 2010 baseline:

- `lambda = 0`: no demographic transition; every period uses the baseline age profile
- `lambda = 1`: the full demographic path from `age state.csv`
- intermediate values: linear interpolation between those two objects

Implementation file:

- `scale_demographic_path_lambda.m`

## Runner

Main MATLAB runner:

- `run_transition_re_lambda_continuation.m`

PowerShell wrapper:

- `run_transition_re_lambda_continuation.ps1`

Workflow wrapper:

- `run_transition_re_lambda_workflow.ps1`

## Fixed solver settings

Hold the solver rule fixed at the current benchmark profile:

- config-`11` style control settings
- global candidate selection
- greedy acceptance
- no retuning across lambdas

This keeps the continuation run interpretably about the demographic scaling, not about new
algorithm choices.

## Lambda ladder

The coarse ladder is:

- `0.00`
- `0.25`
- `0.50`
- `0.75`
- `1.00`

Each step warm-starts from the previous step's final price path.

## Outputs

- `transition_re_lambda_continuation_summary.csv`
- `transition_re_lambda_continuation_results.mat`
- `workflow_logs/lambda_continuation_stdout.log`
- `workflow_logs/lambda_continuation_stderr.log`
- `workflow_logs/transition_re_lambda_workflow.log`

The summary records, for each `lambda`:

- residual norm
- max gap
- worst period
- whether the solver converged or fell back to `current_path`
- nontrivial update count and last nontrivial iteration
- the price-path span
- the warm-start source

## Stopping rule

This workflow is intentionally bounded.

- run the coarse ladder once
- if the story looks smooth and unchanged, stop
- if the run breaks sharply between two lambdas, refine at most one interval
- then stop again and use the result as intuition rather than a new precision target

## How to read the result

If the continuation ladder shows the same qualitative path shape all the way to `lambda = 1`, that
supports the extension message that RE matters only modestly under the present calibration.

If the numerical problem appears only near high `lambda`, that strengthens the computational note:
the full RE transition becomes hard when the full demographic transition is switched on, not because
the whole framework is degenerate at every scale.
