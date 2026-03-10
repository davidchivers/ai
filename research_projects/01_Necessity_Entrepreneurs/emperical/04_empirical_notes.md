# Strategy 1: Displacement-based worker-to-business panel

**Strategy type:** Event study or matched-difference design using worker histories linked to business formation records.

**Literature.**
Fairlie (2013), Fairlie and Fossen (2019), and Fossen (2021) show that weaker labor-market
conditions and unemployment matter for entrepreneurial entry, especially at the lower-scale
margin. Fairlie and Miranda (2016) show that the first-worker margin is distinct from
nonemployer entry. Sedlacek and Sterk (2017) imply that entrant quality and scale also move
over the cycle.

**How this applies to the question.**
Use workers hit by plant closures or mass layoffs and compare them with similar workers not
hit by those shocks. Link pre-entry labor-market histories to business formation records and
separate entry into nonemployer businesses from entry into employer businesses. A baseline
equation is `Y_it^k = alpha_i + gamma_t + sum_tau beta_tau^k * 1[event_time=tau] + epsilon_it`,
where `k` includes nonemployer entry, employer entry, first payroll, initial employment, and
one-year survival. The key threat is that layoffs can coincide with local demand shocks that
also affect business opportunities. The cleanest mitigation is to focus on plant closures or
mass-layoff events, add industry-by-time controls, and check pre-trends. Feasibility is high
if restricted worker-business linked data are realistic; otherwise it is not.

**References.**
Fairlie (2013); Fairlie and Fossen (2019); Fossen (2021); Fairlie and Miranda (2016);
Sedlacek and Sterk (2017).

# Strategy 2: Unemployment-insurance variation and entry composition

**Strategy type:** Policy quasi-experiment using changes in UI generosity, duration, or exhaustion rules.

**Literature.**
This strategy fits the paper directly because the model's main comparative statics run through
outside options and social insurance. The existing project draft already studies the UI margin
structurally, while Fairlie and Fossen (2019) provide the empirical motivation for separating
opportunity and necessity entry.

**How this applies to the question.**
Exploit sharp changes in UI rules across states or over time and estimate how entry composition
responds. With microdata, the baseline equation is `Y_ist^k = alpha_i + delta_s + gamma_t +
beta_k * UI_st + epsilon_ist`. With public aggregates, the same logic can be estimated at the
state-month or state-year level using business applications, high-propensity applications,
nonemployer counts, and CPS transitions into self-employment. The main threat is policy
endogeneity: UI changes often occur when the labor market is already deteriorating. The design
therefore needs event studies, border or neighboring-state comparisons where possible, and
careful separation of recession timing from policy timing. Feasibility is moderate: it is
easier than the linked-worker design, but causal credibility is weaker unless the policy shock
is unusually sharp.

**References.**
Fairlie and Fossen (2019); project draft UI ladder and sidecar data notes.

# Strategy 3: Local labor-demand shocks with public entry-composition outcomes

**Strategy type:** Shift-share or mass-layoff exposure design using local-area panels.

**Literature.**
Fairlie (2013) and Fossen (2021) suggest that weaker labor demand raises lower-scale entry.
Sedlacek and Sterk (2017) and Haltiwanger (2012) imply that employer-oriented formation and
startup job creation are much more cyclical.

**How this applies to the question.**
Use local labor-demand shocks as outside-option shifters and map them to a panel of entry
composition outcomes. A baseline equation is `Y_ct^k = delta_c + gamma_t + beta_k * Shock_ct +
epsilon_ct`, where `k` includes total business applications, high-propensity application share,
nonemployer establishment growth, employer establishment growth, and CPS self-employment
transitions where available. This design does not classify individuals, but it can identify
whether worsening outside options shift activity toward low-scale entry and away from
employer-oriented entry. The main threat is that local shocks can also move product demand,
credit, and housing conditions, so the interpretation is cleaner as a composition design than
as a pure person-level necessity label. Feasibility is high because most of the required public
series are already close to the project's current sidecar workflow.

**References.**
Fairlie (2013); Fossen (2021); Sedlacek and Sterk (2017); Haltiwanger (2012).

# Strategy 4: Latent necessity score using multiple indicators

**Strategy type:** Measurement model or posterior classification using linked survey and administrative indicators.

**Literature.**
This is less common as a single canonical design, but it follows naturally from the literature's
mixed proxy problem. GEM captures motives, prior-status designs capture transitions, and
business-form evidence captures scale. The point here is to combine them instead of pretending
one proxy is enough.

**How this applies to the question.**
Construct a posterior probability that an entrant is necessity-driven using variables such as
pre-entry employment status, recent displacement, UI receipt or exhaustion, initial payroll,
industry, survival, and motive responses where available. One practical version is a supervised
or semi-structured score estimated on a subset where the outside-option shock is especially
clear, then applied more broadly. The key weakness is that this is a measurement exercise, not
clean causal identification, and it will be sensitive to modeling choices. Its best role is as a
secondary classification layer after a cleaner shock-based design, not as the main empirical
claim.

**References.**
Fairlie and Fossen (2019); GEM U.S. microdata note; Fairlie and Miranda (2016); Hurst and
Pugsley (2011).
