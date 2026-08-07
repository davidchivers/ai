# Shared scripts

Scripts in this folder automate recurring repository-maintenance tasks.

## Current scripts

- `organize_notes.ps1`: audits projects by default and normalizes them only with explicit `-Apply`; generated `notes/build/` outputs are preserved.
- `hide_tex_and_artifacts.ps1`: moves root-level TeX source/build artifacts out of visible `drafts/` and `slides/` folders into archived subfolders.
- `git_size_guard.ps1`: blocks accidental commits of large data/media/cache files when installed as the repo pre-commit hook.
- `spillover_audit.ps1`: reports C:/D: storage pressure, checks the D: spillover configuration, and can prune dangling git objects on request.
- `sync_skill_bridges.ps1`: refreshes generated `.agents/skills/` and `.claude/skills/` hard-link bridges for flat and packaged shared skills.
- `audit_agent_library.ps1`: checks skill metadata and bridges, stale instructions, and oversized or duplicated project-state headings without changing files.
- `sync_awesome_econ_skills.ps1`: audits the external Awesome Econ catalogue by default. Use `-Apply` only after reviewing conflicts; `-Force` also requires `-Apply`.

## Usage rule

- Prefer the default audit, `-DryRun`, or the equivalent inspection mode before wide repo moves. Require an explicit apply switch for mutations.
- Never run an upstream skill sync with `-Force` merely to make the hashes match; local skills intentionally contain repository-specific rules.
- Keep one-off or experimental scripts out of `_shared/`; those belong in `_playground/` until they prove reusable.
