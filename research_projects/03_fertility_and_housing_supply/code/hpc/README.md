# HPC prep

This folder contains the minimum cluster handoff layer for the current annual NIMBY steady-state workflow.

## Files

- `prepare_annual_nimby_bundle.ps1`
  - stages a portable bundle with:
    - this project's `code/`
    - `README.md`, `STATUS.md`, `memory.md`
    - annual NIMBY benchmark outputs and transition matrices from `notes/build/`
    - upstream `../02_nimbyism_and_housing_supply/code/steadystate/`
    - upstream `../02_nimbyism_and_housing_supply/code/codes_abb/`
    - bundled `nl_zbl.mat` when found locally
    - bundled upstream small `TransitionMatrix.mat` when found locally
- `run_annual_nimby_workflow.sh`
  - Linux batch runner for the current annual NIMBY workflow
  - supports resume via `START_AT_STEP` and `END_AT_STEP`
- `annual_nimby_workflow.slurm`
  - basic SLURM wrapper around `run_annual_nimby_workflow.sh`
- `run_annual_nimby_low_entry_vote_followup.sh`
  - Linux batch runner for the targeted low-entry annual follow-up
  - runs `run_nimby_annual_low_entry_vote_followup('full')` by default
- `annual_nimby_low_entry_vote_followup.slurm`
  - basic SLURM wrapper around `run_annual_nimby_low_entry_vote_followup.sh`
- `run_annual_nimby_low_entry_broad_screen.sh`
  - Linux batch runner for the broader low-entry annual screen
  - runs `run_nimby_annual_low_entry_broad_screen('full')` by default
- `annual_nimby_low_entry_broad_screen.slurm`
  - basic SLURM wrapper around `run_annual_nimby_low_entry_broad_screen.sh`
- `run_annual_nimby_owner_grid_compromise_screen.sh`
  - Linux batch runner for the owner-grid compromise screen
  - runs `run_nimby_annual_owner_grid_compromise_screen('full')` by default
- `annual_nimby_owner_grid_compromise_screen.slurm`
  - basic SLURM wrapper around `run_annual_nimby_owner_grid_compromise_screen.sh`
- `run_fertility_benchmark_refresh.sh`
  - Linux batch runner for the long 5-year benchmark refresh
  - runs `run_ge_fertility_main` and `write_fertility_vs_nimby_benchmark_main`
  - then tries the benchmark plot/PDF refresh when `python` / `pandoc` are available
- `fertility_benchmark_refresh.slurm`
  - basic SLURM wrapper around `run_fertility_benchmark_refresh.sh`
- `run_fertility_annual_broad_calibration_screen.sh`
  - Linux batch runner for the annual fertility-first broad-band calibration screen
  - runs `run_fertility_annual_broad_calibration_screen('fast')` by default
- `fertility_annual_broad_calibration_screen.slurm`
  - basic SLURM wrapper around `run_fertility_annual_broad_calibration_screen.sh`
- `run_fertility_annual_timing_stock_screen.sh`
  - Linux batch runner for the targeted annual timing-plus-stock screen
  - runs `run_fertility_annual_timing_stock_screen('fast')` by default
- `fertility_annual_timing_stock_screen.slurm`
  - basic SLURM wrapper around `run_fertility_annual_timing_stock_screen.sh`
- `run_fertility_annual_timing_stock_bridge_screen.sh`
  - Linux batch runner for the narrower frontier-bridge follow-up after the completed timing-stock survivor batch
  - runs `run_fertility_annual_timing_stock_bridge_screen('fast')` by default
- `fertility_annual_timing_stock_bridge_screen.slurm`
  - basic SLURM wrapper around `run_fertility_annual_timing_stock_bridge_screen.sh`
- `run_fertility_annual_anticipated_price_drift_screen.sh`
  - Linux batch runner for the annual anticipated-price-drift RE-style confirmation screen
  - runs `run_fertility_annual_anticipated_price_drift_screen('confirm')` by default
- `fertility_annual_anticipated_price_drift_screen.slurm`
  - basic SLURM wrapper around `run_fertility_annual_anticipated_price_drift_screen.sh`

## Prepare the bundle on this machine

```powershell
powershell -ExecutionPolicy Bypass -File code\hpc\prepare_annual_nimby_bundle.ps1
```

The default output root is:

```text
_playground/backups/YYYY-MM-DD/03_fertility_and_housing_supply_hpc/
```

The script also writes `latest_bundle.txt` in that folder so the newest staged path is easy to find tomorrow.

## Upload and run on the cluster

1. Copy the generated `.zip` bundle to the cluster.
2. Unzip it so the extracted folder contains sibling directories:
   - `03_fertility_and_housing_supply/`
   - `02_nimbyism_and_housing_supply/`
   - `external_assets/` if bundled
3. From `03_fertility_and_housing_supply/code/hpc/`, either:

```bash
bash run_annual_nimby_workflow.sh
```

or:

```bash
sbatch annual_nimby_workflow.slurm
```

## Resume the current heavy step only

If the local machine has already finished steps `1-3`, restart only the live heavy step:

```bash
export START_AT_STEP=4
export END_AT_STEP=4
bash run_annual_nimby_workflow.sh
```

The step mapping is:

1. `run_nimby_annual_recalibration_stage2('full')`
2. `compare_nimby_local_age_block_periodization_main('benchmark')`
3. `run_nimby_annual_housing_access_screen('fast')`
4. `run_nimby_annual_housing_access_screen('full')`

## Hamilton MATLAB note

The official Durham Hamilton MATLAB guidance notes that MATLAB jobs can be
unexpectedly slow under some OpenMP placement settings. If a Hamilton MATLAB
job looks unusually sluggish, add the following lines immediately after
loading the MATLAB module in the job script:

```bash
module purge
module load matlab
unset OMP_PLACES
unset OMP_PROC_BIND
```

Reference:
`https://www.durham.ac.uk/research/institutes-and-centres/advanced-research-computing/hamilton-supercomputer/software/applications/matlab/`

## Run the targeted low-entry vote-side follow-up

If the broad annual screen is already in flight locally and you want the
next tighter cluster follow-up instead, submit:

```bash
sbatch --nice=10000 annual_nimby_low_entry_vote_followup.slurm
```

That workflow fixes:

- uniform cohorts
- hold-5y `ka`
- benchmark `CC`
- low-entry owner grid `housingmax = 10`

and then re-screens only:

- `theta_r`
- `rent_markup`

## Run the broader low-entry annual screen

If the narrow low-entry vote-side rerun has already finished and you want
the next broader annual screen that keeps `housingmax = 10` in play while
reopening `cohort weights`, `ka`, `theta_r`, and `rent_markup`, submit:

```bash
sbatch --nice=10000 annual_nimby_low_entry_broad_screen.slurm
```

## Run the owner-grid compromise screen

If the broad low-entry screen has already finished and you want the next
branch that reopens `housingmax` while keeping uniform cohorts and
benchmark `CC` fixed, submit:

```bash
sbatch --nice=10000 annual_nimby_owner_grid_compromise_screen.slurm
```

## Run the long 5-year benchmark refresh

If the solver path has changed and the public 5-year benchmark note needs a
clean rebuild on the cluster, submit:

```bash
sbatch --nice=10000 fertility_benchmark_refresh.slurm
```

That workflow rebuilds:

- `notes/build/fertility_run_ge_report.md`
- `notes/build/fertility_vs_nimby_benchmark_report.md`
- `notes/build/fertility_vs_nimby_benchmark_summary.csv`
- `notes/build/fertility_vs_nimby_common_price_grid.csv`

and then attempts the benchmark figure/PDF refresh when the staged cluster
environment has the needed Python / Pandoc tools.

## Run the annual fertility broad-band calibration screen

If the annual target policy has shifted from exact matching to wide
screening bands, submit:

```bash
sbatch --nice=10000 --export=ALL,MODE=fast fertility_annual_broad_calibration_screen.slurm
```

That workflow:

- scores annual fertility candidates on broad timing / childlessness bands
- keeps TFR as validation-only
- requires the price comparative statics to move in the right direction
- treats this as an economic-model screen rather than a simulation-style fit

## Run the targeted annual timing-plus-stock screen

If the broad annual survivor box has already shown that fixed-timing
searches are too flat, submit:

```bash
sbatch --nice=10000 --export=ALL,MODE=fast fertility_annual_timing_stock_screen.slurm
```

That workflow:

- treats the cancelled broad box as a survivor diagnosis, not a benchmark
- varies first-birth timing profiles explicitly
- combines those timing profiles with stronger stock-fertility deterrence bundles
- keeps the annual targets as broad screening bands plus sign checks

## Run the timing-stock frontier bridge follow-up

If the completed timing-stock batch has already exposed a clean timing-vs-childlessness frontier,
submit:

```bash
sbatch --nice=10000 --export=ALL,MODE=fast fertility_annual_timing_stock_bridge_screen.slurm
```

That workflow:

- treats the completed timing-stock batch as a `survivor`, not a final calibration
- drops the dominated mild-deterrence branch from the `fast` box
- keeps only the more front-loaded timing profiles that moved the frontier materially
- searches finer `phi0` steps along the low-deterrence survivor region

## Run the annual anticipated-price-drift RE-style confirmation

If the current question is whether the live anticipated-price-drift branch
survives beyond the local smoke on a cleaner annual grid, submit:

```bash
sbatch --nice=10000 --export=ALL,MODE=confirm fertility_annual_anticipated_price_drift_screen.slurm
```

That workflow:

- treats the existing drift block as a bounded RE-style expectation wedge, not a full transition RE solve
- keeps the live fertility anchor fixed
- tests whether loading continuation values from higher future prices still materially improves vote on a larger grid
- writes the main interpretation note to `notes/build/fertility_annual_anticipated_price_drift_screen.md`
