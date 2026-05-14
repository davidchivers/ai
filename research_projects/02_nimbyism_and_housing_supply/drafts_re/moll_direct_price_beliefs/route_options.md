# Moll route options for the NIMBY extension

## Bottom line

Moll does not give a single recipe. He explicitly frames the paper as a
challenge: replace rational expectations about equilibrium prices with direct
price beliefs, then discipline those beliefs using three criteria:

1. computational tractability;
2. consistency with empirical expectations evidence;
3. endogeneity of beliefs to model reality, so the exercise has some immunity
   to the Lucas critique.

Therefore the right workflow is not "pick T40." It is to choose among several
direct-price-belief routes and be clear about what each one can claim.

## Route A: temporary equilibrium with measured or calibrated price beliefs

**Object.** Households optimise given a subjective future house-price path or
distribution. Markets clear each period under those beliefs.

**Why it is Moll-consistent.** Temporary equilibrium is the first building
block he discusses: beliefs are specified in the model and need not be rational,
while markets still clear.

**What it buys us.**

- Very tractable.
- Clean separation between household optimisation and market clearing.
- Easy to explain to readers.

**Weakness.**

- By itself it fails the belief-feedback part of Moll's third criterion. It is
  only an intermediate object unless the beliefs are measured, policy-contingent,
  or updated from model outcomes.

**NIMBY implementation.**

- Use an externally disciplined expected price path from house-price
  expectations evidence, a simple survey-calibrated growth expectation, or a
  vignette-style counterfactual belief path.
- Solve the annual political model under that belief path.
- Report as "temporary equilibrium under measured/calibrated price beliefs."

**14-hour suitability.** Good for a design memo and possibly a smoke if the
belief path can be specified without new data collection.

## Route B: least-squares learning over a perceived law of motion

**Object.** Agents forecast prices with a low-dimensional perceived law of
motion. Coefficients update from realized model prices by least squares or a
stochastic approximation rule.

**Why it is Moll-consistent.** This is one of the main routes he discusses.
It directly addresses the belief-feedback criterion while keeping the agent's
forecasting problem low dimensional.

**What it buys us.**

- Closest to an operational replacement for RE in this project.
- Tractable and recursive.
- Makes belief feedback explicit.
- Can start from existing code:
  `extensions/re_no_politics/run_linear_age_price_rule.m`.

**Weakness.**

- It still needs empirical discipline. A purely internal least-squares rule is
  not enough for paper claims unless its parameters or moments line up with
  evidence on house-price expectations.

**NIMBY implementation.**

Start with:

```text
E_t[Delta log P_{t+s}] =
    lambda^(s-1) * (a + rho Delta log P_t + beta M_{t+s})
```

where `M` is a low-dimensional public demographic pressure index. Iterate:

1. generate believed price paths from current coefficients;
2. solve the temporary-equilibrium path;
3. update coefficients from realized prices;
4. stop when coefficients and forecast-error RMSE stabilize.

**14-hour suitability.** Best default route. It is implementable from existing
code and directly responds to Moll's criteria.

## Route C: restricted perceptions / simple heuristic forecasting model

**Object.** Agents use a deliberately restricted price-forecasting model, such
as extrapolation, cognitive discounting, diagnostic expectations, or anchoring
to a benchmark price band.

**Why it is Moll-consistent.** Moll discusses heuristics and simple restricted
forecasting models as a promising direction. The key is to solve a restricted
perceptions equilibrium, not merely impose an arbitrary path.

**What it buys us.**

- Very transparent behaviorally.
- Can connect to empirical patterns: extrapolation, cognitive discounting,
  diagnostic expectations, heterogeneous beliefs.
- Can be close to existing bounded/anchored experiments in this project.

**Weakness.**

- It is easy to make this ad hoc. It needs either calibration to expectations
  evidence or a clean restricted-perceptions equilibrium condition.

**NIMBY implementation.**

Candidate rules:

- cognitive discounting of future demographic price pressure;
- adaptive/extrapolative beliefs using recent realized house-price growth;
- anchored expectations that update only inside a benchmark price band;
- heterogeneous belief types if the evidence supports it.

**14-hour suitability.** Good as a design and robustness route. A full
implementation may be secondary to Route B unless the rule is already available.

## Route D: price-only Krusell-Smith / aggregate-law route

**Object.** Agents forecast prices directly using a perceived aggregate law of
motion, rather than forecasting moments of the cross-sectional distribution.

**Why it is partly Moll-consistent.** Moll says the variant where the
Krusell-Smith moments are prices themselves is closer to the approach he
advocates, but he also says we can do better by incorporating empirical
evidence.

**What it buys us.**

- Natural computational bridge from RE.
- Keeps forecasts price-based.

**Weakness.**

- If it is not empirically disciplined, it is only a computational shortcut.

**14-hour suitability.** Useful as infrastructure or a cross-check, not the
main paper-facing route.

## Route E: reinforcement learning

**Object.** Agents learn value functions or policies from experience without
solving the full model.

**Why it is Moll-consistent.** Reinforcement learning is one of his listed
promising directions.

**What it buys us.**

- Potentially avoids specifying a perceived law of motion.
- Can be deeply aligned with experience-based learning.

**Weakness.**

- Too large for the current paper route.
- Hard to discipline and validate quickly.

**14-hour suitability.** Not suitable. Record as future work only.

## Ranking for this project

1. **Route B, least-squares learning over a direct price law:** best immediate
   route because it is implementable and satisfies the feedback criterion.
2. **Route C, restricted perceptions/simple heuristics:** best paper robustness
   route if we can discipline the rule using expectations evidence.
3. **Route A, temporary equilibrium with calibrated beliefs:** useful baseline
   but incomplete unless beliefs are measured or policy-contingent.
4. **Route D, price-only aggregate law:** useful computational scaffold.
5. **Route E, reinforcement learning:** future work.

The existing bounded T40 result belongs outside this ranking as a prototype. It
can inform Route C, but it is not itself the route Moll advocates.

## 2026-05-14 execution status

Created the small local workbench in `workbench/` and the Hamilton packet in
`../hamilton_jobs/` to test the runnable avenues rather than keep this as a
plan-only route.

Local smoke read:

| Route | Smoke object | RMSE log price | Use |
|---|---|---:|---|
| A | temporary bounded T40 baseline | `0.000645268674443` | baseline only |
| B | recursive age-price least-squares learning | `0.000344809404341` | main route |
| C | restricted static heuristic | `0.000355376384361` | robustness |
| D | price-only AR(1) | `0.000230369031896` | cross-check |

The AR(1) smoke has the lowest in-sample error because the available path is
smooth and nearly flat, but it drops the demographic channel. The preferred
paper route is still B unless the Hamilton direct-belief learning run is
unstable.

Submitted Hamilton job `17152180` (`bb80moll14`, array `1-5`) to run:

- `mollA_temp_bound40_rss`;
- `mollB_lsl_age_t40`;
- `mollC_static_t40`;
- `mollC_adapt_anchor_t40`;
- `mollD_ar1_t40`.

Measured/survey expectations remain a data gate. Reinforcement learning remains
future work.
