function run_fertility_annual_owner_mortgage_state_screen(mode)
% run_fertility_annual_owner_mortgage_state_screen.m
%
% Freeze the current best annual working point and test a minimal
% "owner with mortgage" state proxy: while young, any owner position must
% carry at least some mortgage share. This separates young mortgaged
% owners from outright owners without adding a full extra state dimension.

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
    fprintf('\n=== annual owner-mortgage-state candidate %d / %d ===\n', i, numel(candidates));
    candidate_rows(i) = evaluate_candidate(candidates(i), settings, cfg);
end

candidate_table = struct2table(candidate_rows);
candidate_table = sortrows(candidate_table, ...
    {'primary_pass', 'homeownership_pass', 'wealth_pass', 'crossing_is_unique', 'score'}, ...
    {'descend', 'descend', 'descend', 'descend', 'ascend'});
writetable(candidate_table, fullfile(out_dir, 'fertility_annual_owner_mortgage_state_screen_candidates.csv'));
write_summary_note(fullfile(out_dir, 'fertility_annual_owner_mortgage_state_screen.md'), candidate_table, settings, cfg);
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
settings.current_age_weights = cfg.target_first_birth_age_share_annual;

base_overrides = cfg.overrides;
switch char(settings.mode)
    case 'smoke'
        base_overrides.I = 12;
        base_overrides.J = 4;
        settings.crossing_price_grid = [1.50, 2.00, 5.00];
        settings.min_mortgage_share_grid = [0.05, 0.10, 0.15, 0.20, 0.25];
        settings.min_mortgage_age_max_grid = [29, 34, 39];
    case 'confirm'
        base_overrides.I = 20;
        base_overrides.J = 6;
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.50, 5.00];
        settings.min_mortgage_share_grid = [0.05, 0.10, 0.15, 0.20, 0.25, 0.30];
        settings.min_mortgage_age_max_grid = [29, 34, 39];
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
settings.fixed_fertility = struct( ...
    'label', string(settings.anchor.label), ...
    'birth_utility_by_parity', settings.anchor.birth_utility_by_parity, ...
    'child_utility', settings.anchor.child_utility, ...
    'birth_cost', settings.anchor.birth_cost, ...
    'birth_price_coeff', settings.anchor.birth_price_coeff, ...
    'lambda_crowd', settings.anchor.lambda_crowd, ...
    'first_birth_realized_weights', settings.anchor.first_birth_realized_weights);
end

function candidates = build_candidates(settings)
idx = 0;
candidates = repmat(empty_candidate_spec(), 0, 1);

idx = idx + 1;
candidates(idx) = build_candidate_spec(idx, "baseline_no_young_mortgage_state", 0.0, 0);

for ishare = 1:numel(settings.min_mortgage_share_grid)
    share = settings.min_mortgage_share_grid(ishare);
    for iage = 1:numel(settings.min_mortgage_age_max_grid)
        age_max = settings.min_mortgage_age_max_grid(iage);
        idx = idx + 1;
        candidates(idx) = build_candidate_spec( ...
            idx, ...
            sprintf('young owner min mortgage %.2f | age max %d', share, age_max), ...
            share, age_max);
    end
end
end

function spec = empty_candidate_spec()
spec = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'owner_min_mortgage_share', NaN, ...
    'owner_min_mortgage_age_max', NaN);
end

function spec = build_candidate_spec(candidate_id, label, owner_min_mortgage_share, owner_min_mortgage_age_max)
spec = empty_candidate_spec();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.owner_min_mortgage_share = owner_min_mortgage_share;
spec.owner_min_mortgage_age_max = owner_min_mortgage_age_max;
end

function row = evaluate_candidate(candidate, settings, cfg)
overrides = build_overrides(candidate, settings, cfg);

price_grid = settings.crossing_price_grid;
n = numel(price_grid);
avg_birth_rate = NaN(n, 1);
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

for i = 1:n
    point = evaluate_point(price_grid(i), cfg.rbPos, overrides, cfg.eval_age, price_grid(i) == settings.eval_price);
    avg_birth_rate(i) = point.avg_birth_rate;
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
end

eval_idx = find(price_grid == settings.eval_price, 1);
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
max_cross_vote = max(vote_per_mass);
crossing_gap_to_zero = min(abs(vote_per_mass));
mass_penalty = 1e12 * max(max(mass_error) - 1e-8, 0);
score = 4.0 * annual_scores.primary_score + home_scores.score + wealth_scores.score + max(0, -max_cross_vote) ...
    + 0.5 * double(~crossing.is_unique) + mass_penalty;

row = empty_candidate_row();
row.candidate_id = candidate.candidate_id;
row.label = candidate.label;
row.owner_min_mortgage_share = candidate.owner_min_mortgage_share;
row.owner_min_mortgage_age_max = candidate.owner_min_mortgage_age_max;
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
row.eval_mortgage_share_among_owners_under_35 = wealth_eval.mortgaged_owner_share_under_35 / max(owner_share_25_34(eval_idx), 1e-12);
row.eval_vote_per_mass = vote_per_mass(eval_idx);
row.eval_debt_per_mass = debt_per_mass(eval_idx);
row.primary_pass = double(annual_scores.primary_pass);
row.homeownership_pass = double(home_scores.pass);
row.wealth_pass = double(wealth_scores.pass);
row.crossing_is_unique = double(crossing.is_unique);
row.crossing_refined_price = crossing.refined_price;
row.crossing_gap_to_zero = crossing_gap_to_zero;
row.score = score;
end

function overrides = build_overrides(candidate, settings, cfg)
anchor = settings.anchor;
fertility = settings.fixed_fertility;
overrides = settings.base_overrides;
overrides.birth_utility_by_parity = fertility.birth_utility_by_parity;
overrides.child_utility = fertility.child_utility;
overrides.birth_cost = fertility.birth_cost;
overrides.birth_price_coeff = fertility.birth_price_coeff;
overrides.lambda_crowd = fertility.lambda_crowd;
overrides.birth_age_weights = settings.current_age_weights;
overrides.realized_birth_weights = ones(size(settings.current_age_weights));
overrides.first_birth_realized_weights = fertility.first_birth_realized_weights;
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
overrides.owner_min_mortgage_share = candidate.owner_min_mortgage_share;
overrides.owner_min_mortgage_age_max = candidate.owner_min_mortgage_age_max;
overrides.owner_entry_payment_to_income_cap = settings.fixed_finance.owner_entry_payment_to_income_cap;
overrides.owner_entry_payment_to_income_age_max = anchor.owner_entry_payment_to_income_age_max;
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
point.avg_birth_rate = diagnostics.avg_birth_rate;
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

valid_mass = isfinite(dens) & dens > 0;
den = sum(dens(valid_mass), 'all');
num = sum(dens(valid_mass & metric_mask), 'all');
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
crossing.is_unique = sign_change_count == 1;
crossing.sign_change_count = sign_change_count;
crossing.refined_price = refined_price;
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'owner_min_mortgage_share', NaN, ...
    'owner_min_mortgage_age_max', NaN, ...
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
    'eval_mortgage_share_among_owners_under_35', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'eval_debt_per_mass', NaN, ...
    'primary_pass', NaN, ...
    'homeownership_pass', NaN, ...
    'wealth_pass', NaN, ...
    'crossing_is_unique', NaN, ...
    'crossing_refined_price', NaN, ...
    'crossing_gap_to_zero', NaN, ...
    'score', NaN);
end

function write_summary_note(note_path, candidate_table, settings, cfg)
fid = fopen(note_path, 'w');
if fid == -1
    error('Could not open %s for writing.', note_path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Annual owner mortgage-state screen\n\n');
fprintf(fid, 'This workflow freezes the current best annual working point and then imposes a minimal young-owner mortgage-state rule: below a chosen age, any owner position must carry at least some mortgage share.\n\n');
fprintf(fid, '## Fixed working point\n\n');
fprintf(fid, '- fertility anchor:\n');
fprintf(fid, '  - `%s`\n', char(settings.fixed_fertility.label));
fprintf(fid, '  - `phi0 = %.3f`\n', settings.fixed_fertility.birth_utility_by_parity(1));
fprintf(fid, '  - `child utility = %.3f`\n', settings.fixed_fertility.child_utility);
fprintf(fid, '  - `birth cost = %.3f`\n', settings.fixed_fertility.birth_cost);
fprintf(fid, '  - `kappa = %.2f`\n', settings.fixed_fertility.birth_price_coeff);
fprintf(fid, '  - `lambda = %.2f`\n', settings.fixed_fertility.lambda_crowd);
fprintf(fid, '- finance anchor:\n');
fprintf(fid, '  - owner mortgage `CC = %.2f`\n', settings.fixed_finance.owner_mortgage_CC);
fprintf(fid, '  - entry mortgage floor `%.2f`\n', settings.fixed_finance.owner_entry_mortgage_floor);
fprintf(fid, '  - entry PTI cap `%.2f`\n', settings.fixed_finance.owner_entry_payment_to_income_cap);
fprintf(fid, '  - amortization `%.2f`\n', settings.fixed_finance.owner_mortgage_amortization);
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', settings.base_overrides.I, settings.base_overrides.J);
fprintf(fid, '- crossing grid: `%s`\n\n', strjoin(compose('%.2f', settings.crossing_price_grid), ', '));

fprintf(fid, '## Main read\n\n');
fprintf(fid, '- candidates screened: `%d`\n', height(candidate_table));
fprintf(fid, '- fertility passes: `%d`\n', sum(candidate_table.primary_pass == 1));
fprintf(fid, '- homeownership passes: `%d`\n', sum(candidate_table.homeownership_pass == 1));
fprintf(fid, '- wealth passes: `%d`\n', sum(candidate_table.wealth_pass == 1));
fprintf(fid, '- unique crossings: `%d`\n\n', sum(candidate_table.crossing_is_unique == 1));

fprintf(fid, '## Top candidates\n\n');
fprintf(fid, '| Rank | Candidate | Owner 25-34 | Mort owner <35 | Mort share / owners <35 | Mean age | Share 30+ | Childless @50 | Vote/mass @2.0 | Crossing | Score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
top_n = min(12, height(candidate_table));
for i = 1:top_n
    crossing_text = 'none';
    if candidate_table.crossing_is_unique(i) == 1
        crossing_text = sprintf('~%.3f', candidate_table.crossing_refined_price(i));
    end
    label_text = strrep(char(candidate_table.label(i)), '|', '&#124;');
    fprintf(fid, '| %d | %s | `%.3f` | `%.3f` | `%.3f` | `%.2f` | `%.3f` | `%.3f` | `%.3f` | %s | `%.4f` |\n', ...
        i, label_text, candidate_table.eval_owner_share_25_34(i), candidate_table.eval_mortgaged_owner_share_under_35(i), ...
        candidate_table.eval_mortgage_share_among_owners_under_35(i), candidate_table.eval_mean_age_first_birth(i), ...
        candidate_table.eval_share_first_birth_30_plus(i), candidate_table.eval_childless_share_at_50(i), ...
        candidate_table.eval_vote_per_mass(i), crossing_text, candidate_table.score(i));
end
fprintf(fid, '\n');

best = candidate_table(1, :);
target_owner_25_34 = find_target_reference(cfg.homeownership_target_ranges, "owner_share_25_34");
target_mort_owner = find_target_reference(cfg.wealth_target_ranges, "mortgaged_owner_share_under_35");
target_mort_share_among_owners = target_mort_owner / target_owner_25_34;
fprintf(fid, '## Best candidate\n\n');
fprintf(fid, '- label: `%s`\n', char(best.label));
fprintf(fid, '- owner share `25-34`: `%.3f`\n', best.eval_owner_share_25_34);
fprintf(fid, '- mortgaged-owner share under `35`: `%.3f`\n', best.eval_mortgaged_owner_share_under_35);
fprintf(fid, '- mortgage share among young owners: `%.3f`\n', best.eval_mortgage_share_among_owners_under_35);
fprintf(fid, '- target mortgage share among young owners: `%.3f`\n', target_mort_share_among_owners);
fprintf(fid, '- mean age first birth: `%.2f`\n', best.eval_mean_age_first_birth);
fprintf(fid, '- share first births age `30+`: `%.3f`\n', best.eval_share_first_birth_30_plus);
fprintf(fid, '- childless share at `50`: `%.3f`\n', best.eval_childless_share_at_50);
fprintf(fid, '- vote per mass at `q = %.2f`: `%.3f`\n', settings.eval_price, best.eval_vote_per_mass);
if best.crossing_is_unique == 1
    fprintf(fid, '- crossing price: `%.6f`\n', best.crossing_refined_price);
elseif isfinite(best.crossing_refined_price)
    fprintf(fid, '- crossing price: `none (not unique; first interpolated zero ~%.6f)`\n', best.crossing_refined_price);
else
    fprintf(fid, '- crossing price: `none`\n');
end
end

function value = find_target_reference(ranges, name)
all_targets = [ranges.support(:); ranges.validation(:)];
idx = find(strcmp(string({all_targets.name}), string(name)), 1);
value = all_targets(idx).reference;
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end
