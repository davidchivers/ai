# 04 Empirical notes

Last updated: 2026-02-25

---

# Strategy 1: Railways and dialect levelling in industrial Britain

**Strategy type:** Staggered differences-in-differences / event study using historical infrastructure rollout.

**Literature.**
Donaldson and Hornbeck (2016) estimate large market-access gains from US railroads using a
geographic network approach. Donaldson (2018) provides the Indian railroad counterpart with
trade-cost and welfare interpretation. Gregory and Marti-Henneberg (2016) offer UK-specific
GIS evidence linking rail expansion to local demographic change in England and Wales
1825-1911. Fouka and Serlin (2024) use industrialisation and migration to explain cultural
identity change in 19th-century Britain — the closest direct template for our design.

**How this applies to the question.**
The unit is a district-year panel in England and Wales, covering the 19th to early 20th
century. Treatment is first rail access year or a continuous market-access change measure
constructed from historical rail GIS. The linguistic outcome is an innovation-token share
$L_{i,t}$ (proportion of innovative spellings for a target phonetic feature) drawn from
historical text corpora and validated against Survey of English Dialects anchors. The
baseline specification is:

$$Y_{i,t} = \sum_{k \neq -1} \beta_k\, \mathbf{1}[t - T_i = k] + \alpha_i + \lambda_t + X_{i,t}'\Gamma + \varepsilon_{i,t}$$

Key threats are endogenous rail placement (district FE, pre-trend checks, optional
route-planning instrument), linguistic measurement error (restrict to robust feature
families, external validation with dialect atlas), and composition change from migration
(include migration controls, cohort-specific checks). Feasibility is medium — all primary
data sources are public, but text-to-phonetic coding and boundary harmonisation require
substantial build work.

**References.**
Donaldson, D. (2018). "Railroads of the Raj." *AER*.
Donaldson, D., and R. Hornbeck (2016). "Railroads and American Economic Growth." *QJE*.
Fouka, V., and T. Serlin (2024). "Industry and Identity." *NBER WP 33114*.
Gregory, I., and J. Marti-Henneberg (2016). "Railways, Urbanization, and Local Demography." *Social Science History*.

---

# Strategy 2: Dialect distance and intra-UK migration/trade gravity

**Strategy type:** Gravity regression with bilateral dialect distance as friction.

**Literature.**
Falck, Heblich, Lameli, and Suedekum (2012) show that historically similar German dialects
predict higher modern migration flows, even controlling for geographic distance. Lameli,
Suedekum, Nitsch, and Wolf (2015) extend this to intra-German trade. Melitz (2008) and
Melitz and Toubal (2014) provide the international gravity framework with language channels
decomposed into spoken-language, translation, and common-origin effects.

**How this applies to the question.**
The unit is a region-pair-year. Dialect distance is constructed from the Survey of English
Dialects or equivalent UK sources as a pairwise matrix. The outcome is bilateral migration
flow, commuting flow, or (if available) bilateral trade. The specification is:

$$Flow_{ij,t} = \beta\, DialectDist_{ij} + \gamma\, TradeCost_{ij,t} + FE_{ij} + FE_t + Z_{ij,t}'\Pi + u_{ij,t}$$

The prediction is $\beta < 0$: greater dialect distance reduces flows. Key threats are
omitted historical ties correlated with both dialect and economic proximity (pair FE,
time-varying transport controls, placebo tests in low-communication sectors). This design
provides external-validity evidence on the economic relevance of dialect differences and
complements Strategy 1's reduced-form approach to the causes of dialect change.

**References.**
Falck, O., S. Heblich, A. Lameli, and J. Suedekum (2012). "Dialects, Cultural Identity, and Economic Exchange." *J. Urban Economics*.
Lameli, A., J. Suedekum, V. Nitsch, and N. Wolf (2015). "Same Same But Different." *German Economic Review*.
Melitz, J. (2008). "Language and Foreign Trade." *European Economic Review*.
