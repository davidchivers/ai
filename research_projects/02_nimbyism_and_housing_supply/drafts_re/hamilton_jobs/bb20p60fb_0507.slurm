#!/bin/bash
# Narrow fallback for the baby-boom T20 full p0060 RE fixed point.
# Starts from the best existing full-p0060 Broyden path and tries more
# conservative update rules instead of rerunning the easier homotopy stages.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb20p60fb
#SBATCH -p shared
#SBATCH -t 08:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --array=0-5
#SBATCH -o logs/bb20p60fb_%A_%a.out
#SBATCH -e logs/bb20p60fb_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("fb20b20c0015" "fb20b30c0020" "fb20b40c0025" "fb20r003" "fb20r005" "fb20aa4d25")
METHODS=("broyden" "broyden" "broyden" "relaxation" "relaxation" "anderson")
RELAX=("0.04" "0.05" "0.06" "0.03" "0.05" "0.04")
BROYDEN_DAMP=("0.20" "0.30" "0.40" "0.00" "0.00" "0.00")
BROYDEN_CAP=("0.0015" "0.0020" "0.0025" "0.0010" "0.0010" "0.0010")
AA_MEMORY=("4" "4" "4" "4" "4" "4")
AA_DAMP=("0.25" "0.25" "0.25" "0.25" "0.25" "0.25")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; seed=fullfile('$RUN_ROOT','annual','truth','annual_political_full_re_price_path','seed_p0060_best_d80o7.csv'); paths=readtable(fullfile('$RUN_ROOT','annual','truth','annual_political_full_re_price_path','brh20d80c005_p0060','paths_all.csv')); paths=paths(paths.outer_iter==7,:); paths=sortrows(paths,'period'); writetable(table(paths.price_generated,'VariableNames',{'price'}),seed); run_annual_political_full_re_price_path('RunTag','${RUN_TAGS[$IDX]}','T',20,'TailYears',20,'TerminalAnchor','terminal_fixed_point','TerminalIter',60,'TerminalRelaxation',0.25,'OuterIter',24,'PathRelaxation',str2double('${RELAX[$IDX]}'),'PathUpdateMethod','${METHODS[$IDX]}','AndersonMemory',str2double('${AA_MEMORY[$IDX]}'),'AndersonDamping',str2double('${AA_DAMP[$IDX]}'),'AndersonRidge',1e-8,'AndersonCoeffCap',10,'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'PoliticalPassThrough',-0.006,'VoteScale',0.02,'VoteRule','smooth_logit','VoteTau',NaN,'VoteSigma',0,'VoteShiftMode','path_shift','SourceMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','old_paper_source_min.mat'),'DemographicScenario','published_baby_boom','DemographicPathMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','irfs_100.mat'),'DemographicPathVar','ageimpulse','DemographicShockAmplitude',0.25,'ReferenceYear',NaN,'InitialPathCsv',seed,'ModIrfDir',fullfile('$RUN_ROOT','SteadyState','Mod_IRF'),'ModFunctionsDir',fullfile('$RUN_ROOT','SteadyState','Mod_Functions'),'CompeconDir',fullfile('$RUN_ROOT','COMPECON'))"
