# status

## objective
Estimate SKU-level public-versus-market laptop price gaps in UK procurement and identify mechanisms (bundling, competition, governance/timing, threshold rules).

## completed this session
- Created full project structure and requested files.
- Drafted UK institutional background and framework mechanism notes.
- Drafted data inventory, schemas, matching, cleaning, and sampling plans.
- Drafted empirical identification, specifications, robustness, falsification, heterogeneity sections.
- Added paper-writing skeleton and Python pipeline stubs.

## next 3 tasks
1. Data acquisition: build notice list and attachment download index.
2. Measurement validation: parse 20-30 attachments manually to calibrate extraction rules.
3. Feasibility check for threshold design (running variable, density, manipulation tests).

## blockers
- No collected raw data yet.
- Citation verification pending for institutional/literature claims.

## decisions
- Main project path: `projects/08_uk_procurement_laptop_pricing`.
- Main estimand uses high-confidence, warranty-aligned SKU matches.
- Bundled and non-separable contracts are analysed separately from hardware-only baseline.
