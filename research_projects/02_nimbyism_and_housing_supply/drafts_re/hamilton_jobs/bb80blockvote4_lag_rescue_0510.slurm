#!/bin/bash
# Four-year block-vote T80 RE lag robustness smoke.
# Purpose: keep the acceptable four-year political timing, but test a
# time-to-build style lag in the generated price/pass-through map.
# This is a robustness/model-extension run, not a baseline promotion.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80bv4lg
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --array=0-5
#SBATCH -o logs/bb80bv4lg_%A_%a.out
#SBATCH -e logs/bb80bv4lg_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bv80bv4lag_l1_n006" "bv80bv4lag_l2_n006" "bv80bv4lag_l4_n006" "bv80bv4lag_l1_n012" "bv80bv4lag_l2_n012" "bv80bv4lag_l4_n012")
NORE_TAGS=("nore80bv4_006" "nore80bv4_006" "nore80bv4_006" "nore80bv4_012" "nore80bv4_012" "nore80bv4_012")
LAG=("1" "2" "4" "1" "2" "4")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_t80_blockvote4_fullseed_rescue_0510('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','bv4p_r25_d14','SourceOuter',14,'NoReRunTag','${NORE_TAGS[$IDX]}','SeedMode','hybrid_shifted','HybridSwitchPeriod',40,'OuterIter',18,'BroydenDamping',0.30,'BroydenStepCap',0.0030,'BasisStepCap',0.00045,'LaggedPassThrough',true,'PassThroughLagYears',str2double('${LAG[$IDX]}'),'RunRoot','$RUN_ROOT')"
