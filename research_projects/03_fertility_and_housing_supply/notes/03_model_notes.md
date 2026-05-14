# 03 model notes

Last updated: 2026-03-22

## Current implemented household benchmark

The active MATLAB object is now the steady-state heterogeneous-household block in
`code/SolveSS_fertility.m`, not the older aggregate prototype described later in this file.
The older reduced-form and structural-FOC comparison notes are kept below as archival
diagnostics, but the current benchmark and verification work is based on the household solver.

### Intuition first

The corrected household block now separates two child objects that had previously been mixed
together:

- `p_t`: parity, or children ever born. This is the permanent fertility state.
- `h_t`: children currently at home. This is the temporary housing-crowding state.

A birth increases both states today. Later, children can leave home so `h_t` falls, but `p_t`
does not. This is the key modeling distinction needed to match completed fertility without
pretending that older households still have the same number of resident children.

Housing matters through crowding. More children at home reduce effective housing services, so
high housing prices make additional births less attractive. The political equilibrium remains the
project-02 vote/debt fixed-point problem, now evaluated using the fertility-augmented household
policies.

### Variables

- `b_t`: liquid assets / debt choice carried into next period
- `a_t`: housing stock choice
- `z_t`: idiosyncratic income state
- `p_t in {0,1,2,3+}`: parity, or children ever born
- `h_t in {0,1,2,3}`: children currently at home
- `q`: housing purchase price (`a_price` in code)
- `r(q)`: rental price implied by `q`

### Key household equations

Let `H_t` denote raw housing services from owned plus rented housing. Without a birth this
period, flow utility is

$$
u^0_t = \log c_t + s_h \log\left(\frac{H_t}{(1 + \lambda_c h_t)^{\psi_c}}\right)
+ \nu_h h_t - \text{penalty}_t.
$$

If a birth occurs, the newborn counts immediately in the crowding and child-utility terms:

$$
u^1_t = \log c_t + s_h \log\left(\frac{H_t}{(1 + \lambda_c (h_t + 1))^{\psi_c}}\right)
+ \nu_h (h_t + 1) + \phi(p_t) - \kappa_0 - \kappa_q q - \text{penalty}_t.
$$

Here `\phi(p_t)` is parity-specific birth utility, `\kappa_0` is the direct birth cost, and
`\kappa_q q` is the housing-price-sensitive birth cost term.

The state transitions are:

$$
p_{t+1} = \min(p_t + \mathbf{1}\{\text{birth}\}, 3+),
$$

$$
h_{t+1} =
\begin{cases}
h_t + 1 & \text{after birth, before leave-home shock} \\
h_t & \text{without birth, before leave-home shock}
\end{cases}
$$

followed by a reduced-form leave-home shock that can lower `h_{t+1}` by one child. The
leave-home block is disciplined by Census-style leave-by-bin targets and should be interpreted as
a reduced-form device, not a structural model of young-adult co-residence.

### Verification and active benchmark

The upstream reproduction check is now exact: when `C = 1` and the fertility/crowding terms are
shut off, `SolveSS_fertility.m` reproduces the project-02 `SolveSS_function.m` distance, vote,
and debt outputs exactly.

The active benchmark is centralized in `code/fertility_benchmark_config.m`:

- solver grid: `I = 60`, `J = 14`
- `birth_utility_by_parity = [1.05, 1.15, 0.95]`
- `child_utility = 0.02`
- `birth_cost = 0.06`
- `birth_price_coeff = 0.24`
- `lambda_crowd = 0.18`
- `birth_age_weights = [0.438, 0.381, 0.152, 0.029]`
- `first_birth_realized_weights = [1.00, 0.55, 0.22, 0.06]`

The key March 22 change is that the old equal-weight timing block is gone. The household solver
now applies age-specific realized-birth shifters to parity-zero births, calibrated to the pooled
recent U.S. CDC WONDER first-birth distribution for ages `25+`. Later-parity births continue to
use unit realized weights, so the model fixes the first-birth hazard problem without imposing an
equally steep age penalty on all higher-parity births.

Current timing readout from `notes/build/fertility_first_birth_timing.md`:

- target first-birth shares at ages `25, 30, 35, 40`: `[0.438, 0.381, 0.152, 0.029]`
- model shares at benchmark `a_price = 2.00`: `[0.498, 0.312, 0.143, 0.047]`
- moving from `a_price = 1.50` to `3.00`, mean age at first birth now rises from `27.57` to
  `30.95`
- over the same range, the share of first births at age `30+` rises from `0.370` to `0.709`
- the average first-birth rate falls from `0.233` to `0.134`

The old completed-fertility benchmark note in `notes/build/fertility_run_ge_report.md` is now
stale on the fertility side because the market-clearing wrapper has not yet been rerun cleanly
after the timing fix. A refreshed narrow benchmark solve now shows the vote switching sign between
`a_price = 1.824` and `1.825`, so the political crossing has shifted upward from the old
equal-weight benchmark and is now best reported as a local bracket rather than as a stale exact
point from the pre-fix run.

Current benchmark readout from direct solves:

- at benchmark `a_price = 2.00`, age-50 completed-fertility shares are
  `[0.3728, 0.0937, 0.4123, 0.1212]`
- the timing-focused calibration improves the first-birth hazard materially relative to the old
  equal-weight block, but it does not yet jointly recover the old completed-fertility target
  `[0.165, 0.193, 0.357, 0.285]`

### Numerical-resolution note

The benchmark was promoted at `I = 60`, `J = 14` because the coarser `I = 50`, `J = 10` grid
created vote wiggles on the market-clearing grid. The finer household grid removes that spurious
extra sign change for the promoted candidate and is therefore the correct resolution for the
current corrected-code benchmark.

### Internal note for draft boundary

The live 5-year benchmark read and the annual rebaseline status are important project-state facts,
but they are not themselves paper text.

- Keep the current branch split documented in internal notes:
  - corrected 5-year benchmark is the working model object
  - annual branch is a separate rebaseline / extension track until its corrected screen settles
- Do not paste solver-fix history, queue / Hamilton status, or branch-management language into the
  paper draft.
- If the draft needs a benchmark statement, write it as a clean model comparison only, without the
  internal debugging or workflow context.

### Annual supply-timing interpretation

The annual construction-flow block is now the project's benchmark interpretation object for supply
timing. The benchmark is not the short Bellman RE diagnostic itself. It is the annual
`permits -> starts -> completions -> stock -> prices` block calibrated to construction-flow
moments.

Current benchmark anchors from the calibrated annual block:

- starts / permits target about `0.932`
- completions / starts target about `0.895`
- permit-inventory lag target about `0.50` years
- benchmark calibrated parameters:
  - `start_hazard = 0.65`
  - `completion_hazard = 0.45`
  - `permit_inventory_years = 0.25`
  - `uc_inventory_years = 0.70`

The new timing-robustness note is:

- `notes/build/annual_full_re_stationary_transition_timing_robustness_T80.md`

That note should guide interpretation:

- `benchmark_timing` is the data-disciplined annual supply-response benchmark.
- `faster_timing` and `slower_timing` are modest robustness cases around that benchmark, not
  separately identified political-delay estimates.
- So the paper-facing language should be:
  - benchmark timing from data first
  - then a small faster/slower timing menu as robustness
  - not a claim that one exact construction delay is point-identified.

## Legacy aggregate prototype notes

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
