# Bounded political-path workflow

This workflow is the first bridge from the current house-price transition solver to a true
political RE object.

## Goal

Produce a bounded transition packet that contains, for each period:

- the current guessed and updated house-price path
- the implied market-clearing price path
- equal-weight political pressure
- coalition-weighted political pressure

The key point is not to solve the full political RE fixed point immediately. The key point is to
recover the missing time-varying political residual path from the shared Bellman layer.

## Packet

- horizon: first 4 periods
- transition policy mode: `full_backward`
- outer iterations: 1
- political path: on
- coalition-weighted diagnostics: on

## Main outputs

- `transition_re_political_path_summary.csv`
- `transition_re_political_path_periods.csv`
- `transition_re_political_path_results.mat`
- `transition_re_political_path_report.md`

## Interpretation rule

Read this packet as a diagnostic, not a solved fixed point.

It answers:

- where along the path the political imbalance is largest
- whether the political pressure lines up with the same periods that drive the house-price residuals
- whether equal-weight and coalition-weighted political pressure point in the same direction

It does not yet answer:

- whether the full joint price-and-vote fixed point exists
- whether the political path converges under a joint update rule

## Next escalation

If this bounded packet is numerically well behaved, the next step is a bounded joint update
experiment on the same `T = 4` horizon.

That means:

1. compute the house-price residual path
2. compute the political residual path
3. define a joint update rule for prices and the political state
4. test whether the bounded `T = 4` object stabilizes

Do not jump straight to the full 2010-2018 political RE fixed point before the bounded object is
under control.
