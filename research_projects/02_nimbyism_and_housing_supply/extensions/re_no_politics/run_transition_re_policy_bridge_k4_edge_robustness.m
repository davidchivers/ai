function [summary, attempts] = run_transition_re_policy_bridge_k4_edge_robustness(output_tag)
% Probe whether the local retry-aware k = 4 alpha edge is driven by the
% current max-gap filter or by a deeper solver / basin transition.

if nargin < 1 || isempty(output_tag)
    output_tag = 'k4_edge_robustness';
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(baseline_dir);
addpath(this_dir);

alpha_values = [0.190899658203125, 0.19090576171875];
robust_per_attempt_max_iter = 50;
gap_cutoffs = [0.03, 0.05, 0.10];

demographic_path_full = build_demographic_path_from_age_state_csv(project_root);
demographic_path_k4 = truncate_demographic_path(demographic_path_full, 4);

summary_rows = repmat(initialize_summary_row(), numel(alpha_values) * 2, 1);
attempt_rows = repmat(initialize_attempt_row(), numel(alpha_values) * 2, 1);
summary_idx = 0;
attempt_idx = 0;
all_results = cell(numel(alpha_values), 1);

paths_struct = build_output_paths(this_dir, output_tag);

fprintf('=== NIMBY RE policy-bridge k = 4 edge robustness ===\n');
fprintf('Alphas: %s\n', mat2str(alpha_values, 15));
fprintf('Robustness per-attempt max_iter: %d\n', robust_per_attempt_max_iter);

for alpha_idx = 1:numel(alpha_values)
    alpha = alpha_values(alpha_idx);
    alpha_tag = format_alpha_tag(alpha);
    baseline_summary_path = fullfile(this_dir, ...
        sprintf('transition_re_policy_bridge_alpha_frontier_single_%s_k4_retryaware_summary.csv', alpha_tag));
    baseline_results_path = fullfile(this_dir, ...
        sprintf('transition_re_policy_bridge_alpha_frontier_single_%s_k4_retryaware_results.mat', alpha_tag));

    baseline_summary = readtable(baseline_summary_path);
    baseline_row = baseline_summary(baseline_summary.k == 4, :);
    loaded = load(baseline_results_path, 'state');
    k3_guess = extend_guess( ...
        loaded.state.all_results{3, 1}.final_price_path(:), ...
        loaded.state.anchor_price_path(:), ...
        4);

    summary_idx = summary_idx + 1;
    summary_rows(summary_idx) = make_baseline_summary_row(alpha, baseline_row, gap_cutoffs);

    params = default_params(alpha, robust_per_attempt_max_iter);
    retry_case = run_retry_case(k3_guess, demographic_path_k4, params, gap_cutoffs);
    all_results{alpha_idx} = retry_case;

    summary_idx = summary_idx + 1;
    summary_rows(summary_idx) = make_retry_summary_row(alpha, retry_case, gap_cutoffs);

    for j = 1:numel(retry_case.attempts)
        attempt_idx = attempt_idx + 1;
        attempt_rows(attempt_idx) = make_attempt_row(alpha, retry_case.attempts(j));
    end

    save_partial_outputs(paths_struct, summary_rows(1:summary_idx), attempt_rows(1:attempt_idx), all_results);
end

summary = struct2table(summary_rows(1:summary_idx));
attempts = struct2table(attempt_rows(1:attempt_idx));

writetable(summary, paths_struct.summary_path);
writetable(attempts, paths_struct.attempts_path);
save(paths_struct.results_path, 'summary', 'attempts', 'all_results', 'gap_cutoffs', 'alpha_values');
end

function row = initialize_summary_row()
row = struct( ...
    'alpha', NaN, ...
    'case_label', "", ...
    'per_attempt_max_iter', NaN, ...
    'attempt_count', NaN, ...
    'status', "", ...
    'iterations_completed', NaN, ...
    'converged', false, ...
    'looks_stable_gap_0_03', false, ...
    'looks_stable_gap_0_05', false, ...
    'looks_stable_gap_0_10', false, ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'policy_reference_price_last_used', NaN, ...
    'warm_start_source', "", ...
    'elapsed_seconds', NaN);
end

function row = initialize_attempt_row()
row = struct( ...
    'alpha', NaN, ...
    'per_attempt_max_iter', NaN, ...
    'attempt_number', NaN, ...
    'attempt_label', "", ...
    'status', "", ...
    'iterations_completed', NaN, ...
    'converged', false, ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'policy_reference_price_last_used', NaN, ...
    'elapsed_seconds', NaN, ...
    'start_price_1', NaN, ...
    'start_price_2', NaN, ...
    'start_price_3', NaN, ...
    'start_price_4', NaN, ...
    'final_price_1', NaN, ...
    'final_price_2', NaN, ...
    'final_price_3', NaN, ...
    'final_price_4', NaN);
end

function row = make_baseline_summary_row(alpha, baseline_row, gap_cutoffs)
row = initialize_summary_row();
row.alpha = alpha;
row.case_label = "baseline_retry25x25_existing";
row.per_attempt_max_iter = 25;
row.attempt_count = infer_attempt_count(string(baseline_row.status{1}));
row.status = string(baseline_row.status{1});
row.iterations_completed = baseline_row.iterations_completed(1);
row.converged = baseline_row.converged(1);
row.looks_stable_gap_0_03 = baseline_row.max_abs_gap(1) < gap_cutoffs(1);
row.looks_stable_gap_0_05 = baseline_row.max_abs_gap(1) < gap_cutoffs(2);
row.looks_stable_gap_0_10 = baseline_row.max_abs_gap(1) < gap_cutoffs(3);
row.residual_norm = baseline_row.residual_norm(1);
row.max_abs_gap = baseline_row.max_abs_gap(1);
row.max_abs_update = baseline_row.max_abs_update(1);
row.price_min = baseline_row.price_min(1);
row.price_max = baseline_row.price_max(1);
row.policy_reference_price_last_used = baseline_row.policy_reference_price_last_used(1);
row.warm_start_source = string(baseline_row.warm_start_source{1});
row.elapsed_seconds = baseline_row.elapsed_seconds(1);
end

function row = make_retry_summary_row(alpha, retry_case, gap_cutoffs)
final_attempt = retry_case.attempts(end);
row = initialize_summary_row();
row.alpha = alpha;
row.case_label = "retry50x50";
row.per_attempt_max_iter = retry_case.per_attempt_max_iter;
row.attempt_count = numel(retry_case.attempts);
row.status = retry_case.status;
row.iterations_completed = retry_case.iterations_completed;
row.converged = final_attempt.results.converged;
row.looks_stable_gap_0_03 = final_attempt.results.update_diagnostics.max_abs_gap < gap_cutoffs(1);
row.looks_stable_gap_0_05 = final_attempt.results.update_diagnostics.max_abs_gap < gap_cutoffs(2);
row.looks_stable_gap_0_10 = final_attempt.results.update_diagnostics.max_abs_gap < gap_cutoffs(3);
row.residual_norm = final_attempt.results.iteration_log(final_attempt.results.iterations).residual_norm;
row.max_abs_gap = final_attempt.results.update_diagnostics.max_abs_gap;
row.max_abs_update = final_attempt.results.iteration_log(final_attempt.results.iterations).max_abs_update;
row.price_min = min(final_attempt.results.final_price_path);
row.price_max = max(final_attempt.results.final_price_path);
row.policy_reference_price_last_used = final_attempt.results.policy_reference_price_path_used(end);
row.warm_start_source = retry_case.warm_start_source;
row.elapsed_seconds = retry_case.elapsed_seconds;
end

function row = make_attempt_row(alpha, attempt)
results = attempt.results;
iter_idx = results.iterations;
start_path = attempt.start_path(:);
final_path = results.final_price_path(:);

row = initialize_attempt_row();
row.alpha = alpha;
row.per_attempt_max_iter = attempt.per_attempt_max_iter;
row.attempt_number = attempt.attempt_number;
row.attempt_label = attempt.attempt_label;
row.status = attempt.status;
row.iterations_completed = iter_idx;
row.converged = results.converged;
row.residual_norm = results.iteration_log(iter_idx).residual_norm;
row.max_abs_gap = results.update_diagnostics.max_abs_gap;
row.max_abs_update = results.iteration_log(iter_idx).max_abs_update;
row.price_min = min(final_path);
row.price_max = max(final_path);
row.policy_reference_price_last_used = results.policy_reference_price_path_used(end);
row.elapsed_seconds = attempt.elapsed_seconds;
row.start_price_1 = start_path(1);
row.start_price_2 = start_path(2);
row.start_price_3 = start_path(3);
row.start_price_4 = start_path(4);
row.final_price_1 = final_path(1);
row.final_price_2 = final_path(2);
row.final_price_3 = final_path(3);
row.final_price_4 = final_path(4);
end

function retry_case = run_retry_case(start_guess, demographic_path_k4, params, gap_cutoffs)
attempts = repmat(struct( ...
    'attempt_number', NaN, ...
    'attempt_label', "", ...
    'status', "", ...
    'start_path', NaN(4, 1), ...
    'per_attempt_max_iter', params.max_iter, ...
    'elapsed_seconds', NaN, ...
    'results', []), 2, 1);

[attempt1_results, attempt1_elapsed] = run_once(start_guess, demographic_path_k4, params);
attempts(1).attempt_number = 1;
attempts(1).attempt_label = "attempt_1_same_alpha_k_3";
attempts(1).status = "ok";
attempts(1).start_path = start_guess(:);
attempts(1).elapsed_seconds = attempt1_elapsed;
attempts(1).results = attempt1_results;

retry_case = struct();
retry_case.per_attempt_max_iter = params.max_iter;
retry_case.attempts = attempts(1);
retry_case.status = "ok";
retry_case.iterations_completed = attempt1_results.iterations;
retry_case.elapsed_seconds = attempt1_elapsed;
retry_case.warm_start_source = "same_alpha_k_3";

if looks_stable_with_gap(attempt1_results, params, gap_cutoffs(2))
    return;
end

retry_guess = attempt1_results.final_price_path(:);
retry_params = params;
retry_params.max_iter = params.max_iter;
retry_params.tol = params.tol;
retry_params.damping = params.damping;

[attempt2_results, attempt2_elapsed] = run_once(retry_guess, demographic_path_k4, retry_params);
attempts(2).attempt_number = 2;
attempts(2).attempt_label = "attempt_2_retry_from_failed_endpoint";
attempts(2).status = "ok";
attempts(2).start_path = retry_guess(:);
attempts(2).elapsed_seconds = attempt2_elapsed;
attempts(2).results = attempt2_results;

retry_case.attempts = attempts;
retry_case.iterations_completed = attempt1_results.iterations + attempt2_results.iterations;
retry_case.elapsed_seconds = attempt1_elapsed + attempt2_elapsed;
retry_case.warm_start_source = "same_alpha_k_3 -> retry_from_failed_endpoint";
retry_case.status = "ok_retry_failed";

if looks_stable_with_gap(attempt2_results, params, gap_cutoffs(2))
    retry_case.status = "ok_after_retry";
end
end

function [results, elapsed_seconds] = run_once(start_guess, demographic_path_k4, params)
run_tic = tic;
results = solve_transition_re_no_politics(start_guess, demographic_path_k4, params);
elapsed_seconds = toc(run_tic);
end

function params = default_params(alpha, max_iter)
params = struct();
params.max_iter = max_iter;
params.tol = 1e-4;
params.damping = 0.25;
params.max_update_frac = 0.10;
params.smoothing_weight = 5.00;
params.terminal_anchor_weight = 0.50;
params.targeted_correction_weight = 0.35;
params.max_targeted_periods = 3;
params.target_block_half_width = 1;
params.line_search_scales = [0.01, 0.02, 0.05];
params.update_scheme = 'sequential_blocks';
params.outer_iteration_mode = 'fertility_style';
params.fixed_point_relaxation_weight = 0.10;
params.fixed_point_relaxation_space = 'log';
params.fixed_point_price_min = 0.40;
params.fixed_point_price_max = 5.00;
params.terminal_price_rule = 'flat_tail';
params.terminal_reference_mode = 'fixed_price';
params.terminal_reference_price = 2.0;
params.transition_policy_mode = 'steady_state_by_period_price';
params.policy_reference_mode = 'blended_current_and_fixed_price';
params.policy_reference_price = 2.0;
params.policy_reference_blend_weight = alpha;
params.policy_reference_price_floor = NaN;
params.policy_reference_price_cap = NaN;
end

function tf = looks_stable_with_gap(results, params, gap_cutoff)
tol = 1e-6;
tf = results.update_diagnostics.max_abs_gap < gap_cutoff && ...
    min(results.final_price_path) > params.fixed_point_price_min + tol && ...
    max(results.final_price_path) < params.fixed_point_price_max - tol;
end

function n = infer_attempt_count(status)
if contains(status, "retry")
    n = 2;
else
    n = 1;
end
end

function paths_struct = build_output_paths(this_dir, output_tag)
paths_struct = struct();
paths_struct.summary_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_summary.csv', output_tag));
paths_struct.attempts_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_attempts.csv', output_tag));
paths_struct.results_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_results.mat', output_tag));
end

function save_partial_outputs(paths_struct, summary_rows, attempt_rows, all_results)
summary_table = struct2table(summary_rows);
attempts_table = struct2table(attempt_rows);

writetable(summary_table, paths_struct.summary_path);
writetable(attempts_table, paths_struct.attempts_path);
save(paths_struct.results_path, 'summary_table', 'attempts_table', 'all_results');
end

function alpha_tag = format_alpha_tag(alpha)
alpha_tag = regexprep(sprintf('%.15f', alpha), '0+$', '');
alpha_tag = regexprep(alpha_tag, '\.$', '');
alpha_tag = strrep(alpha_tag, '.', '_');
end

function demographic_path_k = truncate_demographic_path(demographic_path_full, k)
demographic_path_k = demographic_path_full;
fields = fieldnames(demographic_path_full);
for i = 1:numel(fields)
    field_name = fields{i};
    value = demographic_path_full.(field_name);
    if isnumeric(value)
        if isvector(value) && numel(value) == numel(demographic_path_full.periods)
            demographic_path_k.(field_name) = value(1:k, :);
        elseif ismatrix(value) && size(value, 1) == numel(demographic_path_full.periods)
            demographic_path_k.(field_name) = value(1:k, :);
        else
            demographic_path_k.(field_name) = value;
        end
    else
        demographic_path_k.(field_name) = value;
    end
end
demographic_path_k.description = sprintf('%s Truncated to first %d periods for the k = 4 edge robustness checks.', ...
    demographic_path_full.description, k);
end

function guess = extend_guess(current_guess, anchor_price_path, k)
guess = current_guess(:);
if numel(guess) >= k
    guess = guess(1:k);
else
    guess = [guess; anchor_price_path(numel(guess) + 1:k)];
end
end
