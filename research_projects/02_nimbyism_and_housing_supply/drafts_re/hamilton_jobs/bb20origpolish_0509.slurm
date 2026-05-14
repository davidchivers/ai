#!/bin/bash
# Original path-shift RE near-miss polish packet.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20opol
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-7
#SBATCH -o logs/bb20opol_%A_%a.out
#SBATCH -e logs/bb20opol_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("opol_rbguess_f7e" "opol_rbguess_r25" "opol_rbend4_micro" "opol_rbrend1_micro" "opol_brh7_f7e" "opol_rbr50_micro" "opol_rbrep25_micro" "opol_rbref_micro")
SOURCE_TAGS=("rb20guess_k8" "rb20guess_k8" "rb20end50_k8" "rbr20end100_k8" "brh20d80c005_p0060" "rbr20end50_k8" "rb20report25_k8" "rb20ref_end50")
SOURCE_OUTERS=("2" "2" "4" "1" "7" "1" "3" "4")
SEED_MODES=("guess" "report25" "guess" "guess" "guess" "guess" "guess" "guess")
BASIS_DIM=("10" "10" "10" "10" "10" "10" "10" "10")
BROYDEN_DAMP=("0.18" "0.16" "0.12" "0.10" "0.16" "0.12" "0.12" "0.12")
BROYDEN_CAP=("0.0025" "0.0020" "0.0015" "0.0012" "0.0020" "0.0015" "0.0015" "0.0015")
BASIS_CAP=("0.00025" "0.00022" "0.00018" "0.00015" "0.00022" "0.00018" "0.00018" "0.00018")
END_WEIGHT=("8" "8" "10" "10" "8" "10" "10" "10")
FOCUS_WEIGHT=("8" "8" "6" "6" "8" "6" "6" "6")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_bb20_basis_root_0508('RunTag','${RUN_TAGS[$IDX]}','SourceRunTag','${SOURCE_TAGS[$IDX]}','SourceOuter',str2double('${SOURCE_OUTERS[$IDX]}'),'SeedMode','${SEED_MODES[$IDX]}','TailYears',20,'TerminalAnchor','terminal_fixed_point','TerminalBlendWeight',1.00,'OuterIter',22,'BasisDim',str2double('${BASIS_DIM[$IDX]}'),'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisEndWeight',str2double('${END_WEIGHT[$IDX]}'),'BasisTailWeight',0.12,'BasisFocusStart',6,'BasisFocusEnd',8,'BasisFocusWeight',str2double('${FOCUS_WEIGHT[$IDX]}'),'PoliticalPassThrough',-0.006,'VoteShiftMode','path_shift','RunRoot','$RUN_ROOT')"
