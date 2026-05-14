# k=2 bridge report

Generated: 2026-04-08 13:34:21

## Goal

- Test whether the immediate `k = 2` instability is mainly being driven by the terminal steady-state continuation object.
- Hold the rest of the fertility-style bounded solve fixed and vary only how the terminal reference price is chosen.

## Cases

- path_end_price_tail: mode = path_end_price; terminal reference price used = 5.000000; final p2 = 5.000000; implied p2 = 164.389623; max gap = 159.389623
- initial_path_price_tail: mode = initial_path_price; terminal reference price used = 2.000336; final p2 = 5.000000; implied p2 = 162.950526; max gap = 157.950526
- fixed_price_2_0_tail: mode = fixed_price; terminal reference price used = 2.000000; final p2 = 5.000000; implied p2 = 162.950526; max gap = 157.950526

## Best current bridge case

- Case: fixed_price_2_0_tail
- Max gap: 157.950526
- Residual norm: 3.484009
- Final price path: [2.000336, 5.000000]
- Implied price path: [2.000336, 162.950526]
- Excess demand path: [0.000000, 3.033406]

## Interpretation

- Tail simplification alone does not materially fix the `k = 2` instability. That points away from the terminal steady-state tail as the sole bottleneck.

## Next step

- If one case clearly dominates, build the next reduced-form bridge around that case.
- If all cases remain explosive, simplify the within-period or age-profile object next rather than only the terminal tail.
