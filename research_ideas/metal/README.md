# Metal

**Canonical status tracker**: `research_ideas/metal/STATUS.md`

## One-line objective
Study whether blockbuster metal albums in a country or language area induce new local band
formation, using the existing Metallum-based band-entry panel as the starting outcome dataset.
The project now also has a live parallel branch that treats local scenes and membership networks
as the main innovation object rather than only as a mechanism check.

## Workflow (current)
- Project is in very early notes phase.
- Active drafting is Markdown-first in `notes/`.
- Do not start LaTeX paper drafting or paper PDFs until explicitly requested.
- Local storage rule:
  - track code, notes, and small hand-built source tables in git
  - keep `data/raw/` and `data/processed/` out of git and on `D:\AI_data\research_ideas\metal\`
    via local junctions on this machine

## Current status
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
hold up under deeper historical validation.

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
- `STATUS.md`
- `memory.md`

## Next 3 concrete tasks
1. Make the branch decision explicitly:
   decide whether the scene-network branch is a main-design candidate, a mechanism section, or a
   bounded descriptive appendix after the broad-case review packets.
2. Audit the `3` mid-scene cases only if needed:
   use the same packet workflow on `Chico`, `Fulda`, and `Wollongong` only if the broad-case set
   still feels too thin.
3. If the scene branch stays secondary, return to the domestic-success redesign:
   clean the weak pilot rows and rerun the residualized country-genre pass.
