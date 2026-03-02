# 03 Model notes

Last updated: 2026-02-25

---

# Model 1: Dialect dynamics with strategic complementarity

**Model type:** Dynamic coordination game with multiple equilibria and tipping behaviour.

**Literature.**
The model draws on coordination game logic applied to language adoption. Weinreich, Labov,
and Herzog (1968) define the core explanatory problems for language change: why some variants
persist, why change is gradual, and what triggers rapid shifts. Baxter, Blythe, Croft, and
McKane (2006) formalise variant competition with stochastic dynamics showing slow drift
punctuated by transitions. In economics, the strategic complementarity structure parallels
technology adoption games where local coordination payoffs sustain multiple equilibria.

The key economic inputs come from Falck, Heblich, Lameli, and Suedekum (2012) and Lameli,
Suedekum, Nitsch, and Wolf (2015), who show that dialect distance has real economic content —
it predicts migration and trade flows within Germany. Fouka and Serlin (2024) demonstrate
that industrialisation and migration jointly reshape cultural identity in 19th-century
Britain, providing the closest direct template for a UK historical design.

**How this applies to the question.**
Each region $i$ has a state variable $x_{i,t} \in [0,1]$: the share of speakers using the
innovative variant. Adoption depends on local coordination complementarity ($\kappa$),
external-contact exposure from migration ($\mu$), state/media prestige pressure ($\psi$),
and articulation advantage ($\phi_i$). The law of motion is:

$$x_{i,t+1} - x_{i,t} = \eta\, x_{i,t}(1 - x_{i,t}) \left[\alpha_i + \phi_i + \kappa x_{i,t} + \mu \sum_j w_{ij,t} x_{j,t} + \psi P_t\right]$$

This generates three testable predictions: (1) regions with larger integration shocks show
faster $x$ changes; (2) policy/media shocks have stronger effects near the tipping threshold;
(3) heterogeneous identity environments produce uneven convergence. The parameters $\mu$ and
$\psi$ map directly to the empirical rail-access and schooling/media treatments.

**References.**
Baxter, G., R. Blythe, W. Croft, and A. McKane (2006). "Utterance Selection Model." *Physical Review E*.
Falck, O., S. Heblich, A. Lameli, and J. Suedekum (2012). "Dialects, Cultural Identity, and Economic Exchange." *J. Urban Economics*.
Fouka, V., and T. Serlin (2024). "Industry and Identity." *NBER WP 33114*.
Weinreich, U., W. Labov, and M. Herzog (1968). "Empirical Foundations for a Theory of Language Change."

---

# Model 2: Continuous phonetic target with contact and contrast forces

**Model type:** Quadratic loss minimisation model of speech production with exemplar dynamics.

**Literature.**
Pierrehumbert (2001) shows that frequency and exemplar storage generate directional sound
change: speakers store noisy realisations and reproduce from their exemplar cloud, creating
systematic drift. Blevins (2004) adds that articulatory biases create persistent directional
tendencies. Labov (1994) documents that chain shifts — where movement in one vowel category
triggers compensating movement in adjacent categories — are a regular feature of sound
change.

**How this applies to the question.**
Each region $i$ has a phonetic target $z_{i,k,t}$ for category $k$. The speaker minimises a
loss trading off inherited exemplars, articulation efficiency, contact-network pressure,
prestige pressure, and contrast maintenance with neighbouring categories. The quadratic
approximation gives a reduced-form update:

$$z_{i,k,t+1} = a\, z_{i,k,t} + b\, \bar{z}_{N(i),k,t} + c\, z^{std}_{k,t} + d\, z^a_k + u_{i,k,t}$$

with $a + b + c + d \approx 1$. High $a$ produces persistence (slow change); high $b$ and
$c$ produce convergence toward network and prestige targets; high $d$ sustains local
articulatory anchors. The contrast force generates chain-shift predictions: a perturbation
in one category propagates to adjacent categories. This model is the right framework when
the outcome variable is continuous phonetic measurement rather than binary variant adoption.

**References.**
Blevins, J. (2004). *Evolutionary Phonology*. Cambridge University Press.
Labov, W. (1994). *Principles of Linguistic Change, Volume 1: Internal Factors*. Blackwell.
Pierrehumbert, J. (2001). "Exemplar Dynamics." In *Frequency and the Emergence of Linguistic Structure*.

---

# Model 3: Dialect distance as economic friction

**Model type:** Gravity model with bilateral dialect distance as a trade/migration cost.

**Literature.**
Melitz (2008) and Melitz and Toubal (2014) show that language links have large positive
effects on bilateral trade, with spoken-language and translation channels operating
separately. Adsera and Pytlikova (2015) find that linguistic proximity strongly predicts
international migration. Spolaore and Wacziarg (2009) demonstrate that historical and
cultural distance predicts slower diffusion of development, with language as a key channel.

**How this applies to the question.**
This model does not explain how dialects change — that is Models 1 and 2. Instead it
explains why dialect differences matter economically. Bilateral flows between regions $i$ and
$j$ depend on dialect distance:

$$Flow_{ij,t} = \gamma_1\, DialectDist_{ij,t} + \gamma_2\, TradeCost_{ij,t} + FE_{ij} + FE_t + u_{ij,t}$$

The prediction is $\gamma_1 < 0$: greater dialect distance reduces migration, trade, and
matching. This is the gravity backup design in the empirical notes. It also closes the
feedback loop: if economic integration (rail access) changes dialects (Model 1), and dialect
convergence reduces frictions (Model 3), then there is a dynamic feedback between
infrastructure, language, and development.

**References.**
Adsera, A., and M. Pytlikova (2015). "The Role of Language in Shaping International Migration." *Economic Journal*.
Melitz, J. (2008). "Language and Foreign Trade." *European Economic Review*.
Spolaore, E., and R. Wacziarg (2009). "The Diffusion of Development." *QJE*.
