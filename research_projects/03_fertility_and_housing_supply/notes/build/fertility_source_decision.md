# Fertility source decision

Date: 2026-03-09

## Decision

Use a modern natality-based fertility source as the main empirical path.

Do not use the legacy historical metro `gfr_15_44` series as the baseline dataset for the
paper. Keep it only as an archival reduced-form sign-check sample.

## Why

1. The current processed panel is not aligned across outcomes and controls:
   - `gfr_15_44` currently runs from 1940--1995 at metro-year level.
   - `female_pop_15_44` currently runs from 2010--2018 at county-year level.
   - overlap is zero.
2. The project mechanism is mainly about delayed family formation.
3. A modern natality build can target first-birth timing outcomes and can also generate a
   modern fallback fertility-rate panel if needed.

## Local data audit

The legacy Dropbox fertility files used in the old NIMBY workflow do not support a clean
first-birth timing design:

1. `birthrates_updated.dta`
   - columns: `statefips`, `year`, `birthrate`
2. `birthrates13.dta`
   - columns: `statefips`, `year`, `birthrate`
3. `merged_birthrates_migrationweights.dta`
   - columns include `metarea`, `year`, `weightedbirthrate`, `rent`, `own`, `age`, `unemp`
   - no maternal-age-at-birth variable
   - no birth-order/parity variable
4. `3 birthrates.do`
   - builds weighted metro birth rates from state birth rates and metro weights
   - this is an old aggregate birth-rate workflow, not a natality microdata workflow

Conclusion:

1. The legacy files are useful for historical sign checks.
2. They are not suitable for the intended modern nativity-adjusted panel.
3. They are not suitable for a first-birth timing design.

## Working source path

Main source family:

1. CDC/NCHS natality public-use data and official natality tabulations.
2. Practical first route: CDC WONDER natality summary extracts.

Fields needed:

1. maternal age at birth
2. live birth order or parity to identify first births
3. geography that maps to county, `cbsa`, or state
4. year, and possibly month if a higher-frequency timing design is viable

Important implementation nuance:

1. County-level microdata are restricted in the post-2005 vital statistics files.
2. For a non-restricted first pass, the practical route is likely county or state summary
   extracts from CDC WONDER natality rather than raw county microdata.
3. If the summary extracts are too coarse for the preferred timing outcomes, then either:
   - move to state-month/state-year as the first implementation, or
   - consider restricted-use access later
4. In CDC WONDER, county of residence is available for 2007-2024 but only counties with
   population at or above 100,000 are individually identified; smaller counties are grouped.
5. CDC WONDER also suppresses sub-national counts from 1 to 9, so sparse first-birth county
   cells will disappear even among identified counties.

## Outcome priority under this decision

1. Preferred outcome family:
   - first-birth timing measures
   - age-bin first-birth shares
   - first-birth rates where denominators can be built consistently
2. Supporting outcome:
   - `gfr_15_44` from a modern overlapping series
3. Historical fallback sample:
   - use the old metro `gfr_15_44` only for provisional reduced-form sign checks

## Immediate implementation implication

Do not spend more time extending the current historical metro `gfr_15_44` sample into the
main design. The next build step should define:

1. natality source access path
2. years
3. geography
4. first-birth identification rule
5. whether the first implementation is county-year, `cbsa`-year, state-year, or state-month
