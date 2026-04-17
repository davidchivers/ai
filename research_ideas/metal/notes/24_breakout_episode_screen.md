# Breakout episode screen

Last updated: 2026-04-09
Status: first screened candidate list for the breakout-demand branch

## Purpose

This note is the first operational screen for the breakout-demand branch. It does **not** claim
that these are final treatment events. It only asks a narrower question:

- which existing `country x genre_family` hit episodes are clean enough to try in the first branch

The corresponding candidate file is:

- `data/processed/country_genre_analysis/breakout_episode_candidates.csv`

## Screen rule

An episode is a first-pass candidate only if it satisfies most of the following:

1. chart-led rather than certification-led
2. timing is precise enough for event time
3. the genre-family link is easy to defend
4. the source is official or close to official
5. the event is not obviously just another hit inside a genre that is already fully mature in that
   market

This last condition is why the screen is much stricter than "earliest top-10 row in the file."
For example, many `heavy_metal` rows are real chart events but poor first-pass breakout episodes,
because heavy metal is already too mature in those markets for the event to read as a genre
activation shock.

## First-pass candidates

The strongest current conceptual first-pass episodes are:

1. `DEU x extreme_metal x 1996`
   `Sepultura - Roots`
2. `GBR x extreme_metal x 1996`
   `Sepultura - Roots`
3. `ITA x extreme_metal x 1996`
   `Sepultura - Roots`
4. `DEU x industrial_metal x 2001`
   `Rammstein - Mutter`
5. `DEU x symphonic_metal x 2004`
   `Nightwish - Once`

Why these survive:

- they are chart-led
- timing is precise enough for a stacked event study
- the genre-family match is fairly clean
- they are more plausibly read as national legitimation episodes than the mature `heavy_metal`
  cases

The strongest single market for a first branch is now clearly `DEU`, because it has multiple
screened candidates with official chart timing and non-mature genre families.

## Operational compatibility with the live scene taxonomy

Three of the conceptually strongest candidates use `extreme_metal` as the market-side genre
label. That is defensible on the treatment side, but it is not a live `genre_family` in the
current `city x genre_family x year` scene panel. The live panel splits that space into families
such as `black_metal`, `death_metal`, and `thrash_metal`.

So the branch now needs a clean distinction between:

- conceptual breakout candidates
- operational stack events that can be merged directly onto the live scene panel

The current operational stack therefore retains:

1. `DEU x industrial_metal x 2001`
   `Rammstein - Mutter`
2. `DEU x symphonic_metal x 2004`
   `Nightwish - Once`
3. `FIN x symphonic_metal x 2004`
   `Nightwish - Once`
4. `DEU x power_metal x 2012`
   `Sabaton - Carolus Rex`
5. `SWE x power_metal x 2012`
   `Sabaton - Carolus Rex`

The live operational audit for those additions now sits in:

- `notes/26_breakout_candidate_audit.md`
- `data/processed/country_genre_analysis/breakout_event_candidate_audit.csv`

The parked reserve events, if the branch needs more panel-compatible episodes later, are now:

1. `DEU x power_metal x 2016`
   `Sabaton - The Last Stand`
   Operationally non-flat, but it is a later repeat rather than the first German power-metal
   breakout.
2. `DEU x power_metal x 2018`
   `Powerwolf - The Sacrament of Sin`
   Same issue: stronger than the first breakout in some respects, but no longer valid under the
   branch's first-breakout rule.
3. `GBR x industrial_metal x 2022`
   `Rammstein - Zeit`
   First breakout row, but flat in pre-shock focal capability.
4. `AUS x symphonic_metal x 2020`
   `Nightwish - Human. :II: Nature.`
   First breakout row, but almost no pre-shock focal capability and zero event-window genre starts.

The three `Roots` rows stay in the screen as conceptually interesting legitimation episodes, but
they should not be loaded into the operational event file unless the live scene taxonomy is
expanded or a transparent bridge from `extreme_metal` to the scene families is built first.

## Secondary candidates

These are real and usable episodes, but not ideal for the first pass:

1. `DEU x power_metal x 2018`
   `Powerwolf - The Sacrament of Sin`
   Clean home-market number-1 event, but late.
2. `AUS x symphonic_metal x 2020`
   `Nightwish - Human. :II: Nature.`
   Clean timing, but the accessible Australian chart window is modern only.
3. `AUS x extreme_metal x 2021`
   `Gojira - Fortitude`
   Same problem as above.
4. `GBR x industrial_metal x 2022`
   `Rammstein - Zeit`
   Clean timing, but too late to anchor the first pass.

## Exclusions for the first branch

### 1. Heavy-metal episodes

Most `heavy_metal` rows are excluded from the first pass even when they are clean chart events.
The problem is not data quality. The problem is interpretation. In `GBR`, `DEU`, and `ITA`,
heavy metal is already too mature for these hits to read naturally as genre breakout or
legitimation shocks.

### 2. Certification-led or mixed-source markets

The first branch should avoid:

- `USA`
- `BRA`

Those rows are useful for the broader treatment workflow, but they are not the right first-pass
events for a cleaner causal branch.

### 3. Thin one-off markets

The first branch should also avoid leaning on:

- `FRA`
- `FIN`
- `NOR`
- `SWE`

unless a later pass shows one clearly dominant flagship episode worth isolating on its own.

## Practical implication

The branch now has a real first-screen candidate set. The next branch task is:

1. keep the operational event file limited to scene-taxonomy-compatible rows
2. merge those retained episodes onto the `city x genre_family x year` scene panel
3. freeze pre-shock local capability before each event
4. run a stacked differential-response event study only after the descriptive branch checks look
   credible

The right first operational market to build around is now `DEU`. The `GBR` and `ITA`
`extreme_metal` candidates remain useful only as conceptual screen rows until the genre bridge is
solved.

That keeps this as a real branch: concrete enough to test, but still clearly separate from the
main reduced-form paper.
