#!/bin/bash
#SBATCH --job-name=ann_trans_mech
#SBATCH --output=ann_trans_mech_%j.out
#SBATCH --error=ann_trans_mech_%j.err
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-02:00:00

set -euo pipefail

PROJECT_ROOT="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
bash "$PROJECT_ROOT/code/hpc/run_annual_transition_mechanism_scenarios.sh"
