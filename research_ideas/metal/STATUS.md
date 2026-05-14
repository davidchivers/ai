# STATUS - Metal

## Snapshot

- Last updated: 2026-05-13 (D-drive data restored and external-arrival final audit rerun)
- Current phase: the main paper is `scene -> genre emergence`. The headline result is now limited
  to local spawning flow, target-genre active bands, and target-genre multi-band musicians.
  Broker or connector language is background only. The live draft now also frames the preferred
  specification more explicitly as a within-cell transition into operational scene status rather
  than as a quasi-structural scene production function, and the role-composition material is kept
  firmly in the background. The band-success sidecar is now materially wider as a data workflow
  and has been reframed as an upgrading ladder rather than a naive band success regression: the
  current matched file reaches `16` home-market presence cases, `13`
  home-market validation cases, `12` foreign-market presence cases, and `5`
  `validated_then_foreign` cases across `BRA`, `DEU`, `FIN`, `FRA`, `GBR`, `ITA`, `NOR`, `SWE`,
  and `USA`. That is conceptually much cleaner than the older `ever successful` outcome, but it is
  still too sparse to become a headline result, because the median founding-to-first-home-market
  presence gap is `16.5` years and the audited `city x genre_family x formed_year` cohort file
  still produces only `5` home-market validated winner cohorts within `15` years. The thick-scene
  network figure is now explicitly parked rather than treated as the active bottleneck: the
  Helsinki cases remain useful as exploratory visuals, but the paper should not wait on a network
  figure until there is a better direct-control workflow. There is now also a first exploratory
  scene-diffusion prototype for `black_metal`: the animated map matches `895` geography-clean
  emerged cities and `14,694` matched city-year observations, and it looks more like a sequence of
  hub formation and spread than a one-origin narrative. That branch is still descriptive and
  secondary. The paper should stay economics-first and scene-first, with heavy metal as the
  empirical laboratory for creativity and innovation.
  A 2026-05-13 recovery pass traced the missing `D:\AI_data\research_ideas\metal` raw/processed
  contents to an April 30 local cleanup of `C:\Users\Dave_\AI\.claude\worktrees`, whose
  `research_ideas_metal` worktree contained junctions into the real `D:` data targets. The
  band-level all-metal outcome, treatment-side outputs, country-genre diagnostics, and
  `city_genre_first_appearance.csv` were regenerated. The missing raw archives were later found in
  local downloads/Outlook attachment cache and moved to `D:\AI_data\research_ideas\metal\raw`.
  Known C-drive copies of those two recovered archives were removed. The member dump now ingests
  again from `data/raw/band_members_20260325.zip`, producing `971,877` unique member-band edges,
  and the downstream scene-network and external-arrival files have been rebuilt on the D-backed
  processed-data junction.
  There is also a band-level world animation prototype in `notes/13_band_world_animation_workflow.md`
  using `black_metal` band activity spans. It renders `101,092` matched band-year observations on a
  `3`-year grid and is useful as a visual check on whether the genre can be shown as a moving world
  map of active bands. It is still exploratory and secondary. The first serious diffusion panel now
  also exists for `black_metal`: lagged exposure to already-emerged hubs is positive in standalone
  year-FE specifications, but it washes out once lagged local same-genre band stock is included.
  So the diffusion branch is interesting, but the current evidence still says local scene thickness
  is the main empirical object. The first multi-genre check points the same way across
  `black_metal`, `death_metal`, `thrash_metal`, `doom_metal`, and `power_metal`: diffusion is
  visually real, but the external hub-exposure terms mostly do not survive once local thickness is
  included.
  A new broad digital-era split check now points in a related direction. In the preferred
  exact-year fixed-effects scene regression, local spawning flow attenuates from `0.0177` before
  1995 to `0.0071` in `2005-2014`, and target-genre active-band stock attenuates from `0.0977` to
  `0.0310`. But target-genre multi-band musicians remain stable at `0.0270`, `0.0312`, and
  `0.0325` across the same three periods. That is useful as a descriptive robustness check on
  whether digitization reduced some local scene advantages without making within-genre overlapping
  worker depth irrelevant.
  There is now also a real reusable city-broadband data workflow on this machine. Official Ookla
  Open Data fixed-broadband parquet files from `2019 Q1` to `2025 Q4` have been mirrored to
  `D:\AI_data\shared\connectivity\ookla_open_data\`, and a first proof-of-concept
  `black_metal` city-quarter panel has been built for `895` cities. That is useful for later
  recent-period city work and for the other project, but it does not solve the early internet-era
  question in the main metal paper because the coverage starts only in `2019`.
  The model note has also now been rewritten into a more explicit economics object. The live
  preferred theory is a local variety-creation model with two micro-mechanisms: spinouts and
  recombination through overlapping workers. Diffusion remains an extension only.
  The theory note has now been rewritten to match that read: the live conceptual framework is local
  niche formation through labor pooling, spinouts, and recombination, with diffusion as a
  secondary extension rather than the headline object.
  That compact framework is no longer isolated in `notes/03_model_notes.md`; it is now folded into
  `notes/08_scene_paper_sections.md`, so the live paper draft and the theory note are aligned.
  The main draft is also now explicitly structured as `Data`, `Empirical approach`, and `Results`,
  which is a better paper order than the earlier mixed data-and-design section.
  Paper writing has now started explicitly at the user's request. The project has a first
  solo-author LaTeX draft in `drafts/metal.tex`, backed by section files for `data`, `method`, and
  `results`, plus three initial tables and inserted figures. That draft compiles successfully to
  `drafts/metal.pdf`. The current paper order is now cleaner and more standard:
  - literature review
  - empirical motivation
  - model
  - data
  - empirical approach
  - results
  The model and literature sections have now both been materially strengthened. The model is no
  longer a short conceptual paragraph: it now contains a compact differentiated-variety setup with
  heterogeneous founders, spinout status, overlapping-project experience, endogenous entry costs,
  aggregate entry, and an emergence threshold. The literature review has been expanded around the
  same mechanism spine rather than generic background.
  The draft now also has:
  - a short literature-review section
  - an empirical-motivation section
  - a new static black-metal diffusion figure built from the scene-diffusion panel in
    `code/51_build_black_metal_diffusion_snapshots.py`
  An internal AER-style referee report now also exists in `referee/aer_referee_report.md`, and the
  practical read is useful but blunt: the project looks like a promising field-journal paper, not
  an AER paper in current form. The main objection is that the current threshold-based emergence
  result may still be too close to a mechanical local-thickness fact. The second objection is that
  the paper remains too reduced-form and setting-specific for AER even though the data object is
  genuinely interesting. A concrete revision sequence now exists in
  `referee/aer_revision_plan.md`. That plan says the immediate bottlenecks are:
  - front-end rewrite into a real introduction-led paper
  - a direct answer to the mechanical-threshold objection
  - stronger substantive validation of the emergence measure
  That threshold-response package now exists in live paper form. Under alternative emergence
  cutoffs of `3`, `4`, `5`, `6`, and `8` bands, the three headline scene coefficients stay
  positive. But the stronger distance-from-threshold checks are more sobering: once the sample is
  restricted to cells that are still far below the cutoff, the pattern attenuates sharply and the
  target-genre multi-band coefficient is no longer distinguishable from zero. The safest current
  paper read is therefore late-stage local niche consolidation rather than the earliest seed stage
  of scene formation. The mechanism read is now sharper as well. A focal niche-specificity check
  still keeps target-genre multi-band musicians positive once target-genre active musicians are
  added, while target-genre active musicians turn negative. In a companion specification, a
  residual outside-focal multi-band margin also turns negative while the focal same-genre overlap
  term stays positive. That makes the overlap result look more niche-specific rather than more
  generic. A final referee-style stabilization pass has also now tightened the paper on
  presentation rather than expansion: claim language is slightly more disciplined, the city-level
  clustering choice is now explained explicitly in the method section, and the data section no
  longer overstates the archive universe as a literally complete census of metal. There is now
  also a final stop-or-stabilize memo in `referee/field_journal_stop_or_stabilize_memo.md`, and
  its recommendation is to stabilize rather than widen the paper again.
  The measurement-validation package now also exists in live paper form. The preferred exact-year
  sample is already geography-clean on the current audit rule, with zero region-like rows and zero
  malformed-label rows surviving into the live fixed-effects panel. Tightening the geography screen
  further does not materially change the headline result: dropping the small-dense labels,
  restricting the sample to `1990` onward, and restricting to the `23` countries with at least
  `50` emergence events all leave local spawning flow, target-genre active bands, and
  target-genre multi-band musicians close to their baseline values. A short historical sanity table
  is also now in the appendix. Birmingham heavy metal (`1977`), Tampa death metal (`1987`),
  Bergen black metal (`1992`), Oslo black metal (`1990`), and Gothenburg melodic death metal
  (`1996`) all look broadly plausible as operational scene dates, while the Bay Area thrash row is
  useful as a geography check because it is intentionally excluded from the city baseline as a
  wider-unit label.
  The scope cleanup is now also done in the live draft. The digital-era split remains as a short
  descriptive appendix note, but the broader internet-adoption and city-broadband probes have been
  pushed out of the main results section because they are too broad, too late, or too small to
  identify a local digital mechanism cleanly. The main paper is now more clearly centered on the
  critical-mass fact and the preferred exact-year scene result.
  The main-table interpretation has now also been tightened. The preferred table and method
  section now make explicit that the lagged predictors are z-scored, so the headline coefficients
  are directly comparable on a common within-sample scale. The draft now states that local
  spawning flow corresponds to about `1.3` percentage points, target-genre active bands to about
  `5.1` percentage points, and target-genre multi-band depth to about `2.3` percentage points
  relative to a `3.09` percent event rate. The negative overall multi-band-musician control is now
  explained as a conditional niche-specificity result rather than as evidence against worker
  overlap.
  A third internal AER-style referee read now also exists, and the tone has shifted in a useful
  way. The recommendation remains reject at AER standard, but the practical read is now that the
  draft has crossed into a coherent field-journal paper rather than a sprawling working memo. The
  main remaining issues are no longer missing packages or obvious structural clutter. They are
  tighter claim discipline, a possible compression of the role-composition paragraph, and one more
  front-end polish pass if needed.
  That front-end polish pass is now also done. The abstract and introduction have been rewritten to
  speak more directly to the bounded paper the project actually supports: local scene emergence in
  heavy metal, a carefully validated reduced-form result, and a narrower late-stage
  niche-consolidation interpretation. The opening pages now lean less on broad general-interest
  aspiration and more on the specific contribution the data and design can defend.
  The literature review has now been compressed as well. It still keeps the economic-geography,
  agglomeration, spinout, recombination, variety, digitization, and genre-formation anchors, but
  it now does so with less explanatory detour. The middle of the paper is therefore better aligned
  with the tighter front end and results section.
  There is now also a clean field-journal positioning memo in `referee/field_journal_positioning_memo.md`.
  That memo states the bounded contribution directly in field-paper terms rather than through the
  negative lens of what would fail at the AER bar.
  A separate causal-follow-on strategy note now also exists in `notes/23_breakout_demand_shock_design.md`.
  The current recommendation is not to stretch the live scene paper into a causal paper. If a
  quasi-causal extension is pursued, the first serious branch should instead be a breakout-demand
  shock design: a stacked city-by-genre event study around a small number of clean
  `country x genre_family` breakout episodes, using pre-shock local capability to identify
  differential response within the treated country-genre. The central-musician-loss idea remains
  interesting, but only as a second-ranked feasibility audit. That branch has now also been pushed
  into real workflow form. Under the strict top-10 first-breakout screen, the operational stack
  now reaches `6` events and `97` positive-capability city-event cells at `t = -1`. Promoting
  `Angra - Temple of Shadows` into the live branch via the archived `Epoca` page publication date
  as observed event timing also lifts the relaxed peak-20 extension to `10` events and `187`
  positive-capability city-event cells. That relaxed stack is now better grounded on three
  margins: the retained Italian gothic-metal first breakout is `Lacuna Coil - Karmacode` in
  `2006`, recovered directly from official FIMI chart pages with entry `W14-2006`, peak `17`, and
  a run reaching `20` weeks; the retained Swedish power-metal first breakout is `Sabaton - Carolus
  Rex` in `2012`, recovered from official Sverigetopplistan pages with first placement `W22-2012`,
  peak `2`, and a run reaching `31` weeks; and the retained Brazilian power-metal first breakout
  is now `Angra - Temple of Shadows` in `2005`, with observed event date `2005-11-17`, `39`
  positive-capability cities, and `117` years with genre starts. But the branch still fails the
  descriptive gate because positive-capability cities remain dramatically different before the
  breakout and the margin is still partly driven by `DEU x power_metal x 2012`.
  Brazil is therefore no longer just a source-recovery margin for this branch. The live retained
  row is now in place. But the earlier Brazilian target still matters: `Angra - Rebirth` is now
  anchored on an archived official Angra-site gold report dated `2001-12-20`, with additional
  official-site launch traces on `2001-09-15` and `2001-11-26`, while the live Pro-Musica
  certificate search still returns zero results for `Angra`, so `Rebirth` remains a weaker
  certification-timed earlier-breakout candidate rather than a chart-entry event.
  `Lacuna Coil - Comalies` also remains an official dead end under the current FIMI workflow. So the
  breakout-demand branch is still a useful feasibility object rather than a regression-ready causal
  paper, and it should stay parked unless the explicit re-entry rule in
  `notes/29_breakout_branch_parking_memo.md` is met.
  The central-musician-loss branch has now also moved past pure first-pass audit. The original
  precision-first shortlist built from the live member-edge data still recovers `31` audit-ready
  rows after requiring fully observed terminal years, `3+` lifetime bands, `2+` local same-genre
  bands at the terminal year, at least `5` active local same-genre bands in the scene, and a
  fallback to the most recent earlier scene snapshot capped at a `2`-year gap. But the workflow
  has now been extended through relaxed recovery shortlists that allow blank terminal years,
  looser local-band thresholds, and an any-current margin for known connector names that the strict
  screen misses. That deeper audit now yields a much larger clean object in
  `data/processed/scene_networks/central_loss_verified_death_events.csv`, currently with `20`
  verified death events. The verified set now includes the earlier first-pass deaths plus later
  recoveries such as `Ivo Rocha`, `Apollyon Baphomet`, `Franco Crucifixion`, `Azizi`, `Warwolf`,
  `Sergey Bokarev`, `Micha Laska`, and `Doomicus Stardust`. The audit ledger has also become
  materially sharper on the negative side, with many stage-name candidates now explicitly ruled out
  as false positives or current-musician mismatches rather than left as live possibilities. The
  broader recovery workflow has now also been stress-tested to a real stopping point: the
  `any-current` recovery shortlist is fully audited and no longer contains open cases, leaving
  only `6` unresolved identity-heavy names after a small follow-up pass ruled out `Domjan Laszlo`,
  `Eliud Tamez`, and `Q_Snc` as supportable death events rather than a broad hidden obituary
  frontier. The
  branch therefore now looks genuinely feasible as a bounded causal-audit project. But the preview
  panel still keeps the interpretation narrow: only `9` of the `20` verified deaths have a
  minimally usable short post window in the live `city x genre x year` panel, and `18` of the
  `20` are already post-emergence events. A first descriptive post-emergence summary now also
  exists and is mixed rather than dramatic: focal same-genre stocks keep rising in the short
  window, city-wide total band starts soften slightly, and city-wide spawning flow is roughly flat
  to slightly higher. A first matched-control prototype now sharpens that read further. With `3`
  same-genre controls per treated event, the average DID-style change in focal same-genre band
  starts is `-0.932`, with `6` of `9` event-level deltas negative, while city-wide spawning flow
  does not show the same negative matched pattern. The branch now also has a first stacked
  fixed-effects prototype on top of that matched sample. In the event-weighted stack, the
  treated-by-post coefficient for focal same-genre band starts is `-0.932`, and collapsing the
  one duplicate `city x genre x year` shock leaves it at `-0.993`. The short event-study path is
  also suggestive in the same narrow direction: the largest drop is in the event year itself
  (`t = -2.333` relative to `t-1`), while focal multi-band depth and city-wide spawning do not
  show the same negative treated-by-post pattern. So the branch still does not look like a
  plausible causal design for scene emergence itself. If it survives, it now looks most plausible
  as a post-emergence design for focal same-genre entry rather than for broad scene collapse.
  A new causal-channel reassessment in `notes/31_causal_channel_reassessment.md` now ranks
  experienced outside-musician arrivals as the best new follow-on causal audit. A quick scan of the
  member-edge data finds `3,763` cross-city experienced-arrival `city x genre x year` cells within
  five years before observed emergence, and `479` under the stricter cross-country definition.
  That makes the arrival channel much richer than the verified-death design while staying closer
  to the paper's recombination mechanism than the breakout-demand branch. The memo's rule is still
  conservative: this is a follow-on audit, not a reason to reopen the stabilized main draft unless
  the first arrival event-study has credible pre-trends and is not mechanically counting the
  arriving musician's own band.
  The first operational arrival pass now exists in `notes/32_external_arrival_first_pass.md` and
  scripts `code/83_build_external_arrival_event_study.py` and
  `code/84_build_external_arrival_matched_control.py`. The event build recovers `55,183`
  cell-level first-arrival events across four definitions. In the strict `cross_country_same_genre`
  analysis sample, there are `212` subthreshold pre-emergence events, and raw local same-genre
  starts rise from `0.234` in years `-3` to `-1` to `0.500` in years `+1` to `+3`. A stricter
  same-country matched-control pass recovers matched controls for `184` events. The treated
  change is `0.199`, the matched-control change is `0.100`, and the DID-style difference is
  `0.099`, but only `48.9` percent of event-level DID changes are positive. The branch is
  therefore alive and substantially more feasible than deaths, but the first controlled read is
  suggestive rather than decisive. The final audit in
  `code/85_build_external_arrival_final_audit.py` now also runs on the restored data. It excludes
  the arriving musician's own band from treated outcomes and computes a matched event-study with
  `t-1` as the baseline. In the strict matched stack, it keeps `184` treated events, removes `97`
  arrival-associated event-year bands, and leaves the mean own-band-excluded normalized post
  coefficient over `t=+1` to `t=+3` at `0.130`; the mean normalized pre coefficient over `t=-5`
  to `t=-2` is `0.016`. That is the best live causal follow-on read, but it still needs country
  and genre concentration checks before it can be treated as more than a sidecar.
  The empirical-motivation section has now also been tightened without changing the figure set.
  The long subgenre-by-subgenre walk-through has been cut back so the section now reads more like
  setup for the panel result and less like a second paper on genre taxonomy.
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
      - `CÃ³rdoba` black metal
      - `Nagoya` grindcore
    - weak-on-topology or weak-on-lead cases:
      - `Girona` black metal
      - `Patras` black metal
      - `Manchester` brutal death metal
  - practical implication:
    - the broad-city audit keeps the scene branch alive, but not yet as the headline design
    - the branch now looks strongest as a bounded mechanism or descriptive fork unless the mixed
      cases survive deeper historical validation
- Locked the branch decision explicitly and returned the critical path to the domestic-success
  redesign:
  - added:
    - `data/processed/scene_networks/scene_branch_decision_memo.md`
    - `code/14_build_domestic_success_cleanup_priority.py`
  - current domestic cleanup outputs:
    - `data/processed/country_genre_analysis/domestic_success_cleanup_priority.csv`
    - `data/processed/country_genre_analysis/domestic_success_cleanup_priority.md`
    - `data/processed/country_genre_analysis/domestic_success_pilot_cases_shock_clean.csv`
  - current cleanup read:
    - `keep_in_shock_clean`: `2`
    - `provisional_keep_in_shock_clean`: `1`
    - `replace_or_redate_before_use`: `3`
    - `drop_from_shock_baseline`: `4`
    - shock-clean keep set:
      - `Rammstein`
      - `Nightwish`
      - provisional `Sepultura`
  - practical implication:
    - the mature-scene and deep-complements rows should stay in the project only as scene evidence
      or contrast cases, not as the domestic-shock baseline
- Generalized the domestic-success rerun scripts so they can estimate alternative case files
  without forking the workflow:
  - `code/11_build_domestic_success_pilot_event_pass.py` now accepts:
    - `--pilot-cases-file`
    - `--output-token`
  - `code/12_estimate_domestic_success_pilot_fe.py` now accepts:
    - `--pilot-cases-file`
    - `--output-token`
  - current shock-clean rerun outputs:
    - `data/processed/country_genre_analysis/domestic_success_pilot_case_years_shock_clean.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_event_windows_shock_clean.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_event_study_shock_clean.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_event_pass_summary_shock_clean.md`
    - `data/processed/country_genre_analysis/domestic_success_pilot_fe_static_shock_clean.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_fe_event_study_shock_clean.csv`
    - `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary_shock_clean.md`
  - current shock-clean read:
    - descriptive event pass:
      - `2` of `3` cases improve on the all-band share-gap margin
      - pooled all-band share gap rises from about `0.1` percentage points pre-period mean to
        about `1.5` post-period mean
    - FE pass:
      - full `3`-case static coefficient on all starts:
        about `+2.8` with clustered SE `5.7`
      - strict `2`-case `source_a + tier_1` static coefficient on all starts:
        about `-4.3` with clustered SE `2.0`
  - practical implication:
    - pruning clearly weak rows helps, but the positive read still depends on the provisional
      Brazil `Sepultura` row
    - the next domestic-success move is to add earlier source-`A` keep candidates, not to treat
      the current tiny subset as persuasive on its own
- Built the first actual scene-cluster regression and reopened the scene branch on a stronger
  empirical design:
  - added `code/30_estimate_scene_cluster_regression.py`
  - wrote:
    - `data/processed/scene_networks/scene_cluster_regression_results.csv`
    - `data/processed/scene_networks/scene_cluster_regression_summary.md`
  - current regression read:
    - seeded `5`-year forecast LPM:
      - `N = 174,416`
      - positive windows: `23,519`
      - `z_log_active_bands = 0.1205`
      - `z_density = 0.0064`
      - `z_modularity_q = 0.0125`
      - `z_bridge_pct = -0.0086`
    - seeded exact-year fixed-effects panel:
      - `N = 180,498`
      - emergence events: `5,422`
      - `z_roll3_n_nontrivial_communities = 0.0116`
      - `z_roll3_log_active_bands = 0.0669`
      - bridge share, density, and modularity are weak once `city-genre` and year effects are
        absorbed
  - practical implication:
    - the old `community_precedes_label` threshold remains too fragile to be the main estimand
    - but the scene branch now has a credible regression-based cluster design
    - the most promising scene story is local thickness plus organizational variety, not a
      bridge-musician headline
    - the next workflow should build robustness and richer cluster measures around this regression
      design rather than return immediately to the domestic-success file
- Built the first robustness pass around the scene-cluster regression:
  - `code/30_estimate_scene_cluster_regression.py` now estimates:
    - seeded forecast horizons of `3`, `5`, `7`, and `10` years
    - seeded exact-year fixed-effects panels with `roll-3` and `roll-5` smoothing
  - current robustness read:
    - forecast horizons:
      - scene size stays positive and grows with the horizon:
        `0.0787`, `0.1205`, `0.1552`, `0.1945`
      - density stays positive:
        `0.0039`, `0.0064`, `0.0086`, `0.0090`
      - modularity stays positive:
        `0.0093`, `0.0125`, `0.0121`, `0.0092`
      - bridge share stays negative:
        `-0.0032`, `-0.0086`, `-0.0136`, `-0.0193`
    - exact-year FE:
      - `roll-3`:
        - `z_roll3_n_nontrivial_communities = 0.0116`
        - `z_roll3_log_active_bands = 0.0669`
      - `roll-5`:
        - `z_roll5_n_nontrivial_communities = 0.0096`
        - `z_roll5_log_active_bands = 0.0664`
      - bridge share stays null in both FE windows
  - practical implication:
    - the scene-cluster result now survives a first medium-run robustness pass
    - the stable mechanism is thickness plus organizational variety, not bridging
    - the next high-value move is to add richer cluster variables rather than spend more time on
      the old threshold count
- Built the first role, switcher, and signed-proxy extension pass for the scene branch:
  - added `code/31_probe_scene_role_switcher_extensions.py`
  - wrote:
    - `data/processed/scene_networks/city_year_scene_role_switcher_features.csv`
    - `data/processed/scene_networks/scene_role_switcher_critical_mass.csv`
    - `data/processed/scene_networks/scene_role_switcher_extension_results.csv`
    - `data/processed/scene_networks/scene_role_switcher_extension_summary.md`
  - current extension read:
    - descriptive critical mass:
      - exact-year emergence rate rises with active bands:
        - `<10`: `0.0145`
        - `10-19`: `0.0305`
        - `20-39`: `0.0341`
        - `40+`: `0.0398`
      - exact-year emergence rate also rises with multi-band musicians:
        - `0-1`: `0.0140`
        - `2-4`: `0.0242`
        - `5-9`: `0.0334`
        - `10+`: `0.0374`
    - exact-year FE extension:
      - `z_roll5_log_multi_band_musicians = 0.0087`
      - `z_roll5_multi_band_share = -0.0036`
      - current implication: absolute switcher mass matters more than switchers as a scene share
    - role composition:
      - strongest role-specific signal is guitar share among switchers
      - current coefficient: `-0.0013`
      - current p-value: `0.0621`
      - current implication: no positive guitarist-creativity headline yet; if anything the first
        sign is weakly negative
    - signed/unsigned proxy:
      - `z_roll5_unsigned_band_share_current_proxy = -0.0024`
      - current p-value: `0.0123`
      - current implication: unsigned-heavy scenes look less emergence-prone on this proxy, but the
        measure is based on current label status rather than historical contracts
  - practical implication:
    - critical mass is now more than a metaphor; it shows up clearly in descriptive rates
    - the best next mechanism move is not another generic switcher variable, but richer and more
      genre-targeted cluster measures
    - signed-versus-unsigned remains too historically noisy to treat as a core scene mechanism yet
- Built the richer scene-cluster extension pass around spawning, pedigree, and target-genre labor
  pools:
  - added `code/32_build_scene_cluster_richer_extensions.py`
  - wrote:
    - `data/processed/scene_networks/city_year_scene_cluster_richer_features.csv`
    - `data/processed/scene_networks/city_genre_scene_cluster_richer_features.csv`
    - `data/processed/scene_networks/scene_cluster_richer_extension_results.csv`
    - `data/processed/scene_networks/scene_cluster_richer_extension_summary.md`
  - current richer extension read:
    - descriptive scale:
      - city-year rows with any observed formation flow: `24,861`
      - mean spawn share among nonzero-formation city-years: `0.384`
      - mean founder pedigree among nonzero-formation city-years: `0.293`
      - target-genre rows written: `438,922`
      - mean active bands within a target genre-cell: `2.250`
      - mean broker-musician share within active target genre-cells: `0.403`
    - exact-year FE with spawning and founder pedigree:
      - `z_roll5_log_spawn_bands_formed = 0.0189`
      - `z_roll5_spawn_share_formed = -0.0059`
      - `z_roll5_founder_pedigree_mean = -0.0016` with `p = 0.2246`
    - exact-year FE with target-genre labor pools:
      - `z_roll5_log_genre_active_bands = 0.1642`
      - `z_roll5_log_genre_active_musicians = -0.1128`
    - exact-year FE with target-genre broker musicians:
      - `z_roll5_log_genre_broker_musicians = 0.0665`
      - `z_roll5_genre_broker_share = -0.0815`
    - exact-year FE with target-genre switcher depth:
      - `z_roll5_log_genre_multi_band_musicians = 0.0440`
      - `z_roll5_genre_multi_band_share = -0.0280`
    - role-targeted labor pools:
      - strongest role coefficient is guitar:
        `z_roll5_log_genre_active_guitar_musicians = -0.0360`
      - keyboards are weakest:
        `z_roll5_log_genre_active_keyboards_musicians = -0.0018`, `p = 0.1888`
  - practical implication:
    - the scene branch now speaks directly to spinouts, target-genre labor pools, and local
      broker stock rather than only whole-city thickness
    - the stronger recurring result is in absolute counts, not compositional shares
    - founder pedigree is currently too weak to carry a main mechanism claim on its own
- Built the compact stress-test pass for the richer scene-cluster branch:
  - added `code/33_stress_test_scene_cluster_richer_specs.py`
  - wrote:
    - `data/processed/scene_networks/scene_cluster_richer_stress_test_results.csv`
    - `data/processed/scene_networks/scene_cluster_richer_stress_test_summary.md`
  - current compact stress-test read:
    - counts-only exact-year FE:
      - spawning flow stays positive under both windows:
        - `roll-3`: `0.0088`
        - `roll-5`: `0.0133`
      - target-genre active bands stay strongly positive:
        - `roll-3`: `0.0480`
        - `roll-5`: `0.0534`
      - target-genre multi-band musicians stay positive:
        - `roll-3`: `0.0220`
        - `roll-5`: `0.0225`
      - target-genre broker musicians are slightly negative in counts-only tables:
        - `roll-3`: `-0.0033`
        - `roll-5`: `-0.0053`
    - counts-plus-shares exact-year FE:
      - negative share terms survive under both windows:
        - `roll-5` spawn share: `-0.0066`
        - `roll-5` broker share: `-0.0724`
        - `roll-5` multi-band share: `-0.0195`
      - the corresponding count terms remain positive:
        - `roll-5` spawning flow: `0.0224`
        - `roll-5` target-genre active bands: `0.0488`
        - `roll-5` target-genre broker musicians: `0.0579`
        - `roll-5` target-genre multi-band musicians: `0.0331`
      - practical read:
        - the broker-count term flips from slightly negative to strongly positive once broker share
          is held fixed
    - removing the overall switcher control barely changes the target-genre switcher term:
      - `roll-5` coefficient moves only from `0.0225` to `0.0216`
  - practical implication:
    - the count-versus-share split survives a shorter lag window and a compact table
    - the cleanest stable scene mechanisms are now spawning flow, target-genre active band stock,
      and target-genre switcher depth
    - broker musicians remain live, but the sign now has to be interpreted as count conditional on
      broker concentration rather than as a generic unconditional stock story
- Built the preferred scene-mechanism table and selection memo:
  - added `code/34_build_scene_preferred_mechanism_table.py`
  - wrote:
    - `data/processed/scene_networks/scene_cluster_preferred_mechanism_table.csv`
    - `data/processed/scene_networks/scene_cluster_preferred_mechanism_table.md`
  - chosen presentation:
    - paired `roll-5` exact-year FE table
    - Panel A:
      counts-only core with overall scene controls plus:
      - local spawning flow
      - target-genre active bands
      - target-genre multi-band musicians
    - Panel B:
      composition extension adding:
      - spawn share
      - target-genre broker musicians
      - target-genre broker share
      - target-genre multi-band share
  - current preferred-table read:
    - Panel A core coefficients:
      - local spawning flow: `0.0134`
      - target-genre active bands: `0.0505`
      - target-genre multi-band musicians: `0.0227`
    - Panel B composition coefficients:
      - local spawning flow: `0.0224`
      - spawn share: `-0.0066`
      - target-genre active bands: `0.0488`
      - target-genre broker musicians: `0.0579`
      - target-genre broker share: `-0.0724`
      - target-genre multi-band musicians: `0.0331`
      - target-genre multi-band share: `-0.0195`
    - robustness built into the selection memo:
      - target-genre multi-band musician depth remains:
        - `0.0221` under `roll-3`
        - `0.0217` when the overall switcher control is removed
      - broker count is omitted from Panel A because its counts-only reference coefficient is
        `-0.0053`
  - practical implication:
    - the headline scene result is now no longer an open table-design question
    - the paper can headline spawning flow, target-genre active band stock, and target-genre
      switcher depth as the stable unconditional margins
    - broker musicians belong in the adjacent composition panel, not the unconditional headline
- Built the first paper-facing scene figure package and wrote the audit notes:
  - added `code/35_build_scene_presentation_figures.py`
  - wrote:
    - `data/processed/scene_networks/scene_figure_roadmap.md`
    - `data/processed/scene_networks/scene_presentation_figures_summary.md`
    - `data/processed/scene_networks/figures/scene_critical_mass_event_rates.png`
    - `data/processed/scene_networks/figures/scene_preferred_mechanism_coefficients.png`
  - also documented the scene pipeline and measurement layer in:
    - `data/processed/scene_networks/scene_data_cleaning_audit.md`
    - `data/processed/scene_networks/scene_variable_measurement_audit.md`
  - current figure-package read:
    - the recommended scene sequence is now:
      - a global metal-expansion opener if needed
      - the scene critical-mass figure
      - the preferred paired mechanism coefficient figure
      - then an optional broker companion or case-study network figure
    - the critical-mass figure makes the descriptive scene pattern visually obvious:
      - emergence rises from `1.4%` to `4.0%` across active-band bins
      - emergence rises from `1.4%` to `3.7%` across multi-band-musician bins
    - the preferred coefficient plot turns the locked table into a paper object:
      - Panel A headlines spawning flow, target-genre active bands, and target-genre multi-band
        depth
      - Panel B keeps the negative share terms visible while treating broker musicians as a
        conditional composition result
  - practical implication:
    - the branch has now moved from tables-only exploration into a real draftable figure package
    - the next task is to write the scene memo and appendix objects around these figures, not to
      keep inventing new generic scene measures
- Started the markdown-first paper draft for the scene branch:
  - added `notes/06_scene_paper_skeleton.md`
  - current draft object includes:
    - title options
    - abstract skeleton
    - section order
    - figure placement
    - appendix plan
    - writing rules about what to claim and what not to claim
  - current draft logic:
    - Figure 1 is optional orientation material
    - Figure 2 is the critical-mass scene fact
    - Figure 3 is the paired preferred mechanism result
    - theory is compact and comes after the empirical facts, not before them
  - practical implication:
    - the project now has a real paper architecture in markdown
    - LaTeX and PDF work should wait until this markdown draft becomes a stable prose memo
- Expanded the scene paper draft into a prose memo:
  - added `notes/07_scene_paper_memo.md`
  - the memo now contains:
    - a paper-level opening argument
    - the reduced-form design language
    - the current headline empirical result
    - the mechanism interpretation
    - the main-text figure order
  - current prose rule:
    - no causal claims
    - `cross-genre connectors` in paper language
    - theory stays compact and downstream of the reduced-form evidence
  - practical implication:
    - the project now has a usable markdown memo rather than only an outline
    - the next writing move is to expand Introduction, Data, and Results into section-ready prose
- Expanded the scene draft again into section-ready paper text:
  - added `notes/08_scene_paper_sections.md`
  - current section draft now contains:
    - a full Introduction
    - a full Data and Measurement section
    - a full Results section with descriptive and reduced-form subsections
  - current paper logic in prose:
    - the paper is about scene formation rather than retrospective label history
    - the first core figure is the critical-mass scene figure
    - the second core figure is the preferred paired mechanism figure
    - the clean headline remains spawning flow, target-genre active bands, and target-genre
      multi-band depth
  - practical implication:
    - the project now has section-ready markdown text that could be ported into LaTeX later
    - the next move is appendix construction or one additional supporting figure, not a fresh
      rewrite of the empirical spine
- Converted the audit notes into appendix-ready paper objects:
  - wrote:
    - `data/processed/scene_networks/scene_appendix_sample_construction.md`
    - `data/processed/scene_networks/scene_appendix_sample_construction.csv`
    - `data/processed/scene_networks/scene_appendix_variable_crosswalk.md`
    - `data/processed/scene_networks/scene_appendix_variable_crosswalk.csv`
  - current appendix package now covers:
    - sample construction from raw Metallum bands and member rows to the preferred exact-year FE
      sample of `171,653` city-genre-years and `5,306` emergence events
    - paper-facing definitions for the preferred outcome and mechanism variables
    - caption-ready text for later LaTeX transfer
  - practical implication:
    - the paper package now has main-text section prose plus appendix-ready support objects
    - the remaining paper-design choice is the final supporting figure, not missing appendix
      infrastructure
- Dropped broker from the active paper package:
  - rebuilt `data/processed/scene_networks/figures/scene_preferred_mechanism_coefficients.png`
    as a single-panel headline figure using only the preferred core exact-year FE specification
  - updated the live paper-facing files so that:
    - broker or connector variables are background analysis, not a main-text paper object
    - the core headline is now only:
      - local spawning flow
      - target-genre active bands
      - target-genre multi-band musicians
    - the remaining main-text figure choice is now only the case-study network figure
  - practical implication:
    - the paper is cleaner and narrower
    - the next figure decision is no longer broker versus case-study; it is which case-study to use
- Built the first band-success sidecar pilot:
  - added `code/38_build_band_success_sidecar_data.py`
  - wrote:
    - `data/processed/band_success/band_birth_panel.csv`
    - `data/processed/band_success/band_scene_at_birth_panel.csv`
    - `data/processed/band_success/band_success_outcomes.csv`
    - `data/processed/band_success/band_success_match_diagnostics.csv`
    - `data/processed/band_success/band_success_descriptive_pilot.csv`
    - `data/processed/band_success/band_success_sidecar_summary.md`
  - current pilot read:
    - birth-panel rows: `128,053`
    - exact pre-birth scene matches at `formed_year - 1`: `67,572`
    - curated home-market success artists after conservative alias or homonym screen: `11`
    - matched birth-panel success cases:
      - `presence`: `10`
      - `certification`: `5`
      - `top10`: `4`
    - conservative audit already required:
      - `Rhapsody` mapped to `Rhapsody of Fire`
      - obvious homonym collisions `Disturbed` and `Slipknot` excluded
      - `Rammstein` remains unmatched under current Metallum coverage
  - practical implication:
    - the workflow is real enough to keep
    - the current outcome file is too thin to justify a serious band-level regression yet
- Reframed the band-success sidecar as an upgrading-ladder workflow:
  - added `code/47_build_band_upgrading_ladder_sidecar.py`
  - added `notes/11_band_upgrading_ladder.md`
  - wrote:
    - `data/processed/band_success/band_upgrading_ladder_outcomes.csv`
    - `data/processed/band_success/city_genre_birth_cohort_upgrading_panel.csv`
    - `data/processed/band_success/city_genre_birth_cohort_upgrading_pilot.csv`
    - `data/processed/band_success/band_upgrading_ladder_summary.md`
  - current sidecar read:
    - matched bands by stage:
      - `16` home-market presence
      - `13` home-market validation
      - `12` foreign-market presence
      - `5` validated-then-foreign
    - audited cohort file:
      - `57,756` `city x genre_family x formed_year` rows
      - `5` home-market validated winner cohorts within `15` years
      - `3` validated-then-foreign cohorts within `20` years
  - practical implication:
    - this is a better sidecar question than `ever successful band`
    - but it is still too sparse to justify a serious regression branch yet
- Built the first scene-diffusion prototype:
  - added `code/48_build_scene_diffusion_map.py`
  - added `notes/12_scene_diffusion_workflow.md`
  - wrote:
    - `data/processed/scene_networks/diffusion/black_metal_city_coordinates.csv`
    - `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_panel.csv`
    - `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_map.html`
    - `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_summary.md`
  - current descriptive read:
    - matched city coverage in the geography-clean emerged-city subset:
      - `895` of `977` cities (`91.6%`)
    - matched yearly active city observations:
      - `14,694`
    - by `1995`, the matched panel already shows `391` active cities and `65` cumulative emerged
      local scenes
    - by `2010`, it shows `633` active cities and `633` cumulative emerged scenes
  - practical implication:
    - this looks like a real scene-to-scene diffusion branch rather than a one-birthplace story
    - the next step, if revisited, should be a distance-weighted exposure panel rather than map
      styling
- Built the first serious scene-diffusion exposure panel:
  - added `code/50_build_scene_diffusion_exposure_panel.py`
  - added `notes/14_scene_diffusion_exposure_panel.md`
  - wrote:
    - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_panel.csv`
    - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_results.csv`
    - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_bins.csv`
    - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_summary.md`
  - current black-metal read:
    - matched city cells in genre:
      - `4,281`
    - at-risk city-year observations:
      - `11,503`
    - emergence events in at-risk sample:
      - `894`
    - exposure bins:
      - emergence rate rises from `0.0626` in the lowest hub-band exposure quintile to `0.0874`
        in the highest
    - first reduced-form pass:
      - lagged local same-genre band stock is strongly positive (`0.1290`)
      - lagged external hub exposure is positive on its own (`0.0068` for hub count,
        `0.0062` for hub active-band exposure)
      - but the external exposure terms wash out once lagged local band stock is included
  - practical implication:
    - diffusion looks real descriptively
    - but in this first black-metal pass it does not displace local thickness as the core result
- Built the first Gephi-ready large-scene export:
  - added `code/39_export_gephi_city_genre_network.py`
  - wrote:
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_nodes.csv`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_edges.csv`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_gephi_recipe.md`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_summary.md`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_nodes.csv`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_edges.csv`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_gephi_recipe.md`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_summary.md`
  - current export read:
    - `Helsinki, Finland / death_metal / 2005`:
      - active musicians: `105`
      - collaboration edges: `163`
      - multi-band connectors: `5`
    - `Helsinki, Finland / black_metal / 2010`:
      - active musicians: `79`
      - collaboration edges: `159`
      - repeated ties: `8`
      - multi-band connectors: `13`
    - Gephi now installed on `D:`:
      - `D:\apps\gephi\bin\gephi64.exe`
  - practical implication:
    - the old Pittsburgh microcase is still useful as a readable pre-emergence toy case
    - but if the paper wants a visually impressive force-directed local network map, a large
      city-genre case like Helsinki is the better object
    - the black-metal export may be the stronger visual because it has more connector structure
      relative to its size
- Built the first static thick-scene preview package and connector-core trims:
  - added `code/40_build_gephi_preview_graphs.py`
  - wrote:
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_preview.png`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_connector_core_preview.png`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_preview.png`
    - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_connector_core_preview.png`
    - `data/processed/scene_networks/gephi_exports/helsinki_gephi_preview_comparison.md`
  - current preview read:
    - the full-scene maps are useful diagnostics but too fragmented for the paper because city-year
      collaboration maps contain many disconnected band cliques
    - connector-core trims read much better because they keep only components with multi-band
      bridges
    - `Helsinki / black_metal / 2010` is now the preferred thick-scene figure:
      - `53` musicians
      - `146` edges
      - `8` repeated ties
      - `13` connectors
      - `6` connected components
    - `Helsinki / death_metal / 2005` is now the contrast case for scene scale without much
      overlap:
      - `20` musicians
      - `34` edges
      - `5` connectors
      - `4` connected components

## In Progress

- Advancing the main paper draft around the locked three-variable scene result:
  - `notes/08_scene_paper_sections.md` is now the live fuller markdown draft with abstract,
    introduction, data and measurement, results, and conclusion
  - the immediate writing goal is now a referee-driven revision pass rather than generic draft
    polishing
- Running the revision sequence from the internal AER-style report:
  - active plan file: `referee/aer_revision_plan.md`
  - working default target: strong field-journal paper unless a much stronger identification
    strategy appears
- The paper front end has now been rewritten into a real introduction-led draft:
  - added `drafts/sections/introduction.tex`
  - `drafts/metal.tex` now opens with `Introduction`, then `Related literature`
  - the abstract has been tightened to the narrower reduced-form paper
- The threshold-objection response package has now been built and integrated into the draft:
  - added `code/70_build_scene_threshold_response.py`
  - wrote `scene_threshold_response_results.csv`
  - wrote `scene_threshold_response_summary.md`
  - added appendix tables for threshold robustness and focal labor-pool specificity
  - updated the abstract, introduction, results section, and appendix text to match the narrower
    post-response interpretation
- The measurement-validation package has now been built and integrated into the draft:
  - added `code/71_build_scene_measurement_validation.py`
  - wrote:
    - `scene_measurement_validation_results.csv`
    - `scene_historical_sanity_cases.csv`
    - `scene_measurement_validation_summary.md`
  - added appendix tables for geography robustness and historical sanity cases
  - updated the data, results, and appendix sections to match the new validation material
- The digital and broadband branch has now been pushed out of the main paper narrative:
  - the main results section now keeps only a short secondary note on the period split
  - the broader internet-adoption and city-broadband probes now sit in an appendix prose
    subsection rather than occupying main-text space
  - practical implication:
    - the paper is now more clearly organized around:
      - descriptive critical mass
      - the preferred exact-year scene result
      - threshold and measurement validation
- The main-table interpretation and presentation pass is now also done:
  - the method section now states explicitly that the lagged predictors are z-scored, so the
    coefficients are directly comparable
  - the preferred table notes now explain that the coefficients are within-sample percentage-point
    changes in emergence probability from a one-standard-deviation increase in the lagged
    predictor
  - the results section now translates the three headline coefficients into percentage-point terms
    relative to the `3.09` percent event rate and explains the negative overall multi-band control
    as a conditional niche-specificity result
- A third internal referee-style report now exists:
  - `referee/aer_referee_report_round3.md`
  - current read:
    - still reject at AER standard
    - but the paper is now judged much closer to strong field-journal fit
    - the next tightening targets are:
      - claim discipline
      - possible compression of the role-composition paragraph
      - one more front-end polish pass if needed
- The front-end polish pass is now also done:
  - the abstract now leads with local scene emergence in heavy metal rather than a broader
    category-creation question
  - the introduction now states the paper's bounded contribution more directly and treats the field
    setting as a useful laboratory rather than as a route to inflated generality
  - practical implication:
    - the next revision should be compressive rather than architectural
- The literature review compression pass is now also done:
  - `drafts/sections/literature_review.tex` now keeps the same citation spine with fewer
    explanatory detours
  - practical implication:
    - the middle of the paper now better matches the discipline of the front end and results
- A clean field-journal positioning memo now exists:
  - `referee/field_journal_positioning_memo.md`
  - practical implication:
    - the project now has a stable target statement for the next draft stage that does not depend
      on comparison to the AER bar
- Keeping the appendix support objects aligned with the main draft:
  - `scene_appendix_sample_construction.md`
  - `scene_appendix_variable_crosswalk.md`
  - the corresponding LaTeX appendix objects now exist inside `drafts/`
- Holding the scene-to-band-success branch as an active sidecar rather than a main-paper branch:
  - the active sidecar note is now `notes/11_band_upgrading_ladder.md`
  - the next sidecar task is to lock one bounded cohort-winner outcome before any regression
  - do not force a naive full-sample birth regression from the current long-gap matched cases
- Holding the network figure and domestic-success branches in reserve:
  - the network figure stays parked until there is a better direct-control workflow
  - the scene-diffusion branch is exploratory and descriptive for now
  - the `shock_clean` domestic-success workflow remains a fallback if the scene paper weakens

## Next 3 Tasks

1. Run leave-country-out and leave-genre-out sensitivity checks on
   `external_arrival_final_audit_event_study.csv`.
2. Manually inspect the largest positive and negative strict arrival events to separate plausible
   local arrivals from database artifacts.
3. Decide whether the arrival branch remains a parked sidecar or becomes a separate follow-on
   paper object; do not reopen the stabilized main draft unless the sensitivity checks hold up.

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
  - locked:
    the baseline paper should read as economics of collaborative innovation in a project-based
    creative industry using membership networks and genre emergence timing
  - active sidecar:
    test whether the same scene conditions also predict later successful bands
  - keep `domestic breakthrough as shock` only as the fallback contrast design

## References

- Project overview: `research_ideas/metal/README.md`
- Memory: `research_ideas/metal/memory.md`
- Notes index: `research_ideas/metal/notes/README.md`
