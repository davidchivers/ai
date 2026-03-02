# Fix Checklist (Coding)

Status note (2026-02-23): Active project tracking has moved to projects/01_necessity_entrepreneurs/STATUS.md. Keep this file as supporting detail for coding fixes.
Status update (2026-02-24): Items marked "AI copy" are implemented in `calibration/ai_calibration/cfv_red_final.cpp` but not yet merged into canonical `calibration/cfv_red_final.cpp`.

## Critical
- [ ] Fix entrepreneur output formula in simulation blocks (`cfv_red_final.cpp:972`, `cfv_red_final.cpp:2189`).
- [ ] Set `ppl_edu` before any interpolation calls in reporting loops (`cfv_red_final.cpp:1184`, `cfv_red_final.cpp:2341`).
- [ ] Recompute `ppl_edu` per agent before CEV interpolation (`cfv_red_final.cpp:1289`, `cfv_red_final.cpp:2439`).

## High
- [x] Correct `check_agg()` theta criterion to use an explicit theta tolerance (`> k_tol_theta_agg`) [AI copy].
- [ ] Resolve `q(theta)` vs `theta_ut` denominator in vacancy/search cost (`cfv_red_final.cpp:2785`, `cfv_red_final.cpp:2834`).
- [ ] Standardize and document state coding (`i_w`) across paper and code.

## Medium
- [ ] Decide whether separation in profit cost is average or education-specific (`cfv_red_final.cpp:2834`).
- [ ] Move `srand(...)` out of the period loop (`cfv_red_final.cpp:799`).
- [x] Replace hardcoded path root with configurable runtime root (`CFV_WORKINGPATH`) [AI copy].

## Added for convergence robustness (2026-02-24)
- [x] Add startup checks for required `data/input/cfv/*` files [AI copy].
- [x] Guard `theta` updates against invalid `v_t/u_t` states [AI copy].
- [x] Guard `rho` updates when employed count is zero [AI copy].
- [x] Guard `tau_y1 = total_lower_out / earning_wkr` against near-zero denominator [AI copy].
- [x] Remove `static` aggregate iteration counter scope issue in `solve_model()` [AI copy].

## Low
- [ ] Unify figure filename case conventions between scripts and paper includes.

