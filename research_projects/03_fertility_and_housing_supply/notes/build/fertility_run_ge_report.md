# Fertility GE run

## Reproduction check

- Distance gap: 0
- Vote gap: 0
- Debt gap: 0

## Benchmark defaults

- solver grids: `I = 60`, `J = 14`
- birth utilities: `[0.850, 1.100, 1.200]`
- child utility: `0.020`
- birth cost: `0.060`
- birth price coeff: `0.240`
- lambda crowd: `0.180`

## Price sweep

- a_price 1.50: avg_birth_rate 0.655463, totalvote 0.236730, parity50 [0.070, 0.166, 0.349, 0.415], home-any age40 0.885, home-any age50 0.872, mass_error 1.421e-14
- a_price 2.00: avg_birth_rate 0.529015, totalvote -0.333213, parity50 [0.224, 0.256, 0.293, 0.228], home-any age40 0.719, home-any age50 0.696, mass_error 1.599e-14
- a_price 2.50: avg_birth_rate 0.364748, totalvote -0.432149, parity50 [0.460, 0.264, 0.179, 0.097], home-any age40 0.484, home-any age50 0.460, mass_error 1.776e-14
- a_price 3.00: avg_birth_rate 0.197750, totalvote -0.341994, parity50 [0.703, 0.196, 0.075, 0.026], home-any age40 0.247, home-any age50 0.241, mass_error 1.776e-14

## Market clearing

- Sign changes on supplied market grid: 1
- Vote crosses zero between 1.75 (0.008446) and 2.00 (-0.333213)
- Refined equilibrium price estimate: 1.751853 (linear_interpolation)
