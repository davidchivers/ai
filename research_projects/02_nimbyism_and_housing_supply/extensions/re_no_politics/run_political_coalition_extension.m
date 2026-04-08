function run_political_coalition_extension()
% Entry point for the coalition-weighted NIMBY extension.
% Sets up paths, validates dependencies, then runs the grid search
% to find the coalition-weighted voting equilibrium price.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

fprintf('=== Political Coalition Extension ===\n');
fprintf('Project root: %s\n', project_root);
fprintf('Baseline steady-state code: %s\n', baseline_dir);

% Validate required files
required_files = {
    fullfile(baseline_dir, 'SolveSS_iter.m')
    fullfile(this_dir, 'solve_ss_coalition.m')
    fullfile(this_dir, 'ClearMarkets_coalition.m')
    fullfile(this_dir, 'compute_coalition_vote.m')
};

missing = {};
for i = 1:numel(required_files)
    if ~isfile(required_files{i})
        missing{end+1} = required_files{i}; %#ok<AGROW>
    end
end

if ~isempty(missing)
    fprintf('Missing required files:\n');
    for i = 1:numel(missing)
        fprintf('  - %s\n', missing{i});
    end
    error('Extension failed path validation.');
end

% Add paths (baseline needed for TransitionMatrix.mat and helpers)
addpath(baseline_dir);
addpath(this_dir);

fprintf('\nRunning ClearMarkets_coalition grid search...\n\n');

% Run the grid search driver
ClearMarkets_coalition();

fprintf('\nExtension B complete. Results saved in SS_coalition_iter.mat\n');

end
