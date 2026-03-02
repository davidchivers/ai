# AI Calibration Workspace

This folder contains an isolated calibration workflow for tasks 1 and 2:
- task 1: run baseline/UI experiments from a local runtime root
- task 2: patched solver diagnostics for robust convergence checks

## Folder layout

- `cfv_red_final.cpp`: patched calibration source
- `nr.h`: required header
- `runtime/data/input/cfv/`: place required input text files here
- `runtime/data/output/`: run outputs
- `setup_ai_calibration.ps1`: prepares runtime directories and copies input files
- `run_ai_calibration.ps1`: compile and run a selected scenario

## Required input files

Place these in `runtime/data/input/cfv/`:
- `policy_functions_v17_in.txt`
- `rnd_100k.txt`
- `x_shk_iid.txt`
- `input_pi_x_iid_1.txt`
- `input_pi_x.txt`

## One-time setup

```powershell
cd projects/01_necessity_entrepreneurs/calibration/ai_calibration
./setup_ai_calibration.ps1 -SourceInputDir "C:/path/to/folder/with/input/files"
```

## Run scenarios

```powershell
./run_ai_calibration.ps1 -Scenario baseline
./run_ai_calibration.ps1 -Scenario ui_005
./run_ai_calibration.ps1 -Scenario ui_000
```

Scenarios map to `CFV_UI_REPLACEMENT` values:
- `baseline` -> no override
- `ui_005` -> `0.05`
- `ui_000` -> `0.00`

## Ablation controls (single run)

`run_ai_calibration.ps1` supports runtime simplification toggles:
- `-SkipTransition` -> sets `CFV_SKIP_TRANSITION=1` (steady-state endpoints only)
- `-FixedTheta <value>` -> fixes matching update (`CFV_FIXED_THETA`)
- `-FixedRho <value>` -> fixes separation update (`CFV_FIXED_RHO`)
- `-FixedR <value>` -> fixes interest rate in GE loop (`CFV_FIXED_R`)
- `-FixedW <value>` -> fixes wage in GE loop (`CFV_FIXED_W`)
- `-UpdateStep1 <value>` -> overrides GE relaxation parameter in `(0,1)` (`CFV_UPDATE_STEP1`)
- `-MarketGapClamp <value>` -> clamps market-imbalance updates for `r/w` (`CFV_MARKET_GAP_CLAMP`, default `10.0`)
- `-AdaptiveGE` -> enables adaptive per-variable GE damping (`CFV_ADAPTIVE_GE`)
- optional adaptive tuning:
  - `-AdaptiveMinStep`, `-AdaptiveMaxStep`
  - `-AdaptiveTighten`, `-AdaptiveRelax`
  - `-AdaptiveImproveRatio`, `-AdaptiveWorsenRatio`
- `-MaxIterAgg <N>` -> caps steady-state GE loop (`CFV_MAX_ITER_AGG`)
- `-MaxTransitionIter <N>` + `-TransitionTol <tol>` -> caps transition loop
- `-RngSeed <int>` -> deterministic RNG (`CFV_RNG_SEED`)
- `-SingleCase <int>` -> run one canonical case id only (`CFV_SINGLE_CASE`, default `51`)
- `-TimeoutSeconds <N>` -> kills long runs from PowerShell wrapper

Example:

```powershell
./run_ai_calibration.ps1 -Scenario ui_000 -SkipTransition -MaxIterAgg 8 -RngSeed 12345
```

## Ablation matrix runner

Run a predefined matrix and auto-generate summary artifacts:

```powershell
./run_ablation_matrix.ps1 -Profile quick
```

Outputs:
- `runtime/data/output/ablation/run_matrix.csv`
- `runtime/data/output/ablation/ablation_summary.csv`
- `runtime/data/output/ablation/ablation_report.md`

## Patched diagnostics in this copy

- Uses `CFV_WORKINGPATH` instead of a fixed hardcoded root
- Validates required input files before running
- Adds theta tolerance to aggregate convergence check
- Removes static aggregate iteration counter scope
- Guards `theta` updates against invalid `v_t/u_t`
- Guards `rho` updates against zero employed count
- Guards `tau_y1 = total_lower_out / earning_wkr` against near-zero denominator

