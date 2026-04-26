# Annual Political Benchmark Transition Workflow

## Goal

Build one defensible annual benchmark transition, not a many-parameter fit.

The current evidence suggests the paper-consistent political pass-through mechanism is
stable through `T = 40` and close through `T = 80`. Because the earlier 5-year lane
contained a timing mismatch, benchmark claims should be made only from the verified
annual code path. The benchmark should use the fewest parameters needed to describe that
mechanism.

## Benchmark Closure

Use one effective pass-through parameter:

```text
vote residual = vote share - target vote
pressure      = tanh(vote residual / tau)
log price     = log(reference price) + eta * pressure
```

Implementation crosswalk in the current runner:

```text
rho = 0
vote_scale = tau = 0.020
gamma = 1
phi = eta
```

This avoids separately calibrating `phi` and `gamma`, which the existing runs show are
not separately identified by these transition paths.

## Active Calibration Step

Hamilton job `16893840` runs `T = 80` with:

- `tau = 0.020`
- `rho = 0`
- `gamma = 1`
- `eta in [0.060, 0.075, 0.090, 0.105, 0.120, 0.150]`
- `PeriodIter = 4`

Preliminary result: `eta >= 0.090` makes the `T = 80` contemporaneous benchmark usable
under the strict residual cutoff, but larger `eta` also buys the improvement with a
larger price movement. The benchmark choice should balance residual fit, price movement,
and parsimony rather than mechanically selecting the largest `eta`.

Selection rule:

1. Prefer the smallest max absolute vote residual.
2. Require no price cap hit.
3. Prefer smaller `eta` if residuals are economically indistinguishable.
4. Keep max log price movement in a plausible band; do not buy a tiny vote gain with a
   huge price move.

## Robustness After Benchmark

Once a benchmark `eta` is chosen, run robustness checks as diagnostics, not as extra
calibration:

1. Horizon robustness: `T = 20`, `T = 40`, `T = 80`.
2. Solver robustness: `PeriodIter = 2`, `4`, and optionally `6`.
3. Local eta robustness: `eta * 0.8`, `eta`, `eta * 1.2`.
4. Smoothing robustness: `tau = 0.015`, `0.020`, `0.030`.
5. Lag robustness: political pressure in year `t` affects the price/supply environment
   after 1, 5, or 10 years, not necessarily contemporaneously.
6. Death/terminal-age robustness: baseline terminal age votes in the final living year,
   half terminal-age weight, and terminal age excluded before voting.
7. Path sanity: price movement, homeownership, and housing demand should remain smooth and
   economically small.

Current robustness status:

- Lagged pass-through at `T = 80` is not fatal: `eta >= 0.105` is usable under the
  one-year lag check.
- Death/terminal-age robustness is running under Hamilton job `16893866`.

## Scope

This is a serious annual transition with household re-solving and dynamic distribution
updates using the paper-consistent reduced-form political pass-through closure. A separate
construction-stock-price block is not part of the benchmark claim and is not needed unless
we choose to build a different model extension later. The remaining uncertainty is mostly
about timing assumptions and robustness, especially terminal-age death/exit timing.
