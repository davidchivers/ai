function simulation = forward_distribution_path_fertility(solver_results, initial_cross_section, options)
% forward_distribution_path_fertility.m
%
% Stage 2 of the structural transition-path RE build:
% simulate the household distribution forward conditional on the solved
% policy path from solve_household_path_fertility.m.

if nargin < 2
    initial_cross_section = [];
end
if nargin < 3 || isempty(options)
    options = struct();
end

if ~isfield(options, 'store_cross_section') || isempty(options.store_cross_section)
    options.store_cross_section = true;
end
if ~isfield(options, 'normalize_initial_cross_section') || isempty(options.normalize_initial_cross_section)
    options.normalize_initial_cross_section = true;
end

params = solver_results.params;
env = solver_results.core_env;
path_solution = solver_results.path_solution;
T = numel(solver_results.q_path);

if isempty(initial_cross_section)
    initial_q = solver_results.options.initial_q;
    initial_rb = solver_results.rb_pos_path(1);
    initial_solution = solve_household_path_fertility(initial_q, params, struct('rbPos_path', initial_rb));
    initial_cross_section = build_stationary_cross_sections_fd(initial_solution.tail_solution, params, initial_solution.core_env, options.normalize_initial_cross_section);
end

entrant_density = initial_cross_section.pre{1};
current_pre_cross_section = initial_cross_section.pre;

simulation = struct();
simulation.initial_cross_section = initial_cross_section;
simulation.entrant_density = entrant_density;
if options.store_cross_section
    simulation.pre_policy_cross_section = cell(T, env.age_n);
    simulation.post_policy_cross_section = cell(T, env.age_n);
else
    simulation.pre_policy_cross_section = {};
    simulation.post_policy_cross_section = {};
end

for t = 1:T
    next_pre_cross_section = cell(env.age_n, 1);
    next_pre_cross_section{1} = entrant_density;
    for age_pos = 2:env.age_n
        next_pre_cross_section{age_pos} = zeros(env.I, env.J, env.K, env.H, env.P);
    end

    post_cross_section = cell(env.age_n, 1);

    for age_pos = 1:(env.age_n - 1)
        density_age = current_pre_cross_section{age_pos};
        if sum(density_age(:)) <= 0
            post_cross_section{age_pos} = zeros(env.I, env.J, env.K, env.H, env.P);
            continue;
        end

        density_raw = apply_policy_transition_fd(density_age, path_solution, t, age_pos, env);
        post_cross_section{age_pos} = density_raw;
        density_next = apply_z_transition_fd(density_raw, env.transitionmatrix(:, :, age_pos));
        age_scale = env.cohortsize(age_pos + 1) / env.cohortsize(age_pos);
        next_pre_cross_section{age_pos + 1} = next_pre_cross_section{age_pos + 1} + age_scale * density_next;
    end

    density_age = current_pre_cross_section{env.age_n};
    if sum(density_age(:)) <= 0
        post_cross_section{env.age_n} = zeros(env.I, env.J, env.K, env.H, env.P);
    else
        density_raw = apply_policy_transition_fd(density_age, path_solution, t, env.age_n, env);
        post_cross_section{env.age_n} = density_raw;
    end

    if options.store_cross_section
        simulation.pre_policy_cross_section(t, :) = current_pre_cross_section;
        simulation.post_policy_cross_section(t, :) = post_cross_section;
    end

    current_pre_cross_section = next_pre_cross_section;
end
end

function cross_section = build_stationary_cross_sections_fd(constant_solution, params, env, normalize_cross_section)
density_prev = build_initial_density_fd(env.initialdist, env.b, env.bzero, env.J, env.K, env.home_index, env.parity_index, params);
pre_cross_section = cell(env.age_n, 1);
post_cross_section = cell(env.age_n, 1);

for age_pos = 1:env.age_n
    pre_cross_section{age_pos} = (env.cohortsize(age_pos) / env.age_n) * density_prev;
    density_raw = apply_policy_transition_fd(density_prev, constant_solution, 1, age_pos, env);
    post_cross_section{age_pos} = (env.cohortsize(age_pos) / env.age_n) * density_raw;
    if age_pos < env.age_n
        density_prev = apply_z_transition_fd(density_raw, env.transitionmatrix(:, :, age_pos));
    end
end

if normalize_cross_section
    total_mass = total_cross_section_mass_fd(post_cross_section);
    for age_pos = 1:env.age_n
        pre_cross_section{age_pos} = pre_cross_section{age_pos} ./ max(total_mass, 1e-12);
        post_cross_section{age_pos} = post_cross_section{age_pos} ./ max(total_mass, 1e-12);
    end
end

cross_section = struct('pre', {pre_cross_section}, 'post', {post_cross_section});
end

function density_raw = apply_policy_transition_fd(density_prev, solution, t, age_pos, env)
policy_age = get_policy_block_fd(solution, t, age_pos);
density_raw = zeros(env.I, env.J, env.K, env.H, env.P);
leave_prob = env.leave_profile(age_pos);

for ih = 1:env.H
    home_count = env.home_grid(ih);
    ih_keep = ih;
    ih_decay = env.home_index(max(home_count - 1, 0));
    ih_birth_keep = env.home_index(min(home_count + 1, env.H - 1));
    ih_birth_decay = env.home_index(min(max(home_count - 1, 0) + 1, env.H - 1));

    for ip = 1:env.P
        ip_birth = env.parity_index(min(env.parity_grid(ip) + 1, env.P - 1));
        for iz = 1:env.K
            for ij = 1:env.J
                for ii = 1:env.I
                    mass = density_prev(ii, ij, iz, ih, ip);
                    if mass <= 0
                        continue;
                    end

                    prob = policy_age.birth_prob(ii, ij, iz, ih, ip);
                    nb = policy_age.index_b(ii, ij, iz, ih, ip);
                    na = policy_age.index_a(ii, ij, iz, ih, ip);
                    mass_nb = (1 - prob) * mass;
                    density_raw(nb, na, iz, ih_decay, ip) = density_raw(nb, na, iz, ih_decay, ip) + leave_prob * mass_nb;
                    density_raw(nb, na, iz, ih_keep, ip) = density_raw(nb, na, iz, ih_keep, ip) + (1 - leave_prob) * mass_nb;

                    if prob > 0
                        nb_b = policy_age.index_b_birth(ii, ij, iz, ih, ip);
                        na_b = policy_age.index_a_birth(ii, ij, iz, ih, ip);
                        mass_b = prob * mass;
                        density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) + leave_prob * mass_b;
                        density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) + (1 - leave_prob) * mass_b;
                    end
                end
            end
        end
    end
end
end

function policy_age = get_policy_block_fd(solution, t, age_pos)
if solution.time_varying
    policy_age = struct( ...
        'index_a', solution.index_a{t, age_pos}, ...
        'index_b', solution.index_b{t, age_pos}, ...
        'birth_prob', solution.birth_prob{t, age_pos}, ...
        'index_a_birth', solution.index_a_birth{t, age_pos}, ...
        'index_b_birth', solution.index_b_birth{t, age_pos});
else
    policy_age = struct( ...
        'index_a', solution.index_a{age_pos}, ...
        'index_b', solution.index_b{age_pos}, ...
        'birth_prob', solution.birth_prob{age_pos}, ...
        'index_a_birth', solution.index_a_birth{age_pos}, ...
        'index_b_birth', solution.index_b_birth{age_pos});
end
end

function density_next = apply_z_transition_fd(density_current, z_transition)
[I, J, K, H, P] = size(density_current);
density_next = zeros(I, J, K, H, P);
for ih = 1:H
    for ip = 1:P
        for iz = 1:K
            for iz_next = 1:K
                density_next(:, :, iz_next, ih, ip) = density_next(:, :, iz_next, ih, ip) ...
                    + z_transition(iz, iz_next) * density_current(:, :, iz, ih, ip);
            end
        end
    end
end
end

function density_init = build_initial_density_fd(initialdist, b_grid, bzero, J, K, home_index, parity_index, params)
density_init = zeros(numel(b_grid), J, K, numel(0:(params.C - 1)), numel(0:(params.P - 1)));

if isfield(params, 'initial_b_points') && isfield(params, 'initial_b_shares') ...
        && ~isempty(params.initial_b_points) && ~isempty(params.initial_b_shares)
    points = params.initial_b_points(:);
    shares = params.initial_b_shares(:);
    if numel(points) ~= numel(shares)
        error('initial_b_points and initial_b_shares must have the same length.');
    end
    shares = max(shares, 0);
    shares = shares ./ max(sum(shares), 1e-12);
    for iz = 1:K
        mass = initialdist(iz);
        for ib = 1:numel(points)
            density_init(:, 1, iz, home_index(0), parity_index(0)) = density_init(:, 1, iz, home_index(0), parity_index(0)) ...
                + deposit_mass_on_b_grid_fd(b_grid, points(ib), mass * shares(ib));
        end
    end
    return;
end

share = min(max(params.parental_transfer_share, 0), 1);
gift_idx = bzero;
if params.parental_transfer_b_boost > 0
    target_b = max(b_grid(bzero), 0) + params.parental_transfer_b_boost;
    [~, gift_idx] = min(abs(b_grid - target_b));
end
for iz = 1:K
    mass = initialdist(iz);
    density_init(bzero, 1, iz, home_index(0), parity_index(0)) = (1 - share) * mass;
    density_init(gift_idx, 1, iz, home_index(0), parity_index(0)) = density_init(gift_idx, 1, iz, home_index(0), parity_index(0)) + share * mass;
end
end

function mass_vec = deposit_mass_on_b_grid_fd(b_grid, target_b, mass)
mass_vec = zeros(numel(b_grid), 1);
if mass <= 0
    return;
end
if target_b <= b_grid(1)
    mass_vec(1) = mass;
    return;
end
if target_b >= b_grid(end)
    mass_vec(end) = mass;
    return;
end

upper_idx = find(b_grid >= target_b, 1);
lower_idx = upper_idx - 1;
b_low = b_grid(lower_idx);
b_high = b_grid(upper_idx);
if abs(b_high - b_low) < 1e-12
    mass_vec(lower_idx) = mass;
    return;
end

upper_weight = (target_b - b_low) / (b_high - b_low);
upper_weight = min(max(upper_weight, 0), 1);
mass_vec(lower_idx) = mass * (1 - upper_weight);
mass_vec(upper_idx) = mass * upper_weight;
end

function total_mass = total_cross_section_mass_fd(cross_section)
total_mass = 0;
for age_pos = 1:numel(cross_section)
    total_mass = total_mass + sum(cross_section{age_pos}(:));
end
end
