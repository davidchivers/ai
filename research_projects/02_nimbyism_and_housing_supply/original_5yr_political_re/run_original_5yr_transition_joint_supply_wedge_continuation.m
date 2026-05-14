function [summary, results] = run_original_5yr_transition_joint_supply_wedge_continuation( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    wedge_floor, wedge_cap, k_schedule, housing_clear_max_iter)
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
    'final_metrics', struct(), ...
    'iteration_log', []), numel(k_schedule), 1);

current_price_seed = seed_price_path(:);
current_wedge_seed = zeros(numel(current_price_seed), 1);

for stage_idx = 1:numel(k_schedule)
    k = k_schedule(stage_idx);
    demographic_path = truncate_demographic_path_local(demographic_path_full, k);
    stage_basis_count = min(k, basis_count);
    basis = build_block_basis_local(k, stage_basis_count);

    stage_price_seed = fit_path_to_horizon_local(current_price_seed, k, seed_price_path(max(1, min(numel(seed_price_path), k))));
    stage_wedge_seed = clamp_path_local(fit_path_to_horizon_local(current_wedge_seed, k, 0.0), wedge_floor, wedge_cap);
    stage_theta_seed = basis \ stage_wedge_seed;

    stage_run_dir = fullfile(output_dir, sprintf('k%02d', k));
    if ~exist(stage_run_dir, 'dir')
        mkdir(stage_run_dir);
    end

    [stage_summary, stage_result] = run_joint_stage_local( ...
        k, max_outer_iter, basis, stage_price_seed, stage_theta_seed, stage_run_dir, ...
        demographic_path, demographic_source_mode, finite_diff_step, ridge_lambda, candidate_scales, ...
        trust_region_log_step, active_threshold_frac, wedge_floor, wedge_cap, housing_clear_max_iter);

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
    stage_results(stage_idx).final_metrics = stage_result.final_metrics;
    stage_results(stage_idx).iteration_log = stage_result.iteration_log;

    current_price_seed = stage_result.final_price_path(:);
    current_wedge_seed = stage_result.final_wedge_path(:);
end

summary = table( ...
    k_schedule(:), ...
    [stage_results.iterations]', ...
    [stage_results.improved_any]', ...
    extract_metric_local(stage_results, 'max_abs_vote'), ...
    extract_metric_local(stage_results, 'reduced_vote_l2'), ...
    extract_metric_local(stage_results, 'max_abs_gap'), ...
    extract_metric_local(stage_results, 'merit'), ...
    'VariableNames', { ...
        'horizon_k', 'iterations_completed', 'improved_any', ...
        'final_max_abs_vote', 'final_reduced_vote_l2', 'final_max_abs_gap', 'final_merit'});

results = struct();
results.run_tag = string(run_tag);
results.output_dir = string(output_dir);
results.max_k = max_k;
results.k_schedule = k_schedule(:);
results.max_outer_iter = max_outer_iter;
results.basis_count = basis_count;
results.seed_price_csv_path = string(seed_price_csv_path);
results.demographic_source_mode = string(demographic_source_mode);
results.finite_diff_step = finite_diff_step;
results.ridge_lambda = ridge_lambda;
results.candidate_scales = candidate_scales(:);
results.trust_region_log_step = trust_region_log_step;
results.active_threshold_frac = active_threshold_frac;
results.wedge_floor = wedge_floor;
results.wedge_cap = wedge_cap;
results.housing_clear_max_iter = housing_clear_max_iter;
results.stage_results = stage_results;
results.message = 'Joint supply-wedge continuation branch completed using a wedge path as the outer political object and a housing-clearing inner solve.';

writetable(summary, fullfile(output_dir, sprintf('%s_summary.csv', run_tag)));
final_stage = stage_results(end);
writematrix(final_stage.final_price_path(:), fullfile(output_dir, sprintf('%s_final_price_path.csv', run_tag)));
writematrix(final_stage.final_wedge_path(:), fullfile(output_dir, sprintf('%s_final_wedge_path.csv', run_tag)));
writematrix(final_stage.final_vote_path(:), fullfile(output_dir, sprintf('%s_final_vote_path.csv', run_tag)));
save(fullfile(output_dir, sprintf('%s_results.mat', run_tag)), 'summary', 'results');
end

function [summary, result] = run_joint_stage_local(k, max_outer_iter, basis, price_seed_path, theta_seed, stage_run_dir, demographic_path, demographic_source_mode, finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, wedge_floor, wedge_cap, housing_clear_max_iter)
current_theta = theta_seed(:);
current_wedge_path = clamp_path_local(basis * current_theta, wedge_floor, wedge_cap);
current_price_path = price_seed_path(:);

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
    'accepted', false, ...
    'accepted_direction', 0, ...
    'accepted_scale', 0, ...
    'accepted_max_abs_vote', NaN, ...
    'accepted_reduced_vote_l2', NaN, ...
    'accepted_max_abs_gap', NaN, ...
    'accepted_merit', NaN), max_outer_iter, 1);

best_eval = evaluate_joint_candidate_local(current_price_path, current_wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter);
improved_any = false;

for iter = 1:max_outer_iter
    base_eval = evaluate_joint_candidate_local(current_price_path, current_wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter);
    [jacobian, jacobian_stats] = build_wedge_fd_jacobian_local(base_eval, current_price_path, current_wedge_path, basis, demographic_path, finite_diff_step, active_threshold_frac, housing_clear_max_iter, wedge_floor, wedge_cap);
    delta_theta = solve_reduced_step_local(jacobian, base_eval.metrics.reduced_vote_residual, ridge_lambda);
    raw_wedge_step = basis * delta_theta;
    [raw_wedge_step, trust_region_binding, raw_step_max_abs] = enforce_trust_region_local(raw_wedge_step, trust_region_log_step);

    iteration_log(iter).iteration = iter;
    iteration_log(iter).current_max_abs_vote = base_eval.metrics.max_abs_vote;
    iteration_log(iter).current_reduced_vote_l2 = base_eval.metrics.reduced_vote_l2;
    iteration_log(iter).current_vote_l2 = base_eval.metrics.vote_l2;
    iteration_log(iter).current_max_abs_gap = base_eval.metrics.max_abs_gap;
    iteration_log(iter).current_residual_norm = base_eval.metrics.residual_norm;
    iteration_log(iter).current_merit = base_eval.metrics.merit;
    iteration_log(iter).fd_rank = jacobian_stats.rank;
    iteration_log(iter).fd_cond_proxy = jacobian_stats.cond_proxy;
    iteration_log(iter).raw_step_max_abs = raw_step_max_abs;
    iteration_log(iter).trust_region_binding = trust_region_binding;

    chosen_eval = base_eval;
    chosen_theta = current_theta;
    accepted = false;
    chosen_direction = 0;
    chosen_scale = 0;
    direction_list = [1, -1];

    for direction_idx = 1:numel(direction_list)
        direction_sign = direction_list(direction_idx);
        for scale_idx = 1:numel(candidate_scales)
            scale = candidate_scales(scale_idx);
            candidate_wedge_path = clamp_path_local(current_wedge_path + direction_sign .* scale .* raw_wedge_step, wedge_floor, wedge_cap);
            if max(abs(candidate_wedge_path - current_wedge_path)) < 1e-10
                continue;
            end
            candidate_theta = basis \ candidate_wedge_path;
            candidate_eval = evaluate_joint_candidate_local(base_eval.price_path, candidate_wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter);
            if is_better_joint_candidate_local(candidate_eval.metrics, chosen_eval.metrics, base_eval.metrics)
                accepted = true;
                chosen_eval = candidate_eval;
                chosen_theta = candidate_theta;
                chosen_direction = direction_sign;
                chosen_scale = scale;
            end
        end
    end

    iteration_log(iter).accepted = accepted;
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
    [iteration_log(1:completed).accepted]', ...
    [iteration_log(1:completed).accepted_direction]', ...
    [iteration_log(1:completed).accepted_scale]', ...
    [iteration_log(1:completed).accepted_max_abs_vote]', ...
    [iteration_log(1:completed).accepted_reduced_vote_l2]', ...
    [iteration_log(1:completed).accepted_max_abs_gap]', ...
    [iteration_log(1:completed).accepted_merit]', ...
    'VariableNames', { ...
        'iteration', 'current_max_abs_vote', 'current_reduced_vote_l2', 'current_vote_l2', ...
        'current_max_abs_gap', 'current_residual_norm', 'current_merit', 'fd_rank', ...
        'fd_cond_proxy', 'raw_step_max_abs', 'trust_region_binding', 'accepted', ...
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
result.final_metrics = best_eval.metrics;
result.iteration_log = iteration_log(1:completed);
result.demographic_source_mode = string(demographic_source_mode);
end

function eval_result = evaluate_joint_candidate_local(price_guess_path, wedge_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter)
params = default_joint_inner_params_local();
params.max_iter = housing_clear_max_iter;
params.compute_political_path = true;
params.save_current_path_pass = false;
params.save_period_details = true;
params.supply_wedge_path = wedge_path(:);
params.supply_wedge_space = 'log';

solve_results = solve_transition_re_no_politics(price_guess_path(:), demographic_path, params);
vote_path = solve_results.political.equal_weight_vote_path(:);
active_mask = build_active_mask_local(vote_path, active_threshold_frac);
weighted_vote_path = vote_path .* active_mask;
reduced_vote_residual = basis' * weighted_vote_path;
metrics = summarize_joint_metrics_local(solve_results, vote_path, weighted_vote_path, reduced_vote_residual);

eval_result = struct();
eval_result.price_path = solve_results.final_price_path(:);
eval_result.wedge_path = wedge_path(:);
eval_result.vote_path = vote_path(:);
eval_result.active_mask = active_mask(:);
eval_result.weighted_vote_path = weighted_vote_path(:);
eval_result.metrics = metrics;
end

function [jacobian, stats] = build_wedge_fd_jacobian_local(base_eval, current_price_path, current_wedge_path, basis, demographic_path, finite_diff_step, active_threshold_frac, housing_clear_max_iter, wedge_floor, wedge_cap)
num_basis = size(basis, 2);
jacobian = NaN(numel(base_eval.metrics.reduced_vote_residual), num_basis);
base_residual = base_eval.metrics.reduced_vote_residual(:);

for j = 1:num_basis
    perturb_path = clamp_path_local(current_wedge_path(:) + finite_diff_step .* basis(:, j), wedge_floor, wedge_cap);
    perturbed_eval = evaluate_joint_candidate_local(current_price_path, perturb_path, basis, demographic_path, active_threshold_frac, housing_clear_max_iter);
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

function metrics = summarize_joint_metrics_local(solve_results, vote_path, weighted_vote_path, reduced_vote_residual)
metrics = struct();
metrics.max_abs_vote = max(abs(vote_path));
metrics.vote_l2 = norm(vote_path, 2);
metrics.active_max_abs_vote = max(abs(weighted_vote_path));
metrics.active_vote_l2 = norm(weighted_vote_path, 2);
metrics.reduced_vote_residual = reduced_vote_residual(:);
metrics.reduced_vote_l2 = norm(reduced_vote_residual, 2);
metrics.max_abs_gap = solve_results.update_diagnostics.max_abs_gap;
metrics.residual_norm = solve_results.iteration_log(solve_results.iterations).residual_norm;
metrics.merit = metrics.reduced_vote_l2.^2 + ...
    0.25 .* metrics.vote_l2.^2 + ...
    0.10 .* metrics.max_abs_gap.^2 + ...
    0.01 .* metrics.residual_norm.^2;
end

function tf = is_better_joint_candidate_local(candidate_metrics, incumbent_metrics, baseline_metrics)
vote_guard = max(1e-4, 0.10 .* baseline_metrics.max_abs_vote);
gap_guard = max(5e-4, 0.10 .* baseline_metrics.max_abs_gap);
tf = candidate_metrics.merit < (incumbent_metrics.merit - 1e-4) && ...
    candidate_metrics.max_abs_vote <= baseline_metrics.max_abs_vote + vote_guard && ...
    candidate_metrics.max_abs_gap <= baseline_metrics.max_abs_gap + gap_guard;
end

function active_mask = build_active_mask_local(vote_path, active_threshold_frac)
vote_path = vote_path(:);
threshold = active_threshold_frac .* max(abs(vote_path));
active_mask = double(abs(vote_path) >= threshold);
active_idx = find(active_mask > 0);
for i = 1:numel(active_idx)
    idx = active_idx(i);
    left_idx = max(1, idx - 1);
    right_idx = min(numel(vote_path), idx + 1);
    active_mask(left_idx:right_idx) = 1.0;
end
if all(active_mask == 0)
    active_mask(1:min(numel(vote_path), 3)) = 1.0;
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

function fitted = fit_path_to_horizon_local(path_like, horizon_k, fallback_value)
if isempty(path_like)
    fitted = fallback_value .* ones(horizon_k, 1);
    return;
end
fitted = path_like(:);
if numel(fitted) == 1
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
end

function metric_column = extract_metric_local(stage_results, field_name)
metric_column = NaN(numel(stage_results), 1);
for idx = 1:numel(stage_results)
    if isfield(stage_results(idx).final_metrics, field_name)
        metric_column(idx) = stage_results(idx).final_metrics.(field_name);
    end
end
end
