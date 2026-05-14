function run_moll_direct_price_beliefs_0514(row_id, varargin)
% Moll-aligned direct price-belief routes for the annual political model.
%
% This runner treats the annual full-RE solver as a temporary-equilibrium
% evaluator: for a supplied subjective future price path, it computes the
% generated/current-price path. The learning routes then update the perceived
% price law from those generated prices. This is deliberately not labeled as a
% full rational-expectations result.

p = inputParser;
p.addRequired('row_id');
p.addParameter('GridCsv', fullfile(pwd, 'model_moll_direct_0514.csv'));
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

run_tag = row_text(row, 'run_tag');
route = lower(string(row_text(row, 'route')));
fprintf('Running Moll direct-price-beliefs row %.0f: %s (%s)\n', row_id_num, run_tag, route);

annual_dir = pwd;
out_root = fullfile(annual_dir, 'truth', 'moll_direct_price_beliefs');
out_dir = fullfile(out_root, run_tag);
seed_dir = fullfile(out_dir, 'seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end

horizon_t = round(row_number(row, 'horizon_t'));
tail_years = round(row_number_default(row, 'tail_years', 0));
internal_t = horizon_t + tail_years;
max_learning_iters = round(row_number_default(row, 'learning_iters', 1));
convergence_tol = row_number_default(row, 'convergence_tol', 2.5e-4);
max_abs_log_move = row_number_default(row, 'max_abs_log_move', 0.18);

price_path = build_seed(row, annual_dir, internal_t);
reference_price = price_path(1);
price_path = clamp_price_path(price_path, reference_price, max_abs_log_move);

iter_tables = {};
path_tables = {};
coef_tables = {};
coeffs = [];
status = "max_iter_reached";

for iter = 1:max_learning_iters
    iter_tag = sprintf('%s_iter%02d', run_tag, iter);
    seed_path = fullfile(seed_dir, sprintf('%s_seed.csv', iter_tag));
    writetable(table(price_path(:), 'VariableNames', {'price'}), seed_path);

    run_one_temporary_equilibrium(row, cfg.RunRoot, iter_tag, seed_path);

    paths_path = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path', iter_tag, 'paths_all.csv');
    if ~isfile(paths_path)
        error('Expected temporary-equilibrium paths not found: %s', paths_path);
    end
    paths = readtable(paths_path);
    paths = paths(paths.outer_iter == 1, :);
    paths = sortrows(paths, 'period');
    if height(paths) < internal_t
        error('Temporary-equilibrium paths for %s have %.0f rows, expected at least %.0f.', iter_tag, height(paths), internal_t);
    end
    paths = paths(1:internal_t, :);

    [next_price, coeffs, coef_tbl] = update_direct_belief_path(route, row, paths, price_path, coeffs, reference_price, max_abs_log_move);
    log_update = log(next_price(:) ./ price_path(:));
    forecast_errors = log(paths.price_generated(:) ./ paths.price_guess(:));
    report_ix = 1:min(horizon_t, numel(forecast_errors));
    update_ix = 1:min(horizon_t, numel(log_update));

    iter_tbl = table( ...
        string(run_tag), route, iter, string(iter_tag), ...
        sqrt(mean(forecast_errors(report_ix).^2)), ...
        max(abs(forecast_errors(report_ix))), ...
        max(abs(log_update(update_ix))), ...
        min(paths.price_guess(report_ix)), max(paths.price_guess(report_ix)), ...
        min(paths.price_generated(report_ix)), max(paths.price_generated(report_ix)), ...
        'VariableNames', {'run_tag','route','learning_iter','temporary_run_tag', ...
        'rmse_log_forecast_error','max_abs_log_forecast_error','max_abs_log_belief_update', ...
        'price_guess_min','price_guess_max','price_generated_min','price_generated_max'});
    iter_tables{end + 1} = iter_tbl; %#ok<AGROW>

    paths.moll_run_tag = repmat(string(run_tag), height(paths), 1);
    paths.moll_route = repmat(route, height(paths), 1);
    paths.learning_iter = repmat(iter, height(paths), 1);
    path_tables{end + 1} = paths; %#ok<AGROW>

    if ~isempty(coef_tbl)
        coef_tbl.run_tag = repmat(string(run_tag), height(coef_tbl), 1);
        coef_tbl.route = repmat(route, height(coef_tbl), 1);
        coef_tbl.learning_iter = repmat(iter, height(coef_tbl), 1);
        coef_tables{end + 1} = coef_tbl; %#ok<AGROW>
    end
    write_partial_outputs(out_dir, iter_tables, path_tables, coef_tables);

    fprintf('  iter %d: RMSE %.6g, max error %.6g, max belief update %.6g\n', ...
        iter, iter_tbl.rmse_log_forecast_error, iter_tbl.max_abs_log_forecast_error, iter_tbl.max_abs_log_belief_update);

    if route == "temporary_fixed_path"
        status = "fixed_path_evaluated";
        break;
    end
    if iter_tbl.max_abs_log_belief_update <= convergence_tol
        status = sprintf('belief_rule_converged_iter_%d', iter);
        break;
    end
    price_path = next_price;
end

belief_iterations = vertcat(iter_tables{:});
belief_paths_all = vertcat(path_tables{:});
writetable(belief_iterations, fullfile(out_dir, 'belief_iterations.csv'));
writetable(belief_paths_all, fullfile(out_dir, 'belief_paths_all.csv'));
if isempty(coef_tables)
    belief_coefficients = table();
else
    belief_coefficients = vertcat(coef_tables{:});
end
writetable(belief_coefficients, fullfile(out_dir, 'belief_coefficients.csv'));
write_note(fullfile(out_dir, 'note.md'), row, status);

fprintf('Moll direct-price-beliefs row complete: %s (%s)\n', run_tag, status);
end

function write_partial_outputs(out_dir, iter_tables, path_tables, coef_tables)
belief_iterations = vertcat(iter_tables{:});
belief_paths_all = vertcat(path_tables{:});
writetable(belief_iterations, fullfile(out_dir, 'belief_iterations.csv'));
writetable(belief_paths_all, fullfile(out_dir, 'belief_paths_all.csv'));
if ~isempty(coef_tables)
    belief_coefficients = vertcat(coef_tables{:});
    writetable(belief_coefficients, fullfile(out_dir, 'belief_coefficients.csv'));
end
end

function run_one_temporary_equilibrium(row, run_root, iter_tag, seed_path)
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

function [next_price, coeffs, coef_tbl] = update_direct_belief_path(route, row, paths, old_price, coeffs, reference_price, max_abs_log_move)
log_old = log(old_price(:));
log_generated = log(paths.price_generated(:));
n = numel(log_generated);
age_signal = double(paths.age_col_used(:));
age_signal = age_signal - age_signal(1);
relax = row_number_default(row, 'path_learning_relaxation', 0.40);
gain = row_number_default(row, 'coeff_learning_gain', 0.50);
coef_tbl = table();

switch route
    case "temporary_fixed_path"
        next_log = log_old;
    case "learning_age_price"
        x = [ones(n - 1, 1), log_generated(1:(end - 1)), age_signal(2:end)];
        y = log_generated(2:end);
        raw_coeffs = x \ y;
        if isempty(coeffs)
            coeffs = raw_coeffs;
        else
            coeffs = (1 - gain) .* coeffs + gain .* raw_coeffs;
        end
        lag_log = [log_generated(1); log_generated(1:(end - 1))];
        rule_log = coeffs(1) + coeffs(2) .* lag_log + coeffs(3) .* age_signal;
        next_log = (1 - relax) .* log_old + relax .* rule_log;
        coef_tbl = coefficient_table(["intercept"; "rho_lag_log_price"; "beta_age_signal"], coeffs, raw_coeffs);
    case "price_only_ar1"
        x = [ones(n - 1, 1), log_generated(1:(end - 1))];
        y = log_generated(2:end);
        raw_coeffs = x \ y;
        if isempty(coeffs)
            coeffs = raw_coeffs;
        else
            coeffs = (1 - gain) .* coeffs + gain .* raw_coeffs;
        end
        lag_log = [log_generated(1); log_generated(1:(end - 1))];
        rule_log = coeffs(1) + coeffs(2) .* lag_log;
        next_log = (1 - relax) .* log_old + relax .* rule_log;
        coef_tbl = coefficient_table(["intercept"; "rho_lag_log_price"], coeffs, raw_coeffs);
    case "restricted_heuristic"
        lambda = row_number_default(row, 'heuristic_lambda', 0.0);
        anchor = row_number_default(row, 'heuristic_anchor', 0.0);
        benchmark = mean(log_generated(1:min(4, n)));
        rule_log = nan(n, 1);
        rule_log(1) = log_generated(1);
        for t = 2:n
            if t == 2
                last_growth = 0;
            else
                last_growth = log_generated(t - 1) - log_generated(t - 2);
            end
            rule_log(t) = log_generated(t - 1) + lambda * last_growth - anchor * (log_generated(t - 1) - benchmark);
        end
        next_log = (1 - relax) .* log_old + relax .* rule_log;
        coeffs = [lambda; anchor; benchmark];
        coef_tbl = coefficient_table(["lambda"; "anchor"; "log_benchmark"], coeffs, coeffs);
    otherwise
        error('Unknown Moll route: %s', route);
end

next_log = clamp_log_path(next_log, log(reference_price), max_abs_log_move);
next_price = exp(next_log);
end

function tbl = coefficient_table(names, values, raw_values)
tbl = table(names(:), values(:), raw_values(:), ...
    'VariableNames', {'coefficient','value','raw_value'});
end

function demo_path = demographic_path_for_scenario(demo_scenario, run_root)
annual_dir = pwd;
if any(lower(string(demo_scenario)) == ["external_age_path", "official_projection", "projection_external"])
    demo_path = fullfile(annual_dir, 'official_age_path_0512.mat');
else
    demo_path = fullfile(run_root, 'SteadyState', 'Mod_IRF', 'irfs_100.mat');
end
end

function seed = build_seed(row, annual_dir, internal_t)
mode = lower(string(row_text_default(row, 'source_mode', 'flat')));
switch mode
    case {"flat", "none", ""}
        seed_price = row_number_default(row, 'seed_price', 1.0);
        seed = seed_price .* ones(internal_t, 1);
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
            seed = src.(source_col);
        elseif ismember('price_generated', src.Properties.VariableNames)
            seed = src.price_generated;
        elseif ismember('price_guess', src.Properties.VariableNames)
            seed = src.price_guess;
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
            error('No-RE seed paths not found: %s', source_paths);
        end
        src = readtable(source_paths);
        src = sortrows(src, 'period');
        if ismember('price', src.Properties.VariableNames)
            seed = src.price;
        elseif ismember('PriceHouse', src.Properties.VariableNames)
            seed = src.PriceHouse;
        else
            error('No-RE paths lack a price column: %s', source_paths);
        end
    otherwise
        error('Unknown source_mode: %s', mode);
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

function price_path = clamp_price_path(price_path, reference_price, max_abs_log_move)
price_path = min(max(price_path, reference_price * exp(-max_abs_log_move)), reference_price * exp(max_abs_log_move));
end

function log_path = clamp_log_path(log_path, log_reference_price, max_abs_log_move)
log_path = min(max(log_path, log_reference_price - max_abs_log_move), log_reference_price + max_abs_log_move);
end

function write_note(note_path, row, status)
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Moll direct-price-beliefs run\n\n');
fprintf(fid, '- Run tag: `%s`\n', row_text(row, 'run_tag'));
fprintf(fid, '- Route: `%s`\n', row_text(row, 'route'));
fprintf(fid, '- Status: `%s`\n', status);
fprintf(fid, '- Scenario: `%s`\n', row_text(row, 'demographic_scenario'));
fprintf(fid, '- Horizon: `T%d`, tail years `%d`\n', round(row_number(row, 'horizon_t')), round(row_number_default(row, 'tail_years', 0)));
fprintf(fid, '\nThis is a direct price-beliefs object. It evaluates temporary equilibria under subjective price paths and, for learning routes, updates the perceived law from generated prices. It is not a full rational-expectations fixed point.\n');
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
