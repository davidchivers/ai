# Skill: Update Interview Index

## Input
- All interview `_meta/metadata.yml` files.
- Optional Excel tracker(s).

## Output
- `master_index.csv`
- `master_index.md`
- Backfilled metadata links/fields where safe.

## Rules
- Treat metadata as canonical per interview.
- Add missing fields conservatively; do not overwrite user-entered values.
- Keep list fields deduplicated (`source_files`, `tags`, `chapter_candidates`).
- Continue gracefully when Excel is unreadable; preserve path links.

## Procedure
1. Discover interview folders.
2. Load and validate metadata with defaults.
3. Detect/link Excel tracker paths.
4. Optionally prefill missing metadata from readable Excel rows.
5. Write normalized index outputs.

