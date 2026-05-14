# Wide T80 RE Transition Search 2026-05-12

Purpose: thirteen-hour Hamilton packet to search broadly for a full T80 baby-boom rational-expectations transition equilibrium.

Run from:

`/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual`

Files:

- `model_re_wide_0512.csv`
- `run_re_wide_0512.m`
- `bb80rewide_0512.slurm`
- `rank_re_wide_0512.py`

Submit:

```bash
sbatch bb80rewide_0512.slurm
```

Rank:

```bash
python3 rank_re_wide_0512.py --annual-dir . --grid model_re_wide_0512.csv --out-dir truth/re_wide_0512
```

The packet has 40 parallel rows. It keeps the four-year political block and the main pass-through `0.006` for the headline rows, but spreads across:

- T40/T60 bounded-expectations sources promoted to full T80 with shifted no-RE tails.
- Best bridge/failsafe survivor paths continued and refocused.
- Terminal closure, hidden-tail, basis-dimension, and residual-focus windows.
- Delivery-lag diagnostics around the current best 4-year lag.
- Lower pass-through and lower-shock homotopy diagnostics.
- No-RE and small-shock paths as alternative initial guesses.

Decision thresholds:

- `paper_safe`: `max_abs_path_gap <= 0.0002`
- `usable`: `<= 0.001`
- `survivor`: `0.001 < gap <= 0.003`
- `dead`: missing, failed, or `> 0.003`

Interpretation guard: rows labelled `homotopy_diagnostic`, `lag_sweep`, `seed_diagnostic`, or `blind_restart` are search aids unless they clear at the paper target. The main paper-route candidates are rows labelled `full_t80_bridge_candidate` and `projected_pf_candidate` at pass-through `0.006`, shock amplitude `0.25`, horizon `80`.
