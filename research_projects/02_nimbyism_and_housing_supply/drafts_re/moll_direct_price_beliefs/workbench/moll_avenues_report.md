# Moll direct-price-beliefs avenues workbench

Built: 2026-05-14

Source: Benjamin Moll, rational-expectations challenge PDF,
https://benjaminmoll.com/wp-content/uploads/2024/07/challenge.pdf

## Bottom line

This workbench treats Moll as giving a route menu, not a single command
to use the existing bounded T40 object. The common denominator is direct
price beliefs: agents forecast prices directly, the forecast rule is low
dimensional, and the rule should be disciplined by expectations evidence
or updated from model outcomes.

For this project, the best immediate route is still Route B: least-squares
learning over a direct price law. Route C, restricted perceptions or
heuristics, is the best robustness route. Route A is useful only as a
baseline until measured or calibrated expectations are added. Route D is
infrastructure. Route E is future work.

## Numeric smoke results

| Route | Status | RMSE log price | Max abs log error | Decision |
|---|---|---:|---:|---|
| temporary_equilibrium_bounded_t40 | numeric_smoke_available | 0.000645269 | 0.000990327 | keep_as_baseline_only |
| survey_or_measured_price_beliefs | blocked_by_missing_expectations_data |  |  | data_gate_before_claim |
| least_squares_learning_age_price | numeric_smoke_available | 0.000344809 | 0.00125731 | build_first |
| restricted_perceptions_adaptive_anchor | numeric_smoke_available | 0.000355376 | 0.00190048 | develop_as_robustness |
| price_only_aggregate_law_ar1 | numeric_smoke_available | 0.000230369 | 0.000708108 | use_as_cross_check |
| reduced_form_price_operator_k8 | existing_numeric_operator_converged |  | 4.62977e-09 | infrastructure_not_headline |
| reinforcement_learning | not_suitable_for_current_14h_route |  |  | future_work_only |

## Route reads

- Temporary-equilibrium baseline: uses `bound40_baby_rss_l4` outer `7`.
  It is tractable and numerically usable, but still weak on empirical
  discipline and weak on belief feedback.
- Survey or measured expectations: conceptually important for Moll, but
  this local workbench has no external expectations moments wired in yet.
  This is a data gate, not a computational failure.
- Least-squares learning: the smoke rule is
  `logP_t = a + rho logP_{t-1} + beta age_signal_t`.
  Full-sample smoke coefficients are a = 0.601645,
  rho = 0.725808,
  beta = -1.39293e-05.
  This is the closest operational match to Moll because realized prices
  feed back into the perceived law of motion.
- Restricted perceptions: the best smoke heuristic is adaptive growth with
  lambda = 0 and
  anchor = 0.
  It is a good robustness candidate if calibrated to expectations evidence.
- Price-only aggregate law: the AR(1) smoke is useful as a price-only
  scaffold, but it is thinner than the age-price learning rule because it
  ignores demographic information.
- Existing reduced-form operator: the no-politics k-step price operator has
  already converged through k = 8 at re_weight = 1. It supports using a
  price-only aggregate closure as infrastructure, not as the headline
  annual political model.
- Reinforcement learning: a real avenue in the broad Moll menu, but not
  credible for the current paper timeline without a separate design.

## Next implementation step

Port Route B into the annual political baby-boom runner as the main Moll
route: generate subjective price paths from a low-dimensional perceived
law, solve temporary equilibrium, update coefficients from realized
model prices, and write coefficient and forecast-error diagnostics each
outer iteration. In parallel, keep Route C as a calibrated robustness
rule and Route A as a measured-expectations baseline once external
expectations moments are added.

## Limits

These are smoke checks on available small outputs. They do not by
themselves prove a new structural equilibrium and they do not supply the
missing empirical expectations calibration.
