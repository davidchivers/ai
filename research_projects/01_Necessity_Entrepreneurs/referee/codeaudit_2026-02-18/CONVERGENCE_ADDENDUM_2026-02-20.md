# Convergence Addendum (2026-02-20)

## Status Update (2026-02-24)
- Toolchain is now available for reruns in the AI calibration workspace:
  - `C:/msys64/ucrt64/bin/g++.exe` (MSYS2 UCRT64 GCC).
- Diagnostics/guardrail patches are implemented in:
  - `projects/01_necessity_entrepreneurs/calibration/ai_calibration/cfv_red_final.cpp`
- Execution is still blocked by missing solver input files under `data/input/cfv/`:
  - `policy_functions_v17_in.txt`, `rnd_100k.txt`, `x_shk_iid.txt`,
    `input_pi_x_iid_1.txt`, `input_pi_x.txt`.
- Therefore the requested benchmark-vs-failing convergence trace pair has not yet been produced in this environment.

## Why this matters now
The model appears not to converge in very-low-UI runs (especially UI=0). This can invalidate comparative statics if not diagnosed before new calibration runs.

## Most likely channels
1. GE outer-loop overshooting when UI is near zero.
2. Feasibility failures (negative/near-zero consumption) causing NaN/Inf in value updates.
3. Indexing/interpolation fragility (education index order and CEV index usage from prior audit findings).
4. Malformed stopping rule in aggregate convergence check (previously flagged).
5. Sensitivity from matching-object mapping (`p(theta)` vs `q(theta)`) in hiring-cost terms.

## What we need from code owner (minimum package)
1. Exact source file(s) and commit/date used for benchmark and failing runs.
2. One convergent log (UI=0.4) and one non-convergent log (UI=0.0), with full iteration trace.
3. Full parameter block for both runs: UI `b`, taxes/transfers, matching params, damping, tolerances, max iterations, grid settings.
4. Failure signature label: inner VFI fail, policy oscillation, GE divergence, NaN/Inf, or infeasible states.
5. Iteration-level series for key aggregates (`w`, `tau`, `theta`, entrepreneurship, firm size).

## Debug protocol requested
1. Reproduce benchmark and failing runs with same seed and logging format.
2. Validate feasibility guards before maximization (`c>0`, finite utility, borrowing constraints).
3. Separate inner-loop and outer-loop convergence checks to identify first failing block.
4. Add damping/line-search in outer updates if missing.
5. Run UI homotopy path: 0.4 -> 0.3 -> 0.2 -> 0.1 -> 0.05 -> 0.0 with warm starts.
6. Re-test after index/stopping-rule fixes and compare convergence traces.

## Ready-to-recalibrate criteria
- Benchmark and UI=0.0 both converge under identical stopping logic.
- No NaN/Inf or feasibility violations.
- Stable traces under at least two seeds.
- Key moments reproducible across reruns.
