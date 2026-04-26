function cross_section = build_stationary_cross_section_nimby(constant_solution, env, normalize_cross_section)
% build_stationary_cross_section_nimby.m
%
% Build the stationary age-by-state cross section implied by a constant
% Nimby Bellman solution. This is the steady-state companion to
% solve_household_path_nimby.m.

if nargin < 3 || isempty(normalize_cross_section)
    normalize_cross_section = true;
end

if isfield(constant_solution, 'time_varying') && constant_solution.time_varying
    error('build_stationary_cross_section_nimby expects a constant (time-invariant) solution.');
end

density_prev = build_initial_density_local(env.initialdist, env.I, env.J, env.K, env.bzero);
pre_cross_section = cell(env.age_n, 1);
post_cross_section = cell(env.age_n, 1);

for age_idx = 1:env.age_n
    pre_cross_section{age_idx} = density_prev;
    density_raw = map_density_with_policy_local( ...
        density_prev, constant_solution.index_b{age_idx}, constant_solution.index_a{age_idx}, env.I, env.J, env.K);
    post_cross_section{age_idx} = density_raw;

    if age_idx < env.age_n
        density_prev = apply_z_transition_local(density_raw, env.transitionmatrix(:, :, age_idx)');
    end
end

if normalize_cross_section
    total_mass = total_cross_section_mass_local(post_cross_section);
    scale = max(total_mass, 1e-12);
    for age_idx = 1:env.age_n
        pre_cross_section{age_idx} = pre_cross_section{age_idx} ./ scale;
        post_cross_section{age_idx} = post_cross_section{age_idx} ./ scale;
    end
end

dens4 = zeros(env.I, env.J, env.K, env.age_n);
for age_idx = 1:env.age_n
    dens4(:, :, :, age_idx) = post_cross_section{age_idx};
end

totaldensity = sum(dens4, 4);
totaldensity = totaldensity ./ max(sum(totaldensity(:)), 1e-12);

cross_section = struct();
cross_section.pre = {pre_cross_section};
cross_section.post = {post_cross_section};
cross_section.dens4 = dens4;
cross_section.totaldensity = totaldensity;
end

function density_init = build_initial_density_local(initialdist, I, J, K, bzero)
density_init = zeros(I, J, K);
for iz = 1:K
    density_init(bzero, 1, iz) = initialdist(iz);
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

function total_mass = total_cross_section_mass_local(cross_section)
total_mass = 0;
for age_idx = 1:numel(cross_section)
    total_mass = total_mass + sum(cross_section{age_idx}(:));
end
end
