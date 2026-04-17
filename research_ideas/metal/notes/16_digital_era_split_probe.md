# 16 Digital-era split probe

Last updated: 2026-03-30
Status: descriptive robustness check

## Question

Do the headline local scene coefficients weaken once digital access frictions fall?

This is not a clean identification design for the causal effect of the internet. It is a period
split probe meant to see whether the preferred scene result looks materially different in an early
period, a transition period, and a later digital period.

## Design

- Reuse the preferred `roll-5` exact-year fixed-effects scene specification.
- Keep the preferred core predictors:
  - overall active bands
  - nontrivial communities
  - overall multi-band musicians
  - local spawning flow
  - target-genre active bands
  - target-genre multi-band musicians
- Split the sample into:
  - `<= 1994`
  - `1995-2004`
  - `2005-2014`

Outputs:

- `data/processed/scene_networks/scene_digital_era_split_results.csv`
- `data/processed/scene_networks/scene_digital_era_split_summary.md`

## Sample sizes

- `<= 1994`: `16,396` city-genre-years, `560` emergence events
- `1995-2004`: `57,465` city-genre-years, `1,540` emergence events
- `2005-2014`: `78,508` city-genre-years, `2,398` emergence events

## Headline coefficients

| Predictor | <=1994 | 1995-2004 | 2005-2014 |
|---|---:|---:|---:|
| Local spawning flow | `0.0177***` | `0.0141***` | `0.0071**` |
| Target-genre active bands | `0.0977***` | `0.0422***` | `0.0310***` |
| Target-genre multi-band musicians | `0.0270***` | `0.0312***` | `0.0325***` |

## Current read

- The local spawning term attenuates over time.
- The target-genre active-band stock term also attenuates materially from the pre-1995 period to
  the later sample.
- The target-genre multi-band-musician term does **not** attenuate. If anything, it stays stable
  or slightly strengthens.

## Interpretation

The cleanest read is not that digitization made local scenes irrelevant. It is that some margins of
local thickness appear weaker in later periods, while within-genre overlapping worker depth remains
important. That is consistent with an environment in which recorded music and information become
easier to access remotely, but local recombination and project overlap still matter for scene
formation.

This should stay a descriptive robustness check, not a causal internet result. The period cutoffs
are broad and imperfect, and many other things change across these eras besides online access.
