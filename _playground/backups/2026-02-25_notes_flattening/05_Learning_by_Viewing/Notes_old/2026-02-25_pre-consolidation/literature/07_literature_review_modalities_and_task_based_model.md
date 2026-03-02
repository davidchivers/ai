# Literature Review: Learning Modalities and a Task-Based Model Direction

Date: 2026-02-24  
Project: Learning by Viewing

## 1) Scope

Question: what does credible evidence say about relative effectiveness of learning modalities (reading/text-diagram, video/dynamic visuals, tutoring), and how should that shape the model?

This note focuses on verified sources and extracts findings that directly inform model primitives and empirical design.

## 2) Verified literature (selected)

### A. Economics evidence on instruction mode and learning technology

1. Banerjee, Cole, Duflo, Linden (2007), QJE, "Remedying Education"  
DOI: 10.1162/qjec.122.3.1235  
Link: https://academic.oup.com/qje/article-abstract/122/3/1235/1879525

2. Bettinger, Fox, Loeb, Taylor (2017), AER, "Virtual Classrooms"  
DOI: 10.1257/aer.20151193  
Link: https://www.aeaweb.org/articles?id=10.1257/aer.20151193

3. Muralidharan, Singh, Ganimian (2019), AER, "Disrupting Education?"  
DOI: 10.1257/aer.20171112  
Link: https://www.aeaweb.org/articles?id=10.1257/aer.20171112

4. Escueta, Quan, Nickow, Oreopoulos (2017), NBER review  
DOI: 10.3386/w23744  
Link: https://www.nber.org/papers/w23744

5. Nickow, Oreopoulos, Quan (2020), tutoring meta-analysis, NBER  
DOI: 10.3386/w27476  
Link: https://www.nber.org/papers/w27476

### B. Learning-science evidence on text/diagram vs dynamic visual/video vs tutoring

6. Ginns (2005), Learning and Instruction, "Meta-analysis of the modality effect"  
DOI: 10.1016/j.learninstruc.2005.07.001  
Link (journal issue index with article DOI): https://www.sciencedirect.com/journal/learning-and-instruction/vol/15/issue/4

7. Hoffler and Leutner (2007), Learning and Instruction, animation vs static visuals meta-analysis  
DOI: 10.1016/j.learninstruc.2007.09.013  
Link: https://www.sciencedirect.com/science/article/pii/S0959475207001077

8. Mayer and Moreno (2003), Educational Psychologist, cognitive load in multimedia learning  
DOI: 10.1207/S15326985EP3801_6  
Link (DOI landing): https://doi.org/10.1207/S15326985EP3801_6

9. VanLehn (2011), Educational Psychologist, human tutoring vs ITS  
DOI: 10.1080/00461520.2011.611369  
Link (DOI landing): https://doi.org/10.1080/00461520.2011.611369

### C. Task-based economics framework to adapt for learning modalities

10. Acemoglu and Autor (2011), Skills, Tasks and Technologies  
DOI (working paper): 10.3386/w16082  
Link: https://www.nber.org/papers/w16082

11. Acemoglu and Restrepo (2019), JEP, Automation and New Tasks  
DOI (working paper): 10.3386/w25684  
Link: https://www.nber.org/papers/w25684

## 3) Literature findings that matter for this project

### Finding 1: "Technology in education" is not uniformly positive; design and integration matter

In economics RCT evidence, outcomes vary sharply by pedagogy and targeting. Banerjee et al. (2007) and Muralidharan et al. (2019) show large gains when instruction is targeted to learner level and integrated into a coherent learning process. Bettinger et al. (2017) shows that online course mode can reduce outcomes relative to in-person for college students in that context.

Inference for us: modality alone is not treatment; modality x task x pedagogy is treatment.

### Finding 2: Dynamic visuals/video tend to help more on procedural-motor and change-over-time content

Hoffler and Leutner (2007) report that animation advantages are much stronger when content is procedural-motor and representational (not decorative). This directly fits the "learning by viewing" hypothesis for tacit tasks.

Inference for us: gains should be heterogeneous by task type, not averaged across all tasks.

### Finding 3: Modality effects are conditional, not universal

Ginns (2005) and related modality literature imply positive average effects for dual-channel designs, but boundary conditions matter (pacing, cognitive load, design quality). Mayer and Moreno (2003) reinforces that poor multimedia design can overload rather than help.

Inference for us: add quality/clarity and cognitive-load channels explicitly in the empirical plan.

### Finding 4: Tutoring is robustly effective, and can benchmark video effects

Nickow et al. (2020) show strong average tutoring effects. VanLehn (2011) suggests well-designed intelligent tutoring can approach human tutoring in some settings.

Inference for us: tutoring is a natural comparator and complement arm, not just a control.

### Finding 5: A task-based framework is the right way to discipline the model

Acemoglu-style task frameworks organize heterogeneity through task characteristics and comparative advantage. For learning, the analog is: each modality has different productivity across task attributes.

Inference for us: model tasks as units to which different learning technologies are assigned.

## 4) Task-based model direction (recommended)

### 4.1 Core structure

Let tasks be indexed by $j$ with attributes:
- $p_j$: procedural/tacit intensity
- $c_j$: conceptual/text intensity
- $r_j$: risk of harmful error
- $q_j$: verifiability of outcomes

Let modality be $m \\in \\{R, V, T\\}$:
- $R$: reading/diagrams
- $V$: video/dynamic demonstration
- $T$: tutoring (human or high-quality interactive system)

Learner $i$ chooses modality-task effort allocation to maximize expected skill gains net of costs.

### 4.2 Learning production function

For learner $i$, task $j$, modality $m$:

$$
\\Delta S_{ijm}
= \\alpha_j
+ \\beta_m
+ \\gamma_{mp} p_j
+ \\gamma_{mc} c_j
+ \\gamma_{mr} r_j
+ \\eta_i
+ \\kappa X_i
- C_{ijm}
+ \\varepsilon_{ijm}
$$

Key testable restrictions:
1. $\\gamma_{Vp} > \\gamma_{Rp}$ (video advantage for procedural tasks).
2. $\\gamma_{Rc} \\ge \\gamma_{Vc}$ in some conceptual-heavy tasks (possible reading advantage).
3. $\\gamma_{Tr} > \\gamma_{Vr}$ when risk is high (tutoring advantage on high-risk tasks).

### 4.3 Choice/assignment margin

Learners (or institutions) choose modality:

$$
m_{ij}^* = \\arg\\max_m \\left\\{ E[\\Delta S_{ijm}] - C_{ijm} \\right\\}
$$

This produces a clean empirical implication: treatment effects of video are largest where task attributes imply high relative productivity of video over alternatives.

### 4.4 Dynamic extension (optional, still simple)

Add cumulative practice $h_{ij,t}$:

$$
S_{ij,t+1} = S_{ij,t} + f_m(p_j,c_j,r_j)\\cdot h_{ij,t} - \\delta S_{ij,t}
$$

This nests your previous learning-curve idea while making the slope task-modality specific.

### 4.5 Acemoglu-style task assignment variant (learning, not automation)

Let tasks be indexed by $j \\in [0,1]$ with learnability profile $\\ell_j$ (how quickly performance improves with instruction) and procedural intensity $p_j$.

Define modality-specific productivity for learning:

$$
\\Pi_m(j)=A_m\\exp(\\rho_m p_j + \\zeta_m \\ell_j), \\quad m \\in \\{R,V,T\\}.
$$

For learner $i$, effective gain from assigning modality $m$ to task $j$ is:

$$
G_{ijm}=\\Pi_m(j)\\,h_{ij}-C_{ijm},
$$

where $h_{ij}$ is effort and $C_{ijm}$ is modality-specific cost.

Assignment rule:

$$
m_{ij}^*=\\arg\\max_m G_{ijm}.
$$

Prediction: as $p_j$ and $\\ell_j$ rise, the mass of tasks assigned to video should increase when $\\rho_V > \\rho_R$ and $\\zeta_V > \\zeta_R$.

Inference for design: estimate treatment heterogeneity as a function of task-level learnability and procedural intensity, not just average video effects.

## 5) What this means for empirical design

### 5.1 Why DDD is now even more compelling

A triple-difference design can directly map to the model:
- before/after video-access change,
- high-$p_j$ versus low-$p_j$ tasks,
- treated versus control groups.

This estimates task-modality interaction terms rather than only average mode effects.

### 5.2 Comparator structure should include tutoring where possible

Because tutoring has strong prior evidence, including a tutoring margin (or proxy for tutoring access) gives a policy-relevant benchmark: is video a substitute, complement, or inferior for high-risk/high-feedback tasks?

### 5.3 Quality matters as a first-order moderator

Include content quality proxies (e.g., instructor quality metrics, completion/rewatch behavior, pedagogical structure tags) because literature implies modality effects depend on design quality.

## 6) Answer to your model uncertainty (bottom line)

You should not pick "learning curve only" or "Bayesian only" as the full model right now.

Best path:
1. Use a task-based reduced-form core model (above) as the organizing framework.
2. Keep the learning-curve dynamic as a tractable extension.
3. Use Bayesian precision interpretation for mechanism tests (error variance compression, novice effects).

This keeps the model empirical-first, literature-consistent, and tightly connected to identification.

## 7) Next step I recommend

Rewrite `Notes/empirical/03_design_memo_v1.md` around this task-based structure:
1. Define task taxonomy (high/low procedural; high/low risk).
2. State baseline DDD equation with task interactions.
3. Specify the minimum data needed to classify tasks and modality exposure.
4. Pre-specify two falsification tests:
   - no effect on low-procedural tasks,
   - stronger effects where video quality is higher.

