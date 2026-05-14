function run_fertility_annual_transition_path_prep()
% run_fertility_annual_transition_path_prep.m
%
% Write the concrete age-cross-section target pack for the annual
% transition-path branch. This is a preparation step, not a full
% transition solve.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

spec = fertility_annual_transition_path_branch_spec();
baseline = load_current_baseline(out_dir);
target_table = build_transition_target_table(spec, baseline);

writetable(target_table, fullfile(out_dir, 'fertility_annual_transition_path_targets.csv'));
write_note(fullfile(out_dir, 'fertility_annual_transition_path_prep.md'), spec, baseline, target_table);
end

function baseline = load_current_baseline(out_dir)
baseline = struct( ...
    'available', false, ...
    'label', "anchor no-mix baseline", ...
    'eval_owner_share_25_34', NaN, ...
    'eval_owner_share_35_44', NaN, ...
    'eval_owner_share_45_54', NaN, ...
    'eval_debt_holder_share_under_35', NaN, ...
    'eval_debt_holder_share_35_44', NaN, ...
    'eval_mortgaged_owner_share_under_35', NaN, ...
    'eval_mortgaged_owner_share_35_44', NaN, ...
    'eval_mortgaged_owner_share_45_54', NaN, ...
    'eval_mortgaged_owner_share_55_64', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'crossing_refined_price', NaN, ...
    'crossing_is_unique', NaN);

csv_path = fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen_candidates.csv');
if ~exist(csv_path, 'file')
    return;
end

tbl = readtable(csv_path, 'TextType', 'string');
idx = find(tbl.label == "anchor no-mix baseline", 1);
if isempty(idx)
    return;
end

baseline.available = true;
baseline.label = tbl.label(idx);
baseline.eval_owner_share_25_34 = tbl.eval_owner_share_25_34(idx);
baseline.eval_owner_share_35_44 = tbl.eval_owner_share_35_44(idx);
baseline.eval_owner_share_45_54 = tbl.eval_owner_share_45_54(idx);
baseline.eval_debt_holder_share_under_35 = tbl.eval_debt_holder_share_under_35(idx);
baseline.eval_debt_holder_share_35_44 = tbl.eval_debt_holder_share_35_44(idx);
baseline.eval_mortgaged_owner_share_under_35 = tbl.eval_mortgaged_owner_share_under_35(idx);
baseline.eval_mortgaged_owner_share_35_44 = tbl.eval_mortgaged_owner_share_35_44(idx);
baseline.eval_mortgaged_owner_share_45_54 = tbl.eval_mortgaged_owner_share_45_54(idx);
baseline.eval_mortgaged_owner_share_55_64 = tbl.eval_mortgaged_owner_share_55_64(idx);
baseline.eval_vote_per_mass = tbl.eval_vote_per_mass(idx);
baseline.crossing_refined_price = tbl.crossing_refined_price(idx);
baseline.crossing_is_unique = tbl.crossing_is_unique(idx);
end

function tbl = build_transition_target_table(spec, baseline)
rows = repmat(empty_row(), 0, 1);
idx = 0;

home_targets = spec.time_zero_targets.homeownership;
all_home = [home_targets.support(:); home_targets.validation(:)];
for i = 1:numel(all_home)
    idx = idx + 1;
    rows(idx) = make_row_from_target(all_home(i), baseline);
end

wealth_targets = spec.time_zero_targets.wealth;
all_wealth = [wealth_targets.support(:); wealth_targets.validation(:)];
for i = 1:numel(all_wealth)
    idx = idx + 1;
    rows(idx) = make_row_from_target(all_wealth(i), baseline);
end

tbl = struct2table(rows);
end

function row = empty_row()
row = struct( ...
    'object', "", ...
    'role', "", ...
    'source', "", ...
    'reference', NaN, ...
    'lower', NaN, ...
    'upper', NaN, ...
    'current_no_mix_baseline', NaN, ...
    'gap_to_reference', NaN);
end

function row = make_row_from_target(target, baseline)
row = empty_row();
row.object = string(target.name);
row.role = string(target.role);
row.source = string(target.source);
row.reference = target.reference;
row.lower = target.lower;
row.upper = target.upper;
row.current_no_mix_baseline = baseline_value_for_object(baseline, target.name);
row.gap_to_reference = row.current_no_mix_baseline - row.reference;
end

function value = baseline_value_for_object(baseline, name)
switch char(string(name))
    case 'owner_share_25_34'
        value = baseline.eval_owner_share_25_34;
    case 'owner_share_35_44'
        value = baseline.eval_owner_share_35_44;
    case 'owner_share_45_54'
        value = baseline.eval_owner_share_45_54;
    case 'debt_holder_share_under_35'
        value = baseline.eval_debt_holder_share_under_35;
    case 'debt_holder_share_35_44'
        value = baseline.eval_debt_holder_share_35_44;
    case 'mortgaged_owner_share_under_35'
        value = baseline.eval_mortgaged_owner_share_under_35;
    case 'mortgaged_owner_share_35_44'
        value = baseline.eval_mortgaged_owner_share_35_44;
    case 'mortgaged_owner_share_45_54'
        value = baseline.eval_mortgaged_owner_share_45_54;
    case 'mortgaged_owner_share_55_64'
        value = baseline.eval_mortgaged_owner_share_55_64;
    otherwise
        value = NaN;
end
end

function write_note(note_path, spec, baseline, target_table)
fid = fopen(note_path, 'w');
if fid == -1
    error('Could not open %s for writing.', note_path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Annual transition-path prep\n\n');
fprintf(fid, 'This is the concrete scaffold for the annual transition-path branch. It does not run a full transition solver yet. It writes the time-zero age-cross-section targets and the implementation sequence needed for that branch.\n\n');

fprintf(fid, '## Objective\n\n');
fprintf(fid, '- `%s`\n\n', char(spec.objective));

fprintf(fid, '## Starting point\n\n');
fprintf(fid, '- steady-state source note: `%s`\n', char(spec.starting_point.source_note));
fprintf(fid, '- steady-state source csv: `%s`\n', char(spec.starting_point.source_csv));
fprintf(fid, '- current working point label: `%s`\n', char(spec.starting_point.label));
if baseline.available
    fprintf(fid, '- current no-mix baseline read:\n');
    fprintf(fid, '  - owner share `25-34`: `%.3f`\n', baseline.eval_owner_share_25_34);
    fprintf(fid, '  - owner share `35-44`: `%.3f`\n', baseline.eval_owner_share_35_44);
    fprintf(fid, '  - debt-holder share under `35`: `%.3f`\n', baseline.eval_debt_holder_share_under_35);
    fprintf(fid, '  - mortgaged-owner share under `35`: `%.3f`\n', baseline.eval_mortgaged_owner_share_under_35);
    fprintf(fid, '  - vote per mass at eval price: `%.3f`\n', baseline.eval_vote_per_mass);
    if baseline.crossing_is_unique == 1
        fprintf(fid, '  - unique crossing: `%.6f`\n', baseline.crossing_refined_price);
    end
else
    fprintf(fid, '- current no-mix baseline read: `not available yet`\n');
end
fprintf(fid, '\n');

fprintf(fid, '## Time-zero age blocks\n\n');
for i = 1:numel(spec.time_zero_age_blocks)
    fprintf(fid, '- `%s`\n', char(spec.time_zero_age_blocks(i)));
end
fprintf(fid, '\n');

fprintf(fid, '## Time-zero state buckets\n\n');
for i = 1:numel(spec.time_zero_buckets)
    fprintf(fid, '- `%s`\n', char(spec.time_zero_buckets(i)));
end
fprintf(fid, '\n');

fprintf(fid, '## Required objects\n\n');
for i = 1:numel(spec.required_objects)
    fprintf(fid, '- %s\n', char(spec.required_objects(i)));
end
fprintf(fid, '\n');

fprintf(fid, '## Implementation phases\n\n');
for i = 1:numel(spec.implementation_phases)
    fprintf(fid, '%d. %s\n', i, char(spec.implementation_phases(i)));
end
fprintf(fid, '\n');

fprintf(fid, '## Transition-path targets\n\n');
fprintf(fid, '| Object | Role | Reference | Lower | Upper | Current no-mix | Gap |\n');
fprintf(fid, '|---|---|---:|---:|---:|---:|---:|\n');
for i = 1:height(target_table)
    fprintf(fid, '| %s | %s | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` |\n', ...
        char(target_table.object(i)), char(target_table.role(i)), target_table.reference(i), ...
        target_table.lower(i), target_table.upper(i), target_table.current_no_mix_baseline(i), ...
        target_table.gap_to_reference(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Stop rules\n\n');
for i = 1:numel(spec.stop_rules)
    fprintf(fid, '- %s\n', char(spec.stop_rules(i)));
end
fprintf(fid, '\n');

fprintf(fid, '## Template links\n\n');
fprintf(fid, '- steady-state anchor template: `%s`\n', char(spec.templates.steady_state_anchor));
fprintf(fid, '- current transition bridge: `%s`\n', char(spec.templates.current_transition_bridge));
fprintf(fid, '- homeownership targets: `%s`\n', char(spec.templates.homeownership_targets));
fprintf(fid, '- wealth targets: `%s`\n', char(spec.templates.wealth_targets));
end
