#!/bin/bash
#SBATCH -J obnr1
#SBATCH -p shared
#SBATCH -t 8:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=18G
#SBATCH -o logs/obnr1_%A_%a.out
#SBATCH -e logs/obnr1_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

case "${SLURM_ARRAY_TASK_ID:-0}" in
  0)
    PHI="-0.006"
    RUN_TAG="obn006_0505"
    ;;
  1)
    PHI="-0.012"
    RUN_TAG="obn012_0505"
    ;;
  2)
    PHI="-0.020"
    RUN_TAG="obn020_0505"
    ;;
  *)
    echo "Unknown SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}" >&2
    exit 2
    ;;
esac

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs"
cd "$RUN_ROOT/annual"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; run_annual_political_transition_fail_safe('RunTag','$RUN_TAG','TSchedule',[80],'PeriodIter',4,'LaggedPassThrough',false,'PassThroughLagYears',1,'AgeWeightVariant','baseline','PressureMode','smooth','VoteRule','smooth_logit','VoteTau',NaN,'VoteSigma',0,'SourceMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','old_paper_source_min.mat'),'DemographicScenario','published_baby_boom','DemographicPathMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','irfs_100.mat'),'DemographicPathVar','ageimpulse','DemographicShockAmplitude',0.25,'VoteScale',0.02,'Candidates',[0 $PHI 1.00],'ModIrfDir',fullfile('$RUN_ROOT','SteadyState','Mod_IRF'),'ModFunctionsDir',fullfile('$RUN_ROOT','SteadyState','Mod_Functions'),'CompeconDir',fullfile('$RUN_ROOT','COMPECON'))"
