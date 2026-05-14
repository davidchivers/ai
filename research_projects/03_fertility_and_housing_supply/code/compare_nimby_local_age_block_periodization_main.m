function compare_nimby_local_age_block_periodization_main(mode, variant)
% compare_nimby_local_age_block_periodization_main.m -- Collapse the local
% annual NIMBY benchmark into 5-year age blocks and compare against the
% local 5-year benchmark at the same benchmark price.
%
% Usage:
%   compare_nimby_local_age_block_periodization_main
%   compare_nimby_local_age_block_periodization_main('benchmark')
%   compare_nimby_local_age_block_periodization_main('smoke', 'stage1_reference')
%
% Outputs:
%   notes/build/nimby_local_age_block_periodization.csv
%   notes/build/nimby_local_age_block_periodization_summary.csv
%   notes/build/nimby_local_age_block_periodization.md

if nargin < 1 || isempty(mode)
    mode = 'benchmark';
end
if nargin < 2 || isempty(variant)
    variant = 'stage1_reference';
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
clear SolveSS_function SolveSS_fertility

ensure_external_matlab_data_paths();

cfg = build_config(mode, variant, project_root);
ensure_transition_matrix(cfg.five_year_overrides.transition_matrix_file, 5, cfg.agemin, cfg.agemax);
ensure_transition_matrix(cfg.annual_overrides.transition_matrix_file, 1, cfg.agemin, cfg.agemax);

five_year_point = evaluate_point(cfg.eval_price, cfg.rbPos_five_year, cfg.five_year_overrides);
annual_point = evaluate_point(cfg.eval_price, cfg.rbPos_annual, cfg.annual_overrides);

five_year_summary = summarize_by_age(five_year_point.diagnostics, cfg.five_year_overrides);
annual_summary = summarize_by_age(annual_point.diagnostics, cfg.annual_overrides);
block_table = build_age_block_table(five_year_summary, annual_summary, cfg);
summary_table = build_summary_table(five_year_point, annual_point);

writetable(block_table, fullfile(out_dir, 'nimby_local_age_block_periodization.csv'));
writetable(summary_table, fullfile(out_dir, 'nimby_local_age_block_periodization_summary.csv'));
save(fullfile(out_dir, 'nimby_local_age_block_periodization_results.mat'), ...
    'cfg', 'five_year_point', 'annual_point', 'five_year_summary', 'annual_summary', 'block_table', 'summary_table');

write_report(fullfile(out_dir, 'nimby_local_age_block_periodization.md'), cfg, summary_table, block_table);
end

function cfg = build_config(mode, variant, project_root)
base = fertility_benchmark_config();
cfg = struct();
cfg.mode = lower(string(mode));
cfg.variant = lower(string(variant));
cfg.agemin = 25;
cfg.agemax = 80;
cfg.eval_price = base.eval_price;
cfg.rbPos_five_year = base.rbPos;
cfg.rbPos_annual = annualize_net_rate(base.rbPos, 5);
cfg.beta_five_year = 0.98;
cfg.bequestweight_five_year = 0.98;
cfg.ra_five_year = -0.03;
cfg.rent_markup_five_year = 0.02;
cfg.rb_spread_five_year = 0.02;
cfg.ka_five_year = 0.06;
cfg.d_a_price_five_year = 1.01;

switch char(cfg.mode)
    case 'benchmark'
        cfg.solver_I = base.overrides.I;
        cfg.solver_J = base.overrides.J;
    case 'smoke'
        cfg.solver_I = base.stage1_solver_overrides.I;
        cfg.solver_J = base.stage1_solver_overrides.J;
    otherwise
        error('Unknown mode "%s". Use "smoke" or "benchmark".', mode);
end

five_year_overrides = build_nimby_shutoff_overrides(base.overrides);
five_year_overrides.agemin = cfg.agemin;
five_year_overrides.agemax = cfg.agemax;
five_year_overrides.dage = 5;
five_year_overrides.I = cfg.solver_I;
five_year_overrides.J = cfg.solver_J;
five_year_overrides.housingmin = 0;
five_year_overrides.housingmax = 15;
five_year_overrides.bmin = -20;
five_year_overrides.bmax = 20;
five_year_overrides.ka = cfg.ka_five_year;
five_year_overrides.bequestweight = cfg.bequestweight_five_year;
five_year_overrides.d_a_price = cfg.d_a_price_five_year;
five_year_overrides.cohort_weights_by_age = expand_cohort_profile(cfg.agemin:5:cfg.agemax);
five_year_overrides.transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_5y_25_80.mat');
cfg.five_year_overrides = five_year_overrides;

annual_overrides = build_nimby_shutoff_overrides(base.overrides);
annual_overrides.agemin = cfg.agemin;
annual_overrides.agemax = cfg.agemax;
annual_overrides.dage = 1;
annual_overrides.I = cfg.solver_I;
annual_overrides.J = cfg.solver_J;
annual_overrides.housingmin = 0;
annual_overrides.housingmax = 15;
annual_overrides.bmin = -20;
annual_overrides.bmax = 20;
annual_overrides.transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_annual.mat');
annual_overrides.beta = annualize_discount(cfg.beta_five_year, 5);
annual_overrides.bequestweight = annualize_discount(cfg.bequestweight_five_year, 5);
annual_overrides.rspread = annualize_spread(base.rbPos, cfg.rb_spread_five_year, 5);
annual_overrides.ra = annualize_net_rate(cfg.ra_five_year, 5);
annual_overrides.rent_markup = annualize_net_rate(cfg.rent_markup_five_year, 5);
annual_overrides.ka = cfg.ka_five_year;
annual_overrides.d_a_price = cfg.d_a_price_five_year;

switch char(cfg.variant)
    case 'stage1_reference'
        annual_overrides.cohort_weights_by_age = expand_cohort_profile(cfg.agemin:1:cfg.agemax);
    otherwise
        error('Unknown annual variant "%s".', variant);
end

cfg.annual_overrides = annual_overrides;
end

function point = evaluate_point(a_price, rbPos, overrides)
[distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([a_price, rbPos], overrides);
mass = sum(diagnostics.age_mass);
point = struct( ...
    'distance', distance, ...
    'totalvote', totalvote, ...
    'debtstock', debtstock, ...
    'mass', mass, ...
    'vote_per_mass', totalvote / max(mass, 1e-12), ...
    'debt_per_mass', debtstock / max(mass, 1e-12), ...
    'diagnostics', diagnostics);
end

function summary = summarize_by_age(diagnostics, overrides)
ages = overrides.agemin:overrides.dage:overrides.agemax;
mass_age = diagnostics.age_mass(:);
vote_age = squeeze(sum(sum(sum(diagnostics.vote4, 1), 2), 3));
vote_age = vote_age(:);

owner_mass_age = squeeze(sum(sum(sum(diagnostics.dens4(:, 2:end, :, :), 1), 2), 3));
owner_mass_age = owner_mass_age(:);

b_grid = linspace(overrides.bmin, overrides.bmax, size(diagnostics.dens4, 1))';
b_age = zeros(numel(ages), 1);
for ia = 1:numel(ages)
    dens_age = diagnostics.dens4(:, :, :, ia);
    b_age(ia) = sum(dens_age .* reshape(b_grid, [], 1, 1), 'all');
end

summary = struct();
summary.ages = ages(:);
summary.mass_age = mass_age;
summary.vote_age = vote_age;
summary.owner_mass_age = owner_mass_age;
summary.b_sum_age = b_age;
summary.vote_per_mass_age = vote_age ./ max(mass_age, 1e-12);
summary.owner_share_age = owner_mass_age ./ max(mass_age, 1e-12);
summary.mean_liquid_assets_age = b_age ./ max(mass_age, 1e-12);
end

function block_table = build_age_block_table(five_year_summary, annual_summary, cfg)
block_starts = cfg.agemin:5:cfg.agemax;
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
five_year_mass_share = NaN(n, 1);
annual_mass_share = NaN(n, 1);

for i = 1:n
    lower_age = block_starts(i);
    upper_age = min(lower_age + 4, cfg.agemax);
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

    five_year_mass_share(i) = mass5 / max(sum(five_year_summary.mass_age), 1e-12);
    annual_mass_share(i) = mass1 / max(sum(annual_summary.mass_age), 1e-12);
end

block_table = table(age_block, ...
    five_year_vote_per_mass, annual_vote_per_mass, vote_gap, ...
    five_year_owner_share, annual_owner_share, owner_share_gap, ...
    five_year_mean_liquid_assets, annual_mean_liquid_assets, liquid_asset_gap, ...
    five_year_mass_share, annual_mass_share);
end

function summary_table = build_summary_table(five_year_point, annual_point)
summary_table = table( ...
    five_year_point.vote_per_mass, annual_point.vote_per_mass, annual_point.vote_per_mass - five_year_point.vote_per_mass, ...
    five_year_point.debt_per_mass, annual_point.debt_per_mass, annual_point.debt_per_mass - five_year_point.debt_per_mass, ...
    five_year_point.mass, annual_point.mass, ...
    'VariableNames', {'five_year_vote_per_mass', 'annual_vote_per_mass', 'vote_gap', ...
    'five_year_debt_per_mass', 'annual_debt_per_mass', 'debt_gap', ...
    'five_year_mass', 'annual_mass'});
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

function write_report(report_path, cfg, summary_table, block_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Local NIMBY age-block periodization comparison\n\n');
fprintf(fid, 'This report compares the local 5-year NIMBY shutoff benchmark to the local annual benchmark at `a\\_price = %.2f`, collapsing the annual solution into 5-year age blocks so the age profile can be compared directly.\n\n', cfg.eval_price);

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(cfg.mode));
fprintf(fid, '- annual variant: `%s`\n', char(cfg.variant));
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', cfg.solver_I, cfg.solver_J);
fprintf(fid, '- annual benchmark uses: annualized `beta`, `bequestweight`, `ra`, `rspread`, `rent_markup`; hold-5y `ka`; hold-5y vote shock; expanded 5-year cohort profile on annual ages.\n\n');

fprintf(fid, '## Overall benchmark comparison\n\n');
fprintf(fid, '| 5-year vote/mass | Annual vote/mass | Gap | 5-year debt/mass | Annual debt/mass | Gap |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|\n');
fprintf(fid, '| `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n\n', ...
    summary_table.five_year_vote_per_mass, summary_table.annual_vote_per_mass, summary_table.vote_gap, ...
    summary_table.five_year_debt_per_mass, summary_table.annual_debt_per_mass, summary_table.debt_gap);

fprintf(fid, '## 5-year age-block comparison\n\n');
fprintf(fid, '| Age block | 5-year vote/mass | Annual vote/mass | Gap | 5-year owner share | Annual owner share | 5-year mean b | Annual mean b |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(block_table)
    fprintf(fid, '| %s | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n', ...
        char(block_table.age_block(i)), block_table.five_year_vote_per_mass(i), block_table.annual_vote_per_mass(i), ...
        block_table.vote_gap(i), block_table.five_year_owner_share(i), block_table.annual_owner_share(i), ...
        block_table.five_year_mean_liquid_assets(i), block_table.annual_mean_liquid_assets(i));
end
fprintf(fid, '\n');

fprintf(fid, 'Annual age blocks are formed by summing annual age masses, annual vote contributions, owner masses, and liquid-asset sums over the corresponding single-year ages before normalizing by the block mass.\n');
fclose(fid);
end
