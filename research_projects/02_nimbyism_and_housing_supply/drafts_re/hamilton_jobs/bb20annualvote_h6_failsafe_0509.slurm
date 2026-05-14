#!/bin/bash
# One allowed 12-hour-failsafe continuation from the best h6 annual-vote branch.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20avf6
#SBATCH -p shared
#SBATCH -t 04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-1
#SBATCH -o logs/bb20avf6_%A_%a.out
#SBATCH -e logs/bb20avf6_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("av20fh6f_h6_k8" "av20fh6f_h7_k8")
VOTE_HORIZON=("6" "7")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','av20fh5c_h6_k8','SourceOuter',4,'SeedMode','guess','TailYears',20,'TerminalAnchor','terminal_fixed_point','TerminalBlendWeight',1.00,'OuterIter',8,'BasisDim',8,'BroydenDamping',0.30,'BroydenStepCap',0.005,'BasisStepCap',0.0008,'BasisEndWeight',10,'BasisTailWeight',0.15,'BasisFocusStart',6,'BasisFocusEnd',8,'BasisFocusWeight',1,'PoliticalPassThrough',-0.006,'VoteShiftMode','finite_horizon','VoteShiftHorizon',str2double('${VOTE_HORIZON[$IDX]}'),'RunRoot','$RUN_ROOT')"
