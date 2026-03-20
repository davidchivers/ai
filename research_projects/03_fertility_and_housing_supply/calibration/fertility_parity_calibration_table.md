# Fertility parity calibration table

This table documents the active fertility-household benchmark after the
2026-03-17 corrected-code recalibration.

The model now separates:

- permanent parity `p`: children ever born
- temporary home-child state `h`: children currently at home

The model unit is interpreted as one homogeneous fertility household.

## Benchmark calibration

The active benchmark is:

| Parameter | Value |
|---|---:|
| `I` | `60` |
| `J` | `14` |
| `birth_utility_1` | `0.85` |
| `birth_utility_2` | `1.10` |
| `birth_utility_3` | `1.20` |
| `child_utility` | `0.02` |
| `birth_cost` | `0.06` |
| `birth_price_coeff` | `0.24` |
| `lambda_crowd` | `0.18` |
| `leave_home_age_bins` | `20, 25, 30` |
| `leave_home_bin_probs` | `0.588, 0.147, 0.265` |

Interpretation:

- `birth_utility_1`, `birth_utility_2`, `birth_utility_3` are reduced-form
  birth-order incentives in the persistent parity state.
- `h_t` governs crowding in housing services and remains temporary.
- the leave-home block remains a reduced-form U.S.-targeted co-residence
  calibration, not a structural model of departure expectations.

## Main completed-fertility target

Official target:

- U.S. Census, 2022, all women age `45-50`
- detailed shares:
  - `0`: `0.165`
  - `1`: `0.193`
  - `2`: `0.357`
  - `3+`: `0.285`

Model readout at `a_price = 2.0`, age `50`:

| Parity | Target | Model | Abs. error |
|---|---:|---:|---:|
| `0` | `0.165` | `0.224` | `0.059` |
| `1` | `0.193` | `0.256` | `0.063` |
| `2` | `0.357` | `0.293` | `0.064` |
| `3+` | `0.285` | `0.228` | `0.057` |

This fit is weaker than the old demographic-fit candidate, but it is the best
benchmark that also produces a clean market-clearing result once the household
grid is sufficiently fine.

## Temporary children-at-home readout

The temporary home-child state is not matched to the completed-fertility
table. It is instead disciplined by:

- fertility timing in the household block
- the leave-home bins `20/25/30`
- U.S. Census young-adult co-residence moments used in
  `fertility_leave_home_calibration_table.md`

Current readout at `a_price = 2.0`:

| Age | Share with any children at home | Mean children at home |
|---|---:|---:|
| `40` | `0.719` | `1.097` |
| `50` | `0.696` | `1.265` |

## Benchmark selection note

The corrected-code search first identified candidate 3 as the best benchmark
trade-off in parameter space:

- better equilibrium shape than the strongest demographic-fit candidate
- weaker parity fit than the demographic-fit candidate

At the old household grids `I = 50`, `J = 10`, candidate 3 showed local vote
wiggles on the fine market grid (`+,-,+,-` between `a_price = 1.5` and
`2.25`). A targeted local search over nearby parameters, logit smoothing, and
the finite-difference step did not remove those wiggles. A grid-resolution
check showed the issue was numerical:

- at `I = 60`, `J = 14`, the same candidate gives a unique crossing
- the completed-fertility distribution is unchanged to reported precision

## Equilibrium result

Under the benchmark household grid and parameters:

- the vote schedule on `a_price = 1.5:0.25:3.5` has exactly one sign change
- the crossing is between `1.75` and `2.00`
- the refined equilibrium estimate is `a_price = 1.774665`

So the current benchmark is now a clean one-crossing equilibrium calibration,
with the numerical-resolution note recorded explicitly.
