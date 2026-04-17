# Metal

**Canonical status tracker**: `research_ideas/metal/STATUS.md`

## One-line objective
Study how local scenes in metal generate new genre emergence and, as a sidecar question, later
successful bands, using domestic breakthrough shocks only as a fallback design.

## Workflow (current)
- Paper drafting has now started.
- The live paper draft is in `drafts/`, with `notes/` retained as upstream source material.
- Current writing workflow:
  - develop paper prose and structure in `drafts/metal.tex`
  - keep `notes/` as the design and evidence archive behind the paper draft
- Local storage rule:
  - track code, notes, and small hand-built source tables in git
  - keep `data/raw/` and `data/processed/` out of git and on `D:\AI_data\research_ideas\metal\`
    via local junctions on this machine

## Current status
The live workflow should be read in three layers:

- main paper: `scene -> genre emergence`
- active sidecar: `scene -> band success`
- fallback: `domestic breakthrough shock -> later entry`

The active band-success sidecar already has working data objects in `data/processed/band_success/`,
and the audited home-market coverage is now wider: the current file reaches `16` matched
`presence` cases, `5` certification cases, and `9` top-10 cases across `BRA`, `DEU`, `FIN`,
`FRA`, `GBR`, `ITA`, `NOR`, `SWE`, and `USA`. The cleaner redesign is now an upgrading-ladder
workflow in `notes/11_band_upgrading_ladder.md`, where the preferred sidecar question is whether a
`city x genre_family x formed_year` cohort produces a home-market validated winner within a
bounded horizon. That is conceptually much better than the older `ever successful band` idea, but
it is still too sparse to become a main paper result.

The thick-scene network figure is still provisional and is currently parked rather than treated as
the active bottleneck. The Helsinki black-metal cases remain useful as exploratory visuals, but the
paper should not wait on a network figure. Pittsburgh remains only a smaller mechanism contrast.

There is now also a first exploratory scene-diffusion prototype in
`notes/12_scene_diffusion_workflow.md`. The initial black-metal build creates a live animated world
map from `895` matched city coordinates and `14,694` matched city-year observations. That branch is
descriptive rather than causal and should stay secondary for now, but it already looks more like a
hub-spread story than a single-birthplace story.

There is also a separate band-level world animation branch in
`notes/13_band_world_animation_workflow.md`. The black-metal prototype uses `101,092` matched
band-year observations on a `3`-year grid and is the closest thing in the project to the “moving
map of active bands” idea. It is still exploratory.

The first serious diffusion panel now exists too in `notes/14_scene_diffusion_exposure_panel.md`.
In the black-metal prototype, lagged exposure to already-emerged hubs is positive on its own, but
it washes out once lagged local same-genre band stock is included. That keeps the diffusion branch
interesting, but it currently reads more like a complement to the main local-thickness result than
as a rival headline.

The first cross-genre diffusion comparison is now in `notes/15_multi_genre_diffusion_check.md`.
Across `black_metal`, `death_metal`, `thrash_metal`, `doom_metal`, and `power_metal`, the broad
read is similar: the maps show spread, but the external hub-exposure terms mostly do not survive
once local same-genre thickness is included. That keeps diffusion as descriptive support rather
than the core empirical spine.

There is now also a broad digital-era robustness split in `notes/16_digital_era_split_probe.md`.
Using the preferred exact-year fixed-effects scene specification, the local spawning-flow and
target-genre band-stock terms attenuate from the pre-1995 sample to `2005-2014`, but the
target-genre multi-band-musician term stays stable. That is useful as a descriptive check on
whether the local-scene result survives into the more digital period without pretending to isolate
 a clean internet effect.

The live writing object is now `notes/08_scene_paper_sections.md`, which has been tightened into
first full-draft prose for the Introduction, Data and Measurement, and Results sections, and now
includes the compact conceptual framework aligned to the live empirical result. The draft is now
explicitly organized around `Data`, `Empirical approach`, and `Results`.

Those notes now feed a first solo-author LaTeX paper draft in:

- `drafts/metal.tex`
- `drafts/sections/model.tex`
- `drafts/sections/data.tex`
- `drafts/sections/method.tex`
- `drafts/sections/results.tex`

The first compiled paper output is:

- `drafts/metal.pdf`

The draft now also includes:

- a literature-review section that connects the project to music markets, creative geography, and
  varieties or spillovers models
- an empirical-motivation section with a global genre-proliferation figure and a static black-metal
  diffusion figure
- a compact model section before the data and empirical design

The project scaffold is now separate from `learning_by_viewing`. The treatment-side audit points to
a concrete first path: do not chase full country-year album sales. Instead, build a curated
blockbuster-album panel using official chart archives and certification thresholds in a core set
of countries, then add language spillovers only after the country-year hit shock is working. The
project now has an active curated seed in `data/blockbuster_album_seed.csv`, a locked first-pass
operational rule in `data/blockbuster_hit_rule.md`, and a current core treatment build in:

- `data/processed/blockbuster_album_country_hits_core.csv`
- `data/processed/blockbuster_country_year_hit_panel.csv`
- `data/processed/blockbuster_country_year_hit_summary.md`
- `data/processed/blockbuster_band_influence_memo.md`

As of `2026-03-26`, the project also has the full Metal Archives member dump staged in
`data/raw/band_members_20260325.zip`. The ingest pipeline now supports the delivered role-level
schema and writes:

- `data/processed/scene_networks/full_musician_band_edges.csv`
- `data/processed/scene_networks/full_member_ingest_summary.md`

The city-network branch is now no longer limited to Wikipedia pilots. It has been scaled to the
full dump and currently writes:

- `data/processed/scene_networks/city_network_stats.csv`
- `data/processed/scene_networks/city_band_band_edges.csv`
- `data/processed/scene_networks/city_network_summary.md`
- `data/processed/scene_networks/mechanism_test_results.md`
- `data/processed/scene_networks/city_year_network_snapshots.csv`
- `data/processed/scene_networks/community_vs_label_timing.csv`
- `data/processed/scene_networks/community_vs_label_results.md`

Current read from that branch:

- ingest scale:
  - `1,038,533` raw member-role rows
  - `971,877` unique member-band edges
  - `682,126` unique musicians
  - `152,923` musicians in `2+` bands (`22.4%`)
- city-network scale:
  - `22,572` cities with any member-linked bands
  - `2,319` cities with `10+` bands
- first mechanism pass:
  - residualized density is negative
  - residualized clustering is positive
  - residualized bridge-musician share is positive and currently the strongest simple
    cross-sectional predictor of genre-emergence counts

The practical implication is that the scenes-as-innovation branch is now empirically real rather
than just a model note. The lagged timing test also now exists rather than sitting on the to-do
list, and it now has a materially cleaner geography baseline. The raw full pass from
`code/24_test_community_precedes_label.py` built `34,645` lagged city-year snapshots and `5,756`
city-genre timing comparisons, with `529` `community_precedes_label` cases. After adding a
reusable geography audit in `code/25_audit_scene_geography.py` and rerunning under stricter
thresholds (`min_bands = 10`, `community_min_genre_bands = 4`, `genre_share_threshold = 0.67`),
the current strict city-baseline read is `32,684` snapshots, `5,429` timing rows, `21` precedes
cases, `86` same-year cases, and `5,322` undetected cases; the median lead among precedes cases
remains `4` years. The main substantive read is therefore no longer "there might be a large
pre-label community margin." It is that the original headline collapses sharply under cleaner
geography, but the surviving `21` precedes cases do not disappear. A surviving-case audit
classifies those `21` into `8` broad-scene cases, `3` mid-scene cases, and `10` fragile cases,
with `black_metal` accounting for `11` of the `21`. The key robustness read is tighter still:
increasing the genre-share threshold from `0.67` to `0.75` leaves the precedes count at `21`, but
requiring `5` same-genre bands collapses it to `0`, because every surviving case is detected on
exactly `4` same-genre bands. Region-like units are now handled explicitly as a side object rather
than mixed into the baseline: the sidecar run adds only one extra precedes case,
`Utrecht Province, Netherlands` in `black_metal`, while the other `133` region-like rows remain
undetected. The broad-case review packets now give a first actual manual-validation read:
`4` of the `8` broad cases show clear `multi_bridge_support`, `2` are `hub_bridge_mixed`, and
`2` are `single_bridge_risk`. The strongest local-network cases are currently `Pittsburgh`,
`Bilbao`, and `Brussels`; `Córdoba` and `Nagoya` remain live but more mixed; `Girona` and
`Patras` now look topology-fragile; and `Manchester` looks locally real but has only a `1`-year
lead. That means the branch still looks interesting, but not as a broad clean main design. Right
now it looks more promising as a bounded descriptive or mechanism branch unless the mixed cases
hold up under deeper historical validation. That branch decision is now explicit in
`data/processed/scene_networks/scene_branch_decision_memo.md`: the threshold-count version of the
scene branch stays secondary. The domestic-success redesign remains useful as fallback and a
contrast case. Its current cleanup pass keeps only `Rammstein`, `Nightwish`, and provisional
`Sepultura` in `data/processed/country_genre_analysis/domestic_success_pilot_cases_shock_clean.csv`.
That cleaned subset improves the full-set static FE sign on `all` starts to about `+2.8`, but the
stricter `source_a + tier_1` subset remains negative at about `-4.3`, so the positive read still
depends on the weakest-source row.

That older threshold-based branch decision is now partly superseded by the first actual panel
regression in `code/30_estimate_scene_cluster_regression.py`, which writes:

- `data/processed/scene_networks/scene_cluster_regression_results.csv`
- `data/processed/scene_networks/scene_cluster_regression_summary.md`

The regression-based read is stronger than the old `21`-case threshold count. In the seeded `5`-
year forecast spec (`N = 174,416`, `23,519` positive windows), scene size is strongly positive
(`z_log_active_bands = 0.1205`), density and modularity are also positive, and bridge share is
negative. In the stricter seeded exact-year fixed-effects panel (`N = 180,498`, `5,422` emergence
events), bridge share and modularity wash out once `city-genre` and year effects are absorbed, but
lagged nontrivial community count remains strongly positive
(`z_roll3_n_nontrivial_communities = 0.0116`, `p < 0.001`) alongside scene size
(`z_roll3_log_active_bands = 0.0669`). So the best live scene paper is no longer "communities
precede labels in `21` places." It is "thicker local musician clusters with more organizational
variety are more likely to generate later genre emergence." That reopens the scene branch as the
more interesting main design, while the domestic-success redesign now sits in fallback position.

The first robustness pass now backs that up. The same script also runs seeded forecast horizons of
`3`, `5`, `7`, and `10` years plus exact-year fixed-effects panels with `roll-3` and `roll-5`
smoothing. Across the forecast horizons, scene size stays strongly positive and density or
modularity stay positive, while bridge share becomes more negative at longer horizons. In the FE
panels, the stable terms are scene size and nontrivial community count, with bridge share staying
null under both smoothing windows. That means the live mechanism read is now fairly specific:
local thickness and organizational variety look robust; bridge musicians do not currently look like
the core headline variable.

The newest scene extension pass goes one step closer to your actual mechanism questions. The new
script `code/31_probe_scene_role_switcher_extensions.py` writes:

- `data/processed/scene_networks/city_year_scene_role_switcher_features.csv`
- `data/processed/scene_networks/scene_role_switcher_critical_mass.csv`
- `data/processed/scene_networks/scene_role_switcher_extension_results.csv`
- `data/processed/scene_networks/scene_role_switcher_extension_summary.md`

Current read from that pass:

- critical mass is real descriptively:
  - exact-year emergence rates rise from `0.0145` below `10` active bands to `0.0398` at `40+`
  - they also rise from `0.0140` with `0-1` multi-band musicians to `0.0374` with `10+`
- switchers matter more in absolute mass than as a scene share:
  - in the exact-year FE extension, `z_roll5_log_multi_band_musicians = 0.0087`
  - but `z_roll5_multi_band_share = -0.0036`
- the role-specific read is not giving a clean guitarist-creativity story yet:
  - the strongest role-composition term is guitar share among switchers
  - but the sign is weakly negative (`-0.0013`, `p = 0.0621`)
- the signed/unsigned result is only a current-label proxy:
  - current unsigned-heavy scenes look less emergence-prone on that proxy (`-0.0024`)
  - but this is not a historical contract-status measure, so it is not a headline finding

So the mechanism ranking is now sharper. The paper does not currently look like "bridge musicians"
or "guitarists" are the central story. It looks more like:

- scene thickness
- organizational variety
- absolute switcher mass

with signed/unsigned still too noisy to treat as a core historical mechanism.

That mechanism read is now extended again by the richer scene pass in
`code/32_build_scene_cluster_richer_extensions.py`, which writes:

- `data/processed/scene_networks/city_year_scene_cluster_richer_features.csv`
- `data/processed/scene_networks/city_genre_scene_cluster_richer_features.csv`
- `data/processed/scene_networks/scene_cluster_richer_extension_results.csv`
- `data/processed/scene_networks/scene_cluster_richer_extension_summary.md`

Current read from that pass:

- spawning and target-genre stock matter more than pedigree:
  - `z_roll5_log_spawn_bands_formed = 0.0189`
  - `z_roll5_spawn_share_formed = -0.0059`
  - `z_roll5_founder_pedigree_mean = -0.0016`, `p = 0.2246`
- within-genre labor-pool scale is strong, but composition shares are not:
  - `z_roll5_log_genre_active_bands = 0.1642`
  - `z_roll5_log_genre_active_musicians = -0.1128`
- target-genre broker and switcher counts are positive:
  - `z_roll5_log_genre_broker_musicians = 0.0665`
  - `z_roll5_log_genre_multi_band_musicians = 0.0440`
  - but the corresponding share terms are negative:
    `z_roll5_genre_broker_share = -0.0815`,
    `z_roll5_genre_multi_band_share = -0.0280`
- role-targeted labor pools are mostly negative or null once target-genre band stock is included:
  - strongest role term is guitar at `-0.0360`
  - keyboards are weak and insignificant at `-0.0018`, `p = 0.1888`

So the live scene story is now more specific than "thickness helps." It looks like absolute local
target-genre stock, spinout flow, and cross-band or cross-genre musician depth matter more than
compositional shares or founder pedigree.

That richer read now has a compact stress test in
`code/33_stress_test_scene_cluster_richer_specs.py`, which writes:

- `data/processed/scene_networks/scene_cluster_richer_stress_test_results.csv`
- `data/processed/scene_networks/scene_cluster_richer_stress_test_summary.md`

Current read from that stress test:

- the count-versus-share split survives a shorter lag window:
  - spawning flow stays positive in compact `roll-3` and `roll-5` counts-only FE tables
  - target-genre active bands stay strongly positive
  - target-genre multi-band musician depth also stays positive
- the broker term is now more nuanced than the first richer pass suggested:
  - in counts-only compact tables, target-genre broker-musician count is slightly negative
  - once broker share is added, broker count flips strongly positive while broker share is strongly
    negative
- the negative share terms are stable:
  - `roll-5` spawn share: `-0.0066`
  - `roll-5` broker share: `-0.0724`
  - `roll-5` multi-band share: `-0.0195`
- the within-genre switcher result looks genuinely local rather than a proxy for total switcher
  mass:
  - removing the overall switcher control only moves the `roll-5` target-genre multi-band
    coefficient from `0.0225` to `0.0216`

So the live scene story is now narrower and stronger. The cleanest stable terms are local spawning
flow, target-genre active bands, and target-genre switcher depth. Broker musicians remain live,
but only as count conditional on broker concentration rather than as a simple unconditional stock
story.

That choice is now translated into a preferred headline output in
`code/34_build_scene_preferred_mechanism_table.py`, which writes:

- `data/processed/scene_networks/scene_cluster_preferred_mechanism_table.csv`
- `data/processed/scene_networks/scene_cluster_preferred_mechanism_table.md`

Current preferred presentation:

- paired `roll-5` exact-year FE table
- Panel A is the headline counts-only core:
  - local spawning flow: `0.0134`
  - target-genre active bands: `0.0505`
  - target-genre multi-band musicians: `0.0227`
- Panel B is the adjacent composition extension:
  - local spawning flow: `0.0224`
  - spawn share: `-0.0066`
  - target-genre active bands: `0.0488`
  - target-genre broker musicians: `0.0579`
  - target-genre broker share: `-0.0724`
  - target-genre multi-band musicians: `0.0331`
  - target-genre multi-band share: `-0.0195`
- why this is the preferred layout:
  - counts-only alone would hide the composition result
  - counts-plus-shares alone would overstate broker count as an unconditional headline
  - the paired table lets the paper headline the stable unconditional mechanisms while keeping the
    negative share terms and broker sign flip visible

The scene branch now also has a first paper-facing figure package in
`code/35_build_scene_presentation_figures.py`, which writes:

- `data/processed/scene_networks/scene_figure_roadmap.md`
- `data/processed/scene_networks/scene_presentation_figures_summary.md`
- `data/processed/scene_networks/figures/scene_critical_mass_event_rates.png`
- `data/processed/scene_networks/figures/scene_preferred_mechanism_coefficients.png`

Current presentation read:

- the first scene figure should be the critical-mass descriptive:
  - exact-year emergence rates rise from `1.4%` below `10` active bands to `4.0%` at `40+`
  - they rise from `1.4%` with `0-1` multi-band musicians to `3.7%` with `10+`
- the second scene figure should be the headline core coefficient plot:
  - it isolates local spawning flow, target-genre active bands, and target-genre multi-band depth
  - broker or connector variables are no longer part of the active main-text paper package
- the world-map idea remains usable as an opener, but only as optional orientation material rather
  than as the core scene result

For audit and appendix work, the branch now also has:

- `data/processed/scene_networks/scene_data_cleaning_audit.md`
- `data/processed/scene_networks/scene_variable_measurement_audit.md`
- `data/processed/scene_networks/scene_appendix_sample_construction.md`
- `data/processed/scene_networks/scene_appendix_variable_crosswalk.md`

Paper drafting has now started in markdown rather than LaTeX. The live draft object is:

- `notes/06_scene_paper_skeleton.md`
- `notes/07_scene_paper_memo.md`
- `notes/08_scene_paper_sections.md`

Current writing rule:

- lock the empirical argument in markdown first
- keep theory compact and downstream of the reduced-form facts
- delay serious LaTeX and PDF work until the figure order, abstract, and appendix plan stabilize

The key scope choice is now settled: this is an all-metal Metallum project, not a technical-death
project. The current outcome build is in `data/processed/`, anchored by
`metal_archives_all_metal_band_clean.csv` and `metal_archives_all_metal_country_year_panel.csv`.
The same source now also supports a first country-genre refinement in:

- `data/processed/country_genre_analysis/country_genre_family_year_panel.csv`
- `data/processed/country_genre_analysis/country_genre_growth_summary.md`
- `data/processed/country_genre_analysis/thrash_metal_selected_countries_share.png`

After adding Germany, a hardened-but-still-mixed Brazil manual supplement, an Italy cleanup
pass, a seed refresh aimed at language-spillover expansion, an Australia ARIA supplement, and a
United States RIAA supplement, the baseline treatment remains the country-year hit-intensity panel
rather than a pure first-breakthrough file. The current build now recovers `85` album-country rows
across Australia, Brazil, Germany, the United Kingdom, Italy, and the United States, including
`41` top-10 rows, `15` certification rows, and `51` country-year rows with any treatment signal
once chart-weeks are counted. The key treatment split is now `7` home-market top-10 rows and `34`
foreign-market top-10 rows. Italy is now cleaner on official chart presence because the seed adds
exact FIMI-recoverable home-market rows for
`Rhapsody - Power of the Dragonflame`, `Rhapsody of Fire - Triumph or Agony`, and
`Lacuna Coil - Delirium`, while `Comalies` is now explicitly treated as a historical benchmark
that produces no official FIMI chart or certification evidence. The important implication is that
Italy is stronger for official chart-presence intensity, but it still does not widen the domestic
top-10 event sample. Brazil now helps more concretely on the Sepultura side: `Roots` enters as a
named journalistic-source Brazil gold proxy and `Nation` now uses Dicionario Cravo Albin rather
than a Wikipedia album page. But Brazil is still not the cleanest source market, because direct
Pro-Musica retrieval remains blocked and the supplement still mixes one official band press
release, named historical or journalistic sources, and some remaining Wikipedia fallbacks. The
influence side is now also stronger: `code/04_build_band_influence_memo.py`
no longer reports only raw before/after windows or only the narrow top-10 margin. It now compares
three band-market definitions side by side using country and year fixed-effect residuals from the
all-metal outcome panel:

- `presence`: first recovered chart-presence or certification signal
- `certification`: first gold-or-higher certification
- `top10`: first recovered top-10 album-chart hit

Current read:

- `presence` is the most informative broad descriptive margin:
  - `45` complete windows
  - `12` complete home-market windows
  - strongest home-market presence case: `Metallica` in the United States after `Load`
  - Brazil home-market presence still includes `Sepultura - Roots` and `Angra - Rebirth`
- `certification` is no longer just a token fallback:
  - `10` complete windows
  - strongest home-market certification case: `Metallica` in the United States after `Load`
- `top10` remains the conservative blockbuster margin:
  - `19` complete windows
  - `4` complete home-market windows
  - strongest single-market top-10 case remains `Nightwish` in Germany

Those descriptive choices are now the working defaults for the next stage:

- main descriptive event baseline: `presence`
- conservative robustness margin: `top10`
- first genre-specific baseline: broad `genre_family` cells

The new country-genre prototype does not replace that baseline yet. Its role is to sharpen the
mechanism by comparing later entry in the same broad genre family within a country against the
same genre elsewhere. The current graph set should be read as illustrative only. It now includes a
selected-countries comparison in broad `thrash metal`, not a claim that Brazil must be the anchor
case for the project. The language-spillover roadmap also moved forward materially: `Australia` is
now a built same-language reference market with `9` official ARIA rows in the core panel, and the
`United States` now also enters as a built certification-led reference market with `8` exact
public RIAA album-certification matches in the core supplement.

The project has now moved beyond the market-build stage into the first real
`country x genre_family x year` domestic-success pass. That pilot is built in:

- `data/processed/country_genre_analysis/domestic_success_pilot_case_years.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_event_windows.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_event_study.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_event_pass_summary.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_share_gap_event_study.png`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_static.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.csv`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.png`

Current pilot read:

- the treatment file is now `10` hand-coded `country x genre_family` cases, not `5`
- the descriptive share-gap pass is mixed rather than cleanly positive:
  - strongest case so far remains `Sepultura` in Brazil `thrash metal`
  - `3` of `10` pilot cases improve on the all-band share-gap margin, while `7` deteriorate
  - the pooled all-band share gap drifts from about `5.2` percentage points in the pre-period
    mean to about `2.9` in the post-period mean
- the first residualized fixed-effects pass is worse, not better:
  - full-pilot static coefficient on all starts: about `-7.5` with clustered SE `5.0`
  - strict `source_a + tier_1` subset static coefficient on all starts: about `-11.8` with
    clustered SE `7.1`
  - average lead coefficients are positive while average post coefficients are negative
- the first scene-complements diagnostic makes the alternative mechanism look real enough to keep:
  - strongest mature-scene milestone candidates:
    - `Dimmu Borgir` in Norway black metal
    - `Rhapsody` in Italian power metal
  - strongest rising-scene breakthrough candidates:
    - `Nightwish` in Finnish symphonic metal
    - `Sepultura` in Brazilian thrash metal
  - deepest and still-thickening cases:
    - `Pantera` and `Metallica` in the United States
- the first qualitative scene-history memo points the same way:
  - strongest mature-scene milestone cases:
    - `Dimmu Borgir`, `Rhapsody`, and `Metallica`
  - clearest mixed or scene-building cases:
    - `Sepultura` and `Nightwish`
- practical implication: the current treatment file looks too late-coded and too heterogeneous to
  read causally, so the next bottleneck is re-dating or replacing weak pilot rows rather than
  adding more chart markets. The project now has a real empirical fork between
  `breakout as shock` and `breakout as scene milestone`.

## Key files
- `notes/01_project_overview.md`
- `notes/02_literature_and_synthesis.md`
- `notes/03_model_notes.md`
- `notes/04_empirical_notes.md`
- `notes/05_research_plan.md`
- `data/raw/band_members_20260325.zip`
- `data/source_matrix.csv`
- `data/processed/metal_archives_all_metal_summary.md`
- `data/processed/blockbuster_country_year_hit_summary.md`
- `data/processed/scene_networks/full_member_ingest_summary.md`
- `data/processed/scene_networks/city_network_summary.md`
- `data/processed/scene_networks/mechanism_test_results.md`
- `data/processed/scene_networks/community_vs_label_results.md`
- `data/processed/scene_networks/region_like_scene_candidates.md`
- `data/processed/scene_networks/broad_city_case_review_packets.md`
- `data/processed/scene_networks/scene_branch_decision_memo.md`
- `data/processed/scene_networks/scene_cluster_regression_summary.md`
- `data/processed/scene_networks/scene_role_switcher_extension_summary.md`
- `data/processed/scene_networks/scene_cluster_richer_extension_summary.md`
- `data/processed/scene_networks/scene_cluster_richer_stress_test_summary.md`
- `data/processed/scene_networks/scene_cluster_preferred_mechanism_table.md`
- `code/30_estimate_scene_cluster_regression.py`
- `code/31_probe_scene_role_switcher_extensions.py`
- `code/32_build_scene_cluster_richer_extensions.py`
- `code/33_stress_test_scene_cluster_richer_specs.py`
- `code/34_build_scene_preferred_mechanism_table.py`
- `data/processed/country_genre_analysis/domestic_success_cleanup_priority.md`
- `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary_shock_clean.md`
- `STATUS.md`
- `memory.md`

## Next 3 concrete tasks
1. Tighten the main scene-paper draft in `notes/08_scene_paper_sections.md` before opening any
   LaTeX workflow.
2. Keep the appendix objects close to the paper spine:
   maintain the sample-construction and variable-crosswalk materials so the empirical package stays
   auditable.
3. Keep the band-success branch secondary and disciplined:
   if returning to it, use `notes/11_band_upgrading_ladder.md` and the cohort winner ladder rather
   than widening raw coverage for its own sake; keep the network figure parked unless a better
   direct-control workflow makes it easy to produce something genuinely paper quality.
