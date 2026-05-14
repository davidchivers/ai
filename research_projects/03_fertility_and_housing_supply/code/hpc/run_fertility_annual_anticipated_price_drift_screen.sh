#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CODE_DIR="$PROJECT_ROOT/code"
CODE_DIR_MATLAB="${CODE_DIR//\\/\/}"

LOGS_ROOT="$PROJECT_ROOT/notes/build/logs"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$LOGS_ROOT/fertility_annual_anticipated_price_drift_screen_hpc_$RUN_STAMP"
STATUS_PATH="$RUN_DIR/status.txt"
SUMMARY_PATH="$RUN_DIR/summary.txt"
MANIFEST_PATH="$RUN_DIR/manifest.txt"

MATLAB_CMD="${MATLAB_CMD:-matlab}"
MODE="${MODE:-confirm}"
export ZAC_DAVID_EXTERNAL_ROOT="${ZAC_DAVID_EXTERNAL_ROOT:-$(cd "$PROJECT_ROOT/.." && pwd)/external_assets}"

mkdir -p "$RUN_DIR"
touch "$STATUS_PATH"

write_status() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$STATUS_PATH"
}

cat >"$MANIFEST_PATH" <<EOF
Objective: run the annual fertility anticipated-price-drift RE-style confirmation screen on Linux/HPC.
Project root: $PROJECT_ROOT
MATLAB command: $MATLAB_CMD
Mode: $MODE
External asset root: $ZAC_DAVID_EXTERNAL_ROOT
Workflow: run_fertility_annual_anticipated_price_drift_screen('$MODE')
EOF

write_status "START fertility_annual_anticipated_price_drift_screen mode=$MODE"
if ! "$MATLAB_CMD" -batch "cd('$CODE_DIR_MATLAB'); run_fertility_annual_anticipated_price_drift_screen('$MODE');" >"$RUN_DIR/stdout.log" 2>"$RUN_DIR/stderr.log"; then
    write_status "FAIL fertility_annual_anticipated_price_drift_screen"
    cat >"$SUMMARY_PATH" <<EOF
Annual fertility anticipated-price-drift RE-style screen stopped with an error.
Run directory: $RUN_DIR
Stdout: $RUN_DIR/stdout.log
Stderr: $RUN_DIR/stderr.log
EOF
    exit 1
fi

write_status "SUCCESS fertility_annual_anticipated_price_drift_screen"
cat >"$SUMMARY_PATH" <<EOF
Annual fertility anticipated-price-drift RE-style screen completed successfully.
Run directory: $RUN_DIR
Primary report: $PROJECT_ROOT/notes/build/fertility_annual_anticipated_price_drift_screen.md
EOF

printf 'Run directory: %s\n' "$RUN_DIR"
