# STATUS - 03_Fertility_and_Housing_Supply

## Snapshot

- Last updated: 2026-03-20 (persistent NIMBY-shock scenario grid and calibration sensitivity added)
- 2026-03-20 persistent NIMBY-shock scenario grid added:
  - `code/build_nimby_shock_scenarios.py`
  - `notes/build/nimby_shock_scenario_grid.csv`
  - `notes/build/nimby_shock_calibration_sensitivity.csv`
  - `notes/build/nimby_shock_scenarios.md`
  - `notes/build/nimby_shock_scenarios.png`
  - `notes/build/nimby_shock_scenarios.pdf`
  The long-run fertility result is now shown to be monotone in persistent NIMBY intensity. In the
  medium-immigration projection, moving from `theta0 + 0.03` to `theta0 + 0.10` lowers projected
  `2100` fertility from about `0.180` to about `0.167` against a baseline of about `0.188`, while
  the projected `2100` house-price index rises from about `1.562` to about `2.281` against a
  baseline of about `1.254`. Nearby changes in fertility-price sensitivity and family-demand
  strength leave the sign of the result unchanged.
- Last updated: 2026-03-20 (persistent NIMBY-shock fertility counterfactual added)
- 2026-03-20 persistent NIMBY-shock counterfactual added:
  - `code/build_nimby_shock_fertility_counterfactual.py`
  - updated `code/nimby_fertility_transition_bridge.py`
  - `notes/build/nimby_shock_transition_series.csv`
  - `notes/build/nimby_shock_projection_series.csv`
  - `notes/build/nimby_shock_fertility_counterfactual_summary.csv`
  - `notes/build/nimby_shock_fertility_counterfactual.md`
  - `notes/build/nimby_shock_fertility_counterfactual.png`
  - `notes/build/nimby_shock_fertility_counterfactual.pdf`
  - updated `notes/build/nimby_vs_fertility_model_comparison.pdf`
  - updated `drafts/fertility_and_housing_supply.pdf`
  The long-run dynamic object has been redirected away from the aging-only bridge and toward a
  more relevant supply-tightening counterfactual. Starting from a shared baseline and imposing a
  permanent increase in baseline political tightness, the model now delivers the paper's intended
  mechanism directly: sustained housing scarcity raises future house prices and lowers realized
  fertility.
- Last updated: 2026-03-20 (standalone manuscript draft written and compiled)
- 2026-03-20 standalone manuscript draft added:
  - `drafts/fertility_and_housing_supply.tex`
  - `drafts/fertility_and_housing_supply.pdf`
  The comparison note has now been turned into a paper draft. The draft is written as a
  standalone fertility-and-housing paper rather than as a code memo or a project-03 delta note.
  It keeps the exact benchmark comparison, the baby-boom section, the historical validation, the
  bounded robustness pass, and the future demographic-projection bridge, while labeling the
  projection object honestly as a matched bridge rather than the full project-02 forecast solver.
- Last updated: 2026-03-20 (robustness and future-projection bridge added)
- 2026-03-20 robustness and future-projection bridge added:
  - `code/nimby_fertility_transition_bridge.py`
  - `code/build_nimby_vs_fertility_transition_robustness.py`
  - `code/export_nimby_forecast_reference_main.m`
  - `code/build_nimby_vs_fertility_projection_comparison.py`
  - `notes/build/nimby_vs_fertility_transition_robustness.png`
  - `notes/build/nimby_vs_fertility_transition_robustness.pdf`
  - `notes/build/nimby_vs_fertility_transition_robustness.csv`
  - `notes/build/nimby_vs_fertility_projection_comparison.png`
  - `notes/build/nimby_vs_fertility_projection_comparison.pdf`
  - `notes/build/nimby_vs_fertility_projection_summary.csv`
  - updated `notes/build/nimby_vs_fertility_model_comparison.pdf`
  The comparison note now includes a bounded baby-boom robustness section and a future
  demographic-projection bridge. The robustness bridge reproduces the MATLAB benchmark policy
  runs to machine precision before varying shock size, price sensitivity, and family-demand
  strength. The projection section uses the upstream forecast age weights but compares a matched
  NIMBY proxy against the fertility bridge rather than the full project-02 forecast solver.
- Last updated: 2026-03-20 (transition tenure and cohort proxy comparison added)
- 2026-03-20 transition tenure and cohort proxy comparison added:
  - updated `code/run_experiments_matlab_main.m`
  - updated `code/plot_nimby_vs_fertility_transition_figures.py`
  - `notes/build/nimby_vs_fertility_generation_homeownership.png`
  - `notes/build/nimby_vs_fertility_generation_homeownership.pdf`
  - `notes/build/nimby_vs_fertility_transition_proxy_series.csv`
  - updated `notes/build/nimby_vs_fertility_baby_boom_transition.png`
  - updated `notes/build/nimby_vs_fertility_baby_boom_summary.csv`
  - updated `notes/build/nimby_vs_fertility_model_comparison.pdf`
  The baby-boom comparison note now includes NIMBY-style tenure-access panels and a cohort
  homeownership-access comparison. On the fertility side these are explicitly reduced-form proxy
  objects, not structural tenure choices, because the current transition block still has no
  savings or tenure state. Even so, the new panels show a materially larger young-homeownership
  decline in the fertility transition and a stronger hit to the later child generation than to the
  parent generation.
- Last updated: 2026-03-20 (historical validation and projection input bridge added)
- 2026-03-20 historical validation and projection input bridge added:
  - `notes/build/nimby_vs_fertility_historical_validation.png`
  - `notes/build/nimby_vs_fertility_historical_validation.pdf`
  - `notes/build/nimby_vs_fertility_historical_validation.md`
  - `notes/build/nimby_vs_fertility_historical_validation_summary.csv`
  - `notes/build/nimby_vs_fertility_historical_validation_series.csv`
  - `notes/build/nimby_projection_age_groups.png`
  - `notes/build/nimby_projection_age_groups.pdf`
  - `notes/build/nimby_projection_age_groups.md`
  - `notes/build/nimby_projection_age_groups.csv`
  - `notes/build/nimby_baby_boom_reference_full.csv`
  - updated `notes/build/nimby_vs_fertility_model_comparison.pdf`
  The comparison note now includes a historical postwar fertility validation section. Using the
  aggregate legacy fertility series and aligning the decline from `1956` onward to model period
  `t >= 10`, the fertility extension fits the post-boom decline modestly better than the NIMBY
  path at each checked horizon (`10`, `20`, `30`, `40` years). The upstream NIMBY transition
  export now also includes the richer homeownership and generational objects needed for the next
  comparison pass, and the NIMBY paper's age-share projection input has been localized into the
  project-03 build folder.
- Last updated: 2026-03-20 (baby-boom transition comparison added to model note)
- 2026-03-20 baby-boom transition comparison added:
  - `notes/build/nimby_baby_boom_reference.csv`
  - `notes/build/nimby_baby_boom_reference_source.txt`
  - `notes/build/nimby_vs_fertility_baby_boom_transition.png`
  - `notes/build/nimby_vs_fertility_baby_boom_transition.pdf`
  - `notes/build/nimby_vs_fertility_baby_boom_summary.csv`
  - updated `notes/build/nimby_vs_fertility_model_comparison.pdf`
  The comparison note now includes a direct temporary-birthrate-increase section using the
  upstream NIMBY smoothed IRF object from Dropbox and a matched fertility transition run under
  the same `+10%` shock for 10 periods. In normalized units, the average post-window price
  response is about `0.020` in the NIMBY transition versus about `0.051` in the fertility
  transition.
- Last updated: 2026-03-20 (NIMBY-style model comparison note compiled)
- 2026-03-20 NIMBY-style model comparison note added:
  - `notes/build/nimby_vs_fertility_model_comparison.tex`
  - `notes/build/nimby_vs_fertility_model_comparison.pdf`
  - `notes/build/nimby_vs_fertility_household_support.png`
  - `notes/build/nimby_vs_fertility_household_support.pdf`
  - `notes/build/nimby_vs_fertility_benchmark_objects.png`
  - `notes/build/nimby_vs_fertility_benchmark_objects.pdf`
  This note follows the Gross and Chivers model-section order, keeps the main text at the model
  level rather than the implementation level, moves solver details to an appendix, and replaces
  the copied NIMBY figure placeholders with genuine steady-state redraws from the current NIMBY
  and fertility benchmark objects.
- Last updated: 2026-03-20 (corrected calibration sweep confirmed benchmark; comparison refresh completed)
- 2026-03-20 comparison refresh completed:
  - `notes/build/fertility_vs_nimby_benchmark_report.md`
  - `notes/build/fertility_vs_nimby_benchmark_report.pdf`
  - `notes/build/fertility_vs_nimby_benchmark_summary.csv`
  - `notes/build/fertility_vs_nimby_common_price_grid.csv`
  - `notes/build/fertility_vs_nimby_benchmark_panels.png`
  - `notes/build/fertility_vs_nimby_benchmark_panels.pdf`
  The public-facing comparison bundle now reflects both raw `totalvote` and normalized
  `vote_per_mass`, plus stationary mass, debt, and family-state diagnostics under the corrected
  benchmark.
- 2026-03-19 corrected calibration sweep completed after the forward-pass mass fix:
  - `notes/build/fertility_calibration_report.md`
  - `notes/build/fertility_calibration_sweep.csv`
  - `notes/build/fertility_calibration_market_checks.csv`
  The sweep confirms that the current solver defaults remain both the best full demographic
  candidate and the best full benchmark candidate under the corrected code.
- 2026-03-19 benchmark confirmation:
  - candidate `1` and current defaults are the same object
  - benchmark remains `I = 60`, `J = 14`
  - unique market crossing remains at approximately `a_price = 1.751853`
  - age-50 completed fertility remains `[0.2237, 0.2556, 0.2927, 0.2280]`
- 2026-03-19 comparison-layer refresh prepared:
  - `code/write_fertility_vs_nimby_benchmark_main.m` now reports both raw `totalvote`
    and normalized `vote_per_mass`, plus stationary mass
  - `code/plot_fertility_vs_nimby_benchmark.py` now builds a six-panel figure
    separating raw vote, normalized vote, debt, mass, and family outcomes
  - `code/refresh_corrected_benchmark_outputs.ps1` now reruns the benchmark reports,
    figure build, and PDF compile in one step
- 2026-03-19 stale-job cleanup:
  duplicate timed-out MATLAB calibration jobs were killed so they could not overwrite the
  same benchmark output files.
- 2026-03-18 benchmark freeze: added `code/fertility_benchmark_config.m` as the single source
  of truth for the corrected-code household benchmark, and updated
  `code/run_ge_fertility_main.m` plus `code/calibrate_fertility_block_main.m` to read from it.
- 2026-03-18 model verification: the reproduction check is now a real comparison against the
  upstream `SolveSS_function.m`; the corrected solver reproduces distance, vote, and debt
  exactly in the `C = 1` shutoff case.
- 2026-03-18 corrected-code benchmark: on the active `I = 60`, `J = 14` grid, the benchmark
  calibration
  - `birth_utility_by_parity = [0.85, 1.10, 1.20]`
  - `child_utility = 0.02`
  - `birth_cost = 0.06`
  - `birth_price_coeff = 0.24`
  - `lambda_crowd = 0.18`
  yields a unique vote crossing between `a_price = 1.75` and `2.00`, with refined equilibrium
  price `1.774665`.
- 2026-03-18 numerical-resolution finding: the old `I = 50`, `J = 10` household grid created
  vote wiggles on the market-clearing grid. Moving to `I = 60`, `J = 14` removes that wiggle
  for the promoted benchmark candidate and is now the active benchmark resolution.
- 2026-03-18 model interpretation lock: parity (`children ever born`) is treated as a permanent
  household state, while children-at-home is a temporary housing-demand state disciplined by a
  reduced-form leave-home calibration.
- 2026-03-18 benchmark comparison note added:
  - `code/write_fertility_vs_nimby_benchmark_main.m`
  - `notes/build/fertility_vs_nimby_benchmark_report.md`
  - `notes/build/fertility_vs_nimby_benchmark_report.pdf`
  - `notes/build/fertility_vs_nimby_benchmark_summary.csv`
  - `notes/build/fertility_vs_nimby_common_price_grid.csv`
  - `notes/build/fertility_vs_nimby_benchmark_panels.png`
  - `notes/build/fertility_vs_nimby_benchmark_panels.pdf`
  This now gives a direct side-by-side comparison against the upstream NIMBY benchmark.
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
- 2026-03-09 check-in: empirical work became the active priority while the model block was still
  unsettled; that model-side pause has now been lifted because the household benchmark is
  running again under corrected code.
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
- Overall state: the household model block is benchmarked, the corrected calibration sweep has
  confirmed the active benchmark, the refreshed NIMBY-versus-fertility comparison bundle is in
  place, and the model-comparison note now contains the exact steady-state comparison, a direct
  baby-boom transition comparison, tenure-access and cohort-access proxy panels, and a historical
  fertility-validation section, a bounded robustness section, and a future demographic-projection
  bridge. The main remaining model-side gap is no longer the comparison pack itself but the
  absence of savings/net-worth objects and the lack of the full project-02 forecast solver on the
  fertility side.
- 2026-02-25 organization update: added standardized `drafts/` and `slides/` latest-file naming with explicit `old_drafts/` and `old_slides/` archive folders.
- 2026-02-25 capitalization cleanup: folder names standardized to lowercase across the project tree.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Corrected-code household fertility block implemented in MATLAB:
  - `code/SolveSS_fertility.m`
  - permanent parity state (`children ever born`) separated from temporary
    children-at-home state
  - corrected newborn utility accounting on the birth branch
  - age-mass-weighted diagnostics saved to `SS_fertility.mat`
- Market-clearing and benchmark runners added and stabilized:
  - `code/ClearMarkets_fertility.m`
  - `code/run_ge_fertility_main.m`
  - `code/calibrate_fertility_block_main.m`
  - `code/fertility_benchmark_config.m`
- Household benchmark documentation generated:
  - `notes/build/fertility_run_ge_report.md`
  - `notes/build/fertility_calibration_report.md`
  - `notes/build/fertility_reproduction_check.csv`
  - `notes/build/fertility_price_sweep.csv`
  - `notes/build/fertility_market_clearing_grid.csv`
  - `notes/build/fertility_local_benchmark_search.csv`
  - `notes/build/fertility_household_equation_summary.pdf`
- One-page household-equation summary created:
  - `notes/build/fertility_household_equation_summary.pdf`
  - `notes/build/fertility_household_equation_summary.tex`
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
  - `drafts/README.md`
  - `calibration/README.md`
  - `code/README.md`
  - `slides/README.md`
  - canonical latest paper files: `drafts/fertility_and_housing_supply.{lyx,pdf}`
  - canonical latest slides files: `slides/fertility_and_housing_supply_slides.{lyx,pdf}`
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

- Deciding whether the current supply-tightening counterfactual is sufficient for the long-run
  section or whether it should be extended into a richer housing-regime comparison.
- Deciding whether the current bridge objects are sufficient for the first full draft or whether
  a true savings / balance-sheet block is needed before circulating the paper more widely.
- Keeping the empirical geography mismatch in view, but not treating it as the active task while
  the manuscript framing and model results are being stabilized.

## Next 3 Tasks

1. Decide which persistent NIMBY shift should be the paper's benchmark long-run counterfactual: `theta0 + 0.03`, `+0.05`, or a low/medium/high regime table.
2. Tighten `drafts/fertility_and_housing_supply.tex` so the new persistent-NIMBY-shock section reads cleanly and the old aging-only framing is fully gone.
3. Decide whether to build a true savings / balance-sheet block for exact net-worth and tenure comparisons or to keep the current access-proxy comparison as the dynamic object for this paper.

## Blockers

- Upstream project-02 transition files needed for the baby-boom comparison live in Dropbox rather
  than this repo copy, so the transition section is reproducible locally but not yet repo-self-contained.
- Direct fertility-specific causal evidence remains thinner than broader housing-supply evidence.
- Legacy NIMBY fertility inputs exist locally in Dropbox but are outside this git repo, so reproducibility currently depends on local external paths.
- ACS nativity backfill script (`code/09_backfill_nativity_from_acs_api.py`) now handles 2010-2013 via B06001+B06003 fallback; minor approximation remains (ages 18-44 not 15-44) for those years.
- The current housing and policy raw files are metro-year rather than county-year, so they do not directly merge to the new county fertility file.
- The legacy permits series has much thinner overlap than rents in the temporary state-year bridge.
- The equilibrium-clean benchmark fits completed fertility less tightly than the stronger
  demographic-fit candidate, so benchmark choice is still a model-side presentation decision.
- The current project-03 transition prototype now emits directly comparable homeownership-access
  proxies, but it still does not emit net-worth or future-forecast objects, so a full
  figure-by-figure replication of the NIMBY transition and projection sections remains blocked on
  transition-side implementation rather than on missing upstream NIMBY data.

## Open Decisions

- County-cell suppression threshold for fallback aggregation to `cbsa`-year.
- Exact treatment of zero-birth or near-zero cells in transformed outcomes such as `ln_gfr_15_44`.
- Whether policy timing is coded purely at state level first and then mapped into local exposure intensity.
- Whether maternal age at first birth should be the headline timing summary or a supporting summary behind age-bin first-birth shares/rates.
- Whether the first unrestricted implementation should begin with large-county county-year or directly at state-year in CDC WONDER.
- Which IV path, if any, is credible enough for the first empirical paper: reform exposure, close-election politics, or supply-elasticity interactions.
- Whether the paper benchmark should prioritize the unique-crossing corrected-code equilibrium
  (`I = 60`, `J = 14`) or present the stronger demographic-fit calibration as the main
  robustness case.
- How prominently the benchmark comparison should emphasize normalized vote-per-mass relative to
  raw aggregate vote in the main text.

## References

- Project overview: `README.md`
- Session log: `memory.md`
- Model notes: `notes/03_model_notes.md`
- Benchmark config: `code/fertility_benchmark_config.m`
- Benchmark runner: `code/run_ge_fertility_main.m`
- Calibration runner: `code/calibrate_fertility_block_main.m`
- Benchmark refresh runner: `code/refresh_corrected_benchmark_outputs.ps1`
- Latest GE benchmark report: `notes/build/fertility_run_ge_report.md`
- Latest calibration report: `notes/build/fertility_calibration_report.md`
- Canonical latest paper/slide folders: `drafts/` and `slides/`
- Shared structure standard: `_shared/standards/paper_project_structure_standard.md`
- Shared code/calibration standard: `_shared/standards/code_calibration_standard.md`

## Working Rule

- When asked "where are we?" or to update the to-do list, update this file first.
- Do not remove PDF files from the shared Dropbox export pipeline under `exports/` when those files are required for collaboration deliverables.




