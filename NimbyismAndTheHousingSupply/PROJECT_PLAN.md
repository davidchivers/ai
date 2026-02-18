# NIMBYism and the Housing Supply — Project Plan

**Paper**: Gross and Chivers (2025) "NIMBYism and the Housing Supply"
**Published in**: Journal of Monetary Economics (JME), 2025
**Authors**: Isaac Gross (Monash University) & David Chivers (Durham University)
**Status**: Published. This repo holds the archival version + code review + supplementary analysis.
**Last updated**: 2026-02-18

---

## Paper Summary

We develop a political economy model of the housing market in which the supply of new homes is shaped by a democratic vote among households. Voter support for additional housing is determined by the effect on households' expected discounted utility via changes in house prices. Homeowners typically oppose new housing (the NIMBY effect), while renters and younger/lower-income households support more supply. Calibrating to US demographic data, the political economy mechanism explains a 15% increase in house prices since 1950. A temporary baby boom gives that generation higher homeownership and wealth at the expense of subsequent generations.

---

## Folder Structure

- `Gross and Chivers (2025)...lyx/pdf` — Main paper (LyX source + published JME PDF)
- `Code/` — All computational scripts (no large data files)
  - `Codes_ABB/` — MATLAB estimation code (quantile regression, MCMC, bootstraps) + Stata do-files
  - `SteadyState/` — MATLAB OLG steady-state solver + impulse responses
  - `Iacoviello_Pavan_JME/` — Reference replication code (Fortran + MATLAB)
  - `Data/` — Stata do-files + small CSVs for data processing (raw data excluded)
- `Figures/` — 27 publication-ready figures
- `Graphs/` — Working graphs + Stata generation scripts
- `Literature/` — 90+ reference PDFs organized by topic
- `Slides/` — Presentation LyX files
- `Referee/` — Journal referee reports + automated review
- `Submission/` — Cover letters + disclosure statements
- `Moments/` — Supplementary calibration materials

---

## Workstreams

### WS1: Archival & Code Documentation
- **Status**: Complete (initial setup)
- Copied from Dropbox, cleaned of old drafts and large data files
- Code scripts preserved for reproducibility

### WS2: Referee Report (Math/Typos) — OPTIONAL
- **Status**: Not started
- **Approach**: Read full LyX, check all equations, derivations, proofs
- **Output**: `Referee/REFEREE_REPORT.md` + `.tex` + `.pdf`
- Can run as background agent task if needed

### WS3: Code Review — OPTIONAL
- **Status**: Not started
- Four components:
  1. MATLAB estimation (`Codes_ABB/`, ~28 .m files)
  2. MATLAB steady-state solver (`SteadyState/`, ~19 .m files)
  3. Fortran replication (`Iacoviello_Pavan_JME/`, lighter review)
  4. Stata data processing (9 .do files)
- **Output**: `Code/CODE_REVIEW.md`
- Good candidate for Codex batch task

### WS3: LyX-to-TeX Conversion — OPTIONAL
- **Status**: Not started
- Paper is published, so LyX is authoritative source
- Could export to .tex for archival or editing without LyX

---

## Tools & Resources

- **Stata**: StataNow 19 SE at C:/Program Files/StataNow19/StataSE-64.exe
- **MATLAB**: Required for Code/Codes_ABB and Code/SteadyState
- **Codex**: Available for self-contained batch tasks (code review, literature)

---

## Notes for Future Claude Sessions

- Read this file first to understand project state
- The LyX file is ~4300 lines — read in chunks
- This is a PUBLISHED paper (JME 2025) — focus is archival + review, not drafting
- Code is MATLAB + Fortran + Stata (not C++ like NecessityEntrepreneurs)
- Coauthor is Isaac Gross ("Zac") at Monash University
- Large data files (.mat, .dta) are excluded from repo — regenerable from scripts
