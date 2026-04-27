# Exposure attitudes

## Project summary

This is project 04 in the shared `ai` repository.

The project studies whether everyday exposure segregation, measured from mobility and point-of-interest data, affects social capital and related political or social attitudes in the United States.

The current Dropbox source folder is:

```text
C:\Users\Dave_\Dropbox\exposure_attitudes
```

This project folder is not a copy of the Dropbox project. It is the clean Git-facing coordination layer: project summary, workflow notes, code map, data restrictions, and status tracking. Raw or processed data should stay out of Git.

## Research question

How does exposure segregation, the degree to which people of different racial or socioeconomic groups encounter one another in daily life, affect social capital formation and attitudes in U.S. counties and metropolitan areas?

## Main idea

The project distinguishes residential segregation from experienced or exposure segregation. The core hypothesis is that segregation in day-to-day activity spaces weakens bridging social capital, civic participation, and economic connectedness. The project also explores whether exposure patterns help explain survey-based attitudes, especially zero-sum attitudes from Stantcheva et al. (2026).

## Main strands

1. County/MSA social-capital paper.
2. Survey-attitudes extension using Stantcheva et al. zero-sum attitudes.
3. Newer CBG and POI exposure-measure construction using mobility flows and public-space/venue data.

## Key source files read

These Dropbox files were read or inspected for orientation:

- `PROJECT.md`
- `TASKS.md`
- `context.md`
- `email_to_tommy_new_measures.md`
- `Diary.docx`
- `Empirical Patterns from Public Space.docx`
- `IDEA LOG FOR PUBLIC SPACE PROJECT.docx`
- `To do list for the project.docx`
- `code/stantcheva_etal2026_expseg_instructions.md`
- `code/stantcheva_etal2026_expseg_regressions_instructions.md`
- first part of `code/paper_exposure_segregation_social_capital_draft.tex`
- folder and filename metadata for code and data directories

The `data/` folder and data-like files were not opened.

## Data sources named in project documents

- SafeGraph / Advan mobility and POI data
- ACS
- Opportunity Insights / Chetty et al. social capital data
- Yelp / Outscraper / Google Maps review workflows
- PSID
- FHFA house prices
- HUD USPS ZIP crosswalk
- ZeroSum Survey / Stantcheva et al. (2026)
- Census boundary files
- residential segregation data
- land unavailability / VARLU measures

## Identification strategy

The current causal strategy uses land unavailability and local variability in land unavailability (`VARLU`) as instruments for residential or experienced segregation. The logic is that geography-driven supply constraints and within-area heterogeneity in land constraints shape sorting, amenities, and activity-space overlap. The empirical pipeline then estimates effects of experienced segregation on social capital outcomes, with controls for residential segregation, population, and other county/MSA covariates.

The strongest current version of the logic is local rather than aggregate: geographic constraints can make nearby areas respond differently to demand shocks, producing very local SES and amenity heterogeneity. That heterogeneity may create more cross-neighborhood use of amenities and therefore lower exposure segregation. This is promising as a first stage, but the exclusion restriction remains the central challenge because land-unavailability variability could also affect outcomes through prices, residential segregation, density, public goods, or amenity quality.

See `notes/06_land_unavailability_identification.md` for the working identification memo.

## Main code map

County/MSA build scripts:

- `code/con_master_county.do`
- `code/con_master_msa.do`
- `code/con_exposegr.do`
- `code/con_socialcapital.do`
- `code/con_oppor_insights.do`
- `code/con_residsegr.do`
- `code/con_varlu_county.do`
- `code/con_varlu_msa.do`
- `code/con_varlu_county_national.do`
- `code/con_varlu_msa_national.do`

Regression and table scripts:

- `code/regressions/reg_expseg_soccap_cnty.do`
- `code/regressions/reg_expseg_smo_varlu_firststage_cnty.do`
- `code/regressions/reg_expseg_smo_varlu_firststage_msa.do`
- `code/regressions/tbl_fig_draft_v1.do`

Stantcheva extension:

- `code/con_stantcheva_etal2026_expseg.do`
- `code/con_stantcheva_etal2026_expseg_regressions.do`
- `code/stantcheva_etal2026_expseg_instructions.md`
- `code/stantcheva_etal2026_expseg_regressions_instructions.md`

Newer POI / CBG exposure pipeline:

- Tommy handoff indicates run order:
  1. `pipeline_poi.py`
  2. `pipeline_msa.py`
  3. `pipeline_cbg.py`
- Those files appear to live under the Dropbox `data/Exposure_segregation/` area, which is treated here as data-side material and was not opened.

## Data restrictions

Do not copy raw or processed data into this Git repo.

Dropbox currently contains a large `data/` tree, including Dewey raw and processed folders. That data tree should be treated as restricted. If the team wants it removed from Dropbox, do that as a deliberate Dropbox-side cleanup after confirming exactly what to delete.

## Hamilton / HPC

If large processing is moved to Durham Hamilton, use the project guide in `docs/hamilton_workflow.md`. The short version is: use lowercase underscore names, keep raw and intermediate data outside Git, run intensive work through Slurm rather than on login nodes, and check live queue/storage status before major jobs.

## Current status

The project is active. Existing documents say:

- county and MSA master datasets exist
- the exposure-segregation construction pipeline exists
- IV first-stage work is underway and partly established
- draft table and figure generation exists
- the paper draft is incomplete and still has placeholders
- the Stantcheva extension has detailed build and regression specs
- newer POI/CBG exposure measures are under active design

Dropbox now contains a revised paper draft at `C:\Users\Dave_\Dropbox\exposure_attitudes\Draft\exposure_segregation_social_capital.pdf`. The current revision uses a standard Durham author block and includes the generated county summary table, standardized first-stage table, economic-connectedness table, volunteering table, and first-stage figures.

See `STATUS.md` for the live task list.
