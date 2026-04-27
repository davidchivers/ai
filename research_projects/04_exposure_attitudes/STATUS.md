# Project status

## Current status

Stage: Active data/code audit and project intake.

Organizer: Dave

Known collaborators and contributors from Dropbox notes:

- Eren Arbatli: PI / lead on Dropbox project
- Diego: collaborator
- Abdul: RA work folder present
- Daniel: RA/collaborator for literature search
- Tommy: RA on newer exposure-segregation pipeline
- Dave: joining project and setting up Git coordination in `research_projects/04_exposure_attitudes`

This project studies the effect of experienced or exposure segregation on social capital and attitudes. It already has substantial Stata, Python, and LaTeX code in Dropbox, plus a large `data/` tree that should not be read by Codex or committed to Git.

## Decisions

| Date | Decision | Reason | Owner |
|---|---|---|---|
| 2026-04-27 | Create `research_projects/04_exposure_attitudes` as the shared AI repo project folder. | User clarified that collaborators already have access to the `ai` repo and asked to put the project in `research_projects` as project 04. | Dave / Codex |
| 2026-04-27 | Treat Dropbox `data/` as restricted and do not open data files. | Project docs flag `data/Dewey_raw/` and `data/Dewey_processed/` as restricted; repo policy blocks raw data in AI context. | Dave / Codex |
| 2026-04-27 | Use this folder as a coordination layer, not as a Dropbox mirror. | Dropbox contains data, generated outputs, logs, and working code; the AI repo should keep clean Markdown coordination and safe code notes. | Dave / Codex |
| 2026-04-27 | Frame the project as two arms: POI/public-space mixing and downstream outcomes. | User clarified that one arm documents which places are inclusive and the second links exposure to outcomes such as social capital and attitudes. | Dave / Codex |
| 2026-04-27 | Stantcheva results are most promising for ages-10-19 exposure segregation. | Aggregate workbook shows strongest associations for pro-redistribution and donation outcomes. | Dave / Codex |
| 2026-04-27 | Treat land-unavailability variability as the candidate first-stage / IV spine, not as a settled causal design. | User clarified the Saiz-style mechanism: geography-driven land constraints generate local SES and amenity heterogeneity, which may lower exposure segregation. Exclusion remains the central challenge. | Dave / Codex |

## Data access

- Dropbox source folder: `C:\Users\Dave_\Dropbox\exposure_attitudes`
- Data folder present in Dropbox: yes
- Data opened by Codex: no
- Data-like files opened by Codex: no
- Dewey raw/processed folders present: yes, by folder metadata only
- Recommendation: remove or relocate restricted data from shared Dropbox only after explicit confirmation and a precise deletion plan

## Next 3 tasks

1. Locate and summarize the existing VARLU / land-unavailability first-stage outputs, especially the sign after population controls.
2. Write the exclusion-restriction checklist: residential segregation, prices, density, amenity quality, local public goods, and geography channels.
3. Decide whether the first outcome paper should be anchored on Chetty social capital, volunteering/donations, or Stantcheva attitudes.

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

## Session log

- 2026-04-27: Created project 04 intake files in the shared AI repo from safe Dropbox documents and metadata. Did not open raw data.
- 2026-04-27: Added a working identification note on land-unavailability variability, exposure segregation, and IV caveats.
