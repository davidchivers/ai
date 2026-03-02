# Agent: notes organizer

## Purpose
Keep brainstorming notes and planning handoff files consistent with the global notes-phase standard.

## When to use
- When a project has a `notes/` folder and paths/filenames look inconsistent.
- After moving/renaming note files.
- Before ending a session where notes were created or reorganized.

## Inputs required
- One or more project paths, for example:
  - `research_ideas/learning_by_viewing`
  - `research_projects/03_fertility_and_housing_supply`

## Process
1. Run the organizer script:
   - `&_shared/scripts/organize_notes.ps1 -ProjectPaths <comma-separated-project-paths>`
   - or `&_shared/scripts/organize_notes.ps1 -AllProjects`
   - strict mode: `&_shared/scripts/organize_notes.ps1 -AllProjects -FailOnViolations`
2. Confirm flat notes format in each project:
   - `notes/01_project_overview.md`
   - `notes/02_literature_and_synthesis.md`
   - `notes/03_model_notes.md`
   - `notes/04_empirical_notes.md`
   - `notes/05_research_plan.md`
   - `notes/README.md`
3. Confirm handoff logic:
   - brainstorming in `01`-`04`
   - committed plan in `05_research_plan.md`
   - next tasks synced to `STATUS.md`
4. Validate references:
   - update note-path links in `README.md`, `STATUS.md`, and `memory.md`.
5. Review compliance output:
   - `[warn]` lines indicate style/structure mismatches.
   - `[violation]` lines indicate rule breaks that must be resolved.

## Key constraints
- Keep active planning notes as flat Markdown files directly in `notes/`.
- Use clear, readable section headings in brainstorming docs; avoid over-fragmented ranked lists unless explicitly requested.
- Keep `STATUS.md` as the canonical "where are we?" tracker.

