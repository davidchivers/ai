#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CODE_DIR="$PROJECT_ROOT/code"
CODE_DIR_MATLAB="${CODE_DIR//\\/\/}"
BUILD_DIR="$PROJECT_ROOT/notes/build"

LOGS_ROOT="$BUILD_DIR/logs"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$LOGS_ROOT/fertility_benchmark_refresh_hpc_$RUN_STAMP"
STATUS_PATH="$RUN_DIR/status.txt"
SUMMARY_PATH="$RUN_DIR/summary.txt"
MANIFEST_PATH="$RUN_DIR/manifest.txt"

MATLAB_CMD="${MATLAB_CMD:-matlab}"
PYTHON_CMD="${PYTHON_CMD:-python3}"
export ZAC_DAVID_EXTERNAL_ROOT="${ZAC_DAVID_EXTERNAL_ROOT:-$(cd "$PROJECT_ROOT/.." && pwd)/external_assets}"

mkdir -p "$RUN_DIR"
touch "$STATUS_PATH"

write_status() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$STATUS_PATH"
}

run_matlab_step() {
    local step_name="$1"
    local batch_command="$2"

    write_status "START $step_name"
    if ! "$MATLAB_CMD" -batch "cd('$CODE_DIR_MATLAB'); $batch_command;" >"$RUN_DIR/${step_name}_stdout.log" 2>"$RUN_DIR/${step_name}_stderr.log"; then
        write_status "FAIL $step_name"
        return 1
    fi
    write_status "DONE $step_name"
}

cat >"$MANIFEST_PATH" <<EOF
Objective: rebuild the long 5-year fertility benchmark comparison layer on Linux/HPC.
Project root: $PROJECT_ROOT
MATLAB command: $MATLAB_CMD
Python command: $PYTHON_CMD
External asset root: $ZAC_DAVID_EXTERNAL_ROOT
Core MATLAB steps:
  1. run_ge_fertility_main
  2. write_fertility_vs_nimby_benchmark_main
Optional steps:
  3. plot_fertility_vs_nimby_benchmark.py
  4. pandoc benchmark PDF rebuild
EOF

run_matlab_step "01_run_ge_fertility" "run_ge_fertility_main"
run_matlab_step "02_write_benchmark_note" "write_fertility_vs_nimby_benchmark_main"

if command -v "$PYTHON_CMD" >/dev/null 2>&1; then
    write_status "START 03_plot_benchmark_panels"
    if "$PYTHON_CMD" "$CODE_DIR/plot_fertility_vs_nimby_benchmark.py" >"$RUN_DIR/03_plot_benchmark_panels_stdout.log" 2>"$RUN_DIR/03_plot_benchmark_panels_stderr.log"; then
        write_status "DONE 03_plot_benchmark_panels"
    else
        write_status "WARN 03_plot_benchmark_panels failed"
    fi
elif command -v python >/dev/null 2>&1; then
    write_status "START 03_plot_benchmark_panels"
    if python "$CODE_DIR/plot_fertility_vs_nimby_benchmark.py" >"$RUN_DIR/03_plot_benchmark_panels_stdout.log" 2>"$RUN_DIR/03_plot_benchmark_panels_stderr.log"; then
        write_status "DONE 03_plot_benchmark_panels"
    else
        write_status "WARN 03_plot_benchmark_panels failed"
    fi
else
    write_status "SKIP 03_plot_benchmark_panels python not found"
fi

if command -v pandoc >/dev/null 2>&1; then
    REPORT_MD="$BUILD_DIR/fertility_vs_nimby_benchmark_report.md"
    REPORT_PDF="$BUILD_DIR/fertility_vs_nimby_benchmark_report.pdf"
    if [[ -f "$REPORT_MD" ]]; then
        write_status "START 04_pandoc_benchmark_pdf"
        if pandoc "$REPORT_MD" --from markdown --to pdf --pdf-engine=xelatex --resource-path="$BUILD_DIR" -o "$REPORT_PDF" >"$RUN_DIR/04_pandoc_benchmark_pdf_stdout.log" 2>"$RUN_DIR/04_pandoc_benchmark_pdf_stderr.log"; then
            write_status "DONE 04_pandoc_benchmark_pdf"
        else
            write_status "WARN 04_pandoc_benchmark_pdf failed"
        fi
    else
        write_status "SKIP 04_pandoc_benchmark_pdf report markdown missing"
    fi
else
    write_status "SKIP 04_pandoc_benchmark_pdf pandoc not found"
fi

write_status "SUCCESS fertility_benchmark_refresh"
cat >"$SUMMARY_PATH" <<EOF
Fertility 5-year benchmark refresh completed successfully.
Run directory: $RUN_DIR
Core outputs:
  - $BUILD_DIR/fertility_run_ge_report.md
  - $BUILD_DIR/fertility_vs_nimby_benchmark_report.md
  - $BUILD_DIR/fertility_vs_nimby_benchmark_summary.csv
  - $BUILD_DIR/fertility_vs_nimby_common_price_grid.csv
Optional outputs if available:
  - $BUILD_DIR/fertility_vs_nimby_benchmark_panels.png
  - $BUILD_DIR/fertility_vs_nimby_benchmark_panels.pdf
  - $BUILD_DIR/fertility_vs_nimby_benchmark_report.pdf
EOF

printf 'Run directory: %s\n' "$RUN_DIR"
