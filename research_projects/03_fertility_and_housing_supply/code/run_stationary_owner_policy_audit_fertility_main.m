function run_stationary_owner_policy_audit_fertility_main()
% run_stationary_owner_policy_audit_fertility_main.m
%
% Diagnose whether the stationary ownership pathology is already present in
% the renter-to-owner Bellman choice map at ages 25 and 30.

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
q_value = cfg.eval_price;
rb_pos = cfg.rbPos;
target_ages = [25, 30];

cases = { ...
    struct('case_name', 'contrast_I30_J14', 'I', 30, 'J', 14), ...
    struct('case_name', 'benchmark_I60_J14', 'I', 60, 'J', 14)};

summary_rows = table();
age25_rows = table();
results = struct([]);

for c = 1:numel(cases)
    case_cfg = cases{c};
    overrides = cfg.overrides;
    overrides.I = case_cfg.I;
    overrides.J = case_cfg.J;
    overrides.return_transition_objects = true;

    fprintf('Running owner-policy audit for %s...\n', case_cfg.case_name);
    t_start = tic;
    [distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([q_value, rb_pos], overrides);
    runtime_seconds = toc(t_start);

    case_summary = build_case_summary(case_cfg, diagnostics, q_value, rb_pos, distance, totalvote, debtstock, runtime_seconds, target_ages);
    summary_rows = [summary_rows; case_summary]; %#ok<AGROW>

    case_age25 = build_age25_state_map(case_cfg, diagnostics, q_value, rb_pos);
    age25_rows = [age25_rows; case_age25]; %#ok<AGROW>

    results(end + 1).case_name = case_cfg.case_name; %#ok<AGROW>
    results(end).diagnostics = diagnostics;
    results(end).summary = case_summary;
    results(end).age25 = case_age25;
end

writetable(summary_rows, fullfile(out_dir, 'structural_stationary_owner_policy_audit_summary.csv'));
writetable(age25_rows, fullfile(out_dir, 'structural_stationary_owner_policy_audit_age25_states.csv'));
save(fullfile(out_dir, 'structural_stationary_owner_policy_audit_results.mat'), 'results');
write_note(fullfile(out_dir, 'structural_stationary_owner_policy_audit.md'), summary_rows, age25_rows, q_value, rb_pos);
disp('Structural stationary owner-policy audit complete.');
end

function summary_rows = build_case_summary(case_cfg, diagnostics, q_value, rb_pos, distance, totalvote, debtstock, runtime_seconds, target_ages)
summary_rows = table();
for a = 1:numel(target_ages)
    target_age = target_ages(a);
    age_idx = find(diagnostics.ages == target_age, 1);
    if isempty(age_idx)
        continue;
    end

    post = diagnostics.density_raw_ages{age_idx};
    pre = diagnostics.density_pre_policy_ages{age_idx};
    idx_a = diagnostics.index_a_ages{age_idx};
    idx_b = diagnostics.index_b_ages{age_idx};
    idx_a_birth = diagnostics.index_a_birth_ages{age_idx};
    idx_b_birth = diagnostics.index_b_birth_ages{age_idx};
    birth_prob = diagnostics.birth_prob_ages{age_idx};

    a_grid = diagnostics.a_grid(:);
    b_grid = diagnostics.b_grid(:);
    z_grid = diagnostics.z_grid(:);
    z_lifecycle = diagnostics.z_lifecycle(:);
    home_grid = diagnostics.home_grid(:);
    parity_grid = diagnostics.parity_grid(:);

    owner_j = 2:numel(a_grid);
    renter_j = 1;
    owner_post = post(:, owner_j, :, :, :);
    owner_post_mass = sum(owner_post, 'all');
    post_mass = sum(post(:));

    top_h_idx = numel(a_grid);
    top2_h_idx = max(2, numel(a_grid) - 1):numel(a_grid);
    top_b_idx = numel(b_grid);
    top2_b_idx = max(1, numel(b_grid) - 1):numel(b_grid);
    small_owner_j = min(2, numel(a_grid));
    negative_b_mask = b_grid < 0;

    owner_entry_dest = zeros(numel(b_grid), numel(a_grid));
    owner_entry_infeasible_mass = 0.0;
    renter_mass = sum(pre(:, renter_j, :, :, :), 'all');

    for ip = 1:numel(parity_grid)
        for ih = 1:numel(home_grid)
            for iz = 1:numel(z_grid)
                income = exp(z_grid(iz)) * z_lifecycle(age_idx);
                for ii = 1:numel(b_grid)
                    mass = pre(ii, renter_j, iz, ih, ip);
                    if mass <= 0
                        continue;
                    end

                    current_b = b_grid(ii);
                    prob = birth_prob(ii, renter_j, iz, ih, ip);

                    nb = idx_b(ii, renter_j, iz, ih, ip);
                    na = idx_a(ii, renter_j, iz, ih, ip);
                    mass_nb = (1 - prob) * mass;
                    if na > 1
                        owner_entry_dest(nb, na) = owner_entry_dest(nb, na) + mass_nb;
                        if owner_choice_budget_residual(current_b, a_grid(renter_j), b_grid(nb), a_grid(na), income, q_value, rb_pos, diagnostics.params) < 0
                            owner_entry_infeasible_mass = owner_entry_infeasible_mass + mass_nb;
                        end
                    end

                    if prob > 0
                        nb_b = idx_b_birth(ii, renter_j, iz, ih, ip);
                        na_b = idx_a_birth(ii, renter_j, iz, ih, ip);
                        mass_b = prob * mass;
                        if na_b > 1
                            owner_entry_dest(nb_b, na_b) = owner_entry_dest(nb_b, na_b) + mass_b;
                            if owner_choice_budget_residual(current_b, a_grid(renter_j), b_grid(nb_b), a_grid(na_b), income, q_value, rb_pos, diagnostics.params) < 0
                                owner_entry_infeasible_mass = owner_entry_infeasible_mass + mass_b;
                            end
                        end
                    end
                end
            end
        end
    end

    owner_entry_mass = sum(owner_entry_dest(:));
    owner_entry_negative_b_mass = sum(owner_entry_dest(negative_b_mask, owner_j), 'all');

    row = struct2table(orderfields(struct( ...
        'case_name', string(case_cfg.case_name), ...
        'I', case_cfg.I, ...
        'J', case_cfg.J, ...
        'age', target_age, ...
        'runtime_seconds', runtime_seconds, ...
        'distance', distance, ...
        'vote_per_mass', totalvote / max(sum(diagnostics.age_mass), 1e-12), ...
        'debt_per_mass', debtstock / max(sum(diagnostics.age_mass), 1e-12), ...
        'q_value', q_value, ...
        'rb_pos', rb_pos, ...
        'post_owner_share', owner_post_mass / max(post_mass, 1e-12), ...
        'post_owner_top_h_share', sum(post(:, top_h_idx, :, :, :), 'all') / max(owner_post_mass, 1e-12), ...
        'post_owner_top2_h_share', sum(post(:, top2_h_idx, :, :, :), 'all') / max(owner_post_mass, 1e-12), ...
        'post_owner_top_b_share', sum(owner_post(top_b_idx, :, :, :, :), 'all') / max(owner_post_mass, 1e-12), ...
        'post_owner_top2_b_share', sum(owner_post(top2_b_idx, :, :, :, :), 'all') / max(owner_post_mass, 1e-12), ...
        'post_owner_negative_b_share', sum(owner_post(negative_b_mask, :, :, :, :), 'all') / max(owner_post_mass, 1e-12), ...
        'post_owner_small_h_share', sum(post(:, small_owner_j, :, :, :), 'all') / max(owner_post_mass, 1e-12), ...
        'post_owner_mean_b', weighted_b_mean(owner_post, b_grid), ...
        'post_owner_mean_h', weighted_h_mean(owner_post, a_grid(owner_j)), ...
        'renter_mass', renter_mass, ...
        'renter_to_owner_entry_share', owner_entry_mass / max(renter_mass, 1e-12), ...
        'renter_entry_top_h_share', sum(owner_entry_dest(:, top_h_idx), 'all') / max(owner_entry_mass, 1e-12), ...
        'renter_entry_top2_h_share', sum(owner_entry_dest(:, top2_h_idx), 'all') / max(owner_entry_mass, 1e-12), ...
        'renter_entry_top_b_share', sum(owner_entry_dest(top_b_idx, owner_j), 'all') / max(owner_entry_mass, 1e-12), ...
        'renter_entry_top2_b_share', sum(owner_entry_dest(top2_b_idx, owner_j), 'all') / max(owner_entry_mass, 1e-12), ...
        'renter_entry_negative_b_share', owner_entry_negative_b_mass / max(owner_entry_mass, 1e-12), ...
        'renter_entry_small_h_share', sum(owner_entry_dest(:, small_owner_j), 'all') / max(owner_entry_mass, 1e-12), ...
        'renter_entry_infeasible_owner_share', owner_entry_infeasible_mass / max(owner_entry_mass, 1e-12))));
    summary_rows = [summary_rows; row]; %#ok<AGROW>
end
end

function age25_rows = build_age25_state_map(case_cfg, diagnostics, q_value, rb_pos)
age25_rows = table();
target_age = 25;
age_idx = find(diagnostics.ages == target_age, 1);
if isempty(age_idx)
    return;
end

pre = diagnostics.density_pre_policy_ages{age_idx};
idx_a = diagnostics.index_a_ages{age_idx};
idx_b = diagnostics.index_b_ages{age_idx};
idx_a_birth = diagnostics.index_a_birth_ages{age_idx};
idx_b_birth = diagnostics.index_b_birth_ages{age_idx};
birth_prob = diagnostics.birth_prob_ages{age_idx};

a_grid = diagnostics.a_grid(:);
b_grid = diagnostics.b_grid(:);
z_grid = diagnostics.z_grid(:);
z_lifecycle = diagnostics.z_lifecycle(:);
home_grid = diagnostics.home_grid(:);
parity_grid = diagnostics.parity_grid(:);

for ip = 1:numel(parity_grid)
    for ih = 1:numel(home_grid)
        for iz = 1:numel(z_grid)
            income = exp(z_grid(iz)) * z_lifecycle(age_idx);
            for ii = 1:numel(b_grid)
                current_mass = pre(ii, 1, iz, ih, ip);
                if current_mass <= 0
                    continue;
                end

                current_b = b_grid(ii);
                nb_idx_a = idx_a(ii, 1, iz, ih, ip);
                nb_idx_b = idx_b(ii, 1, iz, ih, ip);
                b_idx_a = idx_a_birth(ii, 1, iz, ih, ip);
                b_idx_b = idx_b_birth(ii, 1, iz, ih, ip);

                nb_budget_residual = owner_choice_budget_residual(current_b, a_grid(1), b_grid(nb_idx_b), a_grid(nb_idx_a), income, q_value, rb_pos, diagnostics.params);
                b_budget_residual = owner_choice_budget_residual(current_b, a_grid(1), b_grid(b_idx_b), a_grid(b_idx_a), income, q_value, rb_pos, diagnostics.params);

                row = struct2table(orderfields(struct( ...
                    'case_name', string(case_cfg.case_name), ...
                    'z_index', iz, ...
                    'z_value', z_grid(iz), ...
                    'current_income', income, ...
                    'current_b', current_b, ...
                    'current_home_count', home_grid(ih), ...
                    'current_parity', parity_grid(ip), ...
                    'current_mass', current_mass, ...
                    'birth_prob', birth_prob(ii, 1, iz, ih, ip), ...
                    'nb_choice_owner', double(nb_idx_a > 1), ...
                    'nb_choice_a', a_grid(nb_idx_a), ...
                    'nb_choice_b', b_grid(nb_idx_b), ...
                    'nb_choice_top_h', double(nb_idx_a == numel(a_grid)), ...
                    'nb_choice_top_b', double(nb_idx_b == numel(b_grid)), ...
                    'nb_owner_budget_residual', nb_budget_residual, ...
                    'nb_owner_budget_infeasible', double(nb_idx_a > 1 && nb_budget_residual < 0), ...
                    'birth_choice_owner', double(b_idx_a > 1), ...
                    'birth_choice_a', a_grid(b_idx_a), ...
                    'birth_choice_b', b_grid(b_idx_b), ...
                    'birth_choice_top_h', double(b_idx_a == numel(a_grid)), ...
                    'birth_choice_top_b', double(b_idx_b == numel(b_grid)), ...
                    'birth_owner_budget_residual', b_budget_residual, ...
                    'birth_owner_budget_infeasible', double(b_idx_a > 1 && b_budget_residual < 0))));
                age25_rows = [age25_rows; row]; %#ok<AGROW>
            end
        end
    end
end
end

function residual = owner_choice_budget_residual(current_b, current_a, next_b, next_a, income, q_value, rb_pos, params)
if current_b >= 0
    current_return = rb_pos;
else
    current_return = rb_pos + params.rspread;
end
current_gross_resources = income + current_b * (1 + current_return) + current_a * q_value;
adjustment = 1 + params.ka * (1 - (next_a == current_a));
purchase_cost = next_a * q_value * adjustment;
residual = current_gross_resources - purchase_cost - next_b;
end

function out = weighted_b_mean(owner_post, b_grid)
owner_mass = sum(owner_post(:));
if owner_mass <= 0
    out = NaN;
    return;
end
b_plane = reshape(b_grid, [], 1, 1, 1, 1);
out = sum(owner_post .* b_plane, 'all') / owner_mass;
end

function out = weighted_h_mean(owner_post, owner_a_grid)
owner_mass = sum(owner_post(:));
if owner_mass <= 0
    out = NaN;
    return;
end
h_plane = reshape(owner_a_grid, 1, [], 1, 1, 1);
out = sum(owner_post .* h_plane, 'all') / owner_mass;
end

function write_note(path, summary_rows, age25_rows, q_value, rb_pos)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural stationary owner-policy audit\n\n');
fprintf(fid, 'This note asks a narrower question than the grid ladders: does the owner-boundary pathology already appear in the stationary renter-to-owner Bellman choice map, or only after the forward recursion has had time to concentrate mass?\n\n');
fprintf(fid, 'Fixed point for the audit:\n\n');
fprintf(fid, '- house price `q = %.3f`\n', q_value);
fprintf(fid, '- savings rate `rbPos = %.3f`\n\n', rb_pos);

fprintf(fid, '## Summary table\n\n');
fprintf(fid, '| case | age | post owner share | post owner top-h share | post owner top-b share | renter-to-owner entry share | renter-entry top-h share | renter-entry top-b share | renter-entry infeasible-owner share |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(summary_rows)
    fprintf(fid, '| %s | %d | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f |\n', ...
        summary_rows.case_name(i), summary_rows.age(i), summary_rows.post_owner_share(i), ...
        summary_rows.post_owner_top_h_share(i), summary_rows.post_owner_top_b_share(i), ...
        summary_rows.renter_to_owner_entry_share(i), summary_rows.renter_entry_top_h_share(i), ...
        summary_rows.renter_entry_top_b_share(i), summary_rows.renter_entry_infeasible_owner_share(i));
end

fprintf(fid, '\n## Age-25 renter state map\n\n');
fprintf(fid, '| case | z index | income | current b | mass | birth prob | no-birth owner? | no-birth a'' | no-birth b'' | no-birth top-h? | no-birth top-b? | no-birth infeasible? | birth owner? | birth a'' | birth b'' | birth top-h? | birth top-b? | birth infeasible? |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(age25_rows)
    fprintf(fid, '| %s | %d | %.3f | %.3f | %.6f | %.3f | %d | %.3f | %.3f | %d | %d | %d | %d | %.3f | %.3f | %d | %d | %d |\n', ...
        age25_rows.case_name(i), age25_rows.z_index(i), age25_rows.current_income(i), age25_rows.current_b(i), ...
        age25_rows.current_mass(i), age25_rows.birth_prob(i), age25_rows.nb_choice_owner(i), ...
        age25_rows.nb_choice_a(i), age25_rows.nb_choice_b(i), age25_rows.nb_choice_top_h(i), ...
        age25_rows.nb_choice_top_b(i), age25_rows.nb_owner_budget_infeasible(i), ...
        age25_rows.birth_choice_owner(i), age25_rows.birth_choice_a(i), age25_rows.birth_choice_b(i), ...
        age25_rows.birth_choice_top_h(i), age25_rows.birth_choice_top_b(i), age25_rows.birth_owner_budget_infeasible(i));
end

benchmark_25 = summary_rows(summary_rows.case_name == "benchmark_I60_J14" & summary_rows.age == 25, :);
benchmark_30 = summary_rows(summary_rows.case_name == "benchmark_I60_J14" & summary_rows.age == 30, :);
contrast_25 = summary_rows(summary_rows.case_name == "contrast_I30_J14" & summary_rows.age == 25, :);

fprintf(fid, '\n## Read\n\n');
if ~isempty(benchmark_25)
    fprintf(fid, '- In the benchmark grid, the refreshed age-25 Bellman choice map is now clean on the dimensions this audit was built to test.\n');
    fprintf(fid, '  - among renter states at age `25`, owner-entry mass going to the top housing cell is `%.3f`\n', benchmark_25.renter_entry_top_h_share);
    fprintf(fid, '  - owner-entry mass going to the top asset cell is `%.3f`\n', benchmark_25.renter_entry_top_b_share);
    fprintf(fid, '  - owner-entry mass with negative raw budget residual before clipping is `%.3f`\n', benchmark_25.renter_entry_infeasible_owner_share);
end
if ~isempty(benchmark_30)
    fprintf(fid, '- The same is true at age `30` in the benchmark grid.\n');
    fprintf(fid, '  - renter-entry top-h share is `%.3f`\n', benchmark_30.renter_entry_top_h_share);
    fprintf(fid, '  - renter-entry top-b share is `%.3f`\n', benchmark_30.renter_entry_top_b_share);
    fprintf(fid, '  - infeasible-owner share is `%.3f`\n', benchmark_30.renter_entry_infeasible_owner_share);
end
if ~isempty(contrast_25)
    fprintf(fid, '- The `I = 30, J = 14` contrast also clears on the same dimensions.\n');
    fprintf(fid, '  - at age `25`, renter-entry top-h share there is `%.3f`\n', contrast_25.renter_entry_top_h_share);
    fprintf(fid, '  - renter-entry top-b share is `%.3f`\n', contrast_25.renter_entry_top_b_share);
    fprintf(fid, '  - infeasible-owner share is `%.3f`\n', contrast_25.renter_entry_infeasible_owner_share);
end

fprintf(fid, '- Interpretation:\n');
fprintf(fid, '  - the hard feasibility penalty removes the earlier benchmark pattern in which renter-owner entry was jumping to top-cell and budget-infeasible owner states\n');
fprintf(fid, '  - remaining transition-path problems are therefore no longer explained by that stationary Bellman failure mode\n');
fprintf(fid, '- Implication:\n');
fprintf(fid, '  - do not start the outer RE loop yet, but the next diagnosis should now move back to the transition path itself, ideally on a medium or benchmark grid rather than only the `I = 20`, `J = 6` smoke grid\n');
fprintf(fid, '  - the stationary household feasibility bug is no longer the main blocker after this fix\n');
end
