# 04 Empirical notes

Last updated: 2026-03-21

## Current build status
The outcome side is already usable. The project-specific all-metal build now lives in:

- `data/processed/metal_archives_all_metal_band_clean.csv`
- `data/processed/metal_archives_all_metal_country_year_panel.csv`
- `data/processed/metal_archives_all_metal_summary.md`

The treatment side is the active bottleneck. The current treatment inputs are:

- `data/blockbuster_album_seed.csv`
- `data/blockbuster_hit_rule.md`
- `data/blockbuster_album_country_hits_pilot_sample.csv`
- `data/processed/blockbuster_album_country_hits_core.csv`
- `data/processed/blockbuster_country_year_hit_panel.csv`
- `data/processed/blockbuster_country_year_hit_summary.md`

So the empirical problem is no longer "do we have an outcome?" It is "can we recover auditable
breakthrough timing by country well enough to estimate a disciplined event panel?"

---

# Strategy 1: Country-year curated blockbuster hit panel

**Strategy type:** Country-year reduced-form panel using official chart-entry and certification
events for a curated seed of metal albums.

**Literature.**
The exact academic design anchors still need verification, so this strategy is currently grounded
in auditable measurement rather than in a locked paper list. The practical benchmark is an
event-style cultural-production panel: use visible breakthrough timing rather than proprietary
sales counts, and keep the treatment definition tied to official sources.

**How this applies to the question.**
The baseline outcome is all-metal band entry by country and year from the full Metallum snapshot.
Let `BandsFormed_ct` denote new bands in country `c`, year `t`. Build the treatment from the
curated seed in `data/blockbuster_album_seed.csv`, using the current operational rule in
`data/blockbuster_hit_rule.md`: first official top-10 album-chart entry as the baseline hit
timing, with gold-or-higher certification as fallback. The core treatment variables are:

- `hit_top10_ct`
- `hit_home_top10_ct`
- `hit_foreign_top10_ct`
- `hit_no1_ct`
- `hit_chart_weeks_ct`
- `hit_certified_ct`

The first-pass regression is:

$$
BandsFormed_{ct} = \alpha_c + \lambda_t + \beta_1 hit\_home\_top10_{ct} + \beta_2 hit\_foreign\_top10_{ct} + \beta_3 hit\_home\_certified_{ct} + \beta_4 hit\_foreign\_certified_{ct} + \varepsilon_{ct}.
$$

This is attractive because it is reproducible, country-specific, and tied to official chart
archives rather than to fan-maintained summaries. The main threats are reverse causality, uneven
chart-source depth across countries, and the fact that chart hits may reflect already-rising
scenes. The mitigation is to treat this as a disciplined reduced-form baseline, keep the seed
curated and auditable, and later compare it against narrower first-breakthrough events.

Feasibility is currently strongest in the United Kingdom, Germany, Italy, Australia, and now the
United States, with Brazil still entering as a substantively important but source-weaker manual
extension. The outcome side is already large enough that treatment measurement, not sample
sparsity, is the main constraint. Germany is still added through a manual official-source
supplement, Brazil still enters through a manual supplement because direct Pro-Musica retrieval is
blocked in this environment, Italy is cleaner because the seed includes additional exact
FIMI-recoverable domestic chart rows, Australia enters through a manual official-source supplement
built from the live ARIA chart API, and the United States now enters through a manual official
supplement built from exact public RIAA album-certification matches. The current six-market core
build recovers `85` album-country rows across `37` seed albums:

- Australia: `9` rows, `6` top-10 rows
- Brazil: `6` rows, `2` top-10 rows, `5` certification rows
- Germany: `14` rows, `11` top-10 rows
- United Kingdom: `24` rows, `13` top-10 rows
- Italy: `24` rows, `9` top-10 rows, `2` certification rows
- United States: `8` rows, `8` certification rows
- Exposure split: `7` home-market top-10 rows and `34` foreign-market top-10 rows
- Certification rows recovered: `15`
- Country-year rows with any treatment signal once chart-weeks are counted: `51`

That is enough to move the treatment side beyond a pilot and into a real first-pass event panel.
The design choice after Germany is to keep this country-year intensity panel as the baseline
treatment object. A pure first-breakthrough file remains useful, but it would discard repeated
country-year shocks that already exist in the current build.

The Brazil rows still need to be read carefully. They currently mix:

- one official band press release for `Iron Maiden - The Book of Souls`
- a named journalistic source for `Sepultura - Roots`
- a named historical source for `Sepultura - Nation`
- still-weaker secondary traces for `Angra - Rebirth`, `Angra - Temple of Shadows`, and
  `Sepultura - Dante XXI`

So Brazil is now a somewhat better substantive extension than before, especially because it now
adds explicit Sepultura home-market certification timing in `1996` and `2001` as well as the
existing Brazil home-market top-10 event for `Angra - Temple of Shadows`. But it is still not the
cleanest benchmark market for source purity.

Italy now clarifies a second measurement point. The historical anchor `Lacuna Coil - Comalies`
produces an official FIMI title page but no chart or certification evidence, so it should no
longer be treated as if it were a recoverable domestic treatment row. The cleaner official Italian
rows are currently:

- `Rhapsody - Power of the Dragonflame` with FIMI peak `15` in `W13-2002`
- `Rhapsody of Fire - Triumph or Agony` with FIMI peak `18` in `W40-2006`
- `Lacuna Coil - Delirium` with FIMI peak `11` in `W22-2016`

Those rows matter for official chart-presence intensity and for the broader country-year panel,
but they do not widen the domestic top-10 event sample. So the top-10 rule remains a conservative
baseline, and a secondary official chart-presence margin is now a live design option if the
home-market sample stays too thin.

**References.**
Primary sources:

- Official Charts archive and search tools
- FIMI Top of the Music archive
- `data/source_matrix.csv`
- `data/blockbuster_album_seed.csv`
- `data/blockbuster_hit_rule.md`

Verified academic design anchors pending.

---

# Strategy 2: First home-market breakthrough event study

**Strategy type:** Event-study design around a band's first clear home-market breakthrough.

**Literature.**
The likely academic links are role-model effects, local success signals, and event-study designs
around visible shocks, but the exact paper set still needs verification. This strategy is kept
alive because it may ultimately be more interpretable than a noisy annual intensity panel.

**How this applies to the question.**
Define a band's first home-market breakthrough as the first official top-10 album-chart entry in
its home market, with official certification timing as fallback where chart timing is missing. For
band or album event `b` in country `c_b` and year `t_b`, estimate post-event changes in later band
entry:

$$
BandsFormed_{ct} = \alpha_c + \lambda_t + \sum_{j \neq -1} \beta_j \mathbf{1}[t - t_b = j] + u_{ct}.
$$

This design is especially useful for the motivating mechanism. A band like Sepultura is not mainly
interesting because it adds one more chart hit to Brazil in 1996. It is interesting because it may
serve as a locally legible breakthrough event that changes what later entrants think is possible.

The main threats are selection into breakthrough timing and weak event counts if the seed remains
too small. The mitigation is to keep the home-market definition explicit, begin with a curated seed
of clear candidates, and use this as either a complement to or simplification of Strategy 1.

Feasibility depends on whether the current chart workflow can recover enough reliable first events
for the core markets. The UK, Germany, Italy, and Brazil expansion now exists, so this strategy
survives as a complement to the baseline rather than as the new default treatment object. The
current limitation is still on the home-market event count: the Italy cleanup adds chart-only home
rows, but it does not add new domestic top-10 events, so the complete home-market first-hit sample
remains small.

**References.**
Primary sources:

- `data/blockbuster_album_seed.csv`
- `data/blockbuster_hit_rule.md`
- `data/blockbuster_album_country_hits_pilot_sample.csv`

Verified academic event-study anchors pending.

---

# Strategy 3: Band influence ranking and heterogeneity margins

**Strategy type:** Residualized ranking exercise built from the event panel rather than a separate
stand-alone treatment design.

**Literature.**
This strategy will likely sit closest to superstar spillovers, local role-model effects, and
cultural entrepreneurship. The exact ranking and heterogeneity papers still need to be verified
before any citation-heavy draft is written.

**How this applies to the question.**
Once Strategy 1 or Strategy 2 yields a credible event panel, the project can rank bands by their
downstream entry impact. The ranking should not use naive post-hit counts. Instead, it should
measure post-event entry net of country and year structure over a fixed window. The same workflow
can be run on several margins:

- all-metal entry
- broad genre-family entry
- unsigned entry
- later signed entry
- home-market effects versus foreign-market spillovers

That makes the "most influential bands" question empirical rather than anecdotal. A band could be
highly influential even if later bands do not copy its exact style, as long as its breakthrough is
followed by a large residualized startup wave.

The main threat is overinterpretation. A ranking is only useful if it clearly conditions on
baseline scene growth, common shocks, and the difference between home-market and foreign-market
exposure. So this should remain a derived output from the event panel rather than a free-standing
descriptive list.

The first reproducible memo now exists in `data/processed/blockbuster_band_influence_memo.md`.
It no longer relies on only one narrow event rule. The current workflow compares three
band-market definitions side by side:

- first visible band-market success
- first certification by band-market
- first top-10 by band-market

All three use the same three-year pre/post windows and the same residualization step that partials
out country and year structure on the all-metal and unsigned-entry margins. The memo is still not
a causal estimate, but it is now more disciplined than the earlier raw before/after ranking and
more general than the earlier top-10-only pass.

The current split read matters for the motivating mechanism:

- under `presence`, the home-market sample is much less thin:
  - `12` complete home-market windows
  - strongest home-market presence case so far:
    - `Metallica` in the United States after `Load`
  - Brazil now contributes explicit home-market presence windows for:
    - `Sepultura - Roots`
    - `Angra - Rebirth`
- under `certification`, the sample is now a real secondary margin rather than a token fallback:
  - `10` complete windows total
  - strongest home-market certification case so far:
    - `Metallica` in the United States after `Load`
- under `top10`, the original conservative blockbuster margin still has:
  - `4` complete home-market windows
  - strongest foreign-market top-10 case so far:
    - `Nightwish` in Germany after `Once`
- current pooled dynamic limitation:
  - the aggregate event-study profiles remain descriptive and somewhat noisy, so the residualized
    ranking is still more informative than the average event path

**References.**
Primary project references:

- `notes/01_project_overview.md`
- `notes/03_model_notes.md`
- `data/processed/blockbuster_band_influence_event_study.csv`

Verified academic ranking anchors pending.

---

# Strategy 4: Country-genre breakthrough panel

**Strategy type:** `country x genre_family x year` event panel that compares later entry in the
same genre family after a domestically visible breakthrough.

**Literature.**
The exact paper set still needs verification, but this is the most natural place to connect the
project to local role-model effects, cultural entrepreneurship, and triple-difference style event
designs. The measurement object is stronger than a pooled all-metal panel because it compares the
same broad genre family across countries rather than treating all later metal entry as equally
close to the breakthrough.

**How this applies to the question.**
The motivating version is no longer just "did country `c` get more metal bands after one famous
band?" It is "did country `c` get more later entry in genre family `g` than other countries got in
that same genre family, net of country-wide metal growth and global genre growth?"

That suggests the following unit of observation:

- `country c x genre_family g x year t`

Let `BandsFormed_cgt` denote new bands in country `c`, broad genre family `g`, and year `t`.
Let `Breakthrough_cgt` denote a first visible domestic breakthrough in that same country-genre
cell. The disciplined panel regression is then:

$$
BandsFormed_{cgt} = \alpha_{cg} + \lambda_{gt} + \mu_{ct} + \beta Breakthrough_{cgt} + \varepsilon_{cgt}.
$$

This absorbs:

- stable country-genre differences through `\alpha_{cg}`
- global booms in a genre through `\lambda_{gt}`
- country-wide metal booms through `\mu_{ct}`

That is the cleanest way to isolate the domestic-exemplar mechanism the project actually cares
about.

The current prototype now exists on the outcome side. Using
`data/processed/metal_archives_all_metal_band_clean.csv`, the project now builds a reusable broad
family panel and a first illustrative graph in:

- `data/processed/country_genre_analysis/country_genre_family_year_panel.csv`
- `data/processed/country_genre_analysis/brazil_thrash_vs_rest_of_world.csv`
- `data/processed/country_genre_analysis/brazil_thrash_metal_vs_rest_of_world_share.png`
- `data/processed/country_genre_analysis/country_genre_growth_summary.md`
- `data/processed/country_genre_analysis/domestic_success_spillover_rule.md`
- `data/processed/country_genre_analysis/foreign_spillover_coding_preview.csv`
- `data/processed/country_genre_analysis/foreign_spillover_coding_summary.md`
- `data/processed/country_genre_analysis/language_spillover_market_priority.csv`
- `data/processed/country_genre_analysis/language_spillover_market_priority.md`
- `data/processed/country_genre_analysis/australia_aria_seed_overlap.csv`
- `data/processed/country_genre_analysis/usa_riaa_seed_probe.csv`
- `data/processed/country_genre_analysis/language_spillover_build_readiness.md`

The current graphs are descriptive rather than causal. They are there to verify that the object is
worth building before breakthrough timing is curated. One graph compares an illustrative
country-genre case against the rest of the world, and a second compares several large countries in
the same broad genre family on one chart. Those are examples of the panel, not privileged
substantive cases.

The first spillover-coding rule now also exists in
`data/processed/country_genre_analysis/domestic_success_spillover_rule.md`, together with a
mechanical preview based on the existing core treatment panel. In the original preview, run on the
then-current four-market build, that preview classifies rows as:

- `12` `domestic_success`
- `10` `same_language_foreign`
- `24` `different_language_foreign`
- `1` `multiple_language_foreign`

The rule is therefore implementable with the current data. But the preview also shows the current
limitation very clearly: most same-language foreign rows come from English-language foreign acts
hitting the UK, while Germany, Italy, and Brazil contribute mainly different-language foreign
exposure. So the language-spillover idea is conceptually sharp, but the present market set is not
yet rich enough to estimate it convincingly without expansion.

The market-priority pass makes the language composition explicit. The refreshed curated seed now
has `37` albums, `33` of which are English-language. So the same-language foreign design is still
mostly an English-market design, but the market ranking changed once Australia was actually built.
`Australia` is now a built same-language reference market, and `United States` is now also built
as a certification-led reference market under the currently audited public source path. `Sweden`,
`France`, and the other already-built non-English reference markets are still low-yield for the
same-language question unless the seed later expands toward more non-English-language flagship
acts.

The source-readiness pass now points to two built English-language reference markets rather than a
single next follow-up.
`Australia` still has a shallow public official history, with ARIA related dates currently exposed
only back to `2019-07-01`. But the refreshed seed overlaps `9` albums in that public window, and
those rows are now in the core panel:

- `Metallica - 72 Seasons`
- `Iron Maiden - Senjutsu`
- `Rammstein - Zeit`
- `Judas Priest - Invincible Shield`
- `Nightwish - Human. :II: Nature.`
- `Lacuna Coil - Black Anima`
- `Sabaton - The War to End All Wars`
- `Ghost - Impera`
- `Gojira - Fortitude`

`United States` keeps the deeper historical path through public RIAA search pages and now has
exact album-format certification matches for `8` seed albums, all of which are now in the current
core supplement:

- `Metallica - Load`
- `Metallica - Death Magnetic`
- `Sepultura - Roots`
- `Rammstein - Sehnsucht`
- `Pantera - The Great Southern Trendkill`
- `Lamb of God - Ashes of the Wake`
- `Slipknot - All Hope Is Gone`
- `Disturbed - Immortalized`

So the seed refresh plus the Australia and U.S. builds did what they needed to do. `Australia` is
no longer a one-row modern edge case; it is now a usable same-language reference market, and the
`United States` is no longer just a readiness prospect but an active certification-led market in
the core panel.

**Visible-breakthrough measurement note.**
The eventual breakthrough event does not need to be album-only. A breakthrough song can plausibly
be the relevant exposure event if it is the first moment when a band becomes locally salient
through radio, television, streaming, or other broad circulation channels. So the broader
treatment object should be "first visible breakthrough in market `c`," not mechanically "first hit
album."

The practical caution is genre-specific. For metal, official album charts and certifications are
usually easier to recover consistently across countries than singles-chart histories, and singles
data may bias the sample toward crossover bands. So song-led breakthroughs should stay in the
project as an explicit exploration path or composite fallback rather than silently replacing the
album-based baseline.

One concrete extension to explore later is a composite rule:

- first official top-40 or top-10 album-chart entry
- or first official top-40 or top-10 song-chart entry
- or first gold-or-higher certification
- or first official chart-presence event in thin-source markets

That would let the data distinguish `song-led`, `album-led`, and `certification-led` visibility
events without forcing one exposure channel on every market.

Current prototype read:

- the broad family panel currently tracks `18` genre families
- it yields a large reusable country-genre-year outcome object before any breakthrough timing is
  imposed
- the selected-country prototype graph confirms that the same genre family can have very different
  time paths across countries even after normalizing by each country's total metal starts
- that makes a within-genre, across-country design look much more promising than a pooled
  all-metal comparison alone
- the broad family panel now also preserves `all`, `unsigned`, and `signed` band-start margins in
  the same output file, so the country-genre pass no longer depends on a single total-entry
  outcome

That pattern is substantively useful. It suggests the right object may be genre salience within a
country rather than only raw counts of new bands.

The first actual domestic-success pilot pass now exists in:

- `data/processed/country_genre_analysis/domestic_success_pilot_case_years.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_event_windows.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_event_study.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_event_pass_summary.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_share_gap_event_study.png`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_static.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.png`

That pilot locks two practical choices for the next stage:

- use `presence` as the main descriptive event baseline
- keep broad `genre_family` cells as the first country-genre baseline

The current pilot read is mixed and, after residualization, not encouraging:

- the treatment file is now `10` hand-coded `country x genre_family` cases
- strongest positive descriptive case so far:
  - `Sepultura` in Brazil `thrash metal`
- current all-band share-gap improvement count:
  - `3` pilot cases improve
  - `7` deteriorate
- pooled all-band share gap:
  - about `5.2` percentage points in the pre-period mean
  - about `2.9` in the post-period mean
- first residualized FE read on all starts:
  - full-pilot static coefficient:
    - about `-7.5` with clustered SE `5.0`
  - strict `source_a + tier_1` subset static coefficient:
    - about `-11.8` with clustered SE `7.1`
  - average full-pilot lead coefficients:
    - about `+2.9`
  - average full-pilot post coefficients:
    - about `-4.1`

That is informative even though it is not yet a positive headline result. The country-genre
object itself is buildable, but the current timing is probably too late and the treatment file is
too heterogeneous. In practice, several current pilot events already look late relative to local
scene takeoff, which is exactly what the positive lead coefficients are flagging.

**Main threats.**
The first threat is timing. "First observed band in genre-country cell" is not the same as
"first domestically visible breakthrough." The second threat is classification. Metal Archives
genre strings are highly fragmented, so the first-pass panel must use broad families or another
auditable grouping rather than pretending every raw tag is a stable unit. The third threat is
overlap: bands can belong to more than one broad family, so the panel is inherently multi-label.

**Practical implication.**
This is still the strongest live refinement of the project's motivating mechanism, but the first
residualized pass says the treatment file is not ready to carry the project yet. The next real
step is no longer to prove that the object can be built or to run the first fixed-effects model.
Both now exist. The next step is to re-date or replace weak pilot rows, then expand only with
earlier and higher-confidence domestic-success cases, and only then rerun the residualized panel
with country-genre, country-year, and genre-year structure. The first operational rule for the
treatment file still lives in
`data/processed/country_genre_analysis/domestic_success_pilot_design.md`, and the current pilot
case file still lives in `data/processed/country_genre_analysis/domestic_success_pilot_cases.csv`.
Brazil `thrash metal` remains one possible case, not the required anchor case.

**References.**
Primary project references:

- `data/processed/country_genre_analysis/country_genre_family_year_panel.csv`
- `data/processed/country_genre_analysis/country_genre_growth_summary.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_design.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_cases.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_cases_summary.md`
- `data/processed/country_genre_analysis/thrash_metal_selected_countries_share.png`
- `data/processed/genre_analysis/genre_analysis_summary.md`

Verified academic country-genre design anchors pending.

---

# Strategy 5: Scene complements and breakout success

**Strategy type:** Treat domestic breakout success as partly predicted by prior scene depth and
complementary local inputs rather than only as an ex post shock to entry.

**Literature.**
The exact anchor papers still need verification, but this strategy is the closest fit to economic
geography, agglomeration in cultural production, and scene-formation accounts where local
complements make flagship success possible.

**How this applies to the question.**
The current negative fixed-effects pass makes this alternative too plausible to ignore. Positive
lead coefficients suggest that several coded treatment cells were already growing before the
breakthrough year. One interpretation is simply poor timing. Another is that the band is emerging
from a scene that was already thickening.

On this reading, the empirical question changes from:

- did breakout success cause more later entry?

to:

- did prior local scene complements help predict which country-genre cells produced breakout
  success?

The most practical first-pass predictors are already close to the current data:

- lagged band starts in the same `country x genre_family`
- lagged unsigned starts in the same `country x genre_family`
- lagged country-wide all-metal starts
- lagged genre share within country-year
- pre-period growth rates rather than only pre-period levels

The first stripped-down prediction equation is:

$$
Breakthrough_{cg,t} = \alpha_{cg} + \lambda_t + \beta_1 LaggedEntry_{cg,t-k} + \beta_2 LaggedUnsigned_{cg,t-k} + \beta_3 LaggedShare_{cg,t-k} + \varepsilon_{cgt}.
$$

This is not yet a clean causal design, but it is a disciplined way to test whether the current
pilot is better understood as a scene-milestone story than as a pure inspiration shock.

If the complements story looks strong, the second-stage question becomes whether breakout success
then produces further acceleration. That would suggest testing:

- slope changes rather than level shifts
- unsigned entry first, signed entry later
- auxiliary scene outcomes where data can be built later, such as labels or festival activity

**Exploration plan.**
The right exploration sequence is narrow and diagnostic:

1. For the current pilot cases, measure pre-breakthrough scene depth and pre-trends directly.
2. Rank pilot rows by how late the coded breakthrough looks relative to local scene growth.
3. Build a simple pilot prediction file where the dependent variable is whether a
   `country x genre_family` cell eventually produces a coded domestic success.
4. Test whether lagged same-genre entry and lagged unsigned entry predict that outcome.
5. Only after that, decide whether the project should keep foregrounding breakthrough-as-shock or
   shift toward breakthrough-as-scene-milestone.

**Practical implication.**
This is now a real alternative to test, not just a verbal caveat. If it fits the data better than
the one-way shock story, the project may become stronger as a paper about scene complements and
creative-market thickening than as a pure domestic-exemplar paper.

The first diagnostic now exists in:

- `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_case_years.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_case_metrics.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_rankings.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_summary.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_scatter.png`

Current diagnostic read:

- mature-scene milestone candidates:
  - `Dimmu Borgir` in Norway black metal
  - `Rhapsody` in Italian power metal
- rising-scene breakthrough candidates:
  - `Nightwish` in Finnish symphonic metal
  - `Sepultura` in Brazilian thrash metal
- deep and still-thickening cases:
  - `Pantera` and `Metallica` in the United States

That is still heuristic rather than causal, but it is useful. It suggests the complements story is
not just a verbal rescue for the failed FE pass. It is picking out a different structure in the
same pilot rows and gives a disciplined way to separate rows that look like mature-scene
milestones from rows that still look compatible with a rising-scene breakthrough story.

The first qualitative scene-history pass now exists in:

- `data/processed/country_genre_analysis/scene_qualitative_evidence_source_map.csv`
- `data/processed/country_genre_analysis/scene_qualitative_evidence_memo.md`

Current qualitative read:

- strongest mature-scene milestone cases:
  - `Dimmu Borgir` / Norway black metal
  - `Rhapsody` / Italy power metal
  - `Metallica` / U.S. heavy metal
- clearest mixed scene-plus-breakthrough case:
  - `Sepultura` / Brazil thrash metal
- clearest rising-scene or scene-building case:
  - `Nightwish` / Finland symphonic metal

That qualitative evidence is useful because it lines up with the new quantitative diagnostic in a
nontrivial way. It makes the complements fork more credible and gives the treatment cleanup a
better basis than raw counts alone.

**References.**
Primary project references:

- `data/processed/country_genre_analysis/domestic_success_pilot_event_windows.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary.md`
- `data/processed/country_genre_analysis/country_genre_family_year_panel.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_summary.md`
- `data/processed/country_genre_analysis/scene_qualitative_evidence_memo.md`

Verified academic scene-complements anchors pending.
