function run_annual_political_full_re_price_path(varargin)
% Perfect-foresight transition over the house-price path.
%
% Demographics are exogenous. The aggregate object households forecast is the
% future house-price path. If demographics are flat, the price path should stay
% at the steady-state reference price.

p = inputParser;
p.addParameter('RunTag', '');
p.addParameter('T', 4);
p.addParameter('TailYears', 20);
p.addParameter('TerminalAnchor', 'reference');
p.addParameter('TerminalIter', 20);
p.addParameter('TerminalRelaxation', 0.25);
p.addParameter('OuterIter', 2);
p.addParameter('PathRelaxation', 0.50);
p.addParameter('Eta', 0.090);
p.addParameter('VoteScale', 0.020);
p.addParameter('MaxAbsLogPriceMove', 0.18);
p.addParameter('PressureMode', 'smooth');
p.addParameter('DemographicScenario', 'fixed_age_share');
p.addParameter('DemographicShockAmplitude', 0.25);
p.addParameter('AgeWeightVariant', 'baseline');
p.addParameter('ReferenceYear', NaN);
p.addParameter('InitialPathCsv', '');
p.addParameter('ModIrfDir', 'C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_IRF');
p.addParameter('SourceMat', 'loop101_output_extended.mat');
p.addParameter('ModFunctionsDir', 'D:\SteadyState\Mod_Functions');
p.addParameter('CompeconDir', 'C:\Users\Dave_\COMPECON');
p.parse(varargin{:});
cfg = p.Results;
cfg.ReportT = cfg.T;
cfg.InternalT = cfg.T + cfg.TailYears;

this_dir = fileparts(mfilename('fullpath'));
out_root = fullfile(this_dir, 'truth', 'annual_political_full_re_price_path');
if ~exist(out_root, 'dir')
    mkdir(out_root);
end
if isempty(cfg.RunTag)
    cfg.RunTag = ['annual_full_re_', datestr(now, 'yyyymmdd_HHMMSS')];
end
out_dir = fullfile(out_root, cfg.RunTag);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
status_path = fullfile(out_root, 'latest_status.json');
write_status(status_path, 'running', 'Initializing full price-path RE transition.', cfg.RunTag, out_dir);

addpath(cfg.ModIrfDir);
if exist(cfg.ModFunctionsDir, 'dir')
    addpath(cfg.ModFunctionsDir);
end
addpath(fullfile(cfg.CompeconDir, 'CEtools'));
addpath(fullfile(cfg.CompeconDir, 'CEdemos'));
addpath(fullfile(cfg.CompeconDir, 'compecon2011_64'));

old_pwd = pwd;
cleanup = onCleanup(@() cd(old_pwd));
cd(cfg.ModIrfDir);

[base, age_share] = build_baseline(cfg);
age_share = apply_demographic_scenario(age_share, cfg, base);
T = cfg.InternalT;

if ~isempty(cfg.InitialPathCsv) && isfile(cfg.InitialPathCsv)
    init_tbl = readtable(cfg.InitialPathCsv);
    if ismember('price', init_tbl.Properties.VariableNames)
        price_path = init_tbl.price(1:min(T, height(init_tbl)));
    else
        price_path = table2array(init_tbl(1:min(T, height(init_tbl)), 1));
    end
    if numel(price_path) < T
        price_path = [price_path(:); base.reference_price .* ones(T - numel(price_path), 1)];
    end
else
    price_path = base.reference_price .* ones(T, 1);
end
price_path = clamp_price_path(price_path, base.reference_price, cfg.MaxAbsLogPriceMove);
terminal_agevector = age_share(:, min(base.reference_col + cfg.InternalT, size(age_share, 2)));
terminal_agevector = apply_age_weight_variant(terminal_agevector, cfg.AgeWeightVariant);
terminal_price = compute_terminal_price(cfg, base, terminal_agevector, price_path(end));

all_summary = table();
all_paths = table();

for outer = 1:cfg.OuterIter
    write_status(status_path, 'running', sprintf('Solving full RE path outer iteration %d/%d.', outer, cfg.OuterIter), cfg.RunTag, out_dir);
    solved_path = solve_price_path(base, price_path, 1.0, terminal_price);
    solved_shift = solve_price_path(base, price_path, base.param.deltaPh, terminal_price);

    [iter_summary, iter_paths, generated_path] = simulate_generated_path(cfg, base, age_share, price_path, solved_path, solved_shift, outer);
    all_summary = [all_summary; iter_summary]; %#ok<AGROW>
    all_paths = [all_paths; iter_paths]; %#ok<AGROW>

    price_path = exp((1 - cfg.PathRelaxation) .* log(price_path) + cfg.PathRelaxation .* log(generated_path));
    price_path = clamp_price_path(price_path, base.reference_price, cfg.MaxAbsLogPriceMove);

    writetable(all_summary, fullfile(out_dir, 'summary_all.csv'));
    writetable(all_paths, fullfile(out_dir, 'paths_all.csv'));
end

write_note(fullfile(out_dir, 'note.md'), cfg, base, all_summary);
write_status(status_path, 'complete', 'Full price-path RE transition complete.', cfg.RunTag, out_dir);
disp('Full price-path RE transition complete.');
end

function [base, age_share] = build_baseline(cfg)
options = struct();
options.mod_data_path = fullfile(fileparts(cfg.ModIrfDir), 'Mod_Data', filesep);

source_path = cfg.SourceMat;
if ~isfile(source_path)
    source_path = fullfile(cfg.ModIrfDir, cfg.SourceMat);
end
S = load(source_path, 'param', 'age_share', 'PriceHouse', 'VoteBaseline', 'indReference', ...
    'forecast_lower', 'forecast_median', 'forecast_upper');
param = S.param;
age_share = S.age_share;

age_share_start_year = 1950;
if isfinite(cfg.ReferenceYear)
    ref_col = round(cfg.ReferenceYear - age_share_start_year + 1);
else
    ref_col = min(51, size(age_share, 2));
end
if ref_col < 1 || ref_col > size(age_share, 2)
    error('ReferenceYear %.0f maps to invalid age_share column %d.', cfg.ReferenceYear, ref_col);
end
agevector0 = age_share(:, ref_col);
agevector0 = apply_age_weight_variant(agevector0, cfg.AgeWeightVariant);
reference_price = S.PriceHouse(S.indReference);
source_target_vote = S.VoteBaseline(ref_col, S.indReference);

param.Ph = reference_price;
param.Ph_ss = reference_price;
param.Ph_prev = reference_price;
param.rA_ss = param.rA;
param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* param.Ph;

[param, glob, options] = setup_modelspace(param, options);
solved_ss = solve_coeff(param, glob, options);

param_high = set_price(param, reference_price * param.deltaPh);
solved_high = solve_coeff(param_high, glob, options);

VV_delta = max(max(solved_high.policies.vVR(:), solved_high.policies.vVA(:)), solved_high.policies.vVN(:));
VV = max(max(solved_ss.policies.vVR(:), solved_ss.policies.vVA(:)), solved_ss.policies.vVN(:));
VoteV = (VV_delta >= VV);
VoteV = reshape(VoteV, [glob.Nb * glob.Nh * glob.Ny, param.J + 1]);
VoteV = VoteV(:, 1:end-1) * 1;

eq_ss = solve_statdist(solved_ss, param, glob, options);
VoteAge = sum(eq_ss.dist.L .* VoteV, 1);

base = struct();
base.param = param;
base.glob = glob;
base.options = options;
base.eq_ss = eq_ss;
base.solved_ss = solved_ss;
base.reference_price = reference_price;
base.source_target_vote = source_target_vote;
if strcmpi(cfg.AgeWeightVariant, 'baseline')
    base.target_vote = source_target_vote;
else
    base.target_vote = VoteAge * agevector0;
end
base.recomputed_target_vote = VoteAge * agevector0;
base.reference_col = ref_col;
base.agevector0 = agevector0;
base.source_path = source_path;
base.age_share_start_year = age_share_start_year;
base.reference_year = base.age_share_start_year + ref_col - 1;
base.forecast_start_year = 2020;
base.forecast_low = [];
base.forecast_median = [];
base.forecast_high = [];
if isfield(S, 'forecast_lower')
    base.forecast_low = S.forecast_lower;
end
if isfield(S, 'forecast_median')
    base.forecast_median = S.forecast_median;
end
if isfield(S, 'forecast_upper')
    base.forecast_high = S.forecast_upper;
end
end

function terminal_price = compute_terminal_price(cfg, base, terminal_agevector, initial_price)
switch lower(string(cfg.TerminalAnchor))
    case "reference"
        terminal_price = base.reference_price;
        return
    case {"terminal_fixed_point", "terminal", "fixed_point"}
        terminal_price = clamp_price_path(initial_price, base.reference_price, cfg.MaxAbsLogPriceMove);
    otherwise
        error('Unknown TerminalAnchor: %s', cfg.TerminalAnchor);
end

for it = 1:cfg.TerminalIter
    param_t = set_price(base.param, terminal_price);
    solved = solve_coeff(param_t, base.glob, base.options);
    param_shift = set_price(base.param, terminal_price * base.param.deltaPh);
    solved_shift = solve_coeff(param_shift, base.glob, base.options);
    eq = solve_statdist(solved, param_t, base.glob, base.options);
    VoteV = build_vote_matrix(solved, solved_shift, base.glob, base.param);
    VoteAge = sum(eq.dist.L .* VoteV, 1);
    vote = VoteAge * terminal_agevector;
    pressure = compute_pressure(vote - base.target_vote, cfg.VoteScale, cfg.PressureMode);
    generated = base.reference_price * exp(cfg.Eta * pressure);
    generated = clamp_price_path(generated, base.reference_price, cfg.MaxAbsLogPriceMove);
    terminal_price = exp((1 - cfg.TerminalRelaxation) * log(terminal_price) + cfg.TerminalRelaxation * log(generated));
    terminal_price = clamp_price_path(terminal_price, base.reference_price, cfg.MaxAbsLogPriceMove);
end
end

function solved_path = solve_price_path(base, price_path, shift_factor, terminal_price)
T = numel(price_path);
param = base.param;
glob = base.glob;
options = base.options;

tail_price = terminal_price * shift_factor;
terminal_param = set_price(param, tail_price);
solved_path = cell(T + 1, 1);
solved_path{T + 1} = solve_coeff(terminal_param, glob, options);

for t = T:-1:1
    current_price = price_path(t) * shift_factor;
    if t < T
        next_price = price_path(t + 1) * shift_factor;
    else
        next_price = tail_price;
    end
    current_param = set_price(param, current_price);
    solved_path{t} = solve_coeff_one_time(solved_path{t + 1}, current_param, glob, next_price);
end
end

function solved = solve_coeff_one_time(solved_next, param, glob, next_price)
s = glob.s;
Ns = glob.Ns;
Nb = glob.Nb;
Nh = glob.Nh;
Ny = glob.Ny;
J = param.J;

consR = zeros(Ns, J);
bprimeR = zeros(Ns, J);
rentR = zeros(Ns, J);
consA = zeros(Ns, J);
bprimeA = zeros(Ns, J);
hprimeA = zeros(Ns, J);
consN = zeros(Ns, J);
bprimeN = zeros(Ns, J);
vVR = zeros(Ns, J + 1);
vVA = zeros(Ns, J + 1);
vVN = zeros(Ns, J + 1);
vVE = zeros(Ns, J);

value_J1 = func_households('value_J1', s, J + 1, [], [], [], param, glob);
vVR(:, J + 1) = value_J1;
vVA(:, J + 1) = value_J1;
vVN(:, J + 1) = value_J1;

for jj = J:-1:1
    vR_int = reshape(solved_next.policies.vVR(:, jj + 1)', Nb, Nh, Ny);
    vR_int = griddedInterpolant(glob.s_b, glob.s_h, glob.s_y, vR_int, 'linear');
    vA_int = reshape(solved_next.policies.vVA(:, jj + 1)', Nb, Nh, Ny);
    vA_int = griddedInterpolant(glob.s_b, glob.s_h, glob.s_y, vA_int, 'linear');
    vN_int = reshape(solved_next.policies.vVN(:, jj + 1)', Nb, Nh, Ny);
    vN_int = griddedInterpolant(glob.s_b, glob.s_h, glob.s_y, vN_int, 'linear');

    vE = expected_valfunc_at_price(vR_int, vA_int, vN_int, s, jj + 1, param, glob, next_price);
    vE_int = reshape(vE', Nb, Nh, Ny);
    vE_int = griddedInterpolant(glob.s_b, glob.s_h, glob.s_y, vE_int, 'linear');

    v = solve_valfunc(vE_int, s, jj, param, glob);

    vVR(:, jj) = v.vVR;
    vVA(:, jj) = v.vVA;
    vVN(:, jj) = v.vVN;
    vVE(:, jj) = vE;
    bprimeR(:, jj) = v.bprimeR;
    consR(:, jj) = v.consR;
    rentR(:, jj) = v.rentR;
    bprimeA(:, jj) = v.bprimeA;
    hprimeA(:, jj) = v.hprimeA;
    consA(:, jj) = v.consA;
    bprimeN(:, jj) = v.bprimeN;
    consN(:, jj) = v.consN;
end

solved = struct();
solved.policies.vVR = vVR;
solved.policies.vVA = vVA;
solved.policies.vVN = vVN;
solved.policies.vVE = vVE;
solved.policies.bprimeR = bprimeR;
solved.policies.rentR = rentR;
solved.policies.consR = consR;
solved.policies.bprimeA = bprimeA;
solved.policies.hprimeA = hprimeA;
solved.policies.consA = consA;
solved.policies.bprimeN = bprimeN;
solved.policies.consN = consN;
end

function vE = expected_valfunc_at_price(vR, vA, vN, s, jj, param, glob, next_price)
R = param.R;
Rm = param.Rm;
Fs = param.Fs;

if jj > param.Jret
    E = glob.Emat_ret;
else
    E = glob.Emat;
end

bprime = s(:, 1);
hprime = s(:, 2);
yprime = s(:, 3);
Rprime = ((bprime < 0) .* Rm + (bprime >= 0) .* R);

xprimeR = bprime .* Rprime + next_price .* (1 - Fs) .* hprime;
vRprime = vR(xprimeR, 0 * hprime, yprime);

xprimeA = bprime .* Rprime + next_price .* (1 - Fs) .* hprime;
vAprime = vA(xprimeA, 0 * hprime, yprime);

xprimeN = bprime .* Rprime;
vNprime = vN(xprimeN, hprime, yprime);

[~, ix] = max([vRprime, vAprime, vNprime], [], 2);
indR = double(ix == 1);
indA = double(ix == 2);
indN = double(ix == 3);
vVprime = indR .* vRprime + indA .* vAprime + indN .* vNprime;
vE = E * vVprime;

if jj > param.J
    xprime = bprime .* Rprime + next_price .* (1 - Fs) .* hprime;
    vVprime = vN(xprime, hprime, yprime);
    vE = E * vVprime;
end
end

function [summary, paths, generated_price] = simulate_generated_path(cfg, base, age_share, price_path, solved_path, solved_shift, outer)
T = numel(price_path);
eqprev = base.eq_ss;
path_rows = cell(T, 18);
vote_resids = nan(T, 1);
generated_price = nan(T, 1);
homeownership = nan(T, 1);
housing_demand = nan(T, 1);

for t = 1:T
    age_col = min(base.reference_col + t, size(age_share, 2));
    agevector = age_share(:, age_col);
    agevector = apply_age_weight_variant(agevector, cfg.AgeWeightVariant);

    param_t = set_price(base.param, price_path(t));
    eq = solve_dyndist(solved_path{t}, param_t, base.glob, base.options, eqprev);

    VoteV = build_vote_matrix(solved_path{t}, solved_shift{t}, base.glob, base.param);
    VoteAge = sum(eq.dist.L .* VoteV, 1);
    vote = VoteAge * agevector;
    vote_resid = vote - base.target_vote;
    pressure = compute_pressure(vote_resid, cfg.VoteScale, cfg.PressureMode);
    restriction = cfg.Eta * pressure;
    generated_price(t) = base.reference_price * exp(restriction);
    generated_price(t) = clamp_price_path(generated_price(t), base.reference_price, cfg.MaxAbsLogPriceMove);

    vote_resids(t) = vote_resid;
    homeownership(t) = eq.age.homeownership' * agevector;
    housing_demand(t) = eq.age.H' * agevector;
    is_report = t <= cfg.ReportT;
    path_rows(t, :) = {outer, t, 2000 + t, is_report, cfg.Eta, cfg.VoteScale, string(cfg.DemographicScenario), price_path(t), generated_price(t), vote, vote_resid, pressure, restriction, homeownership(t), housing_demand(t), abs(log(generated_price(t) / price_path(t))), abs(log(price_path(t) / base.reference_price)), cfg.PathRelaxation};

    eqprev = eq;
end

report_ix = 1:min(cfg.ReportT, T);
max_path_gap = max(abs(log(generated_price(report_ix) ./ price_path(report_ix))));
max_abs_vote = max(abs(vote_resids(report_ix)));
mean_abs_vote = mean(abs(vote_resids(report_ix)));
max_abs_log_price = max(abs(log(price_path(report_ix) ./ base.reference_price)));
mean_homeownership = mean(homeownership(report_ix));
[verdict, message] = classify_path(max_path_gap, max_abs_vote, max_abs_log_price);

summary = cell2table({outer, cfg.ReportT, T, cfg.TailYears, cfg.Eta, cfg.VoteScale, string(cfg.DemographicScenario), max_path_gap, max_abs_vote, mean_abs_vote, max_abs_log_price, mean_homeownership, verdict, message}, ...
    'VariableNames', {'outer_iter','report_T','internal_T','tail_years','eta','vote_scale','demographic_scenario','max_abs_path_gap','max_abs_vote_resid','mean_abs_vote_resid','max_abs_log_price_move','mean_homeownership','verdict','message'});
paths = cell2table(path_rows, 'VariableNames', {'outer_iter','period','year','is_report_period','eta','vote_scale','demographic_scenario','price_guess','price_generated','vote','vote_resid','pressure','restriction','homeownership','housing_demand','abs_log_path_gap','abs_log_price_move','path_relaxation'});
end

function VoteV = build_vote_matrix(solved, solved_shift, glob, param)
VV_delta = max(max(solved_shift.policies.vVR(:), solved_shift.policies.vVA(:)), solved_shift.policies.vVN(:));
VV = max(max(solved.policies.vVR(:), solved.policies.vVA(:)), solved.policies.vVN(:));
VoteV = (VV_delta >= VV);
VoteV = reshape(VoteV, [glob.Nb * glob.Nh * glob.Ny, param.J + 1]);
VoteV = VoteV(:, 1:end-1) * 1;
end

function param = set_price(param, price)
param.Ph = price;
param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* price;
end

function [verdict, message] = classify_path(max_path_gap, max_abs_vote, max_abs_log_price)
if max_path_gap <= 0.020 && max_abs_vote <= 0.020 && max_abs_log_price <= 0.18
    verdict = "usable";
    message = "Path fixed point and political residual are within paper-smoke bands.";
elseif max_path_gap <= 0.050 && max_abs_vote <= 0.050 && max_abs_log_price <= 0.18
    verdict = "survivor";
    message = "Promising but needs more damping or outer iterations.";
else
    verdict = "dead";
    message = "Not yet a credible fixed point for the full RE price path.";
end
end

function pressure = compute_pressure(vote_resid, vote_scale, pressure_mode)
switch lower(string(pressure_mode))
    case "hard_sign"
        if vote_resid > 0
            pressure = 1;
        elseif vote_resid < 0
            pressure = -1;
        else
            pressure = 0;
        end
    case {"smooth", "tanh"}
        pressure = tanh(vote_resid ./ vote_scale);
    case {"softnorm", "soft_norm"}
        pressure = vote_resid ./ sqrt(vote_resid.^2 + vote_scale.^2);
    case {"linear_clip", "clipped_linear"}
        pressure = max(-1, min(1, vote_resid ./ vote_scale));
    case "logit"
        pressure = 2 ./ (1 + exp(-vote_resid ./ vote_scale)) - 1;
    otherwise
        error('Unknown PressureMode: %s', pressure_mode);
end
end

function agevector = apply_age_weight_variant(agevector, variant)
agevector = agevector(:);
switch lower(string(variant))
    case "terminal_half"
        agevector(end) = 0.5 * agevector(end);
    case "terminal_drop"
        agevector(end) = 0;
end
agevector = normalize_agevector(agevector);
end

function age_share_out = apply_demographic_scenario(age_share, cfg, base)
scenario = lower(string(cfg.DemographicScenario));
age_share_out = age_share;
if scenario == "source_path"
    return
end
if any(scenario == ["forecast_low", "projection_low", "immigration_low", "low_immigration"])
    age_share_out = apply_projection_path(age_share_out, base.forecast_low, base);
    return
end
if any(scenario == ["forecast_median", "forecast_medium", "projection_median", "projection_medium", "immigration_medium", "medium_immigration"])
    age_share_out = apply_projection_path(age_share_out, base.forecast_median, base);
    return
end
if any(scenario == ["forecast_high", "projection_high", "immigration_high", "high_immigration"])
    age_share_out = apply_projection_path(age_share_out, base.forecast_high, base);
    return
end
if scenario == "fixed_age_share"
    ref_col = base.reference_col;
    baseline = normalize_agevector(age_share(:, ref_col));
    for col = (ref_col + 1):size(age_share_out, 2)
        age_share_out(:, col) = baseline;
    end
    return
end

ref_col = base.reference_col;
baseline = normalize_agevector(age_share(:, ref_col));
n_ages = numel(baseline);
n_forward = max(cfg.InternalT + 2, size(age_share, 2) - ref_col);
entrant_scale = build_annual_entrant_scale(n_forward, scenario, cfg.DemographicShockAmplitude);
survival = default_annual_survival_rates(n_ages);

path = zeros(n_ages, n_forward + 1);
path(:, 1) = baseline;
for t = 1:n_forward
    next = zeros(n_ages, 1);
    next(1) = baseline(1) * entrant_scale(t);
    next(2:end) = path(1:end-1, t) .* survival(1:end-1);
    path(:, t + 1) = normalize_agevector(next);
end

for t = 1:n_forward
    col = ref_col + t;
    if col <= size(age_share_out, 2)
        age_share_out(:, col) = path(:, t + 1);
    end
end
end

function age_share_out = apply_projection_path(age_share_out, forecast_path, base)
if isempty(forecast_path)
    error('Requested projection scenario, but forecast age-share path is missing from %s.', base.source_path);
end
forecast_path = double(forecast_path);
forecast_start_col = base.reference_col + (base.forecast_start_year - (base.age_share_start_year + base.reference_col - 1));
if forecast_start_col < 1
    error('Computed invalid forecast start column: %d.', forecast_start_col);
end
max_cols = min(size(forecast_path, 2), size(age_share_out, 2) - forecast_start_col + 1);
if max_cols <= 0
    error('Projection path does not overlap with age_share columns.');
end
for j = 1:max_cols
    age_share_out(:, forecast_start_col + j - 1) = normalize_agevector(forecast_path(:, j));
end
end

function entrant_scale = build_annual_entrant_scale(n_forward, scenario, amplitude)
entrant_scale = ones(n_forward, 1);
switch lower(string(scenario))
    case "flat_entrant"
        return
    case "baby_boom"
        rise_len = min(10, n_forward);
        fall_len = min(20, max(0, n_forward - rise_len));
        entrant_scale(1:rise_len) = linspace(1, 1 + amplitude, rise_len);
        if fall_len > 0
            entrant_scale((rise_len + 1):(rise_len + fall_len)) = linspace(1 + amplitude, 1, fall_len);
        end
    case "secular_decline"
        entrant_scale = linspace(1, max(0.20, 1 - amplitude), n_forward)';
    otherwise
        error('Unknown demographic scenario: %s', scenario);
end
end

function survival = default_annual_survival_rates(n_ages)
ages = (25:(25 + n_ages - 1))';
survival = 0.995 - 0.00015 * max(ages - 45, 0) - 0.0010 * max(ages - 70, 0);
survival = min(max(survival, 0.80), 0.998);
survival(end) = 0;
end

function agevector = normalize_agevector(agevector)
agevector = agevector(:);
agevector(~isfinite(agevector)) = 0;
agevector(agevector < 0) = 0;
total = sum(agevector);
if total <= 0
    error('Age vector has non-positive mass.');
end
agevector = agevector ./ total;
end

function price_path = clamp_price_path(price_path, reference_price, max_abs_log_move)
price_path = min(max(price_path, reference_price * exp(-max_abs_log_move)), reference_price * exp(max_abs_log_move));
end

function write_note(note_path, cfg, base, summary)
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Annual full RE price-path run\n\n');
fprintf(fid, 'This run solves households with perfect foresight over the house-price path.\n');
fprintf(fid, 'Demographics are exogenous; the expected aggregate object is the future price path.\n\n');
fprintf(fid, '- Scenario: `%s`\n', cfg.DemographicScenario);
fprintf(fid, '- T: `%d`\n', cfg.T);
fprintf(fid, '- Tail years: `%d`\n', cfg.TailYears);
fprintf(fid, '- Internal T: `%d`\n', cfg.InternalT);
fprintf(fid, '- Terminal anchor: `%s`\n', cfg.TerminalAnchor);
fprintf(fid, '- Terminal iterations: `%d`\n', cfg.TerminalIter);
fprintf(fid, '- Outer iterations: `%d`\n', cfg.OuterIter);
fprintf(fid, '- Eta: `%.6f`\n', cfg.Eta);
fprintf(fid, '- Vote scale: `%.6f`\n', cfg.VoteScale);
fprintf(fid, '- Reference year: `%d`\n', base.reference_year);
fprintf(fid, '- Reference price: `%.6f`\n', base.reference_price);
fprintf(fid, '- Target vote: `%.6f`\n', base.target_vote);
fprintf(fid, '- Source: `%s`\n\n', base.source_path);
if ~isempty(summary)
    last = summary(end, :);
    fprintf(fid, 'Final verdict: `%s`.\n', string(last.verdict));
    fprintf(fid, 'Final max path gap over reported periods: `%.6f`.\n', last.max_abs_path_gap);
    fprintf(fid, 'Final max vote residual: `%.6f`.\n', last.max_abs_vote_resid);
end
end

function write_status(status_path, state, message, run_tag, out_dir)
fid = fopen(status_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '{"state":"%s","message":"%s","run_tag":"%s","out_dir":"%s","timestamp":"%s"}\n', ...
    escape_json(state), escape_json(message), escape_json(run_tag), escape_json(out_dir), datestr(now, 30));
end

function s = escape_json(s)
s = char(string(s));
s = strrep(s, '\', '\\');
s = strrep(s, '"', '\"');
end
