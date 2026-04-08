function run_household_fertility_extension_main()
% First household-block fertility extension built on the project-02 VFI structure.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
if exist(project02_steady, 'dir')
    addpath(project02_steady);
end
ensure_external_matlab_data_paths();

p = default_params();
price_grid = [0.70, 0.90, 1.10, 1.30];
results = cell(numel(price_grid), 1);

for i = 1:numel(price_grid)
    results{i} = solve_household_block_at_price(price_grid(i), p);
end

summary = build_summary(results);
birth_age = build_birth_age_table(results);
child_vote = build_child_vote_table(results);

writetable(struct2table(summary), fullfile(out_dir, 'household_fertility_extension_summary.csv'));
writetable(birth_age, fullfile(out_dir, 'household_fertility_birth_rate_by_age.csv'));
writetable(child_vote, fullfile(out_dir, 'household_fertility_vote_by_child_state.csv'));

report_path = fullfile(out_dir, 'household_fertility_extension_report.md');
write_report(report_path, p, summary, birth_age, child_vote);

disp('Household-block fertility extension complete.');
end

function p = default_params()
p.rspread = 0.02;
p.rb_pos = 0.03;
p.ra = -0.03;
p.rent_markup = 0.02;
p.s_h = 1.00;
p.theta_r = 0.85;
p.beta = 0.98;
p.ka = 0.06;
p.bequest_weight = 0.98;
p.cc = 0.90;
p.penalty = 1e6;

p.agemin = 25;
p.agemax = 90;
p.dage = 5;
p.agepension = 60;

p.I = 20;
p.J = 8;
p.bmin = -12;
p.bmax = 16;
p.housingmin = 0;
p.housingmax = 18;

p.child_states = [0, 1, 2];
p.child_home_years = 10;
p.lambda_crowd = 0.35;
p.psi_crowd = 0.60;
p.birth_utility = 0.24;
p.child_utility = 0.09;
p.birth_cost = 0.05;
p.birth_logit_scale = 0.08;
p.birth_ages = [25, 30, 35, 40];

p.d_price = 1.01;
end

function result = solve_household_block_at_price(a_price, p)
rb_neg = p.rb_pos + p.rspread;
r_price = rb_neg - p.ra + p.rent_markup;

ages = p.agemin:p.dage:p.agemax;
age_n = numel(ages);

tmp = load('TransitionMatrix.mat');
transitionmatrix = tmp.transitionmatrix;
y_mid = tmp.y_mid;
z_lifecycle = tmp.z_lifecycle;
z = y_mid;
K = numel(z);
z_lifecycle = z_lifecycle ./ z_lifecycle(1);
if isfield(tmp, 'initialdist')
    initialdist = tmp.initialdist;
else
    stat = stationary_dist(transitionmatrix(:, :, 1)');
    initialdist = stat(:)';
end

b = linspace(p.bmin, p.bmax, p.I);
a = linspace(p.housingmin, p.housingmax, p.J);
bb = b' * ones(1, p.J);
aa = ones(p.I, 1) * a;
child_grid = p.child_states;
C = numel(child_grid);

Rb_line = p.rb_pos .* (b >= 0) + rb_neg .* (b < 0);

z_transitions = cell(age_n - 1, 1);
for iage = 1:(age_n - 1)
    z_transitions{iage} = transitionmatrix(:, :, iage)';
end

value_next = zeros(p.I, p.J, K, C);
value_next_dp = zeros(p.I, p.J, K, C);
birth_prob = zeros(p.I, p.J, K, C, age_n);
policy_child_next0 = ones(p.I, p.J, K, C, age_n);
policy_b_idx0 = ones(p.I, p.J, K, C, age_n);
policy_a_idx0 = ones(p.I, p.J, K, C, age_n);
policy_child_next1 = ones(p.I, p.J, K, C, age_n);
policy_b_idx1 = ones(p.I, p.J, K, C, age_n);
policy_a_idx1 = ones(p.I, p.J, K, C, age_n);
vote_pref = zeros(p.I, p.J, K, C, age_n);

for age_pos = age_n:-1:1
    age = ages(age_pos);
    current = -1e12 * ones(p.I, p.J, K, C);
    current_dp = -1e12 * ones(p.I, p.J, K, C);

    fertile = any(p.birth_ages == age);
    if age_pos < age_n
        z_transition = z_transitions{age_pos};
    else
        z_transition = [];
    end

    for ic = 1:C
        child_count = child_grid(ic);
        child_after_decay = max(child_count - 1, 0);
        for iz = 1:K
            if age_pos < age_n
                cont0 = expected_value_plane(z_transition(iz, :), value_next, child_after_decay, child_grid);
                cont1 = expected_value_plane(z_transition(iz, :), value_next, min(child_after_decay + 1, child_grid(end)), child_grid);
                cont0_dp = expected_value_plane(z_transition(iz, :), value_next_dp, child_after_decay, child_grid);
                cont1_dp = expected_value_plane(z_transition(iz, :), value_next_dp, min(child_after_decay + 1, child_grid(end)), child_grid);
            else
                cont0 = zeros(p.I, p.J);
                cont1 = zeros(p.I, p.J);
                cont0_dp = zeros(p.I, p.J);
                cont1_dp = zeros(p.I, p.J);
            end

            income = exp(z(iz)) * z_lifecycle(age_pos);
            for ij = 1:p.J
                for ii = 1:p.I
                    [best0, b0, a0] = evaluate_choice(ii, ij, income, aa, bb, a_price, r_price, Rb_line, ...
                        child_count, cont0, 0, p);
                    current(ii, ij, iz, ic) = best0;
                    policy_b_idx0(ii, ij, iz, ic, age_pos) = b0;
                    policy_a_idx0(ii, ij, iz, ic, age_pos) = a0;
                    policy_child_next0(ii, ij, iz, ic, age_pos) = child_index(child_after_decay, child_grid);

                    [best0_dp, ~, ~] = evaluate_choice(ii, ij, income, aa, bb, a_price * p.d_price, r_price, Rb_line, ...
                        child_count, cont0_dp, 0, p);
                    current_dp(ii, ij, iz, ic) = best0_dp;

                    if fertile
                        [best1, b1, a1] = evaluate_choice(ii, ij, income, aa, bb, a_price, r_price, Rb_line, ...
                            child_count, cont1, 1, p);
                        [best1_dp, ~, ~] = evaluate_choice(ii, ij, income, aa, bb, a_price * p.d_price, r_price, Rb_line, ...
                            child_count, cont1_dp, 1, p);
                        policy_b_idx1(ii, ij, iz, ic, age_pos) = b1;
                        policy_a_idx1(ii, ij, iz, ic, age_pos) = a1;
                        policy_child_next1(ii, ij, iz, ic, age_pos) = child_index(min(child_after_decay + 1, child_grid(end)), child_grid);
                        birth_prob(ii, ij, iz, ic, age_pos) = logistic_prob(best1 - best0, p.birth_logit_scale);
                        current(ii, ij, iz, ic) = smooth_value(best0, best1, p.birth_logit_scale);
                        current_dp(ii, ij, iz, ic) = smooth_value(best0_dp, best1_dp, p.birth_logit_scale);
                    end
                end
            end
        end
    end

    vote_pref(:, :, :, :, age_pos) = sign(current_dp - current);
    value_next = current;
    value_next_dp = current_dp;
end

distribution = zeros(p.I, p.J, K, C, age_n);
initial_child_idx = child_index(0, child_grid);
[~, bzero] = min(abs(b));
for iz = 1:K
    distribution(bzero, 1, iz, initial_child_idx, 1) = initialdist(iz);
end

birth_mass_by_age = zeros(age_n, 1);
vote_mass_by_age = zeros(age_n, 1);
child_vote_mass = zeros(C, 1);
child_pop_mass = zeros(C, 1);
rent_share_by_age = zeros(age_n, 1);

for age_pos = 1:age_n
    dist = distribution(:, :, :, :, age_pos);
    birth_policy_age = birth_prob(:, :, :, :, age_pos);
    vote_age = vote_pref(:, :, :, :, age_pos);

    birth_mass_by_age(age_pos) = sum(dist(:) .* birth_policy_age(:));
    vote_mass_by_age(age_pos) = sum(dist(:) .* vote_age(:));
    rent_share_by_age(age_pos) = sum(dist(:, 1, :, :), 'all');

    for ic = 1:C
        child_vote_mass(ic) = child_vote_mass(ic) + sum(dist(:, :, :, ic) .* vote_age(:, :, :, ic), 'all');
        child_pop_mass(ic) = child_pop_mass(ic) + sum(dist(:, :, :, ic), 'all');
    end

    if age_pos < age_n
        next_dist = zeros(p.I, p.J, K, C);
        z_transition = z_transitions{age_pos};
        for ic = 1:C
            for iz = 1:K
                for ij = 1:p.J
                    for ii = 1:p.I
                        mass = dist(ii, ij, iz, ic);
                        if mass <= 0
                            continue;
                        end
                        prob = birth_prob(ii, ij, iz, ic, age_pos);
                        nb0 = policy_b_idx0(ii, ij, iz, ic, age_pos);
                        na0 = policy_a_idx0(ii, ij, iz, ic, age_pos);
                        nc0 = policy_child_next0(ii, ij, iz, ic, age_pos);
                        nb1 = policy_b_idx1(ii, ij, iz, ic, age_pos);
                        na1 = policy_a_idx1(ii, ij, iz, ic, age_pos);
                        nc1 = policy_child_next1(ii, ij, iz, ic, age_pos);
                        for izn = 1:K
                            trans_mass = mass * z_transition(iz, izn);
                            next_dist(nb0, na0, izn, nc0) = next_dist(nb0, na0, izn, nc0) + (1 - prob) * trans_mass;
                            next_dist(nb1, na1, izn, nc1) = next_dist(nb1, na1, izn, nc1) + prob * trans_mass;
                        end
                    end
                end
            end
        end
        distribution(:, :, :, :, age_pos + 1) = next_dist;
    end
end

function stat = stationary_dist(z_transition)
[vec, ~] = eigs(z_transition', 1, 'largestreal');
stat = real(vec);
stat = stat ./ sum(stat);
stat = max(stat, 0);
stat = stat ./ sum(stat);
end

function prob = logistic_prob(delta, scale)
arg = max(-30, min(30, delta / max(scale, 1e-8)));
prob = 1 / (1 + exp(-arg));
end

function val = smooth_value(v0, v1, scale)
mx = max(v0, v1);
val = mx + scale * log(exp((v0 - mx) / max(scale, 1e-8)) + exp((v1 - mx) / max(scale, 1e-8)));
end

age_population = squeeze(sum(distribution, [1, 2, 3, 4]));
birth_rate_by_age = birth_mass_by_age ./ max(age_population, 1e-12);

result.price = a_price;
result.ages = ages(:);
result.birth_rate_by_age = birth_rate_by_age;
result.birth_mass_by_age = birth_mass_by_age;
result.vote_mass_by_age = vote_mass_by_age;
result.age_population = age_population;
result.total_birth_mass = sum(birth_mass_by_age);
result.total_vote_support = sum(vote_mass_by_age) / max(sum(age_population), 1e-12);
result.rent_share_avg = mean(rent_share_by_age);
result.child_pop_share = child_pop_mass ./ max(sum(child_pop_mass), 1e-12);
result.child_vote_support = child_vote_mass ./ max(child_pop_mass, 1e-12);
end

function out = expected_value_plane(z_weights, value_next, child_state, child_grid)
nc = child_index(child_state, child_grid);
slice = value_next(:, :, :, nc);
out = zeros(size(slice, 1), size(slice, 2));
for izn = 1:numel(z_weights)
    out = out + z_weights(izn) .* slice(:, :, izn);
end
end

function idx = child_index(child_state, child_grid)
idx = find(child_grid == child_state, 1);
end

function [best_value, best_b, best_a] = evaluate_choice(ii, ij, income, aa, bb, a_price, r_price, rb_line, child_count, continuation, birth_choice, p)
best_value = -1e12;
best_b = 1;
best_a = 1;

current_b = bb(ii, ij);
current_a = aa(ii, ij);
effective_child = child_count + birth_choice;

for next_a = 1:size(aa, 2)
    adj_cost = 1 + p.ka * (aa(1, next_a) ~= current_a);
    for next_b = 1:size(bb, 1)
        if next_a == 1
            cons = (income + rb_line(ii) * current_b + current_a * a_price ...
                - aa(next_b, next_a) * a_price * adj_cost + current_b - bb(next_b, next_a)) ...
                / (1 + p.s_h * p.theta_r);
            rent = cons / r_price * p.theta_r * p.s_h;
            housing_services = aa(next_b, next_a) + p.theta_r * rent;
        else
            cons = income + rb_line(ii) * current_b + current_a * a_price ...
                - aa(next_b, next_a) * a_price * adj_cost + current_b - bb(next_b, next_a);
            rent = 0.0;
            housing_services = aa(next_b, next_a);
        end

        penalty = 0;
        if -bb(next_b, next_a) > aa(next_b, next_a) * a_price * p.cc
            penalty = p.penalty;
        end
        if cons <= 1e-12
            continue;
        end

        h_eff = max(housing_services, 1e-8) / (1 + p.lambda_crowd * effective_child) ^ p.psi_crowd;
        flow = log(cons) + p.s_h * log(max(h_eff, 1e-8)) + p.child_utility * child_count ...
            + p.birth_utility * birth_choice - p.birth_cost * birth_choice - penalty;
        bequest_term = p.bequest_weight * log(max(bb(next_b, next_a) + a_price * aa(next_b, next_a), 1e-8));
        value = flow + continuation(next_b, next_a);
        if isnan(continuation(next_b, next_a))
            value = -1e12;
        end

        if continuation(next_b, next_a) == 0
            value = flow + bequest_term;
        end

        if value > best_value
            best_value = value;
            best_b = next_b;
            best_a = next_a;
        end
    end
end
end

function summary = build_summary(results)
results = [results{:}];
summary = repmat(struct( ...
    'price', 0.0, ...
    'total_birth_mass', 0.0, ...
    'total_vote_support', 0.0, ...
    'rent_share_avg', 0.0, ...
    'birth_rate_age25_40', 0.0), numel(results), 1);

for i = 1:numel(results)
    age_mask = results(i).ages >= 25 & results(i).ages <= 40;
    summary(i).price = results(i).price;
    summary(i).total_birth_mass = results(i).total_birth_mass;
    summary(i).total_vote_support = results(i).total_vote_support;
    summary(i).rent_share_avg = results(i).rent_share_avg;
    summary(i).birth_rate_age25_40 = mean(results(i).birth_rate_by_age(age_mask));
end
end

function tbl = build_birth_age_table(results)
results = [results{:}];
rows = [];
for i = 1:numel(results)
    row = table(results(i).ages, repmat(results(i).price, numel(results(i).ages), 1), ...
        results(i).birth_rate_by_age, results(i).vote_mass_by_age ./ max(results(i).age_population, 1e-12), ...
        'VariableNames', {'age', 'price', 'birth_rate', 'vote_support'});
    rows = [rows; row]; %#ok<AGROW>
end
tbl = rows;
end

function tbl = build_child_vote_table(results)
results = [results{:}];
rows = [];
for i = 1:numel(results)
    child_state = (0:2)';
    row = table(repmat(results(i).price, numel(child_state), 1), child_state, ...
        results(i).child_pop_share(:), results(i).child_vote_support(:), ...
        'VariableNames', {'price', 'child_state', 'population_share', 'vote_support'});
    rows = [rows; row]; %#ok<AGROW>
end
tbl = rows;
end

function write_report(path, p, summary, birth_age, child_vote)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write report file: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Household-block fertility extension report\n\n');
fprintf(fid, '- Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '- This is the first project-03 MATLAB extension that uses the upstream household VFI structure rather than the representative-agent aggregate prototype.\n');
fprintf(fid, '- External MATLAB assets loaded from `D:\\research_data\\zac_and_david` with fallback path support.\n\n');

fprintf(fid, '## Model design\n\n');
fprintf(fid, '- Base solver style: project-02 household VFI with age-income transition matrices.\n');
fprintf(fid, '- Added state: dependent children at home (`0`, `1`, `2`).\n');
fprintf(fid, '- Added choice at fertile ages (`25`, `30`, `35`, `40`): discrete birth decision.\n');
fprintf(fid, '- Housing crowding channel: effective housing services scaled by `(1 + lambda_crowd * children)^(-psi_crowd)`.\n');
fprintf(fid, '- Birth choice is smoothed with a logit approximation to avoid all-or-nothing corner solutions in the first-pass calibration.\n');
fprintf(fid, '- Price perturbation vote object retained from the NIMBY code so we can see how fertility changes the voting margin.\n\n');

fprintf(fid, '### Parameters\n\n');
fprintf(fid, '- `birth_utility = %.3f`\n', p.birth_utility);
fprintf(fid, '- `child_utility = %.3f`\n', p.child_utility);
fprintf(fid, '- `birth_cost = %.3f`\n', p.birth_cost);
fprintf(fid, '- `birth_logit_scale = %.3f`\n', p.birth_logit_scale);
fprintf(fid, '- `lambda_crowd = %.3f`\n', p.lambda_crowd);
fprintf(fid, '- `psi_crowd = %.3f`\n', p.psi_crowd);
fprintf(fid, '- Grids: `I=%d`, `J=%d`, child states = `%d`\n\n', p.I, p.J, numel(p.child_states));

fprintf(fid, '## Summary table\n\n');
fprintf(fid, '| price | total_birth_mass | total_vote_support | rent_share_avg | birth_rate_age25_40 |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: |\n');
for i = 1:height(struct2table(summary))
    fprintf(fid, '| %.2f | %.6f | %.6f | %.6f | %.6f |\n', summary(i).price, summary(i).total_birth_mass, summary(i).total_vote_support, summary(i).rent_share_avg, summary(i).birth_rate_age25_40);
end

fprintf(fid, '\n## Readout\n\n');
fprintf(fid, '- The key object is how the household birth decision and vote support move as the exogenous house-price level rises.\n');
fprintf(fid, '- This is not yet a full general-equilibrium fertility-NIMBY solver, but it is the first proper household-block step toward one.\n');
fprintf(fid, '- The next modelling step is to endogenize the price object instead of evaluating the household block on a small price grid.\n\n');

fprintf(fid, '## Files\n\n');
fprintf(fid, '- `household_fertility_extension_summary.csv`\n');
fprintf(fid, '- `household_fertility_birth_rate_by_age.csv`\n');
fprintf(fid, '- `household_fertility_vote_by_child_state.csv`\n');
end
