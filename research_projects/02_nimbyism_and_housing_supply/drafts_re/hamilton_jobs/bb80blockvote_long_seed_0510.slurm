#!/bin/bash
# Long-block vote T80 diagnostic only.
# Purpose: test whether very infrequent voting gives a smoother T80 seed that
# can later be homotopied back to the acceptable four-year block-vote model.
# This is not an acceptable paper route by itself.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80bvl
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --array=0-3
#SBATCH -o logs/bb80bvl_%A_%a.out
#SBATCH -e logs/bb80bvl_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bv80bvl20_d14" "bv80bvl20_d18" "bv80bvl40_d14" "bv80bvl40_d18")
SOURCE_TAGS=("bv4p_r25_d14" "bv4p_r25_d18" "bv4p_r25_d14" "bv4p_r25_d18")
SOURCE_OUTERS=("14" "6" "14" "6")
BLOCK_LEN=("20" "20" "40" "40")
OUTER_ITER=("18" "18" "18" "18")
BROYDEN_DAMP=("0.22" "0.22" "0.22" "0.22")
BROYDEN_CAP=("0.0022" "0.0022" "0.0022" "0.0022")
BASIS_CAP=("0.00032" "0.00032" "0.00032" "0.00032")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_t80_accepted_promotion_0509('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'VoteShiftMode','block_vote','VoteShiftHorizon',str2double('${BLOCK_LEN[$IDX]}'),'VoteBlockLength',str2double('${BLOCK_LEN[$IDX]}'),'OuterIter',str2double('${OUTER_ITER[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'RunRoot','$RUN_ROOT')"
