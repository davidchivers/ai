# Annual map ladder summary, 2026-04-25

This ladder repeats the saved-grid annual political pass-through smoke at short and long
horizons. It is a diagnostic only: no new household Bellman solves and no true annual
transition equilibrium.

## Inputs

- source grid: `C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_IRF\loop101_output_extended.mat`
- target vote share: saved year-2000 reference vote
- reference price: saved year-2000 reference price
- political rule: vote residual -> `tanh` pressure -> permit/supply restriction
- price rule: reference price multiplied by `exp(gamma * restriction)`

## Ladder Results

| horizon | verdict | rho | phi | gamma | max abs vote residual | improvement | max abs log price move | grid hit share |
|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 4 | usable | 0.00 | 0.10 | 1.00 | 0.003312 | 0.022987 | 0.086552 | 0.000 |
| 8 | usable | 0.00 | 0.06 | 1.00 | 0.005655 | 0.020644 | 0.051931 | 0.000 |
| 16 | usable | 0.00 | 0.06 | 1.00 | 0.005655 | 0.020644 | 0.051931 | 0.000 |
| 80 | usable | 0.00 | 0.10 | 1.00 | 0.011425 | 0.026749 | 0.095697 | 0.000 |

## Read

The saved-grid map supports the soft pass-through idea. Moderate values around
`phi * gamma = 0.06` to `0.10` reduce the vote residual substantially without forcing
exact political clearing and without hitting the saved price grid.

The next serious test is a real annual `T = 4` transition smoke. The saved-grid ladder is
not enough to send an 80-year job to Hamilton, because it does not yet include annual
household transition dynamics or a structural permit/stock law.
