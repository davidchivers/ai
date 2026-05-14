# 02_Nimbyism_and_Housing_Supply

**Paper**: Gross & Chivers (2025) "NIMBYism and the Housing Supply"
**Journal**: Journal of Monetary Economics (published 2025)
**Status**: Published - post-publication maintenance / extension base
**Last updated**: 2026-04-11
**Canonical status tracker**: `research_projects/02_nimbyism_and_housing_supply/STATUS.md`

---

## What this project is

OLG model of housing market dynamics in which homeowners vote against new housing supply
(NIMBY behaviour) to protect the value of their existing wealth. Calibrated to US data.
Published in JME 2025.

This project also serves as the **upstream codebase** for `03_Fertility_and_Housing_Supply`.

## Current status

Authoritative live status is maintained in `STATUS.md`. This section is a brief snapshot.

- [x] Paper published (JME 2025)
- [x] Code migrated to repo (MATLAB steady-state + Stata data pipeline)
- [x] External path portability pass added for MATLAB and Stata entry points (`D:` first,
  Dropbox fallback)
- [x] Extension workspace scaffold added under `extensions/re_no_politics/`
- [x] Simplified RE policy-bridge branch now isolated for the NIMBY extension
- [x] Anchored-policy follow-up now clarifies the reduced-form interpretation:
  the stable branch is closer to a nearly frozen benchmark-price policy map than to a generic
  clipped-current-price rule
- [x] Reduced-form-first NIMBY RE branch now in place:
  a smooth aggregate operator fit on the stable fixed-price benchmark solves cleanly at one-step
  and stays stable through the full forward horizon in the bounded `k`-step ladder
- [x] Policy-bridge blend rung now in place:
  the full-horizon blend frontier is sharp around `alpha = 0.015 -> 0.02`, but the matched-budget
  `k`-ladder shows that shorter horizons can still absorb some current-price feedback before the
  by-period instability returns
- [x] Resumable coarse `alpha` frontier now in place:
  on the grid `{0.00, 0.01, 0.015, 0.02, 0.03, 0.05, 0.10, 0.20, 0.50, 1.00}`, the largest stable
  tested `alpha` stays at `1.00` through `k = 3` and drops to `0.05` by `k = 4` and `k = 5`
- [x] Compiled sidecar for the no-politics branch now covers the runtime core plus the main
  workflow-used solver payloads (`selection_diagnostics` and optional
  `density_by_period_age`) on bounded validation packs
- [x] Compiled frontier runner now exists for the blended policy-bridge branch:
  it reuses the retry-aware warm-start ladder logic from the MATLAB frontier workflow, and the
  current like-for-like check matches the completed `alpha = 0.20`, `k = 1..3` retry-aware rows
- [x] Compiled high-horizon continuation workflow now exists:
  the sidecar matches the local `k = 4` and `k = 5` retry-aware edge checks, the current compiled
  full-horizon bracket is stable at `0.18083671212196353` and unstable at `0.18083722352981568`,
  and the bounded 12-hour away workflow under
  `extensions/re_no_politics/compiled_sidecar/` for compact full-horizon bracket refinement
  has already reached its target bracket width (about `5.11e-07`)
- [x] Compiled warm-start diagnostic now exists for the old `alpha = 0.14`, `k = 4` restart check:
  the sidecar case-sweep runner matches the MATLAB warm-start summary and path tables to
  floating-point noise
- [x] Compiled restart-check coverage now also includes the old `alpha = 0.15` and `0.20`,
  `k = 4` packets:
  the sidecar case-sweep runner matches the saved MATLAB restart-check summaries on both sides
  of that older local branch
- [ ] Referee folder: `Economic Journal Referee Reports.docx` present but no formal response
  document yet
- [ ] Code review of MATLAB code (`SteadyState/`, `Codes_ABB/`) not yet started
- [ ] Any fixes found here should be logged in `UPSTREAM_FIX_LOG.md` for porting to project 03

## Next 3 concrete tasks

1. **Validate portability helpers** on the external MATLAB/Stata data roots.
2. **Code review** `code/steadystate/` and `code/codes_abb/` against published paper objects.
3. **Log and port real upstream fixes** through `UPSTREAM_FIX_LOG.md` and project 03.

---

## Folder structure

```
02_nimbyism_and_housing_supply/
  Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx   <- paper source
  Gross and Chivers (2025) NIMBYism and the Housing Supply.pdf   <- published PDF
  AgeByYear.xlsx / US Age Share Fine Grained.xlsx               <- root data files
  old/project_plan_2026-02-18.md                               <- archived initial setup plan
  UPSTREAM_FIX_LOG.md                                           <- fixes to port to project 03
  code/
    Codes_ABB/    <- MATLAB: estimation (quantile regression, MCMC, bootstraps)
    SteadyState/  <- MATLAB: OLG steady-state solver
    data/         <- Stata do-files for data pipeline
    Iacoviello_Pavan_JME/  <- reference model (Fortran)
  extensions/     <- post-publication extension workspaces
  figures/        <- 27 publication figures
  graphs/         <- working graphs + Stata scripts
  literature/     <- 90+ reference PDFs
  moments/        <- calibration target documentation
  referee/
    Economic Journal Referee Reports.docx   <- journal referee reports
  slides/         <- LyX presentation files
  submission/     <- cover letters, disclosures
```
