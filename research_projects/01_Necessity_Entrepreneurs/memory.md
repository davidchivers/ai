# Project Memory - Necessity Entrepreneurs

Most recent session first.

---

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
  - `projects/01_necessity_entrepreneurs/drafts/old_drafts/source_tex/necessity_entrepreneurship.tex`
  - `projects/01_necessity_entrepreneurs/slides/old_slides/source_tex/necessity_entrepreneurship_slides.tex`
  - `projects/01_necessity_entrepreneurs/drafts/old_drafts/build_artifacts/`
- Added reusable cleanup script:
  - `_shared/scripts/hide_tex_and_artifacts.ps1`
- Updated reference-flag sync script to target archived TeX:
  - `projects/01_necessity_entrepreneurs/scripts/sync_reference_flags.ps1`

### Session: 2026-02-25 (drafts and slides structure standardization)
- Standardized latest draft files (no version suffix) in `drafts/`:
  - `projects/01_necessity_entrepreneurs/drafts/necessity_entrepreneurship.lyx`
  - `projects/01_necessity_entrepreneurs/drafts/necessity_entrepreneurship.tex`
  - `projects/01_necessity_entrepreneurs/drafts/necessity_entrepreneurship.pdf`
- Standardized latest slide files (no version suffix) in `slides/`:
  - `projects/01_necessity_entrepreneurs/slides/necessity_entrepreneurship_slides.lyx`
  - `projects/01_necessity_entrepreneurs/slides/necessity_entrepreneurship_slides.tex`
  - `projects/01_necessity_entrepreneurs/slides/necessity_entrepreneurship_slides.pdf`
- Standardized archive structure:
  - `projects/01_necessity_entrepreneurs/drafts/old_drafts/`
  - `projects/01_necessity_entrepreneurs/slides/old_slides/`
- Preserved legacy root/temporary files under:
  - `projects/01_necessity_entrepreneurs/drafts/old_drafts/legacy_pre_standardization/`

### Session: 2026-02-25 (checklist format switch + naming preference)
- Replaced dated markdown reference checklist with single-file Excel-friendly CSV workflow:
  - `projects/01_necessity_entrepreneurs/literature/checklist/reference_checklist.csv` (single source file)
  - `confirm_yn` values: `Y/Yes` = done; blank or `N` = open
  - open-item view handled directly in Excel via column filter (no second CSV, no script)
- Folder organization cleanup for paper workflow:
  - moved `projects/01_necessity_entrepreneurs/docs/` to `projects/01_necessity_entrepreneurs/notes/`
  - initially set canonical latest outputs in project root (`paper_latest.pdf`, `slides_latest.pdf`) [later superseded by drafts/slides standardization]
  - moved temporary LyX export PDFs to `projects/01_necessity_entrepreneurs/drafts/old_drafts/`
- Removed the prior markdown checklist file (superseded by CSV workflow).
- Shared memory updated with global filename preference:
  - no date prefixes for working documents by default; use dated names only for explicit archives/backups or when requested.
- Renamed literature verification artifacts to non-dated filenames:
  - `projects/01_necessity_entrepreneurs/notes/legacy_literature_citation_verification.md`
  - `projects/01_necessity_entrepreneurs/notes/literature/pdf_restore_report.csv`
  - `projects/01_necessity_entrepreneurs/notes/literature/pdf_direct_attempts.csv`
  - `projects/01_necessity_entrepreneurs/notes/literature/pdf_additional_attempts.csv`
  - `projects/01_necessity_entrepreneurs/notes/legacy_literature_verified_pdf_snippets.txt`

### Session: 2026-02-24 (AI calibration workspace + solver robustness patch)
- Created isolated calibration workspace:
  - `projects/01_necessity_entrepreneurs/calibration/ai_calibration/`
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
  - `projects/01_necessity_entrepreneurs/calibration/ai_calibration/run_ai_calibration.ps1`
  - now auto-detects and uses `C:/msys64/ucrt64/bin/g++.exe` even when `g++` is not on PATH.
- Updated literature review draft to add explicit verification flags after each cited study:
  - `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
  - added `[CHECK]` markers after five citations in `\\section{Literature Review}`.

### Session: 2026-02-23 (draft sync, affiliation fix, experiment-curve update, calibration triage)
- Stabilized LyX/TeX/PDF workflow for active draft:
  - Source: `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.lyx`
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
  - `projects/01_necessity_entrepreneurs/figures/curve_entrepreneurship_by_education_current_experiments.png/.pdf`
  - `projects/01_necessity_entrepreneurs/figures/curve_labor_demand_by_education_current_experiments.png/.pdf`
  - `projects/01_necessity_entrepreneurs/figures/curve_transition_rates_current_experiments.png/.pdf`
  - generator script: `projects/01_necessity_entrepreneurs/figures/generate_experiment_curves.py`
  - copied same files to Dropbox project `figures/`.
- Slide comparison result:
  - `projects/01_necessity_entrepreneurs/Slides_paper_v4.tex` and `Dropbox/.../Slides_v3.lyx` still use old case-based curve figures (`case_220/221/222/225/226`, `case_222_with_*`), not the new 7.1/7.2/7.3 experiment framing.
- Calibration debugging triage:
  - recovered code into project tree: `projects/01_necessity_entrepreneurs/calibration/cfv_red_final.cpp` and `nr.h`.
  - identified likely no-UI convergence issues in code (theta tolerance check, aggregate loop stability, missing guards).
  - full replication not run yet due missing compiler in session and missing required external inputs (`data/input/cfv/*`) plus hardcoded root path.

### Session: 2026-02-23 (literature restore + lit-review rewrite)
- Restored project-local literature PDFs into `projects/01_necessity_entrepreneurs/literature/`:
  - `buera_2009.pdf`
  - `fairlie_fossen_2019.pdf`
  - `hurst_pugsley_2011.pdf`
  - `petrongolo_pissarides_2001_workingpaper_2000.pdf`
  - `poschke_2013_workingpaper_2012.pdf`
  - `cagetti_denardi_2006_workingpaper.pdf`
- Rewrote `\\section{Literature Review}` in
  `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
  to rely on verified local PDF evidence.
- Added citation verification artifacts:
  - `projects/01_necessity_entrepreneurs/notes/legacy_literature_citation_verification.md`
  - `projects/01_necessity_entrepreneurs/notes/literature/pdf_restore_report.csv`
  - `projects/01_necessity_entrepreneurs/notes/literature/pdf_direct_attempts.csv`
  - `projects/01_necessity_entrepreneurs/notes/legacy_literature_verified_pdf_snippets.txt`
- Recompiled draft with bibliography:
  - `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.pdf`
- Remaining gap: several cited keys still do not have exact-paper PDFs restored locally (tracked in `STATUS.md` and citation verification report).

### Session: 2026-02-23 (additional citation recovery pass)
- Added additional local literature files:
  - `projects/01_necessity_entrepreneurs/literature/sedlacek_sterk_2017_repository_version.pdf`
  - `projects/01_necessity_entrepreneurs/literature/donovan_lu_schoellman_2020_sr596.pdf`
  - `projects/01_necessity_entrepreneurs/literature/cagetti_denardi_2003_wp620.pdf`
- Added archive subfolder for failed/non-PDF fetches:
  - `projects/01_necessity_entrepreneurs/literature/old/2026-02-23_failed_downloads/`
- Updated literature-review text to include `\\citet{sedlacek_sterk_2017}` after restoring repository full text.
- Recompiled draft and bibliography:
  - `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.pdf`
- Final targeted recovery pass confirmed no open exact-paper PDFs for:
  - `lucas_1978`, `evans_jovanovic_1989`, `hurst_lusardi_2004`, `mortensen_pissarides_1994`, `donovan_lu_schoellman_2023`, `cagetti_denardi_2006` (exact journal versions).

### Session: 2026-02-23 (single canonical status tracker)
- Added canonical project tracker: `projects/01_necessity_entrepreneurs/STATUS.md`
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
  - `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
- Added dedicated `\\section{Literature Review}` with verified citations.
- Recompiled PDF with bibliography rendered.

### Session: 2026-02-19 (repo reorganisation)
- Repository restructured: `PaperProjects/` renamed to `projects/`; `skills/` moved to `_shared/skills/`
- This file and `README.md` created as part of the new workspace standard
- No changes made to paper content in this session

### Session: 2026-02-18 (math audit + code crosswalk)
- Math audit run on full LyX file; 30 issues found
- Referee response drafted and compiled: `referee/RESPONSE_TO_REFEREE.tex/.pdf`
- CodeÃ¢â‚¬â€œpaper crosswalk of `cfv_red_final.cpp` completed
- 10 discrepancies found (D1Ã¢â‚¬â€œD10); D1 fixed; D2Ã¢â‚¬â€œD10 require decisions

---

## Key files

| Role | Path |
|---|---|
| Paper source (TeX) | `projects/01_necessity_entrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.tex` |
| C++ calibration code | `projects/01_necessity_entrepreneurs/calibration/cfv_red_final.cpp` |
| Referee response (TeX) | `projects/01_necessity_entrepreneurs/referee/RESPONSE_TO_REFEREE.tex` |
| Math audit report | `projects/01_necessity_entrepreneurs/referee/codeaudit_2026-02-18/CODE_REFEREE_REPORT.md` |
| Figure scripts | `projects/01_necessity_entrepreneurs/figures/generate_enter_employed.py` |

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
| 226 | Unknown Ã¢â‚¬â€ ask Dave |

## Key conventions

- TeX file is ~54k tokens; read in 400Ã¢â‚¬â€œ500 line chunks.
- $i_w$ coding: paper uses 0=unemployed, 1=employed, 2=entrepreneur; code uses reverse (0=entrepreneur).
- Build LaTeX in the `referee/` folder: `pdflatex RESPONSE_TO_REFEREE.tex`.
- Do NOT commit `.aux`, `.log`, `.out` build artifacts.

