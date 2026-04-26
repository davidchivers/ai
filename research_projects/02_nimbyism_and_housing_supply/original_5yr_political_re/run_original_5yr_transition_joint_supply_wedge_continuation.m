function [summary, results] = run_original_5yr_transition_joint_supply_wedge_continuation( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    wedge_floor, wedge_cap, k_schedule, housing_clear_max_iter, political_response_mode, political_response_sigma, ...
    seed_wedge_csv_path, prefix_lock_length, stage_init_accept_mode, objective_horizon)
% Joint political/housing branch with a policy-style supply wedge path.
%
% The outer unknown is a low-dimensional wedge path z_t that scales housing
% supply through Hbar_t. The inner block then clears the housing side
% conditional on z_t using solve_transition_re_no_politics. Political
% residuals are evaluated on the resulting path and fed back into z_t.

if nargin < 1 || isempty(max_k)
    max_k = 14;
end
if nargin < 2 || isempty(max_outer_iter)
    max_outer_iter = 4;
end
if nargin < 3 || isempty(basis_count)
    basis_count = 3;
end
if nargin < 4 || isempty(seed_price_csv_path)
    seed_price_csv_path = '';
end
if nargin < 5
    run_tag = '';
end
if nargin < 6 || isempty(demographic_source_mode)
    demographic_source_mode = 'historical_1950';
end
if nargin < 7 || isempty(finite_diff_step)
    finite_diff_step = 1e-2;
end
if nargin < 8 || isempty(ridge_lambda)
    ridge_lambda = 1e-3;
end
if nargin < 9 || isempty(candidate_scales)
    candidate_scales = [1.0; 0.5; 0.25];
end
if nargin < 10 || isempty(trust_region_log_step)
    trust_region_log_step = 0.08;
end
if nargin < 11 || isempty(active_threshold_frac)
    active_threshold_frac = 0.65;
end
if nargin < 12 || isempty(wedge_floor)
    wedge_floor = -0.50;
end
if nargin < 13 || isempty(wedge_cap)
    wedge_cap = 0.50;
end
if nargin < 14 || isempty(k_schedule)
    if max_k <= 6
        k_schedule = (2:max_k)';
    else
        k_schedule = unique([2:6, 8:2:min(12, max_k), max_k])';
    end
end
if nargin < 15 || isempty(housing_clear_max_iter)
    housing_clear_max_iter = 4;
end
if nargin < 16 || isempty(political_response_mode)
    political_response_mode = 'hard_sign';
end
if nargin < 17 || isempty(political_response_sigma)
    political_response_sigma = 0.05;
end
if nargin < 18 || isempty(seed_wedge_csv_path)
    seed_wedge_csv_path = '';
end
if nargin < 19 || isempty(prefix_lock_length)
    prefix_lock_length = 0;
end
if nargin < 20 || isempty(stage_init_accept_mode)
    stage_init_accept_mode = 'strict';
end
if nargin < 21 || isempty(objective_horizon)
    objective_horizon = 0;
end

validateattributes(max_k, {'double'}, {'scalar', 'integer', '>=', 2});
validateattributes(max_outer_iter, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(basis_count, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(finite_diff_step, {'double'}, {'scalar', 'positive'});
validateattributes(ridge_lambda, {'double'}, {'scalar', 'nonnegative'});
validateattributes(candidate_scales, {'double'}, {'vector', 'nonempty', 'positive'});
validateattributes(trust_region_log_step, {'double'}, {'scalar', 'positive'});
validateattributes(active_threshold_frac, {'double'}, {'scalar', '>', 0, '<=', 1});
validateattributes(wedge_floor, {'double'}, {'scalar', '<', wedge_cap});
validateattributes(wedge_cap, {'double'}, {'scalar', '>', wedge_floor});
validateattributes(housing_clear_max_iter, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(political_response_sigma, {'double'}, {'scalar', 'finite', 'real', 'positive'});
validateattributes(prefix_lock_length, {'double'}, {'scalar', 'integer', '>=', 0});
validateattributes(objective_horizon, {'double'}, {'scalar', 'integer', '>=', 0});

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(this_dir);
baseline_dir = fullfile(project_root, 'code', 'steadystate');
extension_dir = fullfile(project_root, 'extensions', 're_no_politics');

addpath(this_dir);
addpath(baseline_dir);
addpath(extension_dir);

demographic_path_full = build_demographic_path_local(project_root, demographic_source_mode);
T_full = numel(demographic_path_full.periods);
max_k = min(max(2, round(max_k)), T_full);

k_schedule = unique(round(k_schedule(:)));
k_schedule = k_schedule(k_schedule >= 2 & k_schedule <= max_k);
if isempty(k_schedule)
    error('k_schedule contains no valid horizons.');
end

default_seed = fullfile(this_dir, 'original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv');
seed_price_path = build_price_guess_local(default_seed, seed_price_csv_path, max_k);
seed_wedge_path = build_wedge_guess_local(seed_wedge_csv_path, max_k, wedge_floor, wedge_cap);

if isempty(run_tag)
    run_tag = sprintf('joint_wedge_k%d_i%d_b%d', max_k, max_outer_iter, basis_count);
end
run_tag = regexprep(lower(string(run_tag)), '[^a-z0-9_]+', '_');
output_dir = fullfile(this_dir, 'truth', 'joint_supply_wedge', char(run_tag));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

stage_results = repmat(struct( ...
    'horizon_k', NaN, ...
    'run_dir', "", ...
    'iterations', NaN, ...
    'improved_any', false, ...
    'final_price_path', [], ...
    'final_wedge_path', [], ...
    'final_vote_path', [], ...
    'objective_horizon', NaN, ...
    'final_metrics', struct(), ...
    'iteration_log', []), numel(k_schedule), 1);

current_price_seed = seed_price_path(:);
current_wedge_seed = seed_wedge_path(:);

for stage_idx = 1:numel(k_schedule)
    k = k_schedule(stage_idx);
    demographic_path = truncate_demographic_path_local(demographic_path_full, k);
    stage_objective_horizon = k;
    if objective_horizon > 0
        stage_objective_horizon = min(k, objective_horizon);
    end
    objective_mask = build_objective_mask_local(k, stage_objective_horizon);

    stage_price_seed = fit_path_to_horizon_local(current_price_seed, k, seed_price_path(max(1, min(numel(seed_price_path), k))));
    stage_wedge_seed = clamp_path_local(fit_path_to_horizon_local(current_wedge_seed, k, 0.0), wedge_floor, wedge_cap);
    stage_fixed_wedge_path = zeros(k, 1);
    stage_prefix_lock_length = min(prefix_lock_length, k - 1);
    if stage_objective_horizon < k
        basis = build_objective_block_basis_local(k, basis_count, stage_objective_horizon);
    elseif stage_prefix_lock_length > 0
        stage_fixed_wedge_path(1:stage_prefix_lock_length) = stage_wedge_seed(1:stage_prefix_lock_length);
        basis = build_tail_block_basis_local(k, basis_count, stage_prefix_lock_length);
    else
        stage_basis_count = min(k, basis_count);
        basis = build_block_basis_local(k, stage_basis_count);
    end
    stage_theta_seed = basis \ (stage_wedge_seed - stage_fixed_wedge_path);

    stage_run_dir = fullfile(output_dir, sprintf('k%02d', k));
    if ~exist(stage_run_dir, 'dir')
        mkdir(stage_run_dir);
    end

    [stage_summary, stage_result] = run_joint_stage_local( ...
        k, max_outer_iter, basis, stage_price_seed, stage_theta_seed, stage_run_dir, ...
        demographic_path, demographic_source_mode, finite_diff_step, ridge_lambda, candidate_scales, ...
        trust_region_log_step, active_threshold_frac, wedge_floor, wedge_cap, housing_clear_max_iter, ...
        political_response_mode, political_response_sigma, stage_fixed_wedge_path, stage_init_accept_mode, objective_mask);

    writetable(stage_summary, fullfile(stage_run_dir, sprintf('%s_k%02d_summary.csv', run_tag, k)));
    writematrix(stage_result.final_price_path(:), fullfile(stage_run_dir, sprintf('%s_k%02d_final_price_path.csv', run_tag, k)));
    writematrix(stage_result.final_wedge_path(:), fullfile(stage_run_dir, sprintf('%s_k%02d_final_wedge_path.csv', run_tag, k)));
    writematrix(stage_result.final_vote_path(:), fullfile(stage_run_dir, sprintf('%s_k%02d_final_vote_path.csv', run_tag, k)));

    stage_results(stage_idx).horizon_k = k;
    stage_results(stage_idx).run_dir = string(stage_run_dir);
    stage_results(stage_idx).iterations = stage_result.iterations;
    stage_results(stage_idx).improved_any = stage_result.improved_any;
    stage_results(stage_idx).final_price_path = stage_result.final_price_path(:);
    stage_results(stage_idx).final_wedge_path = stage_result.final_wedge_path(:);
    stage_results(stage_idx).final_vote_path = stage_result.final_vote_path(:);
    stage_results(stage_idx).objective_horizon = stage_result.objective_horizon;
    stage_results(stage_idx).final_metrics = stage_result.final_metrics;
    stage_results(stage_idx).iteration_log = stage_result.iteration_log;

    current_price_seed = stage_result.final_price_path(:);
    current_wedge_seed = stage_result.final_wedge_path(:);
end

summary = table( ...
    k_schedule(:), ...
    [stage_results.objective_horizon]', ...
    [stage_results.iterations]', ...
    [stage_results.improved_any]', ...
    extract_metric_local(stage_results, 'max_abs_vote'), ...
    extract_metric_local(stage_results, 'full_max_abs_vote'), ...
    extract_metric_local(stage_results, 'ghost_max_abs_vote'), ...
    extract_metric_local(stage_results, 'reduced_vote_l2'), ...
    extract_metric_local(stage_results, 'tail_max_abs_vote'), ...
    extract_metric_local(stage_results, 'prefix_max_abs_vote'), ...
    extract_metric_local(stage_results, 'max_abs_gap'), ...
    extract_metric_local(stage_results, 'full_max_abs_gap'), ...
    extract_metric_local(stage_results, 'ghost_max_abs_gap'), ...
    extract_metric_local(stage_results, 'tail_max_abs_gap'), ...
    extract_metric_local(stage_results, 'prefix_max_abs_gap'), ...
    extract_metric_local(stage_results, 'merit'), ...
    'VariableNames', { ...
        'horizon_k', 'objective_horizon', 'iterations_completed', 'improved_any', ...
        'final_max_abs_vote', 'final_full_max_abs_vote', 'final_ghost_max_abs_vote', ...
        'final_reduced_vote_l2', 'final_tail_max_abs_vote', 'final_prefix_max_abs_vote', ...
        'final_max_abs_gap', 'final_full_max_abs_gap', 'final_ghost_max_abs_gap', ...
        'final_tail_max_abs_gap', 'final_prefix_max_abs_gap', 'final_merit'});

results = struct();
results.run_tag = string(run_tag);
results.output_dir = string(output_dir);
results.max_k = max_k;
results.k_schedule = k_schedule(:);
results.max_outer_iter = max_outer_iter;
results.basis_count = basis_count;
results.prefix_lock_length = prefix_lock_length;
results.objective_horizon = objective_horizon;
results.seed_price_csv_path = string(seed_price_csv_path);
results.seed_wedge_csv_path = string(seed_wedge_csv_path);
results.demographic_source_mode = string(demographic_source_mode);
results.finite_diff_step = finite_diff_step;
results.ridge_lambda = ridge_lambda;
results.candidate_scales = candidate_scales(:);
results.trust_region_log_step = trust_region_log_step;
results.active_threshold_frac = active_threshold_frac;
results.wedge_floor = wedge_floor;
results.wedge_cap = wedge_cap;
results.housing_clear_max_iter = housing_clear_max_iter;
results.political_response_mode = string(political_response_mode);
results.political_response_sigma = political_response_sigma;
results.stage_init_accept_mode = string(stage_init_accept_mode);
results.stage_results = stage_results;
results.message = 'Joint supply-wedge continuation branch completed using a wedge path as the outer political object and a housing-clearing inner solve.';

writetable(summary, fullfile(output_dir, sprintf('%s_summary.csv', run_tag)));
final_stage = stage_results(end);
writematrix(final_stage.final_price_path(:), fullfile(output_dir, sprintf('%s_final_price_path.csv', run_tag)));
writematrix(final_stage.final_wedge_path(:), fullfile(output_dir, sprintf('%s_final_wedge_path.csv', run_tag)));
writematrix(final_stage.final_vote_path(:), fullfile(output_dir, sprintf('%s_final_vote_path.csv', run_tag)));
save(fullfile(output_dir, sprintf('%s_results.mat', run_tag)), 'summary', 'results');
end

function [summary, result] = run_joint_stage_local(k, max_outer_iter, basis, price_seed_path, theta_seed, stage_run_dir, demographic_path, demographic_source_mode, finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, wedge_floor, wedge_cap, housing_clear_max_iter, political_response_mode, political_response_sigma, fixed_wedge_path, stage_init_accept_mode, objective_mask)
if nargin < 19 || isempty(fixed_wedge_path)
    fixed_wedge_path = zeros(size(basis, 1), 1);
end
if nargin < 20 || isempty(stage_init_accept_mode)
    stage_init_accept_mode = 'strict';
end
if nargin < 21 || isempty(objective_mask)
    objective_mask = ones(size(basis, 1), 1);
end
fixed_wedge_path = fixed_wedge_path(:);
if numel(fixed_wedge_path) ~= size(basis, 1)
    error('fixed_wedge_path must have one entry per transition period.');
end
objective_mask = sanitize_objective_mask_local(objective_mask, size(basis, 1));
current_theta = theta_seed(:);
current_wedge_path = clamp_path_local(fixed_wedge_path + basis * current_theta, wedge_floor, wedge_cap);
current_price_path = price_seed_path(:);
candidate_scales = expand_candidate_scales_local(candidate_scales);
fd_step_ladder = finite_diff_step .* [1.0; 0.5];
ridge_ladder = ridge_lambda .* [1.0; 10.0];
trust_region_ladder = trust_region_log_step .* [1.0; 0.5; 0.25];
trace_log_path = fullfile(stage_run_dir, 'evaluation_trace.log');
if exist(trace_log_path, 'file')
    delete(trace_log_path);
end
append_trace_line_local(trace_log_path, sprintf('event=stage_start k=%d objective_horizon=%d mode=%s sigma=%.6g accept_mode=%s basis_count=%d fixed_prefix_periods=%d outer_iter=%d housing_clear_max_iter=%d', ...
    k, nnz(objective_mask > 0), char(string(political_response_mode)), political_response_sigma, char(string(stage_init_accept_mode)), ...
    size(basis, 2), sum(all(abs(basis) < 1e-14, 2)), max_outer_iter, housing_clear_max_iter));

iteration_log = repmat(struct( ...
    'iteration', NaN, ...
    'current_max_abs_vote', NaN, ...
    'current_reduced_vote_l2', NaN, ...
    'current_vote_l2', NaN, ...
    'current_max_abs_gap', NaN, ...
    'current_residual_norm', NaN, ...
    'current_merit', NaN, ...
    'fd_rank', NaN, ...
    'fd_cond_proxy', NaN, ...
    'raw_step_max_abs', NaN, ...
    'trust_region_binding', false, ...
    'attempt_count', 0, ...
    'accepted', false, ...
    'accepted_search_label', "", ...
    'accepted_fd_step', NaN, ...
    'accepted_ridge_lambda', NaN, ...
    'accepted_trust_region_log_step', NaN, ...
    'accepted_direction', 0, ...
    'accepted_scale', 0, ...
    'accepted_max_abs_vote', NaN, ...
    'accepted_reduced_vote_l2', NaN, ...
    'accepted_max_abs_gap', NaN, ...
    'accepted_merit', NaN), max_outer_iter, 1);

best_eval = evaluate_joint_candidate_local(current_price_path, current_wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, political_response_mode, political_response_sigma, trace_log_path, sprintf('k%02d_stage_init', k), objective_mask);
improved_any = false;
early_accepted = false;
best_trial_eval = best_eval;
best_trial_theta = current_theta;

if should_early_accept_stage_init_local(k, best_eval, political_response_mode, stage_init_accept_mode)
    early_accepted = true;
    iteration_log(1).iteration = 0;
    iteration_log(1).current_max_abs_vote = best_eval.metrics.max_abs_vote;
    iteration_log(1).current_reduced_vote_l2 = best_eval.metrics.reduced_vote_l2;
    iteration_log(1).current_vote_l2 = best_eval.metrics.vote_l2;
    iteration_log(1).current_max_abs_gap = best_eval.metrics.max_abs_gap;
    iteration_log(1).current_residual_norm = best_eval.metrics.residual_norm;
    iteration_log(1).current_merit = best_eval.metrics.merit;
    iteration_log(1).fd_rank = 0;
    iteration_log(1).fd_cond_proxy = 0;
    iteration_log(1).raw_step_max_abs = 0;
    iteration_log(1).trust_region_binding = false;
    iteration_log(1).attempt_count = 0;
    iteration_log(1).accepted = true;
    iteration_log(1).accepted_search_label = "early_accept_stage_init";
    iteration_log(1).accepted_fd_step = 0;
    iteration_log(1).accepted_ridge_lambda = 0;
    iteration_log(1).accepted_trust_region_log_step = 0;
    iteration_log(1).accepted_direction = 0;
    iteration_log(1).accepted_scale = 0;
    iteration_log(1).accepted_max_abs_vote = best_eval.metrics.max_abs_vote;
    iteration_log(1).accepted_reduced_vote_l2 = best_eval.metrics.reduced_vote_l2;
    iteration_log(1).accepted_max_abs_gap = best_eval.metrics.max_abs_gap;
    iteration_log(1).accepted_merit = best_eval.metrics.merit;
    append_trace_line_local(trace_log_path, sprintf(['event=stage_early_accept k=%d max_abs_vote=%.12g ' ...
        'max_abs_gap=%.12g merit=%.12g'], ...
        k, best_eval.metrics.max_abs_vote, best_eval.metrics.max_abs_gap, best_eval.metrics.merit));
else
for iter = 1:max_outer_iter
    base_eval = evaluate_joint_candidate_local(current_price_path, current_wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, political_response_mode, political_response_sigma, trace_log_path, sprintf('k%02d_iter%02d_base', k, iter), objective_mask);
    iteration_log(iter).iteration = iter;
    iteration_log(iter).current_max_abs_vote = base_eval.metrics.max_abs_vote;
    iteration_log(iter).current_reduced_vote_l2 = base_eval.metrics.reduced_vote_l2;
    iteration_log(iter).current_vote_l2 = base_eval.metrics.vote_l2;
    iteration_log(iter).current_max_abs_gap = base_eval.metrics.max_abs_gap;
    iteration_log(iter).current_residual_norm = base_eval.metrics.residual_norm;
    iteration_log(iter).current_merit = base_eval.metrics.merit;

    chosen_eval = base_eval;
    chosen_theta = current_theta;
    accepted = false;
    chosen_search_label = "";
    chosen_fd_step = NaN;
    chosen_ridge_lambda = NaN;
    chosen_trust_region_log_step = NaN;
    chosen_direction = 0;
    chosen_scale = 0;
    fd_rank = NaN;
    fd_cond_proxy = NaN;
    raw_step_max_abs = NaN;
    trust_region_binding = false;
    attempt_count = 0;

    for fd_step_idx = 1:numel(fd_step_ladder)
        fd_step_now = fd_step_ladder(fd_step_idx);
        [jacobian, jacobian_stats] = build_wedge_fd_jacobian_local(base_eval, current_price_path, current_wedge_path, basis, demographic_path, fd_step_now, active_threshold_frac, housing_clear_max_iter, wedge_floor, wedge_cap, political_response_mode, political_response_sigma, trace_log_path, sprintf('k%02d_iter%02d', k, iter), objective_mask);
        fd_rank = jacobian_stats.rank;
        fd_cond_proxy = jacobian_stats.cond_proxy;

        for ridge_idx = 1:numel(ridge_ladder)
            ridge_now = ridge_ladder(ridge_idx);
            delta_theta = solve_reduced_step_local(jacobian, base_eval.metrics.reduced_vote_residual, ridge_now);
            raw_wedge_step = basis * delta_theta;
            raw_step_max_abs = max(raw_step_max_abs, max(abs(raw_wedge_step)));

            for trust_idx = 1:numel(trust_region_ladder)
                trust_now = trust_region_ladder(trust_idx);
                [newton_step, trust_binding_now, ~] = enforce_trust_region_local(raw_wedge_step, trust_now);
                trust_region_binding = trust_region_binding || trust_binding_now;

                [candidate_eval, candidate_theta, candidate_accepted, candidate_direction, candidate_scale, local_attempts, family_best_eval, family_best_theta] = ...
                    search_candidate_family_local(base_eval, current_wedge_path, fixed_wedge_path, newton_step, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, wedge_floor, wedge_cap, candidate_scales, political_response_mode, political_response_sigma, trace_log_path, sprintf('k%02d_iter%02d_newton_fd%02d_r%02d_t%02d', k, iter, fd_step_idx, ridge_idx, trust_idx), objective_mask);
                attempt_count = attempt_count + local_attempts;
                if family_best_eval.metrics.merit < best_trial_eval.metrics.merit
                    best_trial_eval = family_best_eval;
                    best_trial_theta = family_best_theta;
                end

                if candidate_accepted
                    chosen_eval = candidate_eval;
                    chosen_theta = candidate_theta;
                    accepted = true;
                    chosen_search_label = "newton";
                    chosen_fd_step = fd_step_now;
                    chosen_ridge_lambda = ridge_now;
                    chosen_trust_region_log_step = trust_now;
                    chosen_direction = candidate_direction;
                    chosen_scale = candidate_scale;
                    break;
                end
            end

            if accepted
                break;
            end
        end

        if accepted
            break;
        end
    end

    if ~accepted
        fallback_trust = trust_region_ladder(end);
        fallback_steps = build_fallback_search_steps_local(base_eval.metrics.reduced_vote_residual, basis, fallback_trust);
        for step_idx = 1:numel(fallback_steps)
            [candidate_eval, candidate_theta, candidate_accepted, candidate_direction, candidate_scale, local_attempts, family_best_eval, family_best_theta] = ...
                search_candidate_family_local(base_eval, current_wedge_path, fixed_wedge_path, fallback_steps(step_idx).step_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, wedge_floor, wedge_cap, candidate_scales, political_response_mode, political_response_sigma, trace_log_path, sprintf('k%02d_iter%02d_fallback_%s', k, iter, char(string(fallback_steps(step_idx).label))), objective_mask);
            attempt_count = attempt_count + local_attempts;
            if family_best_eval.metrics.merit < best_trial_eval.metrics.merit
                best_trial_eval = family_best_eval;
                best_trial_theta = family_best_theta;
            end

            if candidate_accepted
                chosen_eval = candidate_eval;
                chosen_theta = candidate_theta;
                accepted = true;
                chosen_search_label = fallback_steps(step_idx).label;
                chosen_fd_step = 0.0;
                chosen_ridge_lambda = 0.0;
                chosen_trust_region_log_step = fallback_trust;
                chosen_direction = candidate_direction;
                chosen_scale = candidate_scale;
                break;
            end
        end
    end

    iteration_log(iter).fd_rank = fd_rank;
    iteration_log(iter).fd_cond_proxy = fd_cond_proxy;
    iteration_log(iter).raw_step_max_abs = raw_step_max_abs;
    iteration_log(iter).trust_region_binding = trust_region_binding;
    iteration_log(iter).attempt_count = attempt_count;
    iteration_log(iter).accepted = accepted;
    iteration_log(iter).accepted_search_label = chosen_search_label;
    iteration_log(iter).accepted_fd_step = chosen_fd_step;
    iteration_log(iter).accepted_ridge_lambda = chosen_ridge_lambda;
    iteration_log(iter).accepted_trust_region_log_step = chosen_trust_region_log_step;
    iteration_log(iter).accepted_direction = chosen_direction;
    iteration_log(iter).accepted_scale = chosen_scale;
    iteration_log(iter).accepted_max_abs_vote = chosen_eval.metrics.max_abs_vote;
    iteration_log(iter).accepted_reduced_vote_l2 = chosen_eval.metrics.reduced_vote_l2;
    iteration_log(iter).accepted_max_abs_gap = chosen_eval.metrics.max_abs_gap;
    iteration_log(iter).accepted_merit = chosen_eval.metrics.merit;

    best_eval = chosen_eval;
    if accepted
        improved_any = true;
        current_theta = chosen_theta;
        current_wedge_path = chosen_eval.wedge_path(:);
        current_price_path = chosen_eval.price_path(:);
        if chosen_eval.metrics.max_abs_vote < 1e-3
            break;
        end
    else
        break;
    end
end
end

completed = find(~isnan([iteration_log.iteration]), 1, 'last');
if isempty(completed)
    completed = 1;
end

summary = table( ...
    (1:completed)', ...
    [iteration_log(1:completed).current_max_abs_vote]', ...
    [iteration_log(1:completed).current_reduced_vote_l2]', ...
    [iteration_log(1:completed).current_vote_l2]', ...
    [iteration_log(1:completed).current_max_abs_gap]', ...
    [iteration_log(1:completed).current_residual_norm]', ...
    [iteration_log(1:completed).current_merit]', ...
    [iteration_log(1:completed).fd_rank]', ...
    [iteration_log(1:completed).fd_cond_proxy]', ...
    [iteration_log(1:completed).raw_step_max_abs]', ...
    [iteration_log(1:completed).trust_region_binding]', ...
    [iteration_log(1:completed).attempt_count]', ...
    [iteration_log(1:completed).accepted]', ...
    string({iteration_log(1:completed).accepted_search_label})', ...
    [iteration_log(1:completed).accepted_fd_step]', ...
    [iteration_log(1:completed).accepted_ridge_lambda]', ...
    [iteration_log(1:completed).accepted_trust_region_log_step]', ...
    [iteration_log(1:completed).accepted_direction]', ...
    [iteration_log(1:completed).accepted_scale]', ...
    [iteration_log(1:completed).accepted_max_abs_vote]', ...
    [iteration_log(1:completed).accepted_reduced_vote_l2]', ...
    [iteration_log(1:completed).accepted_max_abs_gap]', ...
    [iteration_log(1:completed).accepted_merit]', ...
    'VariableNames', { ...
        'iteration', 'current_max_abs_vote', 'current_reduced_vote_l2', 'current_vote_l2', ...
        'current_max_abs_gap', 'current_residual_norm', 'current_merit', 'fd_rank', ...
        'fd_cond_proxy', 'raw_step_max_abs', 'trust_region_binding', 'attempt_count', 'accepted', ...
        'accepted_search_label', 'accepted_fd_step', 'accepted_ridge_lambda', 'accepted_trust_region_log_step', ...
        'accepted_direction', 'accepted_scale', 'accepted_max_abs_vote', ...
        'accepted_reduced_vote_l2', 'accepted_max_abs_gap', 'accepted_merit'});

result = struct();
result.horizon_k = k;
result.run_dir = string(stage_run_dir);
result.iterations = completed;
result.improved_any = improved_any;
result.final_price_path = best_eval.price_path(:);
result.final_wedge_path = best_eval.wedge_path(:);
result.final_vote_path = best_eval.vote_path(:);
result.objective_horizon = nnz(objective_mask > 0);
result.final_metrics = best_eval.metrics;
result.best_trial_price_path = best_trial_eval.price_path(:);
result.best_trial_wedge_path = best_trial_eval.wedge_path(:);
result.best_trial_vote_path = best_trial_eval.vote_path(:);
result.best_trial_metrics = best_trial_eval.metrics;
result.best_trial_theta = best_trial_theta(:);
result.fixed_wedge_path = fixed_wedge_path(:);
result.iteration_log = iteration_log(1:completed);
result.demographic_source_mode = string(demographic_source_mode);
result.political_response_mode = string(political_response_mode);
result.political_response_sigma = political_response_sigma;
result.early_accepted = early_accepted;
result.stage_init_accept_mode = string(stage_init_accept_mode);
result.trace_log_path = string(trace_log_path);
append_trace_line_local(trace_log_path, sprintf(['event=stage_done k=%d completed=%d improved_any=%d early_accepted=%d ' ...
    'final_max_abs_vote=%.12g final_reduced_vote_l2=%.12g final_max_abs_gap=%.12g final_merit=%.12g ' ...
    'best_trial_max_abs_vote=%.12g best_trial_reduced_vote_l2=%.12g best_trial_max_abs_gap=%.12g best_trial_merit=%.12g'], ...
    k, completed, improved_any, early_accepted, best_eval.metrics.max_abs_vote, best_eval.metrics.reduced_vote_l2, best_eval.metrics.max_abs_gap, best_eval.metrics.merit, ...
    best_trial_eval.metrics.max_abs_vote, best_trial_eval.metrics.reduced_vote_l2, best_trial_eval.metrics.max_abs_gap, best_trial_eval.metrics.merit));
end

function tf = should_early_accept_stage_init_local(k, eval_result, political_response_mode, stage_init_accept_mode)
mode = lower(string(political_response_mode));
accept_mode = lower(string(stage_init_accept_mode));
if accept_mode == "stage_init_only" || accept_mode == "probe"
    tf = mode ~= "hard_sign";
    return;
end
tf = k >= 4 && mode ~= "hard_sign" && ...
    eval_result.metrics.max_abs_vote <= 5e-3 && ...
    eval_result.metrics.max_abs_gap <= 1e-2 && ...
    eval_result.metrics.merit <= 1e-4;
end

function eval_result = evaluate_joint_candidate_local(price_guess_path, wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, political_response_mode, political_response_sigma, trace_log_path, trace_label, objective_mask)
if nargin < 9 || isempty(trace_log_path)
    trace_log_path = '';
end
if nargin < 10 || isempty(trace_label)
    trace_label = 'eval';
end
if nargin < 11 || isempty(objective_mask)
    objective_mask = ones(numel(price_guess_path), 1);
end
objective_mask = sanitize_objective_mask_local(objective_mask, numel(price_guess_path));

params = default_joint_inner_params_local();
params.max_iter = housing_clear_max_iter;
params.compute_political_path = true;
params.save_current_path_pass = false;
params.save_period_details = true;
params.save_political_details = should_save_political_details_local(political_response_mode);
params.supply_wedge_path = wedge_path(:);
params.supply_wedge_space = 'log';
params.trace_log_path = trace_log_path;
params.trace_label = sprintf('%s_inner', sanitize_trace_label_local(trace_label));
params.political_response_mode = political_response_mode;
params.political_response_sigma = political_response_sigma;

append_trace_line_local(trace_log_path, sprintf(['event=eval_start label=%s max_k=%d price_first=%.12g price_last=%.12g ' ...
    'wedge_first=%.12g wedge_last=%.12g wedge_abs_max=%.12g sigma=%.6g'], ...
    sanitize_trace_label_local(trace_label), numel(price_guess_path), price_guess_path(1), price_guess_path(end), ...
    wedge_path(1), wedge_path(end), max(abs(wedge_path(:))), political_response_sigma));
append_trace_line_local(trace_log_path, sprintf('event=eval_before_inner label=%s', sanitize_trace_label_local(trace_label)));
try
    solve_results = solve_transition_re_no_politics(price_guess_path(:), demographic_path, params);
catch err
    append_trace_line_local(trace_log_path, sprintf('event=eval_error label=%s message=%s', ...
        sanitize_trace_label_local(trace_label), sanitize_trace_label_local(err.message)));
    rethrow(err);
end
residual_norm = NaN;
if solve_results.iterations >= 1 && numel(solve_results.iteration_log) >= solve_results.iterations
    residual_norm = solve_results.iteration_log(solve_results.iterations).residual_norm;
end
append_trace_line_local(trace_log_path, sprintf('event=eval_after_inner label=%s inner_iters=%d max_abs_gap=%.12g residual_norm=%.12g', ...
    sanitize_trace_label_local(trace_label), solve_results.iterations, solve_results.update_diagnostics.max_abs_gap, residual_norm));
vote_path = solve_results.political.equal_weight_vote_path(:);
active_mask = build_active_mask_local(vote_path, active_threshold_frac, objective_mask);
unlocked_mask = double(any(abs(basis) > 1e-14, 2));
if any(unlocked_mask == 0)
    active_mask = max(active_mask, unlocked_mask .* objective_mask);
end
weighted_vote_path = vote_path .* active_mask;
reduced_vote_residual = basis' * weighted_vote_path;
smooth_diagnostics = summarize_smooth_diagnostics_local(solve_results, political_response_mode, political_response_sigma);
metrics = summarize_joint_metrics_local(solve_results, vote_path, weighted_vote_path, reduced_vote_residual, smooth_diagnostics, active_mask, unlocked_mask, objective_mask);
append_trace_line_local(trace_log_path, sprintf(['event=eval_done label=%s max_abs_vote=%.12g reduced_vote_l2=%.12g ' ...
    'max_abs_gap=%.12g merit=%.12g smooth_available=%d scaled_abs_median=%.12g scaled_abs_max=%.12g ' ...
    'sat095=%.12g sat099=%.12g w_sat095=%.12g w_sat099=%.12g w_resp_abs_mean=%.12g ' ...
    'active_count=%d unlocked_count=%d unlocked_active_count=%d tail_max_abs_vote=%.12g prefix_max_abs_vote=%.12g ' ...
    'tail_max_abs_gap=%.12g prefix_max_abs_gap=%.12g'], ...
    sanitize_trace_label_local(trace_label), metrics.max_abs_vote, metrics.reduced_vote_l2, ...
    metrics.max_abs_gap, metrics.merit, smooth_diagnostics.available, ...
    smooth_diagnostics.scaled_abs_median, smooth_diagnostics.scaled_abs_max, ...
    smooth_diagnostics.saturation_share_095, smooth_diagnostics.saturation_share_099, ...
    smooth_diagnostics.mass_weighted_saturation_share_095, smooth_diagnostics.mass_weighted_saturation_share_099, ...
    smooth_diagnostics.mass_weighted_response_abs_mean, metrics.active_count, metrics.unlocked_count, ...
    metrics.unlocked_active_count, metrics.tail_max_abs_vote, metrics.prefix_max_abs_vote, ...
    metrics.tail_max_abs_gap, metrics.prefix_max_abs_gap));

eval_result = struct();
eval_result.price_path = solve_results.final_price_path(:);
eval_result.wedge_path = wedge_path(:);
eval_result.vote_path = vote_path(:);
eval_result.active_mask = active_mask(:);
eval_result.unlocked_mask = unlocked_mask(:);
eval_result.weighted_vote_path = weighted_vote_path(:);
eval_result.objective_mask = objective_mask(:);
eval_result.metrics = metrics;
eval_result.smooth_diagnostics = smooth_diagnostics;
end

function [jacobian, stats] = build_wedge_fd_jacobian_local(base_eval, current_price_path, current_wedge_path, basis, demographic_path, finite_diff_step, active_threshold_frac, housing_clear_max_iter, wedge_floor, wedge_cap, political_response_mode, political_response_sigma, trace_log_path, trace_prefix, objective_mask)
if nargin < 15 || isempty(objective_mask)
    objective_mask = ones(numel(current_price_path), 1);
end
num_basis = size(basis, 2);
jacobian = NaN(numel(base_eval.metrics.reduced_vote_residual), num_basis);
base_residual = base_eval.metrics.reduced_vote_residual(:);

for j = 1:num_basis
    perturb_path = clamp_path_local(current_wedge_path(:) + finite_diff_step .* basis(:, j), wedge_floor, wedge_cap);
    perturbed_eval = evaluate_joint_candidate_local(current_price_path, perturb_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, political_response_mode, political_response_sigma, trace_log_path, sprintf('%s_fd%02d', trace_prefix, j), objective_mask);
    jacobian(:, j) = (perturbed_eval.metrics.reduced_vote_residual(:) - base_residual) ./ finite_diff_step;
end

singular_values = svd(jacobian, 'econ');
if isempty(singular_values)
    stats.rank = 0;
    stats.cond_proxy = Inf;
else
    stats.rank = sum(singular_values > 1e-10);
    stats.cond_proxy = singular_values(1) ./ max(singular_values(end), 1e-10);
end
end

function metrics = summarize_joint_metrics_local(solve_results, vote_path, weighted_vote_path, reduced_vote_residual, smooth_diagnostics, active_mask, unlocked_mask, objective_mask)
if nargin < 8 || isempty(objective_mask)
    objective_mask = ones(numel(vote_path), 1);
end
objective_mask = sanitize_objective_mask_local(objective_mask, numel(vote_path));
metrics = struct();
objective_vote_path = vote_path(objective_mask > 0);
metrics.max_abs_vote = max(abs(objective_vote_path));
metrics.vote_l2 = norm(objective_vote_path, 2);
metrics.full_max_abs_vote = max(abs(vote_path));
metrics.full_vote_l2 = norm(vote_path, 2);
metrics.ghost_max_abs_vote = masked_max_abs_local(vote_path, 1.0 - objective_mask);
metrics.active_max_abs_vote = max(abs(weighted_vote_path));
metrics.active_vote_l2 = norm(weighted_vote_path, 2);
metrics.reduced_vote_residual = reduced_vote_residual(:);
metrics.reduced_vote_l2 = norm(reduced_vote_residual, 2);
metrics.residual_norm = solve_results.iteration_log(solve_results.iterations).residual_norm;
locked_mask = 1.0 - unlocked_mask(:);
objective_unlocked_mask = unlocked_mask(:) .* objective_mask(:);
objective_locked_mask = locked_mask(:) .* objective_mask(:);
metrics.active_count = nnz(active_mask(:) > 0);
metrics.unlocked_count = nnz(unlocked_mask(:) > 0);
metrics.unlocked_active_count = nnz(unlocked_mask(:) > 0 & active_mask(:) > 0);
metrics.objective_horizon = nnz(objective_mask > 0);
metrics.tail_max_abs_vote = masked_max_abs_local(vote_path, objective_unlocked_mask);
metrics.prefix_max_abs_vote = masked_max_abs_local(vote_path, objective_locked_mask);
gap_path = extract_gap_path_local(solve_results);
metrics.max_abs_gap = masked_max_abs_local(gap_path, objective_mask);
metrics.full_max_abs_gap = max(abs(gap_path));
metrics.ghost_max_abs_gap = masked_max_abs_local(gap_path, 1.0 - objective_mask);
metrics.tail_max_abs_gap = masked_max_abs_local(gap_path, objective_unlocked_mask);
metrics.prefix_max_abs_gap = masked_max_abs_local(gap_path, objective_locked_mask);
metrics.merit = metrics.reduced_vote_l2.^2 + ...
    0.25 .* metrics.vote_l2.^2 + ...
    0.10 .* metrics.max_abs_gap.^2 + ...
    0.01 .* metrics.residual_norm.^2;
metrics.smooth_diagnostics = smooth_diagnostics;
end

function value = masked_max_abs_local(path_like, mask_like)
path_like = path_like(:);
mask_like = mask_like(:) > 0;
if isempty(path_like) || isempty(mask_like) || numel(path_like) ~= numel(mask_like) || ~any(mask_like)
    value = NaN;
else
    value = max(abs(path_like(mask_like)));
end
end

function objective_mask = build_objective_mask_local(T, objective_horizon)
objective_horizon = min(max(round(objective_horizon), 1), T);
objective_mask = zeros(T, 1);
objective_mask(1:objective_horizon) = 1.0;
end

function objective_mask = sanitize_objective_mask_local(objective_mask, T)
objective_mask = double(objective_mask(:) > 0);
if numel(objective_mask) ~= T
    error('objective_mask must have one entry per transition period.');
end
if ~any(objective_mask > 0)
    objective_mask(1:min(T, 1)) = 1.0;
end
end

function gap_path = extract_gap_path_local(solve_results)
if isfield(solve_results, 'log_price_residual_raw')
    gap_path = solve_results.log_price_residual_raw(:);
elseif isfield(solve_results, 'period_diagnostics') && isfield(solve_results.period_diagnostics, 'log_price_residual_raw')
    gap_path = solve_results.period_diagnostics.log_price_residual_raw(:);
else
    gap_path = NaN(numel(solve_results.final_price_path), 1);
end
end

function tf = is_admissible_joint_candidate_local(candidate_metrics, baseline_metrics)
vote_guard = max(1e-4, 0.10 .* baseline_metrics.max_abs_vote);
gap_guard = max(5e-4, 0.10 .* baseline_metrics.max_abs_gap);
tf = candidate_metrics.max_abs_vote <= baseline_metrics.max_abs_vote + vote_guard && ...
    candidate_metrics.max_abs_gap <= baseline_metrics.max_abs_gap + gap_guard;
end

function tf = is_better_joint_candidate_local(candidate_metrics, incumbent_metrics, baseline_metrics)
merit_guard = max(1e-6, 0.05 .* baseline_metrics.merit);
tf = is_admissible_joint_candidate_local(candidate_metrics, baseline_metrics) && ...
    candidate_metrics.merit < (incumbent_metrics.merit - merit_guard);
end

function active_mask = build_active_mask_local(vote_path, active_threshold_frac, objective_mask)
vote_path = vote_path(:);
if nargin < 3 || isempty(objective_mask)
    objective_mask = ones(size(vote_path));
end
objective_mask = sanitize_objective_mask_local(objective_mask, numel(vote_path));
target_idx = objective_mask > 0;
active_mask = zeros(size(vote_path));
if ~any(target_idx)
    active_mask(1:min(numel(vote_path), 3)) = 1.0;
    return;
end
threshold = active_threshold_frac .* max(abs(vote_path(target_idx)));
active_mask(target_idx & abs(vote_path) >= threshold) = 1.0;
active_idx = find(active_mask > 0);
for i = 1:numel(active_idx)
    idx = active_idx(i);
    left_idx = max(1, idx - 1);
    right_idx = min(numel(vote_path), idx + 1);
    active_mask(left_idx:right_idx) = max(active_mask(left_idx:right_idx), objective_mask(left_idx:right_idx));
end
if all(active_mask == 0)
    first_targets = find(target_idx, min(nnz(target_idx), 3), 'first');
    active_mask(first_targets) = 1.0;
end
end

function basis = build_block_basis_local(T, basis_count)
basis = zeros(T, basis_count);
edges = round(linspace(1, T + 1, basis_count + 1));
for j = 1:basis_count
    left_idx = edges(j);
    right_idx = max(edges(j + 1) - 1, left_idx);
    basis(left_idx:right_idx, j) = 1.0;
    norm_j = norm(basis(:, j), 2);
    if norm_j > 0
        basis(:, j) = basis(:, j) ./ norm_j;
    end
end
end

function basis = build_objective_block_basis_local(T, basis_count, objective_horizon)
objective_horizon = min(max(round(objective_horizon), 1), T);
objective_basis_count = min(max(round(basis_count), 1), objective_horizon);
basis = zeros(T, objective_basis_count);
basis(1:objective_horizon, :) = build_block_basis_local(objective_horizon, objective_basis_count);
end

function basis = build_tail_block_basis_local(T, basis_count, prefix_lock_length)
prefix_lock_length = min(max(round(prefix_lock_length), 0), T - 1);
tail_length = T - prefix_lock_length;
tail_basis_count = min(max(round(basis_count), 1), tail_length);
basis = zeros(T, tail_basis_count);
basis(prefix_lock_length + 1:end, :) = build_block_basis_local(tail_length, tail_basis_count);
end

function params = default_joint_inner_params_local()
params = struct();
params.max_iter = 4;
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
params.transition_policy_mode = 'full_backward';
params.terminal_price_rule = 'flat_tail';
params.terminal_reference_mode = 'path_end_price';
params.compute_political_path = true;
params.save_political_details = false;
params.save_period_details = true;
params.save_current_path_pass = false;
params.fixed_point_price_min = 0.05;
params.fixed_point_price_max = 5.00;
params.steady_state_reference_mode = 'original_5yr_political';
params.coalition_params = struct( ...
    'alpha_owner', 0.0, ...
    'alpha_old_owner', 0.0, ...
    'alpha_leverage', 0.0, ...
    'alpha_bighouse', 0.0);
end

function delta_coeff = solve_reduced_step_local(jacobian, residual_vector, ridge_lambda)
residual_vector = residual_vector(:);
normal_matrix = jacobian' * jacobian + ridge_lambda .* eye(size(jacobian, 2));
rhs = -(jacobian' * residual_vector);
delta_coeff = normal_matrix \ rhs;
if any(~isfinite(delta_coeff))
    delta_coeff = zeros(size(rhs));
end
end

function [chosen_eval, chosen_theta, accepted, chosen_direction, chosen_scale, attempt_count, best_seen_eval, best_seen_theta] = search_candidate_family_local(base_eval, current_wedge_path, fixed_wedge_path, step_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, wedge_floor, wedge_cap, candidate_scales, political_response_mode, political_response_sigma, trace_log_path, trace_prefix, objective_mask)
if nargin < 16 || isempty(objective_mask)
    objective_mask = ones(numel(current_wedge_path), 1);
end
chosen_eval = base_eval;
chosen_theta = basis \ (current_wedge_path - fixed_wedge_path);
accepted = false;
chosen_direction = 0;
chosen_scale = 0;
attempt_count = 0;
best_seen_eval = base_eval;
best_seen_theta = chosen_theta;

if max(abs(step_path)) < 1e-10
    return;
end

direction_list = [1, -1];
for direction_idx = 1:numel(direction_list)
    direction_sign = direction_list(direction_idx);
    for scale_idx = 1:numel(candidate_scales)
        scale = candidate_scales(scale_idx);
        candidate_wedge_path = clamp_path_local(current_wedge_path + direction_sign .* scale .* step_path, wedge_floor, wedge_cap);
        if max(abs(candidate_wedge_path - current_wedge_path)) < 1e-10
            continue;
        end

        attempt_count = attempt_count + 1;
        candidate_theta = basis \ (candidate_wedge_path - fixed_wedge_path);
        if direction_sign > 0
            direction_tag = 'pos';
        else
            direction_tag = 'neg';
        end
        candidate_eval = evaluate_joint_candidate_local(base_eval.price_path, candidate_wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter, political_response_mode, political_response_sigma, trace_log_path, sprintf('%s_%s_s%0.3g', trace_prefix, direction_tag, scale), objective_mask);
        if is_admissible_joint_candidate_local(candidate_eval.metrics, base_eval.metrics) && candidate_eval.metrics.merit < best_seen_eval.metrics.merit
            best_seen_eval = candidate_eval;
            best_seen_theta = candidate_theta;
        end
        if is_better_joint_candidate_local(candidate_eval.metrics, chosen_eval.metrics, base_eval.metrics)
            chosen_eval = candidate_eval;
            chosen_theta = candidate_theta;
            accepted = true;
            chosen_direction = direction_sign;
            chosen_scale = scale;
        end
    end
end
end

function fallback_steps = build_fallback_search_steps_local(reduced_vote_residual, basis, trust_region_log_step)
fallback_steps = struct('label', {}, 'step_path', {});

residual_step = basis * (-reduced_vote_residual(:));
residual_step = scale_direction_to_trust_local(residual_step, trust_region_log_step);
if max(abs(residual_step)) > 1e-10
    fallback_steps(end + 1).label = "residual";
    fallback_steps(end).step_path = residual_step;
end

for j = 1:size(basis, 2)
    basis_step = scale_direction_to_trust_local(basis(:, j), trust_region_log_step);
    if max(abs(basis_step)) > 1e-10
        fallback_steps(end + 1).label = sprintf('basis_%d', j); %#ok<AGROW>
        fallback_steps(end).step_path = basis_step;
    end
end
end

function direction = scale_direction_to_trust_local(direction, trust_region_log_step)
direction = direction(:);
max_abs_direction = max(abs(direction));
if max_abs_direction <= 1e-12
    direction = zeros(size(direction));
else
    direction = trust_region_log_step .* (direction ./ max_abs_direction);
end
end

function candidate_scales = expand_candidate_scales_local(candidate_scales)
candidate_scales = unique(candidate_scales(:), 'stable');
for extra_scale = [0.10, 0.05]
    if ~any(abs(candidate_scales(:) - extra_scale) < 1e-10)
        candidate_scales(end + 1, 1) = extra_scale; %#ok<AGROW>
    end
end
candidate_scales = sort(candidate_scales, 'descend');
end

function [step_path, trust_region_binding, raw_step_max_abs] = enforce_trust_region_local(step_path, trust_region_log_step)
step_path = step_path(:);
raw_step_max_abs = max(abs(step_path));
trust_region_binding = false;
if raw_step_max_abs > trust_region_log_step
    step_path = step_path .* (trust_region_log_step ./ raw_step_max_abs);
    trust_region_binding = true;
end
end

function price_path_guess = build_price_guess_local(default_seed_path, seed_price_csv_path, max_k)
if ~isempty(seed_price_csv_path)
    price_path_guess = readmatrix(seed_price_csv_path);
elseif ischar(default_seed_path) || isstring(default_seed_path)
    if isfile(default_seed_path)
        price_path_guess = readmatrix(default_seed_path);
    else
        price_path_guess = 0.34013605902777766;
    end
else
    price_path_guess = default_seed_path;
end

price_path_guess = fit_path_to_horizon_local(price_path_guess(:), max_k, 0.34013605902777766);
if any(~isfinite(price_path_guess)) || any(price_path_guess <= 0)
    error('Seed price path must contain finite positive values only.');
end
end

function wedge_path_guess = build_wedge_guess_local(seed_wedge_csv_path, max_k, wedge_floor, wedge_cap)
if ~isempty(seed_wedge_csv_path)
    wedge_path_guess = readmatrix(seed_wedge_csv_path);
else
    wedge_path_guess = 0.0;
end

wedge_path_guess = fit_path_to_horizon_local(wedge_path_guess(:), max_k, 0.0);
if any(~isfinite(wedge_path_guess))
    error('Seed wedge path must contain finite values only.');
end
wedge_path_guess = clamp_path_local(wedge_path_guess, wedge_floor, wedge_cap);
end

function fitted = fit_path_to_horizon_local(path_like, horizon_k, fallback_value)
if isempty(path_like)
    fitted = fallback_value .* ones(horizon_k, 1);
    return;
end
fitted = path_like(:);
if isscalar(fitted)
    fitted = fitted .* ones(horizon_k, 1);
elseif numel(fitted) < horizon_k
    fitted = [fitted; fitted(end) .* ones(horizon_k - numel(fitted), 1)];
elseif numel(fitted) > horizon_k
    fitted = fitted(1:horizon_k);
end
end

function clamped = clamp_path_local(path_like, lower_bound, upper_bound)
clamped = min(max(path_like(:), lower_bound), upper_bound);
end

function demographic_path_full = build_demographic_path_local(project_root, demographic_source_mode)
mode = lower(string(demographic_source_mode));
entrant_prefix = "entrant_survival_";
if startsWith(mode, entrant_prefix)
    scenario = extractAfter(mode, strlength(entrant_prefix));
    demographic_path_full = build_original_5yr_demographic_entrant_survival_path(project_root, [], scenario);
    return;
end
switch mode
    case "annual_subsampled"
        demographic_path_full = build_original_5yr_demographic_path_from_age_state_csv(project_root);
    case "historical_1950"
        demographic_path_full = build_original_5yr_demographic_path_from_historical_age_shares(project_root);
    case {"historical_1950_two_group", "historical_1950_old_young_proxy"}
        demographic_path_full = build_original_5yr_demographic_two_group_proxy(project_root);
    otherwise
        error('Unsupported demographic_source_mode: %s', demographic_source_mode);
end
end

function demographic_path = truncate_demographic_path_local(demographic_path_full, max_k)
demographic_path = demographic_path_full;
demographic_path.periods = demographic_path_full.periods(1:max_k);
demographic_path.cohort_scale_by_age = demographic_path_full.cohort_scale_by_age(1:max_k, :);
if isfield(demographic_path_full, 'labels')
    demographic_path.labels = demographic_path_full.labels(1:max_k);
end
if isfield(demographic_path_full, 'population_by_age')
    demographic_path.population_by_age = demographic_path_full.population_by_age(1:max_k, :);
end
if isfield(demographic_path_full, 'entrant_path')
    demographic_path.entrant_path = demographic_path_full.entrant_path(1:max_k, :);
end
if isfield(demographic_path_full, 'survival_rates')
    demographic_path.survival_rates = demographic_path_full.survival_rates;
end
end

function metric_column = extract_metric_local(stage_results, field_name)
metric_column = NaN(numel(stage_results), 1);
for idx = 1:numel(stage_results)
    if isfield(stage_results(idx).final_metrics, field_name)
        metric_column(idx) = stage_results(idx).final_metrics.(field_name);
    end
end
end

function tf = should_save_political_details_local(political_response_mode)
mode = string(political_response_mode);
tf = ~any(strcmpi(mode, ["hard_sign", "sign"]));
end

function diagnostics = summarize_smooth_diagnostics_local(solve_results, political_response_mode, political_response_sigma)
diagnostics = struct( ...
    'available', false, ...
    'obs_count', 0, ...
    'mass_total', NaN, ...
    'value_abs_median', NaN, ...
    'value_abs_max', NaN, ...
    'scaled_abs_median', NaN, ...
    'scaled_abs_max', NaN, ...
    'response_abs_median', NaN, ...
    'response_abs_max', NaN, ...
    'saturation_share_095', NaN, ...
    'saturation_share_099', NaN, ...
    'mass_weighted_scaled_abs_mean', NaN, ...
    'mass_weighted_response_abs_mean', NaN, ...
    'mass_weighted_saturation_share_095', NaN, ...
    'mass_weighted_saturation_share_099', NaN);

if ~should_save_political_details_local(political_response_mode)
    return;
end

if ~isfield(solve_results, 'political') || ~isfield(solve_results.political, 'preference_value_by_period_age') || ...
        ~isfield(solve_results.political, 'preference_response_by_period_age')
    return;
end

value_vector = flatten_numeric_cells_local(solve_results.political.preference_value_by_period_age);
response_vector = flatten_numeric_cells_local(solve_results.political.preference_response_by_period_age);
if isempty(value_vector) || isempty(response_vector)
    return;
end

[mass_value_vector, mass_response_vector, mass_weights] = flatten_weighted_smooth_cells_local(solve_results);

value_abs = abs(value_vector(:));
response_abs = abs(response_vector(:));
scaled_abs = value_abs ./ max(2 .* political_response_sigma, 1e-12);

diagnostics.available = true;
diagnostics.obs_count = numel(value_abs);
diagnostics.value_abs_median = median(value_abs);
diagnostics.value_abs_max = max(value_abs);
diagnostics.scaled_abs_median = median(scaled_abs);
diagnostics.scaled_abs_max = max(scaled_abs);
diagnostics.response_abs_median = median(response_abs);
diagnostics.response_abs_max = max(response_abs);
diagnostics.saturation_share_095 = mean(response_abs >= 0.95);
diagnostics.saturation_share_099 = mean(response_abs >= 0.99);

if ~isempty(mass_weights) && sum(mass_weights) > 0
    mass_weights = mass_weights(:) ./ sum(mass_weights);
    mass_value_abs = abs(mass_value_vector(:));
    mass_response_abs = abs(mass_response_vector(:));
    mass_scaled_abs = mass_value_abs ./ max(2 .* political_response_sigma, 1e-12);

    diagnostics.mass_total = sum(mass_weights);
    diagnostics.mass_weighted_scaled_abs_mean = sum(mass_weights .* mass_scaled_abs);
    diagnostics.mass_weighted_response_abs_mean = sum(mass_weights .* mass_response_abs);
    diagnostics.mass_weighted_saturation_share_095 = sum(mass_weights .* double(mass_response_abs >= 0.95));
    diagnostics.mass_weighted_saturation_share_099 = sum(mass_weights .* double(mass_response_abs >= 0.99));
end
end

function values = flatten_numeric_cells_local(cell_like)
values = [];
if isempty(cell_like)
    return;
end
for idx = 1:numel(cell_like)
    entry = cell_like{idx};
    if isempty(entry)
        continue;
    end
    numeric_entry = entry(:);
    numeric_entry = numeric_entry(isfinite(numeric_entry));
    if isempty(numeric_entry)
        continue;
    end
    values = [values; numeric_entry]; %#ok<AGROW>
end
end

function [value_vector, response_vector, weight_vector] = flatten_weighted_smooth_cells_local(solve_results)
value_vector = [];
response_vector = [];
weight_vector = [];

if ~isfield(solve_results, 'political') || ~isfield(solve_results.political, 'preference_value_by_period_age') || ...
        ~isfield(solve_results.political, 'preference_response_by_period_age') || ...
        ~isfield(solve_results, 'density_by_period_age')
    return;
end

value_cells = solve_results.political.preference_value_by_period_age;
response_cells = solve_results.political.preference_response_by_period_age;
density_cells = solve_results.density_by_period_age;

for idx = 1:numel(value_cells)
    if idx > numel(response_cells) || idx > numel(density_cells)
        break;
    end

    values = value_cells{idx};
    responses = response_cells{idx};
    densities = density_cells{idx};
    if isempty(values) || isempty(responses) || isempty(densities)
        continue;
    end
    if ~isequal(size(values), size(responses)) || ~isequal(size(values), size(densities))
        continue;
    end

    valid_mask = isfinite(values) & isfinite(responses) & isfinite(densities) & (densities > 0);
    if ~any(valid_mask, 'all')
        continue;
    end

    value_vector = [value_vector; values(valid_mask)]; %#ok<AGROW>
    response_vector = [response_vector; responses(valid_mask)]; %#ok<AGROW>
    weight_vector = [weight_vector; densities(valid_mask)]; %#ok<AGROW>
end
end

function append_trace_line_local(trace_log_path, line_text)
if nargin < 1 || isempty(trace_log_path)
    return;
end
trace_dir = fileparts(trace_log_path);
if ~exist(trace_dir, 'dir')
    mkdir(trace_dir);
end
fid = fopen(trace_log_path, 'a');
if fid < 0
    return;
end
cleanup = onCleanup(@() fclose(fid));
timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
fprintf(fid, '[%s] %s\n', timestamp, line_text);
end

function text = sanitize_trace_label_local(text)
text = char(string(text));
text = regexprep(text, '\s+', '_');
text = regexprep(text, '[^A-Za-z0-9_\.\-\=]+', '_');
end
