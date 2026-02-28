# 04 Empirical notes

Last updated: 2026-02-25

---

# Strategy 1: Middle-housing legalisation event study

**Strategy type:** Staggered event study around housing-supply reform shocks.

**Literature.**
Freemark (2019) uses upzoning in Chicago transit zones to study price and permit responses,
finding price effects precede quantity effects. Callaway and Sant'Anna (2021) and Sun and
Abraham (2021) provide modern DiD estimators for staggered designs with heterogeneous
treatment timing. The housing-reform identification approach has growing precedent in the
urban economics literature, though direct fertility applications are scarce — which is the
contribution.

**How this applies to the question.**
The unit is a region-year panel (county or local authority, final geography pending data
lock). Treatment is post-reform exposure to middle-housing legalisation, with an optional
intensity term based on ex-ante housing composition or reform bite. Outcomes are
age-specific birth rates, first-birth timing, and completed-fertility proxies. The event
study is:

$$BirthRate_{it} = \sum_{k \neq -1} \beta_k\, \mathbf{1}\{EventTime_{it} = k\} + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}$$

Key threats are differential demand trends and sorting (pre-trend diagnostics, migration and
labour-market controls), concurrent policy bundles (policy-timing controls and sensitivity
windows), and weak first-stage quantity response (explicit permit and unit-mix first-stage
reporting). Feasibility is medium-high — reform timing data are public, but linking to
granular fertility outcomes requires careful geography harmonisation.

**References.**
Callaway, B., and P. H. C. Sant'Anna (2021). "DiD with Multiple Time Periods." *J. Econometrics*.
Freemark, Y. (2019). "Upzoning Chicago." *Urban Affairs Review*.
Sun, L., and S. Abraham (2021). "Estimating Dynamic Treatment Effects." *J. Econometrics*.

---

# Strategy 2: NIMBY political turnover close-election design

**Strategy type:** Regression discontinuity / close-election IV for housing supply and fertility.

**Literature.**
The close-election RD design follows a standard political economy identification strategy
(Lee, 2008). The application to housing policy draws on the NIMBY political economy
literature (Gyourko et al., 2013; Hilber and Vermeulen) where local political composition
determines supply regulation stringency. The chain from political turnover to supply to
fertility is the novel step.

**How this applies to the question.**
In jurisdictions where pro-housing candidates narrowly win or lose, the near-random
assignment of political power generates exogenous variation in supply policy. The first stage
links political outcomes to housing supply:

$$Supply_{it} = \pi\, ProHousingWin_{it} + f(Margin_{it}) + \eta_i + \tau_t + u_{it}$$

The second stage links instrumented supply to fertility:

$$BirthRate_{it} = \beta\, \widehat{Supply}_{it} + f(Margin_{it}) + \eta_i + \tau_t + e_{it}$$

Key threats are weak first stage (report F-statistics and reduced-form effects),
manipulation at the cutoff (McCrary density test), and concurrent policy changes correlated
with the margin (add policy controls). Feasibility is medium — this is high-upside if
election data and housing-outcome data can be linked at the right geography, but data
assembly is substantially harder than Strategy 1.

**References.**
Gyourko, J., C. Mayer, and T. Sinai (2013). "Superstar Cities." *AEJ: Economic Policy*.
Lee, D. (2008). "Randomized Experiments from Non-random Selection." *J. Econometrics*.

---

# Strategy 3: Geographic supply elasticity as instrument

**Strategy type:** IV using predetermined geographic constraints on housing supply.

**Literature.**
Saiz (2010) constructs supply elasticities from topographic constraints (water bodies,
terrain slope) that are predetermined relative to modern demand shocks. This approach has
been widely adopted to instrument housing costs in settings where demand-side confounders
are the main concern.

**How this applies to the question.**
Geographic supply elasticity provides cross-sectional variation in how demand shocks
translate into price increases. Regions with inelastic supply face larger price responses to
the same demand shock, creating differential fertility pressure. The IV specification is:

$$BirthRate_{i} = \beta\, \widehat{HousingCost}_{i} + X_i'\Gamma + \varepsilon_i$$

where housing cost is instrumented with Saiz-style geographic constraints. This design is
strongest for cross-sectional external validity but weaker on dynamic timing (no event-study
pre-trends). It complements Strategies 1 and 2 by providing a different source of variation
and a different margin of identification.

**References.**
Saiz, A. (2010). "The Geographic Determinants of Housing Supply." *QJE*.
