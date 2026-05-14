function [summary, results] = run_original_5yr_transition_dynare_reduced_path( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    price_floor, price_cap)
% Dynare-driven reduced-path outer solver for the original 5-year transition.
%
% This branch exports a reduced active-set normal-equation system, solves the
% reduced coefficient update with Dynare, then evaluates the resulting price
% path against the full Bellman transition object.

if nargin < 1 || isempty(max_k)
    max_k = 14;
end
if nargin < 2 || isempty(max_outer_iter)
    max_outer_iter = 2;
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
    price_cap = 5.0;
end

validateattributes(max_k, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(max_outer_iter, {'double'}, {'scalar', 'integer', '>=', 1});
validateattributes(basis_count, {'double'}, {'scalar', 'integer', '>=', 2});

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
dynare_dir = fullfile(this_dir, 'dynare_reduced_path');
extension_dir = fullfile(fileparts(this_dir), 'extensions', 're_no_politics');
steadystate_dir = fullfile(fileparts(this_dir), 'code', 'steadystate');
addpath(this_dir);
addpath(dynare_dir);
addpath(extension_dir);
addpath(steadystate_dir);

if isempty(run_tag)
    run_tag = sprintf('dynare_k%d_i%d_b%d', max_k, max_outer_iter, basis_count);
end
run_tag = regexprep(lower(string(run_tag)), '[^a-z0-9_]+', '_');
output_dir = fullfile(this_dir, 'truth', 'dynare_reduced_path', char(run_tag));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

default_seed = fullfile(this_dir, 'original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv');
if isempty(seed_price_csv_path)
    seed_price_csv_path = default_seed;
end

current_seed_csv = seed_price_csv_path;
iteration_log = repmat(struct( ...
    'iteration', NaN, ...
    'current_max_abs_vote', NaN, ...
    'current_active_max_abs_vote', NaN, ...
    'current_vote_l2', NaN, ...
    'current_merit', NaN, ...
    'current_max_abs_gap', NaN, ...
    'current_residual_norm', NaN, ...
    'active_periods', [], ...
    'dynare_status', "", ...
    'dynare_step_max_abs_log', NaN, ...
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
    'max_abs_vote', NaN, ...
    'max_abs_gap', NaN, ...
    'merit', NaN), max_outer_iter, 1);

best_system = struct();
best_eval = struct();
improved_any = false;

for iter = 1:max_outer_iter
    iter_dir = fullfile(output_dir, sprintf('iter_%02d', iter));
    if ~exist(iter_dir, 'dir')
        mkdir(iter_dir);
    end

    system = export_original_5yr_dynare_reduced_system( ...
        max_k, basis_count, demographic_source_mode, current_seed_csv, iter_dir, finite_diff_step, ...
        ridge_lambda, active_threshold_frac, price_floor, price_cap);
    mod_path = build_original_5yr_dynare_reduced_system_mod( ...
        fullfile(iter_dir, 'nimby_dynare_reduced_system_input.mat'), iter_dir);

    [delta_coeff, dynare_status, dynare_message] = solve_dynare_step_local(mod_path, basis_count);
    raw_log_step = system.basis * delta_coeff(:);
    [raw_log_step, trust_region_binding, raw_step_max_abs_log] = enforce_trust_region_local(raw_log_step, trust_region_log_step);

    base_eval = struct();
    base_eval.price_path = system.seed_price_path(:);
    base_eval.vote_path = system.vote_path(:);
    base_eval.active_periods = system.active_periods(:);
    base_eval.metrics = system.metrics;

    iteration_log(iter).iteration = iter;
    iteration_log(iter).current_max_abs_vote = base_eval.metrics.max_abs_vote;
    iteration_log(iter).current_active_max_abs_vote = base_eval.metrics.active_max_abs_vote;
    iteration_log(iter).current_vote_l2 = base_eval.metrics.vote_l2;
    iteration_log(iter).current_merit = base_eval.metrics.merit;
    iteration_log(iter).current_max_abs_gap = base_eval.metrics.max_abs_gap;
    iteration_log(iter).current_residual_norm = base_eval.metrics.residual_norm;
    iteration_log(iter).active_periods = base_eval.active_periods(:)';
    iteration_log(iter).dynare_status = string(dynare_status);
    iteration_log(iter).dynare_step_max_abs_log = raw_step_max_abs_log;
    iteration_log(iter).trust_region_binding = trust_region_binding;

    chosen_eval = base_eval;
    chosen_direction = 0;
    chosen_scale = 0;
    accepted = false;

    if strcmpi(dynare_status, 'ok')
        direction_list = [1, -1];
        for direction_idx = 1:numel(direction_list)
            direction_sign = direction_list(direction_idx);
            for scale_idx = 1:numel(candidate_scales)
                scale = candidate_scales(scale_idx);
                candidate_step = direction_sign .* scale .* raw_log_step;
                if max(abs(candidate_step)) < 1e-10
                    continue;
                end

                candidate_price_path = clamp_price_path_local(base_eval.price_path .* exp(candidate_step), price_floor, price_cap);
                if max(abs(log(candidate_price_path) - log(base_eval.price_path))) < 1e-10
                    continue;
                end

                candidate_eval = evaluate_price_path_local(candidate_price_path, system.demographic_path, system.params, base_eval.active_periods, active_threshold_frac);
                if is_better_candidate_local(candidate_eval.metrics, chosen_eval.metrics, base_eval.metrics)
                    accepted = true;
                    chosen_eval = candidate_eval;
                    chosen_direction = direction_sign;
                    chosen_scale = scale;
                end
            end
        end
    end

    iteration_log(iter).accepted = accepted;
    iteration_log(iter).accepted_direction = chosen_direction;
    iteration_log(iter).accepted_scale = chosen_scale;
    iteration_log(iter).accepted_max_abs_vote = chosen_eval.metrics.max_abs_vote;
    iteration_log(iter).accepted_active_max_abs_vote = chosen_eval.metrics.active_max_abs_vote;
    iteration_log(iter).accepted_vote_l2 = chosen_eval.metrics.vote_l2;
    iteration_log(iter).accepted_merit = chosen_eval.metrics.merit;
    iteration_log(iter).accepted_max_abs_gap = chosen_eval.metrics.max_abs_gap;
    iteration_log(iter).accepted_residual_norm = chosen_eval.metrics.residual_norm;
    iteration_log(iter).max_abs_vote = chosen_eval.metrics.max_abs_vote;
    iteration_log(iter).max_abs_gap = chosen_eval.metrics.max_abs_gap;
    iteration_log(iter).merit = chosen_eval.metrics.merit;

    log_text = string(dynare_message);
    if strlength(log_text) > 0
        writelines(log_text, fullfile(iter_dir, 'dynare_status.txt'));
    end
    writematrix(delta_coeff(:), fullfile(iter_dir, 'dynare_delta_coeff.csv'));

    best_system = system;
    best_eval = chosen_eval;
    if accepted
        improved_any = true;
        current_seed_csv = fullfile(iter_dir, sprintf('%s_iter_%02d_seed.csv', run_tag, iter));
        writematrix(chosen_eval.price_path(:), current_seed_csv);
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
    [iteration_log(1:completed).current_active_max_abs_vote]', ...
    [iteration_log(1:completed).current_vote_l2]', ...
    [iteration_log(1:completed).current_merit]', ...
    [iteration_log(1:completed).current_max_abs_gap]', ...
    [iteration_log(1:completed).current_residual_norm]', ...
    string({iteration_log(1:completed).dynare_status})', ...
    [iteration_log(1:completed).dynare_step_max_abs_log]', ...
    [iteration_log(1:completed).trust_region_binding]', ...
    [iteration_log(1:completed).accepted]', ...
    [iteration_log(1:completed).accepted_direction]', ...
    [iteration_log(1:completed).accepted_scale]', ...
    [iteration_log(1:completed).accepted_max_abs_vote]', ...
    [iteration_log(1:completed).accepted_active_max_abs_vote]', ...
    [iteration_log(1:completed).accepted_vote_l2]', ...
    [iteration_log(1:completed).accepted_merit]', ...
    [iteration_log(1:completed).accepted_max_abs_gap]', ...
    [iteration_log(1:completed).accepted_residual_norm]', ...
    [iteration_log(1:completed).max_abs_vote]', ...
    [iteration_log(1:completed).max_abs_gap]', ...
    [iteration_log(1:completed).merit]', ...
    compose_active_periods_local(iteration_log(1:completed)), ...
    'VariableNames', { ...
        'iteration', 'current_max_abs_vote', 'current_active_max_abs_vote', 'current_vote_l2', ...
        'current_merit', 'current_max_abs_gap', 'current_residual_norm', 'dynare_status', ...
        'dynare_step_max_abs_log', 'trust_region_binding', 'accepted', 'accepted_direction', ...
        'accepted_scale', 'accepted_max_abs_vote', 'accepted_active_max_abs_vote', ...
        'accepted_vote_l2', 'accepted_merit', 'accepted_max_abs_gap', 'accepted_residual_norm', ...
        'max_abs_vote', 'max_abs_gap', 'merit', 'active_periods'});

summary_path = fullfile(output_dir, sprintf('%s_summary.csv', run_tag));
results_path = fullfile(output_dir, sprintf('%s_results.mat', run_tag));
final_price_path_csv = fullfile(output_dir, sprintf('%s_final_price_path.csv', run_tag));
final_vote_path_csv = fullfile(output_dir, sprintf('%s_final_vote_path.csv', run_tag));
writetable(summary, summary_path);
writematrix(best_eval.price_path(:), final_price_path_csv);
writematrix(best_eval.vote_path(:), final_vote_path_csv);

results = struct();
results.run_tag = string(run_tag);
results.output_dir = string(output_dir);
results.max_k = max_k;
results.max_outer_iter = max_outer_iter;
results.basis_count = basis_count;
results.seed_price_csv_path = string(seed_price_csv_path);
results.demographic_source_mode = string(demographic_source_mode);
results.finite_diff_step = finite_diff_step;
results.ridge_lambda = ridge_lambda;
results.candidate_scales = candidate_scales(:);
results.trust_region_log_step = trust_region_log_step;
results.active_threshold_frac = active_threshold_frac;
results.price_floor = price_floor;
results.price_cap = price_cap;
results.iterations = completed;
results.improved_any = improved_any;
results.final_price_path = best_eval.price_path(:);
results.final_vote_path = best_eval.vote_path(:);
results.final_active_periods = best_eval.active_periods(:);
results.final_metrics = best_eval.metrics;
results.iteration_log = iteration_log(1:completed);
results.last_system = best_system;
results.message = 'Dynare reduced-path branch completed using a regularized normal-equation solve for the reduced coefficient update.';
save(results_path, 'summary', 'results');

fprintf('=== Dynare reduced-path branch ===\n');
fprintf('Run tag: %s\n', run_tag);
fprintf('Output dir: %s\n', output_dir);
fprintf('Completed iterations: %d\n', completed);
fprintf('Improved any: %d\n', improved_any);
fprintf('Final max |vote|: %.8f\n', best_eval.metrics.max_abs_vote);
fprintf('Final max gap: %.8f\n', best_eval.metrics.max_abs_gap);
end

function [delta_coeff, status, message] = solve_dynare_step_local(mod_path, basis_count)
global M_ options_ oo_ estim_params_ bayestopt_ dataset_ dataset_info estimation_info ys0_ ex0_ ex_

delta_coeff = zeros(basis_count, 1);
status = "failed";
message = "";

orig_dir = pwd;
cleanup_obj = onCleanup(@() cd(orig_dir)); %#ok<NASGU>
mod_dir = fileparts(mod_path);
[~, mod_stem] = fileparts(mod_path);
cd(mod_dir);

clear global M_ options_ oo_ estim_params_ bayestopt_ dataset_ dataset_info estimation_info ys0_ ex0_ ex_
global M_ options_ oo_

try
    dynare(mod_stem, 'noclearall', 'nolog');
    coeff_names = arrayfun(@(j) sprintf('c%d', j), 1:basis_count, 'UniformOutput', false);
    delta_coeff = extract_dynare_coefficients_local(M_, oo_, coeff_names);
    status = "ok";
    message = "Dynare steady solve completed.";
catch err
    status = "failed";
    message = string(getReport(err, 'basic', 'hyperlinks', 'off'));
end
end

function coeff_values = extract_dynare_coefficients_local(M_, oo_, coeff_names)
endo_names = cellstr(M_.endo_names);
steady_state = oo_.steady_state(:);
coeff_values = zeros(numel(coeff_names), 1);
for j = 1:numel(coeff_names)
    idx = find(strcmp(strtrim(endo_names), coeff_names{j}), 1, 'first');
    if isempty(idx)
        error('Could not find Dynare coefficient variable %s in steady state output.', coeff_names{j});
    end
    coeff_values(j) = steady_state(idx);
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
