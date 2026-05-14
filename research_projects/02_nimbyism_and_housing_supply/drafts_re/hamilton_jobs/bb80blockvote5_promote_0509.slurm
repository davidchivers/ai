#!/bin/bash
# T80 promotion from the exact winning T20 five-year block-vote branch:
# bv5_rbguess_p0060 outer 8, max path gap 0.000814013782239463.
# Submit from: /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual

#SBATCH -J bb80bv5
#SBATCH -p shared
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --array=0-2
#SBATCH -o logs/bb80bv5_%A_%a.out
#SBATCH -e logs/bb80bv5_%A_%a.err

set -euo pipefail
module load matlab/R2025a
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs" "$RUN_ROOT/annual/logs"
cd "$RUN_ROOT/annual"

RUN_TAGS=("bv80rbguess_o8_d018" "bv80rbguess_o8_d022" "bv80rbguess_o8_d026")
BROYDEN_DAMP=("0.18" "0.22" "0.26")
BROYDEN_CAP=("0.0018" "0.0022" "0.0028")
BASIS_CAP=("0.00024" "0.00032" "0.00040")
OUTER_ITER=("18" "20" "22")
IDX="$SLURM_ARRAY_TASK_ID"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; seed_dir=fullfile('$RUN_ROOT','annual','truth','annual_political_full_re_price_path','t80_seeds'); if ~exist(seed_dir,'dir'), mkdir(seed_dir); end; seed=fullfile(seed_dir,'bv5_rbguess_p0060_outer8_seed.csv'); paths=readtable(fullfile('$RUN_ROOT','annual','truth','annual_political_full_re_price_path','bv5_rbguess_p0060','paths_all.csv')); paths=paths(paths.outer_iter==8,:); paths=sortrows(paths,'period'); if isempty(paths), error('Missing bv5_rbguess_p0060 outer 8 seed rows'); end; writetable(table(paths.price_generated,'VariableNames',{'price'}),seed); run_annual_political_full_re_price_path('RunTag','${RUN_TAGS[$IDX]}','T',80,'TailYears',20,'TerminalAnchor','terminal_fixed_point','TerminalIter',160,'TerminalRelaxation',0.12,'TerminalBlendWeight',1.00,'OuterIter',str2double('${OUTER_ITER[$IDX]}'),'PathRelaxation',0.02,'PathUpdateMethod','basis_broyden','BasisDim',8,'BasisDamping',0.25,'BasisStepCap',str2double('${BASIS_CAP[$IDX]}'),'BasisRidge',1e-8,'BasisEndWeight',10,'BasisTailWeight',0.12,'BasisFocusStart',6,'BasisFocusEnd',8,'BasisFocusWeight',8,'BroydenDamping',str2double('${BROYDEN_DAMP[$IDX]}'),'BroydenStepCap',str2double('${BROYDEN_CAP[$IDX]}'),'PoliticalPassThrough',-0.006,'VoteScale',0.02,'VoteRule','smooth_logit','VoteTau',NaN,'VoteSigma',0,'VoteShiftMode','block_vote','VoteShiftHorizon',5,'VoteBlockLength',5,'SourceMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','old_paper_source_min.mat'),'DemographicScenario','published_baby_boom','DemographicPathMat',fullfile('$RUN_ROOT','SteadyState','Mod_IRF','irfs_100.mat'),'DemographicPathVar','ageimpulse','DemographicShockAmplitude',0.25,'ReferenceYear',NaN,'InitialPathCsv',seed,'ModIrfDir',fullfile('$RUN_ROOT','SteadyState','Mod_IRF'),'ModFunctionsDir',fullfile('$RUN_ROOT','SteadyState','Mod_Functions'),'CompeconDir',fullfile('$RUN_ROOT','COMPECON'))"
