function run_fertility_annual_transition_path_bucket_mapping()
% run_fertility_annual_transition_path_bucket_mapping.m
%
% Phase 1 mapping for the annual transition-path branch. Convert the
% observed age-block targets into reduced-form time-zero state buckets:
% renter without debt, renter with debt, owner with mortgage, owner
% outright.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

spec = fertility_annual_transition_path_branch_spec();
bucket_table = build_bucket_table(spec);

writetable(bucket_table, fullfile(out_dir, 'fertility_annual_transition_path_bucket_mapping.csv'));
write_note(fullfile(out_dir, 'fertility_annual_transition_path_bucket_mapping.md'), spec, bucket_table);
end

function tbl = build_bucket_table(spec)
home_ranges = spec.time_zero_targets.homeownership;
wealth_ranges = spec.time_zero_targets.wealth;

owner_25_34 = find_target_value([home_ranges.support(:); home_ranges.validation(:)], "owner_share_25_34");
owner_35_44 = find_target_value([home_ranges.support(:); home_ranges.validation(:)], "owner_share_35_44");
owner_45_54 = find_target_value([home_ranges.support(:); home_ranges.validation(:)], "owner_share_45_54");
owner_55_64 = find_target_value([home_ranges.support(:); home_ranges.validation(:)], "owner_share_55_64");

debt_u35 = find_target_value([wealth_ranges.support(:); wealth_ranges.validation(:)], "debt_holder_share_under_35");
debt_35_44 = find_target_value([wealth_ranges.support(:); wealth_ranges.validation(:)], "debt_holder_share_35_44");

mort_u35 = find_target_value([wealth_ranges.support(:); wealth_ranges.validation(:)], "mortgaged_owner_share_under_35");
mort_35_44 = find_target_value([wealth_ranges.support(:); wealth_ranges.validation(:)], "mortgaged_owner_share_35_44");
mort_45_54 = find_target_value([wealth_ranges.support(:); wealth_ranges.validation(:)], "mortgaged_owner_share_45_54");
mort_55_64 = find_target_value([wealth_ranges.support(:); wealth_ranges.validation(:)], "mortgaged_owner_share_55_64");

rows = [ ...
    map_age_block("25-34", owner_25_34, debt_u35, mort_u35, "data-backed"), ...
    map_age_block("35-44", owner_35_44, debt_35_44, mort_35_44, "data-backed"), ...
    map_age_block("45-54", owner_45_54, mort_45_54, mort_45_54, "inference: no separate debt-holder target, so renter_with_debt is set to zero"), ...
    map_age_block("55-64", owner_55_64, mort_55_64, mort_55_64, "inference: no separate debt-holder target, so renter_with_debt is set to zero")];

tbl = struct2table(rows);
end

function row = map_age_block(age_block, owner_share, debt_holder_share, mortgaged_owner_share, assumption)
owner_with_mortgage = mortgaged_owner_share;
owner_outright = max(owner_share - owner_with_mortgage, 0);
renter_with_debt = max(debt_holder_share - mortgaged_owner_share, 0);
renter_no_debt = max(1.0 - owner_with_mortgage - owner_outright - renter_with_debt, 0);

mass_sum = owner_with_mortgage + owner_outright + renter_with_debt + renter_no_debt;
if abs(mass_sum - 1.0) > 1e-10
    renter_no_debt = renter_no_debt + (1.0 - mass_sum);
end

row = struct( ...
    'age_block', string(age_block), ...
    'owner_share_target', owner_share, ...
    'debt_holder_share_target', debt_holder_share, ...
    'mortgaged_owner_share_target', mortgaged_owner_share, ...
    'bucket_owner_with_mortgage', owner_with_mortgage, ...
    'bucket_owner_outright', owner_outright, ...
    'bucket_renter_with_debt', renter_with_debt, ...
    'bucket_renter_no_debt', renter_no_debt, ...
    'bucket_sum', owner_with_mortgage + owner_outright + renter_with_debt + renter_no_debt, ...
    'assumption', string(assumption));
end

function value = find_target_value(targets, name)
idx = find(strcmp(string({targets.name}), string(name)), 1);
if isempty(idx)
    value = NaN;
else
    value = targets(idx).reference;
end
end

function write_note(note_path, spec, bucket_table)
fid = fopen(note_path, 'w');
if fid == -1
    error('Could not open %s for writing.', note_path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Annual transition-path bucket mapping\n\n');
fprintf(fid, 'This is Phase 1 of the annual transition-path branch. It maps the age-block targets into a reduced-form time-zero cross section over four buckets: renter without debt, renter with debt, owner with mortgage, and owner outright.\n\n');

fprintf(fid, '## Mapping rule\n\n');
fprintf(fid, '- `owner_with_mortgage = mortgaged_owner_share`\n');
fprintf(fid, '- `owner_outright = owner_share - mortgaged_owner_share`\n');
fprintf(fid, '- `renter_with_debt = debt_holder_share - mortgaged_owner_share`\n');
fprintf(fid, '- `renter_no_debt = 1 - owner_with_mortgage - owner_outright - renter_with_debt`\n\n');

fprintf(fid, '## Important inference rule\n\n');
fprintf(fid, '- For `45-54` and `55-64`, there is no separate debt-holder target in the current target pack.\n');
fprintf(fid, '- In those blocks, the mapping sets `renter_with_debt = 0` and treats all observed debt participation as mortgage debt. That is an inference, not direct evidence.\n\n');

fprintf(fid, '## Time-zero bucket table\n\n');
fprintf(fid, '| Age block | Owner target | Debt target | Mortgage-owner target | Owner+mortgage | Owner outright | Renter+debt | Renter no debt | Assumption |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|---|\n');
for i = 1:height(bucket_table)
    fprintf(fid, '| %s | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | %s |\n', ...
        char(bucket_table.age_block(i)), ...
        bucket_table.owner_share_target(i), ...
        bucket_table.debt_holder_share_target(i), ...
        bucket_table.mortgaged_owner_share_target(i), ...
        bucket_table.bucket_owner_with_mortgage(i), ...
        bucket_table.bucket_owner_outright(i), ...
        bucket_table.bucket_renter_with_debt(i), ...
        bucket_table.bucket_renter_no_debt(i), ...
        char(bucket_table.assumption(i)));
end
fprintf(fid, '\n');

fprintf(fid, '## Next implementation step\n\n');
fprintf(fid, 'The next transition-path coding step is to map these four bucket shares into the actual model state grids at `t = 0`, replacing the stationary initial density only at the initial date.\n');
fprintf(fid, 'The steady-state law of motion after `t = 0` should remain endogenous.\n');
fprintf(fid, '\n');
fprintf(fid, 'Spec source: `%s`\n', char(spec.branch_name));
end
