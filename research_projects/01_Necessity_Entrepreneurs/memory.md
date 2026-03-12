# Project Memory - Necessity Entrepreneurs

Most recent session first.

---

### Session: 2026-03-12 (MIT vacancy-rule control check and Econometrica report)
- Continued the MIT/recession-object debugging on the promising incumbent-scaled vacancy rule rather than the legacy replacement-vacancy block.
- Confirmed the incumbent-scaled baseline for `case 147`:
  - run log:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_confirm_vrule4s10_baseline_20260312_20260312_165351.log`
  - key baseline outcomes:
    - `theta = 0.658451`
    - entrepreneur share `= 0.17638`
    - self-employed share among entrepreneurs `= 0.57104`
    - average entrepreneur size `n = 6.22822`
    - average entrepreneur capital `k = 99.3024`
- Froze the matched baseline transition start state for clean MIT comparisons in:
  - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147_vrule4s10_baseline_transition_init_20260312_170043/`
- Ran the matched recession bundle under the same vacancy rule with:
  - `VacancySourceRule = 4`
  - `VacancyScale = 0.10`
  - `OutputDemandWedge = 0.95`
  - `WorkerSeparationAddLow = 0.10`
  - log:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_confirm_vrule4s10_outw095_sep010_mit_20260312_20260312_170751.log`
  - MIT transition output:
    - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147/mit_vrule4s10_outw095_sep010_from_vrule4s10_baseline_20260312/transition_path.csv`
- Steady-state comparison versus the confirmed incumbent-scaled baseline:
  - `theta: 0.658451 -> 0.653936`
  - entrepreneur share: `0.17638 -> 0.18775`
  - self-employed share among entrepreneurs: `0.57104 -> 0.60101`
  - average entrepreneur size `n: 6.22822 -> 5.76434`
  - average entrepreneur capital `k: 99.3024 -> 86.5464`
- Important dynamic follow-up:
  - the matched recession path still showed an early positive `theta` spike, so the steady-state improvement alone was not enough to call the MIT issue fixed.
- Ran a matched baseline-control MIT export from the exact same frozen cross section:
  - log:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_confirm_vrule4s10_baseline_control_mit_20260312_20260312_171644.log`
  - control transition output:
    - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147/mit_vrule4s10_baseline_control_from_vrule4s10_baseline_20260312/transition_path.csv`
- Shock-minus-control read:
  - the recession bundle still raises entrepreneurship and self-employment relative to the matched control,
  - lowers entrepreneur size and capital relative to the matched control,
  - raises low-education unemployment by about `1.6` to `2.7` percentage points over periods `0-24`,
  - but `theta` still overshoots early, peaking at roughly `+8.5` percentage points relative to the matched control path before settling down.
- Practical conclusion:
  - `VacancySourceRule = 4`, `VacancyScale = 0.10` is the best recession candidate so far,
  - it genuinely improves the steady-state recession mapping,
  - but it is not yet a complete fix to the MIT-tightness problem because the early transition dynamics remain too expansionary.
- Also wrote a full external-style paper report for the current manuscript:
  - `referee/ECONOMETRICA_REFEREE_REPORT.tex`
  - `referee/ECONOMETRICA_REFEREE_REPORT.pdf`
- Bottom-line review judgment recorded in that report:
  - real idea,
  - materially improved draft,
  - not currently `Econometrica`-publishable,
  - best path forward is sharper framing, cleaner empirical bridge, cleaner policy decomposition, and a more convincing recession object.

### Session: 2026-03-12 (benchmark cutoff presentation alternatives)
- Built two benchmark-only alternatives so the cutoff object can be judged as a paper figure rather than only as a raw diagnostic:
  - `figures/case147_benchmark_necessity_entry_regions.tex`
  - `figures/case147_benchmark_cutoff_gap_figure.tex`
- Added dedicated generators and preview wrappers:
  - `figures/cutoff_figure_utils.js`
  - `figures/generate_case147_benchmark_necessity_entry_regions.js`
  - `figures/generate_case147_benchmark_cutoff_gap_figure.js`
  - `figures/case147_benchmark_necessity_entry_regions_preview.tex`
  - `figures/case147_benchmark_cutoff_gap_figure_preview.tex`
- Preview PDFs compiled successfully:
  - `figures/case147_benchmark_necessity_entry_regions_preview.pdf`
  - `figures/case147_benchmark_cutoff_gap_figure_preview.pdf`
- Practical read after visual comparison:
  - the shaded necessity-entry-region figure communicates the mechanism more clearly,
  - the gap-by-asset figure is sharper for diagnosis of where the unemployed-employed wedge opens up, but it looks less like a natural main-text cutoff graph.
- Added an R/`ggplot2` renderer so the same benchmark cutoff objects can be rebuilt outside TikZ:
  - `figures/generate_case147_benchmark_cutoff_figures.R`
- Environment update:
  - installed base R `4.5.2` to the default `C:` location through `winget`,
  - installed `ggplot2` to the user library at `C:\Users\Dave_\AppData\Local\R\win-library\4.5`,
  - executed the R renderer successfully and wrote:
    - `figures/case147_benchmark_necessity_entry_regions_r.pdf`
    - `figures/case147_benchmark_necessity_entry_regions_r.png`
    - `figures/case147_benchmark_cutoff_gap_figure_r.pdf`
    - `figures/case147_benchmark_cutoff_gap_figure_r.png`
- Promoted the shaded necessity-entry figure from diagnostic candidate to live draft/slide content:
  - inserted the figure after the benchmark table in:
    - `drafts/necessity_entrepreneurship.tex`
    - `drafts/necessity_entrepreneurship.lyx`
  - added a short economic-intuition paragraph emphasizing that the unemployed-employed wedge opens most at intermediate asset levels and shifts right with education.
- Added a rerunnable slide-safe output path to the TikZ generator:
  - `figures/generate_case147_benchmark_necessity_entry_regions.js`
  - it now writes both:
    - `figures/case147_benchmark_necessity_entry_regions.tex`
    - `figures/case147_benchmark_necessity_entry_regions_slide.tex`
- Updated the slide deck to use the no-caption/no-legend fragment:
  - `slides/necessity_entrepreneurship_slides.tex`
- Verification:
  - rebuilt `drafts/necessity_entrepreneurship.pdf`
  - rebuilt `slides/necessity_entrepreneurship_slides.pdf`
  - removed the large overflow that had come from importing the full paper figure environment into Beamer;
  - one smaller pre-existing overflow remains on the MIT IRF slide later in the deck.

### Session: 2026-03-12 (three-panel cutoff presentation lock)
- Confirmed that the retained benchmark cutoff asset should stay as a three-panel entrepreneurship-entry-by-education figure rather than the old combined entry/employer-threshold display.
- Tightened the benchmark figure wording:
  - `figures/generate_case147_benchmark_cutoff_panels.js`
  - education-row labels now read `Low education`, `Middle education`, and `High education`.
- Updated the supporting review-pack language:
  - `notes/19_transition_and_cutoff_review_pack.tex`
  - `notes/cutoff_diagnostics_inventory.md`
- Practical result:
  - the active cutoff diagnostic set now describes the benchmark figure consistently as the retained three-panel entrepreneurship cutoff object.

### Session: 2026-03-12 (benchmark-only cutoff cleanup)
- Reduced the cutoff diagnostic set to the benchmark model only at the user's request.
- Removed the non-benchmark cutoff comparison fragments from `figures/`:
  - no-unemployment-risk,
  - downturn low-education separation shock,
  - no-UI.
- Trimmed the diagnostic review pack:
  - `notes/19_transition_and_cutoff_review_pack.tex`
  - it now keeps the MIT transition figure and the benchmark cutoff panel only.
- Updated the inventory note:
  - `notes/cutoff_diagnostics_inventory.md`
  - it now lists only the retained benchmark cutoff asset.

### Session: 2026-03-12 (cutoff parser repair for the six-panel graph)
- Traced the bad employer-threshold panels to a parsing bug in the figure generators:
  - `credit_const_v18.txt` is written in `education -> productivity -> asset` order,
  - the generators had been assigning education via `line_index % 3`, which scrambled the employer-threshold side of the six-panel graph.
- Patched the cutoff generators to reconstruct the education blocks from `choose_state_next.txt` and then walk `credit_const_v18.txt` in the correct grid order:
  - `figures/generate_case147_benchmark_cutoff_panels.js`
  - `figures/generate_case147_cutoff_comparison_figure.js`
  - `figures/generate_case147_no_unemployment_cutoff_figure.js`
- Regenerated the benchmark and comparison cutoff assets:
  - `figures/case147_benchmark_cutoff_panels.tex`
  - `figures/case147_no_unemployment_risk_cutoff_panels.tex`
  - `figures/case147_no_unemployment_risk_entry_cutoffs.tex`
  - `figures/case147_no_unemployment_risk_employer_cutoffs.tex`
  - `figures/case147_downturn_lowedu_sep010_entry_cutoffs.tex`
  - `figures/case147_downturn_lowedu_sep010_employer_cutoffs.tex`
  - `figures/case147_ui000_entry_cutoffs.tex`
  - `figures/case147_ui000_employer_cutoffs.tex`
- Fixed a separate preview-only LaTeX issue in the benchmark six-panel wrapper by simplifying the y-axis labels so the benchmark preview compiles cleanly.
- Verification:
  - rebuilt `figures/case147_benchmark_cutoff_panels_preview.pdf`
  - rebuilt `notes/19_transition_and_cutoff_review_pack.pdf`
- Practical result:
  - the six-panel benchmark graph is now based on the correctly parsed employer-threshold data,
  - the figures are again usable for review/diagnostics, but they remain out of the active manuscript until the paper-side presentation decision is revisited.

### Session: 2026-03-11 (slides switched to TeX-plus-PDF only)
- Dropped the placeholder slides LyX source at the user's request:
  - removed `slides/necessity_entrepreneurship_slides.lyx`
- Promoted the real slide source to the canonical slides folder:
  - `slides/necessity_entrepreneurship_slides.tex`
- Updated figure paths in the slide source so it now compiles directly from `slides/` using the project-level `figures/` folder.
- Rebuilt the canonical slide deck successfully:
  - `slides/necessity_entrepreneurship_slides.pdf`
- Practical rule going forward:
  - maintain slides in TeX plus PDF only unless a new LyX source is explicitly requested later.

### Session: 2026-03-11 (LyX calibration sync and paper rebuild)
- Synced the live LyX draft to the cleaned paper-facing calibration rewrite:
  - replaced the old inline calibration block in `drafts/necessity_entrepreneurship.lyx` with an authoritative include of:
    - `drafts/sections/calibration_self_employment.tex`
- Updated the benchmark calibration table fragment:
  - `drafts/tables/calibration_parameters_self_employment.tex`
  - added the code-consistent asset lower bound row:
    - `a_l = 0.01`
- Updated the main draft TeX to match the cleaned calibration path:
  - `drafts/necessity_entrepreneurship.tex`
  - calibration section now inputs the standalone fragment rather than carrying the stale inline table.
- Removed stale paper prose that still said the fixed-tax self-employment ladder was incomplete:
  - conclusion now points to the next paper task as a clean endogenous-tax versus fixed-tax comparison object;
  - appendix robustness text now states that the matched fixed-tax ladder is complete and confirms the benchmark pattern.
- Rebuilt the canonical paper PDF successfully:
  - `drafts/necessity_entrepreneurship.pdf`
- Refreshed the archived LyX-to-TeX companion export:
  - `drafts/old_drafts/source_tex/necessity_entrepreneurship.tex`
- Practical result:
  - the paper PDF is no longer behind the edited source for this calibration-sync pass;
  - the main remaining paper-side quantitative task is now the matched endogenous-tax versus fixed-tax comparison object.

### Session: 2026-03-09 (paper table rebuild, calibration rewrite, and PDF refresh)
- Preserved the key benchmark outputs in dedicated snapshots so richer paper moments could be extracted without later runs overwriting `case_test_new_147`:
  - baseline snapshot:
    - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147_baseline_snapshot_20260309_144705`
  - no-unemployment-risk snapshot:
    - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147_nourisk_snapshot_20260309_150233`
  - `UI=0.05` snapshot:
    - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147_ui005_snapshot_20260309_151050`
  - `UI=0.00` snapshot:
    - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147_ui000_snapshot_20260309_152411`
  - downturn steady-state snapshot:
    - `calibration/self_employment_baseline/runtime/data/Output/case_test_new_147_downturn_lowedu_sep010_snapshot_20260309_153408`
- Extracted a richer table set for the paper:
  - entrepreneurship shares by education,
  - output per household by education,
  - average entrepreneur size by education,
  - average employer size by education,
  - average entrepreneur capital by education in the baseline,
  - self-employed and employer shares by education.
- Rebuilt the main paper tables:
  - `drafts/tables/baseline_results_only.tex`
  - `drafts/tables/self_employment_case147_ui_ladder.tex`
  - `drafts/tables/self_employment_case147_no_unemployment_risk.tex`
  - `drafts/tables/self_employment_case147_downturn_lowedu_sep.tex`
  - `drafts/tables/self_employment_fhire_robustness.tex`
- Added a new paper-facing calibration table and section fragment:
  - `drafts/tables/calibration_parameters_self_employment.tex`
  - `drafts/sections/calibration_self_employment.tex`
- Rewrote the paper-facing `.tex` draft:
  - `drafts/necessity_entrepreneurship.tex`
  - removed visible internal benchmark labels from the LaTeX prose,
  - rewrote the calibration section in a more professional paper-facing style,
  - expanded the baseline table and the no-unemployment-risk / downturn discussion to report output and firm-size moments more clearly.
- Patched the no-unemployment-risk cutoff figure source so the paper build succeeds with current `pgfplots`:
  - `figures/case147_no_unemployment_risk_cutoff_panels.tex`
- Successful PDF build:
  - `drafts/necessity_entrepreneurship.pdf`
- Live-source note:
  - the compiled `.tex` draft is ahead of the editable LyX draft on the calibration rewrite;
  - tomorrow's first paper task should be syncing the LyX calibration block and checking for any remaining visible internal case labels.
- Tomorrow's next steps:
  1. sync `drafts/necessity_entrepreneurship.lyx` to the cleaned calibration rewrite and benchmark-facing language now present in `drafts/necessity_entrepreneurship.tex`;
  2. build the MIT deterministic transition-path experiment from the low-education separation shock and decide which transition outputs are main text versus appendix;
  3. run a wealth/credit diagnostic by asset bins and education to see whether the current benchmark already embeds strong wealth-to-scale inequality effects before adding any extra borrowing-friction counterfactual.

### Session: 2026-03-09 (`case 147` UI ladder, no-risk benchmark, and downturn steady state)
- Cleaned the paper-facing baseline benchmark table:
  - `drafts/tables/baseline_results_only.tex`
  - removed solver diagnostics from the main baseline table and kept only economic moments.
- Completed the missing endogenous-tax `UI=0.05` point for the self-employment benchmark:
  - `calibration/self_employment_baseline/runtime/data/output/case_1/run_ui_005_se147_ui005_caploss025_fhire025_m40_20260309_120241.log`
  - final outcomes:
    - `best_tol = 0.0165639`
    - `entr_share = 0.28877`
    - self-employed share among entrepreneurs `= 0.718219`
    - employer share among entrepreneurs `= 0.281781`
    - `n_entrepreneur avg = 3.31976`
    - `k_entrepreneur avg = 63.8887`
- Added generic self-employment runtime hooks in:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113_self_employment.cpp`
  - `calibration/self_employment_baseline/run_ai_calibration.ps1`
  - new hooks:
    - fixed tax for arbitrary single-case runs,
    - fixed `theta`,
    - fixed `rho`,
    - worker separation shock overrides.
- Fixed-tax no-UI homotopy for `case 147` is now coded but still expensive to run to completion; the direct paper-facing results from this session therefore use the cheaper completed no-risk and downturn steady-state runs first.
- Completed a no-unemployment-risk upper-bound benchmark under fixed tax:
  - `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_se147_nourisk_fixedtax_theta1_rho0_m40_retry_20260309_135436.log`
  - implemented shock:
    - fixed baseline tax `tau_y = 0.00727962`
    - fixed `theta = 1`
    - fixed `rho = 0`
    - worker separations forced to zero
  - final outcomes:
    - `best_tol = 0.0137948`
    - `entr_share = 0.19286`
    - self-employed share among entrepreneurs `= 0.397127`
    - employer share among entrepreneurs `= 0.602873`
    - `n_entrepreneur avg = 5.80694`
    - `k_entrepreneur avg = 90.4392`
- Completed the first downturn steady-state comparison for the future MIT-shock section:
  - `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_se147_downturn_lowedu_sep010_m40_20260309_140245.log`
  - implemented shock:
    - low-education worker separation increased by `0.10`
  - final outcomes:
    - `best_tol = 0.0140382`
    - `entr_share = 0.18680`
    - self-employed share among entrepreneurs `= 0.595289`
    - employer share among entrepreneurs `= 0.404711`
    - `n_entrepreneur avg = 5.79805`
    - `k_entrepreneur avg = 93.3981`
- Added new standalone table fragments so the paper-side merge can happen without touching the live LyX file:
  - `drafts/tables/self_employment_case147_ui_ladder.tex`
  - `drafts/tables/self_employment_case147_no_unemployment_risk.tex`
  - `drafts/tables/self_employment_case147_downturn_lowedu_sep.tex`

### Session: 2026-03-09 (`f_hire = 0.35` upper-side sensitivity)
- Completed the missing upper-side bracket for the employer-threshold cost:
  - baseline:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_se147_baseline_caploss025_fhire035_m40_retry_20260309_112751.log`
  - `UI=0.00`:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_ui_000_se147_ui000_caploss025_fhire035_m40_20260309_110906.log`
- Final `f_hire = 0.35` outcomes:
  - baseline:
    - `best_tol = 0.00774401`
    - `entr_share = 0.17665`
    - self-employed share among entrepreneurs `= 0.592584`
    - employer share among entrepreneurs `= 0.407416`
    - `n_entrepreneur avg = 6.23355`
    - `k_entrepreneur avg = 98.8487`
  - `UI=0.00`:
    - `best_tol = 0.0174317`
    - `entr_share = 0.34012`
    - self-employed share among entrepreneurs `= 0.770963`
    - employer share among entrepreneurs `= 0.229037`
    - `n_entrepreneur avg = 2.61377`
    - `k_entrepreneur avg = 54.7019`
- Comparison to the `f_hire = 0.25` benchmark candidate:
  - baseline:
    - entrepreneurship moves only slightly `0.17805 -> 0.17665`
    - self-employed share among entrepreneurs rises slightly `0.576804 -> 0.592584`
  - `UI=0.00`:
    - entrepreneurship stays close `0.34248 -> 0.34012`
    - self-employed share among entrepreneurs is almost unchanged `0.766994 -> 0.770963`
- Interpretation:
  - the local bracket `f_hire in {0.15, 0.25, 0.35}` is now complete;
  - the benchmark result is not a knife-edge artifact;
  - `case 147` at `f_hire = 0.25` is now defensible as the working benchmark.

### Session: 2026-03-09 (`f_hire = 0.15` local sensitivity)
- Added a runtime override for the self-employment employer-threshold cost so nearby `f_hire` sensitivities can be run without creating new hardcoded cases:
  - source patch:
    - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113_self_employment.cpp`
  - wrapper patch:
    - `calibration/self_employment_baseline/run_ai_calibration.ps1`
  - new runtime env knob:
    - `CFV_SE_HIRING_FIXED_COST`
- Completed matched `case 147` sensitivity runs with `f_hire = 0.15`:
  - baseline:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_baseline_se147_baseline_caploss025_fhire015_m40_20260309_104447.log`
  - `UI=0.00`:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_ui_000_se147_ui000_caploss025_fhire015_m40_20260309_105223.log`
- Final `f_hire = 0.15` outcomes:
  - baseline:
    - `best_tol = 0.00436964`
    - `entr_share = 0.17860`
    - self-employed share among entrepreneurs `= 0.567917`
    - employer share among entrepreneurs `= 0.432083`
    - `n_entrepreneur avg = 6.12737`
    - `k_entrepreneur avg = 97.8587`
  - `UI=0.00`:
    - `best_tol = 0.0136864`
    - `entr_share = 0.33477`
    - self-employed share among entrepreneurs `= 0.732115`
    - employer share among entrepreneurs `= 0.267885`
    - `n_entrepreneur avg = 2.65661`
    - `k_entrepreneur avg = 55.6364`
- Comparison to the `f_hire = 0.25` benchmark candidate:
  - baseline composition shifts only modestly back toward employers:
    - self-employed share among entrepreneurs `0.576804 -> 0.567917`
  - `UI=0.00` also remains strongly self-employment-heavy:
    - self-employed share among entrepreneurs `0.766994 -> 0.732115`
  - entrepreneurship itself stays close:
    - baseline `0.17805 -> 0.17860`
    - `UI=0.00` `0.34248 -> 0.33477`
- Interpretation:
  - the employer-threshold mechanism is robust to a smaller nearby cost;
  - `f_hire = 0.25` does not currently look like a knife-edge calibration artifact;
  - the next judgment call is whether this one-sided local check is enough to lock the benchmark, or whether to add an upper-side `f_hire = 0.35` run before freezing it.

### Session: 2026-03-09 (case 147 no-UI rerun completed)
- Stayed on the self-employment calibration branch after the interrupted earlier run attempt.
- Restored missing runtime input `rnd_100k.txt` into the active project tree from the same-day backup copy:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/rnd_100k.txt`
  - `calibration/self_employment_baseline/runtime/data/input/CFV/rnd_100k.txt`
  - `calibration/ai_calibration/runtime/data/input/CFV/rnd_100k.txt`
- Verified the earlier interrupted `case 147`, `UI=0.00` log was metadata-only:
  - `calibration/self_employment_baseline/runtime/data/output/case_1/run_ui_000_se147_ui000_caploss025_fhire025_m40_20260309_102614.log`
- Found and cleared a stale `cfv_red_final_ai.exe` process in `calibration/self_employment_baseline/` that had locked the executable after interruption.
- Successful rerun executed with `-SkipCompile` from:
  - `calibration/self_employment_baseline/run_ai_calibration.ps1`
  - source file:
    - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113_self_employment.cpp`
  - completed log:
    - `calibration/self_employment_baseline/runtime/data/output/case_1/run_ui_000_se147_ui000_caploss025_fhire025_m40_retry_20260309_103325.log`
- Final `case 147`, `UI=0.00` outcomes:
  - `best_tol = 0.0136763`
  - `entr_share = 0.34248`
  - self-employed share among entrepreneurs `= 0.766994`
  - employer share among entrepreneurs `= 0.233006`
  - `n_entrepreneur avg = 2.55286`
  - `k_entrepreneur avg = 54.0490`
  - final `theta_new = 0.60371`
- Comparison to `case 146`, `UI=0.00`:
  - entrepreneur share: `0.33784 -> 0.34248`
  - self-employed share among entrepreneurs: `0.637314 -> 0.766994`
  - employer share among entrepreneurs: `0.362686 -> 0.233006`
  - `n_entrepreneur avg`: `2.60280 -> 2.55286`
  - `k_entrepreneur avg`: `55.2095 -> 54.0490`
- Interpretation:
  - the fixed employer-threshold cost remains operative in the no-UI experiment;
  - `case 147` now looks stronger, not weaker, as the benchmark candidate because it preserves the necessity-entry response while sharply improving self-employed/employer composition;
  - the next calibration move should be a nearby `f_hire` sensitivity (`0.15` or `0.35`) rather than re-running this point again.

### Session: 2026-03-06 (self-employment closure benchmark + employer-threshold test)
- Clarified the self-employment failure benchmark and coded/ran two main self-employment benchmark cases in:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113_self_employment.cpp`
- `case 146` now means:
  - self-employment root active,
  - entrepreneur closure risk active,
  - closure preserves current-period entrepreneurial income,
  - closure sends the household to the non-UI unemployment state,
  - `25%` partial capital loss on failure.
- `case 146` baseline run:
  - log: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_se146_baseline_caploss025_m40_20260306_154805.log`
  - final outcomes:
    - `best_tol = 0.00366586`
    - `entr_share = 0.17872`
    - self-employed share among entrepreneurs `= 0.438675`
    - employer share among entrepreneurs `= 0.561325`
    - `n_entrepreneur avg = 6.07554`
    - `k_entrepreneur avg = 97.4221`
- Matched policy checks for `case 146`:
  - `UI=0.05`:
    - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_005_se146_ui005_caploss025_m40_20260306_160236.log`
    - final outcomes:
      - `best_tol = 0.00638394`
      - `entr_share = 0.28679`
      - self-employed share among entrepreneurs `= 0.572126`
      - employer share among entrepreneurs `= 0.427874`
  - `UI=0.00`:
    - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_se146_ui000_caploss025_m40_20260306_160236.log`
    - final outcomes:
      - `best_tol = 0.0113072`
      - `entr_share = 0.33784`
      - self-employed share among entrepreneurs `= 0.637314`
      - employer share among entrepreneurs `= 0.362686`
- Interpretation of `case 146`:
  - this branch is much more credible than the no-risk self-employment baseline;
  - lower UI raises entrepreneurship mainly through more self-employment and lower average firm scale;
  - baseline still looked too employer-heavy, which motivated testing an employer-threshold cost.
- Added `case 147 = case 146 + f_hire`:
  - `self_employment_hiring_fixed_cost = 0.25`
  - intended interpretation: a discrete employer-threshold cost on top of smooth hiring/search cost `kappa`
- `case 147` baseline run:
  - log: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_se147_baseline_caploss025_fhire025_m40_20260306_162657.log`
  - final outcomes:
    - `best_tol = 0.00803501`
    - `entr_share = 0.17805`
    - self-employed share among entrepreneurs `= 0.576804`
    - employer share among entrepreneurs `= 0.423196`
    - `n_entrepreneur avg = 6.15868`
    - `k_entrepreneur avg = 98.1596`
- Key inference:
  - `f_hire` barely changes total entrepreneurship,
  - but it moves composition materially toward more self-employment and fewer employers,
  - so `case 147` is a promising next benchmark candidate.
- Literature/provenance work:
  - added `notes/12_failure_timing_capital_loss_and_legal_form.md`
  - added `notes/13_employer_threshold_cost.md`
  - source chain recorded there:
    - Cockx and Desiere (2024) on the first employee,
    - Guo and Wallskog (2025) on new-employer payroll taxes,
    - Harju, Matikka, and Rauhanen (2019) on compliance costs,
    - Blatter, Muehlemann, and Schenker (2012) as broader hiring-cost evidence and caution.
- Paper draft update:
  - `drafts/necessity_entrepreneurship_self_employed.lyx` now explicitly includes `f_hire` in the calibration discussion and parameter table
  - wording states clearly that `f_hire` is an evidence-motivated experimental choice, not a directly estimated structural parameter.

### Session: 2026-03-05 (post-fix proper UI experiment set + draft update)
- Ran the corrected case-101 endogenous-tax UI ladder under matched settings (`SingleCase=101`, `MaxIterAgg=40`, `RngSeed=12345`, `-SkipCompile`):
  - baseline (`UI=0.40`): `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_endog101_baseline_m40_uioverridefix_20260305_20260305_145040.log`
  - low UI (`UI=0.05`): `calibration/ai_calibration/runtime/data/output/case_1/run_ui_005_endog101_ui005_m40_uioverridefix_20260305_20260305_150731.log`
  - no UI (`UI=0.00`): `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_endog101_ui000_m40_uioverridefix_20260305_20260305_145727.log`
- Key outcomes (baseline -> low UI -> no UI):
  - `entr_share`: `0.07884 -> 0.07944 -> 0.08466`
  - equilibrium `tau_y`: `0.01812 -> 0.00277 -> 0.00066`
  - `total_lower_out`: `8994.34 -> 1092.55 -> 0`
  - final `theta_new`: `0.61111 -> 0.62802 -> 0.61191` (little change baseline vs no-UI)
- By-education firm-size moments (mean entrepreneur `n`):
  - low: `8.9299 -> 8.7125 -> 5.6389`
  - medium: `12.0528 -> 11.6187 -> 10.8825`
  - high: `21.5651 -> 21.9708 -> 21.6084`
  - interpretation: scale contraction is concentrated in low/medium education groups; high-education scale is nearly unchanged.
- Saved experiment artifacts:
  - `notes/endog101_ui005_m40_uioverridefix_opt_n_diff_edu_2026-03-05.txt`
  - `notes/endog101_ui005_m40_uioverridefix_state_change_occp_insim_2026-03-05.txt`
  - `notes/endog101_postfix_ui_ladder_comparison.md`
- Updated draft tables to post-fix case-101 values:
  - `drafts/tables/baseline_vs_low_ui_endogenous.tex`
  - `drafts/tables/baseline_vs_no_ui_endogenous.tex`
  - added `drafts/tables/firm_size_by_education_postfix_case101.tex`
  - inserted new firm-size table in `drafts/necessity_entrepreneurship.lyx`
- LyX PDF build:
  - added local `drafts/placeins.sty` fallback for compile reliability.
  - built PDF with LyX batch export:
    - `drafts/necessity_entrepreneurship.pdf` (updated `2026-03-05 15:18`).

### Session: 2026-03-02 (continued case-51 ladder on model 5.1)
- Confirmed active runner remains on model 5.1:
  - `calibration/ai_calibration/run_ai_calibration.ps1` default `SingleCase='51'`.
- Executed comparable case-51 ladder runs (`-SkipTransition -MaxIterAgg 40 -RngSeed 12345 -SkipCompile`) at:
  - `UI=0.40`: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_case51_ladder_m40_ui040_20260302_125757.log`
  - `UI=0.05`: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_case51_ladder_m40_ui005_20260302_130215.log`
  - `UI=0.00`: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_case51_ladder_m40_ui000_20260302_130637.log`
- Result summary (all three logs):
  - same end-state metrics across UI values:
    - `best_tol=0.0499975`,
    - `new theta=0.0101269`,
    - `n_demand=0`, `n_supply=1416.03`,
    - `opt_n_0` diagnostics at end: `nonfinite=36000`,
    - realized entrepreneur labor: `n_entrepreneur avg/max = 0/0`.
  - run metadata confirms overrides were applied (`[override] lowerincome_b` recorded per UI), but equilibrium classification is unchanged.
- Interpretation:
  - case 51 currently settles in the same corner regime at `UI=0.40`, `0.05`, and `0.00`;
  - immediate debugging target is vacancy-floor dependence in `theta` updates (`v_t=1`, `v_mode=2`) versus endogenous vacancy dynamics.

### Session: 2026-03-02 (switched to case 51 / model 5.1)
- Switched active runner case to 51:
  - `calibration/ai_calibration/run_ai_calibration.ps1` default `SingleCase` changed from `101` to `51`.
  - `calibration/ai_calibration/README.md` updated to match (`default 51`).
- Case-51 runs on current patched canonical source:
  - `m5`: `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_case51_m5_interpclamp_20260302_121659.log`
  - `m40`: `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_case51_m40_interpclamp_20260302_121802.log`
- Findings:
  - no numerical blowup in case 51 under current interpolation/indexing fixes;
  - `best_tol` reaches `0.00642932` by iter 40, but outcome is a corner/degenerate equilibrium:
    - `theta -> 0`,
    - `n_demand -> 0`,
    - near-zero labor supply/employment in simulation diagnostics.
- Interpretation:
  - for case 51, convergence metric improves but toward an economically degenerate fixed point; next step is diagnosing the vacancy/unemployment transition channel behind the collapse.

### Session: 2026-03-02 (interpolation/indexing fix materially stabilizes GE loop)
- Added deeper diagnostics in canonical source `main_2025_v1_case113.cpp`:
  - top-state dump for `opt_n_0` tails (`n`, `p_work`, `edu`, `occp_state`, `a_idx`, `x_idx`, `a`, `x`);
  - per-iteration asset out-of-grid counters in simulation:
    - `a0_from_prev` (incoming asset state),
    - `a1_policy` (policy-implied next asset).
- Found and fixed a concrete interpolation indexing inconsistency:
  - `intp_2d` now indexes policy arrays as `[current_state][choice]`, consistent with declarations and `intp_2d_in_6arg`.
- Added interpolation query clamping to grid bounds:
  - `intp_2d`, `intp_2d_opt`, `intp_2d_in_6arg`.
  - This prevents extreme extrapolation when simulated states leave policy-grid support.
- Key comparison runs:
  - pre-interp-clamp reference (`m40`): `run_ui_000_postfix_m40_indexfix_noclampdiag_20260302_113043.log`
    - `n_demand` still exhibits large spikes (up to `1.00386e+19`) and collapses;
    - `best_tol` stuck around `1.42347`.
  - post-interp-clamp (`m20`): `run_ui_000_postfix_m20_interpclamp_20260302_114842.log`
    - `n_demand` drops from `2.175e7` to `1.346e5`;
    - `best_tol` improves to `0.440178`.
  - post-interp-clamp (`m40`): `run_ui_000_postfix_m40_interpclamp_20260302_115636.log`
    - no giant blowups,
    - `n_demand` bounded (max `2.175e7`, end `1.23397e5`),
    - `best_tol` improves to `0.027779`.
- Persistent residual issue after stabilization:
  - entrepreneur realization remains concentrated in education group 0 in these runs (`entr_count_edu` near `[10900,0,0]`);
  - out-of-grid entrepreneur asset frequency remains high, but interpolation no longer explodes due bounded query evaluation.

### Session: 2026-03-02 (occupation-mapping harmonization + comparable rerun)
- Canonical source patched in `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`:
  - in `simulation()`, added `education_index_from_person(...)` and replaced repeated inline education assignment branches;
  - converted theta/rho counting blocks from hard-threshold occupational classification (`intp_occp_sim`) to probability-weighted counting (`intp_2d_opt`);
  - fixed `ppl_edu` ordering-before-use bugs in:
    - unemployment diagnostics loop,
    - welfare interpolation loop (`tmp_cev`),
    - state-change export loop (`state_change_occp_insim.txt`);
  - converted unemployment diagnostics (`unemp_edu_*`, `entr_edu_*`, `emp_edu_*`) to probability-weighted accounting.
- Comparable rerun executed:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_m5_diag_mapfix_20260302_103407.log`
  - config: `ui_000`, `skip_transition`, `max_iter_agg=5`, `seed=12345`, `single_case=101`.
- Comparison vs pre-patch m5 log:
  - entrepreneur mass unchanged: `entr_count=10900`, `entr_count_edu=[10900,0,0]`;
  - probability diagnostics are tighter in late iterations;
  - dominant issue persists: very large entrepreneur labor demand/tails remain and can be larger post-patch in early GE steps (iter 2 `n_demand`: `4.549e8` vs `3.190e7` pre-patch; iter 2 `n_entrepreneur avg`: `41734` vs `2927`).
- Interpretation:
  - mapping/reporting inconsistency was real and fixed in patched blocks,
  - primary non-convergence bottleneck remains entrepreneur policy-demand scale/interpolation behavior.

### Session: 2026-03-02 (canonical main wired to runner + entrepreneur-tail diagnostics)
- Canonical source routing fixed:
  - `calibration/ai_calibration/run_ai_calibration.ps1` now defaults to:
    - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`
  - compile include-path fix added so canonical source compiles with `nr.h` from AI workspace.
  - new runner parameter `-SingleCase` (default `101`) exported to `CFV_SINGLE_CASE`.
- Canonical source (`main_2025_v1_case113.cpp`) patched to honor runtime overrides:
  - `CFV_WORKINGPATH`, `CFV_UI_REPLACEMENT`, `CFV_MAX_ITER_AGG`, `CFV_SINGLE_CASE`, `CFV_RNG_SEED`.
- Numerical guardrails added in canonical source:
  - probability clamps for matching/separation transitions (`theta`, `rho`),
  - denominator guards for `u_t`, `cacu_1`, `earning_wkr`, `n_supply`, and related ratios,
  - safe/positive market updates for `r` and `w`,
  - non-negativity clamps for simulated entrepreneur `n` and `k`.
- Added diagnostics in canonical source:
  - policy-tail diagnostics (`opt_n_0`, `opt_k_0`) per GE iteration,
  - realized entrepreneur diagnostics (`entr_count`, edu split, raw/clamped `n,k` tails).
- Key runs:
  - smoke (`m1`) after patching:
    - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_smoke_v2_20260302_100320.log`
  - diagnostic run (`m5`) used for current inference:
    - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_m5_diag_20260302_101219.log`
    - config: `ui_000`, `skip_transition`, `max_iter_agg=5`, `seed=12345`, `single_case=101`.
- Findings from diagnostic run:
  - previous invalid dynamics are reduced (no negative `r/w` sign flips; theta constrained to valid probability use),
  - dominant remaining issue is large entrepreneur demand scale:
    - `opt_n_0` max around `2.9e4` in early iterations,
    - realized entrepreneur `n` quickly reaches `10^3`-`10^4`,
    - drives very large `n_demand` and strong upward wage pressure.
  - realized entrepreneur mass remains fixed at `10900` (`0.109`) and concentrated in edu group 0 in these runs.
- Coauthor-ready note drafted in:
  - `notes/04_empirical_notes.md` (`Coauthor update draft (canonical main diagnostics)` section).

### Session: 2026-03-01 (interrupted project resumed; ladder rerun executed)
- Patched runner reliability in `calibration/ai_calibration/run_ai_calibration.ps1`:
  - ensured MSYS2 runtime path (`C:/msys64/ucrt64/bin`) is added even under `-SkipCompile` so existing `cfv_red_final_ai.exe` launches reliably (fixes missing-DLL `-1073741515` failures);
  - switched non-timeout execution path to `Start-Process` with redirected stdout/stderr, matching timeout path and avoiding PowerShell-native stderr escalation interruptions;
  - changed exit-code handling so missing process exit code (`999`) is logged as warning instead of terminating run failure.
- Resumed UI ladder protocol in patched harness:
  - command pattern:
    - `./run_ai_calibration.ps1 -Scenario baseline -UiOverride <ui> -SkipTransition -MaxIterAgg 5 -RngSeed 12345 -TimeoutSeconds 900 -SkipCompile -RunTag ladder_m5_ui...`
  - UI points executed: `0.40`, `0.30`, `0.20`, `0.10`, `0.05`, `0.00`.
- Key outcomes from first solve block at each UI:
  - all six UI points returned `solve_model_status=not_converged` at `iter_agg=5`;
  - residual magnitude (`tol_ge`) remained high and similar across ladder (roughly `2.40` to `2.54`);
  - no first-pass convergence region was found in this quick capped ladder.
- Runtime behavior notes:
  - `0.40/0.30/0.20/0.10` logs completed without timeout flags, but still used warning path `exit_code=999`;
  - `0.05` and `0.00` produced first solve-block status, then timed out later in run (`timeout_seconds=900`, `timed_out=1`).
- Latest logs:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui040_20260228_133935.log`
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui030_20260228_134301.log`
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui020_20260301_090124.log`
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui010_20260301_090804.log`
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui005_retry_20260301_100942.log`
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui000_20260301_102517.log`

### Session: 2026-02-28 (cleanup + canonical Dropbox source confirmation)
- Archived legacy/non-canonical project artifacts to reduce active-folder clutter:
  - moved root `PROJECT_PLAN.md` to:
    - `notes/old/2026-02-28/PROJECT_PLAN_legacy_2026-02-18.md`
  - moved older exploratory/non-key AI calibration logs to:
    - `calibration/ai_calibration/runtime/data/output/old/2026-02-28_noncanonical_logs/`
  - moved compile logs to same dated archive folder:
    - `compile_debug.log`, `compile_out.log`
  - moved LaTeX build artifacts in `referee/` to:
    - `referee/old/build_artifacts/2026-02-28/`
- Canonical Dropbox archive path confirmed:
  - `C:/Users/Dave_/Dropbox/Necessity Entrepeneurs/Archive.zip`
  - canonical code entry name found in archive:
    - `main_2025_v1_case113.cpp`
  - note: this differs from earlier shorthand label `main_2025_vi+Case113` in status notes.
- Extracted canonical snapshot to project tree for reproducible reference:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/`
  - contains:
    - `main_2025_v1_case113.cpp`
    - `policy_functions_v17_in.txt`
    - `rnd_100k.txt`
    - `x_shk_iid.txt`
    - `input_pi_x_iid_1.txt`
    - `input_pi_x.txt` (copied from local runtime input directory because this file was not present in `Archive.zip`)
- Hash verification completed:
  - SHA256 matched between extracted snapshot and runtime inputs for:
    - `policy_functions_v17_in.txt`
    - `rnd_100k.txt`
    - `x_shk_iid.txt`
    - `input_pi_x_iid_1.txt`
- Run-readiness update:
  - required input files now present in `calibration/ai_calibration/runtime/data/input/cfv/`.
  - remaining practical decision before ladder rerun: strict raw-canonical run vs patched-harness run for comparability.
- Attempted ladder execution update:
  - patched `calibration/ai_calibration/run_ai_calibration.ps1` so `-SkipCompile` no longer hard-fails when no compiler is installed.
  - attempted UI ladder (`0.40`, `0.30`, `0.20`, `0.10`, `0.05`, `0.00`) with fixed caps/seed.
  - runs did not produce usable solve output under current machine runtime/toolchain state; generated minimal metadata-only logs.
  - archived these failed attempt logs to:
    - `calibration/ai_calibration/runtime/data/output/old/2026-02-28_failed_ladder_attempt/`
  - additional runner patch: timeout process path now flags missing process exit code as warning (`process_exit_code_missing`) instead of silently recording exit `0`.

### Session: 2026-02-27 (next-session handoff note from user)
- User instruction for future runs: use `main_2025_vi+Case113` (Dropbox archive) as the canonical main code for ongoing experiments.
- Planned rerun sequence for next session:
  - start at `UI=0.40` and test convergence first;
  - step down UI sequentially (`0.30`, `0.20`, `0.10`, `0.05`, `0.00`) under comparable run settings.
- Planned diagnostics focus if low UI still fails:
  - reuse existing evidence that aggregate GE feedback (`r/w/theta`) is the likely bottleneck;
  - track theta sign flips, boundary hits, and residual path (`tol_ge`);
  - compare against pinned-controls diagnostics (`fixed r/w`, `fixed theta/rho`, fully pinned aggregates) to localize instability.

### Session: 2026-02-27 (deep ablation + partial-equilibrium diagnostics)
- Extended ablation controls in calibration source:
  - added `CFV_FIXED_R`, `CFV_FIXED_W`, `CFV_UPDATE_STEP1`, `CFV_MARKET_GAP_CLAMP`
  - added guarded market-gap update helpers for `r/w` updates (invalid/negative candidate protection, optional gap clamp)
- Updated runner/docs:
  - `calibration/ai_calibration/run_ai_calibration.ps1` now supports `-FixedR`, `-FixedW`, `-UpdateStep1`, `-MarketGapClamp`
  - `calibration/ai_calibration/README.md` updated accordingly
  - `calibration/ai_calibration/run_ablation_matrix.ps1`:
    - added `focused` and `deep` profiles
    - classification now reads the **last** `[ABLT]` status block in logs (important because main runs two calibration solves)
- Executed focused/deep diagnostics and targeted controls:
  - `run_ablation_matrix.ps1 -Profile focused` (`m15` runs)
  - `run_ablation_matrix.ps1 -Profile deep` (`m40` runs)
  - `ui_000` partial-equilibrium diagnostics:
    - fixed `r/w/theta/rho`: converged in 1 aggregate iteration
    - fixed `r/w` only: non-converged at `m40` but much smaller residual (`tol_ge ~ 0.0268`), no theta sign flips
  - `ui_000` damping sensitivity:
    - `update_step1=0.90` and `0.98` both worse than `0.95` in deep run
- Added market-gap guardrails for aggregate `r/w` update:
  - helper guards in `cfv_red_final.cpp` prevent invalid negative updates and support optional clamp via `CFV_MARKET_GAP_CLAMP`
  - strict clamp trial (`0.5`) in `ui_000` deep run reduced sign flips but created frequent clipping warnings and did not improve residual convergence gap; default clamp set to permissive `10.0` (opt-in tighter clamp only)
- Added consolidated machine-readable summary of key 2026-02-27 runs:
  - `calibration/ai_calibration/runtime/data/output/ablation/diagnostic_key_runs_2026-02-27.csv`
- Added optional adaptive GE damping mode:
  - source/runtime controls: `CFV_ADAPTIVE_GE`, `CFV_ADAPTIVE_MIN_STEP`, `CFV_ADAPTIVE_MAX_STEP`, `CFV_ADAPTIVE_TIGHTEN`, `CFV_ADAPTIVE_RELAX`, `CFV_ADAPTIVE_IMPROVE_RATIO`, `CFV_ADAPTIVE_WORSEN_RATIO`
  - wrapper params added in `run_ai_calibration.ps1`
  - outcomes (vs non-adaptive `ui_000 m40`):
    - non-adaptive `m40`: `tol_ge ~ 0.4038`
    - adaptive `m40`: `tol_ge ~ 1.1735` (worse)
    - adaptive `m80`: `tol_ge ~ 1.5328` (worse)
  - adaptive comparison file:
    - `calibration/ai_calibration/runtime/data/output/ablation/adaptive_comparison_2026-02-27.csv`
- Session ended by user interrupt during tuned adaptive test:
  - `run_ui_000_ui000_m40_adaptive_tuned_*.log` contains only metadata header (no completed solve block).
- Inference from runs:
  - aggregate feedback loop is the dominant convergence bottleneck;
  - fixing matching (`theta/rho`) removes oscillation signatures but does not alone close the GE residual;
  - policy/simulation block can run stably under pinned aggregates.

### Session: 2026-02-27 (ablation matrix runner + quick simplification run)
- Added runtime ablation controls to `calibration/ai_calibration/cfv_red_final.cpp`:
  - `CFV_SKIP_TRANSITION`, `CFV_FIXED_THETA`, `CFV_FIXED_RHO`
  - `CFV_MAX_ITER_AGG`, `CFV_MAX_TRANSITION_ITER`, `CFV_TRANSITION_TOL`
  - `CFV_RNG_SEED` (deterministic RNG seeding)
  - end-of-run machine-readable status lines (`[ABLT] solve_model_status=...`, `[ABLT] transition_status=...`)
- Extended single-run wrapper `calibration/ai_calibration/run_ai_calibration.ps1`:
  - supports ablation params (`-SkipTransition`, `-FixedTheta`, `-FixedRho`, `-MaxIterAgg`, `-MaxTransitionIter`, `-TransitionTol`, `-RngSeed`, `-TimeoutSeconds`, `-SkipCompile`, `-RunTag`)
  - standardized per-run metadata logging (`[ABLT] ...`) in run logs
- Added matrix orchestrator `calibration/ai_calibration/run_ablation_matrix.ps1`:
  - builds predefined run matrix (`quick`/`full`)
  - executes runs, classifies stop rules, and writes summary artifacts
- Updated `calibration/ai_calibration/README.md` with new ablation usage.
- Executed quick matrix:
  - command: `./run_ablation_matrix.ps1 -Profile quick`
  - artifacts:
    - `calibration/ai_calibration/runtime/data/output/ablation/run_matrix.csv`
    - `calibration/ai_calibration/runtime/data/output/ablation/ablation_summary.csv`
    - `calibration/ai_calibration/runtime/data/output/ablation/ablation_report.md`
  - result pattern: all quick capped runs returned `solve_model_status=not_converged` with warning-heavy logs (classified `blowing_up` by current stop rules).

### Session: 2026-02-25 (folder capitalization standardized to lowercase)
- Renamed project domain folders to lowercase:
  - `calibration/` -> `calibration/`
  - `figures/` -> `figures/`
  - `literature/` -> `literature/`
  - `notes/` -> `notes/`
  - `referee/` -> `referee/`
- Updated internal project paths in docs/scripts/source files to match lowercase folders.
- Updated shared guidance references tied to this project and lowercase naming convention.

### Session: 2026-02-25 (clean draft view: lyx/pdf only)
- Applied global clean-view rule for paper folders:
  - keep only latest `.lyx` and `.pdf` visible in `drafts/` and `slides/`
  - move `.tex` exports to archive source paths
  - move LaTeX/BibTeX build artifacts to archive build paths
- Necessity paths now:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/old_drafts/source_tex/necessity_entrepreneurship.tex`
  - `research_projects/01_Necessity_Entrepreneurs/slides/old_slides/source_tex/necessity_entrepreneurship_slides.tex`
  - `research_projects/01_Necessity_Entrepreneurs/drafts/old_drafts/build_artifacts/`
- Added reusable cleanup script:
  - `_shared/scripts/hide_tex_and_artifacts.ps1`
- Updated reference-flag sync script to target archived TeX:
  - `research_projects/01_Necessity_Entrepreneurs/scripts/sync_reference_flags.ps1`

### Session: 2026-02-25 (drafts and slides structure standardization)
- Standardized latest draft files (no version suffix) in `drafts/`:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/necessity_entrepreneurship.lyx`
  - `research_projects/01_Necessity_Entrepreneurs/drafts/necessity_entrepreneurship.tex`
  - `research_projects/01_Necessity_Entrepreneurs/drafts/necessity_entrepreneurship.pdf`
- Standardized latest slide files (no version suffix) in `slides/`:
  - `research_projects/01_Necessity_Entrepreneurs/slides/necessity_entrepreneurship_slides.lyx`
  - `research_projects/01_Necessity_Entrepreneurs/slides/necessity_entrepreneurship_slides.tex`
  - `research_projects/01_Necessity_Entrepreneurs/slides/necessity_entrepreneurship_slides.pdf`
- Standardized archive structure:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/old_drafts/`
  - `research_projects/01_Necessity_Entrepreneurs/slides/old_slides/`
- Preserved legacy root/temporary files under:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/old_drafts/legacy_pre_standardization/`

### Session: 2026-02-25 (checklist format switch + naming preference)
- Replaced dated markdown reference checklist with single-file Excel-friendly CSV workflow:
  - `research_projects/01_Necessity_Entrepreneurs/literature/checklist/reference_checklist.csv` (single source file)
  - `confirm_yn` values: `Y/Yes` = done; blank or `N` = open
  - open-item view handled directly in Excel via column filter (no second CSV, no script)
- Folder organization cleanup for paper workflow:
  - moved `research_projects/01_Necessity_Entrepreneurs/docs/` to `research_projects/01_Necessity_Entrepreneurs/notes/`
  - initially set canonical latest outputs in project root (`paper_latest.pdf`, `slides_latest.pdf`) [later superseded by drafts/slides standardization]
  - moved temporary LyX export PDFs to `research_projects/01_Necessity_Entrepreneurs/drafts/old_drafts/`
- Removed the prior markdown checklist file (superseded by CSV workflow).
- Shared memory updated with global filename preference:
  - no date prefixes for working documents by default; use dated names only for explicit archives/backups or when requested.
- Renamed literature verification artifacts to non-dated filenames:
  - `research_projects/01_Necessity_Entrepreneurs/notes/legacy_literature_citation_verification.md`
  - `research_projects/01_Necessity_Entrepreneurs/notes/literature/pdf_restore_report.csv`
  - `research_projects/01_Necessity_Entrepreneurs/notes/literature/pdf_direct_attempts.csv`
  - `research_projects/01_Necessity_Entrepreneurs/notes/literature/pdf_additional_attempts.csv`
  - `research_projects/01_Necessity_Entrepreneurs/notes/legacy_literature_verified_pdf_snippets.txt`

### Session: 2026-02-24 (AI calibration workspace + solver robustness patch)
- Created isolated calibration workspace:
  - `research_projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/`
  - copied source/header: `.../ai_calibration/cfv_red_final.cpp`, `.../ai_calibration/nr.h`
  - created runtime scaffold: `.../ai_calibration/runtime/data/input/cfv/`, `.../ai_calibration/runtime/data/output/`
- Added setup/run tooling:
  - `.../ai_calibration/setup_ai_calibration.ps1`
  - `.../ai_calibration/run_ai_calibration.ps1`
  - `.../ai_calibration/README.md`
- Patched calibration diagnostics in AI copy to address no-UI convergence fragility:
  - removed hard dependence on legacy fixed path by introducing `CFV_WORKINGPATH` environment-root support;
  - added required-input validation for `policy_functions_v17_in.txt`, `rnd_100k.txt`, `x_shk_iid.txt`, `input_pi_x_iid_1.txt`, `input_pi_x.txt`;
  - added theta tolerance in `check_agg()` (previously effectively zero-tolerance);
  - removed `static` scope on aggregate iteration counter in `solve_model()`;
  - added safeguards for `theta` updates (`v_t/u_t`) and `rho` updates (zero employed count);
  - guarded `tau_y1 = total_lower_out / earning_wkr` against near-zero denominator.
- Added run-time scenario override via environment variable:
  - `CFV_UI_REPLACEMENT` now overrides `lowerincome_b` in AI calibration copy, enabling scripted `baseline`, `ui_005`, `ui_000` runs.
- Current blocker remains unchanged:
  - required `data/input/cfv/*` files not present locally in this workspace.

### Session: 2026-02-24 (compiler path selected + literature [CHECK] markup)
- Installed MSYS2 and UCRT64 GCC toolchain for forward-running calibration:
  - `C:/msys64/ucrt64/bin/g++.exe` (`g++ 15.2.0`)
- Updated AI run script compiler detection:
  - `research_projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/run_ai_calibration.ps1`
  - now auto-detects and uses `C:/msys64/ucrt64/bin/g++.exe` even when `g++` is not on PATH.
- Updated literature review draft to add explicit verification flags after each cited study:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
  - added `[CHECK]` markers after five citations in `\\section{Literature Review}`.

### Session: 2026-02-23 (draft sync, affiliation fix, experiment-curve update, calibration triage)
- Stabilized LyX/TeX/PDF workflow for active draft:
  - Source: `research_projects/01_Necessity_Entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.lyx`
  - Synced export: `.../drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
  - Rebuilt PDF: `.../drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.pdf`
- Updated section-table placement to keep experiment tables attached to sections:
  - `.../drafts/tables/baseline_results_only.tex`
  - `.../drafts/tables/baseline_vs_low_ui_endogenous.tex`
  - `.../drafts/tables/baseline_vs_no_ui_endogenous.tex`
  - `.../drafts/tables/baseline_vs_no_ui_fixed.tex`
- Abstract temporarily replaced with `TO BE COMPLETED.` in the draft LyX.
- Updated David affiliation to `Department of Economics, Durham Business School` in:
  - local draft LyX/TeX;
  - Dropbox main paper LyX: `C:/Users/Dave_/Dropbox/Necessity Entrepeneurs/Chivers et al. (2025) Necessity Entrepreneurship.lyx`
  - Dropbox coauthor package LyX: `C:/Users/Dave_/Dropbox/Necessity Entrepeneurs/David AI output/Coauthor_Package_2026-02-18/Chivers et al. (2025) Necessity Entrepreneurship.lyx`
- Curve figures for current experiment set (7.1/7.2/7.3) generated from latest tables:
  - `research_projects/01_Necessity_Entrepreneurs/figures/curve_entrepreneurship_by_education_current_experiments.png/.pdf`
  - `research_projects/01_Necessity_Entrepreneurs/figures/curve_labor_demand_by_education_current_experiments.png/.pdf`
  - `research_projects/01_Necessity_Entrepreneurs/figures/curve_transition_rates_current_experiments.png/.pdf`
  - generator script: `research_projects/01_Necessity_Entrepreneurs/figures/generate_experiment_curves.py`
  - copied same files to Dropbox project `figures/`.
- Slide comparison result:
  - `research_projects/01_Necessity_Entrepreneurs/Slides_paper_v4.tex` and `Dropbox/.../Slides_v3.lyx` still use old case-based curve figures (`case_220/221/222/225/226`, `case_222_with_*`), not the new 7.1/7.2/7.3 experiment framing.
- Calibration debugging triage:
  - recovered code into project tree: `research_projects/01_Necessity_Entrepreneurs/calibration/cfv_red_final.cpp` and `nr.h`.
  - identified likely no-UI convergence issues in code (theta tolerance check, aggregate loop stability, missing guards).
  - full replication not run yet due missing compiler in session and missing required external inputs (`data/input/cfv/*`) plus hardcoded root path.

### Session: 2026-02-23 (literature restore + lit-review rewrite)
- Restored project-local literature PDFs into `research_projects/01_Necessity_Entrepreneurs/literature/`:
  - `buera_2009.pdf`
  - `fairlie_fossen_2019.pdf`
  - `hurst_pugsley_2011.pdf`
  - `petrongolo_pissarides_2001_workingpaper_2000.pdf`
  - `poschke_2013_workingpaper_2012.pdf`
  - `cagetti_denardi_2006_workingpaper.pdf`
- Rewrote `\\section{Literature Review}` in
  `research_projects/01_Necessity_Entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
  to rely on verified local PDF evidence.
- Added citation verification artifacts:
  - `research_projects/01_Necessity_Entrepreneurs/notes/legacy_literature_citation_verification.md`
  - `research_projects/01_Necessity_Entrepreneurs/notes/literature/pdf_restore_report.csv`
  - `research_projects/01_Necessity_Entrepreneurs/notes/literature/pdf_direct_attempts.csv`
  - `research_projects/01_Necessity_Entrepreneurs/notes/legacy_literature_verified_pdf_snippets.txt`
- Recompiled draft with bibliography:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.pdf`
- Remaining gap: several cited keys still do not have exact-paper PDFs restored locally (tracked in `STATUS.md` and citation verification report).

### Session: 2026-02-23 (additional citation recovery pass)
- Added additional local literature files:
  - `research_projects/01_Necessity_Entrepreneurs/literature/sedlacek_sterk_2017_repository_version.pdf`
  - `research_projects/01_Necessity_Entrepreneurs/literature/donovan_lu_schoellman_2020_sr596.pdf`
  - `research_projects/01_Necessity_Entrepreneurs/literature/cagetti_denardi_2003_wp620.pdf`
- Added archive subfolder for failed/non-PDF fetches:
  - `research_projects/01_Necessity_Entrepreneurs/literature/old/2026-02-23_failed_downloads/`
- Updated literature-review text to include `\\citet{sedlacek_sterk_2017}` after restoring repository full text.
- Recompiled draft and bibliography:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.pdf`
- Final targeted recovery pass confirmed no open exact-paper PDFs for:
  - `lucas_1978`, `evans_jovanovic_1989`, `hurst_lusardi_2004`, `mortensen_pissarides_1994`, `donovan_lu_schoellman_2023`, `cagetti_denardi_2006` (exact journal versions).

### Session: 2026-02-23 (single canonical status tracker)
- Added canonical project tracker: `research_projects/01_Necessity_Entrepreneurs/STATUS.md`
- Consolidated "where are we" and next-actions workflow into `STATUS.md`.
- Set rule: future to-do/status updates should go to `STATUS.md` first (not new ad hoc lists).

### Session: 2026-02-19 (paper draft v2.0 + PDF)
- Created new paper draft in subfolder: `drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
- Added high-level writing pass to:
  - abstract
  - introduction (including literature-positioning paragraphs)
  - baseline results narrative
  - conclusion
- Compiled PDF output: `drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.pdf`
- Note: `literature/` folder is currently empty, so citation expansion remains pending verified sources.

### Session: 2026-02-19 (global BibTeX + dedicated literature review section)
- Created shared bibliography: `_shared/references/global_references.bib`
- Added `natbib` + bibliography wiring in paper draft:
  - `research_projects/01_Necessity_Entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
- Added dedicated `\\section{Literature Review}` with verified citations.
- Recompiled PDF with bibliography rendered.

### Session: 2026-02-19 (repo reorganisation)
- Repository restructured: `PaperProjects/` renamed to `projects/`; `skills/` moved to `_shared/skills/`
- This file and `README.md` created as part of the new workspace standard
- No changes made to paper content in this session

### Session: 2026-02-18 (math audit + code crosswalk)
- Math audit run on full LyX file; 30 issues found
- Referee response drafted and compiled: `referee/RESPONSE_TO_REFEREE.tex/.pdf`
- CodeÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“paper crosswalk of `cfv_red_final.cpp` completed
- 10 discrepancies found (D1ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“D10); D1 fixed; D2ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“D10 require decisions

---

## Key files

| Role | Path |
|---|---|
| Paper source (TeX) | `research_projects/01_Necessity_Entrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.tex` |
| C++ calibration code | `research_projects/01_Necessity_Entrepreneurs/calibration/cfv_red_final.cpp` |
| Referee response (TeX) | `research_projects/01_Necessity_Entrepreneurs/referee/RESPONSE_TO_REFEREE.tex` |
| Math audit report | `research_projects/01_Necessity_Entrepreneurs/referee/codeaudit_2026-02-18/CODE_REFEREE_REPORT.md` |
| Figure scripts | `research_projects/01_Necessity_Entrepreneurs/figures/generate_enter_employed.py` |

## Open decisions (as of 2026-02-18)

| ID | Question | Owner |
|----|----------|-------|
| D2 | Entrepreneur continuation: stay entrepreneur or re-enter as unemployed? | Bo / Dave |
| D3 | $\bar{m}$: paper says 0.8, code uses 0.9. Which is correct? | Dave |
| D4 | $b$: paper says 0.40w, code uses 0.30w/0.25w. Which? | Dave |
| D5 | $\tau_y$: paper says 0.151, code uses 0.037. Same object? | Dave + Bo |
| D6 | HSV progressive tax: is it in the model or aspirational? | Dave |
| D7 | $\alpha, \gamma$: paper shows averages, code uses education-varying. Clarify in paper? | Dave |
| D8 | Government budget: code doesn't balance. Note in paper or fix in code? | Dave |
| D9 | $p(\theta)$ vs $q(\theta)$ in vacancy cost: verify with Bo | Bo |

## Case-to-experiment mapping

| Case # | Experiment |
|---|---|
| 220 | Low unemployment insurance |
| 221 | High unemployment insurance |
| 222 | **Baseline** |
| 225 | No unemployment (frictionless market) |
| 226 | Unknown ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ask Dave |

## Key conventions

- TeX file is ~54k tokens; read in 400ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“500 line chunks.
- $i_w$ coding: paper uses 0=unemployed, 1=employed, 2=entrepreneur; code uses reverse (0=entrepreneur).
- Build LaTeX in the `referee/` folder: `pdflatex RESPONSE_TO_REFEREE.tex`.
- Do NOT commit `.aux`, `.log`, `.out` build artifacts.

