#!/bin/bash
# Eight-hour parallel RE alternatives packet.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80alt12
#SBATCH -p shared
#SBATCH -t 08:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --array=1-18
#SBATCH -o logs/bb80alt12_%A_%a.out
#SBATCH -e logs/bb80alt12_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

cp -f run_annual_political_full_re_price_path_basis_0507.m run_annual_political_full_re_price_path.m

matlab -singleCompThread -batch "addpath(pwd); addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_re_alt_0512(str2double(getenv('SLURM_ARRAY_TASK_ID')),'GridCsv',fullfile(pwd,'model_re_alt_0512.csv'),'RunRoot','$RUN_ROOT')"
