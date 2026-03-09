# data_laptop

Purpose: isolated, update-in-place workspace for local motivation-data pulls and related literature notes for `01_Necessity_Entrepreneurs`.

Why this exists:
- keep data and figure work separate from the canonical project status pipeline while the main experiment flow is sensitive,
- make local updates visible in one place,
- preserve a reproducible trail for any motivation figures added later to the draft or slides.

Scope for the current pass:
- build a clean annual US time series for business counts by employment size,
- use a compatible `0 employees` proxy from Census Nonemployer Statistics,
- use Census Business Dynamics Statistics establishment-size series for employer bins,
- add recession tagging from FRED/NBER-style recession indicator data,
- write a short literature review note on firm creation over the business cycle.

Rules for this folder:
- do not treat this folder as the canonical project plan or status source,
- do not edit `STATUS.md` from this workflow unless the main pipeline issue is resolved,
- prefer official US data sources and save reproducible scripts alongside outputs,
- track each material step in `work_log.md`.

Deferred checks to track here:
- literature review verification check:
  - before any sidecar prose is promoted into the main draft, re-check each literature citation used in the transplant intro and sidecar review for exact title, journal, year, and fit to the paper,
  - keep this as a `data_laptop/` task for now and do not treat it as completed.

Expected artifacts:
- `pull_us_business_size_cycle_data.py`
- `us_business_counts_by_size_annual.csv`
- `us_business_counts_by_size_indexed.png`
- `us_business_counts_by_size_levels.png`
- `us_business_counts_by_size_shares.png`
- `us_business_counts_aggregate_indexed.png`
- `recession_window_changes.csv`
- `recession_window_changes.md`
- `aggregate_recession_window_changes.tex`
- `pull_us_self_employment_companion.py`
- `us_self_employment_rates_monthly.csv`
- `us_self_employment_rates_annual.csv`
- `us_self_employment_rates_annual.png`
- `self_employment_recession_windows.md`
- `self_employment_vs_nonemployer_note.md`
- `pull_us_business_applications_companion.py`
- `us_business_applications_monthly.csv`
- `us_business_applications_annual.csv`
- `us_business_applications_indexed.png`
- `business_applications_recession_windows.md`
- `business_applications_companion_note.md`
- `gem_measurement_note.md`
- `pull_gem_us_motive_microdata.py`
- `us_gem_tea_motive_shares_2019_2021.csv`
- `us_gem_tea_motive_shares_2019_2021_long.csv`
- `us_gem_tea_motive_shares_2019_2021.png`
- `us_gem_jobs_income_overlap_2019_2021.csv`
- `us_gem_jobs_income_overlap_2019_2021_long.csv`
- `us_gem_jobs_income_overlap_2019_2021.png`
- `gem_us_microdata_note.md`
- `necessity_entrepreneurship_intro_motivation_sidecar.lyx`
- `necessity_entrepreneurship_intro_transplant.tex`
- `necessity_entrepreneurship_intro_transplant_preview.tex`
- `necessity_entrepreneurship_intro_transplant_preview_refs.bib`
- `necessity_entrepreneurship_intro_transplant_preview.pdf`
- `handover_note.md`
- `firm_creation_business_cycle_literature_review.md`
- `firm_creation_business_cycle_literature_matrix.csv`
- `motivation_framing_note.md`
- `work_log.md`
