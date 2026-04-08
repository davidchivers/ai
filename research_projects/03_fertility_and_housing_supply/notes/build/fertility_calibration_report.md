# Fertility calibration sweep

## Workflow

- Stage 1 uses a coarse solver screen with `I = 20`, `J = 6` on prices `1.50, 2.00, 3.00`.
- Full verification uses the default solver grids on prices `1.50, 2.00, 2.50, 3.00`.
- Market checks use `ClearMarkets_fertility.m` on `1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.25, 3.50` for a small shortlist.

Calibration price: `a_price = 2.00`
Calibration age for completed fertility: `50`

Target completed-fertility distribution (`0,1,2,3+`): [0.165, 0.193, 0.357, 0.285]

Children-at-home is still reported separately as a temporary state.
Leave-home timing remains disciplined by the Census-based leave-by-bin calibration.

## Best full demographic candidate

- candidate id: 1
- birth utilities: [0.8500, 1.1000, 1.2000]
- child utility: 0.0200
- birth cost: 0.0600
- birth price coeff: 0.2400
- lambda crowd: 0.1800
- demographic score: -7.131
- benchmark score: -4.173
- birth decline (1.5 to 3.0): 0.457713
- vote sign changes on verification grid: 1
- vote low-price positive / high-price negative: 1 / 1
- max mass error: 1.776e-14
- completed-fertility shares at age 50: [0.223716, 0.255603, 0.292729, 0.227952]
- share with any children at home, age 40: 0.718948
- share with any children at home, age 50: 0.695708
- mean children at home, age 40: 1.096502
- mean children at home, age 50: 1.264909

## Best full benchmark candidate

- candidate id: 1
- birth utilities: [0.8500, 1.1000, 1.2000]
- child utility: 0.0200
- birth cost: 0.0600
- birth price coeff: 0.2400
- lambda crowd: 0.1800
- demographic score: -7.131
- benchmark score: -4.173
- birth decline (1.5 to 3.0): 0.457713
- vote sign changes on verification grid: 1
- vote low-price positive / high-price negative: 1 / 1
- max mass error: 1.776e-14
- completed-fertility shares at age 50: [0.223716, 0.255603, 0.292729, 0.227952]
- share with any children at home, age 40: 0.718948
- share with any children at home, age 50: 0.695708
- mean children at home, age 40: 1.096502
- mean children at home, age 50: 1.264909

## Current solver defaults

- candidate id: 0
- birth utilities: [0.8500, 1.1000, 1.2000]
- child utility: 0.0200
- birth cost: 0.0600
- birth price coeff: 0.2400
- lambda crowd: 0.1800
- demographic score: -7.131
- benchmark score: -4.173
- birth decline (1.5 to 3.0): 0.457713
- vote sign changes on verification grid: 1
- vote low-price positive / high-price negative: 1 / 1
- max mass error: 1.776e-14
- completed-fertility shares at age 50: [0.223716, 0.255603, 0.292729, 0.227952]
- share with any children at home, age 40: 0.718948
- share with any children at home, age 50: 0.695708
- mean children at home, age 40: 1.096502
- mean children at home, age 50: 1.264909

## Market checks

- candidate 1: exists 1, unique 1, sign changes 1, refined price 1.751853, method `linear_interpolation`, benchmark score -4.173
- candidate 3: exists 1, unique 1, sign changes 1, refined price 1.751853, method `linear_interpolation`, benchmark score -4.173
- current defaults: exists 1, unique 1, sign changes 1, refined price 1.751853, method `linear_interpolation`, benchmark score -4.173
- candidate 12: exists 1, unique 1, sign changes 1, refined price 1.566648, method `linear_interpolation`, benchmark score -4.442

## Shortlist summaries

Top stage-1 demographic candidates by candidate id: `1, 3, 12, 7, 23, 9`

Top stage-1 benchmark candidates by candidate id: `1, 3, 12, 4, 7, 23`

### Top full candidates by benchmark score

- candidate 1: utilities [0.850, 1.100, 1.200], child utility 0.020, birth cost 0.060, price coeff 0.240, lambda 0.180, parity50 [0.224, 0.256, 0.293, 0.228], vote sign changes 1, benchmark score -4.173
- candidate 3: utilities [0.850, 1.100, 1.200], child utility 0.020, birth cost 0.060, price coeff 0.240, lambda 0.180, parity50 [0.224, 0.256, 0.293, 0.228], vote sign changes 1, benchmark score -4.173
- candidate 12: utilities [1.105, 1.385, 1.419], child utility 0.058, birth cost 0.099, price coeff 0.364, lambda 0.223, parity50 [0.100, 0.149, 0.344, 0.407], vote sign changes 1, benchmark score -4.442
- candidate 7: utilities [1.100, 1.450, 1.500], child utility 0.040, birth cost 0.070, price coeff 0.320, lambda 0.280, parity50 [0.320, 0.205, 0.268, 0.206], vote sign changes 1, benchmark score -7.813
- candidate 23: utilities [0.999, 1.072, 1.108], child utility 0.065, birth cost 0.158, price coeff 0.439, lambda 0.133, parity50 [0.233, 0.326, 0.283, 0.157], vote sign changes 1, benchmark score -9.290

## Promoted benchmark

A unique market-crossing candidate was found and is eligible for promotion.

## Promoted benchmark candidate

- candidate id: 1
- birth utilities: [0.8500, 1.1000, 1.2000]
- child utility: 0.0200
- birth cost: 0.0600
- birth price coeff: 0.2400
- lambda crowd: 0.1800
- demographic score: -7.131
- benchmark score: -4.173
- birth decline (1.5 to 3.0): 0.457713
- vote sign changes on verification grid: 1
- vote low-price positive / high-price negative: 1 / 1
- max mass error: 1.776e-14
- completed-fertility shares at age 50: [0.223716, 0.255603, 0.292729, 0.227952]
- share with any children at home, age 40: 0.718948
- share with any children at home, age 50: 0.695708
- mean children at home, age 40: 1.096502
- mean children at home, age 50: 1.264909

