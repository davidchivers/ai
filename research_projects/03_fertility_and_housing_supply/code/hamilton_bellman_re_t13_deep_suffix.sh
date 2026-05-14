#!/bin/bash
#SBATCH --job-name=fert_t13_tail
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

set -euo pipefail

RUN_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
COMPILED_DIR="${RUN_DIR}/compiled_sidecar"
BUILD_DIR="${RUN_DIR}/build"
OUTPUT_DIR="${RUN_DIR}/outputs"
STATUS_PATH="${RUN_DIR}/status.txt"
RESULTS_PATH="${RUN_DIR}/t13_deep_cases.csv"
SUMMARY_PATH="${RUN_DIR}/summary.txt"
INPUT_DIR="${COMPILED_DIR}/truth/transition_input_t13_diag"
SEED="2.2466822737,2.2613496523,2.2858505356,2.3016953730,2.3236256760,2.4000044888,2.4009632928,2.3615630257,2.3976989307,2.3505260199,2.4061451849,2.4012054578,2.4012054578"
FULL_PREV_MASK="0,1,1,1,1,1,1,1,1,1,1,1,1"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_status() {
  printf '%s %s\n' "$(timestamp)" "$1" | tee -a "${STATUS_PATH}" >/dev/null
}

parse_field() {
  local stdout_path="$1"
  local pattern="$2"
  python3 - "$stdout_path" "$pattern" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
match = re.search(sys.argv[2], text)
print(match.group(1) if match else "")
PY
}

extract_line_payload() {
  local stdout_path="$1"
  local prefix="$2"
  python3 - "$stdout_path" "$prefix" <<'PY'
import pathlib
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").splitlines()
prefix = sys.argv[2]
for line in text:
    if line.startswith(prefix):
        print(line.split(":", 1)[1].strip())
        break
PY
}

append_result() {
  local label="$1"
  local continuity_mask="$2"
  local previous_mask="$3"
  local maxres="$4"
  local iterations="$5"
  local stalled="$6"
  local exit_code="$7"
  local stdout_path="$8"
  local stderr_path="$9"
  local q_path="${10}"
  local implied_q_path="${11}"
  local residual_path="${12}"

  python3 - "$RESULTS_PATH" "$label" "$continuity_mask" "$previous_mask" "$maxres" "$iterations" "$stalled" "$exit_code" "$stdout_path" "$stderr_path" "$q_path" "$implied_q_path" "$residual_path" <<'PY'
import csv
import os
import sys

results_path = sys.argv[1]
row = sys.argv[2:]
header = [
    "case_label",
    "continuity_mask",
    "previous_implied_mask",
    "max_abs_residual",
    "iterations",
    "stalled",
    "exit_code",
    "stdout_path",
    "stderr_path",
    "q_path",
    "implied_q_path",
    "residual_path",
]
write_header = not os.path.exists(results_path)
with open(results_path, "a", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle)
    if write_header:
        writer.writerow(header)
    writer.writerow(row)
PY
}

run_case() {
  local label="$1"
  local continuity_mask="$2"
  local previous_mask="$3"
  local stdout_path="${OUTPUT_DIR}/${label}_stdout.log"
  local stderr_path="${OUTPUT_DIR}/${label}_stderr.log"

  log_status "START ${label}"

  set +e
  "${BUILD_DIR}/fertility_transition_re_cli" \
    "${INPUT_DIR}" \
    --initial-q-path "${SEED}" \
    --q-search-grid "1.5,1.70,1.72,1.73,1.74,1.75,1.80,1.85,1.90,2.00,2.25,2.35,2.40,2.50" \
    --damping 0.2 \
    --max-iter 5 \
    --vote-dp-scope remaining_path \
    --backtracking-line-search \
    --backtracking-activate-residual 0.5 \
    --backtracking-accept-worsen-ratio 1.0 \
    --backtracking-accept-worsen-abs-tol 0.0 \
    --backtracking-shrink-factor 0.5 \
    --max-backtracking-rounds 6 \
    --min-damping-path "0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125" \
    --coordinate-backtracking-line-search \
    --coordinate-backtracking-activate-residual 0.2 \
    --max-coordinate-backtracking-periods 1 \
    --max-coordinate-backtracking-rounds 8 \
    --coordinate-backtracking-require-improvement \
    --coordinate-backtracking-improve-tol 0.0 \
    --coordinate-min-damping-path "0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625" \
    --branch-continuity-mask "${continuity_mask}" \
    --branch-continuity-vote-slack 1.0 \
    --root-selection-lookahead \
    --root-selection-lookahead-min-brackets 2 \
    --root-selection-anchor previous_implied \
    --root-selection-previous-implied-mask "${previous_mask}" \
    --branch-hysteresis-mask "${FULL_PREV_MASK}" \
    --branch-tie-break-mask "${FULL_PREV_MASK}" \
    >"${stdout_path}" 2>"${stderr_path}"
  local exit_code=$?
  set -e

  local maxres
  maxres="$(parse_field "${stdout_path}" 'max abs residual:\s+([0-9Ee+\-\.]+)')"
  local iterations
  iterations="$(parse_field "${stdout_path}" 'iterations run:\s+([0-9]+)')"
  local stalled
  stalled="$(parse_field "${stdout_path}" 'stalled:\s+([01])')"
  local q_path
  q_path="$(extract_line_payload "${stdout_path}" 'q path:')"
  local implied_q_path
  implied_q_path="$(extract_line_payload "${stdout_path}" 'implied q path:')"
  local residual_path
  residual_path="$(extract_line_payload "${stdout_path}" 'residual path:')"

  append_result \
    "${label}" \
    "${continuity_mask}" \
    "${previous_mask}" \
    "${maxres}" \
    "${iterations}" \
    "${stalled}" \
    "${exit_code}" \
    "${stdout_path}" \
    "${stderr_path}" \
    "${q_path}" \
    "${implied_q_path}" \
    "${residual_path}"

  log_status "DONE ${label} maxres=${maxres} stalled=${stalled} exit=${exit_code}"
}

mkdir -p "${OUTPUT_DIR}"
: > "${STATUS_PATH}"
rm -f "${RESULTS_PATH}" "${SUMMARY_PATH}"

log_status "CONFIGURE build_dir=${BUILD_DIR}"
cmake -S "${COMPILED_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release >/dev/null
log_status "BUILD target=fertility_transition_re_cli"
cmake --build "${BUILD_DIR}" --target fertility_transition_re_cli -j "${SLURM_CPUS_PER_TASK:-8}" >/dev/null

run_case "late6_13" "0,0,0,0,0,1,1,1,1,1,1,1,1" "${FULL_PREV_MASK}"
run_case "late5_13" "0,0,0,0,1,1,1,1,1,1,1,1,1" "${FULL_PREV_MASK}"
run_case "late4_13" "0,0,0,1,1,1,1,1,1,1,1,1,1" "${FULL_PREV_MASK}"
run_case "late3_13" "0,0,1,1,1,1,1,1,1,1,1,1,1" "${FULL_PREV_MASK}"
run_case "late6_13_suffix_anchor" "0,0,0,0,0,1,1,1,1,1,1,1,1" "0,0,0,0,0,1,1,1,1,1,1,1,1"
run_case "late5_13_suffix_anchor" "0,0,0,0,1,1,1,1,1,1,1,1,1" "0,0,0,0,1,1,1,1,1,1,1,1,1"
run_case "late4_13_suffix_anchor" "0,0,0,1,1,1,1,1,1,1,1,1,1" "0,0,0,1,1,1,1,1,1,1,1,1,1"
run_case "late3_13_suffix_anchor" "0,0,1,1,1,1,1,1,1,1,1,1,1" "0,0,1,1,1,1,1,1,1,1,1,1,1"

python3 - "$RESULTS_PATH" "$SUMMARY_PATH" <<'PY'
import csv
import pathlib
import sys

results_path = pathlib.Path(sys.argv[1])
summary_path = pathlib.Path(sys.argv[2])
rows = list(csv.DictReader(results_path.open(encoding="utf-8")))
rows.sort(key=lambda row: (float(row["max_abs_residual"]), row["case_label"]))
best = rows[0]
summary_path.write_text(
    "\n".join(
        [
            "Workflow: success",
            f"Best case: {best['case_label']}",
            f"Best maxres: {best['max_abs_residual']}",
            f"Results path: {results_path}",
        ]
    )
    + "\n",
    encoding="utf-8",
)
PY

log_status "SUCCESS summary=${SUMMARY_PATH}"
