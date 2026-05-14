function run_pf_bridge_0511(row_id, varargin)
% Narrow perfect-foresight bridge/polish probes after T20/T40 continuation clears.

p = inputParser;
p.addRequired('row_id');
p.addParameter('GridCsv', fullfile(pwd, 'model_pf_bridge_0511.csv'));
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
    error('Expected exactly one bridge row for row_id %.0f, found %.0f.', row_id_num, height(row));
end

annual_dir = pwd;
re_root = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path');
nore_root = fullfile(annual_dir, 'truth', 'annual_political_transition_fail_safe');
run_tag = row_text(row, 'run_tag');
seed_path = build_seed(row, re_root, nore_root);

ttb_lag = row_number(row, 'ttb_proxy_lag_years');
lagged = ttb_lag > 0;
if ~lagged
    ttb_lag = 1;
end
pass_through = abs(row_number(row, 'pass_through'));

fprintf('Running PF bridge row %.0f: %s\n', row_id_num, run_tag);
run_annual_political_full_re_price_path( ...
    'RunTag', run_tag, ...
    'T', round(row_number(row, 'horizon_t')), ...
    'TailYears', round(row_number(row, 'tail_years')), ...
    'PostReportDemographicMode', 'return_to_steady_state', ...
    'TerminalAnchor', 'terminal_fixed_point', ...
    'TerminalIter', 180, ...
    'TerminalRelaxation', 0.12, ...
    'TerminalBlendWeight', 1.00, ...
    'OuterIter', round(row_number(row, 'outer_iter')), ...
    'PathRelaxation', row_number_default(row, 'path_relaxation', 0.012), ...
    'PathUpdateMethod', 'basis_broyden', ...
    'BasisDim', round(row_number(row, 'basis_dim')), ...
    'BasisDamping', row_number(row, 'basis_damping'), ...
    'BasisStepCap', row_number(row, 'basis_step_cap'), ...
    'BasisRidge', 1e-8, ...
    'BasisEndWeight', 10, ...
    'BasisTailWeight', row_number(row, 'basis_tail_weight'), ...
    'BasisFocusStart', row_number(row, 'basis_focus_start'), ...
    'BasisFocusEnd', row_number(row, 'basis_focus_end'), ...
    'BasisFocusWeight', row_number(row, 'basis_focus_weight'), ...
    'BroydenDamping', row_number(row, 'broyden_damping'), ...
    'BroydenStepCap', row_number(row, 'broyden_step_cap'), ...
    'PoliticalPassThrough', -pass_through, ...
    'VoteScale', 0.02, ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'block_vote', ...
    'VoteShiftHorizon', 4, ...
    'VoteBlockLength', 4, ...
    'LaggedPassThrough', lagged, ...
    'PassThroughLagYears', round(ttb_lag), ...
    'SourceMat', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat'), ...
    'DemographicScenario', 'published_baby_boom', ...
    'DemographicPathMat', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF', 'irfs_100.mat'), ...
    'DemographicPathVar', 'ageimpulse', ...
    'DemographicShockAmplitude', row_number(row, 'shock_amplitude'), ...
    'ReferenceYear', NaN, ...
    'InitialPathCsv', seed_path, ...
    'ModIrfDir', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF'), ...
    'ModFunctionsDir', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_Functions'), ...
    'CompeconDir', fullfile(cfg.RunRoot, 'COMPECON'));
end

function seed_path = build_seed(row, re_root, nore_root)
run_tag = row_text(row, 'run_tag');
horizon_t = round(row_number(row, 'horizon_t'));
source_tag = row_text(row, 'source_run_tag');
source_outer = row_number(row, 'source_outer');
nore_tag = row_text(row, 'no_re_tag');
hybrid_switch = min(round(row_number(row, 'hybrid_switch_period')), horizon_t);

source_paths = fullfile(re_root, source_tag, 'paths_all.csv');
if ~isfile(source_paths)
    error('Source RE paths not found: %s', source_paths);
end
src = readtable(source_paths);
src = src(src.outer_iter == source_outer, :);
src = sortrows(src, 'period');
if isempty(src) || ~ismember('price_generated', src.Properties.VariableNames)
    error('Bad source RE paths for %s outer %.0f.', source_tag, source_outer);
end

nore_paths = fullfile(nore_root, nore_tag, 'paths_T80.csv');
if ~isfile(nore_paths)
    error('No-RE seed paths not found: %s', nore_paths);
end
nore = readtable(nore_paths);
nore = sortrows(nore, 'period');
if ~ismember('price', nore.Properties.VariableNames)
    error('No-RE seed paths must contain price: %s', nore_paths);
end

seed = NaN(horizon_t, 1);
src_period = src.period;
src_price = src.price_generated;
nore_period = nore.period;
nore_price = nore.price;

src_keep = src_period >= 1 & src_period <= hybrid_switch;
seed(src_period(src_keep)) = src_price(src_keep);

if hybrid_switch < horizon_t
    shifted = shift_series_to_match(nore_period, nore_price, src_period, src_price, hybrid_switch);
    tail_keep = nore_period > hybrid_switch & nore_period <= horizon_t;
    seed(nore_period(tail_keep)) = shifted(tail_keep);
end

missing = find(~isfinite(seed) | seed <= 0);
if ~isempty(missing)
    error('Seed for %s has missing or non-positive periods; first missing period %.0f.', run_tag, missing(1));
end

seed_dir = fullfile(re_root, 'pf_bridge_0511_seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end
seed_path = fullfile(seed_dir, [run_tag '_seed.csv']);
writetable(table(seed, 'VariableNames', {'price'}), seed_path);
fprintf('Wrote bridge seed: %s\n', seed_path);
end

function shifted = shift_series_to_match(period, price, ref_period, ref_price, anchor_period)
idx = find(period == anchor_period, 1);
ref_idx = find(ref_period == anchor_period, 1);
if isempty(idx) || isempty(ref_idx)
    error('Cannot align seed at period %.0f.', anchor_period);
end
scale = ref_price(ref_idx) ./ price(idx);
shifted = price .* scale;
end

function value = row_text(row, name)
raw = row.(name);
if iscell(raw)
    raw = raw{1};
else
    raw = raw(1);
end
value = char(string(raw));
end

function value = row_number(row, name)
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
    error('Grid value %s is not numeric: %s', name, string(raw));
end
end

function value = row_number_default(row, name, default_value)
if ~ismember(name, row.Properties.VariableNames)
    value = default_value;
    return
end
value = row_number(row, name);
end
