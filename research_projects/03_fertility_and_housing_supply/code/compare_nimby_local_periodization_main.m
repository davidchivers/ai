function compare_nimby_local_periodization_main(mode)
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
clear SolveSS_function SolveSS_fertility

ensure_external_matlab_data_paths();
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end

cfg = build_config(mode, project_root);
ensure_transition_matrix(cfg.five_year_overrides.transition_matrix_file, 5, cfg.agemin, cfg.agemax);
ensure_transition_matrix(cfg.annual_overrides.transition_matrix_file, 1, cfg.agemin, cfg.agemax);

price_grid = cfg.price_grid(:);
n = numel(price_grid);
five_year_distance = NaN(n, 1);
five_year_vote = NaN(n, 1);
five_year_debt = NaN(n, 1);
five_year_mass = NaN(n, 1);
five_year_vote_per_mass = NaN(n, 1);
five_year_debt_per_mass = NaN(n, 1);
annual_distance = NaN(n, 1);
annual_vote = NaN(n, 1);
annual_debt = NaN(n, 1);
annual_mass = NaN(n, 1);
annual_vote_per_mass = NaN(n, 1);
annual_debt_per_mass = NaN(n, 1);

for i = 1:n
    five_year_point = evaluate_point(price_grid(i), cfg.rbPos_five_year, cfg.five_year_overrides);
    annual_point = evaluate_point(price_grid(i), cfg.rbPos_annual, cfg.annual_overrides);

    five_year_distance(i) = five_year_point.distance;
    five_year_vote(i) = five_year_point.totalvote;
    five_year_debt(i) = five_year_point.debtstock;
    five_year_mass(i) = five_year_point.mass;
    five_year_vote_per_mass(i) = five_year_point.vote_per_mass;
    five_year_debt_per_mass(i) = five_year_point.debt_per_mass;
    annual_distance(i) = annual_point.distance;
    annual_vote(i) = annual_point.totalvote;
    annual_debt(i) = annual_point.debtstock;
    annual_mass(i) = annual_point.mass;
    annual_vote_per_mass(i) = annual_point.vote_per_mass;
    annual_debt_per_mass(i) = annual_point.debt_per_mass;
end

comparison_table = table( ...
    price_grid, five_year_distance, five_year_vote, five_year_debt, five_year_mass, five_year_vote_per_mass, five_year_debt_per_mass, ...
    annual_distance, annual_vote, annual_debt, annual_mass, annual_vote_per_mass, annual_debt_per_mass, ...
    annual_vote - five_year_vote, annual_debt - five_year_debt, ...
    annual_vote_per_mass - five_year_vote_per_mass, annual_debt_per_mass - five_year_debt_per_mass, ...
    'VariableNames', {'a_price', 'five_year_distance', 'five_year_vote', 'five_year_debt', ...
    'five_year_mass', 'five_year_vote_per_mass', 'five_year_debt_per_mass', ...
    'annual_distance', 'annual_vote', 'annual_debt', 'annual_mass', 'annual_vote_per_mass', 'annual_debt_per_mass', ...
    'vote_gap_annual_minus_five_year', 'debt_gap_annual_minus_five_year', ...
    'vote_per_mass_gap_annual_minus_five_year', 'debt_per_mass_gap_annual_minus_five_year'});

eval_idx = find(abs(price_grid - cfg.eval_price) < 1e-12, 1);
if isempty(eval_idx)
    eval_idx = find(min(abs(price_grid - cfg.eval_price)) == abs(price_grid - cfg.eval_price), 1);
end
eval_table = comparison_table(eval_idx, :);

five_year_crossing = summarize_crossing(price_grid, five_year_vote);
annual_crossing = summarize_crossing(price_grid, annual_vote);

writetable(comparison_table, fullfile(out_dir, 'nimby_local_periodization_comparison.csv'));
writetable(eval_table, fullfile(out_dir, 'nimby_local_periodization_eval_price.csv'));
save(fullfile(out_dir, 'nimby_local_periodization_results.mat'), 'comparison_table', 'eval_table', ...
    'five_year_crossing', 'annual_crossing', 'cfg');

write_report(fullfile(out_dir, 'nimby_local_periodization_report.md'), cfg, eval_table, comparison_table, five_year_crossing, annual_crossing);
end

function cfg = build_config(mode, project_root)
base = fertility_benchmark_config();
settings_mode = lower(string(mode));
agemin = 25;
agemax = 80;
beta_five_year = 0.98;
ra_five_year = -0.03;
rent_markup_five_year = 0.02;
rb_spread_five_year = 0.02;

five_year_overrides = build_nimby_shutoff_overrides(base.overrides);
five_year_overrides.agemin = agemin;
five_year_overrides.agemax = agemax;
five_year_overrides.dage = 5;
five_year_overrides.cohort_weights_by_age = expand_cohort_profile(agemin:5:agemax);
five_year_overrides.transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_5y_25_80.mat');

annual_overrides = build_nimby_shutoff_overrides(base.overrides);
annual_overrides.agemin = agemin;
annual_overrides.agemax = agemax;
annual_overrides.dage = 1;
annual_overrides.cohort_weights_by_age = expand_cohort_profile(agemin:1:agemax);
annual_overrides.transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_annual.mat');
annual_overrides.beta = annualize_discount(beta_five_year, 5);
annual_overrides.rspread = annualize_spread(base.rbPos, rb_spread_five_year, 5);
annual_overrides.ra = annualize_net_rate(ra_five_year, 5);
annual_overrides.rent_markup = annualize_net_rate(rent_markup_five_year, 5);

cfg = struct();
cfg.mode = settings_mode;
cfg.agemin = agemin;
cfg.agemax = agemax;
cfg.eval_price = base.eval_price;
cfg.rbPos_five_year = base.rbPos;
cfg.rbPos_annual = annualize_net_rate(base.rbPos, 5);
cfg.five_year_overrides = five_year_overrides;
cfg.annual_overrides = annual_overrides;

switch char(settings_mode)
    case 'benchmark'
        cfg.price_grid = base.market_price_grid;
    case 'smoke'
        cfg.price_grid = [1.50, 2.00, 2.50];
    otherwise
        error('Unknown comparison mode "%s". Use "smoke" or "benchmark".', mode);
end
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

function ensure_transition_matrix(transition_matrix_file, dage, agemin, agemax)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_periodized(transition_matrix_file, dage, agemin, agemax);
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
    'debt_per_mass', debtstock / max(mass, 1e-12));
end

function crossing = summarize_crossing(price_grid, votes)
brackets = find_crossing_brackets(price_grid, votes);
crossing = struct( ...
    'exists', ~isempty(brackets.lower_prices), ...
    'is_unique', numel(brackets.lower_prices) == 1, ...
    'lower_price', NaN, ...
    'upper_price', NaN, ...
    'lower_vote', NaN, ...
    'upper_vote', NaN, ...
    'refined_price', NaN, ...
    'method', '', ...
    'sign_change_count', numel(brackets.lower_prices));
if crossing.sign_change_count == 1
    crossing.lower_price = brackets.lower_prices(1);
    crossing.upper_price = brackets.upper_prices(1);
    crossing.lower_vote = brackets.lower_votes(1);
    crossing.upper_vote = brackets.upper_votes(1);
    crossing.refined_price = interp1([crossing.lower_vote, crossing.upper_vote], [crossing.lower_price, crossing.upper_price], 0);
    crossing.method = 'linear_interpolation';
elseif crossing.sign_change_count > 1
    crossing.method = 'multiple_crossings';
end
end

function brackets = find_crossing_brackets(price_grid, votes)
lower_prices = [];
upper_prices = [];
lower_votes = [];
upper_votes = [];
for i = 1:(numel(price_grid) - 1)
    if votes(i) == 0
        lower_prices(end + 1, 1) = price_grid(i); %#ok<AGROW>
        upper_prices(end + 1, 1) = price_grid(i); %#ok<AGROW>
        lower_votes(end + 1, 1) = votes(i); %#ok<AGROW>
        upper_votes(end + 1, 1) = votes(i); %#ok<AGROW>
        continue;
    end
    if votes(i + 1) == 0 || sign(votes(i)) ~= sign(votes(i + 1))
        lower_prices(end + 1, 1) = price_grid(i); %#ok<AGROW>
        upper_prices(end + 1, 1) = price_grid(i + 1); %#ok<AGROW>
        lower_votes(end + 1, 1) = votes(i); %#ok<AGROW>
        upper_votes(end + 1, 1) = votes(i + 1); %#ok<AGROW>
    end
end
brackets = struct('lower_prices', lower_prices, 'upper_prices', upper_prices, ...
    'lower_votes', lower_votes, 'upper_votes', upper_votes);
end

function write_report(report_path, cfg, eval_table, comparison_table, five_year_crossing, annual_crossing)
fid = fopen(report_path, 'w');
fprintf(fid, '# Local NIMBY periodization comparison\n\n');
fprintf(fid, 'This report compares a local 5-year NIMBY shutoff benchmark to a local annual NIMBY shutoff benchmark using the same solver family, the same age horizon (`25-80`), and transition matrices rebuilt from the same annual income source.\n\n');

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(cfg.mode));
fprintf(fid, '- 5-year case: `dage = 5`, `rbPos = %.6f`\n', cfg.rbPos_five_year);
fprintf(fid, '- annual case: `dage = 1`, `rbPos = %.6f`\n', cfg.rbPos_annual);
fprintf(fid, '- annual case annualizes `beta`, `ra`, `rspread`, and `rent_markup` from the 5-year benchmark.\n\n');

fprintf(fid, '## Eval-price comparison near `a_price = %.2f`\n\n', cfg.eval_price);
fprintf(fid, '| House price | 5-year vote/mass | Annual vote/mass | Gap | 5-year debt/mass | Annual debt/mass | Gap |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|\n');
fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n\n', ...
    eval_table.a_price, eval_table.five_year_vote_per_mass, eval_table.annual_vote_per_mass, ...
    eval_table.vote_per_mass_gap_annual_minus_five_year, eval_table.five_year_debt_per_mass, ...
    eval_table.annual_debt_per_mass, eval_table.debt_per_mass_gap_annual_minus_five_year);

fprintf(fid, 'Raw levels at the eval price are also saved in the CSV, but the mass-normalized objects are the cleaner comparison because the stationary mass differs across the two discretizations.\n\n');

fprintf(fid, '## Common price grid\n\n');
fprintf(fid, '| House price | 5-year vote/mass | Annual vote/mass | 5-year debt/mass | Annual debt/mass | 5-year mass | Annual mass |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(comparison_table)
    fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n', ...
        comparison_table.a_price(i), comparison_table.five_year_vote_per_mass(i), comparison_table.annual_vote_per_mass(i), ...
        comparison_table.five_year_debt_per_mass(i), comparison_table.annual_debt_per_mass(i), ...
        comparison_table.five_year_mass(i), comparison_table.annual_mass(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Raw levels\n\n');
fprintf(fid, '| House price | 5-year vote | Annual vote | 5-year debt | Annual debt |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|\n');
for i = 1:height(comparison_table)
    fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n', ...
        comparison_table.a_price(i), comparison_table.five_year_vote(i), comparison_table.annual_vote(i), ...
        comparison_table.five_year_debt(i), comparison_table.annual_debt(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Crossing summary\n\n');
write_crossing_block(fid, 'Local 5-year NIMBY', five_year_crossing);
write_crossing_block(fid, 'Local annual NIMBY', annual_crossing);
fclose(fid);
end

function write_crossing_block(fid, label, crossing)
fprintf(fid, '### %s\n\n', label);
if ~crossing.exists
    fprintf(fid, '- No sign change found on the submitted grid.\n\n');
    return;
end
fprintf(fid, '- Sign changes: `%d`\n', crossing.sign_change_count);
if crossing.is_unique
    fprintf(fid, '- Bracket: `%.3f` (`%.6f`) to `%.3f` (`%.6f`)\n', ...
        crossing.lower_price, crossing.lower_vote, crossing.upper_price, crossing.upper_vote);
    fprintf(fid, '- Refined price: `%.6f` via `%s`\n\n', crossing.refined_price, crossing.method);
else
    fprintf(fid, '- Multiple sign changes found on the submitted grid.\n\n');
end
end
