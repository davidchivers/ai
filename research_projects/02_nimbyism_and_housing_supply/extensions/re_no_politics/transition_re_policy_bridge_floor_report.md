# Policy bridge floor sweep report

Generated: 2026-04-08 16:40:08

## Goal

- Keep the within-path policy bridge tied to current prices, but clip that policy reference path from below.
- Locate the lowest floor that restores full-horizon numerical stability.
- Interpret the fixed-price bridge as an anchored-expectations object rather than as a one-off numerical trick.

## Benchmark rows

- fixed-price-2.0 benchmark: max gap = 0.000116; residual = 0.000061; price range = [1.908115, 2.168151]
- by-period unclipped bridge: max gap = 223.376777; residual = 5.977617; price range = [1.272223, 5.000000]

## Floor sweep

- floor 1.80: max gap = 27.435547; residual = 3.329260; price range = [0.414313, 5.000000]; policy-ref range = [1.800000, 5.000000]; floor bindings = 2; stable = no
- floor 1.85: max gap = 15.907045; residual = 2.847619; price range = [1.186870, 5.000000]; policy-ref range = [1.850000, 5.000000]; floor bindings = 2; stable = no
- floor 1.90: max gap = 5.497882; residual = 8.193505; price range = [0.400000, 5.000000]; policy-ref range = [1.900000, 5.000000]; floor bindings = 3; stable = no
- floor 1.95: max gap = 2.789425; residual = 1.952073; price range = [0.443922, 2.279472]; policy-ref range = [1.950000, 2.279472]; floor bindings = 5; stable = no
- floor 2.00: max gap = 0.210297; residual = 0.202073; price range = [1.363088, 2.089565]; policy-ref range = [2.000000, 2.089565]; floor bindings = 7; stable = no

## Threshold read

- No tested by-period floor restored full-horizon stability on this sweep.

## Interpretation

- The key margin is not within-path updating itself. The key margin is whether that updating is allowed to follow the low-price tail too far down.
- If a modest floor restores stability, the fixed-price-2.0 bridge is best read as an anchored-expectations approximation: households update with current prices only inside a benchmark band.
- If the lowest stable floor lies close to the minimum price on the fixed-price benchmark path, that sharpens the earlier diagnosis that low current-price policy feedback is the object that reintroduces the blow-up.
