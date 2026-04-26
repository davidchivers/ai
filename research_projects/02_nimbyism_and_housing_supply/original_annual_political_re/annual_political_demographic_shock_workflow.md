# Annual political demographic-shock workflow

This workflow tests whether the smoothed annual political transition survives a real
demographic disturbance.

## What is already annual

The verified annual source has:

```text
param.modperiod = 1
param.J = 56
size(age_share) = 56 x 151
```

So the serious annual lane is already using one-year age cells, not the old 5-year
diagnostic bins.

## Shock design

The runner now supports `DemographicScenario`:

- `source_path`: use the annual source age-share path as loaded,
- `flat_entrant`: hold age-25 entrant mass flat and age cohorts forward mechanically,
- `baby_boom`: temporary increase in age-25 entrants,
- `secular_decline`: gradual decline in age-25 entrants.

For non-source scenarios, the path starts from the same baseline age distribution. Age-25
entrants are shocked, older cohorts age forward with a simple annual survival profile,
and each year's age vector is normalized before voting.

This is a solvability and mechanism test, not yet a final demographic calibration.

## Local smoke

Run a short baby-boom smoke:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\run_annual_political_transition_fail_safe.ps1 -RunTag annual_transition_T4_baby_boom_smoke -TSchedule 4 -PeriodIter 2 -VoteScale 0.020 -PressureMode smooth -DemographicScenario baby_boom -DemographicShockAmplitude 0.25 -CandidatesMat "[0 0.105 1.00]"
```

If that runs cleanly, test `T = 12` locally or submit the full `T = 80` Hamilton stages.

Current local smokes:

- `annual_transition_T4_baby_boom_smoke_20260426`: usable, max vote residual `0.00505`,
  max log price move `0.02302`.
- `annual_transition_T4_secular_decline_smoke_20260426`: usable, max vote residual
  `0.00517`, max log price move `0.02651`.

## Hamilton stages

The thin Hamilton submitter now supports:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Boom -PeriodIter 4
```

and:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Decline -PeriodIter 4
```

Both use the one-parameter eta grid from the benchmark refinement.

## Read

- If the baby-boom and decline shocks survive with residuals in the same neighborhood as
  the benchmark, the transition is robust enough to build paper figures around.
- If one shock fails badly, inspect whether the issue is political pressure saturation,
  too much price movement, or a demographic-age-weight effect.
- If the shock only works with very high eta, the benchmark may be underpowered for large
  demographic changes.
