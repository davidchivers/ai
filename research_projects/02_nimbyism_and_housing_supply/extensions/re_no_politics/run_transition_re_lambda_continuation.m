function results_table = run_transition_re_lambda_continuation()
% Coarse continuation workflow for the transition RE extension.
% The aim is qualitative RE intuition, not a tightly converged benchmark.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');
summary_path = fullfile(this_dir, 'transition_re_lambda_continuation_summary.csv');
results_path = fullfile(this_dir, 'transition_re_lambda_continuation_results.mat');
live_summary_path = fullfile(this_dir, 'transition_re_lambda_continuation_summary_live.csv');
live_results_path = fullfile(this_dir, 'transition_re_lambda_continuation_results_live.mat');

addpath(baseline_dir);
addpath(this_dir);

base_demographic_path = build_demographic_path_from_age_state_csv(project_root);
lambdas = [0.00 0.25 0.50 0.75 1.00];
params = build_params();
raw_results = initialize_raw_results(lambdas, params.max_iter);
detailed_results = cell(numel(lambdas), 1);

if isfile(live_results_path)
    resume_data = load(live_results_path, 'raw_results', 'detailed_results', 'lambdas');
    if isfield(resume_data, 'raw_results') && isfield(resume_data, 'lambdas') && ...
            isequaln(resume_data.lambdas, lambdas) && numel(resume_data.raw_results) == numel(lambdas)
        raw_results = resume_data.raw_results;
        if isfield(resume_data, 'detailed_results') && numel(resume_data.detailed_results) == numel(lambdas)
            detailed_results = resume_data.detailed_results;
        end
        completed_count = sum(arrayfun(@(s) string(s.status) ~= "pending", raw_results));
        fprintf('Resuming lambda continuation checkpoint: %d / %d lambdas already have results.\n', ...
            completed_count, numel(lambdas));
    else
        fprintf('Ignoring incompatible lambda continuation checkpoint and starting fresh.\n');
    end
end

fprintf('=== Transition RE Lambda Continuation ===\n');
fprintf('Lambdas: %s\n', mat2str(lambdas));

default_price_guess = 2.0 .* ones(numel(base_demographic_path.periods), 1);

for i = 1:numel(lambdas)
    if string(raw_results(i).status) ~= "pending"
        fprintf('\nLambda %d / %d already completed with status %s, skipping.\n', ...
            i, numel(lambdas), string(raw_results(i).status));
        continue;
    end

    lambda = lambdas(i);
    demographic_path = scale_demographic_path_lambda(base_demographic_path, lambda);
    [price_path_guess, start_guess_source] = get_starting_price_path(i, detailed_results, raw_results, default_price_guess);

    tic;
    try
        fprintf('\nLambda %d / %d\n', i, numel(lambdas));
        fprintf('  lambda = %.2f\n', lambda);
        fprintf('  start guess source = %s\n', start_guess_source);

        results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);

        accepted_updates = string({results.iteration_log.accepted_update});
        nontrivial_mask = accepted_updates ~= "current_path";
        nontrivial_count = sum(nontrivial_mask);
        if any(nontrivial_mask)
            last_nontrivial_iter = find(nontrivial_mask, 1, 'last');
        else
            last_nontrivial_iter = 0;
        end

        raw_results(i).lambda = lambda;
        raw_results(i).status = "ok";
        raw_results(i).max_iter = params.max_iter;
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
        raw_results(i).nontrivial_update_count = nontrivial_count;
        raw_results(i).last_nontrivial_iter = last_nontrivial_iter;
        raw_results(i).start_guess_source = string(start_guess_source);
        raw_results(i).path_span = max(results.final_price_path) - min(results.final_price_path);
        detailed_results{i} = compact_result_snapshot(results, lambda, start_guess_source);
    catch err
        raw_results(i).lambda = lambda;
        raw_results(i).status = "error";
        raw_results(i).max_iter = params.max_iter;
        raw_results(i).accepted_update = string(err.message);
        raw_results(i).start_guess_source = string(start_guess_source);
        detailed_results{i} = struct([]);
    end

    raw_results(i).damping = params.damping;
    raw_results(i).smoothing_weight = params.smoothing_weight;
    raw_results(i).targeted_correction_weight = params.targeted_correction_weight;
    raw_results(i).line_search_scales = string(mat2str(params.line_search_scales));
    raw_results(i).block_sweep_passes = params.block_sweep_passes;
    raw_results(i).max_blocks_per_pass = params.max_blocks_per_pass;
    raw_results(i).candidate_selection_mode = string(params.candidate_selection_mode);
    raw_results(i).greedy_block_accept = params.greedy_block_accept;
    raw_results(i).candidate_residual_slack = params.candidate_residual_slack;
    raw_results(i).focus_residual_slack = params.focus_residual_slack;
    raw_results(i).elapsed_seconds = toc;

    results_table = build_results_table(raw_results);
    writetable(results_table, live_summary_path);
    save(live_results_path, 'results_table', 'raw_results', 'detailed_results', 'lambdas');
end

results_table = build_results_table(raw_results);
writetable(results_table, summary_path);
save(results_path, 'results_table', 'raw_results', 'detailed_results', 'lambdas');

if isfile(live_summary_path)
    delete(live_summary_path);
end
if isfile(live_results_path)
    delete(live_results_path);
end

fprintf('\nSaved %s\n', summary_path);
fprintf('Saved %s\n', results_path);
end

function params = build_params()
params = struct();
params.max_iter = 4;
params.tol = 1e-4;
params.damping = 0.15;
params.max_update_frac = 0.10;
params.smoothing_weight = 8.0;
params.terminal_anchor_weight = 0.50;
params.targeted_correction_weight = 0.20;
params.max_targeted_periods = 3;
params.target_block_half_width = 1;
params.terminal_price_rule = 'flat_tail';
params.update_scheme = 'sequential_blocks';
params.sequential_block_size = 3;
params.block_sweep_passes = 2;
params.max_blocks_per_pass = 4;
params.greedy_block_accept = true;
params.candidate_improvement_tol = 1e-6;
params.candidate_gap_improvement_tol = 1e-6;
params.candidate_residual_slack = 5e-5;
params.candidate_selection_mode = 'global';
params.focus_gap_improvement_tol = 1e-4;
params.focus_excess_improvement_tol = 1e-5;
params.focus_residual_slack = 2e-4;
params.line_search_scales = [0.10 0.05 0.02 0.01];
params.save_candidate_history = true;
end

function [price_path_guess, start_guess_source] = get_starting_price_path(index, detailed_results, raw_results, default_price_guess)
if index <= 1
    price_path_guess = default_price_guess;
    start_guess_source = "flat_2.0";
    return;
end

prev_result = raw_results(index - 1);
prev_detail = detailed_results{index - 1};

if string(prev_result.status) == "ok" && isstruct(prev_detail) && isfield(prev_detail, 'final_price_path')
    price_path_guess = prev_detail.final_price_path(:);
    start_guess_source = sprintf('lambda_%.2f_final_path', prev_result.lambda);
else
    price_path_guess = default_price_guess;
    start_guess_source = "flat_2.0_fallback";
end
end

function snapshot = compact_result_snapshot(results, lambda, start_guess_source)
snapshot = struct();
snapshot.lambda = lambda;
snapshot.start_guess_source = string(start_guess_source);
snapshot.iteration_log = results.iteration_log;
snapshot.selection_diagnostics = results.selection_diagnostics;
snapshot.final_price_path = results.final_price_path;
snapshot.implied_price_path = results.implied_price_path;
snapshot.log_price_residual_raw = results.log_price_residual_raw;
snapshot.excess_demand_guess_path = results.excess_demand_guess_path;
snapshot.period_diagnostics = results.period_diagnostics;
end

function raw_results = initialize_raw_results(lambdas, max_iter)
raw_results = repmat(struct( ...
    'lambda', NaN, ...
    'status', "pending", ...
    'max_iter', max_iter, ...
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
    'path_span', NaN, ...
    'nontrivial_update_count', NaN, ...
    'last_nontrivial_iter', NaN, ...
    'start_guess_source', "", ...
    'damping', NaN, ...
    'smoothing_weight', NaN, ...
    'targeted_correction_weight', NaN, ...
    'line_search_scales', "", ...
    'block_sweep_passes', NaN, ...
    'max_blocks_per_pass', NaN, ...
    'candidate_selection_mode', "", ...
    'greedy_block_accept', false, ...
    'candidate_residual_slack', NaN, ...
    'focus_residual_slack', NaN, ...
    'elapsed_seconds', NaN), numel(lambdas), 1);

for i = 1:numel(lambdas)
    raw_results(i).lambda = lambdas(i);
end
end

function results_table = build_results_table(raw_results)
results_table = struct2table(raw_results);
results_table = sortrows(results_table, {'lambda'}, {'ascend'});
end
