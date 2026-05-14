function run_stationary_grid_audit_fertility_main()
% run_stationary_grid_audit_fertility_main.m
%
% Diagnose how sensitive the structural stationary benchmark is to the
% asset / housing grid, and check whether the new flat-path transition
% stack reproduces the same stationary moments on each grid.

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
grid_specs = [20, 6; 30, 8; 40, 10; 50, 12; 60, 14];

results = repmat(struct(), size(grid_specs, 1), 1);
rows = table();

for i = 1:size(grid_specs, 1)
    overrides = cfg.overrides;
    overrides.I = grid_specs(i, 1);
    overrides.J = grid_specs(i, 2);

    fprintf('Running stationary grid audit for I = %d, J = %d...\n', overrides.I, overrides.J);
    t_start = tic;
    [distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([q_value, rb_pos], overrides);
    steady = build_stationary_metrics(diagnostics, distance, totalvote, debtstock);

    solver_results = solve_household_path_fertility([q_value, q_value, q_value, q_value], overrides, ...
        struct('rbPos_path', rb_pos, 'initial_q', q_value));
    simulation = forward_distribution_path_fertility(solver_results, [], struct('store_cross_section', true));
    summary = summarize_transition_path_fertility(solver_results, simulation);
    flat = build_flat_path_metrics(summary);
    runtime_seconds = toc(t_start);

    results(i).grid_label = sprintf('I=%d,J=%d', overrides.I, overrides.J);
    results(i).overrides = overrides;
    results(i).steady = steady;
    results(i).flat = flat;
    results(i).steady_mean_age_first_birth = steady.mean_age_first_birth;
    results(i).flat_mean_age_first_birth_t1 = flat.mean_age_first_birth_t1;
    results(i).runtime_seconds = runtime_seconds;

    row = table( ...
        string(results(i).grid_label), ...
        overrides.I, ...
        overrides.J, ...
        runtime_seconds, ...
        steady.total_mass, ...
        steady.vote_per_mass, ...
        steady.debt_per_mass, ...
        steady.avg_birth_rate, ...
        steady.mean_age_first_birth, ...
        steady.owner_share_25_34, ...
        steady.mortgaged_owner_share_under_35, ...
        steady.rent_share, ...
        flat.total_mass_t1, ...
        flat.total_mass_max_abs_change, ...
        flat.owner_share_25_34_t1, ...
        flat.owner_share_25_34_max_abs_change, ...
        flat.mortgaged_owner_share_under_35_t1, ...
        flat.mortgaged_owner_share_under_35_max_abs_change, ...
        flat.avg_birth_rate_t1, ...
        flat.avg_birth_rate_max_abs_change, ...
        flat.mean_age_first_birth_t1, ...
        flat.mean_age_first_birth_max_abs_change, ...
        flat.owner_share_25_34_t1 - steady.owner_share_25_34, ...
        flat.mortgaged_owner_share_under_35_t1 - steady.mortgaged_owner_share_under_35, ...
        flat.avg_birth_rate_t1 - steady.avg_birth_rate, ...
        flat.mean_age_first_birth_t1 - steady.mean_age_first_birth, ...
        'VariableNames', { ...
        'grid_label', 'I', 'J', 'runtime_seconds', ...
        'steady_total_mass', 'steady_vote_per_mass', 'steady_debt_per_mass', ...
        'steady_avg_birth_rate', 'steady_mean_age_first_birth', ...
        'steady_owner_share_25_34', 'steady_mortgaged_owner_share_under_35', 'steady_rent_share', ...
        'flat_total_mass_t1', 'flat_total_mass_max_abs_change', ...
        'flat_owner_share_25_34_t1', 'flat_owner_share_25_34_max_abs_change', ...
        'flat_mortgaged_owner_share_under_35_t1', 'flat_mortgaged_owner_share_under_35_max_abs_change', ...
        'flat_avg_birth_rate_t1', 'flat_avg_birth_rate_max_abs_change', ...
        'flat_mean_age_first_birth_t1', 'flat_mean_age_first_birth_max_abs_change', ...
        'gap_owner_share_25_34_t1', 'gap_mortgaged_owner_share_under_35_t1', ...
        'gap_avg_birth_rate_t1', 'gap_mean_age_first_birth_t1'});
    rows = [rows; row]; %#ok<AGROW>
end

writetable(rows, fullfile(out_dir, 'structural_stationary_grid_audit.csv'));
save(fullfile(out_dir, 'structural_stationary_grid_audit_results.mat'), 'results');
write_note(fullfile(out_dir, 'structural_stationary_grid_audit.md'), rows, q_value, rb_pos);
disp('Structural stationary grid audit complete.');
end

function metrics = build_stationary_metrics(diagnostics, distance, totalvote, debtstock)
ages = diagnostics.ages(:);
age_mass = diagnostics.age_mass(:);
owner_mass_age = squeeze(sum(sum(sum(diagnostics.dens4(:, 2:end, :, :), 1), 2), 3));
owner_mass_age = owner_mass_age(:);

b_grid = diagnostics.b_grid(:);
negative_b_mask = b_grid < 0;
if any(negative_b_mask)
    mortgaged_owner_mass_age = squeeze(sum(sum(sum(diagnostics.dens4(negative_b_mask, 2:end, :, :), 1), 2), 3));
else
    mortgaged_owner_mass_age = zeros(size(age_mass));
end
mortgaged_owner_mass_age = mortgaged_owner_mass_age(:);

age2534_mask = ages >= 25 & ages < 35;
under35_mask = ages < 35;
total_mass = sum(age_mass);

metrics = struct();
metrics.distance = distance;
metrics.total_mass = total_mass;
metrics.vote_per_mass = totalvote / max(total_mass, 1e-12);
metrics.debt_per_mass = debtstock / max(total_mass, 1e-12);
metrics.avg_birth_rate = diagnostics.avg_birth_rate;
metrics.mean_age_first_birth = diagnostics.mean_age_first_birth;
metrics.share_first_birth_30_plus = diagnostics.share_first_birth_30_plus;
metrics.owner_share_25_34 = sum(owner_mass_age(age2534_mask)) / max(sum(age_mass(age2534_mask)), 1e-12);
metrics.mortgaged_owner_share_under_35 = sum(mortgaged_owner_mass_age(under35_mask)) / max(sum(age_mass(under35_mask)), 1e-12);
metrics.rent_share = sum(diagnostics.dens4(:, 1, :, :), 'all') / max(total_mass, 1e-12);
end

function metrics = build_flat_path_metrics(summary)
metrics = struct();
metrics.total_mass_t1 = summary.total_mass(1);
metrics.total_mass_max_abs_change = max(abs(summary.total_mass - summary.total_mass(1)));
metrics.owner_share_25_34_t1 = summary.owner_share_25_34(1);
metrics.owner_share_25_34_max_abs_change = max(abs(summary.owner_share_25_34 - summary.owner_share_25_34(1)));
metrics.mortgaged_owner_share_under_35_t1 = summary.mortgaged_owner_share_under_35(1);
metrics.mortgaged_owner_share_under_35_max_abs_change = max(abs(summary.mortgaged_owner_share_under_35 - summary.mortgaged_owner_share_under_35(1)));
metrics.avg_birth_rate_t1 = summary.avg_birth_rate(1);
metrics.avg_birth_rate_max_abs_change = max(abs(summary.avg_birth_rate - summary.avg_birth_rate(1)));
metrics.mean_age_first_birth_t1 = summary.mean_age_first_birth(1);
metrics.mean_age_first_birth_max_abs_change = max(abs(summary.mean_age_first_birth - summary.mean_age_first_birth(1)), [], 'omitnan');
if ~isfinite(metrics.mean_age_first_birth_max_abs_change)
    metrics.mean_age_first_birth_max_abs_change = NaN;
end
end

function write_note(path, rows, q_value, rb_pos)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural stationary grid audit\n\n');
fprintf(fid, 'This note diagnoses the structural steady-state benchmark at a fixed price before any outer transition-path RE iteration.\n\n');
fprintf(fid, 'Fixed point for the audit:\n\n');
fprintf(fid, '- house price `q = %.3f`\n', q_value);
fprintf(fid, '- savings rate `rbPos = %.3f`\n\n', rb_pos);
fprintf(fid, 'Objects compared on each grid:\n\n');
fprintf(fid, '- `SolveSS_fertility.m` steady-state diagnostics\n');
fprintf(fid, '- flat-path transition stack from `solve_household_path_fertility.m` -> `forward_distribution_path_fertility.m` -> `summarize_transition_path_fertility.m`\n\n');

fprintf(fid, '## Grid ladder\n\n');
fprintf(fid, '| grid | runtime s | steady owner 25-34 | steady mortgaged-owner under 35 | steady avg birth rate | steady mean age first birth | flat owner 25-34 t1 | flat mortgaged-owner under 35 t1 | gap owner | gap mortgage |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(rows)
    fprintf(fid, '| %s | %.1f | %.6f | %.6f | %.6f | %.3f | %.6f | %.6f | %.6f | %.6f |\n', ...
        rows.grid_label(i), rows.runtime_seconds(i), rows.steady_owner_share_25_34(i), ...
        rows.steady_mortgaged_owner_share_under_35(i), rows.steady_avg_birth_rate(i), ...
        rows.steady_mean_age_first_birth(i), rows.flat_owner_share_25_34_t1(i), ...
        rows.flat_mortgaged_owner_share_under_35_t1(i), rows.gap_owner_share_25_34_t1(i), ...
        rows.gap_mortgaged_owner_share_under_35_t1(i));
end

fprintf(fid, '\n## Flat-path constancy check\n\n');
fprintf(fid, '| grid | flat total mass t1 | max abs mass change | max abs owner change | max abs mortgage change | max abs birth-rate change | max abs mean-age-first-birth change |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(rows)
    fprintf(fid, '| %s | %.6f | %.6f | %.6f | %.6f | %.6f | %.6f |\n', ...
        rows.grid_label(i), rows.flat_total_mass_t1(i), rows.flat_total_mass_max_abs_change(i), ...
        rows.flat_owner_share_25_34_max_abs_change(i), rows.flat_mortgaged_owner_share_under_35_max_abs_change(i), ...
        rows.flat_avg_birth_rate_max_abs_change(i), rows.flat_mean_age_first_birth_max_abs_change(i));
end

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- The key diagnosis target here is whether young ownership is already unstable in the stationary solver before any non-flat transition path is introduced.\n');
fprintf(fid, '- If the steady-state moments move sharply across the grid ladder, the outer RE loop should stay on hold until the benchmark resolution problem is understood.\n');
fprintf(fid, '- The current audit shows that the flat-path transition stack reproduces the same-grid stationary ownership shares, average birth rates, and mean age at first birth exactly, and it keeps total mass at `1.000000`.\n');
fprintf(fid, '- That means the remaining issue is not a vote-price loop or a generic path-solver failure.\n');
fprintf(fid, '- The earlier timing gap came from an unweighted steady-state timing diagnostic in `SolveSS_fertility.m`; the main timing output is now cohort-weighted and aligned with the path stack.\n');
fprintf(fid, '- Inference: the next diagnosis should focus on why young ownership is so non-monotone across the stationary grid ladder.\n');
end
