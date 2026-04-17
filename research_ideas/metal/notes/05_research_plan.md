# 05 Research plan

Last updated: 2026-04-10
Status: concise decision lock for the metal project

## Locked direction

- Main paper: `scene -> genre emergence`
- Active sidecar: `scene -> band success`
- Fallback: `domestic breakthrough shock -> later entry`

The live paper is an economics paper about creativity and innovation, using heavy metal as the
empirical laboratory.

## Locked headline result

The exact-year fixed-effects scene result should be centered on:

- local spawning flow
- target-genre active bands
- target-genre multi-band musicians

Broker or cross-genre connector language stays in the background only.

## Evidence status

- The scene-cluster panel is the main empirical spine and is strong enough for the paper.
- The threshold-response package now exists inside the paper draft:
  - under emergence cutoffs of `3`, `4`, `5`, `6`, and `8`, the three headline coefficients stay
    positive
  - but the pattern attenuates sharply once the sample is restricted to cells still far below the
    cutoff
  - the cleanest current read is therefore late-stage local niche consolidation rather than the
    earliest seed stage of scene formation
- The measurement-validation package now also exists inside the paper draft:
  - the preferred exact-year FE sample is already geography-clean on the current audit rule
  - dropping the small-dense labels, restricting to `1990` onward, and restricting to
    high-coverage countries all leave the three headline coefficients close to baseline
  - a short historical sanity table makes the operational scene dates for canonical cases broadly
    plausible while also making the geography screen legible through the excluded Bay Area row
- A new broad digital-era split check suggests some attenuation in local spawning flow and
  target-genre band stock after 2005, but target-genre multi-band musicians stay stable.
- The band-success sidecar is now mechanically real and materially wider, and its cleaner redesign
  is the upgrading-ladder cohort object rather than a naive birth regression.
- Even under that redesign, the current audited winner counts are still sparse enough that the
  sidecar remains secondary rather than draft-driving.
- The case-study network figure is still provisional and is currently parked rather than treated as
  the main bottleneck.
- An internal AER-style referee read now says the project is promising but not yet close to the
  AER bar:
  - the main objection is that the current result may be too close to a mechanical
    threshold-crossing fact
  - the second objection is that the paper is still too reduced-form and setting-specific for AER
  - the practical implication is to revise toward a strong field-journal paper by default unless a
    much stronger identification strategy appears
- A separate causal-follow-on strategy memo now exists:
  - if a quasi-causal branch is pursued, the first serious design should be a breakout-demand shock
    paper at the `city x genre_family` level rather than a rewrite of the live paper
  - the recommended design is a stacked event study around a small number of clean
    `country x genre_family` breakout episodes, with identification coming from differential
    response by pre-shock local capability within the treated country-genre
  - the branch has now been pushed through both:
    - a strict top-10 first-breakout screen
    - a relaxed peak-20 first-breakout extension
  - the practical read is now sharper:
    - strict screen: still too thin, but improved from `4` to `5` retained events after the
      Swedish `Carolus Rex` recovery
    - relaxed screen: now `9` retained events, anchored by `Lacuna Coil - Karmacode` rather than
      `Delirium`, but still fails the descriptive pre-trend gate
  - the final bounded recovery pass cleaned the branch but did not rescue it:
    - `Comalies` remains an official dead end under the current FIMI workflow
    - Brazil timing is materially cleaner for `Rebirth` and `Temple of Shadows`, but those rows
      still do not become chart-entry events usable in the stacked first-breakout design
  - so the branch is now parked as a feasibility object, not a regression-ready causal paper
  - reopen only if one of the explicit conditions in `notes/29_breakout_branch_parking_memo.md`
    is met:
    - recover an official or archive-clean chart-entry date for `Comalies`, `Rebirth`, or
      `Temple of Shadows`
    - add at least `3` additional first-breakout events with non-flat pre-shock capability
    - or change the design away from the current stacked first-breakout event-study requirement
  - the central-musician-loss idea remains the second-ranked mechanism audit
  - the first bounded feasibility pass now exists in `notes/30_central_musician_loss_first_pass.md`
  - current read from that pass:
    - the data can rank plausible local connectors and produce a precision-first shortlist
    - a capped fallback to the latest available pre-terminal scene snapshot materially improves the
      shortlist for late cases
    - targeted web audit now recovers multiple real deaths from the shortlist:
      `Kory Alvarez`, `Miguel Angel`, `L-G Petrov`, `Jasmine You`, `Eric Wagner`,
      `Nattdal`, `Andre Matos`, `Mortifer`, `Geoff Nicholls`, `Reverend Jim Forrester`,
      `Evgeny Reutov`, and `Sergey Stankov`
    - a first serious clean event object now exists:
      `data/processed/scene_networks/central_loss_verified_death_events.csv`
      with `20` verified deaths
    - a first expanded panel preview also exists:
      only `9` of those deaths have a minimally usable short post window in the live panel, and
      `18` of the `20` are already post-emergence
    - the broader recovery workflow has now been stress-tested:
      - the `any-current` recovery shortlist is fully audited and no longer contains open cases
      - the obituary workflow now leaves only `9` unresolved identity-heavy cases
      - so the search margin is largely exhausted under the current conservative standard
    - a first descriptive post-emergence summary now also exists:
      - focal same-genre stock continues to rise in the short window
      - city-wide total band starts soften slightly
      - city-wide spawning flow is roughly flat to slightly higher
      - so the branch now has a real outcome read, but not yet a simple negative-shock result
    - a first matched-control prototype now also exists:
      - each of the `9` usable post-emergence deaths is matched to `3` same-genre control cities
      - the average DID-style change in focal same-genre band starts is `-0.932`
      - `6` of `9` event-level focal-start DID deltas are negative
      - city-wide spawning flow does not show the same negative matched pattern
    - a first stacked fixed-effects prototype now also exists:
      - the stacked treated-by-post coefficient for focal same-genre band starts is `-0.932`
      - collapsing the duplicate `Warsaw x death_metal x 2013` shock-year still gives `-0.993`
      - the event-study path shows the sharpest dip in the event year itself (`t = -2.333`)
      - focal multi-band depth and city-wide spawning do not show the same negative treated-by-post pattern
    - so the most plausible estimand is now narrower:
      - post-death suppression of focal same-genre entry
      - not broad scene collapse
    - but the shortlist still generates obvious false positives and some possible permanent-exit
      cases, so external verification remains necessary before any estimation step
  - so this branch is alive and now has a real estimation prototype, but it is still a small-sample feasibility branch rather than a settled paper design
  - the current design read is now narrower:
    - not a plausible causal paper on scene emergence
    - maybe a plausible causal paper on post-emergence local scene activity

## What to write now

- The paper phase has started in `drafts/`.
- The LaTeX draft is now introduction-led rather than literature-led:
  - `drafts/sections/introduction.tex`
  - `drafts/metal.tex`
- The live LaTeX draft now also has an appendix section with:
  - full sample construction
  - full variable crosswalk
- The live LaTeX draft now also has threshold-response appendix tables and revised main-text
  interpretation for the mechanical-threshold objection.
- The live LaTeX draft now also has measurement-validation appendix tables and revised main-text
  interpretation for geography robustness and historical sanity checks.
- The exploratory internet and broadband material has now been pushed out of the main results
  section and into the appendix as background-only descriptive checks.
- The preferred table and surrounding text now explain coefficient scale explicitly:
  - the lagged predictors are z-scored
  - the three headline coefficients are now translated into percentage-point terms relative to the
    event rate
  - the negative overall multi-band control is now explained as a conditional niche-specificity
    result rather than as evidence against worker overlap
- A third referee-style read now says the paper has moved materially toward field-journal fit even
  though it remains far from the AER bar.
- The abstract and introduction have now been tightened again to match that field-journal read:
  - the opening now leads with local scene emergence in heavy metal rather than a broader category
    creation claim
  - the contributions are now stated more narrowly around the validated reduced-form result
- The literature review has now been shortened to the citation spine the paper actually uses.
- The empirical-motivation section has now also been compressed while keeping the three-figure
  setup:
  - the global proliferation figure still establishes setting scale
  - the subgenre tree stays, but no longer carries a long descendant-by-descendant walk-through
  - the black-metal map now reads more cleanly as spatial setup rather than as a second argument
- A clean field-journal positioning memo now exists in `referee/field_journal_positioning_memo.md`.
- The next writing phase is no longer generic polish. It is a referee-driven revision pass.
- Keep theory compact and downstream of the reduced-form facts.
- Use `predicts`, `tracks`, and `is associated with`, not causal overclaiming.
- Keep the paper scene-first and economics-first.
- Keep the theory object as local niche formation, not abstract network science.
- Default target:
  - revise toward a strong field-journal paper
  - do not write as if AER-level identification is already present

## Working files

- `README.md`
- `STATUS.md`
- `memory.md`
- `notes/03_model_notes.md`
- `notes/06_scene_paper_skeleton.md`
- `notes/08_scene_paper_sections.md`
- `drafts/metal.tex`
- `drafts/sections/data.tex`
- `drafts/sections/method.tex`
- `drafts/sections/results.tex`
- `drafts/sections/appendix.tex`
- `drafts/tables/sample_construction.tex`
- `drafts/tables/main_variables.tex`
- `drafts/tables/preferred_results.tex`
- `drafts/tables/appendix_threshold_response.tex`
- `drafts/tables/appendix_threshold_specificity.tex`
- `drafts/tables/appendix_measurement_validation.tex`
- `drafts/tables/appendix_historical_sanity.tex`
- `data/processed/scene_networks/scene_figure_roadmap.md`
- `data/processed/scene_networks/scene_threshold_response_summary.md`
- `data/processed/scene_networks/scene_measurement_validation_summary.md`
- `notes/09_band_success_workflow.md`
- `notes/11_band_upgrading_ladder.md`
- `notes/16_digital_era_split_probe.md`
- `referee/aer_referee_report.md`
- `referee/aer_revision_plan.md`

## Next 3 tasks

1. Treat field-journal positioning as the working default:
   the project now has a stable field-paper framing, so do not reopen exploratory branches unless
   they directly strengthen the bounded main result.
2. If one more revision pass is wanted, make it a final referee-style read:
   test whether the compressed draft now looks stable enough to stop rather than adding more
   material.
3. If the paper is ready to stabilize, use the field-journal memo as the live positioning note:
   keep further revisions consistent with that bounded contribution.
