# identification strategy

This project uses three complementary designs to distinguish true overpayment from composition and process effects.

## design 1: sku-level price-gap benchmarking
Define:
`price_gap_ijt = log(public_unit_price_ijt) - log(market_price_it)`.

Where:
- `i` is a matched laptop SKU,
- `j` is contract/line item,
- `t` is award date (or benchmark window reference),
- `b` is buyer.

Interpretation:
- Positive mean gap in hardware-only, warranty-aligned matches is consistent with higher public prices.
- Gap decomposition by bundle status distinguishes composition effects from residual markup.

Identification strength:
- Within-SKU benchmarking removes broad product-quality heterogeneity.
- Time alignment to market date controls for product lifecycle price decline.

Key confounds and controls:
- Warranty/service mismatch: handled by comparability flags and separate bundled analysis.
- VAT inconsistency: net-of-VAT harmonization and uncertainty flags.
- Timing mismatch: bounded date windows and sensitivity analysis.

## design 2: competition and route mechanisms
Estimate conditional associations between price gaps and procurement mechanism:

`price_gap_ijt = beta1*framework_ijt + beta2*direct_award_ijt + beta3*bidder_count_ijt + X_ijt*gamma + FE + eps_ijt`

with FE sets including SKU FE, month FE, buyer-type FE (or buyer FE where feasible), and region FE.

Interpretation goal:
- Test whether reduced effective competition proxies (direct award, low bidder count) predict larger gaps, conditional on product and time.

Threats:
- Route endogeneity: route choice may respond to urgency/complexity.
- Omitted service quality: imperfect bundle observables can bias route coefficients.

Mitigation:
- Restrict baseline to hardware-only lines.
- Include route-specific controls and buyer fixed effects where sample size permits.
- Report coefficient stability across FE/specification tiers.

## design 3: threshold quasi-experiment (feasibility-dependent)
Use procurement rule thresholds that discretely change procedure/transparency requirements.

Setup:
- Running variable: contract value (or relevant threshold metric).
- Treatment: being just above threshold.
- Outcome: `price_gap` or harmonised unit price.

Requirements before claiming causal interpretation:
- Sufficient observation density near cutoff.
- Minimal manipulation around threshold (McCrary test).
- Covariate continuity and bandwidth robustness.

If requirements fail:
- Downgrade to descriptive threshold plots and do not claim causal effects.

## explicit identification commitments
- No causal claims from route regressions without transparent endogeneity discussion.
- Threshold design is conditional on diagnostic pass; otherwise presented as exploratory.
- Main policy statements will emphasize what is measured directly versus inferred.

## TODO
- TODO_DATA: validate bidder-count availability and quality.
- TODO_RULES: pin exact threshold(s), rule dates, and jurisdiction scope.
- TODO_QA: predefine minimal diagnostics needed to retain RDD in main text.
