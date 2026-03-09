# AI annotation of the current calibration code

Date: 2026-03-06

Purpose:
- This note explains, in plain English, the code path that generated the current Necessity Entrepreneurship calibration results.
- It is written for coauthor review, not for replication-package release.
- The emphasis is on transparency: what file is being run, what was changed, what the current diagnostics do, and what still looks fragile.

Provenance note:
- The active source for current runs is:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`
- The active wrapper is:
  - `calibration/ai_calibration/run_ai_calibration.ps1`
- The canonical source was edited in place over several sessions. Because of that, this note can verify the **current** logic and the changes documented in project notes, but it is not a byte-for-byte redline against the untouched Dropbox original.

## Files that matter

Main model source:
- `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`
- This is the C++ file that actually computes the equilibria used in the current notes and March 2026 logs.

Execution wrapper:
- `calibration/ai_calibration/run_ai_calibration.ps1`
- This script compiles the C++ file, injects runtime controls through environment variables, launches the executable, and writes metadata into each log.

Runtime logs:
- `calibration/ai_calibration/runtime/data/output/case_1/*.log`
- These logs are the main audit trail for what was actually run.

Current headline logs for the zero-UI discussion:
- Endogenous tax, corrected case 101, `UI=0.00`:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_endog101_ui000_m40_uioverridefix_20260305_20260305_145727.log`
- Fixed baseline tax, homotopy to `UI=0.00`:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_fixedtax113_ui000_m40_homotopyfix_20260306_091442.log`

## How the current code path works

Step 1: PowerShell wrapper sets the run configuration
- `run_ai_calibration.ps1` selects the source file, compiles it if needed, and sets environment variables such as:
  - `CFV_UI_REPLACEMENT`
  - `CFV_SINGLE_CASE`
  - `CFV_MAX_ITER_AGG`
  - `CFV_RNG_SEED`
  - vacancy controls (`CFV_VACANCY_MODE`, `CFV_VACANCY_FLOOR`, `CFV_VACANCY_SCALE`)
- It also records those settings in the top of each log under `[ABLT] ...`.

Step 2: The C++ source reads those runtime overrides
- Early in `main_2025_v1_case113.cpp`, the code parses the `CFV_*` variables and stores them in internal override objects.
- In practice, this is what makes one-case runs, deterministic seeds, UI overrides, and vacancy experiments possible without hand-editing the C++ for every run.

Step 3: `assign_value()` loads the case-specific parameter block
- `assign_value()` is where case 101, case 102, case 103, case 113, and other experiments are defined.
- This is the part that decides what `lowerincome_b`, `bar_m`, `mu`, `kappa`, fixed-tax flags, and related settings are active for a run.

Step 4: `solve_model()` runs the aggregate fixed-point loop
- The model repeatedly:
  - solves policy functions,
  - calls `simulation()`,
  - updates aggregates (`r`, `w`, `theta`, `tau_y`),
  - checks convergence with `check_agg()`.

Step 5: `simulation()` creates the moments used in the paper tables
- This function produces:
  - entrepreneurship shares,
  - labor demand and supply,
  - education splits,
  - tax revenue and transfer spending,
  - the implied update to `theta`.
- Most of the diagnostics used in current debugging are also printed from here.

Step 6: case 113 has a special fixed-tax homotopy mode
- When the executable is run with only case `113`, the code first solves baseline case `101` to get the baseline tax rate.
- It then walks the UI benefit down along a homotopy path while keeping that baseline tax fixed.
- This is the path used for the current fixed-tax placebo/decomposition runs.

## Changes that are visible in the current code

Runtime-control plumbing:
- The current source now reads `CFV_WORKINGPATH`, `CFV_UI_REPLACEMENT`, `CFV_MAX_ITER_AGG`, `CFV_SINGLE_CASE`, `CFV_RNG_SEED`, and vacancy controls.
- This is a major practical change because it makes the runs scriptable and reproducible from PowerShell instead of requiring direct C++ edits.

Numerical guardrails:
- The current code includes guards for:
  - invalid probabilities,
  - near-zero denominators,
  - invalid `r/w` updates,
  - negative simulated entrepreneur `n` and `k`.
- These are defensive numerical changes. They do not redefine the economics directly, but they can materially affect whether the fixed-point iteration blows up or settles.

New diagnostics:
- The code prints:
  - `[THETA_DIAG] ...`
  - policy-tail diagnostics for `opt_n_0` and `opt_k_0`
  - entrepreneur realization diagnostics (`entr_count`, `entr_share`, education split, mean/max `n` and `k`)
  - asset out-of-grid counters
- These diagnostics are essential for understanding why the old solver failed and why the new runs converge.

Mapping and interpolation fixes:
- The current source contains an explicit `education_index_from_person(...)` helper in `simulation()`.
- It also uses probability-weighted occupation counting in places that previously relied on harder occupation classification.
- The interpolation functions were hardened so they clamp query points to grid bounds and use a consistent indexing order.
- This looks like the most important technical reason the model stopped producing explosive fake labor-demand states.

Fixed-tax homotopy logic:
- The current special case-113 path now:
  - solves the baseline first,
  - stores the baseline tax,
  - then runs a UI homotopy toward a target `lowerincome_b`.
- The March 6 patch also ensures the baseline warmup is not contaminated by a zero-UI override and that non-default targets can be written to dedicated output folders.

## What appears legitimate in the current results

The current zero-UI convergence does not rely on a single log artifact:
- The corrected case-101 endogenous-tax run converges at `UI=0.00`.
- The fixed-tax case-113 homotopy run also converges at `UI=0.00`.
- That means the model now reaches a zero-UI steady state under two different closure rules.

The current logs are substantially more auditable than the older ones:
- The wrapper records source file, seed, case id, UI override, and iteration cap.
- The C++ log shows the simulated moments and the aggregate update terms at each iteration.
- This makes it possible to tell when a run is real and when a label is misleading.

The March 4 `ui000_101A` archive should not be used as evidence:
- That log says `ui_override=0.00`, but its terminal moments are baseline case-101 moments.
- So the label is not trustworthy as a zero-UI experiment.
- The later March 5 `uioverridefix` logs are the first credible case-101 no-UI evidence in the current archive.

## What still looks problematic or easy to misread

`101A` is not well defined in the codebase:
- I do not see a separate case block or parameter block called `101A` in the current C++.
- In practice, `101A` appears in run tags and archived log names, not as a distinct coded case.
- That means coauthors should not assume `101A` is a separate calibration without an explicit parameter diff.

The code still prints confusing labels in some runs:
- For override runs, the line `Baseline equilibrium tau_y = ...` can appear even when the run is not a literal baseline.
- That line should be read carefully; it is not always a clean semantic label.

The fixed-tax logs mix warmup and target-path output in one file:
- A case-113 log contains:
  - the baseline warmup,
  - intermediate homotopy steps,
  - the final target step.
- This is workable, but it is easy for a reader to mistake an intermediate block for the final result.

Vacancy mechanics remain a live modeling issue:
- The current runs still use the vacancy-floor structure (`v_floor=1`, `v_mode=2`) unless explicitly changed.
- This appears to keep `theta` relatively insensitive even when UI changes a lot.
- So convergence is now numerically credible, but the economic interpretation of the `theta` response still needs separate scrutiny.

Wrapper/runtime behavior is still slightly awkward:
- Some runs finish with `exit_code=999` because the process exit code is not always available through the current wrapper path.
- The logs are still usable, but this is not a perfectly clean execution environment.

## Practical reading guide for coauthors

If the goal is to verify the current zero-UI result quickly, read in this order:
- `notes/04_empirical_notes.md`
- `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_endog101_ui000_m40_uioverridefix_20260305_20260305_145727.log`
- `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_fixedtax113_ui000_m40_homotopyfix_20260306_091442.log`
- `calibration/ai_calibration/run_ai_calibration.ps1`
- `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`

If the goal is to verify what was changed technically, focus on:
- environment-variable parsing in the C++ main file,
- interpolation functions,
- `simulation()`,
- the case-113 homotopy block,
- the PowerShell runner metadata and launch logic.

## Bottom line

The current code path is no longer a black box.
- We can identify the exact source file used.
- We can identify the wrapper that set the run parameters.
- We can identify the logs that generated the current claims.

The most important credibility point is this:
- the zero-UI result now converges in a corrected case-101 run and also in a fixed-tax placebo run,
- but some older archived logs are mislabeled or semantically misleading,
- so only the corrected March 5-6 logs should be used as evidence in the current draft/update materials.
