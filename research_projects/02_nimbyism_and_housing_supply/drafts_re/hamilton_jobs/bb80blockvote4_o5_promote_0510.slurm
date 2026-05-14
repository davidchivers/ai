#!/bin/bash
# T80 promotion from improved accepted four-year block-vote T20 branch:
# bv4p_r25_d18 outer 5, max path gap 0.00085729659674854.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80bv4o5
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --array=0-2
#SBATCH -o logs/bb80bv4o5_%A_%a.out
#SBATCH -e logs/bb80bv4o5_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bv80bv4_r25o5_d018" "bv80bv4_r25o5_d022" "bv80bv4_r25o5_d026")
BROYDEN_DAMP=("0.18" "0.22" "0.26")
BROYDEN_CAP=("0.0018" "0.0022" "0.0028")
BASIS_CAP=("0.00024" "0.00032" "0.00040")
OUTER_ITER=("18" "20" "22")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_t80_accepted_promotion_0509('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','bv4p_r25_d18','SourceOuter',5,'VoteShiftMode','block_vote','VoteShiftHorizon',4,'VoteBlockLength',4,'OuterIter',str2double('${OUTER_ITER[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'RunRoot','$RUN_ROOT')"
