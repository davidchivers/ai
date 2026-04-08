# Anticipated-demographics RE benchmark

## Goal

Construct a forward-looking voting benchmark for the NIMBY model that:

- keeps one-period majority voting
- keeps no coalition formation and no bargaining across dates
- allows households to look ahead to the boom-driven path of future voters
- shuts down the feedback from today's housing outcome into future political composition

This is an intermediate benchmark between the published random-walk expectation rule and a full political rational-expectations equilibrium.

## Exact benchmark in words

At date `t`, households vote over current housing supply using continuation values that depend on the forecast path of future prices and future political support. The forecast path is generated from the projected demographic consequences of the boom alone.

Crucially, households do **not** assume that today's vote changes tomorrow's voter composition. That is the piece that avoids strategic coalition-building.

## State and forecast objects

Let:

- `j = 1, ..., J` index age bins
- `m_t(j)` be the mass of voters of age `j` at date `t`
- `x_{i,t}` be household `i`'s idiosyncratic state
- `q_t` be current housing supply or permits
- `p_t(q_t, m_t)` be the current housing price

The benchmark takes the projected demographic path

```math
\{m_{t+s}\}_{s \ge 1}
```

as exogenous from the boom projection.

From that path, define a demographic-only forecast for future political support

```math
\hat{\theta}_{t+s|t} = G(m_{t+s}),
```

where `G(.)` is the mapping from age composition to aggregate support for higher prices or lower supply.

Then define the associated forecasted price path

```math
\hat{p}_{t+s|t} = P(\hat{\theta}_{t+s|t}).
```

## Voting problem

Household `i` at date `t` evaluates the current vote using

```math
V^{AD}_{i,t}(q_t) =
u_i(x_{i,t}, q_t, p_t(q_t,m_t))
\;+\;
\sum_{s=1}^{T-t} \beta^s
\mathbb{E}_t
\left[
\tilde{u}_i(x_{i,t+s}, \hat{p}_{t+s|t}, \hat{\theta}_{t+s|t})
\right].
```

The household votes for the current policy that yields the higher value.

The benchmark restriction is:

```math
\frac{\partial \hat{\theta}_{t+s|t}}{\partial q_t} = 0
\quad \text{for all } s \ge 1.
```

So households are forward-looking about boom-driven future politics, but they do not strategically manipulate future voter composition through today's vote.

## What this captures

- Anticipation that a large boom cohort will age into more NIMBY positions later
- Anticipation that future prices may rise because future electorates become more price-protectionist
- Forward-looking current voting without coalition bargaining

## What this excludes

- Any effect of today's lower prices on future homeownership across other cohorts
- Any effect of those tenure changes on future voting
- Dynamic coalition formation or bargaining across dates

## Reduced-form aggregate prototype in code

The MATLAB prototype in `matlab/run_anticipated_demographics_re_toy.m` implements an aggregate approximation of this benchmark:

1. Build a projected age-distribution path for a stylized boom cohort.
2. Map each age distribution into a demographic support index `theta_t`.
3. Add a forward-looking adjustment

```math
\theta^{RE}_t
=
\theta^{myopic}_t
+
\lambda \sum_{s=1}^{T-t} \beta^s \left(\theta^{myopic}_{t+s} - \theta^{ss}\right).
```

4. Map the support index into a price index

```math
p_t = p^{ss} \exp\left[\kappa\left(\theta_t - \theta^{ss}\right)\right].
```

This is not the full household-level structural solve. It is an exploratory aggregate benchmark designed to answer the narrower question:

"How much changes if voters look ahead to the boom-driven future electorate, while we keep strategic political feedback switched off?"
