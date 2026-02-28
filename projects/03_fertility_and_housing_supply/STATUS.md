# STATUS - 03_Fertility_and_Housing_Supply

## Snapshot

- Last updated: 2026-02-25 (notes consolidated into living files)
- Overall state: early-stage extension with literature base and prototype code in place; now switched to Markdown-first note workflow.
- 2026-02-25 organization update: added standardized `drafts/` and `slides/` latest-file naming with explicit `old_drafts/` and `old_slides/` archive folders.
- 2026-02-25 capitalization cleanup: folder names standardized to lowercase across the project tree.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Initial utility and fertility-extension notes created from project 02 foundations.
- Empirical literature pack assembled in `literature/` with verified core PDFs.
- Prototype experiment script and convergence diagnostics generated.
- Markdown-first notes scaffolding created in `notes/`.
- Notes consolidated to four living files:
  - `notes/01_project_overview.md`
  - `notes/03_model_notes.md`
  - `notes/04_empirical_notes.md`
  - `notes/02_literature_and_synthesis.md`
- Pre-consolidation standalone notes archived under:
  - `_playground/backups/2026-02-25_notes_flattening/03_fertility_and_housing_supply/Notes_old`
- Folder structure scaffolding for paper transition created:
  - `projects/03_fertility_and_housing_supply/drafts/README.md`
  - `projects/03_fertility_and_housing_supply/calibration/README.md`
  - `projects/03_fertility_and_housing_supply/code/README.md`
  - `projects/03_fertility_and_housing_supply/slides/README.md`
  - canonical latest paper files: `projects/03_fertility_and_housing_supply/drafts/fertility_and_housing_supply.{lyx,pdf}`
  - canonical latest slides files: `projects/03_fertility_and_housing_supply/slides/fertility_and_housing_supply_slides.{lyx,pdf}`
  - tex exports archived in `drafts/old_drafts/source_tex/` and `slides/old_slides/source_tex/`

## In Progress

- Final contribution framing relative to project 02.
- Identification strategy narrowing for first empirical pass.
- Model iteration decisions around stability and calibration targets.

## Next 3 Tasks

1. Finalize contribution + baseline identification in `notes/04_empirical_notes.md`.
2. Expand direct fertility evidence and update `notes/02_literature_and_synthesis.md`.
3. Record model-iteration choices (damping, targets, convergence checks) in `notes/03_model_notes.md`.

## Blockers

- Direct fertility-specific causal evidence remains thinner than broader housing-supply evidence.
- Upstream project 02 fixes still need a complete porting inventory.

## Open Decisions

- Baseline partner-formation treatment (agnostic baseline vs endogenous extension timing).
- Preferred leave-home target in baseline (`A_leave = 18` vs `19`).
- Minimal mechanism set for first paper draft.

## References

- Project overview: `projects/03_fertility_and_housing_supply/README.md`
- Session log: `projects/03_fertility_and_housing_supply/memory.md`
- Project plan: `projects/03_fertility_and_housing_supply/PROJECT_PLAN.md`
- Upstream sync log: `projects/03_fertility_and_housing_supply/UPSTREAM_SYNC_LOG.md`
- Notes index: `projects/03_fertility_and_housing_supply/notes/README.md`
- Canonical latest paper/slide folders: `projects/03_fertility_and_housing_supply/drafts/` and `projects/03_fertility_and_housing_supply/slides/`
- Shared structure standard: `_shared/standards/paper_project_structure_standard.md`
- Shared code/calibration standard: `_shared/standards/code_calibration_standard.md`

## Working Rule

- When asked "where are we?" or to update the to-do list, update this file first.
- Do not remove PDF files from the shared Dropbox export pipeline under `exports/` when those files are required for collaboration deliverables.




