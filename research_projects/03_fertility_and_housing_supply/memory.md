# Project Memory - Fertility and Housing Supply

Most recent session first.

---

### Session: 2026-03-20 (persistent NIMBY-shock scenario grid)
- Added a scenario-grid builder for the long-run NIMBY counterfactual:
  - `code/build_nimby_shock_scenarios.py`
- New outputs:
  - `notes/build/nimby_shock_scenario_grid.csv`
  - `notes/build/nimby_shock_calibration_sensitivity.csv`
  - `notes/build/nimby_shock_scenarios.md`
  - `notes/build/nimby_shock_scenarios.png`
  - `notes/build/nimby_shock_scenarios.pdf`
- Main quantitative lock:
  - medium-immigration `2100` fertility falls monotonically with persistent NIMBY intensity:
    - `theta0 + 0.03`: `0.180`
    - `theta0 + 0.05`: `0.175`
    - `theta0 + 0.08`: `0.170`
    - `theta0 + 0.10`: `0.167`
    - baseline: `0.188`
  - corresponding medium-immigration `2100` house-price indices are:
    - `1.562`, `1.767`, `2.075`, `2.281`
    - baseline: `1.254`
- Calibration lock after the grid:
  - the sign of the long-run fertility result survives nearby changes in fertility-price
    sensitivity and family-demand strength
  - `lambda_crowd` itself does not move the current forward bridge because that object's fertility
    decision depends on prices, not directly on the housing-burden proxy
- Writing lock after this pass:
  - the paper can now describe the long-run result as monotone in persistent NIMBY intensity, not
    as a single benchmark counterfactual

---

### Session: 2026-03-20 (persistent NIMBY-shock counterfactual)
- Added a direct supply-tightening counterfactual builder:
  - `code/build_nimby_shock_fertility_counterfactual.py`
- Extended the bridge library with two new utilities:
  - persistent NIMBY-shock transition from a shared initial state
  - forward age-scenario projection under a shared initial state plus persistent NIMBY shock
  - file: `code/nimby_fertility_transition_bridge.py`
- New outputs:
  - `notes/build/nimby_shock_transition_series.csv`
  - `notes/build/nimby_shock_projection_series.csv`
  - `notes/build/nimby_shock_fertility_counterfactual_summary.csv`
  - `notes/build/nimby_shock_fertility_counterfactual.md`
  - `notes/build/nimby_shock_fertility_counterfactual.png`
  - `notes/build/nimby_shock_fertility_counterfactual.pdf`
- Main result:
  - a persistent NIMBY shift now gives the long-run object the project actually needs
  - under a permanent `theta0 + 0.05` shift, house prices rise and fertility falls both in the
    stylized transition and in the forward age-scenario bridge
  - medium-immigration projection:
    - `2050` price index `1.163` versus `1.066` baseline
    - `2050` fertility `0.190` versus `0.194` baseline
    - `2100` price index `1.767` versus `1.254` baseline
    - `2100` fertility `0.175` versus `0.188` baseline
- Writing lock after this pass:
  - the old aging-only projection is not the core long-run result anymore
  - the manuscript and the model-comparison note should both center the long-run section on
    persistent housing scarcity lowering realized fertility

---

### Session: 2026-03-20 (standalone manuscript draft)
- Wrote a standalone manuscript draft in LaTeX:
  - `drafts/fertility_and_housing_supply.tex`
  - `drafts/fertility_and_housing_supply.pdf`
- Draft structure:
  - introduction
  - model
  - steady-state benchmark
  - temporary baby boom
  - historical validation
  - robustness
  - future demographic projections
  - conclusion
- Main writing lock:
  - the manuscript is now framed as a standalone fertility-and-housing paper rather than as a
    technical extension memo
  - the benchmark comparison note remains the supporting model pack in `notes/build/`
- Important interpretation lock carried into the draft:
  - baby boom: fertility amplifies the medium-run house-price response
  - long-run aging: fertility flattens the projected price path relative to the NIMBY proxy
  - projection section is still a matched bridge, not the full upstream forecast solver

---

### Session: 2026-03-20 (robustness and projection bridge)
- Added a shared Python bridge for the current transition and projection equations:
  - `code/nimby_fertility_transition_bridge.py`
- Added a bounded baby-boom robustness builder:
  - `code/build_nimby_vs_fertility_transition_robustness.py`
- New robustness outputs:
  - `notes/build/nimby_vs_fertility_transition_robustness.png`
  - `notes/build/nimby_vs_fertility_transition_robustness.pdf`
  - `notes/build/nimby_vs_fertility_transition_robustness.csv`
  - `notes/build/nimby_vs_fertility_transition_robustness_checks.csv`
- Important robustness lock:
  - the Python bridge matches the MATLAB benchmark policy runs to machine precision
  - the price-amplification result is robust across the bounded sweep
  - the access ranking is less uniform than the price ranking, so the draft should lean on the
    robust price result first
- Added an upstream forecast-age exporter and a projection comparison builder:
  - `code/export_nimby_forecast_reference_main.m`
  - `code/build_nimby_vs_fertility_projection_comparison.py`
- New projection outputs:
  - `notes/build/nimby_projection_age_groups_all_scenarios.csv`
  - `notes/build/nimby_projection_reference.csv`
  - `notes/build/nimby_vs_fertility_projection_comparison.png`
  - `notes/build/nimby_vs_fertility_projection_comparison.pdf`
  - `notes/build/nimby_vs_fertility_projection_summary.csv`
  - `notes/build/nimby_projection_bridge.csv`
  - `notes/build/nimby_vs_fertility_projection_bridge.csv`
- Important projection lock:
  - the saved upstream `Price_Trend` vectors in accessible forecast MAT files are too coarse/flat
    to use directly as the paper comparison line
  - the usable current object is therefore a matched bridge driven by the upstream forecast age
    weights, with a NIMBY proxy on one side and the fertility bridge on the other
  - under that bridge, projected aging raises NIMBY-proxy prices but leaves the fertility bridge
    much flatter

---

### Session: 2026-03-20 (transition tenure and cohort proxy pass)
- Extended the project-03 transition runner so each model run now emits:
  - age-bin shares
  - young, old, and aggregate homeownership-access proxies
  - boom, parent, and child generation homeownership-access levels
  - boom, parent, and child generation housing-burden proxy levels
  - file: `code/run_experiments_matlab_main.m`
- Updated the transition figure builder:
  - `code/plot_nimby_vs_fertility_transition_figures.py`
- New or refreshed transition outputs:
  - `notes/build/nimby_vs_fertility_baby_boom_transition.png`
  - `notes/build/nimby_vs_fertility_baby_boom_transition.pdf`
  - `notes/build/nimby_vs_fertility_generation_homeownership.png`
  - `notes/build/nimby_vs_fertility_generation_homeownership.pdf`
  - `notes/build/nimby_vs_fertility_transition_proxy_series.csv`
  - updated `notes/build/nimby_vs_fertility_baby_boom_summary.csv`
- Main dynamic read after the proxy pass:
  - young homeownership access falls much more in the fertility transition than in NIMBY
  - trough young-homeownership response is about `-0.0107` in the fertility transition versus
    about `-0.0019` in NIMBY
  - cohort access ranking on the fertility side is parent least affected, boom generation next,
    child generation most affected
- Important implementation lock:
  - the homeownership comparison gap is now closed with explicit proxy objects
  - the remaining missing dynamic object is a true savings / net-worth block, not another tenure
    plot

---

### Session: 2026-03-20 (historical validation and projection input bridge)
- Extended the upstream NIMBY exporter so the build folder now has both a lean reference CSV and a
  fuller transition export:
  - `code/export_nimby_baby_boom_reference_main.m`
  - `notes/build/nimby_baby_boom_reference.csv`
  - `notes/build/nimby_baby_boom_reference_full.csv`
- Added a historical baby-boom validation builder:
  - `code/build_nimby_vs_fertility_historical_validation.py`
- New historical-validation outputs:
  - `notes/build/nimby_vs_fertility_historical_validation.png`
  - `notes/build/nimby_vs_fertility_historical_validation.pdf`
  - `notes/build/nimby_vs_fertility_historical_validation.md`
  - `notes/build/nimby_vs_fertility_historical_validation_summary.csv`
  - `notes/build/nimby_vs_fertility_historical_validation_series.csv`
- Main historical-validation read:
  - data source is the aggregate `metarea == 0` fertility series from
    `C:/Users/Dave_/Dropbox/Zac and David/Data/merged_birthrates_migrationweights.dta`
  - normalization uses the pre-boom mean over `1940-1945`
  - post-boom comparison aligns historical `1956+` to model `t >= 10`
  - fertility extension RMSE beats the NIMBY line at `10`, `20`, `30`, and `40` year horizons,
    but the improvement is modest
- Added a projection-input bridge:
  - `code/build_nimby_projection_age_groups.py`
  - `notes/build/nimby_projection_age_groups.png`
  - `notes/build/nimby_projection_age_groups.pdf`
  - `notes/build/nimby_projection_age_groups.md`
  - `notes/build/nimby_projection_age_groups.csv`
- Updated the main comparison note:
  - `notes/build/nimby_vs_fertility_model_comparison.tex`
  - `notes/build/nimby_vs_fertility_model_comparison.pdf`
- Important implementation lock after this pass:
  - upstream NIMBY transition data are no longer the main bottleneck for a fuller comparison
  - after the later proxy pass, the remaining blocker is no longer homeownership but net-worth and
    future-forecast objects

---

### Session: 2026-03-20 (baby-boom transition comparison added)
- Found the missing upstream NIMBY transition object in Dropbox:
  - `C:/Users/Dave_/Dropbox/Zac and David/Code/SteadyState/Mod_IRF/irfs_smoothed.mat`
- Added exporter for the upstream NIMBY baby-boom reference:
  - `code/export_nimby_baby_boom_reference_main.m`
- Updated the project-03 transition run to match the NIMBY shock timing and scale:
  - temporary `+10%` shock
  - periods `t = 0` to `9`
  - file: `code/run_experiments_matlab_main.m`
- Added transition plotting script:
  - `code/plot_nimby_vs_fertility_transition_figures.py`
- New transition comparison outputs:
  - `notes/build/nimby_baby_boom_reference.csv`
  - `notes/build/nimby_baby_boom_reference_source.txt`
  - `notes/build/nimby_vs_fertility_baby_boom_transition.png`
  - `notes/build/nimby_vs_fertility_baby_boom_transition.pdf`
  - `notes/build/nimby_vs_fertility_baby_boom_summary.csv`
- Main transition readout:
  - normalized average post-window house-price response is about `0.020` in the NIMBY reference
  - normalized average post-window house-price response is about `0.051` in the fertility transition
  - fertility rises during the boom and then falls modestly below baseline later
- Updated:
  - `notes/build/nimby_vs_fertility_model_comparison.tex`
  - `notes/build/nimby_vs_fertility_model_comparison.pdf`
- Important interpretation lock:
  - the steady-state comparison remains the exact household-to-household benchmark comparison
  - the new baby-boom section is a direct matched transition comparison, but it still uses the
    current project-03 transition block rather than a fully unified household-DP transition solver

---

### Session: 2026-03-20 (NIMBY-style model comparison note compiled)
- Built a separate model-comparison note in LaTeX rather than continuing to overload the current
  LyX manuscript:
  - `notes/build/nimby_vs_fertility_model_comparison.tex`
  - `notes/build/nimby_vs_fertility_model_comparison.pdf`
- The note follows the Gross and Chivers model-section order:
  - `The Model`
  - `Household's Problem`
  - `Real Estate Firms`
  - `Housing Supply`
  - `The Median Voter Theorem`
  - `Equilibrium`
  - benchmark comparison
- Important writing decision from the user:
  - keep implementation and coding material out of the main text
  - move solver details to an appendix
- Added a dedicated figure builder:
  - `code/plot_nimby_vs_fertility_model_figures.py`
- New genuine comparison figures:
  - `notes/build/nimby_vs_fertility_household_support.png`
  - `notes/build/nimby_vs_fertility_household_support.pdf`
  - `notes/build/nimby_vs_fertility_benchmark_objects.png`
  - `notes/build/nimby_vs_fertility_benchmark_objects.pdf`
- Main content decision:
  - use the exact household benchmark equations from `SolveSS_function.m` and
    `SolveSS_fertility.m`
  - do not reuse the older blue prototype equations from the current LyX draft as the main
    comparison object
- Main scope decision:
  - keep the note focused on model structure and verified steady-state comparison
  - do not pretend the current repo has a full direct upstream NIMBY transition stack ready for
    Figure-7-style dynamic comparisons

---

### Session: 2026-03-20 (comparison refresh completed and trackers updated)
- Regenerated the full corrected benchmark comparison bundle:
  - `notes/build/fertility_vs_nimby_benchmark_report.md`
  - `notes/build/fertility_vs_nimby_benchmark_report.pdf`
  - `notes/build/fertility_vs_nimby_benchmark_summary.csv`
  - `notes/build/fertility_vs_nimby_common_price_grid.csv`
  - `notes/build/fertility_vs_nimby_benchmark_panels.png`
  - `notes/build/fertility_vs_nimby_benchmark_panels.pdf`
- Main comparison result after the refresh:
  - the public note now reports both raw `totalvote` and normalized `vote_per_mass`
  - stationary mass is shown explicitly, so the scale difference across models is transparent
  - the corrected benchmark still crosses at `a_price = 1.751853`
- Practical execution note:
  - `powershell ... refresh_corrected_benchmark_outputs.ps1` hit the shell timeout even though
    MATLAB kept running
  - the reliable rerun path was direct `matlab.exe -batch "cd(...); write_fertility_vs_nimby_benchmark_main"`
    followed by `python code/plot_fertility_vs_nimby_benchmark.py`
    and a `pandoc` call from `notes/build/`
- Documentation updates:
  - `notes/03_model_notes.md` now reflects the confirmed March 20 benchmark numbers
  - `code/write_fertility_vs_nimby_benchmark_main.m` now stamps the report frontmatter date
    dynamically instead of hard-coding `2026-03-18`
  - `STATUS.md` and `README.md` now treat the comparison refresh as completed, not pending

---

### Session: 2026-03-20 (corrected calibration sweep confirmed benchmark; comparison refresh queued)
- The detached corrected-code calibration sweep completed successfully:
  - `notes/build/logs/corrected_calibration_20260319_122358.log`
  - `notes/build/fertility_calibration_report.md`
  - `notes/build/fertility_calibration_sweep.csv`
  - `notes/build/fertility_calibration_market_checks.csv`
- Main result:
  - current defaults survived the corrected recalibration sweep
  - candidate `1` and current defaults are the same benchmark object
  - the promoted benchmark remains:
    - `I = 60`, `J = 14`
    - `birth_utility_by_parity = [0.85, 1.10, 1.20]`
    - `child_utility = 0.02`
    - `birth_cost = 0.06`
    - `birth_price_coeff = 0.24`
    - `lambda_crowd = 0.18`
  - unique crossing remains at about `a_price = 1.751853`
  - age-50 completed fertility remains `[0.223716, 0.255603, 0.292729, 0.227952]`
- Reporting layer patched after the mass-scaling bug fix:
  - `code/write_fertility_vs_nimby_benchmark_main.m`
    now records raw `totalvote`, normalized `vote_per_mass`, and total stationary mass
  - `code/plot_fertility_vs_nimby_benchmark.py`
    now builds a six-panel figure with raw vote, normalized vote, debt, mass, and family objects
  - `code/refresh_corrected_benchmark_outputs.ps1`
    now reruns the benchmark reports, comparison build, figure generation, and PDF compile
- Important cleanup:
  - killed two stale timed-out MATLAB calibration jobs so they could not race the detached run
- Immediate pending item:
  - the benchmark comparison report/figure/PDF in `notes/build/` are still stale relative to the
    patched raw-vs-normalized comparison layer until `refresh_corrected_benchmark_outputs.ps1`
    is run

---

### Session: 2026-03-18 (household benchmark freeze and corrected-code recalibration)
- Stabilized the steady-state household fertility block around the corrected-code benchmark:
  - `code/SolveSS_fertility.m`
  - `code/ClearMarkets_fertility.m`
  - `code/run_ge_fertility_main.m`
  - `code/calibrate_fertility_block_main.m`
- Added `code/fertility_benchmark_config.m` as the single source of truth for:
  - benchmark parameter overrides
  - verification price grids
  - calibration target parity shares
  - stage-1 coarse solver settings
- Correctness fixes now live in the active solver stack:
  - reproduction check is a real comparison against upstream `SolveSS_function.m`
  - newborn utility is counted on the birth branch
  - multiple market crossings are reported honestly rather than collapsed to the first root
  - aggregate child-state summaries are age-mass weighted
- Current promoted benchmark:
  - solver grid: `I = 60`, `J = 14`
  - `birth_utility_by_parity = [0.85, 1.10, 1.20]`
  - `child_utility = 0.02`
  - `birth_cost = 0.06`
  - `birth_price_coeff = 0.24`
  - `lambda_crowd = 0.18`
- Current benchmark verification from `notes/build/fertility_run_ge_report.md`:
  - reproduction gaps are exactly zero
  - birth rates decline from `0.655463` at `a_price = 1.5` to `0.197750` at `3.0`
  - one vote sign change on the supplied market grid
  - refined equilibrium price `1.774665`
- Main interpretation lock:
  - parity = `children ever born` (permanent state)
  - children-at-home = temporary crowding state for housing demand
  - leave-home timing remains reduced-form and Census-disciplined, not structural
- Main numerical finding:
  - old `I = 50`, `J = 10` created vote wiggles on the market grid
  - `I = 60`, `J = 14` removes that wiggle for the promoted benchmark candidate
- Main remaining model-side tradeoff:
  - the equilibrium-clean benchmark fits completed fertility less tightly than the stronger
    demographic-fit candidate
  - empirical geography cleanup is still the main paper bottleneck
- Added an explicit benchmark-comparison write-up against project 02:
  - `code/write_fertility_vs_nimby_benchmark_main.m`
  - `notes/build/fertility_vs_nimby_benchmark_report.md`
  - `notes/build/fertility_vs_nimby_benchmark_report.pdf`
  - `notes/build/fertility_vs_nimby_benchmark_summary.csv`
  - `notes/build/fertility_vs_nimby_common_price_grid.csv`
  - `notes/build/nimby_market_clearing_grid.csv`
  - `notes/build/fertility_vs_nimby_benchmark_panels.png`
  - `notes/build/fertility_vs_nimby_benchmark_panels.pdf`
- Main comparison result:
  - upstream NIMBY crossing price on the same `rbPos = 0.03` convention is about `2.326287`
  - project-03 fertility benchmark crossing price is about `1.774665`
  - the project-03 solver still nests NIMBY exactly in the shutoff case

---

### Session: 2026-03-13 (path portability pass and three-way comparison refresh)
- Updated the three legacy-source import scripts so they can find the project-02 data roots
  without hard-coding Dropbox as the only location:
  - `code/06_import_nimby_birthrates_to_raw.py`
  - `code/07_import_nimby_housing_controls_to_raw.py`
  - `code/08_import_nimby_population_policy_to_raw.py`
- New source-root rule:
  - use `ZAC_DAVID_DATA_DIR` if present
  - otherwise prefer `D:\research_data\zac_and_david\Data`
  - otherwise fall back to `C:\Users\Dave_\Dropbox\Zac and David\Data`
- Refreshed the MATLAB comparison write-up so the current reduced-form, old-proxy, and
  structural-FOC objects are all captured in one updated report:
  - `notes/build/old_vs_new_model_comparison_report.md`
  - `notes/build/comparison_summary_old_vs_new.csv`
  - `notes/build/comparison_phase_summary.csv`
  - `notes/build/old_vs_new_paths.png`
  - `notes/build/old_vs_new_policy_effects.png`
  - `notes/build/model_experiment_paths.png`
- Practical read after the refresh:
  - the structural FOC version remains much more fertility- and price-responsive than the
    reduced-form or old-proxy variants
  - empirical cleanup still dominates the near-term agenda, so this remains a diagnostic
    comparison rather than the main current workstream

---

### Session: 2026-03-09 (live CDC WONDER pull, rebuild, and state-year exploratory bridge)
- Added direct CDC WONDER puller:
  - `code/12_pull_cdc_wonder_first_births.py`
- Ran the live natality pull from official CDC WONDER dataset `D66`:
  - output: `data/raw/cdc_wonder_first_births_export.csv`
  - years: `2007-2024`
  - grouping: county, year, age of mother 10
  - filter: first births only
- Fixed two importer issues in `code/11_import_cdc_wonder_first_births.py`:
  - accepted `Age of Mother 10` as the age column label
  - fixed county-derived `state_fips` fallback so blank state codes do not become `00`
- Re-imported fertility:
  - `data/raw/cdc_fertility_county_year.csv`
  - rows: `10,890`
  - years: `2007-2024`
- Ran ACS nativity backfill:
  - `code/09_backfill_nativity_from_acs_api.py`
  - updated `data/raw/population_immigration_county_year.csv`
- Rebuilt the main panel:
  - `code/05_build_us_panel_from_sources.ps1`
  - refreshed:
    - `data/processed/us_fertility_housing_panel_v1.csv`
    - `notes/build/us_panel_source_coverage.md`
    - `notes/build/us_panel_missingness_report.md`
- Main empirical alignment finding:
  - fertility now overlaps with population denominators, but not with the legacy housing/control block at local geography because the housing files are metro-year despite county-style filenames
- Rewrote exploratory regressions around a temporary state-year bridge:
  - `code/10_exploratory_empirical_regressions.py`
  - new bridge file: `notes/build/exploratory_state_year_panel.csv`
  - refreshed outputs:
    - `notes/build/exploratory_regression_summary.md`
    - `notes/build/exploratory_regression_results.csv`
- Current readout from the state-year exploratory pass:
  - `first_birth_rate_15_44` on rent index: negative but imprecise (`coef -9.31`, `p 0.186`, `2010-2017`)
  - `mean_age_first_birth` on rent index: positive but imprecise (`coef 1.00`, `p 0.263`, `2007-2017`)
  - `share_first_birth_30_plus` on rent index: positive but imprecise (`coef 0.0267`, `p 0.652`, `2007-2017`)
  - permits sample is much thinner and not yet persuasive

### Session: 2026-03-09 (CDC WONDER timing-build scaffold implemented)
- Added a modern natality importer:
  - `code/11_import_cdc_wonder_first_births.py`
- Added pull instructions:
  - `notes/build/cdc_wonder_first_birth_pull_instructions.md`
- Extended the fertility schema in:
  - `code/04_build_us_panel_scaffold.ps1`
  - `code/05_build_us_panel_from_sources.ps1`
- New timing fields now supported in the panel schema:
  - `first_births_total`
  - `first_birth_rate_15_44`
  - `mean_age_first_birth`
  - `median_age_first_birth`
  - `share_first_birth_15_19`
  - `share_first_birth_20_24`
  - `share_first_birth_25_29`
  - `share_first_birth_30_34`
  - `share_first_birth_35_44`
  - `share_first_birth_30_plus`
- Builder improvement:
  - `state_fips` can now act as the merge key fallback when county/CBSA ids are absent
- Verification:
  - end-to-end temp test passed for WONDER-style county-year input through panel merge
  - the main repo panel was not rebuilt to completion in-session because the full PowerShell build is slow on the large historical files

### Session: 2026-03-09 (fertility source decision locked)
- Added source-decision note:
  - `notes/build/fertility_source_decision.md`
- Decision:
  - do not use the historical metro `gfr_15_44` sample as the baseline empirical panel
  - use a modern natality-based build as the main empirical path
  - keep the old metro sample only for provisional sign checks
- Basis for the decision:
  - current processed panel has zero overlap between historical fertility observations and modern nativity/population observations
  - legacy Dropbox fertility files only contain aggregate birth-rate series, not maternal-age-at-birth or birth-order variables
- Updated:
  - `notes/04_empirical_notes.md`
  - `notes/05_research_plan.md`
  - `STATUS.md`

### Session: 2026-03-09 (exploratory regressions on current processed panel)
- Added reproducible regression script:
  - `code/10_exploratory_empirical_regressions.py`
- Generated exploratory outputs:
  - `notes/build/exploratory_regression_summary.md`
  - `notes/build/exploratory_regression_results.csv`
- Main empirical finding from this pass:
  - provisional reduced-form sign checks are possible on the historical metro fertility sample
  - post-treatment coefficient is negative in metro/year FE regressions
  - rent coefficient is negative on the small overlap sample
  - event-study bins show non-flat pre-trends
  - permits coefficient is imprecise
- Critical data finding:
  - current `gfr_15_44` observations run from 1940--1995 at metro-year level
  - current `female_pop_15_44` observations run from 2010--2018 at county-year level
  - overlap is zero, so the current merged panel cannot serve as the intended modern nativity-adjusted baseline

### Session: 2026-03-09 (empirical refocus toward first-birth timing)
- Reframed the near-term empirical agenda around first-birth timing rather than overall fertility alone.
- Updated `notes/05_research_plan.md` to prioritize:
  - first-birth timing outcomes
  - reduced-form event studies
  - IV exploration that instruments housing supply/cost rather than fertility directly
- Expanded `notes/04_empirical_notes.md` with:
  - timing-focused outcome definitions
  - a recommendation to use age-at-first-birth only alongside first-birth shares/rates
  - an IV menu with reform exposure as the current preferred path
- Updated `STATUS.md` so canonical next tasks reflect the timing-first empirical design.

### Session: 2026-03-09 (status review)
- Reviewed canonical project context in `STATUS.md`, `README.md`, and `memory.md`.
- No implementation changes yet in this session.
- Active priorities remain:
  - structural-model calibration against empirical fertility-price patterns
  - nativity API backfill and panel rebuild
  - eventual port of fertility choice into project-02 household VFI block once upstream `.mat` inputs are available

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
  - `drafts/`
  - `slides/`
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
  - `drafts/README.md`
  - `calibration/README.md`
- Added canonical output location guidance:
  - latest output targets in dedicated folders: `drafts/fertility_and_housing_supply.pdf`, `slides/fertility_and_housing_supply_slides.pdf`
- Added code folder standards note:
  - `code/README.md`
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
  - `notes/README.md`
- Cross-file note references updated in project docs.

### Session: 2026-02-23 (markdown-first restructure)
- Updated project governance for markdown-first drafting in notes.
- Added canonical notes files:
  - `notes/README.md`
  - `notes/04_empirical_notes.md`
  - `notes/02_literature_and_synthesis.md`
  - `notes/03_model_notes.md`
- Updated `README.md` and `STATUS.md` to point active work into Markdown notes.
- Clarified exception: shared Dropbox export workflow in `exports/` should keep PDF deliverables where expected by collaborators.

### Session: 2026-02-23 (single canonical status tracker)
- Added canonical tracker: `STATUS.md`
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
  - `code/fertility_extension_experiment.py`
- Generated model experiment outputs in `_playground/backups/2026-02-25_notes_flattening/03_fertility_and_housing_supply/Notes_build/`.
- Established export sync workflow to shared collaboration folder.

## Key files

| Role | Path |
|---|---|
| Status tracker | `STATUS.md` |
| Project overview | `README.md` |
| Benchmark config | `code/fertility_benchmark_config.m` |
| Benchmark runner | `code/run_ge_fertility_main.m` |
| Calibration runner | `code/calibrate_fertility_block_main.m` |
| Model notes | `notes/03_model_notes.md` |
| Latest GE benchmark report | `notes/build/fertility_run_ge_report.md` |
| Latest calibration report | `notes/build/fertility_calibration_report.md` |
| Upstream source | `../02_nimbyism_and_housing_supply/` |





