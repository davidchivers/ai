function run_fertility_annual_starter_home_grid_test()
% run_fertility_annual_starter_home_grid_test.m
%
% Direct test of whether housing lumpiness is a key annual-model problem.
% Compare the live annual no-mix baseline under:
% 1. the current uniform owner grid
% 2. a denser low-end starter-home / flat grid

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
settings = build_settings(cfg, spec);
ensure_transition_matrix(settings.base_overrides.transition_matrix_file);

candidates = build_candidates(settings);
candidate_rows = repmat(empty_candidate_row(), numel(candidates), 1);
path_rows = repmat(empty_path_row(), 0, 1);

for i = 1:numel(candidates)
    fprintf('\n=== annual starter-home grid test candidate %d / %d ===\n', i, numel(candidates));
    [candidate_rows(i), candidate_path_rows] = evaluate_candidate(candidates(i), settings, cfg); %#ok<AGROW>
    path_rows = [path_rows; candidate_path_rows]; %#ok<AGROW>
end

candidate_table = struct2table(candidate_rows);
path_table = struct2table(path_rows);
writetable(candidate_table, fullfile(out_dir, 'fertility_annual_starter_home_grid_test_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_starter_home_grid_test_path.csv'));
write_summary_note(fullfile(out_dir, 'fertility_annual_starter_home_grid_test.md'), candidate_table, path_table, settings, cfg);
end

function settings = build_settings(cfg, spec)
settings = struct();
settings.eval_price = cfg.eval_price;
settings.eval_age = cfg.eval_age;
settings.anchor = spec.anchor;
settings.target_ranges = cfg.target_ranges;
settings.homeownership_target_ranges = cfg.homeownership_target_ranges;
settings.wealth_target_ranges = cfg.wealth_target_ranges;
settings.base_overrides = cfg.overrides;
settings.base_overrides.I = 24;
settings.base_overrides.J = 8;
settings.housingmin = 0.0;
settings.housingmax = spec.anchor.housingmax;
settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 3.00, 3.50, 4.00, 5.00];
settings.fixed_finance = struct( ...
    'owner_mortgage_CC', settings.anchor.owner_mortgage_CC, ...
    'owner_entry_mortgage_floor', settings.anchor.baseline_owner_entry_mortgage_floor, ...
    'owner_entry_payment_to_income_cap', settings.anchor.baseline_owner_entry_payment_to_income_cap, ...
    'owner_mortgage_amortization', settings.anchor.owner_mortgage_amortization, ...
    'owner_mortgage_spread', settings.anchor.owner_mortgage_spread);
settings.uniform_grid = linspace(settings.housingmin, settings.housingmax, settings.base_overrides.J);
settings.starter_grid = [0.0, 0.5, 1.0, 1.5, 2.25, 3.5, 5.5, 15.0];
end

function candidates = build_candidates(settings)
candidates = repmat(struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'housing_grid', [], ...
    'first_owner_house', NaN, ...
    'second_owner_house', NaN), 2, 1);

candidates(1).candidate_id = 1;
candidates(1).label = "uniform owner ladder";
candidates(1).housing_grid = settings.uniform_grid;
candidates(1).first_owner_house = settings.uniform_grid(2);
candidates(1).second_owner_house = settings.uniform_grid(3);

candidates(2).candidate_id = 2;
candidates(2).label = "starter-home owner ladder";
candidates(2).housing_grid = settings.starter_grid;
candidates(2).first_owner_house = settings.starter_grid(2);
candidates(2).second_owner_house = settings.starter_grid(3);
end

function [row, path_rows] = evaluate_candidate(candidate, settings, cfg)
overrides = build_overrides(candidate, settings, cfg);

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

path_rows = repmat(empty_path_row(), n, 1);
for i = 1:n
    point = evaluate_point(price_grid(i), cfg.rbPos, overrides, cfg.eval_age, price_grid(i) == settings.eval_price);
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
    if price_grid(i) == settings.eval_price
        wealth_eval = point.wealth_metrics;
    end

    path_rows(i).candidate_id = candidate.candidate_id;
    path_rows(i).label = candidate.label;
    path_rows(i).house_price = price_grid(i);
    path_rows(i).mean_age_first_birth = point.mean_age_first_birth;
    path_rows(i).share_first_birth_30_plus = point.share_first_birth_30_plus;
    path_rows(i).childless_share_at_50 = point.childless_share_at_50;
    path_rows(i).owner_share_25_34 = point.owner_shares(1);
    path_rows(i).owner_share_35_44 = point.owner_shares(2);
    path_rows(i).owner_share_45_54 = point.owner_shares(3);
    path_rows(i).vote_per_mass = point.vote_per_mass;
    path_rows(i).debt_per_mass = point.debt_per_mass;
    path_rows(i).mass_error = point.max_mass_error;
end

annual_scores = score_annual_fertility_targets( ...
    settings.target_ranges, ...
    mean_age_first_birth(price_grid == settings.eval_price), ...
    share_first_birth_30_plus(price_grid == settings.eval_price), ...
    childless_share_at_50(price_grid == settings.eval_price), ...
    support_shares(price_grid == settings.eval_price, :));
home_scores = score_annual_homeownership_support_targets( ...
    settings.homeownership_target_ranges, ...
    [owner_share_25_34(price_grid == settings.eval_price), owner_share_35_44(price_grid == settings.eval_price), owner_share_45_54(price_grid == settings.eval_price)]);
wealth_scores = score_annual_wealth_support_targets(settings.wealth_target_ranges, wealth_eval);
crossing = summarize_crossing(price_grid, vote_per_mass);

row = empty_candidate_row();
row.candidate_id = candidate.candidate_id;
row.label = candidate.label;
row.first_owner_house = candidate.first_owner_house;
row.second_owner_house = candidate.second_owner_house;
row.eval_mean_age_first_birth = mean_age_first_birth(price_grid == settings.eval_price);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(price_grid == settings.eval_price);
row.eval_childless_share_at_50 = childless_share_at_50(price_grid == settings.eval_price);
row.eval_owner_share_25_34 = owner_share_25_34(price_grid == settings.eval_price);
row.eval_owner_share_35_44 = owner_share_35_44(price_grid == settings.eval_price);
row.eval_owner_share_45_54 = owner_share_45_54(price_grid == settings.eval_price);
row.eval_debt_holder_share_under_35 = wealth_eval.debt_holder_share_under_35;
row.eval_mortgaged_owner_share_under_35 = wealth_eval.mortgaged_owner_share_under_35;
row.eval_vote_per_mass = vote_per_mass(price_grid == settings.eval_price);
row.eval_debt_per_mass = debt_per_mass(price_grid == settings.eval_price);
row.primary_pass = double(annual_scores.primary_pass);
row.homeownership_pass = double(home_scores.pass);
row.wealth_pass = double(wealth_scores.pass);
row.crossing_is_unique = double(crossing.is_unique);
row.crossing_refined_price = crossing.refined_price;
row.sign_changes = crossing.sign_changes;
row.max_mass_error = max(mass_error);
end

function overrides = build_overrides(candidate, settings, cfg)
anchor = settings.anchor;
overrides = settings.base_overrides;
overrides.housing_grid = candidate.housing_grid;
overrides.birth_utility_by_parity = anchor.birth_utility_by_parity;
overrides.child_utility = anchor.child_utility;
overrides.birth_cost = anchor.birth_cost;
overrides.birth_price_coeff = anchor.birth_price_coeff;
overrides.lambda_crowd = anchor.lambda_crowd;
overrides.psi_crowd = 0.70;
overrides.birth_age_weights = cfg.target_first_birth_age_share_annual;
overrides.realized_birth_weights = ones(size(cfg.target_first_birth_age_share_annual));
overrides.first_birth_realized_weights = anchor.first_birth_realized_weights;
overrides.housingmax = max(candidate.housing_grid);
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
overrides.owner_entry_deposit_age_max = anchor.owner_entry_age_max;
overrides.ka = anchor.ka;
overrides.rent_markup = anchor.rent_markup;
overrides.parental_transfer_share = 0.0;
overrides.parental_transfer_b_boost = 0.0;
overrides.initial_b_points = anchor.baseline_initial_b_points;
overrides.initial_b_shares = anchor.baseline_initial_b_shares;
end

function point = evaluate_point(a_price, rbPos, overrides, eval_age, compute_wealth)
if nargin < 5
    compute_wealth = false;
end

[~, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([a_price, rbPos], overrides);
ages = diagnostics.ages(:);
first_birth_mass = diagnostics.first_birth_mass_by_age(:);
first_birth_dist = first_birth_mass ./ max(sum(first_birth_mass), 1e-12);
age50_idx = find(ages == eval_age, 1);
owner_shares = owner_share_by_age(diagnostics);

point = struct();
point.mean_age_first_birth = sum(ages .* first_birth_dist);
point.share_first_birth_30_plus = sum(first_birth_dist(ages >= 30));
point.childless_share_at_50 = diagnostics.parity_dist_by_age(age50_idx, 1);
point.vote_per_mass = totalvote / max(sum(diagnostics.age_mass(:)), 1e-12);
point.debt_per_mass = debtstock / max(sum(diagnostics.age_mass(:)), 1e-12);
point.max_mass_error = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));
point.owner_shares = [ ...
    weighted_owner_share(diagnostics.age_mass(:), owner_shares .* diagnostics.age_mass(:), ages, 25, 34), ...
    weighted_owner_share(diagnostics.age_mass(:), owner_shares .* diagnostics.age_mass(:), ages, 35, 44), ...
    weighted_owner_share(diagnostics.age_mass(:), owner_shares .* diagnostics.age_mass(:), ages, 45, 54)];
point.support_shares = [ ...
    sum(first_birth_dist(ages >= 25 & ages <= 29)), ...
    sum(first_birth_dist(ages >= 30 & ages <= 34)), ...
    sum(first_birth_dist(ages >= 35 & ages <= 39)), ...
    sum(first_birth_dist(ages >= 40 & ages <= 44))];
point.wealth_metrics = empty_wealth_metrics();
if compute_wealth
    point.wealth_metrics = wealth_metrics(diagnostics);
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

function metrics = wealth_metrics(diagnostics)
metrics = empty_wealth_metrics();
metrics.debt_holder_share_under_35 = age_group_share_metric(diagnostics, 25, 34, "debt_holder");
metrics.debt_holder_share_35_44 = age_group_share_metric(diagnostics, 35, 44, "debt_holder");
metrics.mortgaged_owner_share_under_35 = age_group_share_metric(diagnostics, 25, 34, "mortgaged_owner");
metrics.mortgaged_owner_share_35_44 = age_group_share_metric(diagnostics, 35, 44, "mortgaged_owner");
metrics.mortgaged_owner_share_45_54 = age_group_share_metric(diagnostics, 45, 54, "mortgaged_owner");
metrics.mortgaged_owner_share_55_64 = age_group_share_metric(diagnostics, 55, 64, "mortgaged_owner");
end

function share = age_group_share_metric(diagnostics, age_lo, age_hi, metric_name)
[num, den] = extract_age_group_mass_metric(diagnostics, age_lo, age_hi, metric_name);
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

function crossing = summarize_crossing(price_grid, vote_grid)
crossing = struct('is_unique', false, 'refined_price', NaN, 'sign_changes', 0);

sign_changes = 0;
first_crossing = NaN;
for i = 1:(numel(price_grid) - 1)
    v0 = vote_grid(i);
    v1 = vote_grid(i + 1);
    if v0 == 0
        sign_changes = sign_changes + 1;
        if isnan(first_crossing)
            first_crossing = price_grid(i);
        end
    elseif v0 * v1 < 0
        sign_changes = sign_changes + 1;
        if isnan(first_crossing)
            weight = abs(v0) / (abs(v0) + abs(v1));
            first_crossing = price_grid(i) + weight * (price_grid(i + 1) - price_grid(i));
        end
    end
end

crossing.sign_changes = sign_changes;
crossing.is_unique = (sign_changes == 1);
if crossing.is_unique
    crossing.refined_price = first_crossing;
end
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
    'first_owner_house', NaN, ...
    'second_owner_house', NaN, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_childless_share_at_50', NaN, ...
    'eval_owner_share_25_34', NaN, ...
    'eval_owner_share_35_44', NaN, ...
    'eval_owner_share_45_54', NaN, ...
    'eval_debt_holder_share_under_35', NaN, ...
    'eval_mortgaged_owner_share_under_35', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'eval_debt_per_mass', NaN, ...
    'primary_pass', 0, ...
    'homeownership_pass', 0, ...
    'wealth_pass', 0, ...
    'crossing_is_unique', 0, ...
    'crossing_refined_price', NaN, ...
    'sign_changes', NaN, ...
    'max_mass_error', NaN);
end

function row = empty_path_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'house_price', NaN, ...
    'mean_age_first_birth', NaN, ...
    'share_first_birth_30_plus', NaN, ...
    'childless_share_at_50', NaN, ...
    'owner_share_25_34', NaN, ...
    'owner_share_35_44', NaN, ...
    'owner_share_45_54', NaN, ...
    'vote_per_mass', NaN, ...
    'debt_per_mass', NaN, ...
    'mass_error', NaN);
end

function write_summary_note(pathstr, candidate_table, path_table, settings, cfg)
fid = fopen(pathstr, 'w');
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# annual starter-home grid test\n\n');
fprintf(fid, 'This is a direct test of whether owner-housing lumpiness is a key annual-model problem. The annual no-mix baseline is held fixed, and only the owner housing ladder is changed.\n\n');
fprintf(fid, '## Fixed annual baseline\n\n');
fprintf(fid, '- birth utility by parity: `[%.3f, %.3f, %.3f]`\n', settings.anchor.birth_utility_by_parity);
fprintf(fid, '- child utility: `%.3f`\n', settings.anchor.child_utility);
fprintf(fid, '- birth cost: `%.3f`\n', settings.anchor.birth_cost);
fprintf(fid, '- price-sensitive birth cost: `%.2f`\n', settings.anchor.birth_price_coeff);
fprintf(fid, '- crowding: `lambda = %.2f`, `psi = 0.70`\n', settings.anchor.lambda_crowd);
fprintf(fid, '- owner-entry mortgage floor: `%.2f`\n', settings.fixed_finance.owner_entry_mortgage_floor);
fprintf(fid, '- owner-entry PTI cap: `%.2f`\n', settings.fixed_finance.owner_entry_payment_to_income_cap);
fprintf(fid, '- owner-mortgage amortization: `%.2f`\n\n', settings.fixed_finance.owner_mortgage_amortization);

fprintf(fid, '## Compared ladders\n\n');
fprintf(fid, '| Case | First owner house | Second owner house | Grid |\n');
fprintf(fid, '|---|---:|---:|---|\n');
fprintf(fid, '| `uniform owner ladder` | %.3f | %.3f | `%s` |\n', candidate_table.first_owner_house(1), candidate_table.second_owner_house(1), format_grid(settings.uniform_grid));
fprintf(fid, '| `starter-home owner ladder` | %.3f | %.3f | `%s` |\n\n', candidate_table.first_owner_house(2), candidate_table.second_owner_house(2), format_grid(settings.starter_grid));

fprintf(fid, '## Eval-price comparison (`q = %.2f`)\n\n', cfg.eval_price);
fprintf(fid, '| Case | Mean age | Share 30+ | Childless @50 | Owner 25-34 | Owner 35-44 | Debt <35 | Mort owner <35 | Vote/mass | Unique crossing | Crossing |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(candidate_table)
    row = candidate_table(i, :);
    fprintf(fid, '| `%s` | %.2f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %d | %.3f |\n', ...
        char(row.label(1)), row.eval_mean_age_first_birth, row.eval_share_first_birth_30_plus, ...
        row.eval_childless_share_at_50, row.eval_owner_share_25_34, row.eval_owner_share_35_44, ...
        row.eval_debt_holder_share_under_35, row.eval_mortgaged_owner_share_under_35, ...
        row.eval_vote_per_mass, row.crossing_is_unique, row.crossing_refined_price);
end
fprintf(fid, '\n');

fprintf(fid, '## Price paths\n\n');
fprintf(fid, '| Case | House price | Owner 25-34 | Vote/mass | Mean age | Share 30+ |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|\n');
for i = 1:height(path_table)
    row = path_table(i, :);
    fprintf(fid, '| `%s` | %.2f | %.3f | %.3f | %.2f | %.3f |\n', ...
        char(row.label(1)), row.house_price, row.owner_share_25_34, row.vote_per_mass, ...
        row.mean_age_first_birth, row.share_first_birth_30_plus);
end
fprintf(fid, '\n');

fprintf(fid, '## Read\n\n');
fprintf(fid, '- If the starter-home ladder raises young mortgaged ownership materially without blowing up fertility or the crossing, then housing lumpiness is a real annual mechanism.\n');
fprintf(fid, '- If it barely moves the annual read, then the missing mechanism is less about owner-size lumpiness and more about qualification / household structure.\n');
end

function out = format_grid(grid)
parts = arrayfun(@(x) sprintf('%.2f', x), grid, 'UniformOutput', false);
out = strjoin(parts, ', ');
end
