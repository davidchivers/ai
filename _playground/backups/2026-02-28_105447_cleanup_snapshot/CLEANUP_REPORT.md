# Cleanup report (2026-02-28)

## Completed now
- Created safety branch: `cleanup/folder-normalization-2026-02-28`
- Snapshot captured under `_playground/backups/2026-02-28_105447_cleanup_snapshot/`
- Normalized tracked project root names in git:
  - `projects/02_Nimbyism_and_Housing_Supply` -> `projects/02_nimbyism_and_housing_supply`
  - `projects/03_Fertility_and_Housing_Supply` -> `projects/03_fertility_and_housing_supply`
- Moved stray `projects/.claude/` out of active tree into snapshot backup.
- Updated `.gitignore` for:
  - `projects/.claude/`
  - `projects/book/literature/*.pdf`

## Verified now
- Root layout is clean and canonical.
- No Dropbox conflict-named directories detected.
- `core.ignorecase` returned to `true` (Windows default).

## Remaining for next pass
- Resolve legacy tracked `projects/Tuition_Fees/*` deletions versus `projects/04_tuition_fees/*` structure.
- Triage and stage large pre-existing untracked additions across `projects/` and `_shared/`.
- Optionally split migration into focused commits by project to reduce risk.
