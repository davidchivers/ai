# 27 Breakout peak-20 relaxed extension

Last updated: 2026-04-09
Status: secondary branch extension after the strict top-10 stack stayed too thin

## Why this note exists

The strict breakout branch was operationally clean, but it remained very small:

- `5` retained first-breakout events
- only `63` positive-capability city-event cells at `t = -1`

That was enough to justify one more structured probe just outside the original screen:

- keep the live scene taxonomy
- keep non-`heavy_metal` only
- keep first chart breakouts
- relax the chart threshold from top `10` to peak `20`

This note records what happens under that relaxed extension.

## Files

The relaxed extension now exists in parallel form:

- `data/processed/country_genre_analysis/breakout_event_candidate_audit_peak20.csv`
- `data/processed/country_genre_analysis/breakout_event_candidate_audit_peak20.md`
- `data/processed/country_genre_analysis/breakout_event_file_peak20_relaxed.csv`
- `data/processed/country_genre_analysis/city_genre_breakout_event_panel_peak20_relaxed.csv`
- `data/processed/country_genre_analysis/city_genre_breakout_capability_peak20_relaxed.csv`
- `data/processed/country_genre_analysis/breakout_branch_panel_summary_peak20_relaxed.md`
- `data/processed/country_genre_analysis/breakout_branch_descriptive_event_time_peak20_relaxed.csv`
- `data/processed/country_genre_analysis/breakout_branch_descriptive_event_summary_peak20_relaxed.csv`
- `data/processed/country_genre_analysis/breakout_branch_descriptive_summary_peak20_relaxed.md`

The scripts were also generalized so this can be reproduced without copy-paste workflows:

- `code/72_build_breakout_event_panel.py`
- `code/73_audit_breakout_event_candidates.py`
- `code/74_build_breakout_branch_descriptive_summary.py`

## What the relaxed screen adds

Relative to the strict top-10 branch, the relaxed peak-20 screen retains four extra
first-breakout rows:

1. `ITA x power_metal x 2002`
   `Rhapsody - Power of the Dragonflame`
2. `ITA x gothic_metal x 2006`
   `Lacuna Coil - Karmacode`
3. `ITA x symphonic_metal x 2007`
   `Nightwish - Dark Passion Play`
4. `GBR x power_metal x 2016`
   `Sabaton - The Last Stand`

So the relaxed retained stack is now:

1. `DEU x industrial_metal x 2001`
2. `ITA x power_metal x 2002`
3. `DEU x symphonic_metal x 2004`
4. `FIN x symphonic_metal x 2004`
5. `ITA x gothic_metal x 2006`
6. `ITA x symphonic_metal x 2007`
7. `DEU x power_metal x 2012`
8. `SWE x power_metal x 2012`
9. `GBR x power_metal x 2016`

## What improves

The relaxed screen is not empty hand-waving. It does materially improve branch support:

- retained events rise from `5` to `9`
- positive-capability city-event cells at `t = -1` rise from `63` to `153`
- zero-capability city-event cells rise from `7,640` to `11,438`

So the branch is **not** exhausted under the current treatment build. There is a real second layer
of candidate events once the chart cutoff is relaxed moderately.

## What does not improve enough

The key descriptive problem survives.

In the relaxed branch:

- mean same-genre band starts in event years `-5` to `-1` are already `0.1176` for
  positive-capability cities and `0.0015` for zero-capability cities
- in event years `0` to `+5`, the means are `0.0730` and `0.0024`
- `DEU x power_metal x 2012` still contributes the largest single block of positive-capability
  cities

The Italy read is also sharper now. The earlier relaxed stack carried `Lacuna Coil - Delirium`
in `2016` because `Comalies` looked like an official FIMI dead end and `Karmacode` was not yet
in the curated seed. Once `Karmacode` entered the live seed, the official FIMI page recovered a
real earlier first breakout for Italian gothic metal: entry `W14-2006`, peak `17`, and a run
reaching `20` weeks. That replacement adds support, but it also makes the pre-existing
positive-capability difference more visible rather than less.

The Swedish side is cleaner too. `Sabaton - Carolus Rex` now has an exact official home-market
row from Sverigetopplistan: first placement `W22-2012`, peak `2`, and a run reaching `31` weeks.
That moves the Swedish power-metal margin from the recovery list into the live strict and relaxed
stacks. It helps support counts, but it still does not solve the broader pretrend problem.

So the added events increase support, but they do not remove the basic problem:

- positive-capability cities are already very different before the breakout

That means the relaxed branch still does **not** clear the descriptive gate for event-study
estimation.

## Practical implication

The current project now has a clean strict-versus-relaxed branch map:

- strict top-10 first-breakout stack:
  cleaner but very thin
- relaxed peak-20 first-breakout stack:
  meaningfully larger, but still descriptively weak

So the live branch decision is now sharper:

1. if staying within the current treatment build, stop before regression
2. if pushing further, the next search should target more first-breakout rows with non-flat
   pre-shock capability rather than immediately estimating an event study

This is useful progress because it tells us the branch is not dead from data scarcity alone, but
it is still not disciplined enough to pretend the causal design is already working.

The ranked next-step recovery list now exists in:

- `notes/28_breakout_seed_recovery_targets.md`
- `data/processed/country_genre_analysis/breakout_seed_recovery_targets.csv`
