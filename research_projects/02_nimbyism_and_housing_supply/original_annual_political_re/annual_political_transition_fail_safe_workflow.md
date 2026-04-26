# Annual political transition fail-safe workflow

## Purpose

Run the first local annual transition smoke on this machine without launching a long or
unbounded MATLAB job.

This is the next step after the saved-grid map smoke. The saved-grid smoke showed that a
moderate political pass-through can reduce vote residuals. This runner checks whether the
same idea survives when the annual household distribution is moved forward period by
period using the annual `Mod_IRF` code.

## What It Does

For each candidate `(rho, phi, gamma)`:

1. Load the annual calibrated model from `Mod_IRF`.
2. Solve the baseline steady state and target vote at the year-2000 age vector.
3. For each annual period:
   - use the next annual demographic age vector
   - solve household policy at the candidate price
   - move the distribution forward with `solve_dyndist`
   - compute the vote residual
   - update political pressure and the permit/supply restriction
4. Save per-period paths and a candidate summary.

The price rule is:

```text
pressure_t    = tanh(vote_residual_t / vote_scale)
restriction_t = rho * restriction_{t-1} + phi * pressure_t
price_t       = reference_price * exp(gamma * restriction_t)
```

This is still a smoke, not the final structural transition solver. It tests whether the
annual dynamic distribution breaks the saved-grid pass-through result.

## Fail-Safe Rules

- Run `T = 4` first.
- Do not climb unless `T = 4` has at least one `usable` or `survivor` candidate.
- Stop if all candidates fail.
- Write `latest_status.json` after every candidate.
- Store stdout/stderr logs under `truth/annual_political_transition_fail_safe/logs/`.
- Do not use Hamilton.
- Do not run `T = 80`.

## Launch

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\start_annual_political_transition_fail_safe.ps1
```
