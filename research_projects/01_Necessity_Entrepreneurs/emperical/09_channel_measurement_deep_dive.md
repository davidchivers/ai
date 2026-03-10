# Channel measurement deep dive

## Purpose

This note turns the existing `emperical/` brainstorming workspace into a tighter
empirical plan for the paper's main channel.

The channel to measure is:

- weaker wage-work outside options raise low-scale, nonemployer-style entry more
  than employer-oriented entry.

Inference: the closest empirical analogue is not a universal label for
"necessity entrepreneurs." It is the differential response of entry composition
to an outside-option shock.

## Measurement principle

The empirical object should be built in layers.

1. Identify an outside-option deterioration that is as exogenous as possible.
2. Measure entry separately for nonemployer and employer outcomes.
3. Track early scale, first payroll, and early survival after entry.
4. Use motives and prior status as supporting interpretation, not as the sole
   classifier.

This is the cleanest bridge from the model to data in the current project.

## What the existing literature already says

### Evidence already verified in the local `literature/` folder

- Fairlie and Fossen (2019) is the closest conceptual bridge already in the
  project. The paper separates opportunity and necessity entrepreneurship and
  shows that the necessity component is the countercyclical one. That does not
  give the exact structural object in this paper, but it strongly supports the
  idea that entry composition matters more than a single entrepreneurship count.
- Sedlacek and Sterk (2017) shows that startup cohorts born in weak aggregate
  conditions are persistently smaller and less growth-oriented. This is directly
  relevant for the paper because it implies that the same entry rate can mask
  very different scale and output consequences.
- Hurst and Pugsley (2011) shows that many small businesses are not innovation-
  driven or high-growth firms. This is useful discipline against treating broad
  self-employment or business ownership as the same object as employer-oriented
  entrepreneurship.
- Poschke (2013) is useful as background for the broader occupational-choice
  view: entrepreneurship can be chosen by heterogeneous workers for different
  reasons, and small persistent firms are not automatically anomalies.

### Supporting project-side leads to verify before draft citation

The repository's sidecar notes also point to a broader empirical stack that is
highly relevant, but some of these should still be verified against the exact
paper version before they move into the draft citation list.

- [VERIFY BEFORE DRAFT CITATION] Fairlie (2013): weaker labor-market conditions
  raise business entry, especially from weaker employment states.
- [VERIFY BEFORE DRAFT CITATION] Fossen (2021): countercyclical movement is more
  concentrated in unincorporated or lower-scale entry than in employer-oriented
  entrepreneurship.
- [VERIFY BEFORE DRAFT CITATION] Fairlie and Miranda (2016): the transition from
  nonemployer to employer is a distinct margin and should not be conflated with
  entry itself.
- [VERIFY BEFORE DRAFT CITATION] Haltiwanger, Jarmin, and Miranda; Fort,
  Haltiwanger, Jarmin, and Miranda: downturns are especially damaging for young,
  small, and job-creating firms.
- Verified project data note: the GEM sidecar evidence shows motive overlap
  within the same entrepreneurial spell, so motives help interpretation but do
  not solve classification.

## Ranked empirical designs

## 1. Displacement-based worker-to-business design

This remains the top design in the folder.

- Shock: plant closure, mass layoff, or other displacement event that sharply
  worsens the worker's outside option.
- Core outcomes: entry into nonemployer activity, entry into employer activity,
  hazard to first employee, early payroll, and early survival.
- Why it is the best fit: it shifts the left-hand side of the paper directly.
  The model is about occupational choice when wage-work options deteriorate, so
  a worker-level outside-option shock is the cleanest empirical mirror.
- What it identifies well: whether weakened outside options disproportionately
  push workers into low-scale entry rather than employer-oriented businesses.
- Main requirement: linked worker-business data that can distinguish ownership
  entry from first payroll and can follow entrants for at least a short horizon.

Inference: if this design is feasible, it is the empirical pillar that best
matches the paper's theory.

## 2. Local labor-demand public-data design

This is the best near-term fallback and is already partly scaffolded in
`data/`.

- Shock: local labor-demand deterioration, ideally measured with a Bartik-style
  demand shift, vacancy-unemployment deterioration, or sharp local employment
  contraction.
- Core outcomes: nonemployer establishment activity, employer establishment
  activity, business applications, high-propensity application share, and CPS
  self-employment companions.
- Why it is attractive: it is feasible with the current repository assets and
  does not depend on restricted linked microdata.
- What it identifies well: whether weak local labor markets are associated with
  a compositional shift toward zero-employee or low-scale activity and away from
  employer-oriented formation.
- Main limitation: local shocks can hit both outside options and entrepreneurial
  demand at the same time, so this design is weaker on interpretation than the
  displacement route.

This is the right design if the goal is to build a publishable empirical bridge
quickly from public data.

## 3. UI-policy quasi-experiment

This is worth keeping, but it should not be the first empirical pillar.

- Shock: sharp changes in UI generosity, duration, or exhaustion.
- Core outcomes: the same nonemployer versus employer composition split, plus
  first payroll where available.
- Why it matters: it is the closest direct policy mirror of the model's main
  quantitative experiments.
- Why it should not lead: UI changes can also move liquidity, search effort, and
  local demand conditions, so a clean outside-option interpretation is harder
  than in displacement-based designs.

Recommendation: use UI designs as a robustness layer or extension after the
main composition result is in place.

## 4. Motive-based sidecar using GEM

This is useful, but only as supporting interpretation.

- What GEM contributes: it directly records motive overlap, including job-
  scarcity and income or wealth motives within the same entrepreneurial spell.
- What GEM does not identify: a clean causal necessity-entrepreneurship object.
- Best use in this project: motivation, interpretation, and a caution against
  reading survey motive labels as a structural classifier.

Recommendation: keep GEM in prose, tables, or appendix support. Do not make it
the headline identification design.

## What not to use as the main empirical object

- A single entrepreneurship or self-employment rate.
- GEM motives alone.
- Prior labor-market status alone.
- Startup capital or initial size alone.
- High-propensity business applications alone.

Each of those is informative. None of them isolates the paper's channel by
itself.

## Observable mapping that fits the paper best

The best empirical stack for this project is:

| Layer | Preferred object | Why it belongs |
| --- | --- | --- |
| Shock | worker displacement or local labor-demand deterioration | directly moves the outside option |
| Extensive-margin outcome | nonemployer entry and employer entry separately | captures the compositional margin in the model |
| Early scale outcome | first payroll, initial employment, payroll, capital if available | tests whether low-scale entry expands more than employer-oriented formation |
| Dynamic outcome | survival and growth to first employee | separates small temporary entry from stronger employer paths |
| Interpretation layer | prior status and GEM motive overlap | supports the story without pretending to be the structural object |

## Feasible build path from the current repository

### Near-term path: public-data composition panel

The repository already has enough local scaffolding to start a serious fallback
design.

- `data/us_business_counts_by_size_annual.csv`
- `data/us_business_applications_annual.csv`
- `data/us_self_employment_rates_annual.csv`
- GEM sidecar files and notes

The immediate empirical panel should target:

- local or state labor-demand deterioration,
- nonemployer versus employer outcome splits,
- business-application composition,
- companion self-employment and motive evidence.

### Medium-term path: linked worker-business request

If a restricted-data route is realistic, the exact wish list should be:

- worker employment history before entry,
- an observable business start event,
- separation between nonemployer and employer entry,
- first payroll timing,
- early employment and survival.

That would let the paper test the model's main comparative statics far more
cleanly than any motive-based design.

## Suggested figures and tables

If the empirical side becomes a formal section or appendix, the most informative
objects would be:

1. A composition figure: outside-option deterioration on the x-axis, with
   nonemployer and employer responses plotted separately.
2. A first-worker margin figure: probability of hiring a first employee after
   entry by shock exposure.
3. A scale table: initial payroll, initial employment, and short-horizon
   survival by entry type and shock exposure.
4. A short GEM table in prose-support mode, showing motive overlap rather than a
   binary necessity classification.

## Recommended decision for tomorrow

The project is ready to narrow to one of two serious paths.

- If the goal is the strongest design, prioritize the displacement-based linked
  worker-to-business route.
- If the goal is a fast, feasible empirical bridge from the existing repository,
  prioritize the public-data local-labor-demand panel.

My recommendation is:

- build the public-data composition panel now,
- keep the linked worker-business route as the preferred medium-term extension,
- treat UI-policy and GEM evidence as supporting layers rather than the main
  empirical pillar.

## Bottom line

The paper's empirical channel should be measured as a composition response to
outside-option deterioration.

That means:

- identify a shock to wage-work prospects,
- separate nonemployer from employer entry,
- then test whether the rise in entrepreneurship is concentrated in lower-scale
  entry and weaker post-entry scale.

That is the closest empirical translation of the model now in this repository.
