function [summary, results] = run_original_5yr_transition_segment_lobe_search( ...
    max_k, seed_price_csv_path, run_tag, demographic_source_mode, log_step_grid, active_threshold_frac, ...
    price_floor, price_cap)
% Coarse full-horizon lobe search around the stable seeded path.
%
% This is a complementary branch to the reduced-path Jacobian runner. It does
% not use local derivatives. Instead, it exploits the observed multi-lobe vote
% geometry and searches over a small signed coefficient grid for three broad
% path segments: early positive lobe, middle negative lobe, late positive lobe.

if nargin < 1 || isempty(max_k)
    max_k = 14;
end
if nargin < 2 || isempty(seed_price_csv_path)
    seed_price_csv_path = '';
end
if nargin < 3
    run_tag = '';
end
if nargin < 4 || isempty(demographic_source_mode)
    demographic_source_mode = 'historical_1950';
end
if nargin < 5 || isempty(log_step_grid)
    log_step_grid = [-0.010, -0.006, -0.003, 0.003, 0.006, 0.010];
end
if nargin < 6 || isempty(active_threshold_frac)
    active_threshold_frac = 0.65;
end
if nargin < 7 || isempty(price_floor)
    price_floor = 0.05;
end
if nargin < 8 || isempty(price_cap)
    price_cap = 5.00;
end

validateattributes(max_k, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(log_step_grid, {'double'}, {'vector', 'nonempty', 'finite', 'real'});
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
run_tag = make_run_tag_local(run_tag, max_k, log_step_grid);

output_dir = fullfile(this_dir, 'truth', 'segment_lobe_search', char(run_tag));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

params = default_transition_eval_params_local();
params.fixed_point_price_min = price_floor;
params.fixed_point_price_max = price_cap;

base_eval = evaluate_price_path_local(seed_price_path, demographic_path, params, [], active_threshold_frac);
segment_defs = build_segment_defs_local(base_eval.vote_path);

candidate_rows = [];
baseline_row = build_row_local("baseline", 0, 0, 0, seed_price_path, base_eval);
candidate_rows = [candidate_rows; baseline_row]; %#ok<AGROW>

best_eval = base_eval;
best_tag = "baseline";
best_shifts = [0, 0, 0];

for left_shift = reshape(log_step_grid, 1, [])
    for mid_shift = reshape(log_step_grid, 1, [])
        for right_shift = reshape(log_step_grid, 1, [])
            candidate_price_path = seed_price_path;
            candidate_price_path(segment_defs.left_idx) = candidate_price_path(segment_defs.left_idx) .* exp(left_shift);
            candidate_price_path(segment_defs.mid_idx) = candidate_price_path(segment_defs.mid_idx) .* exp(mid_shift);
            candidate_price_path(segment_defs.right_idx) = candidate_price_path(segment_defs.right_idx) .* exp(right_shift);
            candidate_price_path = clamp_price_path_local(candidate_price_path, price_floor, price_cap);

            candidate_eval = evaluate_price_path_local(candidate_price_path, demographic_path, params, base_eval.active_periods, active_threshold_frac);
            candidate_tag = sprintf('l_%+.4f_m_%+.4f_r_%+.4f', left_shift, mid_shift, right_shift);
            candidate_rows = [candidate_rows; build_row_local(candidate_tag, left_shift, mid_shift, right_shift, candidate_price_path, candidate_eval)]; %#ok<AGROW>

            if is_better_candidate_local(candidate_eval.metrics, best_eval.metrics, base_eval.metrics)
                best_eval = candidate_eval;
                best_tag = string(candidate_tag);
                best_shifts = [left_shift, mid_shift, right_shift];
            end
        end
    end
end

summary = struct2table(candidate_rows);
summary = sortrows(summary, {'merit', 'max_abs_vote', 'max_abs_gap'}, {'ascend', 'ascend', 'ascend'});

results = struct();
results.run_tag = string(run_tag);
results.output_dir = string(output_dir);
results.seed_source = string(seed_source);
results.demographic_source_mode = string(demographic_source_mode);
results.segment_defs = segment_defs;
results.seed_price_path = seed_price_path(:);
results.seed_metrics = base_eval.metrics;
results.best_candidate_tag = best_tag;
results.best_candidate_shifts = best_shifts;
results.best_price_path = best_eval.price_path(:);
results.best_vote_path = best_eval.vote_path(:);
results.best_metrics = best_eval.metrics;
results.message = 'Segment-lobe coefficient grid search completed on the seeded full-horizon path.';

summary_path = fullfile(output_dir, sprintf('%s_summary.csv', run_tag));
results_path = fullfile(output_dir, sprintf('%s_results.mat', run_tag));
best_price_path_csv = fullfile(output_dir, sprintf('%s_best_price_path.csv', run_tag));
best_vote_path_csv = fullfile(output_dir, sprintf('%s_best_vote_path.csv', run_tag));
writetable(summary, summary_path);
writematrix(results.best_price_path(:), best_price_path_csv);
writematrix(results.best_vote_path(:), best_vote_path_csv);
save(results_path, 'summary', 'results', 'demographic_path', 'seed_price_path');
end

function row = build_row_local(tag, left_shift, mid_shift, right_shift, price_path, eval_result)
row = struct();
row.candidate_tag = string(tag);
row.left_shift = left_shift;
row.mid_shift = mid_shift;
row.right_shift = right_shift;
row.max_abs_vote = eval_result.metrics.max_abs_vote;
row.active_max_abs_vote = eval_result.metrics.active_max_abs_vote;
row.vote_l2 = eval_result.metrics.vote_l2;
row.merit = eval_result.metrics.merit;
row.max_abs_gap = eval_result.metrics.max_abs_gap;
row.residual_norm = eval_result.metrics.residual_norm;
row.price_min = min(price_path);
row.price_max = max(price_path);
end

function segment_defs = build_segment_defs_local(vote_path)
vote_path = vote_path(:);
T = numel(vote_path);
sign_path = sign(vote_path);

for t = 1:T
    if sign_path(t) == 0
        if t == 1
            sign_path(t) = 1;
        else
            sign_path(t) = sign_path(t - 1);
        end
    end
end

segment_breaks = [1; find(diff(sign_path) ~= 0) + 1; T + 1];
segment_starts = segment_breaks(1:end-1);
segment_ends = segment_breaks(2:end) - 1;

if numel(segment_starts) >= 3
    left_idx = (segment_starts(1):segment_ends(1))';
    mid_idx = (segment_starts(2):segment_ends(2))';
    right_idx = (segment_starts(3):segment_ends(end))';
else
    left_idx = (1:max(1, floor(T / 3)))';
    mid_idx = ((max(left_idx) + 1):max(max(left_idx) + 1, floor(2 * T / 3)))';
    right_idx = ((max(mid_idx) + 1):T)';
    if isempty(right_idx)
        right_idx = T;
    end
end

segment_defs = struct();
segment_defs.left_idx = left_idx(:);
segment_defs.mid_idx = mid_idx(:);
segment_defs.right_idx = right_idx(:);
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
eval_result = struct('price_path', price_path, 'vote_path', vote_path, 'active_periods', active_periods(:), 'metrics', metrics);
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

function price_path = clamp_price_path_local(price_path, price_floor, price_cap)
price_path = min(max(price_path(:), price_floor), price_cap);
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

function run_tag = make_run_tag_local(run_tag, max_k, log_step_grid)
if ~isempty(run_tag)
    run_tag = regexprep(lower(string(run_tag)), '[^a-z0-9_]+', '_');
    return;
end

run_tag = sprintf('segment_lobe_k%d_n%d', max_k, numel(log_step_grid));
run_tag = regexprep(lower(string(run_tag)), '[^a-z0-9_]+', '_');
end
