# Policy bridge band sweep report

Generated: 2026-04-08 16:50:22

## Goal

- Test whether the fixed-price bridge can be relaxed into a narrow benchmark band around `2.0`.
- Separate the role of low-price and high-price policy feedback.

## Benchmark row

- fixed-price-2.0 benchmark: max gap = 0.000116; residual = 0.000061; price range = [1.908115, 2.168151]

## Band cases

- band [1.95, 2.05]: max gap = 0.151603; residual = 0.090605; price range = [1.516367, 2.623114]; stable = no
- band [1.95, 2.10]: max gap = 1.016677; residual = 0.874565; price range = [1.717214, 2.279472]; stable = no
- band [1.90, 2.10]: max gap = 2.990741; residual = 0.987396; price range = [1.717214, 5.000000]; stable = no
- band [1.90, 2.15]: max gap = 2.987049; residual = 0.965841; price range = [1.717214, 5.000000]; stable = no

## Read

- No tested benchmark band restored the same level of stability as the fixed-price bridge.
- That points back to a stronger interpretation: the current best reduced-form expectations object is a nearly frozen benchmark-price policy map, not merely a clipped current-price rule.
