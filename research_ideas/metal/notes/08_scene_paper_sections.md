# 08 Scene paper sections

Last updated: 2026-04-09
Status: fuller markdown draft with integrated conceptual framework

## Abstract

This paper studies local scene emergence in heavy metal. Using the full Metal Archives band census
and member dump, I build a city-level collaboration dataset from `971,877` musician-band edges
covering `682,126` musicians and link it to a dynamic city-by-genre panel of local scene
emergence. A city-genre cell is counted as emergent in the year it reaches its fifth band in that
broad genre family. In the preferred exact-year fixed-effects sample, the panel contains
`171,653` city-genre-years and `5,306` emergence events. Two facts organize the paper. First,
exact-year emergence rates rise sharply with local band stock and with the depth of the local
multi-band musician pool. Second, later emergence tracks three stable lagged scene predictors:
local spawning flow, target-genre active bands, and target-genre multi-band musician depth. These
patterns survive nearby threshold changes and geography-clean restrictions, but attenuate sharply
when the risk set is restricted to city-genre cells still far below the threshold. The paper is
therefore strongest on late-stage local niche consolidation rather than on the earliest seed stage
of scene formation. The contribution is reduced-form and measurement-driven rather than causal.
Heavy metal is useful because it makes local project overlap and worker mobility unusually
observable, allowing the paper to study how localized capability, embedded project formation, and
within-niche recombination are associated with local scene emergence.

## 1. Introduction

This paper studies local scene emergence in heavy metal. The question is not why some cities have
more bands in general. It is why some city-genre environments move from scattered local entry to a
recognizable local scene earlier than others. I treat that process as a localized production
problem in a project-based creative industry, where bands are projects, musicians move across
teams, and new local niches are easier to sustain once enough specialized capability has
accumulated.

That question is difficult to study with the usual retrospective approach. Famous scenes are often
identified only after genre labels are settled, canonical bands are known, and local histories can
be written in hindsight. But genre recognition is not the same thing as genre formation. By the
time a label is stabilized, much of the relevant local infrastructure may already have formed
through repeated collaboration, spinouts, and worker mobility across projects. The empirical
challenge is therefore to measure local scene formation before the historical narrative fully
settles.

Heavy metal offers an unusually useful setting for that task. Metal Archives provides a broad band
census with genre strings, formation years, and location information, while the member dump makes
it possible to observe overlapping personnel ties across bands. I use those sources to build a
city-level collaboration dataset from `971,877` musician-band edges covering `682,126` musicians,
and I link that object to a dynamic city-by-genre panel of local scene emergence. The resulting
panel contains `56,978` city-genre cells, of which `5,756` eventually cross the paper's
emergence threshold. The preferred exact-year fixed-effects sample contains `171,653`
city-genre-years and `5,306` emergence events.

The paper's outcome is intentionally operational. A city-genre cell is counted as emergent in the
year the city reaches its fifth band in that broad genre family. This is not a claim that genre
identity literally begins at band number five. It is a transparent empirical rule that separates
isolated local entry from a scene with enough local depth to sustain repeated collaboration and
further entry. That transparency is a feature of the design, but it also defines the paper's main
empirical risk: one must show that the results are not merely a mechanical consequence of thicker
places crossing a stock threshold sooner.

Two empirical facts organize the paper. The first is descriptive. Exact-year emergence rates rise
sharply with local band stock and with the depth of the local multi-band musician pool. The second
is reduced-form. In exact-year fixed-effects specifications, later city-genre emergence tracks
three stable lagged predictors: local spawning flow, target-genre active bands, and target-genre
multi-band musician depth. Composition-heavy extensions and broader connector measures appear only
in background work because they do not improve the main paper object. Threshold-response checks
show that this pattern is not pinned to the fifth-band cutoff, but they also narrow the claim: the
paper is strongest on the later approach to emergence rather than on the earliest seed stage of
scene formation.

The contribution is therefore narrower than the broadest version of the project, but clearer.
First, the paper introduces a large city-level collaboration dataset for metal built from the full
band census and member records rather than from a curated set of famous scenes. Second, it treats
genre emergence as a measurable local event that can be studied in panel form before retrospective
scene histories dominate the evidence. Third, it shows in that panel that later emergence is most
closely associated with local spawning, focal-niche band stock, and focal-niche overlapping-worker
depth, with the clearest evidence coming near the later approach to the scene threshold.

The paper remains reduced-form rather than causal. It does not identify an exogenous source of
scene formation, observe knowledge transfer directly, or date the true historical origin of a
genre. The contribution is instead a carefully validated empirical pattern. In a large panel, new
local scenes are more likely to emerge where local capability is thicker, project spinouts are more
common, and workers are already recombining within related local projects. Heavy metal is useful
here not because it is culturally exceptional, but because the setting makes project overlap and
worker mobility unusually observable.

The rest of the paper proceeds as follows. Section 2 situates the paper in the related
literature. Section 3 presents the empirical motivation. Section 4 sets out a compact model of
local niche formation. Section 5 describes the data and sample construction. Section 6 presents the
empirical approach. Section 7 reports the descriptive and reduced-form results. The appendix
collects the detailed sample-construction and variable-definition objects behind the main
specification.

## 2. Data

### 2.1 Data sources and construction

The analysis combines three linked data objects. The first is the cleaned all-metal band reference
built from the full Metal Archives snapshot. This file provides band identifiers, formation years,
genre strings, countries, and location notes for `163,965` bands, with `131,511` bands carrying a
usable formed year. The second is the full member ingest from the delivered Metal Archives member
dump. That raw file contains `1,038,533` member-role rows, which collapse to `971,877` unique
musician-band edges after duplicate role rows are removed. The third object is a set of city-year
and city-genre panel files that merge the cleaned band reference and the edge file into dynamic
local scene measures.

The first stage of the pipeline constructs yearly local collaboration snapshots. Bands are linked
whenever they share at least one musician and are active in the same year. Those yearly local
projection graphs are summarized into measures of local scale, organizational variety, and worker
mobility. In the broad city-level network baseline, `22,572` cities have at least one
member-linked band and `2,319` cities have at least `10` bands, which is the threshold used for
the main descriptive city-level scene statistics.

The second stage constructs the city-genre emergence panel. Genre strings are mapped to broad
genre families, bands are assigned to cities using the cleaned location field, and each
`city x genre_family` cell receives a `first_band_year` and an `emergence_year`. A cell reaches
emergence in the year the city records its fifth band in that genre family. This definition is
deliberately simple. It is strong enough to exclude one-off local entry, but transparent enough
that the reader can see exactly what the outcome measures.

### 2.2 Sample construction

The sample construction is straightforward but worth stating clearly in the main text. The cleaned
all-metal reference begins with `163,965` bands, of which `161,945` are matched to standardized
countries and `131,511` carry a usable formed year. The delivered member file contributes
`1,038,533` raw member-role rows, which collapse to `971,877` unique musician-band edges and
`682,126` unique musicians after duplicate within-band role rows are removed. Matching the edge
file back to the reference yields `156,729` reference-matched bands in the collaboration data.

Those source files then feed the scene panel. The broad emergence universe contains `56,978`
`city x genre_family` cells, of which `5,756` eventually cross the paper's emergence threshold.
The preferred exact-year estimation sample is narrower because it requires valid lagged rolling
predictors and keeps only the relevant risk set. In the preferred `roll-5` specification, the
final sample contains `171,653` city-genre-years and `5,306` emergence events. The appendix can
show the full construction table, but these headline counts belong in the main draft because they
make the scale of the paper legible immediately.

### 2.3 Main variables

The estimating outcome is `emergence this year`, an indicator equal to one when the current
snapshot year is the cell's emergence year. The preferred paper sample is the `roll-5` exact-year
fixed-effects panel, which contains `171,653` city-genre-years and `5,306` emergence events. The
nearby `roll-3` panel is used as a robustness check.

The headline predictors are all lagged scene measures. `Local spawning flow` counts bands formed
in a city-year whose founding cohort includes at least one musician with prior local band
experience in that city. `Target-genre active bands` counts active local bands in the same broad
genre family as the focal city-genre cell. `Target-genre multi-band musicians` counts local
musicians who are active in the focal genre and simultaneously work across at least two local
bands in that same genre.

The preferred specification also includes three background controls that absorb broader city-level
scene conditions: overall active bands, the number of nontrivial communities in the local yearly
network, and the total number of overall multi-band musicians. All predictors are transformed as
one-year-lagged rolling averages before estimation, with the preferred paper version using a
five-year window and z-scoring within the estimation sample.

## 3. Empirical approach

### 3.1 Estimating design

The empirical design is predictive and reduced-form. The exact-year specification asks whether a
city-genre cell reaches emergence in a given year after conditioning on `city-genre` fixed
effects, year fixed effects, and the lagged scene variables. Standard errors are clustered by
city. This design is useful because it compares the same city-genre environment over time rather
than relying on cross-sectional differences between famous and obscure scenes.

That design should not be read as causal identification. Stronger local scenes may themselves
generate some of the conditions being measured, and omitted local shocks may move both the
predictors and later emergence. The coefficients therefore support a disciplined statement about
which local scene features track later emergence, not a structural claim that those features alone
cause genres to appear.

Most remaining construction detail belongs in the appendix rather than in the main text. The
sample-construction audit traces the pipeline from the raw band and member files to the preferred
exact-year sample. The variable crosswalk records the paper-facing definitions, transformations,
and units of observation for the headline variables. Together those appendix objects make the
pipeline auditable without forcing the main text to read like a data manual.

The empirical logic is therefore straightforward. The descriptive figure shows whether scene
thickness and worker mobility visibly co-move with later emergence in the raw data. The exact-year
panel then asks whether those same scene features still track emergence once fixed differences
across city-genre cells and common year shocks are absorbed. That sequence keeps the paper focused
on a simple economic question: which local collaborative conditions are most closely associated
with the birth of a new creative scene?

### 3.2 Compact conceptual framework

The theoretical task is narrower than a full account of genre origin or cultural diffusion. The
paper needs a framework that explains why some `city x genre_family` cells cross from thin local
activity into repeated entry earlier than others. The paper's theory object is therefore local
niche formation in a project-based creative industry, not technological progress and not network
structure for its own sake. Bands are projects, musicians are skilled workers, and a local scene
emerges when activity in a `city x genre_family` cell becomes thick enough to sustain repeated
entry. The key mechanisms are localized labor pooling, spinouts by already embedded participants,
and recombination across overlapping teams.

Let `c` index cities, `g` genre families, and `t` years. For a cell that is still at risk of
emergence, the local state at the start of period `t` is:

$$
\left(B_{cg,t-1},\; M_{cg,t-1},\; \rho_{c,t-1}\right),
$$

where `B_{cg,t-1}` is target-genre active-band stock, `M_{cg,t-1}` is target-genre multi-band
musician depth, and `\rho_{c,t-1}` is the share of potential founders who are already embedded in
the broader local scene. A compact entry equation is:

$$
\Pi_{icgt}
=
\bar{\pi}_g
+ \phi_B \log(1 + B_{cg,t-1})
+ \phi_M \log(1 + M_{cg,t-1})
+ \gamma e_i
- f_i
+ \varepsilon_i,
\qquad
\phi_B,\phi_M,\gamma > 0,
$$

where founder `i` draws embedded status `e_i \in \{0,1\}`, a fixed cost `f_i`, and an idiosyncratic
shock `\varepsilon_i`. The term in `B` captures local niche thickness and labor pooling. The term
in `M` captures recombinant capacity through overlapping workers. The embedded-founder premium
captures inherited local know-how from prior participation in the scene.

Aggregate entry in the focal niche is then:

$$
N_{cgt} = \int \mathbf{1}\{\Pi_{icgt} \ge 0\} \, dH_{ct}(i),
$$

so higher `B_{cg,t-1}`, `M_{cg,t-1}`, and `\rho_{c,t-1}` all raise the chance of local entry.
Band stock evolves as:

$$
B_{cgt} = (1 - \delta) B_{cg,t-1} + N_{cgt}.
$$

A local scene emerges when activity crosses a viability threshold:

$$
E_{cgt} = \mathbf{1}\{B_{cgt} \ge \bar{B}\},
\qquad
\bar{B} = 5.
$$

This threshold is operational rather than ontological. It marks the point at which the local
niche looks thick enough to sustain repeated entry, not the literal historical birth of a genre.

The empirical spawning measure is indexed at `city-year`, not `city x genre x year`. Let
`N^E_{cg't}` denote entry by embedded founders across all genre families. Observed local spawning
flow is:

$$
S_{ct} = \sum_{g'} N^E_{cg't}.
$$

Because `S_{ct}` is a city-year object, it should be read as a proxy for broad local spinout
intensity rather than as a purely focal-genre count.

This maps directly to the paper's headline predictors:

$$
B_{cg,t-1} \leftrightarrow \text{target-genre active bands}, \qquad
M_{cg,t-1} \leftrightarrow \text{target-genre multi-band musicians}, \qquad
\rho_{c,t-1} \leftrightarrow \text{embedded-founder margin proxied by } S_{c,t-1}.
$$

The reduced-form exact-year specification is therefore a compact empirical analogue of the model:

$$
\Pr(E_{cgt}=1 \mid E_{cg,t-1}=0)
=
F\left(
\alpha_{cg}
+ \lambda_t
+ \beta_S S_{c,t-1}
+ \beta_B B_{cg,t-1}
+ \beta_M M_{cg,t-1}
\right),
$$

where `F` is increasing. The estimated specification adds broader scene controls and smoothed
lags, but this compact version captures the paper's core economic object without pretending to be
a full structural model of band formation or cultural demand.

### 3.3 Scope and interpretation

This design should not be read as a claim of clean causal identification. Stronger local scenes may
themselves generate some of the conditions being measured, and omitted local shocks may move both
the predictors and later emergence. The coefficients therefore support a disciplined statement
about which local scene features predict later emergence, not a structural claim that those
features alone cause genres to appear.

That discipline is important for two reasons. First, the outcome is operational rather than
ontological. Reaching a fifth band in a genre family is a transparent threshold for local scene
emergence, not a claim about the exact historical birth date of a genre. Second, the paper does
not directly observe ideas moving between musicians. What it observes are local conditions that
raise the scope for learning, recombination, and spinouts. The empirical approach is therefore
best understood as a reduced-form test of whether local capability and overlapping project
experience predict niche formation.

## 4. Results

### 4.1 Descriptive critical mass

The first result is descriptive and should appear before the regression figure. Exact-year
emergence rates rise steeply with local scene thickness. When a city has fewer than `10` active
local bands, the exact-year emergence rate is `1.4%`. When it has `40+`, the rate rises to
`4.0%`. The same pattern appears for multi-band depth. When a city has only `0-1` multi-band
musicians, the emergence rate is `1.4%`; when it has `10+`, the rate rises to `3.7%`.

This figure matters because it shows that the scene branch is not being created by specification
search. Even before fixed effects are introduced, later emergence is much more common in places
with thicker local collaborative infrastructure. The pattern also gives the paper its economic
orientation. What matters is not metropolitan scale in the abstract, but local creative capacity:
active projects, worker mobility across projects, and the accumulation of specialized labor within
the focal domain.

The figure should not be oversold as evidence of a literal threshold. It is better read as a
critical-mass fact. Once local scenes move from very thin to moderately thick, emergence becomes
substantially more likely. That descriptive fact is the bridge from the raw data to the exact-year
panel design.

### 4.2 Headline exact-year fixed-effects result

The headline regression result appears in the preferred exact-year fixed-effects specification.
This counts-only `roll-5` design is the cleanest main paper object because it isolates the stable
unconditional scene terms without importing harder-to-interpret composition measures. In that
sample, the outcome is observed over `171,653` city-genre-years with `5,306` emergence events.

Three variables remain stably positive. Local spawning flow enters at `0.0134`. Target-genre
active bands enter at `0.0505`. Target-genre multi-band musicians enter at `0.0227`. Those
coefficients are directly comparable because the lagged predictors are z-scored within the
estimation sample. Relative to the sample event rate of `0.0309`, they imply large associations on
the linear-probability scale: about `1.3` percentage points for spawning flow, `5.1` percentage
points for target-genre active bands, and `2.3` percentage points for target-genre multi-band
depth. The largest term is therefore focal-niche thickness, not a generic city-scale proxy. The
same target-genre multi-band term stays positive in the nearby `roll-3` robustness check, and the
central interpretation does not depend on reviving the earlier broker or connector extension.

The control pattern is also interpretable once the table is read conditionally rather than
literally. Overall active bands remain positive, but overall multi-band musicians enter
negatively. That is not a claim that worker overlap is bad for scenes. Holding fixed focal-genre
active bands and focal-genre multi-band depth, broader city-wide multi-band overlap appears to
proxy for labor spread across many niches rather than for depth in the focal one. The paper's
mechanism read is therefore about niche-specific recombination, not generic scene-wide overlap.

The threshold-response package sharpens what exactly survives. Under alternative emergence cutoffs
of `3`, `4`, `6`, and `8` bands, local spawning flow, target-genre active bands, and
target-genre multi-band musicians all remain positive. But the harder risk-set checks are more
sobering. When rows one band below the fifth-band cutoff are dropped, the same three coefficients
remain positive but shrink materially. When the sample is restricted to cells still well below the
cutoff, the coefficients attenuate sharply and the multi-band term is no longer distinguishable
from zero. The narrow but defensible reading is therefore that the paper is strongest on late-stage
local niche consolidation rather than on the earliest seed stage of scene formation. A
falsification-style specificity check still supports the recombination margin: conditional on
target-genre active bands and total target-genre active musicians, target-genre multi-band
musicians remain positive while total target-genre active musicians turn negative.

The measurement-validation package sharpens the same read on a different margin. The preferred
exact-year sample is already geography-clean on the project's current audit rule: region-like and
malformed labels are excluded upstream, so none survive into the live fixed-effects panel.
Tightening the sample further does not materially move the headline coefficients. Dropping the
small-dense labels changes them only from `0.0134`, `0.0505`, and `0.0227` to `0.0133`,
`0.0510`, and `0.0215`. Restricting to `1990` onward yields `0.0135`, `0.0481`, and `0.0235`,
and restricting to the `23` countries with at least `50` emergence events yields `0.0143`,
`0.0514`, and `0.0213`. A short historical sanity table is also reassuring: Birmingham heavy
metal appears in `1977`, Tampa death metal in `1987`, Bergen black metal in `1992`, Oslo black
metal in `1990`, and Gothenburg melodic death metal in `1996`. The Bay Area row is useful for a
different reason: its raw timing looks plausible too, but it is excluded from the city baseline
because it names a wider unit rather than a city.

The coefficient pattern points to a local innovation environment in which new genre scenes are
more likely to appear when three conditions hold. First, cities are generating project spinouts.
Second, the focal genre already has a thicker local stock of active bands. Third, musicians in
that focal genre are working across multiple local projects, which is consistent with
genre-specific labor pooling and repeated recombination. This is the core empirical message of the
paper.

### 4.3 What the paper does and does not claim

The strength of this result is its discipline. The paper no longer needs to claim that all scenes
are driven by a broad bridge-musician story, nor that historical labels can be cleanly dated by a
single network threshold. The older threshold-count branch remains useful as background motivation,
but the regression-based scene design is the better main object because it rests on repeatable
panel facts rather than on a small number of manually validated cases.

The paper also does not need to claim a structural causal mechanism. The empirical contribution is
already meaningful at the reduced-form level. Local spinout flow, thicker target-genre project
stock, and deeper within-genre worker mobility all track later emergence. That is enough to frame
metal as a laboratory for a broader economic question: how local labor pooling and recombination
shape the birth of new creative categories.

### 4.4 Economic interpretation

What emerges from these results is a specific view of creative development. Local scenes do not
look like passive containers in which bands simply appear once a genre label becomes fashionable.
They look more like project-based labor markets in which workers circulate across teams, new
projects inherit local experience, and niche formation is easier once enough specialized local
capability has accumulated. That interpretation is why metal is useful for economics rather than
only for music history. The empirical objects are bands and musicians, but the underlying problem
is one of localized innovation under team production.

This interpretation also helps explain why the paper's strongest terms are so concrete. Spawning
flow captures local project formation by already embedded participants. Target-genre band stock
captures the thickness of the relevant local domain. Target-genre multi-band depth captures worker
mobility and recombination within that domain. Those are the kinds of conditions one would expect
to matter if new creative categories are born out of repeated local experimentation rather than out
of isolated genius or purely exogenous demand shocks.

## 5. Conclusion

This paper studies scene formation as a problem in the economics of creativity and innovation. In
heavy metal, some city-genre environments convert early scattered activity into recognizable local
scenes much earlier than others. Using a large city-level collaboration dataset linked to a
city-genre panel of emergence timing, the paper shows two robust facts. Emergence is more common
in thicker local scenes, and later emergence tracks local spawning flow, target-genre band stock,
and target-genre multi-band musician depth in the preferred exact-year fixed-effects design.

Those results do not, by themselves, identify a structural causal model. But they do establish a
disciplined reduced-form pattern that is already informative. New creative categories appear more
readily where localized labor pooling, repeated recombination, and spinout formation are already
present. That makes metal a useful empirical laboratory for a broader economic argument: creative
innovation is often organized locally through overlapping teams and mobile workers before it is
recognized formally as a new category.

The next steps in the project should deepen that empirical package rather than broaden it. The
appendix can make the sample construction and variable definitions fully auditable, and the
band-success sidecar can later ask whether the same scene conditions also help generate standout
projects within those scenes. But the main paper no longer depends on solving those extensions
first. The core scene result is already coherent enough to support a full paper draft.
