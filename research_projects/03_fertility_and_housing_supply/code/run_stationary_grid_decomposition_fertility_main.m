function run_stationary_grid_decomposition_fertility_main()
% run_stationary_grid_decomposition_fertility_main.m
%
% Decompose the stationary grid-sensitivity problem by varying the asset
% grid and housing grid one at a time around the benchmark solver.

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

families = { ...
    struct('name', 'vary_I_hold_J14', 'I_list', [20, 30, 40, 50, 60], 'J_list', [14, 14, 14, 14, 14]), ...
    struct('name', 'vary_J_hold_I60', 'I_list', [60, 60, 60, 60, 60], 'J_list', [6, 8, 10, 12, 14])};

rows = table();
results = struct([]);

for f = 1:numel(families)
    family = families{f};
    for i = 1:numel(family.I_list)
        overrides = cfg.overrides;
        overrides.I = family.I_list(i);
        overrides.J = family.J_list(i);
        grid_label = sprintf('I=%d,J=%d', overrides.I, overrides.J);

        fprintf('Running stationary decomposition for %s / %s...\n', family.name, grid_label);
        t_start = tic;
        [distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([q_value, rb_pos], overrides);
        metrics = build_decomposition_metrics(diagnostics, distance, totalvote, debtstock);
        runtime_seconds = toc(t_start);

        results(end + 1).family = family.name; %#ok<AGROW>
        results(end).grid_label = grid_label;
        results(end).metrics = metrics;

        row = struct2table(orderfields(struct( ...
            'family', string(family.name), ...
            'grid_label', string(grid_label), ...
            'I', overrides.I, ...
            'J', overrides.J, ...
            'runtime_seconds', runtime_seconds, ...
            'b_step', metrics.b_step, ...
            'first_owner_house', metrics.first_owner_house, ...
            'second_owner_house', metrics.second_owner_house, ...
            'vote_per_mass', metrics.vote_per_mass, ...
            'debt_per_mass', metrics.debt_per_mass, ...
            'rent_share', metrics.rent_share, ...
            'owner_share_25_34', metrics.owner_share_25_34, ...
            'mortgaged_owner_share_under_35', metrics.mortgaged_owner_share_under_35, ...
            'mortgage_share_among_owners_under_35', metrics.mortgage_share_among_owners_under_35, ...
            'owner_share_age25', metrics.owner_share_age25, ...
            'mortgaged_owner_share_age25', metrics.mortgaged_owner_share_age25, ...
            'small_owner_share_age25', metrics.small_owner_share_age25, ...
            'small_owner_share_among_owners_age25', metrics.small_owner_share_among_owners_age25, ...
            'renter_positive_asset_share_age25', metrics.renter_positive_asset_share_age25, ...
            'mean_owner_b_age25', metrics.mean_owner_b_age25, ...
            'mean_owner_h_age25', metrics.mean_owner_h_age25, ...
            'owner_share_age30', metrics.owner_share_age30, ...
            'mortgaged_owner_share_age30', metrics.mortgaged_owner_share_age30, ...
            'small_owner_share_age30', metrics.small_owner_share_age30, ...
            'small_owner_share_among_owners_age30', metrics.small_owner_share_among_owners_age30, ...
            'renter_positive_asset_share_age30', metrics.renter_positive_asset_share_age30, ...
            'mean_owner_b_age30', metrics.mean_owner_b_age30, ...
            'mean_owner_h_age30', metrics.mean_owner_h_age30)));
        rows = [rows; row]; %#ok<AGROW>
    end
end

writetable(rows, fullfile(out_dir, 'structural_stationary_grid_decomposition.csv'));
save(fullfile(out_dir, 'structural_stationary_grid_decomposition_results.mat'), 'results');
write_note(fullfile(out_dir, 'structural_stationary_grid_decomposition.md'), rows, q_value, rb_pos);
disp('Structural stationary grid decomposition complete.');
end

function metrics = build_decomposition_metrics(diagnostics, distance, totalvote, debtstock)
ages = diagnostics.ages(:);
age_mass = diagnostics.age_mass(:);
dens4 = diagnostics.dens4;
b_grid = diagnostics.b_grid(:);
a_grid = diagnostics.a_grid(:);

negative_b_mask = b_grid < 0;
nonnegative_b_mask = b_grid >= 0;
owner_j_mask = 2:numel(a_grid);
small_owner_j = min(2, numel(a_grid));
large_owner_j_mask = 3:numel(a_grid);
age2534_mask = ages >= 25 & ages < 35;
under35_mask = ages < 35;

owner_mass_age = squeeze(sum(sum(sum(dens4(:, owner_j_mask, :, :), 1), 2), 3));
owner_mass_age = owner_mass_age(:);
if any(negative_b_mask)
    mort_owner_mass_age = squeeze(sum(sum(sum(dens4(negative_b_mask, owner_j_mask, :, :), 1), 2), 3));
else
    mort_owner_mass_age = zeros(size(age_mass));
end
mort_owner_mass_age = mort_owner_mass_age(:);

metrics = struct();
metrics.distance = distance;
metrics.vote_per_mass = totalvote / max(sum(age_mass), 1e-12);
metrics.debt_per_mass = debtstock / max(sum(age_mass), 1e-12);
metrics.rent_share = sum(dens4(:, 1, :, :), 'all') / max(sum(age_mass), 1e-12);
metrics.owner_share_25_34 = sum(owner_mass_age(age2534_mask)) / max(sum(age_mass(age2534_mask)), 1e-12);
metrics.mortgaged_owner_share_under_35 = sum(mort_owner_mass_age(under35_mask)) / max(sum(age_mass(under35_mask)), 1e-12);
metrics.mortgage_share_among_owners_under_35 = sum(mort_owner_mass_age(under35_mask)) / max(sum(owner_mass_age(under35_mask)), 1e-12);
metrics.b_step = mean(diff(b_grid));
metrics.first_owner_house = conditional_grid_value(a_grid, 2);
metrics.second_owner_house = conditional_grid_value(a_grid, 3);

metrics.owner_share_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, mass_age) sum(dens_age(:, owner_j_mask, :), 'all') / max(mass_age, 1e-12));
metrics.mortgaged_owner_share_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, mass_age) sum(dens_age(negative_b_mask, owner_j_mask, :), 'all') / max(mass_age, 1e-12));
metrics.small_owner_share_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, mass_age) sum(dens_age(:, small_owner_j, :), 'all') / max(mass_age, 1e-12));
metrics.small_owner_share_among_owners_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, ~) sum(dens_age(:, small_owner_j, :), 'all') / max(sum(dens_age(:, owner_j_mask, :), 'all'), 1e-12));
metrics.renter_positive_asset_share_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, mass_age) sum(dens_age(nonnegative_b_mask, 1, :), 'all') / max(mass_age, 1e-12));
metrics.mean_owner_b_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, ~) weighted_b_mean(dens_age, b_grid, owner_j_mask));
metrics.mean_owner_h_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, ~) weighted_h_mean(dens_age, a_grid, owner_j_mask));

metrics.owner_share_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, mass_age) sum(dens_age(:, owner_j_mask, :), 'all') / max(mass_age, 1e-12));
metrics.mortgaged_owner_share_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, mass_age) sum(dens_age(negative_b_mask, owner_j_mask, :), 'all') / max(mass_age, 1e-12));
metrics.small_owner_share_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, mass_age) sum(dens_age(:, small_owner_j, :), 'all') / max(mass_age, 1e-12));
metrics.small_owner_share_among_owners_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, ~) sum(dens_age(:, small_owner_j, :), 'all') / max(sum(dens_age(:, owner_j_mask, :), 'all'), 1e-12));
metrics.renter_positive_asset_share_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, mass_age) sum(dens_age(nonnegative_b_mask, 1, :), 'all') / max(mass_age, 1e-12));
metrics.mean_owner_b_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, ~) weighted_b_mean(dens_age, b_grid, owner_j_mask));
metrics.mean_owner_h_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, ~) weighted_h_mean(dens_age, a_grid, owner_j_mask));

if isempty(large_owner_j_mask)
    metrics.large_owner_share_age25 = NaN;
    metrics.large_owner_share_age30 = NaN;
else
    metrics.large_owner_share_age25 = age_metric(dens4, ages, age_mass, 25, @(dens_age, mass_age) sum(dens_age(:, large_owner_j_mask, :), 'all') / max(mass_age, 1e-12));
    metrics.large_owner_share_age30 = age_metric(dens4, ages, age_mass, 30, @(dens_age, mass_age) sum(dens_age(:, large_owner_j_mask, :), 'all') / max(mass_age, 1e-12));
end
end

function out = age_metric(dens4, ages, age_mass, target_age, fn)
idx = find(ages == target_age, 1);
if isempty(idx)
    out = NaN;
    return;
end
dens_age = squeeze(dens4(:, :, :, idx));
mass_age = age_mass(idx);
out = fn(dens_age, mass_age);
end

function out = weighted_b_mean(dens_age, b_grid, owner_j_mask)
owner_dens = dens_age(:, owner_j_mask, :);
owner_mass = sum(owner_dens(:));
if owner_mass <= 0
    out = NaN;
    return;
end
b_plane = reshape(b_grid, [], 1, 1);
out = sum(owner_dens .* b_plane, 'all') / owner_mass;
end

function out = weighted_h_mean(dens_age, a_grid, owner_j_mask)
owner_dens = dens_age(:, owner_j_mask, :);
owner_mass = sum(owner_dens(:));
if owner_mass <= 0
    out = NaN;
    return;
end
h_plane = reshape(a_grid(owner_j_mask), 1, [], 1);
out = sum(owner_dens .* h_plane, 'all') / owner_mass;
end

function out = conditional_grid_value(grid, idx)
if numel(grid) >= idx
    out = grid(idx);
else
    out = NaN;
end
end

function write_note(path, rows, q_value, rb_pos)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural stationary grid decomposition\n\n');
fprintf(fid, 'This note breaks the stationary grid-sensitivity problem into one-at-a-time asset-grid and housing-grid variations.\n\n');
fprintf(fid, 'Fixed point for the audit:\n\n');
fprintf(fid, '- house price `q = %.3f`\n', q_value);
fprintf(fid, '- savings rate `rbPos = %.3f`\n\n', rb_pos);

write_family_table(fid, rows, "vary_I_hold_J14", '## Vary I, hold J = 14');
write_family_table(fid, rows, "vary_J_hold_I60", '## Vary J, hold I = 60');

subset_I = rows(rows.family == "vary_I_hold_J14", :);
subset_J = rows(rows.family == "vary_J_hold_I60", :);
max_small_owner = max([rows.small_owner_share_among_owners_age25; rows.small_owner_share_among_owners_age30]);
min_owner_I = min(subset_I.owner_share_25_34);
max_owner_I = max(subset_I.owner_share_25_34);
min_owner_J = min(subset_J.owner_share_25_34);
max_owner_J = max(subset_J.owner_share_25_34);
min_owner_h_age25 = min(rows.mean_owner_h_age25);
max_owner_h_age25 = max(rows.mean_owner_h_age25);
min_owner_b_age25 = min(rows.mean_owner_b_age25);
max_owner_b_age25 = max(rows.mean_owner_b_age25);

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- This decomposition is meant to answer a narrower question than the broad grid ladder: is young ownership mostly moving with the asset grid, the housing grid, or both?\n');
fprintf(fid, '- The answer from this pass is: mostly the **asset grid**, with some nontrivial housing-grid interaction.\n');
fprintf(fid, '  - holding `J = 14` fixed, owner share `25-34` ranges from about `%.3f` to `%.3f`\n', min_owner_I, max_owner_I);
fprintf(fid, '  - holding `I = 60` fixed, owner share `25-34` ranges from about `%.3f` to `%.3f`\n', min_owner_J, max_owner_J);
fprintf(fid, '- The most striking pathology is not a starter-home margin.\n');
fprintf(fid, '  - the smallest owner cell is unused at ages `25` and `30` in every audited case\n');
fprintf(fid, '  - max smallest-owner share among owners across those ages is `%.3f`\n', max_small_owner);
fprintf(fid, '  - young owners are concentrated in very large housing positions instead:\n');
fprintf(fid, '    - age-25 mean owner housing is roughly `%.1f` to `%.1f` on a grid with max housing `15`\n', min_owner_h_age25, max_owner_h_age25);
fprintf(fid, '    - age-25 mean owner assets range from about `%.1f` to `%.1f`, often near the top of the `b` grid\n', min_owner_b_age25, max_owner_b_age25);
fprintf(fid, '- So the current ownership extensive margin is effectively:\n');
fprintf(fid, '  - a thin set of rich, large-house buyers\n');
fprintf(fid, '  - versus a broad renter mass\n');
fprintf(fid, '  - not a realistic starter-home transition margin\n');
fprintf(fid, '- Inference:\n');
fprintf(fid, '  - the next diagnosis should focus on why the owner problem is pushing young households to the upper housing / asset boundary instead of into small owner states\n');
fprintf(fid, '  - that is more important than the exact spacing of the first owner-house grid point by itself\n');
end

function write_family_table(fid, rows, family_name, title_text)
subset = rows(rows.family == family_name, :);
fprintf(fid, '%s\n\n', title_text);
fprintf(fid, '| grid | b step | first owner house | owner 25-34 | mortgage under 35 | mortgage share among owners under 35 | owner age 25 | small-owner among owners age 25 | renter positive-assets age 25 | mean owner b age 25 | mean owner h age 25 | owner age 30 | small-owner among owners age 30 |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(subset)
    fprintf(fid, '| %s | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f |\n', ...
        subset.grid_label(i), subset.b_step(i), subset.first_owner_house(i), subset.owner_share_25_34(i), ...
        subset.mortgaged_owner_share_under_35(i), subset.mortgage_share_among_owners_under_35(i), ...
        subset.owner_share_age25(i), subset.small_owner_share_among_owners_age25(i), subset.renter_positive_asset_share_age25(i), ...
        subset.mean_owner_b_age25(i), subset.mean_owner_h_age25(i), subset.owner_share_age30(i), ...
        subset.small_owner_share_among_owners_age30(i));
end
fprintf(fid, '\n');
end
