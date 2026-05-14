# Parallel Workflow - political Bellman, price path, and Hamilton

Last updated: 2026-04-14

## Goal

Run the NIMBY transition work in parallel without mixing up three different objects:

1. the current-model political Bellman path
2. the compiled parity / runtime port
3. any later construction-lag extension

The current-model object remains the baseline. A construction-lag law is a model extension, not just a solver trick.

## Lane A - MATLAB economics lane

Purpose:
- keep the current paper model fixed
- solve and diagnose the dynamic political path under the existing permit-vote closure
- map where the political Bellman object becomes hard

Current object:
- guess a house-price path
- solve the Bellman problem
- simulate the distribution forward
- compute the vote path from `sign(V^{dp} - V)`
- update the guessed path with the political residual

Current priority inside this lane:
1. keep the bounded MATLAB political path as the economic reference object
2. use `k = 1, ..., 9` horizon maps to see where the path first becomes hard
3. only after the baseline is well understood, add a separate construction-lag diagnostic branch

What counts as a model extension here:
- any partial-adjustment housing stock law
- any time-to-build or permit-to-completion lag
- any slower construction response mapping permits into delivered housing

Those changes should not be mixed into the baseline political Bellman workflow until they have literature support.

## Lane B - compiled C++ parity lane

Purpose:
- keep porting the inner and outer political Bellman objects into the compiled sidecar
- get exact parity with the MATLAB reference before using the compiled loop as the main engine

Current priority inside this lane:
1. fix the first-step `T = 4` political residual mismatch
2. compare MATLAB and sidecar vote paths period by period on the same initial path
3. only after `T = 4` parity is closed, move back to broader `T = 9` outer-loop work

Current read:
- inner political transition pass already matches MATLAB
- outer compiled wrapper still differs on the first political residual construction

## Lane C - literature lane

Purpose:
- gather local evidence for whether a slower housing-adjustment equation is defensible
- separate "numerical relaxation" from "economic construction lag"

Current priority inside this lane:
1. search the project literature and notes for permit, approval, and build delays
2. identify whether the support is strong enough for calibration or only for qualitative motivation
3. only if the support is credible, open a dedicated construction-friction branch

Current implementation status:
- a first separate diagnostic branch now exists in the extension solver:
  `housing_adjustment_mode = 'construction_lag_price_partial_adjustment'`
- this is a reduced-form price-adjustment law, not yet a fully structural
  housing-stock delivery equation
- the corresponding sweep runner is:
  `run_transition_re_construction_adjustment_sweep.m`
- keep this branch separate from the baseline instant-clearing model until the
  literature lane can justify a stronger calibration target

## Hamilton policy

Use local Windows execution for:
- file edits
- short MATLAB smoke tests
- compiled parity debugging
- quick bounded packets where logs need close inspection

Use Hamilton for:
- broad MATLAB `k` sweeps
- parameter grids over political update weights or lag values
- heavier batch packets where local CPU contention becomes annoying

Hamilton status checked on 2026-04-14:
- `ssh hamilton8 "whoami; hostname; quota; squeue -u hfnt93"` succeeded
- current host: `login1.ham8.dur.ac.uk`
- current quotas:
  - `/home`: `520M / 10G`
  - `/nobackup`: `550.8G / 600G`
- current running job at the time of check:
  - `16786759 shared fert_t13`

Practical rule:
- debug locally first
- once a MATLAB workflow is stable, move the wider sweep to Hamilton rather than saturating local CPU

## Immediate operating plan

1. Keep Lane B live locally until the first-step compiled political residual matches MATLAB on `T = 4`.
2. Keep Lane A as the current-model economics benchmark.
3. Let Lane C answer whether a construction-lag branch is worth opening.
4. If Lane A needs a wider grid than is comfortable locally, move that specific MATLAB sweep to Hamilton.
5. Do not fold a construction-lag equation into the baseline political Bellman lane until the literature case is explicit.
