# 25 Breakout branch workflow

Last updated: 2026-04-09
Status: active branch workflow note

## Why this workflow exists

The breakout-demand branch is now real enough to need an ordered workflow. It should still be
treated as a branch, not as a replacement for the main scene-emergence paper.

The purpose of this note is to stop the branch from drifting into:

- a loose collection of candidate albums
- a coarse `country x genre_family` FE rerun
- or an open-ended treatment-cleaning exercise with no stop rule

The branch question is narrower:

- when a clean national breakout event occurs, do higher-capability cities in that country-genre
  respond more strongly afterward?

## Active branch order

1. Lock the first-pass breakout events.
2. Build the event file, not a bigger general treatment file.
3. Build the stacked city-genre event panel.
4. Freeze pre-shock capability before estimation.
5. Run descriptive event-time gradients before any regression.
6. Estimate the stacked differential-response event study.
7. Stop quickly if the branch fails the pre-specified decision rule.

## Phase 1: lock the first-pass events

Use:

- `notes/24_breakout_episode_screen.md`
- `data/processed/country_genre_analysis/breakout_episode_candidates.csv`
- `notes/26_breakout_candidate_audit.md`
- `data/processed/country_genre_analysis/breakout_event_candidate_audit.csv`

The first-pass event set should stay deliberately small. The current screened priority order is:

1. `DEU x extreme_metal x 1996`
2. `GBR x extreme_metal x 1996`
3. `ITA x extreme_metal x 1996`
4. `DEU x industrial_metal x 2001`
5. `DEU x symphonic_metal x 2004`

The current operational audit now retains five first-breakout events in the live stack:

1. `DEU x industrial_metal x 2001`
2. `DEU x symphonic_metal x 2004`
3. `FIN x symphonic_metal x 2004`
4. `DEU x power_metal x 2012`
5. `SWE x power_metal x 2012`

The `extreme_metal` rows stay in the screen as conceptually interesting treatment events, but
they should not enter the operational branch file until a transparent genre bridge exists.

Likewise, later German power-metal hits in `2016` and `2018` are now explicitly parked as
operationally richer **later repeats**, not first-breakout rows.

Do not expand beyond the compatible operational stack until the stacked branch has been tested
once.

## Phase 2: build the clean breakout-event file

Create one branch-specific event file with one row per retained breakout episode.

Target file:

- `data/processed/country_genre_analysis/breakout_event_file.csv`

Required fields:

- `event_id`
- `market_code`
- `country_name`
- `primary_genre`
- `artist_name`
- `album_title`
- `event_year`
- `event_date_raw`
- `timing_precision`
- `source_name`
- `event_tier`
- `screen_read`

This file should be branch-specific and stable. Do **not** use the whole blockbuster treatment
file as the live branch input once this object exists.

Before loading any event into this file, validate that `primary_genre` exists in the live scene
taxonomy. Unsupported genres stay in the screen note, not in the operational event file.

## Phase 3: build the stacked city-genre event panel

Create one stack per breakout episode.

Target file:

- `data/processed/country_genre_analysis/city_genre_breakout_event_panel.csv`

Preferred unit:

- `city x primary_genre x relative_event_year x event_id`

Preferred event window:

- `-5` to `+5`

Required fields:

- event identifiers
- city identifiers
- focal genre
- relative year
- calendar year
- local same-genre band starts
- local active same-genre band stock
- local same-genre spawning flow
- pre-emergence flag
- already-emerged flag

This should be a branch panel, not a repurposed main-paper file.

## Phase 4: freeze pre-shock capability

Build one capability file before running any event study.

Target file:

- `data/processed/country_genre_analysis/city_genre_breakout_capability.csv`

Measure capability using pre-shock values only:

- target-genre active bands
- target-genre multi-band musicians

Preferred branch implementation:

- freeze capability at `t = -1`
- also compute a simple average over `t = -3` to `t = -1` as a robustness variant

Add simple bins:

- `low_capability`
- `mid_capability`
- `high_capability`

The first pass should probably focus on:

- cities below the emergence threshold before the breakout event

That keeps the branch from just re-reading already-mature hubs.

## Phase 5: run descriptive checks before regressions

Before any regression, build a simple branch summary note.

Target file:

- `data/processed/country_genre_analysis/breakout_branch_descriptive_summary.md`

Minimum checks:

1. number of events in the stack
2. number of countries and cities covered
3. event-time means for high-capability vs low-capability cities
4. whether high-capability cities are already exploding before `t = 0`
5. whether one event dominates the whole branch

If the descriptive read already looks bad, stop here.

## Phase 6: estimate the stacked event study

Only after the descriptive check looks credible, build the first regression outputs.

Target files:

- `data/processed/country_genre_analysis/breakout_branch_event_study_results.csv`
- `data/processed/country_genre_analysis/breakout_branch_event_study_summary.md`
- `data/processed/country_genre_analysis/breakout_branch_event_study.png`

First-pass regression object:

- differential post-breakout response for `high_capability` vs `low_capability` cities

Preferred first outcomes:

1. local same-genre band starts
2. change in local active same-genre band stock
3. local same-genre spawning flow

Secondary outcome:

4. operational emergence among pre-emergence cities only

## Phase 7: branch decision rule

The branch survives only if all of the following are true:

1. the first-pass events still look defensible after the event file is built
2. pre-trends are not visibly explosive
3. high-capability cities respond more than low-capability cities after breakout
4. the result is not entirely driven by one event

If any of those fail, stop. Do not keep adding more markets or more treatment rows just to rescue
the branch.

## What is parked for now

- `USA`
- `BRA`
- certification-led timing
- most mature `heavy_metal` episodes
- late modern-only Australian events as headline evidence
- any attempt to fold this branch back into the live field-paper draft

## Practical next task

The branch objects now exist. The next maintenance step is therefore:

1. keep `breakout_event_file.csv` limited to scene-taxonomy-compatible events
2. rebuild `city_genre_breakout_event_panel.csv`
3. rebuild `city_genre_breakout_capability.csv`
4. check the descriptive summary before any event-study code is written

That descriptive gate has now been run for both:

- the strict top-10 first-breakout stack
- a secondary relaxed `peak <= 20` first-breakout stack

The relaxed extension is documented in `notes/27_breakout_peak20_relaxed_extension.md`. It expands
the stack meaningfully, but it still fails the descriptive gate under the current workflow.

The breakout-event file now exists at:

- `data/processed/country_genre_analysis/breakout_event_file.csv`

Everything else in this branch should now follow from the rebuilt event panel and capability file.
