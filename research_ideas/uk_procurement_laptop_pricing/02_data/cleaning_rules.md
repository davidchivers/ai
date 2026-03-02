# cleaning rules

## VAT harmonization
- Convert all prices to net-of-VAT where possible.
- If source provides only gross price and VAT rate is known, compute net and store both.
- If VAT treatment is unknown, keep observation but set `vat_uncertain_flag = 1`; exclude from baseline.

## bundle decomposition
- If line item separates hardware and services: use hardware unit price for baseline.
- If not separable: classify as bundled and keep for dedicated bundled analysis only.
- Never mix non-separable bundled lines into baseline hardware gap estimand.

## timing alignment
- Primary benchmark window: +/- 14 days around award date.
- Secondary windows for robustness: +/- 7 days and +/- 30 days.
- Record nearest-date distance and whether primary-window match exists.

## quantity and currency checks
- Standardize quantity units to per-device counts.
- Verify GBP denomination; if conversion needed, log exchange-rate source and date.

## outlier policy
- Pre-specify winsorization/sensitivity checks but preserve raw values in master data.
- Report results with and without top/bottom 1% price-gap observations.

## TODO
- TODO_DATA: define parse rules for mixed-currency or ambiguous unit lines.
- TODO_QA: create duplicate-detection logic across duplicate notice publications.
