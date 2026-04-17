function results = solve_original_5yr_bellman_core(x, options)
% Reusable Bellman core extracted from the original 5-year political model.
% This mirrors SolveSS_iter.m closely, including its original price-preference
% branch quirks, but returns structured outputs instead of relying on eval.

if nargin < 2 || isempty(options)
    options = struct();
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
extension_dir = fullfile(project_root, 'extensions', 're_no_politics');
if exist(extension_dir, 'dir')
    addpath(extension_dir, '-begin');
end

ensure_external_matlab_data_paths();

params = default_params_local();
options = apply_default_options_local(options);

a_price = x(1);
rb_pos = x(2);

env = build_environment_local(params);
primitives = build_primitives_local(a_price, rb_pos, params, env, options.price_multiplier);

valuefunctions = cell(1, env.age_n);
valuefunctions_dp = cell(1, env.age_n);
d_valuefunction_dp = cell(1, env.age_n);
index_a = cell(1, env.age_n);
index_b = cell(1, env.age_n);
index_a_dp = cell(1, env.age_n);
index_b_dp = cell(1, env.age_n);

next_value = [];
next_value_dp = [];

for age_idx = env.age_n:-1:1
    if options.verbose_progress
        fprintf('Original Bellman core: age %d\n', env.ages(age_idx));
        drawnow;
    end

    if age_idx == env.age_n
        age_block = solve_terminal_age_local(primitives, params, env, age_idx);
    else
        z_transition = env.transitionmatrix(:, :, age_idx)';
        age_block = solve_working_age_local(primitives, params, env, age_idx, next_value, next_value_dp, z_transition);
    end

    valuefunctions{age_idx} = age_block.valuefunction;
    valuefunctions_dp{age_idx} = age_block.valuefunction_dp;
    d_valuefunction_dp{age_idx} = age_block.valuefunction_dp - age_block.valuefunction;
    index_a{age_idx} = age_block.index_a;
    index_b{age_idx} = age_block.index_b;
    index_a_dp{age_idx} = age_block.index_a_dp;
    index_b_dp{age_idx} = age_block.index_b_dp;

    next_value = age_block.valuefunction;
    next_value_dp = age_block.valuefunction_dp;
end

results = struct();
results.a_price = a_price;
results.rb_pos = rb_pos;
results.params = params;
results.options = options;
results.env = env;
results.primitives = primitives;
results.valuefunctions = valuefunctions;
results.valuefunctions_dp = valuefunctions_dp;
results.d_valuefunction_dp = d_valuefunction_dp;
results.index_a = index_a;
results.index_b = index_b;
results.index_a_dp = index_a_dp;
results.index_b_dp = index_b_dp;
end

function options = apply_default_options_local(options)
if ~isfield(options, 'price_multiplier') || isempty(options.price_multiplier)
    options.price_multiplier = 1.01;
end
if ~isfield(options, 'verbose_progress') || isempty(options.verbose_progress)
    options.verbose_progress = false;
end
end

function params = default_params_local()
params = struct();
params.rspread = 0.02;
params.ra = -0.03;
params.rent_markup = 0.02;
params.omega = 0.5;
params.theta_r = 0.9;
params.beta = 0.8;
params.sigma = 1.5; %#ok<STRNU>
params.eta = 2;
params.ka = 0.07;
params.bequestweight1 = 0.9 * params.beta;
params.bequestweight2 = 0.9 * params.beta;
params.CC = 0.9;
params.penalty = 1e6;
params.agemin = 25;
params.agemax = 90;
params.dage = 5;
params.J = 20;
params.housingmin = 0;
params.housingmax = 25;
params.I = 50;
params.bmin = -15;
params.bmax = 15;
end

function env = build_environment_local(params)
[transitionmatrix, z, Zlifecycle, initialdist, transition_matrix_path] = load_transition_matrix_data();

env = struct();
env.ages = params.agemin:params.dage:params.agemax;
env.age_n = numel(env.ages);
env.transitionmatrix = transitionmatrix;
env.transition_matrix_path = transition_matrix_path;
env.z = z(:)';
env.K = numel(env.z);
env.Zlifecycle = Zlifecycle(:)';
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
    if env.b(env.bzero) < 0
        env.bzero = min(env.bzero + 1, env.I);
    end
end
end

function primitives = build_primitives_local(a_price, rb_pos, params, env, price_multiplier)
rb_neg = rb_pos + params.rspread;
r_price = rb_neg - params.ra + params.rent_markup;

primitives = struct();
primitives.a_price = a_price;
primitives.rb_pos = rb_pos;
primitives.rb_neg = rb_neg;
primitives.r_price = r_price;
primitives.price_multiplier = price_multiplier;
primitives.Ipen = double(-env.bb > env.aa * a_price * params.CC);
primitives.Rb_line = rb_pos .* (env.b >= 0) + rb_neg .* (env.b < 0);
end

function age_block = solve_terminal_age_local(primitives, params, env, age_idx)
valuefunction = nan(env.I, env.J, env.K);
valuefunction_dp = nan(env.I, env.J, env.K);
index_a = nan(env.I, env.J, env.K);
index_b = nan(env.I, env.J, env.K);
index_a_dp = nan(env.I, env.J, env.K);
index_b_dp = nan(env.I, env.J, env.K);

terminal_income_scale = env.Zlifecycle(age_idx);

for iz = 1:env.K
    labor_income = exp(env.z(iz)) * terminal_income_scale;
    for ij = 1:env.J
        current_a = env.a(ij);
        for ii = 1:env.I
            current_b = env.b(ii);

            [consumption_plane, rent_plane, bequest_plane] = build_terminal_branch_local( ...
                labor_income, current_b, current_a, primitives.a_price, primitives.r_price, ...
                primitives.Rb_line(ii), params, env);

            value_plane = compute_terminal_value_plane_local( ...
                consumption_plane, rent_plane, bequest_plane, primitives.Ipen, params, env);

            [best_value, linear_idx] = max(value_plane, [], 'all', 'linear');
            [best_b, best_a] = ind2sub([env.I, env.J], linear_idx);

            valuefunction(ii, ij, iz) = best_value;
            index_b(ii, ij, iz) = best_b;
            index_a(ii, ij, iz) = best_a;

            [consumption_plane_dp, rent_plane_dp, bequest_plane_dp] = build_terminal_branch_local( ...
                labor_income, current_b, current_a, ...
                primitives.a_price * primitives.price_multiplier, ...
                primitives.r_price * primitives.price_multiplier, ...
                primitives.Rb_line(ii), params, env);

            value_plane_dp = compute_terminal_value_plane_local( ...
                consumption_plane_dp, rent_plane_dp, bequest_plane_dp, primitives.Ipen, params, env);

            [best_value_dp, linear_idx_dp] = max(value_plane_dp, [], 'all', 'linear');
            [best_b_dp, best_a_dp] = ind2sub([env.I, env.J], linear_idx_dp);

            valuefunction_dp(ii, ij, iz) = best_value_dp;
            index_b_dp(ii, ij, iz) = best_b_dp;
            index_a_dp(ii, ij, iz) = best_a_dp;
        end
    end
end

age_block = struct();
age_block.valuefunction = valuefunction;
age_block.valuefunction_dp = valuefunction_dp;
age_block.index_a = index_a;
age_block.index_b = index_b;
age_block.index_a_dp = index_a_dp;
age_block.index_b_dp = index_b_dp;
end

function age_block = solve_working_age_local(primitives, params, env, age_idx, next_value, next_value_dp, z_transition)
valuefunction = nan(env.I, env.J, env.K);
valuefunction_dp = nan(env.I, env.J, env.K);
index_a = nan(env.I, env.J, env.K);
index_b = nan(env.I, env.J, env.K);
index_a_dp = nan(env.I, env.J, env.K);
index_b_dp = nan(env.I, env.J, env.K);

expected_value = compute_expected_value_local(next_value, z_transition, env);
expected_value_dp = compute_expected_value_local(next_value_dp, z_transition, env);

income_scale = env.Zlifecycle(age_idx);

for iz = 1:env.K
    labor_income = exp(env.z(iz)) * income_scale;
    for ij = 1:env.J
        current_a = env.a(ij);
        for ii = 1:env.I
            current_b = env.b(ii);

            % Mirror SolveSS_iter exactly: the baseline younger-age branch uses
            % r_price * d_a_price in the rent denominator.
            [consumption_plane, rent_plane] = build_working_branch_local( ...
                labor_income, current_b, current_a, primitives.a_price, ...
                primitives.r_price * primitives.price_multiplier, ...
                primitives.Rb_line(ii), params, env, 'baseline');

            value_plane = compute_working_value_plane_local( ...
                consumption_plane, rent_plane, primitives.Ipen, ...
                expected_value(:, :, iz), params, env);

            [best_value, linear_idx] = max(value_plane, [], 'all', 'linear');
            [best_b, best_a] = ind2sub([env.I, env.J], linear_idx);

            valuefunction(ii, ij, iz) = best_value;
            index_b(ii, ij, iz) = best_b;
            index_a(ii, ij, iz) = best_a;

            [consumption_plane_dp, rent_plane_dp] = build_working_branch_local( ...
                labor_income, current_b, current_a, ...
                primitives.a_price * primitives.price_multiplier, ...
                primitives.r_price * primitives.price_multiplier, ...
                primitives.Rb_line(ii), params, env, 'perturbed');

            value_plane_dp = compute_working_value_plane_local( ...
                consumption_plane_dp, rent_plane_dp, primitives.Ipen, ...
                expected_value_dp(:, :, iz), params, env);

            [best_value_dp, linear_idx_dp] = max(value_plane_dp, [], 'all', 'linear');
            [best_b_dp, best_a_dp] = ind2sub([env.I, env.J], linear_idx_dp);

            valuefunction_dp(ii, ij, iz) = best_value_dp;
            index_b_dp(ii, ij, iz) = best_b_dp;
            index_a_dp(ii, ij, iz) = best_a_dp;
        end
    end
end

age_block = struct();
age_block.valuefunction = valuefunction;
age_block.valuefunction_dp = valuefunction_dp;
age_block.index_a = index_a;
age_block.index_b = index_b;
age_block.index_a_dp = index_a_dp;
age_block.index_b_dp = index_b_dp;
end

function expected_value = compute_expected_value_local(next_value, z_transition, env)
expected_value = zeros(env.I, env.J, env.K);
for iz = 1:env.K
    for iz_next = 1:env.K
        expected_value(:, :, iz) = expected_value(:, :, iz) + z_transition(iz_next, iz) .* next_value(:, :, iz_next);
    end
end
end

function [consumption_plane, rent_plane, bequest_plane] = build_terminal_branch_local( ...
    labor_income, current_b, current_a, branch_price, branch_r_price, rb_line_value, params, env)
wealth_flow = labor_income + rb_line_value .* current_b + current_a * branch_price;
adjust_cost = params.ka .* (1 - (env.aa == current_a));

consumption_plane = zeros(env.I, env.J);
consumption_plane(:, 2:env.J) = max( ...
    wealth_flow - env.aa(:, 2:env.J) .* branch_price .* (1 + adjust_cost(:, 2:env.J)) + current_b - env.bb(:, 2:env.J), ...
    1e-20);
consumption_plane(:, 1) = max( ...
    (wealth_flow - env.aa(:, 1) .* branch_price .* (1 + adjust_cost(:, 1)) + current_b - env.bb(:, 1)) ./ ...
    (1 + ((1 - params.omega) / params.omega * params.theta_r)), ...
    1e-20);

rent_plane = zeros(env.I, env.J);
rent_plane(:, 1) = consumption_plane(:, 1) .* ((1 - params.omega) / params.omega / branch_r_price * params.theta_r);

bequest_plane = max(1e-20, env.bb + branch_price .* env.aa);
end

function value_plane = compute_terminal_value_plane_local(consumption_plane, rent_plane, bequest_plane, Ipen, params, env)
value_plane = compute_utility_plane_local(consumption_plane, rent_plane, params, env) - Ipen .* params.penalty + ...
    params.bequestweight1 .* (1 + bequest_plane ./ params.bequestweight2) .^ (1 - params.eta);
end

function [consumption_plane, rent_plane] = build_working_branch_local( ...
    labor_income, current_b, current_a, branch_price, branch_r_price, rb_line_value, params, env, branch_mode)
wealth_flow = labor_income + rb_line_value .* current_b + current_a * branch_price;
adjust_cost = params.ka .* (1 - (env.aa == current_a));

consumption_plane = zeros(env.I, env.J);
consumption_plane(:, 2:env.J) = max( ...
    wealth_flow - env.aa(:, 2:env.J) .* branch_price .* (1 + adjust_cost(:, 2:env.J)) + current_b - env.bb(:, 2:env.J), ...
    1e-20);
consumption_plane(:, 1) = max( ...
    (wealth_flow - env.aa(:, 1) .* branch_price .* (1 + adjust_cost(:, 1)) + current_b - env.bb(:, 1)) ./ ...
    (1 + ((1 - params.omega) / params.omega * params.theta_r)), ...
    1e-20);

rent_plane = zeros(env.I, env.J);
if strcmp(branch_mode, 'perturbed')
    rent_plane(:, 1) = consumption_plane(:, 1) ./ branch_r_price .* params.theta_r .* params.omega;
else
    rent_plane(:, 1) = consumption_plane(:, 1) .* ((1 - params.omega) / params.omega / branch_r_price * params.theta_r);
end
end

function value_plane = compute_working_value_plane_local(consumption_plane, rent_plane, Ipen, continuation_plane, params, env)
value_plane = compute_utility_plane_local(consumption_plane, rent_plane, params, env) - Ipen .* params.penalty + ...
    params.beta .* continuation_plane;
end

function utility_plane = compute_utility_plane_local(consumption_plane, rent_plane, params, env)
utility_plane = (consumption_plane .^ params.omega .* (env.aa + params.theta_r .* rent_plane) .^ (1 - params.omega)) .^ ...
    (1 - params.eta) ./ (1 - params.eta);
end
