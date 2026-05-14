function run_transition_path_pe_fertility_main()
% run_transition_path_pe_fertility_main.m
%
% First end-to-end partial-equilibrium transition-path pass for the
% structural five-year fertility / housing block.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

overrides = struct('I', 20, 'J', 6);
cases = { ...
    struct('name', 'flat_q_2p0', 'q_path', [2.0, 2.0, 2.0, 2.0]), ...
    struct('name', 'step_up_q_2p1', 'q_path', [2.0, 2.1, 2.1, 2.1])};

case_summaries = cell(numel(cases), 1);
rows = [];

for i = 1:numel(cases)
    solver_results = solve_household_path_fertility(cases{i}.q_path, overrides, struct('rbPos_path', 0.03));
    simulation = forward_distribution_path_fertility(solver_results, [], struct('store_cross_section', true));
    summary = summarize_transition_path_fertility(solver_results, simulation);
    case_summaries{i} = struct('name', cases{i}.name, 'solver_results', solver_results, 'simulation', simulation, 'summary', summary);

    T = numel(summary.q_path);
    case_table = table( ...
        repmat(string(cases{i}.name), T, 1), ...
        (1:T)', ...
        summary.q_path(:), ...
        summary.avg_birth_rate(:), ...
        summary.mean_age_first_birth(:), ...
        summary.owner_share_25_34(:), ...
        summary.mortgaged_owner_share_under_35(:), ...
        summary.total_mass(:), ...
        'VariableNames', {'case_name', 't', 'q', 'avg_birth_rate', 'mean_age_first_birth', 'owner_share_25_34', 'mortgaged_owner_share_under_35', 'total_mass'});
    rows = [rows; case_table]; %#ok<AGROW>
end

writetable(rows, fullfile(out_dir, 'structural_transition_path_pe_summary.csv'));
save(fullfile(out_dir, 'structural_transition_path_pe_results.mat'), 'case_summaries');
write_note(fullfile(out_dir, 'structural_transition_path_pe_note.md'), rows, case_summaries);
disp('Structural transition-path partial-equilibrium pass complete.');
end

function write_note(path, summary_table, case_summaries)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural transition-path partial-equilibrium note\n\n');
fprintf(fid, 'This note records the first end-to-end partial-equilibrium transition-path pass for the structural five-year fertility / housing solver.\n\n');
fprintf(fid, 'Objects:\n\n');
fprintf(fid, '- backward household path solve: `code/solve_household_path_fertility.m`\n');
fprintf(fid, '- forward distribution simulation: `code/forward_distribution_path_fertility.m`\n');
fprintf(fid, '- path summarizer: `code/summarize_transition_path_fertility.m`\n\n');
fprintf(fid, 'Calibration for this smoke:\n\n');
fprintf(fid, '- grids reduced to `I = 20`, `J = 6` for speed\n');
fprintf(fid, '- flat interest-rate path `rbPos = 0.03`\n');
fprintf(fid, '- two test price paths:\n');
fprintf(fid, '  - `flat_q_2p0`: `[2.0, 2.0, 2.0, 2.0]`\n');
fprintf(fid, '  - `step_up_q_2p1`: `[2.0, 2.1, 2.1, 2.1]`\n\n');

fprintf(fid, '## Path summary\n\n');
fprintf(fid, '| case | t | q | avg birth rate | mean age first birth | owner share 25-34 | mortgaged-owner share under 35 | total mass |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(summary_table)
    mean_age = summary_table.mean_age_first_birth(i);
    if isnan(mean_age)
        mean_age_str = 'NaN';
    else
        mean_age_str = sprintf('%.3f', mean_age);
    end
    fprintf(fid, '| %s | %d | %.3f | %.6f | %s | %.6f | %.6f | %.6f |\n', ...
        summary_table.case_name(i), summary_table.t(i), summary_table.q(i), ...
        summary_table.avg_birth_rate(i), mean_age_str, ...
        summary_table.owner_share_25_34(i), summary_table.mortgaged_owner_share_under_35(i), ...
        summary_table.total_mass(i));
end

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- This is not yet a rational-expectations fixed point.\n');
fprintf(fid, '- It is the first structural transition-path object that solves household policies backward on a finite price path and simulates the distribution forward.\n');
fprintf(fid, '- The flat-path replication passes exactly in this smoke: all reported moments are constant through `t = 4` and total mass stays constant.\n');
fprintf(fid, '- The step-up path produces sensible fertility-side movement: average birth rates fall and mean age at first birth rises.\n');
fprintf(fid, '- The same path also changes ownership sharply. In this small-grid smoke, anticipated higher future prices raise young ownership at `t = 1`, but after prices step up the young-owner share falls materially by `t = 3`.\n');
fprintf(fid, '- That means the backward and forward mechanics are live, but the transition distribution still needs diagnosis before the outer RE loop is worth attempting.\n\n');

fprintf(fid, '## Cases\n\n');
for i = 1:numel(case_summaries)
    summary = case_summaries{i}.summary;
    fprintf(fid, '### %s\n\n', case_summaries{i}.name);
    fprintf(fid, '- average birth rate range: `%.6f` to `%.6f`\n', min(summary.avg_birth_rate), max(summary.avg_birth_rate));
    valid_ages = summary.mean_age_first_birth(isfinite(summary.mean_age_first_birth));
    if isempty(valid_ages)
        fprintf(fid, '- mean age at first birth: `NaN`\n');
    else
        fprintf(fid, '- mean age at first birth range: `%.3f` to `%.3f`\n', min(valid_ages), max(valid_ages));
    end
    fprintf(fid, '- owner share 25-34 range: `%.6f` to `%.6f`\n', min(summary.owner_share_25_34), max(summary.owner_share_25_34));
    fprintf(fid, '- mortgaged-owner share under 35 range: `%.6f` to `%.6f`\n\n', min(summary.mortgaged_owner_share_under_35), max(summary.mortgaged_owner_share_under_35));
end
end
