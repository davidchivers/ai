# 05 Research plan

Last updated: 2026-02-26

---

## Chosen question and estimand

Primary question: how much of Michelin-cuisine idea adoption is explained by chef-network exposure, and does that channel induce measurable homogenization over time?

Primary estimand: diffusion elasticity $\beta$ from the idea-level hazard specification, where $\beta$ is the semi-structural effect of lagged network exposure on adoption probability.

Secondary question: do Michelin recognition events change innovation-conformity behavior?

Secondary estimand: event-time coefficients $\{\beta_k\}$ around star gain/loss in stacked DiD/event-study designs.

## Chosen models

Model 1 from `03_model_notes.md` (prestige-weighted network diffusion) is the core framework.

Model 2 from `03_model_notes.md` (innovation vs conformity under status tournament incentives) is the strategic layer for mechanism interpretation.

Model 3 is retained as an extension for attention shocks once the first-wave data pipeline is stable.

## Chosen empirical strategies

Primary design: Strategy 1 from `04_empirical_notes.md` (chef-move event study).

Co-primary mechanism design: Strategy 2 from `04_empirical_notes.md` (idea-level hazard with network exposure).

Triangulation design: Strategy 3 from `04_empirical_notes.md` (star transition stacked DiD).

## Design lock criteria

Lock the primary design if:
1. Restaurant and chef identifiers are consistent enough to build a stable panel and network.
2. Novelty/homogenization measures validate against hand-coded checks in expected direction.
3. Event-study pre-trends are approximately flat in the chef-move design.

Pivot sequence if not:
1. If network quality is weak, prioritize star-transition DiD first.
2. If image coverage is sparse, run text-only baseline and add fused index later.
3. If attention-shock data are noisy, defer Strategy 4 to extension stage.

## Data access stance

First-wave pipeline uses public and permissioned sources only:
- Michelin public pages and archives.
- Wayback snapshots for historical menus/galleries.
- Wikidata plus manual verification for chef career links.
- Permissioned review APIs where needed.

No broad social-platform scraping in first-wave execution.

## Next 3 tasks

1. Finalize scope choices: geography, start year, innovation unit.
2. Build the minimum restaurant-year panel and chef-network spine.
3. Run the first chef-move event study with pre-trend diagnostics and one novelty index.
