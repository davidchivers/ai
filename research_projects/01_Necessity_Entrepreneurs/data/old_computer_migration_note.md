# old computer migration note

Purpose: move `data/` safely to the old computer without relying on sync conflict handling.

## Source of truth

- Treat the copy from this machine as the canonical version for this handoff.
- Do not merge by opening both copies and editing in place before reconciling them.

## Recommended Dropbox destination

- Prefer `Dropbox\economics_repo\` rather than plain `Dropbox\Economics\`.
- Reason: it keeps the future git-backed working copy visually distinct from the archived old path `OneDrive\Desktop\Economics\`.

## Old computer procedure

1. Before opening any files, check whether an older `data/` already exists.
2. If it exists, rename it first to `data_oldpc_premerge_2026_03_08/`.
3. Bring over the current `data/` folder from the source machine.
4. Open the brought-over copy first and continue work there only.
5. Compare against the renamed old-computer copy later, file by file, if needed.

## Git checkpoint rule

- This folder is intended to be checkpointed on its own branch before the broader repo move.
- If the old computer needs the safest possible source, use the pushed branch version rather than a sync-merged folder.

## Files expected in this folder

- `README.md`
- `work_log.md`
- `pull_us_business_size_cycle_data.py`
- `firm_creation_business_cycle_literature_review.md`
- `us_business_counts_by_size_annual.csv`
- `us_business_counts_by_size_indexed.png`
