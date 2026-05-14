#!/bin/bash
#SBATCH --job-name=annual_nimby
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --output=annual_nimby_%j.out
#SBATCH --error=annual_nimby_%j.err

set -euo pipefail

module purge
module load matlab
unset OMP_PLACES
unset OMP_PROC_BIND

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# To resume only the current heavy step, uncomment:
# export START_AT_STEP=4
# export END_AT_STEP=4

bash "$SCRIPT_DIR/run_annual_nimby_workflow.sh"
