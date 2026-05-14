function run_t80_model_grid_0511(row_id, varargin)
% Parameterized first-wave T80 model grid runner.
%
% Submit from the Hamilton annual directory. Each Slurm array task reads one
% row from model_grid_0511.csv and runs the corresponding RE branch. The grid
% is intentionally sparse: terminal continuation, ghost tails, delivery-lag
% proxy, and pass-through robustness are crossed only where they answer a
% distinct modelling question.

p = inputParser;
p.addRequired('row_id');
p.addParameter('GridCsv', fullfile(pwd, 'model_grid_0511.csv'));
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

if ~isfile(cfg.GridCsv)
    error('Grid CSV not found: %s', cfg.GridCsv);
end
opts = detectImportOptions(cfg.GridCsv, 'TextType', 'string');
grid = readtable(cfg.GridCsv, opts);
row = grid(grid.row_id == row_id_num, :);
if height(row) ~= 1
    error('Expected exactly one grid row for row_id %.0f, found %.0f.', row_id_num, height(row));
end

family = lower(string(row_text(row, 'family')));
fprintf('Running model grid row %.0f: %s (%s)\n', row_id_num, row_text(row, 'run_tag'), family);
switch family
    case "re"
        run_re_row(row, cfg.RunRoot);
    case "nore"
        run_nore_row(row, cfg.RunRoot);
    otherwise
        error('Unsupported model-grid family: %s', family);
end
end

function run_re_row(row, run_root)
annual_dir = pwd;
re_root = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path');
seed_path = build_re_seed(row, re_root, fullfile(annual_dir, 'truth', 'annual_political_transition_fail_safe'));

ttb_lag = row_number(row, 'ttb_proxy_lag_years');
lagged = ttb_lag > 0;
if ~lagged
    ttb_lag = 1;
end
pass_through = abs(row_number(row, 'pass_through'));

run_annual_political_full_re_price_path( ...
    'RunTag', row_text(row, 'run_tag'), ...
    'T', 80, ...
    'TailYears', round(row_number(row, 'tail_years')), ...
    'PostReportDemographicMode', row_text(row, 'post_report_demographic_mode'), ...
    'TerminalAnchor', row_text(row, 'terminal_anchor'), ...
    'TerminalIter', 180, ...
    'TerminalRelaxation', 0.12, ...
    'TerminalBlendWeight', 1.00, ...
    'OuterIter', round(row_number(row, 'outer_iter')), ...
    'PathRelaxation', 0.02, ...
    'PathUpdateMethod', 'basis_broyden', ...
    'BasisDim', round(row_number(row, 'basis_dim')), ...
    'BasisDamping', 0.25, ...
    'BasisStepCap', row_number(row, 'basis_step_cap'), ...
    'BasisRidge', 1e-8, ...
    'BasisEndWeight', 10, ...
    'BasisTailWeight', row_number(row, 'basis_tail_weight'), ...
    'BasisFocusStart', 6, ...
    'BasisFocusEnd', 8, ...
    'BasisFocusWeight', 8, ...
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
    'SourceMat', fullfile(run_root, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat'), ...
    'DemographicScenario', 'published_baby_boom', ...
    'DemographicPathMat', fullfile(run_root, 'SteadyState', 'Mod_IRF', 'irfs_100.mat'), ...
    'DemographicPathVar', 'ageimpulse', ...
    'DemographicShockAmplitude', 0.25, ...
    'ReferenceYear', NaN, ...
    'InitialPathCsv', seed_path, ...
    'ModIrfDir', fullfile(run_root, 'SteadyState', 'Mod_IRF'), ...
    'ModFunctionsDir', fullfile(run_root, 'SteadyState', 'Mod_Functions'), ...
    'CompeconDir', fullfile(run_root, 'COMPECON'));
end

function run_nore_row(row, run_root)
ttb_lag = row_number(row, 'ttb_proxy_lag_years');
lagged = ttb_lag > 0;
if ~lagged
    ttb_lag = 1;
end
pass_through = abs(row_number(row, 'pass_through'));
run_annual_political_transition_fail_safe( ...
    'RunTag', row_text(row, 'run_tag'), ...
    'TSchedule', [20 80], ...
    'VoteScale', 0.02, ...
    'RestrictionCap', 0.25, ...
    'MaxAbsLogPriceMove', 0.18, ...
    'PeriodIter', 3, ...
    'UpdateRelaxation', 0.75, ...
    'LaggedPassThrough', lagged, ...
    'PassThroughLagYears', round(ttb_lag), ...
    'AgeWeightVariant', 'baseline', ...
    'PressureMode', 'smooth', ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'block_vote', ...
    'VoteBlockLength', 4, ...
    'SourceMat', fullfile(run_root, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat'), ...
    'DemographicScenario', 'published_baby_boom', ...
    'DemographicPathMat', fullfile(run_root, 'SteadyState', 'Mod_IRF', 'irfs_100.mat'), ...
    'DemographicPathVar', 'ageimpulse', ...
    'DemographicShockAmplitude', 0.25, ...
    'PoliticalCandidates', [0, -pass_through, 1], ...
    'ModIrfDir', fullfile(run_root, 'SteadyState', 'Mod_IRF'), ...
    'ModFunctionsDir', fullfile(run_root, 'SteadyState', 'Mod_Functions'), ...
    'CompeconDir', fullfile(run_root, 'COMPECON'));
end

function seed_path = build_re_seed(row, re_root, nore_root)
run_tag = row_text(row, 'run_tag');
source_tag = row_text(row, 'source_run_tag');
source_outer = row_number(row, 'source_outer');
nore_tag = row_text(row, 'no_re_tag');
seed_mode = lower(string(row_text(row, 'seed_mode')));
hybrid_switch = round(row_number(row, 'hybrid_switch_period'));

source_paths = fullfile(re_root, source_tag, 'paths_all.csv');
if ~isfile(source_paths)
    error('Source RE paths not found: %s', source_paths);
end
src = readtable(source_paths);
src = src(src.outer_iter == source_outer, :);
src = sortrows(src, 'period');
if isempty(src)
    error('No source outer_iter %.0f in %s.', source_outer, source_paths);
end
if ~ismember('price_generated', src.Properties.VariableNames)
    error('Source paths must contain price_generated: %s', source_paths);
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

src_period = src.period;
src_price = src.price_generated;
nore_period = nore.period;
nore_price = nore.price;
seed = NaN(80, 1);

switch seed_mode
    case "nore_full"
        keep = nore_period >= 1 & nore_period <= 80;
        seed(nore_period(keep)) = nore_price(keep);
    case "nore_shifted"
        shifted = shift_series_to_match(nore_period, nore_price, src_period, src_price, 1);
        keep = nore_period >= 1 & nore_period <= 80;
        seed(nore_period(keep)) = shifted(keep);
    case "hybrid_shifted"
        switch_period = min(hybrid_switch, max(src_period));
        src_keep = src_period >= 1 & src_period <= min(switch_period, 80);
        seed(src_period(src_keep)) = src_price(src_keep);
        shifted = shift_series_to_match(nore_period, nore_price, src_period, src_price, switch_period);
        tail_keep = nore_period > switch_period & nore_period <= 80;
        seed(nore_period(tail_keep)) = shifted(tail_keep);
    otherwise
        error('Unsupported seed_mode: %s', seed_mode);
end

if any(~isfinite(seed)) || any(seed <= 0)
    error('Seed for %s has missing or non-positive periods in 1:80.', run_tag);
end

seed_dir = fullfile(re_root, 't80_model_grid_0511_seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end
seed_path = fullfile(seed_dir, [run_tag '_seed.csv']);
writetable(table(seed, 'VariableNames', {'price'}), seed_path);
fprintf('Wrote grid seed: %s\n', seed_path);
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
