# STATUS - 02_Nimbyism_and_Housing_Supply

## Snapshot

- Last updated: 2026-03-13
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

## In Progress

- Post-publication maintenance workflow setup (PowerShell-first; optional WSL utilities for PDF-heavy tasks).
- Preparation for first structured code review pass of MATLAB model folders.
- Low-risk design work for the no-politics rational-expectations extension, without editing the
  published baseline solver files directly.

## Next 3 Tasks

1. Validate the new `D:`-first external path helper on the actual MATLAB/Stata runtime and log
   any remaining missing-path failures.
2. Run code review of `code/steadystate/` (and then `code/codes_abb/`) against published paper objects.
3. Start the first copied no-politics extension solver only after the portability pass is confirmed stable.

## Blockers

- No formal code-review output document yet in the project.
- The large external MATLAB `.mat` inputs still live outside this git repo, so portability
  improvements reduce friction but do not make the project fully self-contained.

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
