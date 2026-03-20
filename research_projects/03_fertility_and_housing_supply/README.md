# 03_Fertility_and_Housing_Supply

Canonical status tracker: `STATUS.md`

## Project type

Paper-phase drafting is now underway, with the notes/build comparison pack still serving as the
model-validation workspace.

## Current status

The corrected-code calibration sweep is now complete and confirms that the active household
fertility benchmark did not move after the forward-pass mass fix. The benchmark remains
centralized through `code/fertility_benchmark_config.m`, reproduces the upstream project-02
solver exactly in the `C = 1` shutoff case, and still delivers a unique vote crossing at
`a_price ~= 1.751853` on the `I = 60`, `J = 14` grid.

There is now a paper draft in `drafts/`:
`drafts/fertility_and_housing_supply.tex` and `drafts/fertility_and_housing_supply.pdf`.
That draft turns the comparison pack into a standalone manuscript built around four model results:
the lower steady-state crossing under fertility, the amplified baby-boom price response, the
modest improvement in postwar fertility-fit, and the flatter long-run aging projection under the
fertility bridge.

The model-side presentation refresh is now complete: the NIMBY-versus-fertility comparison
bundle has been rebuilt so the note and figures report both raw vote and normalized
vote-per-mass after the mass-scaling fix. The empirical geography mismatch between county
fertility data and the legacy metro-year housing/control block is again the main paper
bottleneck, with benchmark-presentation tradeoffs now a secondary framing choice.

There is now also a separate paper-style model-comparison note in `notes/build/`:
`nimby_vs_fertility_model_comparison.pdf`. It follows the Gross and Chivers model-section order,
states the exact household-utility and state-space changes in the fertility extension, keeps
implementation detail in an appendix, and replaces the copied NIMBY placeholders with genuine
steady-state comparison figures.

That note now also includes a direct baby-boom transition comparison. The upstream NIMBY line is
taken from the original smoothed IRF object in Dropbox, while the fertility line is generated from
the matched project-03 transition run under the same temporary `+10%` birth shock for 10 periods.
The transition section now also includes NIMBY-style young/old homeownership panels and a cohort
homeownership-access comparison. On the fertility side these are explicitly labeled proxy objects:
they are built from a common age profile plus the model-implied house-price path, because the
current transition block still does not solve explicit tenure or savings choices.

It now also includes a historical validation section for the postwar fertility decline. Using the
legacy aggregate birth-rate series and aligning the post-boom decline from `1956` onward to model
period `t >= 10`, the fertility extension fits the post-boom decline modestly better than the
flat NIMBY return path at every checked horizon. The note now also includes a bounded baby-boom
robustness section and a future demographic-projection bridge. The projection comparison uses the
upstream forecast age-weight scenarios, but the two lines are matched bridge objects: a NIMBY
proxy with the fertility-demand channel shut off, and the fertility bridge with births plus
children-at-home in the demand block. The richer wealth and exact forecast-solver objects used in
the NIMBY paper are still not available on the fertility side.

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
  - `fertility_and_housing_supply.tex`
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
