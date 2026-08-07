---
name: research-ideation
description: Develop economic research questions from observed phenomena and turn them into testable mechanisms, hypotheses, and feasible research designs. Use during early-stage brainstorming, question refinement, contribution mapping, theoretical mechanism development, or initial empirical-design triage.
---

# Research ideation

Generate a small set of researchable questions, not a long list of plausible-sounding topics.

## Start from available context

Inspect the request, project notes, verified literature, known data access, and constraints first. Infer the field, phenomenon, methodological preferences, and intended output. Ask only about an unresolved choice that materially changes the direction.

Label unsupported novelty or literature-positioning claims `[UNVERIFIED]`. Do not assume that a named dataset is accessible, complete, linkable, or suitable for identification.

## Generate mechanisms, not just topics

Use the most relevant of these lenses:

- **Puzzle:** What observed pattern conflicts with a standard model or common explanation?
- **Policy:** Which intervention, rule, or institutional change creates a decision-relevant question?
- **Data:** What newly available measurement or linkage could distinguish mechanisms?
- **Extension:** Which assumption, population, margin, or equilibrium response is missing from the nearest work?
- **Cross-field:** Can a mechanism or method from another field clarify the question without forcing an analogy?

For each candidate, specify:

1. the observed phenomenon and current evidence status;
2. the proposed economic mechanism;
3. supportive, null, and contradictory predictions;
4. the estimand or theoretical object;
5. the required data and whether access is confirmed;
6. a candidate design or model;
7. identification threats, competing explanations, and falsification tests;
8. the precise contribution, marked `[UNVERIFIED]` until the nearest literature is checked;
9. feasibility, blockers, and the cheapest informative next test.

## Triage without false precision

Assess candidates comparatively, but do not assign confident feasibility, novelty, or identification scores before checking the assumptions behind them. A descriptive pattern is not automatically a causal design; an external shock is not automatically a valid instrument or natural experiment.

Prefer two to four developed candidates. Include a null or contradictory route where it would change whether the project is worth pursuing.

## Output format

For each candidate, use:

### [Question]

**Phenomenon and evidence.** What is observed and what remains unverified.

**Mechanism.** The economic channel and competing explanation.

**Predictions.** Supportive, null, and contradictory implications.

**Design or model.** Estimand, data, method, and main threats.

**Contribution.** The proposed delta from verified nearest work.

**Feasibility and next test.** Confirmed access, blockers, and the cheapest informative next step.

Finish with a short comparison explaining which candidate is best supported now, which is most ambitious, and what evidence could reverse that ranking.

## Repository handoff

When the user wants the ideas recorded, follow `_shared/standards/notes_phase_standard.md`:

- substantive discovery belongs in numbered files `01` to `04`;
- final selections and lock criteria belong in concise `05_research_plan.md`;
- live execution tasks belong in the project's single `STATUS.md`.

## Common failure modes

- Questions so broad that no estimand or mechanism can be stated.
- Novelty claims based on memory rather than a verified literature search.
- Designs that depend on unavailable or un-linkable data.
- Causal language without a credible counterfactual.
- Ranking ideas by excitement while ignoring null evidence and implementation cost.
