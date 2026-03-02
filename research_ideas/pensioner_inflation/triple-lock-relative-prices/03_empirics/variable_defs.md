# variable definitions

## core shocks
- `pension_shock_t`:
  - Baseline: actual state pension uprate minus CPI inflation.
  - Alternative: actual uprate minus earnings growth.
  - Preferred advanced variant: unexpected component relative to pre-announcement forecasts (if forecast archive is available).

## exposure variables
- `exposure_r_retiree_share`: share of population above state pension age (or 65+ as approximation).
- `exposure_r_pension_income_share`: pension income as share of household income in region `r` (if available).
- `exposure_r_old_age_dependency`: robustness measure.

## outcomes
- `inflation_rkt`: inflation in region `r`, category `k`, time `t`.
- `inflation_services_rt`: services inflation by region/time.
- `inflation_nontradable_proxy_rt`: proxy non-tradable inflation bundle.
- `pensioner_basket_inflation_t`: age-weighted national inflation index.
- `diff_pensioner_vs_headline_t`: pensioner basket minus headline CPI/CPIH.

## category mapping for pensioner-intensive sectors
Primary candidates (subject to ONS availability):
- Recreation and culture subcomponents.
- Household/garden related goods and services proxies.
- Personal and local leisure services.

If direct garden-centre price series is unavailable:
- Use closest CPI category proxies + optional external scanner-data extension (future phase).

## controls
- `x_labour_rt`: unemployment, vacancies, wage growth.
- `x_housing_rt`: rents/house price pressure controls.
- `x_energy_t`, `x_food_t`: national shock controls.
- `x_supply_rt`: local business density/capacity constraints.

## fixed effects and trends
- Region FE, category FE, time FE.
- Region linear trends (baseline robustness).
- Optional region x category FE where feasible.

## sample and frequency
- Preferred: monthly or quarterly depending on regional inflation availability.
- Geography: start broad (region/NUTS) then refine to LA if data quality allows.

## coding conventions
- Store intermediate cleaned files in `03_empirics/outputs/tables/` and `03_empirics/outputs/figures/` only when generated.
- Keep raw source ingestion separate once download scripts are activated.
