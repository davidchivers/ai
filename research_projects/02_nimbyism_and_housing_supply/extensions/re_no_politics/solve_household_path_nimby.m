function results = solve_household_path_nimby(price_path, overrides, options)
% solve_household_path_nimby.m
%
% Shared Bellman layer for the Nimby no-politics extension.
% This mirrors the fertility project split between:
%   1. a reusable household/value-function solve
%   2. outer wrappers for steady state or transition-path RE

if nargin < 2 || isempty(overrides)
    overrides = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');
if exist(baseline_dir, 'dir')
    addpath(baseline_dir, '-begin');
end

ensure_external_matlab_data_paths();

params = default_nimby_params_local();
params = apply_overrides_local(params, overrides);
options = apply_default_options_local(options);
[price_path, rb_pos_path] = normalize_paths_local(price_path, options.rbPos_path);

if isfield(options, 'environment') && ~isempty(options.environment)
    env = options.environment;
else
    env = get_solver_environment_cached_local(params);
end

tail_solution_full = [];
if options.return_path_solution
    if isfield(options, 'tail_solution') && ~isempty(options.tail_solution)
        tail_solution_full = options.tail_solution;
    else
        tail_solution_full = solve_constant_tail_local(price_path(end), rb_pos_path(end), params, env, options);
    end
elseif options.return_tail_solution
    if isfield(options, 'tail_solution') && ~isempty(options.tail_solution)
        tail_solution_full = options.tail_solution;
    else
        tail_solution_full = solve_constant_tail_local(price_path(end), rb_pos_path(end), params, env, options);
    end
end

if options.return_path_solution
    path_solution = solve_transition_path_local(price_path, rb_pos_path, tail_solution_full, params, env, options);
else
    path_solution = [];
end

if options.return_tail_solution
    tail_solution = tail_solution_full;
else
    tail_solution = [];
end

if options.compute_price_preference
    price_preference = solve_price_preference_branch_local( ...
        price_path, rb_pos_path, tail_solution_full, path_solution, params, env, options);
else
    price_preference = [];
end

results = struct();
results.price_path = price_path;
results.rb_pos_path = rb_pos_path;
results.params = params;
results.options = options;
results.env = struct( ...
    'ages', env.ages, ...
    'a_grid', env.a, ...
    'b_grid', env.b);
results.core_env = env;
results.transition_matrix_path = env.transition_matrix_path;
results.tail_solution = tail_solution;
results.path_solution = path_solution;
results.price_preference = price_preference;
end

function options = apply_default_options_local(options)
if ~isfield(options, 'rbPos_path') || isempty(options.rbPos_path)
    options.rbPos_path = 0.03;
end
if ~isfield(options, 'return_tail_solution') || isempty(options.return_tail_solution)
    options.return_tail_solution = true;
end
if ~isfield(options, 'return_path_solution') || isempty(options.return_path_solution)
    options.return_path_solution = true;
end
if ~isfield(options, 'verbose_progress') || isempty(options.verbose_progress)
    options.verbose_progress = false;
end
if ~isfield(options, 'compute_price_preference') || isempty(options.compute_price_preference)
    options.compute_price_preference = false;
end
if ~isfield(options, 'price_preference_multiplier') || isempty(options.price_preference_multiplier)
    options.price_preference_multiplier = 1.01;
end
end

function [price_path, rb_pos_path] = normalize_paths_local(price_path, rb_pos_path)
price_path = price_path(:)';
if isempty(price_path)
    error('price_path must contain at least one element.');
end

if isscalar(rb_pos_path)
    rb_pos_path = repmat(rb_pos_path, size(price_path));
else
    rb_pos_path = rb_pos_path(:)';
    if numel(rb_pos_path) ~= numel(price_path)
        error('rbPos_path must be scalar or match price_path length.');
    end
end
end

function params = default_nimby_params_local()
params = struct();
params.agemin = 25;
params.agemax = 90;
params.dage = 5;
params.rspread = 0.02;
params.ra = -0.03;
params.rent_markup = 0.02;
params.omega = 0.5;
params.theta_r = 0.9;
params.beta = 0.8;
params.eta = 2;
params.ka = 0.07;
params.bequestweight1 = 0.9 * params.beta;
params.bequestweight2 = 0.9 * params.beta;
params.CC = 0.9;
params.penalty = 1e6;
params.J = 20;
params.housingmin = 0;
params.housingmax = 25;
params.I = 50;
params.bmin = -15;
params.bmax = 15;
end

function params = apply_overrides_local(params, overrides)
if isempty(overrides)
    return;
end

fields = fieldnames(overrides);
for i = 1:numel(fields)
    params.(fields{i}) = overrides.(fields{i});
end
end

function env = get_solver_environment_cached_local(params)
persistent cached_params cached_env

if ~isempty(cached_params) && isequaln(cached_params, params)
    env = cached_env;
    return;
end

env = build_solver_environment_local(params);
cached_params = params;
cached_env = env;
end

function env = build_solver_environment_local(params)
[transitionmatrix, z, Zlifecycle, initialdist, transition_matrix_path] = load_transition_matrix_data();

env = struct();
env.ages = params.agemin:params.dage:params.agemax;
env.age_n = numel(env.ages);
env.transitionmatrix = transitionmatrix;
env.transition_matrix_path = transition_matrix_path;
env.z = z;
env.K = numel(z);
env.Zlifecycle = Zlifecycle;
env.initialdist = initialdist(:)';

env.J = params.J;
env.a = linspace(params.housingmin, params.housingmax, env.J);
env.I = params.I;
env.b = linspace(params.bmin, params.bmax, env.I);

env.bb = env.b' * ones(1, env.J);
env.aa = ones(env.I, 1) * env.a;

env.bzero = find(env.b >= 0, 1, 'first');
if isempty(env.bzero)
    [~, env.bzero] = min(abs(env.b));
end
end

function solution = solve_constant_tail_local(a_price, rb_pos, params, env, options, price_multiplier)
if nargin < 6 || isempty(price_multiplier)
    price_multiplier = 1.0;
end

solution = struct();
solution.time_varying = false;
solution.price_multiplier = price_multiplier;
solution.value = cell(1, env.age_n);
solution.index_a = cell(1, env.age_n);
solution.index_b = cell(1, env.age_n);

next_value = [];
for age_idx = env.age_n:-1:1
    if options.verbose_progress
        fprintf('    constant solve age %d\n', env.ages(age_idx));
        drawnow;
    end
    age_block = solve_age_block_local(a_price, rb_pos, params, env, age_idx, next_value, price_multiplier);
    solution.value{age_idx} = age_block.value;
    solution.index_a{age_idx} = age_block.index_a;
    solution.index_b{age_idx} = age_block.index_b;
    next_value = age_block.value;
end
end

function solution = solve_transition_path_local(price_path, rb_pos_path, tail_solution, params, env, options, price_multiplier)
if nargin < 7 || isempty(price_multiplier)
    price_multiplier = 1.0;
end

T = numel(price_path);
solution = struct();
solution.time_varying = true;
solution.price_multiplier = price_multiplier;
solution.value = cell(T, env.age_n);
solution.index_a = cell(T, env.age_n);
solution.index_b = cell(T, env.age_n);

for t = T:-1:1
    if options.verbose_progress
        fprintf('    transition solve t=%d of %d\n', t, T);
        drawnow;
    end
    for age_idx = env.age_n:-1:1
        if age_idx == env.age_n
            next_value = [];
        elseif t == T
            next_value = tail_solution.value{age_idx + 1};
        else
            next_value = solution.value{t + 1, age_idx + 1};
        end

        age_block = solve_age_block_local(price_path(t), rb_pos_path(t), params, env, age_idx, next_value, price_multiplier);
        solution.value{t, age_idx} = age_block.value;
        solution.index_a{t, age_idx} = age_block.index_a;
        solution.index_b{t, age_idx} = age_block.index_b;
    end
end
end

function age_block = solve_age_block_local(a_price, rb_pos, params, env, age_idx, next_value, price_multiplier)
if nargin < 7 || isempty(price_multiplier)
    price_multiplier = 1.0;
end

primitives = build_period_primitives_local(a_price, rb_pos, params, env, price_multiplier);

if isempty(next_value)
    [index_b, index_a, valuefunction] = solve_terminal_age_local(primitives, params, env, age_idx);
else
    z_transition = env.transitionmatrix(:, :, age_idx)';
    [index_b, index_a, valuefunction] = solve_working_age_local(primitives, params, env, age_idx, next_value, z_transition);
end

age_block = struct();
age_block.index_b = index_b;
age_block.index_a = index_a;
age_block.value = valuefunction;
end

function primitives = build_period_primitives_local(a_price, rb_pos, params, env, price_multiplier)
if nargin < 5 || isempty(price_multiplier)
    price_multiplier = 1.0;
end

rb_neg = rb_pos + params.rspread;
effective_price = a_price .* price_multiplier;
effective_r_price = (rb_neg - params.ra + params.rent_markup) .* price_multiplier;

primitives = struct();
primitives.a_price = effective_price;
primitives.rb_pos = rb_pos;
primitives.rb_neg = rb_neg;
primitives.r_price = effective_r_price;
primitives.price_multiplier = price_multiplier;
primitives.base_a_price = a_price;
primitives.Ipen = double(-env.bb > env.aa * effective_price * params.CC);
end

function price_preference = solve_price_preference_branch_local(price_path, rb_pos_path, base_tail_solution, base_path_solution, params, env, options)
multiplier = options.price_preference_multiplier;
validateattributes(multiplier, {'double'}, {'scalar', 'finite', 'real', 'positive'}, ...
    mfilename, 'options.price_preference_multiplier');

price_preference = struct();
price_preference.multiplier = multiplier;
price_preference.perturbed_price_path = multiplier .* price_path(:)';
price_preference.perturbed_tail_solution = [];
price_preference.perturbed_path_solution = [];
price_preference.tail_value_difference = [];
price_preference.tail_preference_sign = [];
price_preference.path_value_difference = [];
price_preference.path_preference_sign = [];

needs_tail = ~isempty(base_tail_solution) || ~isempty(base_path_solution);
if needs_tail
    perturbed_tail = solve_constant_tail_local(price_path(end), rb_pos_path(end), params, env, options, multiplier);
    price_preference.perturbed_tail_solution = perturbed_tail;

    if ~isempty(base_tail_solution)
        [tail_diff, tail_sign] = compare_solution_values_local(base_tail_solution.value, perturbed_tail.value);
        price_preference.tail_value_difference = tail_diff;
        price_preference.tail_preference_sign = tail_sign;
    end
else
    perturbed_tail = [];
end

if ~isempty(base_path_solution)
    perturbed_path = solve_transition_path_local(price_path, rb_pos_path, perturbed_tail, params, env, options, multiplier);
    price_preference.perturbed_path_solution = perturbed_path;
    [path_diff, path_sign] = compare_solution_values_local(base_path_solution.value, perturbed_path.value);
    price_preference.path_value_difference = path_diff;
    price_preference.path_preference_sign = path_sign;
end
end

function [value_difference, preference_sign] = compare_solution_values_local(base_value, perturbed_value)
if isempty(base_value) || isempty(perturbed_value)
    value_difference = [];
    preference_sign = [];
    return;
end

value_difference = cell(size(base_value));
preference_sign = cell(size(base_value));
for idx = 1:numel(base_value)
    value_difference{idx} = perturbed_value{idx} - base_value{idx};
    preference_sign{idx} = sign(value_difference{idx});
end
end

function [index_b, index_a, valuefunction] = solve_terminal_age_local(primitives, params, env, age_idx)
index_b = zeros(env.I, env.J, env.K);
index_a = zeros(env.I, env.J, env.K);
valuefunction = zeros(env.I, env.J, env.K);

bequest_plane = max(1e-20, env.bb + primitives.a_price .* env.aa);

for iz = 1:env.K
    labor_income = exp(env.z(iz)) * env.Zlifecycle(age_idx);
    for ij = 1:env.J
        current_a = env.a(ij);
        for ii = 1:env.I
            current_b = env.b(ii);

            consumption_plane = build_consumption_plane_local(current_b, current_a, labor_income, primitives, params, env);
            rent_plane = build_rent_plane_local(consumption_plane, primitives.r_price, params, env);

            value_plane = (consumption_plane .^ params.omega .* (env.aa + params.theta_r .* rent_plane) .^ (1 - params.omega)) .^ ...
                (1 - params.eta) / (1 - params.eta) - primitives.Ipen .* params.penalty + ...
                params.bequestweight1 * (1 + bequest_plane ./ params.bequestweight2) .^ (1 - params.eta);

            [max_value, linear_idx] = max(value_plane, [], 'all', 'linear');
            [best_b, best_a] = ind2sub([env.I, env.J], linear_idx);

            index_b(ii, ij, iz) = best_b;
            index_a(ii, ij, iz) = best_a;
            valuefunction(ii, ij, iz) = max_value;
        end
    end
end
end

function [index_b, index_a, valuefunction] = solve_working_age_local(primitives, params, env, age_idx, next_value, z_transition)
index_b = zeros(env.I, env.J, env.K);
index_a = zeros(env.I, env.J, env.K);
valuefunction = zeros(env.I, env.J, env.K);

expected_value = zeros(env.I, env.J, env.K);
for iz = 1:env.K
    for iz_next = 1:env.K
        expected_value(:, :, iz) = expected_value(:, :, iz) + z_transition(iz_next, iz) .* next_value(:, :, iz_next);
    end
end

for iz = 1:env.K
    labor_income = exp(env.z(iz)) * env.Zlifecycle(age_idx);
    continuation_plane = expected_value(:, :, iz);
    for ij = 1:env.J
        current_a = env.a(ij);
        for ii = 1:env.I
            current_b = env.b(ii);

            consumption_plane = build_consumption_plane_local(current_b, current_a, labor_income, primitives, params, env);
            rent_plane = build_rent_plane_local(consumption_plane, primitives.r_price, params, env);

            value_plane = (consumption_plane .^ params.omega .* (env.aa + params.theta_r .* rent_plane) .^ (1 - params.omega)) .^ ...
                (1 - params.eta) / (1 - params.eta) - primitives.Ipen .* params.penalty + params.beta .* continuation_plane;

            [max_value, linear_idx] = max(value_plane, [], 'all', 'linear');
            [best_b, best_a] = ind2sub([env.I, env.J], linear_idx);

            index_b(ii, ij, iz) = best_b;
            index_a(ii, ij, iz) = best_a;
            valuefunction(ii, ij, iz) = max_value;
        end
    end
end
end

function consumption_plane = build_consumption_plane_local(current_b, current_a, labor_income, primitives, params, env)
consumption_plane = zeros(env.I, env.J);
rb_current = primitives.rb_pos * (current_b >= 0) + primitives.rb_neg * (current_b < 0);
wealth_flow = labor_income + current_b * rb_current + current_a * primitives.a_price;

adjust_cost = params.ka .* (1 - (env.aa == current_a));
consumption_plane(:, 2:env.J) = max(wealth_flow - env.aa(:, 2:env.J) .* primitives.a_price .* (1 + adjust_cost(:, 2:env.J)) + ...
    current_b - env.bb(:, 2:env.J), 1e-20);
consumption_plane(:, 1) = max((wealth_flow - env.aa(:, 1) .* primitives.a_price .* (1 + adjust_cost(:, 1)) + current_b - env.bb(:, 1)) ./ ...
    (1 + ((1 - params.omega) / params.omega * params.theta_r)), 1e-20);
end

function rent_plane = build_rent_plane_local(consumption_plane, r_price, params, env)
rent_plane = zeros(env.I, env.J);
rent_plane(:, 1) = consumption_plane(:, 1) * ((1 - params.omega) / params.omega / r_price * params.theta_r);
end
