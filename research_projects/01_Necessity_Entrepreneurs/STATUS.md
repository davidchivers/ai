# STATUS - 01_Necessity_Entrepreneurs

## Snapshot

- Last updated: 2026-03-02
- Overall state: canonical main is runnable and numerically stable under interpolation/indexing fixes; model 5.1 (case 51) is now reproducible across UI levels but remains in a corner regime with zero labor demand, so focus is identifying the mechanism locking the model there.
- 2026-03-02 continued case-51 (model 5.1) ladder run and classification:
  - completed comparable runs (`-SkipTransition`, `MaxIterAgg=40`, `RngSeed=12345`, `SingleCase=51`) at:
    - `UI=0.40`: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_case51_ladder_m40_ui040_20260302_125757.log`
    - `UI=0.05`: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_case51_ladder_m40_ui005_20260302_130215.log`
    - `UI=0.00`: `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_case51_ladder_m40_ui000_20260302_130637.log`
  - observed end-state metrics were effectively identical across all three UI points:
    - `best_tol=0.0499975`,
    - `new theta=0.0101269`,
    - `n_demand=0` with positive `n_supply` (`1416.03`),
    - `opt_n_0` diagnostics: all nonfinite (`nonfinite=36000`), with realized entrepreneur labor `n_entrepreneur avg/max = 0/0`.
  - inference:
    - all tested case-51 ladder points classify as corner outcomes (not interior equilibria),
    - UI replacement level is not moving the equilibrium in this current configuration.
- 2026-03-02 canonical-main stabilization and deep diagnostics:
  - runner pathing/source selection fixed in `calibration/ai_calibration/run_ai_calibration.ps1`:
    - canonical default source now `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`,
    - include-path compile fix added for canonical source (`nr.h` resolution),
    - new `-SingleCase` parameter wired to `CFV_SINGLE_CASE` (default `101`) for one-case reproducible runs,
    - log metadata now records `single_case`.
  - canonical source patched to honor runtime env overrides:
    - `CFV_WORKINGPATH`, `CFV_UI_REPLACEMENT`, `CFV_MAX_ITER_AGG`, `CFV_SINGLE_CASE`, `CFV_RNG_SEED`.
  - canonical source numerical hardening added:
    - probability clamps for matching/separation probabilities,
    - denominator guards (`u_t`, `cacu_1`, `earning_wkr`, `n_supply`, etc.),
    - guarded/positive `r/w` market updates,
    - non-negativity clamps for interpolated entrepreneur `n` and `k` in simulation aggregation.
  - new diagnostics added in canonical source:
    - per-iteration policy-tail report for `opt_n_0`/`opt_k_0`,
    - realized entrepreneur diagnostics (`entr_count`, education split, raw/clamped `n,k` min/max and tail counts).
  - key diagnostic run:
    - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_m5_diag_20260302_101219.log`
    - configuration: `ui_000`, `-SkipTransition`, `MaxIterAgg=5`, `RngSeed=12345`, `SingleCase=101`.
  - observed pattern:
    - no invalid probability overflow or negative `r/w` sign flips under new guards,
    - `opt_n_0` policy tails are very large (max around `2.9e4` in early GE iterations),
    - realized entrepreneur `n` values also reach large magnitudes (`10^3`-`10^4`) and drive huge `n_demand`,
    - entrepreneur realized mass remains `10900` (`0.109`) and concentrated in edu group 0 in these runs.
  - inference:
    - primary current convergence bottleneck is now entrepreneur policy-demand scale/mapping (not only theta boundary dynamics).
- 2026-03-02 occupation-mapping harmonization patch + comparable rerun:
  - canonical source (`main_2025_v1_case113.cpp`) `simulation()` updates:
    - added single education mapper (`education_index_from_person`) to avoid repeated boundary/misassignment logic,
    - replaced hard-threshold occupational counting (`intp_occp_sim`) with probability-weighted counting (`intp_2d_opt`) in both theta/rho counting blocks,
    - fixed `ppl_edu` ordering bugs in:
      - unemployment diagnostics loop,
      - welfare interpolation loop (`cev`),
      - state-change export loop.
    - unemployment diagnostics (`unemp_edu_*`, `entr_edu_*`, `emp_edu_*`) now use probability-weighted accounting.
  - comparable rerun:
    - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_m5_diag_mapfix_20260302_103407.log`
    - config held fixed: `ui_000`, `-SkipTransition`, `MaxIterAgg=5`, `RngSeed=12345`, `SingleCase=101`.
  - observed after patch:
    - run remains stable and comparable (same wrapper warning path: `exit_code=999` due missing process exit code),
    - entrepreneur mass unchanged (`entr_count=10900`, `entr_count_edu=[10900,0,0]`),
    - probability diagnostics are internally tighter in later iterations,
    - but entrepreneur demand scale remains the dominant issue; example:
      - GE iteration 2 `n_demand` increased (`4.549e8` vs `3.190e7` pre-patch),
      - GE iteration 2 realized entrepreneur `n` average increased (`41734` vs `2927` pre-patch).
  - inference:
    - mapping/ordering defects were real and are now corrected in these reporting/counting paths,
    - non-convergence still appears to be driven by extreme entrepreneur policy scale/interpolation behavior.
- 2026-03-02 interpolation/indexing stabilization pass (major):
  - canonical source (`main_2025_v1_case113.cpp`) updates:
    - added top-state diagnostics for `opt_n_0` policy tails (`n`, `p_work`, `edu`, `occp`, `a/x`),
    - added per-iteration asset out-of-grid counters in simulation (`a0_from_prev`, `a1_policy`),
    - fixed `intp_2d` policy indexing to match declared storage order (`[current_state][choice]`),
    - clamped interpolation query inputs to policy-grid bounds in:
      - `intp_2d`,
      - `intp_2d_opt`,
      - `intp_2d_in_6arg`.
  - diagnostic progression:
    - without interpolation clamping, deeper runs show out-of-grid entrepreneur states and intermittent explosive/negative `n_raw` artifacts;
    - with interpolation clamping enabled:
      - `m20` log `run_ui_000_postfix_m20_interpclamp_20260302_114842.log`:
        - `n_demand` declines from `2.175e7` to `1.346e5`,
        - `best_tol` improves to `0.440178`.
      - `m40` log `run_ui_000_postfix_m40_interpclamp_20260302_115636.log`:
        - no giant `10^19`/`10^40` blowups,
        - `n_demand` remains bounded (`max 2.175e7`, ending `1.23397e5`),
        - `best_tol` improves to `0.027779`.
  - inference:
    - a large share of prior instability was numerical (interpolation extrapolation + indexing inconsistency), not only structural model dynamics.
- 2026-03-02 switched active case to 51 (model 5.1) and validated:
  - runner default updated:
    - `calibration/ai_calibration/run_ai_calibration.ps1`: `SingleCase` default now `51`.
    - `calibration/ai_calibration/README.md` updated to match.
  - case-51 diagnostic runs:
    - `m5`: `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_case51_m5_interpclamp_20260302_121659.log`
    - `m40`: `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_case51_m40_interpclamp_20260302_121802.log`
  - observed case-51 behavior:
    - `best_tol` improves to `0.00642932` by iter 40,
    - but dynamics collapse to degenerate equilibrium (`theta -> 0`, `n_demand -> 0`, near-zero labor supply/employment).
  - interpretation:
    - case 51 no longer shows numerical blowups under current fixes, but converges toward a corner/degenerate state rather than an economically meaningful interior equilibrium.
- 2026-03-01 calibration rerun resume:
  - patched `calibration/ai_calibration/run_ai_calibration.ps1` to improve reliability in this runtime:
    - ensure MSYS2 runtime path is added even with `-SkipCompile` (prevents `-1073741515` missing-DLL launch failures),
    - run executable via `Start-Process` redirection path for both timeout and non-timeout runs (prevents PowerShell stderr warning promotion from killing runs),
    - treat missing process exit code (`999`) as warning instead of hard failure.
  - resumed UI ladder in patched AI harness using consistent first-pass protocol:
    - `-SkipTransition -MaxIterAgg 5 -RngSeed 12345`
    - UI levels run: `0.40`, `0.30`, `0.20`, `0.10`, `0.05`, `0.00`.
  - first solve-block result at all UI points above: `solve_model_status=not_converged` with very similar residual levels (`tol_ge` roughly `2.40` to `2.54`), including low-UI cases.
  - run notes:
    - `UI=0.40/0.30/0.20/0.10` completed without timeout at file level (`timed_out=0`) but still reported `exit_code=999` warning path;
    - `UI=0.05` and `UI=0.00` logs include completed first solve block (`not_converged`) before timing out in later execution (`timeout_seconds=900`).
- 2026-02-28 cleanup and path check-in:
  - archived legacy planning file from project root:
    - `projects/01_Necessity_Entrepreneurs/notes/old/2026-02-28/PROJECT_PLAN_legacy_2026-02-18.md`
  - archived non-canonical calibration logs:
    - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/old/2026-02-28_noncanonical_logs/`
  - archived referee build artifacts (`.aux/.log/.out/.nav/.snm/.toc`):
    - `projects/01_Necessity_Entrepreneurs/referee/old/build_artifacts/2026-02-28/`
  - canonical Dropbox code source confirmed inside:
    - `C:/Users/Dave_/Dropbox/Necessity Entrepeneurs/Archive.zip`
    - canonical entry name in archive is `main_2025_v1_case113.cpp` (not literal `main_2025_vi+Case113`)
  - extracted canonical snapshot to:
    - `projects/01_Necessity_Entrepreneurs/calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/`
  - input hash check: `policy_functions_v17_in.txt`, `rnd_100k.txt`, `x_shk_iid.txt`, and `input_pi_x_iid_1.txt` match byte-for-byte between extracted Dropbox snapshot and AI runtime input folder.
- 2026-02-28 rerun execution check:
  - attempted UI ladder (`0.40` -> `0.00`) with fixed seed/caps in patched AI harness;
  - run wrapper now supports `-SkipCompile` without requiring compiler discovery (script fix applied);
  - however, this machine currently has no detectable `g++/clang++/cl`, and existing binaries are not currently runnable in a stable way under the present runtime environment;
  - provisional ladder logs from this failed attempt were archived to:
    - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/old/2026-02-28_failed_ladder_attempt/`
- 2026-02-27 calibration check-in: ablation harness added and quick simplification matrix run completed (`skip transition`, fixed seed, iteration caps, optional fixed matching). All quick probes returned `solve_model_status=not_converged` with repeated warning-heavy dynamics; no converged steady-state under these short capped runs.
- 2026-02-27 deep ablation check-in: 40-iteration focused runs (`baseline`, `ui_000`, `ui_000` with fixed matching) remain non-converged, but diagnostics isolate the bottleneck:
  - fixing matching (`theta/rho`) removes theta sign flips and lowers the residual gap (`tol_ge` around `0.112` at iter 40) without full convergence;
  - fixing `r/w` (partial-equilibrium test) further lowers residual (`tol_ge` around `0.0268` at iter 40) with no theta oscillation;
  - fixing `r/w/theta/rho` converges in 1 aggregate iteration (as expected under fully pinned aggregates);
  - damping sensitivity tests (`update_step1=0.90` and `0.98`) perform worse than current `0.95` in `ui_000` deep run.
- Inference: convergence wall is primarily in aggregate feedback mapping (`r,w,theta` loop), not in isolated policy-function block execution.
- 2026-02-27 stabilization probe: market-gap guardrails were added for `r/w` updates (`CFV_MARKET_GAP_CLAMP`, invalid-update fallback). A strict clamp trial (`0.5`) reduced sign flips but increased warning-heavy clipping and did not improve convergence; default clamp reset to permissive (`10.0`) so behavior remains close to baseline unless explicitly tightened.
- 2026-02-27 adaptive-damping probe: added optional adaptive GE step control (`CFV_ADAPTIVE_GE` and tuning knobs). In `ui_000`:
  - adaptive `m40` and `m80` both remained non-converged and performed worse than non-adaptive `m40` (`tol_ge` increased from `0.4038` to `1.1735` and `1.5328` respectively);
  - adaptive runs pushed `theta` to boundary more frequently.
  - inference: keep adaptive mode as an optional diagnostic tool, but not as default stabilization.
- 2026-02-27 session stop marker: tuned adaptive run (`run_ui_000_ui000_m40_adaptive_tuned_*.log`) was user-interrupted and contains only run metadata header (no solve output).
- 2026-02-27 decision note for next session: treat `main_2025_vi+Case113` in the Dropbox archive as the canonical main code for experiments going forward (not the current AI sandbox copy by default).
- 2026-02-27 next-session experiment protocol (planned): restart convergence checks at `UI=0.40`, then step down UI levels sequentially to locate the first failure region before deeper low-UI debugging.
- 2026-02-26 check-in: no material status change from 2026-02-25; blockers and next actions unchanged.
- 2026-02-25 check-in: no material status change from 2026-02-24; blockers and next actions unchanged.
- 2026-02-25 organization update: `docs/` moved to `notes/`; canonical latest outputs now standardized inside `drafts/` and `slides/` with unversioned filenames.
- 2026-02-25 naming update: project domain folders standardized to lowercase (`calibration/`, `figures/`, `literature/`, `notes/`, `referee/`).
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Math audit completed (30 issues identified).
- Referee response drafted and compiled:
  - `projects/01_necessity_entrepreneurs/referee/RESPONSE_TO_REFEREE.tex`
  - `projects/01_necessity_entrepreneurs/referee/RESPONSE_TO_REFEREE.pdf`
- Code-paper crosswalk completed (10 discrepancies tracked).
- Draft paper v2.0 written and compiled:
  - `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.tex`
  - `projects/01_necessity_entrepreneurs/drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.pdf`
- Draft/slide naming standardized (latest unversioned files):
  - `projects/01_necessity_entrepreneurs/drafts/necessity_entrepreneurship.{lyx,pdf}`
  - `projects/01_necessity_entrepreneurs/slides/necessity_entrepreneurship_slides.{lyx,pdf}`
  - tex exports archived in `drafts/old_drafts/source_tex/` and `slides/old_slides/source_tex/`
  - legacy files preserved under `projects/01_necessity_entrepreneurs/drafts/old_drafts/legacy_pre_standardization/`
- Literature task progressed:
  - Restored additional verifiable PDFs into `projects/01_necessity_entrepreneurs/literature/` (including repository and working-paper versions for previously missing citations).
  - Rewrote the draft literature-review section from verified local PDF evidence.
  - Built citation verification artifacts in `projects/01_necessity_entrepreneurs/notes/literature/`.
- Draft/build workflow updates completed:
  - LyX -> TeX sync verified for `drafts/Chivers_et_al_2025_Necessity_Entrepreneurship_v2_0.lyx`.
  - PDF rebuilt successfully from synced TeX.
  - Abstract replaced with `TO BE COMPLETED.` placeholder.
  - Section 6 / 7 tables anchored to their sections (`[H]` placement in table fragments).
- Affiliation updated:
  - Local draft LyX/TeX now uses `Department of Economics, Durham Business School`.
  - Same affiliation fix applied to Dropbox coauthor LyX files.
- New current-experiment curve figures generated from latest table set (7.1/7.2/7.3):
  - `projects/01_necessity_entrepreneurs/figures/curve_entrepreneurship_by_education_current_experiments.png/.pdf`
  - `projects/01_necessity_entrepreneurs/figures/curve_labor_demand_by_education_current_experiments.png/.pdf`
  - `projects/01_necessity_entrepreneurs/figures/curve_transition_rates_current_experiments.png/.pdf`
  - Script: `projects/01_necessity_entrepreneurs/figures/generate_experiment_curves.py`
  - Copied to Dropbox project `figures/` for coauthor access.
- Calibration source restored to project tree:
  - `projects/01_necessity_entrepreneurs/calibration/cfv_red_final.cpp`
  - `projects/01_necessity_entrepreneurs/calibration/nr.h`
- AI calibration workspace created for replication tasks 1-2:
  - `projects/01_necessity_entrepreneurs/calibration/ai_calibration/`
  - patched source with robust checks: `.../ai_calibration/cfv_red_final.cpp`
  - run/setup scripts: `.../ai_calibration/setup_ai_calibration.ps1`, `.../ai_calibration/run_ai_calibration.ps1`
  - runtime input/output scaffold: `.../ai_calibration/runtime/data/input/cfv/`, `.../ai_calibration/runtime/data/output/`
- Ablation execution harness added for convergence diagnostics:
  - runtime toggles in `.../ai_calibration/cfv_red_final.cpp` (`CFV_SKIP_TRANSITION`, `CFV_FIXED_THETA`, `CFV_FIXED_RHO`, `CFV_MAX_ITER_AGG`, `CFV_MAX_TRANSITION_ITER`, `CFV_TRANSITION_TOL`, `CFV_RNG_SEED`)
  - extended runner: `.../ai_calibration/run_ai_calibration.ps1`
  - matrix runner: `.../ai_calibration/run_ablation_matrix.ps1`
  - latest artifacts: `.../ai_calibration/runtime/data/output/ablation/run_matrix.csv`, `.../ablation_summary.csv`, `.../ablation_report.md`
- Added additional convergence diagnostics controls:
  - `CFV_FIXED_R`, `CFV_FIXED_W`, `CFV_UPDATE_STEP1`, `CFV_MARKET_GAP_CLAMP`
  - `CFV_ADAPTIVE_GE` plus adaptive tuning parameters (`MIN_STEP`, `MAX_STEP`, `TIGHTEN`, `RELAX`, `IMPROVE_RATIO`, `WORSEN_RATIO`)
  - guarded market-gap update helpers for `r/w` (invalid/negative update protection + optional gap clamp)
  - single-run diagnostic logs:
    - `run_ui_000_peq_ui000_fixed_all_*.log`
    - `run_ui_000_peq_ui000_fixed_rw_*.log`
    - `run_ui_000_ui000_m40_u090_*.log`
    - `run_ui_000_ui000_m40_u098_*.log`
    - `run_ui_000_ui000_m40_guarded_*.log`
  - consolidated key-run table:
    - `.../ai_calibration/runtime/data/output/ablation/diagnostic_key_runs_2026-02-27.csv`
  - adaptive comparison table:
    - `.../ai_calibration/runtime/data/output/ablation/adaptive_comparison_2026-02-27.csv`
- 2026-03-01 resumed ladder outputs captured in:
  - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui040_20260228_133935.log`
  - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui030_20260228_134301.log`
  - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui020_20260301_090124.log`
  - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui010_20260301_090804.log`
  - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui005_retry_20260301_100942.log`
  - `projects/01_Necessity_Entrepreneurs/calibration/ai_calibration/runtime/data/output/case_1/run_baseline_ladder_m5_ui000_20260301_102517.log`

## In Progress

- Case-51 (model 5.1) corner-regime diagnosis after completed comparable ladder (`UI=0.40/0.05/0.00`, `m40`) showing invariant outcomes.
- Isolating vacancy-floor channel (`v_t=1`, `v_mode=2`) versus endogenous vacancy construction in `theta` updates.
- Tracing why realized entrepreneur mass remains concentrated in education group 0 (`entr_count_edu` near `[10900,0,0]`) despite policy-top states concentrated in `edu=2`.
- Diagnosing persistent asset out-of-grid frequency for entrepreneur states (`a0_from_prev` / `a1_policy`) and deciding whether grid expansion vs state-clamp is the better model-consistent remedy.
- Slide-paper graph alignment: old case-based curve slides identified; migration to new 7.1/7.2/7.3 experiment graph set not yet integrated.

## Next 3 Tasks

1. For case 51, decompose the `theta` update channel with logging around vacancy-floor usage (`v_mode`, `v_floor`, `v_t`) versus endogenous vacancy terms to verify what pins `theta` near `0.0101` when `n_demand=0`.
2. Run a controlled case-51 sensitivity with vacancy-floor logic relaxed (or disabled) to test whether UI variation (`0.40/0.05/0.00`) can recover an interior equilibrium.
3. Compare case 51 vs case 101 under identical runner settings (`m40`, fixed seed, skip transition) to isolate whether corner behavior is case-specific or a broader post-fix dynamic.

## Blockers

- Some cited keys still lack exact-paper PDFs in `literature/` (`lucas_1978`, `evans_jovanovic_1989`, `hurst_lusardi_2004`, `mortensen_pissarides_1994`, `donovan_lu_schoellman_2023`; `cagetti_denardi_2006` exact-match pending).
  - After targeted endpoint checks (OpenAlex locations, IDEAS/RePEc, repository mirrors), these remaining exact versions appear closed/restricted.
- Practical execution friction remains in wrapper/runtime behavior: process exit code is intermittently missing (`999` warning path), though runs complete and logs are usable.

## Open Decisions

- D2: Entrepreneur continuation state rule (stay entrepreneur vs re-enter as unemployed).
- D3: `m_bar` value (paper 0.8 vs code 0.9).
- D4: UI replacement ratio object (`0.40w` vs `0.30w/0.25w` implementation).
- D5: Output tax value/object (`tau_y = 0.151` vs `0.037` in code).
- D6: HSV progressive tax treatment (active in model vs future extension).
- D7: Whether to keep education-specific `alpha, gamma` in paper presentation.
- D8: Government budget handling (document imbalance vs fix in code).
- D9: Vacancy cost mapping (`p(theta)` vs `q(theta)` object).

## References

- Primary project overview: `projects/01_necessity_entrepreneurs/README.md`
- Project session log: `projects/01_necessity_entrepreneurs/memory.md`
- Coding fix checklist (source detail): `projects/01_necessity_entrepreneurs/referee/codeaudit_2026-02-18/FIX_CHECKLIST.md`
- Full coding audit report: `projects/01_necessity_entrepreneurs/referee/codeaudit_2026-02-18/CODE_REFEREE_REPORT.md`
- Experiment action list: `projects/01_necessity_entrepreneurs/notes/experiments/experiments_todo.md`
- Cleanup review note: `projects/01_necessity_entrepreneurs/notes/cleanup_candidates_2026-02-28.md`
- Citation verification report: `projects/01_necessity_entrepreneurs/notes/legacy_literature_citation_verification.md`
- Reference checklist (single Excel-editable file): `projects/01_necessity_entrepreneurs/literature/checklist/reference_checklist.csv`
- Canonical Dropbox snapshot: `projects/01_necessity_entrepreneurs/calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/`
- Latest paper PDF: `projects/01_necessity_entrepreneurs/drafts/necessity_entrepreneurship.pdf`
- Latest slides PDF: `projects/01_necessity_entrepreneurs/slides/necessity_entrepreneurship_slides.pdf`

## Working Rule

- When asked "where are we?" or "write/update the to-do list", update this file first.

