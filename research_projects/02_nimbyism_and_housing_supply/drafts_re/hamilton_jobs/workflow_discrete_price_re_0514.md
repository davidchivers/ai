# Discrete-price RE approximation workflow

## Motivation

This follows Zac's suggested simplification: reduce the full RE problem from an
80-period continuous price vector to an 80-period sequence on a small price
grid. The first grid has three states: the steady-state price, 5 percent below,
and 5 percent above.

## Computational object

For a grid price sequence `P_g`:

1. solve the annual household/political transition taking `P_g` as the expected
   future price path;
2. compute the continuous generated price path `G(P_g)`;
3. snap `G(P_g)` to the nearest grid state;
4. iterate until the grid sequence is fixed or a cycle is detected.

A fixed sequence is a discrete-grid RE fixed point. A cycle is not a failure of
the code; it means the projected finite-state map does not settle from that
seed.

This is not yet the more literal multinomial voting model in which households
vote directly among all grid-price alternatives. It is the faster and safer
first implementation of the price-grid idea.

## Rows

| Row | Tag | Grid | Horizon | Seed |
|---:|---|---:|---:|---|
| 1 | `disc3_t40_flat` | 3 states, +/-5 percent | T40 + 40 tail | steady |
| 2 | `disc3_t80_flat` | 3 states, +/-5 percent | T80 | steady |
| 3 | `disc3_t80_source` | 3 states, +/-5 percent | T80 | quantized bounded path |
| 4 | `disc3_t80_high12` | 3 states, +/-5 percent | T80 | steady then high from period 12 |
| 5 | `disc5_t40_source` | 5 states, +/-5 percent | T40 + 40 tail | quantized bounded path |

## Outputs

Each row writes to:

```text
truth/discrete_price_re/<run_tag>/
```

Key files:

- `discrete_iterations.csv`: fixed-sequence, cycle, and residual diagnostics.
- `discrete_states_all.csv`: period-by-period current state, generated price,
  snapped next state, vote, pressure, and housing quantities.
- `price_grid.csv`: grid values.
- `status.csv` and `note.md`: final status and interpretation.

Close out with:

```bash
python3 closeout_discrete_price_re_0514.py --annual-dir .
```
