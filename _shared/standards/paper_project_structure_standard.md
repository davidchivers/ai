# Paper Project Structure Standard

Use this structure for paper-phase projects.

Folder naming rule: use `lowercase_with_underscores` for all folders in the project tree.

## Standard top-level folders

Create the applicable folders when the project needs them; do not add empty placeholders merely to satisfy the layout.

- `drafts/`: latest visible paper source and PDF.
- `slides/`: latest visible slide source and PDF.
- `literature/`: reference PDFs and checklist files.
- `referee/`: response files, issue trackers, and audits tied to a live referee round.
- `audits/`: reusable code-paper, math, evidence, and replication audits that are not tied to a live referee round; create lazily.
- `calibration/`: model-calibration code and run assets.
- `notes/`: pre-paper and supporting notes (design memos, experiment notes, verification notes).

## Canonical latest files

- In `drafts/` (no version suffix):
  - one authoritative editable source: `<paper_title_slug>.lyx` or `<paper_title_slug>.tex`
  - `<paper_title_slug>.pdf`
- In `slides/` (no version suffix):
  - one authoritative editable source: `<paper_title_slug>_slides.lyx` or `<paper_title_slug>_slides.tex`
  - `<paper_title_slug>_slides.pdf`
- Record the authoritative format in `README.md` or `memory.md`. Do not maintain two competing editable sources.

## Generated TeX and build-artifact locations

- If LyX is authoritative, keep generated TeX exports out of the visible draft/slide folders. Store them in:
  - `drafts/old_drafts/source_tex/`
  - `slides/old_slides/source_tex/`
- If TeX is authoritative, keep the canonical `.tex` file beside the canonical PDF in `drafts/` or `slides/`.
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
