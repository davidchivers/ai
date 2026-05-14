#!/bin/bash
# Narrow four-year block-vote p0060 polish from the best acceptable near miss:
# bv4_brh_p0060 outer 4, max path gap 0.00111559708826972.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20bv4p
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-5
#SBATCH -o logs/bb20bv4p_%A_%a.out
#SBATCH -e logs/bb20bv4p_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bv4p_g_d14" "bv4p_g_d18" "bv4p_r25_d14" "bv4p_r25_d18" "bv4p_r50_d14" "bv4p_r50_d18")
SEED_MODES=("guess" "guess" "report25" "report25" "report50" "report50")
BROYDEN_DAMP=("0.14" "0.18" "0.14" "0.18" "0.14" "0.18")
BROYDEN_CAP=("0.0012" "0.0016" "0.0012" "0.0016" "0.0012" "0.0016")
BASIS_CAP=("0.00018" "0.00024" "0.00018" "0.00024" "0.00018" "0.00024")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','bv4_brh_p0060','SourceOuter',4,'SeedMode','${SEED_MODES[$IDX]}','TailYears',20,'TerminalAnchor','terminal_fixed_point','TerminalBlendWeight',1.00,'OuterIter',24,'BasisDim',10,'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',10,'BasisTailWeight',0.12,'BasisFocusStart',6,'BasisFocusEnd',8,'BasisFocusWeight',8,'PoliticalPassThrough',-0.006,'VoteShiftMode','block_vote','VoteShiftHorizon',4,'VoteBlockLength',4,'RunRoot','$RUN_ROOT')"
