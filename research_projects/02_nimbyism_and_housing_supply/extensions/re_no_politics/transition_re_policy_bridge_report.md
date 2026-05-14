# Policy bridge report

Generated: 2026-04-08 14:41:50

## Goal

- Replace the explosive full backward-looking within-path policy map with a simpler bridge object based on steady-state policy rules.
- Check first whether that simplification fixes the `k = 2` problem, then test how far the same bridge survives as the horizon is extended.

## k=2 policy bridge cases

- full_backward_fixed_tail_2_0: mode = full_backward; implied p2 = 162.950526; final p2 = 5.000000; max gap = 157.950526; excess demand 2 = 3.033406
- steady_state_by_period_price: mode = steady_state_by_period_price; implied p2 = 2.089565; final p2 = 2.083034; max gap = 0.006531; excess demand 2 = 0.000125
- steady_state_fixed_price_2_0: mode = steady_state_fixed_price; implied p2 = 2.089565; final p2 = 2.083034; max gap = 0.006531; excess demand 2 = 0.000125

## Best k=2 bridge case

- Case: steady_state_fixed_price_2_0
- Max gap: 0.006531
- Residual norm: 0.003131
- Final price path: [2.000336, 2.083034]
- Implied price path: [2.000336, 2.089565]

## k-step ladder: by-period-price policies

- k = 1: max gap = 0.000000; residual = 0.000000; price range = [2.000336, 2.000336]
- k = 2: max gap = 0.006531; residual = 0.003131; price range = [2.000336, 2.083034]
- k = 3: max gap = 0.020795; residual = 0.012257; price range = [1.707319, 2.089096]
- k = 4: max gap = 68.708316; residual = 2.690678; price range = [1.688008, 5.000000]

## k-step ladder: fixed-price-2.0 policies

- k = 1: max gap = 0.000000; residual = 0.000000; price range = [2.000336, 2.000336]
- k = 2: max gap = 0.006531; residual = 0.003131; price range = [2.000336, 2.083034]
- k = 3: max gap = 0.012494; residual = 0.005784; price range = [2.000336, 2.155656]
- k = 4: max gap = 0.011191; residual = 0.005234; price range = [2.000336, 2.167251]
- k = 5: max gap = 0.000805; residual = 0.000420; price range = [2.000336, 2.168086]
- k = 6: max gap = 0.002765; residual = 0.001358; price range = [2.000336, 2.168146]
- k = 7: max gap = 0.002822; residual = 0.001442; price range = [1.963150, 2.168150]
- k = 8: max gap = 0.006456; residual = 0.003379; price range = [1.914538, 2.168151]
- k = 9: max gap = 0.001615; residual = 0.000852; price range = [1.908545, 2.168151]

## Interpretation

- The policy bridge materially changes the k = 2 result. The max gap falls from roughly 158 under the dynamic benchmark to about 0.007 under the bridge.
- The bridge remains numerically well behaved through k = 3.
- The same bridge breaks again at k = 4, where the max gap jumps to about 68.708.
- If the policy bridge is fixed at price 2.0, the ladder remains numerically well behaved through k = 9.
- At the full 9-period horizon, the fixed-price bridge ends with max gap about 0.002 and price range [1.909, 2.168].
- That pattern says the explosive part of the original transplant is mainly the full forward-looking within-path policy feedback reacting to low current prices, not just the terminal tail.
- The fixed-price policy bridge is therefore the first reduced-form branch that stays stable across the full horizon.

## Next step

- Treat the fixed-price policy bridge as the canonical simplified RE branch for any further NIMBY work.
- If this branch continues, the next technical question is whether the fixed-price bridge can be interpreted as a reduced-form expectations object worth writing up, not whether the old full transplant should be tuned again.
