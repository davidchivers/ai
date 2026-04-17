# 07 Scene paper memo

Last updated: 2026-03-26
Status: markdown-first prose memo

## Working title

Scenes Before Labels: Local Musician Networks and Genre Emergence in Heavy Metal

## Core claim

This paper studies why some cities generate new metal scenes earlier than others. The central
claim is not merely that larger places produce more bands. Later city-genre emergence tracks
scene-specific collaborative infrastructure: local spawning flow, target-genre band stock, and
target-genre multi-band musician depth. The paper is therefore about scene formation as a local
collaborative process, not about retrospective genre naming alone and not primarily about the
older blockbuster-shock design.

## Why this paper is worth writing

Most accounts of genre formation are written after the fact. They identify famous scenes only once
the genre label already exists and once the key bands are canonical. That misses the harder and
more interesting question: what makes some places capable of producing a recognizable new scene in
the first place? The metal setting is useful because the data are unusually rich. Metal Archives
provides a very large band census, and the membership dump makes it possible to observe which
musicians connect bands inside the same local scene. That lets the paper study not only where
bands exist, but how local collaboration networks are structured before a genre reaches a visible
critical mass.

The current empirical branch is strong enough to support that question. The scene project no
longer rests on a fragile threshold-count argument about a small set of hand-audited cases. It
now has a large `city x genre_family x year` panel, exact-year fixed-effects specifications, and
a figure package that communicates the main facts directly. The core message is narrower than the
earliest version of the scene idea, but it is more defensible. What matters most cleanly is not a
generic bridge-musician story. It is the combination of spinout flow, target-genre scale, and
within-genre multi-band depth.

## Data and measurement

The paper combines three objects. First, the cleaned all-metal band reference provides band ids,
formed years, country, genre strings, and location notes from the full Metal Archives snapshot.
Second, the musician-band edge file collapses the raw member dump into unique musician-band links
with usable start and end timing. Third, those inputs are merged into city-year network snapshots
and city-genre timing files that track when a broad genre family first appears in a city and when
that city reaches emergence, defined as the year it reaches its fifth band in that genre family.

That emergence threshold is deliberately simple. The goal is not to recover an exact sociological
moment when a genre becomes culturally recognized. The goal is to define a disciplined and
reproducible local milestone that is strong enough to distinguish isolated bands from a genuine
scene. The paper should be explicit that this is an empirical operationalization, not a claim that
genre identity begins mechanically at band number five.

The key predictors are all lagged scene features. `Local spawning flow` counts new local bands
whose founders include musicians with prior local band history. `Target-genre active bands` counts
active bands in the same broad genre family. `Target-genre multi-band musicians` counts musicians
active in the target genre who are working across at least two local bands in that same genre.

Most of the mechanical detail should stay out of the main text. The paper can now rely on the two
new audit notes, `scene_data_cleaning_audit.md` and `scene_variable_measurement_audit.md`, for a
clean appendix flow chart and variable crosswalk. That matters because the data pipeline is large,
but it is already disciplined enough that the paper does not need to keep re-explaining every
construction choice in the body text.

## First fact: scene emergence has a critical-mass shape

The right first result is descriptive, not regression-based. The critical-mass figure shows that
exact-year emergence rates rise sharply once cities accumulate modest scene scale and modest
multi-band depth. When a city has fewer than `10` active local bands, the exact-year emergence rate
is only `1.4%`. At `40+` active bands, it is `4.0%`. A similarly steep pattern appears for
multi-band musicians: emergence is `1.4%` when the city has `0-1` such musicians and `3.7%` when
it has `10+`.

This figure is important because it does two jobs at once. First, it makes the scene project
visually legible before any specification is introduced. Second, it clarifies the intuition that
the paper is not about raw city size in a generic way. The descriptive pattern already points
toward collaborative thickness, local labor pooling, and the accumulation of scene-specific
capacity. The paper should say this carefully: the figure does not identify a causal threshold,
but it establishes a strong empirical regularity that later motivates the reduced-form panel.

## Empirical design

The baseline panel is `city x genre_family x year`. The preferred specifications are exact-year
fixed-effects models with `city-genre` and year effects, using lagged rolling predictors and
standard errors clustered at the city level. This is a reduced-form design. Its role is to ask
which lagged local scene features track later genre emergence once time-invariant differences
across city-genre cells and common year shocks are absorbed.

That framing matters. The paper should not imply that it has solved the classic problem that
stronger scenes may themselves generate the conditions being measured. The design is useful
because it moves well beyond anecdote and beyond static cross-sections, but it is still a
predictive panel rather than a full identification strategy. The text should therefore use verbs
like `predicts`, `tracks`, and `is associated with`, not `causes`.

## Headline reduced-form result

The preferred paper object is now the headline coefficient figure built from the core scene table.
The paper should center the stable counts-only specification rather than the broader composition
extension.

The message is clear. Local spawning flow is positive at `0.0134`. Target-genre active
bands are strongly positive at `0.0505`. Target-genre multi-band musicians are positive at
`0.0227`. These are the stable unconditional scene mechanisms. They also survive the nearby
robustness checks already built into the package: the target-genre multi-band coefficient remains
`0.0221` under `roll-3` and `0.0217` when the overall switcher control is removed.

## Mechanism interpretation

The cleanest interpretation of the current evidence runs through three channels. First, local
spawning flow suggests spinouts. New bands often appear to be founded by people already embedded
in the local scene. Second, target-genre band stock and target-genre multi-band depth suggest
genre-specific labor pooling. What matters is not only that a city is musically active, but that
the relevant local know-how exists inside the focal genre. Third, within-genre multi-band depth is
consistent with recombinant collaboration across repeated local projects.

That interpretation is already enough for a compact theory section later. The model does not need
to be deep yet. It only needs to organize the empirical facts: spinouts, genre-targeted labor
pools, and bounded recombination. A heavier theory investment before the empirical package is
fully written up would be a mistake. The theory should follow the locked facts, not chase an older
version of the project.

## What the paper should show

The current main-text figure order should be:

1. an optional global opener on the spatial concentration and expansion of metal activity
2. the critical-mass scene figure
3. the headline mechanism coefficient figure
4. one case-study network figure

That fourth slot should be used sparingly. The better default is one case-study network figure,
because the draft already has the core reduced-form result and does not need another regression
object in main text.

## Immediate writing and appendix tasks

The next step is not LaTeX. The next step is to turn this memo into fuller prose for the
Introduction, Data, and Results sections while keeping the claims tightly aligned to the live
figures. In parallel, the audit notes should become appendix-ready objects: a sample-construction
flow from the cleaning audit and a variable crosswalk from the measurement audit. Once the title,
abstract, figure order, and appendix package are stable in markdown, moving into LaTeX will make
sense. Before then, it would just slow the project down.
