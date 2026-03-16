# STATUS - 02_Nimbyism_and_Housing_Supply

## Snapshot

- Last updated: 2026-03-16
- Overall state: published paper; now maintained as an upstream base for project 03, with a
  first portability pass and extension workspace scaffold now added.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Paper published in Journal of Monetary Economics (2025).
- Codebase migrated into repository (MATLAB steady-state, Stata pipeline, figures, literature, submission materials).
- Upstream relationship documented for syncing fixes into project 03.
- Added external-path portability helpers so the MATLAB and Stata code can prefer
  `D:\research_data\zac_and_david\...` with Dropbox fallback.
- Added a first post-publication extension workspace under `extensions/re_no_politics/`.
- Added runnable extension copies for a no-politics housing-clearing steady-state benchmark and a
  coalition-weighted voting steady-state benchmark.

## In Progress

- Post-publication maintenance workflow setup (PowerShell-first; optional WSL utilities for PDF-heavy tasks).
- Preparation for first structured code review pass of MATLAB model folders.
- Reframing the extension workspace around the actual target experiment: demographic transition
  forecasts with RE house prices and no coalition voting.

## Next 3 Tasks

1. Build the transition-path RE-price experiment under an exogenous demographic path, keeping the
   no-coalition simplification but not collapsing the model to a new steady state.
2. Reuse the validated transition-matrix loader and path logic in the transition code so the RE
   forecast does not depend on fragile Matlab path order.
3. Run code review of `code/steadystate/` (and then `code/codes_abb/`) against published paper objects.

## Blockers

- No formal code-review output document yet in the project.
- The large external MATLAB `.mat` inputs still live outside this git repo, so portability
  improvements reduce friction but do not make the project fully self-contained.
- The current implemented extension is a steady-state side benchmark, not yet the main transition-path RE experiment.

## Open Decisions

- Scope of maintenance pass: bug-fix-only vs broader refactor.
- Priority order for reviewing `SteadyState/` vs `Codes_ABB/` modules.

## References

- Project overview: `projects/02_nimbyism_and_housing_supply/README.md`
- Session log: `projects/02_nimbyism_and_housing_supply/memory.md`
- Upstream fix log: `projects/02_nimbyism_and_housing_supply/UPSTREAM_FIX_LOG.md`
- Referee report source file: `projects/02_nimbyism_and_housing_supply/referee/Economic Journal Referee Reports.docx`

## Working Rule

- When asked "where are we?" or to update the to-do list, update this file first.
