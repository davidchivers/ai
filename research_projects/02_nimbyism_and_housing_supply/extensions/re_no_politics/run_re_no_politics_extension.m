function run_re_no_politics_extension()
% Entry point for the no-politics rational-expectations extension.
% Sets up paths, validates dependencies, then runs the grid search
% to find the market-clearing steady-state price.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

fprintf('=== RE No-Politics Extension ===\n');
fprintf('Project root: %s\n', project_root);
fprintf('Baseline steady-state code: %s\n', baseline_dir);

% Validate required files
required_files = {
    fullfile(baseline_dir, 'SolveSS_iter.m')
    fullfile(this_dir, 'solve_ss_no_politics.m')
    fullfile(this_dir, 'ClearMarkets_no_politics.m')
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

fprintf('\nRunning ClearMarkets_no_politics grid search...\n\n');

% Run the grid search driver
ClearMarkets_no_politics();

fprintf('\nExtension A complete. Results saved in SS_no_politics_iter.mat\n');

end
