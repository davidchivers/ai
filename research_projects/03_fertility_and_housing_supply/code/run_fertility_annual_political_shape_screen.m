function run_fertility_annual_political_shape_screen(mode)
% run_fertility_annual_political_shape_screen.m
%
% Narrow annual follow-up after the scalar cohort-blend ridge proved
% numerically fragile. This screen keeps the fertility block fixed and
% replaces the scalar blend with age-selective cohort shapes that flatten
% the young-heavy annual profile by shifting mass toward later-life owners
% without uniformly boosting every age.
%
% Usage:
%   run_fertility_annual_political_shape_screen
%   run_fertility_annual_political_shape_screen('smoke')
%   run_fertility_annual_political_shape_screen('fast')
%   run_fertility_annual_political_shape_screen('confirm')
%
% Outputs:
%   notes/build/fertility_annual_political_shape_screen_candidates.csv
%   notes/build/fertility_annual_political_shape_screen_candidate_paths.csv
%   notes/build/fertility_annual_political_shape_screen_crossing_paths.csv
%   notes/build/fertility_annual_political_shape_screen_target_ranges.csv
%   notes/build/fertility_annual_political_shape_screen.md

if nargin < 1 || isempty(mode)
    mode = 'smoke';
end

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
settings = build_settings(mode, cfg);
ensure_transition_matrix(settings.base_overrides.transition_matrix_file);

target_table = build_target_table(cfg.target_ranges);
writetable(target_table, fullfile(out_dir, 'fertility_annual_political_shape_screen_target_ranges.csv'));

candidate_specs = build_candidate_specs(settings);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();
crossing_path_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual political-shape candidate %d: %s ===\n', spec.candidate_id, char(spec.label));
    [candidate_rows(i), tmp_paths, tmp_crossing_paths] = evaluate_candidate(spec, settings, cfg);
    path_table = [path_table; tmp_paths]; %#ok<AGROW>
    crossing_path_table = [crossing_path_table; tmp_crossing_paths]; %#ok<AGROW>
    checkpoint_outputs(out_dir, settings, target_table, candidate_rows(1:i), path_table, crossing_path_table);
end

checkpoint_outputs(out_dir, settings, target_table, candidate_rows, path_table, crossing_path_table);
end

function settings = build_settings(mode, cfg)
settings = struct();
settings.mode = lower(string(mode));
settings.eval_price = cfg.eval_price;
settings.eval_age = cfg.eval_age;
settings.ages = cfg.annual_ages;
settings.current_age_weights = cfg.target_first_birth_age_share_annual;
settings.current_cohort_weights = cfg.overrides.cohort_weights_by_age;
settings.vote_scale = 100.0;

settings.extra_front_loaded_realized = repelem([1.00, 0.27, 0.045, 0.010], 5);
settings.ka_annual = annualize_adjustment_cost(cfg.ka_five_year, 5);
settings.rent_markup_mid = 0.01;

base_overrides = cfg.overrides;
switch char(settings.mode)
    case 'confirm'
        base_overrides.I = 16;
        base_overrides.J = 12;
        settings.price_grid = [1.50, 2.00, 2.50];
        settings.crossing_price_grid = [2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0];
        settings.shape_codes = ["old_tail_bridge"];
        settings.theta_r_grid = [0.40];
        settings.housingmax_grid = [15.25];
    case 'fast'
        base_overrides.I = 16;
        base_overrides.J = 10;
        settings.price_grid = [1.50, 2.00, 2.50];
        settings.crossing_price_grid = [2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0];
        settings.shape_codes = ["old_tail_bridge_plus", "old_tail_bridge_plus2"];
        settings.theta_r_grid = [0.45, 0.43];
        settings.housingmax_grid = [15.25];
    otherwise
        base_overrides.I = 16;
        base_overrides.J = 10;
        settings.price_grid = [1.50, 2.00, 2.50];
        settings.crossing_price_grid = [2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0];
        settings.shape_codes = ["old_tail_smooth", "old_tail_bridge", "old_tail_mid", "old_tail_strong"];
        settings.theta_r_grid = [0.45, 0.40];
        settings.housingmax_grid = [15.0];
end

settings.base_overrides = base_overrides;
end

function specs = build_candidate_specs(settings)
shape_catalog = build_shape_catalog(settings);
spec_template = build_spec(NaN, "", "", [], NaN, NaN, NaN, NaN);
specs = repmat(spec_template, 0, 1);
idx = 0;

for is = 1:numel(settings.shape_codes)
    shape = shape_catalog.(char(settings.shape_codes(is)));
    for it = 1:numel(settings.theta_r_grid)
        for ih = 1:numel(settings.housingmax_grid)
            idx = idx + 1;
            theta_r_value = settings.theta_r_grid(it);
            housingmax_value = settings.housingmax_grid(ih);
            label = sprintf('%s | theta_r %.2f | housingmax %.1f', ...
                char(shape.label), theta_r_value, housingmax_value);
            specs(idx) = build_spec( ...
                idx, ...
                label, ...
                string(shape.code), ...
                shape.weights, ...
                theta_r_value, ...
                housingmax_value, ...
                settings.ka_annual, ...
                settings.rent_markup_mid);
        end
    end
end
end

function shape_catalog = build_shape_catalog(settings)
base = settings.current_cohort_weights(:)';
ages = settings.ages(:)';

shape_catalog = struct();
shape_catalog.old_tail_smooth = struct( ...
    'code', "old_tail_smooth", ...
    'label', "older-tail smooth shape", ...
    'weights', build_shape_weights(base, ages, 0.82, 0.93, 0.99, 1.12, 1.45));
shape_catalog.old_tail_bridge = struct( ...
    'code', "old_tail_bridge", ...
    'label', "older-tail bridge shape", ...
    'weights', build_shape_weights(base, ages, 0.78, 0.92, 0.97, 1.20, 1.80));
shape_catalog.old_tail_bridge_plus = struct( ...
    'code', "old_tail_bridge_plus", ...
    'label', "older-tail bridge-plus shape", ...
    'weights', build_shape_weights(base, ages, 0.775, 0.918, 0.97, 1.215, 1.87));
shape_catalog.old_tail_bridge_plus2 = struct( ...
    'code', "old_tail_bridge_plus2", ...
    'label', "older-tail bridge-plus2 shape", ...
    'weights', build_shape_weights(base, ages, 0.772, 0.916, 0.97, 1.220, 1.92));
shape_catalog.old_tail_mid = struct( ...
    'code', "old_tail_mid", ...
    'label', "older-tail mid shape", ...
    'weights', build_shape_weights(base, ages, 0.76, 0.91, 0.97, 1.25, 2.05));
shape_catalog.old_tail_strong = struct( ...
    'code', "old_tail_strong", ...
    'label', "older-tail strong shape", ...
    'weights', build_shape_weights(base, ages, 0.74, 0.90, 0.96, 1.32, 2.35));
end

function weights = build_shape_weights(base, ages, young_mult, prime_mult, mature_mult, older_mult, oldest_mult)
mult = oldest_mult * ones(size(base));
mult(ages >= 25 & ages <= 34) = young_mult;
mult(ages >= 35 & ages <= 49) = prime_mult;
mult(ages >= 50 & ages <= 59) = mature_mult;
mult(ages >= 60 & ages <= 69) = older_mult;
mult(ages >= 70) = oldest_mult;
weights = base .* mult;
weights = weights ./ mean(weights);
end

function spec = build_spec(candidate_id, label, shape_code, cohort_weights, theta_r_value, housingmax_value, ka_value, rent_markup_value)
spec = struct();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.shape_code = string(shape_code);
spec.cohort_weights = cohort_weights(:)';
spec.theta_r_value = theta_r_value;
spec.housingmax_value = housingmax_value;
spec.ka_value = ka_value;
spec.rent_markup_value = rent_markup_value;
end

function [row, path_rows, crossing_path_rows] = evaluate_candidate(spec, settings, cfg)
overrides = settings.base_overrides;
overrides.birth_utility_by_parity = [1.120, 1.240, 1.170];
overrides.child_utility = 0.020;
overrides.birth_cost = 0.050;
overrides.birth_price_coeff = 0.16;
overrides.lambda_crowd = 0.10;
overrides.birth_age_weights = settings.current_age_weights;
overrides.realized_birth_weights = ones(size(settings.current_age_weights));
overrides.first_birth_realized_weights = settings.extra_front_loaded_realized;
overrides.cohort_weights_by_age = spec.cohort_weights;
overrides.theta_r = spec.theta_r_value;
overrides.housingmax = spec.housingmax_value;
overrides.ka = spec.ka_value;
overrides.rent_markup = spec.rent_markup_value;

n = numel(settings.price_grid);
avg_birth_rate = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
median_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
mass_error = NaN(n, 1);
totalvote = NaN(n, 1);
debtstock = NaN(n, 1);

eval_diagnostics = [];

for i = 1:n
    point = evaluate_point(settings.price_grid(i), cfg.rbPos, overrides);
    avg_birth_rate(i) = point.avg_birth_rate;
    avg_first_birth_rate(i) = point.avg_first_birth_rate;
    mean_age_first_birth(i) = point.mean_age_first_birth;
    median_age_first_birth(i) = point.median_age_first_birth;
    share_first_birth_30_plus(i) = point.share_first_birth_30_plus;
    mass_error(i) = max(abs(point.mass_post_policy - point.mass_pre_policy));
    totalvote(i) = point.totalvote;
    debtstock(i) = point.debtstock;
    if abs(settings.price_grid(i) - settings.eval_price) < 1e-12
        eval_diagnostics = point.diagnostics;
    end
end

[crossing_results, crossing] = ClearMarkets_fertility(settings.crossing_price_grid, cfg.rbPos, overrides);
support_shares = summarize_first_birth_bins(eval_diagnostics);

childless_share_at_50 = NaN;
if ~isempty(eval_diagnostics)
    age_idx = find(eval_diagnostics.ages == settings.eval_age, 1);
    parity = eval_diagnostics.parity_dist_by_age(age_idx, :);
    childless_share_at_50 = parity(1);
end

eval_idx = find(abs(settings.price_grid - settings.eval_price) < 1e-12, 1);
annual_scores = score_annual_fertility_targets( ...
    cfg.target_ranges, ...
    mean_age_first_birth(eval_idx), ...
    share_first_birth_30_plus(eval_idx), ...
    childless_share_at_50, ...
    support_shares);
mean_age_excess = annual_scores.mean_age_excess;
share30_excess = annual_scores.share30_excess;
childless_excess = annual_scores.childless_excess;
support_excesses = annual_scores.shape_excesses;
support_score = annual_scores.shape_score;
primary_score = annual_scores.primary_score;

mean_age_monotone = all(diff(mean_age_first_birth) >= -1e-9);
share30_monotone = all(diff(share_first_birth_30_plus) >= -1e-9);
birth_rate_monotone = all(diff(avg_birth_rate) <= 1e-9);
overall_direction_ok = mean_age_first_birth(end) >= mean_age_first_birth(1) && ...
    share_first_birth_30_plus(end) >= share_first_birth_30_plus(1) && ...
    avg_birth_rate(end) <= avg_birth_rate(1);

sign_penalty = 0;
sign_penalty = sign_penalty + 2.0 * double(~mean_age_monotone);
sign_penalty = sign_penalty + 2.0 * double(~share30_monotone);
sign_penalty = sign_penalty + 2.0 * double(~birth_rate_monotone);
sign_penalty = sign_penalty + 2.0 * double(~overall_direction_ok);

[max_crossing_vote, max_crossing_idx] = max(crossing_results.totalvote);
max_crossing_price = crossing_results.a_price(max_crossing_idx);
vote_shortfall = max(0, -max_crossing_vote) / settings.vote_scale;
eval_vote_shortfall = max(0, -totalvote(eval_idx)) / settings.vote_scale;

if crossing.exists && crossing.is_unique && ~isnan(crossing.refined_price)
    crossing_penalty = 0.0;
elseif crossing.exists
    crossing_penalty = 1.0;
else
    crossing_penalty = 0.25;
end

max_mass_error = max([mass_error; crossing_results.mass_error]);
mass_penalty = 1e12 * max(max_mass_error - 1e-8, 0);

score = 4.0 * primary_score + sign_penalty + ...
    vote_shortfall + 0.25 * eval_vote_shortfall + crossing_penalty + mass_penalty;

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = spec.label;
row.shape_code = spec.shape_code;
row.theta_r_value = spec.theta_r_value;
row.housingmax_value = spec.housingmax_value;
row.ka_value = spec.ka_value;
row.rent_markup_value = spec.rent_markup_value;
row.eval_avg_birth_rate = avg_birth_rate(eval_idx);
row.eval_avg_first_birth_rate = avg_first_birth_rate(eval_idx);
row.eval_mean_age_first_birth = mean_age_first_birth(eval_idx);
row.eval_median_age_first_birth = median_age_first_birth(eval_idx);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(eval_idx);
row.eval_childless_share_at_50 = childless_share_at_50;
row.eval_share_first_birth_25_29 = support_shares(1);
row.eval_share_first_birth_30_34 = support_shares(2);
row.eval_share_first_birth_35_39 = support_shares(3);
row.eval_share_first_birth_40_44_plus = support_shares(4);
row.eval_totalvote = totalvote(eval_idx);
row.eval_debtstock = debtstock(eval_idx);
row.mean_age_band_excess = mean_age_excess;
row.share30_band_excess = share30_excess;
row.childless_band_excess = childless_excess;
row.support_band_excess = support_score;
row.mean_age_monotone = double(mean_age_monotone);
row.share30_monotone = double(share30_monotone);
row.birth_rate_monotone = double(birth_rate_monotone);
row.overall_direction_ok = double(overall_direction_ok);
row.primary_pass = double(annual_scores.primary_pass);
row.support_pass = double(annual_scores.shape_pass);
row.sign_pass = double(sign_penalty == 0);
row.crossing_exists = double(crossing.exists);
row.crossing_is_unique = double(crossing.is_unique);
row.crossing_sign_changes = crossing.sign_change_count;
row.crossing_refined_price = crossing.refined_price;
row.max_crossing_totalvote = max_crossing_vote;
row.max_crossing_price = max_crossing_price;
row.crossing_gap_to_zero = max(0, -max_crossing_vote);
row.max_mass_error = max_mass_error;
row.score = score;

path_rows = table( ...
    repmat(spec.candidate_id, n, 1), ...
    repmat(spec.label, n, 1), ...
    repmat(spec.shape_code, n, 1), ...
    repmat(spec.theta_r_value, n, 1), ...
    repmat(spec.housingmax_value, n, 1), ...
    settings.price_grid(:), ...
    avg_birth_rate, ...
    avg_first_birth_rate, ...
    mean_age_first_birth, ...
    median_age_first_birth, ...
    share_first_birth_30_plus, ...
    totalvote, ...
    debtstock, ...
    mass_error, ...
    'VariableNames', {'candidate_id', 'label', 'shape_code', 'theta_r_value', 'housingmax_value', ...
    'a_price', 'avg_birth_rate', 'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'totalvote', 'debtstock', 'mass_error'});

crossing_path_rows = table( ...
    repmat(spec.candidate_id, height(crossing_results), 1), ...
    repmat(spec.label, height(crossing_results), 1), ...
    repmat(spec.shape_code, height(crossing_results), 1), ...
    repmat(spec.theta_r_value, height(crossing_results), 1), ...
    repmat(spec.housingmax_value, height(crossing_results), 1), ...
    crossing_results.a_price, ...
    crossing_results.totalvote, ...
    crossing_results.debtstock, ...
    crossing_results.mass_error, ...
    crossing_results.avg_birth_rate, ...
    'VariableNames', {'candidate_id', 'label', 'shape_code', 'theta_r_value', 'housingmax_value', ...
    'a_price', 'totalvote', 'debtstock', 'mass_error', 'avg_birth_rate'});
end

function point = evaluate_point(a_price, rbPos, overrides)
[distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([a_price, rbPos], overrides);
point = struct();
point.distance = distance;
point.totalvote = totalvote;
point.debtstock = debtstock;
point.avg_birth_rate = diagnostics.avg_birth_rate;
point.avg_first_birth_rate = diagnostics.avg_first_birth_rate;
point.mean_age_first_birth = diagnostics.mean_age_first_birth;
point.median_age_first_birth = diagnostics.median_age_first_birth;
point.share_first_birth_30_plus = diagnostics.share_first_birth_30_plus;
point.mass_pre_policy = diagnostics.mass_pre_policy;
point.mass_post_policy = diagnostics.mass_post_policy;
point.diagnostics = diagnostics;
end

function support_shares = summarize_first_birth_bins(diagnostics)
support_shares = NaN(1, 4);
if isempty(diagnostics)
    return;
end
ages = diagnostics.ages(:);
dist = diagnostics.first_birth_age_dist(:);
support_shares(1) = sum(dist(ages >= 25 & ages <= 29));
support_shares(2) = sum(dist(ages >= 30 & ages <= 34));
support_shares(3) = sum(dist(ages >= 35 & ages <= 39));
support_shares(4) = sum(dist(ages >= 40 & ages <= 44));
end

function target = get_target(ranges, name)
all_targets = [ranges.primary(:); ranges.support(:); ranges.validation];
idx = find(strcmp(string({all_targets.name}), string(name)), 1);
if isempty(idx)
    error('Could not find target range "%s".', name);
end
target = all_targets(idx);
end

function value = normalized_band_excess(x, target)
if isnan(x)
    value = 1e6;
    return;
end
if x < target.lower
    excess = target.lower - x;
elseif x > target.upper
    excess = x - target.upper;
else
    excess = 0;
end
width = max(target.upper - target.lower, 1e-8);
value = excess / width;
end

function target_table = build_target_table(ranges)
all_targets = [ranges.primary(:); ranges.support(:); ranges.validation];
target_table = struct2table(all_targets);
target_table = target_table(:, {'name', 'role', 'unit', 'reference', 'lower', 'upper', 'source', 'comment'});
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'shape_code', "", ...
    'theta_r_value', NaN, ...
    'housingmax_value', NaN, ...
    'ka_value', NaN, ...
    'rent_markup_value', NaN, ...
    'eval_avg_birth_rate', NaN, ...
    'eval_avg_first_birth_rate', NaN, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_median_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_childless_share_at_50', NaN, ...
    'eval_share_first_birth_25_29', NaN, ...
    'eval_share_first_birth_30_34', NaN, ...
    'eval_share_first_birth_35_39', NaN, ...
    'eval_share_first_birth_40_44_plus', NaN, ...
    'eval_totalvote', NaN, ...
    'eval_debtstock', NaN, ...
    'mean_age_band_excess', NaN, ...
    'share30_band_excess', NaN, ...
    'childless_band_excess', NaN, ...
    'support_band_excess', NaN, ...
    'mean_age_monotone', NaN, ...
    'share30_monotone', NaN, ...
    'birth_rate_monotone', NaN, ...
    'overall_direction_ok', NaN, ...
    'primary_pass', NaN, ...
    'support_pass', NaN, ...
    'sign_pass', NaN, ...
    'crossing_exists', NaN, ...
    'crossing_is_unique', NaN, ...
    'crossing_sign_changes', NaN, ...
    'crossing_refined_price', NaN, ...
    'max_crossing_totalvote', NaN, ...
    'max_crossing_price', NaN, ...
    'crossing_gap_to_zero', NaN, ...
    'max_mass_error', NaN, ...
    'score', NaN);
end

function checkpoint_outputs(out_dir, settings, target_table, candidate_rows, path_table, crossing_path_table)
candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'score', 'primary_pass', 'crossing_is_unique', 'crossing_gap_to_zero'}, ...
    {'ascend', 'descend', 'descend', 'ascend'});

writetable(candidates_table, fullfile(out_dir, 'fertility_annual_political_shape_screen_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_political_shape_screen_candidate_paths.csv'));
writetable(crossing_path_table, fullfile(out_dir, 'fertility_annual_political_shape_screen_crossing_paths.csv'));

write_report(fullfile(out_dir, 'fertility_annual_political_shape_screen.md'), settings, target_table, candidates_table, path_table, crossing_path_table);
end

function write_report(report_path, settings, target_table, candidates_table, path_table, crossing_path_table)
fid = fopen(report_path, 'w');
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# fertility annual political shape screen\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- solver grid: `I = %d`, `J = %d`\n', settings.base_overrides.I, settings.base_overrides.J);
fprintf(fid, '- evaluation price: `%.2f`\n', settings.eval_price);
fprintf(fid, '- crossing grid: `%s`\n\n', format_price_grid(settings.crossing_price_grid));

fprintf(fid, 'This screen replaces the scalar cohort blend with age-selective cohort shapes that flatten the annual cohort profile by downweighting ages 25-49 and selectively boosting later-life owners, especially the 60+ tail.\n\n');

fprintf(fid, '## target ranges\n\n');
fprintf(fid, '| target | role | lower | upper |\n');
fprintf(fid, '|---|---:|---:|---:|\n');
for i = 1:height(target_table)
    fprintf(fid, '| %s | %s | %.3f | %.3f |\n', ...
        char(target_table.name(i)), char(target_table.role(i)), target_table.lower(i), target_table.upper(i));
end

fprintf(fid, '\n## top candidates\n\n');
fprintf(fid, '| rank | label | mean age | share 30+ | childless 50 | eval vote | max crossing vote | max crossing price | unique crossing | sign changes | score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
top_n = min(10, height(candidates_table));
for i = 1:top_n
    label_text = escape_pipes(char(candidates_table.label(i)));
    fprintf(fid, '| %d | %s | %.3f | %.3f | %.3f | %.3f | %.3f | %.2f | %d | %d | %.4f |\n', ...
        i, label_text, candidates_table.eval_mean_age_first_birth(i), ...
        candidates_table.eval_share_first_birth_30_plus(i), candidates_table.eval_childless_share_at_50(i), ...
        candidates_table.eval_totalvote(i), candidates_table.max_crossing_totalvote(i), ...
        candidates_table.max_crossing_price(i), candidates_table.crossing_is_unique(i), ...
        candidates_table.crossing_sign_changes(i), candidates_table.score(i));
end

if ~isempty(candidates_table)
    best_id = candidates_table.candidate_id(1);
    best_paths = path_table(path_table.candidate_id == best_id, :);
    best_crossing_paths = crossing_path_table(crossing_path_table.candidate_id == best_id, :);
    fprintf(fid, '\n## best candidate path\n\n');
    fprintf(fid, '| price | mean age | share 30+ | avg birth rate | vote |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|\n');
    for i = 1:height(best_paths)
        fprintf(fid, '| %.2f | %.3f | %.3f | %.6f | %.3f |\n', ...
            best_paths.a_price(i), best_paths.mean_age_first_birth(i), ...
            best_paths.share_first_birth_30_plus(i), best_paths.avg_birth_rate(i), best_paths.totalvote(i));
    end

    fprintf(fid, '\n## best candidate crossing grid\n\n');
    fprintf(fid, '| price | vote | avg birth rate |\n');
    fprintf(fid, '|---:|---:|---:|\n');
    for i = 1:height(best_crossing_paths)
        fprintf(fid, '| %.2f | %.3f | %.6f |\n', ...
            best_crossing_paths.a_price(i), best_crossing_paths.totalvote(i), best_crossing_paths.avg_birth_rate(i));
    end
end
end

function text = escape_pipes(text)
text = strrep(text, '|', '\|');
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end

function text = format_price_grid(grid)
parts = arrayfun(@(x) sprintf('%.2f', x), grid, 'UniformOutput', false);
text = strjoin(parts, ', ');
end

function r_annual = annualize_net_rate(r_period, years_per_period)
r_annual = (1 + r_period) .^ (1 / years_per_period) - 1;
end

function ka_annual = annualize_adjustment_cost(ka_period, years_per_period)
ka_annual = 1 - (1 - ka_period) .^ (1 / years_per_period);
end
