---
name: academic-paper-writer
description: Draft, restructure, and revise economics papers in the repository's academic voice. Use for whole-paper architecture or section work, including titles, abstracts, introductions, literature reviews, data and design, results, discussion, and conclusions, after reading the current manuscript and verified evidence.
---

# Academic Paper Writer

## Load the paper before writing

1. Identify the authoritative manuscript and the exact requested scope. Read enough surrounding text to understand the argument, notation, evidence, and promises made elsewhere.
2. Read `_shared/memory/RESEARCH_STYLE.md` and `_shared/memory/academic_voice.md`. Treat the user's strongest prior papers and the current manuscript as the closest style references.
3. Read the live project status and the evidence, tables, figures, code outputs, referee material, and verified literature relevant to the requested section. For Word sources, include comments, footnotes, and tracked changes.
4. Ask only about an unresolved choice that would materially change the paper. Do not fill gaps in the design, evidence, or contribution with plausible prose.

## Establish the section contract

Before drafting, write down the section's job, the claims it may support, the evidence available for each claim, and any unresolved items. Use these section-specific contracts:

| Section | Required content |
|---|---|
| Title and abstract | The actual question, setting, design, main result, and scope, at the strength supported by the paper |
| Introduction | The paper-specific problem, question and answer, credible design or model, precise contribution relative to verified nearby work, and material limits |
| Literature review | An organizing comparison or mechanism, verified citations, and the exact difference between this paper and the closest work |
| Data and design | Unit and sample, construction of key variables, estimand, identifying variation, assumptions, inference, and diagnostics |
| Results | Substantive claim, estimate and units, uncertainty, comparison case, specification and sample, and evidential limits |
| Discussion or mechanisms | What the evidence establishes, what is interpretation, plausible alternatives, and tests that discriminate among them |
| Conclusion | The answer and contribution already established, honest scope and limitations, and implications warranted by the analysis; no new results |

Adapt this structure to theoretical, quantitative, or mixed papers. Do not impose a generic section sequence on a manuscript with a stronger existing architecture.

## Draft from evidence

- Build the argument around verified claims, not around a prose template. Carry exact magnitudes, units, samples, comparison groups, and uncertainty from their sources.
- Mark unresolved citations or facts explicitly. Never invent a reference, result, robustness check, mechanism test, or policy implication.
- Distinguish descriptive association, model implication, interpretation, and causal evidence. Gate causal language on the identification design and its diagnostics.
- Explain why each result matters instead of narrating every table column. Discuss null and contradictory evidence when it bears on the claim.
- Preserve established terminology, notation, LaTeX commands, labels, citations, and requested layout unless changing them is part of the task.

## Apply the house voice

- Open paragraphs with the phenomenon, comparison, result, or mechanism under discussion.
- Keep one causal or inferential step per sentence. Use direct verbs and proportionate claims.
- Define jargon on first use and connect estimates to concrete magnitudes or scope.
- Remove throat-clearing, novelty inflation, empty roadmaps, synonym cycling, canned contribution language, and generic future-work endings.
- Do not use em dashes in academic prose.

## Integrate and verify

1. Check the revision against the full paper for repeated material, broken promises, inconsistent notation, and contradictions in sample, timing, or results.
2. Trace every number and citation to a verified source. State what remains unverified rather than smoothing over it.
3. If editing source, preserve the canonical format and compile or render when practical. Use the layout-specific skill for PDF placement and visual defects.
4. Return the revised text or source, followed by a brief change summary and a separate list of evidence gaps or decisions that still need the user.
