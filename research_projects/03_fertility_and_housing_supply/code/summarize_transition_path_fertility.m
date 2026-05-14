function summary = summarize_transition_path_fertility(solver_results, simulation)
% summarize_transition_path_fertility.m
%
% Stage 3 of the structural transition-path RE build:
% convert the simulated cross-section path into readable transition moments.

env = solver_results.core_env;
path_solution = solver_results.path_solution;
T = numel(solver_results.q_path);

summary = struct();
summary.q_path = solver_results.q_path(:);
summary.rb_pos_path = solver_results.rb_pos_path(:);
summary.ages = env.ages(:);
summary.age_mass = zeros(env.age_n, T);
summary.birth_rate_by_age = zeros(env.age_n, T);
summary.first_birth_rate_by_age = zeros(env.age_n, T);
summary.first_birth_hazard_by_age = NaN(env.age_n, T);
summary.childless_share_by_age = NaN(env.age_n, T);
summary.owner_share_by_age = NaN(env.age_n, T);
summary.mortgaged_owner_share_by_age = NaN(env.age_n, T);
summary.avg_birth_rate = NaN(T, 1);
summary.avg_first_birth_rate = NaN(T, 1);
summary.mean_age_first_birth = NaN(T, 1);
summary.share_first_birth_30_plus = NaN(T, 1);
summary.owner_share_25_34 = NaN(T, 1);
summary.mortgaged_owner_share_under_35 = NaN(T, 1);
summary.total_mass = NaN(T, 1);

fertile_mask = ismember(env.ages, solver_results.params.birth_ages);
under35_mask = env.ages < 35;
age2534_mask = env.ages >= 25 & env.ages < 35;
negative_b_mask = env.b < 0;

for t = 1:T
    first_birth_mass = zeros(env.age_n, 1);

    for age_pos = 1:env.age_n
        density_pre = simulation.pre_policy_cross_section{t, age_pos};
        density_post = simulation.post_policy_cross_section{t, age_pos};
        if isempty(density_pre) || isempty(density_post)
            continue;
        end

        age_mass = sum(density_post(:));
        summary.age_mass(age_pos, t) = age_mass;
        if age_mass <= 0
            continue;
        end

        policy_age = get_policy_block_st(path_solution, t, age_pos);
        birth_prob = policy_age.birth_prob;
        childless_idx = env.parity_index(0);
        childless_density = density_pre(:, :, :, :, childless_idx);
        childless_mass = sum(childless_density(:));

        summary.birth_rate_by_age(age_pos, t) = sum(density_pre(:) .* birth_prob(:)) / max(sum(density_pre(:)), 1e-12);
        first_birth_prob = birth_prob(:, :, :, :, childless_idx);
        first_birth_mass(age_pos) = sum(childless_density(:) .* first_birth_prob(:));
        summary.first_birth_rate_by_age(age_pos, t) = first_birth_mass(age_pos) / max(sum(density_pre(:)), 1e-12);
        summary.first_birth_hazard_by_age(age_pos, t) = first_birth_mass(age_pos) / max(childless_mass, 1e-12);
        summary.childless_share_by_age(age_pos, t) = childless_mass / max(sum(density_pre(:)), 1e-12);
        summary.owner_share_by_age(age_pos, t) = sum(density_post(:, 2:end, :, :, :), 'all') / age_mass;
        summary.mortgaged_owner_share_by_age(age_pos, t) = sum(density_post(negative_b_mask, 2:end, :, :, :), 'all') / age_mass;
    end

    summary.total_mass(t) = sum(summary.age_mass(:, t));
    summary.avg_birth_rate(t) = mean(summary.birth_rate_by_age(fertile_mask, t));
    summary.avg_first_birth_rate(t) = mean(summary.first_birth_rate_by_age(fertile_mask, t));

    if sum(first_birth_mass) > 0
        first_birth_dist = first_birth_mass ./ sum(first_birth_mass);
        summary.mean_age_first_birth(t) = sum(env.ages(:) .* first_birth_dist(:));
        summary.share_first_birth_30_plus(t) = sum(first_birth_dist(env.ages(:) >= 30));
    end

    summary.owner_share_25_34(t) = sum(summary.owner_share_by_age(age2534_mask, t) .* summary.age_mass(age2534_mask, t)) ...
        / max(sum(summary.age_mass(age2534_mask, t)), 1e-12);
    summary.mortgaged_owner_share_under_35(t) = sum(summary.mortgaged_owner_share_by_age(under35_mask, t) .* summary.age_mass(under35_mask, t)) ...
        / max(sum(summary.age_mass(under35_mask, t)), 1e-12);
end
end

function policy_age = get_policy_block_st(solution, t, age_pos)
if solution.time_varying
    policy_age = struct( ...
        'birth_prob', solution.birth_prob{t, age_pos});
else
    policy_age = struct( ...
        'birth_prob', solution.birth_prob{age_pos});
end
end
