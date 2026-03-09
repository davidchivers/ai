# Motivation framing note

Status: sidecar interpretation note for deciding how to use the new data and literature outputs.

Last updated: 2026-03-08

## Recommended message

The safest paper motivation is:

- recession conditions can push more people toward own-account or zero-employee business activity,
- but recession conditions do not necessarily increase employer-firm creation,
- and recession startup cohorts often look smaller and weaker on the job-creation margin.

This is stronger and more defensible than saying simply that "more firms are created during recessions."

## What the current sidecar data already show

From `us_business_counts_by_size_annual.csv`:

- During the Great Recession window (`2007-2010`), `0 employees` rises about `1.9%`.
- Over the same window:
  - `1-4 employees` falls about `3.6%`,
  - `5-19 employees` falls about `2.6%`,
  - `20+ employees` falls about `5.8%`.
- In the composition chart, the `0 employees` share rises steadily while the positive-employment bins lose share.

Interpretation:
- recession-era business activity appears to tilt toward the zero-employee margin rather than toward larger employer establishments.

## Which figure is most paper-ready

Best current candidate:
- `us_business_counts_by_size_indexed.png`

Why:
- it shows differential cyclical movement cleanly,
- all four lines begin at a common base,
- recession shading is easy to read.

Best companion figure:
- `us_business_counts_by_size_shares.png`

Why:
- it makes the composition shift toward `0 employees` visually explicit,
- it is useful if the indexed figure feels too close to a stock-growth chart rather than a composition chart.

## Suggested wording for the paper intro

Safe version:

"US business activity during downturns appears to shift toward very small or own-account businesses rather than toward larger employer establishments. This pattern is consistent with the distinction between necessity-style entry and growth-oriented firm creation emphasized in the literature."

Avoid:

- "recessions create more firms" without qualification,
- "startup creation is countercyclical" as a blanket statement,
- using self-employment, nonemployer activity, and employer startups as if they were interchangeable.

## Best next data extensions

### 1. Person-level companion series

Added:
- `us_self_employment_rates_annual.png`
- `self_employment_vs_nonemployer_note.md`

Why:
- it would give a person-level counterpart to the zero-employee establishment series,
- it would help tie the motivation more directly to the labor-market transition into self-employment.

Rule:
- keep it separate from the establishment-size chart.
- Important update:
  - in the current sidecar evidence, the CPS self-employment rate does **not** rise in the Great Recession window even though the zero-employee establishment count does.
  - this means the two series should be presented as complementary but distinct objects.

### 2. Flow measure companion series

Added:
- `us_business_applications_indexed.png`
- `business_applications_companion_note.md`

Why:
- the current size-bin chart is mainly a stock or composition object,
- a flow series would speak more directly to "firm creation over the business cycle."

Current read:
- this companion is strong,
- in the Great Recession window, total applications fall and high-propensity applications fall much more sharply,
- this is a cleaner creation-flow complement to the size-bin chart than the CPS self-employment rate.

### 3. Entrant quality or scale extension

If feasible later, add a young-firm or entrant-size series.

Why:
- the literature suggests recession cohorts differ not just in counts but in scale and growth potential.

## Working recommendation

For now, keep the empirical motivation in two layers:

1. Primary motivation:
- use the size-bin chart to show a shift toward zero-employee activity in downturns.

2. Interpretive bridge:
- use the literature review to argue that this is consistent with necessity-style entry, while employer startup creation and entrant scale can move differently.

Best two-figure version at this stage:
- `us_business_counts_by_size_indexed.png`
- `us_business_applications_indexed.png`

That is enough to motivate the final MIT-shock exercise without overclaiming.
