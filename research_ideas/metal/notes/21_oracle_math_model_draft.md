Here is the tight version that fits the live paper rather than decorating it. Directly supported by the notes and draft: the theory object is local niche formation in a project-based creative industry; bands are projects, musicians are skilled workers; a scene is observed when a `city × genre_family` cell reaches five active bands; and the live reduced-form predictors are local spawning flow, target-genre active bands, and target-genre multi-band musicians. Editorial formalization below: a minimal entry-threshold model with heterogeneous founders and a latent embedded-founder share. I would suppress full CES demand and generic network objects in the main text; they do not buy anything for the live estimating equation.    

### 1. Economic problem

**Direct support.** The paper is not trying to explain technological progress, global genre origins, or network structure for its own sake. It is trying to explain why some cities become able to sustain a new local creative niche earlier than others. In the live draft, a scene is the point at which a city-genre cell becomes thick enough to support repeated entry, operationalized as crossing the five-band threshold.  

**Editorial formalization.** Treat a band as one differentiated local project variety. The economic problem is a local entry problem under team production: entry is easier when the focal niche is already thicker locally, when overlapping workers deepen local recombinant capacity, and when more potential founders come from inside the existing local scene.

### 2. Compact formal model

**Direct support.** Use (c) for city, (g) for genre family, and (t) for year. Let (B_{cgt}) denote active local bands in the target genre, (M_{cgt}) target-genre multi-band musicians, (S_{ct}) local spawning flow, and (E_{cgt}) scene emergence. The empirical design is an exact-year reduced-form panel with city-genre and year fixed effects and lagged scene variables.  

**Editorial formalization.** At the start of year (t), the relevant state is
[
x_{cg,t-1}=\big(B_{cg,t-1},,M_{cg,t-1},,\rho_{c,t-1}\big),
]
where (\rho_{c,t-1}\in[0,1]) is the city-year share of potential founders already embedded in the local scene. Potential founder (i) draws embedded status (e_i\in{0,1}) with (\Pr(e_i=1)=\rho_{c,t-1}), a fixed cost (f_i), and idiosyncratic payoff shock (\varepsilon_{icgt}).

A compact net-entry-value equation is
[
\Pi_{icgt}
==========

\bar{\pi}*g
+\phi_B \log(1+B*{cg,t-1})
+\phi_M \log(1+M_{cg,t-1})
+\gamma e_i
-f_i
+\varepsilon_{icgt},
\qquad
\phi_B,\phi_M,\gamma>0.
]

Interpretation:
[
\phi_B>0 \quad \Rightarrow \quad \text{thicker local target-genre stock lowers formation frictions;}
]
[
\phi_M>0 \quad \Rightarrow \quad \text{more overlapping workers deepen recombinant and team-assembly capacity;}
]
[
\gamma>0 \quad \Rightarrow \quad \text{embedded founders have a spinout premium.}
]

Entry occurs if (\Pi_{icgt}\ge 0). Aggregate niche entry is
[
N_{cgt}
=======

\int \mathbf{1}{\Pi_{icgt}\ge 0}, dH_{ct}(i),
]
where (H_{ct}) is the distribution of ((e_i,f_i,\varepsilon_{icgt})). Hence
[
\frac{\partial N_{cgt}}{\partial B_{cg,t-1}}>0,\qquad
\frac{\partial N_{cgt}}{\partial M_{cg,t-1}}>0,\qquad
\frac{\partial N_{cgt}}{\partial \rho_{c,t-1}}>0.
]

Band stock evolves as
[
B_{cgt}=(1-\delta)B_{cg,t-1}+N_{cgt}.
]

A local scene emerges when
[
E_{cgt}=\mathbf{1}{B_{cgt}\ge \bar B},\qquad \bar B=5.
]

Let (N^E_{cg't}) denote entry by embedded founders. Then realized local spawning flow is
[
S_{ct}=\sum_{g'}N^E_{cg't}.
]

The empirical reduced-form analogue is
[
\Pr(E_{cgt}=1\mid E_{cg,t-1}=0)
===============================

G!\left(
\alpha_{cg}
+\lambda_t
+\beta_S S_{c,t-1}
+\beta_B B_{cg,t-1}
+\beta_M M_{cg,t-1}
+\Gamma'X_{c,t-1}
\right),
]
where (X_{c,t-1}) collects broader city-year controls and the observed regressors enter as lagged rolling averages. The logs are just a convenient concavity normalization, not a structural claim about exact curvature.

### 3. Mapping to the three live empirical predictors

**Direct support.** The paper-facing definitions are already locked. `Local spawning flow` counts bands formed in a city-year whose founding cohort includes at least one musician with prior local band experience in that city. `Target-genre active bands` counts active local bands in the same broad genre family as the focal cell. `Target-genre multi-band musicians` counts local musicians active in the focal genre who simultaneously work across at least two local bands in that same genre. The spawning term is city-year, not city-genre. The live headline table is the counts-only core on these three variables, with broader city-year scene conditions in the background.   

**Editorial mapping.**
[
B_{cg,t-1};\longleftrightarrow;\text{target-genre active bands}
]
This is local niche thickness and domain-specific labor pooling.

[
M_{cg,t-1};\longleftrightarrow;\text{target-genre multi-band musicians}
]
This is within-genre overlapping-worker depth and recombinant capacity.

[
S_{c,t-1};\longleftrightarrow;\text{local spawning flow}
]
This is realized city-year spinout intensity and an empirical proxy for the latent embedded-founder margin (\rho_{c,t-1}), not a purely focal-genre count.

[
X_{c,t-1};\longleftrightarrow;\text{background city-year scene controls}
]
In the live design, this is where overall active bands, overall multi-band musicians, and nontrivial communities sit.

The model should therefore be written in **levels**, not shares. That matches the live paper object: stable headline results are on counts, while composition shares and broker terms are background or adjacent specifications rather than the core claim.  

### 4. Comparative statics / propositions

These are the propositions worth stating.

1. **Thicker target-genre band stock raises later emergence probability.** If (\phi_B>0), then higher (B_{cg,t-1}) raises entry (N_{cgt}), so it raises the hazard of crossing the emergence threshold.

2. **Deeper target-genre overlapping-worker pools raise later emergence probability.** If (\phi_M>0), then higher (M_{cg,t-1}) raises entry (N_{cgt}) by improving recombinant team formation in the focal niche.

3. **Higher local spawning flow predicts later emergence through embedded-founder supply.** If (\gamma>0), then a larger embedded-founder margin (\rho_{c,t-1}) raises entry. Since (S_{c,t-1}) is the realized city-year footprint of embedded entry, higher (S_{c,t-1}) should predict higher later emergence in reduced form.

4. **Local niche formation can be cumulative without a causal overclaim.** Because new entry raises future band stock, and thicker scenes plausibly generate more future overlapping workers and more embedded founders, the model allows local self-reinforcement. But it does **not** identify which channel is dominant or causal.

That is the right level of ambition: enough theory to discipline signs and interpretation, not a structural claim the data do not support.   

### 5. LaTeX-ready model subsection

This is the paper-facing version I would actually insert. It is a direct condensation of the current model note and the draft’s compact conceptual framework, with diffusion, broker rhetoric, and side branches kept out of the core.   

```latex
\subsection{A compact model of local scene emergence}

The paper studies local niche formation in a project-based creative industry. Bands are projects,
musicians are skilled workers, and a local scene emerges when a city's activity in a focal genre
becomes thick enough to sustain repeated entry. A band is one differentiated local variety.

At the start of year $t$, city $c$ and genre $g$ are summarized by target-genre band stock
$B_{cg,t-1}$, target-genre multi-band musician depth $M_{cg,t-1}$, and an unobserved city-year
embedded-founder share $\rho_{c,t-1}\in[0,1]$. A mass of potential founders draws embedded status
$e_i\in\{0,1\}$, fixed cost $f_i$, and idiosyncratic payoff shock $\varepsilon_{icgt}$, with
$\Pr(e_i=1)=\rho_{c,t-1}$.

Expected net entry value is
\begin{equation}
\Pi_{icgt}
=
\bar{\pi}_g
+\phi_B \ln(1+B_{cg,t-1})
+\phi_M \ln(1+M_{cg,t-1})
+\gamma e_i
-f_i
+\varepsilon_{icgt},
\qquad
\phi_B,\phi_M,\gamma>0.
\end{equation}
The term in $B_{cg,t-1}$ captures local domain thickness and labor-pooling advantages. The term in
$M_{cg,t-1}$ captures recombinant capacity and lower team-assembly frictions. The embedded-founder
premium $\gamma$ captures the inherited routines, contacts, and tacit knowledge of spinout-type
entrants.

Entry occurs when $\Pi_{icgt}\ge 0$. If $H_{ct}$ denotes the distribution of founder types, then
aggregate niche entry is
\begin{equation}
N_{cgt}
=
\int \mathbf{1}\{\Pi_{icgt}\ge 0\}\, dH_{ct}(i).
\end{equation}
Hence niche entry is increasing in lagged target-genre band stock, lagged target-genre multi-band
musician depth, and the local mass of embedded founders.

Band stock evolves as
\begin{equation}
B_{cgt}=(1-\delta)B_{cg,t-1}+N_{cgt}.
\end{equation}
A city-genre scene is observed to emerge when local niche thickness crosses the paper's operational
viability threshold,
\begin{equation}
E_{cgt}=\mathbf{1}\{B_{cgt}\ge \bar{B}\}, \qquad \bar{B}=5.
\end{equation}

Let $N^E_{cg't}$ denote new bands founded by embedded local participants. The paper's spawning
measure is a city-year proxy for broad spinout intensity,
\begin{equation}
S_{ct}=\sum_{g'} N^E_{cg't}.
\end{equation}
Because $S_{ct}$ is measured at the city-year level, it should not be read as a purely focal-genre
count.

For city-genre cells still at risk, the empirical hazard equation is
\begin{equation}
\Pr(E_{cgt}=1 \mid E_{cg,t-1}=0)
=
G\!\left(
\alpha_{cg}
+\lambda_t
+\beta_S S_{c,t-1}
+\beta_B B_{cg,t-1}
+\beta_M M_{cg,t-1}
+\Gamma'X_{c,t-1}
\right),
\end{equation}
where $X_{c,t-1}$ collects broader city-year scene controls. In the data, these variables enter as
lagged rolling averages. The model's reduced-form predictions are $\beta_S>0$, $\beta_B>0$, and
$\beta_M>0$.
```

### 6. What not to claim from the model

Do **not** claim causal identification of knowledge spillovers or spinout effects. Do **not** claim that a genre is literally born at band number five; that threshold is operational. Do **not** claim that (S_{ct}) is focal-genre spawning; it is a city-year proxy for broader local spinout intensity. Do **not** turn this into a diffusion model, broadband model, shock model, broker model, or composition-share model; those are not the live core paper. And do **not** claim direct observation of idea transfer. The data observe local conditions consistent with labor pooling, spinouts, and recombination, and the model should do no more than organize that reduced-form interpretation.    

The main discipline is simple: make the theory an entry-threshold model that matches the regressors, not a larger theory than the paper can honestly support.
