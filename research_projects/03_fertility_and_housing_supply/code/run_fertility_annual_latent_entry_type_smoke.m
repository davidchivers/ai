function run_fertility_annual_latent_entry_type_smoke()
% run_fertility_annual_latent_entry_type_smoke.m
%
% Smoke test a very small permanent extensive-margin heterogeneity layer on
% top of the current usable annual fertility-fit row.
%
% Interpretation:
%   - baseline type: current usable annual row
%   - low-entry type: same household block except lower first-birth utility
%   - type share is fixed and exogenous; it does not move with prices
%
% The purpose is diagnostic only. It asks whether a small low-entry type can
% raise childlessness at age 50 without pushing first births even later.
%
% Outputs:
%   notes/build/fertility_annual_latent_entry_type_smoke.md
%   notes/build/fertility_annual_latent_entry_type_smoke_candidates.csv
%   notes/build/fertility_annual_latent_entry_type_smoke_paths.csv
%   notes/build/fertility_annual_latent_entry_type_smoke_crossing_paths.csv

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
settings = build_settings(cfg);
ensure_transition_matrix(settings.base_overrides.transition_matrix_file);

candidate_specs = build_candidate_specs();
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();
crossing_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual latent-entry candidate %d: %s ===\n', spec.candidate_id, char(spec.label));
    [candidate_rows(i), tmp_paths, tmp_crossing] = evaluate_candidate(spec, settings, cfg);
    path_table = [path_table; tmp_paths]; %#ok<AGROW>
    crossing_table = [crossing_table; tmp_crossing]; %#ok<AGROW>
end

candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'primary_pass', 'sign_pass', 'reference_score', 'crossing_gap_to_zero'}, ...
    {'descend', 'descend', 'ascend', 'ascend'});

writetable(candidates_table, fullfile(out_dir, 'fertility_annual_latent_entry_type_smoke_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_latent_entry_type_smoke_paths.csv'));
writetable(crossing_table, fullfile(out_dir, 'fertility_annual_latent_entry_type_smoke_crossing_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_latent_entry_type_smoke.md'), candidates_table, path_table, crossing_table, cfg.target_ranges);
end

function settings = build_settings(cfg)
settings = struct();
settings.eval_price = cfg.eval_price;
settings.eval_age = cfg.eval_age;
settings.price_grid = [1.50, 2.00, 2.50];
settings.crossing_price_grid = [1.50, 2.00, 2.50, 3.50, 5.00, 6.00];

base_overrides = cfg.smoke_overrides;
base_overrides.birth_utility_by_parity = [1.120, 1.240, 1.170];
base_overrides.child_utility = 0.020;
base_overrides.birth_cost = 0.050;
base_overrides.birth_price_coeff = 0.16;
base_overrides.lambda_crowd = 0.10;
base_overrides.birth_age_weights = cfg.target_first_birth_age_share_annual;
base_overrides.realized_birth_weights = ones(size(cfg.target_first_birth_age_share_annual));
base_overrides.first_birth_realized_weights = repelem([1.00, 0.25, 0.040, 0.008], 5);
base_overrides.cohort_weights_by_age = cfg.overrides.cohort_weights_by_age;

settings.base_overrides = base_overrides;
settings.reference_mean_age = get_target(cfg.target_ranges, "mean_age_first_birth").reference;
settings.reference_share30 = get_target(cfg.target_ranges, "share_first_birth_30_plus").reference;
settings.reference_childless = get_target(cfg.target_ranges, "childless_share_at_50").reference;
end

function specs = build_candidate_specs()
specs = [ ...
    build_spec(1, "baseline usable annual row", 0.00, NaN); ...
    build_spec(2, "5 pct low-entry type | phi0 0.60", 0.05, 0.60); ...
    build_spec(3, "10 pct low-entry type | phi0 0.60", 0.10, 0.60); ...
    build_spec(4, "15 pct low-entry type | phi0 0.60", 0.15, 0.60); ...
    build_spec(5, "10 pct low-entry type | phi0 0.30", 0.10, 0.30); ...
    build_spec(6, "10 pct low-entry type | phi0 0.90", 0.10, 0.90) ...
    ];
end

function spec = build_spec(candidate_id, label, low_type_share, low_type_phi0)
spec = struct();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.low_type_share = low_type_share;
spec.low_type_phi0 = low_type_phi0;
end

function [row, path_rows, crossing_rows] = evaluate_candidate(spec, settings, cfg)
main_weight = 1.0 - spec.low_type_share;
weights = main_weight;
override_list = {settings.base_overrides};

if spec.low_type_share > 0
    low_overrides = settings.base_overrides;
    low_overrides.birth_utility_by_parity(1) = spec.low_type_phi0;
    weights = [main_weight, spec.low_type_share];
    override_list = {settings.base_overrides, low_overrides};
end

n = numel(settings.price_grid);
avg_birth_rate = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
median_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
childless_share_at_50 = NaN(n, 1);
totalvote = NaN(n, 1);
debtstock = NaN(n, 1);
mass_error = NaN(n, 1);
support_25_29 = NaN(n, 1);
support_30_34 = NaN(n, 1);
support_35_39 = NaN(n, 1);
support_40_44 = NaN(n, 1);

for i = 1:n
    point = evaluate_mixture_point(settings.price_grid(i), cfg.rbPos, override_list, weights, settings.eval_age);
    avg_birth_rate(i) = point.avg_birth_rate;
    avg_first_birth_rate(i) = point.avg_first_birth_rate;
    mean_age_first_birth(i) = point.mean_age_first_birth;
    median_age_first_birth(i) = point.median_age_first_birth;
    share_first_birth_30_plus(i) = point.share_first_birth_30_plus;
    childless_share_at_50(i) = point.childless_share_at_50;
    totalvote(i) = point.totalvote;
    debtstock(i) = point.debtstock;
    mass_error(i) = point.max_mass_error;
    support_25_29(i) = point.support_shares(1);
    support_30_34(i) = point.support_shares(2);
    support_35_39(i) = point.support_shares(3);
    support_40_44(i) = point.support_shares(4);
end

ncross = numel(settings.crossing_price_grid);
cross_vote = NaN(ncross, 1);
cross_birth = NaN(ncross, 1);
for i = 1:ncross
    point = evaluate_mixture_point(settings.crossing_price_grid(i), cfg.rbPos, override_list, weights, settings.eval_age);
    cross_vote(i) = point.totalvote;
    cross_birth(i) = point.avg_birth_rate;
end

mean_age_target = get_target(cfg.target_ranges, "mean_age_first_birth");
share30_target = get_target(cfg.target_ranges, "share_first_birth_30_plus");
childless_target = get_target(cfg.target_ranges, "childless_share_at_50");
support_targets = [ ...
    get_target(cfg.target_ranges, "share_first_birth_25_29"), ...
    get_target(cfg.target_ranges, "share_first_birth_30_34"), ...
    get_target(cfg.target_ranges, "share_first_birth_35_39"), ...
    get_target(cfg.target_ranges, "share_first_birth_40_44_plus")];

eval_idx = find(abs(settings.price_grid - settings.eval_price) < 1e-12, 1);
mean_age_excess = normalized_band_excess(mean_age_first_birth(eval_idx), mean_age_target);
share30_excess = normalized_band_excess(share_first_birth_30_plus(eval_idx), share30_target);
childless_excess = normalized_band_excess(childless_share_at_50(eval_idx), childless_target);
support_eval = [support_25_29(eval_idx), support_30_34(eval_idx), support_35_39(eval_idx), support_40_44(eval_idx)];
support_excesses = zeros(1, 4);
for j = 1:4
    support_excesses(j) = normalized_band_excess(support_eval(j), support_targets(j));
end

mean_age_monotone = all(diff(mean_age_first_birth) >= -1e-9);
share30_monotone = all(diff(share_first_birth_30_plus) >= -1e-9);
birth_rate_monotone = all(diff(avg_birth_rate) <= 1e-9);
sign_pass = mean_age_monotone && share30_monotone && birth_rate_monotone;

crossing = summarize_crossing(settings.crossing_price_grid, cross_vote);
reference_score = ...
    abs(mean_age_first_birth(eval_idx) - settings.reference_mean_age) / max(mean_age_target.upper - mean_age_target.lower, 1e-8) + ...
    abs(share_first_birth_30_plus(eval_idx) - settings.reference_share30) / max(share30_target.upper - share30_target.lower, 1e-8) + ...
    abs(childless_share_at_50(eval_idx) - settings.reference_childless) / max(childless_target.upper - childless_target.lower, 1e-8);

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = spec.label;
row.low_type_share = spec.low_type_share;
row.low_type_phi0 = spec.low_type_phi0;
row.eval_mean_age_first_birth = mean_age_first_birth(eval_idx);
row.eval_median_age_first_birth = median_age_first_birth(eval_idx);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(eval_idx);
row.eval_childless_share_at_50 = childless_share_at_50(eval_idx);
row.eval_avg_birth_rate = avg_birth_rate(eval_idx);
row.eval_avg_first_birth_rate = avg_first_birth_rate(eval_idx);
row.eval_totalvote = totalvote(eval_idx);
row.mean_age_band_excess = mean_age_excess;
row.share30_band_excess = share30_excess;
row.childless_band_excess = childless_excess;
row.mean_age_monotone = double(mean_age_monotone);
row.share30_monotone = double(share30_monotone);
row.birth_rate_monotone = double(birth_rate_monotone);
row.primary_pass = double(mean_age_excess == 0 && share30_excess == 0 && childless_excess == 0);
row.sign_pass = double(sign_pass);
row.crossing_exists = double(crossing.exists);
row.crossing_sign_changes = crossing.sign_change_count;
row.crossing_refined_price = crossing.refined_price;
row.max_crossing_totalvote = max(cross_vote);
row.max_crossing_price = settings.crossing_price_grid(argmax(cross_vote));
row.crossing_gap_to_zero = min(abs(cross_vote));
row.reference_score = reference_score;
row.max_mass_error = max(mass_error);
row.delta_mean_age_vs_baseline = NaN;
row.delta_share30_vs_baseline = NaN;
row.delta_childless_vs_baseline = NaN;
row.delta_vote_vs_baseline = NaN;

path_rows = table( ...
    repmat(spec.candidate_id, n, 1), ...
    repmat(spec.label, n, 1), ...
    repmat(spec.low_type_share, n, 1), ...
    repmat(spec.low_type_phi0, n, 1), ...
    settings.price_grid(:), ...
    avg_birth_rate, ...
    avg_first_birth_rate, ...
    mean_age_first_birth, ...
    median_age_first_birth, ...
    share_first_birth_30_plus, ...
    childless_share_at_50, ...
    totalvote, ...
    debtstock, ...
    mass_error, ...
    'VariableNames', {'candidate_id', 'label', 'low_type_share', 'low_type_phi0', 'a_price', ...
    'avg_birth_rate', 'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'childless_share_at_50', 'totalvote', 'debtstock', 'mass_error'});

crossing_rows = table( ...
    repmat(spec.candidate_id, ncross, 1), ...
    repmat(spec.label, ncross, 1), ...
    repmat(spec.low_type_share, ncross, 1), ...
    repmat(spec.low_type_phi0, ncross, 1), ...
    settings.crossing_price_grid(:), ...
    cross_vote, ...
    cross_birth, ...
    'VariableNames', {'candidate_id', 'label', 'low_type_share', 'low_type_phi0', 'a_price', 'totalvote', 'avg_birth_rate'});
end

function point = evaluate_mixture_point(a_price, rbPos, override_list, weights, eval_age)
nt = numel(weights);
diag_list = cell(nt, 1);
vote_vals = zeros(nt, 1);
debt_vals = zeros(nt, 1);
birth_vals = zeros(nt, 1);
first_birth_vals = zeros(nt, 1);
mass_err_vals = zeros(nt, 1);

for it = 1:nt
    [~, ~, ~, vote_vals(it), debt_vals(it), diagnostics] = SolveSS_fertility([a_price, rbPos], override_list{it});
    diag_list{it} = diagnostics;
    birth_vals(it) = diagnostics.avg_birth_rate;
    first_birth_vals(it) = diagnostics.avg_first_birth_rate;
    mass_err_vals(it) = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));
end

ages = diag_list{1}.ages(:);
first_birth_mass = zeros(numel(ages), 1);
age50_mass = 0;
childless50_mass = 0;
total_age_mass = 0;

for it = 1:nt
    diagnostics = diag_list{it};
    first_birth_mass = first_birth_mass + weights(it) * diagnostics.first_birth_mass_by_age(:);
    age50_idx = find(diagnostics.ages == eval_age, 1);
    age50_mass = age50_mass + weights(it) * diagnostics.age_mass(age50_idx);
    childless50_mass = childless50_mass + weights(it) * diagnostics.age_mass(age50_idx) * diagnostics.parity_dist_by_age(age50_idx, 1);
    total_age_mass = total_age_mass + weights(it) * sum(diagnostics.age_mass(:));
end

first_birth_dist = first_birth_mass ./ max(sum(first_birth_mass), 1e-12);
point = struct();
point.avg_birth_rate = sum(weights(:) .* birth_vals) / sum(weights);
point.avg_first_birth_rate = sum(weights(:) .* first_birth_vals) / sum(weights);
point.mean_age_first_birth = sum(ages .* first_birth_dist);
point.median_age_first_birth = weighted_discrete_median(ages, first_birth_dist);
point.share_first_birth_30_plus = sum(first_birth_dist(ages >= 30));
point.childless_share_at_50 = childless50_mass / max(age50_mass, 1e-12);
point.totalvote = sum(weights(:) .* vote_vals) / sum(weights);
point.debtstock = sum(weights(:) .* debt_vals) / sum(weights);
point.max_mass_error = max(mass_err_vals);
point.support_shares = [ ...
    sum(first_birth_dist(ages >= 25 & ages <= 29)), ...
    sum(first_birth_dist(ages >= 30 & ages <= 34)), ...
    sum(first_birth_dist(ages >= 35 & ages <= 39)), ...
    sum(first_birth_dist(ages >= 40 & ages <= 44))];
point.age_mass_total = total_age_mass;
end

function idx = argmax(x)
[~, idx] = max(x);
end

function crossing = summarize_crossing(price_grid, votes)
sign_change_count = 0;
refined_price = NaN;

for i = 1:(numel(price_grid) - 1)
    if votes(i) == 0
        sign_change_count = sign_change_count + 1;
        if isnan(refined_price)
            refined_price = price_grid(i);
        end
    elseif votes(i + 1) == 0
        sign_change_count = sign_change_count + 1;
        if isnan(refined_price)
            refined_price = price_grid(i + 1);
        end
    elseif sign(votes(i)) ~= sign(votes(i + 1))
        sign_change_count = sign_change_count + 1;
        if isnan(refined_price)
            refined_price = interp1([votes(i), votes(i + 1)], [price_grid(i), price_grid(i + 1)], 0);
        end
    end
end

crossing = struct();
crossing.exists = sign_change_count > 0;
crossing.sign_change_count = sign_change_count;
crossing.refined_price = refined_price;
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

function median_age = weighted_discrete_median(values, weights)
weights = weights(:) ./ max(sum(weights), 1e-12);
cumulative = cumsum(weights);
idx = find(cumulative >= 0.5, 1);
if isempty(idx)
    idx = numel(values);
end
median_age = values(idx);
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'low_type_share', NaN, ...
    'low_type_phi0', NaN, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_median_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_childless_share_at_50', NaN, ...
    'eval_avg_birth_rate', NaN, ...
    'eval_avg_first_birth_rate', NaN, ...
    'eval_totalvote', NaN, ...
    'mean_age_band_excess', NaN, ...
    'share30_band_excess', NaN, ...
    'childless_band_excess', NaN, ...
    'mean_age_monotone', NaN, ...
    'share30_monotone', NaN, ...
    'birth_rate_monotone', NaN, ...
    'primary_pass', NaN, ...
    'sign_pass', NaN, ...
    'crossing_exists', NaN, ...
    'crossing_sign_changes', NaN, ...
    'crossing_refined_price', NaN, ...
    'max_crossing_totalvote', NaN, ...
    'max_crossing_price', NaN, ...
    'crossing_gap_to_zero', NaN, ...
    'reference_score', NaN, ...
    'max_mass_error', NaN, ...
    'delta_mean_age_vs_baseline', NaN, ...
    'delta_share30_vs_baseline', NaN, ...
    'delta_childless_vs_baseline', NaN, ...
    'delta_vote_vs_baseline', NaN);
end

function write_report(report_path, candidates_table, path_table, crossing_table, target_ranges)
baseline = candidates_table(1, :);
baseline_row = candidates_table(candidates_table.candidate_id == 1, :);
if ~isempty(baseline_row)
    baseline = baseline_row(1, :);
end

for i = 1:height(candidates_table)
    candidates_table.delta_mean_age_vs_baseline(i) = candidates_table.eval_mean_age_first_birth(i) - baseline.eval_mean_age_first_birth;
    candidates_table.delta_share30_vs_baseline(i) = candidates_table.eval_share_first_birth_30_plus(i) - baseline.eval_share_first_birth_30_plus;
    candidates_table.delta_childless_vs_baseline(i) = candidates_table.eval_childless_share_at_50(i) - baseline.eval_childless_share_at_50;
    candidates_table.delta_vote_vs_baseline(i) = candidates_table.eval_totalvote(i) - baseline.eval_totalvote;
end

fid = fopen(report_path, 'w');
fprintf(fid, '# Annual latent entry-type smoke test\n\n');
fprintf(fid, 'This smoke test keeps the current usable annual row fixed and adds a small permanent low-entry type with lower first-birth utility only. Cohort weights stay fixed at the annual benchmark profile.\n\n');

fprintf(fid, '## Primary targets\n\n');
fprintf(fid, '| Object | Reference | Lower | Upper |\n');
fprintf(fid, '|---|---:|---:|---:|\n');
targets = target_ranges.primary;
for i = 1:numel(targets)
    fprintf(fid, '| %s | `%.4f` | `%.4f` | `%.4f` |\n', ...
        char(targets(i).name), targets(i).reference, targets(i).lower, targets(i).upper);
end

fprintf(fid, '\n## Main read\n\n');
fprintf(fid, '- Baseline usable annual row at `a_price = 2.00`: mean age `%.2f`, share first births age `30+` `%.3f`, childless at `50` `%.3f`, vote `%.3f`.\n', ...
    baseline.eval_mean_age_first_birth, baseline.eval_share_first_birth_30_plus, baseline.eval_childless_share_at_50, baseline.eval_totalvote);

best_childless_idx = argmax(candidates_table.delta_childless_vs_baseline);
best_childless = candidates_table(best_childless_idx, :);
fprintf(fid, '- Largest childlessness gain versus baseline: `%s` -> childless change `%.3f`, mean-age change `%.2f`, share-30+ change `%.3f`, vote change `%.3f`.\n', ...
    char(best_childless.label), best_childless.delta_childless_vs_baseline, best_childless.delta_mean_age_vs_baseline, best_childless.delta_share30_vs_baseline, best_childless.delta_vote_vs_baseline);

fprintf(fid, '\n## Candidate summary\n\n');
fprintf(fid, '| Rank | Candidate | Mean age | Share 30+ | Childless @50 | Vote @2.0 | d mean age | d share 30+ | d childless | Crossing |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:min(height(candidates_table), 6)
    row = candidates_table(i, :);
    crossing_text = 'none';
    if row.crossing_exists == 1
        if ~isnan(row.crossing_refined_price)
            crossing_text = sprintf('~%.3f', row.crossing_refined_price);
        else
            crossing_text = sprintf('%d sign changes', row.crossing_sign_changes);
        end
    end
    fprintf(fid, '| %d | %s | `%.2f` | `%.3f` | `%.3f` | `%.3f` | `%+.2f` | `%+.3f` | `%+.3f` | %s |\n', ...
        i, escape_pipes(char(row.label)), row.eval_mean_age_first_birth, row.eval_share_first_birth_30_plus, ...
        row.eval_childless_share_at_50, row.eval_totalvote, row.delta_mean_age_vs_baseline, ...
        row.delta_share30_vs_baseline, row.delta_childless_vs_baseline, crossing_text);
end

fprintf(fid, '\n## Paths\n\n');
candidate_ids = unique(path_table.candidate_id, 'stable');
for i = 1:numel(candidate_ids)
    cid = candidate_ids(i);
    row = candidates_table(candidates_table.candidate_id == cid, :);
    subset = path_table(path_table.candidate_id == cid, :);
    fprintf(fid, '### %s\n\n', char(row.label));
    fprintf(fid, '| Price | Mean age | Share 30+ | Childless @50 | Avg birth rate | Vote |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|---:|\n');
    for j = 1:height(subset)
        fprintf(fid, '| `%.2f` | `%.2f` | `%.3f` | `%.3f` | `%.4f` | `%.3f` |\n', ...
            subset.a_price(j), subset.mean_age_first_birth(j), subset.share_first_birth_30_plus(j), ...
            subset.childless_share_at_50(j), subset.avg_birth_rate(j), subset.totalvote(j));
    end
    fprintf(fid, '\n');
end

fprintf(fid, '## Crossing grid\n\n');
fprintf(fid, '| Candidate | Max vote | Max-vote price | Gap to zero |\n');
fprintf(fid, '|---|---:|---:|---:|\n');
for i = 1:min(height(candidates_table), 6)
    row = candidates_table(i, :);
    fprintf(fid, '| %s | `%.3f` | `%.2f` | `%.3f` |\n', ...
        escape_pipes(char(row.label)), row.max_crossing_totalvote, row.max_crossing_price, row.crossing_gap_to_zero);
end

fclose(fid);
end

function out = escape_pipes(txt)
out = strrep(txt, '|', '&#124;');
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end
