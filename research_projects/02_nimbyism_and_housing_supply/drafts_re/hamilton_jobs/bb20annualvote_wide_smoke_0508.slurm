#!/bin/bash
# Wider annual-vote finite-horizon smoke for the T20 baby-boom RE price path.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20avwd
#SBATCH -p shared
#SBATCH -t 04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-7
#SBATCH -o logs/bb20avwd_%A_%a.out
#SBATCH -e logs/bb20avwd_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("av20fh8_g_k8" "av20fh10_g_k8" "av20fh15_g_k8" "av20fh20_g_k8" "av20fh10_c7_k12" "av20fh20_c7_k12" "av40fh20_g_k8" "av40fh30_g_k8")
SOURCE_TAGS=("rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8")
SOURCE_OUTERS=("1" "1" "1" "1" "1" "1" "1" "1")
SEED_MODES=("guess" "guess" "guess" "guess" "critical7end100" "critical7end100" "guess" "guess")
TAIL_YEARS=("20" "20" "20" "20" "20" "20" "40" "40")
VOTE_HORIZON=("8" "10" "15" "20" "10" "20" "20" "30")
BASIS_DIM=("8" "8" "8" "8" "12" "12" "8" "8")
BROYDEN_DAMP=("0.30" "0.30" "0.30" "0.30" "0.25" "0.25" "0.30" "0.30")
BROYDEN_CAP=("0.005" "0.005" "0.005" "0.005" "0.004" "0.004" "0.005" "0.005")
BASIS_CAP=("0.0008" "0.0008" "0.0008" "0.0008" "0.00055" "0.00055" "0.0008" "0.0008")
END_WEIGHT=("10" "10" "10" "10" "14" "14" "10" "10")
TAIL_WEIGHT=("0.15" "0.15" "0.15" "0.15" "0.12" "0.12" "0.10" "0.10")
FOCUS_WEIGHT=("1" "1" "1" "1" "16" "16" "1" "1")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'SeedMode','${SEED_MODES[$IDX]}','TailYears',str2double('${TAIL_YEARS[$IDX]}'),'TerminalAnchor','terminal_fixed_point','TerminalBlendWeight',1.00,'OuterIter',8,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',str2double('${END_WEIGHT[$IDX]}'),'BasisTailWeight',str2double('${TAIL_WEIGHT[$IDX]}'),'BasisFocusStart',6,'BasisFocusEnd',8,'BasisFocusWeight',str2double('${FOCUS_WEIGHT[$IDX]}'),'PoliticalPassThrough',-0.006,'VoteShiftMode','finite_horizon','VoteShiftHorizon',str2double('${VOTE_HORIZON[$IDX]}'),'RunRoot','$RUN_ROOT')"
