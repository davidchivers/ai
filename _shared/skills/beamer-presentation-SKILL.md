---
name: beamer-presentation
description: Create and revise professional academic presentations in LaTeX Beamer. Use for research talks, conference presentations, seminars, job talks, and teaching slides that need a coherent narrative, house style, overlays, equations, figures, tables, citations, speaker pacing, and compile-ready visual QA.
---

# Beamer Presentation

## Establish the talk contract

Infer the audience, purpose, duration, venue, expected level of detail, canonical source, and output format from the request and project files. Read the current deck, paper or teaching source, nearby figures and tables, and any house theme before changing slides. Ask only about an unresolved constraint that would materially alter the deck.

Preserve an established theme, aspect ratio, preamble, macros, title-page layout, footer, and visual language unless the user asks for a redesign. Do not add a theme or package merely because it appears in a generic Beamer template.

## Build the argument to fit the time

1. Write a one-sentence audience takeaway and a slide-level narrative before drafting frames.
2. Budget content slides from the talk length and speaking density. Allow more time for equations, identification, unfamiliar institutions, and discussion; keep backup material outside the timed path.
3. Organize research talks around the paper's actual logic: motivating problem or puzzle, question and answer, setting, design or mechanism, evidence, interpretation and limits, and takeaways. Omit stages that do not help this talk.
4. Give each slide one claim that advances the narrative. Use the frame title to state the topic or takeaway, and order visible elements in the sequence the speaker will explain them.
5. Put anticipated detail, derivations, robustness, and alternative specifications in clearly labeled backup slides with reliable navigation.

## Design readable frames

- Prefer a figure, diagram, equation, or compact table when it communicates the claim more directly than prose.
- Keep body text at a presentation-readable size and leave enough whitespace for hierarchy. Split a dense frame before shrinking it into illegibility.
- Use color and emphasis sparingly and consistently. Ensure sufficient contrast and do not rely on color alone to encode meaning.
- Use overlays only when sequence, comparison, or a derivation benefits from staged disclosure. Keep the final overlay intelligible on its own and avoid animation that merely decorates.
- Define notation before use. Align equations with the paper, and highlight only the term or comparative static being discussed.
- Simplify regression tables to the models, rows, uncertainty, sample information, and notes needed for the spoken claim. Never invent estimates or citations.
- Label descriptive evidence, model implications, interpretation, and causal claims at the strength supported by the source material.

## Implement in the canonical deck

Reuse existing commands, components, paths, and citation conventions. Keep figure generation in its reproducible source rather than editing plotted values in the slide. Preserve labels and appendix references, and check that overlays do not change counters or citations unexpectedly.

When creating a new deck, derive a small visual system from the project or institution before writing frames: aspect ratio, type hierarchy, palette, margins, frame titles, figure treatment, table treatment, and footer. Add only the dependencies the chosen design actually needs.

## Compile and visually verify

1. Compile the canonical source and resolve errors, missing assets, undefined citations, and broken references.
2. Render or inspect every slide, including overlay endpoints and backup slides. Check clipping, overflow, font size, contrast, alignment, image resolution, table legibility, and unexpected blank space.
3. Read the timed path as a sequence. Remove repetition, abrupt transitions, unsupported claims, and slides that do not earn their speaking time.
4. Report the canonical source and PDF, timed slide count, major design or narrative changes, and any unresolved content or asset gaps.
