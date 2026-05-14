#!/bin/bash
# Annual-vote timing smoke grid for the T20 baby-boom RE price path.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20avsm
#SBATCH -p shared
#SBATCH -t 04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-11
#SBATCH -o logs/bb20avsm_%A_%a.out
#SBATCH -e logs/bb20avsm_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("av20cur_g_k8" "av20cur_e_k8" "av20cur_c7_k12" "av20cur_g_p003" "av20cur_g_p012" "av20cur40_g_k8" "av20fh2_g_k8" "av20fh2_c7_k12" "av20fh3_g_k8" "av20fh5_g_k8" "av20cur_ref_g" "av20cur_soft_g")
SOURCE_TAGS=("rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8")
SOURCE_OUTERS=("1" "1" "1" "1" "1" "1" "1" "1" "1" "1" "1" "1")
SEED_MODES=("guess" "end100" "critical7end100" "guess" "guess" "guess" "guess" "critical7end100" "guess" "guess" "guess" "guess")
TAIL_YEARS=("20" "20" "20" "20" "20" "40" "20" "20" "20" "20" "20" "40")
TERMINAL_ANCHORS=("terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "reference" "soft_reference")
TERMINAL_BLEND=("1.00" "1.00" "1.00" "1.00" "1.00" "1.00" "1.00" "1.00" "1.00" "1.00" "0.00" "0.50")
VOTE_SHIFT=("current_period" "current_period" "current_period" "current_period" "current_period" "current_period" "finite_horizon" "finite_horizon" "finite_horizon" "finite_horizon" "current_period" "current_period")
VOTE_HORIZON=("1" "1" "1" "1" "1" "1" "2" "2" "3" "5" "1" "1")
PASS_THROUGH=("-0.006" "-0.006" "-0.006" "-0.003" "-0.012" "-0.006" "-0.006" "-0.006" "-0.006" "-0.006" "-0.006" "-0.006")
BASIS_DIM=("8" "8" "12" "8" "8" "8" "8" "12" "8" "8" "8" "8")
BROYDEN_DAMP=("0.35" "0.30" "0.25" "0.35" "0.30" "0.30" "0.30" "0.25" "0.30" "0.30" "0.30" "0.30")
BROYDEN_CAP=("0.006" "0.005" "0.004" "0.006" "0.005" "0.005" "0.005" "0.004" "0.005" "0.005" "0.005" "0.005")
BASIS_CAP=("0.0009" "0.0008" "0.00055" "0.0009" "0.0008" "0.0008" "0.0008" "0.00055" "0.0008" "0.0008" "0.0008" "0.0008")
END_WEIGHT=("10" "12" "14" "10" "12" "10" "10" "14" "10" "10" "10" "10")
TAIL_WEIGHT=("0.15" "0.15" "0.12" "0.15" "0.15" "0.10" "0.15" "0.12" "0.15" "0.15" "0.15" "0.10")
FOCUS_WEIGHT=("1" "1" "16" "1" "1" "1" "1" "16" "1" "1" "1" "1")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'SeedMode','${SEED_MODES[$IDX]}','TailYears',str2double('${TAIL_YEARS[$IDX]}'),'TerminalAnchor','${TERMINAL_ANCHORS[$IDX]}','TerminalBlendWeight',str2double('${TERMINAL_BLEND[$IDX]}'),'OuterIter',8,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',str2double('${END_WEIGHT[$IDX]}'),'BasisTailWeight',str2double('${TAIL_WEIGHT[$IDX]}'),'BasisFocusStart',6,'BasisFocusEnd',8,'BasisFocusWeight',str2double('${FOCUS_WEIGHT[$IDX]}'),'PoliticalPassThrough',str2double('${PASS_THROUGH[$IDX]}'),'VoteShiftMode','${VOTE_SHIFT[$IDX]}','VoteShiftHorizon',str2double('${VOTE_HORIZON[$IDX]}'),'RunRoot','$RUN_ROOT')"
