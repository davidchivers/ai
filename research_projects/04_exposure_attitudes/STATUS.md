# Project status

## Current status

Stage: First paper draft revision with Oracle-ranked next workflow.

Organizer: Dave

Known collaborators and contributors from Dropbox notes:

- Eren Arbatli: PI / lead on Dropbox project
- Diego: collaborator
- Abdul: RA work folder present
- Daniel: RA/collaborator for literature search
- Tommy: RA on newer exposure-segregation pipeline
- Dave: joining project and setting up Git coordination in `research_projects/04_exposure_attitudes`

This project studies the effect of experienced or exposure segregation on social capital and attitudes. It already has substantial Stata, Python, and LaTeX code in Dropbox, plus a large `data/` tree that should not be read by Codex or committed to Git.

The current Dropbox draft now has a corrected Durham economics author block, a revised academic front half, a compact preferred county-outcomes table, a Stantcheva adolescent-exposure table, the generated regression fragments in the appendix, and an Oracle-ranked revision workflow at `Draft/notes/oracle_revision_workflow.md`.

## Decisions

| Date | Decision | Reason | Owner |
|---|---|---|---|
| 2026-04-27 | Create `research_projects/04_exposure_attitudes` as the shared AI repo project folder. | User clarified that collaborators already have access to the `ai` repo and asked to put the project in `research_projects` as project 04. | Dave / Codex |
| 2026-04-27 | Treat Dropbox `data/` as restricted and do not open data files. | Project docs flag `data/Dewey_raw/` and `data/Dewey_processed/` as restricted; repo policy blocks raw data in AI context. | Dave / Codex |
| 2026-04-27 | Use this folder as a coordination layer, not as a Dropbox mirror. | Dropbox contains data, generated outputs, logs, and working code; the AI repo should keep clean Markdown coordination and safe code notes. | Dave / Codex |
| 2026-04-27 | Frame the project as two arms: POI/public-space mixing and downstream outcomes. | User clarified that one arm documents which places are inclusive and the second links exposure to outcomes such as social capital and attitudes. | Dave / Codex |
| 2026-04-27 | Stantcheva results are most promising for ages-10-19 exposure segregation. | Aggregate workbook shows strongest associations for pro-redistribution and donation outcomes. | Dave / Codex |
| 2026-04-27 | Treat land-unavailability variability as the candidate first-stage / IV spine, not as a settled causal design. | User clarified the Saiz-style mechanism: geography-driven land constraints generate local SES and amenity heterogeneity, which may lower exposure segregation. Exclusion remains the central challenge. | Dave / Codex |
| 2026-04-27 | Use `docs/hamilton_workflow.md` for Hamilton/HPC conventions. | Shared guidance is needed for naming, Slurm jobs, storage locations, and safe handling of large data outputs. | Dave / Codex |
| 2026-04-27 | Create the working paper draft in Dropbox `Draft/`. | User asked to begin a LaTeX/PDF draft from existing project ideas, literature, code, and aggregate outputs. | Dave / Codex |

## Data access

- Dropbox source folder: `C:\Users\Dave_\Dropbox\exposure_attitudes`
- Data folder present in Dropbox: yes
- Data opened by Codex: no
- Data-like files opened by Codex: no
- Dewey raw/processed folders present: yes, by folder metadata only
- Recommendation: remove or relocate restricted data from shared Dropbox only after explicit confirmation and a precise deletion plan

## Next 3 tasks

1. Build the missing public-space / POI-category mixing table and coefficient plot so the first empirical arm has a visible descriptive result.
2. Lock the exposure-measure provenance for `expo_segr_n23` and `expo_segr_smo_n23`, including timing window, smoothing method, geography, source, and interpretation.
3. Rebuild the county and Stantcheva evidence around standardized effects, residential-segregation controls, multiple-testing discipline, and IV diagnostics.

## Active branches

| Branch | Owner | Purpose | Status |
|---|---|---|---|
| `research_projects/04_exposure_attitudes` | Codex | Add project 04 summary and coordination files to the shared AI repo. | Initial setup |

## Open blockers

- Dropbox app connector was not authenticated during intake, so Codex used the local synced Dropbox folder.
- The Dropbox project itself has a `.git` folder with many added generated outputs and spreadsheets, but Git checks timed out because the folder is large and synced.
- The Dropbox `data/` folder is too large and sensitive for Codex inspection.
- The temporary separate `dewey_data` repo is superseded by this AI repo project folder.
- The exact Dropbox cleanup action is not confirmed. No deletion was performed.
- Several citations and source details remain to be verified before the paper can be treated as submission-grade.
- The POI-category/public-space table remains the main missing empirical object for the paper spine.
- The land-unavailability IV remains diagnostic rather than a settled causal design.

## Session log

- 2026-04-27: Created project 04 intake files in the shared AI repo from safe Dropbox documents and metadata. Did not open raw data.
- 2026-04-27: Added a working identification note on land-unavailability variability, exposure segregation, and IV caveats.
- 2026-04-27: Added Hamilton workflow guidance for naming conventions, storage, Slurm queues, and safe batch-job practice.
- 2026-04-27: Created Dropbox `Draft/` with LaTeX source, section files, notes, bibliography, and compiled `exposure_segregation_social_capital.pdf`. No raw data were opened or copied.
- 2026-04-27: Revised Dropbox paper draft to use a standard economics-paper author block, tighter academic voice, and inserted summary statistics, first-stage, economic-connectedness, volunteering, and first-stage figure outputs.
- 2026-04-28: Corrected the title-page affiliation to Department of Economics, added the full generated county outcome set to the appendix, created compact preferred county and Stantcheva tables, recompiled the PDF, and saved Oracle's ranked revision workflow in Dropbox `Draft/notes/oracle_revision_workflow.md`.
