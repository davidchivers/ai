function run_transition_value_wedge_audit_fertility_main()
% run_transition_value_wedge_audit_fertility_main.m
%
% Decompose the age-25 owner-versus-renter value gap for the middle income
% states that drive the transition surge.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

this_code_dir = fullfile(project_root, 'code');
project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end

ensure_external_matlab_data_paths();

cfg = fertility_benchmark_config();
overrides = cfg.overrides;
overrides.I = 30;
overrides.J = 14;
overrides.return_transition_objects = true;

[~, ~, ~, ~, ~, diagnostics] = SolveSS_fertility([cfg.eval_price, cfg.rbPos], overrides);
age_idx = find(diagnostics.ages == 25, 1);
if isempty(age_idx)
    error('Age 25 not found in solver age grid.');
end

policy_overrides = overrides;
policy_overrides = rmfield(policy_overrides, 'return_transition_objects');

cases = { ...
    struct('name', 'flat_2p0', 'q_path', [2.0, 2.0, 2.0, 2.0]), ...
    struct('name', 'step_2p10', 'q_path', [2.0, 2.1, 2.1, 2.1]), ...
    struct('name', 'delayed_step_2p10', 'q_path', [2.0, 2.0, 2.1, 2.1]), ...
    struct('name', 'transitory_step_2p10', 'q_path', [2.0, 2.1, 2.0, 2.0])};

target_z = [3, 4];
state_rows = table();

for c = 1:numel(cases)
    case_info = cases{c};
    fprintf('Running value-wedge audit for case %s...\n', case_info.name);
    solver_results = solve_household_path_fertility(case_info.q_path, policy_overrides, struct('rbPos_path', cfg.rbPos));
    env = solver_results.core_env;
    next_value = solver_results.path_solution.value{2, age_idx + 1};
    q_current = solver_results.q_path(1);
    rb_pos = solver_results.rb_pos_path(1);

    for iz = target_z
        rows_for_z = diagnostics.density_pre_policy_ages{age_idx}(:, 1, iz, 1, 1);
        active_idx = find(rows_for_z > 0);
        if isempty(active_idx)
            continue;
        end
        ii = active_idx(1);
        current_mass = rows_for_z(ii);

        metrics = evaluate_owner_renter_gap(ii, iz, q_current, rb_pos, env, solver_results.params, age_idx, next_value);

        row = struct2table(orderfields(struct( ...
            'case_name', string(case_info.name), ...
            'z_index', iz, ...
            'z_value', env.z(iz), ...
            'current_income', metrics.current_income, ...
            'current_b', env.b(ii), ...
            'current_mass', current_mass, ...
            'best_renter_a', metrics.best_renter_a, ...
            'best_renter_b', metrics.best_renter_b, ...
            'best_owner_a', metrics.best_owner_a, ...
            'best_owner_b', metrics.best_owner_b, ...
            'best_renter_total', metrics.best_renter_total, ...
            'best_owner_total', metrics.best_owner_total, ...
            'best_renter_immediate', metrics.best_renter_immediate, ...
            'best_owner_immediate', metrics.best_owner_immediate, ...
            'best_renter_continuation', metrics.best_renter_continuation, ...
            'best_owner_continuation', metrics.best_owner_continuation, ...
            'owner_minus_renter_total', metrics.best_owner_total - metrics.best_renter_total, ...
            'owner_minus_renter_immediate', metrics.best_owner_immediate - metrics.best_renter_immediate, ...
            'owner_minus_renter_continuation', metrics.best_owner_continuation - metrics.best_renter_continuation)));
        state_rows = [state_rows; row]; %#ok<AGROW>
    end
end

writetable(state_rows, fullfile(out_dir, 'structural_transition_value_wedge_audit.csv'));
write_note(fullfile(out_dir, 'structural_transition_value_wedge_audit.md'), state_rows);
disp('Structural transition value-wedge audit complete.');
end

function metrics = evaluate_owner_renter_gap(ii, iz, q_current, rb_pos, env, params, age_idx, next_value)
renter_j = 1;
ih = 1;
ip = 1;
home_count = env.home_grid(ih);
parity_count = env.parity_grid(ip);
leave_prob = env.leave_profile(age_idx);
ih_keep = ih;
ih_decay = env.home_index(max(home_count - 1, 0));
z_transition = env.transitionmatrix(:, :, age_idx);
expected_nobirth = expected_value_plane_local(z_transition(iz, :), next_value, ih_keep, ih_decay, ip, leave_prob);

rb_neg = rb_pos + params.rspread;
r_price = rb_neg - params.ra + params.rent_markup;
current_b = env.b(ii);
current_income = exp(env.z(iz)) * env.Zlifecycle(age_idx);
current_a = env.a(renter_j);
current_return = current_asset_return_rate_local(current_b, renter_j, params, rb_pos, rb_neg);
current_gross_resources = current_income + current_b * (1 + current_return) + current_a * q_current;

choice_penalty = build_choice_penalty_local(env.aa, env.bb, q_current, current_income, rb_pos, params, current_b, renter_j, env.ages(age_idx), parity_count);
theta_r_current = effective_theta_r_local(params, home_count);

% Renter branch
renter_consumption_raw = (current_gross_resources - env.bb(:, 1)) / (1 + params.s_h * theta_r_current);
renter_consumption = max(renter_consumption_raw, 1e-20);
renter_budget_penalty = double(renter_consumption_raw <= 0);
renter_rent = renter_consumption ./ r_price * theta_r_current * params.s_h;
renter_h_services = env.aa(:, 1) + theta_r_current * renter_rent;
renter_h_eff = max(renter_h_services, 1e-8) ./ ((1 + params.lambda_crowd * home_count) ^ params.psi_crowd);
renter_space_penalty = housing_mismatch_penalty_local(params, home_count, renter_h_services);
renter_immediate = log(renter_consumption) + params.s_h * log(renter_h_eff) + params.child_utility * home_count ...
    - renter_space_penalty - (choice_penalty(:, 1) + renter_budget_penalty) * env.penalty;
renter_total = renter_immediate + params.beta * expected_nobirth(:, 1);
[best_renter_total, renter_idx] = max(renter_total);
best_renter_immediate = renter_immediate(renter_idx);
best_renter_continuation = params.beta * expected_nobirth(renter_idx, 1);

% Owner branch
owner_purchase_cost = env.aa(:, 2:end) * q_current .* (1 + params.ka * (1 - (env.aa(:, 2:end) == current_a)));
owner_consumption_raw = current_gross_resources - owner_purchase_cost - env.bb(:, 2:end);
owner_consumption = max(owner_consumption_raw, 1e-20);
owner_budget_penalty = double(owner_consumption_raw <= 0);
owner_h_services = env.aa(:, 2:end);
owner_h_eff = max(owner_h_services, 1e-8) ./ ((1 + params.lambda_crowd * home_count) ^ params.psi_crowd);
owner_space_penalty = housing_mismatch_penalty_local(params, home_count, owner_h_services);
owner_immediate = log(owner_consumption) + params.s_h * log(owner_h_eff) + params.child_utility * home_count ...
    - owner_space_penalty - (choice_penalty(:, 2:end) + owner_budget_penalty) * env.penalty;
owner_total = owner_immediate + params.beta * expected_nobirth(:, 2:end);
[best_owner_total, linear_idx] = max(owner_total, [], 'all', 'linear');
[owner_b_idx, owner_j_local] = ind2sub(size(owner_total), linear_idx);
owner_j_idx = owner_j_local + 1;
best_owner_immediate = owner_immediate(owner_b_idx, owner_j_local);
best_owner_continuation = params.beta * expected_nobirth(owner_b_idx, owner_j_idx);

metrics = struct();
metrics.current_income = current_income;
metrics.best_renter_a = env.a(1);
metrics.best_renter_b = env.b(renter_idx);
metrics.best_owner_a = env.a(owner_j_idx);
metrics.best_owner_b = env.b(owner_b_idx);
metrics.best_renter_total = best_renter_total;
metrics.best_owner_total = best_owner_total;
metrics.best_renter_immediate = best_renter_immediate;
metrics.best_owner_immediate = best_owner_immediate;
metrics.best_renter_continuation = best_renter_continuation;
metrics.best_owner_continuation = best_owner_continuation;
end

function expected = expected_value_plane_local(z_probs, value_next, ih_keep, ih_decay, ip_next, p_leave)
[I, J, K, ~, ~] = size(value_next);
expected = zeros(I, J);
blended = p_leave * value_next(:, :, :, ih_decay, ip_next) + (1 - p_leave) * value_next(:, :, :, ih_keep, ip_next);
for iz_next = 1:K
    expected = expected + z_probs(iz_next) * blended(:, :, iz_next);
end
end

function rate = current_asset_return_rate_local(current_b, current_housing_index, params, rb_pos, rb_neg)
if current_b >= 0
    rate = rb_pos;
    return;
end
if current_housing_index > 1
    rate = rb_pos + params.owner_mortgage_spread;
else
    rate = rb_neg;
end
end

function theta_r_eff = effective_theta_r_local(params, child_count)
theta_r_eff = params.theta_r * max(0.05, 1 - params.theta_r_child_penalty * child_count);
end

function penalty = housing_mismatch_penalty_local(params, child_count, h_services)
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

function choice_penalty = build_choice_penalty_local(aa, bb, a_price, income, rb_pos, params, current_b, current_housing_index, age, parity_count)
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
    mortgage_payment_rate = max(rb_pos + params.owner_mortgage_spread, 0) + params.owner_mortgage_amortization;
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

function write_note(path, state_rows)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural transition value-wedge audit\n\n');
fprintf(fid, 'This note decomposes the no-birth owner-versus-renter value gap for the middle-income age-25 entrant states that drive the transition surge.\n\n');

fprintf(fid, '## State table\n\n');
fprintf(fid, '| case | z index | income | current b | best renter a'' | best renter b'' | best owner a'' | best owner b'' | owner-renter total | owner-renter immediate | owner-renter continuation |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(state_rows)
    fprintf(fid, '| %s | %d | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f |\n', ...
        state_rows.case_name(i), state_rows.z_index(i), state_rows.current_income(i), state_rows.current_b(i), ...
        state_rows.best_renter_a(i), state_rows.best_renter_b(i), state_rows.best_owner_a(i), state_rows.best_owner_b(i), ...
        state_rows.owner_minus_renter_total(i), state_rows.owner_minus_renter_immediate(i), state_rows.owner_minus_renter_continuation(i));
end

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- The point of this audit is to determine whether the owner-entry surge is being driven mainly by:\n');
fprintf(fid, '  - better current-period utility from owning at the unchanged `t = 1` price\n');
fprintf(fid, '  - or better continuation value from carrying owner status into the higher-price future\n');
fprintf(fid, '- The key comparison is the split between `owner-renter immediate` and `owner-renter continuation` across the flat, step, delayed-step, and transitory-step cases.\n');
end
