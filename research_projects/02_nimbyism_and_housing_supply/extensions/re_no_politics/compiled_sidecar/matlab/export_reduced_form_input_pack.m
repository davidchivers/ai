function pack = export_reduced_form_input_pack(output_dir, k, params, initial_guess, project_root, benchmark_results_path)
% Export a reduced-form NIMBY RE input pack plus MATLAB truth outputs.

if nargin < 1 || isempty(output_dir)
    this_dir = fileparts(mfilename('fullpath'));
    output_dir = fullfile(fileparts(this_dir), 'truth', 'reduced_form_one_step');
end
if nargin < 2 || isempty(k)
    k = 1;
end
if nargin < 3 || isempty(params)
    params = struct();
end
if nargin < 4
    initial_guess = [];
end
if nargin < 5 || isempty(project_root)
    this_dir = fileparts(mfilename('fullpath'));
    sidecar_dir = fileparts(this_dir);
    extension_dir = fileparts(sidecar_dir);
    project_root = fileparts(fileparts(extension_dir));
end
if nargin < 6
    benchmark_results_path = [];
end

this_dir = fileparts(mfilename('fullpath'));
sidecar_dir = fileparts(this_dir);
extension_dir = fileparts(sidecar_dir);

addpath(extension_dir);

operator = build_reduced_form_price_operator_from_policy_bridge(project_root, benchmark_results_path);
params = fill_default_params_local(params, operator);

T_full = numel(operator.periods);
max_horizon = T_full - params.start_index + 1;
k = min(k, max_horizon);
initial_guess = extend_guess_local(initial_guess, params.tail_price, k);
results = solve_reduced_form_price_path(operator, k, params, initial_guess);

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

operator_path_table = table( ...
    operator.periods(:), ...
    operator.years(:), ...
    operator.pressure_index(:), ...
    operator.young_share_25_44(:), ...
    operator.benchmark_price_path(:), ...
    'VariableNames', {'period', 'year', 'pressure_index', 'young_share_25_44', 'benchmark_price'});
writetable(operator_path_table, fullfile(output_dir, 'operator_path.csv'));

operator_scalars = {
    'intercept', operator.intercept;
    'pressure_coeff', operator.pressure_coeff;
    'next_price_coeff', operator.next_price_coeff;
    'baseline_price', operator.baseline_price;
    'tail_price', operator.tail_price;
    'log_baseline_price', operator.log_baseline_price;
    'raw_intercept', operator.raw_intercept;
    'raw_pressure_coeff', operator.raw_pressure_coeff;
    'raw_next_price_coeff', operator.raw_next_price_coeff;
    'raw_fit_rmse', operator.raw_fit_rmse;
    'bounded_fit_rmse', operator.bounded_fit_rmse};
writetable(cell2table(operator_scalars, 'VariableNames', {'name', 'value'}), ...
    fullfile(output_dir, 'operator_scalars.csv'));

params_scalars = {
    'k', k;
    'start_index', params.start_index;
    'max_iter', params.max_iter;
    'tol', params.tol;
    'relaxation_weight', params.relaxation_weight;
    're_weight', params.re_weight;
    'price_min', params.price_min;
    'price_max', params.price_max;
    'tail_price', params.tail_price};
writetable(cell2table(params_scalars, 'VariableNames', {'name', 'value'}), ...
    fullfile(output_dir, 'params_scalars.csv'));

writetable(table(initial_guess(:), 'VariableNames', {'initial_guess'}), ...
    fullfile(output_dir, 'initial_guess.csv'));

matlab_solution_table = table( ...
    results.periods(:), ...
    results.years(:), ...
    results.pressure_index(:), ...
    results.young_share_25_44(:), ...
    results.final_price_path(:), ...
    results.implied_price_path(:), ...
    results.implied_price_path_unbounded(:), ...
    results.next_price_reference(:), ...
    'VariableNames', {'period', 'year', 'pressure_index', 'young_share_25_44', ...
    'final_price', 'implied_price', 'implied_price_unbounded', 'next_price_reference'});
writetable(matlab_solution_table, fullfile(output_dir, 'matlab_solution_path.csv'));

matlab_summary = {
    'status', string(results.status);
    'converged', string(results.converged);
    'iterations_completed', string(results.iterations_completed);
    'k', string(results.k);
    'start_index', string(results.start_index);
    're_weight', string(results.re_weight);
    'relaxation_weight', string(results.relaxation_weight);
    'price_min', string(results.price_min);
    'price_max', string(results.price_max);
    'tail_price', string(results.tail_price);
    'max_abs_gap', string(results.max_abs_gap);
    'max_abs_log_gap', string(results.max_abs_log_gap);
    'path_span', string(results.path_span);
    'hits_bound', string(results.hits_bound);
    'looks_stable', string(results.looks_stable)};
writetable(cell2table(matlab_summary, 'VariableNames', {'name', 'value'}), ...
    fullfile(output_dir, 'matlab_summary.csv'));

iteration_log_table = struct2table(results.iteration_log);
writetable(iteration_log_table, fullfile(output_dir, 'matlab_iteration_log.csv'));

save(fullfile(output_dir, 'matlab_truth.mat'), 'operator', 'params', 'initial_guess', 'results');

pack = struct();
pack.output_dir = output_dir;
pack.operator = operator;
pack.params = params;
pack.initial_guess = initial_guess;
pack.results = results;
end

function params = fill_default_params_local(params, operator)
defaults = struct();
defaults.max_iter = 100;
defaults.tol = 1e-8;
defaults.relaxation_weight = 0.50;
defaults.re_weight = 1.0;
defaults.price_min = 1.75;
defaults.price_max = 2.25;
defaults.tail_price = operator.tail_price;
defaults.start_index = 1;

default_names = fieldnames(defaults);
for i = 1:numel(default_names)
    name = default_names{i};
    if ~isfield(params, name) || isempty(params.(name))
        params.(name) = defaults.(name);
    end
end
end

function guess = extend_guess_local(initial_guess, tail_price, k)
if isempty(initial_guess)
    guess = tail_price .* ones(k, 1);
    return;
end

guess = initial_guess(:);
if numel(guess) >= k
    guess = guess(1:k);
else
    guess = [guess; tail_price .* ones(k - numel(guess), 1)];
end
end
