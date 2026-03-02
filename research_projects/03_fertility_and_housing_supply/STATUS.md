# STATUS - 03_Fertility_and_Housing_Supply

## Snapshot

- Last updated: 2026-03-02 (structural FOC implementation + nativity fix + draft cleanup)
- 2026-03-02 check-in: panel baseline outcome and geography-time unit are locked; fertility/housing/controls now contain observed rows in `data/raw/` and are propagated into processed panel build.
- 2026-03-02 model/data audit: NIMBY-style write-up guidance with explicit project-03 differences is documented; remaining empty source blocks are policy timing and population/immigration.
- 2026-03-02 drafting update: `drafts/fertility_and_housing_supply.lyx` was rebuilt from latest NIMBY v13 structure, trimmed to model-only sections on request, and updated with blue-highlighted project-03 differences plus simulation evidence.
- 2026-03-02 coding clarification: current MATLAB prototype includes reduced-form fertility response, lagged-boom political term, and children-at-home demand proxy; full crowding utility is written in the paper but not yet solved as the structural household DP block in code.
- Overall state: model write-up is now close to target style and transparent about code-vs-theory alignment; main remaining work is full structural code alignment and nativity-source completion.
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
- MATLAB experiment runner added in `code/` and latest outputs regenerated under `notes/build/`.
- Model note rewritten with explicit equations, calibration interpretation limits, and baby-boom experiment design:
  - `notes/03_model_notes.md`
- Full manuscript draft written and compiled:
  - text: `drafts/fertility_and_housing_supply.txt`
  - source tex: `drafts/old_drafts/source_tex/fertility_and_housing_supply.tex`
  - pdf: `drafts/fertility_and_housing_supply.pdf`
- US fertility panel blueprint with immigration-aware decomposition added:
  - `notes/04_empirical_notes.md`
- Baseline empirical target lock completed in notes:
  - primary outcome set to `gfr_15_44` with `ln_gfr_15_44` robustness
  - baseline panel unit/year set to county-year, 2005--2023
  - explicit nativity decomposition fields and formulas added
- NIMBY-style model write-up block with explicit project-03 deltas added:
  - utility/fertility channel differences
  - political-equilibrium lagged-boom term
  - quantified new-vs-old proxy result differences from latest MATLAB output
  - file: `notes/03_model_notes.md`
- Real fertility source ingest from legacy NIMBY Dropbox data completed:
  - new importer: `code/06_import_nimby_birthrates_to_raw.py`
  - source used: `C:/Users/Dave_/Dropbox/Zac and David/Data/merged_birthrates_migrationweights.dta`
  - output updated: `data/raw/cdc_fertility_county_year.csv` (30,263 observations)
  - ingest log: `notes/build/us_fertility_ingest_log.md`
- Legacy housing/control source ingest completed:
  - new importer: `code/07_import_nimby_housing_controls_to_raw.py`
  - source used: `C:/Users/Dave_/Dropbox/Zac and David/Data/addedpermits.dta`
  - outputs updated:
    - `data/raw/housing_county_year.csv` (5,708 observations)
    - `data/raw/controls_county_year.csv` (4,667 observations)
  - ingest log: `notes/build/us_housing_controls_ingest_log.md`
- Population + policy legacy ingest completed:
  - new importer: `code/08_import_nimby_population_policy_to_raw.py`
  - outputs updated:
    - `data/raw/population_immigration_county_year.csv` (16,425 observations)
    - `data/raw/policy_reforms_county_year.csv` (41,865 observations)
  - ingest log: `notes/build/us_population_policy_ingest_log.md`
- Source-panel build script bugfix applied for real-data merge:
  - `code/05_build_us_panel_from_sources.ps1` updated to use OrderedDictionary-compatible key checks
  - processed panel rebuilt with non-zero rows: `data/processed/us_fertility_housing_panel_v1.csv` (58,343 data rows; 58,344 including header)
  - coverage report refreshed: `notes/build/us_panel_source_coverage.md`
- Structural crowding-FOC fertility model implemented in MATLAB:
  - new function `simulate_structural_model()` in `code/run_experiments_matlab_main.m`
  - fertility derived from utility FOC: chi*n^(-eta) = marginal crowding cost
  - representative-agent allocation: c = (1-zeta)*y, h = zeta*y/p
  - bisection solver in `solve_fertility_foc()` and `foc_residual()`
  - runs alongside reduced-form and old-proxy for three-way comparison
  - plots and phase-delta tables updated to include structural model
- ACS nativity backfill script fixed for 2010-2013:
  - `code/09_backfill_nativity_from_acs_api.py` now uses B06001+B06003 fallback for years where B05013 is unavailable
  - 2014+ still uses B05013 directly
  - minor approximation: 2010-2013 covers ages 18-44 (not 15-44) due to B06001 bin boundaries
- Model draft notation cleanup:
  - fixed `\psi` collision: crowding exponent now `\psi_c`, bequest parameter remains `\psi`
  - fixed equation cross-references (eq 4->8 for bequest, eq 14->18 for voting condition)
  - fixed "Medan" -> "Median" Voter Theorem typo
  - fixed "Section 6" -> "robustness section" (section was removed in model-only view)
  - added augmented state vector note with `n_{t,home}` for fertility extension
  - fixed blue-block colour consistency for eq 6 explanation text
- Model draft rewritten to match latest NIMBY source style:
  - base source used: `C:/Users/Dave_/Dropbox/Zac and David/NIMBYism and the Housing Supply v13.lyx~`
  - canonical draft: `drafts/fertility_and_housing_supply.lyx`
  - canonical pdf: `drafts/fertility_and_housing_supply.pdf`
- Model-only paper view produced on request:
  - retained section: `The Model` (with subsections)
  - removed from active draft: introduction, related literature, calibration/quantitative/robustness/conclusion sections
- Blue-highlighted project-03 write-up blocks added in model section:
  - crowding-based fertility utility
  - children-at-home state transition
  - lagged-boom political-equilibrium term
  - demand channel with children-at-home pressure
  - explicit code-alignment note (what is and is not yet fully structural in MATLAB)
- Existing MATLAB simulation outputs inserted into draft:
  - figures copied into `drafts/Figures/`
  - included charts: `old_vs_new_paths.png`, `old_vs_new_policy_effects.png`
  - numerical deltas from `notes/build/comparison_phase_summary.csv` added in text
- US panel scaffold artifacts generated:
  - `data/processed/us_fertility_housing_panel_v1.csv`
  - `notes/build/us_panel_data_dictionary.md`
  - `notes/build/us_panel_missingness_report.md`
  - generator script: `code/04_build_us_panel_scaffold.ps1`
- Source-ingestion build pipeline added:
  - `code/05_build_us_panel_from_sources.ps1`
  - input templates in `data/raw/`
  - coverage diagnostics in `notes/build/us_panel_source_coverage.md`
- Ingestion pipeline aligned with project-02 (NIMBY) identifier style:
  - supports canonical ids plus aliases (`STCOU`, `CBSA`, `statefips`, `met2013`, `YEAR`)
  - includes `metarea` and `metareano` compatibility columns in panel schema
- Legacy/duplicate clutter folders removed:
  - `code-David_Laptop/`
  - `literature-David_Laptop/`
  - `exports/david_ai_output_with_zac_and_david/_archive-David_Laptop/`

## In Progress

- Calibration tuning of structural FOC parameters (chi, eta_child, lambda_crowd, psi_crowd) against empirical fertility-price relationships.
- Running nativity backfill script against Census API and rebuilding panel with `code/05_build_us_panel_from_sources.ps1`.
- Data plan and panel design for fertility + housing + immigration integration.

## Next 3 Tasks

1. Run the updated MATLAB experiments (`01_run_experiments_matlab.m`) to generate structural-vs-reduced-form comparison outputs; calibrate structural parameters to match empirical fertility-price semi-elasticity.
2. Run nativity backfill (`code/09_backfill_nativity_from_acs_api.py`) and rebuild panel (`code/05_build_us_panel_from_sources.ps1`); refresh coverage and missingness reports.
3. Extend the structural model toward heterogeneous agents: port the FOC-based fertility choice into the project-02 value-function-iteration household block once upstream `.mat` inputs are available.

## Blockers

- Upstream project-02 steady-state MATLAB inputs (for example `nl_zbl.mat` / `TransitionMatrix.mat`) are not present in this repo copy.
- Direct fertility-specific causal evidence remains thinner than broader housing-supply evidence.
- Legacy NIMBY fertility inputs exist locally in Dropbox but are outside this git repo, so reproducibility currently depends on local external paths.
- ACS nativity backfill script (`code/09_backfill_nativity_from_acs_api.py`) now handles 2010-2013 via B06001+B06003 fallback; minor approximation (ages 18-44 not 15-44) for those years. Needs to be run against the API and panel rebuilt.

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




