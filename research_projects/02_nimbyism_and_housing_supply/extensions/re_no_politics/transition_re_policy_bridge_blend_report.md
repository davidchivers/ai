# Policy-bridge blend report

This note records the next rung between the stable fixed-price policy bridge and the pure by-period-price bridge.

## Objects

- Full-horizon blend sweep:
  policy-reference path
  `(1 - alpha) * 2.0 + alpha * current_price_path`
  over the full 2010-2018 horizon.
- Blend ladder:
  the same policy-reference object, but extended in horizon length `k = 1, 2, ...` with the same
  `25`-iteration budget used in the earlier policy-bridge ladder.

## Files

- `run_transition_re_policy_bridge_blend_sweep.m`
- `run_transition_re_policy_bridge_blend_sweep.ps1`
- `run_transition_re_policy_bridge_blend_ladder.m`
- `run_transition_re_policy_bridge_blend_ladder.ps1`
- `workflow_re_policy_bridge_blend.md`
- `workflow_re_policy_bridge_blend_ladder.md`

## Full-horizon read

- Refined full-horizon sweep outputs:
  - `transition_re_policy_bridge_blend_refine_0_05_summary.csv`
  - `transition_re_policy_bridge_blend_mid_0_015_summary.csv`
- Stable full-horizon cases on the tested grid:
  - `alpha = 0.00`
  - `alpha = 0.01`
  - `alpha = 0.015`
- On those stable full-horizon cases:
  - max gap is about `0.00033`
  - price range stays about `[1.9081, 2.1682]`
- First unstable full-horizon case on the refined grid:
  - `alpha = 0.02`
  - max gap rises to about `0.0759`
  - residual norm rises to about `0.0896`
- By `alpha = 0.05`, the full-horizon case is much worse again.

So the full-horizon read is still sharp:
small amounts of current-price feedback are tolerated, but the full 9-period path becomes unstable by about `alpha = 0.02`.

## k-ladder read

- Ladder outputs:
  - `transition_re_policy_bridge_blend_ladder_frontier.csv`
  - `transition_re_policy_bridge_blend_ladder_alpha_0_05_frontier.csv`
  - `transition_re_policy_bridge_blend_ladder_alpha_1_00_frontier.csv`
  - `transition_re_policy_bridge_blend_ladder_alpha_0_02_frontier.csv`
- Matched-budget ladder results:
  - `alpha = 1.00`:
    stable through `k = 3`, unstable at `k = 4`
  - `alpha = 0.05`:
    stable through `k = 4`
  - `alpha = 0.02`:
    stable through at least `k = 5` in the checkpointed ladder output
  - `alpha = 0.00`, `0.01`, `0.015`:
    stable through the full ladder `k = 9`
- A longer timed rerun for `alpha = 0.02` reached a stable `k = 6` before entering `k = 7`,
  but that continuation was stopped by the wall-clock cap rather than by a clean numerical failure.

So the matched-budget ladder is less sharp than the full-horizon sweep.
The full-horizon problem rejects `alpha = 0.02`, but shorter ladders can still absorb some current-price feedback before the instability returns.

## Interpretation

- The old simple story was:
  stable only in a tiny neighborhood of the fixed-price branch.
- The updated story is:
  that is true for the full 9-period horizon, but not for shorter ladders.
- So the structural difficulty grows with both:
  - the amount of current-price feedback
  - the length of the forward-looking horizon

The most useful current reading is therefore:

- reduced-form operator:
  easiest rung
- fixed-price policy bridge:
  next stable structural proxy
- blended current-price bridge:
  intermediate rung whose frontier shrinks as the horizon lengthens
- pure by-period-price bridge:
  stable only on short ladders
- full structural household-policy block:
  still the hard unsolved object
