# 05 Research plan

Last updated: 2026-03-13
Status: education remains the default first-paper path; music now has a built MusicBrainz
validation benchmark while the first manual Metallum pull is still pending

## A. Priority: 1 (highest) - chosen question and estimand
Research question: does learning by viewing causally improve skill acquisition on procedural tasks, and by how much relative to low-procedural tasks?

Primary estimand:
$$
\beta_3 = \frac{\partial^2 Y}{\partial Exposure\,\partial Procedurality}
$$
from a baseline interaction design.

Secondary estimand:
- Complementarity slope between viewing exposure and human support intensity.

## B. Priority: 2 - top 1-2 model choices and why
1. Model 1 (task-biased instructional technology) from `03_model_notes.md`.
- Why: directly maps to the main empirical interaction object.
- What it buys: clean theory-to-regression mapping with low complexity.

2. Model 2 (human-support complementarity) from `03_model_notes.md`.
- Why: policy-relevant distinction between substitution and complementarity.
- What it buys: actionable bundle design implications.

## C. Priority: 3 - top 1-2 empirical strategies and why
1. Strategy 1 (Mindspark RCT extension) from `04_empirical_notes.md`.
- Why: fastest credible causal baseline and heterogeneity benchmark.
- Deliverable: baseline effect-size table plus procedural-interaction extension.

2. Strategy 3 (FCC x NCES x SEDA broadband DiD) from `04_empirical_notes.md`.
- Why: public-data external validity in a US context.
- Deliverable: district-panel interaction estimate with event-study diagnostics.

## D. Priority: 4 - data access decision and fallback
Primary data path:
- Start immediately with Strategy 1 replication archive (public access).

Parallel build:
- Start linkage pipeline for Strategy 3 public US panel.

Fallback if public linkage stalls:
- Move to Strategy 2 (OULAD) for dynamic learner-task evidence.

## E. Priority: 5 - locked default outcome metrics and procedurality rule
Strategy 1 (Mindspark RCT extension):
- Primary outcome: `post_score_std`.
- Baseline specification: ANCOVA-style regression with `pre_score_std` included as the main
  baseline control.
- Secondary outcomes: `score_gain_std` and raw-score replication metrics where needed for
  direct comparison with the published archive outputs.
- Main treatment for the first pass: `treat_assign` (ITT).
- Exposure extension after replication: `viewing_exposure_std`, instrumented with treatment
  assignment when usage is analyzed.

Strategy 3 (FCC x NCES x SEDA broadband DiD):
- Primary outcome: `achievement_std` at the district-subject-year level.
- Build rule: retain `grade_band` in the raw and merged panels until the source layout is
  confirmed and a collapse rule is justified.
- Secondary outcome handling: keep published precision or cell-size fields so weighted
  versions can be added later without rebuilding the panel.
- Main treatment for the first pass: continuous broadband coverage (`coverage_25_3_share`).
- Binary staggered-treatment and event-study versions remain secondary until the treatment
  threshold is locked.

Procedurality coding rule:
- Main regressor in both strategies: continuous `procedurality_score_v1` on the 0-1 scale.
- Construction rule: code three equally weighted components on the 0-1 scale, then average:
  demonstrability by viewing, sequence dependence, and tacit or motor execution intensity.
- Strategy 1 coding unit: item if item-level content exists; otherwise module or topic.
- Strategy 3 coding unit: subject by grade-band if needed; otherwise subject-level coding.
- Binary robustness split: define `procedural_high_v1 = 1` when
  `procedurality_score_v1 >= 2/3`.

## F. Priority: 6 - next 3 tasks (owner, deliverable, deadline)
1. Owner: Codex
- Deliverable: finish the remaining Strategy 3 NCES mapping and write the explicit reshape or
  merge recipe for the verified Mindspark files so the education branch reaches a clean
  feasibility checkpoint.
- Deadline: next working session.

2. Owner: Codex
- Deliverable: estimation script skeleton for Strategy 1 baseline ITT, usage-IV extension,
  and Strategy 3 continuous-treatment and event-study specifications.
- Deadline: within two sessions.

3. Owner: User + Codex
- Deliverable: first-pass coding examples that apply the procedurality rubric to a small set
  of Mindspark content units and Strategy 3 subject cells, while using the music-side
  validation panel only as a branch-comparison benchmark.
- Deadline: within two sessions.

## G. Parked idea
- Cross-country internet or 3G rollout with immigrant cohorts is now recorded in
  `04_empirical_notes.md` as a secondary design, not the lead paper.
- Reason: relevant public data exist, but the treatment is too far from direct
  learning-by-viewing exposure and public immigrant datasets do not cleanly observe task-level
  skill acquisition.
- Regional internet rollout with lagged metal or guitar complexity is also now parked in
  `04_empirical_notes.md` as a mechanism-style extension rather than a main design.
- Reason: the causal story is better than the immigrant version, but outcome measurement and
  genre-trend confounds remain too weak for a first paper.
