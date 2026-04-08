# Static bloc-coordination extension

## Purpose

This note defines a coalition extension that is materially richer than the published baseline, but much simpler than a full dynamic coalition game.

The idea is:

- voting remains one-period and sincere
- there are no transfers across dates
- there is no bargaining over future policy paths
- some voter groups coordinate better within a period and therefore receive extra effective political weight

This is the natural next extension after the anticipated-demographics RE benchmark.

## Recommended positioning

This should be described as a **within-period bloc-coordination model**, not as full coalition bargaining.

Interpretation:

- homeowners' associations, neighborhood groups, and repeat local participants can coordinate turnout and message discipline better than diffuse young renters
- this changes the effective influence of groups in current votes
- but does not require an explicit repeated political game

## Group structure

Partition households into blocs `g \in \mathcal{G}`. A practical first partition is:

- young renters
- young owners
- middle-age renters
- middle-age owners
- old renters
- old owners

Let:

- `\mu_{g,t}` be bloc `g`'s population share at date `t`
- `s_{i,t}` be household `i`'s baseline support for higher prices or lower supply
- `\bar{s}_{g,t}` be average support within bloc `g`

The baseline bloc support is

```math
\bar{s}_{g,t} = \frac{1}{\mu_{g,t}} \int_{i \in g} s_{i,t} \, di.
```

## Simplest coalition version

The simplest useful version is a threshold coordination premium.

Define

```math
C_{g,t}
=
\mathbf{1}\{\mu_{g,t} \ge \bar{\mu}\}
\cdot
\mathbf{1}\{|\bar{s}_{g,t}| \ge \bar{s}\}.
```

Then effective political weights are

```math
\omega_{g,t}^{coal}
=
\frac{\mu_{g,t}(1+\phi C_{g,t})}
{\sum_{h \in \mathcal{G}} \mu_{h,t}(1+\phi C_{h,t})},
```

where `\phi > 0` is the coalition premium.

Aggregate political support becomes

```math
\Theta_t^{coal}
=
\sum_{g \in \mathcal{G}} \omega_{g,t}^{coal} \bar{s}_{g,t}.
```

Then the price/supply block is solved as usual, replacing baseline support with `\Theta_t^{coal}`.

### Interpretation

A bloc gets extra effective influence only when:

- it is large enough to matter
- it is internally aligned enough to coordinate

This is the easiest coalition experiment to code and explain.

## Best practical coalition version

The best extension that is still tractable is a smooth coordination technology.

Let within-bloc disagreement be

```math
D_{g,t}
=
\frac{1}{\mu_{g,t}} \int_{i \in g} (s_{i,t}-\bar{s}_{g,t})^2 \, di.
```

Define a smooth coordination index

```math
C_{g,t}
=
\Lambda\left(
a_0 + a_1 \mu_{g,t} + a_2 |\bar{s}_{g,t}| - a_3 D_{g,t}
\right),
```

where `\Lambda(z) = 1/(1+e^{-z})`.

Effective weights are again

```math
\omega_{g,t}^{coal}
=
\frac{\mu_{g,t}(1+\phi C_{g,t})}
{\sum_{h \in \mathcal{G}} \mu_{h,t}(1+\phi C_{h,t})}.
```

Aggregate support is

```math
\Theta_t^{coal}
=
\sum_{g \in \mathcal{G}} \omega_{g,t}^{coal} \bar{s}_{g,t}.
```

### Why this is better

- avoids hard thresholds
- allows large but internally divided blocs to coordinate poorly
- allows small but highly aligned blocs to gain some influence without dominating
- can be calibrated to turnout or campaign-intensity moments if desired

## What this extension does not do

This model still excludes:

- bargaining across dates
- side payments across groups
- strategic manipulation of today's vote to change tomorrow's tenure composition
- endogenous formation and breakup of political organizations

So this is still much simpler than a true dynamic coalition model.

## Relation to the RE benchmark

The two extensions can be layered in order:

1. anticipated-demographics RE benchmark
2. static bloc coordination

That combined model would give:

- forward-looking voting about boom-driven future electorates
- plus extra current-period influence for groups that coordinate better

without yet solving a full dynamic coalition game.

## Coding recommendation

### Simplest coding path

Work at the aggregate/group level after household voting preferences are computed:

1. use the existing household block to compute baseline support `s_{i,t}` or its grouped averages
2. aggregate into blocs by age and tenure
3. compute `C_{g,t}`
4. replace raw population weights with coalition-adjusted weights
5. feed adjusted support into the supply/price mapping

### First implementation target

Implement the threshold version first. It is the easiest to interpret and the easiest to compare to the baseline.

Suggested parameters for a first pass:

- blocs: age-by-tenure cells
- `\bar{\mu}`: median bloc mass in steady state
- `\bar{s}`: median absolute bloc support in steady state
- `\phi`: small premium such as `0.1` to `0.3`

Then only move to the smooth version if the threshold model produces interesting results.

## Bottom line

If the question is "what is the best coalition model we could realistically do next?", the answer is the smooth within-period bloc-coordination model.

If the question is "what is the simplest coalition experiment worth doing?", the answer is the threshold coalition-premium model.

I would still do both only after the anticipated-demographics RE benchmark is structurally operational.
