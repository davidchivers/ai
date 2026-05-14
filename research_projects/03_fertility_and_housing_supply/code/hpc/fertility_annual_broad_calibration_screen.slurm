#!/bin/bash
#SBATCH --job-name=ann_fert_cal
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --output=ann_fert_cal_%j.out
#SBATCH --error=ann_fert_cal_%j.err

set -euo pipefail

module purge
module load matlab
unset OMP_PLACES
unset OMP_PROC_BIND

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

bash "$SCRIPT_DIR/run_fertility_annual_broad_calibration_screen.sh"
