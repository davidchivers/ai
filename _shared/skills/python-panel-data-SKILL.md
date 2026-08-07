---
name: python-panel-data
description: Run reproducible panel-data analysis in Python with pandas and linearmodels. Use for preparing panel indexes, estimating fixed- or random-effects models, selecting clustered covariance estimators, diagnosing panel structure and absorption, interpreting estimates, and exporting results for tables or figures.
---

# Python Panel Data

Start from the panel structure and estimand, not from a model formula. Read the data documentation, current scripts, and project environment before changing the analysis.

## Define the analysis contract

Record:

| Field | Required content |
|---|---|
| Panel keys | Entity identifier, time identifier, and expected uniqueness |
| Estimand | Population, outcome, treatment or regressor contrast, and units |
| Variation | Between, within-entity, within-time, or treatment-timing variation |
| Specification | Controls, fixed effects, trends, weights, lags, and restrictions |
| Inference | Dependence structure, cluster variables, and cluster counts |
| Output | Stored estimates, table or figure format, and canonical paths |

Infer fields from live project material. Ask only when a missing choice would change the estimator or interpretation.

## Validate the panel

Before estimation:

1. assert uniqueness of the entity-time key and investigate duplicates rather than dropping them automatically;
2. normalize time to a sortable, documented type and verify gaps, frequency, and coverage;
3. describe balance, entry, exit, attrition, and entity-level observation counts;
4. audit missingness and sample loss for every model variable;
5. check treatment timing, reversals, anticipation, and support where relevant;
6. verify meaningful within variation after restrictions and fixed effects;
7. confirm merge cardinality and weight semantics.

Create the panel index only after these checks. Preserve an explicit analysis-sample flag or equivalent reproducible rule.

## Select the estimator

Choose pooled, fixed-effects, first-difference, between, or random-effects estimation from the estimand and assumptions. Do not select random effects merely because it is more efficient; state the orthogonality assumption it adds. Do not add entity or time fixed effects without explaining which confounding variation they remove and which regressors they absorb.

A generic two-way fixed-effects regression is not a sufficient default for staggered treatment with heterogeneous effects. Map adoption cohorts and comparison groups first, then use a design-appropriate estimator or explain why the simpler specification identifies the requested contrast.

Treat dynamic panels, lagged dependent variables, endogenous regressors, and short-$T$ settings as distinct designs requiring their own assumptions and estimators.

## Implement in Python

Follow the existing environment and dependency files. Use current `pandas`, `linearmodels`, or project-specific APIs as appropriate, but do not add installation commands unless the user asks to change the environment.

Keep code auditable:

1. load derived data and configuration without overwriting raw inputs;
2. assert schema, keys, ordering, treatment construction, and sample restrictions;
3. build model matrices from named variables or documented formulas;
4. fit models on explicitly comparable samples where comparisons require them;
5. store model metadata beside estimates;
6. export tables, figures, and machine-readable coefficient data reproducibly.

Avoid silent row deletion, automatic duplicate removal, and broad exception handling. Surface rank, absorption, convergence, and covariance warnings.

## Specify uncertainty

Match the covariance estimator to assignment and residual dependence. Distinguish entity clustering, time clustering, multiway clustering, and kernel or spatial dependence rather than treating them as interchangeable robustness options. Report the number of clusters and consider few-cluster corrections where conventional asymptotics are weak.

Keep weights, fixed effects, and clustering separate in both code and explanation.

## Diagnose and verify

Check and report:

- observations, entities, periods, and clusters in each fitted sample;
- singleton handling and observations removed by missingness or absorption;
- collinearity, rank, absorbed variables, and remaining within variation;
- coefficient orientation, units, reference categories, and transformation back to natural units;
- residual or influence diagnostics appropriate to the model;
- sensitivity tied to specific design or measurement concerns;
- consistency between fitted objects, exported tables, and plotted values.

Run code when execution is in scope. If data or dependencies are unavailable, provide clearly labeled unexecuted code and state what remains unverified.

Interpret estimates conditional on the design assumptions. Report supportive, null, and contradictory results; do not turn fixed effects or clustered standard errors into a causal claim. Never invent estimates, sample sizes, package output, or references.
