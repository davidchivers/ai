function run_nimby_annual_low_entry_vote_followup(mode)
% run_nimby_annual_low_entry_vote_followup.m -- Full-resolution annual
% NIMBY follow-up that keeps the low-entry owner grid in play while
% re-screening the remaining vote-side / renter-side annual margins.
%
% This workflow starts from the current best access-side follow-up read:
%   uniform cohorts + hold-5y ka + benchmark CC + housingmax = 10
% and then screens only the remaining vote-side / renter-side knobs:
%   1. theta_r
%   2. rent_markup
%
% Usage:
%   run_nimby_annual_low_entry_vote_followup
%   run_nimby_annual_low_entry_vote_followup('full')
%
% Outputs:
%   notes/build/nimby_annual_low_entry_vote_followup_candidates.csv
%   notes/build/nimby_annual_low_entry_vote_followup_candidate_paths.csv
%   notes/build/nimby_annual_low_entry_vote_followup_candidate_blocks.csv
%   notes/build/nimby_annual_low_entry_vote_followup_target_blocks.csv
%   notes/build/nimby_annual_low_entry_vote_followup.md

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

settings = build_settings(mode, project_root);
ensure_transition_matrix(settings.five_year_overrides.transition_matrix_file, 5, settings.agemin, settings.agemax);
ensure_transition_matrix(settings.annual_transition_matrix_file, 1, settings.agemin, settings.agemax);

target_grid = evaluate_grid(settings.compare_price_grid, settings.rbPos_five_year, settings.five_year_overrides);
[~, target_crossing] = ClearMarkets_fertility(settings.crossing_price_grid, settings.rbPos_five_year, settings.five_year_overrides);
target_eval = evaluate_point(settings.eval_price, settings.rbPos_five_year, settings.five_year_overrides);
target_blocks = build_age_block_table( ...
    summarize_by_age(target_eval.diagnostics, settings.five_year_overrides), ...
    summarize_by_age(target_eval.diagnostics, settings.five_year_overrides), ...
    settings.early_life_block_starts);
writetable(target_blocks, fullfile(out_dir, 'nimby_annual_low_entry_vote_followup_target_blocks.csv'));

candidate_specs = build_candidate_specs(settings);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();
block_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual low-entry vote follow-up candidate %d: %s ===\n', spec.candidate_id, spec.label);
    ov = build_annual_candidate_overrides(settings, spec);
    grid = evaluate_grid(settings.compare_price_grid, settings.rbPos_annual, ov);
    [~, crossing] = ClearMarkets_fertility(settings.crossing_price_grid, settings.rbPos_annual, ov);
    eval_point = evaluate_point(settings.eval_price, settings.rbPos_annual, ov);
    candidate_blocks = build_age_block_table( ...
        summarize_by_age(target_eval.diagnostics, settings.five_year_overrides), ...
        summarize_by_age(eval_point.diagnostics, ov), ...
        settings.early_life_block_starts);

    candidate_rows(i) = score_candidate(spec, grid, crossing, eval_point, candidate_blocks, target_grid, target_crossing, target_eval);

    tmp = table( ...
        repmat(spec.candidate_id, height(grid), 1), ...
        repmat(string(spec.label), height(grid), 1), ...
        repmat(string(spec.theta_r_code), height(grid), 1), ...
        repmat(string(spec.rent_markup_code), height(grid), 1), ...
        grid.a_price, ...
        grid.vote_per_mass, ...
        grid.debt_per_mass, ...
        grid.mass, ...
        'VariableNames', {'candidate_id', 'label', 'theta_r_code', 'rent_markup_code', ...
        'a_price', 'vote_per_mass', 'debt_per_mass', 'mass'});
    path_table = [path_table; tmp]; %#ok<AGROW>

    tmp_blocks = table( ...
        repmat(spec.candidate_id, height(candidate_blocks), 1), ...
        repmat(string(spec.label), height(candidate_blocks), 1), ...
        candidate_blocks.age_block, ...
        candidate_blocks.five_year_vote_per_mass, ...
        candidate_blocks.annual_vote_per_mass, ...
        candidate_blocks.vote_gap, ...
        candidate_blocks.five_year_owner_share, ...
        candidate_blocks.annual_owner_share, ...
        candidate_blocks.owner_share_gap, ...
        candidate_blocks.five_year_mean_liquid_assets, ...
        candidate_blocks.annual_mean_liquid_assets, ...
        candidate_blocks.liquid_asset_gap, ...
        'VariableNames', {'candidate_id', 'label', 'age_block', ...
        'five_year_vote_per_mass', 'annual_vote_per_mass', 'vote_gap', ...
        'five_year_owner_share', 'annual_owner_share', 'owner_share_gap', ...
        'five_year_mean_liquid_assets', 'annual_mean_liquid_assets', 'liquid_asset_gap'});
    block_table = [block_table; tmp_blocks]; %#ok<AGROW>
end

candidates_table = sort_candidate_rows(candidate_rows);
writetable(candidates_table, fullfile(out_dir, 'nimby_annual_low_entry_vote_followup_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'nimby_annual_low_entry_vote_followup_candidate_paths.csv'));
writetable(block_table, fullfile(out_dir, 'nimby_annual_low_entry_vote_followup_candidate_blocks.csv'));
write_report(fullfile(out_dir, 'nimby_annual_low_entry_vote_followup.md'), ...
    settings, target_grid, target_crossing, target_eval, target_blocks, candidates_table, block_table);
end

function settings = build_settings(mode, project_root)
cfg = fertility_benchmark_config();
settings = struct();
settings.mode = lower(string(mode));
settings.agemin = 25;
settings.agemax = 80;
settings.eval_price = cfg.eval_price;
settings.early_life_block_starts = 25:5:50;
settings.beta_five_year = 0.98;
settings.bequestweight_five_year = 0.98;
settings.rbPos_five_year = cfg.rbPos;
settings.rb_spread_five_year = 0.02;
settings.ra_five_year = -0.03;
settings.rent_markup_five_year = 0.02;
settings.ka_five_year = 0.06;
settings.d_a_price_five_year = 1.01;
settings.theta_r_low = 0.55;
settings.theta_r_mid = 0.70;
settings.theta_r_benchmark = 0.85;
settings.rent_markup_mid = 0.01;
settings.cc_benchmark = 0.90;
settings.housingmax_low_entry = 10.0;
settings.annual_transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_annual.mat');

settings.beta_annual = annualize_discount(settings.beta_five_year, 5);
settings.bequestweight_annual = annualize_discount(settings.bequestweight_five_year, 5);
settings.rbPos_annual = annualize_net_rate(settings.rbPos_five_year, 5);
settings.rspread_annual = annualize_spread(settings.rbPos_five_year, settings.rb_spread_five_year, 5);
settings.ra_annual = annualize_net_rate(settings.ra_five_year, 5);
settings.rent_markup_annual = annualize_net_rate(settings.rent_markup_five_year, 5);

base_overrides = build_nimby_shutoff_overrides(cfg.overrides);
switch char(settings.mode)
    case 'full'
        solver_I = cfg.overrides.I;
        solver_J = cfg.overrides.J;
        settings.compare_price_grid = [1.25, 1.50, 1.75, 2.00, 2.25, 2.50, 2.75];
        settings.crossing_price_grid = 0.75:0.125:3.00;
    case 'fast'
        solver_I = cfg.stage1_solver_overrides.I;
        solver_J = 10;
        settings.compare_price_grid = [1.25, 1.50, 1.75, 2.00, 2.25, 2.50];
        settings.crossing_price_grid = 0.75:0.25:3.00;
    otherwise
        error('Unknown mode "%s". Use "fast" or "full".', mode);
end

settings.solver_I = solver_I;
settings.solver_J = solver_J;

settings.five_year_overrides = base_overrides;
settings.five_year_overrides.agemin = settings.agemin;
settings.five_year_overrides.agemax = settings.agemax;
settings.five_year_overrides.dage = 5;
settings.five_year_overrides.I = solver_I;
settings.five_year_overrides.J = solver_J;
settings.five_year_overrides.housingmin = 0;
settings.five_year_overrides.housingmax = 15;
settings.five_year_overrides.bmin = -20;
settings.five_year_overrides.bmax = 20;
settings.five_year_overrides.ka = settings.ka_five_year;
settings.five_year_overrides.bequestweight = settings.bequestweight_five_year;
settings.five_year_overrides.d_a_price = settings.d_a_price_five_year;
settings.five_year_overrides.cohort_weights_by_age = expand_cohort_profile(settings.agemin:5:settings.agemax);
settings.five_year_overrides.transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_5y_25_80.mat');
end

function specs = build_candidate_specs(settings)
theta_specs = [ ...
    struct('code', "low", 'label', "low theta_r", 'value', settings.theta_r_low), ...
    struct('code', "mid", 'label', "mid theta_r", 'value', settings.theta_r_mid), ...
    struct('code', "benchmark", 'label', "benchmark theta_r", 'value', settings.theta_r_benchmark)];
rent_specs = [ ...
    struct('code', "annualized", 'label', "annualized rent markup", 'value', settings.rent_markup_annual), ...
    struct('code', "mid", 'label', "mid rent markup", 'value', settings.rent_markup_mid), ...
    struct('code', "hold_5y", 'label', "hold 5y rent markup", 'value', settings.rent_markup_five_year)];

specs = repmat(struct(), numel(theta_specs) * numel(rent_specs), 1);
idx = 0;
for it = 1:numel(theta_specs)
    for ir = 1:numel(rent_specs)
        idx = idx + 1;
        specs(idx).candidate_id = idx;
        specs(idx).theta_r_code = theta_specs(it).code;
        specs(idx).theta_r_label = theta_specs(it).label;
        specs(idx).theta_r_value = theta_specs(it).value;
        specs(idx).rent_markup_code = rent_specs(ir).code;
        specs(idx).rent_markup_label = rent_specs(ir).label;
        specs(idx).rent_markup_value = rent_specs(ir).value;
        specs(idx).label = sprintf('%s + %s', theta_specs(it).label, rent_specs(ir).label);
    end
end
end

function ov = build_annual_candidate_overrides(settings, spec)
cfg = fertility_benchmark_config();
ov = build_nimby_shutoff_overrides(cfg.overrides);
ov.agemin = settings.agemin;
ov.agemax = settings.agemax;
ov.dage = 1;
ov.I = settings.solver_I;
ov.J = settings.solver_J;
ov.housingmin = 0;
ov.housingmax = settings.housingmax_low_entry;
ov.bmin = -20;
ov.bmax = 20;
ov.transition_matrix_file = settings.annual_transition_matrix_file;
ov.beta = settings.beta_annual;
ov.bequestweight = settings.bequestweight_annual;
ov.ra = settings.ra_annual;
ov.rspread = settings.rspread_annual;
ov.rent_markup = spec.rent_markup_value;
ov.ka = settings.ka_five_year;
ov.theta_r = spec.theta_r_value;
ov.d_a_price = settings.d_a_price_five_year;
ov.CC = settings.cc_benchmark;
ov.cohort_weights_by_age = ones(1, numel(settings.agemin:1:settings.agemax));
end

function grid = evaluate_grid(price_grid, rbPos, overrides)
n = numel(price_grid);
a_price = price_grid(:);
vote_per_mass = NaN(n, 1);
debt_per_mass = NaN(n, 1);
mass = NaN(n, 1);
totalvote = NaN(n, 1);
debtstock = NaN(n, 1);

for i = 1:n
    point = evaluate_point(price_grid(i), rbPos, overrides);
    vote_per_mass(i) = point.vote_per_mass;
    debt_per_mass(i) = point.debt_per_mass;
    mass(i) = point.mass;
    totalvote(i) = point.totalvote;
    debtstock(i) = point.debtstock;
end

grid = table(a_price, totalvote, debtstock, mass, vote_per_mass, debt_per_mass);
end

function point = evaluate_point(a_price, rbPos, overrides)
[distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([a_price, rbPos], overrides);
mass = sum(diagnostics.age_mass);
point = struct();
point.distance = distance;
point.totalvote = totalvote;
point.debtstock = debtstock;
point.mass = mass;
point.vote_per_mass = totalvote / max(mass, 1e-12);
point.debt_per_mass = debtstock / max(mass, 1e-12);
point.diagnostics = diagnostics;
end

function summary = summarize_by_age(diagnostics, overrides)
ages = overrides.agemin:overrides.dage:overrides.agemax;
mass_age = diagnostics.age_mass(:);
vote_age = squeeze(sum(sum(sum(diagnostics.vote4, 1), 2), 3));
vote_age = vote_age(:);
owner_mass_age = squeeze(sum(sum(sum(diagnostics.dens4(:, 2:end, :, :), 1), 2), 3));
owner_mass_age = owner_mass_age(:);

b_grid = diagnostics.b_grid(:);
b_sum_age = zeros(numel(ages), 1);
for ia = 1:numel(ages)
    dens_age = diagnostics.dens4(:, :, :, ia);
    b_sum_age(ia) = sum(dens_age .* reshape(b_grid, [], 1, 1), 'all');
end

summary = struct();
summary.ages = ages(:);
summary.mass_age = mass_age;
summary.vote_age = vote_age;
summary.owner_mass_age = owner_mass_age;
summary.b_sum_age = b_sum_age;
summary.vote_per_mass_age = vote_age ./ max(mass_age, 1e-12);
summary.owner_share_age = owner_mass_age ./ max(mass_age, 1e-12);
summary.mean_liquid_assets_age = b_sum_age ./ max(mass_age, 1e-12);
end

function block_table = build_age_block_table(five_year_summary, annual_summary, block_starts)
n = numel(block_starts);
age_block = strings(n, 1);
five_year_vote_per_mass = NaN(n, 1);
annual_vote_per_mass = NaN(n, 1);
vote_gap = NaN(n, 1);
five_year_owner_share = NaN(n, 1);
annual_owner_share = NaN(n, 1);
owner_share_gap = NaN(n, 1);
five_year_mean_liquid_assets = NaN(n, 1);
annual_mean_liquid_assets = NaN(n, 1);
liquid_asset_gap = NaN(n, 1);

for i = 1:n
    lower_age = block_starts(i);
    upper_age = lower_age + 4;
    age_block(i) = string(sprintf('%d-%d', lower_age, upper_age));

    idx5 = find(five_year_summary.ages == lower_age);
    idx1 = annual_summary.ages >= lower_age & annual_summary.ages <= upper_age;

    mass5 = five_year_summary.mass_age(idx5);
    vote5 = five_year_summary.vote_age(idx5);
    owner5 = five_year_summary.owner_mass_age(idx5);
    b5 = five_year_summary.b_sum_age(idx5);

    mass1 = sum(annual_summary.mass_age(idx1));
    vote1 = sum(annual_summary.vote_age(idx1));
    owner1 = sum(annual_summary.owner_mass_age(idx1));
    b1 = sum(annual_summary.b_sum_age(idx1));

    five_year_vote_per_mass(i) = vote5 / max(mass5, 1e-12);
    annual_vote_per_mass(i) = vote1 / max(mass1, 1e-12);
    vote_gap(i) = annual_vote_per_mass(i) - five_year_vote_per_mass(i);

    five_year_owner_share(i) = owner5 / max(mass5, 1e-12);
    annual_owner_share(i) = owner1 / max(mass1, 1e-12);
    owner_share_gap(i) = annual_owner_share(i) - five_year_owner_share(i);

    five_year_mean_liquid_assets(i) = b5 / max(mass5, 1e-12);
    annual_mean_liquid_assets(i) = b1 / max(mass1, 1e-12);
    liquid_asset_gap(i) = annual_mean_liquid_assets(i) - five_year_mean_liquid_assets(i);
end

block_table = table(age_block, ...
    five_year_vote_per_mass, annual_vote_per_mass, vote_gap, ...
    five_year_owner_share, annual_owner_share, owner_share_gap, ...
    five_year_mean_liquid_assets, annual_mean_liquid_assets, liquid_asset_gap);
end

function row = score_candidate(spec, grid, crossing, eval_point, candidate_blocks, target_grid, target_crossing, target_eval)
target_vote = target_grid.vote_per_mass;
target_debt = target_grid.debt_per_mass;
candidate_vote = grid.vote_per_mass;
candidate_debt = grid.debt_per_mass;

vote_rmse = sqrt(mean((candidate_vote - target_vote).^2));
debt_rmse = sqrt(mean((candidate_debt - target_debt).^2));
eval_vote_gap = eval_point.vote_per_mass - target_eval.vote_per_mass;
eval_debt_gap = eval_point.debt_per_mass - target_eval.debt_per_mass;
early_vote_rmse = sqrt(mean(candidate_blocks.vote_gap .^ 2));
early_owner_share_rmse = sqrt(mean(candidate_blocks.owner_share_gap .^ 2));
early_liquid_asset_rmse = sqrt(mean(candidate_blocks.liquid_asset_gap .^ 2));
eval_owner_share_gap_25_29 = candidate_blocks.owner_share_gap(1);
eval_owner_share_gap_50_54 = candidate_blocks.owner_share_gap(end);
eval_liquid_asset_gap_25_29 = candidate_blocks.liquid_asset_gap(1);
eval_liquid_asset_gap_50_54 = candidate_blocks.liquid_asset_gap(end);

crossing_gap = NaN;
if crossing.exists && crossing.is_unique && target_crossing.exists && target_crossing.is_unique ...
        && ~isnan(crossing.refined_price) && ~isnan(target_crossing.refined_price)
    crossing_gap = abs(crossing.refined_price - target_crossing.refined_price);
end

no_cross_penalty = 2.0 * double(~crossing.exists || ~crossing.is_unique || isnan(crossing.refined_price));
crossing_penalty = 0;
if ~isnan(crossing_gap)
    crossing_penalty = 0.5 * crossing_gap;
end
score = vote_rmse + 0.25 * debt_rmse + early_vote_rmse + 0.5 * early_owner_share_rmse ...
    + 0.5 * early_liquid_asset_rmse + crossing_penalty + no_cross_penalty;

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = string(spec.label);
row.theta_r_code = string(spec.theta_r_code);
row.theta_r_value = spec.theta_r_value;
row.rent_markup_code = string(spec.rent_markup_code);
row.rent_markup_value = spec.rent_markup_value;
row.vote_rmse = vote_rmse;
row.debt_rmse = debt_rmse;
row.early_vote_rmse = early_vote_rmse;
row.early_owner_share_rmse = early_owner_share_rmse;
row.early_liquid_asset_rmse = early_liquid_asset_rmse;
row.eval_vote_per_mass = eval_point.vote_per_mass;
row.eval_debt_per_mass = eval_point.debt_per_mass;
row.eval_vote_gap = eval_vote_gap;
row.eval_debt_gap = eval_debt_gap;
row.eval_owner_share_gap_25_29 = eval_owner_share_gap_25_29;
row.eval_owner_share_gap_50_54 = eval_owner_share_gap_50_54;
row.eval_liquid_asset_gap_25_29 = eval_liquid_asset_gap_25_29;
row.eval_liquid_asset_gap_50_54 = eval_liquid_asset_gap_50_54;
row.crossing_exists = double(crossing.exists);
row.crossing_is_unique = double(crossing.is_unique);
row.crossing_sign_changes = crossing.sign_change_count;
row.crossing_refined_price = crossing.refined_price;
row.crossing_gap = crossing_gap;
row.score = score;
end

function row = empty_candidate_row()
row = struct( ...
    'candidate_id', NaN, ...
    'label', "", ...
    'theta_r_code', "", ...
    'theta_r_value', NaN, ...
    'rent_markup_code', "", ...
    'rent_markup_value', NaN, ...
    'vote_rmse', NaN, ...
    'debt_rmse', NaN, ...
    'early_vote_rmse', NaN, ...
    'early_owner_share_rmse', NaN, ...
    'early_liquid_asset_rmse', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'eval_debt_per_mass', NaN, ...
    'eval_vote_gap', NaN, ...
    'eval_debt_gap', NaN, ...
    'eval_owner_share_gap_25_29', NaN, ...
    'eval_owner_share_gap_50_54', NaN, ...
    'eval_liquid_asset_gap_25_29', NaN, ...
    'eval_liquid_asset_gap_50_54', NaN, ...
    'crossing_exists', NaN, ...
    'crossing_is_unique', NaN, ...
    'crossing_sign_changes', NaN, ...
    'crossing_refined_price', NaN, ...
    'crossing_gap', NaN, ...
    'score', NaN);
end

function candidates_table = sort_candidate_rows(candidate_rows)
candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, ...
    {'score', 'early_vote_rmse', 'early_owner_share_rmse', 'early_liquid_asset_rmse', 'vote_rmse'}, ...
    {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
end

function ensure_transition_matrix(transition_matrix_file, dage, agemin, agemax)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_periodized(transition_matrix_file, dage, agemin, agemax);
end

function weights = expand_cohort_profile(ages)
base_ages = 25:5:90;
base_weights = [14 12 10 10 10 10 9 8 7 5 4 2 1 1];
weights = zeros(1, numel(ages));
for ia = 1:numel(ages)
    idx = find(base_ages <= ages(ia), 1, 'last');
    if isempty(idx)
        idx = 1;
    end
    weights(ia) = base_weights(min(idx, numel(base_weights)));
end
weights = weights ./ mean(weights);
end

function beta_annual = annualize_discount(beta_period, years_per_period)
beta_annual = beta_period .^ (1 / years_per_period);
end

function spread_annual = annualize_spread(rb_pos, spread, years_per_period)
rb_neg = rb_pos + spread;
spread_annual = annualize_net_rate(rb_neg, years_per_period) - annualize_net_rate(rb_pos, years_per_period);
end

function r_annual = annualize_net_rate(r_period, years_per_period)
r_annual = (1 + r_period) .^ (1 / years_per_period) - 1;
end

function write_report(report_path, settings, target_grid, target_crossing, target_eval, target_blocks, candidates_table, block_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual NIMBY low-entry vote-side follow-up screen\n\n');
fprintf(fid, ['This workflow keeps the best direct access-side improvement in play and re-screens only the remaining vote-side / renter-side annual margins. ', ...
    'It fixes uniform cohorts, hold-5y `ka`, benchmark `CC`, and low-entry owner grid `housingmax = %.0f`, then varies only `theta_r` and `rent_markup`.\n\n'], ...
    settings.housingmax_low_entry);

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- local target age range: `%d-%d`\n', settings.agemin, settings.agemax);
fprintf(fid, '- early-life blocks: `%s`\n', strjoin(string(settings.early_life_block_starts) + "-" + string(settings.early_life_block_starts + 4), ", "));
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', settings.solver_I, settings.solver_J);
fprintf(fid, '- fixed annual baseline: uniform cohorts, hold-5y `ka`, benchmark `CC`, low-entry owner grid `housingmax = %.0f`\n', settings.housingmax_low_entry);
fprintf(fid, '- screened annual axes: `theta_r`, `rent_markup`\n');
fprintf(fid, '- target eval price: `%.2f`\n', settings.eval_price);
fprintf(fid, '- target eval vote/mass: `%.6f`\n', target_eval.vote_per_mass);
fprintf(fid, '- target eval debt/mass: `%.6f`\n', target_eval.debt_per_mass);
if target_crossing.exists && target_crossing.is_unique
    fprintf(fid, '- target crossing on workflow grid: `%.6f`\n\n', target_crossing.refined_price);
else
    fprintf(fid, '- target crossing on workflow grid: not uniquely identified\n\n');
end

fprintf(fid, '## Target 5-year grid\n\n');
fprintf(fid, '| House price | Vote/mass | Debt/mass | Mass |\n');
fprintf(fid, '|---:|---:|---:|---:|\n');
for i = 1:height(target_grid)
    fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` |\n', ...
        target_grid.a_price(i), target_grid.vote_per_mass(i), target_grid.debt_per_mass(i), target_grid.mass(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Target early-life blocks at eval price\n\n');
fprintf(fid, '| Age block | 5-year vote/mass | 5-year owner share | 5-year mean b |\n');
fprintf(fid, '|---|---:|---:|---:|\n');
for i = 1:height(target_blocks)
    fprintf(fid, '| %s | `%.6f` | `%.6f` | `%.6f` |\n', ...
        char(target_blocks.age_block(i)), target_blocks.five_year_vote_per_mass(i), ...
        target_blocks.five_year_owner_share(i), target_blocks.five_year_mean_liquid_assets(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Candidate ranking\n\n');
fprintf(fid, ['Score is heuristic: overall vote RMSE + 0.25 * overall debt RMSE + early-life vote RMSE + ', ...
    '0.5 * early-life owner-share RMSE + 0.5 * early-life liquid-asset RMSE + crossing penalties. Lower is better.\n\n']);
fprintf(fid, '| Rank | Candidate | Eval vote/mass | Eval debt/mass | Early vote RMSE | Early owner RMSE | Early liquid-asset RMSE | 25-29 owner gap | 25-29 b gap | 50-54 owner gap | 50-54 b gap | Crossing | Score |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
max_rows = min(height(candidates_table), 20);
for i = 1:max_rows
    crossing_text = "none";
    if candidates_table.crossing_exists(i) == 1 && candidates_table.crossing_is_unique(i) == 1 && ~isnan(candidates_table.crossing_refined_price(i))
        crossing_text = string(sprintf('%.4f', candidates_table.crossing_refined_price(i)));
    end
    fprintf(fid, '| %d | %s | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | %s | `%.6f` |\n', ...
        i, char(candidates_table.label(i)), candidates_table.eval_vote_per_mass(i), ...
        candidates_table.eval_debt_per_mass(i), candidates_table.early_vote_rmse(i), ...
        candidates_table.early_owner_share_rmse(i), candidates_table.early_liquid_asset_rmse(i), ...
        candidates_table.eval_owner_share_gap_25_29(i), candidates_table.eval_liquid_asset_gap_25_29(i), ...
        candidates_table.eval_owner_share_gap_50_54(i), candidates_table.eval_liquid_asset_gap_50_54(i), ...
        char(crossing_text), candidates_table.score(i));
end
fprintf(fid, '\n');

if height(candidates_table) >= 1
    best_id = candidates_table.candidate_id(1);
    best_label = candidates_table.label(1);
    best_blocks = block_table(block_table.candidate_id == best_id, :);
    fprintf(fid, '## Best candidate early-life blocks\n\n');
    fprintf(fid, 'Best candidate: `%s`\n\n', char(best_label));
    fprintf(fid, '| Age block | 5-year vote/mass | Annual vote/mass | Gap | 5-year owner share | Annual owner share | Gap | 5-year mean b | Annual mean b | Gap |\n');
    fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
    for i = 1:height(best_blocks)
        fprintf(fid, '| %s | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n', ...
            char(best_blocks.age_block(i)), best_blocks.five_year_vote_per_mass(i), best_blocks.annual_vote_per_mass(i), ...
            best_blocks.vote_gap(i), best_blocks.five_year_owner_share(i), best_blocks.annual_owner_share(i), ...
            best_blocks.owner_share_gap(i), best_blocks.five_year_mean_liquid_assets(i), ...
            best_blocks.annual_mean_liquid_assets(i), best_blocks.liquid_asset_gap(i));
    end
    fprintf(fid, '\n');
end

fprintf(fid, 'The full candidate ranking is saved in `nimby_annual_low_entry_vote_followup_candidates.csv`, and the full age-block panel is saved in `nimby_annual_low_entry_vote_followup_candidate_blocks.csv`.\n');
fclose(fid);
end
