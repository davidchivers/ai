# 04 Empirical notes

Last updated: 2026-02-26

---

# Strategy 1: Chef-move event study (primary)

**Strategy type:** Staggered event study using chef mobility as a network shock.

**Literature.**
Uses event-study logic from modern applied micro and mechanism interpretation from network-diffusion studies. Domain relevance comes from Michelin network and reactivity work (Aubke, 2013; Sands, 2025).

**How this applies to the question.**
Construct restaurant-year panel with treatment dates defined by arrival/departure of high-centrality chefs. Outcomes are novelty and similarity measures from menu/image features.

Baseline:

$$Y_{it}=\sum_{k\neq -1}\beta_k 1[t-T_i=k]+\alpha_i+\lambda_t+X'_{it}\Gamma+\varepsilon_{it}$$

Threats: endogenous matching between chefs and restaurants, local demand shocks, treatment-timing ambiguity. Handle with matched controls, city-year controls, and pre-trend diagnostics.

Feasibility: high.

---

# Strategy 2: Idea-level diffusion hazard (co-primary)

**Strategy type:** Discrete-time adoption hazard with network exposure.

**Literature.**
Directly linked to diffusion and network-learning models (Conley and Udry, 2010; Banerjee et al., 2013; Bramoulle et al., 2009).

**How this applies to the question.**
Create restaurant-idea-year panel where idea adoption is first persistent appearance in menu/image features. Exposure is lagged weighted share of network neighbors that already adopted.

Baseline:

$$\Pr(Adopt_{ikt}=1)=\Lambda(\beta Exposure_{ikt}+\theta A_{kt}+\alpha_i+\delta_t+\eta_k)$$

Threats: reflection and common shocks, adoption-timing error, network mismeasurement. Handle with idea-year controls, alternative adoption rules, and multiple network definitions.

Feasibility: high to medium (engineering-heavy but conceptually clean).

---

# Strategy 3: Michelin star transitions stacked DiD

**Strategy type:** Stacked treatment cohorts around star gain/loss events.

**Literature.**
Builds on recognition and reputation-shock work, including Michelin-specific evidence on behavioral responses.

**How this applies to the question.**
Estimate whether star changes alter novelty and convergence behavior. Use first-star gain and star-loss events with balanced event windows.

Baseline:

$$Y_{it}=\sum_{k\neq -1}\beta_k 1[t-T_i=k]+\alpha_i+\lambda_t+\varepsilon_{it}$$

Threats: selection into treatment, anticipation, and mean reversion. Handle with matched cohorts, lead terms, and placebo event assignments.

Feasibility: medium-high once core panel is built.

---

# Strategy 4: Attention-shock shift-share design

**Strategy type:** Shift-share exposure to global culinary attention shocks.

**Literature.**
Attention and review dynamics from Chevalier and Mayzlin (2006), Anderson and Magruder (2012), and Berger and Milkman (2012).

**How this applies to the question.**
Build idea-level global shock series and combine with pre-period restaurant exposure shares:

$$\hat A_{it}=\sum_k s_{ik0} \Delta A_{kt}$$

Then estimate effects on imitation intensity and novelty.

Threats: shift-share exogeneity and weak first stage. Handle with leave-one-region-out shocks, placebo ideas, and first-stage diagnostics.

Feasibility: medium.

---

# Strategy 5: City-level long-run homogenization panel

**Strategy type:** City-year panel on style convergence/diversity and integration intensity.

**Literature.**
Connects differentiated-product and cultural-transmission views to long-run outcomes.

**How this applies to the question.**
Define city-year homogenization and diversity indices from restaurant style vectors. Regress on network openness and global exposure proxies with city and year fixed effects.

Baseline:

$$H_{ct}=\beta NetOpen_{ct}+\alpha_c+\lambda_t+X'_{ct}\Pi+u_{ct}$$

Threats: omitted city trends and composition change. Handle with city trends, balanced subsamples, and reweighting.

Feasibility: medium-low in first wave.

---

## Data and platform constraints

- Instagram Basic Display API was discontinued starting December 4, 2024 (Meta update dated September 4, 2024).
- Current Instagram access is permissioned and tied to business/creator account workflows.
- Broad scraping of social content carries material ToS and legal risk.
- Michelin does not provide a simple historical bulk API.

Preferred first-wave sources:
- Michelin public pages and archived snapshots.
- Wayback snapshots of restaurant menus/galleries.
- Wikidata plus manual verification for chef careers.
- Permissioned review APIs (e.g., Yelp Fusion) where needed.

## Recommended empirical sequence

1. Build core panel and run Strategy 1.
2. Build idea-level panel and run Strategy 2.
3. Add Strategy 3 for recognition mechanism triangulation.
4. Treat Strategies 4 and 5 as extension layer after validation and legal review.

## References

Anderson, M., and J. Magruder (2012). Learning from the Crowd. Economic Journal.
Aubke, F. (2013). Creative Hot Spots. Creativity and Innovation Management.
Banerjee, A., et al. (2013). The Diffusion of Microfinance. Science.
Berger, J., and K. Milkman (2012). What Makes Online Content Viral? Journal of Marketing Research.
Bramoulle, Y., H. Djebbari, and B. Fortin (2009). Identification of Peer Effects through Social Networks. Journal of Econometrics.
Chevalier, J. A., and D. Mayzlin (2006). The Effect of Word of Mouth on Sales. Journal of Marketing Research.
Conley, T. G., and C. R. Udry (2010). Learning about a New Technology. American Economic Review.
Sands, D. B. (2025). Double-edged stars. Strategic Management Journal.
