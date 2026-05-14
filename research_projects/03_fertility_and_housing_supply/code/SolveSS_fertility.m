function [distance, a_price, rbPos, totalvote, debtstock, diagnostics] = SolveSS_fertility(x, overrides)
% GE fertility extension of the project-02 steady-state household block.
% When C=1 and fertility utility/cost terms are zeroed out, this should
% reproduce the upstream SolveSS_function.m objects at the same [a_price, rbPos].

if nargin < 2
    overrides = struct();
end

ensure_external_matlab_data_paths();

params = default_fertility_params();
params = apply_overrides(params, overrides);

if is_upstream_reproduction_case(params)
    project_root = fileparts(fileparts(mfilename('fullpath')));
    project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
    if exist(project02_steady, 'dir')
        addpath(project02_steady, '-begin');
    end
    distance = SolveSS_function(x);
    upstream = load('SS_function.mat');
    a_price = x(1);
    rbPos = x(2);
    totalvote = sum(upstream.dens4 .* upstream.pref4, 'all');
    debtstock = sum(upstream.bbbb .* upstream.dens4, 'all');
    diagnostics = struct();
    diagnostics.params = params;
    age_n_upstream = size(upstream.dens4, 4);
    upstream_I = size(upstream.dens4, 1);
    upstream_J = size(upstream.dens4, 2);
    upstream_age_mass = squeeze(sum(sum(sum(upstream.dens4, 1), 2), 3));
    diagnostics.birth_rate_by_age = zeros(age_n_upstream, 1);
    diagnostics.first_birth_mass_by_age = zeros(age_n_upstream, 1);
    diagnostics.first_birth_rate_by_age = zeros(age_n_upstream, 1);
    diagnostics.first_birth_hazard_by_age = zeros(age_n_upstream, 1);
    diagnostics.first_birth_age_dist = zeros(age_n_upstream, 1);
    diagnostics.childless_share_by_age = ones(age_n_upstream, 1);
    diagnostics.child_dist_by_age = ones(age_n_upstream, 1);
    diagnostics.home_dist_by_age = ones(age_n_upstream, 1);
    diagnostics.parity_dist_by_age = ones(age_n_upstream, 1);
    diagnostics.age_mass = upstream_age_mass(:);
    diagnostics.mass_pre_policy = diagnostics.age_mass;
    diagnostics.mass_post_policy = diagnostics.age_mass;
    diagnostics.avg_birth_rate = 0;
    diagnostics.avg_first_birth_rate = 0;
    diagnostics.mean_age_first_birth = NaN;
    diagnostics.median_age_first_birth = NaN;
    diagnostics.share_first_birth_30_plus = NaN;
    diagnostics.dens4 = upstream.dens4;
    diagnostics.vote4 = upstream.dens4 .* upstream.pref4;
    diagnostics.pref4 = upstream.pref4;
    diagnostics.bbbb4 = upstream.bbbb;
    diagnostics.zzzz4 = upstream.zzzz;
    diagnostics.totaldensity = upstream.totaldensity;
    diagnostics.totalvote_array = upstream.totalvote;
    diagnostics.ages = params.agemin:params.dage:params.agemax;
    diagnostics.a_grid = linspace(params.housingmin, params.housingmax, upstream_J);
    diagnostics.b_grid = squeeze(upstream.bbbb(:, 1, 1, 1));
    if numel(diagnostics.b_grid) ~= upstream_I
        diagnostics.b_grid = linspace(params.bmin, params.bmax, upstream_I);
    end

    avg_birth_rate = 0;
    first_birth_mass_by_age = diagnostics.first_birth_mass_by_age;
    first_birth_rate_by_age = diagnostics.first_birth_rate_by_age;
    first_birth_hazard_by_age = diagnostics.first_birth_hazard_by_age;
    first_birth_age_dist = diagnostics.first_birth_age_dist;
    childless_share_by_age = diagnostics.childless_share_by_age;
    avg_first_birth_rate = diagnostics.avg_first_birth_rate;
    mean_age_first_birth = diagnostics.mean_age_first_birth;
    median_age_first_birth = diagnostics.median_age_first_birth;
    share_first_birth_30_plus = diagnostics.share_first_birth_30_plus;
    birth_rate_by_age = diagnostics.birth_rate_by_age;
    child_dist_by_age = diagnostics.child_dist_by_age;
    home_dist_by_age = diagnostics.home_dist_by_age;
    parity_dist_by_age = diagnostics.parity_dist_by_age;
    age_mass = diagnostics.age_mass;
    mass_pre_policy = diagnostics.mass_pre_policy;
    mass_post_policy = diagnostics.mass_post_policy;
    dens4 = diagnostics.dens4;
    vote4 = diagnostics.vote4;
    pref4 = diagnostics.pref4;
    bbbb4 = diagnostics.bbbb4;
    zzzz4 = diagnostics.zzzz4;
    save('SS_fertility.mat', 'distance', 'a_price', 'rbPos', 'totalvote', 'debtstock', ...
        'avg_birth_rate', 'avg_first_birth_rate', 'birth_rate_by_age', ...
        'first_birth_mass_by_age', 'first_birth_rate_by_age', 'first_birth_hazard_by_age', ...
        'first_birth_age_dist', 'childless_share_by_age', ...
        'mean_age_first_birth', 'median_age_first_birth', 'share_first_birth_30_plus', ...
        'child_dist_by_age', 'home_dist_by_age', ...
        'parity_dist_by_age', 'age_mass', 'mass_pre_policy', 'mass_post_policy', ...
        'dens4', 'vote4', 'pref4', 'bbbb4', 'zzzz4', 'diagnostics');
    return;
end

a_price = x(1);
rbPos = x(2);
rbNeg = rbPos + params.rspread;
r_price = (rbNeg - params.ra + params.rent_markup);
r_price_dp = r_price * params.d_a_price;

agemin = params.agemin;
agemax = params.agemax;
dage = params.dage;
ages = agemin:dage:agemax;
age_n = numel(ages);
leave_profile = build_leave_profile(params, ages);

tmp = load(params.transition_matrix_file);
transitionmatrix = tmp.transitionmatrix;
z = tmp.y_mid;
K = size(z, 2);
Zlifecycle = tmp.z_lifecycle ./ tmp.z_lifecycle(1);
if isfield(tmp, 'initialdist') && ~isempty(tmp.initialdist)
    initialdist = tmp.initialdist(:)';
else
    initialdist = stationary_dist(transitionmatrix(:, :, 1));
end
if size(transitionmatrix, 3) < max(age_n - 1, 0)
    error('%s only provides %d age transitions, but the solver needs %d for ages %d:%d:%d.', ...
        params.transition_matrix_file, size(transitionmatrix, 3), max(age_n - 1, 0), agemin, dage, agemax);
end
if numel(Zlifecycle) < age_n
    error('%s only provides %d lifecycle income points, but the solver needs %d for ages %d:%d:%d.', ...
        params.transition_matrix_file, numel(Zlifecycle), age_n, agemin, dage, agemax);
end
if numel(initialdist) ~= K
    error('Initial income distribution has %d states, but the income grid has %d.', numel(initialdist), K);
end

if ~isempty(params.housing_grid)
    a = params.housing_grid(:)';
    J = numel(a);
else
    J = params.J;
    a = linspace(params.housingmin, params.housingmax, J);
end
I = params.I;
b = linspace(params.bmin, params.bmax, I);

bb = b' * ones(1, J);
aa = ones(I, 1) * a;

bbb = zeros(I, J, K);
aaa = zeros(I, J, K);
zzz = zeros(I, J, K);
for iz = 1:K
    bbb(:, :, iz) = bb;
    aaa(:, :, iz) = aa;
    zzz(:, :, iz) = z(iz);
end

Penalty = params.penalty;

home_grid = 0:(params.C - 1);
H = numel(home_grid);
home_index = @(n) min(max(round(n), 0), H - 1) + 1;

parity_grid = 0:(params.P - 1);
P = numel(parity_grid);
parity_index = @(n) min(max(round(n), 0), P - 1) + 1;

valuefunction_ages = cell(age_n, 1);
d_valuefunction_dp_ages = cell(age_n, 1);
index_a_ages = cell(age_n, 1);
index_b_ages = cell(age_n, 1);
birth_prob_ages = cell(age_n, 1);
index_a_birth_ages = cell(age_n, 1);
index_b_birth_ages = cell(age_n, 1);

valuefunction_next = [];
valuefunction_next_dp = [];

for age_pos = age_n:-1:1
    age = ages(age_pos);
    fertile = any(params.birth_ages == age) && P > 1;

    valuefunction = NaN(I, J, K, H, P);
    valuefunction_dp = NaN(I, J, K, H, P);
    index_a = NaN(I, J, K, H, P);
    index_b = NaN(I, J, K, H, P);
    index_a_birth = NaN(I, J, K, H, P);
    index_b_birth = NaN(I, J, K, H, P);
    birth_prob = zeros(I, J, K, H, P);

    for ih = 1:H
        home_count = home_grid(ih);
        leave_prob = leave_profile(age_pos);
        ih_keep = ih;
        ih_decay = home_index(max(home_count - 1, 0));
        ih_birth_keep = home_index(min(home_count + 1, H - 1));
        ih_birth_decay = home_index(min(max(home_count - 1, 0) + 1, H - 1));

        for ip = 1:P
            parity_count = parity_grid(ip);
            can_birth = fertile && parity_count < (P - 1);
            ip_birth = parity_index(min(parity_count + 1, P - 1));
            realized_birth_weight = get_realized_birth_weight_by_age_and_parity(params, age, parity_count);

            for iz = 1:K
                if age_pos < age_n
                    z_transition = transitionmatrix(:, :, age_pos);
                    expected_nobirth = expected_value_plane(z_transition(iz, :), valuefunction_next, ih_keep, ih_decay, ip, leave_prob);
                    expected_nobirth_dp = expected_value_plane(z_transition(iz, :), valuefunction_next_dp, ih_keep, ih_decay, ip, leave_prob);
                    if can_birth
                        expected_birth = expected_value_plane(z_transition(iz, :), valuefunction_next, ih_birth_keep, ih_birth_decay, ip_birth, leave_prob);
                        expected_birth_dp = expected_value_plane(z_transition(iz, :), valuefunction_next_dp, ih_birth_keep, ih_birth_decay, ip_birth, leave_prob);
                    else
                        expected_birth = zeros(I, J);
                        expected_birth_dp = zeros(I, J);
                    end
                else
                    expected_nobirth = zeros(I, J);
                    expected_nobirth_dp = zeros(I, J);
                    expected_birth = zeros(I, J);
                    expected_birth_dp = zeros(I, J);
                end
                expected_nobirth_choice = blend_expected_price_drift(expected_nobirth, expected_nobirth_dp, params.anticipated_price_drift_weight);
                expected_birth_choice = blend_expected_price_drift(expected_birth, expected_birth_dp, params.anticipated_price_drift_weight);

                income = exp(z(iz)) * Zlifecycle(age_pos);

                for ij = 1:J
                    for ii = 1:I
                        [maxvalue_nb, ind_b_nb, ind_a_nb] = solve_branch(ii, ij, income, aa, bb, ...
                            a_price, r_price, rbPos, rbNeg, a, Penalty, params, ...
                            home_count, parity_count, expected_nobirth_choice, false, age_pos == age_n, age);

                        [maxvalue_nb_dp, ~, ~] = solve_branch(ii, ij, income, aa, bb, ...
                            a_price * params.d_a_price, r_price_dp, rbPos, rbNeg, a, Penalty, ...
                            params, home_count, parity_count, expected_nobirth_dp, false, age_pos == age_n, age);

                        index_b(ii, ij, iz, ih, ip) = ind_b_nb;
                        index_a(ii, ij, iz, ih, ip) = ind_a_nb;
                        index_b_birth(ii, ij, iz, ih, ip) = ind_b_nb;
                        index_a_birth(ii, ij, iz, ih, ip) = ind_a_nb;

                        if can_birth
                            [maxvalue_b, ind_b_b, ind_a_b] = solve_branch(ii, ij, income, aa, bb, ...
                                a_price, r_price, rbPos, rbNeg, a, Penalty, params, ...
                                home_count, parity_count, expected_birth_choice, true, age_pos == age_n, age);

                            [maxvalue_b_dp, ~, ~] = solve_branch(ii, ij, income, aa, bb, ...
                                a_price * params.d_a_price, r_price_dp, rbPos, rbNeg, a, Penalty, ...
                                params, home_count, parity_count, expected_birth_dp, true, age_pos == age_n, age);

                            try_value = realized_birth_weight * maxvalue_b + (1 - realized_birth_weight) * maxvalue_nb;
                            try_value_dp = realized_birth_weight * maxvalue_b_dp + (1 - realized_birth_weight) * maxvalue_nb_dp;
                            try_prob = logistic_prob(try_value - maxvalue_nb, params.logit_scale);

                            birth_prob(ii, ij, iz, ih, ip) = try_prob * realized_birth_weight;
                            valuefunction(ii, ij, iz, ih, ip) = smooth_value(maxvalue_nb, try_value, params.logit_scale);
                            valuefunction_dp(ii, ij, iz, ih, ip) = smooth_value(maxvalue_nb_dp, try_value_dp, params.logit_scale);
                            index_b_birth(ii, ij, iz, ih, ip) = ind_b_b;
                            index_a_birth(ii, ij, iz, ih, ip) = ind_a_b;
                        else
                            valuefunction(ii, ij, iz, ih, ip) = maxvalue_nb;
                            valuefunction_dp(ii, ij, iz, ih, ip) = maxvalue_nb_dp;
                        end
                    end
                end
            end
        end
    end

    valuefunction_ages{age_pos} = valuefunction;
    d_valuefunction_dp_ages{age_pos} = valuefunction_dp - valuefunction;
    index_a_ages{age_pos} = index_a;
    index_b_ages{age_pos} = index_b;
    birth_prob_ages{age_pos} = birth_prob;
    index_a_birth_ages{age_pos} = index_a_birth;
    index_b_birth_ages{age_pos} = index_b_birth;

    valuefunction_next = valuefunction;
    valuefunction_next_dp = valuefunction_dp;
end

[~, bzero] = min(abs(b));
if b(bzero) < 0
    bzero = bzero + 1;
end

cohortsize = build_cohort_weights(params, ages);

density_raw_ages = cell(age_n, 1);
density_pre_policy_ages = cell(age_n, 1);
density_age = cell(age_n, 1);
vote_age = cell(age_n, 1);
home_dist_by_age = zeros(age_n, H);
parity_dist_by_age = zeros(age_n, P);
birth_rate_by_age = zeros(age_n, 1);
first_birth_mass_by_age = zeros(age_n, 1);
first_birth_rate_by_age = zeros(age_n, 1);
first_birth_hazard_by_age = NaN(age_n, 1);
childless_share_by_age = NaN(age_n, 1);
mass_pre_policy = zeros(age_n, 1);
mass_post_policy = zeros(age_n, 1);

density_prev = build_initial_density(initialdist, b, bzero, J, K, home_index, parity_index, params);

for age_pos = 1:age_n
    age = ages(age_pos);

    if age_pos > 1
        density_prev = apply_z_transition(density_raw_ages{age_pos - 1}, transitionmatrix(:, :, age_pos - 1));
    end

    density_pre_policy_ages{age_pos} = density_prev;
    mass_pre_policy(age_pos) = sum(density_prev(:));
    d_vf = d_valuefunction_dp_ages{age_pos};
    vote_age{age_pos} = sign(d_vf) .* density_prev;

    for ih = 1:H
        home_dist_by_age(age_pos, ih) = sum(density_prev(:, :, :, ih, :), 'all') / max(mass_pre_policy(age_pos), 1e-12);
    end
    for ip = 1:P
        parity_dist_by_age(age_pos, ip) = sum(density_prev(:, :, :, :, ip), 'all') / max(mass_pre_policy(age_pos), 1e-12);
    end

    childless_density = density_prev(:, :, :, :, parity_index(0));
    childless_mass = sum(childless_density, 'all');
    childless_share_by_age(age_pos) = childless_mass / max(mass_pre_policy(age_pos), 1e-12);

    if any(params.birth_ages == age)
        birth_rate_by_age(age_pos) = sum(density_prev(:) .* birth_prob_ages{age_pos}(:)) / max(mass_pre_policy(age_pos), 1e-12);
        first_birth_prob = birth_prob_ages{age_pos}(:, :, :, :, parity_index(0));
        first_birth_mass_by_age(age_pos) = sum(childless_density(:) .* first_birth_prob(:));
        first_birth_rate_by_age(age_pos) = first_birth_mass_by_age(age_pos) / max(mass_pre_policy(age_pos), 1e-12);
        first_birth_hazard_by_age(age_pos) = first_birth_mass_by_age(age_pos) / max(childless_mass, 1e-12);
    end

    density_raw = zeros(I, J, K, H, P);
    for ih = 1:H
        home_count = home_grid(ih);
        leave_prob = leave_profile(age_pos);
        ih_keep = ih;
        ih_decay = home_index(max(home_count - 1, 0));
        ih_birth_keep = home_index(min(home_count + 1, H - 1));
        ih_birth_decay = home_index(min(max(home_count - 1, 0) + 1, H - 1));

        for ip = 1:P
            parity_count = parity_grid(ip);
            ip_birth = parity_index(min(parity_count + 1, P - 1));

            for iz = 1:K
                for ij = 1:J
                    for ii = 1:I
                        mass = density_prev(ii, ij, iz, ih, ip);
                        if mass <= 0
                            continue;
                        end

                        prob = birth_prob_ages{age_pos}(ii, ij, iz, ih, ip);

                        nb = index_b_ages{age_pos}(ii, ij, iz, ih, ip);
                        na = index_a_ages{age_pos}(ii, ij, iz, ih, ip);
                        mass_nb = (1 - prob) * mass;
                        density_raw(nb, na, iz, ih_decay, ip) = density_raw(nb, na, iz, ih_decay, ip) + leave_prob * mass_nb;
                        density_raw(nb, na, iz, ih_keep, ip) = density_raw(nb, na, iz, ih_keep, ip) + (1 - leave_prob) * mass_nb;

                        if prob > 0
                            nb_b = index_b_birth_ages{age_pos}(ii, ij, iz, ih, ip);
                            na_b = index_a_birth_ages{age_pos}(ii, ij, iz, ih, ip);
                            mass_b = prob * mass;
                            density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) + leave_prob * mass_b;
                            density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) + (1 - leave_prob) * mass_b;
                        end
                    end
                end
            end
        end
    end

    mass_post_policy(age_pos) = sum(density_raw(:));
    density_raw_ages{age_pos} = density_raw;
    density_age{age_pos} = cohortsize(age_pos) * density_raw;
end

dens4 = zeros(I, J, K, age_n);
vote4 = zeros(I, J, K, age_n);
pref4 = zeros(I, J, K, age_n);
bbbb4 = zeros(I, J, K, age_n);
zzzz4 = zeros(I, J, K, age_n);
totaldensity = zeros(I, J, K);
totalvote_array = zeros(I, J, K);

for age_pos = 1:age_n
    dens_c = sum(sum(density_age{age_pos}, 5), 4);
    vote_c = sum(sum(density_age{age_pos} .* sign(d_valuefunction_dp_ages{age_pos}), 5), 4);

    dens4(:, :, :, age_pos) = dens_c / age_n;
    vote4(:, :, :, age_pos) = vote_c / age_n;
    pref4(:, :, :, age_pos) = vote4(:, :, :, age_pos) ./ max(dens4(:, :, :, age_pos), 1e-20);
    bbbb4(:, :, :, age_pos) = bbb;
    zzzz4(:, :, :, age_pos) = exp(zzz) .* Zlifecycle(age_pos);

    totaldensity = totaldensity + dens_c;
    totalvote_array = totalvote_array + vote_c;
end

totaldensity = totaldensity ./ sum(totaldensity(:));
totalvote = sum(vote4, 'all');
debtstock = sum(bbbb4 .* dens4, 'all');
distance = 100 * totalvote^2 + debtstock^2;
avg_birth_rate = mean(birth_rate_by_age(ismember(ages, params.birth_ages)));
fertile_mask = ismember(ages, params.birth_ages);
avg_first_birth_rate = mean(first_birth_rate_by_age(fertile_mask));
first_birth_age_dist = zeros(age_n, 1);
first_birth_age_dist_unweighted = zeros(age_n, 1);
first_birth_mass_by_age_weighted = zeros(age_n, 1);
mean_age_first_birth = NaN;
mean_age_first_birth_unweighted = NaN;
median_age_first_birth = NaN;
median_age_first_birth_unweighted = NaN;
share_first_birth_30_plus = NaN;
share_first_birth_30_plus_unweighted = NaN;
total_first_birth_mass = sum(first_birth_mass_by_age(fertile_mask));
if total_first_birth_mass > 0
    first_birth_age_dist_unweighted = first_birth_mass_by_age ./ total_first_birth_mass;
    mean_age_first_birth_unweighted = sum(ages(:) .* first_birth_age_dist_unweighted(:));
    median_age_first_birth_unweighted = weighted_discrete_median(ages(:), first_birth_age_dist_unweighted(:));
    share_first_birth_30_plus_unweighted = sum(first_birth_age_dist_unweighted(ages(:) >= 30));
end

first_birth_mass_by_age_weighted = first_birth_mass_by_age .* (cohortsize(:) / age_n);
total_first_birth_mass_weighted = sum(first_birth_mass_by_age_weighted(fertile_mask));
if total_first_birth_mass_weighted > 0
    first_birth_age_dist = first_birth_mass_by_age_weighted ./ total_first_birth_mass_weighted;
    mean_age_first_birth = sum(ages(:) .* first_birth_age_dist(:));
    median_age_first_birth = weighted_discrete_median(ages(:), first_birth_age_dist(:));
    share_first_birth_30_plus = sum(first_birth_age_dist(ages(:) >= 30));
end

disp(['Vote for higher prices -1 to 1 = ', num2str(totalvote)]);
disp(['Debt Stock = ', num2str(debtstock)]);
disp(['Avg birth rate (fertile ages) = ', num2str(avg_birth_rate)]);
disp(['Rent Share = ', num2str(sum(dens4(:, 1, :, :), 'all'))]);

diagnostics = struct();
diagnostics.params = params;
diagnostics.birth_rate_by_age = birth_rate_by_age;
diagnostics.first_birth_mass_by_age = first_birth_mass_by_age;
diagnostics.first_birth_mass_by_age_weighted = first_birth_mass_by_age_weighted;
diagnostics.first_birth_rate_by_age = first_birth_rate_by_age;
diagnostics.first_birth_hazard_by_age = first_birth_hazard_by_age;
diagnostics.first_birth_age_dist = first_birth_age_dist;
diagnostics.first_birth_age_dist_unweighted = first_birth_age_dist_unweighted;
diagnostics.childless_share_by_age = childless_share_by_age;
diagnostics.child_dist_by_age = home_dist_by_age;
diagnostics.home_dist_by_age = home_dist_by_age;
diagnostics.parity_dist_by_age = parity_dist_by_age;
diagnostics.mass_pre_policy = mass_pre_policy;
diagnostics.mass_post_policy = mass_post_policy;
diagnostics.avg_birth_rate = avg_birth_rate;
diagnostics.avg_first_birth_rate = avg_first_birth_rate;
diagnostics.mean_age_first_birth = mean_age_first_birth;
diagnostics.mean_age_first_birth_unweighted = mean_age_first_birth_unweighted;
diagnostics.median_age_first_birth = median_age_first_birth;
diagnostics.median_age_first_birth_unweighted = median_age_first_birth_unweighted;
diagnostics.share_first_birth_30_plus = share_first_birth_30_plus;
diagnostics.share_first_birth_30_plus_unweighted = share_first_birth_30_plus_unweighted;
diagnostics.dens4 = dens4;
diagnostics.vote4 = vote4;
diagnostics.pref4 = pref4;
diagnostics.bbbb4 = bbbb4;
diagnostics.zzzz4 = zzzz4;
diagnostics.totaldensity = totaldensity;
diagnostics.totalvote_array = totalvote_array;
diagnostics.ages = ages;
diagnostics.leave_profile = leave_profile;
diagnostics.a_grid = a;
diagnostics.b_grid = b;
diagnostics.z_grid = z(:);
diagnostics.z_lifecycle = Zlifecycle(:);
diagnostics.initialdist = initialdist(:);
diagnostics.age_mass = squeeze(sum(sum(sum(dens4, 1), 2), 3));
diagnostics.home_grid = home_grid(:);
diagnostics.parity_grid = parity_grid(:);

if params.return_transition_objects
    diagnostics.index_a_ages = index_a_ages;
    diagnostics.index_b_ages = index_b_ages;
    diagnostics.index_a_birth_ages = index_a_birth_ages;
    diagnostics.index_b_birth_ages = index_b_birth_ages;
    diagnostics.birth_prob_ages = birth_prob_ages;
    diagnostics.density_pre_policy_ages = density_pre_policy_ages;
    diagnostics.density_raw_ages = density_raw_ages;
end

child_dist_by_age = home_dist_by_age;
age_mass = diagnostics.age_mass;
save('SS_fertility.mat', 'distance', 'a_price', 'rbPos', 'totalvote', 'debtstock', ...
    'avg_birth_rate', 'avg_first_birth_rate', 'birth_rate_by_age', ...
    'first_birth_mass_by_age', 'first_birth_rate_by_age', 'first_birth_hazard_by_age', ...
    'first_birth_mass_by_age_weighted', 'first_birth_age_dist', 'first_birth_age_dist_unweighted', 'childless_share_by_age', ...
    'mean_age_first_birth', 'mean_age_first_birth_unweighted', ...
    'median_age_first_birth', 'median_age_first_birth_unweighted', ...
    'share_first_birth_30_plus', 'share_first_birth_30_plus_unweighted', ...
    'child_dist_by_age', 'home_dist_by_age', ...
    'parity_dist_by_age', 'age_mass', 'mass_pre_policy', 'mass_post_policy', 'dens4', 'vote4', ...
    'pref4', 'bbbb4', 'zzzz4', 'diagnostics');

end

function [maxvalue, ind_b, ind_a] = solve_branch(ii, ij, income, aa, bb, a_price, r_price, ...
    rbPos, rbNeg, a_grid, Penalty, params, home_count, parity_count, continuation_value, is_birth, is_terminal, age)

current_b = bb(ii, ij);
current_gross_resources = income + current_b * (1 + current_asset_return_rate(current_b, ij, params, rbPos, rbNeg)) ...
    + a_grid(ij) * a_price;
choice_penalty = build_choice_penalty(aa, bb, a_price, income, rbPos, params, current_b, ij, age, parity_count);
owner_entry_gift = owner_entry_deposit_gift(params, ij, current_b, age);
owner_purchase_cost = aa(:, 2:end) * a_price .* (1 + params.ka * (1 - (aa(:, 2:end) == a_grid(ij))));
value_plane_no_gift = build_value_plane(0.0);
if owner_entry_gift > 0
    value_plane_with_gift = build_value_plane(owner_entry_gift);
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

function rate = current_asset_return_rate(current_b, current_housing_index, params, rbPos, rbNeg)
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

function gift = owner_entry_deposit_gift(params, current_housing_index, current_b, age)
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

function value_plane = build_value_plane(applied_owner_entry_gift)
consumption_plane = zeros(size(aa));
budget_penalty = zeros(size(aa));

owner_consumption_raw = current_gross_resources + applied_owner_entry_gift ...
    - owner_purchase_cost ...
    - bb(:, 2:end);
consumption_plane(:, 2:end) = max(owner_consumption_raw, 1e-20);
budget_penalty(:, 2:end) = double(owner_consumption_raw <= 0);

theta_r_current = effective_theta_r(params, home_count);
renter_consumption_raw = (current_gross_resources ...
    - aa(:, 1) * a_price .* (1 + params.ka * (1 - (aa(:, 1) == a_grid(ij)))) ...
    - bb(:, 1)) / (1 + params.s_h * theta_r_current);
consumption_plane(:, 1) = max(renter_consumption_raw, 1e-20);
budget_penalty(:, 1) = double(renter_consumption_raw <= 0);

rent_plane = zeros(size(aa));
rent_plane(:, 1) = consumption_plane(:, 1) ./ r_price * theta_r_current * params.s_h;

h_services = aa + theta_r_current * rent_plane;
h_eff = max(h_services, 1e-8) ./ ((1 + params.lambda_crowd * home_count) ^ params.psi_crowd);
space_penalty = housing_mismatch_penalty(params, home_count, h_services);

value_plane = log(consumption_plane) + params.s_h * log(h_eff) + params.child_utility * home_count ...
    - space_penalty - (choice_penalty + budget_penalty) * Penalty;

if is_birth
    n_eff = min(home_count + 1, params.C - 1);
    theta_r_birth = effective_theta_r(params, n_eff);
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
    space_penalty_birth = housing_mismatch_penalty(params, n_eff, h_services_birth);
    birth_utility_n = get_parity_birth_utility(params, parity_count);
    value_plane = log(consumption_plane_birth) + params.s_h * log(h_eff_birth) + params.child_utility * n_eff ...
        + birth_utility_n - params.birth_cost - params.birth_price_coeff * a_price ...
        - space_penalty_birth - (choice_penalty + budget_penalty_birth) * Penalty;
end

if is_terminal
    bequest_plane = max(1e-20, bb + a_price .* aa);
    value_plane = value_plane + params.bequestweight * log(bequest_plane);
else
    value_plane = value_plane + params.beta * continuation_value;
end
end

function choice_penalty = build_choice_penalty(aa, bb, a_price, income, rbPos, params, current_b, current_housing_index, age, parity_count)
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

[maxvalue, linear_idx] = max(value_plane, [], 'all', 'linear');
[ind_b, ind_a] = ind2sub(size(value_plane), linear_idx);
end

function expected = expected_value_plane(z_probs, value_next, ih_keep, ih_decay, ip_next, p_leave)
[I, J, K, ~, ~] = size(value_next);
expected = zeros(I, J);
blended = p_leave * value_next(:, :, :, ih_decay, ip_next) + (1 - p_leave) * value_next(:, :, :, ih_keep, ip_next);
for iz_next = 1:K
    expected = expected + z_probs(iz_next) * blended(:, :, iz_next);
end
end

function stat = stationary_dist(z_transition)
[vec, ~] = eigs(z_transition', 1, 'largestreal');
stat = real(vec);
stat = max(stat, 0);
stat = stat ./ sum(stat);
end

function density_next = apply_z_transition(density_current, z_transition)
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

function prob = logistic_prob(delta, scale)
if scale <= 0
    prob = double(delta > 0);
    return;
end
arg = max(-30, min(30, delta / scale));
prob = 1 / (1 + exp(-arg));
end

function val = smooth_value(v0, v1, scale)
if scale <= 0
    val = max(v0, v1);
    return;
end
mx = max(v0, v1);
val = mx + scale * log(exp((v0 - mx) / scale) + exp((v1 - mx) / scale));
end

function params = default_fertility_params()
benchmark_cfg = fertility_benchmark_config();

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
params.agemax = 90;
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
params.anticipated_price_drift_weight = 0.0;
params.leave_home_age_bins = [20 25 30];
params.leave_home_bin_probs = [0.588 0.147 0.265];
params.cohort_weights_by_age = [];
params.transition_matrix_file = 'TransitionMatrix.mat';
params.d_a_price = 1.01;
params.return_transition_objects = false;

params = apply_overrides(params, benchmark_cfg.overrides);
if isnan(params.owner_mortgage_CC)
    params.owner_mortgage_CC = params.CC;
end
if isnan(params.owner_mortgage_spread)
    params.owner_mortgage_spread = params.rspread;
end
end

function s = apply_overrides(s, overrides)
fields = fieldnames(overrides);
for i = 1:numel(fields)
    s.(fields{i}) = overrides.(fields{i});
end
end

function theta_r_eff = effective_theta_r(params, child_count)
theta_r_eff = params.theta_r * max(0.05, 1 - params.theta_r_child_penalty * child_count);
end

function penalty = housing_mismatch_penalty(params, child_count, h_services)
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

function density_init = build_initial_density(initialdist, b_grid, bzero, J, K, home_index, parity_index, params)
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
                + deposit_mass_on_b_grid(b_grid, points(ib), mass * shares(ib));
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

function mass_vec = deposit_mass_on_b_grid(b_grid, target_b, mass)
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
lower_weight = 1 - upper_weight;
mass_vec(lower_idx) = mass * lower_weight;
mass_vec(upper_idx) = mass * upper_weight;
end

function expected_choice = blend_expected_price_drift(expected_base, expected_high, weight)
if weight <= 0
    expected_choice = expected_base;
    return;
end
weight = min(max(weight, 0), 1);
expected_choice = (1 - weight) * expected_base + weight * expected_high;
end

function tf = is_upstream_reproduction_case(params)
tf = params.dage == 5 ...
    && params.agemin == 25 ...
    && params.agemax == 90 ...
    && params.C == 1 ...
    && params.P == 1 ...
    && params.birth_utility == 0 ...
    && params.child_utility == 0 ...
    && params.birth_cost == 0 ...
    && params.lambda_crowd == 0 ...
    && params.theta_r_child_penalty == 0 ...
    && params.family_space_floor == 0 ...
    && params.family_space_penalty == 0 ...
    && params.family_space_fixed_penalty == 0 ...
    && params.parental_transfer_share == 0 ...
    && params.parental_transfer_b_boost == 0 ...
    && isempty(params.initial_b_points) ...
    && isempty(params.initial_b_shares) ...
    && params.owner_entry_deposit_gift == 0 ...
    && params.owner_entry_b_floor <= -1e8 ...
    && params.owner_entry_mortgage_floor == 0 ...
    && params.owner_min_mortgage_share == 0 ...
    && params.owner_min_mortgage_age_max == 0 ...
    && ~isfinite(params.owner_entry_payment_to_income_cap) ...
    && params.owner_mortgage_CC == params.CC ...
    && params.owner_mortgage_spread == params.rspread ...
    && params.owner_mortgage_amortization == 0 ...
    && params.anticipated_price_drift_weight == 0 ...
    && params.psi_crowd == 0;
end

function val = get_parity_birth_utility(params, n)
if isfield(params, 'birth_utility_by_parity') && ~isempty(params.birth_utility_by_parity)
    idx = min(max(n + 1, 1), numel(params.birth_utility_by_parity));
    val = params.birth_utility_by_parity(idx);
else
    val = params.birth_utility;
end
end

function w = get_realized_birth_weight_by_age_and_parity(params, age, parity_count)
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

function leave_profile = build_leave_profile(params, ages)
if isfield(params, 'leave_home_age_bins') && ~isempty(params.leave_home_age_bins)
    leave_profile = build_leave_profile_from_bins(params, ages);
else
    leave_profile = repmat(params.p_leave, 1, numel(ages));
end
leave_profile = min(max(leave_profile, 0), 1);
end

function leave_profile = build_leave_profile_from_bins(params, ages)
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

function cohortsize = build_cohort_weights(params, ages)
if isfield(params, 'cohort_weights_by_age') && ~isempty(params.cohort_weights_by_age)
    cohortsize = params.cohort_weights_by_age(:)';
    if numel(cohortsize) ~= numel(ages)
        error('cohort_weights_by_age has %d elements, but the solver age grid has %d ages.', ...
            numel(cohortsize), numel(ages));
    end
elseif params.dage == 5 && params.agemin == 25 && params.agemax == 90 && numel(ages) == 14
    cohortsize = [14 12 10 10 10 10 9 8 7 5 4 2 1 1];
elseif params.dage == 1
    cohortsize = expand_five_year_cohort_profile(ages);
else
    cohortsize = ones(1, numel(ages));
end

if any(~isfinite(cohortsize)) || any(cohortsize <= 0)
    error('Cohort weights must be finite and strictly positive.');
end
cohortsize = cohortsize ./ mean(cohortsize);
end

function cohortsize = expand_five_year_cohort_profile(ages)
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

function median_age = weighted_discrete_median(values, weights)
weights = weights(:);
values = values(:);
if isempty(weights) || sum(weights) <= 0
    median_age = NaN;
    return;
end
weights = weights ./ sum(weights);
cdf = cumsum(weights);
idx = find(cdf >= 0.5, 1, 'first');
median_age = values(idx);
end
