# memory.md — BOOK

Most recent session first.

---

### Session: 2026-02-23 (resume and audience definition)
- Resumed from prior scaffold/style stage and converted one planning placeholder into a concrete decision.
- Added a working target-audience definition to `Bookmaster Plan.md`:
  - Intelligent general readers without required economics training.
  - Secondary practitioner audience (policy, education, health, business, media).
  - Plain-English promise with optional technical depth only when useful.
- Updated `To Do List.md` to mark target audience as completed.

## Next 3 concrete tasks (as of 2026-02-23)
1. Replace Chapter 1-16 placeholder working titles in `Bookmaster Plan.md`.
2. Confirm chapter file naming convention across `Draft Chapters/` and `Final Chapters/`.
3. Decide whether the ending should be a short epilogue or a stronger expanded conclusion.

---

### Session: 2026-02-20 (project initialization)
- Created project scaffold:
  - `projects/BOOK/code/`
  - `projects/BOOK/data/`
  - `projects/BOOK/figures/`
  - `projects/BOOK/literature/`
  - `projects/BOOK/notes/`
  - `projects/BOOK/referee/`
  - `projects/BOOK/slides/`
  - `projects/BOOK/old/`
- Added project entry to `projects/README.md`.
- Added baseline `README.md` and `memory.md`.

## Key files

| Role | Path |
|---|---|
| Project overview | `projects/BOOK/README.md` |
| Session memory | `projects/BOOK/memory.md` |

## Current status
Scaffold only. No paper/code/data artifacts yet.

## Next 3 concrete tasks (as of 2026-02-20)
1. Define project scope and contribution.
2. Populate `literature/` with verified sources.
3. Start a dated research note in `notes/`.

---

### Session: 2026-02-20 (style guide + chapter scaffold)
- Read all three reference books (PDFs in `literature/`):
  - *How to Read Numbers* (David & Tom Chivers, 2021)
  - *Everything is Predictable* (Tom Chivers, 2024)
  - *The AI Does Not Hate You* (Tom Chivers, 2019)
- Read Master Plan, To Do List, and two existing draft chapters from Google Drive
- Created `STYLE_GUIDE.md` — voice, chapter structure, existing examples, tone calibration per chapter
- Created `Chapters/` folder structure with one subfolder and README per chapter (Ch 1–16)
- Workflow confirmed: David drafts → chat → Tom rewrites → David comments → Tom resolves
- Google Drive stays as .docx only; MD files live in repo only (not synced to Drive)
- Added `projects/book/literature/*.pdf` to `.gitignore`

---

### Session: 2026-02-20 (book-mode reset + collaboration intent)
- Reframed project from research-paper template to popular-science book workflow.
- Added book-specific folders:
  - `projects/BOOK/Manuscript/`
  - `projects/BOOK/Chapters/`
  - `projects/BOOK/sources/`
  - `projects/BOOK/googledrive/`
- Recorded author/collaborator context:
  - David Chivers (academic economics author context).
  - Tom Chivers (journalist collaborator context).
- Added Drive-link objective for `THE TARGET TRAP` folder.
- Located Google Drive folder path:
  - `G:\My Drive\The Target Trap (Book Project)`
- Added Google Drive index tooling:
  - `projects/BOOK/googledrive/refresh_drive_index.ps1`
  - `projects/BOOK/googledrive/INDEX.md`
- Current indexed Google Docs in folder:
  - `Book Master Plan.gdoc`
  - `01 - Draft - Introduction.gdoc`
  - `02 - Draft - Offside Law.gdoc`
  - `Book Proposal.gdoc`
  - `To Do List.gdoc`
- Attempt to create a direct filesystem link into `projects/BOOK/googledrive/` failed due Windows privilege restrictions for symlink creation in this shell session.
