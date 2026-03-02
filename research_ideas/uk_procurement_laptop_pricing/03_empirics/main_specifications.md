# main specifications

## baseline model
`price_gap_ijt = beta1*framework_ijt + beta2*direct_award_ijt + beta3*log(quantity_ijt + 1) + FE + eps_ijt`

## preferred fixed effects
- `SKU FE` to absorb time-invariant product differences.
- `time FE` (month-year) to absorb aggregate price trends and seasonality.
- `buyer FE` (preferred) or `buyer-type FE` when sparse.
- Optional `region FE` where delivery/logistics variation is meaningful.

## standard errors
- Cluster at buyer level in primary specification.
- Report contract-level clustering as robustness.

## variable notes
- `framework_ijt`: indicator for framework call-off route.
- `direct_award_ijt`: indicator for direct award procedure.
- `quantity_ijt`: line-item quantity; logged to capture scale effects.

## extended mechanism model
Add bidder competition:
`+ beta4*bidder_count_ijt` (or bins if noisy/missing).

## interpretation discipline
- Coefficients are conditional associations unless quasi-experimental assumptions are explicitly validated.
- Any mechanism language should be framed as evidence-consistent, not proof, outside threshold design.
