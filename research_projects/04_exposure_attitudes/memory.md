# Project memory

## Stable facts

- Project folder: `research_projects/04_exposure_attitudes`
- Active AI repo branch: `research_projects/04_exposure_attitudes`
- Dropbox source: `C:\Users\Dave_\Dropbox\exposure_attitudes`
- Dropbox draft folder: `C:\Users\Dave_\Dropbox\exposure_attitudes\Draft`
- Current compiled draft PDF: `C:\Users\Dave_\Dropbox\exposure_attitudes\Draft\exposure_segregation_social_capital.pdf`
- Latest draft revision note: title page now uses Cemal Eren Arbatli, Diego Marino Fages, and David Chivers with Durham economics affiliation; abstract and introduction are written in the NIMBY-style mechanism-first voice; results section now includes generated summary statistics, standardized first-stage, compact preferred county outcomes, Stantcheva adolescent-exposure results, first-stage figures, and full generated regression appendices.
- Latest Oracle workflow note: `C:\Users\Dave_\Dropbox\exposure_attitudes\Draft\notes\oracle_revision_workflow.md`
- Source folder name: `exposure_attitudes`
- Main topic: exposure segregation, public-space mixing, social capital, and attitudes
- Primary languages in Dropbox code: Stata, Python, R, LaTeX
- Raw data policy: do not read, copy, or commit Dropbox `data/`

## Orientation files

Fastest files for future Codex sessions to read:

1. `README.md`
2. `STATUS.md`
3. `notes/01_project_overview.md`
4. `notes/02_folder_and_code_map.md`
5. `notes/03_data_policy_and_dropbox_audit.md`
6. `notes/04_two_arm_design_and_measurement_issues.md`
7. `notes/05_stantcheva_regression_summary.md`
8. `notes/06_land_unavailability_identification.md`
9. `docs/hamilton_workflow.md` if working on Hamilton/HPC jobs
10. Dropbox `Draft/notes/` for paper-kickoff notes, literature map, data inventory, and results audit

Dropbox source files that were useful:

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
- `code/paper_exposure_segregation_social_capital_draft.tex`

## Conventions

- Treat this repo folder as the coordination and clean-Git layer.
- Do not mirror Dropbox raw data.
- Do not open files under Dropbox `data/` unless explicitly permitted and policy is updated.
- Log Codex work in `workstreams/codex.md`.
- Use `STATUS.md` for the canonical project state.
- Use lowercase underscore names for Hamilton paths, job names, scripts, logs, and outputs.
- Put future Hamilton scripts under `code/hpc/` only when the first script is added.
- Keep Hamilton logs and outputs in ignored local folders such as `logs/hpc/`, `outputs/hpc/`, `scratch/`, or `/nobackup/<username>/exposure_attitudes/`.

## Decisions

| Date | Decision | Reason | Owner |
|---|---|---|---|
| 2026-04-27 | Use `research_projects/04_exposure_attitudes` as the AI repo project folder. | User clarified that Eren and Diego already have access to the shared `ai` repo and asked to put the project in `research_projects` as project 04. | Dave / Codex |
| 2026-04-27 | Do not delete Dropbox data automatically. | Dropbox deletion is destructive and the folder contains many data sources, not a single clearly identified file. | Codex |
| 2026-04-27 | Treat POI/public-space inclusivity as a separate first arm from the outcome regressions. | User clarified the project structure and measurement motivation. | Dave / Codex |
| 2026-04-27 | Record land-unavailability variability as the main candidate identification channel. | User clarified the Saiz-style supply-constraint mechanism and the first-stage intuition. | Dave / Codex |
| 2026-04-27 | Add a Hamilton workflow guide. | Project may need large mobility-data processing and collaborators need shared naming and Slurm conventions. | Dave / Codex |
| 2026-04-27 | Start the paper in Dropbox `Draft/`. | User wants Aaron/Eren, Diego, and Dave to begin a shared LaTeX/PDF paper draft from existing project evidence. | Dave / Codex |

## Open questions

- Which exact Dropbox data file or folder should be deleted, if any?
- Should the project later be renamed `04_exposure_segregation_social_capital` for paper clarity, or keep the Dropbox-aligned `04_exposure_attitudes`?
- Which empirical strand is Dave joining first: social-capital paper, Stantcheva extension, or new CBG/POI exposure measures?
- Which exact Chandler Lutz/Luz source should be cited for the updated land-unavailability measure?
- Which POI/public-space category aggregation should become the first descriptive table?
- Should the Stantcheva attitude regressions be turned into a formal paper table or kept as a complementary appendix until identification is clearer?
- Oracle recommendation: prioritize POI-category/public-space evidence first, then exposure-provenance documentation, exposure-versus-residential distinctiveness, standardized county associations, IV diagnostics, and Stantcheva timing plots.
