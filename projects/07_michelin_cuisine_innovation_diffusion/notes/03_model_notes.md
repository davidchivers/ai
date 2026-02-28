# 03 Model notes

Last updated: 2026-02-26

---

# Model 1: Prestige-weighted network diffusion

**Model type:** Dynamic adoption model with network exposure and status effects.

**Literature.**
The structure follows diffusion with social learning (Conley and Udry, 2010; Banerjee et al., 2013) and network transmission logic (Bala and Goyal, 1998; Bramoulle, Djebbari, and Fortin, 2009). Status enters via market-signaling channels (Podolny, 1993).

**How this applies to the question.**
Restaurant $i$ chooses whether to adopt idea $k$ at time $t$. Adoption probability depends on lagged exposure through chef-network links, attention shocks, and prior status:

$$E_{ikt} = \sum_j w_{ij} a_{jk,t-1}$$
$$\Pr(a_{ikt}=1)=\Lambda(\alpha_k + \beta E_{ikt} + \gamma A_{kt} + \eta S_{i,t-1} - c_{ik})$$

Style updates via adopted ideas, and homogenization is measured by rising pairwise cosine similarity among style vectors.

**Predictions.**
1. Higher network exposure increases adoption hazard.
2. Attention shocks raise adoption more for high-exposure restaurants.
3. Saturated diffusion increases aggregate similarity if common motifs dominate.

---

# Model 2: Innovation vs conformity in Michelin status tournaments

**Model type:** Static choice of novelty under recognition risk and demand returns.

**Literature.**
Status-market and conformity logic from Rosen (1981), Podolny (1993), Phillips and Zuckerman (2001), and Hsu (2006). Domain mapping from Michelin/haute-cuisine institutional work (Rao, Monin, and Durand, 2003; Sands, 2025).

**How this applies to the question.**
Restaurant chooses novelty $n_{it}$ and quality $q_{it}$. Michelin recognition probability is highest near an evaluator-legible frontier, creating an interior choice:

$$R_{it}=\lambda_q q_{it} - \lambda_n (n_{it}-n^*_t)^2 + \lambda_s S_{i,t-1}$$
$$\Pr(Star_{it}=1)=\Lambda(R_{it}-\kappa_t)$$
$$\ln D_{it}=\delta_0+\delta_1 Star_{it}+\delta_2 n_{it}-\delta_3(n_{it}-\bar n_{ct})^2+\mu_i+\tau_t$$

**Predictions.**
1. Novelty is not monotone in status pressure; expect nonlinearity.
2. Mid-status restaurants exhibit stronger conformity than frontier leaders.
3. Post-star behavior may shift toward safer, legible styles.

---

# Model 3: Attention-shock imitation dynamics

**Model type:** Diffusion model with media-driven shocks to imitation payoffs.

**Literature.**
Attention and review channels from Chevalier and Mayzlin (2006), Anderson and Magruder (2012), Mayzlin, Dover, and Chevalier (2014), Luca and Zervas (2016), and Berger and Milkman (2012).

**How this applies to the question.**
Idea-level attention follows a shock process and affects imitation decisions:

$$A_{kt}=\phi A_{k,t-1}+\nu_{kt}$$
$$m_{ikt}=1\{\alpha+\beta E_{ikt}+\gamma A_{kt}+\psi Z_i>\xi_{ikt}\}$$

This predicts episodic convergence waves when global attention concentrates on a narrow set of highly visible ideas.

**Predictions.**
1. Attention spikes increase imitation intensity.
2. Effects are stronger for visual motifs than less visible techniques.
3. Identity-rigid restaurants show weaker convergence response.

---

# Model 4: Dual-channel cultural evolution (lineage vs global)

**Model type:** Aggregate dynamic system for city-level idea shares.

**Literature.**
Cultural-transmission foundations from Bisin and Verdier (2001), Cavalli-Sforza and Feldman (1981), and Boyd and Richerson (1985).

**How this applies to the question.**
City-level share of idea $k$ evolves by a weighted combination of local lineage transmission and global-media transmission:

$$p_{k,c,t+1}=(1-\mu)[(1-\lambda_c)p^L_{k,c,t}+\lambda_c p^G_{k,t}] + \mu/K$$
$$D_{ct}=-\sum_k p_{kct}\ln p_{kct}$$

where $D_{ct}$ is style diversity.

**Predictions.**
1. Higher global-exposure weight $\lambda_c$ lowers local diversity over time.
2. Strong lineage channel slows homogenization.
3. Positive mutation $\mu$ maintains persistent innovation tails.

---

## Model selection for first paper

Use Model 1 as the core mechanism and Model 2 as the strategic incentive layer.
Model 3 is the preferred extension once attention shock data are stabilized.
Model 4 is the long-run framing extension for the second-wave paper.

## References

Bala, V., and S. Goyal (1998). Learning from Neighbours. Review of Economic Studies.
Banerjee, A., et al. (2013). The Diffusion of Microfinance. Science.
Bisin, A., and T. Verdier (2001). The Economics of Cultural Transmission and the Dynamics of Preferences. Journal of Economic Theory.
Boyd, R., and P. J. Richerson (1985). Culture and the Evolutionary Process. University of Chicago Press.
Bramoulle, Y., H. Djebbari, and B. Fortin (2009). Identification of Peer Effects through Social Networks. Journal of Econometrics.
Cavalli-Sforza, L. L., and M. W. Feldman (1981). Cultural Transmission and Evolution. Princeton University Press.
Chevalier, J. A., and D. Mayzlin (2006). The Effect of Word of Mouth on Sales. Journal of Marketing Research.
Conley, T. G., and C. R. Udry (2010). Learning about a New Technology. American Economic Review.
Hsu, G. (2006). Jacks of All Trades and Masters of None. Administrative Science Quarterly.
Luca, M., and G. Zervas (2016). Fake It Till You Make It. Management Science.
Mayzlin, D., Y. Dover, and J. Chevalier (2014). Promotional Reviews. American Economic Review.
Phillips, D. J., and E. W. Zuckerman (2001). Middle-Status Conformity. American Journal of Sociology.
Podolny, J. M. (1993). A Status-Based Model of Market Competition. American Journal of Sociology.
Rao, H., P. Monin, and R. Durand (2003). Institutional Change in Toque Ville. American Journal of Sociology.
Rosen, S. (1981). The Economics of Superstars. American Economic Review.
Sands, D. B. (2025). Double-edged stars. Strategic Management Journal.
