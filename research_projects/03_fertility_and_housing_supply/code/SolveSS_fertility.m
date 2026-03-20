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
    diagnostics.birth_rate_by_age = zeros(size(upstream.dens4, 4), 1);
    diagnostics.child_dist_by_age = ones(size(upstream.dens4, 4), 1);
    diagnostics.home_dist_by_age = diagnostics.child_dist_by_age;
    diagnostics.parity_dist_by_age = ones(size(upstream.dens4, 4), 1);
    diagnostics.age_mass = squeeze(sum(sum(sum(upstream.dens4, 1), 2), 3));
    diagnostics.mass_pre_policy = ones(size(upstream.dens4, 4), 1);
    diagnostics.mass_post_policy = ones(size(upstream.dens4, 4), 1);
    diagnostics.avg_birth_rate = 0;
    diagnostics.dens4 = upstream.dens4;
    diagnostics.vote4 = upstream.dens4 .* upstream.pref4;
    diagnostics.pref4 = upstream.pref4;
    diagnostics.bbbb4 = upstream.bbbb;
    diagnostics.zzzz4 = upstream.zzzz;
    diagnostics.totaldensity = upstream.totaldensity;
    diagnostics.totalvote_array = upstream.totalvote;
    diagnostics.ages = params.agemin:params.dage:params.agemax;
    diagnostics.a_grid = linspace(params.housingmin, params.housingmax, params.J);
    diagnostics.b_grid = linspace(params.bmin, params.bmax, params.I);

    avg_birth_rate = 0;
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
        'avg_birth_rate', 'birth_rate_by_age', 'child_dist_by_age', 'home_dist_by_age', ...
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

tmp = load('TransitionMatrix.mat', 'transitionmatrix', 'y_mid', 'z_lifecycle');
transitionmatrix = tmp.transitionmatrix;
z = tmp.y_mid;
K = size(z, 2);
Zlifecycle = tmp.z_lifecycle ./ tmp.z_lifecycle(1);
initialdist = stationary_dist(transitionmatrix(:, :, 1)');

J = params.J;
a = linspace(params.housingmin, params.housingmax, J);
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

Ipen = double(-bbb > aaa * a_price * params.CC);
Penalty = params.penalty;
Rb_line = rbPos .* (b >= 0) + rbNeg .* (b < 0);

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

            for iz = 1:K
                if age_pos < age_n
                    z_transition = transitionmatrix(:, :, age_pos)';
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

                income = exp(z(iz)) * Zlifecycle(age_pos);

                for ij = 1:J
                    for ii = 1:I
                        [maxvalue_nb, ind_b_nb, ind_a_nb] = solve_branch(ii, ij, income, aa, bb, ...
                            a_price, r_price, Rb_line, a, Ipen(:, :, iz), Penalty, params, ...
                            home_count, parity_count, expected_nobirth, false, age_pos == age_n);

                        [maxvalue_nb_dp, ~, ~] = solve_branch(ii, ij, income, aa, bb, ...
                            a_price * params.d_a_price, r_price_dp, Rb_line, a, Ipen(:, :, iz), Penalty, ...
                            params, home_count, parity_count, expected_nobirth_dp, false, age_pos == age_n);

                        index_b(ii, ij, iz, ih, ip) = ind_b_nb;
                        index_a(ii, ij, iz, ih, ip) = ind_a_nb;
                        index_b_birth(ii, ij, iz, ih, ip) = ind_b_nb;
                        index_a_birth(ii, ij, iz, ih, ip) = ind_a_nb;

                        if can_birth
                            [maxvalue_b, ind_b_b, ind_a_b] = solve_branch(ii, ij, income, aa, bb, ...
                                a_price, r_price, Rb_line, a, Ipen(:, :, iz), Penalty, params, ...
                                home_count, parity_count, expected_birth, true, age_pos == age_n);

                            [maxvalue_b_dp, ~, ~] = solve_branch(ii, ij, income, aa, bb, ...
                                a_price * params.d_a_price, r_price_dp, Rb_line, a, Ipen(:, :, iz), Penalty, ...
                                params, home_count, parity_count, expected_birth_dp, true, age_pos == age_n);

                            birth_prob(ii, ij, iz, ih, ip) = logistic_prob(maxvalue_b - maxvalue_nb, params.logit_scale);
                            valuefunction(ii, ij, iz, ih, ip) = smooth_value(maxvalue_nb, maxvalue_b, params.logit_scale);
                            valuefunction_dp(ii, ij, iz, ih, ip) = smooth_value(maxvalue_nb_dp, maxvalue_b_dp, params.logit_scale);
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

cohortsize = [14 12 10 10 10 10 9 8 7 5 4 2 1 1];
cohortsize = cohortsize / mean(cohortsize);

density_age = cell(age_n, 1);
vote_age = cell(age_n, 1);
home_dist_by_age = zeros(age_n, H);
parity_dist_by_age = zeros(age_n, P);
birth_rate_by_age = zeros(age_n, 1);
mass_pre_policy = zeros(age_n, 1);
mass_post_policy = zeros(age_n, 1);

density_prev = zeros(I, J, K, H, P);
for iz = 1:K
    density_prev(bzero, 1, iz, home_index(0), parity_index(0)) = initialdist(iz);
end

for age_pos = 1:age_n
    age = ages(age_pos);

    if age_pos > 1
        density_prev = apply_z_transition(density_age{age_pos - 1}, transitionmatrix(:, :, age_pos - 1)');
    end

    mass_pre_policy(age_pos) = sum(density_prev(:));
    d_vf = d_valuefunction_dp_ages{age_pos};
    vote_age{age_pos} = sign(d_vf) .* density_prev;

    for ih = 1:H
        home_dist_by_age(age_pos, ih) = sum(density_prev(:, :, :, ih, :), 'all') / max(mass_pre_policy(age_pos), 1e-12);
    end
    for ip = 1:P
        parity_dist_by_age(age_pos, ip) = sum(density_prev(:, :, :, :, ip), 'all') / max(mass_pre_policy(age_pos), 1e-12);
    end

    if any(params.birth_ages == age)
        birth_rate_by_age(age_pos) = sum(density_prev(:) .* birth_prob_ages{age_pos}(:)) / max(mass_pre_policy(age_pos), 1e-12);
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

disp(['Vote for higher prices -1 to 1 = ', num2str(totalvote)]);
disp(['Debt Stock = ', num2str(debtstock)]);
disp(['Avg birth rate (fertile ages) = ', num2str(avg_birth_rate)]);
disp(['Rent Share = ', num2str(sum(dens4(:, 1, :, :), 'all'))]);

diagnostics = struct();
diagnostics.params = params;
diagnostics.birth_rate_by_age = birth_rate_by_age;
diagnostics.child_dist_by_age = home_dist_by_age;
diagnostics.home_dist_by_age = home_dist_by_age;
diagnostics.parity_dist_by_age = parity_dist_by_age;
diagnostics.mass_pre_policy = mass_pre_policy;
diagnostics.mass_post_policy = mass_post_policy;
diagnostics.avg_birth_rate = avg_birth_rate;
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
diagnostics.age_mass = squeeze(sum(sum(sum(dens4, 1), 2), 3));

child_dist_by_age = home_dist_by_age;
age_mass = diagnostics.age_mass;
save('SS_fertility.mat', 'distance', 'a_price', 'rbPos', 'totalvote', 'debtstock', ...
    'avg_birth_rate', 'birth_rate_by_age', 'child_dist_by_age', 'home_dist_by_age', ...
    'parity_dist_by_age', 'age_mass', 'mass_pre_policy', 'mass_post_policy', 'dens4', 'vote4', ...
    'pref4', 'bbbb4', 'zzzz4', 'diagnostics');

end

function [maxvalue, ind_b, ind_a] = solve_branch(ii, ij, income, aa, bb, a_price, r_price, ...
    Rb_line, a_grid, Ipen_slice, Penalty, params, home_count, parity_count, continuation_value, is_birth, is_terminal)

consumption_plane = zeros(size(aa));
consumption_plane(:, 2:end) = max(income + Rb_line(ii) .* bb(ii, ij) + a_grid(ij) * a_price ...
    - aa(:, 2:end) * a_price .* (1 + params.ka * (1 - (aa(:, 2:end) == a_grid(ij)))) ...
    + bb(ii, ij) - bb(:, 2:end), 1e-20);
consumption_plane(:, 1) = max((income + Rb_line(ii) .* bb(ii, ij) + a_grid(ij) * a_price ...
    - aa(:, 1) * a_price .* (1 + params.ka * (1 - (aa(:, 1) == a_grid(ij)))) ...
    + bb(ii, ij) - bb(:, 1)) / (1 + params.s_h * params.theta_r), 1e-20);

rent_plane = zeros(size(aa));
rent_plane(:, 1) = consumption_plane(:, 1) ./ r_price * params.theta_r * params.s_h;

h_services = aa + params.theta_r * rent_plane;
h_eff = max(h_services, 1e-8) ./ ((1 + params.lambda_crowd * home_count) ^ params.psi_crowd);

value_plane = log(consumption_plane) + params.s_h * log(h_eff) + params.child_utility * home_count ...
    - Ipen_slice * Penalty;

if is_birth
    n_eff = min(home_count + 1, params.C - 1);
    h_eff_birth = max(h_services, 1e-8) ./ ((1 + params.lambda_crowd * n_eff) ^ params.psi_crowd);
    birth_utility_n = get_parity_birth_utility(params, parity_count);
    value_plane = log(consumption_plane) + params.s_h * log(h_eff_birth) + params.child_utility * n_eff ...
        + birth_utility_n - params.birth_cost - params.birth_price_coeff * a_price ...
        - Ipen_slice * Penalty;
end

if is_terminal
    bequest_plane = max(1e-20, bb + a_price .* aa);
    value_plane = value_plane + params.bequestweight * log(bequest_plane);
else
    value_plane = value_plane + params.beta * continuation_value;
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
params.leave_home_age_bins = [20 25 30];
params.leave_home_bin_probs = [0.588 0.147 0.265];
params.d_a_price = 1.01;

params = apply_overrides(params, benchmark_cfg.overrides);
end

function s = apply_overrides(s, overrides)
fields = fieldnames(overrides);
for i = 1:numel(fields)
    s.(fields{i}) = overrides.(fields{i});
end
end

function tf = is_upstream_reproduction_case(params)
tf = params.C == 1 ...
    && params.birth_utility == 0 ...
    && params.child_utility == 0 ...
    && params.birth_cost == 0 ...
    && params.lambda_crowd == 0 ...
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
