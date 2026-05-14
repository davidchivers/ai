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
p.addParameter('PostReportDemographicMode', 'natural');
p.addParameter('TerminalAnchor', 'reference');
p.addParameter('TerminalIter', 20);
p.addParameter('TerminalRelaxation', 0.25);
p.addParameter('TerminalBlendWeight', 0.50);
p.addParameter('OuterIter', 2);
p.addParameter('PathRelaxation', 0.50);
p.addParameter('PathUpdateMethod', 'relaxation');
p.addParameter('AndersonMemory', 4);
p.addParameter('AndersonDamping', 0.70);
p.addParameter('AndersonRidge', 1e-8);
p.addParameter('AndersonCoeffCap', 10);
p.addParameter('BroydenDamping', 0.80);
p.addParameter('BroydenStepCap', 0.010);
p.addParameter('BasisDim', 8);
p.addParameter('BasisDamping', 0.35);
p.addParameter('BasisStepCap', 0.0015);
p.addParameter('BasisRidge', 1e-8);
p.addParameter('BasisEndWeight', 6.0);
p.addParameter('BasisTailWeight', 0.20);
p.addParameter('BasisFocusStart', NaN);
p.addParameter('BasisFocusEnd', NaN);
p.addParameter('BasisFocusWeight', 1.0);
p.addParameter('SafeguardBestAnchor', true);
p.addParameter('SafeguardWorseTolerance', 0.00);
p.addParameter('SafeguardResetHistory', true);
p.addParameter('PoliticalPassThrough', NaN);
p.addParameter('Eta', NaN); % Legacy alias for PoliticalPassThrough.
p.addParameter('VoteScale', 0.020);
p.addParameter('VoteRule', 'smooth_logit');
p.addParameter('VoteTau', NaN);
p.addParameter('VoteSigma', 0);
p.addParameter('VoteShiftMode', 'path_shift');
p.addParameter('VoteShiftHorizon', 5);
p.addParameter('VoteBlockLength', 5);
p.addParameter('LaggedPassThrough', false);
p.addParameter('PassThroughLagYears', 1);
p.addParameter('MaxAbsLogPriceMove', 0.18);
p.addParameter('PressureMode', 'smooth');
p.addParameter('DemographicScenario', 'fixed_age_share');
p.addParameter('DemographicPathMat', '');
p.addParameter('DemographicPathVar', 'ageimpulse');
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
cfg = normalize_political_pass_through_config(cfg);
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
age_share = apply_post_report_demographics(age_share, cfg, base);
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
cfg.demographic_source_cols = size(age_share, 2);
cfg.terminal_age_col_requested = base.reference_col + cfg.InternalT;
cfg.terminal_age_col = min(cfg.terminal_age_col_requested, cfg.demographic_source_cols);
cfg.terminal_age_year = base.age_share_start_year + cfg.terminal_age_col - 1;
cfg.demographic_horizon_capped = cfg.terminal_age_col_requested > cfg.demographic_source_cols;
terminal_agevector = age_share(:, cfg.terminal_age_col);
terminal_agevector = apply_age_weight_variant(terminal_agevector, cfg.AgeWeightVariant);
[terminal_price, terminal_diag] = compute_terminal_price(cfg, base, terminal_agevector, price_path(end));
terminal_age_table = table((1:numel(terminal_agevector))', (25:(25 + numel(terminal_agevector) - 1))', terminal_agevector(:), ...
    'VariableNames', {'age_index','model_age','age_weight'});
writetable(struct2table(terminal_diag), fullfile(out_dir, 'terminal_anchor.csv'));
writetable(terminal_age_table, fullfile(out_dir, 'terminal_agevector.csv'));

all_summary = table();
all_paths = table();
all_age_paths = table();
history_f = [];
history_r = [];
history_x = [];
broyden_H = [];
best_report_gap = Inf;
best_x = [];
best_f = [];
best_r = [];

for outer = 1:cfg.OuterIter
    write_status(status_path, 'running', sprintf('Solving full RE path outer iteration %d/%d.', outer, cfg.OuterIter), cfg.RunTag, out_dir);
    solved_path = solve_price_path(base, price_path, 1.0, terminal_price);
    solved_shift = solve_vote_shift_path(cfg, base, price_path, solved_path, terminal_price);

    [iter_summary, iter_paths, iter_age_paths, generated_path] = simulate_generated_path(cfg, base, age_share, price_path, solved_path, solved_shift, outer);
    all_summary = [all_summary; iter_summary]; %#ok<AGROW>
    all_paths = [all_paths; iter_paths]; %#ok<AGROW>
    all_age_paths = [all_age_paths; iter_age_paths]; %#ok<AGROW>

    x = log(price_path ./ base.reference_price);
    f = log(generated_path ./ base.reference_price);
    r = f - x;
    history_f = [history_f, f(:)]; %#ok<AGROW>
    history_r = [history_r, r(:)]; %#ok<AGROW>
    history_x = [history_x, x(:)]; %#ok<AGROW>
    report_update_ix = 1:min(cfg.ReportT, numel(r));
    current_report_gap = max(abs(r(report_update_ix)));
    if current_report_gap < best_report_gap
        best_report_gap = current_report_gap;
        best_x = x(:);
        best_f = f(:);
        best_r = r(:);
    end

    update_x = x(:);
    update_f = f(:);
    update_history_x = history_x;
    update_history_f = history_f;
    update_history_r = history_r;
    update_H = broyden_H;
    if cfg.SafeguardBestAnchor && isfinite(best_report_gap) && ...
            current_report_gap > best_report_gap * (1 + cfg.SafeguardWorseTolerance)
        update_x = best_x;
        update_f = best_f;
        if cfg.SafeguardResetHistory
            update_history_x = best_x;
            update_history_f = best_f;
            update_history_r = best_r;
            update_H = [];
        end
    end

    [x_next, broyden_H] = update_log_price_path(cfg, update_x, update_f, update_history_x, update_history_f, update_history_r, update_H);
    price_path = base.reference_price .* exp(x_next);
    price_path = clamp_price_path(price_path, base.reference_price, cfg.MaxAbsLogPriceMove);

    writetable(all_summary, fullfile(out_dir, 'summary_all.csv'));
    writetable(all_paths, fullfile(out_dir, 'paths_all.csv'));
    writetable(all_age_paths, fullfile(out_dir, 'age_paths_all.csv'));
end

write_note(fullfile(out_dir, 'note.md'), cfg, base, all_summary, terminal_diag);
write_status(status_path, 'complete', 'Full price-path RE transition complete.', cfg.RunTag, out_dir);
disp('Full price-path RE transition complete.');
end

function [x_next, broyden_H] = update_log_price_path(cfg, x, f, history_x, history_f, history_r, broyden_H)
method = lower(string(cfg.PathUpdateMethod));
relaxed = (1 - cfg.PathRelaxation) .* x + cfg.PathRelaxation .* f;
switch method
    case {"relaxation", "damping", "plain"}
        x_next = relaxed;
        return
    case {"trust_region_relaxation", "report_trust_region", "coordinate_relaxation"}
        r = history_r(:, end);
        n = numel(x);
        step = cfg.PathRelaxation .* r(:);
        report_T = min(max(1, round(cfg.ReportT)), n);
        if report_T < n
            step((report_T + 1):end) = cfg.BasisTailWeight .* step((report_T + 1):end);
        end
        if isfinite(cfg.BasisFocusStart) && isfinite(cfg.BasisFocusEnd)
            focus_start = min(max(1, round(cfg.BasisFocusStart)), n);
            focus_end = min(max(focus_start, round(cfg.BasisFocusEnd)), n);
            step(focus_start:focus_end) = cfg.BasisFocusWeight .* step(focus_start:focus_end);
        end
        step_cap = max(cfg.BasisStepCap, 1e-7);
        step = max(-step_cap, min(step_cap, step));
        x_next = x + step;
        return
    case {"anderson", "aa", "safeguarded_anderson"}
        m_total = size(history_r, 2);
        m = min(max(1, round(cfg.AndersonMemory)) + 1, m_total);
        if m < 2
            x_next = relaxed;
            return
        end
        R = history_r(:, (m_total - m + 1):m_total);
        F = history_f(:, (m_total - m + 1):m_total);
        gram = R' * R + cfg.AndersonRidge .* eye(m);
        system = [gram, ones(m, 1); ones(1, m), 0];
        rhs = [zeros(m, 1); 1];
        coeff = system \ rhs;
        alpha = coeff(1:m);
        if any(~isfinite(alpha)) || sum(abs(alpha)) > cfg.AndersonCoeffCap
            x_next = relaxed;
            return
        end
        candidate = F * alpha;
        if any(~isfinite(candidate))
            x_next = relaxed;
            return
        end
        damp = min(max(cfg.AndersonDamping, 0), 1);
        x_next = (1 - damp) .* relaxed + damp .* candidate;
        return
    case {"broyden", "broyden_inverse", "safe_broyden"}
        n = numel(x);
        if isempty(broyden_H)
            broyden_H = -cfg.PathRelaxation .* eye(n);
        end
        m_total = size(history_r, 2);
        if m_total >= 2
            s = history_x(:, end) - history_x(:, end - 1);
            y = history_r(:, end) - history_r(:, end - 1);
            denom = y' * y;
            if isfinite(denom) && denom > 1e-12
                broyden_H = broyden_H + ((s - broyden_H * y) * y') ./ denom;
            end
        end
        step = -broyden_H * history_r(:, end);
        if any(~isfinite(step))
            x_next = relaxed;
            return
        end
        step_cap = max(cfg.BroydenStepCap, 1e-6);
        step = max(-step_cap, min(step_cap, step));
        candidate = x + min(max(cfg.BroydenDamping, 0), 1) .* step;
        if any(~isfinite(candidate))
            x_next = relaxed;
            return
        end
        x_next = candidate;
        return
    case {"basis", "basis_relaxation", "reduced_basis"}
        n = numel(x);
        B = build_reduced_path_basis(n, cfg.BasisDim, cfg.ReportT);
        r = history_r(:, end);
        [gram, w] = build_reduced_basis_gram(B, n, cfg);
        rhs = B' * (w .* r);
        coeff = gram \ rhs;
        projected = B * coeff;
        if any(~isfinite(projected))
            x_next = relaxed;
            return
        end
        step = min(max(cfg.BasisDamping, 0), 1) .* projected;
        step_cap = max(cfg.BasisStepCap, 1e-6);
        step = max(-step_cap, min(step_cap, step));
        candidate = x + step;
        if any(~isfinite(candidate))
            x_next = relaxed;
            return
        end
        x_next = candidate;
        return
    case {"basis_broyden", "reduced_basis_broyden", "basis_root"}
        n = numel(x);
        B = build_reduced_path_basis(n, cfg.BasisDim, cfg.ReportT);
        [gram, w] = build_reduced_basis_gram(B, n, cfg);
        k = size(B, 2);
        r = history_r(:, end);
        br = gram \ (B' * (w .* r));
        if isempty(broyden_H) || any(size(broyden_H) ~= [k, k])
            broyden_H = -eye(k);
        end
        m_total = size(history_r, 2);
        if m_total >= 2
            c_now = gram \ (B' * (w .* history_x(:, end)));
            c_prev = gram \ (B' * (w .* history_x(:, end - 1)));
            br_prev = gram \ (B' * (w .* history_r(:, end - 1)));
            s = c_now - c_prev;
            y = br - br_prev;
            denom = y' * y;
            if isfinite(denom) && denom > 1e-12
                broyden_H = broyden_H + ((s - broyden_H * y) * y') ./ denom;
            end
        end
        coeff_step = -broyden_H * br;
        if any(~isfinite(coeff_step))
            coeff_step = br;
        end
        coeff_cap = max(cfg.BroydenStepCap, 1e-6);
        coeff_step = max(-coeff_cap, min(coeff_cap, coeff_step));
        step = B * coeff_step;
        if any(~isfinite(step))
            projected = B * br;
            step = projected;
        end
        damp = min(max(cfg.BroydenDamping, 0), 1);
        step = damp .* step;
        step_cap = max(cfg.BasisStepCap, 1e-6);
        step = max(-step_cap, min(step_cap, step));
        candidate = x + step;
        if any(~isfinite(candidate))
            x_next = relaxed;
            return
        end
        x_next = candidate;
        return
    otherwise
        error('Unknown PathUpdateMethod: %s', method);
end
end

function [gram, w] = build_reduced_basis_gram(B, n, cfg)
w = cfg.BasisTailWeight .* ones(n, 1);
report_T = min(max(1, round(cfg.ReportT)), n);
w(1:report_T) = 1.0;
end_start = max(1, report_T - 4);
w(end_start:report_T) = cfg.BasisEndWeight;
if isfinite(cfg.BasisFocusStart) && isfinite(cfg.BasisFocusEnd)
    focus_start = min(max(1, round(cfg.BasisFocusStart)), n);
    focus_end = min(max(focus_start, round(cfg.BasisFocusEnd)), n);
    w(focus_start:focus_end) = max(w(focus_start:focus_end), cfg.BasisFocusWeight);
end
gram = B' * (w .* B) + cfg.BasisRidge .* eye(size(B, 2));
end

function B = build_reduced_path_basis(n, basis_dim, report_T)
k = min(max(3, round(basis_dim)), n);
report_T = min(max(2, round(report_T)), n);
report_knots = round(linspace(1, report_T, max(3, ceil(0.75 * k))));
tail_knots = round(linspace(report_T + 1, n, max(1, k - numel(unique(report_knots)) + 1)));
knots = unique([report_knots(:); tail_knots(:); n]);
knots = knots(knots >= 1 & knots <= n);
if numel(knots) > k
    keep = round(linspace(1, numel(knots), k));
    knots = knots(unique(keep));
end
if knots(1) ~= 1
    knots = [1; knots(:)];
end
if knots(end) ~= n
    knots = [knots(:); n];
end
knots = unique(knots(:));
t = (1:n)';
B = zeros(n, numel(knots));
for j = 1:numel(knots)
    if j == 1
        right = knots(j + 1);
        ix = t <= right;
        B(ix, j) = max(0, (right - t(ix)) ./ max(right - knots(j), 1));
    elseif j == numel(knots)
        left = knots(j - 1);
        ix = t >= left;
        B(ix, j) = max(0, (t(ix) - left) ./ max(knots(j) - left, 1));
    else
        left = knots(j - 1);
        right = knots(j + 1);
        ix_left = t >= left & t <= knots(j);
        ix_right = t >= knots(j) & t <= right;
        B(ix_left, j) = (t(ix_left) - left) ./ max(knots(j) - left, 1);
        B(ix_right, j) = max(B(ix_right, j), (right - t(ix_right)) ./ max(right - knots(j), 1));
    end
end
B = B ./ max(sqrt(sum(B.^2, 1)), 1e-12);
end

function cfg = normalize_political_pass_through_config(cfg)
default_pass_through = 0.090;
has_primary = ~(isnumeric(cfg.PoliticalPassThrough) && isscalar(cfg.PoliticalPassThrough) && isnan(cfg.PoliticalPassThrough));
has_legacy = ~(isnumeric(cfg.Eta) && isscalar(cfg.Eta) && isnan(cfg.Eta));
if has_primary && has_legacy && abs(cfg.PoliticalPassThrough - cfg.Eta) > 1e-12
    error('PoliticalPassThrough and legacy Eta both supplied with different values.');
end
if ~has_primary
    if has_legacy
        cfg.PoliticalPassThrough = cfg.Eta;
    else
        cfg.PoliticalPassThrough = default_pass_through;
    end
end
cfg.Eta = cfg.PoliticalPassThrough; % Keep legacy callers from breaking inside old wrappers.
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
    S = load(source_path, 'param', 'age_share', 'PriceHouse', 'VoteBaseline', 'indReference', ...
        'forecast_lower', 'forecast_median', 'forecast_upper');
else
    S = load(source_path, 'param', 'age_share', 'agevector', 'TargetVote', ...
        'forecast_lower', 'forecast_median', 'forecast_upper');
end
param = S.param;
age_share = S.age_share;

age_share_start_year = 1950;
if isfinite(cfg.ReferenceYear)
    ref_col = round(cfg.ReferenceYear - age_share_start_year + 1);
elseif ~has_projection_baseline && isfield(S, 'agevector')
    [~, ref_col] = min(sum(abs(age_share - S.agevector(:)), 1));
else
    ref_col = min(51, size(age_share, 2));
end
if ref_col < 1 || ref_col > size(age_share, 2)
    error('ReferenceYear %.0f maps to invalid age_share column %d.', cfg.ReferenceYear, ref_col);
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
param.Pr = param.kappa .* param.wages + (1 + param.delta - 1 / param.R) .* param.Ph;

[param, glob, options] = setup_modelspace(param, options);
solved_ss = solve_coeff(param, glob, options);

param_high = set_price(param, reference_price * param.deltaPh);
solved_high = solve_coeff(param_high, glob, options);

VV_delta = max(max(solved_high.policies.vVR(:), solved_high.policies.vVA(:)), solved_high.policies.vVN(:));
VV = max(max(solved_ss.policies.vVR(:), solved_ss.policies.vVA(:)), solved_ss.policies.vVN(:));
vote_params = resolve_vote_params(cfg, VV_delta - VV);
VoteV = build_vote_matrix(solved_ss, solved_high, glob, param, vote_params);

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

function [terminal_price, terminal_diag] = compute_terminal_price(cfg, base, terminal_agevector, initial_price)
terminal_blend_weight = 1.0;
switch lower(string(cfg.TerminalAnchor))
    case "reference"
        terminal_price = base.reference_price;
        terminal_diag = evaluate_terminal_anchor(cfg, base, terminal_agevector, terminal_price);
        return
    case {"terminal_fixed_point", "terminal", "fixed_point"}
        terminal_price = clamp_price_path(initial_price, base.reference_price, cfg.MaxAbsLogPriceMove);
    case {"soft_reference", "reference_blend", "terminal_blend"}
        terminal_price = clamp_price_path(initial_price, base.reference_price, cfg.MaxAbsLogPriceMove);
        terminal_blend_weight = min(max(cfg.TerminalBlendWeight, 0), 1);
    otherwise
        error('Unknown TerminalAnchor: %s', cfg.TerminalAnchor);
end

for it = 1:cfg.TerminalIter
    param_t = set_price(base.param, terminal_price);
    solved = solve_coeff(param_t, base.glob, base.options);
    solved_shift = solve_vote_shift_once(cfg, base, solved, terminal_price, terminal_price);
    eq = solve_statdist(solved, param_t, base.glob, base.options);
    VoteV = build_vote_matrix(solved, solved_shift, base.glob, base.param, base.vote_params);
    VoteAge = sum(eq.dist.L .* VoteV, 1);
    vote = VoteAge * terminal_agevector;
    pressure = compute_pressure(vote - base.target_vote, cfg.VoteScale, cfg.PressureMode);
    generated = base.reference_price * exp(cfg.PoliticalPassThrough * pressure);
    generated = clamp_price_path(generated, base.reference_price, cfg.MaxAbsLogPriceMove);
    target_price = exp(terminal_blend_weight * log(generated) + (1 - terminal_blend_weight) * log(base.reference_price));
    terminal_price = exp((1 - cfg.TerminalRelaxation) * log(terminal_price) + cfg.TerminalRelaxation * log(target_price));
    terminal_price = clamp_price_path(terminal_price, base.reference_price, cfg.MaxAbsLogPriceMove);
end
terminal_diag = evaluate_terminal_anchor(cfg, base, terminal_agevector, terminal_price);
end

function terminal_diag = evaluate_terminal_anchor(cfg, base, terminal_agevector, terminal_price)
param_t = set_price(base.param, terminal_price);
solved = solve_coeff(param_t, base.glob, base.options);
solved_shift = solve_vote_shift_once(cfg, base, solved, terminal_price, terminal_price);
eq = solve_statdist(solved, param_t, base.glob, base.options);
VoteV = build_vote_matrix(solved, solved_shift, base.glob, base.param, base.vote_params);
VoteAge = sum(eq.dist.L .* VoteV, 1);
vote = VoteAge * terminal_agevector;
vote_resid = vote - base.target_vote;
pressure = compute_pressure(vote_resid, cfg.VoteScale, cfg.PressureMode);
restriction = cfg.PoliticalPassThrough * pressure;
generated = base.reference_price * exp(restriction);
generated = clamp_price_path(generated, base.reference_price, cfg.MaxAbsLogPriceMove);

terminal_diag = struct();
terminal_diag.demographic_scenario = string(cfg.DemographicScenario);
terminal_diag.post_report_demographic_mode = string(cfg.PostReportDemographicMode);
terminal_diag.reference_year = base.reference_year;
terminal_diag.report_T = cfg.ReportT;
terminal_diag.tail_years = cfg.TailYears;
terminal_diag.internal_T = cfg.InternalT;
terminal_diag.terminal_anchor = string(cfg.TerminalAnchor);
terminal_diag.terminal_blend_weight = cfg.TerminalBlendWeight;
terminal_diag.terminal_iter = cfg.TerminalIter;
terminal_diag.terminal_relaxation = cfg.TerminalRelaxation;
terminal_diag.reference_price = base.reference_price;
terminal_diag.terminal_price = terminal_price;
terminal_diag.terminal_generated_price = generated;
terminal_diag.terminal_abs_log_gap = abs(log(generated / terminal_price));
terminal_diag.terminal_vote = vote;
terminal_diag.terminal_vote_resid = vote_resid;
terminal_diag.terminal_pressure = pressure;
terminal_diag.terminal_restriction = restriction;
terminal_diag.terminal_homeownership = eq.age.homeownership' * terminal_agevector;
terminal_diag.terminal_housing_demand = eq.age.H' * terminal_agevector;
terminal_diag.political_pass_through = cfg.PoliticalPassThrough;
terminal_diag.vote_scale = cfg.VoteScale;
terminal_diag.vote_shift_mode = string(cfg.VoteShiftMode);
terminal_diag.vote_shift_horizon = cfg.VoteShiftHorizon;
terminal_diag.pressure_mode = string(cfg.PressureMode);
terminal_diag.age_weight_variant = string(cfg.AgeWeightVariant);
terminal_diag.max_abs_log_price_move = cfg.MaxAbsLogPriceMove;
terminal_diag.target_vote = base.target_vote;
terminal_diag.source_path = string(base.source_path);
if isfield(cfg, 'demographic_source_cols')
    terminal_diag.demographic_source_cols = cfg.demographic_source_cols;
    terminal_diag.terminal_age_col_requested = cfg.terminal_age_col_requested;
    terminal_diag.terminal_age_col_used = cfg.terminal_age_col;
    terminal_diag.terminal_age_year = cfg.terminal_age_year;
    terminal_diag.demographic_horizon_capped = cfg.demographic_horizon_capped;
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

function solved_shift = solve_vote_shift_path(cfg, base, price_path, solved_path, terminal_price)
T = numel(price_path);
mode = lower(string(cfg.VoteShiftMode));
switch mode
    case {"path_shift", "full_path", "future_path"}
        solved_shift = solve_price_path(base, price_path, base.param.deltaPh, terminal_price);
    case {"current_period", "current_price", "one_period"}
        solved_shift = cell(T, 1);
        for t = T:-1:1
            current_price = price_path(t);
            if t < T
                next_price = price_path(t + 1);
            else
                next_price = terminal_price;
            end
            solved_shift{t} = solve_vote_shift_once(cfg, base, solved_path{t + 1}, current_price, next_price);
        end
    case {"finite_horizon", "finite_path", "horizon_path"}
        solved_shift = cell(T, 1);
        for t = T:-1:1
            solved_shift{t} = solve_vote_shift_finite_horizon(cfg, base, solved_path, price_path, t, terminal_price);
        end
    case {"block_vote", "periodic_block", "periodic_vote", "five_year_vote"}
        solved_shift = cell(T, 1);
        block_len = max(1, ceil(cfg.VoteBlockLength));
        for block_start = 1:block_len:T
            block_end = min(T, block_start + block_len - 1);
            block_shift = solve_vote_shift_block_horizon(cfg, base, solved_path, price_path, block_start, block_end, terminal_price);
            for t = block_start:block_end
                solved_shift{t} = block_shift;
            end
        end
    otherwise
        error('Unknown VoteShiftMode: %s', cfg.VoteShiftMode);
end
end

function solved_shift = solve_vote_shift_finite_horizon(cfg, base, solved_path, price_path, t0, terminal_price)
T = numel(price_path);
horizon = max(1, ceil(cfg.VoteShiftHorizon));
end_idx = min(T, t0 + horizon - 1);
solved_next = solved_path{end_idx + 1};

for t = end_idx:-1:t0
    current_price = price_path(t);
    if t < end_idx
        next_price = price_path(t + 1) * base.param.deltaPh;
    elseif end_idx < T
        next_price = price_path(end_idx + 1);
    else
        next_price = terminal_price;
    end
    solved_next = solve_vote_shift_once_core(base, solved_next, current_price, next_price, true);
end

solved_shift = solved_next;
end

function solved_shift = solve_vote_shift_block_horizon(cfg, base, solved_path, price_path, block_start, block_end, terminal_price)
T = numel(price_path);
end_idx = min(T, block_end);
solved_next = solved_path{end_idx + 1};

for t = end_idx:-1:block_start
    current_price = price_path(t);
    if t < end_idx
        next_price = price_path(t + 1) * base.param.deltaPh;
    elseif end_idx < T
        next_price = price_path(end_idx + 1);
    else
        next_price = terminal_price;
    end
    solved_next = solve_vote_shift_once_core(base, solved_next, current_price, next_price, true);
end

solved_shift = solved_next;
end

function solved_shift = solve_vote_shift_once(cfg, base, solved_next, current_price, next_price)
mode = lower(string(cfg.VoteShiftMode));
switch mode
    case {"path_shift", "full_path", "future_path"}
        solved_shift = solve_vote_shift_once_core(base, solved_next, current_price, next_price, false);
    case {"current_period", "current_price", "one_period"}
        solved_shift = solve_vote_shift_once_core(base, solved_next, current_price, next_price, true);
    case {"finite_horizon", "finite_path", "horizon_path"}
        solved_shift = solve_vote_shift_terminal_horizon(cfg, base, solved_next, current_price);
    case {"block_vote", "periodic_block", "periodic_vote", "five_year_vote"}
        solved_shift = solve_vote_shift_terminal_block(cfg, base, solved_next, current_price);
    otherwise
        error('Unknown VoteShiftMode: %s', cfg.VoteShiftMode);
end
end

function solved_shift = solve_vote_shift_terminal_horizon(cfg, base, solved, terminal_price)
horizon = max(1, ceil(cfg.VoteShiftHorizon));
solved_next = solved;
for t = horizon:-1:1
    if t > 1
        next_price = terminal_price * base.param.deltaPh;
    else
        next_price = terminal_price;
    end
    solved_next = solve_vote_shift_once_core(base, solved_next, terminal_price, next_price, true);
end
solved_shift = solved_next;
end

function solved_shift = solve_vote_shift_terminal_block(cfg, base, solved, terminal_price)
horizon = max(1, ceil(cfg.VoteBlockLength));
solved_next = solved;
for t = horizon:-1:1
    if t > 1
        next_price = terminal_price * base.param.deltaPh;
    else
        next_price = terminal_price;
    end
    solved_next = solve_vote_shift_once_core(base, solved_next, terminal_price, next_price, true);
end
solved_shift = solved_next;
end

function solved_shift = solve_vote_shift_once_core(base, solved_next, current_price, next_price, use_next_path)
shifted_param = set_price(base.param, current_price * base.param.deltaPh);
if use_next_path
    solved_shift = solve_coeff_one_time(solved_next, shifted_param, base.glob, next_price);
else
    solved_shift = solve_coeff(shifted_param, base.glob, base.options);
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

function [summary, paths, age_paths, generated_price] = simulate_generated_path(cfg, base, age_share, price_path, solved_path, solved_shift, outer)
T = numel(price_path);
eqprev = base.eq_ss;
path_rows = cell(T, 22);
age_rows = cell(T * base.param.J, 20);
age_row = 0;
vote_resids = nan(T, 1);
generated_price = nan(T, 1);
homeownership = nan(T, 1);
housing_demand = nan(T, 1);
block_vote_mode = is_block_vote_mode(cfg);
block_len = max(1, ceil(cfg.VoteBlockLength));
block_vote = NaN;
block_vote_resid = NaN;
block_pressure = NaN;
block_restriction = NaN;
lag_years = max(1, round(cfg.PassThroughLagYears));
restriction_queue = zeros(lag_years, 1);

for t = 1:T
    age_col_requested = base.reference_col + t;
    age_col = min(age_col_requested, size(age_share, 2));
    age_year = base.age_share_start_year + age_col - 1;
    demographic_capped = age_col_requested > size(age_share, 2);
    agevector = age_share(:, age_col);
    agevector = apply_age_weight_variant(agevector, cfg.AgeWeightVariant);

    param_t = set_price(base.param, price_path(t));
    eq = solve_dyndist(solved_path{t}, param_t, base.glob, base.options, eqprev);

    is_vote_period = ~block_vote_mode || mod(t - 1, block_len) == 0;
    if is_vote_period
        VoteV = build_vote_matrix(solved_path{t}, solved_shift{t}, base.glob, base.param, base.vote_params);
        VoteAge = sum(eq.dist.L .* VoteV, 1);
        vote = VoteAge * agevector;
        vote_resid = vote - base.target_vote;
        pressure = compute_pressure(vote_resid, cfg.VoteScale, cfg.PressureMode);
        restriction = cfg.PoliticalPassThrough * pressure;
        if block_vote_mode
            block_vote = vote;
            block_vote_resid = vote_resid;
            block_pressure = pressure;
            block_restriction = restriction;
        end
    else
        vote = block_vote;
        vote_resid = block_vote_resid;
        pressure = block_pressure;
        restriction = block_restriction;
    end
    if cfg.LaggedPassThrough
        price_restriction = restriction_queue(1);
        restriction_queue = [restriction_queue(2:end); restriction];
    else
        price_restriction = restriction;
    end
    generated_price(t) = base.reference_price * exp(price_restriction);
    generated_price(t) = clamp_price_path(generated_price(t), base.reference_price, cfg.MaxAbsLogPriceMove);

    vote_resids(t) = vote_resid;
    homeownership(t) = eq.age.homeownership' * agevector;
    housing_demand(t) = eq.age.H' * agevector;
    is_report = t <= cfg.ReportT;
    path_rows(t, :) = {outer, t, 2000 + t, is_report, cfg.PoliticalPassThrough, cfg.VoteScale, string(cfg.DemographicScenario), age_col_requested, age_col, age_year, demographic_capped, price_path(t), generated_price(t), vote, vote_resid, pressure, restriction, homeownership(t), housing_demand(t), abs(log(generated_price(t) / price_path(t))), abs(log(price_path(t) / base.reference_price)), cfg.PathRelaxation};

    model_ages = (25:(25 + base.param.J - 1))';
    if isfield(base.param, 'ages')
        model_ages = base.param.ages(:);
    end
    for jj = 1:base.param.J
        age_row = age_row + 1;
        age_rows(age_row, :) = {outer, t, 2000 + t, is_report, cfg.PoliticalPassThrough, cfg.VoteScale, string(cfg.DemographicScenario), age_col, age_year, jj, model_ages(jj), agevector(jj), eq.age.B(jj), eq.age.C(jj), eq.age.H(jj), eq.age.Rent(jj), eq.age.NW(jj), eq.age.M(jj), eq.age.homeownership(jj), eq.age.hasmortgage(jj)};
    end

    eqprev = eq;
end

report_ix = 1:min(cfg.ReportT, T);
max_path_gap = max(abs(log(generated_price(report_ix) ./ price_path(report_ix))));
max_abs_vote = max(abs(vote_resids(report_ix)));
mean_abs_vote = mean(abs(vote_resids(report_ix)));
max_abs_log_price = max(abs(log(price_path(report_ix) ./ base.reference_price)));
mean_homeownership = mean(homeownership(report_ix));
[verdict, message] = classify_path(max_path_gap, max_abs_vote, max_abs_log_price);

summary = cell2table({outer, cfg.ReportT, T, cfg.TailYears, cfg.PoliticalPassThrough, cfg.VoteScale, string(cfg.DemographicScenario), max_path_gap, max_abs_vote, mean_abs_vote, max_abs_log_price, mean_homeownership, verdict, message}, ...
    'VariableNames', {'outer_iter','report_T','internal_T','tail_years','political_pass_through','vote_scale','demographic_scenario','max_abs_path_gap','max_abs_vote_resid','mean_abs_vote_resid','max_abs_log_price_move','mean_homeownership','verdict','message'});
paths = cell2table(path_rows, 'VariableNames', {'outer_iter','period','year','is_report_period','political_pass_through','vote_scale','demographic_scenario','age_col_requested','age_col_used','age_year','demographic_horizon_capped','price_guess','price_generated','vote','vote_resid','pressure','restriction','homeownership','housing_demand','abs_log_path_gap','abs_log_price_move','path_relaxation'});
age_paths = cell2table(age_rows(1:age_row, :), 'VariableNames', {'outer_iter','period','year','is_report_period','political_pass_through','vote_scale','demographic_scenario','age_col_used','age_year','age_index','model_age','age_weight','B','C','H','Rent','NW','M','homeownership','hasmortgage'});
end

function tf = is_block_vote_mode(cfg)
mode = lower(string(cfg.VoteShiftMode));
tf = any(mode == ["block_vote", "periodic_block", "periodic_vote", "five_year_vote"]);
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

function age_share_out = apply_post_report_demographics(age_share, cfg, base)
mode = lower(string(cfg.PostReportDemographicMode));
age_share_out = age_share;
if any(mode == ["natural", "none", ""])
    return
end
report_col = min(base.reference_col + cfg.ReportT, size(age_share_out, 2));
last_col = min(base.reference_col + cfg.InternalT + 2, size(age_share_out, 2));
if last_col <= report_col
    return
end
report_vec = normalize_agevector(age_share_out(:, report_col));
steady_vec = normalize_agevector(base.agevector0);
tail_len = max(1, last_col - report_col);
for col = (report_col + 1):last_col
    switch mode
        case {"hold_report_end", "hold_terminal", "flat_tail"}
            next_vec = report_vec;
        case {"return_to_steady", "return_to_steady_state", "return_to_reference", "steady_state"}
            weight = min(1, (col - report_col) / tail_len);
            next_vec = (1 - weight) .* report_vec + weight .* steady_vec;
        otherwise
            error('Unknown PostReportDemographicMode: %s', cfg.PostReportDemographicMode);
    end
    age_share_out(:, col) = normalize_agevector(next_vec);
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
    case {"permanent_baby_boom", "permanent_entrant_increase", "birth_increase"}
        entrant_scale = (1 + amplitude) .* ones(n_forward, 1);
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

function write_note(note_path, cfg, base, summary, terminal_diag)
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Annual full RE price-path run\n\n');
fprintf(fid, 'This run solves households with perfect foresight over the house-price path.\n');
fprintf(fid, 'Demographics are exogenous; the expected aggregate object is the future price path.\n\n');
fprintf(fid, '- Scenario: `%s`\n', cfg.DemographicScenario);
fprintf(fid, '- T: `%d`\n', cfg.T);
fprintf(fid, '- Tail years: `%d`\n', cfg.TailYears);
fprintf(fid, '- Internal T: `%d`\n', cfg.InternalT);
fprintf(fid, '- Post-report demographic mode: `%s`\n', cfg.PostReportDemographicMode);
fprintf(fid, '- Terminal anchor: `%s`\n', cfg.TerminalAnchor);
fprintf(fid, '- Terminal iterations: `%d`\n', cfg.TerminalIter);
fprintf(fid, '- Outer iterations: `%d`\n', cfg.OuterIter);
fprintf(fid, '- Path relaxation: `%.6f`\n', cfg.PathRelaxation);
fprintf(fid, '- Path update method: `%s`\n', cfg.PathUpdateMethod);
fprintf(fid, '- Anderson memory: `%d`\n', round(cfg.AndersonMemory));
fprintf(fid, '- Anderson damping: `%.6f`\n', cfg.AndersonDamping);
fprintf(fid, '- Anderson ridge: `%.12g`\n', cfg.AndersonRidge);
fprintf(fid, '- Anderson coefficient cap: `%.6f`\n', cfg.AndersonCoeffCap);
fprintf(fid, '- Broyden damping: `%.6f`\n', cfg.BroydenDamping);
fprintf(fid, '- Broyden step cap: `%.6f`\n', cfg.BroydenStepCap);
fprintf(fid, '- Political pass-through: `%.6f`\n', cfg.PoliticalPassThrough);
fprintf(fid, '- Vote scale: `%.6f`\n', cfg.VoteScale);
fprintf(fid, '- Vote rule: `%s`\n', base.vote_params.rule);
fprintf(fid, '- Vote tau: `%.10g`\n', base.vote_params.tau);
fprintf(fid, '- Vote sigma: `%.10g`\n', base.vote_params.sigma);
fprintf(fid, '- Vote shift mode: `%s`\n', cfg.VoteShiftMode);
fprintf(fid, '- Vote shift horizon: `%d`\n', cfg.VoteShiftHorizon);
fprintf(fid, '- Vote block length: `%d`\n', cfg.VoteBlockLength);
fprintf(fid, '- Lagged pass-through: `%d`\n', cfg.LaggedPassThrough);
fprintf(fid, '- Pass-through lag years: `%d`\n', cfg.PassThroughLagYears);
fprintf(fid, '- Reference year: `%d`\n', base.reference_year);
fprintf(fid, '- Reference price: `%.6f`\n', base.reference_price);
fprintf(fid, '- Target vote: `%.6f`\n', base.target_vote);
fprintf(fid, '- Source: `%s`\n\n', base.source_path);
if nargin >= 5 && ~isempty(terminal_diag)
    fprintf(fid, 'Terminal steady-state anchor diagnostic:\n\n');
    fprintf(fid, '- Terminal price: `%.6f`\n', terminal_diag.terminal_price);
    fprintf(fid, '- Terminal generated price: `%.6f`\n', terminal_diag.terminal_generated_price);
    fprintf(fid, '- Terminal price gap: `%.6f`\n', terminal_diag.terminal_abs_log_gap);
    fprintf(fid, '- Terminal vote residual: `%.6f`\n\n', terminal_diag.terminal_vote_resid);
end
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
