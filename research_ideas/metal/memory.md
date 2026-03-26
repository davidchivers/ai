# Project memory - Metal

Most recent session first.

---

### Session: 2026-03-26 (region-like sidecar and broad-case review packets)
- Refined the geography-clean scene workflow so region-like labels are retained as a separate side
  object rather than mixed into the city baseline.
- Added:
  - `code/27_build_region_like_scene_candidates.py`
  - `code/28_build_broad_city_case_shortlist.py`
  - `code/29_build_broad_city_case_review_packets.py`
- Current region-like sidecar outputs:
  - `data/processed/scene_networks/community_vs_label_timing_region_like_sidecar.csv`
  - `data/processed/scene_networks/community_vs_label_results_region_like_sidecar.md`
  - `data/processed/scene_networks/region_like_scene_candidates.csv`
  - `data/processed/scene_networks/region_like_scene_candidates.md`
- Current region-like read:
  - region-like timing rows: `134`
  - `community_precedes_label`: `1`
  - `community_same_year_as_label`: `0`
  - `community_not_detected_by_label`: `133`
  - the only region-like precedes case is:
    - `Utrecht Province, Netherlands` / `black_metal` / lead `5`
- Current strict city-baseline read after the restored rerun:
  - `32,684` lagged city-year snapshots
  - `5,429` city-genre timing rows
  - `21` `community_precedes_label` cases
  - `86` `community_same_year_as_label` cases
  - `5,322` `community_not_detected_by_label` cases
  - median lead among precedes cases: `4` years
  - max lead among precedes cases: `14` years
- Built the first broad-city review outputs:
  - `data/processed/scene_networks/broad_city_precedes_case_shortlist.csv`
  - `data/processed/scene_networks/broad_city_precedes_case_shortlist.md`
  - `data/processed/scene_networks/broad_city_case_review_summary.csv`
  - `data/processed/scene_networks/broad_city_case_review_supporting_bands.csv`
  - `data/processed/scene_networks/broad_city_case_review_bridge_musicians.csv`
  - `data/processed/scene_networks/broad_city_case_review_packets.md`
- Current broad-case review read:
  - reviewed broad cases: `8`
  - `multi_bridge_support`: `4`
  - `hub_bridge_mixed`: `2`
  - `single_bridge_risk`: `2`
  - strongest local-network cases:
    - `Pittsburgh` / `doom_metal`
    - `Bilbao` / `black_metal`
    - `Brussels` / `metalcore`
  - still-live but mixed:
    - `Córdoba` / `black_metal`
    - `Nagoya` / `grindcore`
  - topology-weak or timing-weak:
    - `Girona` / `black_metal`
    - `Patras` / `black_metal`
    - `Manchester` / `brutal_death_metal`
- Current interpretation:
  - the city baseline remains the right main unit
  - region-like units do not add much signal beyond the city baseline
  - the scene-network branch survives as a real bounded mechanism or descriptive fork
  - it still does not look strong enough to dominate the whole project unless the mixed cases hold
    up under deeper historical validation

---

### Session: 2026-03-26 (geography-clean strict rerun tightened)
- Added `code/25_audit_scene_geography.py` as a reusable city-label audit for the scene-network
  branch.
- Extended `code/24_test_community_precedes_label.py` so the full-data timing run can read:
  - `--exclude-city-file`
  - `--exclude-flag-column`
- Current geography-audit workflow now:
  - builds the audit universe from the union of:
    - `data/processed/scene_networks/city_network_stats.csv`
    - `data/processed/scene_networks/city_year_network_snapshots.csv`
  - writes:
    - `data/processed/scene_networks/city_geography_audit.csv`
    - `data/processed/scene_networks/city_geography_audit_summary.md`
  - current baseline exclusions: `155`
- Current strict lagged-timing configuration:
  - `min_bands = 10`
  - `community_min_genre_bands = 4`
  - `genre_share_threshold = 0.67`
  - geography exclusions loaded from `city_geography_audit.csv`
- Current strict rerun read:
  - `32,689` lagged city-year snapshots
  - `5,430` city-genre timing rows
  - `21` `community_precedes_label` cases
  - `86` `community_same_year_as_label` cases
  - `5,323` `community_not_detected_by_label` cases
  - median lead among precedes cases: `4` years
  - max lead among precedes cases: `14` years
- Current interpretation:
  - the first-pass `529` precedes headline collapses sharply under a materially cleaner baseline
  - repeated geography tightening has not pushed the precedes count below `21`
  - the remaining geography tail is now small and all-undetected:
    `Kanagawa Prefecture`, `Mississippi`, and `Transylvania` are the current excluded labels still
    visible in the latest timing file because the audit is built iteratively from the newest
    outputs
  - the bottleneck has shifted from raw data plumbing to substantive triage:
    inspect the surviving `21` cases and decide whether the scene-network branch still outranks
    the domestic-success redesign
- Added `code/26_audit_surviving_precedes_cases.py` to audit the surviving strict-baseline
  precedes cases.
- Wrote:
  - `data/processed/scene_networks/surviving_precedes_case_audit.csv`
  - `data/processed/scene_networks/surviving_precedes_case_audit.md`
- Current surviving-case read:
  - `21` surviving precedes cases
  - `8` `broad_scene_case`
  - `3` `mid_scene_case`
  - `10` `fragile_case`
  - `11` of `21` cases are `black_metal`
  - all `21` cases are detected on exactly `4` same-genre bands
- Ran a one-step robustness grid around the cleaned baseline:
  - `community_min_genre_bands = 4`, `genre_share_threshold = 0.75`:
    still `21` precedes cases
  - `community_min_genre_bands = 5`, `genre_share_threshold = 0.67`:
    `0` precedes cases
  - `community_min_genre_bands = 5`, `genre_share_threshold = 0.75`:
    `0` precedes cases
- Current interpretation:
  - the geography cleanup result is no longer the main uncertainty
  - the surviving signal is real enough to keep as a live branch, because some cases sit in large
    recognizable scenes
  - but it is count-fragile in absolute support size, so it does not currently look strong enough
    to dominate the whole project without manual validation of the strongest subset

---

### Session: 2026-03-26 (lagged community-vs-label timing pass built)
- Added a project-level `.gitignore` so git can track the metal source side without trying to
  absorb large local data folders.
- Local storage convention on this machine:
  - keep `research_ideas/metal/data/raw/` and `research_ideas/metal/data/processed/` on
    `D:\AI_data\research_ideas\metal\`
  - expose them back into the project through local junctions so the existing scripts can keep
    using the same relative paths
- Rewrote `code/24_test_community_precedes_label.py` from pilot-only mode into a full-data
  workflow built on the delivered member dump.
- Full-mode implementation now:
  - loads the cleaned band reference from `metal_archives_all_metal_band_clean.csv`
  - reads `full_musician_band_edges.csv` and turns `first_year_in_band` plus `last_year_in_band`
    into lagged city-year membership events
  - builds reusable lagged city-year scene snapshots rather than only a one-off timing memo
  - uses deterministic label-propagation community detection in full mode
  - scores a city-year community as genre-supporting when it has at least `3` same-genre bands and
    at least `50%` genre share
- Wrote:
  - `data/processed/scene_networks/city_year_network_snapshots.csv`
  - `data/processed/scene_networks/community_vs_label_timing.csv`
  - `data/processed/scene_networks/community_vs_label_results.md`
- Current full-pass read:
  - `34,645` lagged city-year snapshots
  - `5,756` city-genre timing rows across `1,826` cities
  - `529` `community_precedes_label` cases
  - `453` `community_same_year_as_label` cases
  - `4,774` `community_not_detected_by_label` cases
  - median lead among precedes cases: `4` years
  - max lead among precedes cases: `35` years
- Current interpretation:
  - the scene-network branch now has a real lagged timing object, not just static cross-sections
  - the first pass is promising but mixed rather than decisive
  - many strong precedes cases sit in tiny or awkward scene units, so geography cleanup is now the
    highest-value next move
  - the design decision is no longer "can the lagged test be built?" but "does the result survive
    a cleaner city definition and stricter community rule?"

---

### Session: 2026-03-26 (full member dump ingested; full city-network pass built)
- Staged the delivered Metal Archives member dump:
  - `data/raw/band_members_20260325.zip`
- Rewrote `code/20_ingest_member_data.py` so it now:
  - accepts `.zip` or `.csv`
  - supports the delivered role-level schema:
    - `band_id`
    - `person_id`
    - `member_name`
    - `current_member`
    - `role_description`
    - `date_from`
    - `date_to`
  - collapses multiple role rows to one `band_id x member_id` edge before building networks
- Wrote:
  - `data/processed/scene_networks/full_musician_band_edges.csv`
  - `data/processed/scene_networks/full_member_ingest_summary.md`
- Current ingest read:
  - `1,038,533` raw member-role rows
  - `971,877` unique member-band edges
  - `682,126` unique musicians
  - `152,923` musicians in `2+` bands (`22.4%`)
  - `29,469` band ids in the delivered file are not present in the current cleaned band reference,
    so some membership rows still lack merged band metadata
- Rewrote `code/21_build_city_networks.py` into a two-pass city-local workflow so it scales to the
  full edge file.
- Wrote:
  - `data/processed/scene_networks/city_network_stats.csv`
  - `data/processed/scene_networks/city_band_band_edges.csv`
  - `data/processed/scene_networks/city_network_summary.md`
- Current full-city read:
  - `22,572` cities with any member-linked bands
  - `2,319` cities with `10+` bands
  - median density: about `0.053`
  - median clustering: about `0.253`
  - median bridge-musician share: about `12.8%`
- Reran `code/23_test_network_predicts_genre.py` and updated its interpretation block so it no
  longer assumes the raw signs beforehand.
- Wrote:
  - `data/processed/scene_networks/mechanism_test_merged.csv`
  - `data/processed/scene_networks/mechanism_test_results.md`
- Current mechanism read:
  - raw density association with genre-emergence counts is negative
  - residualized density remains negative after partialling out city size
  - residualized clustering is positive
  - residualized bridge-musician share is positive and currently has the strongest simple fit
    (`R-squared` about `0.053`)
- Current roadmap read:
  - the member-data branch is now a real empirical design rather than a pilot-only idea
  - but the present evidence is still static and contemporaneous
  - the next real bottleneck is lagged network structure plus full `community_precedes_label`
    timing, not more static cross-sections
  - city-unit cleaning now matters:
    some labels are regions or otherwise unusual scene units, and the densest small-city outliers
    need auditing before they are treated as substantive benchmarks

---

### Session: 2026-03-21 (qualitative scene-evidence memo built)
- Added:
  - `data/processed/country_genre_analysis/scene_qualitative_evidence_source_map.csv`
  - `data/processed/country_genre_analysis/scene_qualitative_evidence_memo.md`
- Current qualitative read:
  - strongest mature-scene milestone cases:
    - `Dimmu Borgir` / Norway black metal
    - `Rhapsody` / Italy power metal
    - `Metallica` / U.S. heavy metal
  - clearest mixed scene-plus-breakthrough case:
    - `Sepultura` / Brazil thrash metal
  - clearest rising-scene or scene-building case:
    - `Nightwish` / Finland symphonic metal
- Current roadmap read:
  - the complements fork now has both quantitative and qualitative support
  - the immediate use is treatment triage, not final citation-ready literature
  - the next move is to prune or re-date weak shock-design rows using both sources together

---

### Session: 2026-03-21 (scene-complements diagnostic built)
- Added `code/13_build_scene_complements_diagnostic.py`.
- Wrote:
  - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_case_years.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_case_metrics.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_rankings.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_summary.md`
  - `data/processed/country_genre_analysis/domestic_success_pilot_scene_complements_scatter.png`
- Current read:
  - mature-scene milestone candidates:
    - `Dimmu Borgir` in Norway black metal
    - `Rhapsody` in Italian power metal
  - rising-scene breakthrough candidates:
    - `Nightwish` in Finnish symphonic metal
    - `Sepultura` in Brazilian thrash metal
  - deep and still-thickening cases:
    - `Pantera` and `Metallica` in the United States
- Current roadmap read:
  - the complementary-scenes story is now empirically live, not just conceptual
  - the most immediate use is to rank which current pilot rows are weakest for the original
    shock-based design
  - the next decision is whether to build a broader breakout-prediction risk file or first use
    this diagnostic to prune and re-date the shock-treatment file

---

### Session: 2026-03-21 (expanded domestic-success pilot and FE pass)
- Expanded `data/processed/country_genre_analysis/domestic_success_pilot_cases.csv` from `5` to
  `10` rows using existing source-backed home-market cases.
- Added:
  - `code/12_estimate_domestic_success_pilot_fe.py`
  - `data/processed/country_genre_analysis/domestic_success_pilot_fe_static.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary.md`
  - `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study.png`
- Updated the descriptive pilot read:
  - `10` pilot cases and `60` case-year rows
  - strongest current positive case remains:
    - `Sepultura` in Brazil `thrash metal`
  - all-band share-gap improvement is mixed:
    - `3` cases improve
    - `7` deteriorate
  - pooled all-band share gap drifts from about `5.2` percentage points in the pre-period mean
    to about `2.9` in the post-period mean
- First residualized FE read:
  - full-pilot static coefficient on all starts:
    - about `-7.5` with clustered SE `5.0`
  - strict `source_a + tier_1` subset static coefficient on all starts:
    - about `-11.8` with clustered SE `7.1`
  - average lead coefficients on all starts:
    - about `+2.9`
  - average post coefficients on all starts:
    - about `-4.1`
- Current roadmap read:
  - the first residualized pass does not rescue the design
  - the main problem now looks like late-coded or weak treatment timing rather than missing
    market coverage
  - the next clean move is to re-date or replace weak pilot rows before widening the file again
  - a second mechanism is now explicitly live in the notes:
    - local scene complements may help predict breakout success
    - this should be explored as a bounded alternative rather than treated as a full redesign yet

---

### Session: 2026-03-21 (domestic-success pilot event pass built)
- Locked the next-stage descriptive defaults:
  - main descriptive event baseline: `presence`
  - conservative robustness margin: `top10`
  - first genre baseline: broad `genre_family` cells
- Extended `data/processed/country_genre_analysis/country_genre_family_year_panel.csv` so it now
  preserves `all`, `unsigned`, and `signed` band-start margins.
- Added `code/11_build_domestic_success_pilot_event_pass.py`.
- Wrote:
  - `data/processed/country_genre_analysis/domestic_success_pilot_case_years.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_event_windows.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_event_study.csv`
  - `data/processed/country_genre_analysis/domestic_success_pilot_event_pass_summary.md`
  - `data/processed/country_genre_analysis/domestic_success_pilot_share_gap_event_study.png`
- Current pilot read:
  - `5` pilot cases and `30` case-year rows
  - strongest current positive case:
    - `Sepultura` in Brazil `thrash metal`
  - all-band share-gap improvement is mixed:
    - `2` cases improve
    - `3` deteriorate
  - pooled all-band share gap falls from about `10.2` percentage points in the pre-period mean
    to about `6.5` in the post-period mean
- Current roadmap read:
  - the project has moved beyond market expansion as the main bottleneck
  - the live bottleneck is now event timing quality and pilot-case quality
  - the next clean move is to broaden the domestic-success treatment file and then run a
    residualized country-genre specification

---

### Session: 2026-03-21 (United States certification extension built)
- Added `data/blockbuster_album_country_hits_usa_manual.csv` as a manual official-source
  supplement built from exact public RIAA album-certification matches.
- Rebuilt the core treatment outputs and influence memo after adding the United States:
  - `blockbuster_album_country_hits_core.csv`
  - `blockbuster_country_year_hit_panel.csv`
  - `blockbuster_country_year_hit_summary.md`
  - `blockbuster_band_influence_memo.md`
- Current six-market read:
  - `85` album-country rows
  - `41` top-10 rows
  - `15` certification rows
  - `51` country-year rows with some treatment signal
  - United States contributes `8` certification-led rows
- Current influence read:
  - `presence`: `57` band-market events and `45` complete windows
  - `certification`: `11` band-market events and `10` complete windows
  - `top10`: `30` band-market events and `19` complete windows
  - strongest home-market `presence` and `certification` case:
    - `Metallica` in the United States after `Load`
- Current roadmap read:
  - the U.S. extension is no longer pending
  - the main live choices now are event definition, genre-family baseline, and whether Brazil
    needs more hardening before the first country-genre domestic-success pass

---

### Session: 2026-03-21 (Australia extension built)
- Added `data/blockbuster_album_country_hits_aus_manual.csv` as an official-source Australia
  supplement built from the live ARIA albums-chart API.
- Rebuilt the core treatment outputs and influence memo after adding Australia:
  - `blockbuster_album_country_hits_core.csv`
  - `blockbuster_country_year_hit_panel.csv`
  - `blockbuster_country_year_hit_summary.md`
  - `blockbuster_band_influence_memo.md`
- Current five-market read:
  - `77` album-country rows
  - `41` top-10 rows
  - `7` certification rows
  - `46` country-year rows with some treatment signal
  - Australia contributes `9` rows and `6` top-10 rows
- Current roadmap read:
  - Australia is now a built same-language reference market
  - at that point, `United States` was the cleanest unbuilt extension
  - the next live choice is `United States` extension versus Brazil source hardening

---

### Session: 2026-03-21 (seed refresh and four-market rebuild)
- Added `code/10_probe_seed_refresh_candidates.py` plus:
  - `seed_refresh_candidate_probe.csv`
  - `seed_refresh_candidate_probe.md`
- Built `data/blockbuster_seed_refresh_candidate_pool.csv` as a reproducible candidate pool for
  the language-spillover seed refresh.
- Current probe read:
  - `12` candidates are source-supported additions under the current public ARIA or RIAA paths
  - the rejected or deferred candidates in this pass were:
    - `Powerwolf - Wake Up the Wicked`
    - `Lamb of God - Omens`
- Refreshed `data/blockbuster_album_seed.csv`:
  - seed size is now `37` albums
  - English-language seed size is now `33`
- Reran the market-priority and readiness checks:
  - `Australia` now has `33` same-language foreign seed candidates in the ranking output
  - `United States` now has `26` same-language foreign seed candidates in the ranking output
  - `Australia` now overlaps `9` seed albums in the public ARIA history window
  - `United States` now has `8` exact album-format public RIAA certification matches
- Rebuilt the existing four-market treatment outputs on the refreshed seed:
  - `blockbuster_album_country_hits_core.csv`
  - `blockbuster_country_year_hit_panel.csv`
  - `blockbuster_country_year_hit_summary.md`
  - `blockbuster_band_influence_memo.md`
- Current rebuilt panel read:
  - `68` album-country rows
  - `35` top-10 rows
  - `7` certification rows
  - `42` country-year rows with some treatment signal
  - `7` home-market top-10 rows
  - `28` foreign-market top-10 rows
  - market totals:
    - Brazil `6`
    - Germany `14`
    - United Kingdom `24`
    - Italy `24`
- Practical implication:
  - the seed refresh was worth doing
  - `Australia` is now a real next same-language market build
  - `United States` remains the best certification-led follow-up market

---

### Session: 2026-03-21 (country-genre family prototype)
- Added `code/08_rank_language_spillover_markets.py` plus:
  - `language_spillover_market_priority.csv`
  - `language_spillover_market_priority.md`
- Current ranking read:
  - the current seed is `25` albums, `22` of which are English-language
  - the same-language spillover design is therefore mostly an English-market design under the
    current seed
  - `Australia` is the clear next public-source extension
  - `United States` is the second-best extension but mainly through a certification-led `RIAA`
    path under the current audited source matrix
  - `Sweden`, `France`, and the already-built non-English reference markets are low-yield for the
    current same-language question unless the seed broadens toward more non-English-language acts
- Fixed a data hygiene bug in `data/source_matrix.csv`:
  - the Brazil row was missing its `preferred_treatment_use` field
  - it now records `manual_home_market_extension`
- Added `code/09_probe_language_spillover_readiness.py` plus:
  - `australia_aria_seed_overlap.csv`
  - `usa_riaa_seed_probe.csv`
  - `language_spillover_build_readiness.md`
- Current readiness read:
  - Australia is still the cleanest conceptual next same-language market
  - but the live public ARIA albums-chart history currently reaches back only to `2019-07-01`
  - that overlaps exactly one current seed album:
    - `Ghost - Impera`
  - the public RIAA path is machine-readable enough to recover exact album-format certification
    matches, but only for `4` current seed albums:
    - `Metallica - Load`
    - `Metallica - Death Magnetic`
    - `Sepultura - Roots`
    - `Rammstein - Sehnsucht`
  - the current bottleneck is therefore seed-source overlap, not just which market to add next
- Added an explicit domestic-success build checklist to `notes/05_research_plan.md`.
- Current highest-upside path is now recorded more clearly:
  - domestic success as the main treatment
  - same-language foreign success as the first spillover margin
  - different-language foreign success as the weaker comparison margin
- Wrote `data/processed/country_genre_analysis/domestic_success_pilot_design.md` as the first
  operational rule memo for the stronger design.
- Key rule choices now locked in that memo:
  - use visible home-market success, not first obscure existence
  - allow `album_led`, `song_led`, `certification_led`, and `chart_presence_led` events
  - keep Tier 1 and Tier 2 events in the first pilot
  - treat language as a spillover boundary in the next coding step
- Built `data/processed/country_genre_analysis/domestic_success_pilot_cases.csv` and
  `data/processed/country_genre_analysis/domestic_success_pilot_cases_summary.md`.
- Current pilot rows:
  - Brazil `thrash metal` / Sepultura / `Roots`
  - Germany `industrial metal` / Rammstein / `Herzeleid`
  - Finland `symphonic metal` / Nightwish / `Sacrament Of Wilderness`
  - Italy `power metal` / Rhapsody / `Power of the Dragonflame`
  - Norway `black metal` / Dimmu Borgir / `Stormblast`
- Current read:
  - the pilot is already useful because it spans several countries and event types
  - the weakest current rows are Italy and Norway, which still need better historical first-in-cell
    checks
- Built `code/07_preview_spillover_coding.py` plus the first spillover-coding outputs:
  - `domestic_success_spillover_rule.md`
  - `foreign_spillover_coding_preview.csv`
  - `foreign_spillover_coding_counts.csv`
  - `foreign_spillover_coding_summary.md`
  - `pilot_market_language_reference.csv`
- Current spillover preview read:
  - `domestic_success = 12`
  - `same_language_foreign = 10`
  - `different_language_foreign = 24`
  - `multiple_language_foreign = 1`
  - the rule works mechanically, but same-language foreign variation is still too concentrated in
    the UK to be comfortable as a serious estimating margin yet
- Rewrote `notes/02_literature_and_synthesis.md` from a placeholder strand map into a real
  verified literature note spanning economics, economic geography, sociology, and popular-music
  studies.
- Current literature read:
  - there is useful prior work on domestic bias, digitization, artist entry, scenes, and genre
    formation
  - the main apparent opening is still the missing direct economics paper on domestic breakthrough
    effects on later `country x genre x year` producer entry
- Added `code/06_build_country_genre_growth_panel.py` to convert the cleaned all-metal Metallum
  build into a reusable `country x genre_family x year` panel.
- Wrote the first outputs in `data/processed/country_genre_analysis/`:
  - `country_genre_family_year_panel.csv`
  - `brazil_thrash_vs_rest_of_world.csv`
  - `brazil_thrash_metal_vs_rest_of_world_share.png`
  - `thrash_metal_selected_countries_share.csv`
  - `thrash_metal_selected_countries_share.png`
  - `country_genre_growth_summary.md`
- The panel currently uses broad genre families rather than raw Metal Archives genre strings,
  because the raw string space is too fragmented for a clean country-genre design.
- The first graph choices are illustrative only. They should not be read as committing the
  project to Brazil as the anchor case.
- Current descriptive read:
  - one graph compares Brazil's thrash share against the corresponding rest-of-world share
  - a second graph compares several large thrash countries on one chart
- Important scope note:
  - this is a prototype outcome object, not the final treatment timing
  - the next research step is to replace first observed genre-country starts with a curated
    `country-genre breakthrough` event rule

---

### Session: 2026-03-20 (broader visibility-vs-certification-vs-top10 memo)
- Rewrote `code/04_build_band_influence_memo.py` so the influence workflow no longer depends only
  on `first_top10_by_band_market`.
- The current memo now compares three band-market definitions:
  - `first_presence_by_band_market`
  - `first_certification_by_band_market`
  - `first_top10_by_band_market`
- Current sample sizes:
  - `presence`: `33` band-market events, `32` complete windows, `8` complete home-market windows
  - `certification`: `3` band-market events, `3` complete windows, `2` complete home-market
    windows
  - `top10`: `17` band-market events, `15` complete windows, `4` complete home-market windows
- Current broad read:
  - `presence` is the most informative general descriptive margin
  - it now lets Brazil matter through `Sepultura - Roots` and `Angra - Rebirth`
  - `top10` remains useful as the conservative blockbuster margin, but it is no longer the only
    meaningful event definition

---

### Session: 2026-03-20 (Brazil Sepultura hardening pass)
- Improved the Brazil manual supplement specifically on the Sepultura side:
  - added `sepultura_roots_1996` to `data/blockbuster_album_country_hits_bra_manual.csv`
    using a named journalistic source that states `Roots` reached gold in Brazil
  - replaced `sepultura_nation_2001` with a Dicionario Cravo Albin source and shifted the
    certification timing to `2001`
- Rebuilt the treatment outputs:
  - `data/processed/blockbuster_album_country_hits_core.csv`
  - `data/processed/blockbuster_country_year_hit_panel.csv`
  - `data/processed/blockbuster_country_year_hit_summary.md`
- Current four-market treatment build now recovers:
  - `47` album-country rows
  - Brazil: `6` rows
  - Germany: `14` rows
  - United Kingdom: `13` rows
  - Italy: `14` rows
  - `24` top-10 rows
  - `5` certification rows
- Current implication of the Brazil pass:
  - Brazil now has explicit Sepultura home-market certification years in `1996`, `2001`, and
    `2008`
  - the weakest remaining Brazil rows are now much more specific:
    - `Angra - Rebirth`
    - `Angra - Temple of Shadows`
    - `Sepultura - Dante XXI`
  - the top-10 event sample and influence ranking do not change because this pass affects only
    certification timing, not top-10 rows

---

### Session: 2026-03-20 (Italy official-source cleanup and summary fix)
- Expanded the curated seed with cleaner official FIMI-recoverable Italian flagship rows:
  - `Lacuna Coil - Delirium`
  - `Rhapsody - Power of the Dragonflame`
  - `Rhapsody of Fire - Triumph or Agony`
- Kept `Lacuna Coil - Comalies` in the seed only as a historical benchmark and marked it
  explicitly as an official FIMI dead end with no chart or certification evidence recovered.
- Rebuilt the treatment outputs:
  - `data/processed/blockbuster_album_country_hits_core.csv`
  - `data/processed/blockbuster_country_year_hit_panel.csv`
  - `data/processed/blockbuster_country_year_hit_summary.md`
- Current four-market treatment build now recovers:
  - `46` album-country rows
  - Brazil: `5` rows
  - Germany: `14` rows
  - United Kingdom: `13` rows
  - Italy: `14` rows
  - `24` top-10 rows
  - `35` country-year rows with any treatment signal once chart-weeks are counted
- Current implication of the Italy pass:
  - Italy is now materially cleaner for official chart-presence intensity
  - Italy adds home-market chart-presence years in `2002`, `2006`, and `2016`
  - but it does not add new domestic top-10 or certification events, so the complete
    home-market first-hit window count stays at `4`
- Fixed the summary logic in `code/03_build_core_treatment_panel.py` so chart-weeks-only years are
  no longer omitted from the "any treatment signal" table.

---

### Session: 2026-03-20 (residualized ranking and event-study pass)
- Reworked `code/04_build_band_influence_memo.py` so the influence workflow now residualizes
  all-metal and unsigned entry on country and year fixed effects before comparing event windows.
- Added a new output:
  - `data/processed/blockbuster_band_influence_event_study.csv`
- Refreshed the other influence outputs:
  - `data/processed/blockbuster_band_influence_event_windows.csv`
  - `data/processed/blockbuster_band_influence_ranking.csv`
  - `data/processed/blockbuster_band_influence_memo.md`
- Current residualized read:
  - strongest single-market residualized all-metal case: `Nightwish` in Germany after `Once`
    at about `+155.6` bands per year
  - strongest home-market residualized case: `Iron Maiden` in the United Kingdom after
    `Brave New World` at about `+56.8` bands per year
  - `Metallica` and `Sepultura` remain tied in the multi-market residualized ranking because the
    bundled `1996` foreign-market events are still not separable
  - the aggregate event-study profile is still noisy, with pooled residuals remaining negative
    through the pre-period and turning clearly positive only by `t+2`

---

### Session: 2026-03-20 (Brazil manual supplement and seed expansion)
- Added a Brazil manual supplement:
  - `data/blockbuster_album_country_hits_bra_manual.csv`
- Expanded the curated seed with additional Brazilian home-market flagship albums:
  - `Angra - Rebirth`
  - `Angra - Temple of Shadows`
  - `Sepultura - Nation`
  - `Sepultura - Dante XXI`
- Updated the core treatment builder so manual rows can use year-level timing when a blocked
  source prevents recovery of a precise weekly chart or certification date.
- Rebuilt the treatment outputs:
  - `data/processed/blockbuster_album_country_hits_core.csv`
  - `data/processed/blockbuster_country_year_hit_panel.csv`
  - `data/processed/blockbuster_country_year_hit_summary.md`
- Current four-market treatment build:
  - `42` album-country rows
  - Brazil: `5` rows
  - Germany: `14` rows
  - United Kingdom: `12` rows
  - Italy: `11` rows
  - `24` top-10 rows
  - `24` country-year rows with non-zero top-10 or certification signal before the later
    chart-weeks summary fix
- Current split read after Brazil:
  - `5` home-market top-10 rows
  - `19` foreign-market top-10 rows
  - `4` complete home-market first-hit windows
  - `11` complete foreign-market first-hit windows
  - Brazil now contributes one complete home-market first-hit window:
    - `Angra` in Brazil after `Temple of Shadows`
- Important caveat:
  - Brazil is currently a provisional market extension
  - the supplement originally mixed one official band press release with clearly labeled
    secondary-source chart and certification traces because direct Pro-Musica retrieval is blocked
    in this environment

---

### Session: 2026-03-20 (home-vs-foreign treatment split)
- Added home-versus-foreign coding to the treatment build:
  - `blockbuster_album_country_hits_core.csv` now includes `market_exposure_type`,
    `home_market_i`, and `foreign_market_i`
  - `blockbuster_country_year_hit_panel.csv` now includes split treatment columns for top-10,
    number-one, chart weeks, and certification counts
- Rebuilt the treatment outputs successfully after adding retry logic for transient chart-source
  request failures.
- Current split counts:
  - `36` album-country rows total
  - `22` top-10 rows total
  - `4` home-market top-10 rows
  - `18` foreign-market top-10 rows
- Updated the influence workflow so the event-window and ranking outputs carry the same split.
- Current split read:
  - `3` complete home-market first-hit windows
  - `10` complete foreign-market first-hit windows
  - strongest home-market case: `Iron Maiden` in the United Kingdom after `Brave New World`
  - strongest foreign-market case: `Nightwish` in Germany after `Once`
- Practical implication:
  - the project can now distinguish domestic exemplar effects from foreign-blockbuster exposure
  - but the home-market sample is still too thin to anchor the project on its own

---

### Session: 2026-03-20 (Germany build, baseline lock, influence memo)
- Extended the core treatment build to Germany using a manual official-source supplement because
  `offiziellecharts.de` blocks scripted requests in this environment.
- Fixed the core treatment builder so Germany date fields are parsed as ISO dates rather than as
  FIMI week codes.
- Rebuilt the treatment outputs:
  - `data/processed/blockbuster_album_country_hits_core.csv`
  - `data/processed/blockbuster_country_year_hit_panel.csv`
  - `data/processed/blockbuster_country_year_hit_summary.md`
- Current three-market treatment build:
  - `36` album-country rows
  - Germany: `14` rows
  - United Kingdom: `11` rows
  - Italy: `11` rows
  - `22` top-10 rows
  - `19` country-year rows with non-zero treatment signal
- Locked the baseline treatment choice:
  - keep the country-year hit-intensity panel as the baseline
  - use first-hit band-market windows as a derived diagnostic rather than as the main treatment
    object
- Added the first reproducible influence-memo workflow:
  - `code/04_build_band_influence_memo.py`
  - `data/processed/blockbuster_band_influence_event_windows.csv`
  - `data/processed/blockbuster_band_influence_ranking.csv`
  - `data/processed/blockbuster_band_influence_memo.md`
- Current descriptive influence read:
  - `Iron Maiden` is the strongest positive multi-market band in the current sample
  - `Nightwish` in Germany is the largest single-market raw-delta case
  - bundled `1996` country-year hits mean `Metallica` and `Sepultura` are not cleanly separable
    in the current three-market panel

---

### Session: 2026-03-20 (UK/Italy core treatment panel build)
- Added `code/03_build_core_treatment_panel.py` to expand the active metal seed into official
  treatment rows for the United Kingdom and Italy.
- Wrote the first machine-readable treatment outputs:
  - `data/processed/blockbuster_album_country_hits_core.csv`
  - `data/processed/blockbuster_country_year_hit_panel.csv`
  - `data/processed/blockbuster_country_year_hit_summary.md`
- Current build result:
  - `22` album-country rows across the active seed
  - United Kingdom: `11` rows, `6` top-10 rows
  - Italy: `11` rows, `5` top-10 rows, `1` certification row
- Current practical implication:
  - the metal treatment side is no longer just a hand-built pilot
  - the next treatment step is Germany
  - once Germany is added, the project should decide whether to keep the annual intensity panel or
    simplify to a first-breakthrough event file

---

### Session: 2026-03-20 (notes structure refit)
- Refit the metal notes to the stronger shared notes house style across:
  - `notes/01_project_overview.md`
  - `notes/02_literature_and_synthesis.md`
  - `notes/03_model_notes.md`
  - `notes/04_empirical_notes.md`
  - `notes/05_research_plan.md`
- Locked the internal note structure more clearly:
  - `01` now uses project intention, motivating intuition, scope, risks, lock questions, and
    roadmap sections
  - `02` now separates literature strands, synthesis, and open verification tasks
  - `03` now uses explicit `# Model N` blocks
  - `04` now uses explicit `# Strategy N` blocks
  - `05` now records the decision log, design lock criteria, and owner-plus-deliverable next tasks
- Verification:
  - `&_shared/scripts/organize_notes.ps1 -ProjectPaths research_ideas/metal -FailOnViolations`
    passed cleanly

---

### Session: 2026-03-20 (question expansion: influential bands)
- Added an explicit secondary question to the metal project:
  - which bands appear most influential for later startup, measured by downstream entry effects
    rather than by style alone
- Locked the interpretation:
  - "influential" here means later band formation associated with a band's breakthrough or hit
    exposure
  - this can be tracked on several margins:
    - all-metal entry
    - subgenre-specific entry
    - unsigned entry
    - later signed entry
- Practical implication:
  - once the treatment event panel exists, the project can produce both an average treatment design
    and a band-influence ranking
  - that ranking should be residualized or event-style, not a naive post-hit count

---

### Session: 2026-03-20 (seed list and hit rule)
- Added the first active curated treatment seed:
  - `data/blockbuster_album_seed.csv`
- Added the first operational hit-rule memo:
  - `data/blockbuster_hit_rule.md`
- Locked the first treatment-side rule:
  - scope: metal-only curated seed, release year `>= 1995`
  - Tier A `tier_a_global_anchor` for strong cross-market blockbuster candidates
  - Tier B `tier_b_home_market_flagship` for domestic flagship releases
  - baseline hit timing: first official top-10 national album-chart entry
  - fallback timing: first official gold-or-higher certification date
  - baseline country-year treatment: `hit_top10_ct`
  - secondary intensity measures: `hit_no1_ct`, `hit_chart_weeks_ct`, `hit_certified_ct`
- Practical implication:
  - the project no longer needs to decide what a first-pass "hit" is before extraction starts
  - the next treatment-side bottleneck is now scaling the UK and Italy workflow to the current
    seed, then adding Germany
- Important scope note:
  - the earlier Linkin Park row in the UK/Italy pilot file should be treated as a workflow stress
    test only, not as part of the active metal seed

---

### Session: 2026-03-20 (all-metal outcome build)
- Confirmed that the Metallum SQLite snapshot contains `163,965` rows in `band_info`, so the
  project does not need to stay inside the old pilot-family subset.
- Added `code/02_build_all_metal_outcome.py` to build an all-metal outcome directly from the full
  Metallum snapshot.
- Wrote outputs to `data/processed/`, including:
  - `metal_archives_all_metal_band_clean.csv`
  - `metal_archives_all_metal_country_year_panel.csv`
  - `metal_archives_all_metal_core_country_summary.csv`
  - `metal_archives_all_metal_unmatched_countries.csv`
  - `metal_archives_all_metal_summary.md`
- Current read from the all-metal build:
  - matched countries: `161,945`
  - usable formed years: `131,511`
  - matched and dated rows: `130,108`
- Working project recommendation now locked:
  - default outcome for this project: all metal bands in Metallum
  - genre restrictions are not part of the baseline design

---

### Session: 2026-03-20 (outcome-scope exploration)
- Added `code/01_explore_outcome_scope.py` to quantify how sparse the reused Metallum outcome is
  under different genre scopes.
- Wrote outputs to `data/exploration/`, including:
  - `outcome_scope_summary.md`
  - `core_country_outcome_scope_summary.csv`
  - `core_country_outcome_scope_years.csv`
  - `top_country_scope_rankings.csv`
  - `pilot_hit_event_windows.csv`
- Fixed `data/blockbuster_album_country_hits_pilot_sample.csv` so it is valid CSV and can be read
  by code.
- Current read from the exploration:
  - strict technical-death sample is usable but relatively sparse for this new question
  - broad technical-family counts are much denser in the main treatment markets
  - United Kingdom, Germany, and Italy become especially more attractive under the broad outcome
- This is now a transitional diagnostic only. It was useful for showing that the old narrow pilot
  scope was too restrictive, but it is no longer the project's default outcome definition.

---

### Session: 2026-03-20 (project initialization)
- Created a separate `research_ideas/metal/` branch folder to hold the blockbuster-album idea as
  its own project rather than as a sub-branch of `learning_by_viewing`.
- The intended starting outcome data are not duplicated yet. The current reusable paths live in:
  - `research_ideas/learning_by_viewing/music/data/strategy_8_music_pilot/processed/music_pilot_country_year_panel.csv`
  - `research_ideas/learning_by_viewing/music/data/strategy_8_music_pilot/processed/metal_archives_band_clean.csv`
- Current project logic:
  - outcome side already exists in a usable country-year format
  - treatment side is the hard part
  - the first tractable design may need to use major-hit proxies rather than full sales panels
- Core open choices:
  - country shock versus language shock
  - certifications versus chart peaks versus curated blockbusters
  - whether the first pass should remain technical-death-metal only or later broaden to more of
    metal once the treatment side works

---

### Session: 2026-03-20 (official source audit)
- Audited current treatment-side source feasibility using official or primary sources.
- Current practical read:
  - full country-by-year album sales are unlikely to be the best first build
  - official chart archives and certification databases are feasible for a core set of countries
  - Luminate looks like the strongest commercial fallback if open-source chart proxies prove too
    noisy
- Locked the first treatment recommendation:
  - curated blockbuster metal album list
  - country-specific chart-entry shocks and chart-run measures
  - certification thresholds as a secondary intensity measure
  - core first countries: US, UK, Germany, Italy, Sweden, Australia
  - target start year around 1995
- Important language-design note:
  - language spillovers still look promising
  - but they should be added only after the country-year shock panel works, because metal often
    circulates in English even outside English-speaking countries
- Added the first treatment-side scaffolds:
  - `data/source_matrix.csv`
  - `data/blockbuster_album_seed_template.csv`
  - `data/blockbuster_album_country_hits_template.csv`

---

### Session: 2026-03-20 (UK and Italy pilot extraction)
- Built the first hand-collected pilot sample:
  - `data/blockbuster_album_country_hits_pilot_sample.csv`
- Current pilot albums:
  - Iron Maiden, `The Book of Souls`
  - Linkin Park, `Hybrid Theory`
- Current pilot countries:
  - United Kingdom
  - Italy
- Pilot read:
  - UK Official Charts album pages are rich enough to recover first chart date, peak, weeks, and
    the full weekly run
  - FIMI search pages are rich enough to recover entry week, peak, run length, and certification
    timing
  - the real scaling issue is now the curated album seed, not whether the country sources exist

## Working conventions

- Keep this project notes-first until the treatment data path is credible.
- Reuse the existing Metallum build where possible rather than duplicating files too early.
- Distinguish clearly between what exists now and what is still a proposed data source.
