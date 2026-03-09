# Business applications companion note

Status: sidecar interpretation note for the flow-side companion series.

Last updated: 2026-03-08

## Why this note exists

The business-size charts are mainly stock or composition objects. If we want an empirical object closer to "firm creation over the business cycle," the business-applications flow series is a better companion.

## Source

This sidecar series uses Census Business Formation Statistics via FRED:

- `BABATOTALSAUS`: total business applications
- `BAHBATOTALSAUS`: high-propensity business applications

Outputs:
- `us_business_applications_monthly.csv`
- `us_business_applications_annual.csv`
- `us_business_applications_indexed.png`
- `business_applications_recession_windows.md`

## What it shows

From `business_applications_recession_windows.md`:

- `2007-2010 Great Recession window`:
  - total applications fall about `5.8%`,
  - high-propensity applications fall about `22.1%`,
  - the high-propensity share falls by about `9.7` percentage points.

- `2019-2022 pandemic window`:
  - total applications rise about `44.5%`,
  - high-propensity applications rise about `31.0%`,
  - but the high-propensity share still falls by about `3.5` percentage points.

## Interpretation

This flow-side object fits the literature better than the CPS self-employment rate if the question is specifically about business creation.

The main read is:

- downturns can reduce or weaken growth-oriented business creation even when other low-scale activity margins behave differently,
- the high-propensity share is especially informative because it moves beyond raw application counts toward application quality or employer-likelihood.

## Recommended use

If we want two empirical motivation figures, the cleanest pair is now:

1. `us_business_counts_by_size_indexed.png`
- shows the shift toward the zero-employee margin in business counts.

2. `us_business_applications_indexed.png`
- shows that actual business-formation flow, especially high-propensity applications, weakens much more in recession conditions.

That pair matches the literature well:

- necessity-style low-scale activity can rise or remain resilient,
- growth-oriented employer-type creation can weaken.

## Current recommendation

If we only keep one companion beyond the main size-bin figure, it should probably be the business-applications flow series rather than the CPS self-employment rate.
