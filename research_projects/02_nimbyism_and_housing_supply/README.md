# 02_Nimbyism_and_Housing_Supply

**Paper**: Gross & Chivers (2025) "NIMBYism and the Housing Supply"
**Journal**: Journal of Monetary Economics (published 2025)
**Status**: Published - post-publication maintenance / extension base
**Last updated**: 2026-03-13
**Canonical status tracker**: `projects/02_nimbyism_and_housing_supply/STATUS.md`

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
  PROJECT_PLAN.md                                               <- original setup plan
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
