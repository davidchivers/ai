# 26 Breakout candidate audit

Last updated: 2026-04-09
Status: branch feasibility audit after taxonomy correction

## Why this note exists

The breakout-demand branch now has two different screening layers:

1. the original conceptual screen in `notes/24_breakout_episode_screen.md`
2. a live operational audit against the actual `city x genre_family x year` scene panel

The operational audit matters because some conceptually attractive treatment rows do not survive
contact with the scene data. The clearest example is `extreme_metal`: it can make sense on the
treatment side, but it is not a live family in the current scene panel.

The current audit outputs are:

- `data/processed/country_genre_analysis/breakout_event_candidate_audit.csv`
- `data/processed/country_genre_analysis/breakout_event_candidate_audit.md`

## Audit rule

The audit starts from a narrow treatment universe:

- chart-led top-10 rows only
- live scene-taxonomy families only
- non-`heavy_metal` rows only

Then it asks four practical questions for each candidate:

1. is this the **first** chart-led breakout for that `market x genre_family`?
2. does the event window contain any local same-genre starts?
3. is there any positive pre-shock focal capability in the city panel?
4. if the row looks good, is it still a first-breakout row rather than a later repeat?

## Current operational result

The audit retains four first-breakout rows for the live branch:

1. `DEU x industrial_metal x 2001`
   `Rammstein - Mutter`
2. `DEU x symphonic_metal x 2004`
   `Nightwish - Once`
3. `FIN x symphonic_metal x 2004`
   `Nightwish - Once`
4. `DEU x power_metal x 2012`
   `Sabaton - Carolus Rex`

These are retained because they are all first-breakout rows under the chart-led rule and all have
at least some non-flat pre-shock focal capability in the live city panel.

## What got parked

### 1. Conceptual but taxonomy-incompatible rows

The `Sepultura - Roots` rows remain interesting as conceptual legitimation episodes, but they are
parked because `extreme_metal` is not a live scene-panel family.

### 2. Flat-capability first-breakout rows

Some rows are first breakouts in treatment space but still look weak in the live city panel:

- `AUS x industrial_metal x 2022`
- `GBR x industrial_metal x 2022`
- `SWE x power_metal x 2022`

These are parked because the current pre-shock city panel shows zero positive focal capability,
which kills the branch's core heterogeneity margin before estimation even starts.

### 3. Later repeats

Some rows are empirically richer than the retained first breakouts but violate the branch design:

- `DEU x power_metal x 2016`
- `DEU x power_metal x 2018`

Those rows are now explicitly parked as **later repeats**, not as candidate first-breakout
events.

## Practical implication

This branch is now cleaner than it was, but also more bounded.

The current operational stack is:

- no longer taxonomy-confused
- no longer silently mixing first breakouts with later repeats
- still thin enough that the branch should be treated as a feasibility workflow rather than as a
  regression-ready causal paper

So the current order is:

1. keep the operational event file tied to the four retained first-breakout rows
2. rebuild the branch panel and capability file from that stack
3. use descriptive event-time checks before writing any event-study regression code

If those descriptive checks look bad, stop the branch early rather than widening the event file
just to rescue it.

## Current descriptive gate

That descriptive gate has now been run in:

- `data/processed/country_genre_analysis/breakout_branch_descriptive_event_time.csv`
- `data/processed/country_genre_analysis/breakout_branch_descriptive_event_summary.csv`
- `data/processed/country_genre_analysis/breakout_branch_descriptive_summary.md`

The current read is cautious rather than encouraging:

- the branch has only `49` positive-capability city-event cells at `t = -1`
- the pre-period gap is already large
- the positive-capability margin is partly dominated by `DEU x power_metal x 2012`

So the branch is now operationally clean, but it has **not** cleared the descriptive gate for
event-study estimation yet. Under the current workflow, the next move is not regression. It is
either:

1. find more first-breakout events with non-flat pre-shock capability
2. or stop the branch at feasibility stage
