# 03 model notes

Last updated: 2026-03-02

## Intuition first

This project extends the project-02 NIMBY housing-politics mechanism with a fertility channel.
The key question is whether a temporary baby boom can worsen later housing tightness through
political feedback, and then reduce fertility in later periods.

Current prototype result from MATLAB:

1. During the baby-boom window, fertility rises mechanically (by construction).
2. As boom cohorts age into the political block, housing supply tightens (higher `theta`).
3. In the calibrated run, post-boom prices are higher and post-boom fertility is lower
   relative to baseline in the new model.

This is a mechanism result, not yet a quantified statement about the US data.

## Variables and state

Core state variables in the implemented prototype:

- `M_t(j)`: population share in age bin `j`
- `p_t`: housing price index
- `theta_t`: political supply tightness
- `b_t`: births
- `f_t`: fertility rate among fertile-age bins
- `n_home_t`: lagged births proxy for children-at-home demand pressure

Key parameters currently used:

- horizon `T = 80`
- fertility block: `f_level`, `f_price_semi_elasticity`
- politics block: `theta0`, `theta_old`, `theta_young`, `theta_boom_nimby`
- supply elasticity: `eps0`
- demand sensitivities: `d0`, `d_young`, `d_birth`

## Implemented equations

### fertility choice — reduced-form (original prototype)

Desired fertility rate:

$$
f_t^* = \text{clip}\left(f_{level}\exp(-\eta_p p_t),\,0.05,\,0.85\right)
$$

Observed births with temporary baby-boom shock multiplier `\mu_t`:

$$
b_t = f_t^* \cdot \sum_{j\in \mathcal{F}} M_t(j)\cdot \mu_t
$$

where `\mu_t = 1 + \text{boom\_amp}` on `t \in [t_{start}, t_{end}]`, else `1`.

### fertility choice — structural FOC (new, added 2026-03-02)

Fertility is now also solved from the crowding-utility first-order condition.
The representative fertile-age household allocates income between consumption and housing
via Cobb-Douglas demand: `c = (1-zeta)*y`, `h = zeta*y/p_h`. Given these, optimal
fertility `n*` solves the FOC:

$$
\chi \, n^{-\eta} = \frac{\zeta \psi_c \lambda}{1 + \lambda \, n_{total}} \left[c^{1-\zeta} \, h_{eff}^{\zeta}\right]^{1-\gamma}
$$

where `n_total = n_{home,current} + n` (existing children plus new), and
`h_eff = h / (1 + lambda * n_total)^{psi_c}`.

LHS = marginal utility of an additional child.
RHS = marginal crowding cost through reduced effective housing.

This is solved by bisection in `solve_fertility_foc()`. The structural model
runs alongside the reduced-form and old-proxy models for comparison.

New parameters for structural model:
- `zeta = 0.20`: housing share in Cobb-Douglas utility
- `gamma_risk = 2.0`: risk aversion
- `chi = 0.15`: weight on child utility
- `eta_child = 0.50`: curvature on child utility
- `lambda_crowd = 0.30`: crowding sensitivity per child
- `psi_crowd = 0.60`: crowding exponent

### political tightness

$$
\theta_t = \text{clip}\Big(
\theta_0 + \theta_{old}\cdot old_t - \theta_{young}\cdot young_t
+ \theta_{boom}\cdot \overline{b}_{t-\ell:t-\ell-w+1},
\,0,\,0.95\Big)
$$

The final term is the lagged baby-boom cohort entry into the NIMBY voter block.

### housing market update

Demand:

$$
D_t = d_0 + d_{young}\cdot young_t + d_{birth}\cdot b_t + 0.15\cdot n\_home_t
$$

Supply:

$$
S_t = s_0 + \varepsilon_0(1-\theta_t)\exp(-p_t)
$$

Price law of motion:

$$
p_{t+1} = (1-\lambda)p_t + \lambda\left[p_t + g(D_t - S_t)\right]
$$

## Experiment design used in latest run

- Baseline: no baby-boom shock
- Shock run: temporary baby-boom shock of `+60%` births from `t=15` to `t=24`
- Damping: `0.25`
- Comparison: new model vs old proxy (old proxy has no endogenous fertility response)
- Post window for interpretation: `t >= 40`

Latest outputs are in:

- `notes/build/comparison_summary_old_vs_new.csv`
- `notes/build/comparison_phase_summary.csv`
- `notes/build/old_vs_new_model_comparison_report.md`

## What the current model shows

From the latest `comparison_phase_summary.csv`:

- Reduced-form and structural FOC models both show: `delta_price_post > 0` and `delta_fertility_post < 0`
- Interpretation: the temporary baby boom can tighten future housing politics and slightly
  depress fertility later, conditional on this calibration.
- The structural FOC model derives fertility from utility maximisation rather than a
  semi-elasticity, making the price-fertility link internally consistent with the
  crowding mechanism written up in the paper.

## What it does not show

1. It does not identify causal effects in real US data.
2. It does not yet include explicit migration/immigration flows in demographic accounting.
3. It is not yet the full project-02 heterogeneous-agent steady-state MATLAB stack
   (value function iteration over individual households with idiosyncratic income shocks).
   The structural FOC model uses a representative-agent allocation within the aggregate
   simulation framework.

## Mapping to project-02

This prototype is intentionally close in spirit to project 02:

1. Political housing-supply tightness is the core channel.
2. A demographic shock is introduced (baby boom), then transmitted through politics.
3. The fertility extension is the added channel in project 03.

Next implementation step is to port this extension onto the full project-02 MATLAB system
once upstream data files are available.

## NIMBY-style write-up block (differences highlighted)

Use this structure to mirror the model write-up style in
`02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx`
while making project-03 changes explicit.

### Model environment (same core architecture as project 02)

As in project 02, households live through the life cycle, choose consumption/saving/housing,
and vote over housing-supply tightness through a median-voter political equilibrium.
Demographics shift the voting coalition and therefore equilibrium housing costs over time.

### Household problem and utility (project-03 difference)

Project-02 baseline utility is over consumption, housing services, and bequests. Project 03 adds
an endogenous fertility margin that is negatively linked to housing costs:

$$
f_t^* = \text{clip}\left(f_{level}\exp(-\eta_p p_t),\,0.05,\,0.85\right),\qquad
b_t = f_t^* \cdot \sum_{j\in \mathcal{F}} M_t(j)\cdot \mu_t.
$$

Interpretation: fertility is no longer an exogenous demographic path only; it becomes a channel
through which housing tightness can feed back into later births.

### Political block and equilibrium (project-03 difference)

Project 02 ties political outcomes to lifecycle composition and housing positions. Project 03 keeps
that mechanism and adds a lagged baby-boom cohort term:

$$
\theta_t = \text{clip}\Big(
\theta_0 + \theta_{old}\cdot old_t - \theta_{young}\cdot young_t
+ \theta_{boom}\cdot \overline{b}_{t-\ell:t-\ell-w+1},
\,0,\,0.95\Big).
$$

This is the mechanism for "boom today -> tighter politics later."

### Quantitative results (difference vs project-02-style old proxy)

From `notes/build/comparison_phase_summary.csv` (MATLAB run dated 2026-03-01):

- New model post-shock effects: `delta_price_post = +0.0381`, `delta_fertility_post = -0.00181`.
- Old proxy post-shock effects: `delta_price_post = -0.0856`, `delta_fertility_post = -0.00011`.

Key difference: with the fertility channel active, the post-boom period shows higher prices and
lower fertility relative to baseline; this is the "predict subsequent fertility fall" mechanism
under the current calibration.

### Scope note relative to project 02

- This is currently a prototype extension and not yet the full project-02 steady-state stack.
- Immigration/nativity flows are not yet embedded in the dynamic model state transition.
- Empirical discipline is planned through the US panel build in `notes/04_empirical_notes.md`.

## US fertility data audit (2026-03-02)

Current status of real-data ingestion for project 03:

- `data/raw/cdc_fertility_county_year.csv` exists but currently contains header only (no rows).
- `data/processed/us_fertility_housing_panel_v1.csv` is also header only.
- `notes/build/us_panel_source_coverage.md` reports `rows = 0` for fertility/housing/policy/population/controls.

NIMBY project data lead:

- `02_nimbyism_and_housing_supply/code/data/3 birthrates.do` uses `birthrates_updated`,
  `weights`, and `tenurerates` Stata datasets to build weighted birth-rate panels.
- `02_nimbyism_and_housing_supply/code/data/merge data.do` points to an external Dropbox data path,
  indicating the core `.dta` inputs are not in this repository copy.

Usable in-repo demographic source:

- `02_nimbyism_and_housing_supply/code/data/age state.csv` contains large state-level
  age/sex population series (2010-2018 style columns), but it is not the final county-year fertility
  panel and does not provide nativity-specific fertility rates out of the box.
