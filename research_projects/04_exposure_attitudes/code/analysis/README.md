# Analysis code

This folder is reserved for cleaned analysis scripts copied or rewritten from the Dropbox project.

Candidate source scripts from Dropbox include:

- `code/con_master_county.do`
- `code/con_master_msa.do`
- `code/con_stantcheva_etal2026_expseg.do`
- `code/con_stantcheva_etal2026_expseg_regressions.do`
- `code/regressions/tbl_fig_draft_v1.do`

Before copying any script, check:

- it does not contain secrets
- it does not write raw data into tracked paths
- it does not print raw rows into logs
- its paths are portable
- generated outputs remain ignored unless they are safe aggregate artifacts
