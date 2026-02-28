# Codex Collaboration Guide (Data Lab)

## Recommended platform split

- GitHub: source of truth for all working files.
- Local folder (`projects/data_lab/`): where each person runs Codex.
- OneDrive: optional sync/backup layer only.

## Daily team flow

1. Pull latest `main`.
2. Create branch for your task.
3. Work with Codex on your branch.
4. Commit with clear message.
5. Open PR and request one review.
6. Merge after approval.

## Avoid editing over each other

- Do not have two people editing the same file on `main` directly.
- If same file is needed, coordinate in branch names and PR timing.
- Keep drafts in `09_shared_workspace/` with dated names.

## Branch naming examples

- `david/mission-statement-edits`
- `johnpaul/website-service-page-copy`
- `demid/pilot-course-outline`

## Commit message template

`<area>: <why this change matters>`

Examples:
- `website: clarify business training offer for pilot clients`
- `governance: add low-bureaucracy operating principles`

## Simple branch protection to enable on GitHub

- Require pull request before merge.
- Require at least 1 approval.
- Block direct pushes to `main`.
