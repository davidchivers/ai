function results = solve_transition_re_no_politics(price_path_guess, demographic_path, params)
% Finite-horizon transition solver for a no-coalition RE price experiment.
% This first implementation solves the household problem for a guessed
% price path, simulates the cross-sectional distribution forward under an
% exogenous demographic age profile, and returns the implied price path.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');
if exist(baseline_dir, 'dir')
    addpath(baseline_dir, '-begin');
end

if nargin < 3 || isempty(params)
    params = struct();
end
if ~isfield(params, 'max_iter'), params.max_iter = 3; end
if ~isfield(params, 'tol'), params.tol = 1e-3; end
if ~isfield(params, 'damping'), params.damping = 0.25; end
if ~isfield(params, 'terminal_price_rule'), params.terminal_price_rule = 'flat_tail'; end
if ~isfield(params, 'terminal_reference_mode'), params.terminal_reference_mode = 'path_end_price'; end
if ~isfield(params, 'terminal_reference_price'), params.terminal_reference_price = NaN; end
if ~isfield(params, 'transition_policy_mode'), params.transition_policy_mode = 'full_backward'; end
if ~isfield(params, 'policy_reference_mode'), params.policy_reference_mode = 'path_current_prices'; end
if ~isfield(params, 'policy_reference_price'), params.policy_reference_price = NaN; end
if ~isfield(params, 'policy_reference_blend_weight'), params.policy_reference_blend_weight = NaN; end
if ~isfield(params, 'policy_reference_price_floor'), params.policy_reference_price_floor = NaN; end
if ~isfield(params, 'policy_reference_price_cap'), params.policy_reference_price_cap = NaN; end
if ~isfield(params, 'steady_state_reference_mode'), params.steady_state_reference_mode = 're_no_politics'; end
if ~isfield(params, 'rbPos'), params.rbPos = 0.03; end
if ~isfield(params, 'supply_params'), params.supply_params = struct(); end
if ~isfield(params.supply_params, 'eta_s'), params.supply_params.eta_s = 1.0; end
if ~isfield(params, 'supply_hbar_path'), params.supply_hbar_path = []; end
if ~isfield(params, 'supply_wedge_path'), params.supply_wedge_path = []; end
if ~isfield(params, 'supply_wedge_space'), params.supply_wedge_space = 'log'; end
if ~isfield(params, 'max_update_frac'), params.max_update_frac = 0.10; end
if ~isfield(params, 'smoothing_weight'), params.smoothing_weight = 5.00; end
if ~isfield(params, 'terminal_anchor_weight'), params.terminal_anchor_weight = 0.50; end
if ~isfield(params, 'targeted_correction_weight'), params.targeted_correction_weight = 0.35; end
if ~isfield(params, 'max_targeted_periods'), params.max_targeted_periods = 3; end
if ~isfield(params, 'target_block_half_width'), params.target_block_half_width = 1; end
if ~isfield(params, 'line_search_scales'), params.line_search_scales = [0.01, 0.02, 0.05, 0.10]; end
if ~isfield(params, 'update_scheme'), params.update_scheme = 'sequential_blocks'; end
if ~isfield(params, 'outer_iteration_mode'), params.outer_iteration_mode = 'candidate_search'; end
if ~isfield(params, 'fixed_point_relaxation_weight'), params.fixed_point_relaxation_weight = 0.40; end
if ~isfield(params, 'fixed_point_relaxation_space'), params.fixed_point_relaxation_space = 'level'; end
if ~isfield(params, 'fixed_point_price_min'), params.fixed_point_price_min = 0.40; end
if ~isfield(params, 'fixed_point_price_max'), params.fixed_point_price_max = 5.00; end
if ~isfield(params, 'sequential_block_size'), params.sequential_block_size = 3; end
if ~isfield(params, 'block_sweep_passes'), params.block_sweep_passes = 2; end
if ~isfield(params, 'max_blocks_per_pass'), params.max_blocks_per_pass = 4; end
if ~isfield(params, 'greedy_block_accept'), params.greedy_block_accept = true; end
if ~isfield(params, 'candidate_improvement_tol'), params.candidate_improvement_tol = 1e-6; end
if ~isfield(params, 'candidate_gap_improvement_tol'), params.candidate_gap_improvement_tol = 1e-6; end
if ~isfield(params, 'candidate_residual_slack'), params.candidate_residual_slack = 5e-5; end
if ~isfield(params, 'candidate_selection_mode'), params.candidate_selection_mode = 'global'; end
if ~isfield(params, 'focus_gap_improvement_tol'), params.focus_gap_improvement_tol = 1e-4; end
if ~isfield(params, 'focus_excess_improvement_tol'), params.focus_excess_improvement_tol = 1e-5; end
if ~isfield(params, 'focus_residual_slack'), params.focus_residual_slack = 2e-4; end
if ~isfield(params, 'sequential_return_endpoint'), params.sequential_return_endpoint = false; end
if ~isfield(params, 'save_candidate_history'), params.save_candidate_history = false; end
if ~isfield(params, 'save_period_details'), params.save_period_details = false; end
if ~isfield(params, 'save_outer_iteration_paths'), params.save_outer_iteration_paths = false; end
if ~isfield(params, 'save_current_path_pass'), params.save_current_path_pass = false; end
if ~isfield(params, 'compute_political_path'), params.compute_political_path = false; end
if ~isfield(params, 'save_political_details'), params.save_political_details = false; end
if ~isfield(params, 'trace_log_path'), params.trace_log_path = ''; end
if ~isfield(params, 'trace_label'), params.trace_label = 'solve_transition'; end
if ~isfield(params, 'political_response_mode'), params.political_response_mode = 'hard_sign'; end
if ~isfield(params, 'political_response_sigma'), params.political_response_sigma = 0.05; end
if ~isfield(params, 'coalition_params'), params.coalition_params = struct(); end
if ~isfield(params, 'housing_adjustment_mode'), params.housing_adjustment_mode = 'instant_market_clearing'; end
if ~isfield(params, 'housing_adjustment_weight'), params.housing_adjustment_weight = 1.0; end
if ~isfield(params, 'housing_adjustment_space'), params.housing_adjustment_space = 'log'; end
if ~isfield(params, 'housing_adjustment_anchor_price'), params.housing_adjustment_anchor_price = NaN; end

validateattributes(price_path_guess, {'double'}, {'vector', 'nonempty', 'finite', 'real', 'positive'}, mfilename, 'price_path_guess');
validateattributes(demographic_path, {'struct'}, {'scalar', 'nonempty'}, mfilename, 'demographic_path');
if ~isnan(params.policy_reference_price_floor)
    validateattributes(params.policy_reference_price_floor, {'double'}, {'scalar', 'finite', 'real', 'positive'}, ...
        mfilename, 'params.policy_reference_price_floor');
end
if ~isnan(params.policy_reference_price_cap)
    validateattributes(params.policy_reference_price_cap, {'double'}, {'scalar', 'finite', 'real', 'positive'}, ...
        mfilename, 'params.policy_reference_price_cap');
end
if ~isnan(params.policy_reference_blend_weight)
    validateattributes(params.policy_reference_blend_weight, {'double'}, {'scalar', 'finite', 'real', '>=', 0, '<=', 1}, ...
        mfilename, 'params.policy_reference_blend_weight');
end
if ~isnan(params.policy_reference_price_floor) && ~isnan(params.policy_reference_price_cap) && ...
        params.policy_reference_price_floor > params.policy_reference_price_cap
    error('params.policy_reference_price_floor cannot exceed params.policy_reference_price_cap.');
end

required_fields = {'periods'};
for i = 1:numel(required_fields)
    if ~isfield(demographic_path, required_fields{i})
        error('demographic_path must contain field %s.', required_fields{i});
    end
end

price_path_guess = price_path_guess(:);
periods = demographic_path.periods(:);

if isfield(demographic_path, 'cohort_scale_by_age')
    cohort_scale_by_age = demographic_path.cohort_scale_by_age;
    validateattributes(cohort_scale_by_age, {'double'}, {'2d', 'nrows', numel(price_path_guess), 'finite', 'real'}, ...
        mfilename, 'demographic_path.cohort_scale_by_age');
else
    error('demographic_path.cohort_scale_by_age is required for the transition solver.');
end

if numel(periods) ~= numel(price_path_guess)
    error('price_path_guess length must match demographic_path.periods length.');
end

validateattributes(params.max_iter, {'double'}, {'scalar', 'integer', '>=', 1}, mfilename, 'params.max_iter');
validateattributes(params.tol, {'double'}, {'scalar', 'positive'}, mfilename, 'params.tol');
validateattributes(params.housing_adjustment_weight, {'double'}, {'scalar', 'finite', 'real', '>=', 0, '<=', 1}, mfilename, 'params.housing_adjustment_weight');
validateattributes(params.fixed_point_relaxation_weight, {'double'}, {'scalar', '>', 0, '<=', 1}, mfilename, 'params.fixed_point_relaxation_weight');
validateattributes(params.fixed_point_price_min, {'double'}, {'scalar', 'positive'}, mfilename, 'params.fixed_point_price_min');
validateattributes(params.fixed_point_price_max, {'double'}, {'scalar', 'positive'}, mfilename, 'params.fixed_point_price_max');
validateattributes(params.political_response_sigma, {'double'}, {'scalar', 'finite', 'real', 'positive'}, mfilename, 'params.political_response_sigma');
if params.fixed_point_price_max <= params.fixed_point_price_min
    error('params.fixed_point_price_max must exceed params.fixed_point_price_min.');
end
if ~isnan(params.housing_adjustment_anchor_price)
    validateattributes(params.housing_adjustment_anchor_price, {'double'}, {'scalar', 'finite', 'real', 'positive'}, ...
        mfilename, 'params.housing_adjustment_anchor_price');
end

household_seed = solve_household_path_nimby( ...
    price_path_guess(1), ...
    struct(), ...
    struct('rbPos_path', params.rbPos, 'return_path_solution', false, 'return_tail_solution', false));
env = household_seed.core_env;
transition_matrix_path = household_seed.transition_matrix_path;
target_age_masses = build_target_age_masses(cohort_scale_by_age, demographic_path);

initial_reference = load_ss_reference(price_path_guess(1), params.rbPos, params.supply_params, params.steady_state_reference_mode);
params.supply_params = normalize_supply_params(params.supply_params, price_path_guess(1), initial_reference.Hdemand);
resolved_supply = resolve_supply_path_local(params, numel(price_path_guess));
params.supply_hbar_path = resolved_supply.hbar_path;
params.supply_wedge_path = resolved_supply.wedge_path;
initial_density = build_initial_density(initial_reference.dens4, target_age_masses(1, :));
append_transition_trace_local(params, sprintf('event=solve_start label=%s T=%d max_iter=%d political_mode=%s sigma=%.6g', ...
    sanitize_transition_trace_local(params.trace_label), numel(price_path_guess), params.max_iter, ...
    char(string(params.political_response_mode)), params.political_response_sigma));

current_price_path = price_path_guess;
run_cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
iteration_log = repmat(struct( ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'accepted_update', "", ...
    'worst_gap_period', NaN, ...
    'worst_excess_demand_period', NaN, ...
    'worst_excess_demand', NaN), params.max_iter, 1);
if params.save_outer_iteration_paths
    iteration_current_price_paths = NaN(params.max_iter, numel(price_path_guess));
    iteration_base_implied_price_paths = NaN(params.max_iter, numel(price_path_guess));
    iteration_selected_price_paths = NaN(params.max_iter, numel(price_path_guess));
else
    iteration_current_price_paths = [];
    iteration_base_implied_price_paths = [];
    iteration_selected_price_paths = [];
end
selection_diagnostics = cell(params.max_iter, 1);
last_run = struct();
last_current_run = struct();

for iter = 1:params.max_iter
    append_transition_trace_local(params, sprintf('event=solve_iter_start label=%s iter=%d price_first=%.12g price_last=%.12g', ...
        sanitize_transition_trace_local(params.trace_label), iter, current_price_path(1), current_price_path(end)));
    [base_run, run_cache] = run_transition_pass(current_price_path, initial_density, target_age_masses, ...
        env, params, run_cache);
    append_transition_trace_local(params, sprintf('event=solve_iter_after_pass label=%s iter=%d residual_norm=%.12g max_abs_gap=%.12g', ...
        sanitize_transition_trace_local(params.trace_label), iter, base_run.residual_norm, base_run.max_abs_gap));
    if params.save_outer_iteration_paths
        iteration_current_price_paths(iter, :) = current_price_path(:)';
        iteration_base_implied_price_paths(iter, :) = base_run.implied_price_path(:)';
    end
    [updated_price_path, diagnostics] = update_price_path_re_no_politics( ...
        current_price_path, base_run.implied_price_path, params);

    current_run = base_run;
    current_run.label = "current_path";
    last_current_run = current_run;

    selected_run = current_run;
    selected_price_path = current_price_path;
    iteration_detail = initialize_iteration_selection_detail(iter, current_run, diagnostics, params);

    if use_current_path_only_outer_loop(params)
        selected_run = current_run;
        selected_run.label = "current_path_only";
        selected_price_path = current_price_path;
        iteration_detail.sequential = struct([]);
    elseif use_fertility_style_outer_loop(params)
        selected_price_path = build_fertility_style_price_update(current_price_path, base_run.implied_price_path, params);
        [selected_run, run_cache] = run_transition_pass(selected_price_path, initial_density, target_age_masses, ...
            env, params, run_cache);
        selected_run.label = "fertility_style_relaxation";
        iteration_detail.sequential = struct([]);
    else
        [full_update_run, run_cache] = run_transition_pass(updated_price_path, initial_density, target_age_masses, ...
            env, params, run_cache);
        full_update_run.label = "regularized_full_update";
        if params.save_candidate_history
            full_update_focus_periods = find_focus_periods(current_run, diagnostics);
            full_update_assessment = assess_candidate_selection(full_update_run, selected_run, full_update_focus_periods, params);
            iteration_detail.initial_candidates = append_candidate_detail( ...
                iteration_detail.initial_candidates, full_update_run, selected_run, full_update_focus_periods, ...
                full_update_assessment, struct('stage', "initial_regularized_full", 'pass', 0, ...
                'block_start', NaN, 'block_stop', NaN, 'scale', NaN, 'became_best', full_update_assessment.sequential_wins, ...
                'accepted_greedily', false));
        end
        if is_better_candidate(full_update_run, selected_run, params)
            selected_run = full_update_run;
            selected_price_path = updated_price_path;
        end

        if strcmp(params.update_scheme, 'sequential_blocks')
            [selected_run, selected_price_path, iteration_detail.sequential] = try_sequential_block_candidates( ...
                initial_density, target_age_masses, ...
                env, params, selected_run, selected_price_path, run_cache);
        else
            [selected_run, selected_price_path] = try_line_search_candidates( ...
                current_price_path, diagnostics.log_update_step, diagnostics.targeted_blocks, ...
                initial_density, target_age_masses, env, params, selected_run, selected_price_path, run_cache);
            iteration_detail.sequential = struct([]);
        end
    end

    selected_run.sim.Hsupply_updated_path = compute_supply_path(selected_price_path, params.supply_params, params.supply_hbar_path);
    selected_run.sim.excess_demand_updated_path = selected_run.sim.Hdemand_path - selected_run.sim.Hsupply_updated_path;
    selected_run.sim.log_price_residual_smoothed = log(diagnostics.smoothed_implied_price_path) - log(current_price_path);

    iteration_log(iter).residual_norm = selected_run.residual_norm;
    iteration_log(iter).max_abs_gap = selected_run.max_abs_gap;
    iteration_log(iter).max_abs_update = max(abs(selected_price_path - current_price_path));
    iteration_log(iter).accepted_update = selected_run.label;
    [~, iteration_log(iter).worst_gap_period] = max(abs(selected_run.sim.log_price_residual_raw));
    [iteration_log(iter).worst_excess_demand, iteration_log(iter).worst_excess_demand_period] = ...
        max(abs(selected_run.sim.excess_demand_guess_path));
    append_transition_trace_local(params, sprintf('event=solve_iter_after_select label=%s iter=%d accepted_update=%s selected_gap=%.12g selected_residual=%.12g', ...
        sanitize_transition_trace_local(params.trace_label), iter, sanitize_transition_trace_local(selected_run.label), ...
        selected_run.max_abs_gap, selected_run.residual_norm));
    if params.save_outer_iteration_paths
        iteration_selected_price_paths(iter, :) = selected_price_path(:)';
    end

    last_run = struct();
    last_run.policy_idx_b = selected_run.policy_idx_b;
    last_run.policy_idx_a = selected_run.policy_idx_a;
    last_run.valuefunctions = selected_run.valuefunctions;
    last_run.sim = selected_run.sim;
    last_run.implied_price_path = selected_run.implied_price_path;
    last_run.terminal_reference_price_used = selected_run.terminal_reference_price_used;
    last_run.policy_reference_price_path_used = selected_run.policy_reference_price_path_used;
    last_run.updated_price_path = selected_price_path;
    last_run.update_diagnostics = diagnostics;
    last_run.update_diagnostics.max_abs_gap = selected_run.max_abs_gap;
    last_run.update_diagnostics.max_abs_smoothed_gap = selected_run.max_abs_gap;
    last_run.update_diagnostics.accepted_update = selected_run.label;
    if use_current_path_only_outer_loop(params)
        last_run.update_diagnostics.fixed_point_price_path = selected_price_path;
        last_run.update_diagnostics.current_path_only = true;
    elseif use_fertility_style_outer_loop(params)
        last_run.update_diagnostics.fixed_point_price_path = selected_price_path;
        last_run.update_diagnostics.fixed_point_relaxation_weight = params.fixed_point_relaxation_weight;
    end
    if params.save_candidate_history
        iteration_detail.final_selected_label = string(selected_run.label);
        iteration_detail.final_residual_norm = selected_run.residual_norm;
        iteration_detail.final_max_abs_gap = selected_run.max_abs_gap;
        selection_diagnostics{iter} = iteration_detail;
    end

    current_price_path = selected_price_path;
    if selected_run.max_abs_gap < params.tol
        append_transition_trace_local(params, sprintf('event=solve_converged label=%s iter=%d final_gap=%.12g', ...
            sanitize_transition_trace_local(params.trace_label), iter, selected_run.max_abs_gap));
        break;
    end
end

results = struct();
results.placeholder = false;
results.converged = last_run.update_diagnostics.max_abs_gap < params.tol;
results.iterations = find(~isnan([iteration_log.max_abs_gap]), 1, 'last');
results.price_path_guess = price_path_guess;
results.final_price_path = current_price_path;
results.implied_price_path = last_run.implied_price_path;
results.updated_price_path = last_run.updated_price_path;
results.terminal_reference_price_used = last_run.terminal_reference_price_used;
results.policy_reference_price_path_used = last_run.policy_reference_price_path_used;
results.demographic_path = demographic_path;
results.cohort_scale = mean(cohort_scale_by_age, 2);
results.cohort_scale_by_age = cohort_scale_by_age;
results.target_age_masses = target_age_masses;
results.params = params;
results.transition_matrix_path = transition_matrix_path;
if use_current_path_only_outer_loop(params)
    results.message = 'Transition solver evaluated the supplied price path without an inner price update.';
elseif use_fertility_style_outer_loop(params)
    results.message = 'Transition solver completed backward-forward passes with fertility-style full-path relaxation.';
else
    results.message = 'Transition solver completed a backward-forward pass and updated the price path.';
end
results.update_diagnostics = last_run.update_diagnostics;
results.iteration_log = iteration_log(1:results.iterations);
results.policy_idx_b = last_run.policy_idx_b;
results.policy_idx_a = last_run.policy_idx_a;
results.valuefunctions = last_run.valuefunctions;
if params.save_outer_iteration_paths
    results.iteration_current_price_paths = iteration_current_price_paths(1:results.iterations, :);
    results.iteration_base_implied_price_paths = iteration_base_implied_price_paths(1:results.iterations, :);
    results.iteration_selected_price_paths = iteration_selected_price_paths(1:results.iterations, :);
end
if params.save_candidate_history
    results.selection_diagnostics = selection_diagnostics(1:results.iterations);
end
results.Hdemand_path = last_run.sim.Hdemand_path;
results.Hsupply_path = last_run.sim.Hsupply_updated_path;
results.supply_hbar_path = params.supply_hbar_path(:);
results.supply_wedge_path = params.supply_wedge_path(:);
results.excess_demand_path = last_run.sim.excess_demand_updated_path;
results.excess_demand_guess_path = last_run.sim.excess_demand_guess_path;
results.log_price_residual_raw = last_run.sim.log_price_residual_raw;
results.log_price_residual_smoothed = last_run.sim.log_price_residual_smoothed;
results.debt_path = last_run.sim.debt_path;
results.rent_share_path = last_run.sim.rent_share_path;
if isfield(last_run.sim, 'political')
    results.political = last_run.sim.political;
end
append_transition_trace_local(params, sprintf('event=solve_done label=%s iterations=%d converged=%d final_gap=%.12g final_residual=%.12g', ...
    sanitize_transition_trace_local(params.trace_label), results.iterations, results.converged, ...
    last_run.update_diagnostics.max_abs_gap, results.iteration_log(end).residual_norm));
results.period_diagnostics = struct( ...
    'Hdemand_path', last_run.sim.Hdemand_path, ...
    'Hsupply_guess_path', last_run.sim.Hsupply_guess_path, ...
    'Hsupply_updated_path', last_run.sim.Hsupply_updated_path, ...
    'excess_demand_guess_path', last_run.sim.excess_demand_guess_path, ...
    'excess_demand_updated_path', last_run.sim.excess_demand_updated_path, ...
    'instant_implied_price_path', last_run.sim.instant_implied_price_path, ...
    'implied_price_path_raw', last_run.implied_price_path, ...
    'implied_price_path_smoothed', last_run.update_diagnostics.smoothed_implied_price_path, ...
    'log_price_residual_raw', last_run.sim.log_price_residual_raw, ...
    'log_price_residual_smoothed', last_run.sim.log_price_residual_smoothed, ...
    'housing_adjustment', last_run.sim.housing_adjustment, ...
    'supply_hbar_path', params.supply_hbar_path(:), ...
    'supply_wedge_path', params.supply_wedge_path(:), ...
    'targeted_periods', last_run.update_diagnostics.targeted_periods, ...
    'targeted_blocks', last_run.update_diagnostics.targeted_blocks);
if isfield(last_run.sim, 'political')
    results.period_diagnostics.equal_weight_vote_path = last_run.sim.political.equal_weight_vote_path;
    results.period_diagnostics.weighted_vote_path = last_run.sim.political.weighted_vote_path;
end
if params.save_period_details
    results.density_by_period_age = last_run.sim.density_by_period_age;
end
if params.save_current_path_pass
    results.current_path_pass = last_current_run;
end

function append_transition_trace_local(params, line_text)
if ~isfield(params, 'trace_log_path') || isempty(params.trace_log_path)
    return;
end

trace_dir = fileparts(params.trace_log_path);
if ~exist(trace_dir, 'dir')
    mkdir(trace_dir);
end

fid = fopen(params.trace_log_path, 'a');
if fid < 0
    return;
end
cleanup = onCleanup(@() fclose(fid));
timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
fprintf(fid, '[%s] %s\n', timestamp, line_text);
end

function text = sanitize_transition_trace_local(text)
text = char(string(text));
text = regexprep(text, '\s+', '_');
text = regexprep(text, '[^A-Za-z0-9_\.\-\=]+', '_');
end

function tf = use_fertility_style_outer_loop(params)
tf = strcmpi(string(params.outer_iteration_mode), "fertility_style");
end

function tf = use_current_path_only_outer_loop(params)
mode = lower(string(params.outer_iteration_mode));
tf = mode == "evaluate_current_path" || mode == "current_path_only";
end

function updated_price_path = build_fertility_style_price_update(current_price_path, implied_price_path, params)
weight = params.fixed_point_relaxation_weight;
if strcmpi(string(params.fixed_point_relaxation_space), "log")
    log_current = log(max(current_price_path(:), 1e-8));
    log_implied = log(max(implied_price_path(:), 1e-8));
    updated_price_path = exp((1 - weight) .* log_current + weight .* log_implied);
else
    updated_price_path = (1 - weight) .* current_price_path(:) + weight .* implied_price_path(:);
end
updated_price_path = min(max(updated_price_path, params.fixed_point_price_min), params.fixed_point_price_max);
end

function [run, run_cache] = run_transition_pass(price_path, initial_density, target_age_masses, env, params, run_cache)
cache_key = build_transition_pass_cache_key(price_path, params);
if isKey(run_cache, cache_key)
    run = run_cache(cache_key);
    return;
end

policy_mode = lower(string(params.transition_policy_mode));
terminal_reference_price = NaN;
policy_reference_price_path = NaN(size(price_path));
preference_sign_by_period_age = [];
preference_value_by_period_age = [];

switch policy_mode
    case "full_backward"
        terminal_reference_price = resolve_terminal_reference_price(price_path, params);
        terminal_reference = load_ss_reference(terminal_reference_price, params.rbPos, params.supply_params, params.steady_state_reference_mode);
        household_results = solve_household_path_nimby( ...
            price_path, ...
            struct(), ...
            struct( ...
                'rbPos_path', params.rbPos, ...
                'environment', env, ...
                'tail_solution', terminal_reference.household_tail_solution, ...
                'compute_price_preference', params.compute_political_path, ...
                'return_path_solution', true, ...
                'return_tail_solution', false));
        policy_idx_b = household_results.path_solution.index_b;
        policy_idx_a = household_results.path_solution.index_a;
        valuefunctions = household_results.path_solution.value;
        if params.compute_political_path
            preference_sign_by_period_age = household_results.price_preference.path_preference_sign;
            preference_value_by_period_age = household_results.price_preference.path_value_difference;
        end
    case "steady_state_by_period_price"
        if params.compute_political_path
            error('params.compute_political_path is currently supported only for params.transition_policy_mode = ''full_backward''.');
        end
        price_reference_path = resolve_policy_reference_price_path(price_path, params);
        [policy_idx_b, policy_idx_a, valuefunctions, policy_reference_price_path] = ...
            build_policy_path_from_ss_prices(price_reference_path, params, env.age_n);
    case "steady_state_fixed_price"
        if params.compute_political_path
            error('params.compute_political_path is currently supported only for params.transition_policy_mode = ''full_backward''.');
        end
        fixed_policy_price = resolve_policy_reference_price(price_path, params);
        fixed_price_path = fixed_policy_price .* ones(size(price_path));
        [policy_idx_b, policy_idx_a, valuefunctions, policy_reference_price_path] = ...
            build_policy_path_from_ss_prices(fixed_price_path, params, env.age_n);
    otherwise
        error('Unsupported params.transition_policy_mode: %s', params.transition_policy_mode);
end

store_density_by_period_age = params.save_period_details || params.compute_political_path;
sim = simulate_forward_transition(policy_idx_b, policy_idx_a, initial_density, ...
    target_age_masses, env, store_density_by_period_age);

if params.compute_political_path
    sim.political = compute_transition_political_path_local( ...
        sim.density_by_period_age, preference_sign_by_period_age, preference_value_by_period_age, ...
        env, price_path, params.coalition_params, params.save_political_details, ...
        params.political_response_mode, params.political_response_sigma);
    if ~params.save_period_details
        sim = rmfield(sim, 'density_by_period_age');
    end
end

instant_implied_price_path = invert_supply_path(sim.Hdemand_path, params.supply_params, params.supply_hbar_path);
[implied_price_path, housing_adjustment] = apply_housing_adjustment_path_local(instant_implied_price_path, price_path, params);
sim.Hsupply_guess_path = compute_supply_path(price_path, params.supply_params, params.supply_hbar_path);
sim.excess_demand_guess_path = sim.Hdemand_path - sim.Hsupply_guess_path;
sim.instant_implied_price_path = instant_implied_price_path;
sim.housing_adjustment = housing_adjustment;
sim.log_price_residual_raw = log(implied_price_path) - log(price_path);

run = struct();
run.policy_idx_b = policy_idx_b;
run.policy_idx_a = policy_idx_a;
run.valuefunctions = valuefunctions;
run.sim = sim;
run.implied_price_path = implied_price_path;
run.max_abs_gap = max(abs(implied_price_path - price_path));
run.residual_norm = norm(log(implied_price_path) - log(price_path));
run.terminal_reference_price_used = terminal_reference_price;
run.policy_reference_price_path_used = policy_reference_price_path;
run_cache(cache_key) = run;
end

function cache_key = build_transition_pass_cache_key(price_path, params)
terminal_mode = lower(string(params.terminal_reference_mode));
terminal_fixed_price = NaN;
if strcmp(terminal_mode, "fixed_price")
    terminal_fixed_price = params.terminal_reference_price;
end
policy_mode = lower(string(params.transition_policy_mode));
policy_ref_mode = lower(string(params.policy_reference_mode));
policy_fixed_price = NaN;
if strcmp(policy_ref_mode, "fixed_price")
    policy_fixed_price = params.policy_reference_price;
end
policy_blend_weight = params.policy_reference_blend_weight;
policy_price_floor = params.policy_reference_price_floor;
policy_price_cap = params.policy_reference_price_cap;
housing_adjustment_mode = lower(string(params.housing_adjustment_mode));
housing_adjustment_space = lower(string(params.housing_adjustment_space));
housing_adjustment_weight = params.housing_adjustment_weight;
housing_adjustment_anchor_price = params.housing_adjustment_anchor_price;
price_key = sprintf('%.8f_', price_path);
cache_key = sprintf(['terminal=%s|terminal_fixed=%.8f|policy=%s|policy_ref=%s|policy_fixed=%.8f|' ...
    'policy_blend=%.8f|policy_floor=%.8f|policy_cap=%.8f|housing_mode=%s|housing_space=%s|' ...
    'housing_weight=%.8f|housing_anchor=%.8f|political_mode=%s|political_sigma=%.8f|path=%s'], ...
    terminal_mode, terminal_fixed_price, policy_mode, policy_ref_mode, policy_fixed_price, ...
    policy_blend_weight, policy_price_floor, policy_price_cap, housing_adjustment_mode, housing_adjustment_space, ...
    housing_adjustment_weight, housing_adjustment_anchor_price, lower(string(params.political_response_mode)), ...
    params.political_response_sigma, price_key);
end

function [best_run, best_price_path] = try_line_search_candidates(current_price_path, log_update_step, targeted_blocks, ...
    initial_density, target_age_masses, env, params, best_run, best_price_path, run_cache)

log_current = log(current_price_path);
scales = params.line_search_scales(:)';

for scale = scales
    full_candidate_price_path = exp(log_current + scale .* log_update_step);
    [full_candidate_run, run_cache] = run_transition_pass(full_candidate_price_path, initial_density, target_age_masses, ...
        env, params, run_cache);
    full_candidate_run.label = sprintf('full_path_%.2f', scale);

    if is_better_candidate(full_candidate_run, best_run, params)
        best_run = full_candidate_run;
        best_price_path = full_candidate_price_path;
    end

    if isempty(targeted_blocks)
        continue;
    end

    block_candidate_price_path = current_price_path;
    scaled_candidate_price_path = full_candidate_price_path;
    for block_idx = 1:size(targeted_blocks, 1)
        left = targeted_blocks(block_idx, 1);
        right = targeted_blocks(block_idx, 2);
        block_candidate_price_path(left:right) = scaled_candidate_price_path(left:right);
    end

    [block_candidate_run, run_cache] = run_transition_pass(block_candidate_price_path, initial_density, target_age_masses, ...
        env, params, run_cache);
    block_candidate_run.label = sprintf('targeted_block_%.2f', scale);

    if is_better_candidate(block_candidate_run, best_run, params)
        best_run = block_candidate_run;
        best_price_path = block_candidate_price_path;
    end
end
end

function [best_run, best_price_path, sequential_detail] = try_sequential_block_candidates( ...
    initial_density, target_age_masses, env, params, best_run, best_price_path, run_cache)

T = numel(best_price_path);
block_size = min(params.sequential_block_size, T);
current_candidate_price_path = best_price_path;
current_candidate_run = best_run;
sequential_detail = initialize_sequential_detail(current_candidate_run, params);
if ~isfield(current_candidate_run, 'label')
    current_candidate_run.label = "current_path";
end

for pass = 1:params.block_sweep_passes
    [pass_updated_price_path, pass_diagnostics] = update_price_path_re_no_politics( ...
        current_candidate_price_path, current_candidate_run.implied_price_path, params);
    focus_periods = find_focus_periods(current_candidate_run, pass_diagnostics);
    block_starts = build_block_start_order(focus_periods, T, block_size, params.max_blocks_per_pass);
    log_current = log(current_candidate_price_path);
    log_step = pass_diagnostics.log_update_step;

    pass_best_run = current_candidate_run;
    pass_best_price_path = current_candidate_price_path;
    accepted_in_pass = false;
    pass_detail = initialize_pass_detail(pass, current_candidate_run, focus_periods, block_starts, pass_diagnostics);

    [full_candidate_run, run_cache] = run_transition_pass(pass_updated_price_path, initial_density, target_age_masses, ...
        env, params, run_cache);
    full_candidate_run.label = sprintf('regularized_full_p%d', pass);
    full_assessment = assess_candidate_selection(full_candidate_run, pass_best_run, focus_periods, params);
    if params.save_candidate_history
        pass_detail.candidate_evaluations = append_candidate_detail( ...
            pass_detail.candidate_evaluations, full_candidate_run, pass_best_run, focus_periods, full_assessment, ...
            struct('stage', "sequential_regularized_full", 'pass', pass, 'block_start', NaN, 'block_stop', NaN, ...
            'scale', NaN, 'became_best', full_assessment.sequential_wins, ...
            'accepted_greedily', params.greedy_block_accept && full_assessment.greedy_sequential));
    end
    if full_assessment.sequential_wins
        pass_best_run = full_candidate_run;
        pass_best_price_path = pass_updated_price_path;
        if params.greedy_block_accept && full_assessment.greedy_sequential
            accepted_in_pass = true;
            pass_detail.greedy_accept_label = string(full_candidate_run.label);
        end
    end

    if ~accepted_in_pass
        for start_idx = block_starts
            stop_idx = min(T, start_idx + block_size - 1);
            block = start_idx:stop_idx;

            for scale = params.line_search_scales(:)'
                candidate_price_path = current_candidate_price_path;
                candidate_log_block = log_current(block) + scale .* log_step(block);
                candidate_price_path(block) = exp(candidate_log_block);

                [candidate_run, run_cache] = run_transition_pass(candidate_price_path, initial_density, target_age_masses, ...
                    env, params, run_cache);
                candidate_run.label = sprintf('sequential_block_p%d_%d_%d_%.2f', pass, start_idx, stop_idx, scale);

                candidate_assessment = assess_candidate_selection(candidate_run, pass_best_run, focus_periods, params);
                if params.save_candidate_history
                    pass_detail.candidate_evaluations = append_candidate_detail( ...
                        pass_detail.candidate_evaluations, candidate_run, pass_best_run, focus_periods, candidate_assessment, ...
                        struct('stage', "sequential_block", 'pass', pass, 'block_start', start_idx, 'block_stop', stop_idx, ...
                        'scale', scale, 'became_best', candidate_assessment.sequential_wins, ...
                        'accepted_greedily', params.greedy_block_accept && candidate_assessment.greedy_sequential));
                end

                if candidate_assessment.sequential_wins
                    pass_best_run = candidate_run;
                    pass_best_price_path = candidate_price_path;
                    if params.greedy_block_accept && candidate_assessment.greedy_sequential
                        accepted_in_pass = true;
                        pass_detail.greedy_accept_label = string(candidate_run.label);
                        break;
                    end
                end
            end

            if accepted_in_pass
                break;
            end
        end
    end

    pass_detail.selected_label = string(pass_best_run.label);
    pass_detail.selected_residual_norm = pass_best_run.residual_norm;
    pass_detail.selected_max_abs_gap = pass_best_run.max_abs_gap;
    pass_detail.accepted_in_pass = accepted_in_pass;

    if is_better_candidate(pass_best_run, best_run, params)
        best_run = pass_best_run;
        best_price_path = pass_best_price_path;
    end

    if params.save_candidate_history
        sequential_detail.passes = append_pass_detail(sequential_detail.passes, pass_detail);
    end

    if strcmp(pass_best_run.label, current_candidate_run.label)
        break;
    end

    current_candidate_run = pass_best_run;
    current_candidate_price_path = pass_best_price_path;
end

if params.sequential_return_endpoint
    best_run = current_candidate_run;
    best_price_path = current_candidate_price_path;
end
if params.save_candidate_history
    sequential_detail.final_label = string(best_run.label);
    sequential_detail.final_residual_norm = best_run.residual_norm;
    sequential_detail.final_max_abs_gap = best_run.max_abs_gap;
else
    sequential_detail = struct([]);
end
end

function focus_periods = find_focus_periods(current_candidate_run, diagnostics)
[~, worst_gap_period] = max(abs(current_candidate_run.sim.log_price_residual_raw));
[~, worst_excess_period] = max(abs(current_candidate_run.sim.excess_demand_guess_path));

focus_periods = unique([ ...
    diagnostics.targeted_periods(:); ...
    worst_gap_period; ...
    worst_excess_period], 'stable');
end

function block_starts = build_block_start_order(targeted_periods, T, block_size, max_blocks_per_pass)
base_starts = 1:block_size:T;
core_starts = zeros(0, 1);
neighbor_starts = zeros(0, 1);
for i = 1:numel(targeted_periods)
    start_idx = max(1, min(T - block_size + 1, targeted_periods(i) - floor((block_size - 1) / 2)));
    core_starts(end + 1, 1) = start_idx; %#ok<AGROW>
    if start_idx - block_size >= 1
        neighbor_starts(end + 1, 1) = start_idx - block_size; %#ok<AGROW>
    end
    if start_idx + block_size <= T - block_size + 1
        neighbor_starts(end + 1, 1) = start_idx + block_size; %#ok<AGROW>
    end
end

core_starts = unique(sort(core_starts), 'stable');
neighbor_starts = unique(sort(neighbor_starts), 'stable');
block_starts = unique([core_starts; neighbor_starts; base_starts(:)], 'stable')';
if nargin >= 4 && max_blocks_per_pass > 0 && numel(block_starts) > max_blocks_per_pass
    block_starts = block_starts(1:max_blocks_per_pass);
end
end

function detail = initialize_iteration_selection_detail(iter, current_run, diagnostics, params)
detail = struct( ...
    'iteration', iter, ...
    'candidate_selection_mode', candidate_selection_mode(params), ...
    'current_label', string(current_run.label), ...
    'current_residual_norm', current_run.residual_norm, ...
    'current_max_abs_gap', current_run.max_abs_gap, ...
    'targeted_periods', diagnostics.targeted_periods(:)', ...
    'targeted_blocks', diagnostics.targeted_blocks, ...
    'initial_candidates', repmat(candidate_detail_template(), 0, 1), ...
    'sequential', struct([]), ...
    'final_selected_label', "", ...
    'final_residual_norm', NaN, ...
    'final_max_abs_gap', NaN);
end

function detail = initialize_sequential_detail(current_run, params)
if ~params.save_candidate_history
    detail = struct([]);
    return;
end

detail = struct( ...
    'selection_mode', candidate_selection_mode(params), ...
    'start_label', string(current_run.label), ...
    'passes', repmat(pass_detail_template(), 0, 1), ...
    'final_label', "", ...
    'final_residual_norm', NaN, ...
    'final_max_abs_gap', NaN);
end

function detail = initialize_pass_detail(pass, current_run, focus_periods, block_starts, diagnostics)
detail = pass_detail_template();
detail.pass = pass;
detail.start_label = string(current_run.label);
detail.focus_periods = focus_periods(:)';
detail.targeted_periods = diagnostics.targeted_periods(:)';
detail.targeted_blocks = diagnostics.targeted_blocks;
detail.block_starts = block_starts(:)';
end

function detail = candidate_detail_template()
detail = struct( ...
    'stage', "", ...
    'pass', NaN, ...
    'candidate_label', "", ...
    'incumbent_label', "", ...
    'block_start', NaN, ...
    'block_stop', NaN, ...
    'scale', NaN, ...
    'focus_periods', zeros(1, 0), ...
    'candidate_residual_norm', NaN, ...
    'candidate_max_abs_gap', NaN, ...
    'candidate_focus_gap', NaN, ...
    'candidate_focus_excess', NaN, ...
    'incumbent_residual_norm', NaN, ...
    'incumbent_max_abs_gap', NaN, ...
    'incumbent_focus_gap', NaN, ...
    'incumbent_focus_excess', NaN, ...
    'wins_focus', false, ...
    'wins_global', false, ...
    'wins_sequential', false, ...
    'greedy_global', false, ...
    'greedy_sequential', false, ...
    'selection_reason', "", ...
    'greedy_reason', "", ...
    'became_best', false, ...
    'accepted_greedily', false);
end

function detail = pass_detail_template()
detail = struct( ...
    'pass', NaN, ...
    'start_label', "", ...
    'focus_periods', zeros(1, 0), ...
    'targeted_periods', zeros(1, 0), ...
    'targeted_blocks', zeros(0, 2), ...
    'block_starts', zeros(1, 0), ...
    'candidate_evaluations', repmat(candidate_detail_template(), 0, 1), ...
    'selected_label', "", ...
    'selected_residual_norm', NaN, ...
    'selected_max_abs_gap', NaN, ...
    'accepted_in_pass', false, ...
    'greedy_accept_label', "");
end

function details = append_candidate_detail(details, candidate_run, incumbent_run, focus_periods, assessment, meta)
entry = candidate_detail_template();
entry.stage = string(meta.stage);
entry.pass = meta.pass;
entry.candidate_label = string(candidate_run.label);
entry.incumbent_label = string(incumbent_run.label);
entry.block_start = meta.block_start;
entry.block_stop = meta.block_stop;
entry.scale = meta.scale;
entry.focus_periods = focus_periods(:)';
entry.candidate_residual_norm = candidate_run.residual_norm;
entry.candidate_max_abs_gap = candidate_run.max_abs_gap;
entry.candidate_focus_gap = assessment.candidate_focus_gap;
entry.candidate_focus_excess = assessment.candidate_focus_excess;
entry.incumbent_residual_norm = incumbent_run.residual_norm;
entry.incumbent_max_abs_gap = incumbent_run.max_abs_gap;
entry.incumbent_focus_gap = assessment.incumbent_focus_gap;
entry.incumbent_focus_excess = assessment.incumbent_focus_excess;
entry.wins_focus = assessment.wins_focus;
entry.wins_global = assessment.wins_global;
entry.wins_sequential = assessment.sequential_wins;
entry.greedy_global = assessment.greedy_global;
entry.greedy_sequential = assessment.greedy_sequential;
entry.selection_reason = assessment.sequential_reason;
entry.greedy_reason = assessment.greedy_reason;
entry.became_best = meta.became_best;
entry.accepted_greedily = meta.accepted_greedily;
details(end + 1, 1) = entry; %#ok<AGROW>
end

function details = append_pass_detail(details, pass_detail)
details(end + 1, 1) = pass_detail; %#ok<AGROW>
end

function tf = is_better_sequential_candidate(candidate_run, incumbent_run, focus_periods, params)
assessment = assess_candidate_selection(candidate_run, incumbent_run, focus_periods, params);
tf = assessment.sequential_wins;
end

function tf = improves_sequential_enough(candidate_run, incumbent_run, focus_periods, params)
assessment = assess_candidate_selection(candidate_run, incumbent_run, focus_periods, params);
tf = assessment.greedy_sequential;
end

function mode = candidate_selection_mode(params)
mode = string(params.candidate_selection_mode);
end

function assessment = assess_candidate_selection(candidate_run, incumbent_run, focus_periods, params)
mode = candidate_selection_mode(params);
[candidate_focus_gap, candidate_focus_excess] = focus_metrics(candidate_run, focus_periods);
[incumbent_focus_gap, incumbent_focus_excess] = focus_metrics(incumbent_run, focus_periods);

wins_focus = improves_focus_metric(candidate_run, incumbent_run, focus_periods, params);
wins_global = is_better_candidate(candidate_run, incumbent_run, params);
greedy_global = improves_enough(candidate_run, incumbent_run, params);

if strcmp(mode, "focus")
    sequential_wins = wins_focus;
    greedy_sequential = wins_focus;
elseif strcmp(mode, "hybrid_focus")
    sequential_wins = wins_focus || wins_global;
    greedy_sequential = wins_focus || greedy_global;
else
    sequential_wins = wins_global;
    greedy_sequential = greedy_global;
end

assessment = struct( ...
    'candidate_focus_gap', candidate_focus_gap, ...
    'candidate_focus_excess', candidate_focus_excess, ...
    'incumbent_focus_gap', incumbent_focus_gap, ...
    'incumbent_focus_excess', incumbent_focus_excess, ...
    'wins_focus', wins_focus, ...
    'wins_global', wins_global, ...
    'sequential_wins', sequential_wins, ...
    'greedy_global', greedy_global, ...
    'greedy_sequential', greedy_sequential, ...
    'sequential_reason', selection_reason(mode, wins_focus, wins_global, sequential_wins), ...
    'greedy_reason', selection_reason(mode, wins_focus, greedy_global, greedy_sequential));
end

function reason = selection_reason(mode, focus_flag, global_flag, overall_flag)
if ~overall_flag
    reason = "none";
elseif strcmp(mode, "focus")
    reason = "focus";
elseif strcmp(mode, "hybrid_focus")
    if focus_flag && global_flag
        reason = "focus+global";
    elseif focus_flag
        reason = "focus";
    else
        reason = "global";
    end
else
    reason = "global";
end
end

function tf = improves_focus_metric(candidate_run, incumbent_run, focus_periods, params)
[candidate_focus_gap, candidate_focus_excess] = focus_metrics(candidate_run, focus_periods);
[incumbent_focus_gap, incumbent_focus_excess] = focus_metrics(incumbent_run, focus_periods);

if candidate_run.residual_norm > incumbent_run.residual_norm + params.focus_residual_slack
    tf = false;
    return;
end

if candidate_focus_gap < incumbent_focus_gap - params.focus_gap_improvement_tol
    tf = true;
elseif abs(candidate_focus_gap - incumbent_focus_gap) <= params.focus_gap_improvement_tol && ...
        candidate_focus_excess < incumbent_focus_excess - params.focus_excess_improvement_tol
    tf = true;
else
    tf = false;
end
end

function [focus_gap, focus_excess] = focus_metrics(run, focus_periods)
focus_periods = unique(focus_periods(:));
if isempty(focus_periods)
    focus_gap = max(abs(run.sim.log_price_residual_raw));
    focus_excess = max(abs(run.sim.excess_demand_guess_path));
    return;
end

focus_gap = max(abs(run.sim.log_price_residual_raw(focus_periods)));
focus_excess = max(abs(run.sim.excess_demand_guess_path(focus_periods)));
end

function tf = is_better_candidate(candidate_run, incumbent_run, params)
tolerance = 1e-8;
gap_tol = params.candidate_gap_improvement_tol;
residual_slack = params.candidate_residual_slack;

if candidate_run.max_abs_gap < incumbent_run.max_abs_gap - gap_tol && ...
        candidate_run.residual_norm <= incumbent_run.residual_norm + residual_slack
    tf = true;
elseif candidate_run.residual_norm < incumbent_run.residual_norm - tolerance
    tf = true;
elseif abs(candidate_run.residual_norm - incumbent_run.residual_norm) <= tolerance && ...
        candidate_run.max_abs_gap < incumbent_run.max_abs_gap
    tf = true;
else
    tf = false;
end
end

function tf = improves_enough(candidate_run, incumbent_run, params)
gap_tol = max(params.candidate_gap_improvement_tol, params.candidate_improvement_tol);
residual_slack = params.candidate_residual_slack;
tf = candidate_run.residual_norm < incumbent_run.residual_norm - params.candidate_improvement_tol || ...
    (candidate_run.max_abs_gap < incumbent_run.max_abs_gap - gap_tol && ...
     candidate_run.residual_norm <= incumbent_run.residual_norm + residual_slack);
end
end

function target_age_masses = build_target_age_masses(cohort_scale_by_age, demographic_path)
if nargin >= 2 && isfield(demographic_path, 'population_by_age') && ~isempty(demographic_path.population_by_age)
    population_by_age = demographic_path.population_by_age;
    if isequal(size(population_by_age), size(cohort_scale_by_age))
        population_by_age = max(population_by_age, 0);
        row_totals = sum(population_by_age, 2);
        if all(isfinite(row_totals)) && all(row_totals > 0)
            target_age_masses = population_by_age ./ row_totals;
            return;
        end
    end
end

baseline = cohort_scale_by_age(1, :);
baseline = baseline ./ sum(baseline);
target_age_masses = zeros(size(cohort_scale_by_age));
for t = 1:size(cohort_scale_by_age, 1)
    age_mass = baseline .* cohort_scale_by_age(t, :);
    age_mass = age_mass ./ sum(age_mass);
    target_age_masses(t, :) = age_mass;
end
end

function reference = load_ss_reference(price, rbPos, supply_params, steady_state_reference_mode)
persistent reference_cache
if isempty(reference_cache)
    reference_cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
end

if isfield(supply_params, 'Hbar')
    cache_Hbar = supply_params.Hbar;
else
    cache_Hbar = NaN;
end
if isfield(supply_params, 'Pbar')
    cache_Pbar = supply_params.Pbar;
else
    cache_Pbar = NaN;
end
if isfield(supply_params, 'eta_s')
    cache_eta = supply_params.eta_s;
else
    cache_eta = NaN;
end

mode = lower(string(steady_state_reference_mode));
cache_key = sprintf('mode_%s_p%.6f_rb%.6f_h%.12f_pb%.6f_eta%.6f', ...
    char(mode), price, rbPos, cache_Hbar, cache_Pbar, cache_eta);
if isKey(reference_cache, cache_key)
    reference = reference_cache(cache_key);
    return;
end

switch mode
    case "re_no_politics"
        household_results = solve_household_path_nimby( ...
            price, ...
            struct(), ...
            struct('rbPos_path', rbPos, 'return_path_solution', false, 'return_tail_solution', true));
        cross_section = build_stationary_cross_section_nimby(household_results.tail_solution, household_results.core_env, true);

        reference = struct();
        reference.dens4 = cross_section.dens4;
        reference.Hdemand = compute_housing_demand_from_density(cross_section.dens4);
        reference.age_valuefunctions = household_results.tail_solution.value;
        reference.age_policy_idx_a = household_results.tail_solution.index_a;
        reference.age_policy_idx_b = household_results.tail_solution.index_b;
        reference.household_tail_solution = household_results.tail_solution;
    case "original_5yr_political"
        [~, ~, ~, ~, ~, ss_results] = solve_original_5yr_political_steady_state([price, rbPos], struct('save_ss_iter', false));

        reference = struct();
        reference.dens4 = ss_results.dens4;
        reference.Hdemand = ss_results.Hdemand;
        reference.age_valuefunctions = ss_results.age_valuefunctions;
        reference.age_policy_idx_a = ss_results.age_policy_idx_a;
        reference.age_policy_idx_b = ss_results.age_policy_idx_b;
        reference.household_tail_solution = build_original_tail_solution_local(ss_results);
    otherwise
        error('Unsupported params.steady_state_reference_mode: %s', steady_state_reference_mode);
end

reference_cache(cache_key) = reference;
end

function tail_solution = build_original_tail_solution_local(ss_results)
tail_solution = struct();
tail_solution.time_varying = false;
tail_solution.price_multiplier = 1.0;
tail_solution.value = ss_results.age_valuefunctions;
tail_solution.index_a = ss_results.age_policy_idx_a;
tail_solution.index_b = ss_results.age_policy_idx_b;
end

function supply_params = normalize_supply_params(supply_params, reference_price, reference_Hdemand)
if ~isfield(supply_params, 'Pbar') || isempty(supply_params.Pbar)
    supply_params.Pbar = reference_price;
end
if ~isfield(supply_params, 'Hbar') || isempty(supply_params.Hbar)
    supply_params.Hbar = max(reference_Hdemand, 1e-8);
    supply_params.auto_calibrated = true;
else
    supply_params.auto_calibrated = false;
end
end

function Hdemand = compute_housing_demand_from_density(dens4)
a = linspace(0, 25, size(dens4, 2));
aa = ones(size(dens4, 1), 1) * a;
aaaa = repmat(aa, 1, 1, size(dens4, 3), size(dens4, 4));
Hdemand = sum(aaaa .* dens4, 'all');
end

function density_by_age = build_initial_density(reference_dens4, target_age_mass)
age_n = size(reference_dens4, 4);
density_by_age = cell(1, age_n);
for age_idx = 1:age_n
    base_density = reference_dens4(:, :, :, age_idx);
    base_mass = sum(base_density, 'all');
    if base_mass > 0
        base_density = base_density ./ base_mass;
    end
    density_by_age{age_idx} = base_density .* target_age_mass(age_idx);
end
end

function terminal_reference_price = resolve_terminal_reference_price(price_path, params)
mode = lower(string(params.terminal_reference_mode));

switch mode
    case "path_end_price"
        terminal_reference_price = price_path(end);
    case "initial_path_price"
        terminal_reference_price = price_path(1);
    case "fixed_price"
        terminal_reference_price = params.terminal_reference_price;
        validateattributes(terminal_reference_price, {'double'}, {'scalar', 'finite', 'real', 'positive'}, ...
            mfilename, 'params.terminal_reference_price');
    case "mean_path_price"
        terminal_reference_price = mean(price_path);
    otherwise
        error('Unsupported params.terminal_reference_mode: %s', params.terminal_reference_mode);
end
end

function policy_reference_price = resolve_policy_reference_price(price_path, params)
mode = lower(string(params.policy_reference_mode));

switch mode
    case "path_initial_price"
        policy_reference_price = price_path(1);
    case "path_end_price"
        policy_reference_price = price_path(end);
    case "path_mean_price"
        policy_reference_price = mean(price_path);
    case "fixed_price"
        policy_reference_price = params.policy_reference_price;
        validateattributes(policy_reference_price, {'double'}, {'scalar', 'finite', 'real', 'positive'}, ...
            mfilename, 'params.policy_reference_price');
    otherwise
        error('Unsupported params.policy_reference_mode: %s', params.policy_reference_mode);
end
end

function price_reference_path = resolve_policy_reference_price_path(price_path, params)
mode = lower(string(params.policy_reference_mode));

switch mode
    case "path_current_prices"
        price_reference_path = price_path(:);
    case {"path_initial_price", "path_end_price", "path_mean_price", "fixed_price"}
        reference_price = resolve_policy_reference_price(price_path, params);
        price_reference_path = reference_price .* ones(size(price_path(:)));
    case "blended_current_and_fixed_price"
        fixed_reference_price = params.policy_reference_price;
        validateattributes(fixed_reference_price, {'double'}, {'scalar', 'finite', 'real', 'positive'}, ...
            mfilename, 'params.policy_reference_price');
        blend_weight = params.policy_reference_blend_weight;
        validateattributes(blend_weight, {'double'}, {'scalar', 'finite', 'real', '>=', 0, '<=', 1}, ...
            mfilename, 'params.policy_reference_blend_weight');
        price_reference_path = (1 - blend_weight) .* fixed_reference_price + blend_weight .* price_path(:);
    otherwise
        error('Unsupported params.policy_reference_mode for path resolution: %s', params.policy_reference_mode);
end
end

function [policy_idx_b, policy_idx_a, valuefunctions, policy_reference_price_path] = build_policy_path_from_ss_prices(price_reference_path, params, age_n)
price_reference_path = apply_policy_reference_price_bounds(price_reference_path, params);
T = numel(price_reference_path);
policy_idx_b = cell(T, age_n);
policy_idx_a = cell(T, age_n);
valuefunctions = cell(T, age_n);
policy_reference_price_path = price_reference_path(:);

for t = 1:T
        reference = load_ss_reference(price_reference_path(t), params.rbPos, params.supply_params, params.steady_state_reference_mode);
    for age_idx = 1:age_n
        policy_idx_b{t, age_idx} = reference.age_policy_idx_b{age_idx};
        policy_idx_a{t, age_idx} = reference.age_policy_idx_a{age_idx};
        valuefunctions{t, age_idx} = reference.age_valuefunctions{age_idx};
    end
end
end

function bounded_price_reference_path = apply_policy_reference_price_bounds(price_reference_path, params)
bounded_price_reference_path = price_reference_path(:);

if ~isnan(params.policy_reference_price_floor)
    bounded_price_reference_path = max(bounded_price_reference_path, params.policy_reference_price_floor);
end
if ~isnan(params.policy_reference_price_cap)
    bounded_price_reference_path = min(bounded_price_reference_path, params.policy_reference_price_cap);
end
end

function sim = simulate_forward_transition(policy_idx_b, policy_idx_a, initial_density_by_age, target_age_masses, env, save_period_details)
T = size(policy_idx_b, 1);
age_n = env.age_n;
I = env.I;
J = env.J;
K = env.K;

current_density_by_age = initial_density_by_age;

sim = struct();
sim.Hdemand_path = zeros(T, 1);
sim.Hsupply_path = zeros(T, 1);
sim.debt_path = zeros(T, 1);
sim.rent_share_path = zeros(T, 1);
if save_period_details
    sim.density_by_period_age = cell(T, age_n);
end

for t = 1:T
    current_density_by_age = rescale_density_by_age(current_density_by_age, target_age_masses(t, :), env);

    period_housing = 0;
    period_debt = 0;
    period_renters = 0;
    for age_idx = 1:age_n
        density = current_density_by_age{age_idx};
        period_housing = period_housing + sum(env.aa .* sum(density, 3), 'all');
        period_debt = period_debt + sum(env.bb .* sum(density, 3), 'all');
        period_renters = period_renters + sum(density(:, 1, :), 'all');
        if save_period_details
            sim.density_by_period_age{t, age_idx} = density;
        end
    end

    sim.Hdemand_path(t) = period_housing;
    sim.debt_path(t) = period_debt;
    sim.rent_share_path(t) = period_renters;

    if t == T
        continue;
    end

    next_density_by_age = cell(1, age_n);
    for age_idx = 1:age_n
        next_density_by_age{age_idx} = zeros(I, J, K);
    end

    entrant_density = zeros(I, J, K);
    for iz = 1:K
        entrant_density(env.bzero, 1, iz) = env.initialdist(iz);
    end
    next_density_by_age{1} = entrant_density;

    for age_idx = 1:(age_n - 1)
        chosen_next_assets = map_density_with_policy( ...
            current_density_by_age{age_idx}, policy_idx_b{t, age_idx}, policy_idx_a{t, age_idx}, I, J, K);
        z_transition = env.transitionmatrix(:, :, age_idx)';
        next_density_by_age{age_idx + 1} = next_density_by_age{age_idx + 1} + ...
            apply_z_transition(chosen_next_assets, z_transition);
    end

    current_density_by_age = next_density_by_age;
end
end

function transitioned = apply_z_transition(density, z_transition)
[I, J, K] = size(density);
transitioned = zeros(I, J, K);
for iz = 1:K
    for iz_next = 1:K
        transitioned(:, :, iz_next) = transitioned(:, :, iz_next) + z_transition(iz_next, iz) .* density(:, :, iz);
    end
end
end

function mapped = map_density_with_policy(pre_density, idx_b, idx_a, I, J, K)
mapped = zeros(I, J, K);
for iz = 1:K
    for ij = 1:J
        for ii = 1:I
            mass = pre_density(ii, ij, iz);
            if mass == 0
                continue;
            end
            mapped(idx_b(ii, ij, iz), idx_a(ii, ij, iz), iz) = mapped(idx_b(ii, ij, iz), idx_a(ii, ij, iz), iz) + mass;
        end
    end
end
end

function density_by_age = rescale_density_by_age(density_by_age, target_age_mass, env)
age_n = numel(density_by_age);
fallback = zeros(env.I, env.J, env.K);
for iz = 1:env.K
    fallback(env.bzero, 1, iz) = env.initialdist(iz);
end

for age_idx = 1:age_n
    current_mass = sum(density_by_age{age_idx}, 'all');
    if current_mass > 0
        density_by_age{age_idx} = density_by_age{age_idx} .* (target_age_mass(age_idx) / current_mass);
    else
        density_by_age{age_idx} = fallback .* target_age_mass(age_idx);
    end
end
end

function implied_price_path = invert_supply_path(Hdemand_path, supply_params, supply_hbar_path)
if supply_params.eta_s <= 0
    error('supply_params.eta_s must be positive to invert the supply curve for the transition path.');
end

supply_hbar_path = resolve_supply_hbar_path_local(supply_hbar_path, numel(Hdemand_path), supply_params.Hbar);
implied_price_path = supply_params.Pbar .* max(Hdemand_path ./ supply_hbar_path, 1e-8) .^ (1 ./ supply_params.eta_s);
implied_price_path = implied_price_path(:);
end

function [adjusted_price_path, info] = apply_housing_adjustment_path_local(instant_implied_price_path, current_price_path, params)
instant_implied_price_path = instant_implied_price_path(:);
current_price_path = current_price_path(:);
mode = lower(string(params.housing_adjustment_mode));
space = lower(string(params.housing_adjustment_space));
weight = params.housing_adjustment_weight;

if isnan(params.housing_adjustment_anchor_price)
    anchor_price = current_price_path(1);
else
    anchor_price = params.housing_adjustment_anchor_price;
end

switch mode
    case "instant_market_clearing"
        adjusted_price_path = instant_implied_price_path;
    case {"construction_lag_price_partial_adjustment", "construction_lag"}
        adjusted_price_path = zeros(size(instant_implied_price_path));
        for t = 1:numel(instant_implied_price_path)
            if t == 1
                reference_price = anchor_price;
            else
                reference_price = adjusted_price_path(t - 1);
            end

            switch space
                case "log"
                    adjusted_price_path(t) = exp((1 - weight) .* log(max(reference_price, 1e-8)) + ...
                        weight .* log(max(instant_implied_price_path(t), 1e-8)));
                case "level"
                    adjusted_price_path(t) = (1 - weight) .* reference_price + weight .* instant_implied_price_path(t);
                otherwise
                    error('Unknown params.housing_adjustment_space: %s', params.housing_adjustment_space);
            end
        end
    otherwise
        error('Unknown params.housing_adjustment_mode: %s', params.housing_adjustment_mode);
end

info = struct( ...
    'mode', string(mode), ...
    'space', string(space), ...
    'weight', weight, ...
    'anchor_price', anchor_price);
end

function Hsupply_path = compute_supply_path(price_path, supply_params, supply_hbar_path)
supply_hbar_path = resolve_supply_hbar_path_local(supply_hbar_path, numel(price_path), supply_params.Hbar);
Hsupply_path = supply_hbar_path .* (price_path(:) ./ supply_params.Pbar) .^ supply_params.eta_s;
end

function resolved_supply = resolve_supply_path_local(params, T)
base_hbar = params.supply_params.Hbar;
hbar_path = [];
wedge_path = [];

if isfield(params, 'supply_hbar_path') && ~isempty(params.supply_hbar_path)
    hbar_path = resolve_supply_hbar_path_local(params.supply_hbar_path, T, base_hbar);
    wedge_path = log(max(hbar_path ./ base_hbar, 1e-8));
elseif isfield(params, 'supply_wedge_path') && ~isempty(params.supply_wedge_path)
    wedge_path = resolve_supply_hbar_path_local(params.supply_wedge_path, T, 0.0);
    switch lower(string(params.supply_wedge_space))
        case "log"
            hbar_path = base_hbar .* exp(wedge_path);
        case "level"
            hbar_path = max(base_hbar + wedge_path, 1e-8);
            wedge_path = hbar_path - base_hbar;
        otherwise
            error('Unknown params.supply_wedge_space: %s', params.supply_wedge_space);
    end
else
    hbar_path = base_hbar .* ones(T, 1);
    wedge_path = zeros(T, 1);
end

resolved_supply = struct();
resolved_supply.hbar_path = hbar_path(:);
resolved_supply.wedge_path = wedge_path(:);
end

function resolved = resolve_supply_hbar_path_local(path_like, T, fallback_value)
if nargin < 3 || isempty(fallback_value)
    fallback_value = 1.0;
end

if isempty(path_like)
    resolved = fallback_value .* ones(T, 1);
    return;
end

resolved = path_like(:);
if numel(resolved) == 1
    resolved = resolved .* ones(T, 1);
elseif numel(resolved) < T
    resolved = [resolved; resolved(end) .* ones(T - numel(resolved), 1)];
elseif numel(resolved) > T
    resolved = resolved(1:T);
end
end

function political = compute_transition_political_path_local(density_by_period_age, preference_sign_by_period_age, preference_value_by_period_age, env, price_path, coalition_params, save_political_details, response_mode, response_sigma)
T = size(density_by_period_age, 1);
age_n = env.age_n;

political = struct();
political.response_mode = string(response_mode);
political.response_sigma = response_sigma;
political.equal_weight_vote_path = zeros(T, 1);
political.weighted_vote_path = zeros(T, 1);
political.weighted_vote_share_path = zeros(T, 1);
political.equal_weight_support_path = zeros(T, 1);
political.weighted_support_share_path = zeros(T, 1);
political.equal_weight_distance_path = zeros(T, 1);
political.weighted_distance_path = zeros(T, 1);
political.equal_weight_vote_by_age = zeros(T, age_n);
political.hard_equal_weight_vote_path = zeros(T, 1);
political.hard_weighted_vote_path = zeros(T, 1);
political.hard_weighted_vote_share_path = zeros(T, 1);
political.hard_equal_weight_support_path = zeros(T, 1);
political.hard_weighted_support_share_path = zeros(T, 1);
political.owner_share_path = zeros(T, 1);
political.old_owner_share_path = zeros(T, 1);
political.leveraged_owner_share_path = zeros(T, 1);

if save_political_details
    political.stats_by_period = cell(T, 1);
    political.preference_sign_by_period_age = preference_sign_by_period_age;
    political.preference_value_by_period_age = preference_value_by_period_age;
    political.preference_response_by_period_age = cell(T, age_n);
end

housing_grid = repmat(env.aa, 1, 1, env.K, age_n);
liquid_grid = repmat(env.bb, 1, 1, env.K, age_n);
age_grid = env.ages(:)';

for t = 1:T
    dens4 = zeros(env.I, env.J, env.K, age_n);
    pref4_hard = zeros(env.I, env.J, env.K, age_n);
    pref4_response = zeros(env.I, env.J, env.K, age_n);

    for age_idx = 1:age_n
        dens4(:, :, :, age_idx) = density_by_period_age{t, age_idx};
        pref4_hard(:, :, :, age_idx) = preference_sign_by_period_age{t, age_idx};
        pref4_response(:, :, :, age_idx) = build_political_response_local( ...
            pref4_hard(:, :, :, age_idx), preference_value_by_period_age{t, age_idx}, response_mode, response_sigma);
        political.equal_weight_vote_by_age(t, age_idx) = sum(dens4(:, :, :, age_idx) .* pref4_response(:, :, :, age_idx), 'all');
        if save_political_details
            political.preference_response_by_period_age{t, age_idx} = pref4_response(:, :, :, age_idx);
        end
    end

    period_coalition_params = coalition_params;
    period_coalition_params.house_price = price_path(t);
    stats = compute_coalition_vote(dens4, pref4_response, housing_grid, liquid_grid, age_grid, period_coalition_params);
    hard_stats = compute_coalition_vote(dens4, pref4_hard, housing_grid, liquid_grid, age_grid, period_coalition_params);

    political.equal_weight_vote_path(t) = stats.equal_weight_vote;
    political.weighted_vote_path(t) = stats.weighted_vote;
    political.weighted_vote_share_path(t) = stats.weighted_vote_share;
    political.equal_weight_support_path(t) = 0.5 .* (1 + stats.equal_weight_vote);
    political.weighted_support_share_path(t) = 0.5 .* (1 + stats.weighted_vote_share);
    political.equal_weight_distance_path(t) = stats.equal_weight_vote ^ 2;
    political.weighted_distance_path(t) = stats.weighted_vote ^ 2;
    political.hard_equal_weight_vote_path(t) = hard_stats.equal_weight_vote;
    political.hard_weighted_vote_path(t) = hard_stats.weighted_vote;
    political.hard_weighted_vote_share_path(t) = hard_stats.weighted_vote_share;
    political.hard_equal_weight_support_path(t) = 0.5 .* (1 + hard_stats.equal_weight_vote);
    political.hard_weighted_support_share_path(t) = 0.5 .* (1 + hard_stats.weighted_vote_share);
    political.owner_share_path(t) = stats.owner_share;
    political.old_owner_share_path(t) = stats.old_owner_share;
    political.leveraged_owner_share_path(t) = stats.leveraged_owner_share;

    if save_political_details
        political.stats_by_period{t} = stats;
    end
end
end

function preference_response = build_political_response_local(preference_sign, preference_value_difference, response_mode, response_sigma)
mode = lower(string(response_mode));

switch mode
    case {"hard_sign", "sign"}
        preference_response = preference_sign;
    case {"smooth_tanh", "smoothed_tanh", "probabilistic_permits"}
        if isempty(preference_value_difference)
            error('Smooth political response requires value-difference inputs, but none were provided.');
        end
        preference_response = tanh(preference_value_difference ./ (2 .* response_sigma));
    otherwise
        error('Unsupported params.political_response_mode: %s', response_mode);
end
end
