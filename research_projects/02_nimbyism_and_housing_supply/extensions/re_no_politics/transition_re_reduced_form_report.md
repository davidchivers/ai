# Reduced-form RE report

## Setup

This branch deliberately copies the fertility workflow rather than the fertility fixed-point transplant. The operator is fit on the stable fixed-price policy-bridge benchmark and then used as a separate reduced-form expectations object.

- benchmark source:
  `transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.mat`
- operator:
  current log price as a function of
  - the `25-44` population-share gap from `2010`
  - the next-period log price gap relative to the benchmark price `2.0`
- fitted next-price coefficient:
  about `0.4744`
- bounded-fit RMSE on the benchmark path:
  about `0.0325`
- reduced-form price box:
  `[1.75, 2.25]`
- tail rule:
  flat benchmark tail at `2.0`

## One-step result

The one-step reduced-form rung solves cleanly.

- solved `2011` price:
  about `2.0297`
- iterations:
  `22`
- status:
  converged

This is the right first fertility-style rung: solve one future price off the benchmark tail before asking for more internal consistency.

## k-step ladder

The finite-horizon reduced-form ladder stays stable through the full forward horizon.

| RE weight | Max stable horizon | First non-converged horizon |
|---|---:|---:|
| `0.25` | `8` | `` |
| `0.50` | `8` | `` |
| `0.75` | `8` | `` |
| `1.00` | `8` | `` |
| `1.25` | `8` | `` |

Selected full-horizon (`k = 8`) endpoints:

| RE weight | Solved `2011` price | Solved `2018` price | Price span |
|---|---:|---:|---:|
| `0.25` | `2.0329` | `2.0049` | `0.0279` |
| `0.50` | `2.0367` | `2.0049` | `0.0318` |
| `0.75` | `2.0415` | `2.0049` | `0.0366` |
| `1.00` | `2.0477` | `2.0049` | `0.0427` |
| `1.25` | `2.0557` | `2.0049` | `0.0508` |

## Read

- the reduced-form-first NIMBY branch works
- bounded RE on the smooth aggregate operator is numerically tame
- that is the same broad sequence that worked in fertility:
  reduced form first, then longer horizons
- the contrast with the structural NIMBY solver is now sharper:
  the hard part is the household-policy feedback map, not the demographic transition by itself

## Limitation

This is not yet a structural NIMBY RE solution. The operator is anchored on the stable fixed-price policy-bridge benchmark, so it should be read as a reduced-form aggregate closure, not as a replacement for the full household model.
