function run_transition_anticipation_menu_fertility_main(mode)
% run_transition_anticipation_menu_fertility_main.m
%
% Sweep a menu of anticipated price paths and record how strongly the
% age-25 ownership margin responds at t = 1.

if nargin < 1 || isempty(mode)
    mode = "medium";
end
mode = string(mode);

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
[overrides, cases, note_suffix] = build_mode_config(mode, cfg);

diag_overrides = overrides;
diag_overrides.return_transition_objects = true;
[~, ~, ~, ~, ~, diagnostics] = SolveSS_fertility([cfg.eval_price, cfg.rbPos], diag_overrides);
age_idx = find(diagnostics.ages == 25, 1);
if isempty(age_idx)
    error('Age 25 not found in solver age grid.');
end

flat_case = cases{1};
flat_results = solve_household_path_fertility(flat_case.q_path, overrides, struct('rbPos_path', cfg.rbPos));

rows = table();
z_rows = table();

for i = 1:numel(cases)
    case_info = cases{i};
    fprintf('Running transition anticipation menu case %s (%s)...\n', case_info.name, mode);
    solver_results = solve_household_path_fertility(case_info.q_path, overrides, struct('rbPos_path', cfg.rbPos));
    simulation = forward_distribution_path_fertility(solver_results, [], struct('store_cross_section', true));
    summary = summarize_transition_path_fertility(solver_results, simulation);
    [flip_summary, z_summary] = compute_flip_summary(diagnostics, flat_results, solver_results, age_idx);

    row = struct2table(orderfields(struct( ...
        'mode', mode, ...
        'case_name', string(case_info.name), ...
        'I', overrides.I, ...
        'J', overrides.J, ...
        'q_path_label', string(case_info.label), ...
        'q1', case_info.q_path(1), ...
        'q2', case_info.q_path(2), ...
        'q3', case_info.q_path(3), ...
        'q4', case_info.q_path(4), ...
        'owner_share_25_34_t1', summary.owner_share_25_34(1), ...
        'owner_share_25_34_t2', summary.owner_share_25_34(2), ...
        'owner_share_25_34_t3', summary.owner_share_25_34(3), ...
        'owner_share_25_34_t4', summary.owner_share_25_34(4), ...
        'mortgaged_owner_share_under_35_t1', summary.mortgaged_owner_share_under_35(1), ...
        'mortgaged_owner_share_under_35_t2', summary.mortgaged_owner_share_under_35(2), ...
        'mortgaged_owner_share_under_35_t3', summary.mortgaged_owner_share_under_35(3), ...
        'avg_birth_rate_t1', summary.avg_birth_rate(1), ...
        'avg_birth_rate_t2', summary.avg_birth_rate(2), ...
        'mean_age_first_birth_t1', summary.mean_age_first_birth(1), ...
        'mean_age_first_birth_t2', summary.mean_age_first_birth(2), ...
        'flip_renter_to_owner_mass_share_t1', flip_summary.flip_renter_to_owner_mass_share, ...
        'flip_owner_to_renter_mass_share_t1', flip_summary.flip_owner_to_renter_mass_share, ...
        'flat_owner_mass_share_t1', flip_summary.flat_owner_mass_share, ...
        'case_owner_mass_share_t1', flip_summary.case_owner_mass_share, ...
        'flip_mean_income_t1', flip_summary.flip_mean_income, ...
        'flip_mean_b_t1', flip_summary.flip_mean_b, ...
        'flip_mean_owner_a_t1', flip_summary.flip_mean_owner_a, ...
        'flip_mean_owner_b_t1', flip_summary.flip_mean_owner_b)));
    rows = [rows; row]; %#ok<AGROW>

    z_summary.case_name = repmat(string(case_info.name), height(z_summary), 1);
    z_summary.mode = repmat(mode, height(z_summary), 1);
    z_rows = [z_rows; z_summary]; %#ok<AGROW>
end

summary_path = fullfile(out_dir, sprintf('structural_transition_anticipation_menu_%s_summary.csv', note_suffix));
z_path = fullfile(out_dir, sprintf('structural_transition_anticipation_menu_%s_z_summary.csv', note_suffix));
note_path = fullfile(out_dir, sprintf('structural_transition_anticipation_menu_%s.md', note_suffix));
writetable(rows, summary_path);
writetable(z_rows, z_path);
write_note(note_path, rows, z_rows, mode, overrides.I, overrides.J);
disp('Structural transition anticipation menu complete.');
end

function [overrides, cases, note_suffix] = build_mode_config(mode, cfg)
overrides = cfg.overrides;
switch lower(char(mode))
    case 'medium'
        overrides.I = 30;
        overrides.J = 14;
        note_suffix = 'medium';
        cases = { ...
            struct('name', 'flat_2p0', 'label', '[2.0, 2.0, 2.0, 2.0]', 'q_path', [2.0, 2.0, 2.0, 2.0]), ...
            struct('name', 'step_2p05', 'label', '[2.0, 2.05, 2.05, 2.05]', 'q_path', [2.0, 2.05, 2.05, 2.05]), ...
            struct('name', 'step_2p10', 'label', '[2.0, 2.1, 2.1, 2.1]', 'q_path', [2.0, 2.1, 2.1, 2.1]), ...
            struct('name', 'step_2p15', 'label', '[2.0, 2.15, 2.15, 2.15]', 'q_path', [2.0, 2.15, 2.15, 2.15]), ...
            struct('name', 'delayed_step_2p10', 'label', '[2.0, 2.0, 2.1, 2.1]', 'q_path', [2.0, 2.0, 2.1, 2.1]), ...
            struct('name', 'transitory_step_2p10', 'label', '[2.0, 2.1, 2.0, 2.0]', 'q_path', [2.0, 2.1, 2.0, 2.0])};
    case 'benchmark'
        overrides.I = 60;
        overrides.J = 14;
        note_suffix = 'benchmark';
        cases = { ...
            struct('name', 'flat_2p0', 'label', '[2.0, 2.0, 2.0, 2.0]', 'q_path', [2.0, 2.0, 2.0, 2.0]), ...
            struct('name', 'step_2p05', 'label', '[2.0, 2.05, 2.05, 2.05]', 'q_path', [2.0, 2.05, 2.05, 2.05]), ...
            struct('name', 'step_2p10', 'label', '[2.0, 2.1, 2.1, 2.1]', 'q_path', [2.0, 2.1, 2.1, 2.1]), ...
            struct('name', 'delayed_step_2p10', 'label', '[2.0, 2.0, 2.1, 2.1]', 'q_path', [2.0, 2.0, 2.1, 2.1]), ...
            struct('name', 'transitory_step_2p10', 'label', '[2.0, 2.1, 2.0, 2.0]', 'q_path', [2.0, 2.1, 2.0, 2.0])};
    otherwise
        error('Unknown mode "%s". Use "medium" or "benchmark".', mode);
end
end

function [summary_row, z_rows] = compute_flip_summary(diagnostics, flat_results, case_results, age_idx)
pre_density = diagnostics.density_pre_policy_ages{age_idx};
flat_policy = get_policy_block(flat_results.path_solution, 1, age_idx);
case_policy = get_policy_block(case_results.path_solution, 1, age_idx);

renter_j = 1;
state_rows = table();
for ip = 1:numel(diagnostics.parity_grid)
    for ih = 1:numel(diagnostics.home_grid)
        for iz = 1:numel(diagnostics.z_grid)
            current_income = exp(diagnostics.z_grid(iz)) * diagnostics.z_lifecycle(age_idx);
            for ii = 1:numel(diagnostics.b_grid)
                current_mass = pre_density(ii, renter_j, iz, ih, ip);
                if current_mass <= 0
                    continue;
                end

                flat_a_idx = flat_policy.index_a(ii, renter_j, iz, ih, ip);
                flat_b_idx = flat_policy.index_b(ii, renter_j, iz, ih, ip);
                case_a_idx = case_policy.index_a(ii, renter_j, iz, ih, ip);
                case_b_idx = case_policy.index_b(ii, renter_j, iz, ih, ip);
                flat_owner = double(flat_a_idx > 1);
                case_owner = double(case_a_idx > 1);

                row = struct2table(orderfields(struct( ...
                    'z_index', iz, ...
                    'z_value', diagnostics.z_grid(iz), ...
                    'current_income', current_income, ...
                    'current_b', diagnostics.b_grid(ii), ...
                    'current_mass', current_mass, ...
                    'flat_owner', flat_owner, ...
                    'case_owner', case_owner, ...
                    'flat_a', diagnostics.a_grid(flat_a_idx), ...
                    'flat_b', diagnostics.b_grid(flat_b_idx), ...
                    'case_a', diagnostics.a_grid(case_a_idx), ...
                    'case_b', diagnostics.b_grid(case_b_idx), ...
                    'flip_renter_to_owner', double(flat_owner == 0 && case_owner == 1), ...
                    'flip_owner_to_renter', double(flat_owner == 1 && case_owner == 0))));
                state_rows = [state_rows; row]; %#ok<AGROW>
            end
        end
    end
end

total_mass = sum(state_rows.current_mass);
summary_row = struct();
summary_row.flat_owner_mass_share = sum(state_rows.current_mass .* state_rows.flat_owner) / max(total_mass, 1e-12);
summary_row.case_owner_mass_share = sum(state_rows.current_mass .* state_rows.case_owner) / max(total_mass, 1e-12);
summary_row.flip_renter_to_owner_mass_share = sum(state_rows.current_mass .* state_rows.flip_renter_to_owner) / max(total_mass, 1e-12);
summary_row.flip_owner_to_renter_mass_share = sum(state_rows.current_mass .* state_rows.flip_owner_to_renter) / max(total_mass, 1e-12);
summary_row.flip_mean_income = weighted_mean(state_rows.current_income, state_rows.current_mass .* state_rows.flip_renter_to_owner);
summary_row.flip_mean_b = weighted_mean(state_rows.current_b, state_rows.current_mass .* state_rows.flip_renter_to_owner);
summary_row.flip_mean_owner_a = weighted_mean(state_rows.case_a, state_rows.current_mass .* state_rows.flip_renter_to_owner);
summary_row.flip_mean_owner_b = weighted_mean(state_rows.case_b, state_rows.current_mass .* state_rows.flip_renter_to_owner);

z_rows = table();
for i = unique(state_rows.z_index(:))'
    mask = state_rows.z_index == i;
    row = struct2table(orderfields(struct( ...
        'z_index', i, ...
        'z_value', state_rows.z_value(find(mask, 1)), ...
        'mass_share', sum(state_rows.current_mass(mask)) / max(total_mass, 1e-12), ...
        'flat_owner_mass_share', sum(state_rows.current_mass(mask) .* state_rows.flat_owner(mask)) / max(total_mass, 1e-12), ...
        'case_owner_mass_share', sum(state_rows.current_mass(mask) .* state_rows.case_owner(mask)) / max(total_mass, 1e-12), ...
        'flip_renter_to_owner_mass_share', sum(state_rows.current_mass(mask) .* state_rows.flip_renter_to_owner(mask)) / max(total_mass, 1e-12), ...
        'flip_owner_to_renter_mass_share', sum(state_rows.current_mass(mask) .* state_rows.flip_owner_to_renter(mask)) / max(total_mass, 1e-12))));
    z_rows = [z_rows; row]; %#ok<AGROW>
end
end

function out = weighted_mean(values, weights)
values = values(:);
weights = weights(:);
tw = sum(weights);
if tw <= 0
    out = NaN;
    return;
end
out = sum(values .* weights) / tw;
end

function policy_age = get_policy_block(solution, t, age_pos)
policy_age = struct( ...
    'index_a', solution.index_a{t, age_pos}, ...
    'index_b', solution.index_b{t, age_pos}, ...
    'birth_prob', solution.birth_prob{t, age_pos});
end

function write_note(path, rows, z_rows, mode, I, J)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural transition anticipation menu (%s)\n\n', mode);
fprintf(fid, 'This note sweeps a bounded menu of anticipated price paths and records how strongly the age-25 ownership margin responds at `t = 1`.\n\n');
fprintf(fid, 'Grid:\n\n');
fprintf(fid, '- `I = %d`\n', I);
fprintf(fid, '- `J = %d`\n\n', J);

fprintf(fid, '## Case summary\n\n');
fprintf(fid, '| case | q path | owner t1 | owner t2 | owner t3 | flip renter->owner t1 | mean income of flips | mean owner a of flips |\n');
fprintf(fid, '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(rows)
    fprintf(fid, '| %s | %s | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f |\n', ...
        rows.case_name(i), rows.q_path_label(i), rows.owner_share_25_34_t1(i), ...
        rows.owner_share_25_34_t2(i), rows.owner_share_25_34_t3(i), ...
        rows.flip_renter_to_owner_mass_share_t1(i), rows.flip_mean_income_t1(i), ...
        rows.flip_mean_owner_a_t1(i));
end

fprintf(fid, '\n## Flip mass by income state\n\n');
fprintf(fid, '| case | z index | z value | mass share | flat owner share | case owner share | renter->owner flip share |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(z_rows)
    fprintf(fid, '| %s | %d | %.4f | %.3f | %.3f | %.3f | %.3f |\n', ...
        z_rows.case_name(i), z_rows.z_index(i), z_rows.z_value(i), z_rows.mass_share(i), ...
        z_rows.flat_owner_mass_share(i), z_rows.case_owner_mass_share(i), ...
        z_rows.flip_renter_to_owner_mass_share(i));
end

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- The point of this menu is to separate three possibilities:\n');
fprintf(fid, '  - the surge only appears for large permanent future price increases\n');
fprintf(fid, '  - the surge appears even for small future increases\n');
fprintf(fid, '  - the surge depends on whether the increase starts immediately or only later\n');
fprintf(fid, '- The live diagnostic should focus on:\n');
fprintf(fid, '  - how owner share at `t = 1` moves with the future-price path\n');
fprintf(fid, '  - how much of the age-25 entrant mass flips renter-to-owner at `t = 1`\n');
fprintf(fid, '  - whether the flip mass stays concentrated in the same income states across cases\n');
end
