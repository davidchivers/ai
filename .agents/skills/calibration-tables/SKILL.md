---
name: calibration-tables
description: Build or revise quantitative macro calibration tables so every row has explicit provenance, the table matches the live implementation, and sources and targets are legible to readers. Use for benchmark parameter tables, source-target crosswalks, and paper-ready calibration writeups.
workflow_stage: writing
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: Dave AI workspace
version: 1.0.0
tags:
  - calibration
  - macro
  - tables
  - latex
  - provenance
  - replication
---

# Calibration Tables

## Purpose

This skill is for quantitative macro calibration tables that need to survive referee scrutiny. The goal is not just to list numbers. The goal is to make every row answer: what is this object, where did it come from, and does it match the live model implementation?

## When to Use

- Writing or revising a benchmark calibration table in a macro paper
- Converting a vague parameter list into a source/target table
- Reconciling calibration code with paper tables
- Deciding whether a row belongs in the main table, a fit table, or calibration prose
- Cleaning up mixed rows such as direct sources, calibrated moments, normalizations, and implementation objects

For repo-specific code-versus-paper checking, pair this skill with the [`code-paper-crosswalk`](../../../_shared/agents/code-paper-crosswalk.md) agent.

## Core Rule

Every quantitative row must be one of these:

1. Direct source
2. Targeted moment
3. Benchmark choice
4. Normalization
5. Derived object
6. Equilibrium object
7. Implementation object

If you cannot classify a row, the table is not ready.

## Default Table Design

Use this as the default layout unless the paper has a clear established style:

`Parameter | Value | Description | Source / target / normalization`

This is the safest default because it forces provenance into the table itself.

## Recommended Workflow

### Step 1: Audit the live object first

- Check the code, not just the old draft.
- Confirm whether the paper row is an active input, a derived quantity, or stale legacy notation.
- Never report inactive legacy parameters as if they are part of the current benchmark.

### Step 2: Classify every row

Use the smallest honest label:

- `Source:` externally assigned from data, another paper, or institutional rule
- `Target:` chosen to match a moment
- `Normalization:` unit choice or scaling convention
- `Benchmark choice:` imposed value, literature convention, or robustness center
- `Derived from:` mechanically implied by other reported objects
- `Solved in equilibrium:` not calibrated directly
- `Implementation:` grid, discretization, imported object, interpolation rule

### Step 3: Pick the right architecture

Use one of these patterns.

#### Pattern A: Single benchmark table

Use when the calibration is compact and each row can carry its own provenance.

`Parameter | Value | Description | Source / target / normalization`

#### Pattern B: Externally calibrated plus internally calibrated

Use when some parameters are assigned directly and others are chosen to hit moments.

- Panel A: externally calibrated parameters
- Panel B: internally calibrated parameters
- Separate fit table: `Moment | Data | Model`

#### Pattern C: Multi-country or multi-calibration comparison

Use when the same parameter block is repeated across economies.

`Parameter | Description | Country A | Country B | Notes`

This is common when the notes column does the provenance work.

### Step 4: Write rows so a referee can parse them fast

Good rows are short and explicit.

- Direct source: `Population shares by education; Barro and Lee (2013).`
- Target row: `Chosen to match average exit rate of 0.15.`
- Derived row: `Implied by capital share and education-specific span-of-control terms.`
- Implementation row: `Common 40-point support with education-specific probability masses.`

Bad rows hide provenance.

- `Labor productivity by education.`
- `Benchmark unemployment insurance.`
- `Shape parameter.`

### Step 5: Put institutional caveats in the text, not the table

If the code uses a stylized approximation to a real institution, the table should report the implemented object and the calibration text should explain the gap.

Example:

- Table: `b = 0.40 × w`
- Text: say this is a reduced-form nonemployment value tied to the model's base wage, not a literal state-law UI formula based on prior earnings and caps.

### Step 6: Validate the finished table

Before signing off, check:

- Every row has explicit provenance
- Reported values match the live implementation
- Derived objects are not mislabeled as primitive parameters
- Equilibrium objects are not mislabeled as calibrated inputs
- Implementation objects are identified as implementation objects
- If targets matter for credibility, there is a separate model-fit table

## Row Taxonomy

### Direct source

Use when the number is taken from external evidence or set from a verified outside source.

Write:

- `Source: Goldin and Katz (2008)`
- `Source: U.S. Department of Labor`
- `Source: standard quarterly depreciation`

### Targeted moment

Use when the parameter is chosen so the model matches a fact.

Write:

- `Target: average employer share`
- `Target: unemployment rate`
- `Target: capital-output ratio`

Do not just write `calibrated`.

### Benchmark choice

Use when the value is imposed but not sharply identified by a specific source.

Write:

- `Benchmark choice within literature range`
- `Chosen as benchmark robustness center`

### Normalization

Use for pure units or scale choices.

Write:

- `Normalization`
- `Normalized to 1`

### Derived object

Use when the number is implied by other rows.

Write:

- `Derived from k-share and education-specific x-share`

These usually should not appear as independent calibration rows unless readers need them.

### Equilibrium object

Use when the model solves for the object.

Write:

- `Solved in equilibrium`

### Implementation object

Use when the code uses a numerical representation rather than a primitive analytic parameter.

Write:

- `Implementation: common support with group-specific masses`
- `Implementation: Tauchen grid`
- `Implementation: imported policy schedule`

## What Good Tables Do

- Separate sources from targets
- Tell the reader whether a number is assigned, targeted, normalized, or derived
- Match the code that generated the quantitative results
- Keep model fit visible when targeting is important
- Avoid hiding implementation choices that matter quantitatively

## What Bad Tables Do

- List numbers with no provenance
- Mix active and inactive parameters from different model versions
- Report a symbolic distribution in the model but omit how it is implemented numerically
- Call a stylized reduced-form object a literal policy rule
- Call a moment-targeted parameter “from” a paper when the paper only disciplined the target

## Top-Journal Patterns

The examples file gives verified patterns and links:

- [`calibration-tables-examples.md`](../../../_shared/skills/calibration-tables-examples.md)

Use those examples to choose style, not to copy blindly.

## Preferred Output Style

When drafting or revising a table, default to:

1. A paper-ready table
2. One short paragraph of calibration prose that explains any stylized implementation choices
3. A short note listing rows that still need source verification or code confirmation

## Example Prompts

- `Rewrite Table 1 so every row has a source or target.`
- `Check whether our calibration table matches the benchmark code.`
- `Turn this parameter list into a referee-proof macro calibration table.`
- `Split these rows into externally calibrated, targeted, and implementation objects.`
