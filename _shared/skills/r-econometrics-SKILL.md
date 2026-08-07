---
name: r-econometrics
description: Implement and diagnose instrumental-variables, difference-in-differences, event-study, and regression-discontinuity analyses in R. Use when choosing estimators, fixed effects, clustered uncertainty, identification diagnostics, robustness checks, interpretation, and reproducible output for causal empirical work.
---

# R Econometrics

Choose the estimator from the research design, not from a preferred package. Read the current design notes, data construction, existing scripts, and package environment before writing code. Preserve established project conventions unless they undermine identification or reproducibility.

## Write the design contract

Infer known fields from the repository and ask only about a missing choice that materially changes identification or inference.

| Field | Required content |
|---|---|
| Question and estimand | Population, treatment contrast, outcome horizon, and target parameter |
| Assignment mechanism | Instrument, treatment timing, threshold rule, or other source of variation |
| Observation structure | Unit, time, geography, repeated cross-section or panel, and sampling frame |
| Treatment | Definition, timing, adoption cohorts, reversibility, and anticipation |
| Specification | Outcome, controls, fixed effects, trends, weights, and sample restrictions |
| Inference | Dependence structure, assignment level, cluster count, and any few-cluster concern |
| Outputs | Tables, figures, diagnostics, and destination paths |

Separate design assumptions from empirical diagnostics. A diagnostic can reveal a problem but rarely proves the identifying assumption.

## Audit data before estimation

1. Verify observation keys, duplicates, time coverage, treatment coding, and merge results.
2. Tabulate missingness and sample loss for the variables used in each specification.
3. Check support and within-cell variation after fixed effects and restrictions.
4. Confirm that weights have the intended sampling, frequency, or exposure interpretation.
5. Preserve a reproducible analysis sample and record all exclusions.

Stop if the supplied data cannot implement the claimed design. Do not substitute synthetic or partial data without labeling the result.

## Route by identification design

### Instrumental variables

State the endogenous variable, excluded instrument set, included controls, fixed effects, and population whose effect is identified. Explain the relevance and exclusion arguments; state monotonicity or homogeneity assumptions when interpretation requires them.

Report the first stage and diagnostics appropriate to the exact specification, including multiple endogenous regressors or clustered inference where relevant. Do not use a universal first-stage F threshold. When instruments may be weak, use weak-identification-robust tests or confidence sets and temper interpretation. Check reduced form, sign consistency, sample alignment, and sensitivity to influential observations or instrument definitions.

### Difference in differences and event studies

Map treatment timing and adoption cohorts before choosing an estimator. A conventional two-way fixed-effects interaction may be adequate for a single common treatment date under the stated assumptions; it is not a safe default with staggered timing and heterogeneous effects.

For staggered adoption, select a cohort-time or interaction-weighted method suited to the available comparison groups. Document whether never-treated or not-yet-treated units identify each contrast. Define the event-time window, reference period, binning, anticipation treatment, and aggregation weights.

Examine pre-treatment estimates and raw outcome paths, but do not treat failure to reject a pre-trend test as proof of parallel trends. Check composition changes, differential attrition, treatment reversals, spillovers, and sensitivity to trends or comparison groups.

### Regression discontinuity

Confirm the running variable, cutoff, assignment rule, sharp or fuzzy design, score support, and whether agents can manipulate assignment. Prefer local-polynomial estimation with transparent polynomial order, kernel, bandwidth rule, and bias-aware uncertainty. Avoid high-order global polynomials.

Show the outcome against the running variable with the cutoff and local fits. Examine density or sorting evidence and predetermined covariates, while distinguishing these diagnostics from the continuity assumption. Report bandwidth, donut, functional-form, and support sensitivity that is motivated by the design.

## Choose inference deliberately

Match uncertainty to the assignment and dependence structure. Do not cluster reflexively at the panel identifier or add clustering dimensions merely as robustness variants. Record the number and size distribution of clusters. With few clusters or highly unbalanced clusters, use an appropriate small-sample correction, randomization inference, or bootstrap method and explain its assumptions.

Keep fixed effects, weights, and clustering conceptually distinct: each addresses a different problem.

## Implement reproducibly in R

Use packages already declared by the project where they support the design; inspect installed versions and current syntax before relying on specialized estimators. Do not insert package-install commands into analysis scripts.

Structure code around auditable stages:

1. load configuration and derived analysis data;
2. assert keys, treatment timing, support, and sample restrictions;
3. define common samples and specification objects;
4. estimate the main design and its required diagnostics;
5. run a small, theory-motivated robustness set;
6. export tables, figures, and machine-readable estimates;
7. record session or package information using the project's convention.

Avoid specification dumping. Each robustness check should correspond to a concrete identification, measurement, functional-form, or inference concern.

## Verify and report

Before interpreting results, verify sample sizes, treatment and comparison counts, cluster counts, coefficient orientation, reference categories, omitted variables, absorbed regressors, and convergence warnings. Reconcile exported values with the fitted objects.

Report:

- the estimand and identifying variation in plain language;
- the estimate, uncertainty, units, sample, fixed effects, weights, and clustering;
- design-specific diagnostics and what they do or do not establish;
- supportive, null, and contradictory evidence;
- limitations that materially constrain causal interpretation.

Do not invent data, estimates, references, package output, or causal support. Label unexecuted code and unverified assumptions explicitly.
