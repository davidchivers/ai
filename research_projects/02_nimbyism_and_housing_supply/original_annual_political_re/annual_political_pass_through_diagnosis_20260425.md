# Annual Political Pass-Through Diagnosis, 2026-04-25

## Bottom Line

The annual political pass-through mechanism now has three layers of support:

1. Saved-grid map smoke.
2. Annual dynamic-distribution ladder at `T = 4, 8, 12`.
3. Broader annual dynamic `T = 12` pass-through grid.

The key result is that the mechanism is not a one-parameter fluke. A family of
pass-through settings keeps political vote residuals low while requiring only small
price movements.

## Mechanism

The model no longer forces political preferences to clear exactly like a market. Instead:

```text
vote residual -> political pressure -> permit/supply restriction -> price movement
```

The smoke rule is:

```text
pressure_t    = tanh(vote_residual_t / vote_scale)
restriction_t = rho * restriction_{t-1} + phi * pressure_t
price_t       = reference_price * exp(gamma * restriction_t)
```

This means politics is a pressure process, not an exact zero-residual clearing condition.

## Dynamic Ladder

The first three-candidate annual dynamic ladder used the annual `Mod_IRF` household code and
moved the distribution forward with `solve_dyndist`.

| horizon | best max vote residual | best max log price move | read |
|---:|---:|---:|---|
| 4 | 0.00534 | 0.02330 | usable |
| 8 | 0.00534 | 0.02550 | usable |
| 12 | 0.00534 | 0.02581 | usable |

The ladder did not deteriorate as horizons increased from `T = 4` to `T = 12`.

## Broad Grid

The broader controller first ran 108 saved-grid combinations over:

- `phi = 0.03, 0.06, 0.10, 0.15`
- `gamma = 0.50, 1.00, 1.50`
- `rho = 0, 0.50, 0.85`
- `vote_scale = 0.015, 0.020, 0.030`

It then selected 9 no-grid-hit usable candidates and ran the annual dynamic `T = 12` solve.
All 9 selected dynamic candidates were usable.

Best rows by vote scale:

| vote scale | rho | phi | gamma | max vote residual | max log price move |
|---:|---:|---:|---:|---:|---:|
| 0.015 | 0.00 | 0.06 | 1.00 | 0.00632 | 0.02385 |
| 0.020 | 0.00 | 0.15 | 0.50 | 0.00637 | 0.02309 |
| 0.030 | 0.00 | 0.10 | 1.00 | 0.00651 | 0.02135 |

Overall selected dynamic range:

- max vote residual: `0.00632` to `0.00755`
- max log price movement: about `0.018` to `0.024`

## Interpretation

The robust region is roughly:

- `rho = 0`
- effective pass-through `phi * gamma` around `0.06-0.10`
- vote scale between `0.015` and `0.030`

Economically, this says political pressure can move permits/supply enough to stabilize the
political residual, but it does not need to force exact political clearing or generate large
price jumps.

## Hamilton Step

Submitted Hamilton array:

- Slurm array job: `16893451`
- stage: `annpol_lad_20260425_184041`
- horizons: `T = 20, 40`
- vote scales: `0.015, 0.020, 0.030`
- candidates: 3 per vote scale
- tasks: 6 array jobs

This is the right next step before considering `T = 80`.
