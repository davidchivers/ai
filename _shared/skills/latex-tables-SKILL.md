---
name: latex-tables
description: Generate and revise publication-ready regression, summary-statistics, balance, calibration, and results tables in LaTeX. Use when estimates and uncertainty must be traced to Stata, R, Python, or other source output and table structure, notes, model labels, multi-column headers, numeric alignment, width, or manuscript integration must be handled consistently.
---

# LaTeX Tables

## Establish the table contract

Read the source output or generation code, the surrounding manuscript discussion, nearby tables, and the project's established LaTeX style. Infer the table's purpose, comparison, audience, destination, and canonical source. Ask only about an unresolved choice that changes the reported evidence or layout.

Record:

- the rows and columns required and their intended comparison;
- estimate type, units, transformation, and uncertainty measure;
- sample, weights, fixed effects, controls, clustering or other inference details;
- model order, panel structure, precision, significance convention, caption, label, and notes;
- the script or output file from which each value comes.

Never invent estimates, standard errors, confidence intervals, stars, sample sizes, diagnostics, model features, or notes. Use visibly marked placeholders only when the user explicitly requests a template.

## Structure the evidence

- Make the main comparison legible from the column and row hierarchy. Group columns with multicolumn headings only when the grouping carries substantive meaning.
- Report uncertainty in the form produced or required by the analysis and name it in the notes. Apply significance markers only when requested, calculated from the correct inference, and paired with exact cutoffs.
- Include the sample, fixed effects, controls, weights, clustering level, observation count, cluster count, and fit or diagnostic statistics that readers need to interpret the specifications.
- Distinguish zero, no, not applicable, suppressed, and unavailable values. Do not encode all of them as a blank cell.
- Keep captions informative but concise. Put definitions, inference, sample restrictions, and non-obvious transformations in notes rather than hiding them in prose elsewhere.

## Fit the manuscript without obscuring it

Reuse nearby table environments, rules, type size, decimal precision, labels, and note style. Use `booktabs`, `threeparttable`, `siunitx`, or other packages only when the manuscript already supports them or the scoped change adds them deliberately.

Align numbers by decimal point when feasible. Prefer shortening labels, reducing precision, reorganizing panels, or splitting an overloaded table before shrinking it. Do not use `\resizebox` as the default response to excess width; use landscape or rotated layouts only when they improve readability and fit the established document design.

## Keep values reproducible

Generate tables from the analysis workflow when practical rather than transcribing results by hand. Preserve the generation script and make formatting transformations explicit. If manual integration is unavoidable, compare every cell with the authoritative output and record the source snapshot.

## Verify before handoff

1. Check row and model order, signs, decimal places, uncertainty, confidence levels, stars, sample counts, cluster counts, fixed effects, controls, weights, and units against the source.
2. Check that the manuscript's table references and prose describe the same specifications and magnitudes.
3. Compile the canonical document and inspect width, page breaks, repeated headers, notes, alignment, font size, clipping, and cross-references at final page size.
4. Return the canonical table source and generation source, the checks performed, and any unresolved provenance or layout issue.
