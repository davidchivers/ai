# Dynare Reduced-Path Scaffold

This folder now contains both:

- the original low-friction scaffold setup, and
- a real reduced-path Dynare branch for the original 5-year NIMBY RE transition problem

What the scaffold does:

- exports the current incumbent full-horizon seed path and diagnostics into small Dynare-friendly files
- builds a reduced-path basis representation for the `k = 14` price path
- writes a first Dynare `.mod` scaffold that maps coefficient variables into the 14-period log-price path

What the scaffold still does not do:

- it is **not** a full Dynare translation of the political Bellman transition model
- the generated `.mod` file contains placeholder residual equations that still need to be replaced with the chosen reduced-form equilibrium block

The point of the scaffold is to remove setup friction while local and Hamilton runs continue in the background.

## Real reduced-path Dynare branch

The real branch is built around the files:

- `export_original_5yr_dynare_reduced_system.m`
- `build_original_5yr_dynare_reduced_system_mod.m`
- `run_original_5yr_transition_dynare_reduced_path.m`
- `run_original_5yr_transition_dynare_reduced_path.ps1`

That branch does not try to translate the full Bellman transition system into Dynare directly.
Instead, for the current incumbent `k = 14` path it:

1. evaluates the full Bellman transition residuals in MATLAB
2. fixes an active political residual set
3. builds a low-dimensional basis for the 14-period log price path
4. estimates the finite-difference Jacobian of the active residuals with respect to those basis coefficients
5. exports the regularized normal-equation system to Dynare
6. lets Dynare solve for the reduced coefficient update
7. maps that coefficient update back to a full candidate price path
8. re-evaluates the candidate against the full Bellman transition object in MATLAB

So Dynare is being used here as a reduced-system solver, not as a full structural translation of the original NIMBY RE model.

## Main entry point

Run this from MATLAB:

```matlab
run_original_5yr_dynare_scaffold_setup
```

That writes generated files into:

```text
original_5yr_political_re/dynare_reduced_path/generated/
```

## Real branch entry point

Run this from PowerShell:

```powershell
.\run_original_5yr_transition_dynare_reduced_path.ps1 -MatlabExe matlab -RunTag dynare_smoke
```

or from MATLAB:

```matlab
[summary, results] = run_original_5yr_transition_dynare_reduced_path;
```

That writes run-specific outputs into:

```text
original_5yr_political_re/truth/dynare_reduced_path/<run_tag>/
```

## Generated artifacts

- `nimby_dynare_scaffold_input.mat`
  Small MATLAB struct with horizon, demographic path summary, seed path, vote path, active periods, and basis matrix.
- `nimby_dynare_scaffold_manifest.json`
  Human-readable metadata summary.
- `nimby_dynare_seed_price_path.csv`
  The current incumbent full-horizon price path.
- `nimby_dynare_vote_path.csv`
  The incumbent vote path used to define active periods.
- `nimby_dynare_basis.csv`
  Reduced-path basis matrix.
- `nimby_reduced_path_scaffold.mod`
  Dynare template for a reduced-coefficient perfect-foresight formulation.

## Real branch artifacts

For each real branch run, the runner writes:

- `<run_tag>_summary.csv`
- `<run_tag>_results.mat`
- `<run_tag>_final_price_path.csv`
- `<run_tag>_final_vote_path.csv`
- `iter_XX/nimby_dynare_reduced_system_input.mat`
- `iter_XX/nimby_reduced_path_system.mod`
- `iter_XX/dynare_delta_coeff.csv`

The per-iteration system export contains:

- active residual vector
- reduced basis
- finite-difference reduced Jacobian
- regularized normal matrix
- normal right-hand side

## Intended next step

The intended next formulation is:

1. parameterize the 14-period log-price path with a small number of coefficients
2. express the path in Dynare through those coefficients and identities
3. replace the placeholder `votegap_t` equations with a reduced equilibrium block
4. use Dynare's deterministic perfect-foresight machinery as an alternative global path solver

For the current real branch, the immediate next step is narrower:

1. test whether the reduced-system Dynare solve can produce a direction that beats the current incumbent
2. if it can, use that improved seed for the next Hamilton reduced-Jacobian packet
3. only after that decide whether a richer full Dynare formulation is worth the translation cost

## Current incumbent wired into the scaffold

By default the scaffold uses:

- seed path:
  `original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv`
- vote path:
  `original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_vote_path.csv`
- summary:
  `original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_summary.csv`

Those can be changed in `run_original_5yr_dynare_scaffold_setup.m`.
