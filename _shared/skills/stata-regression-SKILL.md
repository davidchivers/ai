---
name: stata-regression
description: Run, diagnose, and report regression analyses in Stata with publication-ready tables. Use when specifying fixed effects, interactions, weights, clustered standard errors, stored estimates, robustness checks, marginal effects, or esttab and estout exports for empirical economics work.
---

# Stata Regression

Build the regression from the research design and live data construction. Read the current master do-file, variable definitions, existing estimates, and project dependencies before editing code. Preserve established paths, macros, and output conventions unless a verified problem requires a scoped change.

## Define the specification contract

Record:

| Field | Required content |
|---|---|
| Estimand | Population, outcome, key contrast, horizon, and units |
| Sample | Inclusion rules, time span, missingness policy, and analysis-sample identifier |
| Regressors | Treatment, controls, interactions, transformations, and reference categories |
| Structure | Panel or repeated cross-section keys, fixed effects, trends, and weights |
| Inference | Dependence or assignment level, cluster variable, and cluster count |
| Output | Model order, labels, statistics, notes, and canonical table path |

Infer known choices from the repository. Ask only about an unresolved choice that materially changes specification, inference, or reporting.

## Validate data and sample

Before estimation:

1. confirm variable storage types, labels, units, ranges, missing codes, and transformations;
2. assert observation or panel keys and investigate duplicates explicitly;
3. verify merge results and treatment construction;
4. tabulate sample loss and preserve a reproducible indicator for each reported sample;
5. inspect treatment support and variation after restrictions and fixed effects;
6. confirm the meaning of probability, frequency, analytic, or importance weights before using them.

Do not clean data opportunistically inside a regression block. Route reusable construction changes to the canonical cleaning workflow.

## Estimate deliberately

Select `regress`, panel estimators, high-dimensional fixed-effects commands, nonlinear estimators, or design-specific commands from the estimand and data structure. Do not substitute a convenient command without checking that its absorbed effects, weights, degrees-of-freedom corrections, and reported sample match the intended model.

For interactions, set and report reference categories and use factor-variable notation where appropriate. For nonlinear models, distinguish coefficients from marginal effects and calculate the quantity the user actually needs. For fixed effects, explain the identifying within variation and record variables dropped through absorption or collinearity.

Match standard errors to the dependence and assignment structure. Report the number and distribution of clusters. Address few-cluster settings with an appropriate correction or alternative inference method rather than relying on conventional clustered asymptotics.

Use packages already declared by the project. Do not place dependency-installation or other environment-changing commands in analysis do-files unless the user explicitly requests dependency management.

## Organize reproducible code

Use the project's master script and path macros. Keep stages explicit:

1. load configuration and the canonical derived dataset;
2. assert schema, sample rules, keys, and model inputs;
3. clear only the stored estimates created by this analysis;
4. estimate named specifications in the intended table order;
5. attach sample, fixed-effect, cluster, weight, and unit metadata to stored results;
6. run design-motivated diagnostics and robustness checks;
7. export the table and any coefficient dataset to canonical output paths.

Avoid specification dumping. Every added column should answer a stated measurement, functional-form, confounding, sample, or inference concern.

## Verify fitted models

For each reported model, check:

- observation, group, period, and cluster counts;
- sample comparability across columns and the reason for any difference;
- singleton removal, absorbed variables, collinearity, and convergence warnings;
- coefficient orientation, scaling, base categories, and transformed-variable interpretation;
- weight behavior and the effective identifying variation;
- consistency of stored estimates with exported cells and notes.

Run the do-file or a bounded relevant section when execution is authorized. Treat a zero return code as necessary but not sufficient: inspect logs, warnings, output existence, and table contents.

## Report results

Use `esttab`, `estout`, or the project's existing exporter only after storing verified models. Give columns meaningful model labels; report uncertainty, fixed effects, weights, samples, and clustering in notes. Do not invent significance stars, estimates, sample sizes, or diagnostics.

Interpret the coefficient in its actual units and conditional sample. Separate evidence from causal interpretation, present null or contradictory findings, and state the assumptions or unresolved diagnostics that limit the claim.
