function run_re_wide_0512(row_id, varargin)
% Thirteen-hour wide T80 transition search for annual baby-boom RE.

p = inputParser;
p.addRequired('row_id');
p.addParameter('GridCsv', fullfile(pwd, 'model_re_wide_0512.csv'));
p.addParameter('RunRoot', fileparts(pwd));
p.parse(row_id, varargin{:});
cfg = p.Results;

if ischar(cfg.row_id) || isstring(cfg.row_id)
    row_id_num = str2double(string(cfg.row_id));
else
    row_id_num = cfg.row_id;
end
if ~isfinite(row_id_num)
    error('Invalid row_id: %s', string(cfg.row_id));
end

opts = detectImportOptions(cfg.GridCsv, 'TextType', 'string');
grid = readtable(cfg.GridCsv, opts);
row = grid(grid.row_id == row_id_num, :);
if height(row) ~= 1
    error('Expected exactly one row for row_id %.0f, found %.0f.', row_id_num, height(row));
end

family = lower(string(row_text(row, 'family')));
fprintf('Running wide T80 RE row %.0f: %s (%s)\n', row_id_num, row_text(row, 'run_tag'), family);
switch family
    case "nore"
        run_no_re(row, cfg.RunRoot);
    case "re"
        run_re(row, cfg.RunRoot);
    otherwise
        error('Unknown family: %s', family);
end
end

function run_no_re(row, run_root)
run_tag = row_text(row, 'run_tag');
T = round(row_number(row, 'horizon_t'));
pass_through = abs(row_number(row, 'pass_through'));
ttb_lag = round(row_number_default(row, 'ttb_proxy_lag_years', 0));
lagged = ttb_lag > 0;
if ~lagged
    ttb_lag = 1;
end
demo_scenario = row_text(row, 'demographic_scenario');
demo_path = demographic_path_for_scenario(demo_scenario, run_root);

run_annual_political_transition_fail_safe( ...
    'RunTag', run_tag, ...
    'TSchedule', T, ...
    'VoteScale', row_number_default(row, 'vote_scale', 0.02), ...
    'RestrictionCap', 0.25, ...
    'MaxAbsLogPriceMove', 0.18, ...
    'PeriodIter', round(row_number_default(row, 'period_iter', 3)), ...
    'UpdateRelaxation', row_number_default(row, 'update_relaxation', 0.75), ...
    'LaggedPassThrough', lagged, ...
    'PassThroughLagYears', ttb_lag, ...
    'AgeWeightVariant', 'baseline', ...
    'PressureMode', 'smooth', ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'block_vote', ...
    'VoteBlockLength', 4, ...
    'SourceMat', fullfile(run_root, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat'), ...
    'DemographicScenario', demo_scenario, ...
    'DemographicPathMat', demo_path, ...
    'DemographicPathVar', 'ageimpulse', ...
    'DemographicShockAmplitude', row_number_default(row, 'shock_amplitude', 0.25), ...
    'PoliticalCandidates', [0, -pass_through, 1], ...
    'ModIrfDir', fullfile(run_root, 'SteadyState', 'Mod_IRF'), ...
    'ModFunctionsDir', fullfile(run_root, 'SteadyState', 'Mod_Functions'), ...
    'CompeconDir', fullfile(run_root, 'COMPECON'));
end

function run_re(row, run_root)
annual_dir = pwd;
re_root = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path');
nore_root = fullfile(annual_dir, 'truth', 'annual_political_transition_fail_safe');
run_tag = row_text(row, 'run_tag');
seed_path = build_seed(row, re_root, nore_root);

ttb_lag = round(row_number_default(row, 'ttb_proxy_lag_years', 0));
lagged = ttb_lag > 0;
if ~lagged
    ttb_lag = 1;
end
pass_through = abs(row_number(row, 'pass_through'));
demo_scenario = row_text(row, 'demographic_scenario');
demo_path = demographic_path_for_scenario(demo_scenario, run_root);

run_annual_political_full_re_price_path( ...
    'RunTag', run_tag, ...
    'T', round(row_number(row, 'horizon_t')), ...
    'TailYears', round(row_number_default(row, 'tail_years', 20)), ...
    'PostReportDemographicMode', row_text_default(row, 'post_report_mode', 'return_to_steady_state'), ...
    'TerminalAnchor', row_text_default(row, 'terminal_anchor', 'terminal_fixed_point'), ...
    'TerminalIter', round(row_number_default(row, 'terminal_iter', 180)), ...
    'TerminalRelaxation', row_number_default(row, 'terminal_relaxation', 0.12), ...
    'TerminalBlendWeight', row_number_default(row, 'terminal_blend_weight', 1.00), ...
    'OuterIter', round(row_number_default(row, 'outer_iter', 10)), ...
    'PathRelaxation', row_number_default(row, 'path_relaxation', 0.01), ...
    'PathUpdateMethod', row_text_default(row, 'path_update_method', 'basis_broyden'), ...
    'BasisDim', round(row_number_default(row, 'basis_dim', 6)), ...
    'BasisDamping', row_number_default(row, 'basis_damping', 0.24), ...
    'BasisStepCap', row_number_default(row, 'basis_step_cap', 0.00045), ...
    'BasisRidge', 1e-8, ...
    'BasisEndWeight', row_number_default(row, 'basis_end_weight', 10), ...
    'BasisTailWeight', row_number_default(row, 'basis_tail_weight', 0.12), ...
    'BasisFocusStart', row_number_default(row, 'basis_focus_start', NaN), ...
    'BasisFocusEnd', row_number_default(row, 'basis_focus_end', NaN), ...
    'BasisFocusWeight', row_number_default(row, 'basis_focus_weight', 1), ...
    'BroydenDamping', row_number_default(row, 'broyden_damping', 0.42), ...
    'BroydenStepCap', row_number_default(row, 'broyden_step_cap', 0.0025), ...
    'PoliticalPassThrough', -pass_through, ...
    'VoteScale', row_number_default(row, 'vote_scale', 0.02), ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', row_text_default(row, 'vote_shift_mode', 'block_vote'), ...
    'VoteShiftHorizon', round(row_number_default(row, 'vote_shift_horizon', row_number_default(row, 'vote_block_length', 4))), ...
    'VoteBlockLength', round(row_number_default(row, 'vote_block_length', 4)), ...
    'LaggedPassThrough', lagged, ...
    'PassThroughLagYears', ttb_lag, ...
    'MaxAbsLogPriceMove', row_number_default(row, 'max_abs_log_price_move', 0.18), ...
    'SourceMat', fullfile(run_root, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat'), ...
    'DemographicScenario', demo_scenario, ...
    'DemographicPathMat', demo_path, ...
    'DemographicPathVar', 'ageimpulse', ...
    'DemographicShockAmplitude', row_number_default(row, 'shock_amplitude', 0.25), ...
    'ReferenceYear', NaN, ...
    'InitialPathCsv', seed_path, ...
    'ModIrfDir', fullfile(run_root, 'SteadyState', 'Mod_IRF'), ...
    'ModFunctionsDir', fullfile(run_root, 'SteadyState', 'Mod_Functions'), ...
    'CompeconDir', fullfile(run_root, 'COMPECON'));
end

function demo_path = demographic_path_for_scenario(demo_scenario, run_root)
annual_dir = pwd;
if any(lower(string(demo_scenario)) == ["external_age_path", "official_projection", "projection_external"])
    demo_path = fullfile(annual_dir, 'official_age_path_0512.mat');
else
    demo_path = fullfile(run_root, 'SteadyState', 'Mod_IRF', 'irfs_100.mat');
end
end

function seed_path = build_seed(row, re_root, nore_root)
mode = lower(string(row_text_default(row, 'source_mode', 'flat')));
run_tag = row_text(row, 'run_tag');
horizon_t = round(row_number(row, 'horizon_t'));
switch mode
    case {"flat", "none", ""}
        seed_path = '';
        return
    case {"re_source", "re_generated"}
        price = read_re_source(row, re_root);
    case {"nore", "no_re"}
        price = read_nore_source(row, nore_root, horizon_t);
    case {"hybrid_re_nore", "splice_re_nore", "re_then_nore"}
        re_price = extend_seed(read_re_source(row, re_root), horizon_t);
        no_price = extend_seed(read_nore_source(row, nore_root, horizon_t), horizon_t);
        switch_t = round(row_number_default(row, 'hybrid_switch_period', min(numel(re_price), horizon_t)));
        switch_t = max(1, min(horizon_t, switch_t));
        if no_price(switch_t) <= 0
            error('No-RE seed has non-positive switch price for %s.', run_tag);
        end
        shifted_no = no_price .* (re_price(switch_t) ./ no_price(switch_t));
        price = [re_price(1:switch_t); shifted_no((switch_t + 1):horizon_t)];
    case {"blend_re_nore", "convex_re_nore"}
        re_price = extend_seed(read_re_source(row, re_root), horizon_t);
        no_price = extend_seed(read_nore_source(row, nore_root, horizon_t), horizon_t);
        switch_t = round(row_number_default(row, 'hybrid_switch_period', min(numel(re_price), horizon_t)));
        switch_t = max(1, min(horizon_t, switch_t));
        if no_price(switch_t) <= 0
            error('No-RE seed has non-positive switch price for %s.', run_tag);
        end
        shifted_no = no_price .* (re_price(switch_t) ./ no_price(switch_t));
        w = min(max(row_number_default(row, 'seed_blend_weight', 0.50), 0), 1);
        price = exp(w .* log(re_price) + (1 - w) .* log(shifted_no));
    otherwise
        error('Unknown source_mode: %s', mode);
end

seed = extend_seed(price, horizon_t);
if any(~isfinite(seed) | seed <= 0)
    error('Seed for %s has missing or non-positive prices.', run_tag);
end
seed_dir = fullfile(re_root, 're_wide_0512_seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end
seed_path = fullfile(seed_dir, [run_tag '_seed.csv']);
writetable(table(seed, 'VariableNames', {'price'}), seed_path);
fprintf('Wrote seed: %s\n', seed_path);
end

function price = read_re_source(row, re_root)
source_tag = row_text(row, 'source_run_tag');
source_outer = round(row_number(row, 'source_outer'));
source_paths = fullfile(re_root, source_tag, 'paths_all.csv');
if ~isfile(source_paths)
    error('Source RE paths not found: %s', source_paths);
end
src = readtable(source_paths);
src = src(src.outer_iter == source_outer, :);
src = sortrows(src, 'period');
if isempty(src)
    error('No source rows for %s outer %.0f.', source_tag, source_outer);
end
if ismember('price_generated', src.Properties.VariableNames)
    price = src.price_generated;
elseif ismember('price_guess', src.Properties.VariableNames)
    price = src.price_guess;
else
    error('Source RE paths lack price columns: %s', source_paths);
end
price = price(:);
end

function price = read_nore_source(row, nore_root, horizon_t)
nore_tag = row_text(row, 'nore_tag');
source_paths = fullfile(nore_root, nore_tag, sprintf('paths_T%d.csv', horizon_t));
if ~isfile(source_paths)
    source_paths = fullfile(nore_root, nore_tag, 'paths_all.csv');
end
if ~isfile(source_paths)
    error('No-RE seed paths not found: %s', source_paths);
end
src = readtable(source_paths);
src = sortrows(src, 'period');
if ismember('price', src.Properties.VariableNames)
    price = src.price;
elseif ismember('PriceHouse', src.Properties.VariableNames)
    price = src.PriceHouse;
else
    error('No-RE paths lack a price column: %s', source_paths);
end
price = price(:);
end

function seed = extend_seed(price, horizon_t)
seed = price(:);
if numel(seed) < horizon_t
    seed = [seed; seed(end) .* ones(horizon_t - numel(seed), 1)];
else
    seed = seed(1:horizon_t);
end
end

function value = row_text(row, name)
value = row_text_default(row, name, '');
if strlength(string(value)) == 0
    error('Grid value %s is empty.', name);
end
end

function value = row_text_default(row, name, default)
if ~ismember(name, row.Properties.VariableNames)
    value = default;
    return
end
raw = row.(name);
if iscell(raw)
    raw = raw{1};
else
    raw = raw(1);
end
txt = strtrim(string(raw));
if strlength(txt) == 0 || any(lower(txt) == ["nan", "missing", "<missing>"])
    value = default;
else
    value = char(txt);
end
end

function value = row_number(row, name)
value = row_number_default(row, name, NaN);
if ~isfinite(value)
    error('Grid value %s is not numeric.', name);
end
end

function value = row_number_default(row, name, default)
if ~ismember(name, row.Properties.VariableNames)
    value = default;
    return
end
raw = row.(name);
if iscell(raw)
    raw = raw{1};
else
    raw = raw(1);
end
if isnumeric(raw)
    value = double(raw);
else
    value = str2double(string(raw));
end
if ~isfinite(value)
    value = default;
end
end
