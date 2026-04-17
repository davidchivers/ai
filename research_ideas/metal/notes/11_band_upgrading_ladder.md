# 11 Band upgrading ladder

Last updated: 2026-03-27
Status: active sidecar redesign note

## Why this note exists

The original sidecar question was too vague: do bands founded in thicker local scenes later become
successful? That was a reasonable first pass, but the current data make the weaknesses clear.

- the observed success lags are often very long
- legacy bands dominate the matched success file
- `ever successful` is not a disciplined outcome
- raw foreign-market appearance is not always a later stage than home-market validation

So the sidecar now needs to be thought of less as a generic `band success` question and more as a
staged upgrading workflow.

The key economics question becomes:

Do thicker local scene cohorts produce validated winners and, in some cases, later cross-market
crossover?

## Preferred ladder

The cleaner ladder from the current audited market file is:

1. `home_market_presence`
   Any audited home-market chart or certification visibility.
2. `home_market_validation`
   A stronger home-market success threshold: audited top-10 or certification visibility.
3. `foreign_market_crossover`
   Any audited foreign-market visibility.
4. `validated_then_foreign`
   A stricter crossover object where foreign-market visibility happens after or at the
   home-validation year.

This is better than talking about a `breakout band` because it makes the thresholds explicit and
lets the foreign side be treated as a second stage rather than folded into one fuzzy outcome.

## Preferred unit

The active sidecar object should now be:

- `city x genre_family x formed_year` cohort

not:

- naive `band x ever successful`

The paper is about scenes as local innovation systems. So the natural sidecar question is whether a
local founding cohort produces a winner within a bounded horizon, not whether a single legacy band
eventually appears in an audited success file decades later.

## Working files

The current ladder build is:

- `code/47_build_band_upgrading_ladder_sidecar.py`
- `data/processed/band_success/band_upgrading_ladder_outcomes.csv`
- `data/processed/band_success/city_genre_birth_cohort_upgrading_panel.csv`
- `data/processed/band_success/city_genre_birth_cohort_upgrading_pilot.csv`
- `data/processed/band_success/band_upgrading_ladder_summary.md`

The ladder uses the already-built birth and scene merge objects from:

- `code/38_build_band_success_sidecar_data.py`
- `data/processed/band_success/band_scene_at_birth_panel.csv`
- `data/processed/band_success/band_success_outcomes.csv`

## Current read

### Matched band counts

- audited home-market countries in the current ladder:
  `BRA`, `DEU`, `FIN`, `FRA`, `GBR`, `ITA`, `NOR`, `SWE`, `USA`
- success artists with audited home-market rows: `17`
- matched onto the birth panel: `16`
- median gap from founding to first home-market presence: `16.5` years

### Matched ladder stages

- `16` bands reach home-market presence
- `13` bands reach home-market validation
- `12` bands reach foreign-market presence
- only `5` satisfy the stricter `validated_then_foreign` ordering

### Bounded timing read

- within `10` years:
  - `3` home-market validation cases
  - `2` validated-then-foreign cases
- within `15` years:
  - `5` home-market validation cases
  - `3` validated-then-foreign cases
- within `20` years:
  - `8` home-market validation cases
  - `3` validated-then-foreign cases

### Cohort object

- audited cohort rows: `57,756`
- cohorts producing home-market validation within `15` years: `5`
- cohorts producing validated-then-foreign crossover within `20` years: `3`

## Interpretation

This redesign is conceptually better than the earlier `ever successful` pilot, but it is still too
sparse for a serious regression branch right now.

The main gain is not statistical power. The main gain is that the sidecar now has a coherent
estimand:

- first-stage outcome:
  did this local founding cohort produce a home-market validated band within `H` years?
- second-stage outcome:
  conditional on local validation, did it later produce foreign crossover?

That reads much more naturally as economics of creative upgrading than as music-history lore.

## What not to do

- do not run a naive full-sample `band x ever successful` regression
- do not treat raw foreign-market appearance as a clean later stage
- do not interpret current `unsigned_i` as historical contract status
- do not let this sidecar replace the main `scene -> genre emergence` paper

## Next concrete task

If this branch is revisited, the right next step is:

1. lock one bounded cohort winner outcome, likely `home_market_validation_within_15y`
2. decide whether the sample should be restricted to later cohorts or audited home markets only
3. run descriptive cohort-winner gradients before any regression
4. keep `validated_then_foreign` as a strict second-stage extension, not the first sidecar outcome
