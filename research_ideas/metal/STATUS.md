# STATUS - Metal

## Snapshot

- Last updated: 2026-03-26 (broad-case review packets built)
- Current phase: the six-market domestic-success branch remains fully built, but the parallel
  scene-network branch now has both the full lagged timing object and a materially cleaner
  geography filter. The first full pass wrote `34,645` city-year snapshots and `5,756`
  city-genre timing rows, with `529` `community_precedes_label` cases. After adding a reusable
  geography-audit exclusion file and rerunning under stricter thresholds
  (`min_bands = 10`, `community_min_genre_bands = 4`, `genre_share_threshold = 0.67`), the
  current strict city-baseline read is `32,684` snapshots, `5,429` timing rows, `21`
  `community_precedes_label` cases, `86` same-year cases, and `5,322` undetected cases. Repeated
  geography tightening has kept the precedes count at `21` while mostly trimming the undetected
  tail. The region-like sidecar adds only one extra precedes case, `Utrecht Province, Netherlands`
  in `black_metal`, so the clean city baseline is not hiding a large region-only signal. A
  surviving-case audit splits the `21` city-baseline precedes cases into `8` broad-scene cases,
  `3` mid-scene cases, and `10` fragile cases. The critical robustness read is that all `21`
  surviving cases are supported by exactly `4` same-genre bands: raising the genre-share threshold
  from `0.67` to `0.75` leaves the count at `21`, but requiring `5` same-genre bands collapses
  precedes to `0`. The new broad-case review packets sharpen that further: `4` of the `8` broad
  cases show clear `multi_bridge_support`, `2` are `hub_bridge_mixed`, and `2` are
  `single_bridge_risk`. The live bottleneck is therefore no longer "can the lagged test be built?"
  but whether the best-supported subset is strong enough to keep the scene-network branch ahead of
  the domestic-success redesign.
- Canonical tracker: this file is the single source of truth for current status.

## Completed

- Created a separate `research_ideas/metal/` folder so the metal-entry idea is no longer bundled
  inside `learning_by_viewing`.
- Set up the standard notes-first scaffold:
  - `README.md`
  - `STATUS.md`
  - `memory.md`
  - `notes/`
- Locked the starting point for the outcome side:
  - reuse the existing Metallum-based band-entry panel already built in
    `research_ideas/learning_by_viewing/music/`
- Framed the treatment side as an open measurement problem rather than as a solved data claim:
  - country-level album sales by year may be difficult
  - a first tractable pass may need to use blockbuster-hit proxies instead
- Audited current official and primary treatment sources:
  - RIAA certifications
  - Official Charts
  - Offizielle Deutsche Charts
  - FIMI
  - Sverigetopplistan
  - ARIA
  - SNEP
  - Luminate as a commercial fallback
- Locked the first treatment recommendation:
  - curated blockbuster albums
  - official chart-entry and chart-run shocks by country
  - certification thresholds as a secondary intensity measure
  - core first countries: US, UK, Germany, Italy, Sweden, Australia
  - initial target window: about 1995 onward
- Added the first treatment-side data scaffolds:
  - `data/source_matrix.csv`
  - `data/blockbuster_album_seed_template.csv`
  - `data/blockbuster_album_country_hits_template.csv`
- Built the first hand-collected pilot sample from official sources:
  - `data/blockbuster_album_country_hits_pilot_sample.csv`
  - current pilot countries: United Kingdom and Italy
  - current pilot albums: `The Book of Souls`, `Hybrid Theory`
- Added a reproducible outcome-scope exploration:
  - `code/01_explore_outcome_scope.py`
  - outputs in `data/exploration/`
- Fixed the pilot treatment CSV so it is valid machine-readable CSV rather than a notes-only file.
- Built the current all-metal outcome from the full Metallum snapshot:
  - `code/02_build_all_metal_outcome.py`
  - `data/processed/metal_archives_all_metal_band_clean.csv`
  - `data/processed/metal_archives_all_metal_country_year_panel.csv`
  - `data/processed/metal_archives_all_metal_summary.md`
- Locked the working outcome recommendation for this project:
  - default outcome: all metal bands in the Metallum snapshot
  - optional later splits: subgenre heterogeneity checks, if needed
- Built the first active curated blockbuster seed:
  - `data/blockbuster_album_seed.csv`
- Locked the first operational hit rule:
  - `data/blockbuster_hit_rule.md`
- Current treatment-side recommendation now locked:
  - seed logic:
    - Tier A `tier_a_global_anchor`
    - Tier B `tier_b_home_market_flagship`
  - baseline hit timing:
    - first official top-10 national album-chart entry
  - fallback timing:
    - first official gold-or-higher certification date
  - baseline country-year treatment:
    - `hit_top10_ct`
  - secondary intensity measures:
    - `hit_no1_ct`
    - `hit_chart_weeks_ct`
    - `hit_certified_ct`
- Built the first machine-readable core treatment outputs for the active metal seed:
  - `code/03_build_core_treatment_panel.py`
  - `data/processed/blockbuster_album_country_hits_core.csv`
  - `data/processed/blockbuster_country_year_hit_panel.csv`
  - `data/processed/blockbuster_country_year_hit_summary.md`
- Current UK/Italy treatment read:
  - `22` album-country rows recovered from the active seed
  - United Kingdom: `11` rows, `6` top-10 rows
  - Italy: `11` rows, `5` top-10 rows, `1` certification row
  - non-zero country-year treatment signal currently appears in:
    - United Kingdom: `1996`, `2000`, `2008`, `2015`, `2022`
    - Italy: `1996`, `2000`, `2008`, `2015`
- Extended the core treatment build to Germany using a manual official-source supplement because
  the official German chart site blocks scripted requests in this environment:
  - total album-country rows now: `36`
  - Germany rows: `14`
  - total top-10 rows now: `22`
  - non-zero country-year treatment signal now appears in:
    - Germany: `1996`, `2000`, `2001`, `2004`, `2008`, `2012`, `2015`, `2016`, `2018`, `2022`
    - United Kingdom: `1996`, `2000`, `2008`, `2015`, `2022`
    - Italy: `1996`, `2000`, `2008`, `2015`
- Locked the baseline treatment choice after the Germany build:
  - keep the country-year intensity panel as the baseline treatment object
  - keep the first-hit band-market file as a derived diagnostic and interpretation layer
  - reason: collapsing to a pure first-breakthrough file would throw away repeated country-year
    shocks that are already visible in the three-market build
- Built the first descriptive band-influence outputs:
  - `code/04_build_band_influence_memo.py`
  - `data/processed/blockbuster_band_influence_event_windows.csv`
  - `data/processed/blockbuster_band_influence_ranking.csv`
  - `data/processed/blockbuster_band_influence_memo.md`
- Current descriptive influence read:
  - strongest multi-market positive band in the current sample: `Iron Maiden`
  - strongest single-market proportional surge: `Iron Maiden` in the United Kingdom after
    `Brave New World`
  - strongest single-market raw-delta case: `Nightwish` in Germany after `Once`
  - important caution: `Metallica` and `Sepultura` share bundled `1996` country-year shocks in
    multiple markets, so the current design cannot separate those cases cleanly
- Added home-versus-foreign coding to the core treatment panel and influence workflow:
  - `blockbuster_album_country_hits_core.csv` now carries:
    - `market_exposure_type`
    - `home_market_i`
    - `foreign_market_i`
  - `blockbuster_country_year_hit_panel.csv` now carries:
    - `hit_home_top10_ct`
    - `hit_foreign_top10_ct`
    - home-versus-foreign splits for `no1`, `chart_weeks`, and `certified`
  - current top-10 split:
    - home-market rows: `4`
    - foreign-market rows: `18`
- Current split read:
  - complete home-market first-hit windows: `3`
  - complete foreign-market first-hit windows: `10`
  - strongest home-market case so far: `Iron Maiden` in the United Kingdom after `Brave New World`
  - strongest foreign-market case so far: `Nightwish` in Germany after `Once`
  - practical implication: the domestic-exemplar question is now measurable, but the home side is
    still thin
- Extended the core treatment build to Brazil through a manual supplement because direct
  Pro-Musica retrieval is blocked in this environment:
  - added `data/blockbuster_album_country_hits_bra_manual.csv`
  - expanded the curated seed with additional Brazilian home-market flagship albums:
    - `Angra - Rebirth`
    - `Angra - Temple of Shadows`
    - `Sepultura - Nation`
    - `Sepultura - Dante XXI`
  - total album-country rows now: `42`
  - Brazil rows: `5`
  - total top-10 rows now: `24`
  - current exposure split: `5` home-market top-10 rows and `19` foreign-market top-10 rows
  - Brazil country-year treatment signal now appears in:
    - `2001`, `2002`, and `2008` through certification rows
    - `2004` through a home-market top-10 row for `Angra - Temple of Shadows`
    - `2015` through a foreign-market number-1 row for `Iron Maiden - The Book of Souls`
- Current split read after Brazil:
  - complete home-market first-hit windows: `4`
  - complete foreign-market first-hit windows: `11`
  - strongest home-market case so far remains `Iron Maiden` in the United Kingdom after
    `Brave New World`
  - Brazil now contributes one complete home-market first-hit window:
    - `Angra` in Brazil after `Temple of Shadows`
  - important caveat:
    - Brazil currently mixes one official band press release with clearly labeled secondary-source
      chart and certification traces, so it is useful as a provisional substantive extension but
      not yet as a fully hardened source benchmark
- Reworked the band-influence workflow into a residualized ranking and event-study pass:
  - `code/04_build_band_influence_memo.py` now residualizes all-metal and unsigned entry on
    country and year fixed effects before building event windows
  - added `data/processed/blockbuster_band_influence_event_study.csv`
  - updated `data/processed/blockbuster_band_influence_event_windows.csv`
  - updated `data/processed/blockbuster_band_influence_ranking.csv`
  - updated `data/processed/blockbuster_band_influence_memo.md`
- Current residualized read:
  - strongest single-market residualized all-metal case: `Nightwish` in Germany after `Once`
    at about `+155.6` bands per year
  - strongest home-market residualized case: `Iron Maiden` in the United Kingdom after
    `Brave New World` at about `+56.8` bands per year
  - strongest multi-market residualized band so far: `Metallica`, but this is not cleanly
    separable from `Sepultura` because their bundled `1996` foreign-market shocks still generate
    identical three-market scores
  - aggregate event-study profile remains noisy:
    - pre-period residuals are still negative on average
    - the pooled mean turns clearly positive only by `t+2`
    - practical implication: the ranking is currently more informative than the pooled dynamic path
- Hardened the Italy treatment side through seed expansion with official FIMI-recoverable domestic
  flagship rows:
  - kept `Lacuna Coil - Comalies` as a historical benchmark but now mark it explicitly as an
    official FIMI dead end
  - added exact FIMI chart-presence rows for:
    - `Rhapsody - Power of the Dragonflame`
    - `Rhapsody of Fire - Triumph or Agony`
    - `Lacuna Coil - Delirium`
  - current four-market treatment build now recovers:
    - `46` album-country rows
    - Brazil: `5` rows
    - Germany: `14` rows
    - United Kingdom: `13` rows
    - Italy: `14` rows
    - `24` top-10 rows
    - `35` country-year rows with any treatment signal once chart-weeks are counted
  - important read:
    - Italy now contributes clean home-market chart-presence years in `2002`, `2006`, and `2016`
    - but the domestic top-10 sample is unchanged, so the complete home-market first-hit window
      count remains `4`
- Fixed the treatment-summary logic so "any treatment signal" now includes chart-weeks-only years
  rather than only top-10 and certification years.
- Hardened the Brazil supplement specifically on the Sepultura side:
  - added a Brazil `Roots` certification row using a named journalistic source that explicitly
    states the album reached gold in Brazil during its 1996 popularity peak
  - replaced the `Nation` row's Wikipedia fallback with Dicionario Cravo Albin, which explicitly
    states that `Nation` reached Disco de Ouro in Brazil in `2001`
  - current four-market treatment build now recovers:
    - `47` album-country rows
    - Brazil: `6` rows
    - Germany: `14` rows
    - United Kingdom: `13` rows
    - Italy: `14` rows
    - `24` top-10 rows
    - `5` certification rows
  - updated Brazil treatment timing:
    - `1996` now carries a Sepultura home-market certification row for `Roots`
    - `2001` now carries two home-market certification rows in Brazil:
      - `Sepultura - Nation`
      - `Angra - Rebirth`
  - important read:
    - Brazil is now less dependent on anonymous Wikipedia fallback for Sepultura
    - but `Dante XXI` and both Angra rows still need stronger sourcing if Brazil is to become a
      clean benchmark market
- Generalized the influence workflow beyond the narrow top-10 definition:
  - `code/04_build_band_influence_memo.py` now compares three band-market definitions:
    - `first_presence_by_band_market`
    - `first_certification_by_band_market`
    - `first_top10_by_band_market`
  - current comparative read:
    - `presence`: `33` band-market events and `32` complete windows
    - `certification`: `3` band-market events and `3` complete windows
    - `top10`: `17` band-market events and `15` complete windows
  - current substantive read:
    - `presence` is the most informative broad descriptive margin
    - it raises the complete home-market sample from `4` under `top10` to `8`
    - strongest home-market presence cases now include:
      - `Iron Maiden - Brave New World` in the UK
      - `Rhapsody - Power of the Dragonflame` in Italy
      - `Angra - Rebirth` in Brazil
    - `Sepultura - Roots` in Brazil
    - `top10` remains the conservative blockbuster margin rather than the only meaningful signal
- Built the first reusable country-genre family panel from the all-metal Metallum outcome:
  - `code/06_build_country_genre_growth_panel.py`
  - `data/processed/country_genre_analysis/country_genre_family_year_panel.csv`
  - `data/processed/country_genre_analysis/brazil_thrash_vs_rest_of_world.csv`
  - `data/processed/country_genre_analysis/brazil_thrash_metal_vs_rest_of_world_share.png`
  - `data/processed/country_genre_analysis/thrash_metal_selected_countries_share.csv`
  - `data/processed/country_genre_analysis/thrash_metal_selected_countries_share.png`
  - `data/processed/country_genre_analysis/country_genre_growth_summary.md`
  - current prototype read:
    - panel tracks `18` broad genre families
    - the graph set is illustrative rather than country-specific
    - one graph now compares several large `thrash metal` countries on one chart
  - practical implication:
    - the strongest live refinement is now a `country x genre_family x year` design
    - the next measurement step is to replace first observed genre-country starts with curated
      domestic breakthrough timing
- Rewrote `notes/02_literature_and_synthesis.md` into a verified cross-field literature note:
  - economics of domestic bias, digitization, and artist entry
  - economic geography of music scenes and genre emergence
  - sociology and popular-music studies on scenes, genre formation, and classification
  - current read:
    - the literature is much stronger than the earlier placeholder suggested
    - I still have not found a verified economics paper that directly estimates domestic
      breakthrough effects on later `country x genre x year` producer entry
- Wrote the first operational domestic-success rule memo:
  - `data/processed/country_genre_analysis/domestic_success_pilot_design.md`
  - current rule:
    - baseline priority is Tier 1 and Tier 2 home-market visibility events
    - song-led breakthroughs stay in scope, but as part of a composite visible-success rule rather
      than as the default metal measure
    - language now sits explicitly as a spillover boundary for the later coding stage
- Built the first hand-coded domestic-success pilot file:
  - `data/processed/country_genre_analysis/domestic_success_pilot_cases.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_cases_summary.md`
  - current pilot composition:
    - `10` candidate `country x genre` cases after the later expansion
    - event types already span `album_led`, `song_led`, `certification_led`, and
      `chart_presence_led`
    - most rows are Source A official cases, but Brazil remains a Source C named-secondary case
  - practical implication:
    - the domestic-success object is now concrete enough to keep building
    - the next bottlenecks are low-confidence first-in-cell checks and spillover coding
- Built the first spillover-coding preview:
  - `data/processed/country_genre_analysis/domestic_success_spillover_rule.md`
  - `data/processed/country_genre_analysis/foreign_spillover_coding_preview.csv`
  - `data/processed/country_genre_analysis/foreign_spillover_coding_counts.csv`
  - `data/processed/country_genre_analysis/foreign_spillover_coding_summary.md`
  - `data/processed/country_genre_analysis/pilot_market_language_reference.csv`
  - current preview counts in the existing core treatment build:
    - `12` `domestic_success`
    - `10` `same_language_foreign`
    - `24` `different_language_foreign`
    - `1` `multiple_language_foreign`
  - practical implication:
    - the spillover rule is implementable with current data
    - but same-language foreign variation is still thin and mostly concentrated in the UK
    - expanding the case and market set now matters more than debating the rule in the abstract
- Ranked the audited markets for the same-language spillover extension:
  - `code/08_rank_language_spillover_markets.py`
  - `data/processed/country_genre_analysis/language_spillover_market_priority.csv`
  - `data/processed/country_genre_analysis/language_spillover_market_priority.md`
  - current ranking read:
    - the current seed is `25` albums, `22` of which are English-language
    - under the current seed, the same-language design is therefore mostly an English-market
      design
    - `Australia` is the clear next extension:
      - `22` same-language foreign seed candidates
      - audited official source path: `ARIA`
    - `United States` is the second-best extension:
      - `20` same-language foreign seed candidates
      - but the currently audited official path is certification-led through `RIAA`
    - `Sweden`, `France`, and the already-built non-English reference markets are low-yield for
      the current same-language question unless the seed later adds more non-English-language
      flagship acts
- Probed actual source overlap for the top same-language extension candidates:
  - `code/09_probe_language_spillover_readiness.py`
  - `data/processed/country_genre_analysis/australia_aria_seed_overlap.csv`
  - `data/processed/country_genre_analysis/usa_riaa_seed_probe.csv`
  - `data/processed/country_genre_analysis/language_spillover_build_readiness.md`
  - current readiness read:
    - `Australia` is machine-readable through the live ARIA chart API
    - but the earliest public ARIA albums-chart date currently returned is `2019-07-01`
    - that overlaps only one current seed album:
      - `Ghost - Impera`
    - `United States` is machine-readable through public RIAA search pages
    - but exact album-format seed matches currently number only `4`:
      - `Metallica - Load`
      - `Metallica - Death Magnetic`
      - `Sepultura - Roots`
      - `Rammstein - Sehnsucht`
    - practical implication:
      - the current bottleneck is now seed-source overlap, not just market ranking
- Refreshed the curated seed and rebuilt the four-market panel:
  - added `12` source-supported albums to `data/blockbuster_album_seed.csv`
  - current seed size: `37` albums, `33` of which are English-language
  - current overlap/readiness gains:
    - `Australia`: `9` overlapping seed albums under the public ARIA history window
    - `United States`: `8` exact public RIAA album-certification matches
  - rebuilt core outputs:
    - `data/processed/blockbuster_album_country_hits_core.csv`
    - `data/processed/blockbuster_country_year_hit_panel.csv`
    - `data/processed/blockbuster_country_year_hit_summary.md`
    - `data/processed/blockbuster_band_influence_memo.md`
  - rebuilt panel read:
    - `68` album-country rows
    - `35` top-10 rows
    - `7` certification rows
    - `42` country-year rows with some treatment signal
    - `7` home-market top-10 rows
    - `28` foreign-market top-10 rows
  - practical implication:
    - `Australia` is now a real next same-language market build rather than a thin placeholder
    - `United States` remains the best certification-led follow-up market
- Built the Australia same-language extension from official ARIA API evidence:
  - added `data/blockbuster_album_country_hits_aus_manual.csv`
  - rebuilt:
    - `data/processed/blockbuster_album_country_hits_core.csv`
    - `data/processed/blockbuster_country_year_hit_panel.csv`
    - `data/processed/blockbuster_country_year_hit_summary.md`
    - `data/processed/blockbuster_band_influence_memo.md`
  - current five-market panel read:
    - `77` album-country rows
    - `41` top-10 rows
    - `7` certification rows
    - `46` country-year rows with some treatment signal
    - Australia: `9` rows and `6` top-10 rows
  - practical implication:
    - Australia is now a built same-language reference market
    - at that point, `United States` was the cleanest unbuilt extension
- Built the United States certification-led extension from exact public RIAA album-certification
  matches:
  - added `data/blockbuster_album_country_hits_usa_manual.csv`
  - rebuilt:
    - `data/processed/blockbuster_album_country_hits_core.csv`
    - `data/processed/blockbuster_country_year_hit_panel.csv`
    - `data/processed/blockbuster_country_year_hit_summary.md`
    - `data/processed/blockbuster_band_influence_memo.md`
  - current six-market panel read:
    - `85` album-country rows
    - `41` top-10 rows
    - `15` certification rows
    - `51` country-year rows with some treatment signal
    - United States: `8` rows, all certification-led
  - current influence read after the U.S. build:
    - `presence`: `57` band-market events and `45` complete windows
    - `certification`: `11` band-market events and `10` complete windows
    - `top10`: `30` band-market events and `19` complete windows
    - strongest home-market `presence` and `certification` case:
      - `Metallica` in the United States after `Load`
  - practical implication:
    - the project no longer needs to decide whether to build the U.S.
    - the live decisions now move back to event definition, Brazil source quality, and the first
      true `country x genre_family x year` pass
- Locked the next-stage baseline choices and built the first real domestic-success pilot pass:
  - main descriptive event baseline:
    - `presence`
  - conservative robustness margin:
    - `top10`
  - first genre-specific baseline:
    - broad `genre_family` cells
  - extended `data/processed/country_genre_analysis/country_genre_family_year_panel.csv` to
    preserve:
    - `all`
    - `unsigned`
    - `signed`
    band-start margins
  - added `code/11_build_domestic_success_pilot_event_pass.py`
  - wrote:
    - `data/processed/country_genre_analysis/domestic_success_pilot_case_years.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_event_windows.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_event_study.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_event_pass_summary.md`
    - `data/processed/country_genre_analysis/domestic_success_pilot_share_gap_event_study.png`
  - current pilot read:
    - `10` pilot cases and `60` case-year rows
    - strongest current positive case:
      - `Sepultura` in Brazil `thrash metal`
    - all-band share-gap improvement is mixed:
      - `3` pilot cases improve
      - `7` deteriorate
    - pooled all-band share gap drifts from about `5.2` percentage points in the pre-period mean
      to about `2.9` in the post-period mean
  - practical implication:
    - the project has moved past the market-build bottleneck
    - the next bottleneck is now event timing quality and pilot-case quality, not adding more
      chart markets
- Built the first residualized `country x genre_family x year` specification:
  - added `code/12_estimate_domestic_success_pilot_fe.py`
  - wrote:
    - `data/processed/country_genre_analysis/domestic_success_pilot_fe_static.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary.md`
    - `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.png`
  - current FE read:
    - full-pilot static coefficient on all starts:
      - about `-7.5` with clustered SE `5.0`
    - strict `source_a + tier_1` subset static coefficient on all starts:
      - about `-11.8` with clustered SE `7.1`
    - average full-pilot lead coefficients on all starts:
      - about `+2.9`
    - average full-pilot post coefficients on all starts:
      - about `-4.1`
  - practical implication:
    - the first residualized pass does not rescue the design
    - positive pre-trends and negative post coefficients suggest several current treatment rows are
      late relative to local scene takeoff
    - the next step should be re-dating or replacing weak rows, not treating the current file as
      close to causal
- Built the first scene-complements diagnostic for the current treated-case set:
  - added `code/13_build_scene_complements_diagnostic.py`
  - wrote:
    - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_case_years.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_case_metrics.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_rankings.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_summary.md`
    - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_scatter.png`
  - current diagnostic read:
    - mature-scene milestone candidates:
      - `Dimmu Borgir` in Norway black metal
      - `Rhapsody` in Italian power metal
    - rising-scene breakthrough candidates:
      - `Nightwish` in Finnish symphonic metal
      - `Sepultura` in Brazilian thrash metal
    - deep and still-thickening cases:
      - `Pantera` and `Metallica` in the United States
  - practical implication:
    - the complements story is no longer just a verbal caveat
    - it is now a real empirical fork that can help decide which pilot rows are weak for the
      shock-based design
- Added the first qualitative scene-evidence memo for the complements fork:
  - wrote:
    - `data/processed/country_genre_analysis/scene_qualitative_evidence_source_map.csv`
    - `data/processed/country_genre_analysis/scene_qualitative_evidence_memo.md`
  - current qualitative read:
    - strongest mature-scene milestone cases:
      - `Dimmu Borgir` / Norway black metal
      - `Rhapsody` / Italy power metal
      - `Metallica` / U.S. heavy metal
    - clearest mixed scene-plus-breakthrough case:
      - `Sepultura` / Brazil thrash metal
    - clearest rising-scene or scene-building case:
      - `Nightwish` / Finland symphonic metal
  - practical implication:
    - the treatment cleanup can now use qualitative scene histories rather than only quantitative
      heuristics when deciding which rows to prune or re-date
- Staged the delivered full Metal Archives member dump inside the project:
  - `data/raw/band_members_20260325.zip`
- Updated the member-data ingest pipeline to support the delivered role-level schema:
  - `code/20_ingest_member_data.py`
  - current ingest now accepts `.zip` or `.csv`
  - role-level rows are collapsed to one `band_id x member_id` edge before network construction
  - wrote:
    - `data/processed/scene_networks/full_musician_band_edges.csv`
    - `data/processed/scene_networks/full_member_ingest_summary.md`
  - current ingest read:
    - `1,038,533` raw member-role rows
    - `971,877` unique member-band edges after collapse
    - `682,126` unique musicians
    - `152,923` musicians in `2+` bands (`22.4%`)
- Reworked the city-network builder so it scales to the full member file rather than only the
  pilot scenes:
  - `code/21_build_city_networks.py`
  - now uses a two-pass city-local build instead of rescanning all musicians for every city
  - wrote:
    - `data/processed/scene_networks/city_network_stats.csv`
    - `data/processed/scene_networks/city_band_band_edges.csv`
    - `data/processed/scene_networks/city_network_summary.md`
  - current city-network read:
    - `22,572` cities with any member-linked bands
    - `2,319` cities with `10+` bands
    - median density: about `0.053`
    - median clustering: about `0.253`
    - median bridge-musician share: about `12.8%`
- Replaced the old member-data placeholder mechanism memo with the first real cross-city pass:
  - reran `code/23_test_network_predicts_genre.py`
  - wrote:
    - `data/processed/scene_networks/mechanism_test_merged.csv`
    - `data/processed/scene_networks/mechanism_test_results.md`
  - current mechanism read:
    - raw density association is negative
    - residualized density remains negative once city size is partialled out
    - residualized clustering is positive
    - residualized bridge-musician share is positive and currently the strongest simple predictor
      of genre-emergence counts, with `R-squared` about `0.053`
  - practical implication:
    - the scene-network branch is no longer a speculative side note
    - but the cross-city pass is still static and contemporaneous, so the next real test must use
      lagged network structure rather than treating this first pass as decisive
- Built the first lagged city-year scene-timing pass from the full member dump:
  - rewrote `code/24_test_community_precedes_label.py` from pilot-only mode into a full-data
    workflow
  - added reusable lagged outputs:
    - `data/processed/scene_networks/city_year_network_snapshots.csv`
    - `data/processed/scene_networks/community_vs_label_timing.csv`
    - `data/processed/scene_networks/community_vs_label_results.md`
  - current timing configuration:
    - community method: `label_prop`
    - minimum active city bands per snapshot: `5`
    - supporting community rule: at least `3` same-genre bands and at least `50%` genre share
  - current timing read:
    - `34,645` city-year snapshots
    - `5,756` city-genre timing rows across `1,826` cities
    - `529` `community_precedes_label` cases
    - `453` `community_same_year_as_label` cases
    - `4,774` `community_not_detected_by_label` cases
    - median lead among precedes cases: `4` years
    - max lead among precedes cases: `35` years
  - practical implication:
    - the lagged timing test now exists as a reusable empirical object rather than as a planned
      next step
    - but the first pass is mixed and selective, and several headline precedes cases sit in tiny
      or geography-questionable scene units, so city filtering and robustness now matter more than
      further raw scale-up
- Built the first reusable geography audit for the scene-network branch and reran the strict
  timing pass on top of it:
  - added `code/25_audit_scene_geography.py`
  - `code/24_test_community_precedes_label.py` now accepts:
    - `--exclude-city-file`
    - `--exclude-flag-column`
  - current audit outputs:
    - `data/processed/scene_networks/city_geography_audit.csv`
    - `data/processed/scene_networks/city_geography_audit_summary.md`
  - current audit read:
    - audit universe: `2,446` city labels from the union of `city_network_stats.csv` and
      `city_year_network_snapshots.csv`
    - current baseline exclusions: `155`
    - the still-visible excluded tail in the latest timing file is only `3` undetected rows:
      `Kanagawa Prefecture`, `Mississippi`, and `Transylvania`
  - current strict timing read:
    - `32,689` city-year snapshots
    - `5,430` city-genre timing rows
    - `21` `community_precedes_label` cases
    - `86` `community_same_year_as_label` cases
    - `5,323` `community_not_detected_by_label` cases
    - median lead among precedes cases: `4` years
    - max lead among precedes cases: `14` years
  - practical implication:
    - the headline `529` precedes count collapses sharply under a cleaner baseline
    - further geography tightening so far has not reduced the precedes count below `21`
    - the real next question is now whether those surviving cases are meaningful enough to anchor
      the scene-network branch
- Audited the surviving strict-baseline precedes cases and ran a one-step robustness grid:
  - added `code/26_audit_surviving_precedes_cases.py`
  - current audit outputs:
    - `data/processed/scene_networks/surviving_precedes_case_audit.csv`
    - `data/processed/scene_networks/surviving_precedes_case_audit.md`
  - current case-audit read:
    - surviving cases: `21`
    - `broad_scene_case`: `8`
    - `mid_scene_case`: `3`
    - `fragile_case`: `10`
    - dominant surviving genre: `black_metal` with `11` cases
    - all `21` surviving cases are detected on exactly `4` same-genre bands
  - current one-step robustness read around the cleaned baseline:
    - `community_min_genre_bands = 4`, `genre_share_threshold = 0.75`:
      `21` precedes cases
    - `community_min_genre_bands = 5`, `genre_share_threshold = 0.67`:
      `0` precedes cases
    - `community_min_genre_bands = 5`, `genre_share_threshold = 0.75`:
      `0` precedes cases
  - practical implication:
    - the surviving signal is not just geography junk, because a meaningful subset sits in broad
      recognizable scenes
    - but it is count-fragile in absolute support size, so this currently looks more promising as a
      narrow descriptive or mechanism branch than as a clean main design
- Reclassified region-like units as a side object rather than mixing them into the city baseline:
  - added `code/27_build_region_like_scene_candidates.py`
  - current sidecar outputs:
    - `data/processed/scene_networks/region_like_scene_units.csv`
    - `data/processed/scene_networks/region_like_scene_units.md`
    - `data/processed/scene_networks/community_vs_label_timing_region_like_sidecar.csv`
    - `data/processed/scene_networks/community_vs_label_results_region_like_sidecar.md`
    - `data/processed/scene_networks/region_like_scene_candidates.csv`
    - `data/processed/scene_networks/region_like_scene_candidates.md`
  - current region-like read:
    - region-like timing rows: `134`
    - `community_precedes_label`: `1`
    - `community_same_year_as_label`: `0`
    - `community_not_detected_by_label`: `133`
    - the only region-like precedes case is `Utrecht Province, Netherlands` in `black_metal`
  - practical implication:
    - region-like units may still be substantively interesting, but they do not change the city
      baseline story enough to justify mixing units
- Built the first broad-case review packets for actual manual validation:
  - added:
    - `code/28_build_broad_city_case_shortlist.py`
    - `code/29_build_broad_city_case_review_packets.py`
  - current review outputs:
    - `data/processed/scene_networks/broad_city_precedes_case_shortlist.csv`
    - `data/processed/scene_networks/broad_city_precedes_case_shortlist.md`
    - `data/processed/scene_networks/broad_city_case_review_summary.csv`
    - `data/processed/scene_networks/broad_city_case_review_supporting_bands.csv`
    - `data/processed/scene_networks/broad_city_case_review_bridge_musicians.csv`
    - `data/processed/scene_networks/broad_city_case_review_packets.md`
  - current broad-case review read:
    - reviewed broad cases: `8`
    - `multi_bridge_support`: `4`
    - `hub_bridge_mixed`: `2`
    - `single_bridge_risk`: `2`
    - strongest topology-plus-lead cases now look like:
      - `Pittsburgh` doom metal
      - `Bilbao` black metal
      - `Brussels` metalcore
    - still-live but more mixed cases:
      - `Córdoba` black metal
      - `Nagoya` grindcore
    - weak-on-topology or weak-on-lead cases:
      - `Girona` black metal
      - `Patras` black metal
      - `Manchester` brutal death metal
  - practical implication:
    - the broad-city audit keeps the scene branch alive, but not yet as the headline design
    - the branch now looks strongest as a bounded mechanism or descriptive fork unless the mixed
      cases survive deeper historical validation

## In Progress

- Writing the branch-decision memo from the first packet-based case review:
  - current broad-case read points toward a bounded scene branch rather than a full pivot
- Deciding whether the `3` mid-scene cases are worth auditing:
  - this now matters only if we still need more plausible positive cases after the broad-case pass
- Deciding whether the scene-network branch should remain a mechanism/descriptive fork or still
  attempt to outrank the domestic-success branch
- Replacing or re-dating pilot domestic-success rows that already look mature before the coded
  breakthrough year if the shock design remains live
- Building a cleaner second-wave domestic-success file with earlier and higher-confidence rows
  before rerunning the fixed-effects specification

## Next 3 Tasks

1. Write the branch-decision memo:
   decide explicitly whether the scene-network branch is now a main-design candidate, a mechanism
   section, or a bounded descriptive appendix after the broad-case review packets.
2. Audit the `3` mid-scene cases only if needed:
   use the same packet workflow on `Chico`, `Fulda`, and `Wollongong` only if we need more live
   candidates beyond the broad-case subset.
3. If the scene branch stays secondary, return to the domestic-success redesign:
   clean the weak pilot rows and rerun the residualized country-genre pass.

## Open Decisions

- Treatment measurement:
  - exact curated blockbuster rule
  - whether to keep raw count, chart-week intensity, or peak-weighted treatment as the preferred
    secondary intensity measure after the baseline top-10 count
- Geography:
  - country-year first is now locked as the baseline treatment object
  - home-market versus foreign-market coding is now implemented in the core panel
  - later country plus shared-language spillovers
- Scope:
  - all metal as the default outcome
  - genre-family or subgenre splits only as later heterogeneity checks
- Project framing:
  - whether the baseline paper should remain `domestic breakthrough as shock`
  - or pivot to `scenes as collaborative innovation` using membership networks and genre
    emergence timing

## References

- Project overview: `research_ideas/metal/README.md`
- Memory: `research_ideas/metal/memory.md`
- Notes index: `research_ideas/metal/notes/README.md`
