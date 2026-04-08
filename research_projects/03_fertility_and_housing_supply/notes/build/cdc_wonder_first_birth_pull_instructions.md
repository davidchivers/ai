# CDC WONDER first-birth pull instructions

Date: 2026-03-09

## Goal

Create the first modern fertility input for project 03, focused on first-birth timing.

## Recommended first pull

Use CDC WONDER natality summaries and export births grouped by:

1. geography of mother's residence
2. year
3. mother's age group

Apply a filter for first births only:

1. live birth order / birth order = first birth

Measure:

1. births

## Preferred geography order

1. county-year if cells are usable
2. state-year if county cells are too sparse or if county export constraints bind

## Official CDC WONDER constraints to keep in mind

Based on the current CDC WONDER natality documentation:

1. County of mother's residence is available in the natality database for 2007-2024.
2. County identifiers are only shown for counties with population at or above 100,000;
   smaller counties are grouped into `Unidentified Counties` within state.
3. Sub-national counts from 1 to 9 births are suppressed.
4. Live birth order is available, so a first-birth filter is feasible in principle.

Implication for the first implementation:

1. County-year can work for large counties, but it will not produce a full national county panel.
2. If the county extract is too sparse for the housing-policy design, move to state-year for
   the first unrestricted pass rather than forcing a weak county panel.

## Direct pull command

From the project root:

```powershell
python code/12_pull_cdc_wonder_first_births.py
```

This writes:

1. `data/raw/cdc_wonder_first_births_export.csv`
2. `notes/build/cdc_wonder_first_birth_pull_log.md`

The current script uses the official CDC WONDER `D66` natality dataset (`2007-2024`) and
pulls county-year results in year-sized chunks to stay under export limits.

## Import command

From the project root:

```powershell
python code/11_import_cdc_wonder_first_births.py
```

This writes:

1. `data/raw/cdc_fertility_county_year.csv`
2. `notes/build/us_fertility_ingest_log.md`

## Manual fallback

If the automated pull fails, save a manual CDC WONDER export as:

- `data/raw/cdc_wonder_first_births_export.csv`

## Output variables created by the importer

The importer creates timing-focused fertility variables including:

1. `first_births_total`
2. `mean_age_first_birth`
3. `median_age_first_birth`
4. `share_first_birth_15_19`
5. `share_first_birth_20_24`
6. `share_first_birth_25_29`
7. `share_first_birth_30_34`
8. `share_first_birth_35_44`
9. `share_first_birth_30_plus`

## Current limitation

1. The importer does not create a modern `gfr_15_44` by itself.
2. `first_birth_rate_15_44` is intended to be derived after the fertility file is merged
   with female population denominators.
