# Code Referee Report (Coding Only)
Date: 2026-02-18
Project: NecessityEntrepreneurs
Paper source of truth: Chivers et al. (2025) Necessity Entrepreneurship.lyx

## Scope
This is a static code audit of `calibration/cfv_red_final.cpp` against the current `.lyx` paper.
No compile/run tests were executed in this environment.

## Status Update (2026-02-24)
- This report still describes findings in the canonical source:
  - `projects/01_necessity_entrepreneurs/calibration/cfv_red_final.cpp`
- An isolated working copy was created for convergence debugging:
  - `projects/01_necessity_entrepreneurs/calibration/ai_calibration/cfv_red_final.cpp`
- Implemented in `AI_calibration` copy (not yet merged to canonical source):
  - `check_agg()` theta term now uses an explicit tolerance threshold.
  - Hardcoded root path replaced by `CFV_WORKINGPATH` environment-root support.
  - Required input-file presence checks added at startup.
  - Guardrails added for fragile updates (`v_t/u_t`, `rho`, `tau_y1` denominators).
  - Aggregate iteration counter scope in `solve_model()` corrected.
- Full rerun remains blocked by missing required input files:
  - `policy_functions_v17_in.txt`, `rnd_100k.txt`, `x_shk_iid.txt`,
    `input_pi_x_iid_1.txt`, `input_pi_x.txt`.

## Findings (ordered by severity)

### 1) Critical: Entrepreneur output is forced to zero in simulation
- File refs:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:972`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2189`
- Problem:
  - In branches where entrepreneur is chosen (`i_occp0_sim_tmp == 0`), output uses
    `y_sim = i_occp0_sim_tmp * x * k^alpha * n^gamma`, so `y_sim` is always zero.
- Why this matters:
  - This can distort aggregate output, `a_y`, `k_y`, and related comparisons.

### 2) Critical: Education index (`ppl_edu`) is used before it is assigned
- File refs:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:1184`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:1188`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2341`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2345`
- Problem:
  - `intp_occp_sim(..., ppl_edu)` is called before `ppl_edu` is set in those loops.
- Why this matters:
  - Wrong policy interpolation by education state can contaminate all reported moments.

### 3) Critical: CEV interpolation uses stale `ppl_edu`
- File refs:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:1289`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2439`
- Problem:
  - CEV interpolation passes `ppl_edu` without recomputing it for each `ppl_sim`.
- Why this matters:
  - Welfare comparisons by policy can be wrong.

### 4) High: Aggregate convergence check for matching term is malformed
- File ref:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2964`
- Problem:
  - `fabs(theta_ut_new - theta_ut)` is included without `> tol_agg`.
- Why this matters:
  - GE stopping criterion may be too strict/incorrect and can misreport convergence.

### 5) High (paper-code math consistency): `p(theta)` vs `q(theta)` mismatch in vacancy cost implementation
- Paper refs:
  - `NecessityEntrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.lyx:833`
  - `NecessityEntrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.lyx:786`
- Code refs:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:887`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2785`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2834`
- Problem:
  - Paper cost term is written with `q(theta)` (firm fill probability), while code updates
    `theta_ut` as `m(v/u)^(1-mu)` and divides cost by `theta_ut`.
- Why this matters:
  - This can change effective hiring/search cost and firm size decisions.

### 6) High (paper-code mapping): `i_w` label convention differs between paper and code
- Paper refs:
  - `NecessityEntrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.lyx:1373`
  - `NecessityEntrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.lyx:1382`
- Code refs:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:618`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:486`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:482`
- Problem:
  - Paper labels: `0=unemployed, 1=employed, 2=entrepreneur`; code comments/logic use
    `0=entrepreneur, 1=worker, 2=unemployed`.
- Why this matters:
  - High risk of interpretation bugs during maintenance and paper-code translation.

### 7) Medium (paper-code math consistency): entrepreneur profit uses average separation in code
- File ref:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:2834`
- Problem:
  - Profit uses `rho_aver` instead of education/state-specific separation in the cost term.
- Why this matters:
  - Can attenuate heterogeneity by education in entrepreneurship margins.

### 8) Medium: random seed reset each simulation period
- File ref:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:799`
- Problem:
  - `srand(time(0))` inside the period loop can reduce randomness quality.

### 9) Medium: hardcoded machine path blocks reproducibility
- File refs:
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:23`
  - `NecessityEntrepreneurs/calibration/cfv_red_final.cpp:3014`
- Problem:
  - Input/output locations are pinned to a local drive path.

### 10) Low: figure filename case mismatch risk
- Paper refs:
  - `NecessityEntrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.lyx:557`
  - `NecessityEntrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.lyx:596`
- Script refs:
  - `NecessityEntrepreneurs/figures/generate_enter_employed.py:89`
  - `NecessityEntrepreneurs/figures/generate_enter_unemployed.py:91`
- Problem:
  - Paper includes lowercase names; scripts write title-case filenames.

## Main Model-Risk Math Issues (Could materially alter results)
1. Entrepreneur output set to zero in simulation (Critical).
2. Education index mis-assignment before interpolation (Critical).
3. Vacancy/search cost denominator mismatch (`q(theta)` vs implemented object) (High).

## Suggested immediate coding order
1. Fix entrepreneur output formula in both steady-state and transition simulation blocks.
2. Fix `ppl_edu` assignment order and CEV interpolation indexing.
3. Fix convergence criterion in `check_agg()`.
4. Resolve and document `p(theta)`/`q(theta)` object mapping in cost term.
5. Standardize `i_w` state mapping in comments and documentation.
