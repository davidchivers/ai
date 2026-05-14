# House-price RE equilibrium definition

## Purpose

This note pins down the exact equilibrium object we should mean in the
`re_no_politics` extension.

The main point is simple:

- the target is **not** merely a transition pass with a given price path
- the target is **not** full political rational expectations either
- the target is a **house-price rational-expectations fixed point under a chosen future mechanism**

That last clause matters. Unknown future house prices are only well defined once we say what
agents think maps future states into future prices.

## Intuition first

The current middle-ground object is:

1. demographics evolve along an exogenous path
2. households forecast future house prices
3. given those expected prices, they choose savings and housing
4. the cross-sectional distribution moves forward
5. housing demand implies a new market-clearing price path
6. equilibrium requires the guessed path to equal the implied path

This is a rational-expectations problem in **house prices**.

It is **not** yet full political rational expectations, because the future mechanism that generates
prices is not an endogenous future voting equilibrium. Instead, it is whatever continuation rule we
feed into the household block, such as `full_backward`, `steady_state_by_period_price`, or
`steady_state_fixed_price`.

## Variables and objects

Let \(t = 0, \dots, T\) index the transition periods.

- \(p_t\): house price at date \(t\)
- \(m_t\): exogenous target age masses at date \(t\)
- \(\mu_t\): cross-sectional density over household states at date \(t\)
- \(g_t\): household policy rules at date \(t\)
- \(V_t\): value function at date \(t\)
- \(H_t^d\): aggregate housing demand at date \(t\)
- \(H_t^s(p_t)\): aggregate housing supply at date \(t\)

In the current code, these objects map roughly as follows:

- guessed price path \(p_{0:T}\): `price_path_guess`
- exogenous demographic path \(m_t\): `cohort_scale_by_age` and `target_age_masses`
- initial distribution \(\mu_0\): `initial_density`
- transition operator conditional on a guessed path:
  `run_transition_pass(...)`
- implied market-clearing price path:
  `invert_supply_path(sim.Hdemand_path, params.supply_params)`

## Conditional transition object

Before defining equilibrium, it helps to separate the easier conditional object.

Given:

- an initial density \(\mu_0\)
- an exogenous demographic path \(\{m_t\}_{t=0}^T\)
- a guessed house-price path \(p = (p_0, \dots, p_T)\)
- a chosen continuation mechanism \(M\)

the code computes a transition pass:

$$
\Psi_M(p) = \tilde p,
$$

where \(\tilde p\) is the implied market-clearing price path produced by:

1. solving the household problem conditional on \(p\) and \(M\)
2. simulating the distribution forward
3. aggregating housing demand period by period
4. inverting the housing-supply curve

This is the object returned inside `run_transition_pass`.

It is not yet equilibrium. It is just the price-path map.

## Household block

Conditional on \(p\) and the continuation mechanism \(M\), the household side solves a backward
dynamic program of the form

$$
V_t(s) = \max_{s'} \left\{ u_t(s, s'; p_t) + \beta \, \mathbb{E}\left[V_{t+1}(s')\right] \right\},
$$

where \(s\) collects the household state variables already used in the NIMBY model.

What changes across mechanism choices is not the one-period problem itself. What changes is the way
future continuation objects are constructed.

In the current solver, the main mechanism choices are:

- `full_backward`
  The household block solves the full backward transition problem along the guessed path, with a
  terminal tail pinned down by `terminal_reference_mode`.
- `steady_state_by_period_price`
  The transition uses period-specific steady-state policy and value objects evaluated at a
  reference price path.
- `steady_state_fixed_price`
  The transition uses one fixed steady-state policy and value object, repeated across the whole
  path.

So a change in `transition_policy_mode` changes the equilibrium object itself. It is not just a
numerical trick.

## Distribution block

Given policy rules and the age-mass targets, the code simulates the cross section forward:

$$
\mu_{t+1} = \Gamma_t(\mu_t, g_t, m_{t+1}).
$$

In the current implementation this is done by:

- mapping current mass through the policy indices
- applying the idiosyncratic shock transition matrix
- rescaling by the target age masses

That is the forward object inside `simulate_forward_transition(...)`.

## Market-clearing price block

Given the simulated distribution, the code aggregates housing demand:

$$
H_t^d = \mathcal{H}(\mu_t).
$$

Supply is parameterized as

$$
H_t^s(p_t) = \bar H \left(\frac{p_t}{\bar P}\right)^{\eta_s}.
$$

So the implied market-clearing price is

$$
\tilde p_t
=
\bar P
\left(\frac{H_t^d}{\bar H}\right)^{1/\eta_s}.
$$

In code this is exactly `invert_supply_path(...)`.

## The target middle-ground equilibrium

Now we can define the object we actually want.

Fix:

- the exogenous demographic path \(\{m_t\}_{t=0}^T\)
- the initial density \(\mu_0\)
- the supply rule
- a chosen continuation mechanism \(M\)

A **house-price rational-expectations equilibrium under mechanism \(M\)** is a price path
\(p^\ast\) such that

$$
p^\ast = \Psi_M(p^\ast).
$$

Equivalently, for every date \(t\),

$$
p_t^\ast = \tilde p_t(p^\ast; M).
$$

This is the clean fixed-point statement for the current no-politics transition object.

Two practical implications follow.

1. Unknown future house prices do not automatically imply full political RE.
   They only imply RE with respect to the chosen mechanism \(M\).
2. Different mechanism choices define different equilibrium objects.
   A fixed point under `steady_state_fixed_price` is not the same object as a fixed point under
   `full_backward`.

## Where policy-reference modes enter

For the bridge objects, the policy-reference path is itself a transformation of the guessed price
path. In the current solver, `policy_reference_mode` includes:

- `path_current_prices`
- `path_initial_price`
- `path_end_price`
- `path_mean_price`
- `fixed_price`
- `blended_current_and_fixed_price`

with optional floor and cap rules.

So for the bridge branches, the actual equilibrium map is really

$$
p \mapsto \Psi_{M,R}(p),
$$

where \(R\) is the rule that turns the guessed path into the policy-reference path used by the
household block.

This matters for interpretation. A fixed point under a frozen or partially frozen policy-reference
rule is still a valid equilibrium of that **simplified** mechanism, but it is not a full
equilibrium of the original structural transition problem.

## What would count as full political RE

Full political rational expectations would require a larger state and a different fixed point.

In that case, future prices would depend on future political outcomes, and future political
outcomes would depend on future distributions of wealth, housing, age, and possibly beliefs. So
agents would need to forecast not only prices, but also the law of motion for the political state.

Schematically, the state would look more like

$$
X_t = (\mu_t, \text{political state}_t, m_t),
$$

and equilibrium would require consistency of both:

$$
p_t = \mathcal{P}(X_t)
$$

and

$$
X_{t+1} = \mathcal{G}(X_t, g_t, p_t).
$$

If future house prices depend on future voting distributions in that sense, then yes, the problem
has become political RE.

That is **not** the current target object in `re_no_politics`.

## Operational definition for this project

For this project, the clean working definition should be:

> We seek a model-consistent house-price path along an exogenous demographic transition, while
> holding the future mechanism fixed at a chosen no-politics continuation rule.

That means:

- demographics are exogenous
- house prices are endogenous
- coalition voting is shut down
- the continuation mechanism is chosen explicitly through
  `transition_policy_mode`, `terminal_reference_mode`, and `policy_reference_mode`
- equilibrium is a fixed point in the house-price path, conditional on that mechanism

## Coding implication

When we ask whether the RE house-price problem is solved, the right question is not:

$$
\text{Did we solve full RE?}
$$

The right question is:

$$
\text{For which mechanism } M \text{ did we solve } p = \Psi_M(p)\text{?}
$$

That is the object the compiled sidecar and the MATLAB truth/export harness should now be organized
around.
