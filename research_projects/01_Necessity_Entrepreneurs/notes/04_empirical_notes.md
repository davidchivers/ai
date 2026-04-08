# 04 Empirical notes

## Coauthor update draft (canonical main diagnostics)

Date: 2026-03-02

Context:
- We switched calibration execution to the canonical source: `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`.
- The runner now enforces one-case runs (`CFV_SINGLE_CASE=101`), UI override (`CFV_UI_REPLACEMENT`), aggregate-iteration cap (`CFV_MAX_ITER_AGG`), and deterministic seed (`CFV_RNG_SEED`).

Code hardening applied (to prevent invalid dynamics while preserving model logic):
- Probability safety: clamp matching/separation probabilities to `[0,1]` when used in transitions.
- Denominator safety: guard `u_t`, `cacu_1`, `earning_wkr`, `n_supply`, and ratio updates used in GE/fiscal updates.
- Price-update safety: constrain market-gap updates so `r` and `w` do not flip sign from one extreme-imbalance step.
- Non-negativity safety: clamp interpolated entrepreneur `n` and `k` used in simulation aggregation to `>= 0`.

New diagnostics added:
- Policy-surface tails each GE iteration for `opt_n_0` and `opt_k_0`.
- Realized entrepreneur mass and tails (`entr_count`, `entr_count_edu`, raw/interpolated `n` and `k` min/max, and tail counts).

Latest run used:
- `ui_000`, `skip_transition`, `max_iter_agg=5`, `seed=12345`, `single_case=101`.
- Log: `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_m5_diag_20260302_101219.log`.

Key findings:
- `theta` no longer goes outside probability range, and `r/w` no longer flip negative under the guarded update.
- Main remaining instability now appears to be entrepreneur labor-demand scale:
  - `opt_n_0` policy tails are very large (example max around `2.9e4` in early GE iterations).
  - Realized entrepreneur `n` is also very large (order `10^3` to `10^4`) once iteration progresses.
  - This mechanically drives very large `n_demand` and pushes wage updates strongly upward.
- Entrepreneur mass in realized simulation remains fixed at `10900` (share `0.109`) and is concentrated in education group 0 in these runs.

Interpretation:
- The current bottleneck is less about raw `theta` instability and more about the scale/mapping of entrepreneur policy objects (`opt_n_0`, and related `opt_k_0`) feeding labor demand in simulation.
- Next debugging target should be policy interpolation/mapping consistency by occupation/education state and scale normalization of entrepreneur choices before GE aggregation.

## Follow-up patch and rerun (occupation mapping)

Date: 2026-03-02

Code changes applied in canonical main:
- In `simulation()`, added a single `education_index_from_person(...)` mapper to avoid repeated threshold logic and boundary mismatches.
- Replaced hard-threshold `intp_occp_sim` counting with probability-weighted counting (`intp_2d_opt`) in both theta/rho counting blocks.
- Fixed `ppl_edu` ordering bugs where education was read before assignment in:
  - unemployment-rate diagnostics loop,
  - welfare interpolation loop (`cev`),
  - state-change export loop.
- Updated unemployment diagnostics (`unemp_edu_*`, `entr_edu_*`, `emp_edu_*`) to probability-weighted accounting rather than binary threshold classification.

Comparable rerun:
- `ui_000`, `skip_transition`, `max_iter_agg=5`, `seed=12345`, `single_case=101`.
- New log: `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_m5_diag_mapfix_20260302_103407.log`.
- Baseline comparison log: `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_postfix_m5_diag_20260302_101219.log`.

Findings from patched rerun:
- The run completes cleanly (same wrapper warning path: `exit_code=999` with missing process exit code).
- Entrepreneur mass and concentration are unchanged: `entr_count=10900`, `entr_count_edu=[10900, 0, 0]`.
- Probability diagnostics are more internally consistent in later iterations (example at iter 5: random unemployment probability `0.845219` vs implied `0.845784`, a much tighter gap than pre-patch).
- Main instability remains: entrepreneur labor demand is still very large.
  - Iteration 2 `n_demand` is even larger post-patch (`4.549e8` vs `3.190e7` pre-patch).
  - Iteration 2 realized entrepreneur `n` average rises sharply (`41734` vs `2927` pre-patch).

Updated interpretation:
- The diagnostics/mapping inconsistencies were real and are now corrected in these blocks.
- But non-convergence is still dominated by extreme entrepreneur policy scale (`opt_n_0` tails / interpolation region behavior), not by the previously mixed counting logic alone.

## Deep follow-up: interpolation bug and stabilization patch

Date: 2026-03-02

Additional diagnostics added:
- `opt_n_0` top-state dump (top 8 states with `n`, `p_work`, `edu`, current occupation, and `a/x` grid points).
- Per-iteration asset out-of-grid counters:
  - `a0_from_prev` (states entering simulation from previous `a1`),
  - `a1_policy` (new policy-implied next-period assets).

Core new findings:
- Out-of-grid assets are persistent for entrepreneur states (`~10900` each simulation pass in these runs).
- Before interpolation fixes, this produced extreme extrapolation artifacts:
  - huge positive `n_raw` spikes (and in deeper iterations, huge negative `n_raw` collapses),
  - unstable swings in `n_demand` and wages.
- A concrete indexing inconsistency was also found in `intp_2d`:
  - policy array was read as `[choice][current_state]` in one function, inconsistent with declared/used layout `[current_state][choice]`.

Code fixes applied:
- Corrected `intp_2d` policy indexing to `[i_x_occp][x_occp0]` (aligning with array declaration and `intp_2d_in_6arg`).
- Added grid-bound input clamping inside interpolation routines:
  - `intp_2d`,
  - `intp_2d_opt`,
  - `intp_2d_in_6arg`.
  This prevents extreme extrapolation when `a` or `x` query points fall outside the policy grid.

Key run outcomes after interpolation fixes:
- `m20` (`run_ui_000_postfix_m20_interpclamp_20260302_114842.log`):
  - `n_demand` shrinks from `2.175e7` (iter 1) to `1.346e5` (iter 20),
  - `n_entrepreneur avg` falls to `12.35`,
  - `best_tol` improves to `0.440`.
- `m40` (`run_ui_000_postfix_m40_interpclamp_20260302_115636.log`):
  - `n_demand` remains bounded (`max 2.175e7`, ending around `1.234e5`),
  - no giant `10^19`/`10^40` blowups,
  - `best_tol` improves substantially to `0.027779`.

Interpretation update:
- A major part of the apparent non-convergence was numerical/interpolation error rather than a purely structural model failure.
- After fixing indexing + extrapolation handling, aggregate dynamics are much better behaved and residuals drop sharply.
- Remaining issue to investigate: persistent entrepreneur mass concentration in education group 0 (`entr_count_edu`), and why entrepreneur states remain out-of-grid so often (possible grid design/policy-boundary issue).

## Write-up draft: post-fix UI experiments (case 101, endogenous tax)

Date: 2026-03-05

Setup:
- Proper matched comparison was run with `SingleCase=101`, `MaxIterAgg=40`, `RngSeed=12345`, and endogenous tax closure.
- UI ladder: baseline `UI=0.40`, low UI `UI=0.05`, and no UI `UI=0.00`.
- Logs:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_endog101_baseline_m40_uioverridefix_20260305_20260305_145040.log`
  - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_005_endog101_ui005_m40_uioverridefix_20260305_20260305_150731.log`
  - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_endog101_ui000_m40_uioverridefix_20260305_20260305_145727.log`

Headline quantitative results:
- Entrepreneurship share rises as UI falls:
  - `0.07884` (UI=0.40) -> `0.07944` (UI=0.05) -> `0.08466` (UI=0.00).
- Endogenous tax and transfer objects move sharply:
  - equilibrium `tau_y`: `0.01812 -> 0.00277 -> 0.00066`,
  - UI outlays (`total_lower_out`): `8994.34 -> 1092.55 -> 0`,
  - tax revenue (`total_tax`): `6584.28 -> 1056.83 -> 254.13`.
- Matching tightness does not collapse in the no-UI run:
  - `theta_new`: `0.61111` (baseline), `0.62802` (UI=0.05), `0.61191` (UI=0.00).

Firm size by education (mean entrepreneur labor demand `n`):
- Low education: `8.9299` -> `8.7125` -> `5.6389` (`-36.85%` vs baseline at UI=0.00).
- Medium education: `12.0528` -> `11.6187` -> `10.8825` (`-9.71%` at UI=0.00).
- High education: `21.5651` -> `21.9708` -> `21.6084` (approximately unchanged).
- Overall entrepreneur mean `n`: `14.9009` -> `14.6931` -> `13.6459` (`-8.42%` at UI=0.00).

Interpretation for draft text:
- After fixing the UI-override path, the model does generate meaningful responses to UI cuts.
- The `UI=0.05` step is modest because it is still a positive safety net and because endogenous fiscal closure already offsets a large part of transfer financing through a lower equilibrium tax rate.
- Moving from `UI=0.05` to `UI=0.00` then produces a larger compositional shift toward lower-scale entrepreneurship, concentrated in low- and medium-education groups.
- In these runs, the no-UI effect is not a pure unemployment-risk channel: it is a joint effect of (i) reduced insurance and (ii) large tax/transfer adjustment, with little change in aggregate matching tightness under the vacancy-floor environment.

Paper-facing text candidate (compact):
- "In the corrected case-101 experiments with endogenous tax closure, cutting unemployment insurance raises entrepreneurship but primarily through composition and fiscal adjustment. Entry rises from 0.0788 (UI=0.40) to 0.0847 (UI=0.00), while the equilibrium tax rate falls from 0.0181 to 0.0007 as transfer spending is removed. The firm-size contraction is concentrated among low- and medium-education entrepreneurs (low-education mean `n`: 8.93 to 5.64), whereas high-education firm size is nearly unchanged. This pattern is consistent with increased necessity entry at the bottom of the distribution rather than a uniform collapse in entrepreneurial scale."

## Coauthor explanation: why the zero-UI case now converges

Date: 2026-03-06

What the older archive does and does not show:
- The archived March 4 `ui000_101A` rerun is **not** valid evidence on the zero-UI equilibrium.
- Evidence:
  - `run_ui_000_ui000_101A_noskip_m40_rerunA_20260304_20260304_125328.log` records `ui_override=0.00`, but it ends with the same terminal moments as the corresponding baseline run:
    - `entr_share = 0.07884`,
    - `n_entrepreneur avg = 14.9009`,
    - `theta_new = 0.611106`,
    - `Baseline equilibrium tau_y = 0.0181222`.
  - Those are the baseline case-101 moments, not a true no-UI steady state.
- Interpretation:
  - the March 4 archive still reflects the pre-fix UI-override path, so it should be treated as a mislabeled baseline-equivalent run rather than a separate no-UI check.

What changed before the true zero-UI convergence result:
- The credible no-UI result appears only after the March 5 `uioverridefix` pass, on top of the earlier numerical stabilization work already documented above.
- The important ingredients are:
  - consistent interpolation indexing and grid clamping,
  - probability/denominator guards in the GE loop,
  - non-negativity clamps on simulated entrepreneur `n` and `k`,
  - a corrected UI override path so case 101 actually runs at the requested `lowerincome_b`.

Evidence: true zero-UI convergence in corrected case 101 (endogenous tax)
- Log:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_endog101_ui000_m40_uioverridefix_20260305_20260305_145727.log`
- Terminal moments:
  - `best_tol = 0.00556019`,
  - `theta_new = 0.61191`,
  - `r_new = 0.0848609`,
  - `w_new = 3.33355`,
  - `entr_share = 0.08466`,
  - `n_entrepreneur avg = 13.6459`,
  - `n_supply / n_demand = 115755 / 115526 = 0.999978`,
  - UI outlays fall to `0`,
  - equilibrium `tau_y` is near zero (`0.00065727` in the comparison summary; simulation update line `3.88994e-07` at the end of the run).

Why convergence occurs now:
- This is not evidence that the model collapses to a trivial corner.
- Evidence:
  - matching tightness stays interior (`theta` remains around `0.61`, not near zero),
  - labor demand and supply are closely aligned at the terminal iteration,
  - entrepreneur policy tails remain bounded (`opt_n_0 max` around `81`, not the earlier explosive values),
  - the final run does not show the earlier extrapolation-driven blowups.
- Interpretation:
  - convergence now occurs because the main numerical failure points were removed, so the fixed-point iteration can settle instead of being knocked off course by bad interpolation/extrapolation and failed policy overrides.

How much is fiscal closure versus pure zero-UI behavior?
- The endogenous-tax run makes convergence easier because removing UI also removes transfer spending, so the equilibrium tax rate collapses sharply.
- But that is not the whole story, because zero UI also converges under fixed tax once the path is run cleanly.

Evidence: zero UI also converges with fixed baseline tax
- Clean March 6 log:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_fixedtax113_ui000_m40_homotopyfix_20260306_091442.log`
- This run first solves baseline case 101 to get `tau_y_baseline = 0.0181222`, then follows the fixed-tax homotopy to target `lowerincome_b = 0.00`.
- Terminal moments:
  - `best_tol = 0.00286268`,
  - `theta_new = 0.615773`,
  - `entr_share = 0.08262`,
  - `n_entrepreneur avg = 14.0681`,
  - `Fixed tau_y (baseline) = 0.0181222`,
  - `UI payments = 0`,
  - `Endogenous lump-sum tax = -0.069693` (a transfer back to households because the fixed baseline tax now over-raises revenue when UI is removed).

Interpretation for coauthors:
- The corrected model now finds a zero-UI steady state under both closures:
  - endogenous tax, and
  - fixed baseline tax plus lump-sum rebating.
- Therefore the new convergence is **not** solely an artifact of letting `tau_y` fall toward zero.
- The endogenous-tax channel still matters quantitatively:
  - it amplifies entry (`0.08466` vs `0.08262`) and produces a somewhat stronger firm-size compression (`13.6459` vs `14.0681` mean entrepreneur `n`),
  - but it is not the fundamental reason the iteration converges.

Current status of the `101A` versus `101` comparison:
- The March 4 `101A` archive should not be used as the "alternative calibration already checked" result for zero UI, because it reproduces the baseline path.
- If `101A` is meant to refer to a genuinely distinct parameterization rather than that archived run tag, the exact defining parameter block still needs to be identified before treating it as a separate sanity check.

Short coauthor-facing summary paragraph:
- "The apparent March 4 zero-UI convergence in the `101A` archive was not a genuine no-UI result: the run still landed on the baseline case because the UI override was not yet propagating through the standard case-101 path. After fixing that path and the earlier interpolation/indexing problems, the model now converges cleanly at zero UI in case 101 (`best_tol = 0.00556`). Importantly, the same qualitative convergence survives when we hold the tax rate fixed at the baseline value and use a lump-sum rebate (`best_tol = 0.00286`), so the result is not just an artifact of the endogenous tax rate collapsing to zero. The endogenous fiscal channel still amplifies the quantitative response, but it is no longer the only reason the solver succeeds."
