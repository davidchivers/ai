function summary = run_transition_political_bellman_k_step_ladder(max_k, max_iter, price_update_mode, political_target, political_update_weight, run_tag, political_update_rule)
% Solve the bounded political Bellman wrapper on progressively longer
% horizons, warm-starting each longer run from the previous shorter one.

if nargin < 1 || isempty(max_k)
    max_k = 9;
end
if nargin < 2 || isempty(max_iter)
    max_iter = 1;
end
if nargin < 3 || isempty(price_update_mode)
    price_update_mode = 'joint_housing_political';
end
if nargin < 4 || isempty(political_target)
    political_target = 'equal_weight_vote';
end
if nargin < 5 || isempty(political_update_weight)
    political_update_weight = 0.005;
end
if nargin < 6 || isempty(run_tag)
    run_tag = '';
end
if nargin < 7 || isempty(political_update_rule)
    political_update_rule = 'fixed_step';
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
            numel(loaded.results.final_price_path) >= T_full
        anchor_price_path = loaded.results.final_price_path(:);
        anchor_source = "transition_re_no_politics_results.final_price_path";
    end
end

run_tag = make_ladder_tag_local(run_tag, max_k, max_iter, price_update_mode, political_target, political_update_weight, political_update_rule);

summary_rows = repmat(struct( ...
    'k', NaN, ...
    'status', "", ...
    'iterations_completed', NaN, ...
    'converged_political', false, ...
    'political_target', "", ...
    'price_update_mode', "", ...
    'max_abs_vote', NaN, ...
    'mean_vote', NaN, ...
    'max_abs_gap', NaN, ...
    'residual_norm', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'path_span', NaN, ...
    'housing_anchor_min', NaN, ...
    'housing_anchor_max', NaN, ...
    'max_abs_political_step', NaN, ...
    'warm_start_source', "", ...
    'elapsed_seconds', NaN), max_k, 1);
all_results = cell(max_k, 1);

current_guess = [];
fprintf('=== Political Bellman k-step ladder ===\n');
fprintf('Anchor source: %s\n', anchor_source);
fprintf('Update mode: %s\n', price_update_mode);
fprintf('Target: %s\n', political_target);
fprintf('Weight: %.4f\n', political_update_weight);
fprintf('Update rule: %s\n', political_update_rule);
fprintf('Run tag: %s\n', run_tag);

for k = 1:max_k
    demographic_path_k = truncate_demographic_path_local(demographic_path_full, k);
    current_guess = extend_guess_local(current_guess, anchor_price_path, k);
    warm_start_source = describe_warm_start_local(k, anchor_source);

    fprintf('\nRunning political Bellman ladder at k = %d with warm start %s ...\n', k, warm_start_source);
    tic;
    try
        [~, results] = run_transition_political_bellman_bounded(k, max_iter, price_update_mode, political_target, political_update_weight, ...
            sprintf('%s_k%d', run_tag, k), political_update_rule);
        elapsed_seconds = toc;
        all_results{k} = results;
        current_guess = results.final_price_path(:);

        iter_idx = results.iterations;
        summary_rows(k) = struct( ...
            'k', k, ...
            'status', "ok", ...
            'iterations_completed', iter_idx, ...
            'converged_political', results.converged_political, ...
            'political_target', string(results.political_target), ...
            'price_update_mode', string(results.price_update_mode), ...
            'max_abs_vote', results.iteration_log(iter_idx).max_abs_vote, ...
            'mean_vote', results.iteration_log(iter_idx).mean_vote, ...
            'max_abs_gap', results.iteration_log(iter_idx).max_abs_gap, ...
            'residual_norm', results.iteration_log(iter_idx).residual_norm, ...
            'price_min', min(results.final_price_path), ...
            'price_max', max(results.final_price_path), ...
            'path_span', max(results.final_price_path) - min(results.final_price_path), ...
            'housing_anchor_min', results.iteration_log(iter_idx).housing_anchor_min, ...
            'housing_anchor_max', results.iteration_log(iter_idx).housing_anchor_max, ...
            'max_abs_political_step', results.iteration_log(iter_idx).max_abs_political_step, ...
            'warm_start_source', warm_start_source, ...
            'elapsed_seconds', elapsed_seconds);

        fprintf('  k=%d done: vote=%.6f, gap=%.6f, range=[%.4f, %.4f]\n', ...
            k, summary_rows(k).max_abs_vote, summary_rows(k).max_abs_gap, ...
            summary_rows(k).price_min, summary_rows(k).price_max);

        if is_unstable_political_k_step_local(summary_rows(k))
            fprintf('  stopping after k=%d because the political ladder looks unstable.\n', k);
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
            'converged_political', false, ...
            'political_target', string(political_target), ...
            'price_update_mode', string(price_update_mode), ...
            'max_abs_vote', NaN, ...
            'mean_vote', NaN, ...
            'max_abs_gap', NaN, ...
            'residual_norm', NaN, ...
            'price_min', NaN, ...
            'price_max', NaN, ...
            'path_span', NaN, ...
            'housing_anchor_min', NaN, ...
            'housing_anchor_max', NaN, ...
            'max_abs_political_step', NaN, ...
            'warm_start_source', warm_start_source, ...
            'elapsed_seconds', elapsed_seconds);
        summary_rows = summary_rows(1:k);
        all_results = all_results(1:k);
        summary = struct2table(summary_rows);
        writetable(summary, fullfile(this_dir, sprintf('transition_political_bellman_%s_ladder_summary.csv', run_tag)));
        save(fullfile(this_dir, sprintf('transition_political_bellman_%s_ladder_results.mat', run_tag)), ...
            'summary', 'all_results', 'anchor_source', 'anchor_price_path', 'ME');
        rethrow(ME);
    end
end

summary = struct2table(summary_rows);
writetable(summary, fullfile(this_dir, sprintf('transition_political_bellman_%s_ladder_summary.csv', run_tag)));
save(fullfile(this_dir, sprintf('transition_political_bellman_%s_ladder_results.mat', run_tag)), ...
    'summary', 'all_results', 'anchor_source', 'anchor_price_path');
end

function run_tag = make_ladder_tag_local(run_tag, max_k, max_iter, price_update_mode, political_target, political_update_weight, political_update_rule)
if ~isempty(run_tag)
    run_tag = regexprep(lower(string(run_tag)), '[^a-z0-9_]+', '_');
    return;
end

run_tag = sprintf('t%d_i%d_%s_%s_%s_w%s', ...
    max_k, ...
    max_iter, ...
    regexprep(lower(string(price_update_mode)), '[^a-z0-9]+', '_'), ...
    regexprep(lower(string(political_target)), '[^a-z0-9]+', '_'), ...
    regexprep(lower(string(political_update_rule)), '[^a-z0-9]+', '_'), ...
    strrep(sprintf('%.4f', political_update_weight), '.', 'p'));
end

function demographic_path_k = truncate_demographic_path_local(demographic_path_full, k)
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
demographic_path_k.description = sprintf('%s Truncated to first %d periods for the political Bellman ladder.', ...
    demographic_path_full.description, k);
end

function guess = extend_guess_local(current_guess, anchor_price_path, k)
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

function label = describe_warm_start_local(k, anchor_source)
if k == 1
    label = "anchor_prefix";
else
    label = sprintf('k_%d_political_final_path_plus_%s_tail', k - 1, anchor_source);
end
end

function tf = is_unstable_political_k_step_local(row)
tf = ~isfinite(row.max_abs_vote) || ~isfinite(row.max_abs_gap) || row.price_min <= 0.40 + 1e-6 || row.price_max >= 5.00 - 1e-6;
end
