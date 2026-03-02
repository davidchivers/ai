# 03 Model notes

Last updated: 2026-02-25

---

# Model 1: Task-biased instructional technology

**Model type:** Task-based production model with technology-task complementarity.

**Literature.**
Autor, Levy, and Murnane (2003) and Acemoglu and Autor (2011) show that technology is not
skill-neutral — it substitutes for or complements specific tasks rather than affecting all
work uniformly. The relevant unit of analysis is the task, not the worker. Technology
interacts with task content, and the distribution of gains across workers follows from which
tasks they perform.

The cognitive foundation comes from Mayer and Moreno (2003): visual demonstration is
particularly effective for tasks that depend on sequence, timing, and execution — where the
visual channel carries information that text cannot. This provides a direct micro-level
mechanism for task-biased effects in a learning context.

On the consumer/household production side, Becker (1965) formalises the idea that households
combine market goods with their own time and skill to produce final consumption. Aguiar and
Hurst (2007) show that home production is quantitatively large and that time allocation
between market and home production responds to relative prices. The key insight for us is
that a reduction in the cost of acquiring task-specific skill shifts the make-or-buy margin:
tasks that were previously outsourced to professionals become feasible for households to
perform themselves.

**How this applies to the question.**

*Setup.* There is a continuum of tasks indexed by $j \in [0,1]$. Each task has a procedural
intensity $p_j \in [0,1]$ that measures how much the task depends on demonstrated sequence,
timing, and physical execution — features that are uniquely well-conveyed by video relative
to text or verbal instruction. Tasks with high $p_j$ include car brake replacement, tile
grouting, guitar chord transitions; low-$p_j$ tasks include tax filing, essay writing,
vocabulary study.

*Skill production.* Individual $i$ can acquire skill in task $j$ by investing time in
learning. The learning technology is:

$$h_{ij} = f(e_{ij},\; V_j,\; p_j)$$

where $e_{ij}$ is learning effort (time), $V_j$ is the availability and quality of
instructional video for task $j$, and $p_j$ is procedural intensity. The critical assumption
is a positive cross-partial:

$$\frac{\partial^2 h_{ij}}{\partial V_j \, \partial p_j} > 0$$

Video raises the marginal product of effort more for high-procedurality tasks. This is the
task-bias assumption. It follows directly from the cognitive science: video's comparative
advantage over text is largest when learning requires observing motion, sequence, and spatial
relationships.

A tractable functional form is:

$$h_{ij} = e_{ij}^{\alpha} \left[ 1 + \gamma(p_j)\, V_j \right]$$

where $\gamma(p_j)$ is increasing in $p_j$ (e.g. $\gamma(p_j) = \gamma_0 + \gamma_1 p_j$
with $\gamma_1 > 0$). Without video ($V_j = 0$), skill depends only on effort. With video,
the return to effort is amplified, and the amplification is larger for procedural tasks.

*Task performance and the make-or-buy decision.* Individual $i$ can either perform task $j$
themselves (home production) or outsource it at market price $w_j$. Self-performance yields
value $v(h_{ij})$ where $v$ is increasing and concave. The individual performs the task
themselves if:

$$v(h_{ij}) - c(e_{ij}) \geq v_0 - w_j$$

where $c(e_{ij})$ is the cost of learning effort and $v_0 - w_j$ is the net payoff from
outsourcing. An increase in $V_j$ raises $h_{ij}$ for given effort, which shifts the
make-or-buy margin: tasks that were previously outsourced become worth learning. The key
comparative static is that this shift is larger for high-$p_j$ tasks because video raises
skill more in those tasks.

*Access and the distributional dimension.* Before platforms like YouTube, acquiring
procedural skill required access to a knowledgeable person — an apprenticeship, a paid
course, a friend or family member who could demonstrate. This access was scarce and unevenly
distributed across income, geography, and social networks. Let $\theta_i$ index individual
$i$'s pre-platform access to instructional demonstration (a reduced-form summary of social
capital, proximity to training institutions, and ability to pay for courses). Individuals
with high $\theta_i$ (e.g. those with a mechanic in the family, or who can afford a
woodworking class) could already learn procedural tasks; those with low $\theta_i$ could not.

YouTube (and similar platforms) effectively sets $V_j > 0$ for a vast range of tasks and
makes it available to anyone with an internet connection, regardless of $\theta_i$. Formally,
before YouTube:

$$h_{ij} = e_{ij}^{\alpha} \left[ 1 + \gamma(p_j)\, \theta_i \right]$$

and after YouTube:

$$h_{ij} = e_{ij}^{\alpha} \left[ 1 + \gamma(p_j)\, (\theta_i + V_j) \right]$$

The additive structure means YouTube is a substitute for pre-existing social access to
demonstration. The marginal effect of YouTube is therefore largest for individuals with low
$\theta_i$ — precisely those who lacked prior access to instructional demonstration. This
generates a distributional prediction: the platform democratises procedural skill acquisition.
Individuals who were previously excluded from learning high-$p_j$ tasks (because they lacked
social connections or income to access instruction) now face the same effective learning
technology as everyone else.

Integrating across the population, the aggregate attempt rate is:

$$A_j = \int \mathbf{1}\!\left[ v(h_{ij}) - c(e_{ij}^*) \geq v_0 - w_j \right] dF(\theta_i)$$

where $e_{ij}^*$ is optimal effort. An increase in $V_j$ brings individuals at the lower end
of the $\theta_i$ distribution above the self-performance threshold, expanding $A_j$ from
below. This has three additional aggregate implications: (i) the variance of skill in task $j$
falls as the lower tail catches up; (ii) the correlation between socioeconomic status and
self-performance weakens; and (iii) the gains are concentrated among groups historically
excluded from informal knowledge networks (lower-income households, rural areas, immigrants
without local social ties).

*Aggregate predictions.* Define the attempt rate $A_j$ as the share of individuals who
choose to perform task $j$ themselves. The model predicts:

1. **Level effect:** $\partial A_j / \partial V_j > 0$ — video availability increases
   self-performance across all tasks.
2. **Task-bias effect:** $\partial^2 A_j / \partial V_j \, \partial p_j > 0$ — the increase
   in self-performance is larger for more procedural tasks.
3. **Input demand effect:** As individuals shift from outsourcing to self-performance, demand
   for complementary inputs (parts, materials, tools) rises. This is because outsourcing
   bundles labour and materials, while self-performance requires purchasing materials
   separately. So $\partial D_j^{materials} / \partial V_j > 0$, again with a stronger
   effect for high-$p_j$ tasks.
4. **Outsourcing displacement:** Demand for professional services in task $j$ falls as $V_j$
   rises, with a larger decline for high-$p_j$ tasks where video closes more of the skill
   gap.
5. **Democratisation effect:** The increase in $A_j$ is concentrated among low-$\theta_i$
   individuals. The SES gradient of self-performance in high-$p_j$ tasks flattens after
   platform access. Rural areas, lower-income households, and communities with thinner social
   networks gain most.

*Mapping to data.* The task-bias prediction maps to the interaction regression:

$$Y_{ij} = \mu_i + \mu_j + \beta_1 E_{ij} + \beta_3 (E_{ij} \times p_j) + X_{ij}' \Gamma + \varepsilon_{ij}$$

where $p_j$ is measured from task content data (O*NET-style procedurality coding or
curriculum rubrics), $E_{ij}$ is effective video exposure, and the prediction is $\beta_3 > 0$.

The input-demand and outsourcing-displacement predictions generate observable implications
outside of educational test scores: retail sales of task-specific inputs (auto parts, lumber,
plumbing fittings) should respond positively to video availability for the corresponding
task, while demand for professional services (mechanics, contractors, plumbers) should respond
negatively.

**References.**
Acemoglu, D., and D. Autor (2011). "Skills, Tasks and Technologies." *Handbook of Labor Economics*.
Aguiar, M., and E. Hurst (2007). "Measuring Trends in Leisure." *QJE*.
Autor, D., F. Levy, and R. Murnane (2003). "The Skill Content of Recent Technological Change." *QJE*.
Becker, G. (1965). "A Theory of the Allocation of Time." *Economic Journal*.
Mayer, R., and R. Moreno (2003). "Nine Ways to Reduce Cognitive Load." *Educational Psychologist*.

---

# Model 2: Human-support complementarity

**Model type:** Multi-input production model with substitution and complementarity between instructional modalities.

**Literature.**
Bloom (1984) establishes that one-to-one tutoring produces two-sigma gains over conventional
instruction, setting a practical upper benchmark. Nickow, Oreopoulos, and Quan (2020)
confirm large average tutoring effects in modern experimental evidence. Muralidharan, Singh,
and Ganimian (2019) show that technology-aided instruction generates large gains that partly
overlap with tutoring effects but arise through different channels. The open question is
whether viewing and human support are complements (each raises the marginal product of the
other) or substitutes (one displaces the other).

**How this applies to the question.**
The model adds a second input — support intensity $S_{ij}$ (tutoring, teacher help, lab
supervision) — alongside video exposure $E_{ij}$. The key claim is that the relationship
between these two inputs depends on task risk and complexity. For complex or high-risk
procedural tasks (e.g. chemistry labs, surgical technique), viewing provides the sequence
demonstration but a tutor provides the safety net and error correction — they complement
each other. For simple repetitive tasks (e.g. vocabulary drills), viewing alone suffices and
the tutor adds little — they substitute.

This generates a three-way interaction as the estimand:

$$Y_{ij} = \mu_i + \mu_j + \beta_1 E_{ij} + \beta_2 S_{ij} + \beta_3 (E_{ij} \times S_{ij}) + \beta_4 (E_{ij} \times S_{ij} \times Risk_j) + X_{ij}'\Gamma + \varepsilon_{ij}$$

The prediction is $\beta_4 > 0$: viewing and support are more complementary in higher-risk
tasks. This has direct policy implications for how to bundle instructional inputs.

**References.**
Bloom, B. (1984). "The 2 Sigma Problem." *Educational Researcher*.
Muralidharan, K., A. Singh, and A. Ganimian (2019). "Disrupting Education?" *AER*.
Nickow, A., P. Oreopoulos, and V. Quan (2020). "The Impressive Effects of Tutoring." *NBER WP 27476*.

---

# Model 3: Quality-adjusted exposure and content heterogeneity

**Model type:** Measurement model linking raw access to effective treatment through content quality.

**Literature.**
Guo, Kim, and Rubin (2014) show that video production choices (length, format, pacing,
instructor visibility) correlate strongly with learner engagement on MOOC platforms. Kizilcec,
Piech, and Schneider (2013) document distinct engagement trajectories across learner types,
implying that the same raw access generates very different realised exposure. Reich (2015)
cautions that most early MOOC inference lacked strong counterfactuals, partly because access
was conflated with effective treatment.

**How this applies to the question.**
This model is about measurement, not a separate causal claim. The argument is that raw
access $A_{jt}$ (platform availability, broadband) is a poor proxy for the actual treatment.
Effective exposure should be quality-adjusted:

$$E_{ijt} = A_{jt} \times Completion_{ijt} \times Quality_{jt}$$

where $Quality_{jt}$ reflects content design features (demonstrability, segmentation,
pacing). The practical implication is that regressions using binary access indicators will
attenuate estimates of the true exposure-procedurality interaction. The measurement model
tells us which treatment definition to prefer in empirical work: completion-weighted,
quality-adjusted exposure rather than access dummies. Strategies 1 and 2 in the empirical
notes can implement this because they observe usage intensity and resource-type detail.

**References.**
Guo, P., J. Kim, and R. Rubin (2014). "How Video Production Affects Student Engagement." *ACM L@S*.
Kizilcec, R., C. Piech, and E. Schneider (2013). "Deconstructing Disengagement." *LAK*.
Reich, J. (2015). "Rebooting MOOC Research." *Science*.

---

# Model 4: Dynamic skill accumulation and persistence

**Model type:** Dynamic human-capital model with depreciation and task-specific learning.

**Literature.**
Ben-Porath (1967) provides the foundational framework for dynamic human-capital investment
with diminishing returns and depreciation. In the instructional technology context, the
relevant extension is that viewing-based learning may depreciate at different rates depending
on task type and practice opportunity. Escueta et al. (2017) document that technology-aided
learning gains are highly context-dependent and sometimes fade, suggesting depreciation or
insufficient reinforcement rather than zero effect.

**How this applies to the question.**
The static cross-sectional interaction ($\beta_3 > 0$ from Model 1) is a snapshot. The
dynamic model asks whether effects persist, accumulate, or decay. Skill evolves as:

$$h_{ij,t+1} = (1 - \delta_j)\, h_{ijt} + (\alpha + \beta\, p_j)\, E_{ijt}$$

where $\delta_j$ is a task-specific depreciation rate. This generates two testable dynamic
predictions. First, event-study designs (Strategies 3 and 4) should show growing effects
that level off — the convergence path to steady state. Second, if practice reinforces
viewed learning, then interruptions in practice should produce faster depreciation for
procedural tasks where skill is use-dependent. The OULAD panel (Strategy 2) can test this
with within-student variation across assessment waves.

**References.**
Ben-Porath, Y. (1967). "The Production of Human Capital and the Life Cycle of Earnings." *JPE*.
Escueta, M., V. Quan, A. Nickow, and P. Oreopoulos (2017). "Education Technology: An Evidence-Based Review." *NBER WP 23744*.
