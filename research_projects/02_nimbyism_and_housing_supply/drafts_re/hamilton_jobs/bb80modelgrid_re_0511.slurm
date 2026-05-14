#!/bin/bash
# First-wave defensible T80 RE model grid.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80mg11
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --array=1-12
#SBATCH -o logs/bb80mg11_%A_%a.out
#SBATCH -e logs/bb80mg11_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

# The local repository keeps the current solver under a dated filename; copy it
# to the function name MATLAB expects inside this isolated Hamilton directory.
cp -f run_annual_political_full_re_price_path_basis_0507.m run_annual_political_full_re_price_path.m

matlab -singleCompThread -batch "addpath(pwd); addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_t80_model_grid_0511(str2double(getenv('SLURM_ARRAY_TASK_ID')),'GridCsv',fullfile(pwd,'model_grid_0511.csv'),'RunRoot','$RUN_ROOT')"
