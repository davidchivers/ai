# Annual political comparison experiments

This workflow compares the annual political pass-through transition against two controls:

- exogenous/random house-price paths on the same annual vote map,
- the hard-sign limit where `tau = 0` and political pressure jumps to `-1`, `0`, or `1`.

The purpose is not to defend every old transition diagnostic. The purpose is to answer
whether the smoothed endogenous political rule is doing something economically useful
relative to arbitrary price paths and relative to the discontinuous median-voter rule.

## Gate 1: saved-grid comparison

Run the cheap annual map comparison first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\run_annual_political_comparison_map.ps1
```

This writes to:

```text
original_annual_political_re/truth/annual_political_comparison_map/
```

It compares:

- constant reference-price path,
- hard-clearing oracle price path, as a diagnostic only,
- smooth endogenous rule at `tau = 0.020`,
- near-hard rule at very small `tau`,
- exact hard-sign rule at `tau = 0`,
- random AR(1) exogenous price paths with matched annual vote weights.

Current full run:

```text
truth/annual_political_comparison_map/annual_comparison_map_full_20260426/
```

Read from the full saved-grid run:

- smooth `tau = 0.020` improves the `T = 80` max residual from `0.0382` to about
  `0.0189-0.0204`,
- hard-sign `tau = 0` is much weaker, with best row `0.0361` and larger eta values
  dead,
- random AR(1) price paths have zero usable draws across the tested amplitudes,
- the hard-clearing oracle is much cleaner mechanically, but requires larger direct
  price movement and is not a model closure.

## Gate 2: dynamic annual comparison

Only after Gate 1 is informative, send a small number of paths through the full annual
dynamic runner. The minimum set is:

- benchmark smooth pass-through, likely `eta = 0.090`, `0.105`, or `0.120`,
- hard-sign `tau = 0` with the same eta values,
- a few representative random/exogenous paths from Gate 1.

The full dynamic step should use the verified annual age weights and the same
death/terminal-age robustness conventions as the benchmark transition.

## Decision rules

- If random price paths often match the benchmark, the political pass-through story is
  weak and we need a different discipline.
- If hard-sign `tau = 0` performs similarly to smoothing, smoothing is mostly cosmetic.
- If hard-sign performs worse or creates unstable/jumpy paths while smoothing remains
  stable, smoothing is doing real work and is defensible as a continuous political
  pressure rule.
- If the hard-clearing oracle needs much larger price movement than the benchmark, that
  supports the reduced-form pass-through interpretation rather than exact annual vote
  clearing.
