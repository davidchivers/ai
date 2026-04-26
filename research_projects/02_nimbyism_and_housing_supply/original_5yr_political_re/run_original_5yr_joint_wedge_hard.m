function [summary, results] = run_original_5yr_joint_wedge_hard( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    wedge_floor, wedge_cap, k_schedule, housing_clear_max_iter, seed_wedge_csv_path, prefix_lock_length)
% Entry point for the joint supply-wedge branch with the original hard vote.

if nargin < 16 || isempty(seed_wedge_csv_path)
    seed_wedge_csv_path = '';
end
if nargin < 17 || isempty(prefix_lock_length)
    prefix_lock_length = 0;
end

if nargin < 5 || isempty(run_tag)
    run_tag = sprintf('joint_wedge_hard_k%d_i%d_b%d', ...
        max_k, max_outer_iter, basis_count);
end

[summary, results] = run_original_5yr_transition_joint_supply_wedge_continuation( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    wedge_floor, wedge_cap, k_schedule, housing_clear_max_iter, ...
    'hard_sign', 0.05, seed_wedge_csv_path, prefix_lock_length);

results.smoothed_politics = false;
results.political_response_mode = "hard_sign";
results.prefix_lock_length = prefix_lock_length;
results.message = ['Joint supply-wedge continuation branch completed using the original hard political sign rule ', ...
    'and the selected demographic source.'];
end
