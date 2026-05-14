#!/bin/bash
# Parallel anchor diagnostics for the T20 p0060 RE path.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20anch
#SBATCH -p shared
#SBATCH -t 06:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-7
#SBATCH -o logs/bb20anch_%A_%a.out
#SBATCH -e logs/bb20anch_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("anc20tfp60_g" "anc20tfp80_g" "anc20tfp60_r50" "anc20tfp60_e50" "anc20ref20_g" "anc20ref60_g" "anc20soft50_60g" "anc20soft75_60g")
SOURCE_TAGS=("rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20end50_k8" "rb20end50_k8")
SOURCE_OUTERS=("4" "4" "4" "4" "4" "4" "4" "4")
SEED_MODES=("guess" "guess" "report50" "end50" "guess" "guess" "guess" "guess")
TAIL_YEARS=("60" "80" "60" "60" "20" "60" "60" "60")
TERMINAL_ANCHORS=("terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "reference" "reference" "soft_reference" "soft_reference")
TERMINAL_BLEND=("1.00" "1.00" "1.00" "1.00" "0.00" "0.00" "0.50" "0.75")
BASIS_DIM=("8" "8" "8" "8" "8" "8" "8" "8")
BROYDEN_DAMP=("0.35" "0.35" "0.35" "0.35" "0.30" "0.30" "0.32" "0.32")
BROYDEN_CAP=("0.005" "0.005" "0.005" "0.005" "0.004" "0.004" "0.004" "0.004")
BASIS_CAP=("0.0007" "0.0007" "0.0007" "0.0007" "0.0006" "0.0006" "0.0006" "0.0006")
END_WEIGHT=("14" "14" "14" "16" "14" "14" "14" "14")
TAIL_WEIGHT=("0.10" "0.08" "0.10" "0.10" "0.15" "0.10" "0.10" "0.10")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'SeedMode','${SEED_MODES[$IDX]}','TailYears',str2double('${TAIL_YEARS[$IDX]}'),'TerminalAnchor','${TERMINAL_ANCHORS[$IDX]}','TerminalBlendWeight',str2double('${TERMINAL_BLEND[$IDX]}'),'OuterIter',16,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',str2double('${END_WEIGHT[$IDX]}'),'BasisTailWeight',str2double('${TAIL_WEIGHT[$IDX]}'),'RunRoot','$RUN_ROOT')"
