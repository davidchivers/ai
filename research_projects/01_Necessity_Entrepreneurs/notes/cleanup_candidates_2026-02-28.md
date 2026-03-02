# Cleanup candidates (review before delete)

This file lists items that are likely safe to delete later, after you confirm no downstream dependency.

## Already archived this session

- Legacy planning file moved from project root:
  - `notes/old/2026-02-28/PROJECT_PLAN_legacy_2026-02-18.md`
- Non-canonical AI calibration logs moved:
  - `calibration/ai_calibration/runtime/data/output/old/2026-02-28_noncanonical_logs/`
- Failed ladder-attempt metadata logs moved:
  - `calibration/ai_calibration/runtime/data/output/old/2026-02-28_failed_ladder_attempt/`
- Referee LaTeX build artifacts moved:
  - `referee/old/build_artifacts/2026-02-28/`

## Suggested delete-later candidates (not deleted now)

- `calibration/ai_calibration/runtime/data/output/old/2026-02-28_noncanonical_logs/`
  - contains older probes, sanity runs, and pre-ablation logs that are not referenced in current `STATUS.md`.
  - recommendation: keep through next successful UI-ladder rerun, then delete folder in one step.
- `calibration/ai_calibration/runtime/data/output/old/2026-02-28_failed_ladder_attempt/`
  - metadata-only logs from a failed execution attempt (no solve traces).
  - recommendation: safe to delete once runtime/toolchain issue is resolved and new ladder runs complete.
- `referee/old/build_artifacts/2026-02-28/`
  - pure compile outputs (`.aux/.log/.out/.nav/.snm/.toc`).
  - recommendation: safe to delete after confirming no need for old compile diagnostics.
- `notes/old/2026-02-28/PROJECT_PLAN_legacy_2026-02-18.md`
  - superseded by `STATUS.md` and `README.md`.
  - recommendation: optional delete if you do not need the historical day-by-day plan.

## Needs manual check

- `figures-David_Laptop` and `referee-David_Laptop` in project root:
  - both are Windows reparse-point directories.
  - recommendation: inspect link target/usage manually before deleting or unlinking.
