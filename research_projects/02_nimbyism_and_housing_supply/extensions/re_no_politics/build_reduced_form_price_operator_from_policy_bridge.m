function operator = build_reduced_form_price_operator_from_policy_bridge(project_root, benchmark_results_path)
% Fit a smooth reduced-form price operator on the stable fixed-price
% policy-bridge benchmark. The operator maps demographic pressure and the
% next-period price gap into the current log price.

if nargin < 1 || isempty(project_root)
    this_file = mfilename('fullpath');
    this_dir = fileparts(this_file);
    project_root = fileparts(fileparts(this_dir));
else
    this_dir = fullfile(project_root, 'extensions', 're_no_politics');
end

if nargin < 2 || isempty(benchmark_results_path)
    benchmark_results_path = fullfile(this_dir, ...
        'transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.mat');
end

demographic_path = build_demographic_path_from_age_state_csv(project_root);
[pressure_index, young_share_25_44] = compute_demographic_pressure_index(demographic_path);

baseline_price = 2.0;
tail_price = baseline_price;
[benchmark_price_path, benchmark_source] = load_benchmark_price_path(benchmark_results_path, demographic_path);

log_baseline_price = log(baseline_price);
next_price_gap = [log(benchmark_price_path(2:end)); log(tail_price)] - log_baseline_price;

X = [ones(numel(pressure_index), 1), pressure_index(:), next_price_gap(:)];
y = log(benchmark_price_path(:));
raw_coeffs = X \ y;

bounded_next_price_coeff = min(max(raw_coeffs(3), 0.0), 0.95);
bounded_coeffs = raw_coeffs;
bounded_coeffs(3) = bounded_next_price_coeff;

raw_fit = X * raw_coeffs;
bounded_fit = X * bounded_coeffs;

operator = struct();
operator.operator_name = 'young_share_plus_next_price_gap';
operator.benchmark_source = benchmark_source;
operator.benchmark_results_path = benchmark_results_path;
operator.baseline_price = baseline_price;
operator.tail_price = tail_price;
operator.log_baseline_price = log_baseline_price;
operator.intercept = bounded_coeffs(1);
operator.pressure_coeff = bounded_coeffs(2);
operator.next_price_coeff = bounded_coeffs(3);
operator.raw_intercept = raw_coeffs(1);
operator.raw_pressure_coeff = raw_coeffs(2);
operator.raw_next_price_coeff = raw_coeffs(3);
operator.pressure_index_name = 'young_share_25_44_gap_from_2010';
operator.pressure_index = pressure_index(:);
operator.young_share_25_44 = young_share_25_44(:);
operator.benchmark_price_path = benchmark_price_path(:);
operator.raw_fit_rmse = sqrt(mean((y - raw_fit).^2));
operator.bounded_fit_rmse = sqrt(mean((y - bounded_fit).^2));
operator.periods = demographic_path.periods(:);
operator.years = demographic_path.years(:);
operator.description = [ ...
    'Reduced-form log-price operator fitted on the stable fixed-price policy-bridge ', ...
    'path using the young-share demographic pressure index and the next-period ', ...
    'log price gap relative to the 2.0 benchmark tail.'];
end

function [pressure_index, young_share_25_44] = compute_demographic_pressure_index(demographic_path)
population_by_age = demographic_path.population_by_age;
total_population = sum(population_by_age, 2);
young_share_25_44 = sum(population_by_age(:, 1:4), 2) ./ total_population;
pressure_index = young_share_25_44 - young_share_25_44(1);
end

function [benchmark_price_path, benchmark_source] = load_benchmark_price_path(benchmark_results_path, demographic_path)
T_full = numel(demographic_path.periods);

if ~isfile(benchmark_results_path)
    error('Benchmark reduced-form source not found: %s', benchmark_results_path);
end

loaded = load(benchmark_results_path, 'all_results', 'summary');
if isfield(loaded, 'all_results') && ~isempty(loaded.all_results) && ...
        numel(loaded.all_results) >= T_full && ~isempty(loaded.all_results{T_full}) && ...
        isfield(loaded.all_results{T_full}, 'final_price_path')
    benchmark_price_path = loaded.all_results{T_full}.final_price_path(:);
    benchmark_source = 'transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.all_results{T}.final_price_path';
    return;
end

error('Could not load the stable fixed-price benchmark path from %s.', benchmark_results_path);
end
