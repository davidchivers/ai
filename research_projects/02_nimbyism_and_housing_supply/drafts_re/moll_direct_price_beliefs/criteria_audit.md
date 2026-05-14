# Moll-aligned direct price-beliefs route

## Decision

Do not treat the current bounded T40 result as "what Moll says to do." It is a
useful prototype because it gives households a direct finite-horizon price path,
but it does not yet discipline beliefs with evidence or close the feedback from
model outcomes into beliefs.

The Moll-aligned route for this project is a restricted direct-price-belief
equilibrium:

1. Households forecast house prices directly, not the full cross-sectional
   distribution.
2. The forecast rule is low dimensional and computationally tractable.
3. The rule is disciplined by evidence on house-price expectations or, as a
   first internal step, by an explicitly estimated perceived law of motion.
4. Actual model prices feed back into the belief rule through a restricted
   perceptions or learning step.

For the route menu, see `route_options.md`. The default immediate route is
least-squares learning over a low-dimensional price law, but temporary
equilibrium with calibrated beliefs and restricted-perceptions heuristics are
also legitimate Moll-adjacent routes with different strengths.

## What Moll requires

Moll's challenge is not to replace full rational expectations with an arbitrary
finite horizon. The core prescription is to replace equilibrium-price rational
expectations with direct price beliefs, then discipline those beliefs.

Operationally, the paper gives three requirements:

- **Tractability:** agents should not have to solve the rational-expectations
  special case or forecast high-dimensional distributions.
- **Empirical discipline:** the belief rule should be connected to evidence on
  how people actually form expectations.
- **Endogeneity:** beliefs should respond to model reality, so the exercise is
  not just an exogenous expectations assumption.

The paper's closest implementation families for us are temporary equilibrium,
survey or evidence-disciplined expectations, least-squares learning, and simple
or restricted forecasting models.

## Audit of current project objects

| Object | Tractable | Evidence-disciplined | Beliefs feed back to model reality | Use |
|---|---|---|---|---|
| Full T80 RE search | No | Not the replacement object | Yes, by construction if it solves | Keep as formal RE benchmark/stress test |
| No-RE/current-price comparator | Yes | Weak | Weak | Comparator only |
| `bound40_baby_rss_l4` | Mostly | Weak: 40-year horizon and RSS tail are not yet justified | Weak: fixed finite path, not a belief-update equilibrium | Prototype/diagnostic, not the Moll route |
| Existing `run_linear_age_price_rule.m` | Yes | Weak-to-medium: simple demographic rule, but not externally disciplined | Medium: coefficients update from model-implied prices | Closest existing code pattern |
| Target restricted direct-price-belief route | Yes | Must be added | Yes, via coefficient updating or restricted perceptions equilibrium | The route that follows Moll |

## Target belief rule

Use a low-dimensional perceived law of motion for log house prices. A practical
first specification is:

```text
E_t[Delta log P_{t+s}] =
    a_s + rho_s Delta log P_t + beta_s M_{t+s}
```

where `M` is a public demographic pressure index, for example a baby-boom or
homeowner-voter pressure measure, not the full cross-sectional distribution.
For longer horizons, apply cognitive discounting or shrinkage:

```text
E_t[Delta log P_{t+s}] =
    lambda^(s-1) * (a + rho Delta log P_t + beta M_{t+s})
```

with `0 <= lambda <= 1`. The benchmark version should start simple:
one intercept, one current-price-growth term, one demographic-pressure term,
and one horizon-decay parameter.

## Computational object

The computation should be:

1. Given belief-rule coefficients, generate the subjective future house-price
   path used by households.
2. Solve the model's temporary equilibrium path under those beliefs.
3. Compare realized model prices with the prices implied by the belief rule.
4. Update belief-rule coefficients by least squares or damped stochastic
   approximation.
5. Iterate until coefficients and realized-price forecast errors stabilize.

This is not full RE, because agents never forecast the full distribution. It is
also not the current bounded T40 object, because the belief rule is estimated
and then updated from model outcomes.

## Implementation plan

1. Use `extensions/re_no_politics/run_linear_age_price_rule.m` as the template
   for the first restricted-price-belief loop, because it already estimates a
   simple log-price rule from model-implied prices.
2. Port the pattern to the annual political baby-boom environment used by the
   current RE/no-RE packets:
   - four-year block voting;
   - pass-through `0.006`;
   - same no-RE normalization;
   - public demographic-pressure index rather than the full age distribution.
3. Add explicit outputs:
   - perceived-law coefficients by iteration;
   - realized versus believed price path;
   - forecast-error RMSE;
   - convergence status;
   - criteria audit row.
4. Use the existing house-price-expectations literature folder to discipline or
   at least benchmark the expectation parameters before any paper claim.
5. Keep the full T80 RE result separate. A solved restricted-belief route is an
   alternative expectations model, not a full-RE result.

## Status of the T40 bounded artifact

The current bounded artifact remains useful because it shows that a direct
finite-horizon price-belief object can be numerically usable. Its status is now
prototype/diagnostic. It should not be the paper's "Moll route" unless we add a
belief-rule justification and feedback/update mechanism.

## Route selection for the next 14 hours

Default to Route B in `route_options.md`: least-squares learning over a direct
price law. In parallel, write the paper-facing conceptual language so Route C
or Route A can be used if Route B fails technically.
