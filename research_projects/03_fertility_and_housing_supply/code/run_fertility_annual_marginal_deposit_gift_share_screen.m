function run_fertility_annual_marginal_deposit_gift_share_screen(mode)
% run_fertility_annual_marginal_deposit_gift_share_screen.m
%
% Data-motivated annual screen for first-home deposit gifts that only fire
% when they tip a gifted renter from renting into ownership.

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
spec = fertility_annual_ownership_balance_sheet_branch_spec();
settings = build_settings(mode, cfg, spec);
ensure_transition_matrix(settings.base_overrides.transition_matrix_file);

candidates = build_candidates(settings);
candidate_rows = repmat(empty_candidate_row(), numel(candidates), 1);

for i = 1:numel(candidates)
    fprintf('\n=== annual marginal-deposit-gift candidate %d / %d ===\n', i, numel(candidates));
    candidate_rows(i) = evaluate_candidate(candidates(i), settings, cfg);
end

candidate_table = struct2table(candidate_rows);
candidate_table = sortrows(candidate_table, ...
    {'primary_pass', 'homeownership_pass', 'wealth_pass', 'crossing_is_unique', 'score'}, ...
    {'descend', 'descend', 'descend', 'descend', 'ascend'});
writetable(candidate_table, fullfile(out_dir, 'fertility_annual_marginal_deposit_gift_share_screen_candidates.csv'));
write_summary_note(fullfile(out_dir, 'fertility_annual_marginal_deposit_gift_share_screen.md'), candidate_table, settings, cfg);
end

function settings = build_settings(mode, cfg, spec)
settings = struct();
settings.mode = lower(string(mode));
settings.eval_price = cfg.eval_price;
settings.eval_age = cfg.eval_age;
settings.anchor = spec.anchor;
settings.target_ranges = cfg.target_ranges;
settings.homeownership_target_ranges = cfg.homeownership_target_ranges;
settings.wealth_target_ranges = cfg.wealth_target_ranges;

base_overrides = cfg.overrides;
switch char(settings.mode)
    case 'smoke'
        base_overrides.I = 12;
        base_overrides.J = 4;
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.50, 5.00];
        settings.gift_share_grid = [0.20, 0.25, 0.33];
        settings.deposit_gift_grid = [0.50, 0.75, 1.00];
        settings.deposit_age_max_grid = [44];
    case 'confirm'
        base_overrides.I = 20;
        base_overrides.J = 6;
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 3.00, 5.00];
        settings.gift_share_grid = [0.20, 0.25, 0.30, 0.33];
        settings.deposit_gift_grid = [0.50, 0.75, 1.00];
        settings.deposit_age_max_grid = [39, 44];
    otherwise
        error('Unknown mode "%s". Use "smoke" or "confirm".', mode);
end

settings.base_overrides = base_overrides;
settings.fixed_finance = struct( ...
    'owner_mortgage_CC', settings.anchor.owner_mortgage_CC, ...
    'owner_entry_mortgage_floor', settings.anchor.baseline_owner_entry_mortgage_floor, ...
    'owner_entry_payment_to_income_cap', settings.anchor.baseline_owner_entry_payment_to_income_cap, ...
    'owner_mortgage_amortization', settings.anchor.owner_mortgage_amortization, ...
    'owner_mortgage_spread', settings.anchor.owner_mortgage_spread);
settings.data_basis = "gift incidence around FHA family-gift / DPA take-up, but only activated for marginal buyers";
end

function candidates = build_candidates(settings)
idx = 0;
candidates = repmat(struct( ...
    'candidate_id', NaN, ...
    'gift_share', NaN, ...
    'deposit_gift', NaN, ...
    'deposit_age_max', NaN, ...
    'marginal_only', false, ...
    'label', ""), 0, 1);

idx = idx + 1;
candidates(idx).candidate_id = idx; %#ok<AGROW>
candidates(idx).gift_share = 0.0;
candidates(idx).deposit_gift = 0.0;
candidates(idx).deposit_age_max = settings.anchor.owner_entry_age_max;
candidates(idx).marginal_only = false;
candidates(idx).label = "baseline no gift";

for ishare = 1:numel(settings.gift_share_grid)
    for igift = 1:numel(settings.deposit_gift_grid)
        for iage = 1:numel(settings.deposit_age_max_grid)
            idx = idx + 1;
            share = settings.gift_share_grid(ishare);
            gift = settings.deposit_gift_grid(igift);
            age_max = settings.deposit_age_max_grid(iage);
            candidates(idx).candidate_id = idx; %#ok<AGROW>
            candidates(idx).gift_share = share;
            candidates(idx).deposit_gift = gift;
            candidates(idx).deposit_age_max = age_max;
            candidates(idx).marginal_only = true;
            candidates(idx).label = string(sprintf('gift share %.2f | gift %.2f | marginal only | age max %d', ...
                share, gift, age_max));
        end
    end
end
end

function row = evaluate_candidate(candidate, settings, cfg)
[override_list, weights] = build_type_list(candidate, settings, cfg);

price_grid = settings.crossing_price_grid;
n = numel(price_grid);
mean_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
childless_share_at_50 = NaN(n, 1);
vote_per_mass = NaN(n, 1);
debt_per_mass = NaN(n, 1);
mass_error = NaN(n, 1);
owner_share_25_34 = NaN(n, 1);
owner_share_35_44 = NaN(n, 1);
owner_share_45_54 = NaN(n, 1);
support_shares = NaN(n, 4);
wealth_eval = empty_wealth_metrics();
eval_idx = find(price_grid == settings.eval_price, 1);

for i = 1:n
    point = evaluate_mixture_point(price_grid(i), cfg.rbPos, override_list, weights, settings.eval_age, i == eval_idx);
    mean_age_first_birth(i) = point.mean_age_first_birth;
    share_first_birth_30_plus(i) = point.share_first_birth_30_plus;
    childless_share_at_50(i) = point.childless_share_at_50;
    vote_per_mass(i) = point.vote_per_mass;
    debt_per_mass(i) = point.debt_per_mass;
    mass_error(i) = point.max_mass_error;
    owner_share_25_34(i) = point.owner_shares(1);
    owner_share_35_44(i) = point.owner_shares(2);
    owner_share_45_54(i) = point.owner_shares(3);
    support_shares(i, :) = point.support_shares;
    if i == eval_idx
        wealth_eval = point.wealth_metrics;
    end
end

annual_scores = score_annual_fertility_targets( ...
    settings.target_ranges, ...
    mean_age_first_birth(eval_idx), ...
    share_first_birth_30_plus(eval_idx), ...
    childless_share_at_50(eval_idx), ...
    support_shares(eval_idx, :));
home_scores = score_annual_homeownership_support_targets( ...
    settings.homeownership_target_ranges, ...
    [owner_share_25_34(eval_idx), owner_share_35_44(eval_idx), owner_share_45_54(eval_idx)]);
wealth_scores = score_annual_wealth_support_targets(settings.wealth_target_ranges, wealth_eval);
crossing = summarize_crossing(price_grid, vote_per_mass);
young_mortgage_target = support_target_reference(settings.wealth_target_ranges, "mortgaged_owner_share_under_35");
target_gap = abs(wealth_eval.mortgaged_owner_share_under_35 - young_mortgage_target);
mass_penalty = 1e12 * max(max(mass_error) - 1e-8, 0);
score = 4.0 * annual_scores.primary_score + home_scores.score + wealth_scores.score + target_gap ...
    + max(0, -max(vote_per_mass)) + 0.5 * double(~crossing.is_unique) + mass_penalty;

row = empty_candidate_row();
row.candidate_id = candidate.candidate_id;
row.label = candidate.label;
row.gift_share = candidate.gift_share;
row.owner_entry_deposit_gift = candidate.deposit_gift;
row.owner_entry_deposit_age_max = candidate.deposit_age_max;
row.marginal_only = double(candidate.marginal_only);
row.eval_mean_age_first_birth = mean_age_first_birth(eval_idx);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(eval_idx);
row.eval_childless_share_at_50 = childless_share_at_50(eval_idx);
row.eval_owner_share_25_34 = owner_share_25_34(eval_idx);
row.eval_owner_share_35_44 = owner_share_35_44(eval_idx);
row.eval_owner_share_45_54 = owner_share_45_54(eval_idx);
row.eval_debt_holder_share_under_35 = wealth_eval.debt_holder_share_under_35;
row.eval_debt_holder_share_35_44 = wealth_eval.debt_holder_share_35_44;
row.eval_mortgaged_owner_share_under_35 = wealth_eval.mortgaged_owner_share_under_35;
row.eval_mortgaged_owner_share_35_44 = wealth_eval.mortgaged_owner_share_35_44;
row.eval_vote_per_mass = vote_per_mass(eval_idx);
row.eval_debt_per_mass = debt_per_mass(eval_idx);
row.primary_pass = double(annual_scores.primary_pass);
row.homeownership_pass = double(home_scores.pass);
row.wealth_pass = double(wealth_scores.pass);
row.crossing_is_unique = double(crossing.is_unique);
row.crossing_refined_price = crossing.refined_price;
row.crossing_gap_to_zero = min(abs(vote_per_mass));
row.score = score;
end

function [override_list, weights] = build_type_list(candidate, settings, cfg)
baseline = build_anchor_overrides(settings, cfg);
baseline.owner_entry_deposit_gift = 0.0;
baseline.owner_entry_deposit_age_max = 0;
baseline.owner_entry_deposit_only_if_marginal = false;

if candidate.gift_share <= 0
    override_list = {baseline};
    weights = 1.0;
    return;
end

gifted = baseline;
gifted.owner_entry_deposit_gift = candidate.deposit_gift;
gifted.owner_entry_deposit_age_max = candidate.deposit_age_max;
gifted.owner_entry_deposit_only_if_marginal = candidate.marginal_only;

override_list = {baseline, gifted};
weights = [1.0 - candidate.gift_share, candidate.gift_share];
end

function overrides = build_anchor_overrides(settings, cfg)
anchor = settings.anchor;
overrides = settings.base_overrides;
overrides.birth_utility_by_parity = anchor.birth_utility_by_parity;
overrides.child_utility = anchor.child_utility;
overrides.birth_cost = anchor.birth_cost;
overrides.birth_price_coeff = anchor.birth_price_coeff;
overrides.lambda_crowd = anchor.lambda_crowd;
overrides.birth_age_weights = cfg.target_first_birth_age_share_annual;
overrides.realized_birth_weights = ones(size(cfg.target_first_birth_age_share_annual));
overrides.first_birth_realized_weights = anchor.first_birth_realized_weights;
overrides.housingmax = anchor.housingmax;
overrides.theta_r = anchor.theta_r;
overrides.CC = anchor.CC;
overrides.owner_mortgage_CC = settings.fixed_finance.owner_mortgage_CC;
overrides.owner_mortgage_spread = settings.fixed_finance.owner_mortgage_spread;
overrides.owner_mortgage_amortization = settings.fixed_finance.owner_mortgage_amortization;
overrides.owner_entry_b_floor = anchor.baseline_owner_entry_b_floor;
overrides.owner_entry_age_max = anchor.owner_entry_age_max;
overrides.owner_entry_mortgage_floor = settings.fixed_finance.owner_entry_mortgage_floor;
overrides.owner_entry_mortgage_age_max = anchor.owner_entry_mortgage_age_max;
overrides.owner_entry_payment_to_income_cap = settings.fixed_finance.owner_entry_payment_to_income_cap;
overrides.owner_entry_payment_to_income_age_max = anchor.owner_entry_payment_to_income_age_max;
overrides.owner_entry_income_multiplier = 1.0;
overrides.owner_entry_income_multiplier_after_birth = 1.0;
overrides.owner_entry_deposit_gift = 0.0;
overrides.owner_entry_deposit_age_max = 0;
overrides.owner_entry_deposit_b_min = -inf;
overrides.owner_entry_deposit_b_max = inf;
overrides.owner_entry_deposit_only_if_marginal = false;
overrides.ka = anchor.ka;
overrides.rent_markup = anchor.rent_markup;
overrides.parental_transfer_share = 0.0;
overrides.parental_transfer_b_boost = 0.0;
overrides.initial_b_points = anchor.baseline_initial_b_points;
overrides.initial_b_shares = anchor.baseline_initial_b_shares;
end

function point = evaluate_mixture_point(a_price, rbPos, override_list, weights, eval_age, compute_wealth_metrics)
if nargin < 6
    compute_wealth_metrics = false;
end

nt = numel(weights);
diag_list = cell(nt, 1);
vote_vals = zeros(nt, 1);
debt_vals = zeros(nt, 1);
birth_vals = zeros(nt, 1);
mass_err_vals = zeros(nt, 1);

for it = 1:nt
    [~, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([a_price, rbPos], override_list{it});
    diag_list{it} = diagnostics;
    vote_vals(it) = totalvote / max(sum(diagnostics.age_mass(:)), 1e-12);
    debt_vals(it) = debtstock / max(sum(diagnostics.age_mass(:)), 1e-12);
    birth_vals(it) = diagnostics.avg_birth_rate;
    mass_err_vals(it) = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));
end

ages = diag_list{1}.ages(:);
first_birth_mass = zeros(numel(ages), 1);
age50_mass = 0.0;
childless50_mass = 0.0;
owner_share_bins = zeros(nt, 3);
for it = 1:nt
    diagnostics = diag_list{it};
    first_birth_mass = first_birth_mass + weights(it) * diagnostics.first_birth_mass_by_age(:);
    age50_idx = find(diagnostics.ages == eval_age, 1);
    age50_mass = age50_mass + weights(it) * diagnostics.age_mass(age50_idx);
    childless50_mass = childless50_mass + weights(it) * diagnostics.age_mass(age50_idx) * diagnostics.parity_dist_by_age(age50_idx, 1);
    age_owner = owner_share_by_age(diagnostics);
    owner_share_bins(it, :) = [ ...
        weighted_owner_share(diagnostics.age_mass(:), age_owner .* diagnostics.age_mass(:), ages, 25, 34), ...
        weighted_owner_share(diagnostics.age_mass(:), age_owner .* diagnostics.age_mass(:), ages, 35, 44), ...
        weighted_owner_share(diagnostics.age_mass(:), age_owner .* diagnostics.age_mass(:), ages, 45, 54)];
end

first_birth_dist = first_birth_mass ./ max(sum(first_birth_mass), 1e-12);
point = struct();
point.mean_age_first_birth = sum(ages .* first_birth_dist);
point.share_first_birth_30_plus = sum(first_birth_dist(ages >= 30));
point.childless_share_at_50 = childless50_mass / max(age50_mass, 1e-12);
point.vote_per_mass = sum(weights(:) .* vote_vals) / sum(weights);
point.debt_per_mass = sum(weights(:) .* debt_vals) / sum(weights);
point.max_mass_error = max(mass_err_vals);
point.avg_birth_rate = sum(weights(:) .* birth_vals) / sum(weights);
point.owner_shares = sum(owner_share_bins .* weights(:), 1) / sum(weights);
point.support_shares = [ ...
    sum(first_birth_dist(ages >= 25 & ages <= 29)), ...
    sum(first_birth_dist(ages >= 30 & ages <= 34)), ...
    sum(first_birth_dist(ages >= 35 & ages <= 39)), ...
    sum(first_birth_dist(ages >= 40 & ages <= 44))];
point.wealth_metrics = empty_wealth_metrics();
if compute_wealth_metrics
    point.wealth_metrics = mixture_wealth_metrics(diag_list, weights);
end
end

function shares = owner_share_by_age(diagnostics)
ages = diagnostics.ages(:);
shares = NaN(numel(ages), 1);
for i = 1:numel(ages)
    age_slice = diagnostics.dens4(:, :, :, i);
    age_mass = sum(age_slice, 'all');
    renter_mass = sum(age_slice(:, 1, :), 'all');
    shares(i) = 1 - renter_mass / max(age_mass, 1e-12);
end
end

function value = weighted_owner_share(age_mass, owner_mass, ages, age_lo, age_hi)
mask = ages >= age_lo & ages <= age_hi;
value = sum(owner_mass(mask)) / max(sum(age_mass(mask)), 1e-12);
end

function metrics = mixture_wealth_metrics(diag_list, weights)
metrics = empty_wealth_metrics();
metrics.debt_holder_share_under_35 = age_group_share_metric(diag_list, weights, 25, 34, "debt_holder");
metrics.debt_holder_share_35_44 = age_group_share_metric(diag_list, weights, 35, 44, "debt_holder");
metrics.mortgaged_owner_share_under_35 = age_group_share_metric(diag_list, weights, 25, 34, "mortgaged_owner");
metrics.mortgaged_owner_share_35_44 = age_group_share_metric(diag_list, weights, 35, 44, "mortgaged_owner");
metrics.mortgaged_owner_share_45_54 = age_group_share_metric(diag_list, weights, 45, 54, "mortgaged_owner");
metrics.mortgaged_owner_share_55_64 = age_group_share_metric(diag_list, weights, 55, 64, "mortgaged_owner");
end

function share = age_group_share_metric(diag_list, weights, age_lo, age_hi, metric_name)
num = 0.0;
den = 0.0;
for it = 1:numel(diag_list)
    [num_it, den_it] = extract_age_group_mass_metric(diag_list{it}, age_lo, age_hi, metric_name);
    num = num + weights(it) * num_it;
    den = den + weights(it) * den_it;
end
share = num / max(den, 1e-12);
end

function [num, den] = extract_age_group_mass_metric(diagnostics, age_lo, age_hi, metric_name)
age_mask = diagnostics.ages(:) >= age_lo & diagnostics.ages(:) <= age_hi;
if ~any(age_mask)
    num = 0.0;
    den = 0.0;
    return;
end

dens = diagnostics.dens4(:, :, :, age_mask);
bvals = diagnostics.bbbb4(:, :, :, age_mask);
owner_mask = false(size(dens));
owner_mask(:, 2:end, :, :) = true;

switch char(metric_name)
    case 'debt_holder'
        metric_mask = bvals < 0;
    case 'mortgaged_owner'
        metric_mask = owner_mask & (bvals < 0);
    otherwise
        error('Unknown wealth metric "%s".', metric_name);
end

num = sum(dens(metric_mask));
den = sum(dens, 'all');
end

function metrics = empty_wealth_metrics()
metrics = struct( ...
    'debt_holder_share_under_35', NaN, ...
    'debt_holder_share_35_44', NaN, ...
    'mortgaged_owner_share_under_35', NaN, ...
    'mortgaged_owner_share_35_44', NaN, ...
    'mortgaged_owner_share_45_54', NaN, ...
    'mortgaged_owner_share_55_64', NaN);
end

function reference = support_target_reference(ranges, target_name)
reference = NaN;
for i = 1:numel(ranges.support)
    if strcmp(string(ranges.support(i).name), string(target_name))
        reference = ranges.support(i).reference;
        return;
    end
end
error('Could not find support target "%s".', target_name);
end

function crossing = summarize_crossing(price_grid, votes)
crossing = struct('exists', false, 'is_unique', false, 'refined_price', NaN, 'sign_change_count', 0);
for i = 1:(numel(price_grid) - 1)
    v0 = votes(i);
    v1 = votes(i + 1);
    if v0 == 0
        crossing.sign_change_count = crossing.sign_change_count + 1;
        if isnan(crossing.refined_price)
            crossing.refined_price = price_grid(i);
        end
    elseif v0 * v1 < 0
        crossing.sign_change_count = crossing.sign_change_count + 1;
        if isnan(crossing.refined_price)
            weight = abs(v0) / (abs(v0) + abs(v1));
            crossing.refined_price = price_grid(i) + weight * (price_grid(i + 1) - price_grid(i));
        end
    end
end
crossing.exists = crossing.sign_change_count > 0;
crossing.is_unique = crossing.sign_change_count == 1;
end

function ensure_transition_matrix(pathstr)
if exist(pathstr, 'file')
    return;
end
build_transition_matrix_annual(pathstr);
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'gift_share', NaN, ...
    'owner_entry_deposit_gift', NaN, ...
    'owner_entry_deposit_age_max', NaN, ...
    'marginal_only', 0, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_childless_share_at_50', NaN, ...
    'eval_owner_share_25_34', NaN, ...
    'eval_owner_share_35_44', NaN, ...
    'eval_owner_share_45_54', NaN, ...
    'eval_debt_holder_share_under_35', NaN, ...
    'eval_debt_holder_share_35_44', NaN, ...
    'eval_mortgaged_owner_share_under_35', NaN, ...
    'eval_mortgaged_owner_share_35_44', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'eval_debt_per_mass', NaN, ...
    'primary_pass', 0, ...
    'homeownership_pass', 0, ...
    'wealth_pass', 0, ...
    'crossing_is_unique', 0, ...
    'crossing_refined_price', NaN, ...
    'crossing_gap_to_zero', NaN, ...
    'score', NaN);
end

function write_summary_note(pathstr, candidate_table, settings, cfg)
fid = fopen(pathstr, 'w');
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# annual marginal deposit-gift share screen\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- data basis: `%s`\n', char(settings.data_basis));
fprintf(fid, '- fixed annual anchor:\n');
fprintf(fid, '  - mean age first birth target read `%.2f`\n', settings.anchor.target_read.mean_age_first_birth);
fprintf(fid, '  - share first births age `30+` target read `%.3f`\n', settings.anchor.target_read.share_first_birth_30_plus);
fprintf(fid, '  - childless at `50` target read `%.3f`\n', settings.anchor.target_read.childless_share_at_50);
fprintf(fid, '\n');
fprintf(fid, 'This branch keeps data-based gift incidence, but the gift only applies when it tips a gifted renter from renting into ownership.\n\n');

if isempty(candidate_table)
    fprintf(fid, 'No candidates evaluated.\n');
    return;
end

best = candidate_table(1, :);
fprintf(fid, '## best candidate\n\n');
fprintf(fid, '- label: `%s`\n', char(best.label(1)));
fprintf(fid, '- gift share: `%.2f`\n', best.gift_share);
fprintf(fid, '- owner-entry deposit gift: `%.2f`\n', best.owner_entry_deposit_gift);
fprintf(fid, '- owner-entry deposit age max: `%d`\n', best.owner_entry_deposit_age_max);
fprintf(fid, '- marginal-only gift rule: `%d`\n', best.marginal_only);
fprintf(fid, '- owner share `25-34`: `%.3f`\n', best.eval_owner_share_25_34);
fprintf(fid, '- owner share `35-44`: `%.3f`\n', best.eval_owner_share_35_44);
fprintf(fid, '- mortgaged-owner share under `35`: `%.3f`\n', best.eval_mortgaged_owner_share_under_35);
fprintf(fid, '- vote per mass at `q = %.2f`: `%.3f`\n', cfg.eval_price, best.eval_vote_per_mass);
fprintf(fid, '- unique crossing: `%d`\n', best.crossing_is_unique);
if best.crossing_is_unique
    fprintf(fid, '- refined crossing price: `%.3f`\n', best.crossing_refined_price);
end
fprintf(fid, '\n');

fprintf(fid, '## top rows\n\n');
fprintf(fid, '| label | gift share | gift | mortgaged-owner <35 | owner 25-34 | vote @ eval | unique crossing |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|\n');
top_n = min(8, height(candidate_table));
for i = 1:top_n
    row = candidate_table(i, :);
    fprintf(fid, '| `%s` | %.2f | %.2f | %.3f | %.3f | %.3f | %d |\n', ...
        char(row.label(1)), row.gift_share, row.owner_entry_deposit_gift, ...
        row.eval_mortgaged_owner_share_under_35, row.eval_owner_share_25_34, ...
        row.eval_vote_per_mass, row.crossing_is_unique);
end
end
