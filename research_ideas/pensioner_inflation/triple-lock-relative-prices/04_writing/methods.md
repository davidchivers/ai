# methods

## model-guided estimand
Estimate whether pension purchasing-power shocks differentially raise inflation in pensioner-intensive non-tradables, especially in retiree-dense and supply-constrained regions.

## baseline econometric structure
`inflation_{rkt} = beta (exposure_r * pension_shock_t * pensioner_intensive_k) + Gamma X_{rt} + FE + epsilon_{rkt}`

## core implementation steps
1. Construct pension shock series.
2. Construct exposure measures.
3. Build category mapping and pensioner-intensity flags using LCF.
4. Estimate panel models with fixed effects and clustered errors.
5. Run falsification and sensitivity tests.

## identification discipline
- Treat national timing as common.
- Leverage cross-sectional heterogeneity.
- Emphasise pre-trends and placebo checks.
