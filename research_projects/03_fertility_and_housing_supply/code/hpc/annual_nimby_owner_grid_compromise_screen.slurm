#!/bin/bash
#SBATCH --job-name=ann_owner_grid
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --output=ann_owner_grid_%j.out
#SBATCH --error=ann_owner_grid_%j.err

set -euo pipefail

module purge
module load matlab
unset OMP_PLACES
unset OMP_PROC_BIND

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

bash "$SCRIPT_DIR/run_annual_nimby_owner_grid_compromise_screen.sh"
