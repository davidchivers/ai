# Contribution and ID Strategy (Draft)

Date: 2026-02-23
Project: 03_Fertility_and_Housing_Supply

## Core contribution statement (working)
Estimate whether housing-supply constraints causally reduce fertility (timing and completed fertility), and quantify how much of this channel operates through housing costs, crowding, and delayed household formation.

## Baseline empirical design (working)
- Unit: region-by-year (to be finalized).
- Treatment: plausibly exogenous variation in housing-supply constraints / effective housing cost pressure.
- Outcomes: birth rates, age-specific fertility, first-birth timing, and parity progression.

## Identification notes
- Candidate strategies:
  - Supply-constraint variation with panel fixed effects.
  - Policy or planning-rule shocks with event-study structure.
  - IV-style designs using pre-determined geography/regulation interactions.
- Main threats:
  - Differential demand trends and migration sorting.
  - Endogenous local policy responses.
  - Composition effects by age/education.

## Decisions needed
1. Confirm primary treatment variable and preferred source.
2. Confirm main outcome family for baseline specification.
3. Confirm preferred first design (DiD/event study vs IV-first).

## Immediate actions
- Add 5-10 high-priority direct fertility papers to `Literature/` and update synthesis.
- Draft baseline estimating equation in this file.
