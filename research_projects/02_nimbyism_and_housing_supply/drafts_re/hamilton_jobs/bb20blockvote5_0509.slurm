#!/bin/bash
# Five-year block-vote fresh-seed homotopy packet.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20bv5
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-3
#SBATCH -o logs/bb20bv5_%A_%a.out
#SBATCH -e logs/bb20bv5_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bv5_rbr" "bv5_rbend" "bv5_rbguess" "bv5_brh")
SOURCE_TAGS=("rbr20end100_k8" "rb20end50_k8" "rb20guess_k8" "brh20d80c005_p0060")
SOURCE_OUTERS=("1" "4" "2" "7")
BASIS_DIM=("8" "8" "8" "10")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_av_homotopy_chain_0509('RunTagStem','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'SeedMode','guess','VoteShiftMode','block_vote','VoteShiftHorizon',5,'VoteBlockLength',5,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'RunRoot','$RUN_ROOT')"
