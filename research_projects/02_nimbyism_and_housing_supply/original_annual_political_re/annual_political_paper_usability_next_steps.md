# Annual Political Transition: Paper-Usability Next Steps

## Current Confidence

The annual political pass-through transition is a promising paper extension, but the
claims should stay cautious until the benchmark and robustness package is assembled. The
right standard is consistency with the published paper's reduced-form political supply
channel, not adding a new construction-stock block that the paper did not use.

What is strong:

- The annual timing correction is fixed.
- The household problem is solved each period.
- The household distribution is moved forward dynamically.
- The political residual is clean through `T = 40`.
- The `T = 80` check is stable and close, with residuals under two percentage points.
- The Hamilton runtime problem was solved by shipping Linux CompEcon MEX binaries.

What should be kept disciplined:

- The permit/supply-to-price link is intentionally reduced-form, as in the paper's
  political mechanism.
- The current transition runner should be presented as the transition analogue of that
  paper mechanism, not as a new construction technology.
- The benchmark should use one effective pass-through parameter, not separately calibrate
  several weakly identified political/supply parameters.
- Because we previously caught an important timing mismatch in the 5-year lane, every
  transition claim should be tied to the verified annual code path and should not be
  generalized back to the old 5-year diagnostics.

## Weighting And Death-Timing Caveat

The annual Hamilton runs use the annual `age_share(:, year)` vectors from the annual
`LOOP.m` source and normalize them each period before aggregating votes:

```text
period vote = VoteAge * normalized annual age-share vector
```

This is not the old equal-age-bin shortcut. However, it does not add a separate
within-period stochastic mortality adjustment. The baseline timing is:

```text
agents alive in the current annual age bin vote in that year;
terminal-age agents exit before the next year.
```

So the remaining caveat is death/exit timing, not age-weight correction. We are checking
this directly with a terminal-age robustness batch:

- baseline terminal-age voting,
- half terminal-age voting weight,
- terminal age excluded before voting.

## Benchmark Transition Package

1. Finish Hamilton job `16893840`, the one-parameter `T = 80` refinement.
2. Select benchmark `eta` using:
   - smallest max vote residual,
   - no price-cap hit,
   - smaller `eta` if residuals are nearly tied,
   - smooth and plausible price/homeownership/housing-demand paths.
3. Re-run the benchmark eta at `T = 20`, `T = 40`, and `T = 80` with the same solver
   settings.
4. Store a single benchmark table:
   - vote residual,
   - price movement,
   - homeownership,
   - housing demand,
   - runtime/verdict.

## Required Comparisons

1. Random price / placebo paths:
   - first saved-grid comparison completed in `annual_comparison_map_full_20260426`,
   - full dynamic version remains to be run if needed,
   - compare political residuals against the benchmark pass-through path,
   - show that the political rule is not just fitting arbitrary price noise.
2. No-politics / exogenous-price path:
   - keep the demographic transition,
   - remove political feedback,
   - compare vote residual and housing-market objects.
3. Smoothing robustness:
   - `tau = 0.015`, `0.020`, `0.030`,
   - include the hard-sign `tau = 0` limit as a discontinuity diagnostic,
   - keep benchmark eta fixed where possible,
   - report whether the path remains stable.
4. Solver robustness:
   - `PeriodIter = 2`, `4`, optionally `6`,
   - confirm benchmark conclusions do not hinge on inner update looseness.
5. Death/exit-timing robustness:
   - baseline,
   - half terminal-age weight,
   - drop terminal age before voting.

## Figures To Rebuild

1. Benchmark transition price path.
2. Political residual by year.
3. Political pressure and implied pass-through.
4. Homeownership and housing demand sanity checks.
5. Benchmark versus random-price/placebo residuals.
6. Horizon robustness: `T = 20`, `T = 40`, `T = 80`.

## Suggested Paper Language

The safe claim is:

> We implement a reduced-form annual political pass-through closure in which vote
> imbalances generate bounded political pressure, and political pressure shifts the
> housing-price path through the supply/permit margin. This is intended as the transition
> analogue of the paper's reduced-form political supply channel. We discipline one
> effective pass-through parameter and test the resulting transition for stability,
> timing, and death/exit robustness.

Avoid claiming:

- exact period-by-period political clearing,
- separately identified `phi` and `gamma`,
- a new primitive construction-stock-price block that is not part of the paper's
  maintained mechanism.
- claims based on the old 5-year diagnostic lane rather than the verified annual code.
