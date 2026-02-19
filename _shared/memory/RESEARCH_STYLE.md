# RESEARCH_STYLE.md — Persistent Memory for AI Sessions

This file records stable preferences for how work is done in this repository.
Read it at the start of any session involving research writing, code, or document generation.

---

## Academic Style

- **Do not invent references.** Only cite papers you can confirm exist (e.g., from the project's `Literature/` folder, or a verified DOI). If uncertain, flag the citation as `[UNVERIFIED — check before submitting]`.
- **Distinguish evidence from inference.** Mark inferences clearly (e.g., "this suggests…", "it appears that…"). Reserve declarative statements for things directly supported by the paper/code/data.
- **Ask before assuming.** If the identification strategy, paper contribution, or data description is unclear, ask the user rather than filling in plausible-sounding content.
- **Calibration parameters**: always check code against the paper. Report discrepancies; do not silently reconcile them.

## Writing Conventions

- LaTeX is the primary document format. LyX files (`.lyx`) are the authoritative source for papers.
- Equations use `amsmath`. Custom shorthand commands (`\fixed`, `\added`, `\noted`) are defined per-document.
- Referee responses follow the template in `_shared/templates/referee_response_template.tex` and the conventions in `_shared/standards/referee_response_standard.md`.
- Use `\subsection*{Issue N: …}` headings to match referee report issue numbers exactly.

## Folder and Cleanliness Rules

- **No clutter in root.** Root-level files: only `AGENTS.md`, `CLAUDE.md`, `README.md`, `.gitignore`, `.git/`, `.claude/`.
- **No old versions in main folders.** Archive previous drafts to `_playground/backups/` or a dated subfolder (e.g., `old/` or `YYYY-MM-DD/`) — never as loose files in the project root.
- **Backups in subfolders only.** If an archive is needed, it goes in `_playground/backups/` or a project-level `old/` subdirectory.
- **Prefer incremental, low-risk changes.** Make one focused change, verify it compiles/runs, then proceed.
- **Git hygiene.** Prefer `git mv` for tracked files. Never force-push main. Always commit with a meaningful message.

## Project Memory

Each project in `projects/<name>/` has:
- `README.md` — what the project is, current status, next 3 concrete tasks.
- `memory.md` — key file paths, conventions, outstanding decisions, session notes.

Read the project's `README.md` and `memory.md` before starting any session on that project.

## Shared Assets

- Skills: `_shared/skills/` — reusable knowledge packs
- Templates: `_shared/templates/` — document templates
- Standards: `_shared/standards/` — conventions and checklists
- Prompts: `_shared/prompts/` — reusable prompt fragments
- Agents: `_shared/agents/` — specialist agent definitions

---

*Last updated: 2026-02-19*
