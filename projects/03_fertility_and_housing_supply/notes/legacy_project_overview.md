# Project Overview - 03_Fertility_and_Housing_Supply

Date: 2026-02-25

## Objective
Estimate whether housing-supply constraints causally affect fertility timing and completed fertility, and quantify the channels through housing costs, crowding, and access to family-sized units.

## Current contribution focus
- Bridge two empirical blocks in one paper narrative:
  - supply constraints/policy shocks -> prices and unit composition
  - prices/unit composition -> fertility outcomes
- Keep the political-economy NIMBY mechanism as upstream structure and add fertility as an endogenous downstream margin.

## Working empirical direction
Primary design track:
- Middle-housing reform event-study/DiD with treatment-intensity extension.

High-upside design track:
- NIMBY political turnover design (close elections -> supply -> fertility).

Core outcomes:
- Birth rates by age group
- First-birth timing
- Parity progression / completed fertility proxies

## Model direction
- Baseline utility keeps CRRA-Cobb-Douglas housing-consumption core.
- Fertility enters through:
  - children-at-home utility term
  - crowding-adjusted effective housing services
- Demography becomes endogenous through fertility-driven cohort transitions.

## Practical priorities
1. Lock baseline treatment and outcome family for the first specification.
2. Build one clean baseline panel and first-stage diagnostics.
3. Keep model implementation numerically stable with damping and share normalization.

## Notes on legacy detail
Detailed pre-consolidation notes (including .tex writeups and experiments) are archived under:
- `_playground/backups/2026-02-25_notes_flattening/03_fertility_and_housing_supply/Notes_old`


