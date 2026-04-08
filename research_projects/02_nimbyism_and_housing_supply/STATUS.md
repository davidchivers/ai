# STATUS - 02_Nimbyism_and_Housing_Supply

## Snapshot

- Last updated: 2026-03-09
- Overall state: published paper; now maintained as an upstream base for project 03.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Paper published in Journal of Monetary Economics (2025).
- Codebase migrated into repository (MATLAB steady-state, Stata pipeline, figures, literature, submission materials).
- Upstream relationship documented for syncing fixes into project 03.

## In Progress

- Post-publication maintenance workflow setup (PowerShell-first; optional WSL utilities for PDF-heavy tasks).
- Preparation for first structured code review pass of MATLAB model folders.
- Separate extension workspace for an anticipated-demographics rational-voting benchmark created under `extension/`; reduced-form toy experiment runs, structural version awaits missing MATLAB inputs.

## Next 3 Tasks

1. Run code review of `code/steadystate/` (and then `code/codes_abb/`) against published paper objects.
2. Log any model-relevant fixes in `UPSTREAM_FIX_LOG.md` with date and rationale.
3. Evaluate each upstream fix for porting into `projects/03_fertility_and_housing_supply/UPSTREAM_SYNC_LOG.md`.

## Blockers

- No formal code-review output document yet in the project.
- Structural extension work is blocked by excluded MATLAB inputs and endpoint objects not present in this git repo (for example legacy `.mat` inputs such as `nl_zbl.mat`, `TransitionMatrix`, and saved boom/baseline endpoint outputs).

## Open Decisions

- Scope of maintenance pass: bug-fix-only vs broader refactor.
- Priority order for reviewing `SteadyState/` vs `Codes_ABB/` modules.
- If extension work resumes, whether to stop at the anticipated-demographics RE benchmark or also prototype an explicit coalition extension.

## Extension Track

### Anticipated-demographics RE benchmark

- Goal: allow households to vote forward-looking based on the boom-driven projected future electorate, while keeping no coalitions, no bargaining across dates, and no feedback from today's vote into future voter composition.
- Math note: `extension/anticipated_demographics_re.md`
- Current write-up: `extension/current_findings.md`
- MATLAB toy benchmark: `extension/matlab/run_anticipated_demographics_re_toy.m`
- MATLAB structural scaffold: `extension/matlab/run_anticipated_demographics_re_structural.m`
- Automatic pipeline: `extension/matlab/run_extension_pipeline.m` with PowerShell entrypoint `extension/run_extension_pipeline.ps1`
- Latest toy-result read: forward-looking anticipated demographics materially amplifies/front-loads the price path relative to the myopic benchmark in the reduced-form prototype.

### Planned next steps when MATLAB inputs are restored

1. Recover the missing structural MATLAB inputs / saved endpoint objects from the legacy local environment.
2. Place raw `SS_iter.mat` and `SS_iter_boom.mat` into `extension/input/` (or restore them under `code/steadystate/`) and run `extension/run_extension_pipeline.ps1`.
3. Let the pipeline export baseline and boom endpoint objects automatically, then compare myopic versus anticipated-demographics transition paths.

### Coalition extension shortlist

- Simplest: reduced-form coalition premium that shifts voting support when aligned adjacent cohorts cross a mass threshold.
- Better intermediate: turnout- or influence-weighted bloc voting by cohort with exogenous coalition weights.
- Best structural version: dynamic coalition formation where current policy affects future tenure and future bloc composition; this is much harder and should come only after the anticipated-demographics benchmark.
- Separate note added: `extension/static_bloc_coordination.md`

## References

- Project overview: `projects/02_nimbyism_and_housing_supply/README.md`
- Session log: `projects/02_nimbyism_and_housing_supply/memory.md`
- Upstream fix log: `projects/02_nimbyism_and_housing_supply/UPSTREAM_FIX_LOG.md`
- Referee report source file: `projects/02_nimbyism_and_housing_supply/referee/Economic Journal Referee Reports.docx`
- Extension workspace: `projects/02_nimbyism_and_housing_supply/extension/`

## Working Rule

- When asked "where are we?" or to update the to-do list, update this file first.
