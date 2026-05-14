# Lightweight RE intuition workflow

This is the recommended workflow for the RE extension now that the goal is intuition rather than a
fully converged quantitative benchmark.

## Goal

Produce a defensible extension message about what RE does in the transition, while being explicit
about why a tightly solved RE path is computationally hard in this model.

## Main outputs

- `transition_re_intuition_note.md`
- `transition_re_followup_report.md`
- existing summary CSVs and MAT files as supporting evidence

## Phase 1: freeze the current benchmark

Treat `config11_global_control` as the canonical benchmark for comparison.

Reason:

- it still has the best worst-gap result
- later challenger cases improve average residual fit only by accepting a worse max gap
- pure-focus cases stall too early to replace it

## Phase 2: extract the qualitative RE message

Use the completed outputs to state:

- where RE seems to matter
- where it does not
- which part of the path is numerically problematic
- why current challenger cases should be read as tradeoff evidence rather than as a new benchmark

Primary sources:

- `transition_re_followup_report.md`
- `transition_re_objective_tradeoff_report.md`
- `transition_re_candidate_selection_summary.csv`
- `transition_re_focus_objective_summary.csv`
- `transition_re_validation_summary.csv`

## Phase 3: explain computational hardness

The extension text should make clear that the hard part is structural:

- the fixed point is a whole price path
- each evaluation needs a backward household solve and a forward distribution simulation
- sequential block search requires many such evaluations per outer iteration
- the main bottleneck is localized around period `3`, so objective tradeoffs become sharp

## Optional phase 4: one simplified RE sanity check

Run this phase only if one more number would materially help the extension narrative.

Recommended options:

- coarse continuation only: `lambda = 0`, `0.5`, `1.0`
- shorter-horizon transition emphasizing early periods
- restricted price updates in periods `2-6`
- low-iteration sanity run whose purpose is directional evidence, not convergence

Compute guardrail:

- one small runner
- one summary CSV
- one MAT file
- stop after one clean milestone

## Stopping rule

Stop if the simplified check tells the same qualitative story as the current runs:

- RE effects are present but localized
- period `3` remains the hard region
- the solver can redistribute error more easily than it can remove the main bottleneck

At that point, write up the extension as an intuition exercise with an explicit numerical caution
instead of treating it as an unresolved calibration project.

## Future revisit trigger

After stopping, treat this extension as deferred rather than abandoned.

Come back to it when one of these becomes true:

- a better numerical method for high-dimensional transition-path RE problems is available
- a simplified model version is in hand that preserves the economic intuition while making the RE
  solve much cheaper
- the paper or a follow-on project needs a sharper quantitative RE claim than the current
  qualitative evidence supports
