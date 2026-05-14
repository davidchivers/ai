# Bounded price expectations route

## Current decision

Keep the full T80 rational-expectations search alive, but stop treating it as
the only credible paper route. The live full-RE search remains job `17145335`
and must still satisfy the hard generated-vs-guessed price-path gates. In
parallel, develop the bounded 40-year forecast-horizon result as a distinct
finite-horizon price-belief equilibrium.

After checking Moll's argument more carefully, this bounded route is only a
prototype. Moll does not prescribe an arbitrary 40-year horizon with a
return-to-steady-state tail. The actual Moll-aligned route is now documented in
`drafts_re/moll_direct_price_beliefs/criteria_audit.md`: a restricted direct
price-belief equilibrium with low-dimensional price forecasts, empirical
discipline, and feedback from model outcomes into beliefs.

## Motivation

Moll's rational-expectations challenge argues that heterogeneous-agent models
with equilibrium price expectations ask agents to forecast prices through
high-dimensional distributional dynamics. The relevant lesson here is not that
the full T80 object should be abandoned, or that any finite-horizon path is
automatically defensible. It is that direct price expectations should replace
distribution forecasting, and those price beliefs need their own discipline.

For this project, the distinction is:

- Full T80 RE: households act on the full generated equilibrium house-price
  path. This remains a robustness target and requires
  `max_abs_path_gap <= 0.001` to be usable, `<= 0.0002` to be paper-safe.
- Bounded price expectations: households forecast the relevant house-price path
  over a finite horizon and use a specified terminal/tail rule afterwards. This
  is a different expectations model, so it should be named and validated as
  such.

## Existing candidate

The current candidate is `bound40_baby_rss_l4` from the 2026-05-12 alternatives
packet. It has:

- forecast horizon: 40 years;
- tail rule: return to steady state;
- pass-through: `0.006`;
- outer iteration: `7`;
- max path gap: `0.000990326504390953`;
- current verdict: usable, not paper-safe;
- interpretation: finite-horizon price-belief equilibrium, not full T80
  perfect foresight.

## First artifact

Built a first local comparison artifact under
`drafts_re/bounded_price_expectations/`.

- Main summary: `drafts_re/bounded_price_expectations/summary.md`.
- Figure: `drafts_re/bounded_price_expectations/figure/bounded_price_expectations_vs_nore_0513.svg`.
- Validation table: `drafts_re/bounded_price_expectations/figure/bounded_price_expectations_validation_0513.csv`.
- Plotted data: `drafts_re/bounded_price_expectations/figure/bounded_price_expectations_vs_nore_0513.csv`.

The plotted comparison uses the 40 reported years, not the full internal
80-year closure tail. Validation recomputes the reported-horizon path gap as
`0.000990326504390731`, matching the ranked gap up to rounding.

## What must be checked next

1. Treat the bounded T40 figure as a diagnostic prototype only.
2. Build the restricted direct-price-belief route specified in
   `drafts_re/moll_direct_price_beliefs/criteria_audit.md`.
3. Report full T80 RE separately, either as successful if it clears the hard
   gates or as a documented stress-test failure if it does not.

## Paper language guard

Do not describe the bounded route as "the rational-expectations result." Use
language such as "bounded price expectations," "finite-horizon price beliefs,"
or "direct price-expectations equilibrium." The full T80 object should remain
the only object called full rational expectations.
