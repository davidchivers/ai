function results = solve_household_path_fertility(q_path, overrides, options)
% solve_household_path_fertility.m
%
% Stage 1 of the structural transition-path RE build:
% solve the household Bellman problem backward on a finite exogenous
% five-year price path.

if nargin < 2 || isempty(overrides)
    overrides = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

project_root = fileparts(fileparts(mfilename('fullpath')));
project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end
ensure_external_matlab_data_paths();

cfg = fertility_benchmark_config();
params = default_fertility_params_tp();
params = apply_overrides_tp(params, overrides);
options = apply_default_options_tp(options, cfg, q_path);
[q_path, rb_pos_path] = normalize_paths_tp(q_path, options.rbPos_path);

env = get_solver_environment_cached_tp(params);
backend_summary = struct();
switch lower(char(options.transition_backend))
    case 'matlab'
        [tail_solution, path_solution] = solve_transition_path_matlab_backend_tp(q_path, rb_pos_path, params, env, options);
    case 'sidecar_mex'
        [tail_solution, path_solution, backend_summary] = ...
            solve_transition_path_sidecar_backend_tp(project_root, q_path, rb_pos_path, params, env, options);
    otherwise
        error('Unknown transition_backend "%s".', options.transition_backend);
end

results = struct();
results.q_path = q_path;
results.rb_pos_path = rb_pos_path;
results.params = params;
results.options = options;
results.env = struct( ...
    'ages', env.ages, ...
    'a_grid', env.a, ...
    'b_grid', env.b, ...
    'leave_profile', env.leave_profile);
results.core_env = env;
results.transition_backend = char(options.transition_backend);
results.backend_summary = backend_summary;
results.tail_solution = tail_solution;
results.path_solution = path_solution;
end

function options = apply_default_options_tp(options, cfg, q_path)
if ~isfield(options, 'rbPos_path') || isempty(options.rbPos_path)
    options.rbPos_path = cfg.rbPos;
end
if ~isfield(options, 'terminal_rule') || isempty(options.terminal_rule)
    options.terminal_rule = 'constant_price_tail';
end
if ~isfield(options, 'return_value_functions') || isempty(options.return_value_functions)
    options.return_value_functions = true;
end
if ~isfield(options, 'initial_q') || isempty(options.initial_q)
    options.initial_q = q_path(1);
end
if ~isfield(options, 'verbose_progress') || isempty(options.verbose_progress)
    options.verbose_progress = false;
end
if ~isfield(options, 'transition_backend') || isempty(options.transition_backend)
    options.transition_backend = 'matlab';
else
    options.transition_backend = char(string(options.transition_backend));
end
if ~isfield(options, 'sidecar_mex_toolchain_root') || isempty(options.sidecar_mex_toolchain_root)
    options.sidecar_mex_toolchain_root = "D:/codex_tools/winlibs-posix-ucrt/mingw64";
end
if ~isfield(options, 'sidecar_mex_force_rebuild') || isempty(options.sidecar_mex_force_rebuild)
    options.sidecar_mex_force_rebuild = false;
end
if ~isfield(options, 'return_tail_solution') || isempty(options.return_tail_solution)
    options.return_tail_solution = true;
end
if ~isfield(options, 'return_path_solution') || isempty(options.return_path_solution)
    options.return_path_solution = true;
end
if ~isfield(options, 'path_solution_scope') || isempty(options.path_solution_scope)
    options.path_solution_scope = 'full';
else
    options.path_solution_scope = char(string(options.path_solution_scope));
end
end

function env = get_solver_environment_cached_tp(params)
persistent cached_params cached_env

if ~isempty(cached_params) && isequaln(cached_params, params)
    env = cached_env;
    return;
end

env = build_solver_environment_tp(params);
cached_params = params;
cached_env = env;
end

function [q_path, rb_pos_path] = normalize_paths_tp(q_path, rb_pos_path)
q_path = q_path(:)';
if isempty(q_path)
    error('q_path must contain at least one element.');
end

if isscalar(rb_pos_path)
    rb_pos_path = repmat(rb_pos_path, size(q_path));
else
    rb_pos_path = rb_pos_path(:)';
    if numel(rb_pos_path) ~= numel(q_path)
        error('rbPos_path must be scalar or match q_path length.');
    end
end
end

function env = build_solver_environment_tp(params)
env = struct();

env.ages = params.agemin:params.dage:params.agemax;
env.age_n = numel(env.ages);
env.leave_profile = build_leave_profile_tp(params, env.ages);

tmp = load(params.transition_matrix_file);
env.transitionmatrix = tmp.transitionmatrix;
env.z = tmp.y_mid;
env.K = size(env.z, 2);
env.Zlifecycle = tmp.z_lifecycle ./ tmp.z_lifecycle(1);
if isfield(tmp, 'initialdist') && ~isempty(tmp.initialdist)
    env.initialdist = tmp.initialdist(:)';
else
    env.initialdist = stationary_dist_tp(env.transitionmatrix(:, :, 1));
end

if size(env.transitionmatrix, 3) < max(env.age_n - 1, 0)
    error('%s only provides %d age transitions, but the solver needs %d.', ...
        params.transition_matrix_file, size(env.transitionmatrix, 3), max(env.age_n - 1, 0));
end
if numel(env.Zlifecycle) < env.age_n
    error('%s only provides %d lifecycle points, but the solver needs %d.', ...
        params.transition_matrix_file, numel(env.Zlifecycle), env.age_n);
end

if ~isempty(params.housing_grid)
    env.a = params.housing_grid(:)';
    env.J = numel(env.a);
else
    env.J = params.J;
    env.a = linspace(params.housingmin, params.housingmax, env.J);
end

env.I = params.I;
env.b = linspace(params.bmin, params.bmax, env.I);
env.bb = env.b' * ones(1, env.J);
env.aa = ones(env.I, 1) * env.a;
env.penalty = params.penalty;
env.cohortsize = build_cohort_weights_tp(params, env.ages);
env.home_grid = 0:(params.C - 1);
env.H = numel(env.home_grid);
env.home_index = @(n) min(max(round(n), 0), env.H - 1) + 1;
env.parity_grid = 0:(params.P - 1);
env.P = numel(env.parity_grid);
env.parity_index = @(n) min(max(round(n), 0), env.P - 1) + 1;
[~, env.bzero] = min(abs(env.b));
if env.b(env.bzero) < 0
    env.bzero = env.bzero + 1;
end
end

function solution = solve_constant_tail_tp(q_value, rb_pos, params, env, options)
solution = initialize_solution_container_tp(1, env.age_n);
solution.time_varying = false;

next_value = [];
for age_pos = env.age_n:-1:1
    if options.verbose_progress
        fprintf('    tail solve age %d\n', env.ages(age_pos));
        drawnow;
    end
    age_block = solve_age_block_tp(q_value, rb_pos, params, env, age_pos, next_value);
    solution.value{age_pos} = age_block.value;
    solution.index_a{age_pos} = age_block.index_a;
    solution.index_b{age_pos} = age_block.index_b;
    solution.birth_prob{age_pos} = age_block.birth_prob;
    solution.index_a_birth{age_pos} = age_block.index_a_birth;
    solution.index_b_birth{age_pos} = age_block.index_b_birth;
    next_value = age_block.value;
end
end

function solution = solve_transition_path_tp(q_path, rb_pos_path, tail_solution, params, env, options)
T = numel(q_path);
solution = initialize_solution_container_tp(T, env.age_n);
solution.time_varying = true;

for t = T:-1:1
    if options.verbose_progress
        fprintf('    transition solve t=%d of %d\n', t, T);
        drawnow;
    end
    for age_pos = env.age_n:-1:1
        if options.verbose_progress
            fprintf('      age %d\n', env.ages(age_pos));
            drawnow;
        end
        if age_pos == env.age_n
            next_value = [];
        elseif t == T
            next_value = tail_solution.value{age_pos + 1};
        else
            next_value = solution.value{t + 1, age_pos + 1};
        end

        age_block = solve_age_block_tp(q_path(t), rb_pos_path(t), params, env, age_pos, next_value);
        solution.value{t, age_pos} = age_block.value;
        solution.index_a{t, age_pos} = age_block.index_a;
        solution.index_b{t, age_pos} = age_block.index_b;
        solution.birth_prob{t, age_pos} = age_block.birth_prob;
        solution.index_a_birth{t, age_pos} = age_block.index_a_birth;
        solution.index_b_birth{t, age_pos} = age_block.index_b_birth;
    end
end
end

function [tail_solution, path_solution] = solve_transition_path_matlab_backend_tp(q_path, rb_pos_path, params, env, options)
tail_solution_full = solve_constant_tail_tp(q_path(end), rb_pos_path(end), params, env, options);

if options.return_tail_solution
    tail_solution = tail_solution_full;
else
    tail_solution = [];
end

if options.return_path_solution
    path_solution = solve_transition_path_tp(q_path, rb_pos_path, tail_solution_full, params, env, options);
    if strcmpi(options.path_solution_scope, 'value_only')
        path_solution = strip_path_solution_to_value_only_tp(path_solution);
    end
else
    path_solution = [];
end
end

function [tail_solution, path_solution, backend_summary] = solve_transition_path_sidecar_backend_tp(project_root, q_path, rb_pos_path, params, env, options)
sidecar_matlab_dir = fullfile(project_root, 'compiled_sidecar', 'matlab');
if ~exist(sidecar_matlab_dir, 'dir')
    error('Compiled sidecar MATLAB directory not found: %s', sidecar_matlab_dir);
end

added_sidecar_path = false;
if ~contains(path, sidecar_matlab_dir, 'IgnoreCase', ispc)
    addpath(sidecar_matlab_dir);
    added_sidecar_path = true;
end
cleanup_sidecar = onCleanup(@() remove_path_if_added_local(sidecar_matlab_dir, added_sidecar_path)); %#ok<NASGU>

mex_path = build_transition_path_mex(options.sidecar_mex_toolchain_root, options.sidecar_mex_force_rebuild);
bin_dir = fileparts(mex_path);
added_bin_path = false;
if ~contains(path, bin_dir, 'IgnoreCase', ispc)
    addpath(bin_dir);
    added_bin_path = true;
end
cleanup_bin = onCleanup(@() remove_path_if_added_local(bin_dir, added_bin_path)); %#ok<NASGU>

path_case = build_transition_path_case_struct(q_path, rb_pos_path, params, env, ...
    sprintf('solve_household_path_fertility_T%d', numel(q_path)));
mex_mode = choose_sidecar_mode_tp(options);
mex_result = fertility_transition_path_mex(path_case, mex_mode);

tail_solution = mex_result.tail_solution;
path_solution = mex_result.path_solution;
backend_summary = rmfield(mex_result, {'tail_solution', 'path_solution'});
backend_summary.mex_path = mex_path;
end

function mex_mode = choose_sidecar_mode_tp(options)
if ~options.return_tail_solution && ~options.return_path_solution
    error('At least one of return_tail_solution or return_path_solution must be true.');
end

if options.return_tail_solution && options.return_path_solution
    if strcmpi(options.path_solution_scope, 'value_only')
        error('path_solution_scope="value_only" is invalid when both tail and path solutions are requested.');
    end
    mex_mode = 'full';
    return;
end

if options.return_tail_solution
    mex_mode = 'tail_only';
    return;
end

if strcmpi(options.path_solution_scope, 'value_only')
    mex_mode = 'path_value_only';
else
    mex_mode = 'path_only';
end
end

function solution = initialize_solution_container_tp(T, age_n)
if T == 1
    solution.value = cell(age_n, 1);
    solution.index_a = cell(age_n, 1);
    solution.index_b = cell(age_n, 1);
    solution.birth_prob = cell(age_n, 1);
    solution.index_a_birth = cell(age_n, 1);
    solution.index_b_birth = cell(age_n, 1);
else
    solution.value = cell(T, age_n);
    solution.index_a = cell(T, age_n);
    solution.index_b = cell(T, age_n);
    solution.birth_prob = cell(T, age_n);
    solution.index_a_birth = cell(T, age_n);
    solution.index_b_birth = cell(T, age_n);
end
end

function remove_path_if_added_local(target_path, was_added)
if was_added && contains(path, target_path, 'IgnoreCase', ispc)
    rmpath(target_path);
end
end

function solution = strip_path_solution_to_value_only_tp(solution)
solution.index_a = [];
solution.index_b = [];
solution.birth_prob = [];
solution.index_a_birth = [];
solution.index_b_birth = [];
end

function age_block = solve_age_block_tp(q_current, rb_pos, params, env, age_pos, next_value)
rb_neg = rb_pos + params.rspread;
r_price = rb_neg - params.ra + params.rent_markup;
age = env.ages(age_pos);
fertile = any(params.birth_ages == age) && env.P > 1;

valuefunction = NaN(env.I, env.J, env.K, env.H, env.P);
index_a = NaN(env.I, env.J, env.K, env.H, env.P);
index_b = NaN(env.I, env.J, env.K, env.H, env.P);
index_a_birth = NaN(env.I, env.J, env.K, env.H, env.P);
index_b_birth = NaN(env.I, env.J, env.K, env.H, env.P);
birth_prob = zeros(env.I, env.J, env.K, env.H, env.P);

for ih = 1:env.H
    home_count = env.home_grid(ih);
    leave_prob = env.leave_profile(age_pos);
    ih_keep = ih;
    ih_decay = env.home_index(max(home_count - 1, 0));
    ih_birth_keep = env.home_index(min(home_count + 1, env.H - 1));
    ih_birth_decay = env.home_index(min(max(home_count - 1, 0) + 1, env.H - 1));

    for ip = 1:env.P
        parity_count = env.parity_grid(ip);
        can_birth = fertile && parity_count < (env.P - 1);
        ip_birth = env.parity_index(min(parity_count + 1, env.P - 1));
        realized_birth_weight = get_realized_birth_weight_by_age_and_parity_tp(params, age, parity_count);

        for iz = 1:env.K
            if age_pos < env.age_n && ~isempty(next_value)
                z_transition = env.transitionmatrix(:, :, age_pos);
                expected_nobirth = expected_value_plane_tp(z_transition(iz, :), next_value, ih_keep, ih_decay, ip, leave_prob);
                if can_birth
                    expected_birth = expected_value_plane_tp(z_transition(iz, :), next_value, ih_birth_keep, ih_birth_decay, ip_birth, leave_prob);
                else
                    expected_birth = zeros(env.I, env.J);
                end
            else
                expected_nobirth = zeros(env.I, env.J);
                expected_birth = zeros(env.I, env.J);
            end

            income = exp(env.z(iz)) * env.Zlifecycle(age_pos);

            for ij = 1:env.J
                for ii = 1:env.I
                    [maxvalue_nb, ind_b_nb, ind_a_nb] = solve_branch_tp(ii, ij, income, env.aa, env.bb, ...
                        q_current, r_price, rb_pos, rb_neg, env.a, env.penalty, params, ...
                        home_count, parity_count, expected_nobirth, false, age_pos == env.age_n, age);

                    index_b(ii, ij, iz, ih, ip) = ind_b_nb;
                    index_a(ii, ij, iz, ih, ip) = ind_a_nb;
                    index_b_birth(ii, ij, iz, ih, ip) = ind_b_nb;
                    index_a_birth(ii, ij, iz, ih, ip) = ind_a_nb;

                    if can_birth
                        [maxvalue_b, ind_b_b, ind_a_b] = solve_branch_tp(ii, ij, income, env.aa, env.bb, ...
                            q_current, r_price, rb_pos, rb_neg, env.a, env.penalty, params, ...
                            home_count, parity_count, expected_birth, true, age_pos == env.age_n, age);

                        try_value = realized_birth_weight * maxvalue_b + (1 - realized_birth_weight) * maxvalue_nb;
                        try_prob = logistic_prob_tp(try_value - maxvalue_nb, params.logit_scale);
                        birth_prob(ii, ij, iz, ih, ip) = try_prob * realized_birth_weight;
                        valuefunction(ii, ij, iz, ih, ip) = smooth_value_tp(maxvalue_nb, try_value, params.logit_scale);
                        index_b_birth(ii, ij, iz, ih, ip) = ind_b_b;
                        index_a_birth(ii, ij, iz, ih, ip) = ind_a_b;
                    else
                        valuefunction(ii, ij, iz, ih, ip) = maxvalue_nb;
                    end
                end
            end
        end
    end
end

age_block = struct();
age_block.value = valuefunction;
age_block.index_a = index_a;
age_block.index_b = index_b;
age_block.birth_prob = birth_prob;
age_block.index_a_birth = index_a_birth;
age_block.index_b_birth = index_b_birth;
end

function [maxvalue, ind_b, ind_a] = solve_branch_tp(ii, ij, income, aa, bb, a_price, r_price, ...
    rbPos, rbNeg, a_grid, penalty_value, params, home_count, parity_count, continuation_value, is_birth, is_terminal, age)

current_b = bb(ii, ij);
current_gross_resources = income + current_b * (1 + current_asset_return_rate_tp(current_b, ij, params, rbPos, rbNeg)) ...
    + a_grid(ij) * a_price;
choice_penalty = build_choice_penalty_tp(aa, bb, a_price, income, rbPos, params, current_b, ij, age, parity_count);
owner_entry_gift = owner_entry_deposit_gift_tp(params, ij, current_b, age);
owner_purchase_cost = aa(:, 2:end) * a_price .* (1 + params.ka * (1 - (aa(:, 2:end) == a_grid(ij))));
value_plane_no_gift = build_value_plane_tp(0.0);
if owner_entry_gift > 0
    value_plane_with_gift = build_value_plane_tp(owner_entry_gift);
    if params.owner_entry_deposit_only_if_marginal && ij == 1
        renter_best = max(value_plane_no_gift(:, 1), [], 'all');
        owner_best_no_gift = max(value_plane_no_gift(:, 2:end), [], 'all');
        owner_best_with_gift = max(value_plane_with_gift(:, 2:end), [], 'all');
        if owner_best_no_gift < renter_best && owner_best_with_gift > renter_best
            value_plane = value_plane_with_gift;
        else
            value_plane = value_plane_no_gift;
        end
    else
        value_plane = value_plane_with_gift;
    end
else
    value_plane = value_plane_no_gift;
end

    function value_plane = build_value_plane_tp(applied_owner_entry_gift)
        consumption_plane = zeros(size(aa));
        budget_penalty = zeros(size(aa));

        owner_consumption_raw = current_gross_resources + applied_owner_entry_gift ...
            - owner_purchase_cost ...
            - bb(:, 2:end);
        consumption_plane(:, 2:end) = max(owner_consumption_raw, 1e-20);
        budget_penalty(:, 2:end) = double(owner_consumption_raw <= 0);

        theta_r_current = effective_theta_r_tp(params, home_count);
        renter_consumption_raw = (current_gross_resources ...
            - aa(:, 1) * a_price .* (1 + params.ka * (1 - (aa(:, 1) == a_grid(ij)))) ...
            - bb(:, 1)) / (1 + params.s_h * theta_r_current);
        consumption_plane(:, 1) = max(renter_consumption_raw, 1e-20);
        budget_penalty(:, 1) = double(renter_consumption_raw <= 0);

        rent_plane = zeros(size(aa));
        rent_plane(:, 1) = consumption_plane(:, 1) ./ r_price * theta_r_current * params.s_h;

        h_services = aa + theta_r_current * rent_plane;
        h_eff = max(h_services, 1e-8) ./ ((1 + params.lambda_crowd * home_count) ^ params.psi_crowd);
        space_penalty = housing_mismatch_penalty_tp(params, home_count, h_services);

        value_plane = log(consumption_plane) + params.s_h * log(h_eff) + params.child_utility * home_count ...
            - space_penalty - (choice_penalty + budget_penalty) * penalty_value;

        if is_birth
            n_eff = min(home_count + 1, params.C - 1);
            theta_r_birth = effective_theta_r_tp(params, n_eff);
            consumption_plane_birth = consumption_plane;
            budget_penalty_birth = budget_penalty;
            renter_consumption_birth_raw = (current_gross_resources ...
                - aa(:, 1) * a_price .* (1 + params.ka * (1 - (aa(:, 1) == a_grid(ij)))) ...
                - bb(:, 1)) / (1 + params.s_h * theta_r_birth);
            consumption_plane_birth(:, 1) = max(renter_consumption_birth_raw, 1e-20);
            budget_penalty_birth(:, 1) = double(renter_consumption_birth_raw <= 0);
            rent_plane_birth = zeros(size(aa));
            rent_plane_birth(:, 1) = consumption_plane_birth(:, 1) ./ r_price * theta_r_birth * params.s_h;
            h_services_birth = aa + theta_r_birth * rent_plane_birth;
            h_eff_birth = max(h_services_birth, 1e-8) ./ ((1 + params.lambda_crowd * n_eff) ^ params.psi_crowd);
            space_penalty_birth = housing_mismatch_penalty_tp(params, n_eff, h_services_birth);
            birth_utility_n = get_parity_birth_utility_tp(params, parity_count);
            value_plane = log(consumption_plane_birth) + params.s_h * log(h_eff_birth) + params.child_utility * n_eff ...
                + birth_utility_n - params.birth_cost - params.birth_price_coeff * a_price ...
                - space_penalty_birth - (choice_penalty + budget_penalty_birth) * penalty_value;
        end

        if is_terminal
            bequest_plane = max(1e-20, bb + a_price .* aa);
            value_plane = value_plane + params.bequestweight * log(bequest_plane);
        else
            value_plane = value_plane + params.beta * continuation_value;
        end
    end

[maxvalue, linear_idx] = max(value_plane, [], 'all', 'linear');
[ind_b, ind_a] = ind2sub(size(value_plane), linear_idx);
end

function rate = current_asset_return_rate_tp(current_b, current_housing_index, params, rbPos, rbNeg)
if current_b >= 0
    rate = rbPos;
    return;
end

if current_housing_index > 1
    rate = rbPos + params.owner_mortgage_spread;
else
    rate = rbNeg;
end
end

function gift = owner_entry_deposit_gift_tp(params, current_housing_index, current_b, age)
gift = 0.0;
if params.owner_entry_deposit_gift <= 0
    return;
end
if current_housing_index ~= 1
    return;
end
if age > params.owner_entry_deposit_age_max
    return;
end
if current_b < params.owner_entry_deposit_b_min || current_b > params.owner_entry_deposit_b_max
    return;
end
gift = params.owner_entry_deposit_gift;
end

function choice_penalty = build_choice_penalty_tp(aa, bb, a_price, income, rbPos, params, current_b, current_housing_index, age, parity_count)
choice_penalty = zeros(size(aa));
choice_penalty(:, 1) = double(-bb(:, 1) > aa(:, 1) * a_price * params.CC);
choice_penalty(:, 2:end) = double(-bb(:, 2:end) > aa(:, 2:end) * a_price * params.owner_mortgage_CC);

if age <= params.owner_entry_age_max && current_housing_index == 1 && params.owner_entry_b_floor > -1e8
    if current_b < params.owner_entry_b_floor
        choice_penalty(:, 2:end) = 1;
    end
end

if age <= params.owner_entry_mortgage_age_max && current_housing_index == 1 && params.owner_entry_mortgage_floor > 0
    min_entry_mortgage = aa(:, 2:end) * a_price * params.owner_entry_mortgage_floor;
    choice_penalty(:, 2:end) = max(choice_penalty(:, 2:end), double(-bb(:, 2:end) < min_entry_mortgage));
end

if age <= params.owner_min_mortgage_age_max && params.owner_min_mortgage_share > 0
    min_owner_mortgage = aa(:, 2:end) * a_price * params.owner_min_mortgage_share;
    choice_penalty(:, 2:end) = max(choice_penalty(:, 2:end), double(-bb(:, 2:end) < min_owner_mortgage));
end

if age <= params.owner_entry_payment_to_income_age_max && current_housing_index == 1 ...
        && isfinite(params.owner_entry_payment_to_income_cap)
    mortgage_balance = max(-bb(:, 2:end), 0);
    mortgage_payment_rate = max(rbPos + params.owner_mortgage_spread, 0) + params.owner_mortgage_amortization;
    qualifying_income_multiplier = params.owner_entry_income_multiplier;
    if parity_count > 0
        qualifying_income_multiplier = params.owner_entry_income_multiplier_after_birth;
    end
    qualifying_income = max(income * max(qualifying_income_multiplier, 1e-8), 1e-8);
    payment_to_income = (mortgage_balance * mortgage_payment_rate) / qualifying_income;
    choice_penalty(:, 2:end) = max(choice_penalty(:, 2:end), double(payment_to_income > params.owner_entry_payment_to_income_cap));
end

if current_housing_index > 1 && current_b < 0 && params.owner_mortgage_amortization > 0
    amortized_floor = current_b * (1 - params.owner_mortgage_amortization);
    choice_penalty(:, 2:end) = max(choice_penalty(:, 2:end), double(bb(:, 2:end) < amortized_floor));
end
end

function theta_r_eff = effective_theta_r_tp(params, child_count)
theta_r_eff = params.theta_r * max(0.05, 1 - params.theta_r_child_penalty * child_count);
end

function penalty = housing_mismatch_penalty_tp(params, child_count, h_services)
if params.family_space_floor <= 0 || child_count <= 0 || ...
        (params.family_space_penalty <= 0 && params.family_space_fixed_penalty <= 0)
    penalty = zeros(size(h_services));
    return;
end
required_space = params.family_space_floor * child_count;
shortfall = max(0, required_space - h_services);
penalty = params.family_space_penalty * shortfall;
if params.family_space_fixed_penalty > 0
    penalty = penalty + params.family_space_fixed_penalty * double(shortfall > 0);
end
end

function expected = expected_value_plane_tp(z_probs, value_next, ih_keep, ih_decay, ip_next, p_leave)
[I, J, K, ~, ~] = size(value_next);
expected = zeros(I, J);
blended = p_leave * value_next(:, :, :, ih_decay, ip_next) + (1 - p_leave) * value_next(:, :, :, ih_keep, ip_next);
for iz_next = 1:K
    expected = expected + z_probs(iz_next) * blended(:, :, iz_next);
end
end

function stat = stationary_dist_tp(z_transition)
[vec, ~] = eigs(z_transition', 1, 'largestreal');
stat = real(vec);
stat = max(stat, 0);
stat = stat ./ sum(stat);
end

function prob = logistic_prob_tp(delta, scale)
if scale <= 0
    prob = double(delta > 0);
    return;
end
arg = max(-30, min(30, delta / scale));
prob = 1 / (1 + exp(-arg));
end

function val = smooth_value_tp(v0, v1, scale)
if scale <= 0
    val = max(v0, v1);
    return;
end
mx = max(v0, v1);
val = mx + scale * log(exp((v0 - mx) / scale) + exp((v1 - mx) / scale));
end

function params = default_fertility_params_tp()
benchmark_cfg = fertility_benchmark_config();
project_root = fileparts(fileparts(mfilename('fullpath')));

params.rspread = 0.02;
params.ra = -0.03;
params.rent_markup = 0.02;
params.s_h = 1;
params.theta_r = 0.85;
params.beta = 0.98;
params.ka = 0.06;
params.bequestweight = 0.98;
params.CC = 0.9;
params.penalty = 1e6;

params.agemin = 25;
params.agemax = 80;
params.dage = 5;

params.J = 10;
params.housingmin = 0;
params.housingmax = 15;
params.housing_grid = [];
params.I = 50;
params.bmin = -20;
params.bmax = 20;

params.C = 4;
params.P = 4;
params.birth_utility = 0.28;
params.birth_utility_by_parity = [1.16 1.49 1.51];
params.child_utility = 0.05;
params.birth_cost = 0.05;
params.birth_price_coeff = 0.34;
params.logit_scale = 0.15;
params.lambda_crowd = 0.265;
params.psi_crowd = 0.70;
params.p_leave = 0.30;
params.birth_ages = [25 30 35 40];
params.birth_age_weights = [0.25 0.25 0.25 0.25];
params.realized_birth_weights = ones(size(params.birth_ages));
params.first_birth_realized_weights = [];
params.theta_r_child_penalty = 0.0;
params.family_space_floor = 0.0;
params.family_space_penalty = 0.0;
params.family_space_fixed_penalty = 0.0;
params.parental_transfer_share = 0.0;
params.parental_transfer_b_boost = 0.0;
params.initial_b_points = [];
params.initial_b_shares = [];
params.owner_entry_deposit_gift = 0.0;
params.owner_entry_deposit_age_max = 0;
params.owner_entry_deposit_b_min = -inf;
params.owner_entry_deposit_b_max = inf;
params.owner_entry_deposit_only_if_marginal = false;
params.owner_entry_b_floor = -1e9;
params.owner_entry_age_max = inf;
params.owner_entry_mortgage_floor = 0.0;
params.owner_entry_mortgage_age_max = inf;
params.owner_min_mortgage_share = 0.0;
params.owner_min_mortgage_age_max = 0;
params.owner_entry_payment_to_income_cap = inf;
params.owner_entry_payment_to_income_age_max = inf;
params.owner_entry_income_multiplier = 1.0;
params.owner_entry_income_multiplier_after_birth = 1.0;
params.owner_mortgage_CC = NaN;
params.owner_mortgage_spread = NaN;
params.owner_mortgage_amortization = 0.0;
params.leave_home_age_bins = [20 25 30];
params.leave_home_bin_probs = [0.588 0.147 0.265];
params.cohort_weights_by_age = [];
params.transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_5y_25_80.mat');

params = apply_overrides_tp(params, benchmark_cfg.overrides);
if isnan(params.owner_mortgage_CC)
    params.owner_mortgage_CC = params.CC;
end
if isnan(params.owner_mortgage_spread)
    params.owner_mortgage_spread = params.rspread;
end
end

function s = apply_overrides_tp(s, overrides)
fields = fieldnames(overrides);
for i = 1:numel(fields)
    s.(fields{i}) = overrides.(fields{i});
end
end

function val = get_parity_birth_utility_tp(params, n)
if isfield(params, 'birth_utility_by_parity') && ~isempty(params.birth_utility_by_parity)
    idx = min(max(n + 1, 1), numel(params.birth_utility_by_parity));
    val = params.birth_utility_by_parity(idx);
else
    val = params.birth_utility;
end
end

function w = get_realized_birth_weight_by_age_and_parity_tp(params, age, parity_count)
if parity_count == 0 && isfield(params, 'first_birth_realized_weights') && ~isempty(params.first_birth_realized_weights)
    weights = params.first_birth_realized_weights;
elseif isfield(params, 'realized_birth_weights') && ~isempty(params.realized_birth_weights)
    weights = params.realized_birth_weights;
else
    weights = 1;
end
idx = find(params.birth_ages == age, 1);
if isempty(idx)
    w = 1;
    return;
end
w = weights(min(idx, numel(weights)));
w = min(max(w, 0), 1);
end

function leave_profile = build_leave_profile_tp(params, ages)
if isfield(params, 'leave_home_age_bins') && ~isempty(params.leave_home_age_bins)
    leave_profile = build_leave_profile_from_bins_tp(params, ages);
else
    leave_profile = repmat(params.p_leave, 1, numel(ages));
end
leave_profile = min(max(leave_profile, 0), 1);
end

function leave_profile = build_leave_profile_from_bins_tp(params, ages)
dage = params.dage;
birth_ages = params.birth_ages(:)';
birth_weights = params.birth_age_weights(:)';
birth_weights = birth_weights ./ sum(birth_weights);
leave_home_ages = params.leave_home_age_bins(:)';
leave_home_probs = params.leave_home_bin_probs(:)';
leave_home_probs = leave_home_probs ./ sum(leave_home_probs);

leave_profile = zeros(1, numel(ages));
for ia = 1:numel(ages)
    age = ages(ia);
    active_mass = 0;
    exit_mass = 0;

    for ib = 1:numel(birth_ages)
        birth_age = birth_ages(ib);
        if age < birth_age
            continue;
        end
        for id = 1:numel(leave_home_ages)
            leave_age = leave_home_ages(id);
            weight = birth_weights(ib) * leave_home_probs(id);
            exit_parent_age = birth_age + leave_age;
            if age < exit_parent_age
                active_mass = active_mass + weight;
                if age + dage >= exit_parent_age
                    exit_mass = exit_mass + weight;
                end
            end
        end
    end

    if active_mass > 0
        leave_profile(ia) = exit_mass / active_mass;
    else
        leave_profile(ia) = 1;
    end
end
end

function cohortsize = build_cohort_weights_tp(params, ages)
if isfield(params, 'cohort_weights_by_age') && ~isempty(params.cohort_weights_by_age)
    cohortsize = params.cohort_weights_by_age(:)';
    if numel(cohortsize) ~= numel(ages)
        error('cohort_weights_by_age has %d elements, but the solver age grid has %d ages.', ...
            numel(cohortsize), numel(ages));
    end
elseif params.dage == 5
    cohortsize = expand_five_year_cohort_profile_tp(ages);
elseif params.dage == 1
    cohortsize = expand_five_year_cohort_profile_tp(ages);
else
    cohortsize = ones(1, numel(ages));
end

if any(~isfinite(cohortsize)) || any(cohortsize <= 0)
    error('Cohort weights must be finite and strictly positive.');
end
cohortsize = cohortsize ./ mean(cohortsize);
end

function cohortsize = expand_five_year_cohort_profile_tp(ages)
base_ages = 25:5:90;
base_weights = [14 12 10 10 10 10 9 8 7 5 4 2 1 1];
cohortsize = zeros(1, numel(ages));

for ia = 1:numel(ages)
    idx = find(base_ages <= ages(ia), 1, 'last');
    if isempty(idx)
        idx = 1;
    end
    cohortsize(ia) = base_weights(min(idx, numel(base_weights)));
end
end
