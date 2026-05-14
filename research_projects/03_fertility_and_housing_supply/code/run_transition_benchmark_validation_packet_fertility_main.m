function run_transition_benchmark_validation_packet_fertility_main(section, case_indices)
% run_transition_benchmark_validation_packet_fertility_main.m
%
% Benchmark-only validation packet for the structural transition-path
% Bellman object:
%   1. smoother permanent price paths on the benchmark grid
%   2. a small owner-carry sensitivity block around the benchmark grid
%   3. report-only note refresh from the saved CSVs when section is
%      "report" or "report_only"

if nargin < 1 || isempty(section)
    section = "all";
end
section = string(section);
report_only = any(section == ["report", "report_only"]);

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
base_overrides = cfg.overrides;
base_overrides.I = 60;
base_overrides.J = 14;

flat_q = [2.0, 2.0, 2.0, 2.0];
step_q = [2.0, 2.1, 2.1, 2.1];

path_cases = { ...
    struct('name', 'flat_2p0', 'label', '[2.0, 2.0, 2.0, 2.0]', 'q_path', flat_q), ...
    struct('name', 'step_2p10', 'label', '[2.0, 2.1, 2.1, 2.1]', 'q_path', step_q), ...
    struct('name', 'smooth_front_loaded', 'label', '[2.0, 2.05, 2.08, 2.10]', 'q_path', [2.0, 2.05, 2.08, 2.10]), ...
    struct('name', 'smooth_even_ramp', 'label', '[2.0, 2.03, 2.06, 2.10]', 'q_path', [2.0, 2.03, 2.06, 2.10]), ...
    struct('name', 'smooth_back_loaded', 'label', '[2.0, 2.02, 2.05, 2.10]', 'q_path', [2.0, 2.02, 2.05, 2.10])};

sensitivity_cases = { ...
    struct('name', 'base_step_2p10', 'label', 'default geometry', 'q_path', step_q, 'param_overrides', struct()), ...
    struct('name', 'higher_transaction_cost', 'label', 'ka = 0.08', 'q_path', step_q, 'param_overrides', struct('ka', 0.08)), ...
    struct('name', 'higher_owner_spread', 'label', 'owner mortgage spread = 0.03', 'q_path', step_q, 'param_overrides', struct('owner_mortgage_spread', 0.03)), ...
    struct('name', 'positive_amortization', 'label', 'owner mortgage amortization = 0.02', 'q_path', step_q, 'param_overrides', struct('owner_mortgage_amortization', 0.02))};

if nargin < 2 || isempty(case_indices)
    case_indices = [];
end
case_indices = case_indices(:)';

path_csv = fullfile(out_dir, 'structural_transition_benchmark_validation_paths.csv');
sensitivity_csv = fullfile(out_dir, 'structural_transition_benchmark_validation_sensitivities.csv');
note_path = fullfile(out_dir, 'structural_transition_benchmark_validation.md');

if section == "all" || section == "paths"
    fprintf('Running benchmark smoother-path validation block...\n');
    if isempty(case_indices)
        selected_path_cases = path_cases;
    else
        selected_path_cases = path_cases(case_indices);
    end
    path_rows_new = run_path_block(cfg, base_overrides, selected_path_cases);
    if isfile(path_csv)
        existing_path_rows = readtable(path_csv);
        path_rows = [existing_path_rows; path_rows_new]; %#ok<AGROW>
        [~, keep_idx] = unique(string(path_rows.case_name), 'last');
        path_rows = path_rows(sort(keep_idx), :);
    else
        path_rows = path_rows_new;
    end
    writetable(path_rows, path_csv);
elseif isfile(path_csv)
    path_rows = readtable(path_csv);
else
    path_rows = table();
end

if section == "all" || section == "sensitivity"
    fprintf('Running benchmark owner-carry sensitivity block...\n');
    if isempty(case_indices)
        selected_cases = sensitivity_cases;
    else
        selected_cases = sensitivity_cases(case_indices);
    end
    new_sensitivity_rows = run_sensitivity_block(cfg, base_overrides, flat_q, selected_cases);
    if isfile(sensitivity_csv)
        existing_sensitivity_rows = readtable(sensitivity_csv);
        sensitivity_rows = [existing_sensitivity_rows; new_sensitivity_rows]; %#ok<AGROW>
        [~, keep_idx] = unique(string(sensitivity_rows.case_name), 'last');
        sensitivity_rows = sensitivity_rows(sort(keep_idx), :);
    else
        sensitivity_rows = new_sensitivity_rows;
    end
    writetable(sensitivity_rows, sensitivity_csv);
elseif isfile(sensitivity_csv)
    sensitivity_rows = readtable(sensitivity_csv);
else
    sensitivity_rows = table();
end

write_note(note_path, path_rows, sensitivity_rows);

if report_only
    fprintf('Refreshed benchmark validation note from existing CSVs only.\n');
end
disp('Structural transition benchmark validation packet complete.');
end

function rows = run_path_block(cfg, base_overrides, cases)
fprintf('  Path block: building benchmark diagnostics...\n');
drawnow;
[diagnostics, age_idx] = solve_diagnostics_case(cfg, base_overrides);
fprintf('  Path block: solving benchmark flat reference path...\n');
drawnow;
flat_results = solve_household_path_fertility(cases{1}.q_path, base_overrides, struct('rbPos_path', cfg.rbPos, 'verbose_progress', true));
flat_simulation = forward_distribution_path_fertility(flat_results, [], struct('store_cross_section', true));
flat_summary = summarize_transition_path_fertility(flat_results, flat_simulation);

rows = table();
for i = 1:numel(cases)
    case_info = cases{i};
    if i == 1
        fprintf('  Path case %s: reusing benchmark flat reference path...\n', case_info.name);
        drawnow;
        solver_results = flat_results;
        summary = flat_summary;
        z_summary = table( ...
            unique(diagnostics.z_grid(:)), unique(diagnostics.z_grid(:)), zeros(numel(unique(diagnostics.z_grid(:))), 1), ...
            'VariableNames', {'z_index', 'z_value', 'flip_renter_to_owner_mass_share'});
        z_summary.z_index = (1:height(z_summary))';
        flip_summary = struct( ...
            'flip_renter_to_owner_mass_share', 0.0, ...
            'flip_owner_to_renter_mass_share', 0.0, ...
            'flip_mean_income', NaN, ...
            'flip_mean_b', NaN, ...
            'flip_mean_owner_a', NaN, ...
            'flip_mean_owner_b', NaN);
    else
        fprintf('  Path case %s: solving household path...\n', case_info.name);
        drawnow;
        solver_results = solve_household_path_fertility(case_info.q_path, base_overrides, struct('rbPos_path', cfg.rbPos, 'verbose_progress', true));
        fprintf('  Path case %s: simulating forward...\n', case_info.name);
        drawnow;
        simulation = forward_distribution_path_fertility(solver_results, [], struct('store_cross_section', true));
        fprintf('  Path case %s: summarizing and auditing flips...\n', case_info.name);
        drawnow;
        summary = summarize_transition_path_fertility(solver_results, simulation);
        [flip_summary, z_summary] = compute_flip_summary_local(diagnostics, flat_results, solver_results, age_idx);
    end

    row = struct2table(orderfields(struct( ...
        'block', "smoother_paths", ...
        'case_name', string(case_info.name), ...
        'label', string(case_info.label), ...
        'I', base_overrides.I, ...
        'J', base_overrides.J, ...
        'q1', case_info.q_path(1), ...
        'q2', case_info.q_path(2), ...
        'q3', case_info.q_path(3), ...
        'q4', case_info.q_path(4), ...
        'owner_share_25_34_t1', summary.owner_share_25_34(1), ...
        'owner_share_25_34_t2', summary.owner_share_25_34(2), ...
        'owner_share_25_34_t3', summary.owner_share_25_34(3), ...
        'mortgaged_owner_share_under_35_t1', summary.mortgaged_owner_share_under_35(1), ...
        'avg_birth_rate_t1', summary.avg_birth_rate(1), ...
        'mean_age_first_birth_t1', summary.mean_age_first_birth(1), ...
        'flip_renter_to_owner_mass_share_t1', flip_summary.flip_renter_to_owner_mass_share, ...
        'flip_owner_to_renter_mass_share_t1', flip_summary.flip_owner_to_renter_mass_share, ...
        'flip_mean_income_t1', flip_summary.flip_mean_income, ...
        'flip_mean_b_t1', flip_summary.flip_mean_b, ...
        'flip_mean_owner_a_t1', flip_summary.flip_mean_owner_a, ...
        'flip_mean_owner_b_t1', flip_summary.flip_mean_owner_b, ...
        'flip_z_states', format_flip_z_states(z_summary))));
    rows = [rows; row]; %#ok<AGROW>
end
end

function rows = run_sensitivity_block(cfg, base_overrides, flat_q, cases)
rows = table();
for i = 1:numel(cases)
    case_info = cases{i};
    case_overrides = merge_structs_local(base_overrides, case_info.param_overrides);
    fprintf('  Sensitivity case %s: building diagnostics...\n', case_info.name);
    drawnow;
    [diagnostics, age_idx] = solve_diagnostics_case(cfg, case_overrides);

    fprintf('  Sensitivity case %s: solving flat reference path...\n', case_info.name);
    drawnow;
    flat_results = solve_household_path_fertility(flat_q, case_overrides, struct('rbPos_path', cfg.rbPos, 'verbose_progress', true));
    fprintf('  Sensitivity case %s: solving step path...\n', case_info.name);
    drawnow;
    step_results = solve_household_path_fertility(case_info.q_path, case_overrides, struct('rbPos_path', cfg.rbPos, 'verbose_progress', true));
    fprintf('  Sensitivity case %s: simulating and auditing...\n', case_info.name);
    drawnow;
    simulation = forward_distribution_path_fertility(step_results, [], struct('store_cross_section', true));
    summary = summarize_transition_path_fertility(step_results, simulation);
    [flip_summary, z_summary] = compute_flip_summary_local(diagnostics, flat_results, step_results, age_idx);

    row = struct2table(orderfields(struct( ...
        'block', "owner_carry_sensitivity", ...
        'case_name', string(case_info.name), ...
        'label', string(case_info.label), ...
        'I', case_overrides.I, ...
        'J', case_overrides.J, ...
        'ka', get_override_value_local(case_overrides, 'ka'), ...
        'owner_mortgage_spread', get_override_value_local(case_overrides, 'owner_mortgage_spread'), ...
        'owner_mortgage_amortization', get_override_value_local(case_overrides, 'owner_mortgage_amortization'), ...
        'owner_share_25_34_t1', summary.owner_share_25_34(1), ...
        'owner_share_25_34_t2', summary.owner_share_25_34(2), ...
        'owner_share_25_34_t3', summary.owner_share_25_34(3), ...
        'mortgaged_owner_share_under_35_t1', summary.mortgaged_owner_share_under_35(1), ...
        'avg_birth_rate_t1', summary.avg_birth_rate(1), ...
        'mean_age_first_birth_t1', summary.mean_age_first_birth(1), ...
        'flip_renter_to_owner_mass_share_t1', flip_summary.flip_renter_to_owner_mass_share, ...
        'flip_owner_to_renter_mass_share_t1', flip_summary.flip_owner_to_renter_mass_share, ...
        'flip_mean_income_t1', flip_summary.flip_mean_income, ...
        'flip_mean_b_t1', flip_summary.flip_mean_b, ...
        'flip_mean_owner_a_t1', flip_summary.flip_mean_owner_a, ...
        'flip_mean_owner_b_t1', flip_summary.flip_mean_owner_b, ...
        'flip_z_states', format_flip_z_states(z_summary))));
    rows = [rows; row]; %#ok<AGROW>
end
end

function [diagnostics, age_idx] = solve_diagnostics_case(cfg, overrides)
diag_overrides = overrides;
diag_overrides.return_transition_objects = true;
[~, ~, ~, ~, ~, diagnostics] = SolveSS_fertility([cfg.eval_price, cfg.rbPos], diag_overrides);
age_idx = find(diagnostics.ages == 25, 1);
if isempty(age_idx)
    error('Age 25 not found in diagnostics age grid.');
end
end

function [summary_row, z_rows] = compute_flip_summary_local(diagnostics, flat_results, case_results, age_idx)
pre_density = diagnostics.density_pre_policy_ages{age_idx};
flat_policy = get_policy_block_local(flat_results.path_solution, 1, age_idx);
case_policy = get_policy_block_local(case_results.path_solution, 1, age_idx);

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
summary_row.flip_renter_to_owner_mass_share = sum(state_rows.current_mass .* state_rows.flip_renter_to_owner) / max(total_mass, 1e-12);
summary_row.flip_owner_to_renter_mass_share = sum(state_rows.current_mass .* state_rows.flip_owner_to_renter) / max(total_mass, 1e-12);
summary_row.flip_mean_income = weighted_mean_local(state_rows.current_income, state_rows.current_mass .* state_rows.flip_renter_to_owner);
summary_row.flip_mean_b = weighted_mean_local(state_rows.current_b, state_rows.current_mass .* state_rows.flip_renter_to_owner);
summary_row.flip_mean_owner_a = weighted_mean_local(state_rows.case_a, state_rows.current_mass .* state_rows.flip_renter_to_owner);
summary_row.flip_mean_owner_b = weighted_mean_local(state_rows.case_b, state_rows.current_mass .* state_rows.flip_renter_to_owner);

z_rows = table();
for i = unique(state_rows.z_index(:))'
    mask = state_rows.z_index == i;
    row = struct2table(orderfields(struct( ...
        'z_index', i, ...
        'z_value', state_rows.z_value(find(mask, 1)), ...
        'flip_renter_to_owner_mass_share', sum(state_rows.current_mass(mask) .* state_rows.flip_renter_to_owner(mask)) / max(total_mass, 1e-12))));
    z_rows = [z_rows; row]; %#ok<AGROW>
end
end

function label = format_flip_z_states(z_rows)
flip_mask = z_rows.flip_renter_to_owner_mass_share > 1e-8;
if ~any(flip_mask)
    label = "none";
    return;
end
parts = strings(sum(flip_mask), 1);
flip_rows = z_rows(flip_mask, :);
for i = 1:height(flip_rows)
    parts(i) = sprintf('z%d:%.3f', flip_rows.z_index(i), flip_rows.flip_renter_to_owner_mass_share(i));
end
label = strjoin(parts, ', ');
end

function policy_age = get_policy_block_local(solution, t, age_pos)
policy_age = struct( ...
    'index_a', solution.index_a{t, age_pos}, ...
    'index_b', solution.index_b{t, age_pos}, ...
    'birth_prob', solution.birth_prob{t, age_pos});
end

function out = weighted_mean_local(values, weights)
values = values(:);
weights = weights(:);
total_weight = sum(weights);
if total_weight <= 0
    out = NaN;
    return;
end
out = sum(values .* weights) / total_weight;
end

function merged = merge_structs_local(base_struct, override_struct)
merged = base_struct;
fields = fieldnames(override_struct);
for i = 1:numel(fields)
    merged.(fields{i}) = override_struct.(fields{i});
end
end

function out = get_override_value_local(overrides, field_name)
if isfield(overrides, field_name)
    out = overrides.(field_name);
else
    out = NaN;
end
end

function write_note(path, path_rows, sensitivity_rows)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural transition benchmark validation\n\n');
fprintf(fid, 'This note runs the benchmark-only decision gate before any outer RE wrapper. It checks smoother permanent price paths on the benchmark grid, then a small owner-carry sensitivity block around the benchmark step path.\n\n');

fprintf(fid, '## Smoother permanent paths\n\n');
if isempty(path_rows)
    fprintf(fid, '_Path block not yet written._\n');
else
    fprintf(fid, '| case | path | owner t1 | owner t2 | owner t3 | flip mass t1 | flip z states |\n');
    fprintf(fid, '| --- | --- | ---: | ---: | ---: | ---: | --- |\n');
    for i = 1:height(path_rows)
        fprintf(fid, '| %s | %s | %.3f | %.3f | %.3f | %.3f | %s |\n', ...
            scalar_text_local(path_rows.case_name(i)), scalar_text_local(path_rows.label(i)), path_rows.owner_share_25_34_t1(i), ...
            path_rows.owner_share_25_34_t2(i), path_rows.owner_share_25_34_t3(i), ...
            path_rows.flip_renter_to_owner_mass_share_t1(i), scalar_text_local(path_rows.flip_z_states(i)));
    end
end

fprintf(fid, '\n## Owner-carry sensitivity around the benchmark step path\n\n');
if isempty(sensitivity_rows)
    fprintf(fid, '_Sensitivity block not yet written._\n');
else
    fprintf(fid, '| case | geometry change | owner t1 | owner t2 | owner t3 | flip mass t1 | flip z states |\n');
    fprintf(fid, '| --- | --- | ---: | ---: | ---: | ---: | --- |\n');
    for i = 1:height(sensitivity_rows)
        fprintf(fid, '| %s | %s | %.3f | %.3f | %.3f | %.3f | %s |\n', ...
            scalar_text_local(sensitivity_rows.case_name(i)), scalar_text_local(sensitivity_rows.label(i)), sensitivity_rows.owner_share_25_34_t1(i), ...
            sensitivity_rows.owner_share_25_34_t2(i), sensitivity_rows.owner_share_25_34_t3(i), ...
            sensitivity_rows.flip_renter_to_owner_mass_share_t1(i), scalar_text_local(sensitivity_rows.flip_z_states(i)));
    end
end

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- The decision gate is simple:\n');
fprintf(fid, '  - if smoother permanent paths and modest owner-carry changes leave the benchmark-grid flip pattern concentrated and economically interpretable, the next step is the first outer RE wrapper\n');
fprintf(fid, '  - if the pattern disappears or explodes under these small changes, the transition geometry should be softened before any outer RE solve\n');
end

function out = scalar_text_local(value)
if iscell(value)
    value = value{1};
end
out = char(string(value));
end
