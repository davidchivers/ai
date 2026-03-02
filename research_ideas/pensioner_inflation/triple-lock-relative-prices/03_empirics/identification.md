# identification strategy

## target estimand
Causal/semi-causal effect of pension purchasing-power shocks on relative inflation in pensioner-intensive non-tradable categories, with heterogeneity by regional retiree exposure.

## approach A: shift-share (Bartik-style) demand shock
### design
- Define `Exposure_r` as retiree share (or pension-income share) in region `r`.
- Define national pension shock `Shock_t` as real pension growth innovation.
- Estimate:
`Inflation_{rkt} = beta (Exposure_r * Shock_t * PensionerCategory_k) + controls + FE + epsilon_{rkt}`

### outcomes
- Category-region inflation rates, especially services/non-tradables.

### controls
- Local labour market indicators.
- Housing and demand proxies.
- Region fixed effects, time fixed effects, region trends.

### threats
- Retiree share correlated with amenity demand and long-run local trends.
- Selective migration of retirees.
- Measurement error in regional inflation by category.

### mitigations
- Pre-trend checks.
- Placebo categories with low pensioner relevance.
- Alternative exposure definitions and lag structures.

## approach B: pensioner-basket inflation differential
### design
- Construct pensioner-weighted inflation index using age-specific LCF weights and CPI category inflation.
- Compare against aggregate CPI/CPIH inflation.
- Regress differential on pension uprating shocks and interaction terms.

### key test
- Whether pensioner-basket inflation systematically widens during positive pension shock periods.

### threats
- Mechanical index-construction differences.
- Aggregate shocks hitting pensioner-heavy categories (e.g., energy/food episodes).

### mitigations
- Re-estimate excluding volatile categories.
- Use core/services variants and robustness baskets.

## approach C: regional DiD around policy regime changes/suspensions
### design
- Exploit discrete policy episodes (e.g., temporary triple-lock deviations or formula method changes) with national timing.
- Continuous treatment: retiree density.
- Estimate event-time interactions with exposure intensity.

### threats
- Limited number of policy events reduces power.
- Concurrent national policy changes.

### mitigations
- Narrow windows + flexible controls.
- Stack events if multiple episodes exist.
- Report sensitivity to window choices.

## alternative mechanisms to rule out explicitly
1. Baumol cost disease/sectoral productivity trends.
2. Energy/food shocks disproportionately affecting older households.
3. Housing-cost measurement differences (CPI vs CPIH).
4. Local supply shocks (weather, Brexit-linked labour constraints in horticulture/services).
5. General service-sector wage growth unrelated to pensions.

## falsification tests
1. Tradables placebo: little/no effect expected.
2. Low-retiree regions: attenuated effect expected.
3. Non-pensioner-heavy categories: weaker or no response.
4. Pre-period placebo shocks: no anticipatory pattern before policy-relevant timing.
