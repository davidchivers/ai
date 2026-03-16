# Project Memory - NIMBYism and the Housing Supply

Most recent session first.

---

### Session: 2026-03-16 (extension completion cleanup)
- Clarified project intent after runtime validation: the interesting experiment is not the current
  steady-state no-politics closure. The main target is a demographic forecast with rational
  expectations over house prices along the transition path, under the simplification of no voting
  coalitions.
- Added the first transition-path RE scaffold files:
  `run_demographic_forecast_re_no_politics.m`,
  `build_demographic_path_from_age_state_csv.m`,
  `solve_transition_re_no_politics.m`, and
  `update_price_path_re_no_politics.m`.
- Verified that the transition scaffold runner executes in MATLAB, resolves the transition matrix
  correctly, and saves `transition_re_no_politics_scaffold.mat`. The remaining missing piece is the
  actual household transition solve and forward distribution update inside the placeholder solver.
- The scaffold now uses a real demographic path from `code/data/age state.csv` rather than a fake
  placeholder path. On the current mapping, the aggregate cohort-scale path over 2010-2018 is
  approximately `[1.000, 1.014, 1.031, 1.046, 1.063, 1.080, 1.097, 1.116, 1.133]`.
- Reclassified the current no-politics steady-state object as a side benchmark worth keeping for
  reference/debugging, but not the main quantitative exercise.
- Confirmed that `extensions/re_no_politics/` now contains both completed first-pass extensions:
  `solve_ss_no_politics.m` / `ClearMarkets_no_politics.m` / `run_re_no_politics_extension.m` and
  `solve_ss_coalition.m` / `compute_coalition_vote.m` / `ClearMarkets_coalition.m` /
  `run_political_coalition_extension.m`.
- Converted both `ClearMarkets_*` drivers from scripts into MATLAB functions so the runner wrappers
  can call them without relying on script execution in a function workspace.
- Updated the extension README plus project `STATUS.md` to reflect that the solver copies exist and
  the immediate next step is runtime validation rather than initial implementation.
- Runtime note: `TransitionMatrix.mat` for this project does exist on `D:\research_data\zac_and_david\Code\SteadyState\TransitionMatrix.mat`.
  The first Matlab failure came from path precedence: Matlab loaded another `TransitionMatrix.mat`
  lacking `initialdist`, so the extension now needs to resolve the steady-state file explicitly.
- Runtime verification result: `run_re_no_politics_extension` completed successfully once the loader
  was changed to resolve a usable transition bundle explicitly. On this machine, the working source
  file for `transitionmatrix`, `y_mid`, and `z_lifecycle` is
  `C:\Users\Dave_\Dropbox\Zac and David\Code\Codes_ABB\TransitionMatrix.mat`; `initialdist` is then
  sourced separately (or reconstructed if needed). The imported `D:\research_data\zac_and_david\Code\SteadyState\TransitionMatrix.mat`
  alone is not sufficient because it lacks `y_mid` and `z_lifecycle`.
- Runtime verification result: `run_political_coalition_extension` also completed successfully with
  the same transition-matrix loader. On the current 30-point price grid, the best coalition result
  was at price `1.8276` with weighted vote `-0.4875` and distance `0.2376`.
- Matlab became callable later in the session via the full executable path, and the no-politics
  extension runner was executed successfully after the transition-matrix loader fix.

### Session: 2026-03-13 (extension workspace, coalition direction, and portability pass)
- Created extension workspace at `extensions/re_no_politics/`.
- Added `implementation_plan.md` and `run_re_no_politics_extension.m` to separate the no-politics RE path from the published baseline code.
- Added `political_coalition_extension.md` and `compute_coalition_vote.m` for a first political-side extension that makes NIMBYism stronger via coalition-weighted voting rather than equal vote weights.
- Added `ensure_external_matlab_data_paths.m` in both `code/steadystate/` and
  `code/codes_abb/`, and updated the main MATLAB entry files to call the helper before loading
  external `.mat` assets.
- Updated `code/data/merge data.do` to try `D:\research_data\zac_and_david\Data` first and
  then fall back to `C:\Users\Dave_\Dropbox\Zac and David\Data`.
- Practical next step if coding continues: validate the extension entry points in MATLAB and decide
  whether the baseline `d_a_price` rent leak should be fixed upstream or left as an extension-only correction.

### Session: 2026-02-23 (single canonical status tracker)
- Added canonical tracker: `projects/02_nimbyism_and_housing_supply/STATUS.md`
- Set rule that "where are we" and to-do updates should be made in `STATUS.md` first.

### Session: 2026-02-22 (workflow note)
- Checked for WSL path artifacts in this project (`/mnt/c`, bash shebangs, Linux-only path assumptions): none found.
- Preferred shell for this project is PowerShell/Windows because core tooling is MATLAB + Stata + LyX on Windows paths.
- If doing PDF-heavy extraction/search work, consider running those specific tasks in WSL tools, while keeping core project runs in PowerShell.

### Session: 2026-02-19 (repo reorganisation)
- Project moved from `PaperProjects/02_nimbyism_and_housing_supply/` to `projects/02_nimbyism_and_housing_supply/`
- `README.md` and `memory.md` created as part of workspace standard
- No changes to paper content

### Session: 2026-02 (initial setup — nimbyism-housing-supply branch)
- Project imported from Dropbox (selective copy; large data/mat files excluded)
- MATLAB scripts, Stata do-files, figures, literature, slides, submission files present
- LyX source and published PDF present
- Setup plan documented in `PROJECT_PLAN.md` (now archived to `_playground/nimbyism_setup_plan.md`)

---

## Key files

| Role | Path |
|---|---|
| Paper source (LyX) | `projects/02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx` |
| Published PDF | `projects/02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.pdf` |
| MATLAB steady-state | `projects/02_nimbyism_and_housing_supply/code/steadystate/SolveSS.m` |
| Stata data pipeline | `projects/02_nimbyism_and_housing_supply/code/data/merge data.do` |
| Upstream fix log | `projects/02_nimbyism_and_housing_supply/UPSTREAM_FIX_LOG.md` |
| Referee reports | `projects/02_nimbyism_and_housing_supply/referee/Economic Journal Referee Reports.docx` |

## Upstream relationship

This project is upstream of `03_Fertility_and_Housing_Supply`.
Any fix found here that affects the model structure should be:
1. Applied here
2. Logged in `UPSTREAM_FIX_LOG.md`
3. Evaluated for porting to project 03 via `03/.../UPSTREAM_SYNC_LOG.md`

## What is excluded (large files not in repo)

- All `.mat` files (MATLAB intermediates, ~6 × 161MB each)
- All `.dta` files (Stata binary data — regenerable from `.do` scripts)
- Previous draft versions (v1–v12 of the LyX file)
- Raw data subfolders (Buildings/, CPS age data/, IPUMS*, Maps/)

## Key conventions

- LyX is the authoritative paper format.
- MATLAB code in `Codes_ABB/` follows Arellano-Blundell-Bond notation.
- Do NOT commit `.mat` or `.dta` files (already in `.gitignore`).
- Shell preference for this project: PowerShell first; use WSL selectively for PDF-heavy utilities.
