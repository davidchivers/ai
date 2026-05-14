#!/bin/bash
# 12-hour T20 full-p0060 rescue workflow.
# Uses reduced-basis price-path updates with extra weight near the end of the
# reported 20-year window, plus controlled seeds from the best p0060 iterate.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20bas12
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-7
#SBATCH -o logs/bb20bas12_%A_%a.out
#SBATCH -e logs/bb20bas12_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("rb20guess_k8" "rb20end50_k8" "rb20report25_k8" "rb20rampend_k10" "rb40guess_k8" "rb40end50_k10" "rb20ref_end50" "rb40ref_end50")
SEED_MODES=("guess" "end50" "report25" "rampend" "guess" "end50" "end50" "end50")
TAIL_YEARS=("20" "20" "20" "20" "40" "40" "20" "40")
TERMINAL_ANCHORS=("terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "reference" "reference")
BASIS_DIM=("8" "8" "8" "10" "8" "10" "8" "10")
BASIS_DAMP=("0.35" "0.30" "0.30" "0.25" "0.30" "0.25" "0.30" "0.25")
BASIS_CAP=("0.0012" "0.0010" "0.0010" "0.0009" "0.0010" "0.0009" "0.0010" "0.0009")
END_WEIGHT=("8" "10" "8" "12" "10" "12" "10" "12")
TAIL_WEIGHT=("0.20" "0.20" "0.20" "0.20" "0.12" "0.12" "0.20" "0.12")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis12_0507('RunTag','${RUN_TAGS[$IDX]}','SeedMode','${SEED_MODES[$IDX]}','TailYears',str2double('${TAIL_YEARS[$IDX]}'),'TerminalAnchor','${TERMINAL_ANCHORS[$IDX]}','OuterIter',36,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'BasisDamping',str2double('${BASIS_DAMP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',str2double('${END_WEIGHT[$IDX]}'),'BasisTailWeight',str2double('${TAIL_WEIGHT[$IDX]}'),'RunRoot','$RUN_ROOT')"
