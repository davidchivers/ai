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
