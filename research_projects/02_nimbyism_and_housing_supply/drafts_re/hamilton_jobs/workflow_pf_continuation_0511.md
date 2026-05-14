# 2026-05-11 Perfect-Foresight Continuation Probes

Purpose: start clean numerical continuation routes while the first-wave T80 model grid continues.

These probes do not change the expectation concept. They preserve deterministic perfect foresight, four-year block voting, pass-through `0.006`, return-to-steady-state post-report demographics, an 80-year hidden tail, and the best current delivery-lag proxy (`PassThroughLagYears = 4`).

## Rows

- Horizon continuation: solve the same best-family object at reported horizons `T20`, `T40`, and `T60`.
- Shock-amplitude continuation: solve `T80` at baby-boom amplitudes `0.10`, `0.15`, and `0.20`.

The target amplitude remains `0.25`. The amplitude rows are not final paper rows by themselves; they test whether the solver can approach the target through smaller demographic shocks.

## Verdict Rules

- `paper_safe`: `max_abs_path_gap <= 0.0002`.
- `usable`: `max_abs_path_gap <= 0.001`.
- `survivor`: `0.001 < max_abs_path_gap <= 0.003`.
- `dead`: missing, failed, or best gap above `0.003`.

If a horizon row clears, it becomes a seed candidate for the next horizon. If an amplitude row clears, it becomes a seed candidate for the next amplitude. Do not submit the next chain automatically without a checkpoint unless the user explicitly asks.
