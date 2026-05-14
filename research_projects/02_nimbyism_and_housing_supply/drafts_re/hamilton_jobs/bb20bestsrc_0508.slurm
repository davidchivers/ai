#!/bin/bash
# Branches restarted from the current best live root result.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20bsrc
#SBATCH -p shared
#SBATCH -t 05:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-5
#SBATCH -o logs/bb20bsrc_%A_%a.out
#SBATCH -e logs/bb20bsrc_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bsrc_c7e20_k14" "bsrc_c7e20_k18" "bsrc_c7only20_k14" "bsrc_c7e60_k14" "bsrc_c7soft50_k14" "bsrc_c7soft75_k14")
SOURCE_TAGS=("rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8" "rbr20end100_k8")
SOURCE_OUTERS=("1" "1" "1" "1" "1" "1")
SEED_MODES=("critical7end100" "critical7end100" "critical7" "critical7end100" "critical7end100" "critical7end100")
TAIL_YEARS=("20" "20" "20" "60" "60" "60")
TERMINAL_ANCHORS=("terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "terminal_fixed_point" "soft_reference" "soft_reference")
TERMINAL_BLEND=("1.00" "1.00" "1.00" "1.00" "0.50" "0.75")
BASIS_DIM=("14" "18" "14" "14" "14" "14")
BROYDEN_DAMP=("0.22" "0.18" "0.22" "0.20" "0.20" "0.20")
BROYDEN_CAP=("0.0035" "0.0030" "0.0035" "0.0030" "0.0030" "0.0030")
BASIS_CAP=("0.00045" "0.00040" "0.00045" "0.00040" "0.00040" "0.00040")
END_WEIGHT=("12" "12" "10" "12" "12" "12")
TAIL_WEIGHT=("0.12" "0.12" "0.12" "0.08" "0.08" "0.08")
FOCUS_WEIGHT=("22" "24" "22" "24" "24" "24")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'SeedMode','${SEED_MODES[$IDX]}','TailYears',str2double('${TAIL_YEARS[$IDX]}'),'TerminalAnchor','${TERMINAL_ANCHORS[$IDX]}','TerminalBlendWeight',str2double('${TERMINAL_BLEND[$IDX]}'),'OuterIter',12,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',str2double('${END_WEIGHT[$IDX]}'),'BasisTailWeight',str2double('${TAIL_WEIGHT[$IDX]}'),'BasisFocusStart',6,'BasisFocusEnd',8,'BasisFocusWeight',str2double('${FOCUS_WEIGHT[$IDX]}'),'RunRoot','$RUN_ROOT')"
