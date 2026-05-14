function results_table = run_transition_re_longrun_followup()
% Run longer multi-iteration tests for the best configs from the tuning grid.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');
tuning_results_path = fullfile(this_dir, 'transition_re_tuning_results.mat');
summary_path = fullfile(this_dir, 'transition_re_longrun_summary.csv');
results_path = fullfile(this_dir, 'transition_re_longrun_results.mat');
live_summary_path = fullfile(this_dir, 'transition_re_longrun_summary_live.csv');
live_results_path = fullfile(this_dir, 'transition_re_longrun_results_live.mat');

if ~isfile(tuning_results_path)
    error('Tuning results not found: %s', tuning_results_path);
end

addpath(baseline_dir);
addpath(this_dir);

tuning_data = load(tuning_results_path, 'results_table', 'configs');
results_table_in = tuning_data.results_table;
configs = tuning_data.configs;

top_k = 3;
iter_grid = [5, 10];
ok_rows = results_table_in(strcmp(string(results_table_in.status), "ok"), :);
if isempty(ok_rows)
    error('No ok rows found in %s', tuning_results_path);
end

top_k = min(top_k, height(ok_rows));
selected_config_ids = ok_rows.config_id(1:top_k);
cases = build_cases(selected_config_ids, iter_grid);
raw_results = initialize_raw_results(cases);

if isfile(live_results_path)
    resume_data = load(live_results_path, 'raw_results', 'cases');
    if isfield(resume_data, 'raw_results') && isfield(resume_data, 'cases') && ...
            numel(resume_data.raw_results) == numel(cases) && isequaln(resume_data.cases, cases)
        raw_results = resume_data.raw_results;
        completed_count = sum(arrayfun(@(s) string(s.status) ~= "pending", raw_results));
        fprintf('Resuming long-run checkpoint: %d / %d cases already have results.\n', ...
            completed_count, numel(cases));
    else
        fprintf('Ignoring incompatible long-run checkpoint and starting fresh.\n');
    end
end

demographic_path = build_demographic_path_from_age_state_csv(project_root);

fprintf('=== Transition RE Long-Run Follow-Up ===\n');
fprintf('Configs selected: %s\n', mat2str(selected_config_ids(:)'));
fprintf('Iteration grid: %s\n', mat2str(iter_grid));

for i = 1:numel(cases)
    if string(raw_results(i).status) ~= "pending"
        fprintf('\nCase %d / %d already completed with status %s, skipping.\n', ...
            i, numel(cases), string(raw_results(i).status));
        continue;
    end

    case_info = cases(i);
    params = build_base_params();
    config = configs{case_info.config_id};
    fields = fieldnames(config);
    for j = 1:numel(fields)
        params.(fields{j}) = config.(fields{j});
    end
    params.max_iter = case_info.max_iter;

    tic;
    try
        fprintf('\nCase %d / %d\n', i, numel(cases));
        fprintf('  config_id = %d, max_iter = %d\n', case_info.config_id, case_info.max_iter);
        fprintf('  damping = %.3f, smoothing = %.2f, targeted = %.2f, scales = %s\n', ...
            params.damping, params.smoothing_weight, params.targeted_correction_weight, mat2str(params.line_search_scales));

        price_path_guess = 2.0 .* ones(numel(demographic_path.periods), 1);
        results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);

        raw_results(i).case_id = i;
        raw_results(i).config_id = case_info.config_id;
        raw_results(i).status = "ok";
        raw_results(i).max_iter = case_info.max_iter;
        raw_results(i).iterations_completed = results.iterations;
        raw_results(i).converged = results.converged;
        raw_results(i).residual_norm = results.iteration_log(end).residual_norm;
        raw_results(i).max_abs_gap = results.iteration_log(end).max_abs_gap;
        raw_results(i).max_abs_update = results.iteration_log(end).max_abs_update;
        raw_results(i).accepted_update = string(results.iteration_log(end).accepted_update);
        raw_results(i).worst_gap_period = results.iteration_log(end).worst_gap_period;
        raw_results(i).worst_excess_demand_period = results.iteration_log(end).worst_excess_demand_period;
        raw_results(i).worst_excess_demand = results.iteration_log(end).worst_excess_demand;
        raw_results(i).price_min = min(results.final_price_path);
        raw_results(i).price_max = max(results.final_price_path);
    catch err
        raw_results(i).case_id = i;
        raw_results(i).config_id = case_info.config_id;
        raw_results(i).status = "error";
        raw_results(i).max_iter = case_info.max_iter;
        raw_results(i).accepted_update = string(err.message);
    end

    raw_results(i).damping = params.damping;
    raw_results(i).smoothing_weight = params.smoothing_weight;
    raw_results(i).targeted_correction_weight = params.targeted_correction_weight;
    raw_results(i).line_search_scales = string(mat2str(params.line_search_scales));
    raw_results(i).elapsed_seconds = toc;

    results_table = build_results_table(raw_results);
    writetable(results_table, live_summary_path);
    save(live_results_path, 'results_table', 'raw_results', 'cases');
end

results_table = build_results_table(raw_results);
writetable(results_table, summary_path);
save(results_path, 'results_table', 'raw_results', 'cases');

if isfile(live_summary_path)
    delete(live_summary_path);
end
if isfile(live_results_path)
    delete(live_results_path);
end

fprintf('\nSaved %s\n', summary_path);
fprintf('Saved %s\n', results_path);
end

function params = build_base_params()
params = struct();
params.max_iter = 3;
params.tol = 1e-4;
params.damping = 0.25;
params.max_update_frac = 0.10;
params.terminal_anchor_weight = 0.50;
params.max_targeted_periods = 3;
params.target_block_half_width = 1;
params.terminal_price_rule = 'flat_tail';
params.update_scheme = 'sequential_blocks';
params.sequential_block_size = 3;
params.block_sweep_passes = 2;
params.max_blocks_per_pass = 4;
params.greedy_block_accept = true;
params.candidate_improvement_tol = 1e-6;
end

function cases = build_cases(config_ids, iter_grid)
num_cases = numel(config_ids) * numel(iter_grid);
cases = repmat(struct('config_id', NaN, 'max_iter', NaN), num_cases, 1);
idx = 1;
for i = 1:numel(config_ids)
    for j = 1:numel(iter_grid)
        cases(idx).config_id = config_ids(i);
        cases(idx).max_iter = iter_grid(j);
        idx = idx + 1;
    end
end
end

function raw_results = initialize_raw_results(cases)
raw_results = repmat(struct( ...
    'case_id', NaN, ...
    'config_id', NaN, ...
    'status', "pending", ...
    'max_iter', NaN, ...
    'iterations_completed', NaN, ...
    'converged', false, ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'accepted_update', "", ...
    'worst_gap_period', NaN, ...
    'worst_excess_demand_period', NaN, ...
    'worst_excess_demand', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'damping', NaN, ...
    'smoothing_weight', NaN, ...
    'targeted_correction_weight', NaN, ...
    'line_search_scales', "", ...
    'elapsed_seconds', NaN), numel(cases), 1);
end

function results_table = build_results_table(raw_results)
results_table = struct2table(raw_results);
results_table = sortrows(results_table, ...
    {'status', 'residual_norm', 'max_abs_gap', 'max_iter', 'config_id'}, ...
    {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
end
