function [summary, results] = run_original_5yr_joint_wedge_smoothed( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    wedge_floor, wedge_cap, k_schedule, housing_clear_max_iter, political_response_sigma, seed_wedge_csv_path, prefix_lock_length, stage_init_accept_mode, varargin)
% Short canonical entry point for the smoothed-politics branch.

if nargin < 16 || isempty(political_response_sigma)
    political_response_sigma = 0.05;
end
if nargin < 17 || isempty(seed_wedge_csv_path)
    seed_wedge_csv_path = '';
end
if nargin < 18 || isempty(prefix_lock_length)
    prefix_lock_length = 0;
end
if nargin < 19 || isempty(stage_init_accept_mode)
    stage_init_accept_mode = 'strict';
end
objective_horizon = 0;
if nargin >= 20 && ~isempty(varargin)
    objective_horizon = varargin{1};
end

if nargin < 5 || isempty(run_tag)
    run_tag = sprintf('joint_wedge_smoothpermits_k%d_i%d_b%d_s%0.3g', ...
        max_k, max_outer_iter, basis_count, political_response_sigma);
end

[summary, results] = run_original_5yr_transition_joint_supply_wedge_continuation( ...
    max_k, max_outer_iter, basis_count, seed_price_csv_path, run_tag, demographic_source_mode, ...
    finite_diff_step, ridge_lambda, candidate_scales, trust_region_log_step, active_threshold_frac, ...
    wedge_floor, wedge_cap, k_schedule, housing_clear_max_iter, ...
    'smooth_tanh', political_response_sigma, seed_wedge_csv_path, prefix_lock_length, stage_init_accept_mode, objective_horizon);

results.smoothed_politics = true;
results.political_response_mode = "smooth_tanh";
results.political_response_sigma = political_response_sigma;
results.prefix_lock_length = prefix_lock_length;
results.stage_init_accept_mode = string(stage_init_accept_mode);
results.objective_horizon = objective_horizon;
results.message = ['Joint supply-wedge continuation branch completed using a smooth permit-response rule ', ...
    'response = tanh((Vdp - V)/(2*sigma)).'];
end
