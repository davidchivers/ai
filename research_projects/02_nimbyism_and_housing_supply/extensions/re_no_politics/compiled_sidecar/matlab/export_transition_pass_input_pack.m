function pack = export_transition_pass_input_pack( ...
    output_dir, horizon, price_level, project_root, transition_policy_mode, policy_reference_price, ...
    terminal_reference_mode, terminal_reference_price, policy_reference_mode, ...
    policy_reference_blend_weight, policy_reference_price_floor, policy_reference_price_cap, save_period_details, explicit_price_path, ...
    compute_political_path, save_political_details, price_preference_multiplier, coalition_params)
% Export a bounded structural NIMBY transition-pass pack plus MATLAB truth.

if nargin < 1 || isempty(output_dir)
    this_dir = fileparts(mfilename('fullpath'));
    output_dir = fullfile(fileparts(this_dir), 'truth', 'transition_pass_t4_diag');
end
if nargin < 2 || isempty(horizon)
    horizon = 4;
end
if nargin < 3 || isempty(price_level)
    price_level = 2.0;
end
if nargin < 4 || isempty(project_root)
    this_dir = fileparts(mfilename('fullpath'));
    sidecar_dir = fileparts(this_dir);
    extension_dir = fileparts(sidecar_dir);
    project_root = fileparts(fileparts(extension_dir));
end
if nargin < 5 || isempty(transition_policy_mode)
    transition_policy_mode = 'full_backward';
end
if nargin < 6 || isempty(policy_reference_price)
    policy_reference_price = price_level;
end
if nargin < 7 || isempty(terminal_reference_mode)
    terminal_reference_mode = 'fixed_price';
end
if nargin < 8 || isempty(terminal_reference_price)
    terminal_reference_price = price_level;
end
if nargin < 9 || isempty(policy_reference_mode)
    if strcmpi(transition_policy_mode, 'steady_state_fixed_price')
        policy_reference_mode = 'fixed_price';
    else
        policy_reference_mode = 'path_current_prices';
    end
end
if nargin < 10 || isempty(policy_reference_blend_weight)
    policy_reference_blend_weight = NaN;
end
if nargin < 11 || isempty(policy_reference_price_floor)
    policy_reference_price_floor = NaN;
end
if nargin < 12 || isempty(policy_reference_price_cap)
    policy_reference_price_cap = NaN;
end
if nargin < 13 || isempty(save_period_details)
    save_period_details = false;
end
if nargin < 14
    explicit_price_path = [];
end
if nargin < 15 || isempty(compute_political_path)
    compute_political_path = false;
end
if nargin < 16 || isempty(save_political_details)
    save_political_details = false;
end
if nargin < 17 || isempty(price_preference_multiplier)
    price_preference_multiplier = 1.01;
end
if nargin < 18 || isempty(coalition_params)
    coalition_params = struct();
end

this_dir = fileparts(mfilename('fullpath'));
sidecar_dir = fileparts(this_dir);
extension_dir = fileparts(sidecar_dir);
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(extension_dir);
addpath(baseline_dir);

demographic_path = build_demographic_path_from_age_state_csv(project_root);
[transitionmatrix, z, Zlifecycle, initialdist] = load_transition_matrix_data();

model = setup_model_objects_local(z, Zlifecycle, 0.03);
params = struct();
params.rbPos = model.rbPos;
params.supply_params = struct('eta_s', 1.0);
params.terminal_reference_mode = char(string(terminal_reference_mode));
params.terminal_reference_price = terminal_reference_price;
params.transition_policy_mode = char(string(transition_policy_mode));
params.policy_reference_mode = char(string(policy_reference_mode));
params.policy_reference_price = policy_reference_price;
params.policy_reference_blend_weight = policy_reference_blend_weight;
params.policy_reference_price_floor = policy_reference_price_floor;
params.policy_reference_price_cap = policy_reference_price_cap;
params.save_period_details = logical(save_period_details);
params.compute_political_path = logical(compute_political_path);
params.save_political_details = logical(save_political_details);
params.price_preference_multiplier = price_preference_multiplier;
params.coalition_params = set_default_coalition_params_local(coalition_params);
if params.compute_political_path
    params.save_period_details = true;
end

T_full = numel(demographic_path.periods);
horizon = min(horizon, T_full);
if isempty(explicit_price_path)
    price_path = price_level .* ones(horizon, 1);
else
    price_path = explicit_price_path(:);
    if numel(price_path) ~= horizon
        error('explicit_price_path length must equal horizon.');
    end
end
target_age_masses = build_target_age_masses_local(demographic_path.cohort_scale_by_age(1:horizon, :));

initial_reference = load_ss_reference_local(price_path(1), params.rbPos, params.supply_params);
params.supply_params = normalize_supply_params_local(params.supply_params, price_path(1), initial_reference.Hdemand);
initial_density = build_initial_density_local(initial_reference.dens4, target_age_masses(1, :));

truth = run_transition_pass_local(price_path, initial_density, target_age_masses, initialdist, transitionmatrix, model, params);

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

write_named_scalars(fullfile(output_dir, 'meta_scalars.csv'), {
    'T', horizon;
    'age_n', model.age_n;
    'I', model.I;
    'J', model.J;
    'K', model.K;
    'bzero', model.bzero - 1;
    'rb_pos', model.rbPos;
    'rb_neg', model.rbNeg;
    'ra', model.ra;
    'r_price', model.r_price;
    'omega', model.omega;
    'theta_r', model.theta_r;
    'beta', model.beta;
    'eta', model.eta;
    'ka', model.ka;
    'bequestweight1', model.bequestweight1;
    'bequestweight2', model.bequestweight2;
    'CC', model.CC;
    'penalty', model.penalty;
    'supply_Hbar', params.supply_params.Hbar;
    'supply_Pbar', params.supply_params.Pbar;
    'supply_eta_s', params.supply_params.eta_s;
    'terminal_reference_price', optional_scalar_sentinel(params.terminal_reference_price);
    'policy_reference_price', optional_scalar_sentinel(params.policy_reference_price);
    'policy_reference_blend_weight', optional_scalar_sentinel(params.policy_reference_blend_weight);
    'policy_reference_price_floor', optional_scalar_sentinel(params.policy_reference_price_floor);
    'policy_reference_price_cap', optional_scalar_sentinel(params.policy_reference_price_cap);
    'save_period_details', double(params.save_period_details);
    'compute_political_path', double(params.compute_political_path);
    'save_political_details', double(params.save_political_details);
    'price_preference_multiplier', params.price_preference_multiplier;
    'alpha_owner', params.coalition_params.alpha_owner;
    'alpha_old_owner', params.coalition_params.alpha_old_owner;
    'alpha_leverage', params.coalition_params.alpha_leverage;
    'alpha_bighouse', params.coalition_params.alpha_bighouse;
    'owner_cutoff', params.coalition_params.owner_cutoff;
    'old_age_cutoff', params.coalition_params.old_age_cutoff;
    'leverage_cutoff', params.coalition_params.leverage_cutoff;
    'housing_scale', params.coalition_params.housing_scale;
    'eps_value', params.coalition_params.eps_value});
write_named_strings(fullfile(output_dir, 'meta_strings.csv'), {
    'terminal_reference_mode', params.terminal_reference_mode;
    'transition_policy_mode', params.transition_policy_mode;
    'policy_reference_mode', params.policy_reference_mode});

writematrix(model.a(:), fullfile(output_dir, 'a.csv'));
writematrix(model.b(:), fullfile(output_dir, 'b.csv'));
writematrix(model.z(:), fullfile(output_dir, 'z.csv'));
writematrix(model.Zlifecycle(:), fullfile(output_dir, 'Zlifecycle.csv'));
writematrix(price_path(:), fullfile(output_dir, 'price_path.csv'));
writematrix(initialdist(:), fullfile(output_dir, 'initialdist.csv'));
writematrix(target_age_masses(:), fullfile(output_dir, 'target_age_masses.csv'));
writematrix(transitionmatrix(:), fullfile(output_dir, 'transitionmatrix.csv'));
writematrix(pack_density_by_age(initial_density), fullfile(output_dir, 'initial_density.csv'));
writematrix(pack_age_cell(initial_reference.age_valuefunctions), fullfile(output_dir, 'terminal_age_values.csv'));
if strcmpi(params.transition_policy_mode, 'steady_state_fixed_price')
    writematrix(pack_policy_cell(truth.reference_policy_idx_b), fullfile(output_dir, 'reference_policy_idx_b.csv'));
    writematrix(pack_policy_cell(truth.reference_policy_idx_a), fullfile(output_dir, 'reference_policy_idx_a.csv'));
    writematrix(pack_value_cell(truth.reference_valuefunctions), fullfile(output_dir, 'reference_valuefunctions.csv'));
end

writematrix(pack_policy_cell(truth.policy_idx_b), fullfile(output_dir, 'matlab_policy_idx_b.csv'));
writematrix(pack_policy_cell(truth.policy_idx_a), fullfile(output_dir, 'matlab_policy_idx_a.csv'));
writematrix(pack_value_cell(truth.valuefunctions), fullfile(output_dir, 'matlab_valuefunctions.csv'));
writematrix(truth.sim.Hdemand_path(:), fullfile(output_dir, 'matlab_Hdemand_path.csv'));
writematrix(truth.sim.Hsupply_guess_path(:), fullfile(output_dir, 'matlab_Hsupply_guess_path.csv'));
writematrix(truth.sim.excess_demand_guess_path(:), fullfile(output_dir, 'matlab_excess_demand_guess_path.csv'));
writematrix(truth.implied_price_path(:), fullfile(output_dir, 'matlab_implied_price_path.csv'));
writematrix(truth.sim.log_price_residual_raw(:), fullfile(output_dir, 'matlab_log_price_residual_raw.csv'));
writematrix(truth.sim.debt_path(:), fullfile(output_dir, 'matlab_debt_path.csv'));
writematrix(truth.sim.rent_share_path(:), fullfile(output_dir, 'matlab_rent_share_path.csv'));
if ~all(isnan(truth.policy_reference_price_path_used(:)))
    writematrix(truth.policy_reference_price_path_used(:), fullfile(output_dir, 'matlab_policy_reference_price_path_used.csv'));
end
if ~isnan(truth.terminal_reference_price_used)
    writematrix(truth.terminal_reference_price_used, fullfile(output_dir, 'matlab_terminal_reference_price_used.csv'));
end
if params.save_period_details
    writematrix(pack_density_by_period_age(truth.sim.density_by_period_age), fullfile(output_dir, 'matlab_density_by_period_age.csv'));
end
if params.compute_political_path
    writematrix(truth.sim.political.equal_weight_vote_path(:), fullfile(output_dir, 'matlab_equal_weight_vote_path.csv'));
    writematrix(truth.sim.political.weighted_vote_path(:), fullfile(output_dir, 'matlab_weighted_vote_path.csv'));
    writematrix(truth.sim.political.weighted_vote_share_path(:), fullfile(output_dir, 'matlab_weighted_vote_share_path.csv'));
    writematrix(truth.sim.political.equal_weight_distance_path(:), fullfile(output_dir, 'matlab_equal_weight_distance_path.csv'));
    writematrix(truth.sim.political.weighted_distance_path(:), fullfile(output_dir, 'matlab_weighted_distance_path.csv'));
    writematrix(truth.sim.political.owner_share_path(:), fullfile(output_dir, 'matlab_owner_share_path.csv'));
    writematrix(truth.sim.political.old_owner_share_path(:), fullfile(output_dir, 'matlab_old_owner_share_path.csv'));
    writematrix(truth.sim.political.leveraged_owner_share_path(:), fullfile(output_dir, 'matlab_leveraged_owner_share_path.csv'));
end

write_named_scalars(fullfile(output_dir, 'matlab_summary.csv'), {
    'max_abs_gap', truth.max_abs_gap;
    'residual_norm', truth.residual_norm});

pack = struct();
pack.output_dir = output_dir;
pack.price_path = price_path;
pack.target_age_masses = target_age_masses;
pack.initial_density = initial_density;
pack.initial_reference = initial_reference;
pack.truth = truth;
end

function model = setup_model_objects_local(z, Zlifecycle, rbPos)
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

model.z = z(:)';
model.K = numel(model.z);
model.Zlifecycle = Zlifecycle(:)';

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

function target_age_masses = build_target_age_masses_local(cohort_scale_by_age)
baseline = cohort_scale_by_age(1, :);
baseline = baseline ./ sum(baseline);
target_age_masses = zeros(size(cohort_scale_by_age));
for t = 1:size(cohort_scale_by_age, 1)
    age_mass = baseline .* cohort_scale_by_age(t, :);
    age_mass = age_mass ./ sum(age_mass);
    target_age_masses(t, :) = age_mass;
end
end

function reference = load_ss_reference_local(price, rbPos, supply_params)
solve_ss_no_politics([price, rbPos], supply_params); %#ok<NASGU>
ss = load('SS_no_politics_iter.mat');

reference = struct();
reference.dens4 = ss.dens4;
reference.Hdemand = compute_housing_demand_from_density_local(ss.dens4);
reference.age_valuefunctions = cell(1, size(ss.dens4, 4));
reference.age_policy_idx_a = cell(1, size(ss.dens4, 4));
reference.age_policy_idx_b = cell(1, size(ss.dens4, 4));
for age_idx = 1:size(ss.dens4, 4)
    age = 25 + 5 * (age_idx - 1);
    reference.age_valuefunctions{age_idx} = ss.(sprintf('valuefunction_%d', age));
    reference.age_policy_idx_a{age_idx} = ss.(sprintf('index_a_%d', age));
    reference.age_policy_idx_b{age_idx} = ss.(sprintf('index_b_%d', age));
end
end

function supply_params = normalize_supply_params_local(supply_params, reference_price, reference_Hdemand)
if ~isfield(supply_params, 'Pbar') || isempty(supply_params.Pbar)
    supply_params.Pbar = reference_price;
end
if ~isfield(supply_params, 'Hbar') || isempty(supply_params.Hbar)
    supply_params.Hbar = max(reference_Hdemand, 1e-8);
end
if ~isfield(supply_params, 'eta_s') || isempty(supply_params.eta_s)
    supply_params.eta_s = 1.0;
end
end

function Hdemand = compute_housing_demand_from_density_local(dens4)
a = linspace(0, 25, size(dens4, 2));
aa = ones(size(dens4, 1), 1) * a;
aaaa = repmat(aa, 1, 1, size(dens4, 3), size(dens4, 4));
Hdemand = sum(aaaa .* dens4, 'all');
end

function density_by_age = build_initial_density_local(reference_dens4, target_age_mass)
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

function run = run_transition_pass_local(price_path, initial_density, target_age_masses, initialdist, transitionmatrix, model, params)
policy_mode = lower(string(params.transition_policy_mode));
terminal_reference_price = NaN;
policy_reference_price_path = NaN(size(price_path));
reference_policy_idx_b = {};
reference_policy_idx_a = {};
reference_valuefunctions = {};
political = struct();

switch policy_mode
    case "full_backward"
        terminal_reference_price = resolve_terminal_reference_price_local(price_path, params);
        terminal_reference = load_ss_reference_local(terminal_reference_price, params.rbPos, params.supply_params);
        [policy_idx_b, policy_idx_a, valuefunctions] = solve_backward_transition_local( ...
            price_path, terminal_reference.age_valuefunctions, transitionmatrix, model);
    case "steady_state_fixed_price"
        fixed_price_path = resolve_policy_reference_price_path_local(price_path, params);
        [policy_idx_b, policy_idx_a, valuefunctions, policy_reference_price_path] = ...
            build_policy_path_from_ss_prices_local(fixed_price_path, params, model.age_n);
        reference_policy_idx_b = policy_idx_b;
        reference_policy_idx_a = policy_idx_a;
        reference_valuefunctions = valuefunctions;
    case "steady_state_by_period_price"
        price_reference_path = resolve_policy_reference_price_path_local(price_path, params);
        [policy_idx_b, policy_idx_a, valuefunctions, policy_reference_price_path] = ...
            build_policy_path_from_ss_prices_local(price_reference_path, params, model.age_n);
        reference_policy_idx_b = policy_idx_b;
        reference_policy_idx_a = policy_idx_a;
        reference_valuefunctions = valuefunctions;
    otherwise
        error('Unsupported params.transition_policy_mode: %s', params.transition_policy_mode);
end

if params.compute_political_path && policy_mode ~= "full_backward"
    error('params.compute_political_path is currently supported only for params.transition_policy_mode = ''full_backward''.');
end

sim = simulate_forward_transition_local(policy_idx_b, policy_idx_a, initial_density, target_age_masses, ...
    initialdist, transitionmatrix, model, params.save_period_details);

if params.compute_political_path
    perturbed_price_path = params.price_preference_multiplier .* price_path(:);
    perturbed_tail_reference = load_ss_reference_local(perturbed_price_path(end), params.rbPos, params.supply_params);
    [~, ~, perturbed_valuefunctions] = solve_backward_transition_local( ...
        perturbed_price_path, perturbed_tail_reference.age_valuefunctions, transitionmatrix, model);
    preference_sign_by_period_age = cell(size(valuefunctions));
    for t = 1:size(valuefunctions, 1)
        for age_idx = 1:size(valuefunctions, 2)
            preference_sign_by_period_age{t, age_idx} = sign(perturbed_valuefunctions{t, age_idx} - valuefunctions{t, age_idx});
        end
    end
    political = build_political_path_local(sim.density_by_period_age, preference_sign_by_period_age, model, price_path, params.coalition_params);
    sim.political = political;
end

implied_price_path = invert_supply_path_local(sim.Hdemand_path, params.supply_params);
sim.Hsupply_guess_path = compute_supply_path_local(price_path, params.supply_params);
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
run.reference_policy_idx_b = reference_policy_idx_b;
run.reference_policy_idx_a = reference_policy_idx_a;
run.reference_valuefunctions = reference_valuefunctions;
run.terminal_reference_price_used = terminal_reference_price;
run.policy_reference_price_path_used = policy_reference_price_path;
run.political = political;
end

function terminal_reference_price = resolve_terminal_reference_price_local(price_path, params)
mode = lower(string(params.terminal_reference_mode));
switch mode
    case "path_end_price"
        terminal_reference_price = price_path(end);
    case "initial_path_price"
        terminal_reference_price = price_path(1);
    case "fixed_price"
        terminal_reference_price = params.terminal_reference_price;
    case "mean_path_price"
        terminal_reference_price = mean(price_path);
    otherwise
        error('Unsupported params.terminal_reference_mode: %s', params.terminal_reference_mode);
end
end

function policy_reference_price = resolve_policy_reference_price_local(price_path, params)
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
    otherwise
        error('Unsupported params.policy_reference_mode: %s', params.policy_reference_mode);
end
end

function price_reference_path = resolve_policy_reference_price_path_local(price_path, params)
mode = lower(string(params.policy_reference_mode));
switch mode
    case "path_current_prices"
        price_reference_path = price_path(:);
    case {"path_initial_price", "path_end_price", "path_mean_price", "fixed_price"}
        reference_price = resolve_policy_reference_price_local(price_path, params);
        price_reference_path = reference_price .* ones(size(price_path(:)));
    case "blended_current_and_fixed_price"
        blend_weight = params.policy_reference_blend_weight;
        reference_price = params.policy_reference_price;
        price_reference_path = (1 - blend_weight) .* reference_price + blend_weight .* price_path(:);
    otherwise
        error('Unsupported params.policy_reference_mode for path resolution: %s', params.policy_reference_mode);
end
price_reference_path = apply_policy_reference_price_bounds_local(price_reference_path, params);
end

function bounded_price_reference_path = apply_policy_reference_price_bounds_local(price_reference_path, params)
bounded_price_reference_path = price_reference_path(:);
if ~isnan(params.policy_reference_price_floor)
    bounded_price_reference_path = max(bounded_price_reference_path, params.policy_reference_price_floor);
end
if ~isnan(params.policy_reference_price_cap)
    bounded_price_reference_path = min(bounded_price_reference_path, params.policy_reference_price_cap);
end
end

function [policy_idx_b, policy_idx_a, valuefunctions, policy_reference_price_path] = ...
    build_policy_path_from_ss_prices_local(price_reference_path, params, age_n)
price_reference_path = price_reference_path(:);
T = numel(price_reference_path);
policy_idx_b = cell(T, age_n);
policy_idx_a = cell(T, age_n);
valuefunctions = cell(T, age_n);
policy_reference_price_path = price_reference_path;

for t = 1:T
    reference = load_ss_reference_local(price_reference_path(t), params.rbPos, params.supply_params);
    for age_idx = 1:age_n
        policy_idx_b{t, age_idx} = reference.age_policy_idx_b{age_idx};
        policy_idx_a{t, age_idx} = reference.age_policy_idx_a{age_idx};
        valuefunctions{t, age_idx} = reference.age_valuefunctions{age_idx};
    end
end
end

function [policy_idx_b, policy_idx_a, valuefunctions] = solve_backward_transition_local(price_path, terminal_age_values, transitionmatrix, model)
T = numel(price_path);
age_n = model.age_n;

policy_idx_b = cell(T, age_n);
policy_idx_a = cell(T, age_n);
valuefunctions = cell(T, age_n);

for t = T:-1:1
    a_price = price_path(t);
    r_price = model.r_price;
    Ipen = double(-model.bb > model.aa * a_price * model.CC);

    for age_idx = age_n:-1:1
        if age_idx == age_n
            [index_b, index_a, valuefunction] = solve_terminal_age_local(a_price, r_price, Ipen, model, age_idx);
        else
            if t == T
                next_values = terminal_age_values{age_idx + 1};
            else
                next_values = valuefunctions{t + 1, age_idx + 1};
            end
            [index_b, index_a, valuefunction] = solve_working_age_local( ...
                a_price, r_price, Ipen, model, age_idx, next_values, transitionmatrix(:, :, age_idx)');
        end

        policy_idx_b{t, age_idx} = index_b;
        policy_idx_a{t, age_idx} = index_a;
        valuefunctions{t, age_idx} = valuefunction;
    end
end
end

function [index_b, index_a, valuefunction] = solve_terminal_age_local(a_price, r_price, Ipen, model, age_idx)
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

            consumption_plane = build_consumption_plane_local(current_b, current_a, a_price, r_price, labor_income, model);
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

function [index_b, index_a, valuefunction] = solve_working_age_local(a_price, r_price, Ipen, model, age_idx, next_values, z_transition)
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

            consumption_plane = build_consumption_plane_local(current_b, current_a, a_price, r_price, labor_income, model);
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

function consumption_plane = build_consumption_plane_local(current_b, current_a, a_price, r_price, labor_income, model)
consumption_plane = zeros(model.I, model.J);
wealth_flow = labor_income + current_b * (model.rbPos * (current_b >= 0) + model.rbNeg * (current_b < 0)) + current_a * a_price;
adjust_cost = model.ka .* (1 - (model.aa == current_a));
consumption_plane(:, 2:model.J) = max(wealth_flow - model.aa(:, 2:model.J) .* a_price .* (1 + adjust_cost(:, 2:model.J)) + ...
    current_b - model.bb(:, 2:model.J), 1e-20);
consumption_plane(:, 1) = max((wealth_flow - model.aa(:, 1) .* a_price .* (1 + adjust_cost(:, 1)) + current_b - model.bb(:, 1)) ./ ...
    (1 + ((1 - model.omega) / model.omega * model.theta_r)), 1e-20);
end

function sim = simulate_forward_transition_local(policy_idx_b, policy_idx_a, initial_density_by_age, target_age_masses, initialdist, transitionmatrix, model, save_period_details)
T = size(policy_idx_b, 1);
age_n = model.age_n;
current_density_by_age = initial_density_by_age;

sim = struct();
sim.Hdemand_path = zeros(T, 1);
sim.debt_path = zeros(T, 1);
sim.rent_share_path = zeros(T, 1);
if save_period_details
    sim.density_by_period_age = cell(T, age_n);
end

for t = 1:T
    current_density_by_age = rescale_density_by_age_local(current_density_by_age, target_age_masses(t, :), model, initialdist);

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
        next_density_by_age{age_idx} = zeros(model.I, model.J, model.K);
    end

    entrant_density = zeros(model.I, model.J, model.K);
    for iz = 1:model.K
        entrant_density(model.bzero, 1, iz) = initialdist(iz);
    end
    next_density_by_age{1} = entrant_density;

    for age_idx = 1:(age_n - 1)
        chosen_next_assets = map_density_with_policy_local( ...
            current_density_by_age{age_idx}, policy_idx_b{t, age_idx}, policy_idx_a{t, age_idx}, model.I, model.J, model.K);
        z_transition = transitionmatrix(:, :, age_idx)';
        next_density_by_age{age_idx + 1} = next_density_by_age{age_idx + 1} + ...
            apply_z_transition_local(chosen_next_assets, z_transition);
    end

    current_density_by_age = next_density_by_age;
end
end

function transitioned = apply_z_transition_local(density, z_transition)
[I, J, K] = size(density);
transitioned = zeros(I, J, K);
for iz = 1:K
    for iz_next = 1:K
        transitioned(:, :, iz_next) = transitioned(:, :, iz_next) + z_transition(iz_next, iz) .* density(:, :, iz);
    end
end
end

function mapped = map_density_with_policy_local(pre_density, idx_b, idx_a, I, J, K)
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

function density_by_age = rescale_density_by_age_local(density_by_age, target_age_mass, model, initialdist)
fallback = zeros(model.I, model.J, model.K);
for iz = 1:model.K
    fallback(model.bzero, 1, iz) = initialdist(iz);
end

for age_idx = 1:numel(density_by_age)
    current_mass = sum(density_by_age{age_idx}, 'all');
    if current_mass > 0
        density_by_age{age_idx} = density_by_age{age_idx} .* (target_age_mass(age_idx) / current_mass);
    else
        density_by_age{age_idx} = fallback .* target_age_mass(age_idx);
    end
end
end

function packed = pack_density_by_period_age(density_by_period_age)
[T, age_n] = size(density_by_period_age);
first = density_by_period_age{1, 1};
[I, J, K] = size(first);
packed = zeros(I * J * K * age_n * T, 1);
for t = 1:T
    for age_idx = 1:age_n
        offset = (t - 1) * age_n * I * J * K + (age_idx - 1) * I * J * K;
        packed(offset + (1:(I * J * K))) = density_by_period_age{t, age_idx}(:);
    end
end
end

function implied_price_path = invert_supply_path_local(Hdemand_path, supply_params)
implied_price_path = supply_params.Pbar .* max(Hdemand_path ./ supply_params.Hbar, 1e-8) .^ (1 ./ supply_params.eta_s);
implied_price_path = implied_price_path(:);
end

function Hsupply_path = compute_supply_path_local(price_path, supply_params)
Hsupply_path = supply_params.Hbar .* (price_path(:) ./ supply_params.Pbar) .^ supply_params.eta_s;
end

function packed = pack_density_by_age(density_by_age)
age_n = numel(density_by_age);
[I, J, K] = size(density_by_age{1});
packed_array = zeros(I, J, K, age_n);
for age_idx = 1:age_n
    packed_array(:, :, :, age_idx) = density_by_age{age_idx};
end
packed = packed_array(:);
end

function packed = pack_age_cell(age_cell)
age_n = numel(age_cell);
[I, J, K] = size(age_cell{1});
packed_array = zeros(I, J, K, age_n);
for age_idx = 1:age_n
    packed_array(:, :, :, age_idx) = age_cell{age_idx};
end
packed = packed_array(:);
end

function packed = pack_policy_cell(policy_cell)
[T, age_n] = size(policy_cell);
[I, J, K] = size(policy_cell{1, 1});
packed_array = zeros(I, J, K, age_n, T);
for t = 1:T
    for age_idx = 1:age_n
        packed_array(:, :, :, age_idx, t) = policy_cell{t, age_idx};
    end
end
packed = packed_array(:);
end

function packed = pack_value_cell(value_cell)
[T, age_n] = size(value_cell);
[I, J, K] = size(value_cell{1, 1});
packed_array = zeros(I, J, K, age_n, T);
for t = 1:T
    for age_idx = 1:age_n
        packed_array(:, :, :, age_idx, t) = value_cell{t, age_idx};
    end
end
packed = packed_array(:);
end

function write_named_scalars(path, rows)
writetable(cell2table(rows, 'VariableNames', {'name', 'value'}), path);
end

function write_named_strings(path, rows)
writetable(cell2table(rows, 'VariableNames', {'name', 'value'}), path);
end

function value = optional_scalar_sentinel(value)
if isnan(value)
    value = -9.87654321e307;
end
end

function params = set_default_coalition_params_local(params)
defaults = struct( ...
    'alpha_owner', 0.50, ...
    'alpha_old_owner', 0.50, ...
    'alpha_leverage', 0.25, ...
    'alpha_bighouse', 0.10, ...
    'owner_cutoff', 1e-8, ...
    'old_age_cutoff', 55, ...
    'leverage_cutoff', 0.60, ...
    'housing_scale', 1.0, ...
    'eps_value', 1e-12);

fields = fieldnames(defaults);
for i = 1:numel(fields)
    field_name = fields{i};
    if ~isfield(params, field_name) || isempty(params.(field_name))
        params.(field_name) = defaults.(field_name);
    end
end
end

function political = build_political_path_local(density_by_period_age, preference_sign_by_period_age, model, price_path, coalition_params)
[T, age_n] = size(density_by_period_age);
political = struct();
political.equal_weight_vote_path = zeros(T, 1);
political.weighted_vote_path = zeros(T, 1);
political.weighted_vote_share_path = zeros(T, 1);
political.equal_weight_distance_path = zeros(T, 1);
political.weighted_distance_path = zeros(T, 1);
political.owner_share_path = zeros(T, 1);
political.old_owner_share_path = zeros(T, 1);
political.leveraged_owner_share_path = zeros(T, 1);

housing_grid = repmat(model.aa, 1, 1, model.K, age_n);
liquid_grid = repmat(model.bb, 1, 1, model.K, age_n);
age_grid = model.ageline(:)';

for t = 1:T
    dens4 = zeros(model.I, model.J, model.K, age_n);
    pref4 = zeros(model.I, model.J, model.K, age_n);
    for age_idx = 1:age_n
        dens4(:, :, :, age_idx) = density_by_period_age{t, age_idx};
        pref4(:, :, :, age_idx) = preference_sign_by_period_age{t, age_idx};
    end

    period_params = coalition_params;
    period_params.house_price = price_path(t);
    stats = compute_coalition_vote(dens4, pref4, housing_grid, liquid_grid, age_grid, period_params);

    political.equal_weight_vote_path(t) = stats.equal_weight_vote;
    political.weighted_vote_path(t) = stats.weighted_vote;
    political.weighted_vote_share_path(t) = stats.weighted_vote_share;
    political.equal_weight_distance_path(t) = stats.equal_weight_vote ^ 2;
    political.weighted_distance_path(t) = stats.weighted_vote ^ 2;
    political.owner_share_path(t) = stats.owner_share;
    political.old_owner_share_path(t) = stats.old_owner_share;
    political.leveraged_owner_share_path(t) = stats.leveraged_owner_share;
end
end
