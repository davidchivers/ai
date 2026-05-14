#!/bin/bash
# Four-year block-vote T80 RE full-seed rescue.
# Purpose: keep the final model fixed, but replace the weak padded T20 seed
# with no-RE/hybrid full-horizon price seeds.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80bv4fs
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --array=0-5
#SBATCH -o logs/bb80bv4fs_%A_%a.out
#SBATCH -e logs/bb80bv4fs_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bv80bv4fs_n006_d022" "bv80bv4fs_n012_d022" "bv80bv4fs_h006_d022" "bv80bv4fs_h012_d022" "bv80bv4fs_h006_d030" "bv80bv4fs_h012_d030")
SEED_MODES=("nore_full" "nore_full" "hybrid_shifted" "hybrid_shifted" "hybrid_shifted" "hybrid_shifted")
NORE_TAGS=("nore80bv4_006" "nore80bv4_012" "nore80bv4_006" "nore80bv4_012" "nore80bv4_006" "nore80bv4_012")
BROYDEN_DAMP=("0.22" "0.22" "0.22" "0.22" "0.30" "0.30")
BROYDEN_CAP=("0.0022" "0.0022" "0.0022" "0.0022" "0.0030" "0.0030")
BASIS_CAP=("0.00032" "0.00032" "0.00032" "0.00032" "0.00045" "0.00045")
OUTER_ITER=("20" "20" "22" "22" "24" "24")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_t80_blockvote4_fullseed_rescue_0510('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','bv4p_r25_d18','SourceOuter',6,'NoReRunTag','${NORE_TAGS[$IDX]}','SeedMode','${SEED_MODES[$IDX]}','HybridSwitchPeriod',40,'OuterIter',str2double('${OUTER_ITER[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'RunRoot','$RUN_ROOT')"
