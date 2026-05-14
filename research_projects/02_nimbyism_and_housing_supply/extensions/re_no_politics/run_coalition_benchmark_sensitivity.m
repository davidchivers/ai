function results_table = run_coalition_benchmark_sensitivity()
% Benchmark-based coalition sensitivity workflow.
% Runs one-margin-at-a-time coalition cases plus a combined case, all
% benchmarked against the zero-alpha nesting case.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');
summary_path = fullfile(this_dir, 'coalition_benchmark_summary.csv');
results_path = fullfile(this_dir, 'coalition_benchmark_results.mat');
live_summary_path = fullfile(this_dir, 'coalition_benchmark_summary_live.csv');
live_results_path = fullfile(this_dir, 'coalition_benchmark_results_live.mat');

addpath(baseline_dir);
addpath(this_dir);

cases = build_cases();
raw_results = initialize_raw_results(cases);
detailed_results = cell(numel(cases), 1);

if isfile(live_results_path)
    resume_data = load(live_results_path, 'raw_results', 'cases', 'detailed_results');
    if isfield(resume_data, 'raw_results') && isfield(resume_data, 'cases') && ...
            isequaln(resume_data.cases, cases) && numel(resume_data.raw_results) == numel(cases)
        raw_results = resume_data.raw_results;
        if isfield(resume_data, 'detailed_results') && numel(resume_data.detailed_results) == numel(cases)
            detailed_results = resume_data.detailed_results;
        end
        completed_count = sum(arrayfun(@(s) string(s.status) ~= "pending", raw_results));
        fprintf('Resuming coalition benchmark checkpoint: %d / %d cases already have results.\n', ...
            completed_count, numel(cases));
    else
        fprintf('Ignoring incompatible coalition benchmark checkpoint and starting fresh.\n');
    end
end

fprintf('=== Coalition Benchmark Sensitivity ===\n');
fprintf('Cases: %d\n', numel(cases));

for i = 1:numel(cases)
    if string(raw_results(i).status) ~= "pending"
        fprintf('\nCase %d / %d already completed with status %s, skipping.\n', ...
            i, numel(cases), string(raw_results(i).status));
        continue;
    end

    case_info = cases(i);

    tic;
    try
        fprintf('\nCase %d / %d\n', i, numel(cases));
        fprintf('  case = %s\n', case_info.case_name);
        fprintf('  alphas = [%g %g %g %g]\n', ...
            case_info.params.alpha_owner, case_info.params.alpha_old_owner, ...
            case_info.params.alpha_leverage, case_info.params.alpha_bighouse);

        [grid_results, stats_all, grid_meta] = run_case_grid(case_info.params);
        [best_summary, best_stats, best_idx] = summarize_best_case(grid_results, stats_all, grid_meta);

        raw_results(i).case_id = i;
        raw_results(i).case_name = string(case_info.case_name);
        raw_results(i).status = "ok";
        raw_results(i).alpha_owner = case_info.params.alpha_owner;
        raw_results(i).alpha_old_owner = case_info.params.alpha_old_owner;
        raw_results(i).alpha_leverage = case_info.params.alpha_leverage;
        raw_results(i).alpha_bighouse = case_info.params.alpha_bighouse;
        raw_results(i).best_price = best_summary.best_price;
        raw_results(i).min_distance = best_summary.min_distance;
        raw_results(i).weighted_vote = best_summary.weighted_vote;
        raw_results(i).equal_weight_vote = best_summary.equal_weight_vote;
        raw_results(i).owner_share = best_summary.owner_share;
        raw_results(i).old_owner_share = best_summary.old_owner_share;
        raw_results(i).leveraged_owner_share = best_summary.leveraged_owner_share;
        raw_results(i).debtstock = best_summary.debtstock;
        raw_results(i).grid_min_price = min(grid_meta.X1);
        raw_results(i).grid_max_price = max(grid_meta.X1);
        raw_results(i).grid_points = numel(grid_meta.X1);

        detailed_results{i} = struct( ...
            'case_name', string(case_info.case_name), ...
            'coalition_params', case_info.params, ...
            'grid_results', grid_results, ...
            'stats_all', {stats_all}, ...
            'grid_meta', grid_meta, ...
            'best_index', best_idx, ...
            'best_summary', best_summary, ...
            'best_stats', best_stats);
    catch err
        raw_results(i).case_id = i;
        raw_results(i).case_name = string(case_info.case_name);
        raw_results(i).status = "error";
        raw_results(i).alpha_owner = case_info.params.alpha_owner;
        raw_results(i).alpha_old_owner = case_info.params.alpha_old_owner;
        raw_results(i).alpha_leverage = case_info.params.alpha_leverage;
        raw_results(i).alpha_bighouse = case_info.params.alpha_bighouse;
        raw_results(i).notes = string(err.message);
        detailed_results{i} = struct([]);
    end

    raw_results(i).elapsed_seconds = toc;
    results_table = finalize_results_table(raw_results);
    writetable(results_table, live_summary_path);
    save(live_results_path, 'results_table', 'raw_results', 'cases', 'detailed_results');
end

results_table = finalize_results_table(raw_results);
writetable(results_table, summary_path);
save(results_path, 'results_table', 'raw_results', 'cases', 'detailed_results');

if isfile(live_summary_path)
    delete(live_summary_path);
end
if isfile(live_results_path)
    delete(live_results_path);
end

fprintf('\nSaved %s\n', summary_path);
fprintf('Saved %s\n', results_path);
end

function cases = build_cases()
cases = [ ...
    struct('case_name', "benchmark_equal_weight", 'params', struct('alpha_owner', 0.00, 'alpha_old_owner', 0.00, 'alpha_leverage', 0.00, 'alpha_bighouse', 0.00))
    struct('case_name', "owner_only", 'params', struct('alpha_owner', 0.50, 'alpha_old_owner', 0.00, 'alpha_leverage', 0.00, 'alpha_bighouse', 0.00))
    struct('case_name', "old_owner_only", 'params', struct('alpha_owner', 0.00, 'alpha_old_owner', 0.50, 'alpha_leverage', 0.00, 'alpha_bighouse', 0.00))
    struct('case_name', "leveraged_owner_only", 'params', struct('alpha_owner', 0.00, 'alpha_old_owner', 0.00, 'alpha_leverage', 0.25, 'alpha_bighouse', 0.00))
    struct('case_name', "big_house_only", 'params', struct('alpha_owner', 0.00, 'alpha_old_owner', 0.00, 'alpha_leverage', 0.00, 'alpha_bighouse', 0.10))
    struct('case_name', "combined_default", 'params', struct('alpha_owner', 0.50, 'alpha_old_owner', 0.50, 'alpha_leverage', 0.25, 'alpha_bighouse', 0.10))
    ];
end

function [grid_results, stats_all, grid_meta] = run_case_grid(coalition_params)
grid_meta = struct();
grid_meta.X1 = linspace(-1, 1, 30) * 0.2 + 2;
grid_meta.X2 = 0.03;

grid_results = zeros(10, numel(grid_meta.X1));
stats_all = cell(1, numel(grid_meta.X1));

for x1 = 1:numel(grid_meta.X1)
    [distance, a_price, rbPos, totalvote, debtstock, stats] = ...
        solve_ss_coalition([grid_meta.X1(x1), grid_meta.X2], coalition_params); %#ok<ASGLU>

    grid_results(:, x1) = [ ...
        distance
        a_price
        rbPos
        totalvote
        debtstock
        stats.equal_weight_vote
        stats.owner_share
        stats.old_owner_share
        stats.leveraged_owner_share
        stats.weighted_vote_share];
    stats_all{x1} = stats;
end
end

function [best_summary, best_stats, best_idx] = summarize_best_case(grid_results, stats_all, grid_meta)
[min_dist, best_idx] = min(grid_results(1, :));
best_stats = stats_all{best_idx};

best_summary = struct();
best_summary.min_distance = min_dist;
best_summary.best_price = grid_results(2, best_idx);
best_summary.rbPos = grid_results(3, best_idx);
best_summary.weighted_vote = grid_results(4, best_idx);
best_summary.debtstock = grid_results(5, best_idx);
best_summary.equal_weight_vote = grid_results(6, best_idx);
best_summary.owner_share = grid_results(7, best_idx);
best_summary.old_owner_share = grid_results(8, best_idx);
best_summary.leveraged_owner_share = grid_results(9, best_idx);
best_summary.weighted_vote_share = grid_results(10, best_idx);
best_summary.grid_price = grid_meta.X1(best_idx);
end

function raw_results = initialize_raw_results(cases)
raw_results = repmat(struct( ...
    'case_id', NaN, ...
    'case_name', "", ...
    'status', "pending", ...
    'alpha_owner', NaN, ...
    'alpha_old_owner', NaN, ...
    'alpha_leverage', NaN, ...
    'alpha_bighouse', NaN, ...
    'best_price', NaN, ...
    'min_distance', NaN, ...
    'weighted_vote', NaN, ...
    'equal_weight_vote', NaN, ...
    'owner_share', NaN, ...
    'old_owner_share', NaN, ...
    'leveraged_owner_share', NaN, ...
    'debtstock', NaN, ...
    'grid_min_price', NaN, ...
    'grid_max_price', NaN, ...
    'grid_points', NaN, ...
    'benchmark_price_diff', NaN, ...
    'benchmark_weighted_vote_diff', NaN, ...
    'benchmark_equal_vote_diff', NaN, ...
    'benchmark_debtstock_diff', NaN, ...
    'notes', "", ...
    'elapsed_seconds', NaN), numel(cases), 1);
end

function results_table = finalize_results_table(raw_results)
results_table = struct2table(raw_results);
benchmark_mask = strcmp(results_table.case_name, "benchmark_equal_weight") & strcmp(results_table.status, "ok");

if any(benchmark_mask)
    benchmark_row = results_table(benchmark_mask, :);
    results_table.benchmark_price_diff = results_table.best_price - benchmark_row.best_price(1);
    results_table.benchmark_weighted_vote_diff = results_table.weighted_vote - benchmark_row.weighted_vote(1);
    results_table.benchmark_equal_vote_diff = results_table.equal_weight_vote - benchmark_row.equal_weight_vote(1);
    results_table.benchmark_debtstock_diff = results_table.debtstock - benchmark_row.debtstock(1);
end

results_table = sortrows(results_table, {'status', 'case_id'}, {'ascend', 'ascend'});
end
