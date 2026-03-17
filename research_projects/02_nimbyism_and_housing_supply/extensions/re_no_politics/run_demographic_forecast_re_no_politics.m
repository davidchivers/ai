function results = run_demographic_forecast_re_no_politics()
% Entry point for the transition-path RE no-coalition forecast experiment.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');

fprintf('=== Transition RE No-Coalition Forecast ===\n');
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
params.max_iter = 1;
params.tol = 1e-4;
params.damping = 0.25;
params.max_update_frac = 0.10;
params.smoothing_weight = 5.00;
params.terminal_anchor_weight = 0.50;
params.targeted_correction_weight = 0.35;
params.max_targeted_periods = 3;
params.target_block_half_width = 1;
params.line_search_scales = [0.10, 0.05, 0.02, 0.01];
params.update_scheme = 'sequential_blocks';
params.sequential_block_size = 3;
params.block_sweep_passes = 2;
params.terminal_price_rule = 'flat_tail';

price_path_guess = 2.0 .* ones(numel(demographic_path.periods), 1);

fprintf('\nRunning solve_transition_re_no_politics...\n\n');

results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);
save transition_re_no_politics_results results

fprintf('Run status: %s\n', results.message);
fprintf('Transition matrix source: %s\n', results.transition_matrix_path);
fprintf('Demographic source: %s\n', demographic_path.source_path);
fprintf('Supply anchor: Hbar = %.6f, Pbar = %.4f, eta_s = %.2f\n', ...
    results.params.supply_params.Hbar, results.params.supply_params.Pbar, results.params.supply_params.eta_s);
fprintf('Max abs RE price gap after update: %.4f\n', results.update_diagnostics.max_abs_gap);
fprintf('Max abs smoothed RE price gap: %.4f\n', results.update_diagnostics.max_abs_smoothed_gap);
[~, worst_t] = max(abs(results.period_diagnostics.excess_demand_guess_path));
fprintf('Worst excess-demand period: t = %d, excess demand = %.6f\n', ...
    worst_t, results.period_diagnostics.excess_demand_guess_path(worst_t));
fprintf('Targeted correction periods: %s\n', mat2str(results.period_diagnostics.targeted_periods(:)'));
fprintf('Targeted correction blocks: %s\n', mat2str(results.period_diagnostics.targeted_blocks));
fprintf('Results saved in transition_re_no_politics_results.mat\n');
end
