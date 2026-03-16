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
iteration_log = repmat(struct('max_abs_gap', NaN, 'max_abs_update', NaN), params.max_iter, 1);
last_run = struct();

for iter = 1:params.max_iter
    terminal_reference = load_ss_reference(current_price_path(end), params.rbPos, params.supply_params);

    [policy_idx_b, policy_idx_a, valuefunctions] = solve_backward_transition( ...
        current_price_path, terminal_reference.age_valuefunctions, transitionmatrix, model);

    sim = simulate_forward_transition(policy_idx_b, policy_idx_a, initial_density, ...
        target_age_masses, initialdist, transitionmatrix, model, params.save_period_details);

    implied_price_path = invert_supply_path(sim.Hdemand_path, params.supply_params);
    [updated_price_path, diagnostics] = update_price_path_re_no_politics(current_price_path, implied_price_path, params);

    iteration_log(iter).max_abs_gap = diagnostics.max_abs_gap;
    iteration_log(iter).max_abs_update = diagnostics.max_abs_update;

    last_run = struct();
    last_run.policy_idx_b = policy_idx_b;
    last_run.policy_idx_a = policy_idx_a;
    last_run.valuefunctions = valuefunctions;
    last_run.sim = sim;
    last_run.implied_price_path = implied_price_path;
    last_run.updated_price_path = updated_price_path;
    last_run.update_diagnostics = diagnostics;

    current_price_path = updated_price_path;
    if diagnostics.max_abs_gap < params.tol
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
results.Hsupply_path = params.supply_params.Hbar .* (results.final_price_path ./ params.supply_params.Pbar) .^ params.supply_params.eta_s;
results.debt_path = last_run.sim.debt_path;
results.rent_share_path = last_run.sim.rent_share_path;
if params.save_period_details
    results.density_by_period_age = last_run.sim.density_by_period_age;
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
