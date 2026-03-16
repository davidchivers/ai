function results = run_demographic_forecast_re_no_politics()
% Entry point for the transition-path RE no-coalition forecast scaffold.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

fprintf('=== Transition RE No-Coalition Forecast Scaffold ===\n');
fprintf('Project root: %s\n', project_root);
fprintf('Baseline steady-state code: %s\n', baseline_dir);

required_files = {
    fullfile(this_dir, 'build_demographic_path_from_age_state_csv.m')
    fullfile(this_dir, 'load_transition_matrix_data.m')
    fullfile(this_dir, 'solve_transition_re_no_politics.m')
    fullfile(this_dir, 'update_price_path_re_no_politics.m')
    fullfile(baseline_dir, 'ensure_external_matlab_data_paths.m')
};

missing = {};
for i = 1:numel(required_files)
    if ~isfile(required_files{i})
        missing{end + 1} = required_files{i}; %#ok<AGROW>
    end
end

if ~isempty(missing)
    fprintf('Missing required files:\n');
    for i = 1:numel(missing)
        fprintf('  - %s\n', missing{i});
    end
    error('Transition RE scaffold failed path validation.');
end

addpath(baseline_dir);
addpath(this_dir);

demographic_path = build_demographic_path_from_age_state_csv(project_root);

params = struct();
params.max_iter = 25;
params.tol = 1e-4;
params.damping = 0.25;
params.terminal_price_rule = 'flat_tail';

price_path_guess = 2.0 .* ones(numel(demographic_path.periods), 1);

fprintf('\nRunning solve_transition_re_no_politics scaffold...\n\n');

results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);
save transition_re_no_politics_scaffold results

fprintf('Scaffold status: %s\n', results.message);
fprintf('Transition matrix source: %s\n', results.transition_matrix_path);
fprintf('Demographic source: %s\n', demographic_path.source_path);
fprintf('Placeholder results saved in transition_re_no_politics_scaffold.mat\n');
end
