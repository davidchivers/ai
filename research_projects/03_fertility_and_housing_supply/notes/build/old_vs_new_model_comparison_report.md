# Old vs new fertility model comparison (MATLAB)

- Generated (local time): 2026-03-20 15:43:02
- Design: temporary baby-boom shock (NIMBY-style), not family-supply shock
- Damping: 0.25
- Baby-boom multiplier: +10% (t=0 to t=9)
- Post window starts at t=40

## Summary metrics

| scenario | avg_price_t10_79 | avg_fertility_t10_79 | avg_births_t10_79 | final_price | final_fertility | max_abs_price_change |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| new_baseline | -0.481302 | 0.242296 | 0.086596 | -0.291744 | 0.233219 | 0.034219 |
| old_baseline_proxy | -0.802918 | 0.250601 | 0.090200 | -0.906783 | 0.250553 | 0.046710 |
| new_baby_boom | -0.429038 | 0.239783 | 0.085652 | -0.210861 | 0.229476 | 0.034528 |
| old_baby_boom_proxy | -0.755735 | 0.250357 | 0.090200 | -0.813107 | 0.250553 | 0.047705 |
| structural_baseline | 1.004701 | 0.850000 | 0.316768 | 2.675098 | 0.850000 | 0.051100 |
| structural_baby_boom | 1.060421 | 0.850000 | 0.316875 | 2.737612 | 0.850000 | 0.051117 |

## Phase deltas (shock - baseline)

| model | delta_fertility_pre | delta_fertility_boom | delta_fertility_post | delta_price_pre | delta_price_boom | delta_price_post |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| reduced_form | NaN | 0.022342 | -0.003662 | NaN | 0.001624 | 0.076566 |
| old_proxy | NaN | 0.021652 | -0.000001 | NaN | -0.000424 | 0.072689 |
| structural_foc | NaN | 0.085000 | -0.000000 | NaN | 0.008154 | 0.061797 |

## Notes

- The full upstream project-02 MATLAB steady-state run still needs missing external `.mat` inputs in this repo copy.
- Old-model series here is the pre-fertility-channel proxy with the same exogenous baby-boom shock.
