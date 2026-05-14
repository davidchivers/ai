function [summary, results] = run_original_5yr_transition_reduced_path_jacobian( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    price_floor, price_cap)
% Reduced-path Jacobian outer solver for the original 5-year transition.
%
% This is a distinct branch from the targeted line-search family. It treats
% the transition/Bellman block as a black box, parameterizes the log price
% path with a small basis, estimates a finite-difference Jacobian for the
% active political residuals, and then applies a damped least-squares step
% inside a trust region.

if nargin < 1 || isempty(max_k)
    max_k = 14;
end
if nargin < 2 || isempty(max_outer_iter)
    max_outer_iter = 3;
end
if nargin < 3 || isempty(basis_count)
    basis_count = 4;
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
    finite_diff_step = 2.5e-4;
end
if nargin < 8 || isempty(ridge_lambda)
    ridge_lambda = 1e-3;
end
if nargin < 9 || isempty(candidate_scales)
    candidate_scales = [1.0; 0.5; 0.25; 0.1];
end
if nargin < 10 || isempty(trust_region_log_step)
    trust_region_log_step = 2e-3;
end
if nargin < 11 || isempty(active_threshold_frac)
    active_threshold_frac = 0.65;
end
if nargin < 12 || isempty(price_floor)
    price_floor = 0.05;
end
if nargin < 13 || isempty(price_cap)
    price_cap = 5.00;
end

validateattributes(max_k, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(max_outer_iter, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(basis_count, {'double'}, {'scalar', 'integer', '>=', 2});
validateattributes(finite_diff_step, {'double'}, {'scalar', 'positive'});
validateattributes(ridge_lambda, {'double'}, {'scalar', 'nonnegative'});
validateattributes(candidate_scales, {'double'}, {'vector', 'nonempty', 'positive'});
validateattributes(trust_region_log_step, {'double'}, {'scalar', 'positive'});
validateattributes(active_threshold_frac, {'double'}, {'scalar', '>', 0, '<=', 1});
validateattributes(price_floor, {'double'}, {'scalar', 'positive'});
validateattributes(price_cap, {'double'}, {'scalar', '>', price_floor});

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(this_dir);
baseline_dir = fullfile(project_root, 'code', 'steadystate');
extension_dir = fullfile(project_root, 'extensions', 're_no_politics');

addpath(baseline_dir);
addpath(extension_dir);
addpath(this_dir);

demographic_path_full = build_demographic_path_local(project_root, demographic_source_mode);
T_full = numel(demographic_path_full.periods);
max_k = min(max(1, round(max_k)), T_full);
demographic_path = truncate_demographic_path_local(demographic_path_full, max_k);

default_seed = 0.34013605902777766;
seed_price_path = build_price_guess_local(default_seed, seed_price_csv_path, max_k);
seed_source = describe_guess_source_local(default_seed, seed_price_csv_path, seed_price_path);
basis = build_piecewise_linear_basis_local(max_k, basis_count);

run_tag = make_run_tag_local(run_tag, max_k, max_outer_iter, basis_count, finite_diff_step, trust_region_log_step);
output_dir = fullfile(this_dir, 'truth', 'reduced_path_jacobian', char(run_tag));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

params = default_transition_eval_params_local();
params.fixed_point_price_min = price_floor;
params.fixed_point_price_max = price_cap;

current_price_path = seed_price_path(:);
iteration_log = repmat(struct( ...
    'iteration', NaN, ...
    'current_max_abs_vote', NaN, ...
    'current_active_max_abs_vote', NaN, ...
    'current_vote_l2', NaN, ...
    'current_merit', NaN, ...
    'current_max_abs_gap', NaN, ...
    'current_residual_norm', NaN, ...
    'active_periods', [], ...
    'fd_rank', NaN, ...
    'fd_cond_proxy', NaN, ...
    'raw_step_max_abs_log', NaN, ...
    'trust_region_binding', false, ...
    'accepted', false, ...
    'accepted_direction', 0, ...
    'accepted_scale', 0, ...
    'accepted_max_abs_vote', NaN, ...
    'accepted_active_max_abs_vote', NaN, ...
    'accepted_vote_l2', NaN, ...
    'accepted_merit', NaN, ...
    'accepted_max_abs_gap', NaN, ...
    'accepted_residual_norm', NaN, ...
    'candidate_count', NaN), max_outer_iter, 1);

best_eval = struct();
best_eval.metrics = struct();
best_eval.price_path = current_price_path;
best_eval.vote_path = NaN(max_k, 1);
best_eval.active_periods = [];
improved_any = false;

for iter = 1:max_outer_iter
    base_eval = evaluate_price_path_local(current_price_path, demographic_path, params, [], active_threshold_frac);
    [jacobian, jacobian_stats] = build_fd_jacobian_local( ...
        current_price_path, base_eval.active_periods, basis, finite_diff_step, demographic_path, params, ...
        active_threshold_frac, price_floor, price_cap);

    delta_coeff = solve_reduced_step_local(jacobian, base_eval.vote_path(base_eval.active_periods), ridge_lambda);
    raw_log_step = basis * delta_coeff;
    [raw_log_step, trust_region_binding, raw_step_max_abs_log] = enforce_trust_region_local(raw_log_step, trust_region_log_step);

    iteration_log(iter).iteration = iter;
    iteration_log(iter).current_max_abs_vote = base_eval.metrics.max_abs_vote;
    iteration_log(iter).current_active_max_abs_vote = base_eval.metrics.active_max_abs_vote;
    iteration_log(iter).current_vote_l2 = base_eval.metrics.vote_l2;
    iteration_log(iter).current_merit = base_eval.metrics.merit;
    iteration_log(iter).current_max_abs_gap = base_eval.metrics.max_abs_gap;
    iteration_log(iter).current_residual_norm = base_eval.metrics.residual_norm;
    iteration_log(iter).active_periods = base_eval.active_periods(:)';
    iteration_log(iter).fd_rank = jacobian_stats.rank;
    iteration_log(iter).fd_cond_proxy = jacobian_stats.cond_proxy;
    iteration_log(iter).raw_step_max_abs_log = raw_step_max_abs_log;
    iteration_log(iter).trust_region_binding = trust_region_binding;

    candidate_count = 0;
    accepted = false;
    chosen_eval = base_eval;
    chosen_direction = 0;
    chosen_scale = 0;

    direction_list = [1, -1];
    for direction_idx = 1:numel(direction_list)
        direction_sign = direction_list(direction_idx);
        for scale_idx = 1:numel(candidate_scales)
            scale = candidate_scales(scale_idx);
            candidate_count = candidate_count + 1;

            candidate_step = direction_sign .* scale .* raw_log_step;
            if max(abs(candidate_step)) < 1e-10
                continue;
            end

            candidate_price_path = clamp_price_path_local(current_price_path .* exp(candidate_step), price_floor, price_cap);
            if max(abs(log(candidate_price_path) - log(current_price_path))) < 1e-10
                continue;
            end

            candidate_eval = evaluate_price_path_local(candidate_price_path, demographic_path, params, base_eval.active_periods, active_threshold_frac);
            if is_better_candidate_local(candidate_eval.metrics, chosen_eval.metrics, base_eval.metrics)
                accepted = true;
                chosen_eval = candidate_eval;
                chosen_direction = direction_sign;
                chosen_scale = scale;
            end
        end
    end

    iteration_log(iter).candidate_count = candidate_count;
    iteration_log(iter).accepted = accepted;
    iteration_log(iter).accepted_direction = chosen_direction;
    iteration_log(iter).accepted_scale = chosen_scale;
    iteration_log(iter).accepted_max_abs_vote = chosen_eval.metrics.max_abs_vote;
    iteration_log(iter).accepted_active_max_abs_vote = chosen_eval.metrics.active_max_abs_vote;
    iteration_log(iter).accepted_vote_l2 = chosen_eval.metrics.vote_l2;
    iteration_log(iter).accepted_merit = chosen_eval.metrics.merit;
    iteration_log(iter).accepted_max_abs_gap = chosen_eval.metrics.max_abs_gap;
    iteration_log(iter).accepted_residual_norm = chosen_eval.metrics.residual_norm;

    best_eval = chosen_eval;
    if accepted
        improved_any = true;
        current_price_path = chosen_eval.price_path;
    else
        current_price_path = base_eval.price_path;
        break;
    end
end

completed = find(~isnan([iteration_log.iteration]), 1, 'last');
if isempty(completed)
    completed = 1;
    best_eval = evaluate_price_path_local(current_price_path, demographic_path, params, [], active_threshold_frac);
end

summary = table( ...
    (1:completed)', ...
    [iteration_log(1:completed).current_max_abs_vote]', ...
    [iteration_log(1:completed).current_active_max_abs_vote]', ...
    [iteration_log(1:completed).current_vote_l2]', ...
    [iteration_log(1:completed).current_merit]', ...
    [iteration_log(1:completed).current_max_abs_gap]', ...
    [iteration_log(1:completed).current_residual_norm]', ...
    [iteration_log(1:completed).accepted]', ...
    [iteration_log(1:completed).accepted_direction]', ...
    [iteration_log(1:completed).accepted_scale]', ...
    [iteration_log(1:completed).accepted_max_abs_vote]', ...
    [iteration_log(1:completed).accepted_active_max_abs_vote]', ...
    [iteration_log(1:completed).accepted_vote_l2]', ...
    [iteration_log(1:completed).accepted_merit]', ...
    [iteration_log(1:completed).accepted_max_abs_gap]', ...
    [iteration_log(1:completed).accepted_residual_norm]', ...
    [iteration_log(1:completed).fd_rank]', ...
    [iteration_log(1:completed).fd_cond_proxy]', ...
    [iteration_log(1:completed).raw_step_max_abs_log]', ...
    [iteration_log(1:completed).trust_region_binding]', ...
    [iteration_log(1:completed).candidate_count]', ...
    compose_active_periods_local(iteration_log(1:completed)), ...
    'VariableNames', { ...
        'iteration', 'current_max_abs_vote', 'current_active_max_abs_vote', 'current_vote_l2', ...
        'current_merit', 'current_max_abs_gap', 'current_residual_norm', 'accepted', ...
        'accepted_direction', 'accepted_scale', 'accepted_max_abs_vote', 'accepted_active_max_abs_vote', ...
        'accepted_vote_l2', 'accepted_merit', 'accepted_max_abs_gap', 'accepted_residual_norm', ...
        'fd_rank', 'fd_cond_proxy', 'raw_step_max_abs_log', 'trust_region_binding', ...
        'candidate_count', 'active_periods'});

results = struct();
results.run_tag = string(run_tag);
results.output_dir = string(output_dir);
results.seed_source = string(seed_source);
results.demographic_source_mode = string(demographic_source_mode);
results.max_k = max_k;
results.max_outer_iter = max_outer_iter;
results.basis_count = basis_count;
results.finite_diff_step = finite_diff_step;
results.ridge_lambda = ridge_lambda;
results.candidate_scales = candidate_scales(:);
results.trust_region_log_step = trust_region_log_step;
results.active_threshold_frac = active_threshold_frac;
results.price_floor = price_floor;
results.price_cap = price_cap;
results.iterations = completed;
results.improved_any = improved_any;
results.basis = basis;
results.seed_price_path = seed_price_path(:);
results.final_price_path = best_eval.price_path(:);
results.final_vote_path = best_eval.vote_path(:);
results.final_active_periods = best_eval.active_periods(:);
results.final_metrics = best_eval.metrics;
results.iteration_log = iteration_log(1:completed);
results.message = 'Reduced-path Jacobian branch completed using a finite-difference active-set update on a low-dimensional log-price basis.';

summary_path = fullfile(output_dir, sprintf('%s_summary.csv', run_tag));
results_path = fullfile(output_dir, sprintf('%s_results.mat', run_tag));
final_price_path_csv = fullfile(output_dir, sprintf('%s_final_price_path.csv', run_tag));
final_vote_path_csv = fullfile(output_dir, sprintf('%s_final_vote_path.csv', run_tag));
writetable(summary, summary_path);
writematrix(results.final_price_path(:), final_price_path_csv);
writematrix(results.final_vote_path(:), final_vote_path_csv);
save(results_path, 'summary', 'results', 'demographic_path', 'seed_price_path');

fprintf('=== Reduced-path Jacobian branch ===\n');
fprintf('Run tag: %s\n', run_tag);
fprintf('Output dir: %s\n', output_dir);
fprintf('Seed source: %s\n', seed_source);
fprintf('Completed iterations: %d\n', completed);
fprintf('Improved any: %d\n', improved_any);
fprintf('Final max |vote|: %.8f\n', best_eval.metrics.max_abs_vote);
fprintf('Final max gap: %.8f\n', best_eval.metrics.max_abs_gap);
end

function eval_result = evaluate_price_path_local(price_path, demographic_path, params, active_periods, active_threshold_frac)
price_path = price_path(:);
solve_results = solve_transition_re_no_politics(price_path, demographic_path, params);
current_pass = solve_results.current_path_pass;
vote_path = current_pass.sim.political.equal_weight_vote_path(:);
if nargin < 4 || isempty(active_periods)
    active_periods = build_active_periods_local(vote_path, active_threshold_frac);
end
metrics = summarize_metrics_local(current_pass, vote_path, active_periods);

eval_result = struct();
eval_result.price_path = price_path;
eval_result.vote_path = vote_path;
eval_result.active_periods = active_periods(:);
eval_result.metrics = metrics;
end

function [jacobian, stats] = build_fd_jacobian_local(current_price_path, active_periods, basis, finite_diff_step, demographic_path, params, active_threshold_frac, price_floor, price_cap)
current_price_path = current_price_path(:);
active_periods = active_periods(:);
num_basis = size(basis, 2);
jacobian = NaN(numel(active_periods), num_basis);

base_eval = evaluate_price_path_local(current_price_path, demographic_path, params, active_periods, active_threshold_frac);
base_active_vote = base_eval.vote_path(active_periods);

for j = 1:num_basis
    perturb_log_step = finite_diff_step .* basis(:, j);
    perturbed_path = clamp_price_path_local(current_price_path .* exp(perturb_log_step), price_floor, price_cap);
    perturbed_eval = evaluate_price_path_local(perturbed_path, demographic_path, params, active_periods, active_threshold_frac);
    jacobian(:, j) = (perturbed_eval.vote_path(active_periods) - base_active_vote) ./ finite_diff_step;
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

function delta_coeff = solve_reduced_step_local(jacobian, residual_vector, ridge_lambda)
residual_vector = residual_vector(:);
normal_matrix = jacobian' * jacobian + ridge_lambda .* eye(size(jacobian, 2));
rhs = -(jacobian' * residual_vector);
delta_coeff = normal_matrix \ rhs;
if any(~isfinite(delta_coeff))
    delta_coeff = zeros(size(rhs));
end
end

function [log_step, trust_region_binding, raw_step_max_abs_log] = enforce_trust_region_local(log_step, trust_region_log_step)
log_step = log_step(:);
raw_step_max_abs_log = max(abs(log_step));
trust_region_binding = false;
if raw_step_max_abs_log > trust_region_log_step
    log_step = log_step .* (trust_region_log_step ./ raw_step_max_abs_log);
    trust_region_binding = true;
end
end

function tf = is_better_candidate_local(candidate_metrics, incumbent_metrics, baseline_metrics)
vote_guard = max(1e-4, 0.10 .* baseline_metrics.max_abs_vote);
gap_guard = max(5e-4, 0.10 .* baseline_metrics.max_abs_gap);

tf = candidate_metrics.merit < (incumbent_metrics.merit - 1e-4) && ...
    candidate_metrics.max_abs_vote <= baseline_metrics.max_abs_vote + vote_guard && ...
    candidate_metrics.max_abs_gap <= baseline_metrics.max_abs_gap + gap_guard;
end

function metrics = summarize_metrics_local(current_pass, vote_path, active_periods)
active_vote = vote_path(active_periods);
metrics = struct();
metrics.max_abs_vote = max(abs(vote_path));
metrics.active_max_abs_vote = max(abs(active_vote));
metrics.vote_l2 = norm(vote_path, 2);
metrics.active_vote_l2 = norm(active_vote, 2);
metrics.max_abs_gap = current_pass.max_abs_gap;
metrics.residual_norm = current_pass.residual_norm;
metrics.merit = metrics.active_max_abs_vote + 0.25 .* metrics.active_vote_l2 + ...
    0.05 .* metrics.max_abs_gap + 0.01 .* metrics.residual_norm;
end

function active_periods = build_active_periods_local(vote_path, active_threshold_frac)
vote_path = vote_path(:);
T = numel(vote_path);
sign_path = sign(vote_path);
if all(sign_path == 0)
    active_periods = (1:min(T, 3))';
    return;
end

for t = 1:T
    if sign_path(t) == 0
        if t == 1
            next_nonzero = find(sign_path ~= 0, 1, 'first');
            if isempty(next_nonzero)
                sign_path(t) = 1;
            else
                sign_path(t) = sign_path(next_nonzero);
            end
        else
            sign_path(t) = sign_path(t - 1);
        end
    end
end

segment_breaks = [1; find(diff(sign_path) ~= 0) + 1; T + 1];
segment_peaks = [];
for s = 1:(numel(segment_breaks) - 1)
    left_idx = segment_breaks(s);
    right_idx = segment_breaks(s + 1) - 1;
    segment_idx = (left_idx:right_idx)';
    [~, rel_idx] = max(abs(vote_path(segment_idx)));
    segment_peaks(end + 1, 1) = segment_idx(rel_idx); %#ok<AGROW>
end

threshold = active_threshold_frac .* max(abs(vote_path));
threshold_idx = find(abs(vote_path) >= threshold);
active_periods = unique([segment_peaks; threshold_idx(:)]);
active_periods = active_periods(:);
end

function basis = build_piecewise_linear_basis_local(T, basis_count)
grid = (1:T)';
knot_locations = linspace(1, T, basis_count);
basis = zeros(T, basis_count);

for j = 1:basis_count
    if j == 1
        left = knot_locations(j);
        right = knot_locations(j + 1);
        basis(:, j) = max(0, (right - grid) ./ max(right - left, eps));
    elseif j == basis_count
        left = knot_locations(j - 1);
        right = knot_locations(j);
        basis(:, j) = max(0, (grid - left) ./ max(right - left, eps));
    else
        left = knot_locations(j - 1);
        center = knot_locations(j);
        right = knot_locations(j + 1);
        left_weight = max(0, (grid - left) ./ max(center - left, eps));
        right_weight = max(0, (right - grid) ./ max(right - center, eps));
        basis(:, j) = min(left_weight, right_weight);
    end
end
end

function price_path = clamp_price_path_local(price_path, price_floor, price_cap)
price_path = min(max(price_path(:), price_floor), price_cap);
end

function composed = compose_active_periods_local(iteration_log)
composed = strings(numel(iteration_log), 1);
for i = 1:numel(iteration_log)
    active_periods = iteration_log(i).active_periods(:)';
    if isempty(active_periods)
        composed(i) = "";
    else
        composed(i) = strjoin(string(active_periods), ",");
    end
end
end

function price_path_guess = build_price_guess_local(default_seed, seed_price_csv_path, max_k)
if ~isempty(seed_price_csv_path)
    price_path_guess = readmatrix(seed_price_csv_path);
else
    price_path_guess = default_seed;
end

price_path_guess = price_path_guess(:);
if isempty(price_path_guess)
    error('Seed price path is empty.');
end
if any(~isfinite(price_path_guess)) || any(price_path_guess <= 0)
    error('Seed price path must contain finite positive values only.');
end
if isscalar(price_path_guess)
    price_path_guess = price_path_guess .* ones(max_k, 1);
elseif numel(price_path_guess) < max_k
    price_path_guess = [price_path_guess; price_path_guess(end) .* ones(max_k - numel(price_path_guess), 1)];
elseif numel(price_path_guess) > max_k
    price_path_guess = price_path_guess(1:max_k);
end
end

function guess_source = describe_guess_source_local(default_seed, seed_price_csv_path, price_path_guess)
if ~isempty(seed_price_csv_path)
    [~, guess_name, guess_ext] = fileparts(seed_price_csv_path);
    guess_source = sprintf('path_seed_%s%s_len%d', guess_name, guess_ext, numel(price_path_guess));
elseif isscalar(default_seed)
    guess_source = sprintf('flat_original_ss_root_%0.12f', default_seed);
else
    guess_source = sprintf('inline_path_seed_len%d', numel(price_path_guess));
end
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

function params = default_transition_eval_params_local()
params = struct();
params.max_iter = 1;
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
params.save_current_path_pass = true;
params.save_political_details = false;
params.save_period_details = true;
params.fixed_point_price_min = 0.05;
params.fixed_point_price_max = 5.00;
params.steady_state_reference_mode = 'original_5yr_political';
params.coalition_params = struct( ...
    'alpha_owner', 0.0, ...
    'alpha_old_owner', 0.0, ...
    'alpha_leverage', 0.0, ...
    'alpha_bighouse', 0.0);
end

function run_tag = make_run_tag_local(run_tag, max_k, max_outer_iter, basis_count, finite_diff_step, trust_region_log_step)
if ~isempty(run_tag)
    run_tag = regexprep(lower(string(run_tag)), '[^a-z0-9_]+', '_');
    return;
end

fd_piece = strrep(sprintf('fd%.0e', finite_diff_step), '+', '');
tr_piece = strrep(sprintf('tr%.0e', trust_region_log_step), '+', '');
run_tag = sprintf('reduced_k%d_i%d_b%d_%s_%s', max_k, max_outer_iter, basis_count, fd_piece, tr_piece);
run_tag = regexprep(lower(string(run_tag)), '[^a-z0-9_]+', '_');
end
