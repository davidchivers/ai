#!/bin/bash
#SBATCH -J nore80bv4
#SBATCH -p shared
#SBATCH -t 04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --array=0-2
#SBATCH -o logs/nore80bv4_%A_%a.out
#SBATCH -e logs/nore80bv4_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

PASS=("0.006" "0.012" "0.018")
LABEL=("006" "012" "018")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_annual_political_transition_fail_safe('RunTag',['nore80bv4_' '${LABEL[$IDX]}'],'TSchedule',[20 80],'VoteScale',0.02,'RestrictionCap',0.25,'MaxAbsLogPriceMove',0.18,'PeriodIter',3,'UpdateRelaxation',0.75,'LaggedPassThrough',false,'AgeWeightVariant','baseline','PressureMode','smooth','VoteRule','smooth_logit','VoteTau',NaN,'VoteSigma',0,'VoteShiftMode','block_vote','VoteBlockLength',4,'SourceMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','old_paper_source_min.mat'),'DemographicScenario','published_baby_boom','DemographicPathMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','irfs_100.mat'),'DemographicPathVar','ageimpulse','DemographicShockAmplitude',0.25,'PoliticalCandidates',[0,-str2double('${PASS[$IDX]}'),1],'ModIrfDir',fullfile('$RUN_ROOT','SteadyState','Mod_IRF'),'ModFunctionsDir',fullfile('$RUN_ROOT','SteadyState','Mod_Functions'),'CompeconDir',fullfile('$RUN_ROOT','COMPECON'))"
