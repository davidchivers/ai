# STATUS - 03_Fertility_and_Housing_Supply

## Snapshot

- Last updated: 2026-03-13 (three-way MATLAB comparison refreshed; import scripts now prefer D: with Dropbox fallback)
- 2026-03-13 path portability pass: `code/06_import_nimby_birthrates_to_raw.py`,
  `code/07_import_nimby_housing_controls_to_raw.py`, and
  `code/08_import_nimby_population_policy_to_raw.py` now accept `ZAC_DAVID_DATA_DIR`, prefer
  `D:\research_data\zac_and_david\Data`, and fall back to the Dropbox path.
- 2026-03-13 model-comparison refresh: regenerated `notes/build/old_vs_new_model_comparison_report.md`,
  `notes/build/comparison_summary_old_vs_new.csv`, `notes/build/comparison_phase_summary.csv`,
  and the companion comparison plots so the reduced-form, old-proxy, and structural-FOC paths
  are written up in one place.
- 2026-03-09 direct natality pull: added `code/12_pull_cdc_wonder_first_births.py`, pulled the official CDC WONDER `D66` natality extract for `2007-2024` by county-year-age, and wrote `data/raw/cdc_wonder_first_births_export.csv`.
- 2026-03-09 fertility build live: re-imported fertility from the CDC WONDER extract into `data/raw/cdc_fertility_county_year.csv` (`10,890` county-year rows, `2007-2024`), fixed importer parsing for `Age of Mother 10`, and corrected county-derived `state_fips`.
- 2026-03-09 nativity + panel rebuild: ran `code/09_backfill_nativity_from_acs_api.py` and rebuilt `data/processed/us_fertility_housing_panel_v1.csv` plus refreshed coverage/missingness reports.
- 2026-03-09 empirical alignment finding: the modern fertility file overlaps cleanly with county population data but still has zero direct overlap with the legacy housing/control block because those files are metro-year despite their county-style filenames.
- 2026-03-09 exploratory regressions refreshed: rewrote `code/10_exploratory_empirical_regressions.py` to aggregate the raw inputs to state-year, generated `notes/build/exploratory_state_year_panel.csv`, and ran first-birth timing regressions on the feasible overlap sample.
- 2026-03-09 current reduced-form readout: state/year FE coefficients are directionally consistent with delay for rents and age at first birth but imprecise; permits estimates are especially thin because the permits overlap is short and sparse.
- 2026-03-09 check-in: user confirmed that the active priority is empirical work for now; model-side work is deferred until updated MATLAB files are available.
- 2026-03-09 empirical design note: added a candidate pivot from overall fertility to maternal age at first birth / first-birth timing outcomes in `notes/04_empirical_notes.md`; this is written up as an active option, not yet a locked baseline.
- 2026-03-09 empirical reframing: `notes/05_research_plan.md` now centers the near-term agenda on first-birth timing outcomes, reduced-form event studies, and an IV menu that instruments housing supply/cost rather than fertility directly.
- 2026-03-09 empirical state: the raw-source ingest and first processed panel are in place, but the current panel still has large coverage gaps in nativity and housing/control fields, so the immediate bottleneck is panel completion and estimation-ready sample design rather than theory.
- 2026-03-09 exploratory regressions: added `code/10_exploratory_empirical_regressions.py` and generated `notes/build/exploratory_regression_summary.md` plus CSV results; reduced-form sign checks are feasible, but pre-trends are non-flat and permits estimates are imprecise.
- 2026-03-09 panel-alignment finding: current `gfr_15_44` observations are metro-year data from 1940--1995, while `female_pop_15_44` is county-year data from 2010--2018; overlap is zero, so the current merged panel does not support the intended nativity-adjusted modern baseline.
- 2026-03-09 source decision: locked the main empirical path to a modern natality-based fertility build and demoted the historical metro `gfr_15_44` panel to archival sign-check status; see `notes/build/fertility_source_decision.md`.
- 2026-03-09 implementation step: added a CDC WONDER importer (`code/11_import_cdc_wonder_first_births.py`), a direct puller (`code/12_pull_cdc_wonder_first_births.py`), and updated pull instructions in `notes/build/cdc_wonder_first_birth_pull_instructions.md`.
- 2026-03-09 verification: the new WONDER importer plus panel builder were verified end-to-end on a temporary synthetic county-year sample before the live repo rebuild.
- 2026-03-09 official source constraint check: CDC WONDER county residence is usable for 2007--2024, but only counties with population >=100,000 are individually identified and sub-national counts 1--9 are suppressed; this makes state-year a realistic first unrestricted fallback.
- 2026-03-02 check-in: panel baseline outcome and geography-time unit are locked; fertility/housing/controls now contain observed rows in `data/raw/` and are propagated into processed panel build.
- 2026-03-02 model/data audit: NIMBY-style write-up guidance with explicit project-03 differences is documented; remaining empty source blocks are policy timing and population/immigration.
- 2026-03-02 drafting update: `drafts/fertility_and_housing_supply.lyx` was rebuilt from latest NIMBY v13 structure, trimmed to model-only sections on request, and updated with blue-highlighted project-03 differences plus simulation evidence.
- 2026-03-02 coding clarification: current MATLAB prototype includes reduced-form fertility response, lagged-boom political term, and children-at-home demand proxy; full crowding utility is written in the paper but not yet solved as the structural household DP block in code.
- Overall state: empirical infrastructure is built but not yet estimation-ready; main remaining work is nativity completion, panel coverage cleanup, and baseline empirical specification.
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
- Refreshed the three-way MATLAB comparison write-up after rerunning the comparison bundle:
  - `notes/build/old_vs_new_model_comparison_report.md`
  - `notes/build/comparison_summary_old_vs_new.csv`
  - `notes/build/comparison_phase_summary.csv`
  - `notes/build/old_vs_new_paths.png`
  - `notes/build/old_vs_new_policy_effects.png`
  - `notes/build/model_experiment_paths.png`
- Import scripts for legacy project-02 source files now use a portable root-selection rule:
  - explicit environment variable `ZAC_DAVID_DATA_DIR` if set
  - otherwise `D:\research_data\zac_and_david\Data`
  - otherwise Dropbox fallback
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
- Exploratory regression scaffold added and run on current processed panel:
  - script: `code/10_exploratory_empirical_regressions.py`
  - outputs:
    - `notes/build/exploratory_regression_summary.md`
    - `notes/build/exploratory_regression_results.csv`
  - main readout:
    - treated-post coefficient on historical `gfr_15_44` sample is negative
    - rent coefficient is negative on the small overlap sample
    - event-study bins show non-flat pre-trends
    - permits coefficient is imprecise
- Fertility-source decision note added:
  - `notes/build/fertility_source_decision.md`
  - main decision:
    - use modern natality data for the baseline empirical build
    - keep legacy historical metro fertility series only for provisional sign checks
- Modern first-birth timing import scaffold added:
  - script: `code/11_import_cdc_wonder_first_births.py`
  - companion instructions: `notes/build/cdc_wonder_first_birth_pull_instructions.md`
  - builder updates:
    - `code/05_build_us_panel_from_sources.ps1` now carries first-birth timing fields
    - `code/05_build_us_panel_from_sources.ps1` now allows `state_fips`-only fallback keys
    - `first_birth_rate_15_44` can be derived after merge when `female_pop_15_44` is present
  - verification:
    - temp end-to-end county-year test passed
- Direct CDC WONDER pull + refreshed empirical pass completed:
  - new puller: `code/12_pull_cdc_wonder_first_births.py`
  - official extract saved: `data/raw/cdc_wonder_first_births_export.csv`
  - imported fertility file refreshed: `data/raw/cdc_fertility_county_year.csv` (`10,890` rows)
  - ACS nativity backfill run in place: `data/raw/population_immigration_county_year.csv`
  - processed panel rebuilt: `data/processed/us_fertility_housing_panel_v1.csv` (`64,194` rows including unmatched source rows)
  - new exploratory bridge file: `notes/build/exploratory_state_year_panel.csv`
  - updated regression outputs:
    - `notes/build/exploratory_regression_summary.md`
    - `notes/build/exploratory_regression_results.csv`
- Ingestion pipeline aligned with project-02 (NIMBY) identifier style:
  - supports canonical ids plus aliases (`STCOU`, `CBSA`, `statefips`, `met2013`, `YEAR`)
  - includes `metarea` and `metareano` compatibility columns in panel schema
- Legacy/duplicate clutter folders removed:
  - `code-David_Laptop/`
  - `literature-David_Laptop/`
  - `exports/david_ai_output_with_zac_and_david/_archive-David_Laptop/`

## In Progress

- Auditing geography alignment after the live CDC pull: fertility and population now align at county-year, but the housing/policy block is still metro-year.
- Deciding whether the first empirical baseline should be a state-year bridge, a county-to-metro aggregation using a crosswalk, or a replacement housing source with county/CBSA identifiers.
- Tightening the first regression-ready specification around first-birth timing outcomes rather than the deprecated `gfr_15_44` path.
- Evaluating IV feasibility, with current preference for a reform-exposure instrument targeting housing outcomes.
- Treating the state-year exploratory panel as a temporary bridge rather than the final paper design.
- Keeping the refreshed structural crowding-FOC comparison as a diagnostic/model note, not as
  the current binding workstream while empirical cleanup remains the priority.

## Next 3 Tasks

1. Resolve geography mismatch on the housing side: either build a county-to-metro/CBSA crosswalk for the CDC fertility sample or replace the legacy metro housing source with a county/CBSA-compatible panel.
2. Use the temporary state-year bridge in `notes/build/exploratory_state_year_panel.csv` to expand timing regressions, weighting choices, and specification checks while the local-geometry fix is being built.
3. Decide whether the baseline empirical design is temporarily state-year or whether the paper waits for a cleaner county/CBSA housing merge.

## Blockers

- Upstream project-02 steady-state MATLAB inputs (for example `nl_zbl.mat` / `TransitionMatrix.mat`) are not present in this repo copy.
- Updated MATLAB files for the next model iteration are still pending from the user; model integration work is paused until those files arrive.
- Direct fertility-specific causal evidence remains thinner than broader housing-supply evidence.
- Legacy NIMBY fertility inputs exist locally in Dropbox but are outside this git repo, so reproducibility currently depends on local external paths.
- ACS nativity backfill script (`code/09_backfill_nativity_from_acs_api.py`) now handles 2010-2013 via B06001+B06003 fallback; minor approximation remains (ages 18-44 not 15-44) for those years.
- The current housing and policy raw files are metro-year rather than county-year, so they do not directly merge to the new county fertility file.
- The legacy permits series has much thinner overlap than rents in the temporary state-year bridge.

## Open Decisions

- County-cell suppression threshold for fallback aggregation to `cbsa`-year.
- Exact treatment of zero-birth or near-zero cells in transformed outcomes such as `ln_gfr_15_44`.
- Whether policy timing is coded purely at state level first and then mapped into local exposure intensity.
- Whether maternal age at first birth should be the headline timing summary or a supporting summary behind age-bin first-birth shares/rates.
- Whether the first unrestricted implementation should begin with large-county county-year or directly at state-year in CDC WONDER.
- Which IV path, if any, is credible enough for the first empirical paper: reform exposure, close-election politics, or supply-elasticity interactions.

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




