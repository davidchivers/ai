function [summary, frontier] = run_transition_re_policy_bridge_alpha_frontier(max_k, alpha_grid, output_tag)
% Search for the largest stable blend weight alpha at each horizon length k.
% The search resumes from live checkpoints or from partial legacy result
% files written under the same output_tag.

if nargin < 1 || isempty(max_k)
    max_k = [];
end
if nargin < 2 || isempty(alpha_grid)
    alpha_grid = [0.00, 0.01, 0.015, 0.02, 0.03, 0.05, 0.10, 0.20, 0.50, 1.00];
end
if nargin < 3 || isempty(output_tag)
    output_tag = 'alpha_frontier';
end

alpha_grid = unique(sort(alpha_grid(:)'));

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
paths = build_output_paths(this_dir, output_tag);
state = initialize_or_resume_state(paths, max_k, alpha_grid, anchor_price_path, anchor_source);

fprintf('=== NIMBY RE alpha frontier ===\n');
fprintf('Anchor source: %s\n', state.anchor_source);
fprintf('Alpha grid: %s\n', mat2str(state.alpha_grid));
fprintf('Max horizon: k = %d\n', state.max_k);

if state.is_complete
    fprintf('Compatible completed results already exist at %s.\n', paths.results_path);
    summary = build_summary_table(state);
    frontier = build_frontier_table(state);
    return;
end

if state.summary_idx > 0
    fprintf('Resuming frontier search at k = %d, alpha index = %d.\n', ...
        state.next_k, state.current_alpha_idx);
end

while state.next_k <= state.max_k
    k = state.next_k;

    if state.current_alpha_idx < 1
        state = finalize_exhausted_k(state);
        write_checkpoint(paths, state);
        continue;
    end

    alpha_idx = state.current_alpha_idx;
    alpha = state.alpha_grid(alpha_idx);
    demographic_path_k = truncate_demographic_path(demographic_path_full, k);
    params = default_frontier_params(alpha);
    [guess, warm_start_source] = select_warm_start( ...
        k, alpha_idx, state.all_results, state.anchor_price_path, state.anchor_source, state.previous_frontier_idx);

    fprintf('\nSearching frontier at k = %d ...\n', k);
    fprintf('  testing alpha = %.3f with warm start %s ...\n', alpha, warm_start_source);

    run_tic = tic;
    try
        run_info = solve_frontier_case(guess, demographic_path_k, params, warm_start_source);
        results = run_info.results;
        state.all_results{k, alpha_idx} = results;
        state.summary_idx = state.summary_idx + 1;
        state.summary_rows(state.summary_idx) = build_summary_row( ...
            k, alpha, run_info.status, run_info.iterations_completed, ...
            results, params, run_info.warm_start_source, run_info.elapsed_seconds);
        is_stable = state.summary_rows(state.summary_idx).looks_stable;

        fprintf('    alpha=%.3f gap=%.6f residual=%.6f range=[%.4f, %.4f] stable=%d attempts=%d\n', ...
            alpha, state.summary_rows(state.summary_idx).max_abs_gap, ...
            state.summary_rows(state.summary_idx).residual_norm, ...
            state.summary_rows(state.summary_idx).price_min, ...
            state.summary_rows(state.summary_idx).price_max, is_stable, run_info.attempt_count);

        if is_stable
            state.current_k_state.max_stable_alpha = alpha;
            state.current_k_state.frontier_status = "found_stable_alpha";
            state.current_k_state.last_stable_row = state.summary_rows(state.summary_idx);
            state.frontier_rows(k) = make_frontier_row( ...
                k, ...
                state.current_k_state.max_stable_alpha, ...
                state.current_k_state.first_unstable_alpha, ...
                state.current_k_state.frontier_status, ...
                state.current_k_state.last_stable_row);
            state.previous_frontier_idx = alpha_idx;
            state.next_k = k + 1;
            state.current_alpha_idx = state.previous_frontier_idx;
            state.current_k_state = initialize_current_k_state();
        else
            if isnan(state.current_k_state.first_unstable_alpha)
                state.current_k_state.first_unstable_alpha = alpha;
            end
            state.current_k_state.frontier_status = "stepping_down";
            state.frontier_rows(k) = make_frontier_row( ...
                k, ...
                state.current_k_state.max_stable_alpha, ...
                state.current_k_state.first_unstable_alpha, ...
                state.current_k_state.frontier_status, ...
                state.current_k_state.last_stable_row);
            state.current_alpha_idx = alpha_idx - 1;
        end

        write_checkpoint(paths, state);
    catch ME
        elapsed_seconds = toc(run_tic);
        state.summary_idx = state.summary_idx + 1;
        state.summary_rows(state.summary_idx) = struct( ...
            'k', k, ...
            'policy_reference_blend_weight', alpha, ...
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
            'warm_start_source', string(warm_start_source), ...
            'elapsed_seconds', elapsed_seconds);
        state.current_k_state.frontier_status = "error";
        state.frontier_rows(k) = make_frontier_row( ...
            k, ...
            state.current_k_state.max_stable_alpha, ...
            alpha, ...
            state.current_k_state.frontier_status, ...
            state.current_k_state.last_stable_row);
        write_checkpoint(paths, state, ME.message);
        rethrow(ME);
    end
end

state.is_complete = true;
summary = build_summary_table(state);
frontier = build_frontier_table(state);

writetable(summary, paths.summary_path);
writetable(frontier, paths.frontier_path);
save(paths.results_path, ...
    'summary', 'frontier', 'state');

delete_if_exists(paths.live_summary_path);
delete_if_exists(paths.live_frontier_path);
delete_if_exists(paths.live_results_path);
end

function paths = build_output_paths(this_dir, output_tag)
paths = struct();
paths.summary_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_summary.csv', output_tag));
paths.frontier_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_frontier.csv', output_tag));
paths.results_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_results.mat', output_tag));
paths.live_summary_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_summary_live.csv', output_tag));
paths.live_frontier_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_frontier_live.csv', output_tag));
paths.live_results_path = fullfile(this_dir, sprintf('transition_re_policy_bridge_%s_results_live.mat', output_tag));
end

function state = initialize_or_resume_state(paths, max_k, alpha_grid, anchor_price_path, anchor_source)
alpha_label_map = arrayfun(@format_alpha_label, alpha_grid, 'UniformOutput', false);

state = initialize_state(max_k, alpha_grid, alpha_label_map, anchor_price_path, anchor_source);

if isfile(paths.live_results_path)
    loaded = load(paths.live_results_path, 'state');
    if isfield(loaded, 'state') && is_compatible_state(loaded.state, max_k, alpha_grid)
        state = loaded.state;
        return;
    end
end

if isfile(paths.results_path)
    loaded = load(paths.results_path);
    if isfield(loaded, 'state') && is_compatible_state(loaded.state, max_k, alpha_grid)
        state = loaded.state;
        return;
    end

    [legacy_ok, state_from_legacy] = try_resume_legacy_results(loaded, max_k, alpha_grid, alpha_label_map, anchor_price_path, anchor_source);
    if legacy_ok
        state = state_from_legacy;
    end
end
end

function state = initialize_state(max_k, alpha_grid, alpha_label_map, anchor_price_path, anchor_source)
max_cases = max_k * numel(alpha_grid);
state = struct();
state.max_k = max_k;
state.alpha_grid = alpha_grid;
state.alpha_label_map = alpha_label_map;
state.anchor_price_path = anchor_price_path(:);
state.anchor_source = string(anchor_source);
state.summary_rows = initialize_summary_rows(max_cases);
state.summary_idx = 0;
state.frontier_rows = initialize_frontier_rows(max_k);
state.all_results = cell(max_k, numel(alpha_grid));
state.previous_frontier_idx = numel(alpha_grid);
state.next_k = 1;
state.current_alpha_idx = state.previous_frontier_idx;
state.current_k_state = initialize_current_k_state();
state.is_complete = false;
end

function tf = is_compatible_state(state, max_k, alpha_grid)
tf = isfield(state, 'max_k') && isfield(state, 'alpha_grid') && ...
    isequaln(state.max_k, max_k) && isequaln(state.alpha_grid(:)', alpha_grid(:)');
end

function [ok, state] = try_resume_legacy_results(loaded, max_k, alpha_grid, alpha_label_map, anchor_price_path, anchor_source)
ok = false;
state = initialize_state(max_k, alpha_grid, alpha_label_map, anchor_price_path, anchor_source);

if ~isfield(loaded, 'all_results') || ~isfield(loaded, 'alpha_grid')
    return;
end
if ~isequaln(loaded.alpha_grid(:)', alpha_grid(:)')
    return;
end

summary_table = extract_table_field(loaded, {'summary_table', 'summary'});
frontier_table = extract_table_field(loaded, {'frontier_table', 'frontier'});
if isempty(summary_table) || isempty(frontier_table)
    return;
end

summary_struct = table2struct(summary_table);
frontier_struct = table2struct(frontier_table);

num_summary = min(numel(summary_struct), numel(state.summary_rows));
if num_summary > 0
    state.summary_rows(1:num_summary) = summary_struct(1:num_summary);
end
state.summary_idx = num_summary;

state.all_results = loaded.all_results;
if size(state.all_results, 1) < max_k || size(state.all_results, 2) ~= numel(alpha_grid)
    return;
end

for i = 1:numel(frontier_struct)
    k = frontier_struct(i).k;
    if ~isnan(k) && k >= 1 && k <= max_k
        state.frontier_rows(k) = frontier_struct(i);
    end
end

frontier_struct = frontier_struct(~isnan([frontier_struct.k]));
if isempty(frontier_struct)
    ok = true;
    return;
end

last_row = frontier_struct(end);
last_status = string(last_row.frontier_status);
state.anchor_price_path = anchor_price_path(:);
state.anchor_source = string(anchor_source);

if last_row.k == max_k && is_final_frontier_status(last_status)
    state.is_complete = true;
    state.next_k = max_k + 1;
    state.current_alpha_idx = 0;
    state.current_k_state = initialize_current_k_state();
    ok = true;
    return;
end

if is_final_frontier_status(last_status)
    state.next_k = last_row.k + 1;
    if isnan(last_row.max_stable_alpha)
        state.previous_frontier_idx = 1;
    else
        state.previous_frontier_idx = alpha_to_index(last_row.max_stable_alpha, alpha_grid);
    end
    state.current_alpha_idx = state.previous_frontier_idx;
    state.current_k_state = initialize_current_k_state();
    ok = true;
    return;
end

state.next_k = last_row.k;
state.previous_frontier_idx = infer_previous_frontier_idx(frontier_struct, last_row.k, alpha_grid);
state.current_k_state.max_stable_alpha = last_row.max_stable_alpha;
state.current_k_state.first_unstable_alpha = last_row.first_unstable_alpha;
state.current_k_state.frontier_status = last_status;
state.current_k_state.last_stable_row = extract_last_stable_summary_row(summary_struct, last_row.k, last_row.max_stable_alpha);
state.current_alpha_idx = infer_next_alpha_idx(summary_struct, alpha_grid, last_row.k, last_status);

if state.current_alpha_idx < 1
    state = finalize_exhausted_k(state);
end

ok = true;
end

function table_value = extract_table_field(loaded, names)
table_value = [];
for i = 1:numel(names)
    name = names{i};
    if isfield(loaded, name) && istable(loaded.(name))
        table_value = loaded.(name);
        return;
    end
end
end

function tf = is_final_frontier_status(status)
tf = any(status == ["found_stable_alpha", "no_stable_alpha_found"]);
end

function idx = alpha_to_index(alpha, alpha_grid)
idx = find(abs(alpha_grid - alpha) < 1e-12, 1, 'first');
if isempty(idx)
    idx = 1;
end
end

function idx = infer_previous_frontier_idx(frontier_struct, current_k, alpha_grid)
idx = numel(alpha_grid);
if current_k <= 1
    return;
end

prior_rows = frontier_struct([frontier_struct.k] == current_k - 1);
if isempty(prior_rows)
    return;
end

max_stable_alpha = prior_rows(end).max_stable_alpha;
if isnan(max_stable_alpha)
    idx = 1;
else
    idx = alpha_to_index(max_stable_alpha, alpha_grid);
end
end

function idx = infer_next_alpha_idx(summary_struct, alpha_grid, k, frontier_status)
idx = 0;
if isempty(summary_struct)
    return;
end

rows_k = summary_struct([summary_struct.k] == k);
if isempty(rows_k)
    return;
end

tested_alphas = [rows_k.policy_reference_blend_weight];
tested_idx = arrayfun(@(alpha) alpha_to_index(alpha, alpha_grid), tested_alphas);
lowest_tested_idx = min(tested_idx);

if frontier_status == "error"
    idx = lowest_tested_idx;
else
    idx = lowest_tested_idx - 1;
end
end

function row = extract_last_stable_summary_row(summary_struct, k, stable_alpha)
row = [];
if isempty(summary_struct) || isnan(stable_alpha)
    return;
end

rows_k = summary_struct([summary_struct.k] == k);
for i = numel(rows_k):-1:1
    if abs(rows_k(i).policy_reference_blend_weight - stable_alpha) < 1e-12 && rows_k(i).looks_stable
        row = rows_k(i);
        return;
    end
end
end

function rows = initialize_summary_rows(num_rows)
template = struct( ...
    'k', NaN, ...
    'policy_reference_blend_weight', NaN, ...
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
    'elapsed_seconds', NaN);
rows = repmat(template, num_rows, 1);
end

function row = build_summary_row(k, alpha, status, iterations_completed, results, params, warm_start_source, elapsed_seconds)
iter_idx = results.iterations;
policy_ref_path = results.policy_reference_price_path_used(:);

row = struct( ...
    'k', k, ...
    'policy_reference_blend_weight', alpha, ...
    'status', string(status), ...
    'iterations_completed', iterations_completed, ...
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
    'warm_start_source', string(warm_start_source), ...
    'elapsed_seconds', elapsed_seconds);
end

function rows = initialize_frontier_rows(max_k)
template = struct( ...
    'k', NaN, ...
    'max_stable_alpha', NaN, ...
    'first_unstable_alpha', NaN, ...
    'frontier_status', "", ...
    'last_stable_max_abs_gap', NaN, ...
    'last_stable_price_min', NaN, ...
    'last_stable_price_max', NaN);
rows = repmat(template, max_k, 1);
end

function k_state = initialize_current_k_state()
k_state = struct( ...
    'max_stable_alpha', NaN, ...
    'first_unstable_alpha', NaN, ...
    'frontier_status', "searching", ...
    'last_stable_row', []);
end

function state = finalize_exhausted_k(state)
k = state.next_k;
state.current_k_state.frontier_status = "no_stable_alpha_found";
state.frontier_rows(k) = make_frontier_row( ...
    k, ...
    state.current_k_state.max_stable_alpha, ...
    state.current_k_state.first_unstable_alpha, ...
    state.current_k_state.frontier_status, ...
    state.current_k_state.last_stable_row);
state.previous_frontier_idx = 1;
state.next_k = k + 1;
state.current_alpha_idx = state.previous_frontier_idx;
state.current_k_state = initialize_current_k_state();
end

function summary_table = build_summary_table(state)
if state.summary_idx == 0
    summary_table = struct2table(state.summary_rows([]));
else
    summary_table = struct2table(state.summary_rows(1:state.summary_idx));
end
end

function frontier_table = build_frontier_table(state)
frontier_table = trim_frontier_table(state.frontier_rows);
end

function write_checkpoint(paths, state, error_message)
if nargin < 3
    error_message = "";
end

summary_table = build_summary_table(state);
frontier_table = build_frontier_table(state);

writetable(summary_table, paths.live_summary_path);
writetable(frontier_table, paths.live_frontier_path);
save(paths.live_results_path, ...
    'summary_table', 'frontier_table', 'state', 'error_message');
end

function params = default_frontier_params(alpha)
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

function run_info = solve_frontier_case(guess, demographic_path_k, params, warm_start_source)
[results, elapsed_seconds] = solve_frontier_case_once(guess, demographic_path_k, params);
run_info = struct( ...
    'results', results, ...
    'status', "ok", ...
    'iterations_completed', results.iterations, ...
    'warm_start_source', string(warm_start_source), ...
    'elapsed_seconds', elapsed_seconds, ...
    'attempt_count', 1);

if looks_stable(results, params)
    return;
end

retry_guess = results.final_price_path(:);
retry_source = sprintf('%s -> retry_from_failed_endpoint', warm_start_source);
[retry_results, retry_elapsed_seconds] = solve_frontier_case_once(retry_guess, demographic_path_k, params);

run_info.results = retry_results;
run_info.status = "ok_retry_failed";
run_info.iterations_completed = results.iterations + retry_results.iterations;
run_info.warm_start_source = string(retry_source);
run_info.elapsed_seconds = elapsed_seconds + retry_elapsed_seconds;
run_info.attempt_count = 2;

if looks_stable(retry_results, params)
    run_info.status = "ok_after_retry";
end
end

function [results, elapsed_seconds] = solve_frontier_case_once(guess, demographic_path_k, params)
run_tic = tic;
results = solve_transition_re_no_politics(guess, demographic_path_k, params);
elapsed_seconds = toc(run_tic);
end

function [guess, label] = select_warm_start(k, alpha_idx, all_results, anchor_price_path, anchor_source, previous_frontier_idx)
if k > 1 && ~isempty(all_results{k - 1, alpha_idx})
    prior_path = all_results{k - 1, alpha_idx}.final_price_path(:);
    guess = extend_guess(prior_path, anchor_price_path, k);
    label = sprintf('same_alpha_k_%d', k - 1);
    return;
end

if k > 1 && previous_frontier_idx >= 1 && previous_frontier_idx <= size(all_results, 2) && ...
        ~isempty(all_results{k - 1, previous_frontier_idx})
    prior_path = all_results{k - 1, previous_frontier_idx}.final_price_path(:);
    guess = extend_guess(prior_path, anchor_price_path, k);
    label = sprintf('frontier_k_%d_alpha_idx_%d', k - 1, previous_frontier_idx);
    return;
end

for higher_alpha_idx = alpha_idx + 1:size(all_results, 2)
    if ~isempty(all_results{k, higher_alpha_idx})
        prior_path = all_results{k, higher_alpha_idx}.final_price_path(:);
        guess = extend_guess(prior_path, anchor_price_path, k);
        label = sprintf('same_k_higher_alpha_idx_%d', higher_alpha_idx);
        return;
    end
end

guess = anchor_price_path(1:k);
label = sprintf('anchor_prefix_%s', anchor_source);
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
demographic_path_k.description = sprintf('%s Truncated to first %d periods for the alpha frontier.', ...
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

function tf = looks_stable(results, params)
tol = 1e-6;
tf = results.update_diagnostics.max_abs_gap < 0.05 && ...
    min(results.final_price_path) > params.fixed_point_price_min + tol && ...
    max(results.final_price_path) < params.fixed_point_price_max - tol;
end

function row = make_frontier_row(k, max_stable_alpha, first_unstable_alpha, frontier_status, last_stable_row)
row = struct( ...
    'k', k, ...
    'max_stable_alpha', max_stable_alpha, ...
    'first_unstable_alpha', first_unstable_alpha, ...
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

function frontier_table = trim_frontier_table(frontier_rows)
if isempty(frontier_rows)
    frontier_table = struct2table(frontier_rows);
    return;
end

has_k = arrayfun(@(row) ~isnan(row.k), frontier_rows);
frontier_table = struct2table(frontier_rows(has_k));
end

function label = format_alpha_label(alpha)
label = regexprep(sprintf('%.3f', alpha), '0+$', '');
label = regexprep(label, '\.$', '');
label = strrep(label, '.', '_');
end

function delete_if_exists(path_string)
if isfile(path_string)
    delete(path_string);
end
end
