function [summary, results] = run_original_5yr_political_permit_passthrough_smoke( ...
    max_k, phi_grid, rho_grid, run_tag, price_clear_max_iter, outer_iter, ...
    vote_scale, policy_relaxation, wedge_floor, wedge_cap, seed_price_csv_path, ...
    demographic_source_mode, political_response_sigma)
% Diagnostic political pass-through smoke.
%
% This treats the political residual as pressure, not as a clearing condition.
% A smoothed vote residual moves the permit/supply wedge only partially:
%
%   pressure_t = tanh(vote_t / vote_scale)
%   wedge_t    = rho * wedge_{t-1} - phi * pressure_t
%
% A positive vote residual is interpreted as pressure for higher prices, so it
% lowers the supply/permit wedge. Prices then clear the housing market given
% that policy path.

if nargin < 1 || isempty(max_k), max_k = 4; end
if nargin < 2 || isempty(phi_grid), phi_grid = [0.00, 0.025, 0.05, 0.10, 0.20]; end
if nargin < 3 || isempty(rho_grid), rho_grid = [0.00, 0.70]; end
if nargin < 4 || isempty(run_tag)
    run_tag = sprintf('local_phi_pass_k%d_%s', max_k, char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')));
end
if nargin < 5 || isempty(price_clear_max_iter), price_clear_max_iter = 2; end
if nargin < 6 || isempty(outer_iter), outer_iter = 2; end
if nargin < 7 || isempty(vote_scale), vote_scale = 0.02; end
if nargin < 8 || isempty(policy_relaxation), policy_relaxation = 0.75; end
if nargin < 9 || isempty(wedge_floor), wedge_floor = -0.35; end
if nargin < 10 || isempty(wedge_cap), wedge_cap = 0.20; end
if nargin < 11 || isempty(seed_price_csv_path), seed_price_csv_path = ''; end
if nargin < 12 || isempty(demographic_source_mode), demographic_source_mode = 'historical_1950'; end
if nargin < 13 || isempty(political_response_sigma), political_response_sigma = 0.20; end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(this_dir);
addpath(this_dir, '-begin');
addpath(fullfile(project_root, 'extensions', 're_no_politics'), '-begin');
addpath(fullfile(project_root, 'code', 'steadystate'), '-begin');

truth_root = fullfile(this_dir, 'truth', 'political_permit_passthrough');
output_dir = fullfile(truth_root, run_tag);
if ~exist(output_dir, 'dir'), mkdir(output_dir); end
status_path = fullfile(truth_root, 'latest_status.json');
trace_log_path = fullfile(output_dir, sprintf('%s_trace.log', run_tag));
write_status_local(status_path, "running", "Starting political permit pass-through smoke.", run_tag, output_dir);

demographic_path_full = build_demographic_path_local(project_root, demographic_source_mode);
max_k = min(max(2, round(max_k)), numel(demographic_path_full.periods));
demographic_path = truncate_demographic_path_local(demographic_path_full, max_k);

if isempty(seed_price_csv_path)
    candidate_seed = fullfile(this_dir, 'truth', 'joint_supply_wedge', ...
        'local_corrected_s020_flat_k4_10_i1', 'local_corrected_s020_flat_k4_10_i1_final_price_path.csv');
    if isfile(candidate_seed)
        seed_price_csv_path = candidate_seed;
    else
        seed_price_csv_path = fullfile(this_dir, 'original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv');
    end
end
seed_price_path = build_price_guess_local(seed_price_csv_path, max_k);

phi_grid = phi_grid(:);
rho_grid = rho_grid(:);
case_count = numel(phi_grid) .* numel(rho_grid);
summary_rows = repmat(empty_summary_row_local(), case_count, 1);
results = repmat(struct( ...
    'phi', NaN, ...
    'rho', NaN, ...
    'final_price_path', [], ...
    'final_wedge_path', [], ...
    'final_vote_path', [], ...
    'final_pressure_path', [], ...
    'iteration_log', []), case_count, 1);

row_idx = 0;
try
    for phi_idx = 1:numel(phi_grid)
        phi = phi_grid(phi_idx);
        for rho_idx = 1:numel(rho_grid)
            rho = rho_grid(rho_idx);
            row_idx = row_idx + 1;
            case_tag = sprintf('%s_phi%03d_rho%03d', run_tag, round(1000 .* phi), round(1000 .* rho));
            fprintf('Political permit pass-through smoke: phi=%.6g rho=%.6g\n', phi, rho);
            write_status_local(status_path, "running", sprintf('Running phi=%.6g rho=%.6g.', phi, rho), run_tag, output_dir);

            [case_summary, case_result] = run_case_local( ...
                seed_price_path, zeros(max_k, 1), demographic_path, phi, rho, ...
                price_clear_max_iter, outer_iter, vote_scale, policy_relaxation, ...
                wedge_floor, wedge_cap, political_response_sigma, trace_log_path, case_tag);

            summary_rows(row_idx) = case_summary;
            results(row_idx).phi = phi;
            results(row_idx).rho = rho;
            results(row_idx).final_price_path = case_result.final_price_path(:);
            results(row_idx).final_wedge_path = case_result.final_wedge_path(:);
            results(row_idx).final_vote_path = case_result.final_vote_path(:);
            results(row_idx).final_pressure_path = case_result.final_pressure_path(:);
            results(row_idx).iteration_log = case_result.iteration_log;

            writematrix(case_result.final_price_path(:), fullfile(output_dir, sprintf('%s_final_price_path.csv', case_tag)));
            writematrix(case_result.final_wedge_path(:), fullfile(output_dir, sprintf('%s_final_wedge_path.csv', case_tag)));
            writematrix(case_result.final_vote_path(:), fullfile(output_dir, sprintf('%s_final_vote_path.csv', case_tag)));
            writematrix(case_result.final_pressure_path(:), fullfile(output_dir, sprintf('%s_final_pressure_path.csv', case_tag)));
        end
    end

    summary = struct2table(summary_rows);
    writetable(summary, fullfile(output_dir, sprintf('%s_summary.csv', run_tag)));
    save(fullfile(output_dir, sprintf('%s_results.mat', run_tag)), 'summary', 'results', ...
        'max_k', 'phi_grid', 'rho_grid', 'vote_scale', 'policy_relaxation', ...
        'wedge_floor', 'wedge_cap', 'political_response_sigma', 'demographic_source_mode');
    write_status_local(status_path, "finished", "Finished political permit pass-through smoke.", run_tag, output_dir);
catch err
    write_status_local(status_path, "failed", err.message, run_tag, output_dir);
    rethrow(err);
end
end

function [summary_row, case_result] = run_case_local(seed_price_path, seed_wedge_path, demographic_path, phi, rho, ...
    price_clear_max_iter, outer_iter, vote_scale, policy_relaxation, wedge_floor, wedge_cap, political_response_sigma, ...
    trace_log_path, case_tag)
price_path = seed_price_path(:);
wedge_path = seed_wedge_path(:);
iteration_log = repmat(struct( ...
    'iteration', NaN, ...
    'max_abs_vote', NaN, ...
    'vote_l2', NaN, ...
    'max_abs_gap', NaN, ...
    'residual_norm', NaN, ...
    'min_wedge', NaN, ...
    'max_wedge', NaN, ...
    'max_abs_pressure', NaN), outer_iter + 1, 1);

last_pressure_path = zeros(size(price_path));
for iter = 1:outer_iter
    solve_results = evaluate_policy_path_local(price_path, wedge_path, demographic_path, price_clear_max_iter, ...
        political_response_sigma, trace_log_path, sprintf('%s_iter%02d', case_tag, iter));
    vote_path = solve_results.political.equal_weight_vote_path(:);
    pressure_path = tanh(vote_path ./ vote_scale);
    target_wedge_path = build_wedge_policy_local(pressure_path, phi, rho, wedge_floor, wedge_cap);
    next_wedge_path = clamp_path_local((1 - policy_relaxation) .* wedge_path + policy_relaxation .* target_wedge_path, ...
        wedge_floor, wedge_cap);

    iteration_log(iter) = build_iteration_row_local(iter, solve_results, wedge_path, pressure_path);
    price_path = solve_results.final_price_path(:);
    wedge_path = next_wedge_path(:);
    last_pressure_path = pressure_path(:);
end

final_results = evaluate_policy_path_local(price_path, wedge_path, demographic_path, price_clear_max_iter, ...
    political_response_sigma, trace_log_path, sprintf('%s_final', case_tag));
final_vote_path = final_results.political.equal_weight_vote_path(:);
final_pressure_path = tanh(final_vote_path ./ vote_scale);
iteration_log(outer_iter + 1) = build_iteration_row_local(outer_iter + 1, final_results, wedge_path, final_pressure_path);

gap_path = extract_gap_path_local(final_results);
summary_row = empty_summary_row_local();
summary_row.phi = phi;
summary_row.rho = rho;
summary_row.max_abs_vote = max(abs(final_vote_path));
summary_row.vote_l2 = norm(final_vote_path, 2);
summary_row.max_abs_gap = max(abs(gap_path));
summary_row.residual_norm = final_results.iteration_log(final_results.iterations).residual_norm;
summary_row.price_first = final_results.final_price_path(1);
summary_row.price_last = final_results.final_price_path(end);
summary_row.price_min = min(final_results.final_price_path);
summary_row.price_max = max(final_results.final_price_path);
summary_row.wedge_min = min(wedge_path);
summary_row.wedge_max = max(wedge_path);
summary_row.max_abs_pressure = max(abs(final_pressure_path));
summary_row.outer_iter = outer_iter;
summary_row.price_clear_max_iter = price_clear_max_iter;

case_result = struct();
case_result.final_price_path = final_results.final_price_path(:);
case_result.final_wedge_path = wedge_path(:);
case_result.final_vote_path = final_vote_path(:);
case_result.final_pressure_path = final_pressure_path(:);
case_result.last_outer_pressure_path = last_pressure_path(:);
case_result.iteration_log = iteration_log;
end

function solve_results = evaluate_policy_path_local(price_path, wedge_path, demographic_path, price_clear_max_iter, ...
    political_response_sigma, trace_log_path, trace_label)
params = default_passthrough_inner_params_local(price_clear_max_iter);
params.supply_wedge_path = wedge_path(:);
params.supply_wedge_space = 'log';
params.political_response_mode = 'smooth_tanh';
params.political_response_sigma = political_response_sigma;
params.trace_log_path = trace_log_path;
params.trace_label = trace_label;
solve_results = solve_transition_re_no_politics(price_path(:), demographic_path, params);
end

function params = default_passthrough_inner_params_local(price_clear_max_iter)
params = struct();
params.max_iter = price_clear_max_iter;
params.tol = 1e-4;
params.damping = 0.25;
params.max_update_frac = 0.10;
params.smoothing_weight = 5.00;
params.terminal_anchor_weight = 0.50;
params.targeted_correction_weight = 0.35;
params.max_targeted_periods = 3;
params.target_block_half_width = 1;
params.line_search_scales = [0.01, 0.02, 0.05];
params.update_scheme = 'sequential_blocks';
params.outer_iteration_mode = 'fertility_style';
params.fixed_point_relaxation_weight = 0.35;
params.fixed_point_relaxation_space = 'log';
params.transition_policy_mode = 'full_backward';
params.terminal_price_rule = 'flat_tail';
params.terminal_reference_mode = 'path_end_price';
params.compute_political_path = true;
params.save_political_details = false;
params.save_period_details = false;
params.save_current_path_pass = false;
params.fixed_point_price_min = 0.05;
params.fixed_point_price_max = 5.00;
params.steady_state_reference_mode = 'original_5yr_political';
params.coalition_params = struct( ...
    'alpha_owner', 0.0, ...
    'alpha_old_owner', 0.0, ...
    'alpha_leverage', 0.0, ...
    'alpha_bighouse', 0.0);
end

function wedge_path = build_wedge_policy_local(pressure_path, phi, rho, wedge_floor, wedge_cap)
pressure_path = pressure_path(:);
wedge_path = zeros(size(pressure_path));
for t = 1:numel(pressure_path)
    if t == 1
        lagged_wedge = 0.0;
    else
        lagged_wedge = wedge_path(t - 1);
    end
    wedge_path(t) = rho .* lagged_wedge - phi .* pressure_path(t);
end
wedge_path = clamp_path_local(wedge_path, wedge_floor, wedge_cap);
end

function row = build_iteration_row_local(iter, solve_results, wedge_path, pressure_path)
vote_path = solve_results.political.equal_weight_vote_path(:);
gap_path = extract_gap_path_local(solve_results);
row = struct();
row.iteration = iter;
row.max_abs_vote = max(abs(vote_path));
row.vote_l2 = norm(vote_path, 2);
row.max_abs_gap = max(abs(gap_path));
row.residual_norm = solve_results.iteration_log(solve_results.iterations).residual_norm;
row.min_wedge = min(wedge_path);
row.max_wedge = max(wedge_path);
row.max_abs_pressure = max(abs(pressure_path));
end

function row = empty_summary_row_local()
row = struct( ...
    'phi', NaN, ...
    'rho', NaN, ...
    'max_abs_vote', NaN, ...
    'vote_l2', NaN, ...
    'max_abs_gap', NaN, ...
    'residual_norm', NaN, ...
    'price_first', NaN, ...
    'price_last', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'wedge_min', NaN, ...
    'wedge_max', NaN, ...
    'max_abs_pressure', NaN, ...
    'outer_iter', NaN, ...
    'price_clear_max_iter', NaN);
end

function price_path_guess = build_price_guess_local(seed_price_csv_path, max_k)
if ~isempty(seed_price_csv_path) && isfile(seed_price_csv_path)
    price_path_guess = readmatrix(seed_price_csv_path);
else
    price_path_guess = 0.34013605902777766;
end
price_path_guess = fit_path_to_horizon_local(price_path_guess(:), max_k, 0.34013605902777766);
if any(~isfinite(price_path_guess)) || any(price_path_guess <= 0)
    error('Seed price path must contain finite positive values only.');
end
end

function fitted = fit_path_to_horizon_local(path_like, horizon_k, fallback_value)
if isempty(path_like)
    fitted = fallback_value .* ones(horizon_k, 1);
    return;
end
path_like = path_like(:);
if numel(path_like) >= horizon_k
    fitted = path_like(1:horizon_k);
else
    fitted = [path_like; path_like(end) .* ones(horizon_k - numel(path_like), 1)];
end
end

function demographic_path_full = build_demographic_path_local(project_root, demographic_source_mode)
mode = lower(string(demographic_source_mode));
entrant_prefix = "entrant_survival_";
if startsWith(mode, entrant_prefix)
    scenario = extractAfter(mode, strlength(entrant_prefix));
    demographic_path_full = build_original_5yr_demographic_entrant_survival_path(project_root, [], scenario);
    return;
end
switch mode
    case "annual_subsampled"
        demographic_path_full = build_original_5yr_demographic_path_from_age_state_csv(project_root);
    case "historical_1950"
        demographic_path_full = build_original_5yr_demographic_path_from_historical_age_shares(project_root);
    case {"historical_1950_two_group", "historical_1950_old_young_proxy"}
        demographic_path_full = build_original_5yr_demographic_two_group_proxy(project_root);
    otherwise
        error('Unsupported demographic_source_mode: %s', demographic_source_mode);
end
end

function demographic_path = truncate_demographic_path_local(demographic_path_full, max_k)
demographic_path = demographic_path_full;
demographic_path.periods = demographic_path_full.periods(1:max_k);
demographic_path.cohort_scale_by_age = demographic_path_full.cohort_scale_by_age(1:max_k, :);
if isfield(demographic_path_full, 'years')
    demographic_path.years = demographic_path_full.years(1:max_k);
end
if isfield(demographic_path_full, 'labels')
    demographic_path.labels = demographic_path_full.labels(1:max_k);
end
if isfield(demographic_path_full, 'population_by_age')
    demographic_path.population_by_age = demographic_path_full.population_by_age(1:max_k, :);
end
if isfield(demographic_path_full, 'entrant_path')
    demographic_path.entrant_path = demographic_path_full.entrant_path(1:max_k, :);
end
if isfield(demographic_path_full, 'survival_rates')
    demographic_path.survival_rates = demographic_path_full.survival_rates;
end
end

function clamped = clamp_path_local(path_like, lower_bound, upper_bound)
clamped = min(max(path_like(:), lower_bound), upper_bound);
end

function gap_path = extract_gap_path_local(solve_results)
if isfield(solve_results, 'log_price_residual_raw')
    gap_path = solve_results.log_price_residual_raw(:);
elseif isfield(solve_results, 'period_diagnostics') && isfield(solve_results.period_diagnostics, 'log_price_residual_raw')
    gap_path = solve_results.period_diagnostics.log_price_residual_raw(:);
else
    gap_path = NaN(numel(solve_results.final_price_path), 1);
end
end

function write_status_local(status_path, state, message, run_tag, output_dir)
status_dir = fileparts(status_path);
if ~exist(status_dir, 'dir'), mkdir(status_dir); end
payload = struct();
payload.state = char(string(state));
payload.message = char(string(message));
payload.run_tag = char(string(run_tag));
payload.output_dir = char(string(output_dir));
payload.updated_at = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
fid = fopen(status_path, 'w');
if fid < 0, return; end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', jsonencode(payload));
end
