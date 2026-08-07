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

## Startup

- Load only the context needed for the current task.
- Read `_shared/memory/RESEARCH_STYLE.md` for stable user preferences on substantive research, writing, and presentation.
- For a tracked paper project, read the live sections of `STATUS.md` first. Read `README.md` for stable scope and `memory.md` only when durable paths or past decisions are relevant.
- Before proposing project work, check the single live `## Next 3 Tasks` section in `STATUS.md`.
- Load task-specific standards, templates, agents, and skills only when the task matches them.
- Before declaring a repository resource unavailable, check the relevant index under `_shared/`.

---

## Cleanliness rules (critical)

- **No clutter in root.** Root should only contain the canonical workspace structure and governance files: `research_projects/`, `research_ideas/`, `teaching/`, `book/`, `other/`, `_shared/`, `_playground/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.gitignore`, `.git/`, `.agents/`, `.claude/`, `.codex/`, `.vscode/`.
- **C: drive guard for agentic work.** Treat `C:` as the scarce fast workbench and `D:` as the bulky spillover drive. For coding, data, build, browser, transcription, or long-running agent sessions, check `C:` free space at the start and again after any operation likely to create large files. If `C:` is below 20 GB free, or if it drops by more than 2 GB during the session, stop and tell the user in the chat what grew before continuing. Do not install background warning scripts or scheduled popup tasks for this unless the user explicitly asks.
- **Default spillover target.** Put bulky or rebuildable local material under `D:\AI_storage\spillover\` by default: temp downloads, browser profiles, package/model caches, generated bundles, scratch worktrees, and large intermediate outputs. Serious reusable datasets should go under `D:\research_data\` or another project-specific folder on `D:`, with a README or pointer from the repo if needed.
- **No loose old versions in any project folder.** If a draft/output is wrong or superseded, delete it by default rather than keeping a loose stale copy. Only archive a previous version when the user explicitly wants to preserve it or when it is a real milestone snapshot.
- **Backups in subfolders only.** Do not create backup/archive copies by default. If preservation is explicitly needed, put the backup in `_playground/backups/` or the project's own `old/` subdirectory.
- **Build artifacts must not be committed.** `.aux`, `.log`, `.out`, `.nav`, `.snm`, `.toc`, `.mat`, `.dta` go in `.gitignore`.
- When creating new outputs, prefer subfolders over root-level files.
- **Workspace PDF editing rule.** When editing a PDF output anywhere under `C:\Users\Dave_\AI`, close the open PDF viewer first, rebuild the same canonical PDF in place, and reopen that same file. Do not create a separate temporary PDF as the live output just to avoid a file lock.
- **Single status source per tracked research project.** If a research paper project uses status tracking, use exactly one canonical file: `research_projects/<name>/STATUS.md`. Do not create multiple active to-do/status lists for the same project.
- **Status policy by project type.**
  - Numbered paper projects (`01_*`, `02_*`, etc.) must maintain `STATUS.md`.
  - Non-paper folders (e.g., `Book`, `Teaching`, `Department_Admin_Project`, `data_lab`) may use `STATUS.md` optionally; if omitted, `README.md` is the canonical current-state source.

---

## Style rules

- **Do not invent references.** Only cite papers confirmed to exist (e.g., from `Literature/` folder, or a verified DOI). If uncertain, flag as `[UNVERIFIED]`.
- **Distinguish evidence from inference.** Mark inferences explicitly. Use declarative statements only for things directly supported by paper/code/data.
- **Ask before assuming.** If the identification strategy, contribution, or data are unclear, ask the user rather than filling in plausible content.
- **Prefer scoped, reversible changes.** Validate them in proportion to risk.
- **No force-push to main.** Use feature branches and pull requests for significant changes.

---

## Referee responses

Use `_shared/templates/referee_response_template.tex` with `_shared/standards/referee_response_standard.md`. Save the response to `research_projects/<name>/referee/RESPONSE_TO_REFEREE.tex`, and never mark an issue as `\fixed` until the paper change has actually been applied.

---

## Reusable agents and skills

- Use `_shared/agents/README.md` to select narrow repository-specific operating prompts.
- Use `_shared/skills/README.md` to select broader reusable methods and tool workflows.
- Choose the narrowest resource that matches the task; do not stack near-duplicates by default.

---

## git rules

- Prefer `git mv` for tracked files; regular `mv` for untracked.
- Commit with a meaningful message describing *why*, not just *what*.
- Do not commit `.aux`, `.log`, `.out`, `.lyx~`, `.mat`, `.dta`, `.asv`.
- Treat the shared root checkout (`C:\Users\Dave_\AI`) as a stable workspace. Do not switch its branch for one thread or subproject if other threads may still be using it.
- When a thread needs its own branch, use a separate git worktree for that thread and keep branch switching inside that worktree rather than in the shared root checkout.
- Before telling the user where to push, inspect the real git context with `git branch --show-current`, `git worktree list`, and `git for-each-ref --format='%(refname:short)|%(upstream:short)|%(worktreepath)' refs/heads`. Never guess from the folder name alone.
- Long-lived active branches usually mirror the project path. Prefer an existing project branch/worktree over inventing a new branch.
- Treat `archive/*` branches as legacy history only. Never recommend, create, or push active work to an `archive/*` branch unless the user explicitly asks for that.
- Treat whatever branch is currently checked out in the shared root as a home/sidecar branch, not as the default publish target for every project. Inspect live Git state; never hard-code the root's current branch in guidance.
- If a mistaken branch or AI-generated output is not needed, delete it rather than parking it in an archive branch/folder. Ask before deleting anything that may contain unique human work.

---

## Quarterly maintenance

See `_shared/standards/AGENT_LIBRARY_REVIEW.md` for the checklist to keep this library current.
For project status format and update rules, see `_shared/standards/project_status_standard.md`.
