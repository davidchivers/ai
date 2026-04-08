# data handover note

Status: ready for sidecar handoff on 2026-03-08.

## What is ready now

- Main visual motivation pair:
  - `us_business_counts_by_size_indexed.png`
  - `us_business_applications_indexed.png`
- Main transplant text:
  - `necessity_entrepreneurship_intro_transplant.tex`
  - `data_section_transplant.tex`
- Current preview:
  - `necessity_entrepreneurship_intro_transplant_preview.pdf`
- Main sidecar literature files:
  - `firm_creation_business_cycle_literature_review.md`
  - `firm_creation_business_cycle_literature_matrix.csv`

## Recommended framing

- Lead with the identification problem:
  - necessity entrepreneurship is latent and not directly observed in standard data.
- Use recession evidence as motivation, not definition.
- Keep the preferred figure pair as:
  - size-bin business counts,
  - business applications / high-propensity applications.
- Use GEM in prose, not as a main-text figure.
  - The useful GEM point is that necessity and opportunity signals overlap within the same early-stage entrepreneurs.

## GEM lock

- Public U.S. GEM APS microdata are working for `2019-2021`.
- Main outputs:
  - `us_gem_tea_motive_shares_2019_2021.csv`
  - `us_gem_jobs_income_overlap_2019_2021.csv`
  - `gem_us_microdata_note.md`
- Recommended use:
  - cite the overlap fact in prose or a footnote.
- Do not use as a main figure by default:
  - `us_gem_tea_motive_shares_2019_2021.png`
  - `us_gem_jobs_income_overlap_2019_2021.png`

## Figure cautions

- The size-bin figure is a motivation figure, not decisive evidence.
- Reason:
  - it indexes series with very different levels,
  - it combines nonemployer establishments for `0 employees` with BDS employer establishment counts for positive-employment bins.
- The payoff is interpretability of the recession compositional shift, not exact unit comparability.
- Output split:
  - rough PNGs remain in `data/`,
  - final paper-facing `pgfplots` figure files now belong in `../figures/`.

## Writing lock

- The transplant intro has already had:
  - a literature-density pass,
  - an identification-first rewrite,
  - a local academic-paper-writer skill pass,
  - insertion of the two recession figures in place.
- The sidecar now also has a standalone data-section fragment:
  - `data_section_transplant.tex`
  - it keeps the current source priorities explicit:
    - business counts by size and business applications as the primary pair,
    - CPS self-employment and GEM as companion evidence.
- Main draft remains untouched.

## Still deferred

- Literature review verification check:
  - re-check exact title, journal, year, and fit for each citation before promoting any sidecar prose into the main draft.
- No update yet to:
  - `STATUS.md`
  - the canonical paper draft
  - the canonical research plan

## Build note

- Preview compilation works with:
  - `pdflatex`
  - `bibtex`
- `latexmk` is not the reliable route on this machine.
