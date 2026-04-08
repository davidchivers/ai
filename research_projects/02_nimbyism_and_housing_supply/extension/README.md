# Extension workspace

This folder holds exploratory extensions to the published NIMBY model that are intentionally separated from the canonical paper files and the original `code/steadystate/` scripts.

Current contents:

- `anticipated_demographics_re.md`: math note for a no-coalition, forward-looking voting benchmark
- `current_findings.md`: current interpretation of the toy benchmark and the structural next step
- `static_bloc_coordination.md`: math note for a within-period coalition/bloc extension
- `input/README.md`: expected structural `.mat` inputs
- `matlab/run_anticipated_demographics_re_toy.m`: runnable reduced-form aggregate prototype
- `matlab/run_anticipated_demographics_re_structural.m`: structural scaffold that can use endpoint outputs from the original MATLAB solver when they are available
- `matlab/export_structural_endpoints.m`: converts raw `SS_iter*.mat` files into lightweight endpoint files for the extension runner
- `matlab/run_extension_pipeline.m`: automatic extension pipeline
- `run_extension_pipeline.ps1`: PowerShell entrypoint for the automatic pipeline

Important constraint:

- The original project excludes large MATLAB inputs such as `nl_zbl.mat` and generated objects such as `TransitionMatrix.mat`.
- Because of that exclusion, a clean clone of this repo cannot reproduce the full structural transition path on its own.
- The toy script in this folder runs without those excluded inputs. The structural scaffold is ready for local endpoint files once they are restored.
- Local `.mat` inputs under `input/` and generated outputs under `results/` are intentionally gitignored within this extension folder.

Recommended workflow once local `.mat` files are available:

1. Put `SS_iter.mat` and `SS_iter_boom.mat` into `extension/input/`, or restore them under `code/steadystate/`.
2. Run `extension/run_extension_pipeline.ps1`.
3. The pipeline will:
   - run the toy benchmark
   - export lightweight endpoint files automatically if raw `SS_iter*.mat` files are present
   - run the structural anticipated-demographics benchmark if endpoints are available
   - update `extension/results/extension_pipeline_summary.md`
