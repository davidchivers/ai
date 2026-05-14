function run_fertility_annual_broad_calibration_screen(mode)
% run_fertility_annual_broad_calibration_screen.m
%
% Annual fertility-first recalibration screen using wide screening bands
% rather than tight point targets. The goal is to reject obviously wrong
% annual parameterizations, not to force simulation-style exact fit.
%
% Usage:
%   run_fertility_annual_broad_calibration_screen
%   run_fertility_annual_broad_calibration_screen('smoke')
%   run_fertility_annual_broad_calibration_screen('fast')
%   run_fertility_annual_broad_calibration_screen('full')
%
% Outputs:
%   notes/build/fertility_annual_broad_calibration_screen_candidates.csv
%   notes/build/fertility_annual_broad_calibration_screen_candidate_paths.csv
%   notes/build/fertility_annual_broad_calibration_screen_target_ranges.csv
%   notes/build/fertility_annual_broad_calibration_screen.md

if nargin < 1 || isempty(mode)
    mode = 'fast';
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
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end

cfg = fertility_benchmark_annual_config();
settings = build_settings(mode, cfg);
ensure_transition_matrix(settings.base_overrides.transition_matrix_file);

target_table = build_target_table(cfg.target_ranges);
writetable(target_table, fullfile(out_dir, 'fertility_annual_broad_calibration_screen_target_ranges.csv'));

candidate_specs = build_candidate_specs(settings, cfg);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual fertility broad-band candidate %d: %s ===\n', spec.candidate_id, char(spec.label));
    [candidate_rows(i), tmp_paths] = evaluate_candidate(spec, settings, cfg);
    path_table = [path_table; tmp_paths]; %#ok<AGROW>
    checkpoint_outputs(out_dir, settings, target_table, candidate_rows(1:i), path_table);
end

checkpoint_outputs(out_dir, settings, target_table, candidate_rows, path_table);
end

function settings = build_settings(mode, cfg)
settings = struct();
settings.mode = lower(string(mode));
settings.eval_price = cfg.eval_price;
settings.eval_age = cfg.eval_age;

base_overrides = cfg.overrides;
switch char(settings.mode)
    case 'smoke'
        base_overrides.I = 20;
        base_overrides.J = 6;
        settings.price_grid = [1.75, 2.00, 2.25];
        settings.market_price_grid = [1.50, 2.00, 2.50];
        settings.phi0_grid = [1.6, 2.6];
        settings.birth_price_coeff_grid = [0.04];
        settings.lambda_crowd_grid = [0.00, 0.08];
        settings.birth_cost_grid = [0.00];
        settings.child_utility_grid = [0.00];
    case 'fast'
        base_overrides.I = 32;
        base_overrides.J = 10;
        settings.price_grid = [1.50, 2.00, 2.50, 3.00];
        settings.market_price_grid = 1.25:0.25:3.25;
        settings.phi0_grid = [1.4, 2.0, 2.6, 3.2];
        settings.birth_price_coeff_grid = [0.03, 0.08, 0.16];
        settings.lambda_crowd_grid = [0.00, 0.04, 0.10];
        settings.birth_cost_grid = [0.00, 0.05];
        settings.child_utility_grid = [0.00, 0.02];
    case 'full'
        base_overrides.I = cfg.overrides.I;
        base_overrides.J = cfg.overrides.J;
        settings.price_grid = [1.50, 1.75, 2.00, 2.50, 3.00];
        settings.market_price_grid = cfg.market_price_grid;
        settings.phi0_grid = [1.4, 2.0, 2.6, 3.2];
        settings.birth_price_coeff_grid = [0.02, 0.05, 0.10, 0.18];
        settings.lambda_crowd_grid = [0.00, 0.03, 0.07, 0.12];
        settings.birth_cost_grid = [0.00, 0.03, 0.06];
        settings.child_utility_grid = [0.00, 0.02];
    otherwise
        error('Unknown mode "%s". Use "smoke", "fast", or "full".', mode);
end

settings.base_overrides = base_overrides;
end

function specs = build_candidate_specs(settings, cfg)
spec_template = build_spec(NaN, "", NaN, [NaN, NaN, NaN], NaN, NaN, NaN, NaN);
specs = repmat(spec_template, 0, 1);
idx = 0;

idx = idx + 1;
specs(idx) = build_spec( ...
    idx, "current_annualized_benchmark", ...
    cfg.overrides.birth_utility_by_parity(1), ...
    cfg.overrides.birth_utility_by_parity, ...
    cfg.overrides.child_utility, ...
    cfg.overrides.birth_cost, ...
    cfg.overrides.birth_price_coeff, ...
    cfg.overrides.lambda_crowd);

for ip = 1:numel(settings.phi0_grid)
    phi0 = settings.phi0_grid(ip);
    birth_utility_by_parity = [phi0, phi0 + 0.12, phi0 + 0.05];
    for iu = 1:numel(settings.child_utility_grid)
        for ic = 1:numel(settings.birth_cost_grid)
            for ik = 1:numel(settings.birth_price_coeff_grid)
                for il = 1:numel(settings.lambda_crowd_grid)
                    idx = idx + 1;
                    specs(idx) = build_spec( ...
                        idx, ...
                        sprintf('phi0 %.2f | child %.2f | cost %.2f | kappa %.2f | lambda %.2f', ...
                        phi0, settings.child_utility_grid(iu), settings.birth_cost_grid(ic), ...
                        settings.birth_price_coeff_grid(ik), settings.lambda_crowd_grid(il)), ...
                        phi0, ...
                        birth_utility_by_parity, ...
                        settings.child_utility_grid(iu), ...
                        settings.birth_cost_grid(ic), ...
                        settings.birth_price_coeff_grid(ik), ...
                        settings.lambda_crowd_grid(il));
                end
            end
        end
    end
end
end

function spec = build_spec(candidate_id, label, phi0, birth_utility_by_parity, child_utility, birth_cost, birth_price_coeff, lambda_crowd)
spec = struct();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.phi0 = phi0;
spec.birth_utility_by_parity = birth_utility_by_parity;
spec.child_utility = child_utility;
spec.birth_cost = birth_cost;
spec.birth_price_coeff = birth_price_coeff;
spec.lambda_crowd = lambda_crowd;
end

function [row, path_rows] = evaluate_candidate(spec, settings, cfg)
overrides = settings.base_overrides;
overrides.birth_utility_by_parity = spec.birth_utility_by_parity;
overrides.child_utility = spec.child_utility;
overrides.birth_cost = spec.birth_cost;
overrides.birth_price_coeff = spec.birth_price_coeff;
overrides.lambda_crowd = spec.lambda_crowd;

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

[~, crossing] = ClearMarkets_fertility(settings.market_price_grid, cfg.rbPos, overrides);
support_shares = summarize_first_birth_bins(eval_diagnostics);

childless_share_at_50 = NaN;
parity1 = NaN;
parity2 = NaN;
parity3plus = NaN;
if ~isempty(eval_diagnostics)
    age_idx = find(eval_diagnostics.ages == settings.eval_age, 1);
    parity = eval_diagnostics.parity_dist_by_age(age_idx, :);
    childless_share_at_50 = parity(1);
    if numel(parity) >= 2, parity1 = parity(2); end
    if numel(parity) >= 3, parity2 = parity(3); end
    if numel(parity) >= 4, parity3plus = parity(4); end
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

crossing_penalty = 0.25 * double(~crossing.exists || ~crossing.is_unique || isnan(crossing.refined_price));
mass_penalty = 1e12 * max(max(mass_error) - 1e-8, 0);

score = primary_score + sign_penalty + crossing_penalty + mass_penalty;

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = spec.label;
row.birth_utility_1 = spec.birth_utility_by_parity(1);
row.birth_utility_2 = spec.birth_utility_by_parity(2);
row.birth_utility_3 = spec.birth_utility_by_parity(3);
row.child_utility = spec.child_utility;
row.birth_cost = spec.birth_cost;
row.birth_price_coeff = spec.birth_price_coeff;
row.lambda_crowd = spec.lambda_crowd;
row.eval_avg_birth_rate = avg_birth_rate(settings.price_grid == settings.eval_price);
row.eval_avg_first_birth_rate = avg_first_birth_rate(settings.price_grid == settings.eval_price);
row.eval_mean_age_first_birth = mean_age_first_birth(settings.price_grid == settings.eval_price);
row.eval_median_age_first_birth = median_age_first_birth(settings.price_grid == settings.eval_price);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(settings.price_grid == settings.eval_price);
row.eval_childless_share_at_50 = childless_share_at_50;
row.eval_parity1_share_at_50 = parity1;
row.eval_parity2_share_at_50 = parity2;
row.eval_parity3plus_share_at_50 = parity3plus;
row.eval_share_first_birth_25_29 = support_shares(1);
row.eval_share_first_birth_30_34 = support_shares(2);
row.eval_share_first_birth_35_39 = support_shares(3);
row.eval_share_first_birth_40_44_plus = support_shares(4);
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
row.max_mass_error = max(mass_error);
row.score = score;

path_rows = table( ...
    repmat(spec.candidate_id, n, 1), ...
    repmat(spec.label, n, 1), ...
    settings.price_grid(:), ...
    avg_birth_rate, ...
    avg_first_birth_rate, ...
    mean_age_first_birth, ...
    median_age_first_birth, ...
    share_first_birth_30_plus, ...
    totalvote, ...
    debtstock, ...
    mass_error, ...
    'VariableNames', {'candidate_id', 'label', 'a_price', 'avg_birth_rate', ...
    'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'totalvote', 'debtstock', 'mass_error'});
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
    'birth_utility_1', NaN, ...
    'birth_utility_2', NaN, ...
    'birth_utility_3', NaN, ...
    'child_utility', NaN, ...
    'birth_cost', NaN, ...
    'birth_price_coeff', NaN, ...
    'lambda_crowd', NaN, ...
    'eval_avg_birth_rate', NaN, ...
    'eval_avg_first_birth_rate', NaN, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_median_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_childless_share_at_50', NaN, ...
    'eval_parity1_share_at_50', NaN, ...
    'eval_parity2_share_at_50', NaN, ...
    'eval_parity3plus_share_at_50', NaN, ...
    'eval_share_first_birth_25_29', NaN, ...
    'eval_share_first_birth_30_34', NaN, ...
    'eval_share_first_birth_35_39', NaN, ...
    'eval_share_first_birth_40_44_plus', NaN, ...
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
    'max_mass_error', NaN, ...
    'score', NaN);
end

function candidates_table = sort_candidate_rows(candidate_rows)
candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'primary_pass', 'sign_pass', 'support_pass', 'score', 'crossing_is_unique'}, ...
    {'descend', 'descend', 'descend', 'ascend', 'descend'});
end

function checkpoint_outputs(out_dir, settings, target_table, candidate_rows, path_table)
if isempty(candidate_rows)
    return;
end

candidates_table = sort_candidate_rows(candidate_rows);
writetable(candidates_table, fullfile(out_dir, 'fertility_annual_broad_calibration_screen_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_broad_calibration_screen_candidate_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_broad_calibration_screen.md'), ...
    settings, target_table, candidates_table, path_table);
end

function write_report(report_path, settings, target_table, candidates_table, path_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual fertility broad-band calibration screen\n\n');
fprintf(fid, ['This workflow recalibrates the annual fertility model using wide screening bands and qualitative sign checks. ', ...
    'The objective is to reject obviously wrong annual parameterizations, not to hit the data exactly.\n\n']);

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', settings.base_overrides.I, settings.base_overrides.J);
fprintf(fid, '- screening price grid: `%s`\n', format_price_grid(settings.price_grid));
fprintf(fid, '- market-crossing check grid: `%s`\n\n', format_price_grid(settings.market_price_grid));

fprintf(fid, '## Screening targets\n\n');
fprintf(fid, '| Object | Role | Reference | Lower | Upper |\n');
fprintf(fid, '|---|---|---:|---:|---:|\n');
for i = 1:height(target_table)
    fprintf(fid, '| %s | %s | `%.4f` | `%.4f` | `%.4f` |\n', ...
        char(target_table.name(i)), char(target_table.role(i)), target_table.reference(i), ...
        target_table.lower(i), target_table.upper(i));
end
fprintf(fid, '\n');

primary_pass_count = sum(candidates_table.primary_pass == 1);
screen_pass_count = sum(candidates_table.primary_pass == 1 & candidates_table.sign_pass == 1);
fprintf(fid, '## Main read\n\n');
fprintf(fid, '- Candidates screened: `%d`\n', height(candidates_table));
fprintf(fid, '- Candidates inside all primary bands: `%d`\n', primary_pass_count);
fprintf(fid, '- Candidates inside all primary bands and passing sign checks: `%d`\n\n', screen_pass_count);

fprintf(fid, '## Top candidates\n\n');
fprintf(fid, '| Rank | Candidate | Mean age | Share 30+ | Childless @50 | Primary pass | Sign pass | Crossing | Score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|---:|\n');
max_rows = min(height(candidates_table), 20);
for i = 1:max_rows
    crossing_text = "none";
    if candidates_table.crossing_exists(i) == 1 && candidates_table.crossing_is_unique(i) == 1 && ~isnan(candidates_table.crossing_refined_price(i))
        crossing_text = string(sprintf('%.3f', candidates_table.crossing_refined_price(i)));
    end
    fprintf(fid, '| %d | %s | `%.2f` | `%.3f` | `%.3f` | `%d` | `%d` | %s | `%.4f` |\n', ...
        i, char(candidates_table.label(i)), candidates_table.eval_mean_age_first_birth(i), ...
        candidates_table.eval_share_first_birth_30_plus(i), candidates_table.eval_childless_share_at_50(i), ...
        candidates_table.primary_pass(i), candidates_table.sign_pass(i), char(crossing_text), candidates_table.score(i));
end
fprintf(fid, '\n');

if height(candidates_table) >= 1
    best_id = candidates_table.candidate_id(1);
    best_label = candidates_table.label(1);
    best_paths = path_table(path_table.candidate_id == best_id, :);
    fprintf(fid, '## Best candidate path\n\n');
    fprintf(fid, 'Best candidate: `%s`\n\n', char(best_label));
    fprintf(fid, '| House price | Avg birth rate | Avg first-birth rate | Mean age | Median age | Share 30+ | Vote | Debt |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|---:|\n');
    for i = 1:height(best_paths)
        fprintf(fid, '| %.2f | `%.4f` | `%.4f` | `%.2f` | `%.0f` | `%.3f` | `%.4f` | `%.4f` |\n', ...
            best_paths.a_price(i), best_paths.avg_birth_rate(i), best_paths.avg_first_birth_rate(i), ...
            best_paths.mean_age_first_birth(i), best_paths.median_age_first_birth(i), ...
            best_paths.share_first_birth_30_plus(i), best_paths.totalvote(i), best_paths.debtstock(i));
    end
    fprintf(fid, '\n');
end

fprintf(fid, '## Interpretation rule\n\n');
fprintf(fid, ['Inside-band misses are acceptable. The main red flags are large outside-band misses, wrong-sign comparative statics, ', ...
    'or complete failure to generate a reasonable crossing.\n']);
fclose(fid);
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end

function out = format_price_grid(price_grid)
parts = arrayfun(@(x) sprintf('%.2f', x), price_grid, 'UniformOutput', false);
out = strjoin(parts, ', ');
end
