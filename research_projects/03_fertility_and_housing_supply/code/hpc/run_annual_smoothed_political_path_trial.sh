#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CODE_DIR="$PROJECT_ROOT/code"

LOGS_ROOT="$PROJECT_ROOT/notes/build/logs"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$LOGS_ROOT/annual_smoothed_political_path_trial_hpc_$RUN_STAMP"
STATUS_PATH="$RUN_DIR/status.txt"
SUMMARY_PATH="$RUN_DIR/summary.txt"
MANIFEST_PATH="$RUN_DIR/manifest.txt"

OUTPUT_STEM="${OUTPUT_STEM:-nimby_vs_fertility_smoothed_political_path_trial}"
SMOOTH_RHO="${SMOOTH_RHO:-0.65}"
BOOM_AMP="${BOOM_AMP:-0.10}"

mkdir -p "$RUN_DIR"
touch "$STATUS_PATH"

write_status() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$STATUS_PATH"
}

select_python() {
    local modules=(
        "python/3.12.6"
        "python/3.13.9"
        "python/3.10.8"
        "python/3.9.9"
    )
    local chosen=""
    for mod in "${modules[@]}"; do
        module purge >/dev/null 2>&1 || true
        if ! module load "$mod" >/dev/null 2>&1; then
            continue
        fi
        if python - <<'PY' >/dev/null 2>&1
import numpy
import pandas
import matplotlib
PY
        then
            chosen="$mod"
            break
        fi
    done
    if [[ -z "$chosen" ]]; then
        return 1
    fi
    printf '%s\n' "$chosen"
}

PYTHON_MODULE="$(select_python)" || {
    write_status "FAIL no_python_module_with_numpy_pandas_matplotlib"
    cat >"$SUMMARY_PATH" <<EOF
Annual smoothed political-path trial stopped because no tested Python module on Hamilton exposed numpy, pandas, and matplotlib.
Run directory: $RUN_DIR
EOF
    exit 1
}

module purge >/dev/null 2>&1 || true
module load "$PYTHON_MODULE" >/dev/null 2>&1

cat >"$MANIFEST_PATH" <<EOF
Objective: run the dormant bridge-level smoothed political-path trial on Hamilton.
Project root: $PROJECT_ROOT
Python module: $PYTHON_MODULE
Output stem: $OUTPUT_STEM
Smooth rho: $SMOOTH_RHO
Boom amp: $BOOM_AMP
Workflow: python code/build_nimby_vs_fertility_smoothed_political_path_trial.py --smooth-rho $SMOOTH_RHO --boom-amp $BOOM_AMP --stem $OUTPUT_STEM
EOF

write_status "START annual_smoothed_political_path_trial python_module=$PYTHON_MODULE smooth_rho=$SMOOTH_RHO boom_amp=$BOOM_AMP"
if ! python "$CODE_DIR/build_nimby_vs_fertility_smoothed_political_path_trial.py" \
    --smooth-rho "$SMOOTH_RHO" \
    --boom-amp "$BOOM_AMP" \
    --stem "$OUTPUT_STEM" >"$RUN_DIR/stdout.log" 2>"$RUN_DIR/stderr.log"; then
    write_status "FAIL annual_smoothed_political_path_trial"
    cat >"$SUMMARY_PATH" <<EOF
Annual smoothed political-path trial stopped with an error.
Run directory: $RUN_DIR
Stdout: $RUN_DIR/stdout.log
Stderr: $RUN_DIR/stderr.log
EOF
    exit 1
fi

write_status "SUCCESS annual_smoothed_political_path_trial"
cat >"$SUMMARY_PATH" <<EOF
Annual smoothed political-path trial completed successfully.
Run directory: $RUN_DIR
Primary report: $PROJECT_ROOT/notes/build/${OUTPUT_STEM}.md
EOF

printf 'Run directory: %s\n' "$RUN_DIR"
