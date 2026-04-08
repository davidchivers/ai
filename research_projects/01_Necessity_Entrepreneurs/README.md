# 01_Necessity_Entrepreneurs

Canonical status tracker: `research_projects/01_Necessity_Entrepreneurs/STATUS.md`

Coauthor handoff bundle: `research_projects/01_Necessity_Entrepreneurs/coauthor_handoff/`

## Project type

Paper-phase project (active draft + referee workflow).

## Current status

The benchmark self-employment package is currently the locked paper baseline. The March 13
write-up pass captured the corrected matched-control MIT recession figure, the literal
`2007-2009` recession-match scorecard, the title/framing refresh to `Outside Options and
Entrepreneurship`, and the current empirical decision to pursue the worker-displacement route
as the preferred external bridge.

Active follow-up is now narrower:

- keep the recession extension bounded unless one extra channel clearly resolves the
  extensive-margin versus firm-scale tradeoff;
- write the fixed-tax versus endogenous-tax `UI=0.05` / `UI=0.00` robustness comparison as
  an appendix object rather than a new main-text decomposition;
- continue empirical planning through the FSRDC scoping memo and fallback data wish list.

## Where key files go

- Latest paper PDF: `research_projects/01_Necessity_Entrepreneurs/drafts/necessity_entrepreneurship.pdf`
- Latest draft LyX: `research_projects/01_Necessity_Entrepreneurs/drafts/necessity_entrepreneurship.lyx`
- Draft TeX export archive: `research_projects/01_Necessity_Entrepreneurs/drafts/old_drafts/source_tex/necessity_entrepreneurship.tex`
- Latest slides PDF: `research_projects/01_Necessity_Entrepreneurs/slides/necessity_entrepreneurship_slides.pdf`
- Latest slides TeX: `research_projects/01_Necessity_Entrepreneurs/slides/necessity_entrepreneurship_slides.tex`
- Referee material: `research_projects/01_Necessity_Entrepreneurs/referee/`
- Calibration code: `research_projects/01_Necessity_Entrepreneurs/calibration/`
- Notes and pre-paper artifacts: `research_projects/01_Necessity_Entrepreneurs/notes/`
- Literature PDFs: `research_projects/01_Necessity_Entrepreneurs/literature/`

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
    necessity_entrepreneurship_slides.tex
    old_slides/
      vNNN/            # created only when explicitly requested
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

## Archive locations

- Draft compile outputs: `drafts/old_drafts/build_artifacts/`
- Slide compile outputs: `slides/old_slides/build_artifacts/`
- Archived figures and legacy visual assets: `figures/old/`
- Archived note build artifacts: `notes/old/`
- Bulky non-active project outputs retained for provenance: `data/archive/`
