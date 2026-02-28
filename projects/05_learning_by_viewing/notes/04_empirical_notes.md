# 04 Empirical notes

Last updated: 2026-02-25

---

# Strategy 1: Mindspark RCT extension

**Strategy type:** Randomised controlled trial with heterogeneity extension.

**Literature.**
Muralidharan, Singh, and Ganimian (2019) evaluate technology-aided instruction in Indian
primary schools using random assignment. Effect sizes are large and credible, with clean
first-stage identification. Banerjee et al. (2007) provide a complementary RCT in a similar
setting that confirms gains from targeted computer-based learning. Both studies report
average treatment effects; neither decomposes effects by task procedural intensity.

**How this applies to the question.**
The Mindspark replication archive (OpenICPSR / J-PAL) provides individual-level treatment
assignment, baseline and endline scores, demographics, attendance, and usage intensity.
The baseline ITT regression replicates the published result:

$$Y_{is1} = \alpha + \beta T_i + \gamma Y_{is0} + X_i'\delta + \varepsilon_i$$

The extension adds a procedurality interaction. Code assessment items or curriculum modules
are scored for procedural intensity $p_j$ (using a rubric based on demonstrability and
sequence dependence), then the heterogeneity regression is:

$$Y_{ij} = \alpha + \beta_1 E_{ij} + \beta_3 (E_{ij} \times p_j) + X_{ij}'\Gamma + u_{ij}$$

Key threats are attrition imbalance (report Lee bounds), endogenous usage (instrument with
assignment), and item comparability over time. Feasibility is high — this is the fastest
credible starting point.

**References.**
Banerjee, A., S. Cole, E. Duflo, and L. Linden (2007). "Remedying Education." *QJE*.
Muralidharan, K., A. Singh, and A. Ganimian (2019). "Disrupting Education?" *AER*.

---

# Strategy 2: OULAD learner-task panel

**Strategy type:** Panel fixed-effects with within-student variation and dynamic event-style checks.

**Literature.**
Kuzilek, Hlosta, and Zdrahal (2017) release the Open University Learning Analytics Dataset,
which contains time-stamped assessment outcomes, student demographics, daily VLE activity
logs, and resource-type indicators across multiple course presentations. The panel structure
supports within-student designs that are infeasible in cross-sectional RCTs.

**How this applies to the question.**
The unit of observation is student-module-week. Video-type VLE resources are coded for
procedural intensity using module content rubrics. The baseline regression exploits
within-student variation:

$$Y_{ijtw} = \alpha_i + \lambda_{jw} + \tau_t + \beta_1 E_{ijtw} + \beta_3 (E_{ijtw} \times p_j) + u_{ijtw}$$

This design is strongest for dynamic mechanism work: leads and lags of exposure test reverse
causality (struggling students clicking more), week-by-module fixed effects absorb timing
confounds, and alternative resource-type codings check measurement sensitivity. Feasibility
is high (public data), but cleaning the VLE logs is nontrivial.

**References.**
Kuzilek, J., M. Hlosta, and Z. Zdrahal (2017). "Open University Learning Analytics Dataset."
*Scientific Data*.

---

# Strategy 3: Broadband rollout and procedural intensity interaction

**Strategy type:** Staggered differences-in-differences / event study using infrastructure rollout.

**Literature.**
Akerman, Gaarder, and Mogstad (2015) show broadband is skill-complementary in Norwegian
labour markets. Vigdor, Ladd, and Martinez (2014) and Fairlie and Robinson (2013) find that
home technology access does not automatically produce achievement gains, underlining that
exposure quality matters. Callaway and Sant'Anna (2021) and Sun and Abraham (2021) provide
modern DiD estimators for staggered designs with heterogeneous treatment effects.

**How this applies to the question.**
The data come from public US sources: FCC Form 477 broadband coverage, Stanford Education
Data Archive (SEDA) achievement scores, and NCES / Census district-level demographics.
Subjects are coded for procedural intensity (e.g., lab science vs reading comprehension).
The baseline regression is:

$$Y_{dgt} = \alpha_d + \lambda_t + \beta_1 Broadband_{dt} + \beta_3 (Broadband_{dt} \times Procedural_g) + X_{dt}'\theta + \epsilon_{dgt}$$

Key threats are concurrent local reforms (add policy controls and district trends),
measurement error in coverage (test alternative broadband definitions), and staggered-timing
bias (use Callaway-Sant'Anna or Sun-Abraham estimators). Feasibility is medium-high: all
data are public but the linkage work is heavier than Strategies 1 and 2.

**References.**
Akerman, A., I. Gaarder, and M. Mogstad (2015). "The Skill Complementarity of Broadband
Internet." *QJE*.
Callaway, B., and P. H. C. Sant'Anna (2021). "DiD with Multiple Time Periods." *J. Econometrics*.
Sun, L., and S. Abraham (2021). "Estimating Dynamic Treatment Effects." *J. Econometrics*.

---

# Strategy 4: Institutional LMS staggered rollout

**Strategy type:** Event study around staggered course or department video-module rollout.

**Literature.**
Figlio, Rush, and Yin (2013) show that modality can affect learning in tightly controlled
settings. Goodman, Melkers, and Pallais (2019) show online delivery can improve access while
leaving performance effects heterogeneous. Both studies underscore that institutional
implementation details shape treatment intensity.

**How this applies to the question.**
The data are Canvas Data 2 or Blackboard logs linked to registrar records at a partner
institution. The event is staggered introduction of video modules at course or department
level. Module-level video availability, watch behaviour, assignment outcomes, grades, and
withdrawals are observed directly. The event-study specification is:

$$Y_{icst} = \alpha_i + \phi_{cs} + \lambda_t + \sum_{k \neq -1} \beta_k \mathbf{1}[t - T_{cs} = k] + X_{it}'\delta + u_{icst}$$

Key threats are non-random rollout timing (adoption-hazard controls and pre-trend checks),
instructor adaptation (instructor FE), and partial compliance (treatment-intensity
extensions). Feasibility is medium — high upside if data access is secured, but data
governance is the binding constraint.

**References.**
Figlio, D., M. Rush, and L. Yin (2013). "Is It Live or Is It Internet?" *J. Labor Economics*.
Goodman, J., J. Melkers, and A. Pallais (2019). "Can Online Delivery Increase Access?" *J. Labor Economics*.

---

# Strategy 5: Threshold-based remediation design

**Strategy type:** Regression discontinuity around a placement cutoff.

**Literature.**
Imbens and Lemieux (2008) provide the practical guide to RD estimation. The design is
standard in education settings where placement tests sort students into remediation tracks
with different instructional modalities. The RD identifies a local average treatment effect
at the cutoff, which is internally clean but narrower in external validity.

**How this applies to the question.**
The data are placement scores, remediation assignment records, LMS instructional module
logs, and course pass/fail outcomes. Students near the cutoff receive different instructional
bundles (video-heavy vs text-heavy remediation). The RD specification is:

$$Y_i = \alpha + \tau D_i + f(Score_i - c) + \mathbf{1}(Score_i \geq c)\, g(Score_i - c) + X_i'\beta + \varepsilon_i$$

Key threats are sorting at the cutoff (McCrary density test), functional-form sensitivity
(local linear estimation and bandwidth sweeps), and narrow external validity (interpret as
near-threshold effect only). Feasibility is medium-low — strong internal validity if the data
are available, but finding a context with a clean cutoff and video-treatment margin requires
institutional cooperation.

**References.**
Imbens, G., and T. Lemieux (2008). "Regression Discontinuity Designs: A Guide to Practice."
*J. Econometrics*.

---

# Strategy 6: YouTube DIY viewership and downstream demand

**Strategy type:** Reduced-form evidence linking YouTube instructional video consumption to real-economy outcomes (demand for inputs, attempt rates, professional service displacement).

**Literature.**
Krasnikov, Jayachandran, and Kumar (2009) document how consumer search behaviour predicts
purchasing patterns. Stephens-Davidowitz (2014) demonstrates that Google search data can
reveal otherwise unobservable behaviour at scale. In the YouTube context specifically, Google
Trends and the YouTube Data API provide category-level and video-level viewership data that
can be linked to real economic activity. On the DIY side, the American Housing Survey and
American Time Use Survey provide direct measures of household self-performance of maintenance
and repair tasks. Autor (2015) provides the task-framework lens for classifying activities by
procedural content.

The intuition is direct: if YouTube teaches people how to change brake pads, we should see
(a) viewership of brake-pad tutorials, followed by (b) increased retail purchases of brake
pads and tools, and (c) reduced demand for mechanic services — all relative to tasks where
video instruction has less bite (e.g. diagnosing an engine warning light, which is more
cognitive/diagnostic than procedural).

**How this applies to the question.**
This strategy tests Model 1's predictions 1–5 using YouTube as the platform and DIY/home
production tasks as the setting. There are several complementary data configurations:

*Configuration A: Cross-task variation in YouTube viewership and input demand.*
Classify DIY tasks by procedural intensity $p_j$ (e.g. "how to replace a toilet flapper"
is high-$p_j$; "how to choose a paint colour" is low-$p_j$). For each task category $j$,
measure YouTube viewership $Views_{jt}$ (from Google Trends YouTube-filtered search or the
YouTube Data API) and a downstream outcome: retail sales of the corresponding input
(auto-parts sales, hardware-store sales by category from Census Retail Trade Survey or
proprietary scanner data). The regression is:

$$\Delta \ln Sales_{jt} = \alpha_j + \lambda_t + \beta_1 \Delta \ln Views_{jt} + \beta_3 (\Delta \ln Views_{jt} \times p_j) + X_{jt}'\Gamma + \varepsilon_{jt}$$

The prediction is $\beta_1 > 0$ (more YouTube views for a task predict higher input demand)
and $\beta_3 > 0$ (the effect is stronger for high-procedurality tasks). First-differencing
or long-differencing absorbs time-invariant task characteristics. Time fixed effects absorb
aggregate trends (e.g. recessions that shift both viewing and spending).

*Configuration B: Geographic variation in YouTube/broadband access.*
Use cross-MSA or cross-county variation in broadband penetration (FCC Form 477) as a shifter
of YouTube access. Link to American Housing Survey data on whether households perform their
own home repairs vs hiring contractors, or to County Business Patterns data on employment in
repair and maintenance services (NAICS 811). The regression is:

$$Y_{ct} = \alpha_c + \lambda_t + \beta_1 Broadband_{ct} + \beta_3 (Broadband_{ct} \times ProceduralShare_c) + X_{ct}'\delta + u_{ct}$$

where $ProceduralShare_c$ measures the area's mix of housing/vehicle stock that generates
procedural maintenance needs. The prediction is that broadband expansion reduces professional
repair employment more in areas with greater scope for DIY substitution.

*Configuration C: Event study around YouTube category-specific content shocks.*
Some DIY categories experience sharp increases in high-quality instructional content (e.g.
a popular creator launches a comprehensive car-repair series, or YouTube introduces a
how-to shelf for a category). An event-study design around these content shocks tests whether
downstream input demand responds:

$$\ln Sales_{jt} = \alpha_j + \lambda_t + \sum_{k \neq -1} \beta_k \mathbf{1}[t - T_j = k] + u_{jt}$$

Pre-trends in input sales before the content shock validate the design; post-shock increases
in input demand confirm the mechanism.

**Key identification threats and responses.**
- *Reverse causality:* People search YouTube *because* they already decided to do the task.
  Response: use broadband rollout or platform-level content shocks as instruments that shift
  video availability but not underlying task demand. Also: leads of viewership should not
  predict past sales if the direction is views → demand.
- *Confounders:* Macroeconomic conditions simultaneously drive both viewing (more free time
  in recessions) and spending patterns. Response: time fixed effects, controls for local
  unemployment, and cross-task within-time comparisons.
- *Measurement:* YouTube viewership data are noisy and category boundaries are imprecise.
  Response: use multiple viewership proxies (Google Trends, Social Blade, YouTube API),
  show robustness across alternative task-category definitions.

**Data sources.**
- YouTube viewership: Google Trends (filtered to YouTube Search), YouTube Data API v3
  (video-level metadata and view counts by category), Social Blade (channel-level trends).
- Input demand: Census Monthly Retail Trade Survey (NAICS 4413 auto parts, 4441 building
  materials), NPD/Circana scanner data, Amazon product-category sales ranks.
- Professional services: County Business Patterns (NAICS 811 repair and maintenance),
  Bureau of Labor Statistics OES (mechanic and tradesperson employment), Angi/HomeAdvisor
  service request data.
- Household self-performance: American Housing Survey (home repair questions), American Time
  Use Survey (home maintenance time), ATUS Well-Being Module.
- Task classification: O*NET task content descriptors, manual coding of YouTube categories
  for procedural intensity using the rubric from Model 1.

**Feasibility.** High for Configuration A (all data are public or cheaply accessible).
Medium-high for Configuration B (FCC and AHS/CBP linkage is standard). Medium for
Configuration C (requires identifying clean content shocks and precise timing).

**References.**
Autor, D. (2015). "Why Are There Still So Many Jobs?" *JEP*.
Krasnikov, A., S. Jayachandran, and V. Kumar (2009). "The Impact of Customer Relationship
Management on Cost and Profit Efficiencies." *J. Marketing*.
Stephens-Davidowitz, S. (2014). "The Cost of Racial Animus on a Black Candidate." *J. Public Economics*.
