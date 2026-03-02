# Code

Current scripts:

- `01_run_experiments_matlab.m`
- `run_experiments_matlab_main.m`
- `04_build_us_panel_scaffold.ps1`
- `05_build_us_panel_from_sources.ps1`
- `fertility_extension_experiment.py`
- `sync_exports_and_literature_to_zac_david.sh`
- `sync_literature_to_zac_david.sh`

US panel build note:

- `05_build_us_panel_from_sources.ps1` accepts canonical project-03 IDs and NIMBY-style aliases (`STCOU`, `CBSA`, `statefips`, `met2013`, `YEAR`).

Standards:

- Execution-order naming should use numeric prefixes (`01_`, `02_`, ...) as this folder grows.
- Put shared helpers in `code/lib/` when needed.
- Track assumptions and code-paper mismatches in `STATUS.md`.
