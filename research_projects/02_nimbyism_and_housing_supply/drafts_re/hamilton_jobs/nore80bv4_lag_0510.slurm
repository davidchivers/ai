#!/bin/bash
# Four-year block-vote no-RE lag robustness.
# Purpose: test whether delayed pass-through / time-to-build style delivery
# changes the T80 no-RE comparator for the usable pass-through magnitudes.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J nore80bvl
#SBATCH -p shared
#SBATCH -t 04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --array=0-5
#SBATCH -o logs/nore80bvl_%A_%a.out
#SBATCH -e logs/nore80bvl_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("nore80bv4lag_p006_l1" "nore80bv4lag_p006_l2" "nore80bv4lag_p006_l4" "nore80bv4lag_p012_l1" "nore80bv4lag_p012_l2" "nore80bv4lag_p012_l4")
PASS=("0.006" "0.006" "0.006" "0.012" "0.012" "0.012")
LAG=("1" "2" "4" "1" "2" "4")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_annual_political_transition_fail_safe('RunTag','${RUN_TAGS[$IDX]}','TSchedule',[20 80],'VoteScale',0.02,'RestrictionCap',0.25,'MaxAbsLogPriceMove',0.18,'PeriodIter',3,'UpdateRelaxation',0.75,'LaggedPassThrough',true,'PassThroughLagYears',str2double('${LAG[$IDX]}'),'AgeWeightVariant','baseline','PressureMode','smooth','VoteRule','smooth_logit','VoteTau',NaN,'VoteSigma',0,'VoteShiftMode','block_vote','VoteBlockLength',4,'SourceMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','old_paper_source_min.mat'),'DemographicScenario','published_baby_boom','DemographicPathMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','irfs_100.mat'),'DemographicPathVar','ageimpulse','DemographicShockAmplitude',0.25,'PoliticalCandidates',[0,-str2double('${PASS[$IDX]}'),1],'ModIrfDir',fullfile('$RUN_ROOT','SteadyState','Mod_IRF'),'ModFunctionsDir',fullfile('$RUN_ROOT','SteadyState','Mod_Functions'),'CompeconDir',fullfile('$RUN_ROOT','COMPECON'))"
