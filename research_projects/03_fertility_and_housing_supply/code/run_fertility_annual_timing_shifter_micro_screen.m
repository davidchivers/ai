function run_fertility_annual_timing_shifter_micro_screen()
% run_fertility_annual_timing_shifter_micro_screen.m
%
% Small local diagnostic screen for the annual fertility branch. This
% isolates the timing-shifter layer on top of the best low-cost annual
% candidate found in the broad-band smoke pass, so we can see whether the
% remaining delay is mainly coming from first-birth timing weights.
%
% Outputs:
%   notes/build/fertility_annual_timing_shifter_micro_screen.md
%   notes/build/fertility_annual_timing_shifter_micro_screen_candidates.csv
%   notes/build/fertility_annual_timing_shifter_micro_screen_paths.csv

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
    fprintf('\n=== timing-shifter candidate %d: %s ===\n', spec.candidate_id, char(spec.label));
    [candidate_rows(i), tmp_paths] = evaluate_candidate(spec, cfg.smoke_overrides, cfg.rbPos, price_grid, eval_price, eval_age, target_ranges);
    path_table = [path_table; tmp_paths]; %#ok<AGROW>
end

candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'primary_pass', 'sign_pass', 'score', 'eval_mean_age_first_birth'}, ...
    {'descend', 'descend', 'ascend', 'ascend'});

writetable(candidates_table, fullfile(out_dir, 'fertility_annual_timing_shifter_micro_screen_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_timing_shifter_micro_screen_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_timing_shifter_micro_screen.md'), candidates_table, path_table, target_ranges);
end

function specs = build_candidate_specs(cfg)
current_age_weights = cfg.target_first_birth_age_share_annual;
current_realized = cfg.overrides.first_birth_realized_weights;

repeat_5y_realized = repelem([1.00, 0.55, 0.22, 0.06], 5);
steep_realized = repelem([1.00, 0.30, 0.08, 0.02], 5);
flat_realized = ones(1, numel(cfg.annual_birth_ages));
mid_realized_a = repelem([1.00, 0.40, 0.12, 0.03], 5);
mid_realized_b = repelem([1.00, 0.45, 0.15, 0.04], 5);
mid_realized_c = repelem([1.00, 0.50, 0.18, 0.05], 5);
mid_realized_d = repelem([1.00, 0.52, 0.20, 0.055], 5);

early_tilt_age_weights = repeat_bin_shares([0.55, 0.30, 0.12, 0.03]);
flat_age_weights = ones(1, numel(cfg.annual_birth_ages)) / numel(cfg.annual_birth_ages);

specs = [ ...
    build_spec(1, "current annual benchmark", cfg.overrides.birth_utility_by_parity, cfg.overrides.child_utility, cfg.overrides.birth_cost, cfg.overrides.birth_price_coeff, cfg.overrides.lambda_crowd, current_age_weights, current_realized); ...
    build_spec(2, "best broad base + current timing", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, current_realized); ...
    build_spec(3, "best broad base + repeated 5y realized", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, repeat_5y_realized); ...
    build_spec(4, "best broad base + steep realized", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, steep_realized); ...
    build_spec(5, "best broad + repeated 5y realized + early tilt ages", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, early_tilt_age_weights, repeat_5y_realized); ...
    build_spec(6, "best broad + steep realized + early tilt ages", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, early_tilt_age_weights, steep_realized); ...
    build_spec(7, "best broad + flat realized + early tilt ages", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, early_tilt_age_weights, flat_realized); ...
    build_spec(8, "best broad + repeated 5y realized + flat ages", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, flat_age_weights, repeat_5y_realized); ...
    build_spec(9, "best broad + mid realized 0.40/0.12/0.03", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, mid_realized_a); ...
    build_spec(10, "best broad + mid realized 0.45/0.15/0.04", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, mid_realized_b); ...
    build_spec(11, "best broad + mid realized 0.50/0.18/0.05", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, mid_realized_c); ...
    build_spec(12, "best broad + mid realized 0.52/0.20/0.055", [2.60, 2.72, 2.65], 0.00, 0.00, 0.04, 0.08, current_age_weights, mid_realized_d) ...
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

function weights = repeat_bin_shares(bin_shares)
weights = repelem(bin_shares(:)' ./ 5, 5);
weights = weights ./ sum(weights);
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end

function write_report(report_path, candidates_table, path_table, target_ranges)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual timing-shifter micro screen\n\n');
fprintf(fid, ['This local diagnostic holds the low-cost annual candidate fixed and varies only the first-birth timing-shifter layer. ', ...
    'The objective is to see whether annual delay is mainly coming from `first_birth_realized_weights` / age-weight structure.\n\n']);

fprintf(fid, '## Screening bands used\n\n');
fprintf(fid, '- mean age first birth: `%.1f-%.1f`\n', target_ranges.primary(1).lower, target_ranges.primary(1).upper);
fprintf(fid, '- share first births at age `30+`: `%.2f-%.2f`\n', target_ranges.primary(2).lower, target_ranges.primary(2).upper);
fprintf(fid, '- childless share at age `50`: `%.2f-%.2f`\n\n', target_ranges.primary(3).lower, target_ranges.primary(3).upper);

fprintf(fid, '## Candidate ranking\n\n');
fprintf(fid, '| Rank | Candidate | Mean age | Share 30+ | Childless @50 | Primary pass | Sign pass | Score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(candidates_table)
    label_text = strrep(char(candidates_table.label(i)), '|', '/');
    fprintf(fid, '| %d | %s | `%.2f` | `%.3f` | `%.3f` | `%d` | `%d` | `%.4f` |\n', ...
        i, label_text, candidates_table.eval_mean_age_first_birth(i), ...
        candidates_table.eval_share_first_birth_30_plus(i), candidates_table.eval_childless_share_at_50(i), ...
        candidates_table.primary_pass(i), candidates_table.sign_pass(i), candidates_table.score(i));
end
fprintf(fid, '\n');

best_id = candidates_table.candidate_id(1);
best_label = strrep(char(candidates_table.label(1)), '|', '/');
best_paths = path_table(path_table.candidate_id == best_id, :);
fprintf(fid, '## Best candidate path\n\n');
fprintf(fid, 'Best candidate: `%s`\n\n', best_label);
fprintf(fid, '| House price | Avg birth rate | Avg first-birth rate | Mean age | Median age | Share 30+ |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(best_paths)
    fprintf(fid, '| %.2f | `%.4f` | `%.4f` | `%.2f` | `%.0f` | `%.3f` |\n', ...
        best_paths.a_price(i), best_paths.avg_birth_rate(i), best_paths.avg_first_birth_rate(i), ...
        best_paths.mean_age_first_birth(i), best_paths.median_age_first_birth(i), ...
        best_paths.share_first_birth_30_plus(i));
end
fprintf(fid, '\n');
fclose(fid);
end
