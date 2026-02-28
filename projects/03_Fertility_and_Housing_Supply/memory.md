# Project Memory - Fertility and Housing Supply

Most recent session first.

---

### Session: 2026-02-25 (global capitalization cleanup applied)
- Standardized project folders to lowercase naming across this project:
  - `calibration/`, `code/`, `data/`, `exports/`, `figures/`, `literature/`, `notes/`, `referee/`, `drafts/`, `slides/`
- Standardized nested exports folder naming:
  - `exports/david_ai_output_with_zac_and_david/`

### Session: 2026-02-25 (clean draft view: lyx/pdf only)
- Applied global clean-view rule for paper folders:
  - keep only latest `.lyx` and `.pdf` visible in `drafts/` and `slides/`
  - move `.tex` exports to archive source paths
  - move LaTeX build artifacts to archive build paths
- Fertility paths now:
  - `drafts/old_drafts/source_tex/fertility_and_housing_supply.tex`
  - `slides/old_slides/source_tex/fertility_and_housing_supply_slides.tex`
  - `drafts/old_drafts/build_artifacts/` and `slides/old_slides/build_artifacts/`
- Global enforcer script used:
  - `_shared/scripts/hide_tex_and_artifacts.ps1`

### Session: 2026-02-25 (drafts and slides naming standardization)
- Normalized folder naming to lowercase:
  - `projects/03_fertility_and_housing_supply/drafts/`
  - `projects/03_fertility_and_housing_supply/slides/`
- Added canonical latest paper filenames (no version suffix):
  - `drafts/fertility_and_housing_supply.lyx`
  - `drafts/fertility_and_housing_supply.tex`
  - `drafts/fertility_and_housing_supply.pdf`
- Added canonical latest slide filenames (no version suffix):
  - `slides/fertility_and_housing_supply_slides.lyx`
  - `slides/fertility_and_housing_supply_slides.tex`
  - `slides/fertility_and_housing_supply_slides.pdf`
- Added explicit version archive folders:
  - `drafts/old_drafts/`
  - `slides/old_slides/`

### Session: 2026-02-25 (paper-transition folder standards)
- Added paper-phase folder placeholders:
  - `projects/03_fertility_and_housing_supply/drafts/README.md`
  - `projects/03_fertility_and_housing_supply/calibration/README.md`
- Added canonical output location guidance:
  - latest output targets in dedicated folders: `drafts/fertility_and_housing_supply.pdf`, `slides/fertility_and_housing_supply_slides.pdf`
- Added code folder standards note:
  - `projects/03_fertility_and_housing_supply/code/README.md`
- Updated project `README.md` and `STATUS.md` to align pre-paper notes workflow with paper-phase transition structure.

### Session: 2026-02-25 (notes auto-organization standard applied)
- Notes were consolidated to no-ranking living files:
  - `notes/01_project_overview.md`
  - `notes/03_model_notes.md`
  - `notes/04_empirical_notes.md`
  - `notes/02_literature_and_synthesis.md`
- Archived pre-consolidation standalone notes under:
  - `_playground/backups/2026-02-25_notes_flattening/03_fertility_and_housing_supply/Notes_old`
- Notes index regenerated with four canonical files:
  - `projects/03_fertility_and_housing_supply/notes/README.md`
- Cross-file note references updated in project docs.

### Session: 2026-02-23 (markdown-first restructure)
- Updated project governance for markdown-first drafting in notes.
- Added canonical notes files:
  - `projects/03_fertility_and_housing_supply/notes/README.md`
  - `projects/03_fertility_and_housing_supply/notes/04_empirical_notes.md`
  - `projects/03_fertility_and_housing_supply/notes/02_literature_and_synthesis.md`
  - `projects/03_fertility_and_housing_supply/notes/03_model_notes.md`
- Updated `README.md` and `STATUS.md` to point active work into Markdown notes.
- Clarified exception: shared Dropbox export workflow in `exports/` should keep PDF deliverables where expected by collaborators.

### Session: 2026-02-23 (single canonical status tracker)
- Added canonical tracker: `projects/03_fertility_and_housing_supply/STATUS.md`
- Set rule that "where are we" and to-do updates should be made in `STATUS.md` first.

### Session: 2026-02-19 (model sketch with endogenous fertility)
- Updated utility-literature note to include partner formation modeling choice and leave-home calibration notes.
- Recompiled utility note PDF and fertility-extension equations note.
- New note documented equilibrium fixed-point and convergence issues when generation size is endogenous.

### Session: 2026-02-20 (empirical housing-supply and fertility lit review)
- Added empirical-first literature review note and populated project-03 literature with verified papers.
- Archived misdownloaded/non-target PDFs under `literature/old/`.
- Key takeaway: direct fertility evidence was thinner than supply-to-price evidence.

### Session: 2026-02-20 (model experiment + empirical idea prioritization)
- Added integrated note covering computational trial, ranked empirical agenda, and expanded designs.
- Implemented and ran prototype code:
  - `projects/03_fertility_and_housing_supply/code/fertility_extension_experiment.py`
- Generated model experiment outputs in `_playground/backups/2026-02-25_notes_flattening/03_fertility_and_housing_supply/Notes_build/`.
- Established export sync workflow to shared collaboration folder.

## Key files

| Role | Path |
|---|---|
| Project plan | `projects/03_fertility_and_housing_supply/PROJECT_PLAN.md` |
| Status tracker | `projects/03_fertility_and_housing_supply/STATUS.md` |
| Notes index | `projects/03_fertility_and_housing_supply/notes/README.md` |
| Upstream sync log | `projects/03_fertility_and_housing_supply/UPSTREAM_SYNC_LOG.md` |
| Upstream source | `projects/02_nimbyism_and_housing_supply/` |





