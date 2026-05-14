#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CODE_DIR="$PROJECT_ROOT/code"

LOGS_ROOT="$PROJECT_ROOT/notes/build/logs"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$LOGS_ROOT/annual_transition_mechanism_scenarios_hpc_$RUN_STAMP"
STATUS_PATH="$RUN_DIR/status.txt"
SUMMARY_PATH="$RUN_DIR/summary.txt"
MANIFEST_PATH="$RUN_DIR/manifest.txt"

PACK="${PACK:-hamilton}"
OUTPUT_STEM="${OUTPUT_STEM:-annual_transition_mechanism_scenarios_hamilton}"

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
    write_status "FAIL no_python_module_with_numpy_pandas"
    cat >"$SUMMARY_PATH" <<EOF
Annual transition mechanism scenario packet stopped because no tested Python module on Hamilton exposed both numpy and pandas.
Run directory: $RUN_DIR
EOF
    exit 1
}

module purge >/dev/null 2>&1 || true
module load "$PYTHON_MODULE" >/dev/null 2>&1

cat >"$MANIFEST_PATH" <<EOF
Objective: run a bounded Hamilton packet for annual transition mechanism scenarios.
Project root: $PROJECT_ROOT
Python module: $PYTHON_MODULE
Scenario pack: $PACK
Output stem: $OUTPUT_STEM
Workflow: python code/build_annual_transition_mechanism_scenarios.py --pack $PACK --output-stem $OUTPUT_STEM
EOF

write_status "START annual_transition_mechanism_scenarios pack=$PACK python_module=$PYTHON_MODULE"
if ! python "$CODE_DIR/build_annual_transition_mechanism_scenarios.py" --pack "$PACK" --output-stem "$OUTPUT_STEM" >"$RUN_DIR/stdout.log" 2>"$RUN_DIR/stderr.log"; then
    write_status "FAIL annual_transition_mechanism_scenarios"
    cat >"$SUMMARY_PATH" <<EOF
Annual transition mechanism scenarios packet stopped with an error.
Run directory: $RUN_DIR
Stdout: $RUN_DIR/stdout.log
Stderr: $RUN_DIR/stderr.log
EOF
    exit 1
fi

write_status "SUCCESS annual_transition_mechanism_scenarios"
cat >"$SUMMARY_PATH" <<EOF
Annual transition mechanism scenarios packet completed successfully.
Run directory: $RUN_DIR
Primary report: $PROJECT_ROOT/notes/build/${OUTPUT_STEM}.md
EOF

printf 'Run directory: %s\n' "$RUN_DIR"
