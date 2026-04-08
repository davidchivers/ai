# Current findings

## Status

This note records the current state of the anticipated-demographics RE extension before the structural MATLAB endpoint files are restored.

## What has been run

The reduced-form aggregate toy benchmark in `matlab/run_anticipated_demographics_re_toy.m` has been run locally in MATLAB.

The structural scaffold in `matlab/run_anticipated_demographics_re_structural.m` has also been tested, but it currently stops with `missing_inputs` because the required structural endpoint `.mat` files are not yet available in this repo clone.

## Toy benchmark results

Latest read from `results/anticipated_demographics_re_toy.csv`:

- steady-state support index `theta_ss = 0.1425`
- peak myopic price index `= 1.1471`
- peak anticipated-demographics RE price index `= 1.4897`
- max RE-minus-myopic price gap `= 0.3650`

Timing:

- anticipated-demographics RE crosses above price index `1.0` in period `4`
- myopic benchmark crosses above `1.0` in period `6`
- anticipated-demographics RE peaks in period `9`
- myopic benchmark peaks in period `12`

## Interpretation

The extension does not just raise prices mechanically.

Instead, it sharpens the whole boom cycle:

- while the boom cohort is young, forward-looking voters place more weight on the future political consequences of the boom, which deepens the early pro-supply / low-price phase
- once that cohort approaches older, more NIMBY ages, the high-price phase arrives earlier and becomes much larger than in the myopic benchmark

So the anticipated-demographics channel appears to:

- front-load the political-housing response
- increase the amplitude of the later price upswing
- matter even without coalitions or dynamic bargaining

## Important caveat

These numbers are not yet structurally calibrated. The toy benchmark uses an illustrative mapping from age composition to support and from support to prices. It is useful as a proof of concept, not as a quantitative result for the paper.

## Structural next step

Once the legacy structural endpoint files are available, the intended workflow is:

1. place raw `SS_iter.mat` and `SS_iter_boom.mat` files into `extension/input/`, or restore them under `code/steadystate/`
2. run the extension pipeline
3. let the pipeline export lightweight endpoint objects automatically
4. run the structural anticipated-demographics benchmark and compare it to the myopic baseline
