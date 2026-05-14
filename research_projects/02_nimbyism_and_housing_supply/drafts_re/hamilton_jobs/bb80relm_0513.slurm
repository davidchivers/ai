#!/bin/bash
# Future fallback only: sequential black-box LM residual minimization for full-T80 RE.
# Do not submit while bb80safe13 / job 17145335 is live.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80relm13
#SBATCH -p shared
#SBATCH -t 13:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH -o logs/bb80relm13_%j.out
#SBATCH -e logs/bb80relm13_%j.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

cp -f run_annual_political_full_re_price_path_safeguard_0513.m run_annual_political_full_re_price_path.m

matlab -singleCompThread -batch "addpath(pwd); addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_re_lm_0513('RunRoot','$RUN_ROOT','RunTag','lm80_from_w80_b60hold_o4','SourceRunTag','w80_b60hold_bl70','SourceOuter',4,'SourcePriceColumn','price_guess','MaxLmIter',3)"

python3 rank_re_wide_0512.py \
  --annual-dir . \
  --grid truth/re_lm_0513/lm80_from_w80_b60hold_o4_grid.csv \
  --out-dir truth/re_lm_0513/ranked

set +e
python3 closeout_re_safeguard_0513.py \
  --annual-dir . \
  --grid truth/re_lm_0513/lm80_from_w80_b60hold_o4_grid.csv \
  --rank-out-dir truth/re_lm_0513/ranked \
  --figure-out-dir truth/re_lm_0513/figure \
  --failure-memo truth/re_lm_0513/full_t80_re_lm_failure_memo_0513.md \
  --packet-label "LM/Gauss-Newton fallback" \
  --method-summary "continuation, bridge, basis-projection, residual-focus, safeguarded fixed-point, and LM/Gauss-Newton residual-minimization searches" \
  --no-next-solver-section \
  --final
closeout_rc=$?
set -e
if [[ "$closeout_rc" == "0" ]]; then
  echo "LM fallback produced a usable full-T80 RE row and guarded figure."
elif [[ "$closeout_rc" == "2" ]]; then
  echo "LM fallback finished without a usable full-T80 RE row; failure memo written."
else
  echo "LM fallback closeout returned unexpected code ${closeout_rc}."
  exit "$closeout_rc"
fi
