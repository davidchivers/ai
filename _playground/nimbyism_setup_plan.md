# Plan: Set Up NIMBYism and the Housing Supply Project

## What We Found

Your Dropbox folder (`C:/Users/Dave_/Dropbox/Zac and David/`) has ~17GB of files including:
- **13 versions** of the paper (v1–v13 LyX files) — we only need v13
- **Code/** (13GB!) — mostly huge `.mat` intermediate data files; the actual MATLAB/Stata scripts are tiny
- **Data/** (1.4GB) — raw CSVs + Stata data files; the `.do` scripts are what matter
- **Literature/** (2.2MB) — 90+ reference PDFs, well-organized
- **Figures/** — 27 publication-ready images
- **Graphs/, Slides/, Submission/, Moments/** — small supporting files
- **Previous Drafts/** — 60+ old versions (not needed)
- **Referee reports** from Economic Journal

---

## Step 1: Create Branch + Folder

- Create git branch `nimbyism-housing-supply` from `main`
- Create folder `NimbyismAndTheHousingSupply/` (matches your project naming style)

## Step 2: Selective Copy from Dropbox (keep it lean)

### KEEP:
| What | Source | Size |
|------|--------|------|
| Latest paper (LyX) | `NIMBYism and the Housing Supply v13.lyx` → rename to `Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx` | 128KB |
| Published PDF | `NIMBYism and the Housing Supply (2025) JME.pdf` → rename similarly | 6MB |
| MATLAB scripts | All `.m` files from `Code/codes_abb/`, `Code/steadystate/` | ~500KB |
| Stata do-files | `.do` files from `Code/codes_abb/` and `Data/` | tiny |
| Fortran source | `.f90`/`.for` files from `Code/iacoviello_pavan_jme/` | tiny |
| Code documentation | `Readme.txt`, `Overview.lyx`, `FirstOrderConditions.lyx` | tiny |
| Figures | All 27 images from `Figures/` | ~5MB |
| Graphs | Working graphs + Stata scripts from `Graphs/` | ~1.5MB |
| Literature | All 90+ PDFs (already small) | ~2.2MB |
| Slides | Latest presentation LyX files only | ~100KB |
| Submission letters | Cover letters + disclosures from `Submission/` | tiny |
| Referee reports | `Economic Journal Referee Reports.docx` | tiny |
| Moments | Supplementary calibration materials | ~1.7MB |
| Root data files | `AgeByYear.xlsx`, `US Age Share Fine Grained.xlsx` | ~700KB |

### EXCLUDE:
- All v1–v12 LyX files and all old PDFs
- All `.mat` files (huge MATLAB intermediates — 6 files × 161MB each)
- All `.dta` files (Stata binary data — regenerable from `.do` scripts)
- `Previous Drafts/` folder (60+ old versions)
- `Data/Buildings/`, `Data/CPS age data/`, `Data/IPUMS*/`, `Data/Maps/` (raw data subfolders)
- Fortran output files (100+ `.txt` files)
- Backup files (`*.lyx~`, `*.emergency`, `pasted*.*`)
- `desktop.ini`, temp files

**Estimated final size: ~20MB** (down from 17GB)

## Step 3: Update .gitignore

Add rules for this project's file types:
```
*.mat
*.dta
*.lyx~
*.lyx#
*.emergency
*.asv
```

## Step 4: Create PROJECT_PLAN.md

Similar to your NecessityEntrepreneurs one, but reflecting that this paper is **published** (JME 2025). The workstreams are different:

## Step 5: Workstreams (after setup)

### WS1: Referee Report (Math + Typos)
Same approach as NecessityEntrepreneurs Day 1:
- Read the full LyX file (~4300 lines, much smaller than NE)
- Check all equations, derivations, proofs, notation consistency
- Flag typos, formatting issues
- Output: `Referee/REFEREE_REPORT.md` + `.tex` + `.pdf`
- **Can run as a background agent** (self-contained)

### WS2: Code Review
Four components to review:
1. **MATLAB estimation** (`Codes_ABB/`, 28 .m files) — quantile regression, MCMC, bootstraps
2. **MATLAB steady-state** (`SteadyState/`, 19 .m files) — OLG life-cycle model solver
3. **Fortran model** (`Iacoviello_Pavan_JME/`) — replication code (lighter review)
4. **Stata data processing** (9 .do files) — data pipeline
- Output: `Code/CODE_REVIEW.md`
- **Good candidate for Codex** (batch review of many files)

### WS3: LyX-to-TeX Conversion (low priority)
- The paper is published, so LyX is the authoritative source
- Could export to `.tex` for archival or if you want to edit without LyX
- Only do this if you want it

## Step 6: Git Commits (staged)

1. Folder structure + PROJECT_PLAN.md + .gitignore
2. Paper files (LyX + published PDF)
3. Code scripts (no data)
4. Figures + graphs
5. Literature + slides + submission + moments
6. Referee report (after generation)

---

## Questions for You

1. **Folder name**: `NimbyismAndTheHousingSupply` — OK? (CamelCase like `NecessityEntrepreneurs`)
2. **Author order**: The submission PDF says "Gross and Chivers" — is Isaac Gross the coauthor (your "Zac")?
3. **Data scripts**: Keep the Stata `.do` files from `Data/` even without the raw data they process? (Good for documentation of what you did)
4. **Literature PDFs**: Keep all 90+ in the repo? (Only 2.2MB total, but adds bulk to git)
