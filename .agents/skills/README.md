# Codex skills bridge

This folder exposes the canonical shared skills in Codex's preferred
`.agents/skills/<skill>/SKILL.md` layout.

Do not edit skill content here by hand. Each `SKILL.md` mirrors the matching
source file in `../../_shared/skills/`.

To refresh the bridge after adding or renaming shared skills, run:

- `powershell -ExecutionPolicy Bypass -File _shared/scripts/sync_skill_bridges.ps1 -Prune`

Canonical source:

- `../../_shared/skills/`
