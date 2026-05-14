function system = export_original_5yr_dynare_reduced_system(max_k, basis_count, demographic_source_mode, ...
    seed_price_csv_path, output_dir, finite_diff_step, ridge_lambda, active_threshold_frac, ...
    price_floor, price_cap)
% Export a real reduced-path system for the Dynare branch.
%
% The exported object is not a placeholder scaffold. It evaluates the
% incumbent full-horizon price path, builds a low-dimensional basis for the
% log price path, estimates the finite-difference Jacobian of the active
% political residuals with respect to those basis coefficients, and writes
% the regularized normal-equation system that Dynare will solve for the
% reduced coefficient update.

if nargin < 1 || isempty(max_k)
    max_k = 14;
end
if nargin < 2 || isempty(basis_count)
    basis_count = 4;
end
if nargin < 3 || isempty(demographic_source_mode)
    demographic_source_mode = 'historical_1950';
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_dir = fileparts(this_dir);
baseline_dir = fullfile(project_dir, 'code', 'steadystate');
extension_dir = fullfile(project_dir, 'extensions', 're_no_politics');

addpath(baseline_dir);
addpath(extension_dir);
addpath(project_dir);

if nargin < 4 || isempty(seed_price_csv_path)
    seed_price_csv_path = fullfile(project_dir, ...
        'original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv');
end
if nargin < 5 || isempty(output_dir)
    output_dir = fullfile(this_dir, 'generated');
end
if nargin < 6 || isempty(finite_diff_step)
    finite_diff_step = 2.5e-4;
end
if nargin < 7 || isempty(ridge_lambda)
    ridge_lambda = 1e-3;
end
if nargin < 8 || isempty(active_threshold_frac)
    active_threshold_frac = 0.65;
end
if nargin < 9 || isempty(price_floor)
    price_floor = 0.05;
end
if nargin < 10 || isempty(price_cap)
    price_cap = 5.0;
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

demographic_path = build_demographic_path_local(project_dir, demographic_source_mode, max_k);
seed_price_path = build_price_guess_local(seed_price_csv_path, max_k);
basis = build_piecewise_linear_basis_local(max_k, basis_count);

params = default_transition_eval_params_local();
params.fixed_point_price_min = price_floor;
params.fixed_point_price_max = price_cap;

base_eval = evaluate_price_path_local(seed_price_path, demographic_path, params, [], active_threshold_frac);
[full_jacobian, active_jacobian] = build_fd_jacobian_full_local( ...
    seed_price_path, base_eval.active_periods, basis, finite_diff_step, demographic_path, params, ...
    active_threshold_frac, price_floor, price_cap);

active_residual = base_eval.vote_path(base_eval.active_periods);
normal_matrix = active_jacobian' * active_jacobian;
regularized_normal_matrix = normal_matrix + ridge_lambda .* eye(size(normal_matrix, 1));
normal_rhs = active_jacobian' * active_residual;

system = struct();
system.generated_at = char(datetime('now', 'TimeZone', 'Europe/London', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));
system.max_k = max_k;
system.basis_count = basis_count;
system.demographic_source_mode = demographic_source_mode;
system.seed_price_csv_path = seed_price_csv_path;
system.seed_price_path = seed_price_path(:);
system.log_seed_price_path = log(seed_price_path(:));
system.vote_path = base_eval.vote_path(:);
system.active_periods = base_eval.active_periods(:);
system.active_vote_residual = active_residual(:);
system.basis = basis;
system.full_jacobian = full_jacobian;
system.active_jacobian = active_jacobian;
system.normal_matrix = normal_matrix;
system.regularized_normal_matrix = regularized_normal_matrix;
system.normal_rhs = normal_rhs(:);
system.finite_diff_step = finite_diff_step;
system.ridge_lambda = ridge_lambda;
system.active_threshold_frac = active_threshold_frac;
system.price_floor = price_floor;
system.price_cap = price_cap;
system.periods = demographic_path.periods(:);
system.years = demographic_path.years(:);
system.cohort_scale = demographic_path.cohort_scale(:);
system.cohort_scale_by_age = demographic_path.cohort_scale_by_age;
system.age_bins_model = demographic_path.age_bins_model(:);
system.metrics = base_eval.metrics;
system.demographic_path = demographic_path;
system.params = params;

save(fullfile(output_dir, 'nimby_dynare_reduced_system_input.mat'), 'system');
writematrix(system.seed_price_path, fullfile(output_dir, 'nimby_dynare_seed_price_path.csv'));
writematrix(system.vote_path, fullfile(output_dir, 'nimby_dynare_vote_path.csv'));
writematrix(system.active_periods, fullfile(output_dir, 'nimby_dynare_active_periods.csv'));
writematrix(system.basis, fullfile(output_dir, 'nimby_dynare_basis.csv'));
writematrix(system.active_jacobian, fullfile(output_dir, 'nimby_dynare_active_jacobian.csv'));
writematrix(system.regularized_normal_matrix, fullfile(output_dir, 'nimby_dynare_regularized_normal_matrix.csv'));
writematrix(system.normal_rhs, fullfile(output_dir, 'nimby_dynare_normal_rhs.csv'));

manifest = struct();
manifest.generated_at = system.generated_at;
manifest.max_k = system.max_k;
manifest.basis_count = system.basis_count;
manifest.demographic_source_mode = system.demographic_source_mode;
manifest.seed_price_csv_path = system.seed_price_csv_path;
manifest.active_periods = system.active_periods(:)';
manifest.active_threshold_frac = system.active_threshold_frac;
manifest.finite_diff_step = system.finite_diff_step;
manifest.ridge_lambda = system.ridge_lambda;
manifest.metrics = system.metrics;
write_text_local(fullfile(output_dir, 'nimby_dynare_reduced_system_manifest.json'), jsonencode(manifest, PrettyPrint=true));
end

function demographic_path = build_demographic_path_local(project_dir, demographic_source_mode, max_k)
switch lower(string(demographic_source_mode))
    case "historical_1950"
        demographic_path = build_original_5yr_demographic_path_from_historical_age_shares(project_root_local(project_dir));
    case {"historical_1950_two_group", "historical_1950_old_young_proxy"}
        demographic_path = build_original_5yr_demographic_two_group_proxy(project_root_local(project_dir));
    case "age_state_csv"
        demographic_path = build_original_5yr_demographic_path_from_age_state_csv(project_root_local(project_dir));
    otherwise
        error('Unsupported demographic_source_mode: %s', demographic_source_mode);
end

fields_to_truncate = {'periods', 'years', 'cohort_scale', 'population_by_age'};
for i = 1:numel(fields_to_truncate)
    field_name = fields_to_truncate{i};
    if isfield(demographic_path, field_name)
        demographic_path.(field_name) = demographic_path.(field_name)(1:max_k, :);
    end
end
if isfield(demographic_path, 'cohort_scale_by_age')
    demographic_path.cohort_scale_by_age = demographic_path.cohort_scale_by_age(1:max_k, :);
end
end

function root = project_root_local(project_dir)
root = fileparts(project_dir);
end

function price_path_guess = build_price_guess_local(seed_price_csv_path, max_k)
if ~isfile(seed_price_csv_path)
    error('Seed price path CSV not found: %s', seed_price_csv_path);
end

price_path_guess = readmatrix(seed_price_csv_path);
price_path_guess = price_path_guess(:);
price_path_guess = price_path_guess(isfinite(price_path_guess));
if isempty(price_path_guess)
    error('Seed price path CSV contained no finite values: %s', seed_price_csv_path);
end
if any(price_path_guess <= 0)
    error('Seed price path must contain positive values only.');
end
if numel(price_path_guess) < max_k
    price_path_guess = [price_path_guess; price_path_guess(end) .* ones(max_k - numel(price_path_guess), 1)];
elseif numel(price_path_guess) > max_k
    price_path_guess = price_path_guess(1:max_k);
end
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

function [full_jacobian, active_jacobian] = build_fd_jacobian_full_local(current_price_path, active_periods, basis, finite_diff_step, demographic_path, params, active_threshold_frac, price_floor, price_cap)
current_price_path = current_price_path(:);
num_basis = size(basis, 2);
full_jacobian = NaN(numel(current_price_path), num_basis);

base_eval = evaluate_price_path_local(current_price_path, demographic_path, params, active_periods, active_threshold_frac);
base_vote = base_eval.vote_path(:);

for j = 1:num_basis
    perturb_log_step = finite_diff_step .* basis(:, j);
    perturbed_path = clamp_price_path_local(current_price_path .* exp(perturb_log_step), price_floor, price_cap);
    perturbed_eval = evaluate_price_path_local(perturbed_path, demographic_path, params, active_periods, active_threshold_frac);
    full_jacobian(:, j) = (perturbed_eval.vote_path(:) - base_vote) ./ finite_diff_step;
end

active_jacobian = full_jacobian(active_periods, :);
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
if basis_count < 2
    error('basis_count must be at least 2.');
end

anchors = round(linspace(1, T, basis_count));
anchors = unique(max(1, min(T, anchors)));
if numel(anchors) < basis_count
    anchors = unique(round(linspace(1, T, basis_count + 1)));
    anchors = anchors(1:basis_count);
end

grid = (1:T)';
basis = zeros(T, numel(anchors));
for j = 1:numel(anchors)
    if j == 1
        left = anchors(j);
    else
        left = anchors(j - 1);
    end
    center = anchors(j);
    if j == numel(anchors)
        right = anchors(j);
    else
        right = anchors(j + 1);
    end

    for t = 1:T
        x = grid(t);
        if x < left || x > right
            continue;
        end
        if x <= center
            denom = max(center - left, 1);
            basis(t, j) = (x - left) / denom;
        else
            denom = max(right - center, 1);
            basis(t, j) = (right - x) / denom;
        end
        if x == center
            basis(t, j) = 1;
        end
    end
end
end

function price_path = clamp_price_path_local(price_path, price_floor, price_cap)
price_path = min(max(price_path(:), price_floor), price_cap);
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

function write_text_local(path_str, text_str)
fid = fopen(path_str, 'w');
if fid < 0
    error('Could not open file for writing: %s', path_str);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', text_str);
end
