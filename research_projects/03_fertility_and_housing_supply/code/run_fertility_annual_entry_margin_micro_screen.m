function run_fertility_annual_entry_margin_micro_screen()
% run_fertility_annual_entry_margin_micro_screen.m
%
% Local diagnostic screen for the annual fertility branch. This takes the
% timing-profile lesson from the earlier micro screen and tests whether the
% remaining stock-fertility miss is mainly an entry-margin problem: make the
% first birth harder than later births while keeping later-parity utility
% high.
%
% Outputs:
%   notes/build/fertility_annual_entry_margin_micro_screen.md
%   notes/build/fertility_annual_entry_margin_micro_screen_candidates.csv
%   notes/build/fertility_annual_entry_margin_micro_screen_paths.csv

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
clear SolveSS_function SolveSS_fertility ClearMarkets_fertility

ensure_external_matlab_data_paths();

cfg = fertility_benchmark_annual_config();
ensure_transition_matrix(cfg.transition_matrix_file);

price_grid = cfg.smoke_full_price_grid;
eval_price = cfg.eval_price;
eval_age = cfg.eval_age;
target_ranges = cfg.target_ranges;

candidate_specs = build_candidate_specs(cfg);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual entry-margin candidate %d: %s ===\n', spec.candidate_id, char(spec.label));
    [candidate_rows(i), tmp_paths] = evaluate_candidate(spec, cfg.smoke_overrides, cfg.rbPos, price_grid, eval_price, eval_age, target_ranges);
    path_table = [path_table; tmp_paths]; %#ok<AGROW>
end

candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'primary_pass', 'sign_pass', 'score', 'eval_mean_age_first_birth'}, ...
    {'descend', 'descend', 'ascend', 'ascend'});

writetable(candidates_table, fullfile(out_dir, 'fertility_annual_entry_margin_micro_screen_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_entry_margin_micro_screen_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_entry_margin_micro_screen.md'), candidates_table, path_table, target_ranges);
end

function specs = build_candidate_specs(cfg)
current_age_weights = cfg.target_first_birth_age_share_annual;
balanced_realized = repelem([1.00, 0.45, 0.15, 0.04], 5);
early_realized = repelem([1.00, 0.40, 0.12, 0.03], 5);

specs = [ ...
    build_spec(1, "current annual benchmark", cfg.overrides.birth_utility_by_parity, cfg.overrides.child_utility, cfg.overrides.birth_cost, cfg.overrides.birth_price_coeff, cfg.overrides.lambda_crowd, current_age_weights, cfg.overrides.first_birth_realized_weights); ...
    build_spec(2, "balanced timing | flat high parity utility", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, balanced_realized); ...
    build_spec(3, "balanced timing | entry phi1 2.20", [2.20, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, balanced_realized); ...
    build_spec(4, "balanced timing | entry phi1 1.80", [1.80, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, balanced_realized); ...
    build_spec(5, "balanced timing | entry phi1 1.40", [1.40, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, balanced_realized); ...
    build_spec(6, "balanced timing | entry phi1 1.00", [1.00, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, balanced_realized); ...
    build_spec(7, "balanced timing | entry phi1 0.70", [0.70, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, balanced_realized); ...
    build_spec(8, "early timing | flat high parity utility", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, early_realized); ...
    build_spec(9, "early timing | entry phi1 2.20", [2.20, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, early_realized); ...
    build_spec(10, "early timing | entry phi1 1.80", [1.80, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, early_realized); ...
    build_spec(11, "early timing | entry phi1 1.40", [1.40, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, early_realized); ...
    build_spec(12, "early timing | entry phi1 1.00", [1.00, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, early_realized); ...
    build_spec(13, "early timing | entry phi1 1.40 | cost 0.03 | kappa 0.06", [1.40, 2.72, 2.65], 0.00, 0.03, 0.06, 0.08, current_age_weights, early_realized); ...
    build_spec(14, "early timing | entry phi1 1.80 | cost 0.03 | kappa 0.06", [1.80, 2.72, 2.65], 0.00, 0.03, 0.06, 0.08, current_age_weights, early_realized) ...
    ];
end

function spec = build_spec(candidate_id, label, birth_utility_by_parity, child_utility, birth_cost, birth_price_coeff, lambda_crowd, birth_age_weights, first_birth_realized_weights)
spec = struct();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.birth_utility_by_parity = birth_utility_by_parity;
spec.child_utility = child_utility;
spec.birth_cost = birth_cost;
spec.birth_price_coeff = birth_price_coeff;
spec.lambda_crowd = lambda_crowd;
spec.birth_age_weights = birth_age_weights(:)';
spec.first_birth_realized_weights = first_birth_realized_weights(:)';
end

function [row, path_rows] = evaluate_candidate(spec, base_overrides, rbPos, price_grid, eval_price, eval_age, target_ranges)
overrides = base_overrides;
overrides.birth_utility_by_parity = spec.birth_utility_by_parity;
overrides.child_utility = spec.child_utility;
overrides.birth_cost = spec.birth_cost;
overrides.birth_price_coeff = spec.birth_price_coeff;
overrides.lambda_crowd = spec.lambda_crowd;
overrides.birth_age_weights = spec.birth_age_weights;
overrides.realized_birth_weights = ones(size(spec.birth_age_weights));
overrides.first_birth_realized_weights = spec.first_birth_realized_weights;

n = numel(price_grid);
avg_birth_rate = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
median_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
mass_error = NaN(n, 1);

eval_diagnostics = [];
for i = 1:n
    [~, ~, ~, ~, ~, diagnostics] = SolveSS_fertility([price_grid(i), rbPos], overrides);
    avg_birth_rate(i) = diagnostics.avg_birth_rate;
    avg_first_birth_rate(i) = diagnostics.avg_first_birth_rate;
    mean_age_first_birth(i) = diagnostics.mean_age_first_birth;
    median_age_first_birth(i) = diagnostics.median_age_first_birth;
    share_first_birth_30_plus(i) = diagnostics.share_first_birth_30_plus;
    mass_error(i) = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));
    if abs(price_grid(i) - eval_price) < 1e-12
        eval_diagnostics = diagnostics;
    end
end

age_idx = find(eval_diagnostics.ages == eval_age, 1);
parity = eval_diagnostics.parity_dist_by_age(age_idx, :);
support_shares = summarize_first_birth_bins(eval_diagnostics);

mean_age_target = get_target(target_ranges, "mean_age_first_birth");
share30_target = get_target(target_ranges, "share_first_birth_30_plus");
childless_target = get_target(target_ranges, "childless_share_at_50");

mean_age_excess = normalized_band_excess(mean_age_first_birth(price_grid == eval_price), mean_age_target);
share30_excess = normalized_band_excess(share_first_birth_30_plus(price_grid == eval_price), share30_target);
childless_excess = normalized_band_excess(parity(1), childless_target);

support_excesses = [ ...
    normalized_band_excess(support_shares(1), get_target(target_ranges, "share_first_birth_25_29")), ...
    normalized_band_excess(support_shares(2), get_target(target_ranges, "share_first_birth_30_34")), ...
    normalized_band_excess(support_shares(3), get_target(target_ranges, "share_first_birth_35_39")), ...
    normalized_band_excess(support_shares(4), get_target(target_ranges, "share_first_birth_40_44_plus"))];

mean_age_monotone = all(diff(mean_age_first_birth) >= -1e-9);
share30_monotone = all(diff(share_first_birth_30_plus) >= -1e-9);
birth_rate_monotone = all(diff(avg_birth_rate) <= 1e-9);
sign_pass = mean_age_monotone && share30_monotone && birth_rate_monotone;

score = mean_age_excess + share30_excess + childless_excess + 0.25 * mean(support_excesses) ...
    + 2.0 * double(~sign_pass) + 1e12 * max(max(mass_error) - 1e-8, 0);

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = spec.label;
row.birth_utility_1 = spec.birth_utility_by_parity(1);
row.birth_utility_2 = spec.birth_utility_by_parity(2);
row.birth_utility_3 = spec.birth_utility_by_parity(3);
row.birth_cost = spec.birth_cost;
row.birth_price_coeff = spec.birth_price_coeff;
row.lambda_crowd = spec.lambda_crowd;
row.eval_mean_age_first_birth = mean_age_first_birth(price_grid == eval_price);
row.eval_median_age_first_birth = median_age_first_birth(price_grid == eval_price);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(price_grid == eval_price);
row.eval_childless_share_at_50 = parity(1);
row.eval_share_first_birth_25_29 = support_shares(1);
row.eval_share_first_birth_30_34 = support_shares(2);
row.eval_share_first_birth_35_39 = support_shares(3);
row.eval_share_first_birth_40_44_plus = support_shares(4);
row.mean_age_band_excess = mean_age_excess;
row.share30_band_excess = share30_excess;
row.childless_band_excess = childless_excess;
row.mean_age_monotone = double(mean_age_monotone);
row.share30_monotone = double(share30_monotone);
row.birth_rate_monotone = double(birth_rate_monotone);
row.primary_pass = double(mean_age_excess == 0 && share30_excess == 0 && childless_excess == 0);
row.sign_pass = double(sign_pass);
row.max_mass_error = max(mass_error);
row.score = score;

path_rows = table( ...
    repmat(spec.candidate_id, n, 1), ...
    repmat(spec.label, n, 1), ...
    price_grid(:), ...
    avg_birth_rate, ...
    avg_first_birth_rate, ...
    mean_age_first_birth, ...
    median_age_first_birth, ...
    share_first_birth_30_plus, ...
    mass_error, ...
    'VariableNames', {'candidate_id', 'label', 'a_price', 'avg_birth_rate', ...
    'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'mass_error'});
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'birth_utility_1', NaN, ...
    'birth_utility_2', NaN, ...
    'birth_utility_3', NaN, ...
    'birth_cost', NaN, ...
    'birth_price_coeff', NaN, ...
    'lambda_crowd', NaN, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_median_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_childless_share_at_50', NaN, ...
    'eval_share_first_birth_25_29', NaN, ...
    'eval_share_first_birth_30_34', NaN, ...
    'eval_share_first_birth_35_39', NaN, ...
    'eval_share_first_birth_40_44_plus', NaN, ...
    'mean_age_band_excess', NaN, ...
    'share30_band_excess', NaN, ...
    'childless_band_excess', NaN, ...
    'mean_age_monotone', NaN, ...
    'share30_monotone', NaN, ...
    'birth_rate_monotone', NaN, ...
    'primary_pass', NaN, ...
    'sign_pass', NaN, ...
    'max_mass_error', NaN, ...
    'score', NaN);
end

function target = get_target(ranges, name)
all_targets = [ranges.primary(:); ranges.support(:); ranges.validation];
idx = find(strcmp(string({all_targets.name}), string(name)), 1);
target = all_targets(idx);
end

function value = normalized_band_excess(x, target)
if x < target.lower
    excess = target.lower - x;
elseif x > target.upper
    excess = x - target.upper;
else
    excess = 0;
end
value = excess / max(target.upper - target.lower, 1e-8);
end

function support_shares = summarize_first_birth_bins(diagnostics)
ages = diagnostics.ages(:);
dist = diagnostics.first_birth_age_dist(:);
support_shares = [ ...
    sum(dist(ages >= 25 & ages <= 29)), ...
    sum(dist(ages >= 30 & ages <= 34)), ...
    sum(dist(ages >= 35 & ages <= 39)), ...
    sum(dist(ages >= 40 & ages <= 44))];
end

function write_report(report_path, candidates_table, path_table, target_ranges)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual entry-margin micro screen\n\n');
fprintf(fid, 'This local diagnostic keeps the improved annual timing profiles and varies the parity gradient so the first birth can be harder than later births. The question is whether the remaining annual miss is mainly an entry-margin problem.\n\n');

fprintf(fid, '## Screening bands used\n\n');
fprintf(fid, '- mean age first birth: `%.1f-%.1f`\n', get_target(target_ranges, "mean_age_first_birth").lower, get_target(target_ranges, "mean_age_first_birth").upper);
fprintf(fid, '- share first births at age `30+`: `%.2f-%.2f`\n', get_target(target_ranges, "share_first_birth_30_plus").lower, get_target(target_ranges, "share_first_birth_30_plus").upper);
fprintf(fid, '- childless share at age `50`: `%.2f-%.2f`\n\n', get_target(target_ranges, "childless_share_at_50").lower, get_target(target_ranges, "childless_share_at_50").upper);

fprintf(fid, '## Candidate ranking\n\n');
fprintf(fid, '| Rank | Candidate | Mean age | Share 30+ | Childless @50 | Primary pass | Sign pass | Score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|\n');

max_rows = min(height(candidates_table), 20);
for i = 1:max_rows
    fprintf(fid, '| %d | %s | `%.2f` | `%.3f` | `%.3f` | `%d` | `%d` | `%.4f` |\n', ...
        i, char(candidates_table.label(i)), candidates_table.eval_mean_age_first_birth(i), ...
        candidates_table.eval_share_first_birth_30_plus(i), candidates_table.eval_childless_share_at_50(i), ...
        candidates_table.primary_pass(i), candidates_table.sign_pass(i), candidates_table.score(i));
end

if height(candidates_table) >= 1
    best_id = candidates_table.candidate_id(1);
    best_label = candidates_table.label(1);
    best_paths = path_table(path_table.candidate_id == best_id, :);
    fprintf(fid, '\n## Best candidate path\n\n');
    fprintf(fid, 'Best candidate: `%s`\n\n', char(best_label));
    fprintf(fid, '| House price | Avg birth rate | Avg first-birth rate | Mean age | Median age | Share 30+ |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|---:|\n');
    for i = 1:height(best_paths)
        fprintf(fid, '| `%.2f` | `%.4f` | `%.4f` | `%.2f` | `%.0f` | `%.3f` |\n', ...
            best_paths.a_price(i), best_paths.avg_birth_rate(i), best_paths.avg_first_birth_rate(i), ...
            best_paths.mean_age_first_birth(i), best_paths.median_age_first_birth(i), ...
            best_paths.share_first_birth_30_plus(i));
    end
end

fclose(fid);
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end
