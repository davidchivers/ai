# RESEARCH_STYLE.md ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Persistent Memory for AI Sessions

This file records stable preferences for how work is done in this repository.
Read it at the start of any session involving research writing, code, or document generation.

---

## Academic Style

- **Do not invent references.** Only cite papers you can confirm exist (e.g., from the project's `literature/` folder, or a verified DOI). If uncertain, flag the citation as `[UNVERIFIED ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â check before submitting]`.
- **Distinguish evidence from inference.** Mark inferences clearly (e.g., "this suggestsÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦", "it appears thatÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦"). Reserve declarative statements for things directly supported by the paper/code/data.
- **Ask before assuming.** If the identification strategy, paper contribution, or data description is unclear, ask the user rather than filling in plausible-sounding content.
- **Calibration parameters**: always check code against the paper. Report discrepancies; do not silently reconcile them.

## Writing Conventions

- LaTeX is the primary document format. LyX files (`.lyx`) are the authoritative source for papers.
- Equations use `amsmath`. Custom shorthand commands (`\fixed`, `\added`, `\noted`) are defined per-document.
- Referee responses follow the template in `_shared/templates/referee_response_template.tex` and the conventions in `_shared/standards/referee_response_standard.md`.
- Use `\subsection*{Issue N: ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦}` headings to match referee report issue numbers exactly.
- **User preference (global):** pre-paper work (kickoffs, brainstorms, design memos, literature maps, reports, and reviews) is Markdown-first in `notes/`. Do not auto-create `.tex`/`.lyx`/`.pdf` for these.
- **User preference (global):** in pre-paper phases, `notes/` uses a flat Markdown layout (no category subfolders) and standardized numbered living files:
  - canonical files in `notes/`: `01_project_overview.md`, `02_literature_and_synthesis.md`, `03_model_notes.md`, `04_empirical_notes.md`, `05_research_plan.md`
  - workflow: brainstorm in `01`-`04`, then commit choices in `05_research_plan.md`
  - depth distribution: keep `01`-`04` as substantive working notes (full sections, synthesis, and model/empirical detail); keep `05_research_plan.md` concise as a decision-lock file (chosen question, estimands, chosen models/strategies, lock criteria, next 3 tasks)
  - notes index: include `notes/README.md` to map the role of each numbered file
  - when a user asks for a very long/ranked output, place detailed material primarily in `01`-`04` and keep `05` focused on final selections
  - writing style: use clear section titles and paragraph-first structure; do not force priority-ranking labels unless explicitly requested
  - see `_shared/standards/notes_phase_standard.md`
  - automation: `&_shared/scripts/organize_notes.ps1 -AllProjects`
  - strict enforcement: `&_shared/scripts/organize_notes.ps1 -AllProjects -FailOnViolations`
- **Paper-start trigger (global):** only when the user explicitly says to begin paper writing should work move to `Paper/drafts/`, where you create `.tex` and `.lyx` sources and compile `.pdf` drafts.
- **User preference (global):** organize project outputs for a reading-first workflow using the **standard project template** below. Keep `README.md`, `STATUS.md`, and `memory.md` in the project root.

    **Standard folder template (all new research projects):**
  ```
  XX_ProjectName/
  Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ README.md          # what + status + next 3 tasks
  Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ STATUS.md          # live status tracker
  Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ memory.md          # paths, conventions, decisions
  Ã¢â€â€š
  Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ notes/             # brainstorming: markdown/quarto source files
  Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ paper_latest.pdf   # canonical latest paper output (paper-phase only)
  Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ slides_latest.pdf  # canonical latest slides output (paper-phase only)
  Ã¢â€â€š
  Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ Paper/             # everything for the paper Ã¢â‚¬â€ create lazily
      Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ literature/    # reference PDFs (never generated; can exist before Drafts/)
      Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ Drafts/        # LaTeX/LyX source: main.tex, Sections/, refs.bib
      Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ build/     # LaTeX aux files (gitignored) Ã¢â‚¬â€ set via .latexmkrc
      Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ figures/       # source figures for the paper (.pdf, .eps, .png)
      Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ Tables/        # auto-generated .tex fragments from code
      Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ Code/          # analysis scripts; numbered for execution order (01_, 02_)
      Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ lib/       # user-written ado files / helper scripts
      Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ Data/
          Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ raw/       # read-only Ã¢â‚¬â€ never modified by code
          Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ processed/ # output of cleaning scripts
  ```

  **Phase logic:**
  - Phase 1 (brainstorming): use `notes/` for source files only (`.md` preferred) and do not generate PDFs.
    Start `Paper/literature/` as soon as you download the first reference PDF.
  - Phase 2 (writing): create `Paper/drafts/` when drafting begins. Add `Paper/figures/`,
    `Paper/code/`, `Paper/data/` lazily as needed. notes/ stays Ã¢â‚¬â€ it's not deleted.
  - `Paper/` is self-contained: zip it for a co-author or replication package.

  **Rules:**
  - Store canonical latest outputs in the project root as:
    - `paper_latest.pdf`
    - `slides_latest.pdf`
    Keep these overwritten in place (single latest version each).
  - `Paper/drafts/` contains only LaTeX/LyX source files (writing space, not output space).
  - File naming for latest outputs: stable names (`paper_latest.pdf`, `slides_latest.pdf`).
  - Submitted/milestone PDFs: `submitted-[Journal].pdf` (or user-specified variant). Tag the git commit `v1-submitted-JME`.
  - Create all subfolders **lazily** Ã¢â‚¬â€ only when you have a file to put there.
  - Non-research projects should also keep only stable latest output filenames by default (no date prefix unless requested).
  - Old/archived versions go to `_playground/backups/YYYY-MM-DD/` Ã¢â‚¬â€ never as loose files in the project.
- **User preference (global):** create project subfolders lazily (only when adding the first file); never pre-create empty folders.
- **LaTeX overflow guard (global):** for paper-stage LaTeX drafts, include `\usepackage{microtype}` and `\usepackage{xurl}` in the preamble and set `\setlength{\emergencystretch}{3em}` to reduce right-margin overfull lines.
- **LaTeX link formatting (global):** in paper-stage LaTeX drafts, avoid printing full raw URLs inline in body text or source lists when they can overflow margins. Prefer `\href{...}{source link}` (or short descriptive anchor text). If `xurl` is unavailable on the machine, fall back to `\usepackage[hyphens]{url}`.

## Folder and Cleanliness Rules

- **No clutter in root.** Root-level files: only `AGENTS.md`, `CLAUDE.md`, `README.md`, `.gitignore`, `.git/`, `.claude/`.
- **No old versions in main folders.** Archive previous drafts to `_playground/backups/` or a dated subfolder (e.g., `old/` or `YYYY-MM-DD/`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â never as loose files in the project root.
- **Backups in subfolders only.** If an archive is needed, it goes in `_playground/backups/` or a project-level `old/` subdirectory.
- **Prefer incremental, low-risk changes.** Make one focused change, verify it compiles/runs, then proceed.
- **Git hygiene.** Prefer `git mv` for tracked files. Never force-push main. Always commit with a meaningful message.

## Project Memory

Each project in `research_projects/<name>/` has:
- `STATUS.md` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â single source of truth for current status, next 3 tasks, blockers, and decisions.
- `README.md` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â what the project is, current status, next 3 concrete tasks.
- `memory.md` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â key file paths, conventions, outstanding decisions, session notes.

Read the project's `STATUS.md`, `README.md`, and `memory.md` before starting any session on that project.

If asked "where are we?" or asked to write/update a to-do list, update `STATUS.md` instead of creating a new checklist file.

## Global User Preferences (Book Projects)

- `BOOK` is a popular-science book project, not an academic paper workflow.
- Treat David Chivers context as academic economist author background.
- Treat Tom Chivers context as journalist collaborator/audience reviewer.
- When possible, maintain compatibility with Google Docs collaboration workflows for book drafting and review.
- All numbered projects (for example, `01_*`, `02_*`, `03_*`) are academic paper projects intended for publication.

## Global User Preferences (File Naming)

- Do not use date prefixes in working document filenames by default.
- Use stable descriptive filenames and update in place (for example, checklists, notes, reports, and drafts).
- Use dated names only for explicit archive snapshots/backups or when the user asks for date-based naming.

## Global User Preferences (All New Papers: drafts and slides)

- Use `lowercase_with_underscores` for paper working folders and filenames.
- Keep canonical latest paper files in `drafts/` with no version suffix:
  - `<paper_title_slug>.lyx`
  - `<paper_title_slug>.pdf`
- Keep canonical latest slide files in `slides/` with no version suffix:
  - `<paper_title_slug>_slides.lyx`
  - `<paper_title_slug>_slides.pdf`
- Keep TeX exports out of visible draft/slide root folders:
  - `drafts/old_drafts/source_tex/<paper_title_slug>.tex`
  - `slides/old_slides/source_tex/<paper_title_slug>_slides.tex`
- Keep LaTeX build artifacts out of visible root folders:
  - `drafts/old_drafts/build_artifacts/`
  - `slides/old_slides/build_artifacts/`
- Do not create new version folders unless the user explicitly says to start a new version.
- Version snapshots go only in:
  - `drafts/old_drafts/vNNN/`
  - `slides/old_slides/vNNN/`
- On explicit version start, copy current latest files into `vNNN`, rename copied files with `_vNNN`, then continue editing only unversioned latest files.

## Global User Preferences (Capitalization)

- Canonical governance filenames stay uppercase where standardized: `README.md`, `STATUS.md`, `AGENTS.md`, `CLAUDE.md`.
- Folder names across project trees should be `lowercase_with_underscores` (including `drafts/`, `slides/`, `notes/`, `literature/`, `referee/`, `calibration/`, `figures/`, `code/`, `data/`, `exports/`).
- When creating draft folders for new papers, apply lowercase folder naming immediately and do not introduce new capitalized folder names.
- Active notes filenames stay lowercase snake_case with numeric prefixes (for example, `01_project_overview.md`, `05_research_plan.md`).
- Markdown headings should use sentence case by default.
- Avoid all-caps words in prose and headings except fixed acronyms (for example, `UK`, `PDF`, `OLG`, `DDD`).

## Global User Preferences (Model note readability)

- For model explanations, present content in this order: intuition first, variables second, equations third.
- Do not write context-free math; define symbols before any equation.
- Keep labels concise; avoid long-form label clutter.
- Do not remove math entirely: use minimal equations after intuition and variable definitions.

## Global User Preferences (Shell Workflow)

- Prefer PowerShell/Windows as the default shell for project work in this repository.
- Use WSL selectively as a utility environment when doing PDF-heavy tasks (for example, Linux text/PDF extraction tools).
- For mixed workflows, keep core project execution (Stata/MATLAB/LyX and Windows-path scripts) in PowerShell and use WSL only for targeted utilities.
- Naming convention preference: use underscores (`_`) in folder/file names; if the user writes names with spaces, interpret that as underscores unless explicitly told otherwise.

## Global User Preferences (VS Code Layout)

- Preferred layout: activity bar at the top.
- Keep Codex and Claude in the activity bar (primary container), not in a secondary side bar.
- Do not use the secondary side bar by default.

## Shared Assets

- Skills: `_shared/skills/` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â reusable knowledge packs
- Templates: `_shared/templates/` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â document templates
- Standards: `_shared/standards/` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â conventions and checklists
- Prompts: `_shared/prompts/` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â reusable prompt fragments
- Agents: `_shared/agents/` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â specialist agent definitions

---

*Last updated: 2026-02-26 - added global notes depth/distribution rule (`01`-`04` substantive, `05` decision lock) and `notes/README.md` index preference*




