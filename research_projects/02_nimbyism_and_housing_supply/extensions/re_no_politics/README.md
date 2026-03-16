# RE no-politics extension workspace

This subfolder is the implementation workspace for the no-politics rational-expectations extension described in `../re_no_politics_experiment.md`.

## Current status

- Published baseline code remains untouched.
- Extension A now has a copied steady-state solver, grid-search driver, and runnable entry point.
- Extension B now has a copied steady-state solver, coalition vote helper, grid-search driver, and runnable entry point.
- Both extension drivers are MATLAB functions so they can be called safely from the entry-point wrappers.

## Recommended code base

Use `../../code/steadystate/SolveSS_iter.m` as the main baseline for the first extension pass.

Why this file:

- it is already the object called by `../../code/steadystate/ClearMarkets.m`
- it returns useful diagnostics: `distance`, `a_price`, `rbPos`, `totalvote`, `debtstock`
- its terminal object is explicit: `distance = sum(dens4.*pref4,'all')^2`
- the political target is concentrated near the end of the file, which makes the eventual split cleaner

Do not start from `SolveSS.m` unless a script-style version is specifically needed for replication output.

## What the political block currently does

In `SolveSS_iter.m`, the code computes:

- the derivative of the value function with respect to prices
- a state-level sign preference over higher prices
- an age-weighted aggregate vote statistic
- a scalar `distance` that squares the aggregate vote imbalance

That means the current equilibrium object is a political fixed point in price space, not a rational-expectations housing-clearing fixed point.

## Implemented extensions

### Extension A: no-politics RE steady state

- Solver: `solve_ss_no_politics.m`
- Driver: `ClearMarkets_no_politics.m`
- Runner: `run_re_no_politics_extension.m`
- Equilibrium condition: `distance = (Hdemand - Hsupply)^2`
- Supply rule: `Hsupply = Hbar * (a_price / Pbar)^eta_s`
- Output file: `SS_no_politics_iter.mat`

### Extension B: coalition-weighted voting

- Solver: `solve_ss_coalition.m`
- Driver: `ClearMarkets_coalition.m`
- Helper: `compute_coalition_vote.m`
- Runner: `run_political_coalition_extension.m`
- Equilibrium condition: `distance = stats.weighted_vote^2`
- Output file: `SS_coalition_iter.mat`

## Files in this workspace

- `implementation_plan.md`: concrete refactor map from published baseline to extension code
- `run_re_no_politics_extension.m`: entry point for the no-politics extension
- `solve_ss_no_politics.m`: copied steady-state solver with housing clearing replacing voting
- `ClearMarkets_no_politics.m`: function driver for the no-politics price grid
- `political_coalition_extension.md`: extension note for making NIMBY politics stronger
- `compute_coalition_vote.m`: coalition-weighted replacement for the equal-weight vote aggregator
- `solve_ss_coalition.m`: copied steady-state solver with coalition-weighted vote aggregation
- `ClearMarkets_coalition.m`: function driver for the coalition price grid
- `run_political_coalition_extension.m`: entry point for political-side extension work

## How to run

From MATLAB:

- `run_re_no_politics_extension`
- `run_political_coalition_extension`

## Guardrails

- Do not edit the published baseline files until the extension interface is stable.
- When a genuine upstream bug is found in baseline code, log it in `../../UPSTREAM_FIX_LOG.md` separately from extension work.
