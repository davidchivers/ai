# Household-block fertility extension report

- Generated: 2026-03-13 15:26:35
- This is the first project-03 MATLAB extension that uses the upstream household VFI structure rather than the representative-agent aggregate prototype.
- External MATLAB assets loaded from `D:\research_data\zac_and_david` with fallback path support.

## Model design

- Base solver style: project-02 household VFI with age-income transition matrices.
- Added state: dependent children at home (`0`, `1`, `2`).
- Added choice at fertile ages (`25`, `30`, `35`, `40`): discrete birth decision.
- Housing crowding channel: effective housing services scaled by `(1 + lambda_crowd * children)^(-psi_crowd)`.
- Birth choice is smoothed with a logit approximation to avoid all-or-nothing corner solutions in the first-pass calibration.
- Price perturbation vote object retained from the NIMBY code so we can see how fertility changes the voting margin.

### Parameters

- `birth_utility = 0.240`
- `child_utility = 0.090`
- `birth_cost = 0.050`
- `birth_logit_scale = 0.080`
- `lambda_crowd = 0.350`
- `psi_crowd = 0.600`
- Grids: `I=20`, `J=8`, child states = `3`

## Summary table

| price | total_birth_mass | total_vote_support | rent_share_avg | birth_rate_age25_40 |
| --- | ---: | ---: | ---: | ---: |
| 0.90 | 1.318310 | 0.460583 | 0.120988 | 0.318263 |
| 1.00 | 1.318310 | 0.536920 | 0.249086 | 0.318263 |
| 1.10 | 1.318310 | 0.317578 | 0.186667 | 0.318263 |

## Readout

- The key object is how the household birth decision and vote support move as the exogenous house-price level rises.
- This is not yet a full general-equilibrium fertility-NIMBY solver, but it is the first proper household-block step toward one.
- The next modelling step is to endogenize the price object instead of evaluating the household block on a small price grid.

## Files

- `household_fertility_extension_summary.csv`
- `household_fertility_birth_rate_by_age.csv`
- `household_fertility_vote_by_child_state.csv`
