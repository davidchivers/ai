# 06 Scene paper skeleton

Last updated: 2026-03-26
Status: markdown-first draft skeleton

## Working title options

1. Scenes Before Labels: Local Musician Networks and Genre Emergence in Heavy Metal
2. How Scenes Form: Local Collaboration Networks and the Emergence of New Metal Genres
3. Cross-Band Labor Pools and the Geography of Genre Emergence

## One-paragraph paper pitch

This paper studies why some cities generate new metal scenes earlier than others. Using the full
Metal Archives band universe and a large musician-band membership file, I build a
`city x genre_family x year` panel that tracks when a local genre scene reaches emergence,
defined as the year the city reaches its fifth band in that genre family. The main empirical fact
is not simply that larger cities produce more scenes. Later genre emergence is more likely where
cities have thicker local spawning flow, deeper target-genre band stock, and more musicians who
work across multiple local bands within the target genre. These relationships survive exact-year
fixed effects at the `city-genre` level. The paper is therefore about collaborative local scene
formation and genre-specific labor pooling, not about a narrow blockbuster-shock design.

## What this paper should and should not claim

### Core claim

Local genre emergence tracks scene-specific collaborative infrastructure:

- local spawning flow
- target-genre band stock
- target-genre multi-band musician depth

### Secondary claim

The paper should stay with the clean core mechanism result:

- local spawning flow
- target-genre band stock
- target-genre multi-band depth

### What not to claim

- do not claim full causal identification
- do not build the paper around broker or connector variables
- do not let the opener world map substitute for the actual scene evidence
- do not let theory outrun the reduced-form facts

## Draft abstract skeleton

### Opening problem

Why do some places generate new creative scenes earlier than others, even within the same broad
industry?

### Data sentence

I combine the full Metal Archives band census with a large musician-band membership file to build
city-level collaboration networks and a `city x genre_family x year` panel of local genre
emergence.

### Main descriptive fact

Exact-year emergence rates rise sharply once cities reach modest active-band scale and modest
multi-band depth.

### Main reduced-form result

In exact-year fixed-effects specifications, later genre emergence tracks local spawning flow,
target-genre active band stock, and target-genre multi-band musician depth.

### Interpretation

The pattern is consistent with local spinouts, genre-targeted labor pooling, and recombinant
collaboration within scenes.

### Contribution sentence

The paper shifts attention from superstar shocks to scene formation itself, treating genres as
locally produced collaborative outcomes rather than only as labels attached after the fact.

## Main-text structure

### 1. Introduction

#### Job of the section

- motivate why local creative scenes matter
- make the object genre emergence, not retrospective genre history
- state the empirical contribution cleanly

#### Draft flow

1. Open with global expansion and concentration of metal activity.
2. Pivot to the real question:
   why do some cities convert local activity into a new genre scene earlier than others?
3. State the paper's three headline facts:
   - emergence rates rise with local scene scale and multi-band depth
   - spawning flow and target-genre stock predict later emergence
   - target-genre multi-band depth is the cleanest labor-pooling term
4. State the contribution:
   - new data object: city-level collaboration networks from full Metallum membership records
   - new outcome: local genre emergence timing
   - new mechanism read: spinouts and genre-specific labor pools

#### Figure placement

- Figure 1, optional opener:
  global world map or global metal-expansion figure

### 2. Data and measurement

#### Job of the section

- convince the reader that the scene sample is disciplined and reproducible
- define the outcome and the key predictors in plain language

#### Core inputs

- cleaned all-metal band reference:
  `data/processed/metal_archives_all_metal_band_clean.csv`
- full musician-band edge file:
  `data/processed/scene_networks/full_musician_band_edges.csv`
- city-year network snapshots:
  `data/processed/scene_networks/city_year_network_snapshots.csv`
- city-genre timing file:
  `data/processed/scene_networks/city_genre_first_appearance.csv`

#### Definitions that must be explicit

- `emergence_year`:
  first year the city reaches five bands in a broad genre family
- `local spawning flow`:
  count of newly formed local bands whose founders include musicians with prior local band history
- `target-genre active bands`:
  active local bands in the same broad genre family
- `target-genre multi-band musicians`:
  musicians active in the target genre and in at least two local target-genre bands that year

#### Inputs for this section

- `data/processed/scene_networks/scene_data_cleaning_audit.md`
- `data/processed/scene_networks/scene_variable_measurement_audit.md`

#### Appendix link

Move most mechanical detail into:

- Appendix Figure A1:
  sample-construction flow
- Appendix Table A1:
  variable measurement crosswalk

### 3. Descriptive scene facts

#### Job of the section

- give the reader intuitive scene facts before any regression
- show that the scene branch is not just a complicated table exercise

#### Figure placement

- Figure 2:
  `data/processed/scene_networks/figures/scene_critical_mass_event_rates.png`

#### Points to make in prose

- emergence rises from `1.4%` below `10` active bands to `4.0%` at `40+`
- emergence rises from `1.4%` with `0-1` multi-band musicians to `3.7%` with `10+`
- this does not prove causality, but it shows a clear critical-mass pattern
- the descriptive pattern already points toward local labor pooling and collaborative thickness

### 4. Empirical design

#### Job of the section

- explain the exact-year fixed-effects logic in one clean page
- keep the design reduced-form and disciplined

#### Baseline panel

- unit:
  `city x genre_family x year`
- main specification:
  exact-year fixed effects with `city-genre` and year effects
- rolling predictors:
  `roll-5` baseline, `roll-3` as robustness
- inference:
  standard errors clustered at the city level

#### Minimal equation

$$
Emergence_{cgy} = \alpha_{cg} + \lambda_y + \beta X_{cg,y-1:y-5} + \varepsilon_{cgy}
$$

where `Emergence_{cgy}` is an indicator for a city `c` reaching emergence in genre `g` in year
`y`, and `X` contains lagged scene-composition and target-genre depth measures.

#### Tone rule

Use language like:

- predicts
- is associated with
- tracks later emergence

Avoid language like:

- causes
- identifies
- isolates the true effect of

### 5. Headline results

#### Job of the section

- make the preferred paired specification the empirical center of gravity
- keep the result simple enough that it can be remembered

#### Figure placement

- Figure 3:
  `data/processed/scene_networks/figures/scene_preferred_mechanism_coefficients.png`

#### Panel A message

The stable unconditional scene terms are:

- local spawning flow: `0.0134`
- target-genre active bands: `0.0505`
- target-genre multi-band musicians: `0.0227`

#### Interpretation sentence to reuse

Cities are more likely to generate later genre emergence when they produce more local spinouts,
already have thicker target-genre band stock, and sustain deeper within-genre multi-band labor
pools.

### 6. Mechanism interpretation

#### Job of the section

- interpret the coefficients without pretending they are structural parameters
- connect the patterns to a small set of plausible mechanisms

#### Organizing mechanism story

1. Spinouts:
   local spawning flow suggests new bands are often founded by musicians already embedded in the
   local scene.
2. Genre-targeted labor pooling:
   target-genre band stock and target-genre multi-band depth suggest that what matters is not only
   city size, but relevant local know-how inside the focal genre.
3. Recombination through repeated collaboration:
   within-genre multi-band depth is consistent with local recombination and repeated coordination
   across projects.

### 7. Case-study figure section

#### Job of the section

- give the reader one concrete scene after the reduced-form evidence
- do not let qualitative cases replace the panel results

#### Candidate cases

- Provisional current candidate: `Helsinki / black_metal / 2010`
- Smaller contrast case: `Pittsburgh / doom_metal`
- Other fallbacks only if they become more readable: `Bilbao / black_metal`, `Brussels / metalcore`

### 8. Compact theory section

#### Job of the section

- give the paper a disciplined conceptual model without letting theory outrun the facts

#### What the theory section should do

- formalize why local scene thickness can affect later entry
- distinguish spinouts from generic city scale
- explain why target-genre labor pools may matter more than raw city size

#### What the theory section should not do yet

- do not build a deep structural model before the empirical package is fully locked
- do not optimize around the older domestic-success shock design
- do not write more than a compact conceptual section until the case-study object is chosen

### 9. Conclusion

#### Closing message

The strongest version of the paper is now:

- scenes as collaborative innovation
- genre emergence as the outcome
- local spawning and genre-targeted labor pools as the main mechanisms

Not:

- blockbuster shocks as the only serious design
- bridge musicians as a one-variable explanation

## Figure and table package

### Main text

- Figure 1:
  global metal activity opener
- Figure 2:
  scene critical mass before emergence
- Figure 3:
  preferred paired mechanism coefficients
- Figure 4:
  one case-study network figure, provisional

### Appendix

- Appendix Figure A1:
  sample-construction flow from `scene_data_cleaning_audit.md`
- Appendix Table A1:
  variable crosswalk from `scene_variable_measurement_audit.md`
- Appendix Table A2:
  richer-scene stress tests from `scene_cluster_richer_stress_test_results.csv`
- Appendix Figure A2:
  optional emergence-by-decade chart from `city_genre_first_appearance.csv`

## Writing sequence from here

1. Turn this skeleton into a 2-3 page markdown memo with full prose in the Introduction, Data,
   and Results sections.
2. Convert the audit notes into appendix-ready objects so the main text stays readable.
3. Choose one additional visual only after the first prose draft reveals what is missing.
4. Start LaTeX only after the markdown draft has a stable title, abstract, figure order, and
   appendix plan.
