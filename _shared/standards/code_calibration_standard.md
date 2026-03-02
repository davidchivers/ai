# Code and Calibration Standard

Use these rules for `code/` and `calibration/` folders in research projects.

## Code folder

- Keep reproducible scripts in execution order using numbered prefixes (for example `01_`, `02_`, `03_`).
- Keep shared helpers in `code/lib/`.
- Write a short `code/README.md` with run order, inputs, and outputs.
- Do not commit generated artifacts as source files.

## Calibration folder

- Keep model solver source code in `calibration/`.
- Keep runnable workspace assets in a dedicated subfolder (for example `calibration/ai_calibration/`).
- Use explicit input/output folders for runs:
  - `runtime/data/input/`
  - `runtime/data/output/`
- Keep legacy or exploratory runs in `calibration/old/`.
- Add a `calibration/README.md` that documents required external inputs and run commands.

## Documentation rule

- Any path, parameter, or assumption that differs between paper text and code must be logged in project `STATUS.md`.
