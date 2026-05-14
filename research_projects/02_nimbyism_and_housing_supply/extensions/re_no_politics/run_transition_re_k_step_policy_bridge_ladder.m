function summary = run_transition_re_k_step_policy_bridge_ladder(max_k, ladder_variant)
% Extend the k-step ladder using the simplified within-path policy bridge
% that replaces the full backward solve with steady-state-by-price policies.

if nargin < 1 || isempty(max_k)
    max_k = 5;
end
if nargin < 2 || isempty(ladder_variant)
    ladder_variant = 'steady_state_by_period_price';
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(baseline_dir);
addpath(this_dir);

demographic_path_full = build_demographic_path_from_age_state_csv(project_root);
T_full = numel(demographic_path_full.periods);
max_k = min(max(1, round(max_k)), T_full);

anchor_price_path = 2.0 .* ones(T_full, 1);
anchor_source = "flat_2.0";
previous_results_path = fullfile(this_dir, 'transition_re_no_politics_results.mat');
if isfile(previous_results_path)
    loaded = load(previous_results_path, 'results');
    if isfield(loaded, 'results') && isfield(loaded.results, 'final_price_path') && ...
            numel(loaded.results.final_price_path) == T_full
        anchor_price_path = loaded.results.final_price_path(:);
        anchor_source = "transition_re_no_politics_results.final_price_path";
    end
end

summary_rows = repmat(struct( ...
    'k', NaN, ...
    'status', "", ...
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
    'terminal_reference_price_used', NaN, ...
    'policy_reference_price_first_used', NaN, ...
    'policy_reference_price_last_used', NaN, ...
    'warm_start_source', "", ...
    'elapsed_seconds', NaN), max_k, 1);
all_results = cell(max_k, 1);

current_guess = [];
fprintf('=== NIMBY RE k-step policy-bridge ladder ===\n');
fprintf('Anchor source: %s\n', anchor_source);
fprintf('Bridge variant: %s\n', ladder_variant);

for k = 1:max_k
    demographic_path_k = truncate_demographic_path(demographic_path_full, k);
    current_guess = extend_guess(current_guess, anchor_price_path, k);
    warm_start_source = describe_warm_start(k, anchor_source);

    params = default_policy_bridge_params(ladder_variant);
    fprintf('\nRunning k = %d with warm start %s ...\n', k, warm_start_source);

    tic;
    try
        results = solve_transition_re_no_politics(current_guess, demographic_path_k, params);
        elapsed_seconds = toc;
        all_results{k} = results;
        current_guess = results.final_price_path(:);

        iter_idx = results.iterations;
        policy_ref_path = results.policy_reference_price_path_used(:);
        summary_rows(k) = struct( ...
            'k', k, ...
            'status', "ok", ...
            'iterations_completed', iter_idx, ...
            'converged', results.converged, ...
            'residual_norm', results.iteration_log(iter_idx).residual_norm, ...
            'max_abs_gap', results.update_diagnostics.max_abs_gap, ...
            'max_abs_update', results.iteration_log(iter_idx).max_abs_update, ...
            'accepted_update', string(results.iteration_log(iter_idx).accepted_update), ...
            'worst_gap_period', results.iteration_log(iter_idx).worst_gap_period, ...
            'worst_excess_demand_period', results.iteration_log(iter_idx).worst_excess_demand_period, ...
            'worst_excess_demand', results.iteration_log(iter_idx).worst_excess_demand, ...
            'price_min', min(results.final_price_path), ...
            'price_max', max(results.final_price_path), ...
            'path_span', max(results.final_price_path) - min(results.final_price_path), ...
            'terminal_reference_price_used', results.terminal_reference_price_used, ...
            'policy_reference_price_first_used', policy_ref_path(1), ...
            'policy_reference_price_last_used', policy_ref_path(end), ...
            'warm_start_source', warm_start_source, ...
            'elapsed_seconds', elapsed_seconds);

        fprintf('  k=%d done: residual=%.6f, gap=%.6f, update=%.6f, range=[%.4f, %.4f]\n', ...
            k, summary_rows(k).residual_norm, summary_rows(k).max_abs_gap, summary_rows(k).max_abs_update, ...
            summary_rows(k).price_min, summary_rows(k).price_max);

        if is_unstable_k_step(summary_rows(k), params)
            fprintf('  stopping after k=%d because the policy-bridge run looks unstable.\n', k);
            summary_rows = summary_rows(1:k);
            all_results = all_results(1:k);
            break;
        end
    catch ME
        elapsed_seconds = toc;
        summary_rows(k) = struct( ...
            'k', k, ...
            'status', "error", ...
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
            'terminal_reference_price_used', NaN, ...
            'policy_reference_price_first_used', NaN, ...
            'policy_reference_price_last_used', NaN, ...
            'warm_start_source', warm_start_source, ...
            'elapsed_seconds', elapsed_seconds);
        summary_rows = summary_rows(1:k);
        all_results = all_results(1:k);
        save(fullfile(this_dir, 'transition_re_k_step_policy_bridge_results.mat'), ...
            'summary_rows', 'all_results', 'anchor_source', 'anchor_price_path', 'ME');
        rethrow(ME);
    end
end

summary = struct2table(summary_rows);
writetable(summary, fullfile(this_dir, sprintf('transition_re_k_step_policy_bridge_%s_summary.csv', ladder_variant)));
save(fullfile(this_dir, sprintf('transition_re_k_step_policy_bridge_%s_results.mat', ladder_variant)), ...
    'summary', 'all_results', 'anchor_source', 'anchor_price_path', 'ladder_variant');

if strcmpi(ladder_variant, 'steady_state_by_period_price')
    writetable(summary, fullfile(this_dir, 'transition_re_k_step_policy_bridge_summary.csv'));
    save(fullfile(this_dir, 'transition_re_k_step_policy_bridge_results.mat'), ...
        'summary', 'all_results', 'anchor_source', 'anchor_price_path', 'ladder_variant');
end
end

function params = default_policy_bridge_params(ladder_variant)
params = struct();
params.max_iter = 25;
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

switch lower(string(ladder_variant))
    case "steady_state_by_period_price"
        params.transition_policy_mode = 'steady_state_by_period_price';
        params.policy_reference_mode = 'path_current_prices';
        params.policy_reference_price = NaN;
    case "steady_state_fixed_price_2_0"
        params.transition_policy_mode = 'steady_state_fixed_price';
        params.policy_reference_mode = 'fixed_price';
        params.policy_reference_price = 2.0;
    otherwise
        error('Unsupported ladder_variant: %s', ladder_variant);
end
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
demographic_path_k.description = sprintf('%s Truncated to first %d periods for the policy-bridge ladder.', ...
    demographic_path_full.description, k);
end

function guess = extend_guess(current_guess, anchor_price_path, k)
if isempty(current_guess)
    guess = anchor_price_path(1:k);
    return;
end
guess = current_guess(:);
if numel(guess) >= k
    guess = guess(1:k);
else
    guess = [guess; anchor_price_path(numel(guess) + 1:k)];
end
end

function label = describe_warm_start(k, anchor_source)
if k == 1
    label = "anchor_prefix";
else
    label = sprintf('k_%d_final_path_plus_%s_tail', k - 1, anchor_source);
end
end

function tf = is_unstable_k_step(row, params)
tol = 1e-6;
near_lower = row.price_min <= params.fixed_point_price_min + tol;
near_upper = row.price_max >= params.fixed_point_price_max - tol;
tf = (near_lower || near_upper) && row.max_abs_gap > 1.0;
end
