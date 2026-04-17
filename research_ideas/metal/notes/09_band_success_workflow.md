# 09 Band success workflow

Last updated: 2026-03-27
Status: first-pass sidecar design note

This note now records the original band-level pilot. The active redesign note is:

- `notes/11_band_upgrading_ladder.md`

## Why this branch exists

The current scene paper answers one important question: do thicker local creative clusters make
later `city x genre_family` emergence more likely? But that is not the only economics question in
the data. A second question is whether scenes also create successful projects inside those local
clusters. In plain terms: not just `scene -> genre emergence`, but `scene -> band success`.

That extension is attractive because it is still about creativity and innovation rather than music
lore. It moves the project from category formation alone toward project success inside
project-based creative industries.

The right framing is:

- scenes create local labor pools
- scenes increase recombination and spinouts
- some projects founded inside those thick scenes later break out

So the live use of this branch is not to replace the scene paper. It is to test whether the same
scene conditions that predict genre emergence also predict later flagship success at the band
level.

## Core empirical question

Do bands founded in thicker local scenes become more likely to achieve later visible success?

The clean economic interpretation is:

- unit of production: the band
- workers: musicians
- local cluster: the city-level scene
- outcome: later project success

## Preferred design

### Unit of observation

Band `b`, observed either:

- once at birth, using scene conditions in the founding year or just before it
- or in an early-life panel such as the first `3` or `5` years after founding

The low-risk first pass should be a birth-cohort design, not a long panel.

### Baseline predictors

Use the scene variables we already trust most:

- overall active local bands
- nontrivial local communities
- local spawning flow
- target-genre active bands
- target-genre multi-band musicians

These predictors already live in the scene workflow, so the new step is mostly a merge problem,
not a new conceptual build.

### Preferred outcome hierarchy

The success variable has to be historically credible. The best ranking with current data is:

1. `later_home_market_presence_i`
   first visible home-market success from the curated chart or certification file
2. `later_home_market_certification_i`
   stronger but thinner
3. `later_home_market_top10_i`
   cleanest blockbuster rule but probably too sparse for the first band-level pass

Current label status should not be the headline success outcome. It is too noisy and too
contemporaneous for this use.

## Proposed first-pass specification

Let `Success_b` denote whether band `b` later achieves visible home-market success under one of the
outcome rules above. Let `SceneAtBirth_b` denote local scene conditions at founding. Then the
first disciplined band-level regression is:

$$
Success_b = \alpha_{country,decade} + \lambda_{genre} + \beta_1 SceneAtBirth_b + \gamma X_b + \varepsilon_b,
$$

where `X_b` can include:

- founding-year controls
- city size controls
- broad genre-family controls

The reduced-form interpretation is modest: do bands born into thicker local scenes become more
likely to break out later?

## Data objects to build

The workflow should build three explicit files.

### 1. Band birth panel

Create a single `band x birth year` file with:

- `band_id`
- `band_name`
- `city`
- `country`
- `city_country`
- `formed_year`
- `genre_family`

Likely source:

- `data/processed/metal_archives_all_metal_band_clean.csv`

### 2. Scene-at-birth merge

Merge founding-year or lagged founding-year scene predictors onto each band:

- city-year scene measures from the existing scene panel
- target-genre scene measures from the `city x genre x year` scene files

Likely sources:

- `data/processed/scene_networks/city_year_network_snapshots.csv`
- `data/processed/scene_networks/city_year_scene_cluster_richer_features.csv`
- `data/processed/scene_networks/city_genre_scene_cluster_richer_features.csv`

### 3. Band success outcomes

Build a band-level success flag file using the already-built chart and certification workflow.

Likely sources:

- `data/processed/blockbuster_album_country_hits_core.csv`
- `data/processed/blockbuster_band_influence_event_windows.csv`
- `data/processed/blockbuster_band_influence_ranking.csv`

The first version can be narrow and incomplete. It only needs a credible pilot sample for bands
that later appear in the curated breakthrough file.

## Immediate workflow

This should run in a strict order.

1. Build `band_birth_panel.csv`.
   Keep only bands with usable city, year, and broad genre-family coding.
2. Build `band_scene_at_birth_panel.csv`.
   Merge city-year and target-genre scene conditions into the birth panel.
3. Build `band_success_outcomes.csv`.
   Flag later home-market `presence`, `certification`, and `top10` success for bands already in
   the curated event workflow.
4. Run a descriptive pilot before any heavier model.
   Compare later success rates across bins of founding-year scene thickness and target-genre depth.
5. Only then estimate a simple band-level reduced-form success regression.

## Current pilot read

The first actual sidecar build now exists in:

- `code/38_build_band_success_sidecar_data.py`
- `data/processed/band_success/band_birth_panel.csv`
- `data/processed/band_success/band_scene_at_birth_panel.csv`
- `data/processed/band_success/band_success_outcomes.csv`
- `data/processed/band_success/band_success_match_diagnostics.csv`
- `data/processed/band_success/band_success_coverage_audit.csv`
- `data/processed/band_success/band_success_descriptive_pilot.csv`
- `data/processed/band_success/band_success_design_audit.md`
- `data/processed/band_success/band_success_sidecar_summary.md`

Current read from that pilot:

- the mechanical merge works:
  - `128,053` birth-panel rows
  - `67,572` exact pre-birth scene matches at `formed_year - 1`
- home-market success coverage is now materially wider:
  - `17` curated home-market success artists survive the conservative name screen
  - `16` match onto the birth panel
  - `5` have home-market certification signals
  - `9` have home-market top-10 signals
- the name matching needed an explicit audit even at this small scale:
  - `Rhapsody` is mapped to `Rhapsody of Fire`
  - obvious homonym collisions `Disturbed` and `Slipknot` are excluded
  - `Rammstein` stays unmatched because it does not land on a usable Metallum birth row
- the coverage expansion changed the branch diagnosis:
  - Finland, Sweden, France, and Norway now contribute audited home-market success rows
  - the audited home-market countries are now:
    `BRA`, `DEU`, `FIN`, `FRA`, `GBR`, `ITA`, `NOR`, `SWE`, `USA`
- but the design audit still warns against a naive all-band birth regression:
  - median gap from founding to first observed home-market success is `16.5` years
  - only `5` presence cases arrive within `10` years of founding
  - only `7` arrive within `15` years
- the descriptive bins are still not decision-grade:
  - success rates are extremely small
  - they are not monotonically stronger in thicker scene bins under the current broad all-band sample

So the current status is now clearer than before: this branch is real as a data workflow and now
has meaningful home-market coverage, but it is still not ready for a naive full-sample birth
regression.

## What would count as a useful pilot

The first pilot does not need to settle the question. It only needs to answer whether this branch
is worth deeper investment.

The branch looks worth keeping if:

- bands founded in thicker target-genre scenes are visibly more likely to achieve later success
- the result is strongest for `presence` and maybe still visible for `certification`
- the signs line up with the existing scene-emergence paper

The branch should stay secondary if:

- outcome coverage is too sparse even under `presence`
- success cases are too concentrated in a handful of countries or decades
- the band-level merge introduces too much location or timing noise

## Role in the overall project

This branch should be treated as:

- a sidecar to the current scene paper
- a natural follow-on result if the pilot works
- a possible bridge between `scene formation` and `project success`

It should not be treated as:

- a replacement for the current `scene -> genre emergence` result
- a reason to reopen the weak old current-label proxy
- a reason to abandon the economics-first scene framing

## Next concrete task

Do not push this original band-level setup directly into regression. The active next-step redesign
is now:

- `notes/11_band_upgrading_ladder.md`

That redesign moves the sidecar from vague `later band success` toward a staged cohort winner
object:

- bounded home-market validation first
- stricter foreign crossover second
- `city x genre_family x formed_year` as the preferred unit rather than naive band-level `ever
  successful`
