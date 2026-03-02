# STATUS - 02_Nimbyism_and_Housing_Supply

## Snapshot

- Last updated: 2026-02-23
- Overall state: published paper; now maintained as an upstream base for project 03.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Paper published in Journal of Monetary Economics (2025).
- Codebase migrated into repository (MATLAB steady-state, Stata pipeline, figures, literature, submission materials).
- Upstream relationship documented for syncing fixes into project 03.

## In Progress

- Post-publication maintenance workflow setup (PowerShell-first; optional WSL utilities for PDF-heavy tasks).
- Preparation for first structured code review pass of MATLAB model folders.

## Next 3 Tasks

1. Run code review of `code/steadystate/` (and then `code/codes_abb/`) against published paper objects.
2. Log any model-relevant fixes in `UPSTREAM_FIX_LOG.md` with date and rationale.
3. Evaluate each upstream fix for porting into `projects/03_fertility_and_housing_supply/UPSTREAM_SYNC_LOG.md`.

## Blockers

- No formal code-review output document yet in the project.

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
