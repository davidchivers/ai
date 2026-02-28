# 05 Research plan

Last updated: 2026-02-25
Status: draft planning handoff from brainstorming

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
1. Model A (procedural task-modality production) from `03_model_notes.md`.
- Why: directly maps to the main empirical interaction object.
- What it buys: clean theory-to-regression mapping with low complexity.

2. Model D (human-support complementarity) from `03_model_notes.md`.
- Why: policy-relevant distinction between substitution and complementarity.
- What it buys: actionable bundle design implications.

## C. Priority: 3 - top 1-2 empirical strategies and why
1. Strategy A (Mindspark RCT extension) from `04_empirical_notes.md`.
- Why: fastest credible causal baseline and heterogeneity benchmark.
- Deliverable: baseline effect-size table plus procedural-interaction extension.

2. Strategy D (FCC x NCES x SEDA broadband DiD) from `04_empirical_notes.md`.
- Why: public-data external validity in a US context.
- Deliverable: district-panel interaction estimate with event-study diagnostics.

## D. Priority: 4 - data access decision and fallback
Primary data path:
- Start immediately with Strategy A replication archive (public access).

Parallel build:
- Start linkage pipeline for Strategy D public US panel.

Fallback if public linkage stalls:
- Move to Strategy B (OULAD) for dynamic learner-task evidence.

## E. Priority: 5 - next 3 tasks (owner, deliverable, deadline)
1. Owner: Codex
- Deliverable: variable dictionary and reproducible data schema for Strategy A and D.
- Deadline: next working session.

2. Owner: User + Codex
- Deliverable: final choice of core outcome metrics and procedurality coding rule.
- Deadline: next working session.

3. Owner: Codex
- Deliverable: estimation script skeleton (baseline + event-study + robustness checklist).
- Deadline: within two sessions.
