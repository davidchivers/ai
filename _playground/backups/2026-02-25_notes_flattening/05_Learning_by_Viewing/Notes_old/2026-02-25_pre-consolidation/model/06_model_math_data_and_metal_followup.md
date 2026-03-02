# Model Math + Data Paths + Metal Follow-Up

Date: 2026-02-24
Project: Learning by Viewing

## 1) Recommended baseline math: task-modality learning production

### Core objects

Let learner $i$, task $j$, time/attempt $t$, and modality $m \in \{R,V,T\}$ for reading, video, tutoring.

- Skill stock: $S_{ijt}$
- Effort on task: $h_{ijt} \ge 0$
- Task attributes: procedural intensity $p_j$, conceptual intensity $c_j$, risk $r_j$, learnability $\\ell_j$
- Net learning gain from using mode $m$: $\\Delta S_{ijmt}$

### Learning production

Use a reduced-form production function that directly maps to estimation:

$$
\\Delta S_{ijmt}
= \\alpha_j
+ \\beta_m
+ \\gamma_{mp} p_j
+ \\gamma_{mc} c_j
+ \\gamma_{mr} r_j
+ \\gamma_{m\\ell} \\ell_j
+ \\eta_i
- C_{ijmt}
+ \\varepsilon_{ijmt}.
$$

Interpretation:
- $\\beta_m$: average modality effect
- $\\gamma_{m\\bullet}$: modality productivity gradients by task attributes
- $C_{ijmt}$: cost/friction of using modality $m$ for learner-task pair

### Modality choice

Learners or institutions assign modality by:

$$
m_{ijt}^* = \\arg\\max_m \\left\\{ E[\\Delta S_{ijmt}] \\right\\}.
$$

Predicted treatment heterogeneity:
1. Video effects increase with procedural intensity if $\\gamma_{Vp} > \\gamma_{Rp}$.
2. Reading may dominate conceptual tasks if $\\gamma_{Rc} \\ge \\gamma_{Vc}$.
3. Tutoring advantage increases with risk if $\\gamma_{Tr} > \\gamma_{Vr}$.

### Empirical counterpart (DDD-style)

For observed outcomes $Y_{ijgt}$ (learner or group $g$):

$$
Y_{ijgt}
= \\theta_0
+ \\theta_1 \\text{VideoAccess}_{gt}
+ \\theta_2 p_j
+ \\theta_3 \\big(\\text{VideoAccess}_{gt} \\times p_j\\big)
+ \\theta_4 X_{igt}
+ \\mu_i + \\phi_j + \\lambda_t + u_{ijgt}.
$$

The key coefficient is $\\theta_3$: the differential video effect on more procedural tasks.

## 2) Extra model: Acemoglu-style task assignment with learning intensity

This is the task-based extension you asked for: same assignment logic as Acemoglu-style task frameworks, but tasks vary by learning intensity rather than automation susceptibility.

### 2.1 Task continuum and modality technologies

Let tasks be indexed by $j \\in [0,1]$, with attributes $(p_j, \\ell_j)$.

Define modality-specific learning productivity:

$$
A_m(j,t)=\\bar A_{m,t}\\exp\\big(\\rho_m p_j + \\zeta_m \\ell_j\\big), \\quad m \\in \\{R,V,T\\}.
$$

For learner $i$, net gain from assigning mode $m$ to task $j$ is:

$$
G_{ijm,t}=A_m(j,t)\\,h_{ijt}-C_{ijm,t}.
$$

Assignment rule:

$$
m_{ij,t}^*=\\arg\\max_m G_{ijm,t}.
$$

### 2.2 Partition of tasks across modalities

Define assigned set for modality $m$:

$$
\\Omega_m(t)=\\{j \\in [0,1] : m=\\arg\\max_{m'} G_{ijm',t}\\}.
$$

Aggregate learning for learner $i$:

$$
\\Delta S_{it}=\\sum_{m \\in \\{R,V,T\\}} \\int_{\\Omega_m(t)} A_m(j,t)\\,h_{ijt}\\,dj.
$$

### 2.3 Comparative statics

If video productivity shifts up ($\\bar A_{V,t}$ rises) or video is more sensitive to procedural/learnability attributes ($\\rho_V,\\zeta_V$ high), then more high-$(p_j,\\ell_j)$ tasks move into $\\Omega_V(t)$.

This yields an empirical prediction: treatment effects from video-access shocks should be largest where task-level learnability and procedural intensity are high.

## 3) Dynamic extension: learning curve with mode-specific slope

### Core objects

Let learner $i$, task $j$, attempt/time $t$.

- Skill stock: $S_{ijt}$
- Learning mode: $m_{it} \in \{V,T,N\}$ for video, text, none
- Practice intensity: $e_{it} \ge 0$
- Outcome (performance): $Y_{ijt}$

### Law of motion

A parsimonious skill accumulation equation:

$$
S_{ij,t+1} = S_{ijt} + \alpha_j e_{it} + \beta_j \mathbf{1}[m_{it}=V]\cdot e_{it} - \delta_j S_{ijt} + \varepsilon_{ijt}
$$

Interpretation:
- $\alpha_j$: baseline learning-by-doing slope for task $j$
- $\beta_j$: extra slope from video (the key parameter)
- $\delta_j$: depreciation/forgetting

If desired, allow video to shift intercept too:

$$
S_{ij,t+1} = S_{ijt} + \eta_j \mathbf{1}[m_{it}=V] + (\alpha_j+\beta_j \mathbf{1}[m_{it}=V])e_{it} - \delta_j S_{ijt} + \varepsilon_{ijt}
$$

### Measurement equation

Map skill to observed performance:

$$
Y_{ijt} = \theta_j S_{ijt} + \mu_i + \lambda_t + u_{ijt}
$$

or for pass/fail:

$$
P(\text{pass}_{ijt}=1)=\Lambda(\theta_j S_{ijt}+\mu_i+\lambda_t)
$$

### Key outline questions this model answers

1. Is $\beta_j>0$? (Does video raise learning speed conditional on effort?)
2. Is $\beta_j$ larger for procedural tasks than conceptual tasks?
3. Are gains front-loaded (large early effects then flattening)?
4. Is there complementarity: does video matter more when immediate practice $e_{it}$ is high?

### Empirical counterpart

Reduced-form estimating equation close to the model:

$$
Y_{ijt} = \gamma_1 \text{VideoAccess}_{it} + \gamma_2 \text{Attempts}_{it} + \gamma_3 (\text{VideoAccess}_{it}\times \text{Attempts}_{it}) + \mu_i + \phi_j + \lambda_t + \epsilon_{ijt}
$$

Interpretation:
- $\gamma_1$: intercept shift from viewing
- $\gamma_3$: slope/complementarity effect (most important)

## 4) Mechanism extension: Bayesian precision (video as better signal)

### Core setup

Task has latent correct technique $x_j^*$. Learner $i$ holds belief $x_{ijt}\sim N(\mu_{ijt},\sigma^2_{ijt})$.

Signals:
- Text signal: $s^T_{ijt} = x_j^* + \nu^T_{ijt}$, $\nu^T_{ijt}\sim N(0,\tau_T^{-1})$
- Video signal: $s^V_{ijt} = x_j^* + \nu^V_{ijt}$, $\nu^V_{ijt}\sim N(0,\tau_V^{-1})$

Assumption: $\tau_V > \tau_T$ for procedural tasks (video more precise).

### Bayesian update

Posterior precision:

$$
\sigma^{-2}_{ij,t+1}=\sigma^{-2}_{ijt}+\tau_{m_{it}}
$$

Posterior mean:

$$
\mu_{ij,t+1} = \frac{\sigma^{-2}_{ijt}\mu_{ijt}+\tau_{m_{it}} s^{m_{it}}_{ijt}}{\sigma^{-2}_{ijt}+\tau_{m_{it}}}
$$

Action $a_{ijt}$ chosen as posterior mean. Loss:

$$
L_{ijt}=(a_{ijt}-x_j^*)^2
$$

Expected loss is decreasing in posterior precision, so higher $\tau$ means lower expected error.

### Key outline questions this model answers

1. Is video improving outcomes by raising information precision rather than just motivation?
2. Are effects bigger when prior uncertainty is high (novices)?
3. Are effects bigger for high-ambiguity, high-procedural tasks?
4. Do we see variance compression in errors, not just mean shifts?

### Empirical counterpart

Use both mean and dispersion outcomes:
- Mean performance gain: $\Delta E[Y]$
- Error variance reduction: $\Delta Var(\text{error}) < 0$

Test equation:

$$
\text{Error}_{ijt} = \beta_0 + \beta_1 \text{VideoAccess}_{it} + \beta_2 \text{Novice}_i + \beta_3 (\text{VideoAccess}_{it}\times \text{Novice}_i)+\mu_i+\phi_j+\lambda_t+\epsilon_{ijt}
$$

and parallel variance models by cell.

## 5) Deeper on Empirical Design 5: language-based content-supply shock

### Design recap

Use growth in tutorial supply by language-topic cells as a source-side shock. Exposure for region $r$:

$$
Exposure_{rt}=\sum_{\ell} Share_{r\ell,0}\cdot \Delta Supply_{\ell t}
$$

where:
- $Share_{r\ell,0}$: pre-period share of population speaking language $\ell$
- $\Delta Supply_{\ell t}$: global growth in relevant tutorial content in language $\ell$

Then estimate outcomes on $Exposure_{rt}$ with region and time fixed effects.

### Why this is valuable

This design identifies a mechanism that broadband-only designs miss: matching and accessibility. If learners benefit because content becomes understandable and style-matched, language supply shocks should show strong effects even conditional on internet access levels.

It also gives a distribution angle: effects should be larger in language communities previously underserved by educational content.

### Key threats and fixes

1. Endogenous content growth (content rises where demand already rising).
- Fix: instrument $\Delta Supply_{\ell t}$ with creator-side shocks (policy/monetization/translation-tool rollouts by language).

2. Correlated migration/composition changes by language.
- Fix: hold pre-period language shares fixed; add migration controls; robustness on non-mover subsamples where possible.

3. Language-specific macro shocks.
- Fix: language-by-time controls in expanded panels if feasible.

### Minimal feasibility threshold

You need:
1. A language-by-time tutorial supply panel (by topic).
2. Baseline regional language shares.
3. Regional outcome panel for skill proxies.

Without (1), this design is not viable.

## 6) Where to get data for Empirical 1 and 2

Empirical 1 in shortlist: Skill-task heterogeneity DDD.
Empirical 2 in shortlist: Broadband speed-threshold DiD.

### Data for Empirical 1 (DDD, institutional panel)

Best path is partner/admin education or training data where learners are repeatedly tested across modules.

What you need:
1. Learner-level panel outcomes by module/task.
2. Task tagging into procedural/visual vs text-heavy.
3. A clear video-access change date (curriculum or platform policy).

Likely sources:
- Universities/colleges: LMS logs + module scores.
- Vocational training providers: practical assessments + online learning logs.
- Certification platforms (coding/IT): question-level attempt logs, completion, pass data.

Public-only fallback:
- Harder. You may need institutional open-data portals plus aggregate outcomes, but this weakens mechanism testing.

### Data for Empirical 2 (Broadband threshold DiD)

You need a geo-time panel linking broadband quality to outcomes.

Core inputs:
1. Broadband quality/availability over time by small geography.
2. A streaming-feasibility threshold (for example, minimum speed for stable educational video).
3. Skill outcomes at matching geography-time level.

US candidates:
- FCC broadband deployment/speed datasets (coverage by census geography).
- M-Lab/Ookla-type measured speed panels (where accessible).
- Outcomes from ACS/CPS-linked occupational/certification proxies or state education/workforce data.

UK candidates:
- Ofcom/Openreach broadband availability/speed data.
- ONS regional labor/skills datasets.
- Education/vocational outcomes from DfE or awarding bodies (subject to access level).

Notes:
- Choose one country first to reduce merge complexity.
- Align geography early (ZIP/census tract vs local authority/MSOA etc.).

## 7) What about the metal music idea?

Short answer: keep it, but not as Paper 1.

### Why it is still valuable

The idea is conceptually strong for learning-by-viewing. Metal technique is highly procedural, imitation-friendly, and likely sensitive to demonstration quality. It is a good domain to showcase diffusion and best-practice channels.

### Why it is weak for first identification

Main constraints are measurement and data construction:
1. Building a credible technicality index is heavy and potentially contestable.
2. Exposure data at region/cohort level is hard without proprietary platform data.
3. Confounds from production technology trends and genre evolution are substantial.

### Best way to keep it alive

Treat it as a follow-on paper or side project:
1. Start with a narrower instrument-learning domain (guitar/piano exams) with standardized outcomes.
2. Reuse the same model framework (learning curve + precision).
3. Add music-specific complexity measures only after causal pipeline is proven in a cleaner domain.

### If you insist on a metal pilot now

Do a descriptive-plus design memo first, not full causal execution:
1. Define 2-3 technicality metrics.
2. Build a small validation set with expert ratings.
3. Check whether variation is measurable and stable over time before committing.
