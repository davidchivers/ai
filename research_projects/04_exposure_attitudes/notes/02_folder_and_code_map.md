# Folder and code map

## Dropbox source

```text
C:\Users\Dave_\Dropbox\exposure_attitudes
```

## Top-level Dropbox folders

- `.git`: existing Git metadata inside the Dropbox folder
- `Abdul`: RA work folder
- `admin`: admin files
- `code`: Stata, Python, R, LaTeX, instructions, logs, and generated outputs
- `data`: raw and processed data, restricted for Codex
- `output`: generated outputs
- `papers`: literature and reference materials
- `tmp`: temporary files

## Top-level orientation files

- `PROJECT.md`: high-level research question, data, identification, team, status
- `TASKS.md`: active tasks and completed tasks
- `context.md`: extensive project map and recommended read order
- `email_to_tommy_new_measures.md`: requested CBG exposure-measure additions
- `Diary.docx`: chronological idea/task log
- `Empirical Patterns from Public Space.docx`: results and social-capital framing
- `IDEA LOG FOR PUBLIC SPACE PROJECT.docx`: broader public-space and exposure-segregation ideas
- `To do list for the project.docx`: early task plan for literature and SafeGraph/POI work

## Code entry points

### County build

- `code/con_master_county.do`
- `code/con_exposegr.do`
- `code/con_socialcapital.do`
- `code/con_oppor_insights.do`
- `code/con_residsegr.do`
- `code/con_varlu_county.do`
- `code/con_varlu_county_national.do`

### MSA build

- `code/con_master_msa.do`
- `code/con_msa_covariates.do`
- `code/con_msa_lu_raw.do`
- `code/con_varlu_msa.do`
- `code/con_varlu_msa_national.do`

### Regression scripts

- `code/regressions/reg_expseg_soccap_cnty.do`
- `code/regressions/reg_expseg_smo_varlu_firststage_cnty.do`
- `code/regressions/reg_expseg_smo_varlu_firststage_msa.do`
- `code/regressions/reg_varlu_firststage_sq_only.do`
- `code/regressions/tbl_fig_draft_v1.do`

### Stantcheva extension

- `code/con_stantcheva_etal2026_expseg.do`
- `code/con_stantcheva_etal2026_expseg_regressions.do`
- `code/stantcheva_etal2026_expseg_instructions.md`
- `code/stantcheva_etal2026_expseg_regressions_instructions.md`

### Other code areas

- `code/data_processing`: POI / Google / Advan workflows, including older scripts
- `code/scripts`: helper scripts for ZeroSum survey sheets and codebooks
- `code/output`: generated tables, figures, and workbooks
- `code/regressions/log`: generated diagnostic figures and logs

## Important hygiene issue

The Dropbox `code/` folder contains source scripts, logs, generated outputs, compiled LaTeX artifacts, and spreadsheets together. Before copying anything into Git, separate:

- production code
- scratch or exploratory scripts
- generated outputs
- logs
- data-like spreadsheets
- paper source
- compiled paper outputs

This AI repo project folder should not copy the Dropbox tree directly.
