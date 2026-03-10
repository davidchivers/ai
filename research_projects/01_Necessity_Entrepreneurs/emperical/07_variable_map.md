# Variable map

## Purpose

This note maps the paper's formal objects to observables we could actually work with.
The main discipline is simple: every mapping should say both what the proxy captures and
what it misses.

## Core structural distinction

### Model object: necessity entrepreneurship

**Formal meaning.**

- Entrepreneurship chosen only because the wage-work outside option is weak.

**Closest observable analogue.**

- Entry induced by an exogenous deterioration in the outside option.

**Candidate observables.**

- Displacement or plant-closure exposure before entry.
- UI exhaustion or sharp UI generosity changes.
- Local labor-demand shocks that worsen job-finding prospects.

**What is missing.**

- A direct person-level counterfactual under a good outside option.

### Model object: opportunity entrepreneurship

**Formal meaning.**

- Entrepreneurship chosen even when viable wage work is available.

**Closest observable analogue.**

- Entry that persists or appears even when outside options remain strong, or entry driven
  by entrepreneurial pull factors rather than worker push factors.

**Candidate observables.**

- Entry from strong employment states.
- Very rapid payroll start or early hiring conditional on good outside options.
- High-propensity application activity in settings where labor-market prospects are not
  deteriorating.

**What is missing.**

- A clean universal classifier. Opportunity self-employment can look small at entry, so
  size alone is not enough.

## Outside-option variables

### Model object: employment contract or matched status

**Candidate observables.**

- Pre-entry employment status.
- Job tenure before entry.
- Recent mass-layoff or plant-closure exposure.
- UI receipt, exhaustion, or eligibility changes.

**Strength.**

- These variables get closest to the worker-side outside option.

**Limit.**

- Employment status alone is endogenous and can reflect anticipation, preferences, or
  selection.

### Model object: job-finding probability `p(theta)`

**Candidate observables.**

- Local vacancy-unemployment ratios.
- Local labor-market tightness measures.
- Occupation- or industry-specific hiring conditions.
- High-frequency local labor-demand shocks.

**Strength.**

- Directly tied to the theory of outside-option deterioration.

**Limit.**

- Local demand conditions may also move entrepreneurial demand, not only job-finding odds.

### Model object: separation risk `rho`

**Candidate observables.**

- Plant closures.
- Mass layoffs.
- Industry-specific contraction shocks.
- Exposure to sectors with rising employment-exit hazards.

**Strength.**

- Especially attractive because it clearly worsens the outside option.

**Limit.**

- The same shock can also reduce product demand or local credit conditions.

## Entrepreneurship outcomes

### Model object: entrepreneur entry

**Candidate observables.**

- New business applications.
- Transition into self-employment in CPS-style data.
- New business ownership records in linked administrative data.

**Strength.**

- Direct extensive-margin outcome.

**Limit.**

- Different data sources capture different moments: applications, stocks, labor-force
  status, or realized ownership.

### Model object: nonemployer self-employment

**Candidate observables.**

- `establishments_0` in the current business-size panel.
- Unincorporated self-employment in CPS as a rough person-side companion.
- Nonemployer business starts in linked administrative data if available.

**Strength.**

- Closest observed counterpart to the model's zero-hire margin.

**Limit.**

- Zero employees does not imply necessity.
- Nonemployer businesses can be side businesses, professional practices, contractors, or
  staged growth projects.

### Model object: employer entrepreneurship

**Candidate observables.**

- High-propensity business applications.
- Employer business births if available.
- First payroll start.
- Positive employees shortly after entry.

**Strength.**

- Much closer to the model's `n_h > 0` margin.

**Limit.**

- Some true opportunity firms still begin with zero employees and only cross this margin
  later.

## Scale and growth outcomes

### Model object: hired labor `n_h`

**Candidate observables.**

- Initial payroll start.
- Number of employees at or shortly after entry.
- Hazard to first employee.

**Strength.**

- Direct bridge to the employer threshold in the model.

**Limit.**

- Initial `n_h` can understate growth-oriented intent if firms stage hiring over time.

### Model object: entrepreneur capital `k`

**Candidate observables.**

- Startup capital if available in survey or administrative data.
- Initial assets, borrowing, or financing source.
- Early investment spending.

**Strength.**

- Potential bridge to wealth and credit-friction mechanisms.

**Limit.**

- Low startup capital does not cleanly reveal type.
- It can reflect credit constraints, business technology, risk management, or deliberate
  staging.

### Model object: output or scale quality

**Candidate observables.**

- Revenue if available.
- Payroll.
- Survival.
- Growth to first employee or early employment growth.

**Strength.**

- Useful for separating composition from subsequent performance.

**Limit.**

- Ex post success is informative but not identical to ex ante motive or type.

## What the current local data can already support

The current project sidecar can already support four reasonably disciplined observables.

- Zero-employee establishment activity.
- Employer establishment activity.
- Total and high-propensity application flows.
- Incorporated and unincorporated self-employment rates.

That is enough for a composition design. It is not enough for a literal structural
classification of all entrants.

## Recommended measurement hierarchy

The cleanest hierarchy for this project is:

1. Define the causal margin using an outside-option shock.
2. Measure the response separately for nonemployer and employer outcomes.
3. Use initial scale, first payroll, capital, and survival as secondary outcomes.
4. Use motives and prior status as supporting interpretation, not as the sole classifier.

## Bottom line

Inference: the empirical analogue of the model is not a single observed label. It is a
stack of objects:

- outside-option shocks on the left-hand side of the design,
- nonemployer versus employer entry in the middle,
- payroll, capital, and survival on the right-hand side as interpretation outcomes.
