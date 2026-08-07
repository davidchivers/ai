# Agent: Project Status Updater

## Purpose
At the end of a work session (or start of a new one), keep the project's canonical status and supporting documentation aligned. For numbered paper projects, `STATUS.md` is the single source of truth for current state, blockers, decisions, and the next three tasks.

## When to use
- At the end of any productive session on a paper project
- When resuming a project after a gap of more than a week
- Before handing off to a co-author or RA

## Inputs required
- Project folder path (e.g., `research_projects/01_necessity_entrepreneurs/`)
- A brief summary of what was done this session (can be a bullet list)
- Any new key file paths, decisions, or conventions that emerged

## Process
1. Read the live sections of `STATUS.md` first. Read `README.md` for stable scope and the durable sections of `memory.md` for paths, conventions, and decisions; do not load a legacy session diary wholesale when targeted inspection is enough.
2. Update `STATUS.md` first:
   - record the actual current state and completed work
   - keep exactly three concrete next tasks
   - record live blockers and decisions that affect those tasks
   - do not mark work complete without evidence
3. Update `README.md` only where its short project overview or status summary has become stale. Point detailed task tracking to `STATUS.md`; do not create a second active task list.
4. Update `memory.md` only with durable paths, conventions, author decisions, or context that a future session would otherwise lose. Do not use it as a parallel status log.
5. For a non-paper project without `STATUS.md`, treat `README.md` as the canonical current-state source unless the project has explicitly adopted a status file.
6. Re-read the three files and resolve contradictions before finishing.

## Output format
Report which canonical files changed and list any contradiction or author decision that remains unresolved.

## Key constraints
- Do not create another to-do, handoff, or status file.
- Do not duplicate the full `STATUS.md` task list in `README.md` or `memory.md`.
- Do not delete still-relevant decisions from `memory.md`; consolidate obsolete session detail only when its substance is preserved.
- Do NOT mark tasks as complete unless they actually are.
- Follow `_shared/standards/project_status_standard.md` when a paper project uses `STATUS.md`.
