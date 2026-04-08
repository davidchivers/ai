# No-politics RE implementation plan

## Objective

Build a deterministic rational-expectations extension of the NIMBY model in two stages:

1. steady-state no-politics equilibrium
2. transition-path rational-expectations equilibrium under an exogenous demographic path

## Current interpretation

The stage-1 steady-state object has now been implemented and run, but it is only a side benchmark.

The main experiment is stage 2:

- forecast over future demographics,
- keep the model's transition structure,
- introduce rational expectations over the future house-price path,
- and abstract from coalition formation rather than replacing the transition problem with a new steady-state closure.

## Baseline file map

### Directly relevant

- `../../code/steadystate/SolveSS_iter.m`
- `../../code/steadystate/ClearMarkets.m`
- `../../code/steadystate/SolveSS_function.m`
- `../../code/steadystate/SolveSS_function_boom.m`
- `../../code/steadystate/SolveSS_iter_boom.m`

### Lower priority / reference only

- `../../code/steadystate/SolveSS.m`
- `../../code/steadystate/SolveSS_Loop.m`
- `../../code/steadystate/SolveSS_fixedrent.m`
- `../../code/steadystate/solve_steadystate.m`

## Why `SolveSS_iter.m` is the right base

`SolveSS_iter.m` is the cleanest starting point because it is already used as the market-clearing object in the grid search script and exposes the current equilibrium criterion through its returned `distance`.

The household problem, density propagation, and aggregation are all already inside that function. The main extension job is therefore to swap the equilibrium target, not to rebuild the full household side from scratch.

## Where the political logic enters

The political block is concentrated in the latter part of `SolveSS_iter.m`:

- `vote = sign(d_valuefunction_dp).*density_prev`
- `totalvote = totalvote + vote`
- `pref4(:,:,:,iage-1) = sign(d_valuefunction_dp)`
- `distance = sum(dens4.*pref4,'all')^2`
- `totalvote = sum(dens4.*pref4,'all')`

Interpretation:

- household preferences over prices are computed state by state
- those preferences are aggregated with density weights
- the solver targets zero net political pressure

For the extension, these objects become diagnostics at most, not equilibrium conditions.

## Stage 1: steady-state no-politics object

### Goal

Replace the political fixed point with a housing-market residual.

### Candidate equilibrium conditions

Pick one of these and keep the others for robustness:

1. fixed housing stock:
   `distance = (aggregate_owner_housing + aggregate_rental_housing - Hbar)^2`
2. elastic supply:
   `Hsupply = Hbar * (P / Pbar)^eta_s`
   `distance = (Hdemand - Hsupply)^2`
3. fixed rent rule with endogenous asset price:
   keep rent simple in the first pass only if it materially reduces coding complexity

### Status

Implemented as a benchmark only. This stage is not the main object of interest.

## Stage 2: deterministic RE transition path

### Goal

Given a path for demographics, solve for a price path consistent with household expectations and the model's own transition logic.

### Minimal algorithm

1. Guess a price path `P^(0)`.
2. Solve household decisions taking that path as given.
3. Aggregate housing demand period by period.
4. Compute implied market-clearing prices or residuals.
5. Update the guess with damping:
   `P^(n+1) = lambda * P_implied + (1-lambda) * P^(n)`
6. Iterate until both price changes and clearing residuals are small.

### Initial simplifications

- deterministic only
- finite horizon transition
- no coalition formation
- keep the political structure only to the extent needed for the baseline transition object
- hold rent rule fixed if needed for the first run

## Required refactor before real coding

To avoid editing a 500-line file repeatedly, extract three conceptual blocks from `SolveSS_iter.m` into extension copies:

1. parameter and grid setup
2. household solve and density propagation
3. terminal aggregation and equilibrium residual

The extension should own these copies under this folder once implementation starts.

## Suggested file sequence

1. `run_re_no_politics_extension.m`
2. `solve_ss_no_politics.m`
3. `solve_transition_re_no_politics.m`
4. `update_price_path_re_no_politics.m`
5. `run_demographic_forecast_re_no_politics.m`

The steady-state files now exist. A first transition scaffold now also exists for:

- the demographic-path input contract
- a real demographic path built from `code/data/age state.csv`
- the RE price-path update helper
- the transition runner entry point

The next work should implement the actual household transition and forward distribution logic inside `solve_transition_re_no_politics.m`.

## Success criteria for the main milestone

- household decisions can be solved given a full expected future price path
- the demographic path feeds through the transition code without breaking path resolution
- the guessed price path converges to the model-implied path
- the resulting forecast can be compared against the baseline random-walk-style expectation setup
