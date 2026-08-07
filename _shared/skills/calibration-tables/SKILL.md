---
name: calibration-tables
description: Build or revise quantitative macro calibration tables so every row has explicit provenance, the table matches the live implementation, and sources and targets are legible to readers. Use for benchmark parameter tables, source-target crosswalks, model-fit tables, and paper-ready calibration writeups.
---

# Calibration Tables

Build tables that let a reader answer three questions quickly: what is this object, where did its value come from, and does it match the live model implementation?

For repository-specific code-versus-paper checking, pair this skill with the agent at `_shared/agents/code-paper-crosswalk.md`.

## Establish the source of truth

Read the current manuscript, live calibration code and configuration, generated outputs, existing table, and verified external sources before rewriting rows. Treat old drafts and legacy parameter names as evidence to reconcile, not as authority.

Record a working ledger:

| Symbol | Value | Meaning and units | Classification | Source, target, or rule | Code location | Status |
|---|---:|---|---|---|---|---|
|  |  |  |  |  |  | verified, stale, or unresolved |

Do not report an inactive input, derived quantity, equilibrium outcome, or numerical device as though it were a currently calibrated primitive.

## Classify every quantitative row

Use exactly the smallest honest category that fits:

| Category | Use when | Table wording |
|---|---|---|
| Direct source | Assigned from verified external evidence or an institutional rule | `Source: ...` |
| Targeted moment | A parameter is chosen to match a data moment | `Target: ...` |
| Benchmark choice | Imposed as a defensible center or convention, but not sharply sourced | `Benchmark choice within ...` |
| Normalization | Sets units or scale | `Normalization` or `Normalized to 1` |
| Derived object | Mechanically implied by reported primitives | `Derived from ...` |
| Equilibrium object | Solved by the model rather than assigned | `Solved in equilibrium` |
| Implementation object | A grid, discretization, imported schedule, interpolation rule, or other numerical representation | `Implementation: ...` |

If a row cannot be classified, leave it unresolved rather than writing only “calibrated.” Do not claim a value is from a paper when that paper disciplines a target or range rather than the parameter itself.

## Choose the table architecture

Use the paper's established style when it is clear. Otherwise choose the simplest architecture that keeps provenance visible.

### Compact benchmark

Use when each row can carry its own provenance:

`Parameter | Value | Description | Source / target / normalization`

### Assigned parameters, calibrated parameters, and fit

Use when readers need to distinguish external assignment from internal calibration:

- Panel A: externally assigned parameters
- Panel B: internally calibrated parameters and their targets
- Separate fit table: `Moment | Data | Model`

### Repeated economies or calibrations

Use when the same parameter block is compared across settings:

`Parameter | Description | Economy A | Economy B | Source / notes`

Keep comparable definitions and units across columns. If the settings use different empirical definitions, expose that difference rather than forcing visual symmetry.

## Build the table

1. Reconcile each proposed row with the live code, including transformations, units, group ordering, and active configuration.
2. Decide whether the object belongs in the main parameter table, a model-fit table, calibration prose, or an implementation appendix.
3. Write short descriptions that define the economic object, not merely its symbol.
4. Give every row a verified source, target, normalization, derivation, equilibrium status, benchmark rationale, or implementation rule.
5. Put citations close to the rows they support and mark unresolved references explicitly.
6. Explain stylized institutional mappings in prose. The table should report the object the code implements, while the text explains how it differs from the literal institution.

Do not invent values, citations, targets, code locations, or empirical precision. Preserve requested panel, column, and note layouts when they carry a substantive comparison.

## Verify the finished table

Check:

- every displayed value against the active implementation or generated output;
- units, frequency conversions, parameter transformations, and rounding;
- that primitives, derived objects, equilibrium objects, and implementation objects are not mislabeled;
- that every target uses the same empirical and model definition;
- that externally assigned and internally fitted values are distinguishable;
- that a fit table reports the moments needed to assess calibration quality;
- that notes define non-obvious symbols, samples, sources, and conventions;
- that the manuscript prose and code-paper crosswalk describe the same benchmark.

Compile and visually inspect the canonical document when the table is in LaTeX. Check width, alignment, grouping, notes, citations, and legibility at final page size.

## Deliver

Return:

1. the paper-ready table;
2. one short calibration paragraph explaining material implementation or institutional choices;
3. a concise verification list naming any row that still needs a source, target-definition, or code confirmation.

Consult [`references/examples.md`](references/examples.md) only when choosing among table architectures or checking how strong papers expose provenance. Use the patterns, not their wording or values.
