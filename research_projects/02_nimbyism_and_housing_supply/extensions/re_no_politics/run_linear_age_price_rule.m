function results = run_linear_age_price_rule()
% Estimate a simple linear forecast of log house prices on mean age.
% We repeatedly run one RE transition step, regress the implied path on
% mean age, and use the fitted line as the next expectation rule.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(baseline_dir);
addpath(this_dir);
ensure_external_matlab_data_paths();

demographic_path = build_demographic_path_from_age_state_csv(project_root);
[mean_age, target_age_masses] = compute_mean_age_path(demographic_path);

params = struct();
params.max_iter = 1;
params.tol = 1e-4;
params.rbPos = 0.03;
params.damping = 0.25;
params.max_update_frac = 0.10;
params.smoothing_weight = 5.00;
params.terminal_anchor_weight = 0.50;
params.targeted_correction_weight = 0.35;
params.max_targeted_periods = 3;
params.target_block_half_width = 1;
params.line_search_scales = [0.01, 0.02, 0.05];
params.update_scheme = 'sequential_blocks';
params.sequential_block_size = 3;
params.block_sweep_passes = 2;
params.max_blocks_per_pass = 4;
params.greedy_block_accept = true;
params.candidate_improvement_tol = 1e-6;
params.candidate_residual_slack = 5e-5;
params.terminal_price_rule = 'flat_tail';

baseline_price = 2.0;
params.supply_params = build_baseline_supply_anchor(params.rbPos, baseline_price);

T = numel(demographic_path.periods);
mean_age_centered = mean_age(:) - mean_age(1);
X = [ones(T, 1), mean_age_centered];

max_linear_iters = 10;
coeff_convergence_tol = 1e-4;
coef_update_weight = 0.5;
explosion_gap_threshold = 1.0;
explosion_rmse_threshold = 0.5;
price_floor = 0.5;
price_ceiling = 5.0;
coeffs = [log(baseline_price); 0.0];
last_stable_results_iter = struct();
stop_reason = "max_iter_reached";
iteration_history = repmat(struct( ...
    'iteration', NaN, ...
    'intercept', NaN, ...
    'slope', NaN, ...
    'raw_intercept', NaN, ...
    'raw_slope', NaN, ...
    'coef_change', NaN, ...
    'rmse', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_smoothed_gap', NaN, ...
    'price_guess_min', NaN, ...
    'price_guess_max', NaN, ...
    'stable_update', false), max_linear_iters, 1);

fprintf('Linear-age price-rule iterations:\n');
fprintf('  starting intercept = %.4f, slope = %.4f\n', coeffs(1), coeffs(2));

for iter = 1:max_linear_iters
    expected_log_price = coeffs(1) + coeffs(2) * mean_age_centered;
    price_path_guess = exp(expected_log_price);
    results_iter = solve_transition_re_no_politics(price_path_guess, demographic_path, params);

    implied_log_price = log(results_iter.implied_price_path(:));
    raw_coeffs = X \ implied_log_price;
    new_coeffs = (1 - coef_update_weight) .* coeffs + coef_update_weight .* raw_coeffs;
    next_price_path_guess = exp(new_coeffs(1) + new_coeffs(2) * mean_age_centered);
    coef_change = max(abs(new_coeffs - coeffs));
    rmse = sqrt(mean((implied_log_price - expected_log_price).^2));
    is_explosive = results_iter.update_diagnostics.max_abs_gap > explosion_gap_threshold || ...
        rmse > explosion_rmse_threshold || ...
        min(next_price_path_guess) < price_floor || ...
        max(next_price_path_guess) > price_ceiling;

    iteration_history(iter) = struct( ...
        'iteration', iter, ...
        'intercept', new_coeffs(1), ...
        'slope', new_coeffs(2), ...
        'raw_intercept', raw_coeffs(1), ...
        'raw_slope', raw_coeffs(2), ...
        'coef_change', coef_change, ...
        'rmse', rmse, ...
        'max_abs_gap', results_iter.update_diagnostics.max_abs_gap, ...
        'max_abs_smoothed_gap', results_iter.update_diagnostics.max_abs_smoothed_gap, ...
        'price_guess_min', min(next_price_path_guess), ...
        'price_guess_max', max(next_price_path_guess), ...
        'stable_update', ~is_explosive);

    fprintf('  iter %d: intercept = %.4f, slope = %.4f, raw intercept = %.4f, raw slope = %.4f, change = %.4f, RMSE = %.4f, max gap = %.4f\n', ...
        iter, new_coeffs(1), new_coeffs(2), raw_coeffs(1), raw_coeffs(2), coef_change, rmse, ...
        results_iter.update_diagnostics.max_abs_gap);

    if is_explosive
        stop_reason = sprintf('exploded_after_iter_%d', iter);
        fprintf('  stopping: %s (next price range %.4f to %.4f)\n', ...
            stop_reason, min(next_price_path_guess), max(next_price_path_guess));
        break;
    end

    last_stable_results_iter = results_iter;
    coeffs = new_coeffs;
    if coef_change < coeff_convergence_tol
        stop_reason = sprintf('converged_after_iter_%d', iter);
        break;
    end
end

iteration_history = iteration_history(1:iter);

final_expected_log = coeffs(1) + coeffs(2) * mean_age_centered;
final_predicted_price = exp(final_expected_log);
if isempty(fieldnames(last_stable_results_iter))
    final_implied_price = results_iter.implied_price_path(:);
else
    final_implied_price = last_stable_results_iter.implied_price_path(:);
end

summary_table = table( ...
    demographic_path.periods(:), ...
    demographic_path.years(:), ...
    mean_age(:), ...
    mean_age_centered(:), ...
    final_predicted_price, ...
    final_implied_price, ...
    final_predicted_price ./ final_implied_price, ...
    final_expected_log, ...
    log(final_implied_price), ...
    'VariableNames', { ...
    'period', 'year', 'mean_age', 'mean_age_centered', 'price_predicted', ...
    'price_implied', 'price_ratio', 'log_price_predicted', 'log_price_implied'});

iteration_table = struct2table(iteration_history);

summary_path = fullfile(this_dir, 'linear_age_price_rule_summary.csv');
iteration_path = fullfile(this_dir, 'linear_age_price_rule_iterations.csv');
results_path = fullfile(this_dir, 'linear_age_price_rule_results.mat');

writetable(summary_table, summary_path);
writetable(iteration_table, iteration_path);
save(results_path, 'results_iter', 'coeffs', 'mean_age', 'mean_age_centered', 'target_age_masses', ...
    'summary_table', 'iteration_history', 'demographic_path', 'stop_reason');

results = struct();
results.coeffs = coeffs;
results.mean_age = mean_age;
results.mean_age_centered = mean_age_centered;
results.target_age_masses = target_age_masses;
results.final_predicted_price = final_predicted_price;
results.final_implied_price = final_implied_price;
results.iteration_history = iteration_history;
results.summary_table = summary_table;
results.results_iter = results_iter;
results.stop_reason = stop_reason;

fprintf('Linear-age price rule complete: intercept = %.4f, slope = %.6f, stop = %s\n', coeffs(1), coeffs(2), stop_reason);
fprintf('Results saved in %s and %s.\n', summary_path, results_path);
end

function [mean_age, target_age_masses] = compute_mean_age_path(demographic_path)
baseline = demographic_path.cohort_scale_by_age(1, :);
baseline = baseline ./ sum(baseline);
target_age_masses = zeros(size(demographic_path.cohort_scale_by_age));
for t = 1:size(demographic_path.cohort_scale_by_age, 1)
    block = baseline .* demographic_path.cohort_scale_by_age(t, :);
    block = block ./ sum(block);
    target_age_masses(t, :) = block;
end

age_bins = demographic_path.age_bins_model(:);
mean_age = (target_age_masses * age_bins) ./ sum(target_age_masses, 2);
end

function supply_params = build_baseline_supply_anchor(rbPos, baseline_price)
solve_ss_no_politics([baseline_price, rbPos], struct()); %#ok<NASGU>
ss = load('SS_no_politics_iter.mat');

a = linspace(0, 25, size(ss.dens4, 2));
aa = ones(size(ss.dens4, 1), 1) * a;
aaaa = repmat(aa, 1, 1, size(ss.dens4, 3), size(ss.dens4, 4));
Hdemand = sum(aaaa .* ss.dens4, 'all');

supply_params = struct();
supply_params.Pbar = baseline_price;
supply_params.Hbar = max(Hdemand, 1e-8);
end
