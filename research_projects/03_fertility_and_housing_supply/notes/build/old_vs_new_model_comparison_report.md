# Old vs new fertility model comparison (MATLAB)

- Generated (local time): 2026-03-01 11:34:10
- Design: temporary baby-boom shock (NIMBY-style), not family-supply shock
- Damping: 0.25
- Baby-boom multiplier: +60% (t=15 to t=24)
- Post window starts at t=40

## Summary metrics

| scenario | avg_price_t10_79 | avg_fertility_t10_79 | avg_births_t10_79 | final_price | final_fertility | max_abs_price_change |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| new_baseline | -0.481302 | 0.242296 | 0.086596 | -0.291744 | 0.233219 | 0.034219 |
| old_baseline_proxy | -0.802918 | 0.250601 | 0.090200 | -0.906783 | 0.250553 | 0.046710 |
| new_baby_boom | -0.469690 | 0.262527 | 0.094974 | -0.232925 | 0.230491 | 0.034796 |
| old_baby_boom_proxy | -0.880026 | 0.269794 | 0.097931 | -1.005662 | 0.250553 | 0.055992 |

## Phase deltas (shock - baseline)

| model | delta_fertility_pre | delta_fertility_boom | delta_fertility_post | delta_price_pre | delta_price_boom | delta_price_post |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| new | 0.000000 | 0.145361 | -0.001812 | 0.000000 | -0.001259 | 0.038142 |
| old_proxy | 0.000000 | 0.141054 | -0.000107 | 0.000000 | -0.019750 | -0.085626 |

## Notes

- The full upstream project-02 MATLAB steady-state run still needs missing external `.mat` inputs in this repo copy.
- Old-model series here is the pre-fertility-channel proxy with the same exogenous baby-boom shock.
