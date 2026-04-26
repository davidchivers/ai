# Annual political broad-grid fail-safe workflow

## Purpose

Move from the three-candidate ladder to a broader pass-through search without wasting
local time on obviously bad annual dynamic solves.

## Stages

1. Run a cheap saved-grid map over:
   - `phi = 0.03, 0.06, 0.10, 0.15`
   - `gamma = 0.50, 1.00, 1.50`
   - `rho = 0, 0.50, 0.85`
   - `vote_scale = 0.015, 0.020, 0.030`
2. Select the best no-grid-hit candidates from each `vote_scale`.
3. Run the expensive annual dynamic transition fail-safe only on the selected candidates.

## Stop Logic

- Stop if the map stage finds no usable/survivor candidates.
- Run dynamic candidates sequentially by `vote_scale`, not in parallel.
- Keep the dynamic horizon bounded by the requested `T` schedule.
- Write status after each stage.

## Launch

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\start_annual_political_broad_grid_fail_safe.ps1
```
