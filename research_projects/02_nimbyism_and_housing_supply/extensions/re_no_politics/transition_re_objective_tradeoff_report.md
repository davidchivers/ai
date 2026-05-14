# Transition RE objective tradeoff report

Generated: 2026-03-21 06:49:08

## Recommendation

- Keep `config11_global_control` as the canonical benchmark.
- Treat `aggressive_p2_b8_hybrid_relaxed` as the challenger that reveals the tradeoff, not the new default.
- Next search should optimize the worst-period / focus-region objective explicitly, because the challenger's wins are coming from the global residual rule rather than focus-region improvement.

## Headline comparison

- Control `config11_global_control`: residual norm 0.128123139190, max gap 0.165893855901, last nontrivial iteration 3, nontrivial update count 3.
- Challenger `aggressive_p2_b8_hybrid_relaxed`: residual norm 0.128074177550, max gap 0.166384245139, last nontrivial iteration 4, nontrivial update count 4.
- Tradeoff: challenger improves residual norm by 0.000048961640 and extends persistence by 1 iteration, but worsens max gap by 0.000490389238.

## Why the challenger wins

- Control accepted updates: `sequential_block_p2_1_3_0.02`, `sequential_block_p2_4_6_0.10`, `sequential_block_p2_4_6_0.01`, `current_path`, `current_path`, `current_path`.
- Challenger accepted updates: `sequential_block_p2_6_8_0.20`, `sequential_block_p2_6_8_0.10`, `sequential_block_p2_5_7_0.10`, `sequential_block_p2_5_7_0.05`, `current_path`, `current_path`.
- The control's accepted moves concentrate on blocks `1-3` and `4-6`.
- The challenger shifts accepted moves later in the path, first to `6-8` and then `5-7`.
- Control decisive-candidate counts: focus-only winners 0, global-only winners 3, both 3.
- Challenger decisive-candidate counts: focus-only winners 0, global-only winners 8, both 0.
- In the challenger, every selected improvement came from the global residual/gap rule; there were no focus-only selected wins.

## What changed economically

- Control final prices: `[2.00161 2.00173 2.00178 2.00177 2.00117 2.00057 2 2 2]`.
- Challenger final prices: `[2 2.00125 2.00129 2.00161 2.00147 2.00165 1.99988 1.99878 1.99967]`.
- Control raw log-price residuals: `[-0.000806438 0.042774 0.0796178 0.0715638 0.00180012 0.0183767 -0.0202896 -0.0473011 -0.0116153]`.
- Challenger raw log-price residuals: `[0 0.0430161 0.0798628 0.071645 0.00164804 0.0178377 -0.0202293 -0.0466936 -0.011451]`.
- Control excess-demand path: `[-3.09926e-05 0.00168031 0.00318649 0.00285248 6.92562e-05 0.000712691 -0.000771591 -0.00177481 -0.000443631]`.
- Challenger excess-demand path: `[0 0.00168962 0.00319591 0.0028556 6.34102e-05 0.000691973 -0.000769276 -0.00175148 -0.00043732]`.
- Interpretation: the challenger slightly redistributes the path, especially in later periods, but does not materially improve the peak problem around period `3`.

## Validation

- `baseline_control_validation`: residual norm 0.128123139190, max gap 0.165893855901, last nontrivial iteration 3.
- `best_variant_validation`: residual norm 0.128074177550, max gap 0.166384245139, last nontrivial iteration 4.
- The longer-horizon validation reproduces the same tradeoff instead of overturning it.

## Next workflow

- Run a narrow focus-objective follow-up around the control/challenger region.
- Prioritize cases where candidate selection can win on the focus metric itself, not only on the global residual rule.
- Keep the run bounded: a small case set, one summary CSV, one results MAT file, and one refreshed report.
