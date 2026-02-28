# Project Memory - NIMBYism and the Housing Supply

Most recent session first.

---

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
