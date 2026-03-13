# 03_Fertility_and_Housing_Supply

Canonical status tracker: `projects/03_fertility_and_housing_supply/STATUS.md`

## Project type

Pre-paper phase (Markdown-first notes), with planned transition to paper-phase drafting.

## Current status

Empirical work remains the active priority. The live CDC first-birth build and temporary
state-year bridge are in place, and the current bottleneck is still local geography alignment
between county fertility data and the legacy metro-year housing block. On the model side, the
three-way MATLAB comparison has now been refreshed so the reduced-form, old-proxy, and
structural crowding-FOC variants are written up together, but that comparison remains
diagnostic until the empirical baseline is cleaner.

## Current working folders

- `notes/`: active research notes and contribution framing.
- `literature/`: verified source PDFs.
- `code/`: scripts and experiments.
- `data/`, `figures/`, `exports/`: empirical/model artifacts and collaboration outputs.
- `referee/`: reserved for paper-stage response materials.
- `drafts/`: canonical latest paper sources and compiled latest paper PDF.
- `slides/`: canonical latest slide sources and compiled latest slide PDF.

## Draft and slide naming standard

- Latest paper files in `drafts/` (no version suffix):
  - `fertility_and_housing_supply.lyx`
  - `fertility_and_housing_supply.pdf` (when compiled)
- Latest slide files in `slides/` (no version suffix):
  - `fertility_and_housing_supply_slides.lyx`
  - `fertility_and_housing_supply_slides.pdf` (when compiled)
- TeX exports are archived (not shown in root folders):
  - `drafts/old_drafts/source_tex/fertility_and_housing_supply.tex`
  - `slides/old_slides/source_tex/fertility_and_housing_supply_slides.tex`
- Versioned archives only when explicitly requested:
  - `drafts/old_drafts/vNNN/`
  - `slides/old_slides/vNNN/`

## Standards

- Paper structure standard: `_shared/standards/paper_project_structure_standard.md`
- code/calibration standard: `_shared/standards/code_calibration_standard.md`
