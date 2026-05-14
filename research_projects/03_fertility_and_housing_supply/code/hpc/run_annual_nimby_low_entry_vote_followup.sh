#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CODE_DIR="$PROJECT_ROOT/code"
CODE_DIR_MATLAB="${CODE_DIR//\\/\/}"

LOGS_ROOT="$PROJECT_ROOT/notes/build/logs"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$LOGS_ROOT/annual_nimby_low_entry_vote_followup_hpc_$RUN_STAMP"
STATUS_PATH="$RUN_DIR/status.txt"
SUMMARY_PATH="$RUN_DIR/summary.txt"
MANIFEST_PATH="$RUN_DIR/manifest.txt"

MATLAB_CMD="${MATLAB_CMD:-matlab}"
MODE="${MODE:-full}"
export ZAC_DAVID_EXTERNAL_ROOT="${ZAC_DAVID_EXTERNAL_ROOT:-$(cd "$PROJECT_ROOT/.." && pwd)/external_assets}"

mkdir -p "$RUN_DIR"
touch "$STATUS_PATH"

write_status() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$STATUS_PATH"
}

cat >"$MANIFEST_PATH" <<EOF
Objective: run the low-entry annual NIMBY vote-side follow-up on Linux/HPC.
Project root: $PROJECT_ROOT
MATLAB command: $MATLAB_CMD
Mode: $MODE
External asset root: $ZAC_DAVID_EXTERNAL_ROOT
Workflow: run_nimby_annual_low_entry_vote_followup('$MODE')
EOF

write_status "START low_entry_vote_followup mode=$MODE"
if ! "$MATLAB_CMD" -batch "cd('$CODE_DIR_MATLAB'); run_nimby_annual_low_entry_vote_followup('$MODE');" >"$RUN_DIR/stdout.log" 2>"$RUN_DIR/stderr.log"; then
    write_status "FAIL low_entry_vote_followup"
    cat >"$SUMMARY_PATH" <<EOF
Annual NIMBY low-entry vote-side follow-up stopped with an error.
Run directory: $RUN_DIR
Stdout: $RUN_DIR/stdout.log
Stderr: $RUN_DIR/stderr.log
EOF
    exit 1
fi

write_status "SUCCESS low_entry_vote_followup"
cat >"$SUMMARY_PATH" <<EOF
Annual NIMBY low-entry vote-side follow-up completed successfully.
Run directory: $RUN_DIR
Primary report: $PROJECT_ROOT/notes/build/nimby_annual_low_entry_vote_followup.md
EOF

printf 'Run directory: %s\n' "$RUN_DIR"
