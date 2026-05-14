# Moll direct-price-beliefs Hamilton packet

## Purpose

This packet implements the runnable parts of Moll's direct price-beliefs route
without relabeling the failed full-T80 rational-expectations search.

The annual full-RE solver is used only as a temporary-equilibrium evaluator:
given a subjective future price path, it computes the generated/current-price
path implied by household choices and political restrictions. The Moll learning
routes then update the subjective price path from those generated prices.

## Rows

| Row | Tag | Moll avenue | Read |
|---:|---|---|---|
| 1 | `mollA_temp_bound40_rss` | Temporary equilibrium with specified beliefs | Baseline only; no belief feedback |
| 2 | `mollB_lsl_age_t40` | Least-squares learning over direct price law | Main route |
| 3 | `mollC_static_t40` | Restricted perceptions/static heuristic | Workbench-best heuristic |
| 4 | `mollC_adapt_anchor_t40` | Restricted perceptions/adaptive anchor | Behavioral robustness |
| 5 | `mollD_ar1_t40` | Price-only aggregate law | Infrastructure/cross-check |

Measured/survey expectations and reinforcement learning are not launched here:
the first is data-gated, and the second is too large for the current paper
route.

## Expected outputs

Each row writes to:

```text
truth/moll_direct_price_beliefs/<run_tag>/
```

Key files:

- `belief_iterations.csv`: forecast-error and belief-update diagnostics by
  learning iteration.
- `belief_paths_all.csv`: subjective price path, generated price path, and
  political quantities by period and learning iteration.
- `belief_coefficients.csv`: direct price-law or heuristic parameters by
  iteration.
- `note.md`: route description and status.

These outputs are direct-belief route diagnostics, not full-RE success rows.
