# Data inventory

## Purpose

This note lists the empirical assets that already exist inside the project and sorts
them by what they can actually identify. The goal is to prevent two common mistakes:

- pretending a currently available public series can identify the full structural
  necessity object when it cannot,
- overlooking that the project already has enough local material to build a serious
  public-data fallback design if restricted microdata are not available soon.

## Tier 1: Data already in the project and usable now

### 1. Establishment counts by employment size

**Local files.**

- `data/us_business_counts_by_size_annual.csv`
- `data/us_business_counts_by_size_indexed.png`
- `data/us_business_counts_by_size_levels.png`
- `data/us_business_counts_by_size_shares.png`
- `figures/us_business_counts_by_size_indexed.tex`
- `figures/us_business_counts_by_size_shares.tex`

**Current scope.**

- Annual U.S. panel, `1997` to `2022`.
- Core columns include:
  - `establishments_0`
  - `establishments_1_4`
  - `establishments_5_19`
  - `establishments_20_plus`
  - `employer_total`
  - `establishments_all_bins`
  - shares and index versions
  - recession tags

**Unit of observation.**

- Establishments, not people and not firms.

**What it identifies well.**

- Composition of business activity across zero-employee and employer bins.
- Whether downturns shift activity toward the zero-employee margin.
- Whether larger employer bins contract more sharply.

**What it does not identify well.**

- Person-level entry into entrepreneurship.
- Whether the same individuals were pushed in by weak outside options.
- Whether a zero-employee business is a necessity project, an opportunity project, a
  side business, or a staging point before hiring.

**Use in the paper.**

- Strong motivation object.
- Good public-data outcome for a local-area composition design if state-level analogues
  can be built.

### 2. Business applications and high-propensity applications

**Local files.**

- `data/us_business_applications_monthly.csv`
- `data/us_business_applications_annual.csv`
- `data/us_business_applications_indexed.png`
- `figures/us_business_applications_indexed.tex`

**Current scope.**

- Monthly and annual U.S. panel.
- Core columns include:
  - `applications_total`
  - `applications_high_propensity`
  - `high_propensity_share`
  - recession tags

**Unit of observation.**

- Applications, not realized firms and not people.

**What it identifies well.**

- Flow-side business formation intensity.
- Relative strength of more employer-oriented or payroll-likely application activity.
- A useful contrast between total application volume and higher-propensity application
  composition.

**What it does not identify well.**

- Realized business creation one-for-one.
- Necessity versus opportunity at the applicant level.
- Post-entry scale or growth.

**Use in the paper.**

- Best current flow complement to the size-bin business-count figure.
- Strong candidate outcome in a public-data design centered on employer orientation of
  entry rather than on a direct necessity label.

### 3. CPS self-employment companion

**Local files.**

- `data/us_self_employment_rates_monthly.csv`
- `data/us_self_employment_rates_annual.csv`
- `data/us_self_employment_rates_annual.png`
- `figures/us_self_employment_rates_annual.tex`

**Current scope.**

- Annual U.S. panel, `2000` to `2022`, plus monthly companion.
- Core columns include:
  - `unincorporated_self_employed`
  - `incorporated_self_employed`
  - `self_employed_total`
  - `employment_total`
  - `rate_unincorporated`
  - `rate_incorporated`
  - `rate_total`

**Unit of observation.**

- People relative to total employment.

**What it identifies well.**

- Person-side self-employment rates.
- Distinction between incorporated and unincorporated self-employment.
- A useful check against establishment-side measures.

**What it does not identify well.**

- New entry versus continuing self-employment.
- Employer hiring or first payroll.
- Necessity versus opportunity.
- The same business-composition margin as the zero-employee establishment count.

**Use in the paper.**

- Companion evidence only.
- Valuable mainly because it shows that different empirical objects can move differently.

### 4. GEM motive microdata

**Local files.**

- `data/us_gem_tea_motive_shares_2019_2021.csv`
- `data/us_gem_jobs_income_overlap_2019_2021.csv`
- `data/us_gem_jobs_income_overlap_summary_2019_2021.tex`
- `figures/us_gem_jobs_income_overlap_2019_2021.tex`
- `data/gem_us_microdata_note.md`
- `data/gem_measurement_note.md`

**Current scope.**

- Weighted U.S. TEA sample for `2019` to `2021`.
- Overlap file includes:
  - `jobs_only_share`
  - `jobs_and_income_share`
  - `income_only_share`
  - `neither_jobs_nor_income_share`

**Unit of observation.**

- Early-stage entrepreneurs in a survey.

**What it identifies well.**

- Stated motives among actual early-stage entrepreneurs.
- Direct overlap between job-scarcity motives and income or wealth motives.
- Evidence that motive-based labels are not mutually exclusive.

**What it does not identify well.**

- Counterfactual occupational choice.
- Causal response to outside-option shocks.
- Growth, hiring, or post-entry scale.

**Use in the paper.**

- Introduction or framing evidence.
- Best role is to motivate the measurement problem, not to solve it.

## Tier 2: Internal model outputs already in the project that matter for the empirical bridge

### 5. Self-employment benchmark outputs

**Local files.**

- `notes/self_employment_experiment_matrix.csv`
- `figures/case147_mit_lowedu_sep010_irf.pdf`
- recent table fragments in `drafts/tables/`

**What they contribute.**

- A disciplined statement of what the model says should move:
  nonemployer share, employer share, average scale, and response to outside-option
  deterioration.

**Why they belong in an empirical inventory.**

- They tell us which empirical outcomes matter most:
  composition within entrepreneurship, not just total entry.

## Tier 3: High-value data that would materially improve identification, but are not currently in the project

### 6. Worker-to-business linked records

**What they would add.**

- Worker pre-entry employment history.
- Displacement or plant-closure exposure.
- Transition into business ownership.
- Separate observation of nonemployer versus employer entry.
- Early payroll, first-worker timing, and survival.

**Why they matter.**

- This is the cleanest route to estimating local necessity entry at the worker level.

**Current status.**

- Not currently present in the repository.
- Should be treated as the preferred but access-constrained path.

### 7. State or local panel versions of the current public series

**What they would add.**

- Cross-sectional variation in labor-demand shocks or UI policy.
- Much richer identification than a single national time series.

**Why they matter.**

- They turn the current sidecar from motivation into a plausible empirical design.

**Current status.**

- Not currently assembled in this folder, but conceptually closest to the data workflow
  already underway.

### 8. First-worker transition data

**What they would add.**

- Direct evidence on the hazard from nonemployer to employer.
- A cleaner bridge from "starts small" to "intended to grow" than initial size alone.

**Why they matter.**

- They address the key concern that even opportunity firms often start tiny.

## What this inventory implies

Three practical conclusions follow.

- The project already has a credible public-data motivation package.
- The project does not yet have a dataset that can literally classify all entrepreneurs
  as necessity or opportunity types.
- The clean empirical path is therefore either:
  a worker-level shock design with better linked data, or a public-data composition
  design that estimates how outside-option shocks move nonemployer-type versus
  employer-type outcomes.

## Recommended immediate use

Near-term empirical work should split into two lanes.

Lane 1:
push the current public sidecar toward a panel design with local variation.

Lane 2:
specify the exact linked-data wish list needed for the stronger worker-level design.

That way the project does not stall while waiting for perfect data access.
