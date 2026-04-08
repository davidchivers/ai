# 05 Research plan

Last updated: 2026-03-06
Status: active planning lock

## A. Priority: 1 (highest)
Chosen question and estimand.

Chosen question:

Can the self-employment version of the Necessity Entrepreneurship model explain why broad
business creation may rise in downturns even when employer entrepreneurship and startup
quality weaken?

Target estimand:

- the change in broad entrepreneurship between normal times and a downturn;
- decomposed into:
  - self-employment entry
  - employer entry
  - firm size conditional on employer status

Decision lock:

- do not target a full stochastic business-cycle paper immediately;
- target a downturn-composition mechanism first.
- treat this as a separate extension running in parallel to the current benchmark and
  current model-repair extensions, not as a replacement for them.
- benchmark discipline comes first: no downturn-extension quantitative claims before the
  self-employment benchmark case is in a plausible range.

## B. Priority: 2
Top 1-2 model choices and why.

Chosen model choices:

1. Use the self-employment-root model as the core framework.
   Reason: the benchmark employer-only model cannot cleanly separate necessity
   self-employment from employer entrepreneurship.

2. Start with a labor-market downturn shock, not a general productivity shock.
   Reason: the question is about necessity entry from deteriorating worker outside options,
   so the cleanest first shock is:
   - higher worker separation risk, or
   - lower matching efficiency.

3. Use a staged dynamic design.
   Reason:
   - stage 1: steady-state recession comparative statics
   - stage 2: deterministic transition path
   - stage 3: full stochastic business-cycle model only if the first two stages work

Paper-placement rule:

- once the extension is mature enough for the paper, place it after the current
  quantitative experiments as a separate section;
- working target: Section 8 becomes the downturn/business-cycle extension, with the
  conclusion moved later when that material is ready.

## C. Priority: 3
Top 1-2 empirical strategies and why.

Empirical strategy 1:

Map model broad entrepreneurship into:

- self-employment
- employer entrepreneurship

and compare downturn versus normal-time composition rather than only total entry.

Why:

- the model's distinctive prediction is compositional;
- total entrepreneurship alone is too coarse and can hide offsetting movements.

Empirical strategy 2:

Use a recession-style validation table rather than a full estimation exercise at first.

Why:

- the first test is whether the model reproduces the sign pattern:
  - broad creation up or weakly up
  - employer entrepreneurship down
  - average scale down
- that can be assessed before any full transition estimation.

## D. Priority: 4
Data access decision and fallback.

Primary empirical discipline:

- use readily available U.S. self-employment and employer/nonemployer composition targets
  already being assembled in the project notes.

Fallback:

- if employer/nonemployer recession dynamics are hard to pin down immediately, discipline
  the first pass using model-internal decomposition only and treat the exercise as a
  mechanism paper draft.

## E. Priority: 5
Next 3 tasks (owner, deliverable, deadline).

1. Dave / Codex: discipline the self-employment benchmark so total entrepreneurship is in a
   plausible range and closure risk is implemented with correct post-closure treatment.
   Deliverable: calibrated self-employment baseline note plus updated benchmark tables.

2. Dave / Codex: define one downturn shock in the math and code path.
   Preferred first shock: higher worker separation or lower matching efficiency.
   Deliverable: normal-times versus downturn steady-state comparison table.

3. Dave / Codex: if the steady-state comparison has the right composition signs, build a
   deterministic transition-path experiment.
   Deliverable: recession transition figures for unemployment, self-employment, employer
   entrepreneurship, and average employer size.
