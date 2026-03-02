# AGENTS.md — Repository Steering Instructions

This file governs how AI assistants should behave in this repository.
Read this file at the start of every session.

---

## Where things live

| What | Where |
|---|---|
| Research paper projects | `research_projects/<name>/` |
| Early-stage research ideas | `research_ideas/<name>/` |
| Teaching projects | `teaching/<name>/` |
| Book projects | `book/<name>/` |
| Other non-paper projects | `other/<name>/` |
| Reusable skills (knowledge packs) | `_shared/skills/` |
| Document templates | `_shared/templates/` |
| Conventions and checklists | `_shared/standards/` |
| Specialist agent definitions | `_shared/agents/` |
| Persistent memory (style prefs, etc.) | `_shared/memory/` |
| Prompt fragments | `_shared/prompts/` |
| VS Code workspace configs | `_shared/workspaces/` |
| Scratch work and learning material | `_playground/` |
| Archived backups | `_playground/backups/` |

## Per-session startup

1. Read `_shared/memory/RESEARCH_STYLE.md`.
2. If working on a specific research paper project, read `research_projects/<name>/STATUS.md`, `research_projects/<name>/README.md`, and `research_projects/<name>/memory.md`.
3. Check `research_projects/<name>/STATUS.md` for the "Next 3 Tasks" before proposing a plan.

---

## Cleanliness rules (critical)

- **No clutter in root.** Root should only contain the canonical workspace structure and governance files: `research_projects/`, `research_ideas/`, `teaching/`, `book/`, `other/`, `_shared/`, `_playground/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.gitignore`, `.git/`, `.claude/`, `.vscode/`.
- **No loose old versions in any project folder.** Archive previous drafts to a dated subfolder (e.g., `old/`, `_playground/backups/YYYY-MM-DD/`) — never as loose files in the project root.
- **Backups in subfolders only.** If an archive copy is needed, put it in `_playground/backups/` or the project's own `old/` subdirectory.
- **Build artifacts must not be committed.** `.aux`, `.log`, `.out`, `.nav`, `.snm`, `.toc`, `.mat`, `.dta` go in `.gitignore`.
- When creating new outputs, prefer subfolders over root-level files.
- **Single status source per tracked research project.** If a research paper project uses status tracking, use exactly one canonical file: `research_projects/<name>/STATUS.md`. Do not create multiple active to-do/status lists for the same project.
- **Status policy by project type.**
  - Numbered paper projects (`01_*`, `02_*`, etc.) must maintain `STATUS.md`.
  - Non-paper folders (e.g., `Book`, `Teaching`, `Department_Admin_Project`, `data_lab`) may use `STATUS.md` optionally; if omitted, `README.md` is the canonical current-state source.

---

## Style rules

- **Do not invent references.** Only cite papers confirmed to exist (e.g., from `Literature/` folder, or a verified DOI). If uncertain, flag as `[UNVERIFIED]`.
- **Distinguish evidence from inference.** Mark inferences explicitly. Use declarative statements only for things directly supported by paper/code/data.
- **Ask before assuming.** If the identification strategy, contribution, or data are unclear, ask the user rather than filling in plausible content.
- **Prefer incremental, low-risk changes.** Make one focused change, verify it works, then proceed.
- **No force-push to main.** Use feature branches and pull requests for significant changes.

---

## Referee responses

When asked to draft or revise a referee response:
1. Use `_shared/templates/referee_response_template.tex` as the document skeleton.
2. Follow all conventions in `_shared/standards/referee_response_standard.md`.
3. See `_shared/templates/referee_response_example.tex` for a complete real-world example.
4. Save output to `research_projects/<name>/referee/RESPONSE_TO_REFEREE.tex`.
5. Do NOT mark an issue as `\fixed` unless the fix has actually been applied to the paper.

---

## Specialist agents

Reusable agent definitions are in `_shared/agents/`:

| Agent | Use when |
|---|---|
| `math-auditor.md` | Checking equations, FOCs, Bellman equations in a paper |
| `code-paper-crosswalk.md` | Comparing calibration code against paper equations/parameters |
| `referee-response-drafter.md` | Drafting the point-by-point referee response document |
| `literature-reviewer.md` | Drafting lit review from verified PDFs in `Literature/` |
| `project-status-updater.md` | Updating README.md and memory.md at end of session |
| `notes-organizer.md` | Enforcing flat `Notes/` file organization and updating note references |

---

## git rules

- Prefer `git mv` for tracked files; regular `mv` for untracked.
- Commit with a meaningful message describing *why*, not just *what*.
- Do not commit `.aux`, `.log`, `.out`, `.lyx~`, `.mat`, `.dta`, `.asv`.

---

## Quarterly maintenance

See `_shared/standards/AGENT_LIBRARY_REVIEW.md` for the checklist to keep this library current.
For project status format and update rules, see `_shared/standards/project_status_standard.md`.
