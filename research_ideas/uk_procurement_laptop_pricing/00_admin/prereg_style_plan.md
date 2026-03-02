# prereg style plan

## scope
This document records design commitments before full data collection and estimation.

## primary outcome
`price_gap_ijt = log(public_unit_price_ijt) - log(market_price_it)` for high-confidence, warranty-aligned, hardware-comparable observations.

## primary sample
Phase 1 sample: single-SKU line items with explicit quantity and unit price parsed from award attachments.

## primary model family
Linear fixed-effects models with SKU FE and time FE; buyer or buyer-type FE where feasible; clustered standard errors at buyer or contract level.

## design commitments
- Do not pool non-separable bundled observations into the main hardware gap estimand.
- Pre-specify benchmark hierarchy and record source precedence.
- Report missingness and parse success rates by source and document type.
- Run falsification tests and robustness checks as specified in `03_empirics/`.

## TODO before lock
- TODO_DATA: confirm feasible sample size for each FE configuration.
- TODO_RULES: final threshold definitions for discontinuity analysis.
- TODO_CITES: insert legal/institutional source citations.
