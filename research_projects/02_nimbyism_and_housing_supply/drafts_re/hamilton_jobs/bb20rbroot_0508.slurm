#!/bin/bash
# T20 p0060 reduced-basis quasi-Newton rescue.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20rbrt
#SBATCH -p shared
#SBATCH -t 10:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-7
#SBATCH -o logs/bb20rbrt_%A_%a.out
#SBATCH -e logs/bb20rbrt_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("rbr20best_k8" "rbr20rep50_k8" "rbr20end50_k8" "rbr20end100_k8" "rbr20midend_k10" "rbr20guess2_k8" "rbr40guess2_k8" "rbr20ref_k10")
SOURCE_TAGS=("rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20guess_k8" "rb40guess_k8" "rb20ref_end50")
SOURCE_OUTERS=("4" "4" "4" "4" "4" "2" "2" "4")
SEED_MODES=("guess" "report50" "end50" "end100" "midend50" "guess" "guess" "guess")
TAIL_YEARS=("20" "20" "20" "20" "20" "20" "40" "20")
TERMINAL_ANCHORS=("terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "reference")
BASIS_DIM=("8" "8" "8" "8" "10" "8" "8" "10")
BROYDEN_DAMP=("0.40" "0.35" "0.35" "0.30" "0.35" "0.35" "0.35" "0.30")
BROYDEN_CAP=("0.006" "0.005" "0.005" "0.004" "0.005" "0.005" "0.005" "0.004")
BASIS_CAP=("0.0008" "0.0007" "0.0007" "0.0006" "0.0007" "0.0007" "0.0007" "0.0006")
END_WEIGHT=("14" "14" "16" "16" "16" "12" "12" "16")
TAIL_WEIGHT=("0.15" "0.15" "0.15" "0.15" "0.12" "0.15" "0.12" "0.15")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'SeedMode','${SEED_MODES[$IDX]}','TailYears',str2double('${TAIL_YEARS[$IDX]}'),'TerminalAnchor','${TERMINAL_ANCHORS[$IDX]}','OuterIter',28,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',str2double('${END_WEIGHT[$IDX]}'),'BasisTailWeight',str2double('${TAIL_WEIGHT[$IDX]}'),'RunRoot','$RUN_ROOT')"
