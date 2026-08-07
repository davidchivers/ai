---
name: econ-visualization
description: Create and revise publication-quality economic charts and analytical graphics. Use for time series, distributions, coefficient plots, event studies, maps, and multi-panel figures when the comparison task, uncertainty, units, accessibility, reproducible data transformations, export formats, or journal-ready styling matter.
---

# Econ Visualization

## Write the figure contract

Infer the figure's substantive claim, comparison task, audience, data source, surrounding visual style, destination, dimensions, and required formats from the project. Read the actual plotting data or its reproducible construction code before choosing the chart. Ask only about an unresolved choice that changes interpretation or layout.

Record:

- the unit of observation and plotted variables;
- filters, transformations, weights, normalization, and missing-value treatment;
- the comparison the reader must make;
- the uncertainty or sampling information available;
- the required panel order, scale, caption, notes, and export paths.

Do not substitute a convenient dataset, silently aggregate, or infer missing values from an image.

## Match the encoding to the comparison

- Use position on a common scale for precise comparisons. Keep scales comparable across panels unless a different scale is necessary and clearly signposted.
- Show time with an ordered axis and honest intervals. Mark breaks, policy dates, or incomplete periods explicitly.
- Show estimates with their uncertainty and a visible reference value. For event studies, identify the omitted period and preserve the estimator's actual confidence intervals.
- Show distributions when averages conceal relevant heterogeneity. State whether curves, bins, or weights change the apparent mass.
- Use bars for discrete quantities whose baseline matters, not as a default for every category. Use maps only when spatial location is substantively part of the comparison.
- Use log scales, smoothing, dual axes, or truncated axes only for a defensible analytical reason. Label the transformation and prevent it from implying a comparison the data do not support.

## Make the figure legible and faithful

Use concise titles, direct axis labels with units, readable annotation, and a legend only when direct labeling is insufficient. Use a colorblind-safe palette, adequate contrast, distinguishable line types or markers, and a design that remains intelligible in grayscale when publication requires it. Reserve visual emphasis for the focal comparison.

Carry causal, descriptive, modeled, and projected quantities with distinct labels. Do not decorate uncertainty away, hide outliers without documenting the rule, or add precision beyond the source data.

## Keep generation reproducible

Implement data preparation and plotting in the project's existing R, Python, Stata, or other workflow. Reuse nearby themes and naming conventions. Parameterize repeated dimensions or labels when it makes updates safer, and write the canonical output to the expected figure folder.

Export a vector format for papers or scalable documents and a raster preview at the dimensions needed for visual inspection. Use fonts and embedded assets that survive the target compilation or publication workflow.

## Verify mechanically and visually

1. Check plotted row counts, group ordering, dates, units, filters, weights, reference periods, confidence levels, and panel scales against the source data.
2. Render the final output at its intended size. Inspect labels, legends, clipping, overlap, contrast, line weight, whitespace, and small-multiple comparability.
3. Compare the visual claim with the underlying values, including null, contradictory, and extreme observations. Revise any encoding that overstates the evidence.
4. Return the plotting source and canonical outputs, plus a concise note on transformations, uncertainty, regeneration, and any unresolved data issue.
