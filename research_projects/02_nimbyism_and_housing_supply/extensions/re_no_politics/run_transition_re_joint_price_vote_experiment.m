function [summary, period_rows, all_results] = run_transition_re_joint_price_vote_experiment(max_k, joint_iters, vote_weight)
% Bounded joint price-and-vote update experiment built on top of the
% transition political-path packet.

if nargin < 1 || isempty(max_k)
    max_k = 4;
end
if nargin < 2 || isempty(joint_iters)
    joint_iters = 2;
end
if nargin < 3 || isempty(vote_weight)
    vote_weight = 0.001;
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
joint_iters = max(1, round(joint_iters));
demographic_path = truncate_demographic_path_local(demographic_path_full, max_k);

current_price_path = 2.0 .* ones(max_k, 1);
guess_source = "flat_2.0";
previous_results_path = fullfile(this_dir, 'transition_re_no_politics_results.mat');
if isfile(previous_results_path)
    loaded = load(previous_results_path, 'results');
    if isfield(loaded, 'results') && isfield(loaded.results, 'final_price_path') && ...
            numel(loaded.results.final_price_path) >= max_k
        current_price_path = loaded.results.final_price_path(1:max_k);
        guess_source = "transition_re_no_politics_results.final_price_path_prefix";
    end
end

params = default_joint_params_local();

summary_rows = repmat(struct( ...
    'joint_iter', NaN, ...
    'guess_source', "", ...
    'vote_weight', NaN, ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'accepted_update', "", ...
    'max_abs_weighted_vote', NaN, ...
    'worst_weighted_vote_period', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'elapsed_seconds', NaN), joint_iters, 1);

period_rows = repmat(struct( ...
    'joint_iter', NaN, ...
    'period_index', NaN, ...
    'year', NaN, ...
    'input_price', NaN, ...
    'housing_candidate_price', NaN, ...
    'weighted_vote_share', NaN, ...
    'politically_adjusted_price', NaN, ...
    'implied_price', NaN, ...
    'equal_weight_vote', NaN, ...
    'weighted_vote', NaN, ...
    'excess_demand', NaN), joint_iters * max_k, 1);

all_results = cell(joint_iters, 1);
row_idx = 0;

fprintf('=== Joint price-and-vote experiment ===\n');
fprintf('Periods: %d\n', max_k);
fprintf('Joint iterations: %d\n', joint_iters);
fprintf('Vote weight: %.6f\n', vote_weight);
fprintf('Initial guess source: %s\n', guess_source);

for joint_iter = 1:joint_iters
    fprintf('\nRunning joint iteration %d of %d ...\n', joint_iter, joint_iters);
    iter_tic = tic;
    results = solve_transition_re_no_politics(current_price_path, demographic_path, params);
    elapsed_seconds = toc(iter_tic);
    all_results{joint_iter} = results;

    housing_candidate_price = results.final_price_path(:);
    weighted_vote_share = results.political.weighted_vote_share_path(:);
    politically_adjusted_price = housing_candidate_price .* exp(vote_weight .* weighted_vote_share);

    iter_idx = results.iterations;
    summary_rows(joint_iter) = struct( ...
        'joint_iter', joint_iter, ...
        'guess_source', guess_source, ...
        'vote_weight', vote_weight, ...
        'residual_norm', results.iteration_log(iter_idx).residual_norm, ...
        'max_abs_gap', results.update_diagnostics.max_abs_gap, ...
        'max_abs_update', max(abs(politically_adjusted_price - current_price_path)), ...
        'accepted_update', string(results.iteration_log(iter_idx).accepted_update), ...
        'max_abs_weighted_vote', max(abs(results.political.weighted_vote_path)), ...
        'worst_weighted_vote_period', argmax_abs_local(results.political.weighted_vote_path), ...
        'price_min', min(politically_adjusted_price), ...
        'price_max', max(politically_adjusted_price), ...
        'elapsed_seconds', elapsed_seconds);

    for t = 1:max_k
        row_idx = row_idx + 1;
        period_rows(row_idx) = struct( ...
            'joint_iter', joint_iter, ...
            'period_index', t, ...
            'year', demographic_path.years(t), ...
            'input_price', current_price_path(t), ...
            'housing_candidate_price', housing_candidate_price(t), ...
            'weighted_vote_share', weighted_vote_share(t), ...
            'politically_adjusted_price', politically_adjusted_price(t), ...
            'implied_price', results.implied_price_path(t), ...
            'equal_weight_vote', results.political.equal_weight_vote_path(t), ...
            'weighted_vote', results.political.weighted_vote_path(t), ...
            'excess_demand', results.excess_demand_path(t));
    end

    fprintf('  housing gap = %.6f, max weighted vote = %.6f, adjusted range = [%.6f, %.6f]\n', ...
        summary_rows(joint_iter).max_abs_gap, summary_rows(joint_iter).max_abs_weighted_vote, ...
        summary_rows(joint_iter).price_min, summary_rows(joint_iter).price_max);

    current_price_path = politically_adjusted_price;
    guess_source = sprintf('joint_iter_%d_adjusted_path', joint_iter);
end

summary = struct2table(summary_rows);
period_rows = struct2table(period_rows(1:row_idx));
writetable(summary, fullfile(this_dir, 'transition_re_joint_price_vote_summary.csv'));
writetable(period_rows, fullfile(this_dir, 'transition_re_joint_price_vote_periods.csv'));
save(fullfile(this_dir, 'transition_re_joint_price_vote_results.mat'), ...
    'summary', 'period_rows', 'all_results', 'demographic_path', 'vote_weight');
end

function params = default_joint_params_local()
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
params.save_political_details = false;
params.save_period_details = false;
params.coalition_params = struct();
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
demographic_path_k.description = sprintf('%s Truncated to first %d periods for the joint price-vote experiment.', ...
    demographic_path_full.description, k);
end

function idx = argmax_abs_local(x)
[~, idx] = max(abs(x(:)));
end
