function results = solve_transition_re_no_politics(price_path_guess, demographic_path, params)
% Finite-horizon transition solver for a no-coalition RE price experiment.
% This first implementation solves the household problem for a guessed
% price path, simulates the cross-sectional distribution forward under an
% exogenous demographic age profile, and returns the implied price path.

if nargin < 3 || isempty(params)
    params = struct();
end
if ~isfield(params, 'max_iter'), params.max_iter = 3; end
if ~isfield(params, 'tol'), params.tol = 1e-3; end
if ~isfield(params, 'damping'), params.damping = 0.25; end
if ~isfield(params, 'terminal_price_rule'), params.terminal_price_rule = 'flat_tail'; end
if ~isfield(params, 'rbPos'), params.rbPos = 0.03; end
if ~isfield(params, 'supply_params'), params.supply_params = struct(); end
if ~isfield(params.supply_params, 'eta_s'), params.supply_params.eta_s = 1.0; end
if ~isfield(params, 'max_update_frac'), params.max_update_frac = 0.10; end
if ~isfield(params, 'smoothing_weight'), params.smoothing_weight = 5.00; end
if ~isfield(params, 'terminal_anchor_weight'), params.terminal_anchor_weight = 0.50; end
if ~isfield(params, 'targeted_correction_weight'), params.targeted_correction_weight = 0.35; end
if ~isfield(params, 'max_targeted_periods'), params.max_targeted_periods = 3; end
if ~isfield(params, 'target_block_half_width'), params.target_block_half_width = 1; end
if ~isfield(params, 'line_search_scales'), params.line_search_scales = [0.10, 0.05, 0.02, 0.01]; end
if ~isfield(params, 'update_scheme'), params.update_scheme = 'sequential_blocks'; end
if ~isfield(params, 'sequential_block_size'), params.sequential_block_size = 3; end
if ~isfield(params, 'save_period_details'), params.save_period_details = false; end

validateattributes(price_path_guess, {'double'}, {'vector', 'nonempty', 'finite', 'real', 'positive'}, mfilename, 'price_path_guess');
validateattributes(demographic_path, {'struct'}, {'scalar', 'nonempty'}, mfilename, 'demographic_path');

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

[transitionmatrix, z, Zlifecycle, initialdist, transition_matrix_path] = load_transition_matrix_data();

model = setup_model_objects(z, Zlifecycle, params.rbPos);
target_age_masses = build_target_age_masses(cohort_scale_by_age);

initial_reference = load_ss_reference(price_path_guess(1), params.rbPos, params.supply_params);
params.supply_params = normalize_supply_params(params.supply_params, price_path_guess(1), initial_reference.Hdemand);
initial_density = build_initial_density(initial_reference.dens4, target_age_masses(1, :));

current_price_path = price_path_guess;
iteration_log = repmat(struct( ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'accepted_update', "", ...
    'worst_gap_period', NaN, ...
    'worst_excess_demand_period', NaN, ...
    'worst_excess_demand', NaN), params.max_iter, 1);
last_run = struct();

for iter = 1:params.max_iter
    base_run = run_transition_pass(current_price_path, initial_density, target_age_masses, ...
        initialdist, transitionmatrix, model, params);
    [updated_price_path, diagnostics] = update_price_path_re_no_politics( ...
        current_price_path, base_run.implied_price_path, params);

    current_run = base_run;
    current_run.label = "current_path";

    selected_run = current_run;
    selected_price_path = current_price_path;

    if strcmp(params.update_scheme, 'sequential_blocks')
        [selected_run, selected_price_path] = try_sequential_block_candidates( ...
            current_price_path, diagnostics, base_run, initial_density, target_age_masses, ...
            initialdist, transitionmatrix, model, params, selected_run, selected_price_path);
    else
        [selected_run, selected_price_path] = try_line_search_candidates( ...
            current_price_path, diagnostics.log_update_step, diagnostics.targeted_blocks, ...
            initial_density, target_age_masses, initialdist, transitionmatrix, model, params, selected_run, selected_price_path);
    end

    selected_run.sim.Hsupply_updated_path = compute_supply_path(selected_price_path, params.supply_params);
    selected_run.sim.excess_demand_updated_path = selected_run.sim.Hdemand_path - selected_run.sim.Hsupply_updated_path;
    selected_run.sim.log_price_residual_smoothed = log(diagnostics.smoothed_implied_price_path) - log(current_price_path);

    iteration_log(iter).residual_norm = selected_run.residual_norm;
    iteration_log(iter).max_abs_gap = selected_run.max_abs_gap;
    iteration_log(iter).max_abs_update = max(abs(selected_price_path - current_price_path));
    iteration_log(iter).accepted_update = selected_run.label;
    [~, iteration_log(iter).worst_gap_period] = max(abs(selected_run.sim.log_price_residual_raw));
    [iteration_log(iter).worst_excess_demand, iteration_log(iter).worst_excess_demand_period] = ...
        max(abs(selected_run.sim.excess_demand_guess_path));

    last_run = struct();
    last_run.policy_idx_b = selected_run.policy_idx_b;
    last_run.policy_idx_a = selected_run.policy_idx_a;
    last_run.valuefunctions = selected_run.valuefunctions;
    last_run.sim = selected_run.sim;
    last_run.implied_price_path = selected_run.implied_price_path;
    last_run.updated_price_path = selected_price_path;
    last_run.update_diagnostics = diagnostics;
    last_run.update_diagnostics.max_abs_gap = selected_run.max_abs_gap;
    last_run.update_diagnostics.max_abs_smoothed_gap = selected_run.max_abs_gap;
    last_run.update_diagnostics.accepted_update = selected_run.label;

    current_price_path = selected_price_path;
    if selected_run.max_abs_gap < params.tol
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
results.demographic_path = demographic_path;
results.cohort_scale = mean(cohort_scale_by_age, 2);
results.cohort_scale_by_age = cohort_scale_by_age;
results.target_age_masses = target_age_masses;
results.params = params;
results.transition_matrix_path = transition_matrix_path;
results.message = 'Transition solver completed a backward-forward pass and updated the price path.';
results.update_diagnostics = last_run.update_diagnostics;
results.iteration_log = iteration_log(1:results.iterations);
results.Hdemand_path = last_run.sim.Hdemand_path;
results.Hsupply_path = last_run.sim.Hsupply_updated_path;
results.excess_demand_path = last_run.sim.excess_demand_updated_path;
results.excess_demand_guess_path = last_run.sim.excess_demand_guess_path;
results.log_price_residual_raw = last_run.sim.log_price_residual_raw;
results.log_price_residual_smoothed = last_run.sim.log_price_residual_smoothed;
results.debt_path = last_run.sim.debt_path;
results.rent_share_path = last_run.sim.rent_share_path;
results.period_diagnostics = struct( ...
    'Hdemand_path', last_run.sim.Hdemand_path, ...
    'Hsupply_guess_path', last_run.sim.Hsupply_guess_path, ...
    'Hsupply_updated_path', last_run.sim.Hsupply_updated_path, ...
    'excess_demand_guess_path', last_run.sim.excess_demand_guess_path, ...
    'excess_demand_updated_path', last_run.sim.excess_demand_updated_path, ...
    'implied_price_path_raw', last_run.implied_price_path, ...
    'implied_price_path_smoothed', last_run.update_diagnostics.smoothed_implied_price_path, ...
    'log_price_residual_raw', last_run.sim.log_price_residual_raw, ...
    'log_price_residual_smoothed', last_run.sim.log_price_residual_smoothed, ...
    'targeted_periods', last_run.update_diagnostics.targeted_periods, ...
    'targeted_blocks', last_run.update_diagnostics.targeted_blocks);
if params.save_period_details
    results.density_by_period_age = last_run.sim.density_by_period_age;
end

function run = run_transition_pass(price_path, initial_density, target_age_masses, initialdist, transitionmatrix, model, params)
terminal_reference = load_ss_reference(price_path(end), params.rbPos, params.supply_params);

[policy_idx_b, policy_idx_a, valuefunctions] = solve_backward_transition( ...
    price_path, terminal_reference.age_valuefunctions, transitionmatrix, model);

sim = simulate_forward_transition(policy_idx_b, policy_idx_a, initial_density, ...
    target_age_masses, initialdist, transitionmatrix, model, params.save_period_details);

implied_price_path = invert_supply_path(sim.Hdemand_path, params.supply_params);
sim.Hsupply_guess_path = compute_supply_path(price_path, params.supply_params);
sim.excess_demand_guess_path = sim.Hdemand_path - sim.Hsupply_guess_path;
sim.log_price_residual_raw = log(implied_price_path) - log(price_path);

run = struct();
run.policy_idx_b = policy_idx_b;
run.policy_idx_a = policy_idx_a;
run.valuefunctions = valuefunctions;
run.sim = sim;
run.implied_price_path = implied_price_path;
run.max_abs_gap = max(abs(implied_price_path - price_path));
run.residual_norm = norm(log(implied_price_path) - log(price_path));
end

function [best_run, best_price_path] = try_line_search_candidates(current_price_path, log_update_step, targeted_blocks, ...
    initial_density, target_age_masses, initialdist, transitionmatrix, model, params, best_run, best_price_path)

log_current = log(current_price_path);
scales = params.line_search_scales(:)';

for scale = scales
    full_candidate_price_path = exp(log_current + scale .* log_update_step);
    full_candidate_run = run_transition_pass(full_candidate_price_path, initial_density, target_age_masses, ...
        initialdist, transitionmatrix, model, params);
    full_candidate_run.label = sprintf('full_path_%.2f', scale);

    if is_better_candidate(full_candidate_run, best_run)
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

    block_candidate_run = run_transition_pass(block_candidate_price_path, initial_density, target_age_masses, ...
        initialdist, transitionmatrix, model, params);
    block_candidate_run.label = sprintf('targeted_block_%.2f', scale);

    if is_better_candidate(block_candidate_run, best_run)
        best_run = block_candidate_run;
        best_price_path = block_candidate_price_path;
    end
end
end

function [best_run, best_price_path] = try_sequential_block_candidates(current_price_path, diagnostics, base_run, ...
    initial_density, target_age_masses, initialdist, transitionmatrix, model, params, best_run, best_price_path)

T = numel(current_price_path);
block_size = min(params.sequential_block_size, T);
block_starts = 1:block_size:T;
log_current = log(current_price_path);
log_target = log(base_run.implied_price_path);

% Try windows around the currently worst periods first.
priority_starts = [];
for i = 1:numel(diagnostics.targeted_periods)
    start_idx = max(1, min(T - block_size + 1, diagnostics.targeted_periods(i) - floor((block_size - 1) / 2)));
    priority_starts(end + 1) = start_idx; %#ok<AGROW>
end
block_starts = unique([priority_starts, block_starts], 'stable');

for start_idx = block_starts
    stop_idx = min(T, start_idx + block_size - 1);
    block = start_idx:stop_idx;

    for scale = params.line_search_scales(:)'
        candidate_price_path = current_price_path;
        candidate_log_block = log_current(block) + scale .* (log_target(block) - log_current(block));
        candidate_price_path(block) = exp(candidate_log_block);

        candidate_run = run_transition_pass(candidate_price_path, initial_density, target_age_masses, ...
            initialdist, transitionmatrix, model, params);
        candidate_run.label = sprintf('sequential_block_%d_%d_%.2f', start_idx, stop_idx, scale);

        if is_better_candidate(candidate_run, best_run)
            best_run = candidate_run;
            best_price_path = candidate_price_path;
        end
    end
end
end

function tf = is_better_candidate(candidate_run, incumbent_run)
tolerance = 1e-8;
if candidate_run.residual_norm < incumbent_run.residual_norm - tolerance
    tf = true;
elseif abs(candidate_run.residual_norm - incumbent_run.residual_norm) <= tolerance && ...
        candidate_run.max_abs_gap < incumbent_run.max_abs_gap
    tf = true;
else
    tf = false;
end
end
end

function model = setup_model_objects(z, Zlifecycle, rbPos)
model.agemin = 25;
model.agemax = 90;
model.dage = 5;
model.ageline = model.agemin:model.dage:model.agemax;
model.age_n = numel(model.ageline);

model.rspread = 0.02;
model.rbPos = rbPos;
model.rbNeg = rbPos + model.rspread;
model.ra = -0.03;
model.r_price = model.rbNeg - model.ra + 0.02;

model.omega = 0.5;
model.theta_r = 0.9;
model.beta = 0.8;
model.eta = 2;
model.ka = 0.07;
model.bequestweight1 = 0.9 * model.beta;
model.bequestweight2 = 0.9 * model.beta;
model.CC = 0.9;
model.penalty = 1e6;

model.z = z;
model.K = numel(z);
model.Zlifecycle = Zlifecycle;

model.J = 20;
model.a = linspace(0, 25, model.J);
model.I = 50;
model.b = linspace(-15, 15, model.I);

model.bb = model.b' * ones(1, model.J);
model.aa = ones(model.I, 1) * model.a;

model.bzero = find(model.b >= 0, 1, 'first');
if isempty(model.bzero)
    [~, model.bzero] = min(abs(model.b));
end
end

function target_age_masses = build_target_age_masses(cohort_scale_by_age)
baseline = cohort_scale_by_age(1, :);
baseline = baseline ./ sum(baseline);
target_age_masses = zeros(size(cohort_scale_by_age));
for t = 1:size(cohort_scale_by_age, 1)
    age_mass = baseline .* cohort_scale_by_age(t, :);
    age_mass = age_mass ./ sum(age_mass);
    target_age_masses(t, :) = age_mass;
end
end

function reference = load_ss_reference(price, rbPos, supply_params)
solve_ss_no_politics([price, rbPos], supply_params); %#ok<NASGU>
ss = load('SS_no_politics_iter.mat');

reference = struct();
reference.dens4 = ss.dens4;
reference.Hdemand = compute_housing_demand_from_density(ss.dens4);
reference.age_valuefunctions = cell(1, size(ss.dens4, 4));
for age_idx = 1:size(ss.dens4, 4)
    age = 25 + 5 * (age_idx - 1);
    field_name = sprintf('valuefunction_%d', age);
    reference.age_valuefunctions{age_idx} = ss.(field_name);
end
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

function [policy_idx_b, policy_idx_a, valuefunctions] = solve_backward_transition(price_path, terminal_age_values, transitionmatrix, model)
T = numel(price_path);
age_n = model.age_n;
I = model.I;
J = model.J;
K = model.K;

policy_idx_b = cell(T, age_n);
policy_idx_a = cell(T, age_n);
valuefunctions = cell(T, age_n);

for t = T:-1:1
    a_price = price_path(t);
    r_price = model.rbNeg - model.ra + 0.02;
    Ipen = double(-model.bb > model.aa * a_price * model.CC);

    for age_idx = age_n:-1:1
        age = model.ageline(age_idx);

        if age_idx == age_n
            [index_b, index_a, valuefunction] = solve_terminal_age(a_price, r_price, Ipen, model, age_idx);
        else
            if t == T
                next_values = terminal_age_values{age_idx + 1};
            else
                next_values = valuefunctions{t + 1, age_idx + 1};
            end
            [index_b, index_a, valuefunction] = solve_working_age(a_price, r_price, Ipen, model, age_idx, next_values, transitionmatrix(:, :, age_idx)');
        end

        policy_idx_b{t, age_idx} = index_b;
        policy_idx_a{t, age_idx} = index_a;
        valuefunctions{t, age_idx} = valuefunction;
    end
end
end

function [index_b, index_a, valuefunction] = solve_terminal_age(a_price, r_price, Ipen, model, age_idx)
I = model.I;
J = model.J;
K = model.K;

index_b = zeros(I, J, K);
index_a = zeros(I, J, K);
valuefunction = zeros(I, J, K);

for iz = 1:K
    labor_income = exp(model.z(iz)) * model.Zlifecycle(age_idx);
    for ij = 1:J
        current_a = model.a(ij);
        for ii = 1:I
            current_b = model.b(ii);

            consumption_plane = build_consumption_plane(current_b, current_a, a_price, r_price, labor_income, model);
            rent_plane = zeros(I, J);
            rent_plane(:, 1) = consumption_plane(:, 1) * ((1 - model.omega) / model.omega / r_price * model.theta_r);
            bequest_plane = max(1e-20, model.bb + a_price .* model.aa);

            value_plane = (consumption_plane .^ model.omega .* (model.aa + model.theta_r .* rent_plane) .^ (1 - model.omega)) .^ ...
                (1 - model.eta) / (1 - model.eta) - Ipen * model.penalty + ...
                model.bequestweight1 * (1 + bequest_plane ./ model.bequestweight2) .^ (1 - model.eta);

            [max_value, linear_idx] = max(value_plane, [], 'all', 'linear');
            [best_b, best_a] = ind2sub([I, J], linear_idx);

            index_b(ii, ij, iz) = best_b;
            index_a(ii, ij, iz) = best_a;
            valuefunction(ii, ij, iz) = max_value;
        end
    end
end
end

function [index_b, index_a, valuefunction] = solve_working_age(a_price, r_price, Ipen, model, age_idx, next_values, z_transition)
I = model.I;
J = model.J;
K = model.K;

index_b = zeros(I, J, K);
index_a = zeros(I, J, K);
valuefunction = zeros(I, J, K);

expected_value = zeros(I, J, K);
for iz = 1:K
    for iz_next = 1:K
        expected_value(:, :, iz) = expected_value(:, :, iz) + z_transition(iz_next, iz) .* next_values(:, :, iz_next);
    end
end

for iz = 1:K
    labor_income = exp(model.z(iz)) * model.Zlifecycle(age_idx);
    continuation_plane = expected_value(:, :, iz);
    for ij = 1:J
        current_a = model.a(ij);
        for ii = 1:I
            current_b = model.b(ii);

            consumption_plane = build_consumption_plane(current_b, current_a, a_price, r_price, labor_income, model);
            rent_plane = zeros(I, J);
            rent_plane(:, 1) = consumption_plane(:, 1) * ((1 - model.omega) / model.omega / r_price * model.theta_r);

            value_plane = (consumption_plane .^ model.omega .* (model.aa + model.theta_r .* rent_plane) .^ (1 - model.omega)) .^ ...
                (1 - model.eta) / (1 - model.eta) - Ipen * model.penalty + model.beta .* continuation_plane;

            [max_value, linear_idx] = max(value_plane, [], 'all', 'linear');
            [best_b, best_a] = ind2sub([I, J], linear_idx);

            index_b(ii, ij, iz) = best_b;
            index_a(ii, ij, iz) = best_a;
            valuefunction(ii, ij, iz) = max_value;
        end
    end
end
end

function consumption_plane = build_consumption_plane(current_b, current_a, a_price, r_price, labor_income, model)
I = model.I;
J = model.J;

consumption_plane = zeros(I, J);
wealth_flow = labor_income + current_b * (model.rbPos * (current_b >= 0) + model.rbNeg * (current_b < 0)) + current_a * a_price;

adjust_cost = model.ka .* (1 - (model.aa == current_a));
consumption_plane(:, 2:J) = max(wealth_flow - model.aa(:, 2:J) .* a_price .* (1 + adjust_cost(:, 2:J)) + current_b - model.bb(:, 2:J), 1e-20);
consumption_plane(:, 1) = max((wealth_flow - model.aa(:, 1) .* a_price .* (1 + adjust_cost(:, 1)) + current_b - model.bb(:, 1)) ./ ...
    (1 + ((1 - model.omega) / model.omega * model.theta_r)), 1e-20);
end

function sim = simulate_forward_transition(policy_idx_b, policy_idx_a, initial_density_by_age, target_age_masses, initialdist, transitionmatrix, model, save_period_details)
T = size(policy_idx_b, 1);
age_n = model.age_n;
I = model.I;
J = model.J;
K = model.K;

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
    current_density_by_age = rescale_density_by_age(current_density_by_age, target_age_masses(t, :), model, initialdist);

    period_housing = 0;
    period_debt = 0;
    period_renters = 0;
    for age_idx = 1:age_n
        density = current_density_by_age{age_idx};
        period_housing = period_housing + sum(model.aa .* sum(density, 3), 'all');
        period_debt = period_debt + sum(model.bb .* sum(density, 3), 'all');
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
        entrant_density(model.bzero, 1, iz) = initialdist(iz);
    end
    next_density_by_age{1} = entrant_density;

    for age_idx = 1:(age_n - 1)
        chosen_next_assets = map_density_with_policy( ...
            current_density_by_age{age_idx}, policy_idx_b{t, age_idx}, policy_idx_a{t, age_idx}, I, J, K);
        z_transition = transitionmatrix(:, :, age_idx)';
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

function density_by_age = rescale_density_by_age(density_by_age, target_age_mass, model, initialdist)
age_n = numel(density_by_age);
fallback = zeros(model.I, model.J, model.K);
for iz = 1:model.K
    fallback(model.bzero, 1, iz) = initialdist(iz);
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

function implied_price_path = invert_supply_path(Hdemand_path, supply_params)
if supply_params.eta_s <= 0
    error('supply_params.eta_s must be positive to invert the supply curve for the transition path.');
end

implied_price_path = supply_params.Pbar .* max(Hdemand_path ./ supply_params.Hbar, 1e-8) .^ (1 ./ supply_params.eta_s);
implied_price_path = implied_price_path(:);
end

function Hsupply_path = compute_supply_path(price_path, supply_params)
Hsupply_path = supply_params.Hbar .* (price_path(:) ./ supply_params.Pbar) .^ supply_params.eta_s;
end
