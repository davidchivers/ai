# Coalition extension from the benchmark

## Purpose

This note records the clean way to do a coalition extension without letting it drift away from the
 published benchmark.

The main rule is:

- treat coalition politics as a perturbation of the benchmark political model
- change only the political aggregation object first
- compare everything back to the benchmark before adding richer coalition mechanics

## Recommended benchmark

The benchmark for the coalition exercise should be the published political model, not the no-politics
RE transition branch.

Why:

- the coalition extension is about making NIMBY politics stronger
- the natural comparison is therefore the benchmark political equilibrium with equal vote weights
- the no-politics RE branch is better treated as a separate expectations experiment

## Stage 0: exact nesting

Start from a coalition-weighted vote rule that nests the benchmark exactly when all coalition
parameters are zero.

The current helper already has that property:

- `compute_coalition_vote.m`
- if all `alpha_* = 0`, the weighted vote collapses to the equal-weight benchmark object

That is the right design because it makes benchmark comparisons clean.

## Stage 1: one-margin-at-a-time coalition tests

Do not turn on several coalition channels at once at the start.

Instead, run a benchmark-based ladder:

1. homeowner overweight only
2. older-homeowner overweight only
3. leveraged-owner overweight only
4. larger-housing-position overweight only
5. combined coalition case

For each case, compare back to the benchmark on:

- equilibrium house price
- vote imbalance
- debt stock
- any key distributional moments the paper emphasizes

## Stage 2: keep the benchmark economic environment fixed

At first, do not simultaneously change:

- supply elasticities
- expectation rules
- demographic transition assumptions
- bargaining institutions

Otherwise the coalition result becomes hard to interpret.

The clean first question is:

- how much more restrictive does the benchmark political equilibrium become if anti-supply owner
  groups get higher effective political weight?

## Stage 3: only then consider dynamic or RE politics

If the benchmark-based coalition exercise is informative, then a later extension could ask whether
the same coalition logic matters along a transition path.

But that should be a later stage, not the entry point.

The recommended order is:

1. benchmark political model
2. benchmark political model with coalition weights
3. only later, if worthwhile, transition-path or RE coalition dynamics

## Practical workflow

Use the existing coalition objects as the benchmark-based starting point:

- `compute_coalition_vote.m`
- `solve_ss_coalition.m`
- `ClearMarkets_coalition.m`
- `run_political_coalition_extension.m`

The next practical improvement should be a benchmark comparison workflow that reports:

- the zero-alpha nesting check
- one-at-a-time coalition sensitivities
- one combined coalition benchmark

That would make the coalition extension easy to describe in the paper:

- the benchmark nests exactly
- stronger coalition power shifts the political equilibrium in the expected direction
- the result is interpretable because only the political weighting object changed
