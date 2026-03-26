# 05 Research plan

Last updated: 2026-03-21
Status: country-year baseline locked; home-vs-foreign split added; Brazil supplement partly hardened; Italy official cleanup added; broader visibility-vs-certification-vs-top10 memo written; country-genre family prototype added; language-spillover market ranking added; seed refresh completed; Australia extension built; United States certification extension built; domestic-success pilot expanded; first FE pass built

## Chosen question and estimand
Primary question: do blockbuster metal albums in a country or shared-language market induce later
local band formation?

Primary estimand: the lagged association between a visible breakthrough shock and later band entry
in the same country-year panel.
Current baseline decomposition: estimate domestic exemplar and foreign-blockbuster exposure
separately inside the same country-year panel.

Secondary live question: which bands appear most influential for later startup, measured by
residualized downstream entry effects rather than by style alone?

Alternative live question: do local scene complements help predict which `country x genre_family`
cells produce a domestic breakout success in the first place?

## Chosen models
Baseline model: Model 1 from `03_model_notes.md`, where a country-level breakthrough acts as a
local entry shock.

Extension model: Model 2 from `03_model_notes.md`, which adds shared-language spillovers once the
country-year panel is stable.

Derived-output model: Model 3 from `03_model_notes.md`, which converts the event panel into a
band-influence ranking across all-metal, genre-family, and unsigned-entry margins.

## Chosen empirical strategies
Baseline strategy: Strategy 1 from `04_empirical_notes.md`, a country-year curated-blockbuster
hit panel built from official chart and certification sources, now split into home-market and
foreign-market exposure.

Current descriptive event baseline inside that workflow: `presence`.
Current conservative robustness margin: `top10`.

Secondary strategy: Strategy 2 from `04_empirical_notes.md`, a first-breakthrough event-study
design used as a derived diagnostic once enough home-market timing is recovered.

Derived ranking output: Strategy 3 from `04_empirical_notes.md`, which uses the event panel to
rank bands by downstream entry impact after conditioning on country and year structure.

Live refinement: Strategy 4 from `04_empirical_notes.md`, which recasts the outcome as a
`country x genre_family x year` panel so domestic breakthroughs can be tested against the same
genre elsewhere rather than against pooled all-metal growth alone.

Alternative mechanism test: Strategy 5 from `04_empirical_notes.md`, which treats breakout success
as partly predicted by prior scene depth and complementary local inputs.

## Data access and fallback
Outcome side:

- use the full Metallum SQLite snapshot
- keep the all-metal build in `data/processed/` as the default baseline outcome

Treatment side:

- baseline path: official chart archives and certification sources for a curated blockbuster seed
- first core markets now built: Australia, Brazil, Germany, United Kingdom, Italy, United States
- Brazil currently enters through a provisional manual supplement because direct Pro-Musica
  retrieval is blocked in this environment
- the Sepultura side of Brazil is now stronger:
  - `Roots` enters as a named journalistic-source gold row in `1996`
  - `Nation` now uses a named historical source and moves to `2001`
- Italy now contributes additional official home-market chart-presence rows, but they do not add
  new top-10 or certification events
- United States now enters through a certification-led RIAA supplement with `8` exact public
  album-certification matches
- current split count: `7` home-market top-10 rows and `34` foreign-market top-10 rows
- current country-year panel count with any treatment signal once chart-weeks are counted: `51`
- the downstream influence workflow now compares three band-market definitions:
  - `presence`: `45` complete windows
  - `certification`: `10` complete windows
  - `top10`: `19` complete windows
- the domestic-success pilot is now built in `data/processed/country_genre_analysis/` with:
  - `10` pilot cases
  - broad `genre_family` outcomes
  - `all`, `unsigned`, and `signed` margins
  - a first residualized FE pass already estimated

Fallback path:

- if chart extraction proves too noisy, pivot to certification-only timing in a smaller set of
  countries
- if full country-year intensity is too sparse, pivot to a first-breakthrough event file

## Decision log
- Rejected exact global sales-by-country panels as the first pass because they are not currently a
  low-friction, auditable data path.
- Rejected technical-death-only outcomes as the baseline because the blockbuster mechanism is much
  broader than that subgenre.
- Rejected language-first treatment coding as the baseline because country-year treatment can be
  built more cleanly before language exposure is introduced.
- After adding Germany, kept the country-year intensity panel as the baseline treatment object
  because a pure first-breakthrough file would discard repeated country-year shocks that are
  already informative in the three-market build.
- After adding the home-versus-foreign split, kept the same country-year baseline rather than
  branching into a separate domestic-only workflow, because the right comparison is now internal to
  the same panel.
- After adding Brazil, kept the same baseline treatment object and recorded Brazil explicitly as a
  provisional source-weaker extension rather than pretending it is already a clean official-source
  market.
- After adding the residualized ranking pass, treated the ranking as the stronger current
  descriptive read and treated the pooled event-study profile as informative but still noisy.
- After the Italy cleanup, kept the top-10 baseline in place but recorded that clean domestic
  chart-presence rows can exist without generating new top-10 events, so a secondary official
  chart-presence margin is now a live option rather than a scope mistake.
- After the Brazil Sepultura hardening pass, kept Brazil in the core build but recorded that it is
  now a mixed-source market with named sources for `Roots` and `Nation`, while `Dante XXI` and
  the Angra rows remain weaker.
- After the broader visibility pass, stopped treating `top10` as the only meaningful band-market
  event and elevated the choice among `presence`, `certification`, and `top10` into an explicit
  project decision.
- After building the first country-genre prototype, treated the `country x genre_family x year`
  panel as the strongest live refinement of the motivating mechanism, while keeping the broader
  country-year all-metal panel as the current baseline until breakthrough timing is curated.
- After ranking and probing the audited markets for the language-spillover extension, recorded
  that the old seed was the binding constraint: `Australia` overlapped only one seed album under
  the public ARIA history window and `United States` yielded only four exact album-format RIAA
  certification matches.
- After refreshing the seed and rebuilding the current four-market panel, recorded that the
  constraint has eased materially:
  - the seed is now `37` albums, `33` of which are English-language
  - `Australia` now overlaps `9` seed albums under the current public ARIA history window
  - `United States` now yields `8` exact album-format RIAA certification matches
  - the current four-market core treatment build expands to `68` album-country rows, `35` top-10
    rows, and `42` country-year rows with some treatment signal
  - practical implication: `Australia` is now the cleanest next same-language market build rather
    than a thin placeholder
- After actually building the Australia extension, recorded that:
  - the core treatment build is now five-market rather than four-market
  - the panel rises to `77` album-country rows, `41` top-10 rows, and `46` country-year rows with
    some treatment signal
  - the next live treatment decision is now `United States` extension versus Brazil source
    hardening, not whether Australia is worth doing
- After actually building the United States extension, recorded that:
  - the core treatment build is now six-market rather than five-market
  - the panel rises to `85` album-country rows, `41` top-10 rows, `15` certification rows, and
    `51` country-year rows with some treatment signal
  - the broader event definitions widen materially:
    - `presence`: `57` band-market events and `45` complete windows
    - `certification`: `11` band-market events and `10` complete windows
  - strongest home-market `presence` and `certification` case now becomes:
    - `Metallica` in the United States after `Load`
  - practical implication: the next live choices are no longer whether to build the U.S., but
    whether to keep `presence` as the main descriptive object, whether to keep spending time on
    Brazil hardening, and whether to move into the first real country-genre domestic-success pass
- After actually building the first domestic-success pilot pass, recorded that:
  - `presence` is now the main descriptive baseline for the next stage
  - broad `genre_family` cells are now the first country-genre baseline
  - the pilot read is heterogeneous rather than cleanly positive:
    - `3` of `10` pilot cases improve on the all-band share-gap margin
    - `7` deteriorate
    - pooled all-band share gap drifts from about `5.2` percentage points in the pre-period mean
      to about `2.9` in the post-period mean
  - practical implication:
    - the project no longer needs more generic market builds before testing the country-genre
      design
    - the next bottleneck is event timing quality and treatment-file quality
- After expanding the pilot and running the first residualized FE pass, recorded that:
  - the full-pilot static coefficient on all starts is about `-7.5` with clustered SE `5.0`
  - the strict `source_a + tier_1` subset static coefficient on all starts is about `-11.8`
    with clustered SE `7.1`
  - average lead coefficients on all starts are positive while average post coefficients are
    negative
  - practical implication:
    - the current treatment timing looks late or heterogeneous
    - the next move is to re-date or replace weak pilot rows before widening the file again
- After the first negative FE pass, recorded that a second mechanism is now live enough to test
  directly:
  - local scene complements may help predict breakout success
  - the project should therefore keep two empirical forks alive:
    - breakout as domestic-exemplar shock
    - breakout as scene milestone produced by prior scene thickening
- After building the first scene-complements diagnostic, recorded that:
  - the complements fork already separates the current pilot rows in a useful way
  - mature-scene milestone candidates currently include:
    - `Dimmu Borgir` in Norway black metal
    - `Rhapsody` in Italian power metal
  - rising-scene breakthrough candidates currently include:
    - `Nightwish` in Finnish symphonic metal
    - `Sepultura` in Brazilian thrash metal
  - practical implication:
    - the next use of this fork is to help prune or re-date weak rows in the original shock
      design
    - a true breakout-prediction risk file is now worth considering if the complements fork
      remains promising
- After building the qualitative scene-evidence memo, recorded that:
  - the qualitative scene histories line up with the complements diagnostic rather than cutting
    against it
  - strongest mature-scene milestone cases now look especially weak for the original shock design:
    - `Dimmu Borgir`
    - `Rhapsody`
    - `Metallica`
  - clearest rising-scene or mixed cases now look relatively better for continued treatment work:
    - `Nightwish`
    - `Sepultura`
  - practical implication:
    - the next pass should use both quantitative and qualitative evidence to prune or re-date the
      shock-treatment file

## Design lock criteria
Keep the current baseline if:

- the UK and Italy extraction scales to the active metal seed without excessive manual cleaning
- Germany can be added without breaking the workflow
- the resulting event panel yields enough timing variation to estimate a disciplined country-year
  design

Current read:

- these criteria are met at a first-pass level, so the baseline remains the country-year hit panel
- first-hit band-market windows stay in the project as a diagnostic and influence-ranking layer
- the conservative `top10` home-market side is still thin, with `4` complete windows even after
  the U.S. build, although the broader `presence` margin now has `12` complete home-market windows
- the main descriptive event choice is now effectively settled in favor of `presence`
- the next treatment gains should target the domestic-success treatment file itself rather than
  more pooled foreign-hit coverage
- the first residualized country-genre pass is now built, and its negative read reinforces that
  source quality and event timing must improve before the design is persuasive

Pivot more aggressively toward a simpler event-study file if:

- official chart extraction remains too manual
- the annual intensity panel is too noisy relative to the number of credible breakthrough events
- country-year timing proves much less reliable than first breakthrough timing

## Alternative exploration plan: scene complements
This is a bounded side-track, not a full redesign yet.

1. Measure pre-breakthrough scene depth for the current pilot rows.
   Use lagged same-genre starts, lagged unsigned starts, lagged country-wide metal starts, and
   lagged genre share within country-year.
2. Rank pilot rows by likely late coding.
   Flag cases where local scene growth is already strong well before the coded breakout year.
3. Build a pilot breakout-prediction file.
   Unit: `country x genre_family x year` or a collapsed `country x genre_family` pilot table,
   depending on the cleanest first pass.
4. Test whether scene complements predict later domestic success.
   Start descriptively, then add a simple prediction specification before anything more ambitious.
5. Compare the two stories explicitly.
   Ask whether the same cases that look weak in the post-breakthrough design look strong in the
   pre-breakthrough complements design.

Success condition for this fork:

- if lagged scene depth and lagged unsigned entry systematically predict domestic success, keep
  this as a serious alternative framing
- if not, return focus to treatment timing and the domestic-exemplar event design

## Domestic-success build checklist
This is the concrete build order for the stronger version of the project.

1. Define `domestic success` precisely.
   Use a visibly successful home-country act in a specific `country x genre` cell, not the first
   obscure band to exist there.
2. Choose the breakthrough rule.
   Start with an auditable rule such as first official chart presence, first top-10 album, first
   gold certification, first major foreign-label release, or a composite visible-breakthrough
   rule.
3. Lock the unit of analysis.
   Use `country x genre_family x year` as the default panel.
4. Lock the outcome definition.
   Keep broad genre families as the first baseline and revisit narrower parsed tags only after the
   broader panel is working.
5. Build the domestic treatment file.
   For each pilot `country x genre`, record the first domestic breakthrough year and the source
   type behind it.
6. Build the foreign spillover file.
   For the same genre-years, code:
   - domestic breakthrough
   - same-language foreign breakthrough
   - different-language foreign breakthrough
7. Estimate the stripped-down specification first.
   Start with country-genre, country-year, and genre-year fixed effects before adding more margins.
8. Check the mechanism margins.
   Test whether the response is stronger for unsigned entry than for signed entry, whether it is
   larger in thinner prior scenes, and whether same-language spillovers matter more than distant
   foreign exposure.
9. Decide continuation based on that result.
   If the domestic-success signal is weak even in the cleaner country-genre design, do not keep
   widening the data build just to save the project.

## Next 3 tasks
1. Re-date or replace the weakest pilot rows, especially cases that already look mature before the
   coded breakthrough year.
   Owner: Codex
   Deliverable: `data/processed/country_genre_analysis/domestic_success_pilot_cases.csv`
2. Decide whether to build a broader breakout-prediction risk file for the scene-complements fork.
   Owner: Codex
   Deliverable: `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_summary.md`
3. Expand the domestic-success treatment file only with earlier and higher-confidence
   `country x genre_family` rows, using the qualitative scene memo as a pruning aid, then rerun
   the FE pass.
   Owner: Codex
   Deliverable: `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary.md`
