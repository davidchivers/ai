# AGENTS.md — Repository Steering Instructions

This file governs how AI assistants should behave in this repository.
Read this file at the start of every session.

---

## Where things live

| What | Where |
|---|---|
| Research paper projects | `projects/<name>/` |
| Reusable skills (knowledge packs) | `_shared/skills/` |
| Document templates | `_shared/templates/` |
| Conventions and checklists | `_shared/standards/` |
| Specialist agent definitions | `_shared/agents/` |
| Persistent memory (style prefs, etc.) | `_shared/memory/` |
| Prompt fragments | `_shared/prompts/` |
| Scratch work and learning material | `_playground/` |
| Archived backups | `_playground/backups/` |

## Per-session startup

1. Read `_shared/memory/RESEARCH_STYLE.md`.
2. If working on a specific project, read `projects/<name>/README.md` and `projects/<name>/memory.md`.
3. Check `projects/<name>/README.md` for the "next 3 concrete tasks" before proposing a plan.

---

## Cleanliness rules (critical)

- **No clutter in root.** Root may only contain: `AGENTS.md`, `CLAUDE.md`, `README.md`, `.gitignore`, `.git/`, `.claude/`.
- **No loose old versions in any project folder.** Archive previous drafts to a dated subfolder (e.g., `old/`, `_playground/backups/YYYY-MM-DD/`) — never as loose files in the project root.
- **Backups in subfolders only.** If an archive copy is needed, put it in `_playground/backups/` or the project's own `old/` subdirectory.
- **Build artifacts must not be committed.** `.aux`, `.log`, `.out`, `.nav`, `.snm`, `.toc`, `.mat`, `.dta` go in `.gitignore`.
- When creating new outputs, prefer subfolders over root-level files.

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
4. Save output to `projects/<name>/Referee/RESPONSE_TO_REFEREE.tex`.
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

---

## git rules

- Prefer `git mv` for tracked files; regular `mv` for untracked.
- Commit with a meaningful message describing *why*, not just *what*.
- Do not commit `.aux`, `.log`, `.out`, `.lyx~`, `.mat`, `.dta`, `.asv`.

---

## Quarterly maintenance

See `_shared/standards/AGENT_LIBRARY_REVIEW.md` for the checklist to keep this library current.
