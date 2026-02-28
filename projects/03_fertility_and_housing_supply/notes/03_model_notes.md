# 03 Model notes

Last updated: 2026-02-25

---

# Model 1: Fertility and housing in a political-economy OLG

**Model type:** Overlapping-generations model with endogenous fertility, housing market, and NIMBY voting.

**Literature.**
This model extends the NIMBYism and housing supply framework from project 02 (Gross and
Chivers, 2025) by adding endogenous fertility as a household choice. The housing-side
structure builds on Saiz (2010) for supply elasticity heterogeneity, Hilber and Vermeulen
for planning-constraint amplification of prices, and Gyourko, Mayer, and Sinai (2013) for
the political economy of housing regulation. The fertility channel draws on Couillard (2025),
who provides direct structural evidence linking housing composition to fertility outcomes,
and Francke and Korevaar (2022) for dynamic demographic-housing feedback at longer horizons.

**How this applies to the question.**
The core mechanism is that NIMBY voting restricts housing supply — especially
family-sized units — which raises the cost of space and crowds out fertility. The household
chooses consumption, housing, savings, and births to maximise:

$$V_t(s_t) = \max_{c_t, h_{t+1}, a_{t+1}, b_t} \left\{ u(c_t, h_{t,eff}, n_{t,home}) + \beta\, \mathbb{E}_t[V_{t+1}(s_{t+1})] \right\}$$

where effective housing $h_{t,eff} = h_t / (1 + \lambda n_{t,home})^\psi$ captures crowding
from children at home. The equilibrium becomes a joint price-demography fixed point
$\{p_t, r_t, policy_t, M_t\}$ rather than prices with exogenous demographics. The key
reduced-form prediction is that supply-restricting policy shocks reduce birth rates,
particularly among younger and lower-wealth households who are marginal on the
space-fertility trade-off.

**References.**
Couillard, B. (2025). Housing composition and fertility. [Structural counterfactual.]
Francke, M., and M. Korevaar (2022). Long-horizon birth-rate and housing dynamics.
Gyourko, J., C. Mayer, and T. Sinai (2013). "Superstar Cities." *AEJ: Economic Policy*.
Saiz, A. (2010). "The Geographic Determinants of Housing Supply." *QJE*.

---

# Model 2: Reduced-form supply-shock-to-fertility channel

**Model type:** Reduced-form causal framework linking exogenous supply variation to fertility outcomes.

**Literature.**
Freemark (2019) shows that upzoning reforms affect prices before quantities respond,
establishing that policy transmission operates through the price/expectations channel before
new construction materialises. The broader quasi-experimental housing literature (Saiz, 2010;
Hilber and Vermeulen) provides instruments based on geographic constraints. On the fertility
side, the reduced-form literature on housing costs and family formation is growing but still
thin on credible identification, which is the gap this project targets.

**How this applies to the question.**
The reduced-form framework bypasses the structural model and asks directly whether
supply-side shocks change birth rates. The baseline event study around middle-housing
legalisation reforms is:

$$BirthRate_{it} = \sum_{k \neq -1} \beta_k\, \mathbf{1}\{EventTime_{it} = k\} + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}$$

The intensity extension exploits cross-regional variation in reform bite:

$$BirthRate_{it} = \beta\, (Post_{it} \times Exposure_i) + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}$$

Key threats are differential demand trends (pre-trend checks, migration controls), concurrent
policy bundles (policy-timing controls), and weak first-stage quantity response (explicit
permit and unit-mix first-stage reporting). This reduced-form evidence complements the
structural model by providing credible baseline magnitudes without parametric assumptions.

**References.**
Freemark, Y. (2019). "Upzoning Chicago." *Urban Affairs Review*.
Saiz, A. (2010). "The Geographic Determinants of Housing Supply." *QJE*.
