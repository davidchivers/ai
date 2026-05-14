# Project memory - Metal

Most recent session first.

---

### Session: 2026-05-13 (member dump restored and external-arrival final audit rerun)
- Found the two missing delivered archives in local downloads/Outlook attachment cache:
  - `band_members_20260325.zip`
  - `bands_and_first_releases.zip`
- Moved both archives to the D-drive project raw-data target:
  - `D:\AI_data\research_ideas\metal\raw`
  - Known C-drive copies in Downloads and Outlook attachment cache were removed after the D copies
    were verified.
- Reingested the restored member dump:
  - raw member-role rows: `1,038,533`
  - unique member-band edges: `971,877`
  - matched bands: `156,729`
  - unmatched bands: `29,469`
- Rebuilt the scene-network inputs needed by the external-arrival branch:
  - `city_year_network_snapshots.csv`
  - `community_vs_label_timing.csv`
  - `city_year_scene_cluster_richer_features.csv`
  - `city_genre_scene_cluster_richer_features.csv`
- Reran the external-arrival workflow:
  - `code/83_build_external_arrival_event_study.py`
  - `code/84_build_external_arrival_matched_control.py`
  - `code/85_build_external_arrival_final_audit.py`
- Final-audit read:
  - strict matched treated stacks: `184`
  - event-window rows: `10,604`
  - arrival-associated bands removed at event year: `97`
  - mean normalized pre coefficient, `t=-5` to `t=-2`: `0.016`
  - event-year normalized coefficient, `t=0`: `0.011`
  - mean normalized post coefficient, `t=+1` to `t=+3`: `0.130`
- Practical implication:
  - the data are no longer missing for the arrival branch.
  - the own-band-excluded result is positive and the pre-period path is not obviously rising, so
    this remains the best live causal follow-on candidate.
  - it is still not ready for the stabilized main paper; the next gate is leave-country-out,
    leave-genre-out, and manual inspection of the largest event-level positives and negatives.

---

### Session: 2026-05-13 (data-loss forensics and partial rebuild)
- Located the likely loss mechanism for the missing metal raw/processed data.
  - The raw and processed project folders are junction targets on `D:\AI_data\research_ideas\metal`.
  - Archived logs show `data/raw/band_members_20260325.zip`,
    `data/processed/metal_archives_all_metal_band_clean.csv`, and
    `data/processed/scene_networks/full_musician_band_edges.csv` still existed on `2026-04-24`.
  - On `2026-04-30 10:11:41-10:11:51` local time, a cleanup session recursively removed
    `C:\Users\Dave_\AI\.claude\worktrees`; that root included
    `C:\Users\Dave_\AI\.claude\worktrees\research_ideas_metal` on branch `research_ideas/metal`.
  - The real `D:` target folders `raw` and `processed` have `LastWriteTime =
    2026-04-30 10:11:51`, the same second the cleanup completed.
  - Inference: the recursive worktree deletion followed the project data junctions and emptied the
    real `D:` raw/processed targets.
- Recovery checks did not find a restorable member dump or processed scene-network copy.
  - Searched local `C:`/`D:`, local Dropbox/OneDrive folders, Git history/LFS/object history,
    Dropbox active/deleted search, Google Drive search, and both recycle bins.
  - Windows shadow-copy listing required elevation, and Gmail search was blocked by insufficient
    OAuth scope.
- Rebuilt the parts that are reproducible from existing local sources.
  - Restored the expected pointer from the learning-by-viewing raw DB path to the existing
    `D:\research_data\learning_by_viewing\music\strategy_8_music_pilot\raw\metal_archives`
    SQLite snapshot.
  - Reran `code/02_build_all_metal_outcome.py`:
    `163,965` snapshot rows, `161,945` matched countries, `130,108` matched-and-dated rows.
  - Reran `code/03_build_core_treatment_panel.py` and `code/04_build_band_influence_memo.py`.
  - Reran `code/05_analyze_genre_trends.py`, `code/06_build_country_genre_growth_panel.py`, and
    `code/22_build_genre_emergence.py`.
- At that point, unresolved before the later download-cache restore:
  - `data/raw/band_members_20260325.zip`
  - `data/processed/scene_networks/full_musician_band_edges.csv`
  - downstream scene-network, central-loss, and external-arrival outputs that depend on the member
    dump.
- Practical implication:
  - the main reduced-form paper's band census and treatment-side objects are back.
  - the external-arrival last attempt cannot be rerun faithfully until the member dump is restored
    or re-obtained; the old SQLite band snapshot does not contain member/lineup records.
  - Superseded later on `2026-05-13` by the successful download-cache restore recorded above.

---

### Session: 2026-05-13 (external-arrival last attempt scaffold)
- Reopened the experienced outside-musician arrival branch for one last bounded check.
- Confirmed the current machine still lacks the required processed inputs at the project D-drive
  junction targets:
  - `data/processed/metal_archives_all_metal_band_clean.csv`
  - `data/processed/scene_networks/external_arrival_events.csv`
  - `data/processed/scene_networks/external_arrival_matched_controls.csv`
- A broader targeted search across `D:\` and `C:\Users\Dave_` did not recover the raw member dump,
  the processed scene-network files, or the prior external-arrival outputs.
- Updated `code/83_build_external_arrival_event_study.py` so future event files preserve full
  pipe-delimited `arriving_band_ids`; the older event schema did not contain enough information to
  exclude arrival-associated bands from treated outcomes.
- Added `code/85_build_external_arrival_final_audit.py`.
  - It rebuilds band-level local starts.
  - It excludes the arriving musician's own band from treated event-window outcomes.
  - It computes a matched event-study using the existing strict matched-control sample and `t-1`
    as the baseline.
- Verification:
  - `python -m py_compile code\83_build_external_arrival_event_study.py code\84_build_external_arrival_matched_control.py code\85_build_external_arrival_final_audit.py`
    succeeded.
  - Running `code\85_build_external_arrival_final_audit.py` correctly stopped at the missing-input
    preflight check rather than producing a partial result.
- Practical implication:
  - the arrival branch remains feasible and suggestive on the April first-pass numbers, but it is
    not cleared for the main paper.
  - unless the processed data are restored, this causal follow-on should be parked with the deaths
    and breakout branches rather than used to reopen the stabilized field-paper draft.

---

### Session: 2026-04-13 (field-paper wording pass for the main draft)
- Updated:
  - `drafts/metal.tex`
  - `drafts/sections/introduction.tex`
  - `drafts/sections/empirical_motivation.tex`
  - `drafts/sections/method.tex`
  - `drafts/sections/results.tex`
- Writing pass:
  - tightened the paper's wording around the operational outcome rather than changing the evidence
  - the preferred exact-year specification now reads more explicitly as a within-cell transition
    equation on the risk set
  - the introduction and abstract now say more clearly that the paper studies transitions into
    operational scene status rather than a literal ontological birth date
  - the results section now states more directly that the dependent variable is crossing the
    operational fifth-band threshold in the current year
  - the role-composition paragraph is now shorter and more clearly backgrounded
- Verification:
  - `latexmk -pdf -interaction=nonstopmode -halt-on-error metal.tex` ran successfully in
    `drafts/`
  - `drafts/metal.pdf` rebuilt cleanly
- Current implication:
  - the draft is now better aligned with the field-journal positioning memo and the round-5
    referee advice
  - the next sensible step is a stop-or-stabilize read, not another additive expansion

---

### Session: 2026-04-10 (stacked FE prototype for the central-loss branch)
- Added:
  - `code/82_build_central_loss_stacked_spec.py`
  - `data/processed/scene_networks/central_loss_stacked_event_panel.csv`
  - `data/processed/scene_networks/central_loss_stacked_did_results.csv`
  - `data/processed/scene_networks/central_loss_stacked_event_study_results.csv`
  - `data/processed/scene_networks/figures/central_loss_stacked_event_study.png`
  - `data/processed/scene_networks/central_loss_stacked_spec_summary.md`
- Design:
  - stack the `9` usable post-emergence death events against their matched same-genre controls
  - estimate a parsimonious treated-by-post FE DID with `stack-city` and relative-year effects
  - estimate a short event study for focal same-genre band starts with `t-1` as the reference year
- Current read:
  - event-weighted focal same-genre treated-by-post coefficient: `-0.932`
  - unique-shock focal same-genre treated-by-post coefficient: `-0.993`
  - event-study coefficients for focal same-genre band starts:
    - `t-3 = -0.370`
    - `t-2 = -1.000`
    - `t = -2.333`
    - `t+1 = -0.444`
  - focal multi-band depth does not show a negative treated-by-post effect
  - city-wide spawning flow also does not show a negative treated-by-post effect
- Current implication:
  - the branch is now past pure audit mode and has a real estimation prototype
  - the narrow live estimand is now post-death suppression of focal same-genre entry
  - the branch still does not support a broad scene-collapse story or a scene-emergence design

---

### Session: 2026-04-10 (central-musician-loss first pass)
- Added:
  - `code/77_build_central_loss_audit_shortlist.py`
  - `code/78_build_central_loss_event_preview.py`
  - `notes/30_central_musician_loss_first_pass.md`
  - `data/processed/scene_networks/central_loss_candidate_cells.csv`
  - `data/processed/scene_networks/central_loss_audit_shortlist.csv`
  - `data/processed/scene_networks/central_loss_audit_summary.md`
  - `data/processed/scene_networks/central_loss_manual_audit_first_pass.csv`
  - `data/processed/scene_networks/central_loss_verified_death_events.csv`
  - `data/processed/scene_networks/central_loss_event_preview.csv`
  - `data/processed/scene_networks/central_loss_event_window_preview.csv`
  - `data/processed/scene_networks/central_loss_event_preview_summary.md`
- Updated:
  - `notes/README.md`
  - `notes/05_research_plan.md`
  - `STATUS.md`
- Current branch read:
  - the central-musician-loss idea is now a live feasibility object rather than only a design memo
  - the data can already rank plausible local connector losses using stable musician IDs, yearly
    membership spans, local same-genre overlap, and scene-size context
  - the refined first screen now yields `31` audit-ready rows after requiring:
    - fully observed terminal years
    - `3+` lifetime bands
    - `2+` local same-genre active bands at the terminal year
    - a local scene with at least `5` active same-genre bands
    - plus a capped fallback to the latest available scene snapshot within `2` years
  - the first web audit is more encouraging after that refinement:
    - clear or near-clear deaths recovered from within the shortlist:
      `Kory Alvarez`, `Miguel Angel`, `L-G Petrov`, `Jasmine You`, `Eric Wagner`,
      `Nattdal`, `Andre Matos`, `Mortifer`, `Geoff Nicholls`, `Reverend Jim Forrester`,
      `Evgeny Reutov`, and `Sergey Stankov`
    - clear false positives: `Moritz Bossmann`, `Aidan Smith`, `Ilya Zudilov`,
      `Luke Tolcher`, `N. Schner`, `Kriger Morket`, `Andrew Power`, `Tragisk`,
      and `Tommy Henriksen`
    - possible permanent exits rather than death shocks: `Capricornus` and `Ariersohn`
- Current implication:
  - the branch is alive and looks more plausible than at the start of the session
  - but it is still in audit mode rather than estimation mode because the shortlist remains noisy
  - the branch now has a clean first event file with `12` verified deaths
  - the first panel preview is more sobering:
    - only `5` verified deaths have a minimally usable short post window in the live panel
    - `11` of the `12` verified deaths are already post-emergence events
  - the next sensible move, if any, is no longer an emergence event study
  - instead, continue only if the branch is reframed around post-emergence scene activity margins
    such as same-genre starts, spawning, or local multi-band depth

---

### Session: 2026-04-10 (fifth AER-style referee report)
- Added:
  - `referee/aer_referee_report_round5.md`
- Current report read:
  - the recommendation remains reject at AER standard
  - the paper is now judged to be a strong and disciplined reduced-form field-paper draft
  - the decisive AER issue remains unchanged:
    - the preferred exact-year fixed-effects design identifies a robust within-cell transition
      pattern, not a causal account of scene formation
  - the recent narrowing and validation work are treated as genuine improvements, but not as outlet-
    changing improvements
- External cross-check:
  - an Oracle browser review was launched under slug `metal-aer-r5` as a second-model read
  - the browser session was still running when this session note was written, so the saved round-5
    report reflects the direct read rather than a completed Oracle output
- Current implication:
  - the paper now looks close to a stop-or-stabilize decision
  - if one more move is taken, it should likely be a field-journal-standard final read rather than
    another AER-oriented revision cycle

---

### Session: 2026-04-10 (empirical-motivation section compressed)
- Updated:
  - `drafts/sections/empirical_motivation.tex`
  - `STATUS.md`
  - `notes/05_research_plan.md`
- Current writing read:
  - the empirical-motivation section now keeps the same three figures but does less explanatory
    work
  - the long subgenre-by-subgenre walk-through is gone
  - the section now reads more clearly as setup for the city-genre panel and the threshold-crossing
    model rather than as a parallel paper on metal taxonomy or diffusion
- Verification:
  - `latexmk -pdf -interaction=nonstopmode -halt-on-error metal.tex` ran successfully in
    `drafts/`
  - `drafts/metal.pdf` rebuilt cleanly
- Current implication:
  - the draft is now closer to a stop-or-stabilize decision
  - if one more pass is wanted, it should be a final referee-style read rather than another
    additive expansion

---

### Session: 2026-04-09 (overnight workflow closeout; breakout branch parked)
- Added:
  - `notes/29_breakout_branch_parking_memo.md`
- Updated:
  - `notes/README.md`
  - `notes/05_research_plan.md`
  - `STATUS.md`
- Current workflow read:
  - the bounded recovery pass is now closed rather than left as an open-ended branch
  - `Comalies` remains an official FIMI dead end under the live workflow
  - Brazil timing is materially cleaner, but `Rebirth` and `Temple of Shadows` still do not
    become chart-entry events usable in the stacked first-breakout design
- Current implication:
  - the breakout-demand branch should remain parked at feasibility stage
  - active project time should return to the bounded field-journal paper unless one of the
    explicit re-entry conditions in `notes/29_breakout_branch_parking_memo.md` is met

---

### Session: 2026-04-09 (breakout event file created)
- Added:
  - `data/processed/country_genre_analysis/breakout_event_file.csv`
- Updated:
  - `notes/25_breakout_branch_workflow.md`
- Current branch read:
  - the branch now has a stable first-pass event file rather than only a screened candidate list
  - the retained event set contains `5` branch-ready breakout episodes:
    - `DEU x extreme_metal x 1996`
    - `GBR x extreme_metal x 1996`
    - `ITA x extreme_metal x 1996`
    - `DEU x industrial_metal x 2001`
    - `DEU x symphonic_metal x 2004`
- Current implication:
  - the next branch object is now the stacked `city x genre_family x relative_event_year` panel
    built from this event file

---

### Session: 2026-04-09 (breakout branch workflow note added)
- Added:
  - `notes/25_breakout_branch_workflow.md`
- Updated:
  - `notes/README.md`
- Current branch read:
  - the breakout branch now has an explicit phase order rather than only a design note and a
    screened candidate list
  - the next required branch objects are:
    - `breakout_event_file.csv`
    - `city_genre_breakout_event_panel.csv`
- Current implication:
  - the branch can now be worked through in bounded steps without drifting into general treatment
    expansion

---

### Session: 2026-04-09 (breakout branch candidate screen added)
- Added:
  - `data/processed/country_genre_analysis/breakout_episode_candidates.csv`
  - `notes/24_breakout_episode_screen.md`
- Updated:
  - `notes/README.md`
- Current branch read:
  - the breakout-demand idea now has a first screened event set rather than only a design memo
  - the strongest first-pass market is `DEU`, followed by `GBR` and `ITA`
  - most `heavy_metal` rows are intentionally excluded from the first branch because they are too
    mature to read cleanly as genre-breakout events
- Current implication:
  - the next branch task is to convert the screened candidates into a clean breakout-episode file
    and merge it onto the city-genre scene panel for a stacked event-study pass

---

### Session: 2026-04-09 (breakout-demand shock design memo added)
- Added:
  - `notes/23_breakout_demand_shock_design.md`
- Updated:
  - `notes/README.md`
  - `notes/05_research_plan.md`
  - `STATUS.md`
- Current strategy read:
  - the most feasible quasi-causal follow-on is now specified more concretely
  - the right redesign is not a coarse `country x genre_family` treatment panel
  - it is a stacked `city x genre_family` event study around clean national breakout episodes, with
    identification from pre-shock local capability within the treated country-genre
- Current implication:
  - if the project tests a causal extension, the first operational task is to build a clean
    breakout-episode file rather than to add more rows mechanically to the older domestic-success
    FE pilot

---

### Session: 2026-04-09 (causal follow-on strategy memo added)
- Added:
  - `notes/22_causal_followon_designs.md`
- Updated:
  - `notes/README.md`
- Current strategy read:
  - the current draft should stay a reduced-form field paper rather than being stretched into a
    causal scene-origins paper
  - if a quasi-causal follow-on is pursued, the practical ranking is:
    - breakout-demand shock first
    - central-musician-loss feasibility audit second
    - infrastructure shock distant third
- Current implication:
  - the cleanest next step for a causal branch is a bounded audit rather than a rewrite of the live
    paper

---

### Session: 2026-04-09 (fourth internal AER-style referee read)
- Added:
  - `referee/aer_referee_report_round4.md`
- Current report read:
  - the recommendation remains reject at AER standard
  - the draft is now judged to be the strongest version so far and a credible field-paper
  - the central AER blocker remains the same:
    - the strongest result is still about the later approach to an operational emergence threshold
      rather than the causal origin of new scenes
  - the next obvious compression margin is now the empirical-motivation section
- Current implication:
  - the paper should now be treated as close to a stable field-journal draft
  - if one more tightening pass is done, it should be compressive rather than additive

---

### Session: 2026-04-09 (field-journal positioning memo added)
- Added:
  - `referee/field_journal_positioning_memo.md`
- Current implication:
  - the project now has a clean target statement for the next draft stage that is not framed only
    as a response to the AER reports
  - the draft can now be stabilized as a field-paper without reopening exploratory branches

---

### Session: 2026-04-09 (literature review compressed)
- Updated:
  - `drafts/sections/literature_review.tex`
  - `STATUS.md`
  - `notes/05_research_plan.md`
- Current writing read:
  - the literature review now keeps the same citation spine with fewer explanatory detours
  - the paper's middle sections now better match the discipline of the front end and results
- Current implication:
  - the draft is now close to a stable field-paper version
  - the next move is likely a stop-or-stabilize decision rather than another major rewrite

---

### Session: 2026-04-09 (front end polished toward field-journal fit)
- Updated:
  - `drafts/metal.tex`
  - `drafts/sections/introduction.tex`
  - `notes/08_scene_paper_sections.md`
  - `STATUS.md`
  - `notes/05_research_plan.md`
- Current writing read:
  - the abstract now leads with local scene emergence in heavy metal rather than a broader
    category-creation claim
  - the introduction now states the paper's bounded contribution more directly:
    - new city-level collaboration data
    - a panel measure of scene emergence
    - a validated reduced-form result strongest near the later approach to emergence
  - the opening pages now lean less on broad general-interest aspiration and more on the paper the
    current design can actually support
- Current implication:
  - the draft is now better aligned with the round-three referee read
  - the next revision should be compressive rather than architectural

---

### Session: 2026-04-09 (third internal referee read confirms field-journal fit)
- Added:
  - `referee/aer_referee_report_round3.md`
- Current report read:
  - the recommendation remains reject at AER standard
  - but the report is materially more favorable than the prior two rounds
  - the draft is now judged to be a coherent field-journal paper rather than a sprawling working
    memo
  - the main remaining issues are:
    - keep claim language disciplined
    - consider trimming the role-composition paragraph
    - do one more front-end polish pass only if needed
- Current implication:
  - the paper should now be revised as a bounded field-paper, not as an AER-aspirational object
  - the next revisions should be compressive rather than expansive

---

### Session: 2026-04-09 (main-table interpretation and notes tightened)
- Updated:
  - `drafts/sections/method.tex`
  - `drafts/tables/preferred_results.tex`
  - `drafts/sections/results.tex`
  - `notes/08_scene_paper_sections.md`
  - `STATUS.md`
  - `notes/05_research_plan.md`
- Current writing read:
  - the preferred table now states explicitly that the lagged predictors are z-scored, so the
    coefficients are directly comparable on a common within-sample scale
  - the main text now translates the three headline coefficients into percentage-point terms
    relative to the `3.09` percent event rate:
    - local spawning flow: about `1.3` percentage points
    - target-genre active bands: about `5.1` percentage points
    - target-genre multi-band depth: about `2.3` percentage points
  - the negative overall multi-band-musician control is now explained as a conditional contrast:
    broader city-wide overlap is less helpful than overlap concentrated within the focal niche
- Current implication:
  - the preferred scene table now reads more like a paper result and less like a raw regression
    dump
  - the next live task is another referee-style read on the tighter draft rather than more local
    table editing

---

### Session: 2026-04-09 (digital and broadband material pushed into appendix)
- Updated:
  - `drafts/sections/results.tex`
  - `drafts/sections/appendix.tex`
  - `STATUS.md`
  - `notes/05_research_plan.md`
- Current writing read:
  - the main results section is now more tightly centered on:
    - descriptive critical mass
    - the preferred exact-year scene result
    - threshold and measurement validation
  - the digital-era split remains only as a short secondary note
  - the broader country-level internet and city-level broadband probes have been moved out of the
    core narrative and into an appendix prose subsection
- Current implication:
  - the paper now reads less like a bundle of adjacent probes and more like one paper with a clear
    main result
  - the next live bottlenecks are:
    - main-table interpretation and presentation
    - another referee-style read on the tighter draft
    - a final front-end alignment pass if the new referee read still finds drift

---

### Session: 2026-04-09 (measurement-validation package integrated into the draft)
- Added:
  - `code/71_build_scene_measurement_validation.py`
  - `data/processed/scene_networks/scene_measurement_validation_results.csv`
  - `data/processed/scene_networks/scene_historical_sanity_cases.csv`
  - `data/processed/scene_networks/scene_measurement_validation_summary.md`
  - `drafts/tables/appendix_measurement_validation.tex`
  - `drafts/tables/appendix_historical_sanity.tex`
- Updated:
  - `drafts/sections/data.tex`
  - `drafts/sections/results.tex`
  - `drafts/sections/appendix.tex`
  - `notes/08_scene_paper_sections.md`
- Current empirical read:
  - the preferred exact-year FE sample is already geography-clean on the project's current audit
    rule:
    - zero region-like rows
    - zero malformed-label rows
  - tightening the geography screen does not materially move the headline coefficients:
    - dropping the `177` small-dense labels shifts the three coefficients only from `0.0134`,
      `0.0505`, and `0.0227` to `0.0133`, `0.0510`, and `0.0215`
  - coverage-sensitive restrictions also leave the main pattern intact:
    - the post-1990 sample yields `0.0135`, `0.0481`, and `0.0235`
    - the `23` countries with at least `50` emergence events yield `0.0143`, `0.0514`, and
      `0.0213`
  - the historical sanity table is useful on both substantive and measurement margins:
    - Birmingham heavy metal appears in `1977`
    - Tampa death metal appears in `1987`
    - Bergen black metal appears in `1992`
    - Oslo black metal appears in `1990`
    - Gothenburg melodic death metal appears in `1996`
    - Bay Area thrash is intentionally excluded from the city baseline because it is a wider-unit
      label rather than a city
- Current implication:
  - the emergence object is now defended on both threshold and measurement margins
  - the next live bottlenecks are:
    - scope cleanup of the internet and broadband material
    - tighter interpretation and presentation of the preferred table
    - one more results-section compression pass before another internal referee read

---

### Session: 2026-04-09 (threshold-response package integrated into the draft)
- Added:
  - `code/70_build_scene_threshold_response.py`
  - `data/processed/scene_networks/scene_threshold_response_results.csv`
  - `data/processed/scene_networks/scene_threshold_response_summary.md`
  - `drafts/tables/appendix_threshold_response.tex`
  - `drafts/tables/appendix_threshold_specificity.tex`
- Updated:
  - `drafts/metal.tex`
  - `drafts/sections/introduction.tex`
  - `drafts/sections/results.tex`
  - `drafts/sections/appendix.tex`
  - `notes/08_scene_paper_sections.md`
- Current empirical read:
  - the preferred three-variable result is not pinned to the fifth-band cutoff:
    - under thresholds `3`, `4`, `5`, `6`, and `8`, local spawning flow, target-genre active
      bands, and target-genre multi-band musicians all remain positive
  - the stronger distance-from-threshold checks are materially more sobering:
    - dropping rows one band below the fifth-band cutoff leaves the headline coefficients positive
      but much smaller
    - keeping only cells with lag cumulative formed bands `<= 2` attenuates the pattern sharply,
      and the target-genre multi-band coefficient is no longer distinguishable from zero
  - the cleanest narrowed interpretation is now:
    - the paper is strongest on late-stage local niche consolidation rather than on the earliest
      seed stage of scene formation
  - a focal labor-pool specificity check still helps the mechanism read:
    - target-genre multi-band musicians stay positive once target-genre active musicians are added
    - target-genre active musicians themselves turn negative conditional on target-genre active
      bands
- Current implication:
  - the threshold-objection package is now built and integrated into the paper draft
  - the next live bottlenecks are:
    - measurement validation of the emergence object
    - scope cleanup of internet and broadband material
    - interpretation polish for the main table

### Session: 2026-04-09 (internal AER-style referee report, round 2)
- Added:
  - `referee/aer_referee_report_round2.md`
- Current report read:
  - the introduction-led rewrite is judged a real improvement
  - the recommendation still stays at reject for AER
  - the unresolved central issue is still the threshold-mechanics objection
  - the secondary live issue is that the results section remains too diffuse because internet and
    broadband material still take too much main-text space relative to the core scene result
- Current implication:
  - the next revision should not revisit the introduction again first
  - it should now move directly to:
    - threshold-response tests
    - measurement validation
    - tighter scope cleanup in the results section

### Session: 2026-04-09 (appendix package integrated into LaTeX draft)
- Added:
  - `drafts/sections/appendix.tex`
  - `drafts/tables/appendix_sample_construction.tex`
  - `drafts/tables/appendix_variable_crosswalk.tex`
- Updated:
  - `drafts/metal.tex`
  - `drafts/sections/data.tex`
  - `drafts/sections/method.tex`
  - `notes/08_scene_paper_sections.md`
- Current writing read:
  - the paper now has an explicit appendix section in the LaTeX draft rather than only markdown
    audit objects sitting outside the paper
  - the main text still keeps compact sample-construction and variable-summary tables, but it now
    points directly to Appendix Tables `A1` and `A2` for the full audit trail
  - appendix table numbering is now distinct from the main text, and the rebuilt PDF compiles
    cleanly
- Current implication:
  - the empirical package is more defensible and easier to hand to a reader without sending them
    back to markdown notes
  - the next writing bottleneck is now front-end paper quality: abstract, introduction, captions,
    and table notes rather than missing appendix infrastructure

### Session: 2026-04-09 (front end rewritten into an introduction-led draft)
- Added:
  - `drafts/sections/introduction.tex`
- Updated:
  - `drafts/metal.tex`
  - `notes/08_scene_paper_sections.md`
  - `notes/05_research_plan.md`
  - `STATUS.md`
- Current writing read:
  - the paper no longer opens with the literature review
  - the abstract now fits the narrower reduced-form paper better
  - the new introduction states:
    - the question
    - the data contribution
    - the main result
    - the main limitation
    - the paper's broader economics payoff
- Current implication:
  - the front-end bottleneck is materially reduced
  - the next live bottlenecks are now the threshold-objection package and the measurement-validation
    package

### Session: 2026-04-09 (internal AER-style referee report drafted)
- Added:
  - `referee/aer_referee_report.md`
  - `referee/aer_revision_plan.md`
- Current report read:
  - recommendation is reject at AER standard
  - strongest critique is that the main threshold-crossing result is still too close to a
    mechanical local-thickness fact
  - secondary critique is that the paper remains too reduced-form and setting-specific for AER
    even though the data object is genuinely interesting
- Current implication:
  - the report is useful as a sharpening device for the next draft
  - the revision plan now locks the immediate sequence:
    - real introduction and abstract rewrite
    - direct threshold-objection package
    - stronger substantive validation of the emergence measure
    - tighter focus on the core scene result rather than exploratory side branches

### Session: 2026-04-01 (theory notation aligned to empirical scene design)
- Updated:
  - `drafts/sections/model.tex`
  - `notes/03_model_notes.md`
  - `notes/08_scene_paper_sections.md`
- Theory-side changes:
  - clarified that the empirical spawning variable is `city-year`, not `city x genre x year`
  - reinterpreted spawning as a proxy for broad local spinout intensity via the latent embedded-
    founder share `\rho_{ct}`
  - added an explicit threshold-crossing hazard bridge from niche entry dynamics to the paper's
    exact-year emergence outcome
- Current implication:
  - the live model section now maps more tightly to the actual regression object
  - the longer model note and the integrated paper-sections note now use the same spawning
    interpretation

### Session: 2026-03-30 (city-level broadband raw store and first city-quarter panel)
- Added reusable shared scripts:
  - `_shared/scripts/download_ookla_open_data.py`
  - `_shared/scripts/aggregate_ookla_tiles_to_city_points.py`
- New reusable raw-data asset on `D:`:
  - `D:\AI_data\shared\connectivity\ookla_open_data\`
  - official Ookla Open Data fixed-broadband parquet mirror
  - current coverage: `2019 Q1` to `2025 Q4`
  - `28` quarterly files, about `8.57 GB`
- First proof-of-concept city-quarter panel for the project:
  - `data/processed/scene_networks/diffusion/black_metal_city_broadband_2019_2025_radius15km.csv`
  - `895` cities
  - `25,060` city-quarter rows
  - `15 km` radius aggregation from tile centroids
- Current implication:
  - we now have a real reusable city-broadband workflow for recent years
  - this is likely more useful for the other project than for the early-period metal paper because
    Ookla fixed-broadband coverage starts only in `2019`

### Session: 2026-03-30 (model expanded and literature review substantially redrafted)
- Updated:
  - `drafts/sections/model.tex`
  - `drafts/sections/literature_review.tex`
  - `drafts/sections/references.tex`
  - `drafts/metal.tex`
  - `notes/17_lit_review_verification.md`
- Current writing read:
  - the model section is no longer a short gloss; it now includes:
    - CES differentiated-variety setup
    - heterogeneous founders
    - quality and fixed-cost equations
    - aggregate entry
    - dynamics
    - emergence threshold
  - the literature review is now materially fuller and organized around:
    - creative geography and music scenes
    - agglomeration and local externalities
    - worker mobility, spinouts, and recombination
    - varieties
    - digitization and genre measurement
  - the empirical-motivation figures are forced to clear before the model using `\\clearpage`, so
    the diffusion figure no longer drifts into the model section
- Current implication:
  - the next paper bottleneck is now quality of the introduction and the transition from the lit
    review into the model, not missing model substance

### Session: 2026-03-30 (paper reordered to put model before data and empirics)
- Added:
  - `drafts/sections/model.tex`
- Rewrote:
  - `drafts/sections/method.tex`
  - `drafts/metal.tex`
- Current writing read:
  - the LaTeX paper now has a cleaner economics-paper order:
    - literature review
    - empirical motivation
    - model
    - data
    - empirical approach
    - results
  - the compact micro model now sits before the data and empirical section rather than being buried
    inside the method text
- Current implication:
  - the next writing task is to improve the expanded literature review so it matches the stronger
    model section

### Session: 2026-03-30 (model note rewritten around a concrete economics model)
- Rewrote:
  - `notes/03_model_notes.md`
- Current theory read:
  - the best model is now stated explicitly as a hybrid with one center:
    - local variety creation
    - spinouts
    - recombination through overlapping workers
    - diffusion only as a secondary extension
  - the note now includes:
    - ranked candidate model families
    - a simple entry-cost formulation
    - state-variable dynamics for `B`, `M`, and `S`
    - scene emergence as a threshold-crossing event
    - comparative statics that map directly to the paper coefficients
- Current implication:
  - the next clean paper task is to compress this note into a short formal-model subsection in the
    LaTeX draft rather than keep debating model families abstractly

### Session: 2026-03-30 (digital-era split probe)
- Added:
  - `code/54_probe_scene_digital_era_splits.py`
  - `notes/16_digital_era_split_probe.md`
- Wrote:
  - `data/processed/scene_networks/scene_digital_era_split_results.csv`
  - `data/processed/scene_networks/scene_digital_era_split_summary.md`
- Current read:
  - the preferred scene result does not disappear in later periods
  - local spawning flow attenuates across `<=1994`, `1995-2004`, and `2005-2014`
  - target-genre active bands also attenuate materially
  - target-genre multi-band musicians stay stable or slightly strengthen
- Current implication:
  - the digital-era question is worth keeping as a descriptive robustness check
  - the cleanest nuance is not that the internet killed scenes, but that some local stock margins
    weaken while overlapping worker depth remains important

### Session: 2026-03-30 (lit review and empirical motivation integrated into paper)
- Added to the LaTeX draft:
  - `drafts/sections/literature_review.tex`
  - `drafts/sections/empirical_motivation.tex`
  - `drafts/sections/references.tex`
- Added:
  - `code/51_build_black_metal_diffusion_snapshots.py`
  - `data/processed/scene_networks/diffusion/figures/black_metal_diffusion_snapshots.png`
  - `data/processed/scene_networks/diffusion/black_metal_diffusion_snapshots_summary.md`
- Updated:
  - `drafts/metal.tex`
  - `notes/02_literature_and_synthesis.md`
- Current writing read:
  - the paper now has literature review, empirical motivation, data, empirical approach, and
    results
  - the empirical motivation now includes both a global genre-proliferation figure and a static
    scene-diffusion figure
- Current implication:
  - the next pass should improve the quality of the prose and table presentation inside the paper
    rather than expand the empirical scope again

### Session: 2026-03-30 (paper voice rewrite and literature search pass)
- Updated:
  - `drafts/metal.tex`
  - `drafts/sections/data.tex`
  - `drafts/sections/method.tex`
  - `drafts/sections/results.tex`
  - `notes/02_literature_and_synthesis.md`
- Current writing read:
  - the LaTeX draft now reads less like a scaffold and more like a paper draft
  - the `Data`, `Method`, and `Results` sections now use a more restrained academic register
- Current literature read:
  - the lit review note now has a more explicit search-driven bridge on:
    - local spillovers
    - worker mobility
    - urban buzz
    - local variety creation
  - additions include:
    - `Moretti (2004)`
    - `Møen (2000)`
    - `Storper and Venables (2004)`
    - `Glaeser, Ponzetto, and Tobio (2011/2014)`
- Current implication:
  - the next pass should probably improve the tables and title rather than add more branches

### Session: 2026-03-30 (first paper-phase LaTeX draft created)
- Added:
  - `drafts/metal.tex`
  - `drafts/sections/data.tex`
  - `drafts/sections/method.tex`
  - `drafts/sections/results.tex`
  - `drafts/tables/sample_construction.tex`
  - `drafts/tables/main_variables.tex`
  - `drafts/tables/preferred_results.tex`
- Compiled:
  - `drafts/metal.pdf`
- Current writing read:
  - the first LaTeX paper draft is solo-author and intentionally simple
  - main sections are:
    - data
    - empirical approach
    - results
  - the draft already includes three tables and two inserted figures
- Current implication:
  - the next paper task is to improve paper-standard presentation and wording inside the LaTeX
    draft rather than continue expanding side branches

### Session: 2026-03-30 (main draft reorganized around paper order)
- Updated:
  - `notes/08_scene_paper_sections.md`
  - `notes/05_research_plan.md`
  - `README.md`
  - `STATUS.md`
- Current writing read:
  - the main draft is now explicitly structured as:
    - data
    - empirical approach
    - results
  - the sample-construction counts are now stated more clearly in the main data section
- Current implication:
  - the next writing task is the appendix pass, so the main text and appendix objects line up cleanly

### Session: 2026-03-28 (model-side literature anchors added)
- Updated:
  - `notes/02_literature_and_synthesis.md`
- Added a targeted subsection on:
  - differentiated varieties
  - recombination
  - urban agglomeration microfoundations
  - spinouts
- Verified anchors added:
  - `Dixit and Stiglitz (1977)`
  - `Romer (1990)`
  - `Weitzman (1998)`
  - `Duranton and Puga (2004)`
  - `Glaeser et al. (1992)`
  - `Franco and Filson (2006)`
- Current implication:
  - the modelling section can now be framed in more mainstream economics language as local variety
    creation through labor pooling, recombination, and spinouts

### Session: 2026-03-27 (conceptual framework integrated into paper draft)
- Updated:
  - `notes/08_scene_paper_sections.md`
  - `notes/05_research_plan.md`
  - `README.md`
  - `STATUS.md`
- Current writing read:
  - the compact economics framework from `03_model_notes.md` is now inside the main paper draft
  - the live draft now states the theory object directly as local niche formation through labor
    pooling, spinouts, and recombination
- Current implication:
  - the next clean writing task is the appendix pass, not more theory expansion

### Session: 2026-03-27 (model note rewritten)
- Rewrote:
  - `notes/03_model_notes.md`
- Current conceptual read:
  - main theory object:
    - local niche formation in a project-based creative industry
  - core mechanisms:
    - labor pooling
    - spinouts
    - recombination through overlapping teams
  - secondary extension:
    - diffusion of genre templates across cities
  - baseline only:
    - all metal as a parent-form benchmark, not the main paper object
- Current implication:
  - the live theory now matches the data work
  - the next writing step is to fold this compact framework into `08_scene_paper_sections.md`

---

### Session: 2026-03-27 (multi-genre diffusion check run)
- Added:
  - `notes/15_multi_genre_diffusion_check.md`
- Current comparison read:
  - checked:
    - `black_metal`
    - `death_metal`
    - `thrash_metal`
    - `doom_metal`
    - `power_metal`
  - cross-genre result:
    - the maps still make the diffusion idea visually plausible
    - but the first reduced-form exposure terms mostly do not survive once lagged local same-genre
      thickness is included
- Current implication:
  - diffusion is useful as descriptive support
  - local scene thickness remains the stronger empirical result
  - the project should not pivot into a diffusion paper right now

---

### Session: 2026-03-27 (diffusion exposure panel built)
- Added:
  - `code/50_build_scene_diffusion_exposure_panel.py`
  - `notes/14_scene_diffusion_exposure_panel.md`
- Wrote:
  - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_panel.csv`
  - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_results.csv`
  - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_bins.csv`
  - `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_summary.md`
- Current black-metal read:
  - matched city cells:
    - `4,281`
  - at-risk city-year observations:
    - `11,503`
  - emergence events:
    - `894`
  - descriptive pattern:
    - emergence rates rise across hub-exposure quintiles
  - first reduced-form result:
    - lagged external hub exposure is positive on its own
    - but it washes out once lagged local same-genre band stock is included
- Current implication:
  - this is a real diffusion branch, not just a map idea
  - but the first serious pass still reinforces the main scene paper rather than replacing it
  - local same-genre thickness remains the stronger empirical object

---

### Session: 2026-03-27 (band-level world animation prototype built)
- Added:
  - `code/49_build_band_genre_world_animation.py`
  - `notes/13_band_world_animation_workflow.md`
- Wrote:
  - `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_coordinates.csv`
  - `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_panel.csv`
  - `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_yearly_summary.csv`
  - `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation.html`
  - `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_summary.md`
- Current prototype read:
  - first genre:
    - `black_metal`
  - frame step:
    - `3` years
  - geography-clean city matches:
    - `4053` of `6161` (`65.8%`)
  - matched band-year observations:
    - `101,092`
  - descriptive note:
    - this looks like a workable moving world map of active bands, but it is still just a visual
      prototype
- Current implication:
  - this is a separate exploratory branch, not part of the main paper spine
  - if it stays, it should be treated as a visual companion to the diffusion story, not as a core
    empirical result

---

### Session: 2026-03-27 (scene-diffusion prototype built)
- Added:
  - `code/48_build_scene_diffusion_map.py`
  - `notes/12_scene_diffusion_workflow.md`
- Wrote:
  - `data/processed/scene_networks/diffusion/black_metal_city_coordinates.csv`
  - `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_panel.csv`
  - `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_map.html`
  - `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_summary.md`
- Current prototype read:
  - first genre:
    - `black_metal`
  - geography-clean emerged-city coordinate coverage:
    - `895` of `977` cities (`91.6%`)
  - matched yearly active city observations:
    - `14,694`
  - descriptive diffusion pattern:
    - this looks more like a sequence of hub formation and spread than a one-origin story
    - early emerged hubs include `Athens`, `Stockholm`, and `Oslo`
    - later large hubs include `Moscow`, `São Paulo`, `Paris`, `Bogota`, and `Santiago`
- Current implication:
  - this is a useful descriptive branch for showing scene-to-scene diffusion
  - the next serious step would be a distance-weighted exposure panel, not further map styling
  - keep it secondary to the main local scene-emergence paper for now

---

### Session: 2026-03-27 (band-success upgrading ladder sidecar built)
- Added:
  - `code/47_build_band_upgrading_ladder_sidecar.py`
  - `notes/11_band_upgrading_ladder.md`
- Wrote:
  - `data/processed/band_success/band_upgrading_ladder_outcomes.csv`
  - `data/processed/band_success/city_genre_birth_cohort_upgrading_panel.csv`
  - `data/processed/band_success/city_genre_birth_cohort_upgrading_pilot.csv`
  - `data/processed/band_success/band_upgrading_ladder_summary.md`
- Current sidecar read:
  - the cleaner sidecar object is now a staged upgrading ladder rather than vague `breakout band`
  - matched bands by stage:
    - `16` home-market presence
    - `13` home-market validation
    - `12` foreign-market presence
    - `5` validated-then-foreign
  - audited cohort file:
    - `57,756` `city x genre_family x formed_year` rows
    - `5` home-market validated winner cohorts within `15` years
    - `3` validated-then-foreign cohorts within `20` years
- Current implication:
  - this is a better conceptual sidecar than the old `ever successful band` object
  - but it is still too sparse to move into a serious regression branch
  - if the branch is revisited, the next disciplined move is to lock a bounded cohort-winner
    outcome rather than widen raw coverage again

---

### Session: 2026-03-27 (workflow reset around the paper)
- Added `notes/10_workflow_reset.md`.
- Updated:
  - `STATUS.md`
  - `README.md`
  - `notes/05_research_plan.md`
  - `notes/README.md`
- Tightened `notes/08_scene_paper_sections.md` into first full-draft prose rather than a
  section-ready memo.
- Extended `notes/08_scene_paper_sections.md` again with a real abstract, a cleaner bridge from
  measurement to evidence, an economic-interpretation subsection, and a compact conclusion.
- Expanded the band-success sidecar with new home-market manual supplements for:
  - Finland
  - Sweden
  - France
  - Norway
- Updated:
  - `code/03_build_core_treatment_panel.py`
  - `code/38_build_band_success_sidecar_data.py`
- New sidecar outputs now include:
  - `data/processed/band_success/band_success_coverage_audit.csv`
  - `data/processed/band_success/band_success_design_audit.md`
- Current sidecar read after the expansion:
  - curated home-market success artists in current core file: `17`
  - matched onto the birth panel: `16`
  - `top10` cases: `9`
  - median founding-to-success gap: `16.5` years
  - practical implication:
    - the branch is now worth keeping
    - but the next disciplined move is a bounded-horizon or later-cohort redesign, not a naive
      full-sample birth regression
- Current workflow read:
  - the network figure branch is now explicitly parked rather than treated as the main bottleneck
  - the live workflow returns to the paper spine:
    - keep `08_scene_paper_sections.md` as the live writing object
    - keep appendix support moving
    - leave the band-success branch secondary until the main draft advances
- Current implication:
  - the metal project should now be run as a paper-first workflow again, not a graph-first workflow

---

### Session: 2026-03-26 (Helsinki connector-core preview graphs built)
- Added `code/40_build_gephi_preview_graphs.py`.
- Wrote:
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_preview.png`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_connector_core_preview.png`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_preview.png`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_connector_core_preview.png`
  - `data/processed/scene_networks/gephi_exports/helsinki_gephi_preview_comparison.md`
- Current preview read:
  - the full Helsinki maps are useful diagnostics but not good paper figures because the city-year
    network breaks into many disconnected band cliques
  - connector-core trims read much better because they keep only components that contain multi-band
    bridges
  - `Helsinki, Finland / black_metal / 2010` is the best current thick-scene candidate, but it is
    still provisional rather than paper-settled:
    - `53` musicians
    - `146` edges
    - `8` repeated ties
    - `13` connectors
    - `6` connected components
  - `Helsinki, Finland / death_metal / 2005` is mostly a contrast case for thickness without much
    overlap:
    - `20` musicians
    - `34` edges
    - `5` connectors
    - `4` connected components
- Current implication:
  - the live paper-facing thick-scene map is not settled yet
  - Pittsburgh remains useful as a smaller pre-emergence mechanism appendix or slide

---

### Session: 2026-03-26 (Gephi-ready Helsinki export built)
- Added `code/39_export_gephi_city_genre_network.py`.
- Wrote:
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_nodes.csv`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_edges.csv`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_gephi_recipe.md`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_death_metal_2005_summary.md`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_nodes.csv`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_edges.csv`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_gephi_recipe.md`
  - `data/processed/scene_networks/gephi_exports/helsinki_finland_black_metal_2010_summary.md`
- Current export read:
  - `Helsinki, Finland / death_metal / 2005`:
    - active musicians: `105`
    - collaboration edges: `163`
    - multi-band connectors: `5`
  - `Helsinki, Finland / black_metal / 2010`:
    - active musicians: `79`
    - collaboration edges: `159`
    - repeated ties: `8`
    - multi-band connectors: `13`
  - both are much better suited to a Gephi force-directed map than the tiny Pittsburgh microcase
- Current implication:
  - if the paper wants a visually impressive local labor-market network, a large city-genre case
    like Helsinki is the right direction
  - Gephi is now installed at `D:\apps\gephi\`
  - the live workflow is now Gephi-first rather than matplotlib-first for the thick-scene map
  - the black-metal export may actually be the better figure because it has more connector
    structure and repeated ties relative to its size

---

### Session: 2026-03-26 (band-success sidecar pilot built)
- Added `code/38_build_band_success_sidecar_data.py`.
- Wrote:
  - `data/processed/band_success/band_birth_panel.csv`
  - `data/processed/band_success/band_scene_at_birth_panel.csv`
  - `data/processed/band_success/band_success_outcomes.csv`
  - `data/processed/band_success/band_success_match_diagnostics.csv`
  - `data/processed/band_success/band_success_descriptive_pilot.csv`
  - `data/processed/band_success/band_success_sidecar_summary.md`
- Current pilot read:
  - birth panel now has `128,053` rows
  - exact pre-birth scene matches at `formed_year - 1`: `67,572`
  - conservative home-market success coverage is still tiny:
    - `11` curated artists survive the current alias or homonym screen
    - `10` match onto the birth panel
    - `5` certification cases
    - `4` top-10 cases
  - explicit audit adjustments already needed:
    - map `Rhapsody` to `Rhapsody of Fire`
    - exclude obvious homonym collisions `Disturbed` and `Slipknot`
    - `Rammstein` remains unmatched under current Metallum coverage
- Current implication:
  - the sidecar is now a real data workflow, not just a design note
  - it is not yet a serious regression branch because the outcome side is too sparse
  - the next sidecar task is to expand audited home-market success coverage, not to force a model

---

### Session: 2026-03-26 (band-success sidecar moved into active workflow)
- Added `notes/09_band_success_workflow.md`.
- Updated:
  - `notes/04_empirical_notes.md`
  - `notes/05_research_plan.md`
  - `notes/README.md`
  - `README.md`
  - `STATUS.md`
- Current branch logic is now explicit:
  - main paper:
    `scene -> genre emergence`
  - active sidecar:
    `scene -> band success`
  - fallback:
    `domestic breakthrough shock -> later entry`
- Current implication:
  - the next empirical sidecar build should be a band birth panel linked to scene-at-birth
    predictors and later visible success outcomes

---

### Session: 2026-03-26 (musician-only Pittsburgh graph built)
- Added `code/37_build_scene_case_study_musician_network.py`.
- Wrote:
  - `data/processed/scene_networks/figures/pittsburgh_doom_metal_musician_network.png`
  - `data/processed/scene_networks/pittsburgh_doom_metal_musician_network_summary.md`
- Current figure read:
  - redesigned as a weighted musician map with `12` people and `25` co-worker ties in detection
    year `1991`
  - node colors now mark primary local project affiliation
  - edge width now carries repeated shared-band ties directly
  - `6` multi-band connectors are highlighted by outline
- Current implication:
  - this is the preferred fourth-figure candidate over the earlier band-worker bipartite graph
  - it is visually closer to the clustered music-network map style and fits the economics framing
    better because it foregrounds labor pooling and recombination

---

### Session: 2026-03-26 (Pittsburgh case-study graph built)
- Added `code/36_build_scene_case_study_network.py`.
- Wrote:
  - `data/processed/scene_networks/figures/pittsburgh_doom_metal_case_network.png`
  - `data/processed/scene_networks/pittsburgh_doom_metal_case_network_summary.md`
- Current case-study read:
  - the figure shows `5` supporting bands and `12` active worker nodes in detection year `1991`
  - `6` multi-band connectors are highlighted
  - `Penance` is the central local project in the reconstructed cluster
- Current implication:
  - this is now the live small mechanism case rather than the main thick-scene figure
  - write the visual as worker-project recombination and local capability accumulation, not as
    scene lore

---

### Session: 2026-03-26 (broker dropped from paper package)
- Rebuilt `data/processed/scene_networks/figures/scene_preferred_mechanism_coefficients.png` as a
  single-panel headline figure using only the preferred core exact-year FE specification.
- Updated the live paper-facing drafts so broker or connector variables are no longer part of the
  active main-text package.
- Current live paper headline is now only:
  - local spawning flow
  - target-genre active bands
  - target-genre multi-band musicians
- Current implication:
  - the final main-text support object should be a case-study network figure, not a broker panel

---

### Session: 2026-03-26 (appendix objects built)
- Wrote:
  - `data/processed/scene_networks/scene_appendix_sample_construction.md`
  - `data/processed/scene_networks/scene_appendix_sample_construction.csv`
  - `data/processed/scene_networks/scene_appendix_variable_crosswalk.md`
  - `data/processed/scene_networks/scene_appendix_variable_crosswalk.csv`
- Current appendix package now covers:
  - sample construction from raw band and member inputs to the preferred exact-year FE sample
  - paper-facing variable definitions for the preferred scene table
  - caption-ready text for later LaTeX transfer
- Current implication:
  - the scene paper now has real appendix infrastructure
  - the next unresolved paper choice is the last supporting figure

---

### Session: 2026-03-26 (section-ready scene draft written)
- Added `notes/08_scene_paper_sections.md`.
- The paper now has section-ready markdown prose for:
  - Introduction
  - Data and Measurement
  - Results
- Current stable paper logic:
  - critical-mass figure first
  - headline core coefficient figure second
  - one additional supporting figure at most
- Current practical implication:
  - the empirical spine is now written closely enough that appendix work should come next
  - LaTeX is now feasible later, but not yet necessary

---

### Session: 2026-03-26 (scene prose memo written)
- Added `notes/07_scene_paper_memo.md`.
- The paper now exists as real markdown prose, not just as an outline:
  - opening argument
  - data and measurement framing
  - descriptive critical-mass fact
  - exact-year FE design language
  - preferred paired result
  - mechanism interpretation
  - figure order
- Current drafting rule:
  - keep causal language out
  - use `cross-genre connectors` in prose
  - keep theory compact until the empirical draft is fully stable

---

### Session: 2026-03-26 (scene paper skeleton started)
- Added `notes/06_scene_paper_skeleton.md`.
- Current draft structure now exists in markdown rather than LaTeX:
  - working titles
  - one-paragraph pitch
  - abstract skeleton
  - section-by-section paper order
  - figure placement
  - appendix plan
- Current writing rule:
  - empirical spine first
  - compact theory later
  - no serious LaTeX or PDF work until the markdown draft stabilizes
- Current paper logic:
  - optional global opener first
  - critical-mass descriptive figure second
  - preferred paired mechanism figure third
  - one case-study or broker companion figure only after the core draft reveals the need

---

### Session: 2026-03-26 (scene figure package and audits)
- Added `code/35_build_scene_presentation_figures.py`.
- Wrote:
  - `data/processed/scene_networks/scene_figure_roadmap.md`
  - `data/processed/scene_networks/scene_presentation_figures_summary.md`
  - `data/processed/scene_networks/figures/scene_critical_mass_event_rates.png`
  - `data/processed/scene_networks/figures/scene_preferred_mechanism_coefficients.png`
- Also documented the scene branch more explicitly in:
  - `data/processed/scene_networks/scene_data_cleaning_audit.md`
  - `data/processed/scene_networks/scene_variable_measurement_audit.md`
- Current figure-package read:
  - the scene branch now has a real presentation sequence rather than only markdown tables
  - the critical-mass figure is the right first scene visual:
    - exact-year emergence rises from `1.4%` to `4.0%` across active-band bins
    - it rises from `1.4%` to `3.7%` across multi-band-musician bins
  - the preferred coefficient plot is the right second visual:
    - Panel A headlines local spawning flow, target-genre active bands, and target-genre
      multi-band depth
    - Panel B keeps the negative share terms visible without turning broker musicians into the
      unconditional headline
- Current interpretation:
  - the next live scene task is memo-writing and appendix packaging, not more generic predictor
    search
  - paper-facing language should move toward `cross-genre connectors` rather than `broker
    musicians` except in code

---

### Session: 2026-03-26 (preferred scene mechanism table locked)
- Added `code/34_build_scene_preferred_mechanism_table.py`.
- Wrote:
  - `data/processed/scene_networks/scene_cluster_preferred_mechanism_table.csv`
  - `data/processed/scene_networks/scene_cluster_preferred_mechanism_table.md`
- Chosen presentation:
  - paired `roll-5` exact-year FE table
  - Panel A headline core:
    - overall scene controls plus:
      - local spawning flow
      - target-genre active bands
      - target-genre multi-band musicians
  - Panel B composition extension:
    - adds spawn share, broker count and share, and target-genre multi-band share
- Current preferred-table read:
  - Panel A core:
    - local spawning flow: `0.0134`
    - target-genre active bands: `0.0505`
    - target-genre multi-band musicians: `0.0227`
  - Panel B extension:
    - local spawning flow: `0.0224`
    - spawn share: `-0.0066`
    - target-genre active bands: `0.0488`
    - target-genre broker musicians: `0.0579`
    - target-genre broker share: `-0.0724`
    - target-genre multi-band musicians: `0.0331`
    - target-genre multi-band share: `-0.0195`
  - built-in robustness:
    - target-genre multi-band musicians remain:
      - `0.0221` under `roll-3`
      - `0.0217` when the overall switcher control is removed
    - broker count is omitted from Panel A because its counts-only reference coefficient is
      `-0.0053`
- Current interpretation:
  - the scene branch now has a locked headline table rather than an open table-design question
  - the clean unconditional story is local spawning flow plus target-genre active-band and
    switcher depth
  - broker musicians remain in the paper as a conditional composition result, not as a standalone
    unconditional headline
  - the next live task is to refine that broker interpretation or replace it with a cleaner broker
    measure

---

### Session: 2026-03-26 (compact richer-scene stress test built)
- Added `code/33_stress_test_scene_cluster_richer_specs.py`.
- Wrote:
  - `data/processed/scene_networks/scene_cluster_richer_stress_test_results.csv`
  - `data/processed/scene_networks/scene_cluster_richer_stress_test_summary.md`
- Current compact stress-test read:
  - counts-only exact-year FE:
    - local spawning flow stays positive:
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
    - share terms stay negative:
      - `roll-5` spawn share: `-0.0066`
      - `roll-5` broker share: `-0.0724`
      - `roll-5` multi-band share: `-0.0195`
    - count terms remain positive in the same table:
      - `roll-5` spawning flow: `0.0224`
      - `roll-5` target-genre active bands: `0.0488`
      - `roll-5` target-genre broker musicians: `0.0579`
      - `roll-5` target-genre multi-band musicians: `0.0331`
    - broker-musician count therefore flips from slightly negative to strongly positive once
      broker share is held fixed
  - removing the overall switcher control barely changes the target-genre switcher result:
    - `roll-5` coefficient moves from `0.0225` to `0.0216`
- Current interpretation:
  - the count-versus-share split survives both `roll-3` and `roll-5`
  - the cleanest stable scene mechanisms are now spawning flow, target-genre active bands, and
    target-genre switcher depth
  - the broker result is live but now has to be framed as count conditional on broker
    concentration rather than as a generic unconditional stock story
  - the next task is to decide what the compact headline mechanism table should be, not to keep
    adding new generic predictors

---

### Session: 2026-03-26 (richer scene-cluster extensions built)
- Added `code/32_build_scene_cluster_richer_extensions.py`.
- Wrote:
  - `data/processed/scene_networks/city_year_scene_cluster_richer_features.csv`
  - `data/processed/scene_networks/city_genre_scene_cluster_richer_features.csv`
  - `data/processed/scene_networks/scene_cluster_richer_extension_results.csv`
  - `data/processed/scene_networks/scene_cluster_richer_extension_summary.md`
- Current richer extension read:
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
    - `z_roll5_founder_pedigree_mean = -0.0016`, `p = 0.2246`
  - exact-year FE with target-genre labor-pool levels:
    - `z_roll5_log_genre_active_bands = 0.1642`
    - `z_roll5_log_genre_active_musicians = -0.1128`
  - exact-year FE with target-genre broker musicians:
    - `z_roll5_log_genre_broker_musicians = 0.0665`
    - `z_roll5_genre_broker_share = -0.0815`
  - exact-year FE with target-genre switcher depth:
    - `z_roll5_log_genre_multi_band_musicians = 0.0440`
    - `z_roll5_genre_multi_band_share = -0.0280`
  - role-targeted labor pools:
    - strongest role term is guitar:
      `z_roll5_log_genre_active_guitar_musicians = -0.0360`
    - keyboards are weakest:
      `z_roll5_log_genre_active_keyboards_musicians = -0.0018`, `p = 0.1888`
- Current interpretation:
  - the scene branch now has direct measures for spinouts, target-genre labor pools, and
    genre-crossing brokers rather than only city-wide cluster thickness
  - the robust recurring pattern is that absolute target-genre counts are positive while
    corresponding share terms are negative
  - founder pedigree is currently too weak to headline
  - the next scene task should stress-test and compress these richer mechanisms into a preferred
    baseline table before spending more time on the domestic-success fallback

---

### Session: 2026-03-26 (scene role and switcher extensions built)
- Added `code/31_probe_scene_role_switcher_extensions.py`.
- Wrote:
  - `data/processed/scene_networks/city_year_scene_role_switcher_features.csv`
  - `data/processed/scene_networks/scene_role_switcher_critical_mass.csv`
  - `data/processed/scene_networks/scene_role_switcher_extension_results.csv`
  - `data/processed/scene_networks/scene_role_switcher_extension_summary.md`
- Current extension read:
  - descriptive critical mass:
    - active bands:
      - `<10`: `0.0145`
      - `10-19`: `0.0305`
      - `20-39`: `0.0341`
      - `40+`: `0.0398`
    - multi-band musicians:
      - `0-1`: `0.0140`
      - `2-4`: `0.0242`
      - `5-9`: `0.0334`
      - `10+`: `0.0374`
  - exact-year FE:
    - `z_roll5_log_multi_band_musicians = 0.0087`
    - `z_roll5_multi_band_share = -0.0036`
    - current implication: absolute switcher mass matters more than switchers as a scene share
  - role composition:
    - strongest role-specific term is guitar share among switchers
    - current coefficient: `-0.0013`
    - current p-value: `0.0621`
    - current implication: no positive guitarist-creativity story yet
  - signed/unsigned proxy:
    - `z_roll5_unsigned_band_share_current_proxy = -0.0024`
    - current p-value: `0.0123`
    - current implication: current unsigned-heavy scenes look less emergence-prone on this proxy,
      but the measure is not historical
- Current interpretation:
  - the scene branch now has a sharper mechanism ranking:
    - scene thickness
    - organizational variety
    - absolute switcher mass
  - switcher share alone does not look like the key margin
  - signed versus unsigned remains too noisy to elevate beyond exploratory status

---

### Session: 2026-03-26 (scene-cluster robustness pass built)
- Added `code/30_estimate_scene_cluster_regression.py`.
- Wrote:
  - `data/processed/scene_networks/scene_cluster_regression_results.csv`
  - `data/processed/scene_networks/scene_cluster_regression_summary.md`
- Current scene-regression design:
  - seeded forecast LPMs with `3`, `5`, `7`, and `10` year horizons
  - seeded exact-year panels with `city-genre` and year fixed effects
  - current smoothing windows:
    - `roll-3`
    - `roll-5`
  - current predictors:
    - scene size
    - bridge-musician share
    - density
    - modularity
    - nontrivial community count
- Current regression read:
  - forecast horizons:
    - `3y`: size `0.0787`, density `0.0039`, modularity `0.0093`, bridge `-0.0032`
    - `5y`: size `0.1205`, density `0.0064`, modularity `0.0125`, bridge `-0.0086`
    - `7y`: size `0.1552`, density `0.0086`, modularity `0.0121`, bridge `-0.0136`
    - `10y`: size `0.1945`, density `0.0090`, modularity `0.0092`, bridge `-0.0193`
  - exact-year fixed-effects:
    - `roll-3`:
      - `z_roll3_n_nontrivial_communities = 0.0116`
      - `z_roll3_log_active_bands = 0.0669`
    - `roll-5`:
      - `z_roll5_n_nontrivial_communities = 0.0096`
      - `z_roll5_log_active_bands = 0.0664`
    - bridge share stays null in both FE windows
- Current interpretation:
  - the old `community_precedes_label` threshold is still too support-fragile to be the main
    estimand
  - but the scene branch now has a credible regression-based paper design plus a first robustness
    layer
  - the strongest live scene story is local thickness plus organizational variety, not a
    bridge-musician headline
  - domestic success should now be treated as fallback unless the scene regression collapses under
    the next round of robustness checks

---

### Session: 2026-03-26 (scene decision locked; shock-clean domestic rerun built)
- Wrote the explicit scene-branch decision memo:
  - `data/processed/scene_networks/scene_branch_decision_memo.md`
- Current scene-branch decision:
  - keep the scene-network branch as a bounded mechanism or descriptive fork
  - do not promote it to the main paper design
- Current reason:
  - clean city baseline still shows only `21` precedes cases
  - region-like relabeling adds only `1` extra precedes case
  - all surviving city-baseline precedes cases depend on exactly `4` same-genre bands
  - requiring `5` same-genre bands collapses the count to `0`
  - broad-case review packets leave a small but real core:
    - `4` `multi_bridge_support`
    - `2` `hub_bridge_mixed`
    - `2` `single_bridge_risk`
  - strongest scene cases remain:
    - `Pittsburgh`
    - `Bilbao`
    - `Brussels`
- Added `code/14_build_domestic_success_cleanup_priority.py`.
- Current domestic cleanup outputs:
  - `data/processed/country_genre_analysis/domestic_success_cleanup_priority.csv`
  - `data/processed/country_genre_analysis/domestic_success_cleanup_priority.md`
  - `data/processed/country_genre_analysis/domestic_success_pilot_cases_shock_clean.csv`
- Current cleanup read:
  - `keep_in_shock_clean`: `2`
  - `provisional_keep_in_shock_clean`: `1`
  - `replace_or_redate_before_use`: `3`
  - `drop_from_shock_baseline`: `4`
  - shock-clean keep set:
    - `Rammstein`
    - `Nightwish`
    - provisional `Sepultura`
  - drop set:
    - `Dimmu Borgir`
    - `Rhapsody`
    - `Metallica`
    - `Pantera`
  - replace-or-redate set:
    - `Lacuna Coil`
    - `Powerwolf`
    - `Iron Maiden`
- Generalized the domestic-success rerun scripts so they can use arbitrary case files:
  - `code/11_build_domestic_success_pilot_event_pass.py` now accepts:
    - `--pilot-cases-file`
    - `--output-token`
  - `code/12_estimate_domestic_success_pilot_fe.py` now accepts:
    - `--pilot-cases-file`
    - `--output-token`
- Ran the shock-clean reruns and wrote:
  - `data/processed/country_genre_analysis/domestic_success_pilot_event_pass_summary_shock_clean.md`
  - `data/processed/country_genre_analysis/domestic_success_pilot_fe_summary_shock_clean.md`
- Current shock-clean read:
  - descriptive event pass:
    - `2` of `3` cases improve on the all-band share-gap margin
    - pooled all-band share gap rises from about `0.1` percentage points pre-period mean to
      about `1.5` post-period mean
  - FE pass:
    - full `3`-case static coefficient on all starts:
      about `+2.8` with clustered SE `5.7`
    - full `3`-case static coefficient on unsigned starts:
      about `+2.5` with clustered SE `4.8`
    - strict `2`-case `source_a + tier_1` static coefficient on all starts:
      about `-4.3` with clustered SE `2.0`
- Current interpretation:
  - pruning clearly weak rows helps relative to the old `10`-case negative pilot
  - but the positive read currently depends on the provisional `Sepultura` row
  - the right next move is to find earlier source-`A` domestic breakthroughs, not to treat the
    current tiny subset as persuasive

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
- When extending the scene branch, compute rolling predictors at the aggregation level where the
  measure actually lives before merging to the full `city x genre x year` panel; otherwise the
  rolling windows can be contaminated by duplicate within-year panel rows.

---

### Session: 2026-04-09 (breakout branch workflow correction)
- Corrected the breakout-demand branch so the operational workflow matches the live scene taxonomy.
- The key branch issue was real rather than cosmetic:
  - the conceptually attractive `Sepultura - Roots` rows were coded as `extreme_metal`
  - but `extreme_metal` is **not** a live `genre_family` in the current
    `city x genre_family x year` scene panel
  - loading those rows into the event stack produced all-zero focal panels
- The branch now explicitly distinguishes:
  - conceptual screen candidates in
    `data/processed/country_genre_analysis/breakout_episode_candidates.csv`
  - operational stack events in
    `data/processed/country_genre_analysis/breakout_event_file.csv`
- Current operational event file now retains only scene-taxonomy-compatible rows:
  - `deu_industrial_metal_2001_mutter`
  - `deu_symphonic_metal_2004_once`
- Updated the branch notes to record that distinction:
  - `notes/24_breakout_episode_screen.md`
  - `notes/25_breakout_branch_workflow.md`
- Fixed the builder script:
  - `code/72_build_breakout_event_panel.py`
  - the script now validates `primary_genre` against the live scene taxonomy before stacking
  - the old capability-bin assignment bug is fixed; it no longer resets the sparse panel index and
    silently drops most labels
  - the capability rule is now more honest:
    - zero-score cities stay `low_capability`
    - only positive-score cities can become `mid_capability` or `high_capability`
    - events with no variation would be flagged as `flat_capability`
- Rebuilt the branch outputs:
  - `data/processed/country_genre_analysis/city_genre_breakout_event_panel.csv`
  - `data/processed/country_genre_analysis/city_genre_breakout_capability.csv`
  - `data/processed/country_genre_analysis/breakout_branch_panel_summary.md`
- Corrected branch read after rebuild:
  - retained events: `2`
  - event coverage:
    - `deu_industrial_metal_2001_mutter`: `8` event-window years with local genre starts
    - `deu_symphonic_metal_2004_once`: `16` event-window years with local genre starts
  - pre-shock capability is extremely sparse:
    - industrial event: `3` high-capability cities and `2,292` low-capability cities
    - symphonic event: `1` high-capability city, `3` mid-capability cities, and `2,291`
      low-capability cities
- Practical implication:
  - the branch workflow is now valid and reproducible
  - but the current operational stack is still a **workflow object**, not a regression-ready causal
    design
  - the next serious branch decision is whether to add more panel-compatible events or stop before
    event-study estimation

---

### Session: 2026-04-09 (breakout branch audit and descriptive gate)
- Extended the breakout branch from a two-event placeholder into a real audited first-breakout
  stack.
- Added:
  - `code/73_audit_breakout_event_candidates.py`
  - `data/processed/country_genre_analysis/breakout_event_candidate_audit.csv`
  - `data/processed/country_genre_analysis/breakout_event_candidate_audit.md`
  - `notes/26_breakout_candidate_audit.md`
- The audit now starts from the full chart-led top-10 treatment universe with live scene families
  and asks:
  - is the row the first breakout for `market x genre_family`?
  - does the event window show local same-genre starts?
  - is pre-shock focal capability non-flat in the city panel?
- Current retained first-breakout stack:
  - `deu_industrial_metal_2001_mutter`
  - `deu_symphonic_metal_2004_once`
  - `fin_symphonic_metal_2004_once`
  - `deu_power_metal_2012_carolus_rex`
- Current parked rows:
  - taxonomy-incompatible conceptual rows:
    - the `Sepultura - Roots` `extreme_metal` cases
  - first-breakout but flat-capability rows:
    - `aus_industrial_metal_2022_zeit`
    - `gbr_industrial_metal_2022_zeit`
    - `swe_power_metal_2022_the_war_to_end_all_wars`
  - later repeats rather than first breakouts:
    - `deu_power_metal_2016_the_last_stand`
    - `deu_power_metal_2018_the_sacrament_of_sin`
- Updated the operational event file:
  - `data/processed/country_genre_analysis/breakout_event_file.csv`
  - rebuilt:
    - `city_genre_breakout_event_panel.csv`
    - `city_genre_breakout_capability.csv`
    - `breakout_branch_panel_summary.md`
- Corrected four-event branch read:
  - retained events: `4`
  - event-window years with focal starts:
    - industrial Germany 2001: `8`
    - symphonic Germany 2004: `16`
    - symphonic Finland 2004: `13`
    - power Germany 2012: `76`
  - positive-capability cities at `t = -1`:
    - industrial Germany 2001: `3`
    - symphonic Germany 2004: `4`
    - symphonic Finland 2004: `3`
    - power Germany 2012: `49`
- Then ran the explicit descriptive gate before any event-study regression:
  - added `code/74_build_breakout_branch_descriptive_summary.py`
  - wrote:
    - `breakout_branch_descriptive_event_time.csv`
    - `breakout_branch_descriptive_event_summary.csv`
    - `breakout_branch_descriptive_summary.md`
- Current descriptive read:
  - positive-capability city-event cells at `t = -1`: `49`
  - zero-capability city-event cells at `t = -1`: `7,186`
  - pre-period mean local same-genre band starts:
    - positive capability: `0.0571`
    - zero capability: `0.0007`
  - post-period mean local same-genre band starts:
    - positive capability: `0.0408`
    - zero capability: `0.0010`
  - dominant positive-capability event:
    - `deu_power_metal_2012_carolus_rex` with `39` positive-capability cities
- Practical implication:
  - the branch is now cleaner and more honest
  - but it has **not** cleared the descriptive gate for event-study estimation
  - the live next decision is now binary:
    - add more first-breakout events with non-flat pre-shock capability
    - or stop the branch at feasibility stage

---

### Session: 2026-04-09 (breakout relaxed peak-20 extension)
- Kept pushing on the breakout-demand branch after the strict top-10 first-breakout stack proved
  too thin.
- Generalized the branch scripts so they can be reused on alternate event files instead of only on
  the strict default objects:
  - `code/72_build_breakout_event_panel.py` now accepts input and output paths
  - `code/73_audit_breakout_event_candidates.py` now accepts a chart cutoff, top-10 toggle, and
    custom output paths
  - `code/74_build_breakout_branch_descriptive_summary.py` now accepts input and output paths
- Built a secondary relaxed branch screen using:
  - live scene-panel genre families
  - non-`heavy_metal` rows
  - dated chart-entry rows
  - peak position `<= 20` rather than top `10`
- Wrote the relaxed branch objects:
  - `data/processed/country_genre_analysis/breakout_event_candidate_audit_peak20.csv`
  - `data/processed/country_genre_analysis/breakout_event_candidate_audit_peak20.md`
  - `data/processed/country_genre_analysis/breakout_event_file_peak20_relaxed.csv`
  - `data/processed/country_genre_analysis/city_genre_breakout_event_panel_peak20_relaxed.csv`
  - `data/processed/country_genre_analysis/city_genre_breakout_capability_peak20_relaxed.csv`
  - `data/processed/country_genre_analysis/breakout_branch_panel_summary_peak20_relaxed.md`
  - `data/processed/country_genre_analysis/breakout_branch_descriptive_event_time_peak20_relaxed.csv`
  - `data/processed/country_genre_analysis/breakout_branch_descriptive_event_summary_peak20_relaxed.csv`
  - `data/processed/country_genre_analysis/breakout_branch_descriptive_summary_peak20_relaxed.md`
  - note: `notes/27_breakout_peak20_relaxed_extension.md`
- Relaxed retained first-breakout rows:
  - `deu_industrial_metal_2001_mutter`
  - `ita_power_metal_2002_power_of_the_dragonflame`
  - `deu_symphonic_metal_2004_once`
  - `fin_symphonic_metal_2004_once`
  - `ita_symphonic_metal_2007_dark_passion_play`
  - `deu_power_metal_2012_carolus_rex`
  - `gbr_power_metal_2016_the_last_stand`
  - `ita_gothic_metal_2016_delirium`
- Relaxed branch read:
  - retained events rise from `4` to `8`
  - positive-capability city-event cells at `t = -1` rise from `49` to `123`
  - zero-capability city-event cells rise from `7,186` to `11,000`
  - pre-period same-genre band starts remain much higher in positive-capability cities:
    - positive capability: `0.1024`
    - zero capability: `0.0013`
  - post-period same-genre band starts:
    - positive capability: `0.0691`
    - zero capability: `0.0018`
  - `deu_power_metal_2012_carolus_rex` remains the single biggest contributor to the
    positive-capability margin
- Practical implication:
  - the branch is not exhausted under the current treatment build
  - but even the relaxed peak-20 extension still does **not** clear the descriptive gate for
    event-study estimation
  - the current best read is now:
    - strict branch: too thin
    - relaxed branch: larger and more informative, but still descriptively weak
    - next real move, if any, is to search for more first-breakout rows with non-flat pre-shock
      capability rather than to run the event study

---

### Session: 2026-04-09 (branch sweep and recovery targets)
- Added a systematic screen sweep rather than eyeballing one relaxed branch at a time:
  - `code/75_sweep_breakout_branch_screens.py`
  - outputs:
    - `data/processed/country_genre_analysis/breakout_branch_screen_sweep.csv`
    - `data/processed/country_genre_analysis/breakout_branch_screen_sweep.md`
- Current sweep read across:
  - `top10`
  - `peak15`
  - `peak20`
  - `peak25`
  - `peak30`
- Sweep result:
  - best support comes from `peak20`
  - widening beyond `peak20` does not add retained events under the current operational rule
  - no chart cutoff in the current treatment build solves the pretrend problem
- Then moved from screen design to recovery targets:
  - added `code/76_build_breakout_expansion_targets.py`
  - wrote:
    - `data/processed/country_genre_analysis/breakout_seed_recovery_targets.csv`
    - `data/processed/country_genre_analysis/breakout_seed_recovery_targets.md`
  - added note:
    - `notes/28_breakout_seed_recovery_targets.md`
- The target logic now asks:
  - which live-family home-market seeds are missing or weakly recovered
  - and which of those would actually change the relaxed first-breakout set if recovered
- Current highest-value recovery targets:
  - `Lacuna Coil - Comalies` (`ITA`, `gothic_metal`, `2002`)
    - would replace the current relaxed Italian gothic first breakout
    - provisional positive-capability cities: `30`
    - source path: `FIMI` (`low` difficulty)
  - `Angra - Rebirth` (`BRA`, `power_metal`, `2001`)
    - would add a Brazilian power-metal home-market first breakout
    - provisional positive-capability cities: `35`
    - source path: Brazil mixed manual supplement (`high` difficulty)
  - `Angra - Temple of Shadows` (`BRA`, `power_metal`, `2004`)
    - same branch contribution logic as above
    - provisional positive-capability cities: `39`
  - `Sabaton - Carolus Rex` (`SWE`, `power_metal`, `2012`)
    - would add a Swedish power-metal home-market first breakout
    - provisional positive-capability cities: `17`
    - source path: `Sverigetopplistan` (`medium` difficulty)
- Practical implication:
  - the branch now has a concrete next-step map
  - the right next recovery order is:
    1. `Comalies`
    2. `Carolus Rex`
    3. `Rebirth`
    4. `Temple of Shadows`
  - if those do not move, the branch should probably stay at feasibility stage

---

### Session: 2026-04-09 (Karmacode recovery and branch rebuild)
- Reopened the Italian gothic-metal branch after probing the live FIMI archive directly.
- Confirmed that `Lacuna Coil - Comalies` still shows zero official chart and zero certification
  rows on the current FIMI title page, so the original dead-end read remains correct for that
  album.
- Found a better official Italian gothic-metal row in the same source environment:
  - `Lacuna Coil - Karmacode`
  - exact official FIMI recovery:
    - entry week: `W14-2006`
    - peak: `17`
    - maximum observed run length: `20` weeks
- Promoted that recovery into the live treatment build:
  - added `lacuna_coil_karmacode_2006` to `data/blockbuster_album_seed.csv`
  - updated `data/README.md`
  - rebuilt `code/03_build_core_treatment_panel.py`
- The rebuilt core treatment file now includes:
  - `ITA` home-market row for `Karmacode`
  - `GBR` foreign-market row for `Karmacode`
- Rebuilt the relaxed branch from the updated core:
  - reran `code/73_audit_breakout_event_candidates.py` with `peak <= 20`
  - reran `code/72_build_breakout_event_panel.py`
  - reran `code/74_build_breakout_branch_descriptive_summary.py`
  - reran `code/75_sweep_breakout_branch_screens.py`
  - reran `code/76_build_breakout_expansion_targets.py`
- The relaxed retained stack changed materially:
  - `ita_gothic_metal_2016_delirium` dropped to a later repeat
  - `ita_gothic_metal_2006_karmacode` is now the retained Italian gothic-metal first breakout
- Updated relaxed-branch read:
  - retained events remain `8`
  - positive-capability city-event cells at `t = -1` rise from `123` to `139`
  - zero-capability city-event cells become `10,984`
  - pre-period same-genre starts worsen rather than improve:
    - positive capability: `0.1295`
    - zero capability: `0.0013`
  - post-period same-genre starts:
    - positive capability: `0.0755`
    - zero capability: `0.0022`
  - `deu_power_metal_2012_carolus_rex` still dominates the positive-capability margin with `39`
    cities
- Event-specific implication:
  - `Karmacode` improves support and historical plausibility for the Italian gothic-metal slot
  - but it makes the descriptive pretrend problem more visible, not less
  - so the branch is still not regression-ready
- Updated notes and trackers:
  - `notes/27_breakout_peak20_relaxed_extension.md`
  - `notes/28_breakout_seed_recovery_targets.md`
  - `notes/05_research_plan.md`
  - `STATUS.md`
- Updated recovery-target interpretation:
  - `Comalies` remains a real high-priority target
  - but it is now an **earlier-than-Karmacode** recovery target, not the only usable Italian
    gothic-metal row
  - Sweden and Brazil remain the next serious expansion margins after that

---

### Session: 2026-04-09 (Swedish Carolus Rex recovery and second branch rebuild)
- Pushed the next recovery target immediately after the Italian fix instead of stopping at
  `Karmacode`.
- Probed the official Sverigetopplistan weekly album pages directly and confirmed that the public
  chart page plus hidden item-stat endpoint are enough to recover exact Swedish home-market timing.
- Recovered `Sabaton - Carolus Rex` from official Swedish sources:
  - first placement: `W22-2012`
  - peak: `2`
  - run length: `31` weeks
- Added that row to `data/blockbuster_album_country_hits_swe_manual.csv` and updated
  `data/README.md` to reflect the live Swedish manual supplement.
- Rebuilt the core treatment workflow:
  - `code/03_build_core_treatment_panel.py`
  - core rows rise from `94` to `95`
  - home-market top-10 rows rise from `12` to `13`
- Rebuilt the branch objects again:
  - `code/73_audit_breakout_event_candidates.py`
  - `code/72_build_breakout_event_panel.py`
  - `code/74_build_breakout_branch_descriptive_summary.py`
  - `code/75_sweep_breakout_branch_screens.py`
  - `code/76_build_breakout_expansion_targets.py`
- The strict top-10 stack now improves from `4` to `5` retained events:
  - added `swe_power_metal_2012_carolus_rex`
  - positive-capability city-event cells at `t = -1` rise from `49` to `63`
  - zero-capability city-event cells rise from `7,186` to `7,640`
  - pre-period same-genre starts:
    - positive capability: `0.0444`
    - zero capability: `0.0011`
- The relaxed peak-20 stack now improves from `8` to `9` retained events:
  - `swe_power_metal_2012_carolus_rex` joins the already-updated `Karmacode` stack
  - positive-capability city-event cells at `t = -1` rise from `139` to `153`
  - zero-capability city-event cells rise from `10,984` to `11,438`
  - pre-period same-genre starts move to:
    - positive capability: `0.1176`
    - zero capability: `0.0015`
  - post-period same-genre starts move to:
    - positive capability: `0.0730`
    - zero capability: `0.0024`
- Event-specific read:
  - the Swedish row is relatively clean descriptively:
    - positive-capability cities: `14`
    - pre-period same-genre starts: `0.0000`
    - post-period same-genre starts: `0.0476`
  - but the branch still fails overall because the total treated margin remains thin and the stack
    is still partly dominated by `deu_power_metal_2012_carolus_rex`
- Updated branch documents to match the new state:
  - `notes/24_breakout_episode_screen.md`
  - `notes/25_breakout_branch_workflow.md`
  - `notes/27_breakout_peak20_relaxed_extension.md`
  - `notes/28_breakout_seed_recovery_targets.md`
  - `notes/05_research_plan.md`
  - `STATUS.md`
- Also fixed the generated-summary wording in `code/76_build_breakout_expansion_targets.py` so the
  markdown target file now reflects the actual remaining shortlist instead of hard-coding Sweden as
  unresolved.
- New practical read:
  - Italy and Sweden are now materially cleaner than they were at the start of the day
  - the next unresolved recovery margin is basically:
    1. `Comalies`
    2. `Rebirth`
    3. `Temple of Shadows`
  - but even after the Swedish fix, the branch remains a feasibility object, not a regression-ready
    causal design

---

### Session: 2026-04-09 (Brazil source-quality and timing upgrades)
- Reopened the Brazil source-quality margin without changing the branch estimand or workflow.
- Confirmed again that direct Pro-Music Brasil retrieval is still blocked in this environment:
  repeated requests to certificate pages continue to fail with connection resets or remote
  disconnects.
- Extracted text from official Aquiles Priester press PDFs and recovered a stronger source for
  `Angra - Rebirth`:
  - `https://aquilespriester.com/site/wp-content/uploads/2019/02/AQUILES-PRIESTER-Biografia-Oficial-Imprensa-2019.pdf`
  - the official bio explicitly states that `Rebirth` "foi certificado Disco de Ouro no Brasil"
- Then pushed the timing margin further by following the journalistic trail:
  - `https://whiplash.net/materias/news_964/011035-angra.html`
  - Whiplash reports on `2001-12-17` that the gold award had been delivered during the Sao Paulo
    show on `2001-12-15`
  - the live row now uses an observed December `2001` certification timing rather than only the
    release year
- Recovered a stronger source for `Angra - Temple of Shadows` as well:
  - followed the Wikipedia citation trail to the archived `Epoca` page:
    `https://web.archive.org/web/20110212200159/http://revistaepoca.globo.com/Epoca/0,6993,EPT1073675-1655,00.html`
  - the archived page is titled `Lista dos 50 CDs mais vendidos na semana`
  - it records publication on `2005-11-17` and lists `Angra - Temple Of Shadows` at number `10`
    for the period `2005-11-08` to `2005-11-15`
- Updated the live Brazil manual supplement:
  - `data/blockbuster_album_country_hits_bra_manual.csv`
  - `Angra - Rebirth` now uses a dated Whiplash certification-timing report, with the official
    artist bio retained as corroboration in the notes
  - `Angra - Temple of Shadows` now uses the archived `Epoca` chart page rather than a generic
    Wikipedia row or the intermediate BraveWords bridge
- Updated the branch notes and trackers:
  - `data/README.md`
  - `notes/04_empirical_notes.md`
  - `notes/28_breakout_seed_recovery_targets.md`
  - `STATUS.md`
- Rebuilt the core treatment outputs:
  - `code/03_build_core_treatment_panel.py`
  - `data/processed/blockbuster_album_country_hits_core.csv`
  - `data/processed/blockbuster_country_year_hit_panel.csv`
  - `data/processed/blockbuster_country_year_hit_summary.md`
- Practical implication:
  - `Rebirth` is no longer weak on certification existence or basic timing; it now has an observed
    December `2001` gold-award date, though still not a chart-entry date
  - `Temple of Shadows` is no longer just a vague release-year placeholder in the country-year
    panel; it now lands as an observed Brazil home-market top-10 hit in `2005` backed by an
    archived weekly chart page
  - the breakout-event stack is still unchanged because neither Brazilian row has an exact
    chart-entry week or date suitable for the stacked first-breakout workflow

---

### Session: 2026-04-10 (central-musician-loss recovery expansion to 20 verified deaths)
- Continued the central-musician-loss feasibility branch with a deeper recovery workflow rather
  than a shallow obituary pass.
- Extended `code/77_build_central_loss_audit_shortlist.py` so the shortlist builder can now:
  - allow blank `last_year_in_band` values
  - require no current memberships when desired
  - write alternate recovery outputs via suffixes
- Generated and audited multiple recovery margins:
  - `central_loss_audit_shortlist_recovery.csv`
  - `central_loss_audit_shortlist_recovery3.csv`
  - `central_loss_audit_shortlist_recovery_loose.csv`
  - `central_loss_audit_shortlist_recovery_anycurrent.csv`
- Expanded the manual audit ledger materially:
  - `20` `death_verified`
  - `60` `not_loss_or_false_positive`
  - `14` `unresolved`
  - `2` `possible_permanent_exit`
- Expanded the clean death-event object:
  - `data/processed/scene_networks/central_loss_verified_death_events.csv`
  - now `20` verified deaths
- New verified deaths added during the recovery pass include:
  - `Ivo Rocha`
  - `Apollyon Baphomet`
  - `Franco Crucifixion`
  - `Azizi`
  - `Warwolf`
  - `Sergey Bokarev`
  - `Micha Laska`
  - `Doomicus Stardust`
- Rebuilt the event preview:
  - `data/processed/scene_networks/central_loss_event_preview.csv`
  - `data/processed/scene_networks/central_loss_event_window_preview.csv`
  - `data/processed/scene_networks/central_loss_event_preview_summary.md`
- Current preview read:
  - verified death events: `20`
  - events with `3+` pre years, event year, and `1+` post year: `9`
  - emergence timing:
    - `18` `post_emergence`
    - `2` `no_emergence_record`
- Practical implication:
  - the branch is now clearly past pure idea stage
  - but the real bottleneck is no longer raw death count
  - it is usable post window and the fact that almost all verified deaths are already
    post-emergence
  - so the design still looks more plausible for post-emergence scene activity than for scene
    emergence itself

---

### Session: 2026-04-10 (central-loss frontier exhaustion and first post-emergence read)
- Fully audited the `any-current` recovery shortlist:
  - remaining open cases in that margin are now `0`
  - the obituary workflow leaves:
    - `20` `death_verified`
    - `105` `not_loss_or_false_positive`
    - `2` `possible_permanent_exit`
    - `9` `unresolved`
- The remaining unresolved names are now:
  - `Wizard`
  - `Domjan Laszlo`
  - `Roger Stachow`
  - `Marcelo Bartolozzi`
  - `Eliud Tamez`
  - `Andrey Kapachev`
  - `Sinister`
  - `Dawidek`
  - `Q_Snc`
- Practical implication:
  - the search frontier is now largely exhausted under the current conservative standard
  - the remaining uncertainty is identity quality and weak memorial surface, not an obviously rich
    hidden pool of death events
- Built the first descriptive post-emergence outcome object:
  - `code/79_build_central_loss_post_emergence_summary.py`
  - `data/processed/scene_networks/central_loss_post_emergence_event_window.csv`
  - `data/processed/scene_networks/central_loss_post_emergence_relative_year_summary.csv`
  - `data/processed/scene_networks/central_loss_post_emergence_summary.md`
- Current descriptive read from the `9` usable post-emergence events:
  - focal same-genre active-band stock rises from `70.630` in years `-3` to `-1` to `79.500` in
    years `0` to `+1`
  - focal same-genre multi-band musicians rise from `28.333` to `31.222`
  - city total band starts soften slightly from `24.407` to `23.500`
  - city spawning flow rises slightly from `12.815` to `13.833`
  - city spawning share rises from `0.536` to `0.632`
- Practical implication:
  - the branch now has a real outcome read, not only an event ledger
  - but the current descriptive pattern does not support a simple collapse narrative after central
    deaths
  - if the branch continues, it needs a tighter post-emergence estimand rather than more obituary
    search by default

---

### Session: 2026-04-13 (breakout branch re-entry check on the highest-payoff target)
- Reopened the highest-chance causal side branch through the documented top recovery target:
  `Lacuna Coil - Comalies` in `ITA x gothic_metal x 2002`.
- Ran a fresh direct pass against the live official FIMI query path:
  - `https://www.fimi.it/top-of-the-music/music/?artist=LACUNA+COIL&title=COMALIES`
  - result still shows `IN CLASSIFICA (0)` and `CERTIFICAZIONI (0)`
  - by contrast, the same archive path still resolves `Karmacode`, so this does not look like a
    generic FIMI outage
- Practical implication:
  - `Comalies` remains blocked under the current official archive workflow
  - the breakout branch is still not ready to leave feasibility stage
  - if the branch is pushed again, the active next recovery targets are now:
    - `Angra - Rebirth`
    - `Angra - Temple of Shadows`
  - another Italy retry under the same direct FIMI path is probably low value unless a new source
    path appears
- Updated:
  - `notes/28_breakout_seed_recovery_targets.md`
  - `notes/29_breakout_branch_parking_memo.md`
  - `data/processed/country_genre_analysis/breakout_seed_recovery_targets.csv`

- Continued immediately to the next live Brazil targets.
- Fresh Pro-Música Brasil check:
  - `https://pro-musicabr.org.br/home/certificados/?busca_artista=Angra`
  - current live search returns `0 resultados`
  - a sanity check on `Tihuana` returns `2 resultados`, so this does not look like a generic site
    failure
- Practical implication:
  - `Angra - Rebirth` remains blocked on the live official certificate route
  - `Angra - Temple of Shadows` is now the stronger active Brazil row because it still has:
    - the archived `Epoca` top-10 chart window
    - a BraveWords relay of an official Angra website update reporting the same result
  - the active breakout recovery order is now:
    - `Temple of Shadows`
    - `Rebirth`
    - `Comalies` only if a genuinely new Italy source path appears

---

### Session: 2026-04-13 (targeted follow-up on remaining central-loss unresolved names)
- Ran one more bounded search pass on the remaining obituary-side unresolved names instead of
  reopening a broad death search.
- Reclassified three names into `not_loss_or_false_positive`:
  - `Domjan Laszlo`
    Metal Archives still lists him under an active band (`Soul Terror`), with no RIP marker.
  - `Eliud Tamez`
    Metal Archives gives a birth date, current age, and present-tense affiliation, with no RIP
    marker.
  - `Q_Snc`
    Metal Archives lists Vassilis "Q-Snc" in current bands and on later credits through `2022`.
- The obituary workflow now leaves:
  - `20` `death_verified`
  - `108` `not_loss_or_false_positive`
  - `2` `possible_permanent_exit`
  - `6` `unresolved`
- The remaining unresolved names are now:
  - `Wizard`
  - `Roger Stachow`
  - `Marcelo Bartolozzi`
  - `Andrey Kapachev`
  - `Sinister`
  - `Dawidek`
- Practical implication:
  - the search frontier now looks even thinner than it did on April 10
  - another broad obituary hunt is probably not the best use of time
  - the higher-value next move is robustness on the existing `9` usable post-emergence death
    windows

---

### Session: 2026-04-10 (matched-control prototype for central-loss branch)
- Built the first matched-control descriptive prototype:
  - `code/81_build_central_loss_matched_control_prototype.py`
  - `data/processed/scene_networks/central_loss_matched_controls.csv`
  - `data/processed/scene_networks/central_loss_matched_relative_year_summary.csv`
  - `data/processed/scene_networks/central_loss_matched_event_comparison.csv`
  - `data/processed/scene_networks/central_loss_matched_control_summary.md`
- Design:
  - keep the `9` post-emergence deaths with usable short windows
  - match each treated event to `3` same-genre control cities using pre-event focal band starts,
    focal active-band stock, and focal multi-band depth
  - exclude nearby death events in the matched control cells
- Main descriptive read:
  - average DID-style change in focal same-genre band starts: `-0.932`
  - `6` of `9` event-level focal-start DID deltas are negative
  - average DID-style change in city-wide spawning flow: `0.784`
  - so the negative margin shows up more clearly in focal same-genre entry than in broad
    city-wide spawning
- Practical implication:
  - the branch now has a clearer live estimand
  - if it continues, the right target is post-death suppression of focal same-genre entry
  - not a broad scene-collapse narrative

---

### Session: 2026-04-13 (Temple of Shadows enters the live breakout stack)
- Promoted `Angra - Temple of Shadows` from a dated Brazil country-year row into the live breakout
  branch by filling `entry_date = 2005-11-17` in
  `data/blockbuster_album_country_hits_bra_manual.csv`.
- The timing choice is conservative rather than aggressive:
  - it uses the archived `Epoca` page publication date already documented in the notes
  - it does **not** claim a cleaner direct ABPD / Pro-Musica chart-entry week than the source
    actually provides
- Rebuilt the treatment and breakout objects:
  - `code/03_build_core_treatment_panel.py`
  - `code/73_audit_breakout_event_candidates.py`
  - `code/72_build_breakout_event_panel.py`
  - `code/74_build_breakout_branch_descriptive_summary.py`
  - `code/76_build_breakout_expansion_targets.py`
  - plus the strict and `peak20` parallel output files in
    `data/processed/country_genre_analysis/`
- Main branch effect:
  - strict top-10 retained stack rises from `5` to `6`
  - strict positive-capability city-event cells at `t = -1` rise from `63` to `97`
  - relaxed peak-20 retained stack rises from `9` to `10`
  - relaxed positive-capability city-event cells at `t = -1` rise from `153` to `187`
  - `Temple of Shadows` enters as `bra_power_metal_2005_temple_of_shadows`
  - live audit support for that row:
    - `positive_capability_cities = 39`
    - `years_with_genre_starts = 117`
- Interpretation:
  - the breakout branch is materially stronger than it was before this pass
  - Brazil is no longer only a recovery frontier; it now contributes a live retained event
  - but the branch still fails the descriptive gate because pre-period differences remain large
    and the margin is still partly driven by `DEU x power_metal x 2012`
- Practical next-target map after this promotion:
  - `Rebirth` is now the main Brazil target because it could move the retained Brazil power-metal
    breakout earlier from `2005` to `2001`
  - `Comalies` remains the main Italy target, but still looks like an official FIMI dead end
  - `Temple of Shadows` stays on the machine-generated target list only as a timing-refinement
    target, not as a missing retained-event target
- Updated notes and trackers:
  - `notes/27_breakout_peak20_relaxed_extension.md`
  - `notes/28_breakout_seed_recovery_targets.md`
  - `notes/29_breakout_branch_parking_memo.md`
  - `STATUS.md`

---

### Session: 2026-04-14 (Rebirth upgraded to archived official-source certification timing)
- Reopened the highest-value remaining Brazil recovery target, `Angra - Rebirth`, and pushed the
  official-site archive path rather than stopping at the older journalistic fallback.
- Recovered a stronger archived official Angra-site source environment:
  - `https://web.archive.org/web/20011226084243/http://www.angra.net/rebirth.asp`
  - `https://web.archive.org/web/20011212163756/http://www.angra.net/news.asp`
- Main source findings:
  - the archived `Rebirth` page reports on `2001-12-20` that Angra had received a gold record in
    Brazil only `45` days after the launch of `Rebirth`
  - the archived `news.asp` page also contains the `2001-09-15` album announcement with world
    release marked for `2001-10-29`
  - the same official news page includes a `2001-11-26` post-launch press note for `Rebirth`
- Practical interpretation:
  - `Rebirth` now has a better source-quality certification timing anchor than the older
    `Whiplash`-plus-bio path
  - but it still does **not** become a chart-entry breakout event, because no real Brazil chart
    table or direct official chart-entry object was recovered
- Rebuilt the relevant treatment and breakout files:
  - `code/03_build_core_treatment_panel.py`
  - `code/73_audit_breakout_event_candidates.py`
  - `code/72_build_breakout_event_panel.py`
  - `code/74_build_breakout_branch_descriptive_summary.py`
  - `code/76_build_breakout_expansion_targets.py`
- Post-rebuild branch implication:
  - the strict retained breakout stack stays at `6` events
  - positive-capability city-event cells at `t = -1` stay at `97`
  - `Rebirth` upgrades the source quality of the core treatment file, but not the event-study
    feasibility verdict
- Applied the source-quality upgrade to:
  - `data/blockbuster_album_country_hits_bra_manual.csv`
  - `notes/04_empirical_notes.md`
  - `notes/28_breakout_seed_recovery_targets.md`
  - `notes/29_breakout_branch_parking_memo.md`
  - `STATUS.md`

---

### Session: 2026-04-14 (main-result niche-specificity strengthening pass)
- Switched back to the main `scene -> genre emergence` paper and took the most bounded remaining
  strengthening move on the live result rather than reopening side branches.
- Extended the threshold-response workflow in `code/70_build_scene_threshold_response.py` with a
  sharper falsification-style check:
  - keep the preferred fifth-band FE structure
  - add target-genre active musicians
  - add a residual outside-focal multi-band margin constructed as city-wide multi-band musicians
    minus focal same-genre multi-band musicians, clipped at zero
- Important implementation fix:
  - first pass at the new residual margin accidentally rolled the variable only after the risk-set
    filter, which shrank the sample too much
  - corrected the code so the residual outside-focal overlap variable is rolled on the full merged
    panel before the preferred at-risk filter, matching the rest of the workflow
- Final empirical read from the strengthened specificity package:
  - in the active-pool check, target-genre multi-band musicians stay positive at `0.0121` while
    target-genre active musicians are `-0.1049`
  - in the sharper outside-focal check, target-genre multi-band musicians stay positive at
    `0.0114` while the residual outside-focal multi-band margin is `-0.0129`
  - this strengthens the interpretation that the overlap margin is niche-specific rather than a
    generic city-wide overlap proxy
- Rebuilt:
  - `code/70_build_scene_threshold_response.py`
  - `data/processed/scene_networks/scene_threshold_response_results.csv`
  - `data/processed/scene_networks/scene_threshold_response_summary.md`
- Folded the stronger result into the live paper draft:
  - `drafts/metal.tex`
  - `drafts/sections/introduction.tex`
  - `drafts/sections/results.tex`
  - `drafts/sections/appendix.tex`
  - `drafts/tables/appendix_threshold_specificity.tex`
- Verification:
  - `latexmk -pdf -interaction=nonstopmode -halt-on-error metal.tex` succeeded
  - the updated draft compiles cleanly to `drafts/metal.pdf`

---

### Session: 2026-04-14 (final referee-style stabilization pass)
- Ran the promised final referee-style read on the live draft with the goal of compressing and
  disciplining the paper rather than finding new results.
- Main referee-style fixes applied:
  - clarified in `drafts/sections/method.tex` why the live specification clusters standard errors
    by city: the dependence concern is city-level serial and cross-genre correlation from shared
    local shocks
  - softened the opening of `drafts/sections/data.tex` so the paper no longer overstates the
    Metal Archives universe as a literally complete census of all metal activity
  - tightened `drafts/sections/results.tex` so the main coefficient comparison is between
    focal-niche thickness and broader city-level stock terms, not a loose `city size` shorthand
- Verification:
  - reran `latexmk -pdf -interaction=nonstopmode -halt-on-error metal.tex`
  - `drafts/metal.pdf` rebuilt cleanly after the stabilization edits
- Practical read after this pass:
  - the draft now looks more like a stable field-journal paper than an expanding working memo
  - the highest-value next move is a final rendered-PDF stop check, not another empirical branch

---

### Session: 2026-04-14 (field-journal stop-or-stabilize memo written)
- Added `referee/field_journal_stop_or_stabilize_memo.md`.
- Purpose:
  - put the current referee-style stop recommendation into a concrete project note rather than
    leave it only in chat or implicit in `STATUS.md`
- Memo verdict:
  - `Stabilize`
- Main practical rule recorded there:
  - if the rendered PDF does not reveal a new overclaim, confusing caption, or obvious excess
    paragraph, stop and do not reopen exploratory branches

---

### Session: 2026-04-24 (causal-channel reassessment)
- Reopened the causal-channel question after the deaths, breakout, broadband, and main-result
  strengthening passes.
- Added `notes/31_causal_channel_reassessment.md`.
- Main conclusion:
  - do not put more effort into broad death searching or breakout chart recovery by default
  - the best new causal follow-on candidate is experienced outside-musician arrivals into
    subthreshold local `city x genre` cells
- Quick feasibility scans run on live processed data:
  - band split, changed-name, or on-hold rows with inferred end years: `52,723`
  - distinct band-ending `city x genre x year` cells: `46,716`
  - cross-city experienced member-band-genre arrival rows: `145,798`
  - cross-city experienced-arrival `city x genre x year` cells within five years before observed
    emergence: `3,763`
  - stricter cross-country experienced-arrival `city x genre x year` cells within five years before
    observed emergence: `479`
  - post-socialist emergence cells excluding Germany: `692`, with `58` in `1989-1994` and `107` in
    `1995-2000`
- Ranking after the reread:
  - first causal audit to try: experienced outside-musician arrivals
  - cheap secondary probe: global digital platform timing interacted with pre-digital isolation
    and capability
  - interesting separate paper idea: post-socialist cultural or market opening
  - mechanism-only sidecar: band dissolution and spinouts
  - parked unless better timing data appear: historical label shocks, venues, festivals, studios,
    and touring infrastructure
- Practical implication:
  - the stabilized main paper should remain closed for now
  - the next causal branch, if pursued, should start with an arrival event file and a tight
    pre-trend/mechanical-counting audit

---

### Session: 2026-04-24 (external-arrival first pass)
- Built the first operational experienced outside-musician arrival workflow:
  - `code/83_build_external_arrival_event_study.py`
  - `code/84_build_external_arrival_matched_control.py`
- Output files:
  - `data/processed/scene_networks/external_arrival_events.csv`
  - `data/processed/scene_networks/external_arrival_event_windows.csv`
  - `data/processed/scene_networks/external_arrival_relative_year_summary.csv`
  - `data/processed/scene_networks/external_arrival_event_study_summary.md`
  - `data/processed/scene_networks/external_arrival_matched_controls.csv`
  - `data/processed/scene_networks/external_arrival_matched_event_comparison.csv`
  - `data/processed/scene_networks/external_arrival_matched_control_summary.md`
- Added `notes/32_external_arrival_first_pass.md`.
- Operational definition:
  - the data do not observe literal migration
  - the event is first observed membership in a local `city x genre` cell after strictly earlier
    band experience in another city or country
- Event-count read:
  - all cell-level first-arrival events across four definitions: `55,183`
  - analysis-sample events:
    - `cross_city_any`: `2,269`
    - `cross_city_same_genre`: `1,383`
    - `cross_country_any`: `456`
    - `cross_country_same_genre`: `212`
- Raw strict `cross_country_same_genre` event-window read:
  - local same-genre starts rise from `0.234` in years `-3` to `-1` to `0.500` in years `+1` to
    `+3`
  - `57.5` percent of strict events cross the operational emergence threshold within five years
- Matched-control strict read:
  - matched treated events: `184`
  - matched control rows: `780`
  - treated change in local same-genre starts: `0.199`
  - matched-control change: `0.100`
  - DID-style difference: `0.099`
  - share of event-level DID changes above zero: `0.489`
- Practical interpretation:
  - this is the best live causal follow-on candidate by event-count feasibility and mechanism fit
  - the first controlled read is positive on average but not decisive
  - next check should exclude the arriving musician's own band from the entry outcome and run a
    matched stacked event-study
