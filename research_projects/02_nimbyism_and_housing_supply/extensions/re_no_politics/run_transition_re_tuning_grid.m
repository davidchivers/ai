function results_table = run_transition_re_tuning_grid()
% Overnight tuning sweep for the transition RE price-path solver.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(baseline_dir);
addpath(this_dir);

demographic_path = build_demographic_path_from_age_state_csv(project_root);
price_path_guess = 2.0 .* ones(numel(demographic_path.periods), 1);

base_params = struct();
base_params.max_iter = 3;
base_params.tol = 1e-4;
base_params.damping = 0.25;
base_params.max_update_frac = 0.10;
base_params.terminal_anchor_weight = 0.50;
base_params.max_targeted_periods = 3;
base_params.target_block_half_width = 1;
base_params.terminal_price_rule = 'flat_tail';

configs = {
    struct('damping', 0.25, 'smoothing_weight', 5.0,  'targeted_correction_weight', 0.35, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.15, 'smoothing_weight', 5.0,  'targeted_correction_weight', 0.35, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.10, 'smoothing_weight', 5.0,  'targeted_correction_weight', 0.35, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.25, 'smoothing_weight', 8.0,  'targeted_correction_weight', 0.35, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.15, 'smoothing_weight', 8.0,  'targeted_correction_weight', 0.35, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.10, 'smoothing_weight', 8.0,  'targeted_correction_weight', 0.35, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.25, 'smoothing_weight', 5.0,  'targeted_correction_weight', 0.20, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.15, 'smoothing_weight', 5.0,  'targeted_correction_weight', 0.20, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.10, 'smoothing_weight', 5.0,  'targeted_correction_weight', 0.20, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.25, 'smoothing_weight', 8.0,  'targeted_correction_weight', 0.20, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.15, 'smoothing_weight', 8.0,  'targeted_correction_weight', 0.20, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.10, 'smoothing_weight', 8.0,  'targeted_correction_weight', 0.20, 'line_search_scales', [0.10 0.05 0.02 0.01])
    struct('damping', 0.15, 'smoothing_weight', 10.0, 'targeted_correction_weight', 0.35, 'line_search_scales', [0.05 0.02 0.01])
    struct('damping', 0.10, 'smoothing_weight', 10.0, 'targeted_correction_weight', 0.35, 'line_search_scales', [0.05 0.02 0.01])
    struct('damping', 0.15, 'smoothing_weight', 10.0, 'targeted_correction_weight', 0.20, 'line_search_scales', [0.05 0.02 0.01])
    struct('damping', 0.10, 'smoothing_weight', 10.0, 'targeted_correction_weight', 0.20, 'line_search_scales', [0.05 0.02 0.01])
};

num_configs = numel(configs);
raw_results = repmat(struct( ...
    'config_id', NaN, ...
    'status', "", ...
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
    'elapsed_seconds', NaN), num_configs, 1);

fprintf('=== Transition RE Tuning Grid ===\n');
fprintf('Configs: %d\n', num_configs);

for i = 1:num_configs
    params = base_params;
    config = configs{i};
    fields = fieldnames(config);
    for j = 1:numel(fields)
        params.(fields{j}) = config.(fields{j});
    end

    tic;
    try
        fprintf('\nConfig %d / %d\n', i, num_configs);
        fprintf('  damping = %.3f, smoothing = %.2f, targeted = %.2f, scales = %s\n', ...
            params.damping, params.smoothing_weight, params.targeted_correction_weight, mat2str(params.line_search_scales));

        results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);

        raw_results(i).config_id = i;
        raw_results(i).status = "ok";
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
        raw_results(i).config_id = i;
        raw_results(i).status = "error";
        raw_results(i).accepted_update = string(err.message);
    end

    raw_results(i).damping = params.damping;
    raw_results(i).smoothing_weight = params.smoothing_weight;
    raw_results(i).targeted_correction_weight = params.targeted_correction_weight;
    raw_results(i).line_search_scales = string(mat2str(params.line_search_scales));
    raw_results(i).elapsed_seconds = toc;
end

results_table = struct2table(raw_results);
results_table = sortrows(results_table, {'status', 'residual_norm', 'max_abs_gap'}, {'ascend', 'ascend', 'ascend'});

writetable(results_table, fullfile(this_dir, 'transition_re_tuning_summary.csv'));
save(fullfile(this_dir, 'transition_re_tuning_results.mat'), 'results_table', 'raw_results', 'configs');

fprintf('\nSaved %s\n', fullfile(this_dir, 'transition_re_tuning_summary.csv'));
fprintf('Saved %s\n', fullfile(this_dir, 'transition_re_tuning_results.mat'));
end
