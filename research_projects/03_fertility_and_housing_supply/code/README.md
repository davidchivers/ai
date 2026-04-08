# Code

Current scripts:

- `01_run_experiments_matlab.m`
- `run_experiments_matlab_main.m`
- `04_build_us_panel_scaffold.ps1`
- `05_build_us_panel_from_sources.ps1`
- `10_exploratory_empirical_regressions.py`
- `11_import_cdc_wonder_first_births.py`
- `12_pull_cdc_wonder_first_births.py`
- `fertility_extension_experiment.py`
- `sync_exports_and_literature_to_zac_david.sh`
- `sync_literature_to_zac_david.sh`

US panel build note:

- `05_build_us_panel_from_sources.ps1` accepts canonical project-03 IDs and NIMBY-style aliases (`STCOU`, `CBSA`, `statefips`, `met2013`, `YEAR`).
- `12_pull_cdc_wonder_first_births.py` pulls the `D66` CDC WONDER natality extract directly in year-sized chunks and writes `data/raw/cdc_wonder_first_births_export.csv`.
- `11_import_cdc_wonder_first_births.py` turns that CDC WONDER export into the canonical fertility raw file used by the panel builder.
- `10_exploratory_empirical_regressions.py` now builds an exploratory state-year panel from the raw inputs because the current fertility source is county-year while the legacy housing source is metro-year.

Standards:

- Execution-order naming should use numeric prefixes (`01_`, `02_`, ...) as this folder grows.
- Put shared helpers in `code/lib/` when needed.
- Track assumptions and code-paper mismatches in `STATUS.md`.
