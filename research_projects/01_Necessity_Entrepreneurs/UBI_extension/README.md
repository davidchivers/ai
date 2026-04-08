# UBI Extension — Necessity Entrepreneurs

## Purpose

This folder is a self-contained extension to the Necessity Entrepreneurs project
exploring the effect of a Universal Basic Income on necessity entrepreneurship.
It is kept separate from the main calibration to avoid conflicts when working
across multiple machines.

**The canonical source in `calibration/canonical_dropbox/` has NOT been modified.**

---

## Economic question

How large does a universal lump-sum transfer need to be to materially compress
the necessity entrepreneurship band `h_hat_unmatched < h < h_hat_employed`?

The baseline calibration (case 147) has UI at 40% of the mean wage, paid only
while in the UI-eligible unemployment state. UBI differs in two key ways:

1. It is paid in **all** states: employed, unemployed (with or without UI),
   and while running a business.
2. It is **permanent**, not conditional on job-search or duration.

Because UBI raises income in all states, it does not mechanically close the
necessity band the same way targeted UI would. Whether it does so materially
depends on general-equilibrium adjustments and the value functions — hence
the scan.

---

## Scan design

Four cases against the case 147 baseline. All other parameters identical.
Transfer is **unfunded (manna-from-heaven)** to isolate the outside-option
channel. This is the standard first pass; a revenue-neutral version would
damp the effect through the tax wedge.

| Case | UBI level | Note |
|------|-----------|------|
| 147  | 0.0       | Baseline (no UBI) |
| 148  | 0.2 × mean wage | Low UBI |
| 149  | 0.4 × mean wage | Equal to current UI rate — useful benchmark |
| 150  | 0.6 × mean wage | Moderate UBI |
| 151  | 0.8 × mean wage | High UBI |

Key outcomes to track across cases:
- Entrepreneur share (total, and self-employed vs employer split)
- Necessity band width by education group (from cutoff output)
- Average entrepreneur size and capital
- Theta (labour market tightness)

---

## What was changed in the source

File: `source/main_2025_v1_ubi_extension.cpp`
Relative to canonical `main_2025_v1_case113_self_employment.cpp`:

1. **New global**: `double ubi_transfer_level = 0.0;`

2. **New env var**: `CFV_UBI_TRANSFER` — sets `ubi_transfer_level` at runtime,
   consistent with the existing override pattern (e.g. `CFV_UI_REPLACEMENT`).

3. **Income injection** — in `solve_opt`, the `asset_income` base for both
   the worker and entrepreneur branches now includes `ubi_transfer_level * w0_tmp`.
   Because `asset_income` feeds into employed income, UI-unemployed income,
   no-UI-unemployed income, and entrepreneur income, a single addition covers
   all states correctly.

4. **Cases 148–151** added after case 147.

---

## How to run

From this folder:

```powershell
# Steady-state scan (fast — no transition)
powershell -ExecutionPolicy Bypass -File run_ubi_scan.ps1 -SingleCase 148 -SkipTransition -RunTag "ubi020"
powershell -ExecutionPolicy Bypass -File run_ubi_scan.ps1 -SingleCase 149 -SkipTransition -RunTag "ubi040"
powershell -ExecutionPolicy Bypass -File run_ubi_scan.ps1 -SingleCase 150 -SkipTransition -RunTag "ubi060"
powershell -ExecutionPolicy Bypass -File run_ubi_scan.ps1 -SingleCase 151 -SkipTransition -RunTag "ubi080"

# Or run a specific UBI level via env var override on any case:
powershell -ExecutionPolicy Bypass -File run_ubi_scan.ps1 -SingleCase 147 -UBITransfer 0.5 -SkipTransition -RunTag "ubi050_env"
```

Logs go to `runtime/data/output/case_1/`.

The script compiles `source/main_2025_v1_ubi_extension.cpp` on first run
(requires g++ or cl on PATH). After first compile the exe is cached as
`cfv_ubi_extension.exe` in this folder; use `-SkipCompile` to reuse it.

---

## Next steps (after scan)

1. Read entrepreneur share and necessity band from scan logs.
2. Identify the UBI level where the necessity share drops materially.
3. Around that level, run a finer grid (e.g. 0.05 steps) with full calibration.
4. Consider a revenue-neutral version: same UBI but funded by proportional
   labour income tax — this dampens the outside-option effect and gives the
   realistic lower bound.

---

## Folder structure

```
UBI_extension/
  README.md                        — this file
  run_ubi_scan.ps1                 — self-contained run script (UBI-aware)
  cfv_ubi_extension.exe            — compiled binary (generated on first run)
  source/
    main_2025_v1_ubi_extension.cpp — UBI-modified source (do not merge back)
  runtime/
    data/
      input/CFV/                   — model input files (copied from baseline)
      output/case_1/               — scan logs go here
  nr.h, nrexit.cpp, nrtypes*.h, nrutil*.h  — NR headers for compilation
  notes/
    ubi_scan_results.md            — fill in after scan completes
```

---

## Important

- Do NOT merge `main_2025_v1_ubi_extension.cpp` back into the canonical source.
- The canonical source remains unmodified.
- This folder is safe to copy to another machine independently.
