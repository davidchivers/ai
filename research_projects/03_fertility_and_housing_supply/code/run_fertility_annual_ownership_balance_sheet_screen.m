function run_fertility_annual_ownership_balance_sheet_screen(mode)
% run_fertility_annual_ownership_balance_sheet_screen.m
%
% Minimal structural annual repair screen. This workflow holds the usable
% annual fertility anchor fixed and evaluates entrant-type ownership /
% balance-sheet mixtures rather than another one-parameter rescue wedge.
%
% Usage:
%   run_fertility_annual_ownership_balance_sheet_screen
%   run_fertility_annual_ownership_balance_sheet_screen('smoke')
%   run_fertility_annual_ownership_balance_sheet_screen('confirm')
%   run_fertility_annual_ownership_balance_sheet_screen('fast')
%   run_fertility_annual_ownership_balance_sheet_screen('full')
%
% Outputs:
%   notes/build/fertility_annual_ownership_balance_sheet_screen_candidates.csv
%   notes/build/fertility_annual_ownership_balance_sheet_screen_candidate_paths.csv
%   notes/build/fertility_annual_ownership_balance_sheet_screen_crossing_paths.csv
%   notes/build/fertility_annual_ownership_balance_sheet_screen_fertility_targets.csv
%   notes/build/fertility_annual_ownership_balance_sheet_screen_homeownership_targets.csv
%   notes/build/fertility_annual_ownership_balance_sheet_screen_wealth_targets.csv
%   notes/build/fertility_annual_ownership_balance_sheet_screen.md

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

fertility_target_table = build_target_table(cfg.target_ranges);
homeownership_target_table = build_target_table(cfg.homeownership_target_ranges);
wealth_target_table = build_target_table(cfg.wealth_target_ranges);
writetable(fertility_target_table, fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen_fertility_targets.csv'));
writetable(homeownership_target_table, fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen_homeownership_targets.csv'));
writetable(wealth_target_table, fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen_wealth_targets.csv'));

candidate_specs = build_candidate_specs(settings, cfg, spec);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();
crossing_path_table = table();

for i = 1:nc
    this_spec = candidate_specs(i);
    fprintf('\n=== annual ownership/balance-sheet candidate %d: %s ===\n', this_spec.candidate_id, char(this_spec.label));
    [candidate_rows(i), tmp_paths, tmp_crossing] = evaluate_candidate(this_spec, settings, cfg);
    path_table = [path_table; tmp_paths]; %#ok<AGROW>
    crossing_path_table = [crossing_path_table; tmp_crossing]; %#ok<AGROW>
    checkpoint_outputs(out_dir, settings, fertility_target_table, homeownership_target_table, wealth_target_table, candidate_rows(1:i), path_table, crossing_path_table);
end

checkpoint_outputs(out_dir, settings, fertility_target_table, homeownership_target_table, wealth_target_table, candidate_rows, path_table, crossing_path_table);
end

function settings = build_settings(mode, cfg, spec)
settings = struct();
settings.mode = lower(string(mode));
settings.eval_price = spec.grids.eval_price;
settings.eval_age = cfg.eval_age;
settings.anchor = spec.anchor;
settings.homeownership_bins = spec.grids.support_homeownership_bins;

base_overrides = cfg.overrides;
switch char(settings.mode)
    case 'smoke'
        base_overrides.I = 12;
        base_overrides.J = 4;
        settings.price_grid = [1.50, 2.00];
        settings.crossing_price_grid = [1.50, 2.00, 5.00];
    case 'confirm'
        base_overrides.I = 24;
        base_overrides.J = 8;
        settings.price_grid = [1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 3.00, 3.50, 4.00, 5.00];
    case 'fast'
        base_overrides.I = 32;
        base_overrides.J = 10;
        settings.price_grid = [1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 3.00, 3.50, 4.00, 5.00];
    case 'full'
        base_overrides.I = cfg.overrides.I;
        base_overrides.J = cfg.overrides.J;
        settings.price_grid = spec.grids.screen_price_grid;
        settings.crossing_price_grid = spec.grids.crossing_price_grid;
    otherwise
        error('Unknown mode "%s". Use "smoke", "confirm", "fast", or "full".', mode);
end

settings.base_overrides = base_overrides;
end

function specs = build_candidate_specs(settings, cfg, spec)
spec_template = empty_candidate_spec();
specs = repmat(spec_template, 0, 1);
idx = 0;

idx = idx + 1;
specs(idx) = build_candidate_spec( ...
    idx, ...
    "anchor no-mix baseline", ...
    "baseline", ...
    0.00, 1.00, 0.00, ...
    settings.anchor.housingmax, settings.anchor.housingmax, ...
    settings.anchor.theta_r, settings.anchor.theta_r, ...
    settings.anchor.CC, settings.anchor.CC, ...
    settings.anchor.baseline_owner_entry_b_floor, settings.anchor.baseline_owner_entry_b_floor, ...
    settings.anchor.baseline_owner_entry_mortgage_floor, settings.anchor.baseline_owner_entry_mortgage_floor, ...
    settings.anchor.baseline_owner_entry_payment_to_income_cap, settings.anchor.baseline_owner_entry_payment_to_income_cap, ...
    0.0, 0.0, ...
    settings.anchor.ka, settings.anchor.rent_markup);

for ifam = 1:numel(spec.families)
    if settings.mode == "smoke" && ifam > 1
        continue;
    end
    family = spec.families(ifam);
    bundles = build_family_bundles(family, settings.mode);
    for ib = 1:numel(bundles)
        bundle = bundles(ib);
        baseline_share = 0.0;
        if contains(char(family.label), 'three_type')
            baseline_share = max(0.0, 1.0 - bundle.constrained_share - bundle.helped_share);
            if baseline_share <= 0
                continue;
            end
        end

        idx = idx + 1;
        label = sprintf('%s | cshare %.2f | hshare %.2f | chmax %.0f | hhmax %.0f | ctheta %.2f | htheta %.2f | cMCC %.2f | hMCC %.2f | mSpread %.4f | amort %.3f | cEntryLTV %.2f | hEntryLTV %.2f | cPTI %.2f | hPTI %.2f | cFloor %.1f | hFloor %.1f | boost %.1f | ka %.3f | rent %.3f', ...
            char(family.label), ...
            bundle.constrained_share, bundle.helped_share, ...
            bundle.constrained_housingmax, bundle.helped_housingmax, ...
            bundle.constrained_theta_r, bundle.helped_theta_r, ...
            bundle.constrained_cc, bundle.helped_cc, ...
            settings.anchor.owner_mortgage_spread, settings.anchor.owner_mortgage_amortization, bundle.constrained_owner_entry_mortgage_floor, bundle.helped_owner_entry_mortgage_floor, bundle.constrained_owner_entry_payment_to_income_cap, bundle.helped_owner_entry_payment_to_income_cap, ...
            bundle.constrained_owner_entry_b_floor, bundle.helped_owner_entry_b_floor, ...
            bundle.helped_transfer_boost, bundle.ka_value, bundle.rent_markup_value);
        specs(idx) = build_candidate_spec( ...
            idx, ...
            string(label), ...
            family.label, ...
            bundle.constrained_share, baseline_share, bundle.helped_share, ...
            bundle.constrained_housingmax, bundle.helped_housingmax, ...
            bundle.constrained_theta_r, bundle.helped_theta_r, ...
            bundle.constrained_cc, bundle.helped_cc, ...
            bundle.constrained_owner_entry_b_floor, bundle.helped_owner_entry_b_floor, ...
            bundle.constrained_owner_entry_mortgage_floor, bundle.helped_owner_entry_mortgage_floor, ...
            bundle.constrained_owner_entry_payment_to_income_cap, bundle.helped_owner_entry_payment_to_income_cap, ...
            bundle.helped_transfer_share, bundle.helped_transfer_boost, ...
            bundle.ka_value, bundle.rent_markup_value);
    end
end
end

function bundles = build_family_bundles(family, mode)
low_cs = family.constrained_share_grid(1);
mid_cs = family.constrained_share_grid(max(1, ceil(numel(family.constrained_share_grid) / 2)));
high_cs = family.constrained_share_grid(end);
low_hs = family.helped_share_grid(1);
mid_hs = family.helped_share_grid(max(1, ceil(numel(family.helped_share_grid) / 2)));
high_hs = family.helped_share_grid(end);

low_ch = family.constrained_housingmax_grid(1);
high_hh = family.helped_housingmax_grid(end);
mid_ch = family.constrained_housingmax_grid(max(1, ceil(numel(family.constrained_housingmax_grid) / 2)));
mid_hh = family.helped_housingmax_grid(max(1, ceil(numel(family.helped_housingmax_grid) / 2)));

low_ct = family.constrained_theta_r_grid(1);
mid_ct = family.constrained_theta_r_grid(max(1, ceil(numel(family.constrained_theta_r_grid) / 2)));
high_ht = family.helped_theta_r_grid(end);
mid_ht = family.helped_theta_r_grid(max(1, ceil(numel(family.helped_theta_r_grid) / 2)));
low_cc = family.constrained_cc_grid(1);
mid_cc = family.constrained_cc_grid(max(1, ceil(numel(family.constrained_cc_grid) / 2)));
high_hcc = family.helped_cc_grid(end);
mid_hcc = family.helped_cc_grid(max(1, ceil(numel(family.helped_cc_grid) / 2)));
low_floor = family.constrained_owner_entry_b_floor_grid(1);
mid_floor = family.constrained_owner_entry_b_floor_grid(max(1, ceil(numel(family.constrained_owner_entry_b_floor_grid) / 2)));
low_help_floor = family.helped_owner_entry_b_floor_grid(1);
mid_help_floor = family.helped_owner_entry_b_floor_grid(max(1, ceil(numel(family.helped_owner_entry_b_floor_grid) / 2)));
mid_entry_ltv = family.constrained_owner_entry_mortgage_floor_grid(max(1, ceil(numel(family.constrained_owner_entry_mortgage_floor_grid) / 2)));
high_entry_ltv = family.constrained_owner_entry_mortgage_floor_grid(end);
low_help_entry_ltv = family.helped_owner_entry_mortgage_floor_grid(1);
mid_help_entry_ltv = family.helped_owner_entry_mortgage_floor_grid(max(1, ceil(numel(family.helped_owner_entry_mortgage_floor_grid) / 2)));
mid_pti = family.constrained_owner_entry_payment_to_income_cap_grid(max(1, ceil(numel(family.constrained_owner_entry_payment_to_income_cap_grid) / 2)));
high_pti = family.constrained_owner_entry_payment_to_income_cap_grid(end);
low_help_pti = family.helped_owner_entry_payment_to_income_cap_grid(1);
high_help_pti = family.helped_owner_entry_payment_to_income_cap_grid(end);

mid_boost = family.helped_parental_transfer_b_boost_grid(max(1, ceil(numel(family.helped_parental_transfer_b_boost_grid) / 2)));
high_boost = family.helped_parental_transfer_b_boost_grid(end);
transfer_share = family.helped_parental_transfer_share_grid(1);
ka_annual = family.ka_grid(1);
ka_hold = family.ka_grid(end);
rent_annual = family.rent_markup_grid(1);
rent_low = family.rent_markup_grid(end);

    switch char(mode)
    case 'smoke'
        bundles = make_bundle(mid_cs, mid_hs, low_ch, high_hh, low_ct, high_ht, mid_cc, high_hcc, mid_floor, low_help_floor, mid_entry_ltv, low_help_entry_ltv, mid_pti, high_help_pti, transfer_share, mid_boost, ka_annual, rent_annual);
    case 'confirm'
        bundles = [ ...
            make_bundle(mid_cs, mid_hs, low_ch, high_hh, low_ct, high_ht, mid_cc, high_hcc, mid_floor, low_help_floor, mid_entry_ltv, low_help_entry_ltv, mid_pti, high_help_pti, transfer_share, mid_boost, ka_annual, rent_annual), ...
            make_bundle(high_cs, low_hs, low_ch, high_hh, low_ct, high_ht, low_cc, high_hcc, low_floor, low_help_floor, high_entry_ltv, low_help_entry_ltv, high_pti, low_help_pti, transfer_share, high_boost, ka_hold, rent_low), ...
            make_bundle(low_cs, high_hs, mid_ch, high_hh, mid_ct, mid_ht, mid_cc, mid_hcc, mid_floor, mid_help_floor, mid_entry_ltv, mid_help_entry_ltv, mid_pti, high_help_pti, transfer_share, high_boost, ka_hold, rent_annual)];
    otherwise
        bundles = [ ...
            make_bundle(mid_cs, mid_hs, low_ch, high_hh, low_ct, high_ht, mid_cc, high_hcc, mid_floor, low_help_floor, mid_entry_ltv, low_help_entry_ltv, mid_pti, high_help_pti, transfer_share, mid_boost, ka_annual, rent_annual), ...
            make_bundle(high_cs, low_hs, low_ch, high_hh, low_ct, high_ht, low_cc, high_hcc, low_floor, low_help_floor, high_entry_ltv, low_help_entry_ltv, high_pti, low_help_pti, transfer_share, high_boost, ka_hold, rent_low), ...
            make_bundle(low_cs, high_hs, mid_ch, high_hh, mid_ct, mid_ht, mid_cc, mid_hcc, mid_floor, mid_help_floor, mid_entry_ltv, mid_help_entry_ltv, mid_pti, high_help_pti, transfer_share, high_boost, ka_hold, rent_annual), ...
            make_bundle(mid_cs, high_hs, low_ch, mid_hh, low_ct, mid_ht, low_cc, mid_hcc, low_floor, mid_help_floor, high_entry_ltv, mid_help_entry_ltv, high_pti, high_help_pti, transfer_share, mid_boost, ka_annual, rent_low)];
end
end

function bundle = make_bundle(constrained_share, helped_share, constrained_housingmax, helped_housingmax, constrained_theta_r, helped_theta_r, constrained_cc, helped_cc, constrained_owner_entry_b_floor, helped_owner_entry_b_floor, constrained_owner_entry_mortgage_floor, helped_owner_entry_mortgage_floor, constrained_owner_entry_payment_to_income_cap, helped_owner_entry_payment_to_income_cap, helped_transfer_share, helped_transfer_boost, ka_value, rent_markup_value)
bundle = struct( ...
    'constrained_share', constrained_share, ...
    'helped_share', helped_share, ...
    'constrained_housingmax', constrained_housingmax, ...
    'helped_housingmax', helped_housingmax, ...
    'constrained_theta_r', constrained_theta_r, ...
    'helped_theta_r', helped_theta_r, ...
    'constrained_cc', constrained_cc, ...
    'helped_cc', helped_cc, ...
    'constrained_owner_entry_b_floor', constrained_owner_entry_b_floor, ...
    'helped_owner_entry_b_floor', helped_owner_entry_b_floor, ...
    'constrained_owner_entry_mortgage_floor', constrained_owner_entry_mortgage_floor, ...
    'helped_owner_entry_mortgage_floor', helped_owner_entry_mortgage_floor, ...
    'constrained_owner_entry_payment_to_income_cap', constrained_owner_entry_payment_to_income_cap, ...
    'helped_owner_entry_payment_to_income_cap', helped_owner_entry_payment_to_income_cap, ...
    'helped_transfer_share', helped_transfer_share, ...
    'helped_transfer_boost', helped_transfer_boost, ...
    'ka_value', ka_value, ...
    'rent_markup_value', rent_markup_value);
end

function spec = empty_candidate_spec()
spec = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'family_label', "", ...
    'constrained_share', NaN, ...
    'baseline_share', NaN, ...
    'helped_share', NaN, ...
    'constrained_housingmax', NaN, ...
    'helped_housingmax', NaN, ...
    'constrained_theta_r', NaN, ...
    'helped_theta_r', NaN, ...
    'constrained_cc', NaN, ...
    'helped_cc', NaN, ...
    'constrained_owner_entry_b_floor', NaN, ...
    'helped_owner_entry_b_floor', NaN, ...
    'constrained_owner_entry_mortgage_floor', NaN, ...
    'helped_owner_entry_mortgage_floor', NaN, ...
    'constrained_owner_entry_payment_to_income_cap', NaN, ...
    'helped_owner_entry_payment_to_income_cap', NaN, ...
    'helped_transfer_share', NaN, ...
    'helped_transfer_boost', NaN, ...
    'ka_value', NaN, ...
    'rent_markup_value', NaN);
end

function spec = build_candidate_spec(candidate_id, label, family_label, constrained_share, baseline_share, helped_share, constrained_housingmax, helped_housingmax, constrained_theta_r, helped_theta_r, constrained_cc, helped_cc, constrained_owner_entry_b_floor, helped_owner_entry_b_floor, constrained_owner_entry_mortgage_floor, helped_owner_entry_mortgage_floor, constrained_owner_entry_payment_to_income_cap, helped_owner_entry_payment_to_income_cap, helped_transfer_share, helped_transfer_boost, ka_value, rent_markup_value)
spec = empty_candidate_spec();
spec.candidate_id = candidate_id;
spec.label = string(label);
spec.family_label = string(family_label);
spec.constrained_share = constrained_share;
spec.baseline_share = baseline_share;
spec.helped_share = helped_share;
spec.constrained_housingmax = constrained_housingmax;
spec.helped_housingmax = helped_housingmax;
spec.constrained_theta_r = constrained_theta_r;
spec.helped_theta_r = helped_theta_r;
spec.constrained_cc = constrained_cc;
spec.helped_cc = helped_cc;
spec.constrained_owner_entry_b_floor = constrained_owner_entry_b_floor;
spec.helped_owner_entry_b_floor = helped_owner_entry_b_floor;
spec.constrained_owner_entry_mortgage_floor = constrained_owner_entry_mortgage_floor;
spec.helped_owner_entry_mortgage_floor = helped_owner_entry_mortgage_floor;
spec.constrained_owner_entry_payment_to_income_cap = constrained_owner_entry_payment_to_income_cap;
spec.helped_owner_entry_payment_to_income_cap = helped_owner_entry_payment_to_income_cap;
spec.helped_transfer_share = helped_transfer_share;
spec.helped_transfer_boost = helped_transfer_boost;
spec.ka_value = ka_value;
spec.rent_markup_value = rent_markup_value;
end

function [row, path_rows, crossing_rows] = evaluate_candidate(spec, settings, cfg)
[override_list, weights] = build_type_list(spec, settings, cfg);

n = numel(settings.price_grid);
eval_idx = find(abs(settings.price_grid - settings.eval_price) < 1e-12, 1);
if isempty(eval_idx)
    error('Evaluation price %.4f is not on the screening grid.', settings.eval_price);
end

avg_birth_rate = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
median_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
childless_share_at_50 = NaN(n, 1);
vote_per_mass = NaN(n, 1);
debt_per_mass = NaN(n, 1);
mass_error = NaN(n, 1);
owner_share_25_34 = NaN(n, 1);
owner_share_35_44 = NaN(n, 1);
owner_share_45_54 = NaN(n, 1);
support_25_29 = NaN(n, 1);
support_30_34 = NaN(n, 1);
support_35_39 = NaN(n, 1);
support_40_44 = NaN(n, 1);
eval_wealth = empty_wealth_metrics();

for i = 1:n
    point = evaluate_mixture_point(settings.price_grid(i), cfg.rbPos, override_list, weights, settings.eval_age, i == eval_idx);
    avg_birth_rate(i) = point.avg_birth_rate;
    avg_first_birth_rate(i) = point.avg_first_birth_rate;
    mean_age_first_birth(i) = point.mean_age_first_birth;
    median_age_first_birth(i) = point.median_age_first_birth;
    share_first_birth_30_plus(i) = point.share_first_birth_30_plus;
    childless_share_at_50(i) = point.childless_share_at_50;
    vote_per_mass(i) = point.vote_per_mass;
    debt_per_mass(i) = point.debt_per_mass;
    mass_error(i) = point.max_mass_error;
    owner_share_25_34(i) = point.owner_shares(1);
    owner_share_35_44(i) = point.owner_shares(2);
    owner_share_45_54(i) = point.owner_shares(3);
    support_25_29(i) = point.support_shares(1);
    support_30_34(i) = point.support_shares(2);
    support_35_39(i) = point.support_shares(3);
    support_40_44(i) = point.support_shares(4);
    if i == eval_idx
        eval_wealth = point.wealth_metrics;
    end
end

ncross = numel(settings.crossing_price_grid);
cross_vote = NaN(ncross, 1);
cross_birth = NaN(ncross, 1);
cross_debt = NaN(ncross, 1);
cross_mass_error = NaN(ncross, 1);
for i = 1:ncross
    point = evaluate_mixture_point(settings.crossing_price_grid(i), cfg.rbPos, override_list, weights, settings.eval_age, false);
    cross_vote(i) = point.vote_per_mass;
    cross_birth(i) = point.avg_birth_rate;
    cross_debt(i) = point.debt_per_mass;
    cross_mass_error(i) = point.max_mass_error;
end

annual_scores = score_annual_fertility_targets( ...
    cfg.target_ranges, ...
    mean_age_first_birth(eval_idx), ...
    share_first_birth_30_plus(eval_idx), ...
    childless_share_at_50(eval_idx), ...
    [support_25_29(eval_idx), support_30_34(eval_idx), support_35_39(eval_idx), support_40_44(eval_idx)]);
home_scores = score_annual_homeownership_support_targets( ...
    cfg.homeownership_target_ranges, ...
    [owner_share_25_34(eval_idx), owner_share_35_44(eval_idx), owner_share_45_54(eval_idx)]);
wealth_scores = score_annual_wealth_support_targets(cfg.wealth_target_ranges, eval_wealth);

mean_age_monotone = all(diff(mean_age_first_birth) >= -1e-9);
share30_monotone = all(diff(share_first_birth_30_plus) >= -1e-9);
birth_rate_monotone = all(diff(avg_birth_rate) <= 1e-9);
sign_pass = mean_age_monotone && share30_monotone && birth_rate_monotone;

crossing = summarize_crossing(settings.crossing_price_grid, cross_vote);
max_cross_vote = max(cross_vote);
max_cross_price = settings.crossing_price_grid(argmax(cross_vote));
vote_shortfall = max(0, -max_cross_vote);

crossing_penalty = 0.25;
if crossing.exists && crossing.is_unique
    crossing_penalty = 0.0;
elseif crossing.exists
    crossing_penalty = 0.75;
end

sign_penalty = 2.0 * double(~sign_pass);
mass_penalty = 1e12 * max(max([mass_error; cross_mass_error]) - 1e-8, 0);
score = 4.0 * annual_scores.primary_score + home_scores.score + wealth_scores.score + vote_shortfall + crossing_penalty + sign_penalty + mass_penalty;

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = spec.label;
row.family_label = spec.family_label;
row.constrained_share = spec.constrained_share;
row.baseline_share = spec.baseline_share;
row.helped_share = spec.helped_share;
row.constrained_housingmax = spec.constrained_housingmax;
row.helped_housingmax = spec.helped_housingmax;
row.constrained_theta_r = spec.constrained_theta_r;
row.helped_theta_r = spec.helped_theta_r;
row.constrained_cc = spec.constrained_cc;
row.helped_cc = spec.helped_cc;
row.constrained_owner_entry_b_floor = spec.constrained_owner_entry_b_floor;
row.helped_owner_entry_b_floor = spec.helped_owner_entry_b_floor;
row.helped_transfer_share = spec.helped_transfer_share;
row.helped_transfer_boost = spec.helped_transfer_boost;
row.ka_value = spec.ka_value;
row.rent_markup_value = spec.rent_markup_value;
row.eval_avg_birth_rate = avg_birth_rate(eval_idx);
row.eval_avg_first_birth_rate = avg_first_birth_rate(eval_idx);
row.eval_mean_age_first_birth = mean_age_first_birth(eval_idx);
row.eval_median_age_first_birth = median_age_first_birth(eval_idx);
row.eval_share_first_birth_30_plus = share_first_birth_30_plus(eval_idx);
row.eval_childless_share_at_50 = childless_share_at_50(eval_idx);
row.eval_owner_share_25_34 = owner_share_25_34(eval_idx);
row.eval_owner_share_35_44 = owner_share_35_44(eval_idx);
row.eval_owner_share_45_54 = owner_share_45_54(eval_idx);
row.eval_debt_holder_share_under_35 = eval_wealth.debt_holder_share_under_35;
row.eval_debt_holder_share_35_44 = eval_wealth.debt_holder_share_35_44;
row.eval_mortgaged_owner_share_under_35 = eval_wealth.mortgaged_owner_share_under_35;
row.eval_mortgaged_owner_share_35_44 = eval_wealth.mortgaged_owner_share_35_44;
row.eval_mortgaged_owner_share_45_54 = eval_wealth.mortgaged_owner_share_45_54;
row.eval_mortgaged_owner_share_55_64 = eval_wealth.mortgaged_owner_share_55_64;
row.eval_vote_per_mass = vote_per_mass(eval_idx);
row.eval_debt_per_mass = debt_per_mass(eval_idx);
row.mean_age_band_excess = annual_scores.mean_age_excess;
row.share30_band_excess = annual_scores.share30_excess;
row.childless_band_excess = annual_scores.childless_excess;
row.shape_band_excess = annual_scores.shape_score;
row.homeownership_band_excess = home_scores.score;
row.wealth_support_band_excess = wealth_scores.support_score;
row.wealth_validation_band_excess = wealth_scores.validation_score;
row.primary_pass = double(annual_scores.primary_pass);
row.homeownership_pass = double(home_scores.pass);
row.wealth_pass = double(wealth_scores.pass);
row.sign_pass = double(sign_pass);
row.crossing_exists = double(crossing.exists);
row.crossing_is_unique = double(crossing.is_unique);
row.crossing_sign_changes = crossing.sign_change_count;
row.crossing_refined_price = crossing.refined_price;
row.max_crossing_vote_per_mass = max_cross_vote;
row.max_crossing_price = max_cross_price;
row.crossing_gap_to_zero = min(abs(cross_vote));
row.max_mass_error = max([mass_error; cross_mass_error]);
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
    childless_share_at_50, ...
    owner_share_25_34, ...
    owner_share_35_44, ...
    owner_share_45_54, ...
    vote_per_mass, ...
    debt_per_mass, ...
    mass_error, ...
    'VariableNames', {'candidate_id', 'label', 'a_price', 'avg_birth_rate', ...
    'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'childless_share_at_50', ...
    'owner_share_25_34', 'owner_share_35_44', 'owner_share_45_54', ...
    'vote_per_mass', 'debt_per_mass', 'mass_error'});

crossing_rows = table( ...
    repmat(spec.candidate_id, ncross, 1), ...
    repmat(spec.label, ncross, 1), ...
    settings.crossing_price_grid(:), ...
    cross_vote, ...
    cross_debt, ...
    cross_birth, ...
    cross_mass_error, ...
    'VariableNames', {'candidate_id', 'label', 'a_price', 'vote_per_mass', 'debt_per_mass', 'avg_birth_rate', 'mass_error'});
end

function [override_list, weights] = build_type_list(spec, settings, cfg)
baseline = build_anchor_overrides(settings, cfg);
baseline.ka = spec.ka_value;
baseline.rent_markup = spec.rent_markup_value;
baseline.initial_b_points = settings.anchor.baseline_initial_b_points;
baseline.initial_b_shares = settings.anchor.baseline_initial_b_shares;
baseline.CC = settings.anchor.CC;
baseline.owner_mortgage_CC = settings.anchor.owner_mortgage_CC;
baseline.owner_mortgage_spread = settings.anchor.owner_mortgage_spread;
baseline.owner_mortgage_amortization = settings.anchor.owner_mortgage_amortization;
baseline.owner_entry_b_floor = settings.anchor.baseline_owner_entry_b_floor;
baseline.owner_entry_age_max = settings.anchor.owner_entry_age_max;
baseline.owner_entry_mortgage_floor = settings.anchor.baseline_owner_entry_mortgage_floor;
baseline.owner_entry_mortgage_age_max = settings.anchor.owner_entry_mortgage_age_max;
baseline.owner_entry_payment_to_income_cap = settings.anchor.baseline_owner_entry_payment_to_income_cap;
baseline.owner_entry_payment_to_income_age_max = settings.anchor.owner_entry_payment_to_income_age_max;

override_list = {};
weights = [];

if spec.constrained_share > 0
    ov = baseline;
    ov.housingmax = spec.constrained_housingmax;
    ov.theta_r = spec.constrained_theta_r;
    ov.parental_transfer_share = 0.0;
    ov.parental_transfer_b_boost = 0.0;
    ov.initial_b_points = settings.anchor.constrained_initial_b_points;
    ov.initial_b_shares = settings.anchor.constrained_initial_b_shares;
    ov.owner_mortgage_CC = spec.constrained_cc;
    ov.owner_entry_b_floor = spec.constrained_owner_entry_b_floor;
    ov.owner_entry_mortgage_floor = spec.constrained_owner_entry_mortgage_floor;
    ov.owner_entry_payment_to_income_cap = spec.constrained_owner_entry_payment_to_income_cap;
    override_list{end + 1} = ov; %#ok<AGROW>
    weights(end + 1) = spec.constrained_share; %#ok<AGROW>
end

if spec.baseline_share > 0
    override_list{end + 1} = baseline; %#ok<AGROW>
    weights(end + 1) = spec.baseline_share; %#ok<AGROW>
end

if spec.helped_share > 0
    ov = baseline;
    ov.housingmax = spec.helped_housingmax;
    ov.theta_r = spec.helped_theta_r;
    ov.parental_transfer_share = 0.0;
    ov.parental_transfer_b_boost = 0.0;
    ov.initial_b_points = build_helped_initial_b_points(settings.anchor.helped_initial_b_base_points, spec.helped_transfer_boost);
    ov.initial_b_shares = settings.anchor.helped_initial_b_shares;
    ov.owner_mortgage_CC = spec.helped_cc;
    ov.owner_entry_b_floor = spec.helped_owner_entry_b_floor;
    ov.owner_entry_mortgage_floor = spec.helped_owner_entry_mortgage_floor;
    ov.owner_entry_payment_to_income_cap = spec.helped_owner_entry_payment_to_income_cap;
    override_list{end + 1} = ov; %#ok<AGROW>
    weights(end + 1) = spec.helped_share; %#ok<AGROW>
end
end

function overrides = build_anchor_overrides(settings, cfg)
overrides = settings.base_overrides;
overrides.birth_utility_by_parity = settings.anchor.birth_utility_by_parity;
overrides.child_utility = settings.anchor.child_utility;
overrides.birth_cost = settings.anchor.birth_cost;
overrides.birth_price_coeff = settings.anchor.birth_price_coeff;
overrides.lambda_crowd = settings.anchor.lambda_crowd;
overrides.birth_age_weights = cfg.target_first_birth_age_share_annual;
overrides.realized_birth_weights = ones(size(cfg.target_first_birth_age_share_annual));
overrides.first_birth_realized_weights = settings.anchor.first_birth_realized_weights;
overrides.housingmax = settings.anchor.housingmax;
overrides.theta_r = settings.anchor.theta_r;
overrides.CC = settings.anchor.CC;
overrides.owner_mortgage_CC = settings.anchor.owner_mortgage_CC;
overrides.owner_mortgage_spread = settings.anchor.owner_mortgage_spread;
overrides.owner_mortgage_amortization = settings.anchor.owner_mortgage_amortization;
overrides.owner_entry_b_floor = settings.anchor.baseline_owner_entry_b_floor;
overrides.owner_entry_age_max = settings.anchor.owner_entry_age_max;
overrides.owner_entry_mortgage_floor = settings.anchor.baseline_owner_entry_mortgage_floor;
overrides.owner_entry_mortgage_age_max = settings.anchor.owner_entry_mortgage_age_max;
overrides.owner_entry_payment_to_income_cap = settings.anchor.baseline_owner_entry_payment_to_income_cap;
overrides.owner_entry_payment_to_income_age_max = settings.anchor.owner_entry_payment_to_income_age_max;
overrides.ka = settings.anchor.ka;
overrides.rent_markup = settings.anchor.rent_markup;
overrides.parental_transfer_share = 0.0;
overrides.parental_transfer_b_boost = 0.0;
overrides.initial_b_points = settings.anchor.baseline_initial_b_points;
overrides.initial_b_shares = settings.anchor.baseline_initial_b_shares;
end

function points = build_helped_initial_b_points(base_points, boost)
base_points = base_points(:)';
boost_scale = [0.0, 0.5, 1.0];
if numel(base_points) ~= numel(boost_scale)
    error('helped_initial_b_base_points must have length %d.', numel(boost_scale));
end
points = base_points + boost .* boost_scale;
end

function point = evaluate_mixture_point(a_price, rbPos, override_list, weights, eval_age, compute_wealth_metrics)
if nargin < 6
    compute_wealth_metrics = false;
end

nt = numel(weights);
vote_vals = zeros(nt, 1);
debt_vals = zeros(nt, 1);
birth_vals = zeros(nt, 1);
first_birth_vals = zeros(nt, 1);
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
    first_birth_vals(it) = diagnostics.avg_first_birth_rate;
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
point.avg_first_birth_rate = sum(weights(:) .* first_birth_vals) / sum(weights);
point.mean_age_first_birth = sum(ages .* first_birth_dist);
point.median_age_first_birth = weighted_discrete_median(ages, first_birth_dist);
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
        error('Unknown age-group mass metric "%s".', metric_name);
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

function target_table = build_target_table(ranges)
all_targets = [];
if isfield(ranges, 'primary')
    all_targets = [all_targets; ranges.primary(:)]; %#ok<AGROW>
end
if isfield(ranges, 'support')
    all_targets = [all_targets; ranges.support(:)]; %#ok<AGROW>
end
if isfield(ranges, 'validation')
    all_targets = [all_targets; ranges.validation(:)]; %#ok<AGROW>
end
target_table = struct2table(all_targets);
target_table = target_table(:, {'name', 'role', 'unit', 'reference', 'lower', 'upper', 'source', 'comment'});
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

function idx = argmax(x)
[~, idx] = max(x);
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'family_label', "", ...
    'constrained_share', NaN, ...
    'baseline_share', NaN, ...
    'helped_share', NaN, ...
    'constrained_housingmax', NaN, ...
    'helped_housingmax', NaN, ...
    'constrained_theta_r', NaN, ...
    'helped_theta_r', NaN, ...
    'constrained_cc', NaN, ...
    'helped_cc', NaN, ...
    'constrained_owner_entry_b_floor', NaN, ...
    'helped_owner_entry_b_floor', NaN, ...
    'helped_transfer_share', NaN, ...
    'helped_transfer_boost', NaN, ...
    'ka_value', NaN, ...
    'rent_markup_value', NaN, ...
    'eval_avg_birth_rate', NaN, ...
    'eval_avg_first_birth_rate', NaN, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_median_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_childless_share_at_50', NaN, ...
    'eval_owner_share_25_34', NaN, ...
    'eval_owner_share_35_44', NaN, ...
    'eval_owner_share_45_54', NaN, ...
    'eval_debt_holder_share_under_35', NaN, ...
    'eval_debt_holder_share_35_44', NaN, ...
    'eval_mortgaged_owner_share_under_35', NaN, ...
    'eval_mortgaged_owner_share_35_44', NaN, ...
    'eval_mortgaged_owner_share_45_54', NaN, ...
    'eval_mortgaged_owner_share_55_64', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'eval_debt_per_mass', NaN, ...
    'mean_age_band_excess', NaN, ...
    'share30_band_excess', NaN, ...
    'childless_band_excess', NaN, ...
    'shape_band_excess', NaN, ...
    'homeownership_band_excess', NaN, ...
    'wealth_support_band_excess', NaN, ...
    'wealth_validation_band_excess', NaN, ...
    'primary_pass', NaN, ...
    'homeownership_pass', NaN, ...
    'wealth_pass', NaN, ...
    'sign_pass', NaN, ...
    'crossing_exists', NaN, ...
    'crossing_is_unique', NaN, ...
    'crossing_sign_changes', NaN, ...
    'crossing_refined_price', NaN, ...
    'max_crossing_vote_per_mass', NaN, ...
    'max_crossing_price', NaN, ...
    'crossing_gap_to_zero', NaN, ...
    'max_mass_error', NaN, ...
    'score', NaN);
end

function candidates_table = sort_candidate_rows(candidate_rows)
candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'primary_pass', 'homeownership_pass', 'wealth_pass', 'sign_pass', 'crossing_is_unique', 'max_crossing_vote_per_mass', 'score'}, ...
    {'descend', 'descend', 'descend', 'descend', 'descend', 'descend', 'ascend'});
end

function checkpoint_outputs(out_dir, settings, fertility_target_table, homeownership_target_table, wealth_target_table, candidate_rows, path_table, crossing_path_table)
if isempty(candidate_rows)
    return;
end

candidates_table = sort_candidate_rows(candidate_rows);
writetable(candidates_table, fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen_candidate_paths.csv'));
writetable(crossing_path_table, fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen_crossing_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_ownership_balance_sheet_screen.md'), ...
    settings, fertility_target_table, homeownership_target_table, wealth_target_table, candidates_table, path_table, crossing_path_table);
end

function write_report(report_path, settings, fertility_target_table, homeownership_target_table, wealth_target_table, candidates_table, path_table, crossing_path_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual fertility ownership / balance-sheet screen\n\n');
fprintf(fid, 'This workflow holds the `%s` fixed and reopens the annual branch with entrant-type ownership / balance-sheet heterogeneity. The main political object is `vote_per_mass`, so the crossing object is bounded between `-1` and `1`.\n\n', char(settings.anchor.label));

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', settings.base_overrides.I, settings.base_overrides.J);
fprintf(fid, '- screening price grid: `%s`\n', format_price_grid(settings.price_grid));
fprintf(fid, '- crossing check grid: `%s`\n\n', format_price_grid(settings.crossing_price_grid));

fprintf(fid, '## Fixed fertility anchor\n\n');
fprintf(fid, '- mean age first birth target read: `%.2f`\n', settings.anchor.target_read.mean_age_first_birth);
fprintf(fid, '- share first births age `30+` target read: `%.3f`\n', settings.anchor.target_read.share_first_birth_30_plus);
fprintf(fid, '- childless share at `50` target read: `%.4f`\n\n', settings.anchor.target_read.childless_share_at_50);

fprintf(fid, '## Fertility targets\n\n');
fprintf(fid, '| Object | Role | Reference | Lower | Upper |\n');
fprintf(fid, '|---|---|---:|---:|---:|\n');
for i = 1:height(fertility_target_table)
    fprintf(fid, '| %s | %s | `%.4f` | `%.4f` | `%.4f` |\n', ...
        char(fertility_target_table.name(i)), char(fertility_target_table.role(i)), ...
        fertility_target_table.reference(i), fertility_target_table.lower(i), fertility_target_table.upper(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Homeownership support targets\n\n');
fprintf(fid, '| Object | Role | Reference | Lower | Upper |\n');
fprintf(fid, '|---|---|---:|---:|---:|\n');
for i = 1:height(homeownership_target_table)
    fprintf(fid, '| %s | %s | `%.4f` | `%.4f` | `%.4f` |\n', ...
        char(homeownership_target_table.name(i)), char(homeownership_target_table.role(i)), ...
        homeownership_target_table.reference(i), homeownership_target_table.lower(i), homeownership_target_table.upper(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Wealth support and validation targets\n\n');
fprintf(fid, '| Object | Role | Reference | Lower | Upper |\n');
fprintf(fid, '|---|---|---:|---:|---:|\n');
for i = 1:height(wealth_target_table)
    fprintf(fid, '| %s | %s | `%.4f` | `%.4f` | `%.4f` |\n', ...
        char(wealth_target_table.name(i)), char(wealth_target_table.role(i)), ...
        wealth_target_table.reference(i), wealth_target_table.lower(i), wealth_target_table.upper(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Main read\n\n');
fprintf(fid, '- Candidates screened: `%d`\n', height(candidates_table));
fprintf(fid, '- Primary fertility passes: `%d`\n', sum(candidates_table.primary_pass == 1));
fprintf(fid, '- Homeownership support passes: `%d`\n', sum(candidates_table.homeownership_pass == 1));
fprintf(fid, '- Wealth support passes: `%d`\n', sum(candidates_table.wealth_pass == 1));
fprintf(fid, '- Unique crossings on the check grid: `%d`\n', sum(candidates_table.crossing_is_unique == 1));
fprintf(fid, '- Joint fertility + homeownership + wealth + unique-crossing passes: `%d`\n\n', ...
    sum(candidates_table.primary_pass == 1 & candidates_table.homeownership_pass == 1 & candidates_table.wealth_pass == 1 & candidates_table.crossing_is_unique == 1));

fprintf(fid, '## Top candidates\n\n');
fprintf(fid, '| Rank | Candidate | Mean age | Share 30+ | Childless @50 | Owner 25-34 | Owner 35-44 | Owner 45-54 | Debt <35 | Mort owner <35 | Vote/mass @2.0 | Crossing | Score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:min(height(candidates_table), 12)
    row = candidates_table(i, :);
    crossing_text = 'none';
    if row.crossing_is_unique == 1 && ~isnan(row.crossing_refined_price)
        crossing_text = sprintf('~%.3f', row.crossing_refined_price);
    elseif row.crossing_exists == 1
        crossing_text = sprintf('%d changes', row.crossing_sign_changes);
    end
    fprintf(fid, '| %d | %s | `%.2f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | %s | `%.4f` |\n', ...
        i, escape_pipes(char(row.label)), ...
        row.eval_mean_age_first_birth, row.eval_share_first_birth_30_plus, row.eval_childless_share_at_50, ...
        row.eval_owner_share_25_34, row.eval_owner_share_35_44, row.eval_owner_share_45_54, ...
        row.eval_debt_holder_share_under_35, row.eval_mortgaged_owner_share_under_35, ...
        row.eval_vote_per_mass, crossing_text, row.score);
end
fprintf(fid, '\n');

if height(candidates_table) >= 1
    best_id = candidates_table.candidate_id(1);
    best_paths = path_table(path_table.candidate_id == best_id, :);
    best_crossing = crossing_path_table(crossing_path_table.candidate_id == best_id, :);
    fprintf(fid, '## Best candidate path\n\n');
    fprintf(fid, 'Best candidate: `%s`\n\n', char(candidates_table.label(1)));
    fprintf(fid, '| House price | Avg birth rate | Mean age | Share 30+ | Childless @50 | Owner 25-34 | Owner 35-44 | Owner 45-54 | Vote/mass | Debt/mass |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
    for i = 1:height(best_paths)
        fprintf(fid, '| %.2f | `%.4f` | `%.2f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` | `%.3f` |\n', ...
            best_paths.a_price(i), best_paths.avg_birth_rate(i), best_paths.mean_age_first_birth(i), ...
            best_paths.share_first_birth_30_plus(i), best_paths.childless_share_at_50(i), ...
            best_paths.owner_share_25_34(i), best_paths.owner_share_35_44(i), best_paths.owner_share_45_54(i), ...
            best_paths.vote_per_mass(i), best_paths.debt_per_mass(i));
    end
    fprintf(fid, '\n');

    fprintf(fid, '## Best candidate crossing grid\n\n');
    fprintf(fid, '| House price | Vote/mass | Debt/mass | Avg birth rate | Mass error |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|\n');
    for i = 1:height(best_crossing)
        fprintf(fid, '| %.2f | `%.3f` | `%.3f` | `%.4f` | `%.3e` |\n', ...
            best_crossing.a_price(i), best_crossing.vote_per_mass(i), best_crossing.debt_per_mass(i), ...
            best_crossing.avg_birth_rate(i), best_crossing.mass_error(i));
    end
    fprintf(fid, '\n');

    fprintf(fid, '## Best candidate eval balance-sheet shares\n\n');
    fprintf(fid, '| Object | Model | Lower | Upper |\n');
    fprintf(fid, '|---|---:|---:|---:|\n');
    for i = 1:height(wealth_target_table)
        target_name = wealth_target_table.name(i);
        fprintf(fid, '| %s | `%.3f` | `%.3f` | `%.3f` |\n', ...
            char(target_name), candidate_wealth_value(candidates_table(1, :), target_name), ...
            wealth_target_table.lower(i), wealth_target_table.upper(i));
    end
    fprintf(fid, '\n');
end

fprintf(fid, '## Interpretation rule\n\n');
fprintf(fid, '- This is a representative structural screen, not an exhaustive search box.\n');
fprintf(fid, '- If the best rows still have no stable crossing, the annual branch should not go back to scalar rescue wedges.\n');
fprintf(fid, '- If a row survives fertility bands, ACS owner-share support bins, SCF age-wealth support objects, and the wider crossing grid, it becomes the next annual benchmark frontrunner.\n');
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

function text = escape_pipes(text)
text = strrep(text, '|', '&#124;');
end

function value = candidate_wealth_value(row, target_name)
switch char(target_name)
    case 'debt_holder_share_under_35'
        value = row.eval_debt_holder_share_under_35;
    case 'debt_holder_share_35_44'
        value = row.eval_debt_holder_share_35_44;
    case 'mortgaged_owner_share_under_35'
        value = row.eval_mortgaged_owner_share_under_35;
    case 'mortgaged_owner_share_35_44'
        value = row.eval_mortgaged_owner_share_35_44;
    case 'mortgaged_owner_share_45_54'
        value = row.eval_mortgaged_owner_share_45_54;
    case 'mortgaged_owner_share_55_64'
        value = row.eval_mortgaged_owner_share_55_64;
    otherwise
        value = NaN;
end
end
