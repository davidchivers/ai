function run_fertility_annual_family_rent_wedge_screen(mode)
% run_fertility_annual_family_rent_wedge_screen.m
%
% Fast annual prototype for a missing mechanism: renting becomes less
% effective as children are present, so the annual model can generate a
% stronger family-to-ownership channel without reopening the fertility
% anchor itself.
%
% Outputs:
%   notes/build/fertility_annual_family_rent_wedge_screen.md
%   notes/build/fertility_annual_family_rent_wedge_screen_candidates.csv
%   notes/build/fertility_annual_family_rent_wedge_screen_candidate_paths.csv
%   notes/build/fertility_annual_family_rent_wedge_screen_crossing_paths.csv
%   notes/build/fertility_annual_family_rent_wedge_screen_target_ranges.csv

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
writetable(target_table, fullfile(out_dir, 'fertility_annual_family_rent_wedge_screen_target_ranges.csv'));

candidate_specs = build_candidate_specs(settings);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();
crossing_path_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual family-rent-wedge candidate %d: %s ===\n', spec.candidate_id, char(spec.label));
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
settings.current_age_weights = cfg.target_first_birth_age_share_annual;
settings.vote_scale = 100.0;
settings.max_front_loaded_realized = repelem([1.00, 0.25, 0.040, 0.008], 5);

settings.anchor = struct( ...
    'label', "usable_fertility_anchor", ...
    'timing_profile', "max_front_loaded", ...
    'birth_utility_by_parity', [1.120, 1.240, 1.170], ...
    'child_utility', 0.020, ...
    'birth_cost', 0.050, ...
    'birth_price_coeff', 0.16, ...
    'lambda_crowd', 0.10, ...
    'first_birth_realized_weights', settings.max_front_loaded_realized);

base_overrides = cfg.overrides;
switch char(settings.mode)
    case 'fast'
        base_overrides.I = 32;
        base_overrides.J = 10;
        settings.price_grid = [1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.50, 4.00, 5.00];
        settings.theta_r_grid = [0.85, 0.70];
        settings.penalty_grid = [0.00, 0.05, 0.10, 0.15, 0.20, 0.25];
        settings.housingmax_grid = [15.0, 15.25];
    case 'confirm'
        base_overrides.I = 32;
        base_overrides.J = 12;
        settings.price_grid = [1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.50, 4.00, 5.00, 6.00];
        settings.theta_r_grid = [0.85, 0.70];
        settings.penalty_grid = [0.00, 0.05, 0.10, 0.15, 0.20];
        settings.housingmax_grid = [15.0, 15.25];
    otherwise
        base_overrides.I = 16;
        base_overrides.J = 4;
        settings.price_grid = [1.75, 2.00, 2.25];
        settings.crossing_price_grid = [1.75, 2.00, 2.25, 2.50, 3.50, 5.00];
        settings.theta_r_grid = [0.85, 0.70];
        settings.penalty_grid = [0.00, 0.10, 0.20];
        settings.housingmax_grid = [15.0];
end

settings.base_overrides = base_overrides;
end

function specs = build_candidate_specs(settings)
spec_template = build_spec(NaN, "", NaN, NaN, NaN, 0);
specs = repmat(spec_template, 0, 1);
idx = 0;

baseline = struct( ...
    'theta_r_value', 0.85, ...
    'theta_r_child_penalty', 0.00, ...
    'housingmax_value', 15.0, ...
    'is_baseline', 1);

idx = idx + 1;
specs(idx) = build_spec( ...
    idx, ...
    "baseline annual family-rent block", ...
    baseline.theta_r_value, ...
    baseline.theta_r_child_penalty, ...
    baseline.housingmax_value, ...
    baseline.is_baseline);

for ih = 1:numel(settings.housingmax_grid)
    for it = 1:numel(settings.theta_r_grid)
        for ip = 1:numel(settings.penalty_grid)
            theta_value = settings.theta_r_grid(it);
            penalty_value = settings.penalty_grid(ip);
            housingmax_value = settings.housingmax_grid(ih);
            if abs(theta_value - baseline.theta_r_value) < 1e-12 && ...
                    abs(penalty_value - baseline.theta_r_child_penalty) < 1e-12 && ...
                    abs(housingmax_value - baseline.housingmax_value) < 1e-12
                continue;
            end
            idx = idx + 1;
            label = sprintf('theta_r %.2f | child rent penalty %.2f | housingmax %.2f', ...
                theta_value, penalty_value, housingmax_value);
            specs(idx) = build_spec(idx, label, theta_value, penalty_value, housingmax_value, 0);
        end
    end
end
end

function spec = build_spec(candidate_id, label, theta_r_value, theta_r_child_penalty, housingmax_value, is_baseline)
spec = struct();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.theta_r_value = theta_r_value;
spec.theta_r_child_penalty = theta_r_child_penalty;
spec.housingmax_value = housingmax_value;
spec.is_baseline = is_baseline;
end

function [row, path_rows, crossing_path_rows] = evaluate_candidate(spec, settings, cfg)
overrides = settings.base_overrides;
anchor = settings.anchor;
overrides.birth_utility_by_parity = anchor.birth_utility_by_parity;
overrides.child_utility = anchor.child_utility;
overrides.birth_cost = anchor.birth_cost;
overrides.birth_price_coeff = anchor.birth_price_coeff;
overrides.lambda_crowd = anchor.lambda_crowd;
overrides.birth_age_weights = settings.current_age_weights;
overrides.realized_birth_weights = ones(size(settings.current_age_weights));
overrides.first_birth_realized_weights = anchor.first_birth_realized_weights;
overrides.theta_r = spec.theta_r_value;
overrides.theta_r_child_penalty = spec.theta_r_child_penalty;
overrides.housingmax = spec.housingmax_value;

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
    crossing_penalty = 0.50;
else
    crossing_penalty = 0.25;
end

max_mass_error = max([mass_error; crossing_results.mass_error]);
mass_penalty = 1e12 * max(max_mass_error - 1e-8, 0);

score = 4.0 * primary_score + sign_penalty + vote_shortfall + 0.25 * eval_vote_shortfall + crossing_penalty + mass_penalty;

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = spec.label;
row.theta_r_value = spec.theta_r_value;
row.theta_r_child_penalty = spec.theta_r_child_penalty;
row.housingmax_value = spec.housingmax_value;
row.is_baseline = spec.is_baseline;
row.eval_avg_birth_rate = avg_birth_rate(eval_idx);
row.eval_avg_first_birth_rate = avg_first_birth_rate(eval_idx);
row.eval_mean_age_first_birth = mean_age_first_birth(eval_idx);
row.eval_median_age_first_birth = median_age_first_birth(eval_idx);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(eval_idx);
row.eval_childless_share_at_50 = childless_share_at_50;
row.eval_parity1_share_at_50 = parity1;
row.eval_parity2_share_at_50 = parity2;
row.eval_parity3plus_share_at_50 = parity3plus;
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
    repmat(spec.theta_r_value, n, 1), ...
    repmat(spec.theta_r_child_penalty, n, 1), ...
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
    'VariableNames', {'candidate_id', 'label', 'theta_r_value', 'theta_r_child_penalty', 'housingmax_value', ...
    'a_price', 'avg_birth_rate', 'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'totalvote', 'debtstock', 'mass_error'});

crossing_path_rows = table( ...
    repmat(spec.candidate_id, height(crossing_results), 1), ...
    repmat(spec.label, height(crossing_results), 1), ...
    repmat(spec.theta_r_value, height(crossing_results), 1), ...
    repmat(spec.theta_r_child_penalty, height(crossing_results), 1), ...
    repmat(spec.housingmax_value, height(crossing_results), 1), ...
    crossing_results.a_price, ...
    crossing_results.totalvote, ...
    crossing_results.debtstock, ...
    crossing_results.mass_error, ...
    crossing_results.avg_birth_rate, ...
    'VariableNames', {'candidate_id', 'label', 'theta_r_value', 'theta_r_child_penalty', 'housingmax_value', ...
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

function target_table = build_target_table(ranges)
all_targets = [ranges.primary(:); ranges.support(:); ranges.validation];
target_table = struct2table(all_targets);
target_table = target_table(:, {'name', 'role', 'unit', 'reference', 'lower', 'upper', 'source', 'comment'});
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'theta_r_value', NaN, ...
    'theta_r_child_penalty', NaN, ...
    'housingmax_value', NaN, ...
    'is_baseline', NaN, ...
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

function candidates_table = sort_candidate_rows(candidate_rows)
candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'primary_pass', 'sign_pass', 'crossing_is_unique', 'max_crossing_totalvote', 'score'}, ...
    {'descend', 'descend', 'descend', 'descend', 'ascend'});
end

function checkpoint_outputs(out_dir, settings, target_table, candidate_rows, path_table, crossing_path_table)
if isempty(candidate_rows)
    return;
end

candidates_table = sort_candidate_rows(candidate_rows);
writetable(candidates_table, fullfile(out_dir, 'fertility_annual_family_rent_wedge_screen_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_family_rent_wedge_screen_candidate_paths.csv'));
writetable(crossing_path_table, fullfile(out_dir, 'fertility_annual_family_rent_wedge_screen_crossing_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_family_rent_wedge_screen.md'), ...
    settings, target_table, candidates_table, path_table, crossing_path_table);
end

function write_report(report_path, settings, target_table, candidates_table, path_table, crossing_path_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual family-rent-wedge screen\n\n');
fprintf(fid, ['This workflow holds the usable annual fertility anchor fixed and adds a child-dependent renter penalty. ', ...
    'The new mechanism only changes the annual renter block: as children are present, renting becomes less effective relative to owning.\n\n']);

fprintf(fid, '## Fixed fertility anchor\n\n');
fprintf(fid, '- anchor label: `%s`\n', char(settings.anchor.label));
fprintf(fid, '- timing profile: `%s`\n', char(settings.anchor.timing_profile));
fprintf(fid, '- `phi0`: `%.3f`\n', settings.anchor.birth_utility_by_parity(1));
fprintf(fid, '- `child_utility`: `%.3f`\n', settings.anchor.child_utility);
fprintf(fid, '- `birth_cost`: `%.3f`\n', settings.anchor.birth_cost);
fprintf(fid, '- `birth_price_coeff`: `%.2f`\n', settings.anchor.birth_price_coeff);
fprintf(fid, '- `lambda_crowd`: `%.2f`\n\n', settings.anchor.lambda_crowd);

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', settings.base_overrides.I, settings.base_overrides.J);
fprintf(fid, '- screening price grid: `%s`\n', format_price_grid(settings.price_grid));
fprintf(fid, '- market-crossing check grid: `%s`\n\n', format_price_grid(settings.crossing_price_grid));

fprintf(fid, '## Screening targets\n\n');
fprintf(fid, '| Object | Role | Reference | Lower | Upper |\n');
fprintf(fid, '|---|---|---:|---:|---:|\n');
for i = 1:height(target_table)
    fprintf(fid, '| %s | %s | `%.4f` | `%.4f` | `%.4f` |\n', ...
        char(target_table.name(i)), char(target_table.role(i)), target_table.reference(i), ...
        target_table.lower(i), target_table.upper(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Main read\n\n');
fprintf(fid, '- Candidates screened: `%d`\n', height(candidates_table));
fprintf(fid, '- Candidates inside all primary fertility bands: `%d`\n', sum(candidates_table.primary_pass == 1));
fprintf(fid, '- Candidates with a unique crossing: `%d`\n\n', sum(candidates_table.crossing_is_unique == 1));

fprintf(fid, '## Top candidates\n\n');
fprintf(fid, '| Rank | Candidate | Mean age | Share 30+ | Childless @50 | Eval vote | Max crossing-grid vote | Best vote price | Crossing | Score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|\n');
max_rows = min(height(candidates_table), 20);
for i = 1:max_rows
    crossing_text = "none";
    if candidates_table.crossing_exists(i) == 1 && candidates_table.crossing_is_unique(i) == 1 && ~isnan(candidates_table.crossing_refined_price(i))
        crossing_text = string(sprintf('%.3f', candidates_table.crossing_refined_price(i)));
    end
    label_text = strrep(char(candidates_table.label(i)), '|', '&#124;');
    fprintf(fid, '| %d | %s | `%.2f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.2f` | %s | `%.4f` |\n', ...
        i, label_text, candidates_table.eval_mean_age_first_birth(i), ...
        candidates_table.eval_share_first_birth_30_plus(i), candidates_table.eval_childless_share_at_50(i), ...
        candidates_table.eval_totalvote(i), candidates_table.max_crossing_totalvote(i), ...
        candidates_table.max_crossing_price(i), char(crossing_text), candidates_table.score(i));
end
fprintf(fid, '\n');

if height(candidates_table) >= 1
    best_id = candidates_table.candidate_id(1);
    best_label = candidates_table.label(1);
    best_paths = path_table(path_table.candidate_id == best_id, :);
    best_cross_paths = crossing_path_table(crossing_path_table.candidate_id == best_id, :);
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

    fprintf(fid, '## Best candidate crossing grid\n\n');
    fprintf(fid, '| House price | Vote | Debt | Avg birth rate | Mass error |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|\n');
    for i = 1:height(best_cross_paths)
        fprintf(fid, '| %.2f | `%.4f` | `%.4f` | `%.4f` | `%.3e` |\n', ...
            best_cross_paths.a_price(i), best_cross_paths.totalvote(i), best_cross_paths.debtstock(i), ...
            best_cross_paths.avg_birth_rate(i), best_cross_paths.mass_error(i));
    end
    fprintf(fid, '\n');
end

fprintf(fid, '## Theory checkpoint\n\n');
fprintf(fid, '- the old annual branch was varying only scalar owner-access levers inside the same renter block\n');
fprintf(fid, '- this screen adds a different mechanism: renting becomes worse as children accumulate, including on the birth branch itself\n');
fprintf(fid, '- if vote moves toward zero without blowing up timing, the annual problem may really be a missing family-to-ownership channel rather than a missing scalar `theta_r` value\n');
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
