# Local storage layout

Current working layout following the September 2026 SSD migration:

| Location | Role |
| --- | --- |
| C: | Windows, installed applications and required Windows user/application state |
| E:\AI | Shared working checkout, including the live Book |
| E:\AI_worktrees | Separate project branches; consult _shared/workspaces/WORKTREE_MAP.md |
| E:\AI_tasks | Standalone Codex task files; the Documents/Codex folder is an application access link |
| E:\AI_storage\spillover | Active runs, scratch work, package caches and temporary outputs |
| E:\research_data and E:\AI_data | Locally permitted research inputs outside Git |
| E:\AI_tools | Portable AI compiler and document toolchains after verification |
| D:\AI_storage\backups | Migration preservation and selected continuing backups |
| D: preserved model/cache archives | Retained results and provenance; consult the migration classification |
| Durham PRS | Approved institutional project storage under the applicable project rules |

The live migration state and copy receipts are recorded in
E:\AI\other\storage_migration\README.md. A destination folder is not proof that
a copy is complete. Switch a consumer only after its copy receipt passes.

## Working rules

- Use the current checkout and E: paths for new work. Historical reports may name
  their original C: or D: location; retain that provenance.
- Keep raw data, local credentials, dependency caches and migration backups out
  of Git. Storage location does not change a dataset's licence or sharing rules.
- Preserve existing uncommitted, untracked and ignored work during migration.
- Create project virtual environments inside the E: project checkout. Keep
  model weights and bulky package/download caches in E: spillover storage.
- Never use a cross-volume directory move on a tree containing junctions.
  Verify files and target contents, then retarget the link deliberately.
- The C: cache paths required by applications may be junctions to E:.
  Check their resolved target when measuring physical storage.
- Restart applications after changing saved environment variables. Existing
  processes and old Codex tasks can retain their earlier environment/cwd.

## Continuing local backup

The canonical backup script is _shared/scripts/backup_ai_work.py.

It saves ordinary files from E:\AI, E:\AI_worktrees and E:\AI_tasks in versioned,
content-addressed snapshots under D:\AI_storage\backups\ai_work_versions.
This includes uncommitted, untracked and ignored working files. Dependency
environments and junction targets are excluded. Git metadata and objects are
included for nested repositories and staged versions; the two main repositories
also have verified portable bundles. File versions are never automatically deleted.

The backup does not version the external E: research-data and spillover trees.
Their verified D: cutover copies are retained. New external inputs or expensive
new results need their own selected backup or an approved institutional copy.

A local second disk protects against loss of one disk. It is not an off-machine
copy. No external destination is assumed or used without the user's choice.

Run a current-file restore check with:

    python E:\AI\_shared\scripts\backup_ai_work.py --restore-test E:\AI_storage\spillover\storage_cutover_restore_test

Use a new directory beginning with that dedicated restore-test path for each
check. The restore command refuses to overwrite an existing test output.
