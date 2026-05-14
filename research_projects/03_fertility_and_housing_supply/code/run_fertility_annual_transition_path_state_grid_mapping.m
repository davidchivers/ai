function run_fertility_annual_transition_path_state_grid_mapping()
% run_fertility_annual_transition_path_state_grid_mapping.m
%
% Phase 2 mapping for the annual transition-path branch. Take the reduced-
% form time-zero bucket shares and place them on the model state grids
% (b, housing, z, age) as an explicit template for a future transition
% solver. This does not yet solve the transition path.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

cfg = fertility_benchmark_annual_config();
spec = fertility_annual_transition_path_branch_spec();
bucket_csv = fullfile(out_dir, 'fertility_annual_transition_path_bucket_mapping.csv');
if ~exist(bucket_csv, 'file')
    error('Missing %s. Run run_fertility_annual_transition_path_bucket_mapping first.', bucket_csv);
end

bucket_table = readtable(bucket_csv, 'TextType', 'string');
[grid_template, mapping_table, summary_table, meta] = build_state_grid_template(cfg, spec, bucket_table);

save(fullfile(out_dir, 'fertility_annual_transition_path_state_grid_mapping.mat'), ...
    'grid_template', 'mapping_table', 'summary_table', 'meta');
writetable(mapping_table, fullfile(out_dir, 'fertility_annual_transition_path_state_grid_mapping.csv'));
writetable(summary_table, fullfile(out_dir, 'fertility_annual_transition_path_state_grid_mapping_summary.csv'));
write_note(fullfile(out_dir, 'fertility_annual_transition_path_state_grid_mapping.md'), spec, summary_table, meta);
end

function [grid_template, mapping_table, summary_table, meta] = build_state_grid_template(cfg, spec, bucket_table)
ages = (cfg.overrides.agemin:cfg.overrides.dage:cfg.overrides.agemax)';
age_n = numel(ages);
I = 24;
J = 8;
b_grid = linspace(-20, 20, I)';
a_grid = linspace(0, 15, J)';

tmppath = cfg.overrides.transition_matrix_file;
tmp = load(tmppath);
if isfield(tmp, 'initialdist') && ~isempty(tmp.initialdist)
    z_weights = tmp.initialdist(:);
else
    z_weights = stationary_dist_local(tmp.transitionmatrix(:, :, 1));
end
z_weights = z_weights ./ max(sum(z_weights), 1e-12);
K = numel(z_weights);

age_block_rows = build_age_block_rows(bucket_table, ages);
block_masses = compute_block_masses(age_block_rows, age_n);

grid_template = zeros(I, J, K, age_n);
mapping_rows = repmat(empty_mapping_row(), 0, 1);
summary_rows = repmat(empty_summary_row(), 0, 1);
row_idx = 0;

for iblock = 1:numel(age_block_rows)
    block = age_block_rows(iblock);
    age_mask = ages >= block.age_lo & ages <= block.age_hi;
    age_idx = find(age_mask);
    if isempty(age_idx)
        continue;
    end

    age_mass_each = block_masses(iblock) / numel(age_idx);
    bucket_shares = [ ...
        block.bucket_renter_no_debt, ...
        block.bucket_renter_with_debt, ...
        block.bucket_owner_with_mortgage, ...
        block.bucket_owner_outright];
    bucket_names = ["renter_no_debt", "renter_with_debt", "owner_with_mortgage", "owner_outright"];

    for ibucket = 1:numel(bucket_names)
        bucket_name = bucket_names(ibucket);
        bucket_share = bucket_shares(ibucket);
        [b_target, h_target, is_renter] = representative_point(block.age_block, bucket_name);
        b_mass = deposit_mass_on_grid(b_grid, b_target);
        h_mass = deposit_mass_on_grid(a_grid, h_target);
        if is_renter
            h_mass = zeros(size(h_mass));
            h_mass(1) = 1.0;
        end

        for ia = 1:numel(age_idx)
            age_pos = age_idx(ia);
            total_mass = age_mass_each * bucket_share;
            if total_mass <= 0
                continue;
            end

            for iz = 1:K
                mass_bh = total_mass * z_weights(iz) * (b_mass * h_mass');
                grid_template(:, :, iz, age_pos) = grid_template(:, :, iz, age_pos) + mass_bh;

                [b_rows, h_rows] = find(mass_bh > 1e-12);
                for ir = 1:numel(b_rows)
                    row_idx = row_idx + 1;
                    mapping_rows(row_idx) = struct( ...
                        'age', ages(age_pos), ...
                        'age_block', block.age_block, ...
                        'bucket', bucket_name, ...
                        'z_index', iz, ...
                        'b_index', b_rows(ir), ...
                        'b_value', b_grid(b_rows(ir)), ...
                        'housing_index', h_rows(ir), ...
                        'housing_value', a_grid(h_rows(ir)), ...
                        'mass', mass_bh(b_rows(ir), h_rows(ir))); %#ok<AGROW>
                end
            end
        end
    end

    summary_rows(iblock) = struct( ...
        'age_block', block.age_block, ...
        'age_lo', block.age_lo, ...
        'age_hi', block.age_hi, ...
        'block_mass', block_masses(iblock), ...
        'renter_no_debt', block.bucket_renter_no_debt, ...
        'renter_with_debt', block.bucket_renter_with_debt, ...
        'owner_with_mortgage', block.bucket_owner_with_mortgage, ...
        'owner_outright', block.bucket_owner_outright); %#ok<AGROW>
end

mapping_table = struct2table(mapping_rows);
summary_table = struct2table(summary_rows);

meta = struct();
meta.age_grid = ages;
meta.b_grid = b_grid;
meta.housing_grid = a_grid;
meta.z_weights = z_weights;
meta.block_masses = block_masses;
meta.grid_shape = size(grid_template);
meta.note = "Reduced-form t=0 template only. Ages 65-80 are assigned the 55-64 bucket pattern by explicit carry-forward rule.";
end

function rows = build_age_block_rows(bucket_table, ages)
rows = repmat(struct( ...
    'age_block', "", ...
    'age_lo', NaN, ...
    'age_hi', NaN, ...
    'bucket_renter_no_debt', NaN, ...
    'bucket_renter_with_debt', NaN, ...
    'bucket_owner_with_mortgage', NaN, ...
    'bucket_owner_outright', NaN), 5, 1);

blocks = ["25-34", "35-44", "45-54", "55-64", "65-80"];
for i = 1:4
    row = bucket_table(i, :);
    [age_lo, age_hi] = parse_block(row.age_block);
    rows(i) = pack_row(row, age_lo, age_hi);
end

rows(5) = rows(4);
rows(5).age_block = blocks(5);
rows(5).age_lo = 65;
rows(5).age_hi = ages(end);
end

function row = pack_row(tblrow, age_lo, age_hi)
row = struct( ...
    'age_block', tblrow.age_block, ...
    'age_lo', age_lo, ...
    'age_hi', age_hi, ...
    'bucket_renter_no_debt', tblrow.bucket_renter_no_debt, ...
    'bucket_renter_with_debt', tblrow.bucket_renter_with_debt, ...
    'bucket_owner_with_mortgage', tblrow.bucket_owner_with_mortgage, ...
    'bucket_owner_outright', tblrow.bucket_owner_outright);
end

function masses = compute_block_masses(rows, age_n)
masses = zeros(numel(rows), 1);
for i = 1:numel(rows)
    masses(i) = (rows(i).age_hi - rows(i).age_lo + 1) / age_n;
end
masses = masses ./ max(sum(masses), 1e-12);
end

function [age_lo, age_hi] = parse_block(label)
parts = split(string(label), "-");
age_lo = str2double(parts(1));
age_hi = str2double(parts(2));
end

function [b_target, h_target, is_renter] = representative_point(age_block, bucket)
age_block = string(age_block);
bucket = string(bucket);
switch age_block
    case "25-34"
        age_idx = 1;
    case "35-44"
        age_idx = 2;
    case "45-54"
        age_idx = 3;
    otherwise
        age_idx = 4;
end

renter_no_debt_b = [0.0, 0.5, 0.8, 1.0];
renter_with_debt_b = [-1.5, -1.0, -0.5, -0.25];
owner_with_mortgage_b = [-4.0, -3.0, -2.0, -1.0];
owner_outright_b = [0.8, 1.8, 2.8, 3.8];
owner_with_mortgage_h = [2.5, 4.0, 5.5, 5.5];
owner_outright_h = [4.0, 6.0, 8.0, 8.0];

switch bucket
    case "renter_no_debt"
        b_target = renter_no_debt_b(age_idx);
        h_target = 0.0;
        is_renter = true;
    case "renter_with_debt"
        b_target = renter_with_debt_b(age_idx);
        h_target = 0.0;
        is_renter = true;
    case "owner_with_mortgage"
        b_target = owner_with_mortgage_b(age_idx);
        h_target = owner_with_mortgage_h(age_idx);
        is_renter = false;
    case "owner_outright"
        b_target = owner_outright_b(age_idx);
        h_target = owner_outright_h(age_idx);
        is_renter = false;
    otherwise
        error('Unknown bucket %s', bucket);
end
end

function mass_vec = deposit_mass_on_grid(grid, target)
mass_vec = zeros(numel(grid), 1);
if target <= grid(1)
    mass_vec(1) = 1.0;
    return;
end
if target >= grid(end)
    mass_vec(end) = 1.0;
    return;
end
upper_idx = find(grid >= target, 1);
lower_idx = upper_idx - 1;
g_lo = grid(lower_idx);
g_hi = grid(upper_idx);
if abs(g_hi - g_lo) < 1e-12
    mass_vec(lower_idx) = 1.0;
    return;
end
upper_weight = (target - g_lo) / (g_hi - g_lo);
lower_weight = 1.0 - upper_weight;
mass_vec(lower_idx) = lower_weight;
mass_vec(upper_idx) = upper_weight;
end

function row = empty_mapping_row()
row = struct( ...
    'age', NaN, ...
    'age_block', "", ...
    'bucket', "", ...
    'z_index', NaN, ...
    'b_index', NaN, ...
    'b_value', NaN, ...
    'housing_index', NaN, ...
    'housing_value', NaN, ...
    'mass', NaN);
end

function row = empty_summary_row()
row = struct( ...
    'age_block', "", ...
    'age_lo', NaN, ...
    'age_hi', NaN, ...
    'block_mass', NaN, ...
    'renter_no_debt', NaN, ...
    'renter_with_debt', NaN, ...
    'owner_with_mortgage', NaN, ...
    'owner_outright', NaN);
end

function stat = stationary_dist_local(z_transition)
[V, D] = eig(z_transition');
[~, idx] = min(abs(diag(D) - 1));
stat = real(V(:, idx));
stat = stat ./ sum(stat);
stat = stat(:);
end

function write_note(note_path, spec, summary_table, meta)
fid = fopen(note_path, 'w');
if fid == -1
    error('Could not open %s for writing.', note_path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Annual transition-path state-grid mapping\n\n');
fprintf(fid, 'This is Phase 2 of the annual transition-path branch. It takes the reduced-form time-zero bucket shares and places them on the model state grids `(b, housing, z, age)` as a template for a future transition solver.\n\n');
fprintf(fid, '## Grid\n\n');
fprintf(fid, '- `I = %d`\n', meta.grid_shape(1));
fprintf(fid, '- `J = %d`\n', meta.grid_shape(2));
fprintf(fid, '- `K = %d`\n', meta.grid_shape(3));
fprintf(fid, '- ages covered: `%d-%d`\n', meta.age_grid(1), meta.age_grid(end));
fprintf(fid, '- note: `%s`\n\n', meta.note);

fprintf(fid, '## Mapping choices\n\n');
fprintf(fid, '- renters are placed on housing index `1`\n');
fprintf(fid, '- owner-with-mortgage and owner-outright buckets are placed on positive housing points using age-specific representative housing targets\n');
fprintf(fid, '- income-state weights use the annual transition matrix initial distribution\n');
fprintf(fid, '- block masses are proportional to the number of ages in each block\n\n');

fprintf(fid, '## Age-block summary\n\n');
fprintf(fid, '| Age block | Block mass | Renter no debt | Renter with debt | Owner with mortgage | Owner outright |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|\n');
for i = 1:height(summary_table)
    fprintf(fid, '| %s | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` |\n', ...
        char(summary_table.age_block(i)), summary_table.block_mass(i), summary_table.renter_no_debt(i), ...
        summary_table.renter_with_debt(i), summary_table.owner_with_mortgage(i), summary_table.owner_outright(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Next coding step\n\n');
fprintf(fid, 'Use this template to replace the stationary initial density at `t = 0` only. After that, the life-cycle law of motion should remain endogenous.\n');
fprintf(fid, 'Spec source: `%s`\n', char(spec.branch_name));
end
