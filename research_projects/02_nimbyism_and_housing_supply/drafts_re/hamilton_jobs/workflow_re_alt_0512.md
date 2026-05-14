# RE Alternatives Packet 2026-05-12

This is an eight-hour parallel packet for paper-facing alternatives to the failed blind annual T80 baby-boom RE transition.

The rows are grouped by interpretation:

1. `secular_nore` and `secular_re`: rerun the secular demographic projection rather than the temporary baby boom. This is the best paper route if the point is persistent demographic pressure.
2. `official_projection_re`: use the model's built-in official projection hooks if the forecast path is available in the source file.
3. `projected_pf`: keep the baby-boom shock but solve the perfect-foresight path in a deliberately low-dimensional smooth basis. This is a projected RE approximation, not another blind 80-price retry.
4. `local_linear_proxy`: solve small-shock perfect-foresight rows that can be scaled/interpreted as a local-linear sequence-space response if the residuals are small.
5. `partial_equilibrium_pf`: hold the no-RE price path fixed and solve households with perfect foresight over that path. This is a mechanism decomposition, not a headline equilibrium result.
6. `bounded_expectations`: give agents a 40- or 60-year forecast horizon and a terminal rule. This is not infinite-horizon RE, but it is conceptually cleaner than pretending the failed T40 object is a full T80 equilibrium.

Decision gates:

- `paper_safe`: `max_abs_path_gap <= 0.0002`.
- `usable`: `max_abs_path_gap <= 0.001`.
- `survivor`: `0.001 < max_abs_path_gap <= 0.003`.
- `diagnostic`: partial-equilibrium and local-linear rows are useful for mechanism even if they are not full nonlinear equilibrium rows.

Operational rule: do not submit another chained wave inside this packet. At the eight-hour checkpoint, rank all completed rows and choose between a paper route, a diagnostic-only route, or stopping the RE price-path figure attempt.
