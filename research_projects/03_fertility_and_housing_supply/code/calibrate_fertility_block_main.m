function calibrate_fertility_block_main()
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
cd(this_code_dir);
clear SolveSS_fertility ClearMarkets_fertility

ensure_external_matlab_data_paths();
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end

benchmark_cfg = fertility_benchmark_config();
stage1_price_grid = [1.5, benchmark_cfg.eval_price, 3.0];
stage1_solver_overrides = benchmark_cfg.stage1_solver_overrides;
full_price_grid = benchmark_cfg.full_price_grid;
market_price_grid = benchmark_cfg.market_price_grid;
eval_price = benchmark_cfg.eval_price;
eval_age = benchmark_cfg.eval_age;
home_report_ages = benchmark_cfg.home_report_ages;
target_parity = benchmark_cfg.target_parity;

candidate_grid = build_candidate_grid();
n = numel(candidate_grid);
stage1_rows = repmat(empty_result_row(), n, 1);

for i = 1:n
    stage1_rows(i) = evaluate_candidate(i, candidate_grid{i}, stage1_price_grid, eval_price, ...
        eval_age, home_report_ages, target_parity, stage1_solver_overrides);
end

stage1_all = struct2table(stage1_rows);
stage1_demo = sortrows(stage1_all, {'demo_score', 'benchmark_score'}, {'descend', 'descend'});
stage1_benchmark = sortrows(stage1_all, {'benchmark_score', 'demo_score'}, {'descend', 'descend'});

writetable(stage1_all, fullfile(out_dir, 'fertility_calibration_stage1_all.csv'));
writetable(stage1_demo, fullfile(out_dir, 'fertility_calibration_stage1_demographic.csv'));
writetable(stage1_benchmark, fullfile(out_dir, 'fertility_calibration_stage1_benchmark.csv'));

shortlist_ids = build_shortlist_ids(stage1_demo, stage1_benchmark, 6, 6);
shortlist_table = stage1_all(ismember(stage1_all.candidate_id, shortlist_ids), :);
writetable(shortlist_table, fullfile(out_dir, 'fertility_calibration_shortlist.csv'));

full_rows = repmat(empty_result_row(), numel(shortlist_ids), 1);
for i = 1:numel(shortlist_ids)
    candidate_id = shortlist_ids(i);
    full_rows(i) = evaluate_candidate(candidate_id, candidate_grid{candidate_id}, full_price_grid, ...
        eval_price, eval_age, home_report_ages, target_parity, struct());
    full_rows(i).stage1_demo_rank = find(stage1_demo.candidate_id == candidate_id, 1);
    full_rows(i).stage1_benchmark_rank = find(stage1_benchmark.candidate_id == candidate_id, 1);
end

full_table = struct2table(full_rows);
full_demo = sortrows(full_table, {'demo_score', 'benchmark_score'}, {'descend', 'descend'});
full_benchmark = sortrows(full_table, {'benchmark_score', 'demo_score'}, {'descend', 'descend'});

current_defaults = current_benchmark_overrides();
current_row = struct2table(evaluate_candidate(0, current_defaults, full_price_grid, ...
    eval_price, eval_age, home_report_ages, target_parity, struct()));
current_row.source = "current_solver_defaults";

market_candidate_ids = build_market_check_ids(full_demo, full_benchmark);
market_rows = repmat(empty_market_row(), numel(market_candidate_ids), 1);
for i = 1:numel(market_candidate_ids)
    candidate_id = market_candidate_ids(i);
    if candidate_id == 0
        overrides = current_defaults;
        benchmark_score = current_row.benchmark_score;
        demo_score = current_row.demo_score;
    else
        overrides = row_to_overrides(full_table(full_table.candidate_id == candidate_id, :));
        benchmark_score = full_table.benchmark_score(full_table.candidate_id == candidate_id);
        demo_score = full_table.demo_score(full_table.candidate_id == candidate_id);
    end
    [~, crossing] = ClearMarkets_fertility(market_price_grid, 0.03, overrides);
    market_rows(i) = market_result_row(candidate_id, crossing, benchmark_score, demo_score);
end

market_table = struct2table(market_rows);
market_table = sortrows(market_table, {'market_is_unique', 'benchmark_score', 'demo_score'}, ...
    {'descend', 'descend', 'descend'});

writetable(full_table, fullfile(out_dir, 'fertility_calibration_sweep.csv'));
writetable(current_row, fullfile(out_dir, 'fertility_calibration_benchmark.csv'));
writetable(market_table, fullfile(out_dir, 'fertility_calibration_market_checks.csv'));

promoted_row = table();
unique_market = market_table(market_table.market_is_unique == 1, :);
if ~isempty(unique_market)
    promoted_id = unique_market.candidate_id(1);
    if promoted_id == 0
        promoted_row = current_row;
        promoted_row.source = "current_solver_defaults";
    else
        promoted_row = full_table(full_table.candidate_id == promoted_id, :);
        promoted_row.source = "automated_unique_market_candidate";
    end
end

report_path = fullfile(out_dir, 'fertility_calibration_report.md');
fid = fopen(report_path, 'w');
fprintf(fid, '# Fertility calibration sweep\n\n');
fprintf(fid, '## Workflow\n\n');
fprintf(fid, '- Stage 1 uses a coarse solver screen with `I = %d`, `J = %d` on prices `%s`.\n', ...
    stage1_solver_overrides.I, stage1_solver_overrides.J, format_price_grid(stage1_price_grid));
fprintf(fid, '- Full verification uses the default solver grids on prices `%s`.\n', format_price_grid(full_price_grid));
fprintf(fid, '- Market checks use `ClearMarkets_fertility.m` on `%s` for a small shortlist.\n\n', ...
    format_price_grid(market_price_grid));
fprintf(fid, 'Calibration price: `a_price = %.2f`\n', eval_price);
fprintf(fid, 'Calibration age for completed fertility: `%d`\n\n', eval_age);
fprintf(fid, 'Target completed-fertility distribution (`0,1,2,3+`): [%.3f, %.3f, %.3f, %.3f]\n\n', ...
    target_parity(1), target_parity(2), target_parity(3), target_parity(4));
fprintf(fid, 'Children-at-home is still reported separately as a temporary state.\n');
fprintf(fid, 'Leave-home timing remains disciplined by the Census-based leave-by-bin calibration.\n\n');

write_candidate_block(fid, 'Best full demographic candidate', full_demo(1, :), eval_age, home_report_ages);
write_candidate_block(fid, 'Best full benchmark candidate', full_benchmark(1, :), eval_age, home_report_ages);
write_candidate_block(fid, 'Current solver defaults', current_row, eval_age, home_report_ages);

fprintf(fid, '## Market checks\n\n');
for i = 1:height(market_table)
    row = market_table(i, :);
    if row.candidate_id == 0
        label = 'current defaults';
    else
        label = sprintf('candidate %d', row.candidate_id);
    end
    fprintf(fid, '- %s: exists %d, unique %d, sign changes %d, refined price %.6f, method `%s`, benchmark score %.3f\n', ...
        label, row.market_cross_exists, row.market_is_unique, row.market_sign_changes, ...
        row.market_refined_price, row.market_method{1}, row.benchmark_score);
end
fprintf(fid, '\n');

fprintf(fid, '## Shortlist summaries\n\n');
fprintf(fid, 'Top stage-1 demographic candidates by candidate id: `%s`\n\n', format_id_list(stage1_demo.candidate_id(1:min(6, height(stage1_demo)))));
fprintf(fid, 'Top stage-1 benchmark candidates by candidate id: `%s`\n\n', format_id_list(stage1_benchmark.candidate_id(1:min(6, height(stage1_benchmark)))));

fprintf(fid, '### Top full candidates by benchmark score\n\n');
top_display = min(5, height(full_benchmark));
for i = 1:top_display
    row = full_benchmark(i, :);
    fprintf(fid, '- candidate %d: utilities [%.3f, %.3f, %.3f], child utility %.3f, birth cost %.3f, ', ...
        row.candidate_id, row.birth_utility_1, row.birth_utility_2, row.birth_utility_3, ...
        row.child_utility, row.birth_cost);
    fprintf(fid, 'price coeff %.3f, lambda %.3f, parity50 [%.3f, %.3f, %.3f, %.3f], vote sign changes %d, benchmark score %.3f\n', ...
        row.birth_price_coeff, row.lambda_crowd, row.share_parity_0, row.share_parity_1, ...
        row.share_parity_2, row.share_parity_3plus, row.vote_sign_changes, row.benchmark_score);
end
fprintf(fid, '\n');

if ~isempty(promoted_row)
    fprintf(fid, '## Promoted benchmark\n\n');
    fprintf(fid, 'A unique market-crossing candidate was found and is eligible for promotion.\n\n');
    write_candidate_block(fid, 'Promoted benchmark candidate', promoted_row, eval_age, home_report_ages);
else
    fprintf(fid, '## Promoted benchmark\n\n');
    fprintf(fid, 'No unique market-crossing candidate was found in this pass. The corrected-code benchmark remains unresolved.\n\n');
end

fclose(fid);
end

function candidate_grid = build_candidate_grid()
rng(20260317);
n_random = 36;

candidate_grid = { ...
    fertility_benchmark_config().overrides, ...
    struct('birth_utility_by_parity', [0.42 0.28 0.14], 'child_utility', 0.00, 'birth_cost', 0.05, 'birth_price_coeff', 0.085, 'lambda_crowd', 0.50), ...
    struct('birth_utility_by_parity', [0.85 1.10 1.20], 'child_utility', 0.02, 'birth_cost', 0.06, 'birth_price_coeff', 0.24, 'lambda_crowd', 0.18), ...
    struct('birth_utility_by_parity', [0.95 1.25 1.35], 'child_utility', 0.03, 'birth_cost', 0.06, 'birth_price_coeff', 0.30, 'lambda_crowd', 0.22), ...
    struct('birth_utility_by_parity', [1.00 1.30 1.35], 'child_utility', 0.03, 'birth_cost', 0.08, 'birth_price_coeff', 0.38, 'lambda_crowd', 0.26), ...
    struct('birth_utility_by_parity', [1.05 1.35 1.40], 'child_utility', 0.03, 'birth_cost', 0.08, 'birth_price_coeff', 0.40, 'lambda_crowd', 0.255), ...
    struct('birth_utility_by_parity', [1.10 1.45 1.50], 'child_utility', 0.04, 'birth_cost', 0.07, 'birth_price_coeff', 0.32, 'lambda_crowd', 0.28), ...
    struct('birth_utility_by_parity', [1.20 1.55 1.60], 'child_utility', 0.03, 'birth_cost', 0.10, 'birth_price_coeff', 0.45, 'lambda_crowd', 0.20) ...
    };

for i = 1:n_random
    u1 = 0.70 + 0.70 * rand();
    u2 = u1 + 0.05 + 0.70 * rand();
    u3 = max(0.50, u2 - 0.20 + 0.55 * rand());
    child_utility = 0.00 + 0.08 * rand();
    birth_cost = 0.00 + 0.18 * rand();
    price_coeff = 0.20 + 0.35 * rand();
    lambda_crowd = 0.10 + 0.25 * rand();
    candidate_grid{end + 1} = struct( ...
        'birth_utility_by_parity', [u1, u2, u3], ...
        'child_utility', child_utility, ...
        'birth_cost', birth_cost, ...
        'birth_price_coeff', price_coeff, ...
        'lambda_crowd', lambda_crowd);
end
end

function row = evaluate_candidate(candidate_id, overrides, price_grid, eval_price, eval_age, ...
    home_report_ages, target_parity, solver_overrides)
birth_rates = NaN(numel(price_grid), 1);
votes = NaN(numel(price_grid), 1);
mass_errors = NaN(numel(price_grid), 1);
parity_share_eval = NaN(1, 4);
share_home_any = NaN(1, numel(home_report_ages));
mean_home_children = NaN(1, numel(home_report_ages));

solve_overrides = combine_overrides(overrides, solver_overrides);

for j = 1:numel(price_grid)
    [~, ~, ~, votes(j), ~, diagnostics] = SolveSS_fertility([price_grid(j), 0.03], solve_overrides);
    birth_rates(j) = diagnostics.avg_birth_rate;
    mass_errors(j) = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));

    if abs(price_grid(j) - eval_price) < 1e-12
        age_idx = find(diagnostics.ages == eval_age, 1);
        tmp = diagnostics.parity_dist_by_age(age_idx, :);
        parity_share_eval(1:numel(tmp)) = tmp;

        for ia = 1:numel(home_report_ages)
            report_idx = find(diagnostics.ages == home_report_ages(ia), 1);
            home_shares = diagnostics.home_dist_by_age(report_idx, :);
            share_home_any(ia) = 1 - home_shares(1);
            mean_home_children(ia) = sum((0:(numel(home_shares) - 1)) .* home_shares);
        end
    end
end

birth_decline = birth_rates(1) - birth_rates(end);
parity_abs_error = abs(parity_share_eval - target_parity);
parity_rel_error = parity_abs_error ./ max(target_parity, 1e-8);
parity_rmse = sqrt(mean(parity_abs_error .^ 2));
vote_sign_changes = count_sign_changes(votes);

row = empty_result_row();
row.candidate_id = candidate_id;
row.birth_utility_1 = overrides.birth_utility_by_parity(1);
row.birth_utility_2 = overrides.birth_utility_by_parity(2);
row.birth_utility_3 = overrides.birth_utility_by_parity(3);
row.child_utility = getfield_or(overrides, 'child_utility', NaN);
row.birth_cost = getfield_or(overrides, 'birth_cost', NaN);
row.birth_price_coeff = overrides.birth_price_coeff;
row.lambda_crowd = overrides.lambda_crowd;
row.birth_rate_p15 = pick_metric(price_grid, birth_rates, 1.5);
row.birth_rate_p20 = pick_metric(price_grid, birth_rates, 2.0);
row.birth_rate_p25 = pick_metric(price_grid, birth_rates, 2.5);
row.birth_rate_p30 = pick_metric(price_grid, birth_rates, 3.0);
row.birth_decline = birth_decline;
row.vote_p15 = pick_metric(price_grid, votes, 1.5);
row.vote_p20 = pick_metric(price_grid, votes, 2.0);
row.vote_p25 = pick_metric(price_grid, votes, 2.5);
row.vote_p30 = pick_metric(price_grid, votes, 3.0);
row.vote_sign_changes = vote_sign_changes;
row.vote_low_positive = double(votes(1) > 0);
row.vote_high_negative = double(votes(end) < 0);
row.vote_cross = double(vote_sign_changes >= 1);
row.mass_error = max(mass_errors);
row.share_parity_0 = parity_share_eval(1);
row.share_parity_1 = parity_share_eval(2);
row.share_parity_2 = parity_share_eval(3);
row.share_parity_3plus = parity_share_eval(4);
row.parity_rmse = parity_rmse;
row.share_home_any_40 = share_home_any(1);
row.share_home_any_50 = share_home_any(2);
row.mean_home_children_40 = mean_home_children(1);
row.mean_home_children_50 = mean_home_children(2);
row.demo_score = demographic_score(parity_abs_error, parity_rel_error, birth_rates, row.mass_error);
row.benchmark_score = benchmark_score(row.demo_score, votes, vote_sign_changes, birth_decline, row.mass_error);
end

function score = demographic_score(parity_abs_error, parity_rel_error, birth_rates, mass_error)
score = 0;
score = score - 6.0 * sum(parity_rel_error);
score = score - 25.0 * sqrt(mean(parity_abs_error .^ 2));
score = score + 0.75 * double(all(diff(birth_rates) < 0));
score = score - 1e12 * max(mass_error - 1e-8, 0);
end

function score = benchmark_score(demo_score, votes, vote_sign_changes, birth_decline, mass_error)
score = demo_score;
score = score + 0.75 * double(vote_sign_changes >= 1);
score = score + 1.25 * double(vote_sign_changes == 1 && votes(1) > 0 && votes(end) < 0);
score = score + 0.50 * double(votes(1) > 0 && votes(end) < 0);
score = score - 0.75 * max(vote_sign_changes - 1, 0);
score = score - 0.50 * double(all(votes < 0));
score = score - 0.50 * double(all(votes > 0));
score = score + max(birth_decline, -1);
score = score - 1e12 * max(mass_error - 1e-8, 0);
end

function shortlist_ids = build_shortlist_ids(stage1_demo, stage1_benchmark, n_demo, n_benchmark)
shortlist_ids = [];
demo_take = min(n_demo, height(stage1_demo));
bench_take = min(n_benchmark, height(stage1_benchmark));

for i = 1:demo_take
    shortlist_ids(end + 1) = stage1_demo.candidate_id(i); %#ok<AGROW>
end
for i = 1:bench_take
    candidate_id = stage1_benchmark.candidate_id(i);
    if ~ismember(candidate_id, shortlist_ids)
        shortlist_ids(end + 1) = candidate_id; %#ok<AGROW>
    end
end

shortlist_ids = shortlist_ids(:)';
end

function market_candidate_ids = build_market_check_ids(full_demo, full_benchmark)
market_candidate_ids = [];

top_benchmark = min(3, height(full_benchmark));
for i = 1:top_benchmark
    market_candidate_ids(end + 1) = full_benchmark.candidate_id(i); %#ok<AGROW>
end

if ~isempty(full_demo)
    demo_id = full_demo.candidate_id(1);
    if ~ismember(demo_id, market_candidate_ids)
        market_candidate_ids(end + 1) = demo_id; %#ok<AGROW>
    end
end

if ~ismember(0, market_candidate_ids)
    market_candidate_ids(end + 1) = 0; %#ok<AGROW>
end
end

function overrides = current_benchmark_overrides()
cfg = fertility_benchmark_config();
overrides = cfg.overrides;
end

function write_candidate_block(fid, title_text, row, eval_age, home_report_ages)
fprintf(fid, '## %s\n\n', title_text);
fprintf(fid, '- candidate id: %d\n', row.candidate_id);
fprintf(fid, '- birth utilities: [%.4f, %.4f, %.4f]\n', row.birth_utility_1, row.birth_utility_2, row.birth_utility_3);
fprintf(fid, '- child utility: %.4f\n', row.child_utility);
fprintf(fid, '- birth cost: %.4f\n', row.birth_cost);
fprintf(fid, '- birth price coeff: %.4f\n', row.birth_price_coeff);
fprintf(fid, '- lambda crowd: %.4f\n', row.lambda_crowd);
fprintf(fid, '- demographic score: %.3f\n', row.demo_score);
fprintf(fid, '- benchmark score: %.3f\n', row.benchmark_score);
fprintf(fid, '- birth decline (1.5 to 3.0): %.6f\n', row.birth_decline);
fprintf(fid, '- vote sign changes on verification grid: %d\n', row.vote_sign_changes);
fprintf(fid, '- vote low-price positive / high-price negative: %d / %d\n', row.vote_low_positive, row.vote_high_negative);
fprintf(fid, '- max mass error: %.3e\n', row.mass_error);
fprintf(fid, '- completed-fertility shares at age %d: [%.6f, %.6f, %.6f, %.6f]\n', ...
    eval_age, row.share_parity_0, row.share_parity_1, row.share_parity_2, row.share_parity_3plus);
fprintf(fid, '- share with any children at home, age %d: %.6f\n', home_report_ages(1), row.share_home_any_40);
fprintf(fid, '- share with any children at home, age %d: %.6f\n', home_report_ages(2), row.share_home_any_50);
fprintf(fid, '- mean children at home, age %d: %.6f\n', home_report_ages(1), row.mean_home_children_40);
fprintf(fid, '- mean children at home, age %d: %.6f\n\n', home_report_ages(2), row.mean_home_children_50);
end

function row = empty_result_row()
row = struct( ...
    'candidate_id', NaN, ...
    'birth_utility_1', NaN, ...
    'birth_utility_2', NaN, ...
    'birth_utility_3', NaN, ...
    'child_utility', NaN, ...
    'birth_cost', NaN, ...
    'birth_price_coeff', NaN, ...
    'lambda_crowd', NaN, ...
    'birth_rate_p15', NaN, ...
    'birth_rate_p20', NaN, ...
    'birth_rate_p25', NaN, ...
    'birth_rate_p30', NaN, ...
    'birth_decline', NaN, ...
    'vote_p15', NaN, ...
    'vote_p20', NaN, ...
    'vote_p25', NaN, ...
    'vote_p30', NaN, ...
    'vote_sign_changes', NaN, ...
    'vote_low_positive', NaN, ...
    'vote_high_negative', NaN, ...
    'vote_cross', NaN, ...
    'mass_error', NaN, ...
    'share_parity_0', NaN, ...
    'share_parity_1', NaN, ...
    'share_parity_2', NaN, ...
    'share_parity_3plus', NaN, ...
    'parity_rmse', NaN, ...
    'share_home_any_40', NaN, ...
    'share_home_any_50', NaN, ...
    'mean_home_children_40', NaN, ...
    'mean_home_children_50', NaN, ...
    'demo_score', NaN, ...
    'benchmark_score', NaN, ...
    'stage1_demo_rank', NaN, ...
    'stage1_benchmark_rank', NaN);
end

function row = empty_market_row()
row = struct( ...
    'candidate_id', NaN, ...
    'benchmark_score', NaN, ...
    'demo_score', NaN, ...
    'market_cross_exists', NaN, ...
    'market_is_unique', NaN, ...
    'market_sign_changes', NaN, ...
    'market_refined_price', NaN, ...
    'market_refined_vote', NaN, ...
    'market_method', {''});
end

function row = market_result_row(candidate_id, crossing, benchmark_score_value, demo_score_value)
row = empty_market_row();
row.candidate_id = candidate_id;
row.benchmark_score = benchmark_score_value;
row.demo_score = demo_score_value;
row.market_cross_exists = double(crossing.exists);
row.market_is_unique = double(crossing.is_unique);
row.market_sign_changes = crossing.sign_change_count;
row.market_refined_price = crossing.refined_price;
row.market_refined_vote = crossing.refined_vote;
row.market_method = crossing.method;
end

function overrides = row_to_overrides(row)
overrides = struct( ...
    'birth_utility_by_parity', [row.birth_utility_1, row.birth_utility_2, row.birth_utility_3], ...
    'child_utility', row.child_utility, ...
    'birth_cost', row.birth_cost, ...
    'birth_price_coeff', row.birth_price_coeff, ...
    'lambda_crowd', row.lambda_crowd);
end

function out = combine_overrides(primary, secondary)
out = primary;
if nargin < 2 || isempty(secondary)
    return;
end
fields = fieldnames(secondary);
for i = 1:numel(fields)
    out.(fields{i}) = secondary.(fields{i});
end
end

function value = getfield_or(s, fieldname, fallback)
if isfield(s, fieldname)
    value = s.(fieldname);
else
    value = fallback;
end
end

function value = pick_metric(price_grid, values, target_price)
idx = find(abs(price_grid - target_price) < 1e-12, 1);
if isempty(idx)
    value = NaN;
else
    value = values(idx);
end
end

function n_changes = count_sign_changes(values)
values = values(:);
n_changes = 0;
prev_sign = 0;
for i = 1:numel(values)
    current_sign = sign(values(i));
    if current_sign == 0
        continue;
    end
    if prev_sign ~= 0 && current_sign ~= prev_sign
        n_changes = n_changes + 1;
    end
    prev_sign = current_sign;
end
end

function out = format_price_grid(price_grid)
parts = arrayfun(@(x) sprintf('%.2f', x), price_grid, 'UniformOutput', false);
out = strjoin(parts, ', ');
end

function out = format_id_list(ids)
parts = arrayfun(@(x) sprintf('%d', x), ids(:)', 'UniformOutput', false);
out = strjoin(parts, ', ');
end
