---
name: stata-data-cleaning
description: Clean, reshape, merge, validate, and document messy research data in Stata with reproducible do-file workflows. Use when importing raw files, standardizing identifiers, handling missingness and duplicates, constructing variables, checking merge integrity, or producing auditable processed datasets.
---

# Stata data cleaning

Build an auditable transformation from immutable raw inputs to stable processed outputs.

## Inspect before coding

Read the project README, STATUS, memory, and DATA_POLICY when present. Inspect file metadata and a bounded sample before proposing the pipeline.

Confirm or infer:

- source and access restrictions;
- unit of observation and intended key;
- required variables and output unit;
- provider-specific missing-value codes;
- known duplicates, joins, reshapes, and quality problems;
- approximate size and whether full loading is feasible;
- canonical raw and processed locations.

For large inputs, plan sampling, chunking, aggregation, or provider-side filtering before loading them. Ask only about unresolved choices that materially change the pipeline.

## Pipeline requirements

1. Use a project-relative or explicitly supplied root; do not hard-code a personal working directory.
2. Keep raw data read-only and write derived files to the project's designated processed-data location.
3. Use a stable do-file and stable output names. Track code in Git; create milestone snapshots only when explicitly needed.
4. Start a reproducible log without changing machine-wide settings.
5. Inspect schema, labels, missingness, distributions, and candidate keys before transforming.
6. Explain why each transformation is needed.
7. Use `isid`, `assert`, merge-result checks, and before/after counts as executable invariants.
8. Resolve duplicates from documented domain rules; do not drop them mechanically.
9. Preserve original variables when destructive recoding would make an audit difficult.
10. Produce a data dictionary or metadata note alongside the processed dataset.

## Merge and reshape discipline

- State the expected relationship before merging: `1:1`, `1:m`, or `m:1`.
- Verify uniqueness on both sides before `merge`.
- Tabulate and explain `_merge`; do not silently keep only matches.
- After a reshape, assert the new observation count and key.
- Check that weights, dates, identifiers, encodings, and units retain their intended meaning.

## Optional commands

Prefer built-in Stata commands when they are adequate. Check whether an optional command is already installed before using it. Ask before running `ssc install`, and record the installed package/version when reproducibility depends on it.

## Template

When starting a new do-file, adapt [`assets/stata_cleaning_template.do`](assets/stata_cleaning_template.do). Replace every bracketed placeholder and remove unused blocks; do not treat the template as project evidence.

## Validation and handoff

Report:

- input and output paths;
- unit of observation and verified key;
- row/column counts before and after major steps;
- merge and reshape diagnostics;
- unresolved missingness, duplicates, outliers, or access limitations;
- the do-file, stable processed output, log, and data dictionary locations.

Do not call a pipeline complete merely because the do-file runs. The declared invariants and final key must pass.

## Common failure modes

- Overwriting raw data.
- Hard-coded personal paths.
- Unexplained `duplicates drop` or unmatched-row deletion.
- Machine-specific package installation inside the main pipeline.
- Dated working outputs that create competing current versions.
- Loading a very large file before checking storage and memory feasibility.

## References

- [Stata Data Management Reference Manual](https://www.stata.com/manuals/d.pdf)
- [Gentzkow and Shapiro, Code and Data for the Social Sciences](https://web.stanford.edu/~gentzkow/research/CodeAndData.pdf)
- [DIME Analytics Data Handbook](https://worldbank.github.io/dime-data-handbook/)
