function run_fertility_annual_soft_owner_entry_menu_screen(mode)
% run_fertility_annual_soft_owner_entry_menu_screen.m
%
% Freeze the current best annual working point and test a softer entry
% menu: most households keep the baseline finance block, while a small
% share gets access to a more mortgage-heavy owner-entry mode with looser
% underwriting. The goal is to raise young mortgaged ownership without
% collapsing ownership overall.

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
    fprintf('\n=== annual soft owner-entry menu candidate %d / %d ===\n', i, numel(candidates));
    candidate_rows(i) = evaluate_candidate(candidates(i), settings, cfg);
end

candidate_table = struct2table(candidate_rows);
candidate_table = sortrows(candidate_table, ...
    {'primary_pass', 'homeownership_pass', 'wealth_pass', 'crossing_is_unique', 'score'}, ...
    {'descend', 'descend', 'descend', 'descend', 'ascend'});
writetable(candidate_table, fullfile(out_dir, 'fertility_annual_soft_owner_entry_menu_screen_candidates.csv'));
write_summary_note(fullfile(out_dir, 'fertility_annual_soft_owner_entry_menu_screen.md'), candidate_table, settings, cfg);
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
settings.very_front_loaded_realized = repelem([1.00, 0.29, 0.05, 0.012], 5);

base_overrides = cfg.overrides;
switch char(settings.mode)
    case 'smoke'
        base_overrides.I = 12;
        base_overrides.J = 4;
        settings.crossing_price_grid = [1.50, 2.00, 5.00];
        settings.mortgage_type_share_grid = [0.10, 0.20];
        settings.entry_ltv_grid = [0.50, 0.70];
        settings.pti_grid = [0.35, 0.40];
        settings.owner_cc_grid = [0.97];
    case 'confirm'
        base_overrides.I = 20;
        base_overrides.J = 6;
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.50, 5.00];
        settings.mortgage_type_share_grid = [0.10, 0.15, 0.20, 0.30];
        settings.entry_ltv_grid = [0.45, 0.50, 0.60, 0.70];
        settings.pti_grid = [0.35, 0.40, 0.45];
        settings.owner_cc_grid = [0.97, 0.99];
    otherwise
        error('Unknown mode "%s". Use "smoke" or "confirm".', mode);
end

settings.base_overrides = base_overrides;
settings.fixed_fertility = struct( ...
    'label', "best_joint_reanchor", ...
    'birth_utility_by_parity', [1.50, 1.62, 1.55], ...
    'child_utility', 0.025, ...
    'birth_cost', 0.045, ...
    'birth_price_coeff', 0.16, ...
    'lambda_crowd', 0.10, ...
    'first_birth_realized_weights', settings.very_front_loaded_realized);
settings.baseline_finance = struct( ...
    'owner_mortgage_CC', 0.97, ...
    'owner_entry_mortgage_floor', 0.40, ...
    'owner_entry_payment_to_income_cap', 0.30, ...
    'owner_mortgage_amortization', 0.02, ...
    'owner_mortgage_spread', settings.anchor.owner_mortgage_spread);
end

function candidates = build_candidates(settings)
idx = 0;
candidates = repmat(empty_candidate_spec(), 0, 1);

idx = idx + 1;
candidates(idx) = build_candidate_spec(idx, "baseline_no_menu", 0.0, 0.40, 0.30, 0.97);

for is = 1:numel(settings.mortgage_type_share_grid)
    share = settings.mortgage_type_share_grid(is);
    for il = 1:numel(settings.entry_ltv_grid)
        entry_ltv = settings.entry_ltv_grid(il);
        for ip = 1:numel(settings.pti_grid)
            pti = settings.pti_grid(ip);
            for ic = 1:numel(settings.owner_cc_grid)
                owner_cc = settings.owner_cc_grid(ic);
                idx = idx + 1;
                candidates(idx) = build_candidate_spec( ...
                    idx, ...
                    sprintf('mortgage-entry share %.2f | heavy LTV %.2f | heavy PTI %.2f | heavy mCC %.2f', ...
                        share, entry_ltv, pti, owner_cc), ...
                    share, entry_ltv, pti, owner_cc);
            end
        end
    end
end
end

function spec = empty_candidate_spec()
spec = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'mortgage_type_share', NaN, ...
    'heavy_entry_ltv', NaN, ...
    'heavy_pti', NaN, ...
    'heavy_owner_cc', NaN);
end

function spec = build_candidate_spec(candidate_id, label, mortgage_type_share, heavy_entry_ltv, heavy_pti, heavy_owner_cc)
spec = empty_candidate_spec();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.mortgage_type_share = mortgage_type_share;
spec.heavy_entry_ltv = heavy_entry_ltv;
spec.heavy_pti = heavy_pti;
spec.heavy_owner_cc = heavy_owner_cc;
end

function row = evaluate_candidate(candidate, settings, cfg)
[override_list, weights] = build_type_list(candidate, settings, cfg);

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
    point = evaluate_mixture_point(price_grid(i), cfg.rbPos, override_list, weights, settings.eval_age, price_grid(i) == settings.eval_price);
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
row.mortgage_type_share = candidate.mortgage_type_share;
row.heavy_entry_ltv = candidate.heavy_entry_ltv;
row.heavy_pti = candidate.heavy_pti;
row.heavy_owner_cc = candidate.heavy_owner_cc;
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

function [override_list, weights] = build_type_list(candidate, settings, cfg)
baseline = build_overrides(settings.fixed_fertility, settings.baseline_finance, settings.anchor, settings.base_overrides, settings.current_age_weights);

override_list = {};
weights = [];

baseline_share = 1.0 - candidate.mortgage_type_share;
if baseline_share > 0
    override_list{end + 1} = baseline; %#ok<AGROW>
    weights(end + 1) = baseline_share; %#ok<AGROW>
end

if candidate.mortgage_type_share > 0
    heavy_finance = settings.baseline_finance;
    heavy_finance.owner_mortgage_CC = candidate.heavy_owner_cc;
    heavy_finance.owner_entry_mortgage_floor = candidate.heavy_entry_ltv;
    heavy_finance.owner_entry_payment_to_income_cap = candidate.heavy_pti;
    heavy = build_overrides(settings.fixed_fertility, heavy_finance, settings.anchor, settings.base_overrides, settings.current_age_weights);
    override_list{end + 1} = heavy; %#ok<AGROW>
    weights(end + 1) = candidate.mortgage_type_share; %#ok<AGROW>
end
end

function overrides = build_overrides(fertility, finance, anchor, base_overrides, current_age_weights)
overrides = base_overrides;
overrides.birth_utility_by_parity = fertility.birth_utility_by_parity;
overrides.child_utility = fertility.child_utility;
overrides.birth_cost = fertility.birth_cost;
overrides.birth_price_coeff = fertility.birth_price_coeff;
overrides.lambda_crowd = fertility.lambda_crowd;
overrides.birth_age_weights = current_age_weights;
overrides.realized_birth_weights = ones(size(current_age_weights));
overrides.first_birth_realized_weights = fertility.first_birth_realized_weights;
overrides.housingmax = anchor.housingmax;
overrides.theta_r = anchor.theta_r;
overrides.CC = anchor.CC;
overrides.owner_mortgage_CC = finance.owner_mortgage_CC;
overrides.owner_mortgage_spread = finance.owner_mortgage_spread;
overrides.owner_mortgage_amortization = finance.owner_mortgage_amortization;
overrides.owner_entry_b_floor = anchor.baseline_owner_entry_b_floor;
overrides.owner_entry_age_max = anchor.owner_entry_age_max;
overrides.owner_entry_mortgage_floor = finance.owner_entry_mortgage_floor;
overrides.owner_entry_mortgage_age_max = anchor.owner_entry_mortgage_age_max;
overrides.owner_min_mortgage_share = 0.0;
overrides.owner_min_mortgage_age_max = 0;
overrides.owner_entry_payment_to_income_cap = finance.owner_entry_payment_to_income_cap;
overrides.owner_entry_payment_to_income_age_max = anchor.owner_entry_payment_to_income_age_max;
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
vote_vals = zeros(nt, 1);
debt_vals = zeros(nt, 1);
birth_vals = zeros(nt, 1);
mass_err_vals = zeros(nt, 1);

ages = [];
first_birth_mass = [];
age_mass_mix = [];
owner_mass_mix = [];
age50_mass = 0.0;
childless50_mass = 0.0;
total_mass = 0.0;
mixture_diagnostics = cell(nt, 1);

for it = 1:nt
    [~, ~, ~, vote_vals(it), debt_vals(it), diagnostics] = SolveSS_fertility([a_price, rbPos], override_list{it});
    mixture_diagnostics{it} = diagnostics;
    birth_vals(it) = diagnostics.avg_birth_rate;
    mass_err_vals(it) = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));

    if isempty(ages)
        ages = diagnostics.ages(:);
        first_birth_mass = zeros(numel(ages), 1);
        age_mass_mix = zeros(numel(ages), 1);
        owner_mass_mix = zeros(numel(ages), 1);
    end

    age_mass_vec = diagnostics.age_mass(:);
    owner_share_vec = owner_share_by_age(diagnostics);
    owner_mass_vec = age_mass_vec .* owner_share_vec;

    first_birth_mass = first_birth_mass + weights(it) * diagnostics.first_birth_mass_by_age(:);
    age_mass_mix = age_mass_mix + weights(it) * age_mass_vec;
    owner_mass_mix = owner_mass_mix + weights(it) * owner_mass_vec;
    total_mass = total_mass + weights(it) * sum(age_mass_vec);

    age50_idx = find(diagnostics.ages == eval_age, 1);
    age50_mass = age50_mass + weights(it) * diagnostics.age_mass(age50_idx);
    childless50_mass = childless50_mass + weights(it) * diagnostics.age_mass(age50_idx) * diagnostics.parity_dist_by_age(age50_idx, 1);
end

first_birth_dist = first_birth_mass ./ max(sum(first_birth_mass), 1e-12);
totalvote = sum(weights(:) .* vote_vals);
debtstock = sum(weights(:) .* debt_vals);

point = struct();
point.avg_birth_rate = sum(weights(:) .* birth_vals) / sum(weights);
point.mean_age_first_birth = sum(ages .* first_birth_dist);
point.share_first_birth_30_plus = sum(first_birth_dist(ages >= 30));
point.childless_share_at_50 = childless50_mass / max(age50_mass, 1e-12);
point.vote_per_mass = totalvote / max(total_mass, 1e-12);
point.debt_per_mass = debtstock / max(total_mass, 1e-12);
point.max_mass_error = max(mass_err_vals);
point.support_shares = [ ...
    sum(first_birth_dist(ages >= 25 & ages <= 29)), ...
    sum(first_birth_dist(ages >= 30 & ages <= 34)), ...
    sum(first_birth_dist(ages >= 35 & ages <= 39)), ...
    sum(first_birth_dist(ages >= 40 & ages <= 44))];
point.owner_shares = [ ...
    weighted_owner_share(age_mass_mix, owner_mass_mix, ages, 25, 34), ...
    weighted_owner_share(age_mass_mix, owner_mass_mix, ages, 35, 44), ...
    weighted_owner_share(age_mass_mix, owner_mass_mix, ages, 45, 54)];
point.wealth_metrics = empty_wealth_metrics();
if compute_wealth_metrics
    point.wealth_metrics = mixture_wealth_metrics(mixture_diagnostics, weights);
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

function metrics = mixture_wealth_metrics(mixture_diagnostics, weights)
metrics = empty_wealth_metrics();
metrics.debt_holder_share_under_35 = age_group_share_metric(mixture_diagnostics, weights, 25, 34, "debt_holder");
metrics.debt_holder_share_35_44 = age_group_share_metric(mixture_diagnostics, weights, 35, 44, "debt_holder");
metrics.mortgaged_owner_share_under_35 = age_group_share_metric(mixture_diagnostics, weights, 25, 34, "mortgaged_owner");
metrics.mortgaged_owner_share_35_44 = age_group_share_metric(mixture_diagnostics, weights, 35, 44, "mortgaged_owner");
metrics.mortgaged_owner_share_45_54 = age_group_share_metric(mixture_diagnostics, weights, 45, 54, "mortgaged_owner");
metrics.mortgaged_owner_share_55_64 = age_group_share_metric(mixture_diagnostics, weights, 55, 64, "mortgaged_owner");
end

function share = age_group_share_metric(mixture_diagnostics, weights, age_lo, age_hi, metric_name)
num = 0.0;
den = 0.0;
for it = 1:numel(mixture_diagnostics)
    diagnostics = mixture_diagnostics{it};
    [num_it, den_it] = extract_age_group_mass_metric(diagnostics, age_lo, age_hi, metric_name);
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
    'mortgage_type_share', NaN, ...
    'heavy_entry_ltv', NaN, ...
    'heavy_pti', NaN, ...
    'heavy_owner_cc', NaN, ...
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

fprintf(fid, '# Annual soft owner-entry menu screen\n\n');
fprintf(fid, 'This workflow keeps the current best annual working point fixed and lets only a small share of households use a more mortgage-heavy owner-entry mode.\n\n');
fprintf(fid, '## Fixed working point\n\n');
fprintf(fid, '- fertility:\n');
fprintf(fid, '  - very front-loaded timing profile\n');
fprintf(fid, '  - `phi0 = 1.50`\n');
fprintf(fid, '  - `child utility = 0.025`\n');
fprintf(fid, '  - `birth cost = 0.045`\n');
fprintf(fid, '  - `kappa = 0.16`\n');
fprintf(fid, '  - `lambda = 0.10`\n');
fprintf(fid, '- baseline finance:\n');
fprintf(fid, '  - owner mortgage `CC = %.2f`\n', settings.baseline_finance.owner_mortgage_CC);
fprintf(fid, '  - entry mortgage floor `%.2f`\n', settings.baseline_finance.owner_entry_mortgage_floor);
fprintf(fid, '  - entry PTI cap `%.2f`\n', settings.baseline_finance.owner_entry_payment_to_income_cap);
fprintf(fid, '  - amortization `%.2f`\n', settings.baseline_finance.owner_mortgage_amortization);
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
best_crossing_text = 'none';
if best.crossing_is_unique == 1
    best_crossing_text = sprintf('~%.6f', best.crossing_refined_price);
elseif isfinite(best.crossing_refined_price)
    best_crossing_text = sprintf('none (not unique; first interpolated zero ~%.6f)', best.crossing_refined_price);
end
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
fprintf(fid, '- crossing: `%s`\n', best_crossing_text);
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
