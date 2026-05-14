# IER draft sequence: house-price steady state, then Bellman

## Why this order

This ordering matches the actual IER packet:

- the editor's first concern is house-price expectations
- referee 2 says the least satisfactory part of the draft is the steady-state analysis
- referee 2 also asks for missing dynamic details that belong in the household problem and
  expectations notation

So the clean repair sequence is:

1. clarify the steady-state house-price exercise
2. clarify the Bellman problem and the expectations assumption that sits behind it

## Current vulnerable locations in the paper

- steady-state subsection opens at roughly line `2738` in
  `Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx`
- random-walk sentence is at roughly line `1507`
- equilibrium paragraph is around lines `1641-1680`

## Draft 1: steady-state house-price clarification

### Problem this fixes

Referee 2 is right that the phrase "steady state" is doing too much work in the current draft.
The present text sounds too close to a transition exercise, even though the object being computed is
closer to a sequence of demographic-indexed stationary political equilibria.

### Suggested insertion point

Add this at the start of the `Steady State` subsection, before the current sentence
"First we analyze how demographic changes affect the housing market in the model's steady state."

### Draft text

In this section, "steady state" does not mean that the economy is on a transition path with
changing demographic shares. Instead, we study a sequence of stationary political-economic
equilibria indexed by the age distribution of households. For each year's demographic composition,
we hold all non-demographic parameters fixed and solve for the house price that clears the housing
market and makes the median voter indifferent at the margin to an increase in housing supply.
Equivalently, the object in this section is a mapping from the demographic state
$$
\Omega
$$
to the corresponding stationary equilibrium house price
$$
p^h(\Omega).
$$
This exercise should therefore be read as a comparative-static decomposition of how changing age
structure shifts the equilibrium house price through the voting channel, not as a full transition
analysis with model-consistent expectations over future political outcomes.

### Follow-up sentence to replace the current opener

We begin by studying how changes in the age distribution shift the stationary equilibrium house
price through the political supply mechanism.

### Optional extra sentence if needed

Operationally, for each target age distribution we set household formation so that the demographic
structure is constant in the absence of further shocks, and then solve for the associated
political-economic equilibrium.

## Draft 2: Bellman and expectations clarification

### Problem this fixes

The current draft jumps too quickly from household intuition to voting and then to the random-walk
assumption. That leaves open exactly what households forecast, where expectations enter the dynamic
problem, and why the benchmark avoids a full political RE fixed point.

### Suggested insertion point

Use this in the model section near the random-walk sentence around line `1507`, or split it between
the household-problem subsection and the equilibrium subsection.

### Draft text

At date
$$
t,
$$
households take as given the current house price, the current rental price, and the law of motion
for their idiosyncratic income state. Their dynamic problem is to choose consumption, liquid
savings, and housing subject to the relevant borrowing and adjustment constraints, taking into
account how these choices affect continuation value in the next period. Expectations therefore enter
the model through the continuation value in the household Bellman problem. In the benchmark
specification, households do not solve for a fully model-consistent future political equilibrium.
Instead, when forming continuation values they treat future house prices as following a random walk
with respect to the demographic component, so that the expected future house price equals the
current one. This assumption keeps the benchmark transition problem tractable while preserving the
forward-looking link between current voting incentives and expected future housing wealth.

### Optional more explicit version with notation

Let
$$
\mathbf{s}_t
$$
denote the household state, including age, idiosyncratic income, liquid assets, and housing status.
The household's value function takes the form
$$
V_j(\mathbf{s}_t; p_t^h, \Omega_t)
=
\max
\left\{
u(\cdot)
\;+\;
\beta \, \mathbb{E}_t \left[ V_{j+1}(\mathbf{s}_{t+1}; p_{t+1}^h, \Omega_{t+1}) \right]
\right\},
$$
where the expectation is over future idiosyncratic income shocks and, in the benchmark transition
exercise, over a perceived future house-price path that is restricted by the random-walk
assumption. A full political rational-expectations version would replace that shortcut with a fixed
point over the entire future path of house prices, distributions, and voting outcomes.

## How these two pieces fit together

The paper becomes much cleaner if the distinction is explicit:

- the steady-state section is a sequence of demographic-indexed stationary house-price equilibria
- the transition section is the dynamic response to a demographic shock
- the benchmark transition uses a tractable expectations shortcut for future house prices
- the RE extension is then presented as a bounded robustness check on that expectations shortcut

## Recommended immediate use

If we revise the paper for a new outlet, this should be the order:

1. patch the steady-state subsection so the reader knows exactly what object is being solved
2. patch the Bellman and expectations discussion so the random-walk assumption is clearly embedded
   in the household problem
3. only then add the short house-price RE footnote or appendix note
