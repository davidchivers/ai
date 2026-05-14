# Fixed-price policy bridge sweep report

Generated: 2026-04-08 20:55:21

## Goal

- Test whether the stable fixed-price policy bridge is specific to `2.0` or robust to a neighborhood around that benchmark.

## Cases

- fixed price 1.85: max gap = 59.906412; residual = 6.394137; price range = [2.000336, 5.000000]; stable = no
- fixed price 1.90: max gap = 35.316682; residual = 4.703678; price range = [2.000336, 5.000000]; stable = no
- fixed price 1.95: max gap = 3.339869; residual = 0.897330; price range = [2.000336, 5.000000]; stable = no
- fixed price 2.00: max gap = 0.000116; residual = 0.000061; price range = [1.908115, 2.168151]; stable = yes
- fixed price 2.05: max gap = 0.399998; residual = 20.029634; price range = [0.400000, 2.017006]; stable = no
- fixed price 2.10: max gap = 0.399999; residual = 30.860345; price range = [0.400000, 2.000336]; stable = no
- fixed price 2.15: max gap = 0.399997; residual = 30.020154; price range = [0.400000, 2.000336]; stable = no

## Read

- No tested fixed policy-reference price on this grid restored full-horizon stability.
