function run_fertility_annual_crossing_recovery_micro_screen(mode)
% run_fertility_annual_crossing_recovery_micro_screen.m
%
% Narrow annual follow-up after the usable fertility-fit candidate was
% confirmed on moments but still failed market clearing.
%
% This workflow freezes the fertility block at the usable local row and
% varies only a tiny owner-access / renter-side set:
%   1. housingmax
%   2. theta_r
%   3. ka
%   4. rent_markup
%
% The aim is not to reopen fertility search. It is to see whether a clean
% vote crossing can be recovered in the now-usable fertility region.
%
% Usage:
%   run_fertility_annual_crossing_recovery_micro_screen
%   run_fertility_annual_crossing_recovery_micro_screen('smoke')
%   run_fertility_annual_crossing_recovery_micro_screen('confirm')
%   run_fertility_annual_crossing_recovery_micro_screen('fast')
%   run_fertility_annual_crossing_recovery_micro_screen('full')
%
% Outputs:
%   notes/build/fertility_annual_crossing_recovery_micro_screen_candidates.csv
%   notes/build/fertility_annual_crossing_recovery_micro_screen_candidate_paths.csv
%   notes/build/fertility_annual_crossing_recovery_micro_screen_crossing_paths.csv
%   notes/build/fertility_annual_crossing_recovery_micro_screen_target_ranges.csv
%   notes/build/fertility_annual_crossing_recovery_micro_screen.md

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
writetable(target_table, fullfile(out_dir, 'fertility_annual_crossing_recovery_micro_screen_target_ranges.csv'));

candidate_specs = build_candidate_specs(settings);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();
crossing_path_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual crossing-recovery candidate %d: %s ===\n', spec.candidate_id, char(spec.label));
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
settings.theta_r_low = 0.55;
settings.theta_r_mid = 0.70;
settings.theta_r_benchmark = 0.85;
settings.rent_markup_mid = 0.01;
settings.rent_markup_hold_5y = cfg.rent_markup_five_year;
settings.rent_markup_annual = annualize_net_rate(cfg.rent_markup_five_year, 5);
settings.ka_hold_5y = cfg.ka_five_year;
settings.ka_annual = annualize_adjustment_cost(cfg.ka_five_year, 5);

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
    case 'confirm'
        base_overrides.I = 32;
        base_overrides.J = 10;
        settings.price_grid = [1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 3.00, 3.50, 4.00, 5.00];
        settings.spec_mode = "confirm";
    case 'smoke'
        base_overrides.I = 20;
        base_overrides.J = 6;
        settings.price_grid = [1.50, 2.00, 2.50];
        settings.crossing_price_grid = [1.50, 2.00, 2.50, 3.50, 5.00];
        settings.spec_mode = "smoke";
    case 'fast'
        base_overrides.I = 32;
        base_overrides.J = 10;
        settings.price_grid = [1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.50, 4.00, 5.00];
        settings.spec_mode = "fast";
    case 'full'
        base_overrides.I = cfg.overrides.I;
        base_overrides.J = cfg.overrides.J;
        settings.price_grid = [1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.25, 3.50, 4.00, 4.50, 5.00];
        settings.spec_mode = "full";
    otherwise
        error('Unknown mode "%s". Use "smoke", "confirm", "fast", or "full".', mode);
end

settings.base_overrides = base_overrides;
end

function specs = build_candidate_specs(settings)
spec_template = build_spec(NaN, "", NaN, "", NaN, "", NaN, "", NaN, "", 0);
specs = repmat(spec_template, 0, 1);
idx = 0;

baseline = struct( ...
    'housingmax_value', 15.0, ...
    'housingmax_code', "h15", ...
    'theta_r_value', settings.theta_r_benchmark, ...
    'theta_r_code', "benchmark", ...
    'ka_value', settings.ka_annual, ...
    'ka_code', "annualized", ...
    'rent_markup_value', settings.rent_markup_annual, ...
    'rent_markup_code', "annualized", ...
    'is_baseline', 1);

idx = idx + 1;
specs(idx) = build_spec( ...
    idx, ...
    "baseline annual owner block", ...
    baseline.housingmax_value, baseline.housingmax_code, ...
    baseline.theta_r_value, baseline.theta_r_code, ...
    baseline.ka_value, baseline.ka_code, ...
    baseline.rent_markup_value, baseline.rent_markup_code, ...
    baseline.is_baseline);

switch char(settings.spec_mode)
    case 'smoke'
        housing_values = [15, 12];
        theta_specs = [ ...
            struct('code', "mid", 'value', settings.theta_r_mid), ...
            struct('code', "benchmark", 'value', settings.theta_r_benchmark)];
        ka_specs = [ ...
            struct('code', "annualized", 'value', settings.ka_annual), ...
            struct('code', "hold_5y", 'value', settings.ka_hold_5y)];
        rent_specs = struct('code', "mid", 'value', settings.rent_markup_mid);
    case 'confirm'
        housing_values = [15, 12];
        theta_specs = [ ...
            struct('code', "mid", 'value', settings.theta_r_mid), ...
            struct('code', "benchmark", 'value', settings.theta_r_benchmark)];
        ka_specs = [ ...
            struct('code', "annualized", 'value', settings.ka_annual), ...
            struct('code', "hold_5y", 'value', settings.ka_hold_5y)];
        rent_specs = [ ...
            struct('code', "annualized", 'value', settings.rent_markup_annual), ...
            struct('code', "mid", 'value', settings.rent_markup_mid)];
    case 'fast'
        housing_values = [15, 12, 10];
        theta_specs = [ ...
            struct('code', "mid", 'value', settings.theta_r_mid), ...
            struct('code', "benchmark", 'value', settings.theta_r_benchmark), ...
            struct('code', "low", 'value', settings.theta_r_low)];
        ka_specs = [ ...
            struct('code', "annualized", 'value', settings.ka_annual), ...
            struct('code', "hold_5y", 'value', settings.ka_hold_5y)];
        rent_specs = [ ...
            struct('code', "annualized", 'value', settings.rent_markup_annual), ...
            struct('code', "mid", 'value', settings.rent_markup_mid), ...
            struct('code', "hold_5y", 'value', settings.rent_markup_hold_5y)];
    otherwise
        housing_values = [18, 15, 12, 10];
        theta_specs = [ ...
            struct('code', "mid", 'value', settings.theta_r_mid), ...
            struct('code', "benchmark", 'value', settings.theta_r_benchmark), ...
            struct('code', "low", 'value', settings.theta_r_low)];
        ka_specs = [ ...
            struct('code', "annualized", 'value', settings.ka_annual), ...
            struct('code', "hold_5y", 'value', settings.ka_hold_5y)];
        rent_specs = [ ...
            struct('code', "annualized", 'value', settings.rent_markup_annual), ...
            struct('code', "mid", 'value', settings.rent_markup_mid), ...
            struct('code', "hold_5y", 'value', settings.rent_markup_hold_5y)];
end

for ih = 1:numel(housing_values)
    for it = 1:numel(theta_specs)
        for ik = 1:numel(ka_specs)
            for ir = 1:numel(rent_specs)
                if housing_values(ih) == baseline.housingmax_value && ...
                        abs(theta_specs(it).value - baseline.theta_r_value) < 1e-12 && ...
                        abs(ka_specs(ik).value - baseline.ka_value) < 1e-12 && ...
                        abs(rent_specs(ir).value - baseline.rent_markup_value) < 1e-12
                    continue;
                end
                idx = idx + 1;
                label = sprintf('housingmax %.0f | theta_r %s | ka %s | rent %s', ...
                    housing_values(ih), char(theta_specs(it).code), char(ka_specs(ik).code), char(rent_specs(ir).code));
                specs(idx) = build_spec( ...
                    idx, ...
                    label, ...
                    housing_values(ih), string(sprintf('h%.0f', housing_values(ih))), ...
                    theta_specs(it).value, theta_specs(it).code, ...
                    ka_specs(ik).value, ka_specs(ik).code, ...
                    rent_specs(ir).value, rent_specs(ir).code, ...
                    0);
            end
        end
    end
end
end

function spec = build_spec(candidate_id, label, housingmax_value, housingmax_code, theta_r_value, theta_r_code, ka_value, ka_code, rent_markup_value, rent_markup_code, is_baseline)
spec = struct();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.housingmax_value = housingmax_value;
spec.housingmax_code = string(housingmax_code);
spec.theta_r_value = theta_r_value;
spec.theta_r_code = string(theta_r_code);
spec.ka_value = ka_value;
spec.ka_code = string(ka_code);
spec.rent_markup_value = rent_markup_value;
spec.rent_markup_code = string(rent_markup_code);
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
overrides.housingmax = spec.housingmax_value;
overrides.theta_r = spec.theta_r_value;
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
row.housingmax_value = spec.housingmax_value;
row.housingmax_code = spec.housingmax_code;
row.theta_r_value = spec.theta_r_value;
row.theta_r_code = spec.theta_r_code;
row.ka_value = spec.ka_value;
row.ka_code = spec.ka_code;
row.rent_markup_value = spec.rent_markup_value;
row.rent_markup_code = spec.rent_markup_code;
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
    repmat(spec.housingmax_value, n, 1), ...
    repmat(spec.theta_r_code, n, 1), ...
    repmat(spec.ka_code, n, 1), ...
    repmat(spec.rent_markup_code, n, 1), ...
    settings.price_grid(:), ...
    avg_birth_rate, ...
    avg_first_birth_rate, ...
    mean_age_first_birth, ...
    median_age_first_birth, ...
    share_first_birth_30_plus, ...
    totalvote, ...
    debtstock, ...
    mass_error, ...
    'VariableNames', {'candidate_id', 'label', 'housingmax_value', 'theta_r_code', 'ka_code', 'rent_markup_code', ...
    'a_price', 'avg_birth_rate', 'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'totalvote', 'debtstock', 'mass_error'});

crossing_path_rows = table( ...
    repmat(spec.candidate_id, height(crossing_results), 1), ...
    repmat(spec.label, height(crossing_results), 1), ...
    repmat(spec.housingmax_value, height(crossing_results), 1), ...
    repmat(spec.theta_r_code, height(crossing_results), 1), ...
    repmat(spec.ka_code, height(crossing_results), 1), ...
    repmat(spec.rent_markup_code, height(crossing_results), 1), ...
    crossing_results.a_price, ...
    crossing_results.totalvote, ...
    crossing_results.debtstock, ...
    crossing_results.mass_error, ...
    crossing_results.avg_birth_rate, ...
    'VariableNames', {'candidate_id', 'label', 'housingmax_value', 'theta_r_code', 'ka_code', 'rent_markup_code', ...
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
    'housingmax_value', NaN, ...
    'housingmax_code', "", ...
    'theta_r_value', NaN, ...
    'theta_r_code', "", ...
    'ka_value', NaN, ...
    'ka_code', "", ...
    'rent_markup_value', NaN, ...
    'rent_markup_code', "", ...
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
    {'primary_pass', 'sign_pass', 'crossing_is_unique', 'max_crossing_totalvote', 'score', 'support_pass'}, ...
    {'descend', 'descend', 'descend', 'descend', 'ascend', 'descend'});
end

function checkpoint_outputs(out_dir, settings, target_table, candidate_rows, path_table, crossing_path_table)
if isempty(candidate_rows)
    return;
end

candidates_table = sort_candidate_rows(candidate_rows);
writetable(candidates_table, fullfile(out_dir, 'fertility_annual_crossing_recovery_micro_screen_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_crossing_recovery_micro_screen_candidate_paths.csv'));
writetable(crossing_path_table, fullfile(out_dir, 'fertility_annual_crossing_recovery_micro_screen_crossing_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_crossing_recovery_micro_screen.md'), ...
    settings, target_table, candidates_table, path_table, crossing_path_table);
end

function write_report(report_path, settings, target_table, candidates_table, path_table, crossing_path_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual fertility crossing-recovery micro screen\n\n');
fprintf(fid, ['This workflow freezes the first usable annual fertility-fit row and varies only the owner-access / renter-side annual levers. ', ...
    'The question is whether the vote schedule can be lifted back toward zero without losing the now-acceptable timing and childlessness fit.\n\n']);

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

primary_pass_count = sum(candidates_table.primary_pass == 1);
unique_cross_count = sum(candidates_table.crossing_is_unique == 1);
joint_pass_count = sum(candidates_table.primary_pass == 1 & candidates_table.sign_pass == 1 & candidates_table.crossing_is_unique == 1);
fprintf(fid, '## Main read\n\n');
fprintf(fid, '- Candidates screened: `%d`\n', height(candidates_table));
fprintf(fid, '- Candidates inside all primary fertility bands: `%d`\n', primary_pass_count);
fprintf(fid, '- Candidates with a unique crossing: `%d`\n', unique_cross_count);
fprintf(fid, '- Candidates with primary fertility pass + sign pass + unique crossing: `%d`\n\n', joint_pass_count);

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
fprintf(fid, '- the fertility block is frozen at the usable local annual row\n');
fprintf(fid, '- the active question is whether `housingmax`, `theta_r`, `ka`, or `rent_markup` can move the vote schedule back toward zero without reopening fertility search\n');
fprintf(fid, '- if no candidate gets close to zero on the wider crossing grid, the annual blocker is a deeper market-clearing problem, not a missing fertility micro tweak\n');
fprintf(fid, '- if one candidate restores a unique crossing while keeping the fertility moments inside band, that row becomes the annual benchmark frontrunner\n');
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

function r_annual = annualize_net_rate(r_period, years_per_period)
r_annual = (1 + r_period) .^ (1 / years_per_period) - 1;
end

function ka_annual = annualize_adjustment_cost(ka_period, years_per_period)
ka_annual = 1 - (1 - ka_period) .^ (1 / years_per_period);
end
