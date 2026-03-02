# Paper Project Structure Standard

Use this structure for paper-phase projects.

Folder naming rule: use `lowercase_with_underscores` for all folders in the project tree.

## Required top-level folders

- `drafts/`: latest visible paper files (`.lyx`, `.pdf`).
- `slides/`: latest visible slide files (`.lyx`, `.pdf`).
- `literature/`: reference PDFs and checklist files.
- `referee/`: referee response files, audits, and issue trackers.
- `calibration/`: model-calibration code and run assets.
- `notes/`: pre-paper and supporting notes (design memos, experiment notes, verification notes).

## Canonical latest files

- In `drafts/` (no version suffix):
  - `<paper_title_slug>.lyx`
  - `<paper_title_slug>.pdf`
- In `slides/` (no version suffix):
  - `<paper_title_slug>_slides.lyx`
  - `<paper_title_slug>_slides.pdf`

## Technical TeX location

- Keep TeX exports out of the visible root draft/slide folders.
- Store TeX files in:
  - `drafts/old_drafts/source_tex/`
  - `slides/old_slides/source_tex/`
- Keep build artifacts in:
  - `drafts/old_drafts/build_artifacts/`
  - `slides/old_slides/build_artifacts/`

## Archive rule

- Do not create version folders unless explicitly requested by the user.
- Version snapshots go only in:
  - `drafts/old_drafts/vNNN/`
  - `slides/old_slides/vNNN/`
- On version start, copy current latest files into `vNNN`, add `_vNNN` suffix to copied files, then continue editing only unversioned latest files.
- Do not keep multiple loose draft/slide versions in project root folders.
