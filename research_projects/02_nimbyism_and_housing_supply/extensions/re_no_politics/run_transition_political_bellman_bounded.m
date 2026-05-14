function [summary, results] = run_transition_political_bellman_bounded(max_k, max_iter, price_update_mode, political_target, political_update_weight, run_tag, political_update_rule)
% Run a bounded full-political Bellman wrapper on the first few transition periods.

if nargin < 1 || isempty(max_k)
    max_k = 4;
end
if nargin < 2 || isempty(max_iter)
    max_iter = 2;
end
if nargin < 3 || isempty(price_update_mode)
    price_update_mode = 'political_only';
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
demographic_path = truncate_demographic_path_local(demographic_path_full, max_k);

price_path_guess = 2.0 .* ones(max_k, 1);
guess_source = "flat_2.0";
previous_results_path = fullfile(this_dir, 'transition_re_no_politics_results.mat');
if isfile(previous_results_path)
    loaded = load(previous_results_path, 'results');
    if isfield(loaded, 'results') && isfield(loaded.results, 'final_price_path') && ...
            numel(loaded.results.final_price_path) >= max_k
        price_path_guess = loaded.results.final_price_path(1:max_k);
        guess_source = "transition_re_no_politics_results.final_price_path_prefix";
    end
end
run_tag = make_run_tag_local(run_tag, max_k, max_iter, price_update_mode, political_target, political_update_weight, political_update_rule);

params = default_params_local(max_iter, price_update_mode, political_target, political_update_weight, political_update_rule);

fprintf('=== Bounded political Bellman wrapper ===\n');
fprintf('Periods: %d\n', max_k);
fprintf('Iterations: %d\n', max_iter);
fprintf('Target: %s\n', params.political_target);
fprintf('Update mode: %s\n', params.price_update_mode);
fprintf('Update rule: %s\n', params.political_update_rule);
fprintf('Run tag: %s\n', run_tag);
fprintf('Guess source: %s\n', guess_source);

results = solve_transition_political_bellman_nimby(price_path_guess, demographic_path, params);
results.run_tag = string(run_tag);

iters = (1:results.iterations)';
summary = table( ...
    iters, ...
    repmat(string(guess_source), results.iterations, 1), ...
    repmat(string(results.political_target), results.iterations, 1), ...
    repmat(string(results.price_update_mode), results.iterations, 1), ...
    [results.iteration_log.political_update_rule]', ...
    [results.iteration_log.max_abs_vote]', ...
    [results.iteration_log.mean_vote]', ...
    [results.iteration_log.max_abs_gap]', ...
    [results.iteration_log.residual_norm]', ...
    [results.iteration_log.price_min]', ...
    [results.iteration_log.price_max]', ...
    [results.iteration_log.housing_anchor_min]', ...
    [results.iteration_log.housing_anchor_max]', ...
    [results.iteration_log.max_abs_political_step]', ...
    'VariableNames', { ...
        'iteration', 'guess_source', 'political_target', 'price_update_mode', 'political_update_rule', ...
        'max_abs_vote', 'mean_vote', 'max_abs_gap', 'residual_norm', ...
        'price_min', 'price_max', 'housing_anchor_min', 'housing_anchor_max', ...
        'max_abs_political_step'});

summary_path = fullfile(this_dir, sprintf('transition_political_bellman_%s_summary.csv', run_tag));
results_path = fullfile(this_dir, sprintf('transition_political_bellman_%s_results.mat', run_tag));
final_price_path_csv = fullfile(this_dir, sprintf('transition_political_bellman_%s_final_price_path.csv', run_tag));
final_vote_path_csv = fullfile(this_dir, sprintf('transition_political_bellman_%s_final_vote_path.csv', run_tag));
final_anchor_path_csv = fullfile(this_dir, sprintf('transition_political_bellman_%s_final_anchor_path.csv', run_tag));
writetable(summary, summary_path);
writematrix(results.final_price_path(:), final_price_path_csv);
writematrix(results.final_vote_path(:), final_vote_path_csv);
writematrix(results.final_anchor_path(:), final_anchor_path_csv);
save(results_path, ...
    'summary', 'results', 'demographic_path', 'price_path_guess');
end

function params = default_params_local(max_iter, price_update_mode, political_target, political_update_weight, political_update_rule)
params = struct();
params.max_iter = max_iter;
params.tol_vote = 1e-3;
params.political_target = political_target;
params.price_update_mode = price_update_mode;
params.political_update_space = 'log';
params.political_update_rule = political_update_rule;
params.political_update_weight = political_update_weight;
params.max_update_frac = 0.02;
params.price_floor = 0.40;
params.price_cap = 5.00;
params.secant_damping = 0.75;
params.secant_min_abs_slope = 1e-3;
params.pass_params = struct();
params.pass_params.max_iter = 1;
params.pass_params.tol = 1e-4;
params.pass_params.damping = 0.25;
params.pass_params.max_update_frac = 0.10;
params.pass_params.smoothing_weight = 5.00;
params.pass_params.terminal_anchor_weight = 0.50;
params.pass_params.targeted_correction_weight = 0.35;
params.pass_params.max_targeted_periods = 3;
params.pass_params.target_block_half_width = 1;
params.pass_params.line_search_scales = [0.01, 0.02, 0.05];
params.pass_params.update_scheme = 'sequential_blocks';
params.pass_params.transition_policy_mode = 'full_backward';
params.pass_params.terminal_price_rule = 'flat_tail';
params.pass_params.terminal_reference_mode = 'path_end_price';
params.pass_params.compute_political_path = true;
params.pass_params.save_political_details = false;
params.pass_params.save_period_details = true;
params.pass_params.coalition_params = struct( ...
    'alpha_owner', 0.0, ...
    'alpha_old_owner', 0.0, ...
    'alpha_leverage', 0.0, ...
    'alpha_bighouse', 0.0);
end

function run_tag = make_run_tag_local(run_tag, max_k, max_iter, price_update_mode, political_target, political_update_weight, political_update_rule)
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
demographic_path_k.description = sprintf('%s Truncated to first %d periods for the bounded political Bellman wrapper.', ...
    demographic_path_full.description, k);
end
