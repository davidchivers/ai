# Causal follow-on designs

Last updated: 2026-04-09
Status: strategy memo for a quasi-causal follow-on paper, not a revision target for the current draft

## Bottom line

If the goal is to answer the AER-style objection that the current scene paper is not a causal
account of scene emergence, the right move is not to bolt one more robustness table onto the
existing draft. The right move is to define a narrower causal question and build a separate design
around it.

The current paper should stay what it now is:

- a measurement-heavy, reduced-form field paper on local scene emergence

If a follow-on causal paper is pursued, the most realistic ranking is:

1. `external demand / legitimation shock -> local scene activation`
2. `negative local capability shock -> later spawning and emergence`
3. `local infrastructure shock -> later spawning and emergence`

My recommendation is:

- do **not** try to convert the current draft into path 2
- if a causal branch is pursued, start with the breakout-shock design
- treat the central-musician-loss design as the most interesting mechanism audit, but only after a
  quick feasibility count

## Why the current paper should not be stretched into a causal paper

The live draft's strongest result is now clear and bounded. In the exact-year fixed-effects scene
panel, local spawning flow, target-genre active bands, and target-genre multi-band musicians
predict later operational scene emergence. The threshold-response package also narrows the claim in
an honest way: the evidence is strongest near the later approach to the emergence threshold rather
than at the very thinnest initial stage.

That means the current paper can be defended as:

- a panel measure of local scene emergence
- a validated reduced-form result
- an economics interpretation in terms of local capability, embedded entry, and within-niche
  recombination

It cannot honestly be sold as:

- a causal account of how scenes are born from zero
- a clean identification of the spinout channel
- a clean identification of the recombination channel

So path 2 has to be a different paper with a narrower causal estimand.

## What a causal follow-on should try to identify

The realistic causal target is not "the cause of scene emergence" in the broad sense. It is one of
the following margins:

1. whether an external increase in genre demand or legitimation activates local entry where latent
   capability already exists
2. whether the loss of key local recombination capital reduces later local entry or scene growth
3. whether a local production-capacity shock changes later local project formation

That is the correct level of ambition.

## Design 1: breakout-demand shock

### Causal question

When a genre receives a plausibly external demand or legitimation shock in a country, do cities
with latent related capability convert that shock into more local entry or faster scene emergence?

### Why this is promising

This is closest to the project's existing workflow. The project already has:

- curated blockbuster album files
- official chart and certification logic
- a multi-country country-year treatment workflow
- a fallback branch already framed as `domestic breakthrough shock -> later entry`

So this design would build on existing code and source logic rather than starting from zero.

### Best paper version

The clean version is not "big album success causes scenes everywhere." It is:

- national legitimation or demand shocks matter more in places with pre-existing local related
  capability

That suggests a design where the treatment is a country-year breakout event and the cross-sectional
heterogeneity is latent city-level capability measured before the shock.

### Candidate outcome objects

- later city-genre band entry
- later city-genre active-band growth
- later city-genre operational emergence

The cleanest first outcome is probably entry or active-band growth rather than exact threshold
crossing, because the latter may again feel too close to the current paper.

### What this would identify

This would identify a causal demand or legitimation margin:

- when outside recognition rises, places with latent capability are more likely to convert that
  into local activity

That is a real causal contribution, but it is not identification of the spinout or recombination
channel per se.

### Main threats

- shock timing is partly hand-built and heterogeneous
- treatment may still be endogenous to earlier underground scene development
- national-level shocks are coarse relative to city-level outcomes
- some "breakout" moments are not cleanly unexpected

### Practical read

This is the most feasible causal follow-on because the data pipeline already exists.

## Design 2: central-musician-loss shock

### Causal question

Does the unexpected loss of a highly central local multi-band musician reduce later spawning, local
entry, or subsequent scene emergence?

### Why this is attractive

This is the best match to the current paper's mechanism story. If the live interpretation is that
within-niche overlapping workers help local recombination and project formation, then the cleanest
causal probe is to ask what happens when a city loses one of those people.

### Best paper version

The right object is not all musician exits. It is:

- sudden loss of locally central, multi-band, focal-genre musicians

with outcomes measured at the city-genre-year level after the loss.

### Candidate treatment construction

- build pre-shock centrality or local multi-band ranking within city-genre
- identify deaths or clearly dated permanent exits
- compare treated city-genre cells to matched untreated cells before and after the event

### Candidate outcome objects

- local spawning flow
- local same-genre band formation
- local multi-band depth
- later emergence for cells not yet emerged

### What this would identify

This would identify a local capability-loss margin:

- removing central local recombination capital changes later local scene formation

This is much closer to a causal mechanism paper than the breakout-shock design.

### Main threats

- event counts may be too small
- exact dating may be poor
- deaths are not always the relevant form of creative exit
- famous-musician deaths may induce offsetting national demand or memorial effects
- centrality may be measured with error if member spans are incomplete

### Practical read

This is the best mechanism-matched design, but it is much riskier. It should begin with a simple
feasibility audit:

1. count plausibly exogenous losses of focal local multi-band musicians
2. check whether enough events occur before local emergence or during scene growth
3. inspect whether treatment dates are precise enough for an event-study design

If the event count is thin, this branch should stop quickly.

## Design 3: local infrastructure shock

### Causal question

Do local production-capacity shocks such as venue openings or closures, festival starts, label
entries, or studio openings change later local scene formation?

### Why this is conceptually strong

This goes directly to local production infrastructure rather than latent network structure.

### Why it is currently weak in practice

The project does not have this data workflow built. A serious design would require substantial new
historical collection and probably country-specific institutional work. This is the cleanest theory
paper and the worst near-term build.

### Practical read

Do not start here unless there is already a known clean source for one infrastructure margin in one
country.

## Ranked recommendation

### 1. Breakout-demand shock

This is the most feasible because the project already has the beginnings of the data workflow. It
can produce a separate causal paper on demand activation without derailing the current draft.

### 2. Central-musician-loss shock

This is the best mechanism fit and the most interesting if it works. But it should only be pursued
after a quick event-count audit, because the probability of dying on sample size or timing quality
is high.

### 3. Infrastructure shock

This is the best idea in the abstract and the worst use of time right now.

## Recommended next step if we want to test path 2 seriously

Do **not** start by rewriting the current paper.

Start with two bounded audits:

1. **Breakout branch audit**
   Check whether the current blockbuster timing file can support a cleaner country-year shock
   design with one or two flagship genre-country episodes and pre-shock city capability
   heterogeneity.

2. **Loss-shock feasibility audit**
   Count plausible events where a city-genre loses a pre-period top-decile local multi-band
   musician with a clearly dated death or permanent exit.

The decision rule should be:

- if the breakout branch can be cleaned quickly, it is the first causal follow-on
- if the loss-shock branch has surprisingly strong event counts and clean dates, it may be the more
  interesting mechanism paper
- if neither audit looks strong, stop and keep the current project as a field-paper plus future
  agenda

## Implication for the live paper

The existence of these causal follow-on designs should make the current paper easier to position,
not harder.

The live paper can now say, implicitly or explicitly:

- this paper provides the measurement framework and reduced-form scene facts
- a separate causal agenda would isolate demand shocks, local capability losses, or infrastructure
  changes

That is a stronger and more honest project portfolio than pretending the current draft is already a
causal account of scene emergence.
