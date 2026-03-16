# RE no-politics extension workspace

This subfolder is the implementation workspace for the no-politics rational-expectations extension described in `../re_no_politics_experiment.md`.

## Current status

- Published baseline code remains untouched.
- Extension A now has a copied steady-state solver, grid-search driver, and runnable entry point.
- Extension B now has a copied steady-state solver, coalition vote helper, grid-search driver, and runnable entry point.
- Both extension drivers are MATLAB functions so they can be called safely from the entry-point wrappers.
- The current no-politics object is a steady-state benchmark only. It is not the main experiment.

## What this is and is not

- This workspace currently contains a useful side benchmark: a no-politics steady-state object with housing-clearing prices.
- It is not the main rational-expectations experiment the project now wants.
- The main target is a transition-path forecast with future demographic changes and model-consistent house-price expectations, while abstracting from coalition formation.
- In other words, the interesting object is not "new steady state under a different closure". It is "forecasting under RE house prices along a demographic transition path".

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

## Implemented side benchmarks

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

## Main experiment still to build

- Keep the baseline transition structure rather than collapsing to a new steady state.
- Feed in an exogenous demographic path.
- Replace the ad hoc house-price expectation rule with a guessed future price path.
- Solve household decisions using that full expected path.
- Simulate the cross-sectional distribution forward.
- Update the price path until it is consistent with the model's own implied future prices.
- Do this without coalition voting if the no-coalition political assumption remains the target simplification.

## Files in this workspace

- `implementation_plan.md`: concrete refactor map from published baseline to extension code
- `run_re_no_politics_extension.m`: entry point for the no-politics extension
- `solve_ss_no_politics.m`: copied steady-state solver with housing clearing replacing voting
- `ClearMarkets_no_politics.m`: function driver for the no-politics price grid
- `run_demographic_forecast_re_no_politics.m`: entry point for the transition-path RE scaffold
- `build_demographic_path_from_age_state_csv.m`: maps `code/data/age state.csv` into model age bins
- `solve_transition_re_no_politics.m`: transition-path solver interface and diagnostics scaffold
- `update_price_path_re_no_politics.m`: damped price-path update helper for RE iteration
- `political_coalition_extension.md`: extension note for making NIMBY politics stronger
- `compute_coalition_vote.m`: coalition-weighted replacement for the equal-weight vote aggregator
- `solve_ss_coalition.m`: copied steady-state solver with coalition-weighted vote aggregation
- `ClearMarkets_coalition.m`: function driver for the coalition price grid
- `run_political_coalition_extension.m`: entry point for political-side extension work

## How to run

From MATLAB:

- `run_re_no_politics_extension`
- `run_political_coalition_extension`
- `run_demographic_forecast_re_no_politics`

The transition runner now does a real first-pass backward-forward transition solve. It loads the transition matrix through the robust resolver, builds a demographic-path object from `code/data/age state.csv`, solves the household problem for a guessed finite price path, simulates the distribution forward, and returns an implied price path for the next RE update.

Verified on this machine: `run_demographic_forecast_re_no_politics` runs successfully and saves `transition_re_no_politics_results.mat`.
The transition supply curve is now auto-anchored to the baseline household demand scale at the initial reference price, so the default one-step RE update no longer mechanically collapses prices toward zero.
The runner now also saves period-by-period diagnostics for housing demand, supply, excess demand, and raw/smoothed log-price residuals.
The price updater now works in log prices and applies a regularized whole-path update rather than a purely local ad hoc smoother. This materially improves stability in multi-iteration tests.
The updater now also applies a targeted local correction to the worst residual periods, and the iteration log records which periods are driving the current error.
The current implementation is still not a finished quantitative result. Multi-iteration paths now stay numerically bounded and the bad periods are easier to diagnose, but some period residuals still spike sharply, so full RE convergence remains unresolved.

## Guardrails

- Do not edit the published baseline files until the extension interface is stable.
- When a genuine upstream bug is found in baseline code, log it in `../../UPSTREAM_FIX_LOG.md` separately from extension work.
