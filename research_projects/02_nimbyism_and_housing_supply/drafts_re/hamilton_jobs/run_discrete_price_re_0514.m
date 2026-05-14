function run_discrete_price_re_0514(row_id, varargin)
% Discrete-price rational-expectations approximation for the annual model.
%
% Given a path whose entries lie on a small price grid, solve the household and
% political transition, project the generated price path back to the grid, and
% iterate on the finite sequence. This is a grid-state approximation to the
% full RE price-path fixed point, not a continuous full-RE result.

p = inputParser;
p.addRequired('row_id');
p.addParameter('GridCsv', fullfile(pwd, 'model_discrete_price_re_0514.csv'));
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
grid_tbl = readtable(cfg.GridCsv, opts);
row = grid_tbl(grid_tbl.row_id == row_id_num, :);
if height(row) ~= 1
    error('Expected exactly one row for row_id %.0f, found %.0f.', row_id_num, height(row));
end

run_tag = row_text(row, 'run_tag');
fprintf('Running discrete-price RE row %.0f: %s\n', row_id_num, run_tag);

annual_dir = pwd;
out_root = fullfile(annual_dir, 'truth', 'discrete_price_re');
out_dir = fullfile(out_root, run_tag);
seed_dir = fullfile(out_dir, 'seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end

horizon_t = round(row_number(row, 'horizon_t'));
tail_years = round(row_number_default(row, 'tail_years', 0));
internal_t = horizon_t + tail_years;
grid_points = round(row_number_default(row, 'grid_points', 3));
grid_span_pct = row_number_default(row, 'grid_span_pct', 0.05);
max_iters = round(row_number_default(row, 'max_discrete_iters', 6));
max_abs_log_move = row_number_default(row, 'max_abs_log_move', 0.18);

[seed, reference_price] = build_seed(row, annual_dir, internal_t);
price_grid = build_price_grid(reference_price, grid_points, grid_span_pct);
[price_path, state_idx] = snap_to_grid(seed, price_grid);

seen = containers.Map('KeyType', 'char', 'ValueType', 'double');
seen(state_key(state_idx)) = 0;
iteration_tables = {};
state_tables = {};
status = "max_iter_reached";
cycle_start = NaN;
cycle_length = NaN;

for iter = 1:max_iters
    iter_tag = sprintf('%s_iter%02d', run_tag, iter);
    seed_path = fullfile(seed_dir, sprintf('%s_seed.csv', iter_tag));
    writetable(table(price_path(:), state_idx(:), 'VariableNames', {'price','state_index'}), seed_path);

    run_one_grid_evaluation(row, cfg.RunRoot, iter_tag, seed_path);

    paths_path = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path', iter_tag, 'paths_all.csv');
    if ~isfile(paths_path)
        error('Expected grid-evaluation paths not found: %s', paths_path);
    end
    paths = readtable(paths_path);
    paths = paths(paths.outer_iter == 1, :);
    paths = sortrows(paths, 'period');
    if height(paths) < internal_t
        error('Grid-evaluation paths for %s have %.0f rows, expected %.0f.', iter_tag, height(paths), internal_t);
    end
    paths = paths(1:internal_t, :);

    [next_price, next_state] = snap_to_grid(paths.price_generated(:), price_grid);
    current_key = state_key(state_idx);
    next_key = state_key(next_state);
    fixed_sequence = strcmp(current_key, next_key);
    changed = state_idx(:) ~= next_state(:);
    report_ix = 1:min(horizon_t, numel(changed));
    continuous_gap = log(paths.price_generated(:) ./ price_path(:));
    quantized_gap = log(next_price(:) ./ price_path(:));

    iter_tbl = table( ...
        string(run_tag), iter, string(iter_tag), grid_points, grid_span_pct, reference_price, ...
        fixed_sequence, sum(changed(report_ix)), sum(changed), ...
        sqrt(mean(continuous_gap(report_ix).^2)), ...
        max(abs(continuous_gap(report_ix))), ...
        max(abs(quantized_gap(report_ix))), ...
        min(price_path(report_ix)), max(price_path(report_ix)), ...
        min(paths.price_generated(report_ix)), max(paths.price_generated(report_ix)), ...
        'VariableNames', {'run_tag','discrete_iter','temporary_run_tag','grid_points','grid_span_pct','reference_price', ...
        'fixed_sequence','changed_report_count','changed_internal_count','rmse_log_continuous_gap', ...
        'max_abs_log_continuous_gap','max_abs_log_quantized_gap','price_grid_path_min','price_grid_path_max', ...
        'price_generated_min','price_generated_max'});
    iteration_tables{end + 1} = iter_tbl; %#ok<AGROW>

    state_tbl = table( ...
        repmat(string(run_tag), internal_t, 1), repmat(iter, internal_t, 1), (1:internal_t)', ...
        paths.year(:), paths.is_report_period(:), state_idx(:), price_path(:), ...
        paths.price_generated(:), next_state(:), next_price(:), changed(:), ...
        continuous_gap(:), quantized_gap(:), paths.vote(:), paths.vote_resid(:), ...
        paths.pressure(:), paths.restriction(:), paths.homeownership(:), paths.housing_demand(:), ...
        'VariableNames', {'run_tag','discrete_iter','period','year','is_report_period','state_index','price_grid_current', ...
        'price_generated_continuous','state_index_next','price_grid_next','state_changed', ...
        'log_continuous_gap','log_quantized_gap','vote','vote_resid','pressure','restriction','homeownership','housing_demand'});
    state_tables{end + 1} = state_tbl; %#ok<AGROW>

    write_partial_outputs(out_dir, iteration_tables, state_tables, price_grid, status, cycle_start, cycle_length);
    fprintf('  iter %d: changed report %.0f, changed internal %.0f, max continuous gap %.6g, max quantized gap %.6g\n', ...
        iter, iter_tbl.changed_report_count, iter_tbl.changed_internal_count, ...
        iter_tbl.max_abs_log_continuous_gap, iter_tbl.max_abs_log_quantized_gap);

    if fixed_sequence
        status = sprintf('fixed_sequence_iter_%d', iter);
        break;
    end
    if isKey(seen, next_key)
        cycle_start = seen(next_key);
        cycle_length = iter - cycle_start + 1;
        status = sprintf('cycle_detected_iter_%d_length_%d', iter, cycle_length);
        break;
    end
    seen(next_key) = iter;
    price_path = next_price;
    state_idx = next_state;
end

write_partial_outputs(out_dir, iteration_tables, state_tables, price_grid, status, cycle_start, cycle_length);
write_note(fullfile(out_dir, 'note.md'), row, status, price_grid, cycle_start, cycle_length);
fprintf('Discrete-price RE row complete: %s (%s)\n', run_tag, status);
end

function run_one_grid_evaluation(row, run_root, iter_tag, seed_path)
pass_through = abs(row_number(row, 'pass_through'));
ttb_lag = round(row_number_default(row, 'ttb_proxy_lag_years', 0));
lagged = ttb_lag > 0;
if ~lagged
    ttb_lag = 1;
end
demo_scenario = row_text(row, 'demographic_scenario');
demo_path = demographic_path_for_scenario(demo_scenario, run_root);

run_annual_political_full_re_price_path( ...
    'RunTag', iter_tag, ...
    'T', round(row_number(row, 'horizon_t')), ...
    'TailYears', round(row_number_default(row, 'tail_years', 0)), ...
    'PostReportDemographicMode', row_text_default(row, 'post_report_mode', 'return_to_steady_state'), ...
    'TerminalAnchor', row_text_default(row, 'terminal_anchor', 'terminal_fixed_point'), ...
    'TerminalIter', 150, ...
    'TerminalRelaxation', row_number_default(row, 'terminal_relaxation', 0.12), ...
    'TerminalBlendWeight', row_number_default(row, 'terminal_blend_weight', 1.00), ...
    'OuterIter', 1, ...
    'PathRelaxation', 0.0, ...
    'PathUpdateMethod', 'relaxation', ...
    'PoliticalPassThrough', -pass_through, ...
    'VoteScale', row_number_default(row, 'vote_scale', 0.02), ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'block_vote', ...
    'VoteShiftHorizon', 4, ...
    'VoteBlockLength', 4, ...
    'LaggedPassThrough', lagged, ...
    'PassThroughLagYears', ttb_lag, ...
    'MaxAbsLogPriceMove', row_number_default(row, 'max_abs_log_move', 0.18), ...
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

function [seed, reference_price] = build_seed(row, annual_dir, internal_t)
source_mode = lower(string(row_text_default(row, 'source_mode', 'reference')));
seed_mode = lower(string(row_text_default(row, 'seed_mode', 'flat')));
source_price = [];

switch source_mode
    case {"re_source", "re_generated"}
        source_tag = row_text(row, 'source_run_tag');
        source_outer = round(row_number(row, 'source_outer'));
        source_col = row_text_default(row, 'source_price_column', 'price_generated');
        source_paths = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path', source_tag, 'paths_all.csv');
        if ~isfile(source_paths)
            error('Source RE paths not found: %s', source_paths);
        end
        src = readtable(source_paths);
        src = src(src.outer_iter == source_outer, :);
        src = sortrows(src, 'period');
        if isempty(src)
            error('No source rows for %s outer %.0f.', source_tag, source_outer);
        end
        if ismember(source_col, src.Properties.VariableNames)
            source_price = src.(source_col);
        elseif ismember('price_generated', src.Properties.VariableNames)
            source_price = src.price_generated;
        elseif ismember('price_guess', src.Properties.VariableNames)
            source_price = src.price_guess;
        else
            error('Source RE paths lack price columns: %s', source_paths);
        end
    case {"nore", "no_re"}
        nore_tag = row_text(row, 'nore_tag');
        source_paths = fullfile(annual_dir, 'truth', 'annual_political_transition_fail_safe', nore_tag, sprintf('paths_T%d.csv', internal_t));
        if ~isfile(source_paths)
            source_paths = fullfile(annual_dir, 'truth', 'annual_political_transition_fail_safe', nore_tag, 'paths_all.csv');
        end
        if ~isfile(source_paths)
            error('No-RE source paths not found: %s', source_paths);
        end
        src = readtable(source_paths);
        src = sortrows(src, 'period');
        if ismember('price', src.Properties.VariableNames)
            source_price = src.price;
        elseif ismember('PriceHouse', src.Properties.VariableNames)
            source_price = src.PriceHouse;
        else
            error('No-RE paths lack a price column: %s', source_paths);
        end
    case {"reference", "flat", "none", ""}
        source_price = [];
    otherwise
        error('Unknown source_mode: %s', source_mode);
end

if isempty(source_price)
    reference_price = row_number(row, 'reference_price');
else
    source_price = source_price(:);
    reference_price = source_price(1);
end
if ~isfinite(reference_price) || reference_price <= 0
    error('Invalid reference price.');
end

switch seed_mode
    case {"flat", "reference", ""}
        seed = reference_price .* ones(internal_t, 1);
    case {"source", "source_quantized"}
        seed = source_price(:);
    case {"high_after"}
        switch_period = round(row_number_default(row, 'switch_period', 12));
        high_price = reference_price * (1 + row_number_default(row, 'grid_span_pct', 0.05));
        seed = reference_price .* ones(internal_t, 1);
        seed(max(1, switch_period):end) = high_price;
    case {"low_after"}
        switch_period = round(row_number_default(row, 'switch_period', 12));
        low_price = reference_price * (1 - row_number_default(row, 'grid_span_pct', 0.05));
        seed = reference_price .* ones(internal_t, 1);
        seed(max(1, switch_period):end) = low_price;
    otherwise
        error('Unknown seed_mode: %s', seed_mode);
end

seed = seed(:);
if numel(seed) < internal_t
    seed = [seed; seed(end) .* ones(internal_t - numel(seed), 1)];
else
    seed = seed(1:internal_t);
end
if any(~isfinite(seed) | seed <= 0)
    error('Seed has missing or non-positive prices.');
end
end

function grid = build_price_grid(reference_price, grid_points, grid_span_pct)
if grid_points < 2
    error('grid_points must be at least 2.');
end
if grid_span_pct <= 0 || grid_span_pct >= 0.50
    error('grid_span_pct must be in (0, 0.50).');
end
log_offsets = linspace(log(1 - grid_span_pct), log(1 + grid_span_pct), grid_points);
grid = reference_price .* exp(log_offsets(:));
[~, closest_ref] = min(abs(grid - reference_price));
grid(closest_ref) = reference_price;
end

function [snapped_price, state_idx] = snap_to_grid(price, grid)
price = price(:);
log_grid = log(grid(:));
log_price = log(price);
state_idx = nan(numel(price), 1);
for t = 1:numel(price)
    [~, state_idx(t)] = min(abs(log_grid - log_price(t)));
end
snapped_price = grid(state_idx);
end

function key = state_key(state_idx)
key = sprintf('%d_', state_idx(:));
end

function write_partial_outputs(out_dir, iteration_tables, state_tables, price_grid, status, cycle_start, cycle_length)
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
if ~isempty(iteration_tables)
    writetable(vertcat(iteration_tables{:}), fullfile(out_dir, 'discrete_iterations.csv'));
end
if ~isempty(state_tables)
    writetable(vertcat(state_tables{:}), fullfile(out_dir, 'discrete_states_all.csv'));
end
grid_tbl = table((1:numel(price_grid))', price_grid(:), log(price_grid(:) ./ price_grid(ceil(numel(price_grid) / 2))), ...
    'VariableNames', {'state_index','price','log_relative_to_mid_state'});
writetable(grid_tbl, fullfile(out_dir, 'price_grid.csv'));
status_tbl = table(string(status), cycle_start, cycle_length, 'VariableNames', {'status','cycle_start','cycle_length'});
writetable(status_tbl, fullfile(out_dir, 'status.csv'));
end

function write_note(note_path, row, status, price_grid, cycle_start, cycle_length)
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Discrete-price RE approximation\n\n');
fprintf(fid, '- Run tag: `%s`\n', row_text(row, 'run_tag'));
fprintf(fid, '- Status: `%s`\n', status);
fprintf(fid, '- Grid points: `%d`\n', numel(price_grid));
fprintf(fid, '- Grid min/mid/max: `%.8f`, `%.8f`, `%.8f`\n', price_grid(1), price_grid(ceil(numel(price_grid) / 2)), price_grid(end));
if isfinite(cycle_start)
    fprintf(fid, '- Cycle start: `%g`\n', cycle_start);
    fprintf(fid, '- Cycle length: `%g`\n', cycle_length);
end
fprintf(fid, '\nThis is Zac-style price-grid simplification. It searches over a finite price-state sequence by repeatedly projecting the continuous generated price path back onto the price grid. A fixed sequence is a discrete-grid fixed point. A cycle is evidence that the projected map does not settle under this starting seed.\n');
end

function demo_path = demographic_path_for_scenario(demo_scenario, run_root)
annual_dir = pwd;
if any(lower(string(demo_scenario)) == ["external_age_path", "official_projection", "projection_external"])
    demo_path = fullfile(annual_dir, 'official_age_path_0512.mat');
else
    demo_path = fullfile(run_root, 'SteadyState', 'Mod_IRF', 'irfs_100.mat');
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
if isstring(raw) || ischar(raw)
    txt = strtrim(string(raw));
    if strlength(txt) == 0 || any(lower(txt) == ["nan", "missing", "<missing>"])
        value = default;
    else
        value = str2double(txt);
    end
else
    value = double(raw);
end
if ~isscalar(value) || ~isfinite(value)
    value = default;
end
end
