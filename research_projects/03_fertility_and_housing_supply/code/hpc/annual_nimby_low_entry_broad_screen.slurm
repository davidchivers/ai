#!/bin/bash
#SBATCH --job-name=ann_low_entry_broad
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --output=ann_low_entry_broad_%j.out
#SBATCH --error=ann_low_entry_broad_%j.err

set -euo pipefail

module purge
module load matlab
unset OMP_PLACES
unset OMP_PROC_BIND

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

bash "$SCRIPT_DIR/run_annual_nimby_low_entry_broad_screen.sh"
