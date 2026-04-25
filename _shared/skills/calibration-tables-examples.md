# Calibration Table Examples

These examples are not meant to be copied verbatim. They are here to show patterns that work in strong macro papers.

## Main takeaway

The best tables do one of two things well:

- they use a dedicated provenance column, or
- they split externally assigned parameters from internally calibrated parameters and then show fit separately.

## Example 1: American Economic Review

Greg Kaplan, Benjamin Moll, and Giovanni L. Violante, “Monetary Policy According to HANK,” *American Economic Review* 108(3), 2018.

Source:

- Materials appendix PDF from AEA: https://www.aeaweb.org/articles/materials/8561

Relevant lines:

- Table A.1 and surrounding parameterization discussion: [turn16view2](https://www.aeaweb.org/articles/materials/8561)

Pattern:

- grouped by blocks such as preferences, production, government policy, and monetary policy
- compact parameter-values table
- much of the provenance is explained in the paragraph just before the table rather than in a dedicated source column

Use this pattern when:

- many values are inherited from a benchmark model
- only a few parameters are internally pinned down

Do not use this pattern when:

- readers need row-by-row provenance
- the implementation has drifted from the legacy benchmark

## Example 2: Quarterly Journal of Economics

Camila Casas, Federico J. Díez, Gita Gopinath, and Pierre-Olivier Gourinchas, “Dollar Dominance and the Transmission of Monetary Policy,” *Quarterly Journal of Economics* 141(1), 2026.

Source:

- Oxford article page: https://academic.oup.com/qje/article/141/1/605/8261558

Relevant lines:

- Table IV with `Parameter | Description | Canada | Chile | Notes`: [turn9view1](https://academic.oup.com/qje/article/141/1/605/8261558)

Pattern:

- multi-country calibration
- notes column carries the provenance work
- targets are explicit, e.g. `Target of 5`, `Matches import share`, `Flexible prices`

Why it works:

- every row answers where the number came from
- the notes are short, concrete, and economical

## Example 3: Journal of Political Economy

Priit Jeenas and Ricardo Lagos, “Q-Monetary Transmission,” *Journal of Political Economy* 132(3), 2024.

Source:

- publisher PDF mirror: https://crei.cat/wp-content/uploads/2024/04/QMT-pub-1.pdf

Relevant lines:

- Table 1, `Calibrated Parameter Values and Calibration Targets`: [turn16view0](https://crei.cat/wp-content/uploads/2024/04/QMT-pub-1.pdf)

Pattern:

- Panel A: externally calibrated parameters with `Value | Target/Source`
- Panel B: internally calibrated parameters with `Value | Moment | Data | Model`

Why it works:

- externally assigned and internally chosen objects are separated
- the reader sees both the calibrated parameter and the fit to the targeted moment

This is the strongest template when:

- part of the model is direct-source calibration
- part of the model is moment matching

## Example 4: Econometrica

Benjamin Moll, Lukasz Rachel, and Pascual Restrepo, “Uneven Growth: Automation’s Impact on Income and Wealth Inequality,” *Econometrica* 90(6), 2022.

Source:

- publicly available PDF: https://bpb-us-w2.wpmucdn.com/campuspress.yale.edu/dist/c/4765/files/2025/05/ug_pub.pdf

Relevant lines:

- Table I, `Description | Value | Target/Source`: [turn13view0](https://bpb-us-w2.wpmucdn.com/campuspress.yale.edu/dist/c/4765/files/2025/05/ug_pub.pdf)

Pattern:

- single table
- concise `Target/Source` column
- direct mix of standard values, explicit targets, and data mappings

Why it works:

- minimal but honest
- easy to scan
- no orphan parameters

## Example 5: Review of Economic Studies

Morten O. Ravn and Vincent Sterk style is not the target here; a more directly relevant recent example is:

Takuji Komatsu, “Stock Market Participation, Inequality, and Monetary Policy,” *Review of Economic Studies* 92(4), 2025.

Source:

- Oxford article page: https://academic.oup.com/restud/advance-article-abstract/doi/10.1093/restud/rdae068/7698334

Search snippet evidence:

- the article describes `Parameter | Description | Value | Target/Source` and a separate fit table

Pattern:

- explicit `Target/Source` column
- text distinguishes externally calibrated from jointly calibrated parameters
- model fit shown separately

Why it works:

- the benchmark table stays readable
- the fit evidence is not hidden inside long notes

## Cross-example lessons

1. If your table is doing provenance work, give it a provenance column.
2. If your model is targeted, show a separate fit table.
3. If your code uses a numerical implementation object, name it honestly.
4. If your institutional object is stylized, say that in the text.
5. If a parameter is derived from other reported objects, do not present it as independently calibrated.

## Recommended default for this workspace

For most quantitative macro drafts, use:

`Parameter | Value | Description | Source / target / normalization`

If there are many targeted rows, add:

`Moment | Data | Model`

This is usually clearer than a bare three-column parameter list.
