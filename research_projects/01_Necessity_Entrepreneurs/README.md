# 01_Necessity_Entrepreneurs

Canonical status tracker: `projects/01_necessity_entrepreneurs/STATUS.md`

## Project type

Paper-phase project (active draft + referee workflow).

## Where key files go

- Latest paper PDF: `projects/01_necessity_entrepreneurs/drafts/necessity_entrepreneurship.pdf`
- Latest draft LyX: `projects/01_necessity_entrepreneurs/drafts/necessity_entrepreneurship.lyx`
- Draft TeX export archive: `projects/01_necessity_entrepreneurs/drafts/old_drafts/source_tex/necessity_entrepreneurship.tex`
- Latest slides PDF: `projects/01_necessity_entrepreneurs/slides/necessity_entrepreneurship_slides.pdf`
- Latest slides LyX: `projects/01_necessity_entrepreneurs/slides/necessity_entrepreneurship_slides.lyx`
- Slides TeX export archive: `projects/01_necessity_entrepreneurs/slides/old_slides/source_tex/necessity_entrepreneurship_slides.tex`
- Referee material: `projects/01_necessity_entrepreneurs/referee/`
- Calibration code: `projects/01_necessity_entrepreneurs/calibration/`
- Notes and pre-paper artifacts: `projects/01_necessity_entrepreneurs/notes/`
- Literature PDFs: `projects/01_necessity_entrepreneurs/literature/`

## Folder structure

```
01_Necessity_Entrepreneurs/
  README.md
  STATUS.md
  memory.md
  notes/               # notes, experiment checklists, citation verification docs
  drafts/              # latest paper files (no version suffix)
    necessity_entrepreneurship.pdf
    necessity_entrepreneurship.lyx
    old_drafts/
      vNNN/            # created only when explicitly requested
      source_tex/      # archived tex exports
      build_artifacts/ # aux/log/bibtex outputs
  slides/              # latest slide files (no version suffix)
    necessity_entrepreneurship_slides.pdf
    necessity_entrepreneurship_slides.lyx
    old_slides/
      vNNN/            # created only when explicitly requested
      source_tex/      # archived tex exports
      build_artifacts/ # aux/log/bibtex outputs
  referee/             # referee response + audits
  calibration/         # model calibration code and runs
  figures/             # paper figures and generators
  literature/          # reference PDFs + checklist
```

## Working rule

- Keep only latest unversioned files in `drafts/` and `slides/`.
- Create `old_drafts/vNNN` or `old_slides/vNNN` only when the user explicitly says to start a new version.
- Keep legacy snapshots in `drafts/old_drafts/` or `_playground/backups/`.
