# Political path diagnostic report

Generated: 2026-04-13 21:40:05

## Goal

- Build the first bounded transition packet that combines the shared Bellman preference-sign object with period-by-period political aggregation.
- Keep the run bounded: first 4 periods, one outer iteration, full backward household solve.

## Summary

- Case: political_path_t4
- Horizon: 4 periods
- Guess source: transition_re_no_politics_results.final_price_path_prefix
- Iterations completed: 1
- Residual norm: 0.116671
- Max price gap: 0.167264
- Accepted update: sequential_block_p2_1_3_0.01
- Max abs equal-weight vote: 0.970804
- Max abs coalition-weighted vote: 0.948715
- Price range after update: [2.000000, 2.000887]
- Runtime: 249.14 seconds

## Period path

- 2010: guess = 2.000336; final = 2.000625; implied = 2.000336; excess demand = -0.000006; equal-weight vote = -0.970804; weighted vote = -0.948715
- 2011: guess = 2.000403; final = 2.000772; implied = 2.089565; excess demand = 0.001705; equal-weight vote = -0.969502; weighted vote = -0.946427
- 2012: guess = 2.000450; final = 2.000887; implied = 2.168151; excess demand = 0.003212; equal-weight vote = -0.968356; weighted vote = -0.944414
- 2013: guess = 2.000000; final = 2.000000; implied = 2.150754; excess demand = 0.002895; equal-weight vote = -0.968610; weighted vote = -0.944860

## Diagnostic read

- Worst equal-weight political pressure appears in 2010, with vote = -0.970804.
- Worst coalition-weighted political pressure appears in 2010, with weighted vote = -0.948715.
- This packet does not solve the full political RE fixed point. It gives the missing time-varying political residual path conditional on the current bounded transition solve.
- That is the right next object because it tells us whether the political imbalance is concentrated in the same periods as the house-price residuals.

## Next step

- Promote this bounded political-path packet into either a longer-horizon diagnostic or a joint price-plus-vote update rule.
- If we keep the solver bounded, the clean next escalation is a T=4 political update experiment rather than jumping straight to the full 2010-2018 fixed point.
