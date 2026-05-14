# Joint Supply-Wedge Branch

This is a separate solver branch. It should not be confused with the older
price-path update family.

## Core idea

Use a political/supply object as the outer unknown:

- outer unknown: a wedge path `z_t`
- interpretation: `z_t` scales effective housing supply through `Hbar_t`
- inner solve: clear the housing side conditional on `z_t`
- outer residual: evaluate the political vote residual on the resulting path

So the branch is:

`z_t -> housing-clearing price path p_t(z) -> political residual V_t -> update z_t`

not:

`guess p_t -> perturb p_t directly to kill votes`

## Why this exists

The full-horizon failures suggest the old outer variable may be wrong.
Prices are trying to do two jobs at once:

- clear housing
- absorb the political residual

This branch instead lets prices clear conditional on a political/supply
instrument path.

## Implementation

- Shared hook:
  `extensions/re_no_politics/solve_transition_re_no_politics.m`
  now accepts `params.supply_wedge_path` / `params.supply_hbar_path`
  and converts them into a time path for effective `Hbar_t`.
- Main runner:
  `run_original_5yr_transition_joint_supply_wedge_continuation.m`
- Local wrapper:
  `run_original_5yr_transition_joint_supply_wedge_continuation.ps1`
- Hamilton packet:
  `submit_original_5yr_hamilton_joint_supply_wedge_packet.ps1`

## What "both ways" means here

The packet is designed to compare:

- full demographic path: `historical_1950`
- old/young proxy path: `historical_1950_two_group`

under the same joint-supply-wedge architecture.

## Continuation schedule

Default ladder:

- `k = 2, 3, 4, 5, 6, 8, 10, 12, 14`

Each solved horizon seeds the next one with:

- the final price path
- the final wedge path

## Current limitation

This is still a reduced outer solve:

- the wedge path is represented on a low-dimensional block basis
- the Jacobian is finite-difference in that reduced space

So it is closer to a true joint solve than the old price-mask family, but it
is not yet a fully stacked Newton solve over every period/state object.
