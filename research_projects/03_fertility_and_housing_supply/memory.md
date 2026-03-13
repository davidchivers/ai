# Project Memory - Fertility and Housing Supply

Most recent session first.

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





