# Safeguarded Full-T80 RE Polish Packet, 2026-05-13

Purpose: make one methodologically distinct attempt at the full T80 baby-boom rational-expectations transition, starting from the best wide-packet survivors rather than launching another broad blind grid.

The wide packet's best full-T80 target row was `w80_b60hold_bl70` at outer 4, with report-window max absolute path gap `0.00101892245727956`. It narrowly missed the usable gate (`<= 0.001`) and then worsened in later iterations. The new solver copy therefore adds:

- `SafeguardBestAnchor`: when a later iteration is worse than the best report-window residual seen so far, update from the best path/residual instead of the latest path.
- `trust_region_relaxation`: direct log-price fixed-point movement `x_next = x + lambda * (F(x)-x)` with a per-period cap and optional report/tail focus weights.

Rows 1-4 start from the generated path associated with `w80_b60hold_bl70` outer 4. Row 5 starts from the generated path associated with `w80_flat_rss_b6` outer 17. The target specification remains the full T80 published baby-boom transition, pass-through 0.006, shock 0.25, lag 4. These rows should be read as a safeguarded polish/homotopy attempt, not as a new model variant.

Rank from the annual directory:

```bash
python3 rank_re_wide_0512.py --annual-dir . --grid model_re_safeguard_0513.csv --out-dir truth/re_safeguard_0513
```

Decision gates: paper-safe if `max_abs_path_gap <= 0.0002`; usable if `<= 0.001`; survivor if `0.001 < gap <= 0.003`.
