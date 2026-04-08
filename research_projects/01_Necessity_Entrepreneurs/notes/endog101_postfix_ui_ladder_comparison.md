# case 101 post-fix endogenous UI comparison

Run settings (all three): `SingleCase=101`, `MaxIterAgg=40`, `RngSeed=12345`, endogenous tax closure.

## Aggregate outcomes

| Metric | Baseline (UI=0.40) | Low UI (UI=0.05) | No UI (UI=0.00) |
|---|---:|---:|---:|
| `entr_share` | 0.07884 | 0.07944 | 0.08466 |
| `r_new` | 0.0959105 | 0.0891537 | 0.0848609 |
| `w_new` | 3.15002 | 3.25114 | 3.33355 |
| `theta_new` | 0.611106 | 0.628019 | 0.611910 |
| `best_tol` | 0.00680465 | 0.00195998 | 0.00556019 |
| `tau_y` (equilibrium line) | 0.0181222 | 0.00276838 | 0.00065727 |
| `tau_y` (simulation update) | 0.0183684 | 0.00212041 | 3.88994e-07 |
| `total_tax` | 6584.28 | 1056.83 | 254.129 |
| `total_lower_out` | 8994.34 | 1092.55 | 0 |

## Firm size by education (mean entrepreneur labor demand `n`)

| Education group | Baseline (UI=0.40) | Low UI (UI=0.05) | No UI (UI=0.00) |
|---|---:|---:|---:|
| Low edu | 8.9299 | 8.7125 (-2.43%) | 5.6389 (-36.85%) |
| Medium edu | 12.0528 | 11.6187 (-3.60%) | 10.8825 (-9.71%) |
| High edu | 21.5651 | 21.9708 (+1.88%) | 21.6084 (+0.20%) |
| All entrepreneurs | 14.9009 | 14.6931 (-1.39%) | 13.6459 (-8.42%) |

## Interpretation notes

- The post-fix runs do show stronger effects than the pre-fix comparisons: entry increases and taxes drop sharply as UI is cut.
- The worker-risk channel is muted because `theta` remains high and similar across baseline and no-UI in these runs; logs show `v_floor=1` and `v_mode=2` at the final iterations.
- A large part of the no-UI effect is a fiscal/tax channel (UI outlays collapse, endogenous tax falls), with firm-size contraction concentrated in low- and medium-education entrepreneurs.

## Log files

- `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_endog101_baseline_m40_uioverridefix_20260305_20260305_145040.log`
- `calibration/ai_calibration/runtime/data/output/case_1/run_ui_005_endog101_ui005_m40_uioverridefix_20260305_20260305_150731.log`
- `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_endog101_ui000_m40_uioverridefix_20260305_20260305_145727.log`
