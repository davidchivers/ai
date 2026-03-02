# literature map: triple lock and relative prices

## objective
Map the research space linking demographics, transfer indexation, and regional/sectoral inflation in order to test H1 without over-claiming causality.

## concept map legend
- `[M]` mechanism box
- `[O]` observable implication
- `[ID]` identification requirement
- `[R]` risk/confounder
- `[F]` falsification condition

## page 1: motivating structure
[M1] Policy income rule:
- UK state pension uprating under the triple lock generates pension income growth that can diverge from contemporaneous CPI and wages.
- This creates a quasi-exogenous time series in pensioner purchasing power conditional on rule components and political implementation.

[M2] Group-specific demand:
- Pensioners and workers differ in Engel curves and expenditure shares.
- HYPOTHESISED: pensioners allocate relatively more spending to locally supplied services and home-related categories.

[M3] Sectoral supply heterogeneity:
- Non-tradables/local services face steeper short-run supply curves than nationally traded goods.
- Tradables face flatter supply due to imports and national pricing.

[M4] Financing incidence:
- Financing method (tax, payroll tax, debt) alters demand and possibly marginal costs.
- Payroll-type financing can raise unit labour costs in labour-intensive sectors.

[O1] Expected reduced-form pattern:
- Higher relative inflation in pensioner-intensive non-tradables when pension purchasing power rises.

[ID1] Core empirical design requirement:
- Use cross-sectional exposure (retiree density; pension income share) interacted with national pension shock.

## page 2: demand-composition pathway
[M-demand] Pension income shock -> expenditure reweighting by age group:
- Let group g in {W, P} have category shares alpha_gk.
- If alpha_PN > alpha_WN, an increase in pension income tilts aggregate demand toward N.
- HYPOTHESISED: categories include local leisure, personal services, gardening-related goods/services, and health-adjacent services not fully covered by NHS provision.

[O2] Pensioner basket vs aggregate basket:
- Pensioner-weighted inflation exceeds aggregate inflation when pension shocks are positive and N supply is constrained.

[ID2] Data need:
- Age-specific expenditure weights from LCF.
- Category inflation from CPI/CPIH detail.

[R1] Measurement risk:
- Category definitions in CPI may not isolate "garden centres/gardening services" cleanly.

## page 3: supply elasticity layer
[M-supply] Local capacity constraints:
- Non-tradables rely on local labour and local fixed factors.
- Areas with labour shortages, low business entry, or planning frictions should exhibit steeper pass-through from demand to prices.

[O3] Heterogeneous treatment effect:
- Larger effect in retiree-dense regions with low service-sector supply elasticity proxies.

[ID3] Interaction test:
- Pension shock x retiree exposure x low-elasticity proxy.

[R2] Competing local shocks:
- Coastal/local amenity demand shifts, weather shocks, tourism cycles, and Brexit labour supply effects can mimic patterns.

[F1] Falsification:
- No differential inflation in retiree-dense regions even where supply constraints are strongest.

## page 4: fiscal financing channel
[M-fiscal-1] Lump-sum/labour tax financing:
- Mainly redistribution from workers to pensioners.
- Relative demand shifts dominate if marginal propensities differ by group and category.

[M-fiscal-2] Employer payroll tax financing (NIC-like):
- Potential direct cost-push in labour-intensive sectors.
- HYPOTHESISED: non-tradables with high labour share may see larger inflation response independent of demand composition.

[O4] Distinguishing signatures:
- Demand channel: stronger where retiree exposure is high.
- Cost channel: stronger where labour intensity/payroll exposure is high, even at similar retiree exposure.

[ID4] Empirical separation:
- Include labour-intensity interaction and financing-policy variation where possible.

[R3] National co-movement:
- Payroll policy often national and broad; weak cross-sectional variation complicates identification.

## page 5: political economy block
[M-political] Rule durability and salience:
- Triple lock persistence may reflect electoral weight and turnout of pensioners.
- Political salience can generate policy inertia and occasional discrete deviations.

[O5] Institutional episodes:
- Temporary suspension/modification windows may provide event-style variation.

[ID5] Event study design:
- National policy timing + regional exposure intensity.

[R4] Anticipation:
- Households and firms may anticipate uprating announcements, shifting timing of prices and spending.

[F2] If no exposure gradient around discrete policy episodes, political-indexation mechanism has limited price relevance.

## page 6: literature strand 1 (ageing and inflation/relative prices)
Purpose: establish whether demographic composition can affect inflation level or relative price structure.

Expected evidence types (TO-FIND):
- Cross-country panel studies linking old-age share to inflation components.
- Central bank decomposition notes on demographic demand and services inflation.
- Structural models with age-specific consumption baskets.

How it connects to H1:
- Provides priors for sign and sectors.
- Informs which categories are plausibly age-sensitive.

Critical caveat:
- Many studies operate at national aggregate level; our mechanism needs within-country exposure variation for cleaner identification.

## page 7: literature strand 2 (transfers/pensions and consumption patterns)
Purpose: test whether transfer income changes spending composition, not only total spending.

Expected evidence types (TO-FIND):
- Pension reforms generating income discontinuities.
- Cash transfer studies on expenditure shares by category.
- MPC heterogeneity by age and liquidity.

Connection to H1:
- If pension income shocks reallocate spending toward N categories, this supports the first-stage demand channel.

Key threat:
- Transfer shocks may coincide with macro cycles, confounding category trends.

Identification implication:
- Use exposure interactions and pre-trend checks, not raw before/after comparisons.

## page 8: literature strand 3 (regional/sectoral inflation and non-tradables)
Purpose: document whether local demand shocks map into local service inflation when supply is inelastic.

Expected evidence types (TO-FIND):
- Local price index studies and service inflation heterogeneity.
- Housing/amenity or tourism demand shocks with local price effects.
- Non-tradables pass-through estimates.

Connection to H1:
- Provides the reduced-form bridge from demand composition to observed relative prices.

Threat to external validity:
- Many local shock papers are housing-centric; pension channel may be smaller and slower.

## page 9: integrated DAG-style narrative
Nodes:
1. Policy rule components (earnings, CPI, floor, discretionary changes).
2. Pension income growth.
3. Pensioner demand by category.
4. Local non-tradable supply conditions.
5. Category-region price outcomes.
6. Fiscal financing instrument.

Directed paths:
- 1 -> 2 -> 3 -> 5 (primary demand path).
- 6 -> firm costs -> 5 (cost path).
- 4 moderates 3 -> 5 pass-through.

Backdoor paths to block:
- Regional macro shocks affecting both retiree share and inflation.
- Migration/compositional changes altering retiree share endogenously.
- National category shocks unrelated to pensions.

## page 10: testable predictions and sign restrictions
P1. Positive pension shock should raise pensioner-basket inflation relative to aggregate basket inflation. (HYPOTHESISED)
P2. Effect should be larger in service/non-tradables than tradables. (HYPOTHESISED)
P3. Effect should be stronger in retiree-dense regions. (HYPOTHESISED)
P4. If payroll-tax financing binds, labour-intensive sectors show incremental inflation response. (HYPOTHESISED)

Null patterns that challenge H1:
- No relation between pension shocks and pensioner-basket inflation.
- Effects concentrated in tradables only.
- No retiree-density gradient.

## page 11: empirical pitfalls and mitigation map
Pitfall A: Omitted regional demand shocks.
Mitigation: region trends, labour-market controls, housing controls, placebo categories.

Pitfall B: Category misclassification.
Mitigation: multiple outcome definitions (broad services, narrower subgroups, robustness bundles).

Pitfall C: Policy endogeneity.
Mitigation: exploit rule-based component and surprises vs forecast benchmarks when feasible.

Pitfall D: Spatial spillovers.
Mitigation: test neighbouring-region exposure and clustered errors.

Pitfall E: Time aggregation mismatch.
Mitigation: align uprating timing with inflation measurement windows and include announcement/event timing checks.

## page 12: synthesis and research agenda
Working interpretation:
- Triple-lock uprating is a politically mediated transfer rule that can plausibly affect relative prices via demand composition, conditional on supply constraints and category exposure.

What makes this publishable:
- Mechanism-integrated framework combining transfer indexation, demographic demand heterogeneity, and local supply elasticity.
- UK institutional setting offers a transparent policy rule and clear exposure heterogeneity.

Immediate evidence priorities:
1. Build validated pension shock series and policy timeline.
2. Construct pensioner basket weights and inflation differential.
3. Implement exposure-based regional design with explicit falsification tests.

## next steps for actual literature retrieval
1. Pull verified UK institutional sources first: IFS, OBR, DWP, ONS, BoE.
2. Build a master citation table with DOI/URL, publication type, and mechanism tag.
3. Prioritise papers that identify causal or quasi-causal transfer-demand links.
4. Add at least two non-UK studies for each strand to benchmark magnitudes.
5. Replace all `TO-FIND` placeholders in `annotated_bib.md` with verified entries before drafting claims.
