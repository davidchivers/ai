# Revision plan after internal AER-style referee report

Date: 2026-04-09

Related files:

- `referee/aer_referee_report.md`
- `drafts/metal.tex`
- `notes/05_research_plan.md`
- `STATUS.md`

## Bottom line

The current draft should be revised as a strong field-journal paper by default, not as an AER
submission in waiting. The reason is not that the project is weak. The reason is that the current
core result is still too close to a threshold-crossing prediction exercise, and the paper is still
too reduced-form and setting-specific for AER.

That means the revision goal is:

1. make the current scene paper fully defensible on its own terms,
2. answer the mechanical-threshold objection as far as possible within the existing data,
3. validate the emergence measure much more aggressively,
4. tighten the front end and strip out exploratory distractions.

Do not expand the sidecar, diffusion, or broadband branches unless they directly help with those
four goals.

## Priority order

### Priority 1. Rewrite the front end so the paper has a real economics introduction

The current draft still opens like a working manuscript rather than a journal submission.

Deliverables:

1. Replace the current literature-first opening with a proper introduction.
2. Move the literature review behind the introduction.
3. State clearly in the first pages:
   - the question,
   - the data contribution,
   - the exact empirical object,
   - the main result,
   - the main limitation,
   - why economists should care.
4. Rewrite the abstract to match the narrower paper.

Required content:

1. Explicitly say that the contribution is a large-scale panel on local scene emergence, not
causal identification.
2. State that the current result is about prediction and disciplined economic interpretation.
3. Cut any front-end language that sounds like the paper explains the global origin of genres.

Stop condition:

The first three pages should make sense to an economist who never reads past the introduction.

### Priority 2. Build a direct response to the mechanical-threshold objection

This is the main intellectual risk in the current paper. The draft needs a bounded package of
tests aimed squarely at the objection that lagged local thickness is just predicting a stock
threshold mechanically.

Deliverables:

1. A threshold-robustness table or appendix figure using alternative emergence cutoffs such as
   `3`, `4`, `6`, and `8` bands.
2. A short note or table showing whether the headline coefficients remain qualitatively similar
   when the risk set is restricted to cells that are still well below the threshold.
   Practical examples:
   - keep only observations with lagged focal-genre stock `<= 2`
   - or drop cells in the immediate one-band neighborhood below the threshold
3. At least one placebo or falsification exercise that weakens the interpretation if the result is
   purely mechanical.
   Candidate directions:
   - use non-focal local activity margins that should be weaker than target-genre depth
   - compare focal-genre multi-band depth against broad all-genre thickness more explicitly
4. A rewritten interpretation paragraph that says exactly what survives after these tests.

Stop condition:

The paper must be able to answer, in one paragraph, why the result is more than “thicker places
cross thickness thresholds sooner.”

### Priority 3. Validate the measurement system, not just the code pipeline

The appendix now documents construction, but the paper still needs substantive validation of the
emergence measure.

Deliverables:

1. A threshold-validation appendix object:
   - how many cells emerge under each threshold
   - whether the timing rank of well-known scenes is broadly plausible
2. A geography-validation object:
   - robustness to dropping ambiguous cities or region-like labels
   - robustness to narrower geography-clean subsets
3. A coverage-sensitivity object:
   - exclude weak-coverage countries or early years
   - show whether the main result is being driven by a thin archival margin
4. A small historical sanity-check table using known scenes.
   This does not need to be a giant music-history appendix. It only needs to reassure the reader
   that the paper’s operational emergence dates are not absurd.

Stop condition:

A skeptical reader should no longer need to simply trust that “fifth band” is a meaningful
transition.

### Priority 4. Tighten scope and demote exploratory branches

Several current sections read like project residue rather than parts of a disciplined paper.

Required moves:

1. Push most digital-era, internet-adoption, and broadband material to the appendix unless it
   directly strengthens the main interpretation.
2. Keep diffusion descriptive and secondary.
3. Keep the network figure parked unless it becomes clearly paper-quality with little extra work.
4. Keep the band-success branch out of the main narrative.

Stop condition:

The paper should read as one main argument, not as a bundle of interesting side explorations.

### Priority 5. Improve interpretation and presentation of the main table

The preferred table is now coherent, but the paper still leaves several reader questions hanging.

Deliverables:

1. Add economic-magnitude interpretation alongside z-scored coefficients.
2. Explain why overall multi-band musicians enter negatively while target-genre multi-band depth is
   positive.
3. Add a short discussion of clustering choice and any sensitivity to broader clustering
   structures.
4. Tighten table notes and figure captions so each object can stand alone.

Stop condition:

A reader should be able to understand the preferred table without needing to infer the paper’s
interpretive logic from surrounding prose.

## Execution sequence

Recommended order:

1. Front-end rewrite.
2. Mechanical-threshold response package.
3. Measurement-validation package.
4. Scope cleanup.
5. Table and caption polish.

Do not start by adding new data branches. The current bottleneck is credibility and framing, not
more exploratory material.

## Immediate next 3 tasks

1. Rewrite the paper front end:
   create a real introduction, move the literature review back, and align the abstract with the
   narrower paper.
2. Build the threshold-objection appendix package:
   alternative emergence cutoffs, restricted-risk-set checks, and one falsification exercise.
3. Build the measurement-validation appendix package:
   threshold sanity checks, geography-clean robustness, and a short historical validation table.

## Off-path ideas to avoid for now

1. Expanding the band-success sidecar.
2. Chasing more internet or broadband variation unless it becomes central.
3. Reopening the broker or connector story as a headline mechanism.
4. Writing around the identification problem instead of confronting it directly.

## Reassessment point

After priorities 1 to 3 are completed, reassess the paper target.

- If the mechanical-threshold objection is meaningfully weakened and the validation package is
  persuasive, continue toward a polished field-journal submission.
- If not, either narrow the paper further into a high-quality descriptive contribution or look for
  a genuinely stronger source of quasi-exogenous variation before investing in a top-journal push.
