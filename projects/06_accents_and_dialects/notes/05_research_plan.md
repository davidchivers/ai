# 05 Research plan

Last updated: 2026-02-25

---

## Chosen question and estimand

Primary: did transport integration (railways) cause dialect convergence in industrial Britain?

Estimand: the event-study coefficients $\{\beta_k\}$ from the rail-access-to-linguistic-
change specification, testing whether treated districts show accelerated convergence after
rail arrival.

Secondary: does dialect distance reduce bilateral migration and market integration?

Estimand: the gravity coefficient $\gamma_1$ on pairwise dialect distance.

## Chosen models

Model 1 from `03_model_notes.md`: dialect dynamics with strategic complementarity. Predicts
that integration shocks accelerate convergence by raising external-contact weight $\mu$.

Model 3 from `03_model_notes.md`: dialect distance as economic friction. Predicts that
dialect convergence reduces matching and transaction costs.

Model 2 (continuous phonetic target) is available as an extension for continuous acoustic
outcomes but is not required for the baseline.

## Chosen empirical strategies

Strategy 1 from `04_empirical_notes.md`: railways and dialect levelling (staggered event
study). This is the primary design.

Strategy 2 from `04_empirical_notes.md`: dialect-distance gravity. This is the backup and
the external-validity test for economic relevance.

## Design lock criteria

Lock primary design if:
1. Linguistic proxy correlates with at least one external anchor (SED/atlas) in expected
   direction.
2. Treatment timing can be measured reliably from rail GIS.
3. Event-study pre-trends are approximately flat.

Pivot to backup if:
1. Text-based linguistic measure remains too noisy after cleaning.
2. Geographic harmonisation fails for panel outcomes.
3. Rail treatment cannot be credibly separated from baseline trends.

## Data access

All primary sources are public: historical rail GIS, UK census aggregates, text corpora for
linguistic index, boundary crosswalk resources. Restricted-data upgrades (audio archives,
bilateral trade) are deferred to Phase 2.

## Next 3 tasks

1. Build a first-pass UK dialect-distance matrix from Survey of English Dialects locations.
2. Assemble the minimum district-year panel for the railways-language-change design (lock
   geographic unit and panel years, construct treatment timing variables).
3. Run baseline and event-study regressions for the primary design; produce first
   pre-trend and placebo diagnostic figures.
