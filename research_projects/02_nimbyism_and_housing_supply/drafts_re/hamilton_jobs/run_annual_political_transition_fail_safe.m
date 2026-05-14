function run_annual_political_transition_fail_safe(varargin)
% Local fail-safe annual transition smoke for political pressure pass-through.

p = inputParser;
p.addParameter('RunTag', '');
p.addParameter('TSchedule', [4]);
p.addParameter('VoteScale', 0.02);
p.addParameter('RestrictionCap', 0.25);
p.addParameter('MaxAbsLogPriceMove', 0.18);
p.addParameter('PeriodIter', 2);
p.addParameter('UpdateRelaxation', 0.75);
p.addParameter('LaggedPassThrough', false);
p.addParameter('PassThroughLagYears', 1);
p.addParameter('AgeWeightVariant', 'baseline');
p.addParameter('PressureMode', 'smooth');
p.addParameter('VoteRule', 'smooth_logit');
p.addParameter('VoteTau', NaN);
p.addParameter('VoteSigma', 0);
p.addParameter('VoteShiftMode', 'annual');
p.addParameter('VoteBlockLength', 1);
p.addParameter('DemographicScenario', 'source_path');
p.addParameter('DemographicPathMat', '');
p.addParameter('DemographicPathVar', 'ageimpulse');
p.addParameter('DemographicShockAmplitude', 0.25);
p.addParameter('PoliticalCandidates', []);
p.addParameter('Candidates', []); % Legacy alias for PoliticalCandidates.
p.addParameter('ModIrfDir', 'C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_IRF');
p.addParameter('SourceMat', 'loop101_output_extended.mat');
p.addParameter('ModFunctionsDir', 'D:\SteadyState\Mod_Functions');
p.addParameter('CompeconDir', 'C:\Users\Dave_\COMPECON');
p.parse(varargin{:});
cfg = p.Results;
cfg = normalize_political_candidate_config(cfg);

this_dir = fileparts(mfilename('fullpath'));
out_root = fullfile(this_dir, 'truth', 'annual_political_transition_fail_safe');
if ~exist(out_root, 'dir')
    mkdir(out_root);
end
if isempty(cfg.RunTag)
    cfg.RunTag = ['annual_transition_', datestr(now, 'yyyymmdd_HHMMSS')];
end
out_dir = fullfile(out_root, cfg.RunTag);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
status_path = fullfile(out_root, 'latest_status.json');
write_status(status_path, 'running', 'Initializing annual transition smoke.', cfg.RunTag, out_dir);

addpath(cfg.ModIrfDir, '-begin');
mod_parent = fileparts(cfg.ModIrfDir);
if exist(mod_parent, 'dir')
    addpath(mod_parent, '-begin');
end
if exist(cfg.ModFunctionsDir, 'dir')
    addpath(cfg.ModFunctionsDir, '-begin');
end
addpath(fullfile(cfg.CompeconDir, 'CEtools'), '-begin');
addpath(fullfile(cfg.CompeconDir, 'CEdemos'), '-begin');
addpath(fullfile(cfg.CompeconDir, 'compecon2011_64'), '-begin');

old_pwd = pwd;
cleanup = onCleanup(@() cd(old_pwd));
cd(cfg.ModIrfDir);

[base, age_share] = build_baseline(cfg);
age_share = apply_demographic_scenario(age_share, cfg, base);
all_summary = table();
all_paths = table();
all_age_paths = table();

for is = 1:numel(cfg.TSchedule)
    T = cfg.TSchedule(is);
    stage_tag = sprintf('T%d', T);
    write_status(status_path, 'running', sprintf('Running annual transition stage %s.', stage_tag), cfg.RunTag, out_dir);
    [stage_summary, stage_paths, stage_age_paths] = run_stage(cfg, base, age_share, T, status_path, out_dir);
    writetable(stage_summary, fullfile(out_dir, sprintf('summary_%s.csv', stage_tag)));
    writetable(stage_paths, fullfile(out_dir, sprintf('paths_%s.csv', stage_tag)));
    writetable(stage_age_paths, fullfile(out_dir, sprintf('age_paths_%s.csv', stage_tag)));
    all_summary = [all_summary; stage_summary]; %#ok<AGROW>
    all_paths = [all_paths; stage_paths]; %#ok<AGROW>
    all_age_paths = [all_age_paths; stage_age_paths]; %#ok<AGROW>
    if ~any(ismember(string(stage_summary.verdict), ["usable", "survivor"]))
        write_status(status_path, 'stopped', sprintf('Stopped after %s: no usable or survivor candidates.', stage_tag), cfg.RunTag, out_dir);
        writetable(all_summary, fullfile(out_dir, 'summary_all.csv'));
        writetable(all_paths, fullfile(out_dir, 'paths_all.csv'));
        writetable(all_age_paths, fullfile(out_dir, 'age_paths_all.csv'));
        write_note(fullfile(out_dir, 'note.md'), cfg, base, all_summary);
        return
    end
end

writetable(all_summary, fullfile(out_dir, 'summary_all.csv'));
writetable(all_paths, fullfile(out_dir, 'paths_all.csv'));
writetable(all_age_paths, fullfile(out_dir, 'age_paths_all.csv'));
write_note(fullfile(out_dir, 'note.md'), cfg, base, all_summary);
write_status(status_path, 'complete', 'Annual political transition fail-safe complete.', cfg.RunTag, out_dir);
disp('Annual political transition fail-safe complete.');
end

function cfg = normalize_political_candidate_config(cfg)
default_candidates = [0, 0.10, 1.00; 0, 0.06, 1.00; 0.50, 0.10, 0.50];
has_primary = ~isempty(cfg.PoliticalCandidates);
has_legacy = ~isempty(cfg.Candidates);
if has_primary && has_legacy && ~isequal(size(cfg.PoliticalCandidates), size(cfg.Candidates))
    error('PoliticalCandidates and legacy Candidates both supplied with different sizes.');
end
if has_primary && has_legacy && any(abs(cfg.PoliticalCandidates(:) - cfg.Candidates(:)) > 1e-12)
    error('PoliticalCandidates and legacy Candidates both supplied with different values.');
end
if ~has_primary
    if has_legacy
        cfg.PoliticalCandidates = cfg.Candidates;
    else
        cfg.PoliticalCandidates = default_candidates;
    end
end
if size(cfg.PoliticalCandidates, 2) ~= 3
    error('PoliticalCandidates must have three columns: political_persistence, political_pass_through, price_pass_through.');
end
cfg.Candidates = cfg.PoliticalCandidates; % Keep legacy wrappers/readers from breaking.
end

function [base, age_share] = build_baseline(cfg)
options = struct();
options.mod_data_path = fullfile(fileparts(cfg.ModIrfDir), 'Mod_Data', filesep);

source_path = cfg.SourceMat;
if ~isfile(source_path)
    source_path = fullfile(cfg.ModIrfDir, cfg.SourceMat);
end
source_vars = who('-file', source_path);
has_projection_baseline = all(ismember({'PriceHouse','VoteBaseline','indReference'}, source_vars));
if has_projection_baseline
    S = load(source_path, 'param', 'age_share', 'PriceHouse', 'VoteBaseline', 'indReference');
else
    S = load(source_path, 'param', 'age_share', 'agevector', 'TargetVote');
end
param = S.param;
age_share = S.age_share;

if ~has_projection_baseline && isfield(S, 'agevector')
    [~, ref_col] = min(sum(abs(age_share - S.agevector(:)), 1));
else
    ref_col = min(51, size(age_share, 2));
end
if ~has_projection_baseline && isfield(S, 'agevector')
    agevector0 = S.agevector(:);
else
    agevector0 = age_share(:, ref_col);
end
agevector0 = apply_age_weight_variant(agevector0, cfg.AgeWeightVariant);
if has_projection_baseline
    reference_price = S.PriceHouse(S.indReference);
    source_target_vote = S.VoteBaseline(ref_col, S.indReference);
else
    if isfield(param, 'Ph_ss')
        reference_price = param.Ph_ss;
    elseif isfield(param, 'Ph')
        reference_price = param.Ph;
    else
        error('Published-IRF source %s lacks param.Ph_ss/param.Ph.', source_path);
    end
    if isfield(S, 'TargetVote')
        source_target_vote = S.TargetVote;
    else
        source_target_vote = NaN;
    end
end

param.Ph = reference_price;
param.Ph_ss = reference_price;
param.Ph_prev = reference_price;
param.rA_ss = param.rA;
if isfield(param, 'kappa') && isfield(param, 'wages') && isfield(param, 'delta') && isfield(param, 'R')
    param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* param.Ph;
end

[param, glob, options] = setup_modelspace(param, options);
solved = solve_coeff(param, glob, options);

param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* param.Ph .* param.deltaPh;
param.Ph = param.Ph * param.deltaPh;
solved_higherPh = solve_coeff(param, glob, options);

param.Ph = param.Ph_ss;
param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* param.Ph;

VV_delta = max(max(solved_higherPh.policies.vVR(:), solved_higherPh.policies.vVA(:)), solved_higherPh.policies.vVN(:));
VV = max(max(solved.policies.vVR(:), solved.policies.vVA(:)), solved.policies.vVN(:));
vote_params = resolve_vote_params(cfg, VV_delta - VV);
VoteV = build_vote_matrix(solved, solved_higherPh, glob, param, vote_params);
param.Vote = VoteV;

eq = solve_statdist(solved, param, glob, options);
VoteAge = sum(eq.dist.L .* VoteV, 1);

base = struct();
base.param = param;
base.glob = glob;
base.options = options;
base.eq_ss = eq;
base.reference_price = reference_price;
base.source_target_vote = source_target_vote;
if strcmpi(cfg.AgeWeightVariant, 'baseline') && strcmpi(vote_params.rule, 'hard')
    base.target_vote = source_target_vote;
else
    base.target_vote = VoteAge * agevector0;
end
base.recomputed_target_vote = VoteAge * agevector0;
base.vote_params = vote_params;
base.reference_col = ref_col;
base.agevector0 = agevector0;
base.source_path = source_path;
base.mod_irf_dir = cfg.ModIrfDir;
end

function [summary, paths, age_paths] = run_stage(cfg, base, age_share, T, status_path, out_dir)
rows = {};
path_rows = {};
age_path_rows = {};
row_ix = 0;
path_ix = 0;
age_path_ix = 0;
for ic = 1:size(cfg.PoliticalCandidates, 1)
    political_persistence = cfg.PoliticalCandidates(ic, 1);
    political_pass_through = cfg.PoliticalCandidates(ic, 2);
    price_pass_through = cfg.PoliticalCandidates(ic, 3);
    row_ix = row_ix + 1;
    write_status(status_path, 'running', sprintf('Running T=%d candidate %d/%d.', T, ic, size(cfg.PoliticalCandidates, 1)), cfg.RunTag, out_dir);
    try
        [candidate_summary, candidate_paths, candidate_age_paths] = run_candidate(cfg, base, age_share, T, political_persistence, political_pass_through, price_pass_through, row_ix);
        rows(row_ix, :) = candidate_summary;
        for ip = 1:size(candidate_paths, 1)
            path_ix = path_ix + 1;
            path_rows(path_ix, :) = candidate_paths(ip, :);
        end
        for ip = 1:size(candidate_age_paths, 1)
            age_path_ix = age_path_ix + 1;
            age_path_rows(age_path_ix, :) = candidate_age_paths(ip, :);
        end
    catch ME
        rows(row_ix, :) = {T, row_ix, political_persistence, political_pass_through, price_pass_through, NaN, NaN, NaN, NaN, NaN, "error", ME.message};
    end
end

summary = cell2table(rows, 'VariableNames', {'T','candidate_id','political_persistence','political_pass_through','price_pass_through','max_abs_vote_resid','mean_abs_vote_resid','max_abs_log_price_move','max_abs_restriction','mean_homeownership','verdict','message'});
if isempty(path_rows)
    paths = table();
else
    paths = cell2table(path_rows, 'VariableNames', {'T','candidate_id','period','year','political_persistence','political_pass_through','price_pass_through','price','vote','vote_resid','pressure','restriction','homeownership','housing_demand','inner_iter'});
end
if isempty(age_path_rows)
    age_paths = table();
else
    age_paths = cell2table(age_path_rows, 'VariableNames', {'T','candidate_id','period','year','political_persistence','political_pass_through','price_pass_through','price','inner_iter','age_col_used','age_index','model_age','age_weight','B','C','H','Rent','NW','M','homeownership','hasmortgage'});
end
end

function [summary_row, path_rows, age_path_rows] = run_candidate(cfg, base, age_share, T, political_persistence, political_pass_through, price_pass_through, candidate_id)
eqprev = base.eq_ss;
restriction_prev = 0;
lag_years = max(1, round(cfg.PassThroughLagYears));
restriction_queue = zeros(lag_years, 1);
path_rows = {};
age_path_rows = {};
path_ix = 0;
age_path_ix = 0;
vote_resids = nan(T, 1);
prices = nan(T, 1);
restrictions = nan(T, 1);
homeownership = nan(T, 1);
model_ages = get_model_ages(base.param);
block_vote_mode = is_block_vote_mode(cfg);
block_len = max(1, ceil(cfg.VoteBlockLength));
block_vote = NaN;
block_vote_resid = NaN;
block_pressure = NaN;
block_restriction = NaN;

for t = 1:T
    age_col = min(base.reference_col + t, size(age_share, 2));
    agevector = age_share(:, age_col);
    agevector = apply_age_weight_variant(agevector, cfg.AgeWeightVariant);
    if cfg.LaggedPassThrough
        restriction = restriction_queue(1);
        price = base.reference_price * exp(price_pass_through * restriction);
        price = min(max(price, base.reference_price * exp(-cfg.MaxAbsLogPriceMove)), base.reference_price * exp(cfg.MaxAbsLogPriceMove));
        last = evaluate_period(base, eqprev, agevector, price);
        pressure = compute_pressure(last.vote_resid, cfg.VoteScale, cfg.PressureMode);
        restriction_target = political_persistence * restriction_prev + political_pass_through * pressure;
        restriction_target = min(max(restriction_target, -cfg.RestrictionCap), cfg.RestrictionCap);
        restriction_next = (1 - cfg.UpdateRelaxation) * restriction_prev + cfg.UpdateRelaxation * restriction_target;
        restriction_next = min(max(restriction_next, -cfg.RestrictionCap), cfg.RestrictionCap);

        vote_resids(t) = last.vote_resid;
        prices(t) = price;
        restrictions(t) = restriction;
        homeownership(t) = last.homeownership;
        path_ix = path_ix + 1;
        path_rows(path_ix, :) = {T, candidate_id, t, 2000 + t, political_persistence, political_pass_through, price_pass_through, price, last.vote, last.vote_resid, pressure, restriction, last.homeownership, last.housing_demand, 1};
        [age_path_rows, age_path_ix] = append_age_rows(age_path_rows, age_path_ix, T, candidate_id, t, 2000 + t, political_persistence, political_pass_through, price_pass_through, price, 1, age_col, agevector, model_ages, last.eq);
        eqprev = last.eq;
        restriction_prev = restriction_next;
        restriction_queue = [restriction_queue(2:end); restriction_next];
        continue
    end
    is_vote_period = ~block_vote_mode || mod(t - 1, block_len) == 0;
    if is_vote_period
        restriction = restriction_prev;
        last = [];
        inner_iter_used = cfg.PeriodIter;
        for ii = 1:cfg.PeriodIter
            price = base.reference_price * exp(price_pass_through * restriction);
            price = min(max(price, base.reference_price * exp(-cfg.MaxAbsLogPriceMove)), base.reference_price * exp(cfg.MaxAbsLogPriceMove));
            last = evaluate_period(base, eqprev, agevector, price);
            pressure = compute_pressure(last.vote_resid, cfg.VoteScale, cfg.PressureMode);
            restriction_target = political_persistence * restriction_prev + political_pass_through * pressure;
            restriction_target = min(max(restriction_target, -cfg.RestrictionCap), cfg.RestrictionCap);
            restriction = (1 - cfg.UpdateRelaxation) * restriction + cfg.UpdateRelaxation * restriction_target;
        end
        price = base.reference_price * exp(price_pass_through * restriction);
        price = min(max(price, base.reference_price * exp(-cfg.MaxAbsLogPriceMove)), base.reference_price * exp(cfg.MaxAbsLogPriceMove));
        last = evaluate_period(base, eqprev, agevector, price);
        pressure = compute_pressure(last.vote_resid, cfg.VoteScale, cfg.PressureMode);
        restriction_target = political_persistence * restriction_prev + political_pass_through * pressure;
        restriction = (1 - cfg.UpdateRelaxation) * restriction + cfg.UpdateRelaxation * restriction_target;
        restriction = min(max(restriction, -cfg.RestrictionCap), cfg.RestrictionCap);
        price = base.reference_price * exp(price_pass_through * restriction);
        price = min(max(price, base.reference_price * exp(-cfg.MaxAbsLogPriceMove)), base.reference_price * exp(cfg.MaxAbsLogPriceMove));
        last = evaluate_period(base, eqprev, agevector, price);
        pressure = compute_pressure(last.vote_resid, cfg.VoteScale, cfg.PressureMode);
        if block_vote_mode
            block_vote = last.vote;
            block_vote_resid = last.vote_resid;
            block_pressure = pressure;
            block_restriction = restriction;
        end
    else
        restriction = block_restriction;
        price = base.reference_price * exp(price_pass_through * restriction);
        price = min(max(price, base.reference_price * exp(-cfg.MaxAbsLogPriceMove)), base.reference_price * exp(cfg.MaxAbsLogPriceMove));
        last = evaluate_period(base, eqprev, agevector, price);
        pressure = block_pressure;
        inner_iter_used = 0;
    end

    if is_vote_period || ~block_vote_mode
        vote = last.vote;
        vote_resid = last.vote_resid;
    else
        vote = block_vote;
        vote_resid = block_vote_resid;
    end

    vote_resids(t) = vote_resid;
    prices(t) = price;
    restrictions(t) = restriction;
    homeownership(t) = last.homeownership;
    path_ix = path_ix + 1;
    path_rows(path_ix, :) = {T, candidate_id, t, 2000 + t, political_persistence, political_pass_through, price_pass_through, price, vote, vote_resid, pressure, restriction, last.homeownership, last.housing_demand, inner_iter_used};
    [age_path_rows, age_path_ix] = append_age_rows(age_path_rows, age_path_ix, T, candidate_id, t, 2000 + t, political_persistence, political_pass_through, price_pass_through, price, inner_iter_used, age_col, agevector, model_ages, last.eq);
    eqprev = last.eq;
    restriction_prev = restriction;
end

max_abs_vote = max(abs(vote_resids));
mean_abs_vote = mean(abs(vote_resids));
max_abs_log_price = max(abs(log(prices ./ base.reference_price)));
max_abs_restriction = max(abs(restrictions));
mean_homeownership = mean(homeownership);
[verdict, message] = classify_candidate(max_abs_vote, max_abs_log_price);
summary_row = {T, candidate_id, political_persistence, political_pass_through, price_pass_through, max_abs_vote, mean_abs_vote, max_abs_log_price, max_abs_restriction, mean_homeownership, verdict, message};
end

function out = evaluate_period(base, eqprev, agevector, price)
param = base.param;
glob = base.glob;
options = base.options;

param.Ph = price;
param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* price;
[param, glob, options] = setup_modelspace(param, options);
solved = solve_coeff(param, glob, options);

param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* price .* param.deltaPh;
param.Ph = price * param.deltaPh;
solved_higherPh = solve_coeff(param, glob, options);

param.Ph = price;
param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* price;
eq = solve_dyndist(solved, param, glob, options, eqprev);

VV_delta = max(max(solved_higherPh.policies.vVR(:), solved_higherPh.policies.vVA(:)), solved_higherPh.policies.vVN(:));
VV = max(max(solved.policies.vVR(:), solved.policies.vVA(:)), solved.policies.vVN(:));
VoteV = build_vote_matrix(solved, solved_higherPh, glob, param, base.vote_params);
param.Vote = VoteV;

VoteAge = sum(eq.dist.L .* VoteV, 1);
housing_by_age = sum(eq.dist.L .* eq.dist.hprime_dist, 1);
out = struct();
out.eq = eq;
out.vote = VoteAge * agevector;
out.vote_resid = out.vote - base.target_vote;
out.homeownership = eq.age.homeownership' * agevector;
out.housing_demand = housing_by_age * agevector;
end

function vote_params = resolve_vote_params(cfg, value_gap)
vote_params = struct();
vote_params.rule = char(lower(string(cfg.VoteRule)));
vote_params.sigma = cfg.VoteSigma;
vote_params.tau = cfg.VoteTau;
if isnan(vote_params.tau)
    vote_params.tau = infer_vote_tau(value_gap);
end
vote_params.tau = max(vote_params.tau, 1e-10);
end

function tau = infer_vote_tau(value_gap)
abs_gap = abs(value_gap(:));
abs_gap = abs_gap(isfinite(abs_gap) & abs_gap > 0);
if isempty(abs_gap)
    tau = 1e-4;
    return
end
tau = max(prctile(abs_gap, 10), 1e-10);
end

function VoteV = build_vote_matrix(solved, solved_shift, glob, param, vote_params)
VV_delta = max(max(solved_shift.policies.vVR(:), solved_shift.policies.vVA(:)), solved_shift.policies.vVN(:));
VV = max(max(solved.policies.vVR(:), solved.policies.vVA(:)), solved.policies.vVN(:));
gap = VV_delta - VV + vote_params.sigma;
switch lower(string(vote_params.rule))
    case "hard"
        VoteV = gap >= 0;
    case {"smooth_logit", "logit"}
        z = max(-40, min(40, gap ./ vote_params.tau));
        VoteV = 1 ./ (1 + exp(-z));
    case {"smooth_tanh", "tanh"}
        VoteV = 0.5 + 0.5 .* tanh(gap ./ (2 .* vote_params.tau));
    otherwise
        error('Unknown VoteRule: %s', vote_params.rule);
end
VoteV = reshape(VoteV, [glob.Nb * glob.Nh * glob.Ny, param.J + 1]);
VoteV = VoteV(:, 1:end-1);
end

function model_ages = get_model_ages(param)
model_ages = (25:(25 + param.J - 1))';
if isfield(param, 'ages')
    model_ages = param.ages(:);
end
end

function [age_path_rows, age_path_ix] = append_age_rows(age_path_rows, age_path_ix, T, candidate_id, period, year, political_persistence, political_pass_through, price_pass_through, price, inner_iter, age_col, agevector, model_ages, eq)
for jj = 1:numel(model_ages)
    age_path_ix = age_path_ix + 1;
    age_path_rows(age_path_ix, :) = {T, candidate_id, period, year, political_persistence, political_pass_through, price_pass_through, price, inner_iter, age_col, jj, model_ages(jj), agevector(jj), eq.age.B(jj), eq.age.C(jj), eq.age.H(jj), eq.age.Rent(jj), eq.age.NW(jj), eq.age.M(jj), eq.age.homeownership(jj), eq.age.hasmortgage(jj)};
end
end

function [verdict, message] = classify_candidate(max_abs_vote, max_abs_log_price)
if max_abs_log_price >= 0.179
    verdict = "dead";
    message = "hit price movement cap";
elseif max_abs_vote <= 0.015
    verdict = "usable";
    message = "low vote residual";
elseif max_abs_vote <= 0.035
    verdict = "survivor";
    message = "moderate vote residual";
else
    verdict = "dead";
    message = "vote residual too large";
end
end

function pressure = compute_pressure(vote_resid, vote_scale, pressure_mode)
switch lower(string(pressure_mode))
    case "smooth"
        pressure = tanh(vote_resid / vote_scale);
    case "hard_sign"
        pressure = sign(vote_resid);
    otherwise
        error('Unknown PressureMode: %s', pressure_mode);
end
end

function tf = is_block_vote_mode(cfg)
mode = lower(string(cfg.VoteShiftMode));
tf = any(mode == ["block_vote", "periodic_block", "periodic_vote", "four_year_vote", "five_year_vote"]);
end

function agevector = apply_age_weight_variant(agevector, variant)
agevector = max(agevector(:), 0);
variant = lower(string(variant));
switch variant
    case "baseline"
        % Use annual age weights as supplied by the annual LOOP input.
    case "terminal_half"
        agevector(end) = 0.5 * agevector(end);
    case "terminal_drop"
        agevector(end) = 0;
    otherwise
        error('Unknown AgeWeightVariant: %s', variant);
end
total = sum(agevector);
if total <= 0
    error('AgeWeightVariant %s produced zero age mass.', variant);
end
agevector = agevector ./ total;
end

function age_share_out = apply_demographic_scenario(age_share, cfg, base)
scenario = lower(string(cfg.DemographicScenario));
age_share_out = age_share;
if any(scenario == ["source_path", "baseline", "historical", "none"])
    return
end
if any(scenario == ["external_age_path", "published_baby_boom"])
    path_mat = cfg.DemographicPathMat;
    if isempty(path_mat) && scenario == "published_baby_boom"
        path_mat = fullfile(base.mod_irf_dir, 'irfs_100.mat');
    end
    if isempty(path_mat)
        error('DemographicPathMat is required when DemographicScenario is external_age_path.');
    end
    E = load(path_mat, cfg.DemographicPathVar);
    if ~isfield(E, cfg.DemographicPathVar)
        error('DemographicPathVar %s not found in %s.', cfg.DemographicPathVar, path_mat);
    end
    external_path = double(E.(cfg.DemographicPathVar));
    if size(external_path, 1) ~= size(age_share, 1)
        error('External demographic path has %d ages, expected %d.', size(external_path, 1), size(age_share, 1));
    end
    n_forward = min(size(external_path, 2), size(age_share_out, 2) - base.reference_col);
    if n_forward <= 0
        error('External demographic path has no usable forward columns.');
    end
    for t = 1:n_forward
        age_share_out(:, base.reference_col + t) = normalize_agevector(external_path(:, t));
    end
    return
end

first_col = base.reference_col;
n_ages = size(age_share, 1);
n_cols = size(age_share, 2);
n_forward = n_cols - first_col + 1;
if n_forward <= 1
    return
end

population = zeros(n_ages, n_forward);
population(:, 1) = normalize_agevector(age_share(:, first_col));
entrant_scale = build_annual_entrant_scale(n_forward, scenario, cfg.DemographicShockAmplitude);
survival = default_annual_survival_rates(n_ages);

for t = 2:n_forward
    population(1, t) = population(1, 1) * entrant_scale(t);
    for ia = 1:(n_ages - 1)
        population(ia + 1, t) = survival(ia) * population(ia, t - 1);
    end
    population(:, t) = normalize_agevector(population(:, t));
end

age_share_out(:, first_col:n_cols) = population;
end

function entrant_scale = build_annual_entrant_scale(n_forward, scenario, amplitude)
amplitude = max(0, amplitude);
x = (1:n_forward)';
switch scenario
    case {"flat_entrant", "flat"}
        entrant_scale = ones(n_forward, 1);
    case {"baby_boom", "boom", "temporary_boom"}
        center = max(2, min(n_forward, round(0.30 * n_forward)));
        width = max(3.0, 0.10 * n_forward);
        entrant_scale = 1.0 + amplitude .* exp(-0.5 .* ((x - center) ./ width).^2);
    case {"secular_decline", "decline", "birth_decline"}
        entrant_scale = linspace(1.0, max(0.05, 1.0 - amplitude), n_forward)';
    otherwise
        error('Unknown DemographicScenario: %s', scenario);
end
end

function survival = default_annual_survival_rates(n_ages)
ages = (25:(25 + n_ages - 1))';
survival = ones(n_ages, 1);
for i = 1:n_ages
    age = ages(i);
    if age < 50
        survival(i) = 0.998;
    elseif age < 65
        survival(i) = 0.994;
    elseif age < 75
        survival(i) = 0.980;
    elseif age < 85
        survival(i) = 0.940;
    else
        survival(i) = 0.880;
    end
end
survival(end) = 0;
end

function agevector = normalize_agevector(agevector)
agevector = max(agevector(:), 0);
total = sum(agevector);
if total <= 0
    error('Demographic scenario produced zero age mass.');
end
agevector = agevector ./ total;
end

function write_note(note_path, cfg, base, summary)
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Annual political transition fail-safe result\n\n');
fprintf(fid, '- reference price: `%.6f`\n', base.reference_price);
fprintf(fid, '- target vote: `%.6f`\n', base.target_vote);
fprintf(fid, '- source target vote: `%.6f`\n', base.source_target_vote);
fprintf(fid, '- recomputed baseline vote: `%.6f`\n', base.recomputed_target_vote);
fprintf(fid, '- source: `%s`\n', base.source_path);
fprintf(fid, '- vote scale: `%.6f`\n', cfg.VoteScale);
fprintf(fid, '- vote rule: `%s`\n', base.vote_params.rule);
fprintf(fid, '- vote tau: `%.12g`\n', base.vote_params.tau);
fprintf(fid, '- vote sigma: `%.12g`\n', base.vote_params.sigma);
fprintf(fid, '- pressure mode: `%s`\n', cfg.PressureMode);
fprintf(fid, '- demographic scenario: `%s`\n', cfg.DemographicScenario);
fprintf(fid, '- demographic shock amplitude: `%.6f`\n', cfg.DemographicShockAmplitude);
fprintf(fid, '- period iterations: `%d`\n\n', cfg.PeriodIter);
fprintf(fid, '- lagged pass-through: `%d`\n\n', cfg.LaggedPassThrough);
fprintf(fid, '- pass-through lag years: `%d`\n\n', cfg.PassThroughLagYears);
fprintf(fid, '- vote shift mode: `%s`\n\n', cfg.VoteShiftMode);
fprintf(fid, '- vote block length: `%d`\n\n', cfg.VoteBlockLength);
fprintf(fid, '- age weight variant: `%s`\n\n', cfg.AgeWeightVariant);
fprintf(fid, '## Summary\n\n');
fprintf(fid, '| T | verdict | political persistence | political pass-through | price pass-through | max abs vote residual | max abs log price move | mean homeownership |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(summary)
    fprintf(fid, '| %d | %s | %.3f | %.3f | %.3f | %.6f | %.6f | %.6f |\n', ...
        summary.T(i), string(summary.verdict(i)), summary.political_persistence(i), summary.political_pass_through(i), summary.price_pass_through(i), ...
        summary.max_abs_vote_resid(i), summary.max_abs_log_price_move(i), summary.mean_homeownership(i));
end
end

function write_status(status_path, state, message, run_tag, out_dir)
fid = fopen(status_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '{"state":"%s","message":"%s","run_tag":"%s","output_dir":"%s","updated_at":"%s"}\n', ...
    state, escape_json(message), run_tag, strrep(out_dir, '\', '\\'), datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
end

function s = escape_json(s)
s = strrep(s, '\', '\\');
s = strrep(s, '"', '\"');
end
