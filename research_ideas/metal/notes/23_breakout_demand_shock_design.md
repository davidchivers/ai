# Breakout-demand shock design

Last updated: 2026-04-09
Status: first concrete design note for the most feasible quasi-causal follow-on paper

## One-line idea

Use clean country-genre breakout episodes as plausibly external demand or legitimation shocks, and
test whether cities with higher pre-shock local capability convert those shocks into more local
entry or faster local scene growth.

## Why this is the first causal follow-on to try

The project already has a real treatment workflow for blockbuster albums and national hit timing.
That makes this branch much more feasible than infrastructure shocks and much less fragile than a
musician-loss design that may die on event counts.

The current files already establish that the treatment side is real, but also that the old pilot
is too heterogeneous to read causally:

- the core treatment summary recovers `91` album-country rows and `46` top-10 rows across
  `AUS`, `BRA`, `DEU`, `FIN`, `FRA`, `GBR`, `ITA`, `NOR`, `SWE`, and `USA`
- the treatment timing is mixed across chart-led rows, certification-led rows, and manual
  supplements
- the first `country x genre_family x year` FE pilot is mixed to negative and explicitly too
  heterogeneous to support a clean causal interpretation

So the right redesign is not "run the same country-genre FE with more rows." The right redesign is
to shift identification to within-country differences across cities that have more or less latent
capability before the same national breakout event.

## The causal question

When a genre receives a national breakout or legitimation shock, do cities with stronger latent
related capability respond more strongly in local project formation?

This is a narrower and better-identified question than:

- whether breakout albums "cause scenes" in the broad sense

The estimand is a demand-activation margin:

- national breakout shocks should matter more where the local ingredients for scene growth are
  already present

## What the old pilot got wrong

The current domestic-success pilot treats the shock too much as a direct treatment on the whole
`country x genre_family` cell. That design is too coarse.

Why it struggles:

1. treated cells are too few
2. shock dating is heterogeneous
3. some markets are certification-led rather than chart-led
4. the treatment likely picks up a lot of prior country-genre trend
5. the design does not use the key strength of this project, which is city-level capability

The city-level scene data are the actual comparative advantage here. The causal extension should
use them directly.

## Recommended treatment definition

The treatment should be a small set of clean `country x genre_family` breakout episodes, not the
entire mixed treatment file at once.

The first-pass treatment rule should be:

- first clean top-10 national album-chart breakout for a flagship album in a given
  `country x genre_family`

Preferred characteristics:

- chart-led rather than certification-led
- precise year timing
- a genre-family link that is easy to defend
- no obvious dependence on weak manual rows

## Best starting markets

Using the current treatment summary, the most promising markets for a first pass are the ones with
the strongest chart-led coverage:

1. `GBR`
2. `DEU`
3. `ITA`
4. `AUS`

Why:

- these markets have the most recovered top-10 rows in the current build
- they are more chart-led than the current `USA` branch
- they are less dependent on blocked or mixed-source fallback logic than the weaker markets

Markets to avoid in the first causal pass:

- `USA`
  because the current workflow is certification-led rather than chart-led
- `BRA`
  because the current workflow relies on blocked retrieval and mixed manual supplements
- `FRA`, `NOR`, `SWE`, `FIN`
  because current row counts are too thin for a first causal paper unless a flagship episode is
  clearly exceptional

## Unit of observation

The preferred unit is:

- `city x genre_family x event_relative_year`

in a stacked event-study file, where each stack corresponds to one clean
`country x genre_family` breakout episode.

This is better than:

- `country x genre_family x year`

because it moves identification to within-country differences across cities facing the same
national shock.

## Outcome choices

The first outcome should not be the same exact-threshold emergence indicator used in the main
paper. That would feel too close to the existing result.

Preferred first outcomes:

1. local same-genre band starts
2. change in active same-genre band stock
3. local same-genre spawning flow

Secondary outcome:

4. operational emergence for cells not yet emerged before the breakout

Why this order:

- entry and stock growth are closer to the immediate activation margin
- emergence can still be studied, but should not be the only outcome

## Pre-shock capability measure

The key heterogeneity variable should be frozen before the breakout event.

The preferred first-pass capability index is:

- pre-shock target-genre active bands
- pre-shock target-genre multi-band musicians

A simple implementation is to classify cities into:

- low pre-shock capability
- medium pre-shock capability
- high pre-shock capability

using the distribution within the treated country-genre before the breakout year.

An even cleaner first pass is:

- restrict to cities below the emergence threshold before the shock
- ask whether higher-capability subthreshold cities grow more after the breakout

That keeps the causal paper from just rediscovering already-emerged hubs.

## Preferred estimating equation

The clean first specification is a stacked event study:

\[
y_{c e \tau}
=
\alpha_{c e}
+ \lambda_{\tau}
+ \beta \left(\text{HighCapability}_{c e}^{pre} \times \text{Post}_{\tau}\right)
+ \varepsilon_{c e \tau},
\]

where:

- \(e\) indexes a clean `country x genre_family` breakout episode
- \(c\) indexes cities in that country
- \(\tau\) is event time
- \(y_{c e \tau}\) is local same-genre entry, active-band growth, spawning flow, or later
  emergence
- \(\alpha_{c e}\) are city-by-event fixed effects
- \(\lambda_{\tau}\) are relative-year effects common across stacks

The coefficient of interest is:

- whether higher-pre-shock-capability cities respond more after the breakout

This is the right causal object. The national breakout is common within the country-genre event.
Identification comes from differential response by pre-existing local capability, measured before
the shock.

## Stronger version

The stronger version replaces a binary high-capability split with a continuous frozen index:

\[
y_{c e \tau}
=
\alpha_{c e}
+ \lambda_{\tau}
+ \beta \left(\text{CapabilityIndex}_{c e}^{pre} \times \text{Post}_{\tau}\right)
+ \varepsilon_{c e \tau}.
\]

But the binary split is easier to visualize and defend in the first pass.

## What this design identifies

This design does **not** identify the full cause of scene emergence.

It identifies:

- whether national breakout shocks activate local scene growth more strongly where latent local
  capability is already present

That is a real quasi-causal result, and it fits the current project well.

## Key identification threats

### 1. Endogenous breakout timing

The national breakout may itself reflect earlier underground development in the same country-genre.

Response:

- use a small set of clean flagship episodes
- inspect pre-trends directly
- emphasize activation of local heterogeneity after breakout, not pure shock exogeneity

### 2. Already-emerged hubs driving the result

Big cities may both produce the breakout and respond more afterward.

Response:

- freeze capability before the event
- restrict the first pass to cities below the emergence threshold at baseline
- show results are not driven entirely by the top one or two cities

### 3. Mixed treatment timing quality

Certification-led and year-only rows are too noisy for the first causal paper.

Response:

- use chart-led top-10 events only in the first pass
- keep certification-led rows for descriptive support only

### 4. Genre-family coding disputes

Some albums are not cleanly one-genre objects.

Response:

- use broad genre families already adopted in the scene panel
- prefer episodes where the flagship album's genre-family assignment is easy to defend

## Concrete build sequence

### 1. Create the clean breakout-episode file

For each candidate `country x genre_family`, record:

- breakout album
- band
- market
- broad genre family
- first top-10 year
- source quality flag
- whether timing is chart-led and precise

Keep only the cleanest episodes in the first pass.

### 2. Build a stacked city-genre event panel

For each clean episode:

- pull all cities in the same country
- keep the focal genre family
- create event time `-5` to `+5`
- freeze city capability at `t = -1` or the pre-period average

### 3. Build pre-shock capability bins

Using the live scene data, classify cities by:

- focal active-band stock
- focal multi-band depth

measured before the breakout event.

### 4. Estimate the differential-response event study

Run:

- high-capability vs low-capability post-breakout response
- pre-trend checks
- leave-one-country-event-out robustness

### 5. Add one paper-quality figure

The main figure should be:

- event-time coefficients for high-capability minus low-capability cities around breakout

That is a much clearer causal figure than a country-level treatment table.

## Decision rule

This branch is worth deeper investment only if all three conditions hold:

1. at least a handful of breakout episodes have clean chart-led timing
2. pre-trends are not visibly explosive
3. high-capability cities respond more than low-capability cities after the breakout

If those conditions fail, stop. Do not keep polishing a weak causal branch.

## Relation to the live paper

This should be treated as a separate follow-on, not a rewrite of the current draft.

The current paper says:

- which local conditions predict later operational scene emergence

This follow-on would ask:

- whether national breakout shocks activate local scene growth more strongly where those local
  conditions are already in place

That is a coherent portfolio:

- paper 1: measurement and reduced-form scene formation
- paper 2: quasi-causal demand activation of local scene growth
