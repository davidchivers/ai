#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUNDLE_ROOT="$(cd "$PROJECT_ROOT/.." && pwd)"
CODE_DIR="$PROJECT_ROOT/code"
CODE_DIR_MATLAB="${CODE_DIR//\\/\/}"

LOGS_ROOT="$PROJECT_ROOT/notes/build/logs"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$LOGS_ROOT/annual_nimby_hpc_$RUN_STAMP"
STATUS_PATH="$RUN_DIR/status.txt"
SUMMARY_PATH="$RUN_DIR/summary.txt"
MANIFEST_PATH="$RUN_DIR/manifest.txt"

MATLAB_CMD="${MATLAB_CMD:-matlab}"
START_AT_STEP="${START_AT_STEP:-1}"
END_AT_STEP="${END_AT_STEP:-4}"
export ZAC_DAVID_EXTERNAL_ROOT="${ZAC_DAVID_EXTERNAL_ROOT:-$BUNDLE_ROOT/external_assets}"

mkdir -p "$RUN_DIR"
touch "$STATUS_PATH"

if ! [[ "$START_AT_STEP" =~ ^[0-9]+$ && "$END_AT_STEP" =~ ^[0-9]+$ ]]; then
    echo "START_AT_STEP and END_AT_STEP must be integers." >&2
    exit 1
fi

if (( START_AT_STEP < 1 || END_AT_STEP > 4 || START_AT_STEP > END_AT_STEP )); then
    echo "Valid step range is 1-4 and START_AT_STEP must be <= END_AT_STEP." >&2
    exit 1
fi

write_status() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$STATUS_PATH"
}

run_step() {
    local step_index="$1"
    local step_name="$2"
    local batch_command="$3"
    local stdout_path="$RUN_DIR/${step_name}_stdout.log"
    local stderr_path="$RUN_DIR/${step_name}_stderr.log"

    if (( step_index < START_AT_STEP || step_index > END_AT_STEP )); then
        write_status "SKIP ${step_name}"
        return
    fi

    write_status "START ${step_name}"
    if ! "$MATLAB_CMD" -batch "cd('$CODE_DIR_MATLAB'); $batch_command;" >"$stdout_path" 2>"$stderr_path"; then
        write_status "FAIL ${step_name}"
        cat >"$SUMMARY_PATH" <<EOF
Annual NIMBY HPC workflow stopped with an error.
Run directory: $RUN_DIR
Failed step: $step_name
Stdout: $stdout_path
Stderr: $stderr_path
EOF
        return 1
    fi
    write_status "DONE ${step_name}"
}

cat >"$MANIFEST_PATH" <<EOF
Objective: run the annual NIMBY steady-state workflow on Linux/HPC.
Project root: $PROJECT_ROOT
Bundle root: $BUNDLE_ROOT
MATLAB command: $MATLAB_CMD
External asset root: $ZAC_DAVID_EXTERNAL_ROOT
Selected steps: $START_AT_STEP-$END_AT_STEP

Step map:
1. run_nimby_annual_recalibration_stage2('full')
2. compare_nimby_local_age_block_periodization_main('benchmark')
3. run_nimby_annual_housing_access_screen('fast')
4. run_nimby_annual_housing_access_screen('full')
EOF

run_step 1 "01_stage2_full" "run_nimby_annual_recalibration_stage2('full')"
run_step 2 "02_age_block_benchmark" "compare_nimby_local_age_block_periodization_main('benchmark')"
run_step 3 "03_housing_access_fast" "run_nimby_annual_housing_access_screen('fast')"
run_step 4 "04_housing_access_full" "run_nimby_annual_housing_access_screen('full')"

write_status "SUCCESS"
cat >"$SUMMARY_PATH" <<EOF
Annual NIMBY HPC workflow completed successfully.
Run directory: $RUN_DIR
Primary report: $PROJECT_ROOT/notes/build/nimby_annual_housing_access_screen.md
EOF

printf 'Run directory: %s\n' "$RUN_DIR"
