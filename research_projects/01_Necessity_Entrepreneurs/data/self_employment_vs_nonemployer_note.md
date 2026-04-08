# Self-employment versus nonemployer note

Status: sidecar interpretation note for the new person-level companion series.

Last updated: 2026-03-08

## Why this note exists

The new CPS self-employment companion does **not** mechanically reproduce the same recession pattern as the nonemployer-establishment series used in the business-size figures. That difference is important and should be kept explicit.

## What the two sidecar objects are

### Establishment-side object

Source:
- Census Nonemployer Statistics plus Census BDS establishment counts

Key zero-employee series:
- `us_business_counts_by_size_annual.csv`
- `establishments_0`

Interpretation:
- count of nonemployer establishments or own-account business entities

### Person-side object

Source:
- monthly CPS-based employment levels from FRED/BLS

Key rate series:
- `us_self_employment_rates_annual.csv`
- `rate_total`
- `rate_unincorporated`
- `rate_incorporated`

Interpretation:
- self-employment as a share of employment

## What the person-level companion shows

From `self_employment_recession_windows.md`:

- `2007-2010`:
  - total self-employment rate falls from about `11.06%` to `10.70%`,
  - unincorporated falls from about `7.13%` to `6.96%`,
  - incorporated falls from about `3.93%` to `3.73%`.

- `2019-2022`:
  - total self-employment rate rises from about `9.98%` to `10.44%`,
  - both unincorporated and incorporated components rise.

## Comparison to the establishment-side chart

The establishment-side chart showed:

- over `2007-2010`, `0 employees` rises by about `1.9%`,
- while positive-employment bins fall.

So the two sidecar objects differ in the Great Recession:

- business entities at `0 employees` rise,
- but self-employment as a share of employment falls.

## Interpretation

This divergence does **not** mean one series is wrong. It means they are measuring different margins.

Possible reasons:
- a person-level rate uses employment as the denominator,
- a business-count series counts establishments, not workers,
- a nonemployer business count can rise even if self-employment is not rising as a share of all employment,
- multiple-business or part-time ownership margins can move differently from primary labor-force status.

## Recommended use in the paper

Best current use:
- keep the establishment-size chart as the main business-composition motivation figure,
- treat the CPS self-employment chart as a companion or robustness-style motivation figure,
- avoid writing as if the two series say the same thing.

Safe wording:

"Different empirical measures capture different margins of low-scale business activity. In our sidecar evidence, nonemployer business counts rise during the Great Recession window even though CPS self-employment rates do not. We therefore interpret the establishment-size chart as evidence on business composition rather than as a literal self-employment-rate series."

## Current recommendation

The cleanest main motivation remains:

- lead with the establishment-size figure,
- use the literature to motivate why zero-employee activity may capture necessity-style entry,
- keep the CPS self-employment figure as a separate person-level companion rather than forcing the two into one chart.
