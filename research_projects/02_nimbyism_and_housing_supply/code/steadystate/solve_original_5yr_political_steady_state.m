function [distance, a_price, rbPos, totalvote, debtstock, results] = solve_original_5yr_political_steady_state(x, options)
% Original 5-year political steady state, split into:
% 1. Bellman solve
% 2. Distribution pushforward and vote aggregation

if nargin < 2 || isempty(options)
    options = struct();
end

options = apply_default_options_local(options);

if ~isempty(options.core_results)
    core = options.core_results;
else
    core = solve_original_5yr_bellman_core(x, options.core_options);
end

results = aggregate_political_steady_state_local(core);
results.a_price = x(1);
results.rbPos = x(2);
results.rb_pos = x(2);

distance = results.distance;
a_price = results.a_price;
rbPos = results.rbPos;
totalvote = results.totalvote;
debtstock = results.debtstock;

if options.save_ss_iter
    save_snapshot_local(results, options.save_path);
end
end

function options = apply_default_options_local(options)
if ~isfield(options, 'core_options') || isempty(options.core_options)
    options.core_options = struct();
end
if ~isfield(options, 'core_results')
    options.core_results = [];
end
if ~isfield(options, 'save_ss_iter') || isempty(options.save_ss_iter)
    options.save_ss_iter = false;
end
if ~isfield(options, 'save_path') || isempty(options.save_path)
    options.save_path = 'SS_iter.mat';
end
end

function results = aggregate_political_steady_state_local(core)
env = core.env;

cohortsize = ones(1, env.age_n);
cohortsize = cohortsize / mean(cohortsize);

density_prev = zeros(env.I, env.J, env.K);
dens4 = zeros(env.I, env.J, env.K, env.age_n);
pref4 = zeros(env.I, env.J, env.K, env.age_n);
totaldensity = zeros(env.I, env.J, env.K);

for age_idx = 1:env.age_n
    if age_idx == 1
        for iz = 1:env.K
            density_prev(env.bzero, 1, iz) = env.initialdist(iz);
        end
    else
        z_transition = env.transitionmatrix(:, :, age_idx - 1)';
        density_prev = advance_density_z_local(density_prev, z_transition, env);
    end

    density = push_density_through_policies_local( ...
        density_prev, ...
        core.index_b{age_idx}, ...
        core.index_a{age_idx}, ...
        env);

    density = cohortsize(age_idx) .* density;
    density_prev = density;

    dens4(:, :, :, age_idx) = density ./ env.age_n;
    pref4(:, :, :, age_idx) = sign(core.d_valuefunction_dp{age_idx});
    totaldensity = totaldensity + density;
end

debt_grid = repmat(env.bb, 1, 1, env.K, env.age_n);
housing_grid = repmat(env.aa, 1, 1, env.K, env.age_n);

results = struct();
results.dens4 = dens4;
results.pref4 = pref4;
results.preference_sign = pref4;
results.totaldensity = totaldensity ./ sum(totaldensity(:));
results.totalvote = sum(dens4 .* pref4, 'all');
results.distance = results.totalvote ^ 2;
results.debtstock = sum(debt_grid .* dens4, 'all');
results.Hdemand = sum(housing_grid .* dens4, 'all');
results.env = env;
results.params = core.params;
results.options = core.options;
results.primitives = core.primitives;
results.age_valuefunctions = core.valuefunctions;
results.age_valuefunctions_dp = core.valuefunctions_dp;
results.age_d_valuefunctions_dp = core.d_valuefunction_dp;
results.age_policy_idx_a = core.index_a;
results.age_policy_idx_b = core.index_b;
results.age_policy_idx_a_dp = core.index_a_dp;
results.age_policy_idx_b_dp = core.index_b_dp;

for age_idx = 1:env.age_n
    age = env.ages(age_idx);
    results.(sprintf('valuefunction_%d', age)) = core.valuefunctions{age_idx};
    results.(sprintf('valuefunction_dp_%d', age)) = core.valuefunctions_dp{age_idx};
    results.(sprintf('d_valuefunction_dp_%d', age)) = core.d_valuefunction_dp{age_idx};
    results.(sprintf('index_a_%d', age)) = core.index_a{age_idx};
    results.(sprintf('index_b_%d', age)) = core.index_b{age_idx};
    results.(sprintf('index_a_dp_%d', age)) = core.index_a_dp{age_idx};
    results.(sprintf('index_b_dp_%d', age)) = core.index_b_dp{age_idx};
end
end

function next_density = advance_density_z_local(density_prev, z_transition, env)
next_density = zeros(env.I, env.J, env.K);
for iz = 1:env.K
    for iz_prev = 1:env.K
        next_density(:, :, iz) = next_density(:, :, iz) + ...
            z_transition(iz, iz_prev) .* density_prev(:, :, iz_prev);
    end
end
end

function density = push_density_through_policies_local(density_prev, index_b, index_a, env)
density = zeros(env.I, env.J, env.K);
for iz = 1:env.K
    for ii = 1:env.I
        for ij = 1:env.J
            next_b = index_b(ii, ij, iz);
            next_a = index_a(ii, ij, iz);
            density(next_b, next_a, iz) = density(next_b, next_a, iz) + density_prev(ii, ij, iz);
        end
    end
end
end

function save_snapshot_local(results, save_path)
snapshot = build_snapshot_struct_local(results);
save(save_path, '-struct', 'snapshot');
end

function snapshot = build_snapshot_struct_local(results)
snapshot = struct();
snapshot.distance = results.distance;
snapshot.a_price = results.a_price;
snapshot.rbPos = results.rbPos;
snapshot.totalvote = results.totalvote;
snapshot.debtstock = results.debtstock;
snapshot.dens4 = results.dens4;
snapshot.pref4 = results.pref4;

for age_idx = 1:numel(results.env.ages)
    age = results.env.ages(age_idx);
    snapshot.(sprintf('valuefunction_%d', age)) = results.(sprintf('valuefunction_%d', age));
    snapshot.(sprintf('valuefunction_dp_%d', age)) = results.(sprintf('valuefunction_dp_%d', age));
    snapshot.(sprintf('d_valuefunction_dp_%d', age)) = results.(sprintf('d_valuefunction_dp_%d', age));
    snapshot.(sprintf('index_a_%d', age)) = results.(sprintf('index_a_%d', age));
    snapshot.(sprintf('index_b_%d', age)) = results.(sprintf('index_b_%d', age));
    snapshot.(sprintf('index_a_dp_%d', age)) = results.(sprintf('index_a_dp_%d', age));
    snapshot.(sprintf('index_b_dp_%d', age)) = results.(sprintf('index_b_dp_%d', age));
end
end
