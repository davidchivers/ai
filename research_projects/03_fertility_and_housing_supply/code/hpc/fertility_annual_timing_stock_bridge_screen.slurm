#!/bin/bash
#SBATCH --job-name=ann_fert_bridge
#SBATCH --output=ann_fert_bridge_%j.out
#SBATCH --error=ann_fert_bridge_%j.err
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=0-18:00:00

set -euo pipefail

module purge
module load matlab
unset OMP_PLACES
unset OMP_PROC_BIND

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
bash "$SCRIPT_DIR/run_fertility_annual_timing_stock_bridge_screen.sh"
