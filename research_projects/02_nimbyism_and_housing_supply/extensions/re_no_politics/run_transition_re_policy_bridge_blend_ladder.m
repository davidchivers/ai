function [summary, frontier] = run_transition_re_policy_bridge_blend_ladder(max_k, blend_grid, output_tag)
% Map how far each policy-reference blend weight can be extended in horizon
% length before the bounded RE path stops looking numerically stable.

if nargin < 1 || isempty(max_k)
    max_k = [];
end
if nargin < 2 || isempty(blend_grid)
    blend_grid = [0.00, 0.01, 0.015, 0.02, 0.05, 1.00];
end
if nargin < 3 || isempty(output_tag)
    output_tag = 'blend_ladder';
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(baseline_dir);
addpath(this_dir);

demographic_path_full = build_demographic_path_from_age_state_csv(project_root);
T_full = numel(demographic_path_full.periods);
if isempty(max_k)
    max_k = T_full;
end
max_k = min(max(1, round(max_k)), T_full);

[anchor_price_path, anchor_source] = load_anchor_path(this_dir, T_full);
cases = build_blend_cases(blend_grid);

summary_rows = repmat(struct( ...
    'case_name', "", ...
    'policy_reference_blend_weight', NaN, ...
    'k', NaN, ...
    'status', "", ...
    'iterations_completed', NaN, ...
    'converged', false, ...
    'looks_stable', false, ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'path_span', NaN, ...
    'policy_reference_price_first_used', NaN, ...
    'policy_reference_price_last_used', NaN, ...
    'warm_start_source', "", ...
    'elapsed_seconds', NaN), numel(cases) * max_k, 1);
summary_idx = 0;

frontier_rows = repmat(struct( ...
    'case_name', "", ...
    'policy_reference_blend_weight', NaN, ...
    'max_stable_k', NaN, ...
    'first_unstable_k', NaN, ...
    'frontier_status', "", ...
    'last_stable_max_abs_gap', NaN, ...
    'last_stable_price_min', NaN, ...
    'last_stable_price_max', NaN), numel(cases), 1);

all_results = cell(numel(cases), max_k);

fprintf('=== NIMBY RE policy-bridge blend ladder ===\n');
fprintf('Anchor source: %s\n', anchor_source);
fprintf('Blend ladder: %s\n', mat2str(blend_grid));
fprintf('Max horizon: k = %d\n', max_k);

for i = 1:numel(cases)
    case_spec = cases(i);
    current_guess = [];
    stable_k = 0;
    first_unstable_k = NaN;
    last_stable_row = [];
    frontier_status = "stable_through_max_k";

    fprintf('\nAlpha %.3f (%s)\n', case_spec.policy_reference_blend_weight, case_spec.case_name);

    for k = 1:max_k
        demographic_path_k = truncate_demographic_path(demographic_path_full, k);
        current_guess = extend_guess(current_guess, anchor_price_path, k);
        warm_start_source = describe_warm_start(k, case_spec.policy_reference_blend_weight, anchor_source);

        params = default_blend_ladder_params(case_spec.policy_reference_blend_weight);

        fprintf('  running k = %d with warm start %s ...\n', k, warm_start_source);
        run_tic = tic;

        try
            results = solve_transition_re_no_politics(current_guess, demographic_path_k, params);
            elapsed_seconds = toc(run_tic);
            all_results{i, k} = results;
            current_guess = results.final_price_path(:);

            iter_idx = results.iterations;
            policy_ref_path = results.policy_reference_price_path_used(:);

            summary_idx = summary_idx + 1;
            summary_rows(summary_idx) = struct( ...
                'case_name', case_spec.case_name, ...
                'policy_reference_blend_weight', case_spec.policy_reference_blend_weight, ...
                'k', k, ...
                'status', "ok", ...
                'iterations_completed', iter_idx, ...
                'converged', results.converged, ...
                'looks_stable', looks_stable(results, params), ...
                'residual_norm', results.iteration_log(iter_idx).residual_norm, ...
                'max_abs_gap', results.update_diagnostics.max_abs_gap, ...
                'max_abs_update', results.iteration_log(iter_idx).max_abs_update, ...
                'price_min', min(results.final_price_path), ...
                'price_max', max(results.final_price_path), ...
                'path_span', max(results.final_price_path) - min(results.final_price_path), ...
                'policy_reference_price_first_used', policy_ref_path(1), ...
                'policy_reference_price_last_used', policy_ref_path(end), ...
                'warm_start_source', warm_start_source, ...
                'elapsed_seconds', elapsed_seconds);

            fprintf('    k=%d gap=%.6f residual=%.6f range=[%.4f, %.4f] stable=%d\n', ...
                k, summary_rows(summary_idx).max_abs_gap, summary_rows(summary_idx).residual_norm, ...
                summary_rows(summary_idx).price_min, summary_rows(summary_idx).price_max, ...
                summary_rows(summary_idx).looks_stable);

            if summary_rows(summary_idx).looks_stable
                stable_k = k;
                last_stable_row = summary_rows(summary_idx);
                frontier_rows(i) = make_frontier_row(case_spec, stable_k, NaN, "running", last_stable_row);
                save_partial_outputs(this_dir, output_tag, summary_rows(1:summary_idx), frontier_rows, all_results, cases, anchor_price_path, anchor_source);
            else
                first_unstable_k = k;
                frontier_status = "stopped_at_first_unstable_k";
                frontier_rows(i) = make_frontier_row(case_spec, stable_k, first_unstable_k, frontier_status, last_stable_row);
                save_partial_outputs(this_dir, output_tag, summary_rows(1:summary_idx), frontier_rows, all_results, cases, anchor_price_path, anchor_source);
                break;
            end
        catch ME
            elapsed_seconds = toc(run_tic);
            summary_idx = summary_idx + 1;
            summary_rows(summary_idx) = struct( ...
                'case_name', case_spec.case_name, ...
                'policy_reference_blend_weight', case_spec.policy_reference_blend_weight, ...
                'k', k, ...
                'status', "error", ...
                'iterations_completed', NaN, ...
                'converged', false, ...
                'looks_stable', false, ...
                'residual_norm', NaN, ...
                'max_abs_gap', NaN, ...
                'max_abs_update', NaN, ...
                'price_min', NaN, ...
                'price_max', NaN, ...
                'path_span', NaN, ...
                'policy_reference_price_first_used', NaN, ...
                'policy_reference_price_last_used', NaN, ...
                'warm_start_source', warm_start_source, ...
                'elapsed_seconds', elapsed_seconds);
            first_unstable_k = k;
            frontier_status = "error";
            frontier_rows(i) = make_frontier_row(case_spec, stable_k, first_unstable_k, frontier_status, last_stable_row);
            save_partial_outputs(this_dir, output_tag, summary_rows(1:summary_idx), frontier_rows, all_results, cases, anchor_price_path, anchor_source, ME);
            rethrow(ME);
        end
    end

    frontier_rows(i) = make_frontier_row(case_spec, stable_k, first_unstable_k, frontier_status, last_stable_row);
    save_partial_outputs(this_dir, output_tag, summary_rows(1:summary_idx), frontier_rows, all_results, cases, anchor_price_path, anchor_source);
end

summary = struct2table(summary_rows(1:summary_idx));
frontier = trim_frontier_table(frontier_rows);

writetable(summary, fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_summary.csv', output_tag)));
writetable(frontier, fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_frontier.csv', output_tag)));
save(fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_results.mat', output_tag)), ...
    'summary', 'frontier', 'all_results', 'cases', 'anchor_price_path', 'anchor_source');
end

function params = default_blend_ladder_params(alpha)
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
params.transition_policy_mode = 'steady_state_by_period_price';
params.policy_reference_mode = 'blended_current_and_fixed_price';
params.policy_reference_price = 2.0;
params.policy_reference_blend_weight = alpha;
params.policy_reference_price_floor = NaN;
params.policy_reference_price_cap = NaN;
end

function cases = build_blend_cases(blend_grid)
cases = repmat(struct( ...
    'case_name', "", ...
    'policy_reference_blend_weight', NaN), numel(blend_grid), 1);

for i = 1:numel(blend_grid)
    alpha = blend_grid(i);
    alpha_label = format_blend_label(alpha);
    cases(i) = struct( ...
        'case_name', string(sprintf('steady_state_blend_alpha_%s', alpha_label)), ...
        'policy_reference_blend_weight', alpha);
end
end

function label = format_blend_label(alpha)
label = regexprep(sprintf('%.3f', alpha), '0+$', '');
label = regexprep(label, '\.$', '');
label = strrep(label, '.', '_');
end

function [anchor_price_path, anchor_source] = load_anchor_path(this_dir, T_full)
fixed_price_results_path = fullfile(this_dir, 'transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.mat');

if isfile(fixed_price_results_path)
    loaded = load(fixed_price_results_path, 'all_results');
    if isfield(loaded, 'all_results') && ~isempty(loaded.all_results) && ...
            numel(loaded.all_results) >= T_full && ~isempty(loaded.all_results{T_full})
        anchor_price_path = loaded.all_results{T_full}.final_price_path(:);
        anchor_source = "transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.final_price_path";
        return;
    end
end

anchor_price_path = 2.0 .* ones(T_full, 1);
anchor_source = "flat_2.0";
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
demographic_path_k.description = sprintf('%s Truncated to first %d periods for the blend ladder.', ...
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

function label = describe_warm_start(k, alpha, anchor_source)
if k == 1
    label = sprintf('anchor_prefix_alpha_%.3f_%s', alpha, anchor_source);
else
    label = sprintf('k_%d_final_path_alpha_%.3f', k - 1, alpha);
end
end

function tf = looks_stable(results, params)
tol = 1e-6;
tf = results.update_diagnostics.max_abs_gap < 0.05 && ...
    min(results.final_price_path) > params.fixed_point_price_min + tol && ...
    max(results.final_price_path) < params.fixed_point_price_max - tol;
end

function row = make_frontier_row(case_spec, stable_k, first_unstable_k, frontier_status, last_stable_row)
row = struct( ...
    'case_name', case_spec.case_name, ...
    'policy_reference_blend_weight', case_spec.policy_reference_blend_weight, ...
    'max_stable_k', stable_k, ...
    'first_unstable_k', first_unstable_k, ...
    'frontier_status', frontier_status, ...
    'last_stable_max_abs_gap', NaN, ...
    'last_stable_price_min', NaN, ...
    'last_stable_price_max', NaN);

if ~isempty(last_stable_row)
    row.last_stable_max_abs_gap = last_stable_row.max_abs_gap;
    row.last_stable_price_min = last_stable_row.price_min;
    row.last_stable_price_max = last_stable_row.price_max;
end
end

function save_partial_outputs(this_dir, output_tag, summary_rows, frontier_rows, all_results, cases, anchor_price_path, anchor_source, varargin)
summary_table = struct2table(summary_rows);
frontier_table = trim_frontier_table(frontier_rows);

writetable(summary_table, fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_summary.csv', output_tag)));
writetable(frontier_table, fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_frontier.csv', output_tag)));

save_args = {'summary_table', 'frontier_table', 'all_results', 'cases', 'anchor_price_path', 'anchor_source'};
if nargin > 8 && ~isempty(varargin)
    save_args = [save_args, {'varargin'}];
end
save(fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_results.mat', output_tag)), save_args{:});
end

function frontier_table = trim_frontier_table(frontier_rows)
if isempty(frontier_rows)
    frontier_table = struct2table(frontier_rows);
    return;
end

has_case_name = arrayfun(@(row) strlength(string(row.case_name)) > 0, frontier_rows);
frontier_table = struct2table(frontier_rows(has_case_name));
end
