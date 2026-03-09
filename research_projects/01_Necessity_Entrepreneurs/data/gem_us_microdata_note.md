# GEM U.S. microdata note

Status: sidecar extract from official GEM APS individual-level public files.

Last updated: 2026-03-08

## What this file set is

- `us_gem_tea_motive_shares_2019_2021.csv`: wide annual summary for the United States.
- `us_gem_tea_motive_shares_2019_2021_long.csv`: long-format version for plotting.
- `us_gem_tea_motive_shares_2019_2021.png`: broad four-motive trend figure.
- `us_gem_jobs_income_overlap_2019_2021.csv`: overlap shares for jobs-scarce and high-income motives.
- `us_gem_jobs_income_overlap_2019_2021_long.csv`: long-format overlap version.
- `us_gem_jobs_income_overlap_2019_2021.png`: recommended figure for the introduction.
- `us_gem_jobs_income_overlap_summary_2019_2021.tex`: compact TeX summary table for prose or footnote use.
- `../figures/us_gem_jobs_income_overlap_2019_2021.tex`: optional paper-facing pgfplots figure.

## Data construction

- Source page: https://www.gemconsortium.org/data/sets
- Public APS individual-level files used: 2019, 2020, 2021.
- Country filter: `ctryalp == "US"` and `country_name == "United States"`.
- Entrepreneur filter: `TEAyy == 1`.
- Weights: `WEIGHT_A`.
- Motive variables:
  - `TEAyyMOT1yes`: make a difference in the world
  - `TEAyyMOT2yes`: build great wealth or a very high income
  - `TEAyyMOT3yes`: continue a family tradition
  - `TEAyyMOT4yes`: earn a living because jobs are scarce

## Interpretation cautions

- These are motive shares among early-stage entrepreneurs, not population shares.
- The four motives are not mutually exclusive, so the shares do not sum to 100.
- The overlap figure is the key reason the GEM evidence is informative: it shows that necessity and opportunity signals coexist within the same observed entrepreneurial spell.
- The jobs-scarce item is the cleanest public necessity-style motive in the current APS file.
- The public APS individual-level page currently exposes 2021 as the latest cleanly verifiable microdata release; 2022-2023 U.S. motive updates therefore still rely on report evidence rather than public respondent-level files.

## Why this matters for the paper

- This provides direct U.S. motive evidence from microdata rather than only report summaries.
- It supports opening the paper with the identification problem and then using recession evidence as a complementary, not exclusive, source of motivation.
- The most informative visual is the overlap between `jobs are scarce` and `high income / wealth`, not a generic four-line time-series chart.
- The compact TeX table is the easiest object to cite in the main text if we keep GEM as prose rather than as a headline figure.