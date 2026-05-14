function compare_nimby_annual_vs_five_year_main(mode)
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

cfg = fertility_benchmark_annual_config();
settings = select_mode_settings(cfg, mode);
ensure_transition_matrix(settings.overrides.transition_matrix_file);
annual_overrides = build_nimby_shutoff_overrides(settings.overrides);

price_grid = settings.market_price_grid(:);
n = numel(price_grid);

annual_distance = NaN(n, 1);
annual_vote = NaN(n, 1);
annual_debt = NaN(n, 1);
annual_mass = NaN(n, 1);
annual_vote_per_mass = NaN(n, 1);
annual_debt_per_mass = NaN(n, 1);
five_distance = NaN(n, 1);
five_vote = NaN(n, 1);
five_debt = NaN(n, 1);
five_mass = NaN(n, 1);
five_vote_per_mass = NaN(n, 1);
five_debt_per_mass = NaN(n, 1);

for i = 1:n
    annual_point = evaluate_annual_point(price_grid(i), cfg.rbPos, annual_overrides);
    five_year_point = evaluate_five_year_point(price_grid(i), cfg.rbPos_five_year);

    annual_distance(i) = annual_point.distance;
    annual_vote(i) = annual_point.totalvote;
    annual_debt(i) = annual_point.debtstock;
    annual_mass(i) = annual_point.mass;
    annual_vote_per_mass(i) = annual_point.vote_per_mass;
    annual_debt_per_mass(i) = annual_point.debt_per_mass;
    five_distance(i) = five_year_point.distance;
    five_vote(i) = five_year_point.totalvote;
    five_debt(i) = five_year_point.debtstock;
    five_mass(i) = five_year_point.mass;
    five_vote_per_mass(i) = five_year_point.vote_per_mass;
    five_debt_per_mass(i) = five_year_point.debt_per_mass;
end

comparison_table = table( ...
    price_grid, annual_distance, annual_vote, annual_debt, annual_mass, annual_vote_per_mass, annual_debt_per_mass, ...
    five_distance, five_vote, five_debt, five_mass, five_vote_per_mass, five_debt_per_mass, ...
    annual_vote - five_vote, annual_debt - five_debt, ...
    annual_vote_per_mass - five_vote_per_mass, annual_debt_per_mass - five_debt_per_mass, ...
    'VariableNames', {'a_price', 'annual_distance', 'annual_vote', 'annual_debt', ...
    'annual_mass', 'annual_vote_per_mass', 'annual_debt_per_mass', ...
    'five_year_distance', 'five_year_vote', 'five_year_debt', 'five_year_mass', 'five_year_vote_per_mass', 'five_year_debt_per_mass', ...
    'vote_gap_annual_minus_five_year', 'debt_gap_annual_minus_five_year', ...
    'vote_per_mass_gap_annual_minus_five_year', 'debt_per_mass_gap_annual_minus_five_year'});

eval_idx = find(abs(price_grid - cfg.eval_price) < 1e-12, 1);
if isempty(eval_idx)
    eval_idx = find(min(abs(price_grid - cfg.eval_price)) == abs(price_grid - cfg.eval_price), 1);
end
eval_table = comparison_table(eval_idx, :);

annual_crossing = summarize_crossing(price_grid, annual_vote);
five_year_crossing = summarize_crossing(price_grid, five_vote);

writetable(comparison_table, fullfile(out_dir, 'nimby_annual_vs_five_year_comparison.csv'));
writetable(eval_table, fullfile(out_dir, 'nimby_annual_vs_five_year_eval_price.csv'));
save(fullfile(out_dir, 'nimby_annual_vs_five_year_results.mat'), 'comparison_table', 'eval_table', ...
    'annual_crossing', 'five_year_crossing', 'settings');

write_report(fullfile(out_dir, 'nimby_annual_vs_five_year_report.md'), cfg, settings, eval_table, comparison_table, annual_crossing, five_year_crossing);
end

function settings = select_mode_settings(cfg, mode)
settings = struct();
settings.mode = lower(string(mode));
switch char(settings.mode)
    case 'benchmark'
        settings.overrides = cfg.overrides;
        settings.market_price_grid = cfg.market_price_grid;
    case 'smoke'
        settings.overrides = cfg.smoke_overrides;
        settings.market_price_grid = cfg.smoke_market_price_grid;
    otherwise
        error('Unknown comparison mode "%s". Use "smoke" or "benchmark".', mode);
end
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end

function point = evaluate_annual_point(a_price, rbPos, overrides)
[distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([a_price, rbPos], overrides);
mass = sum(diagnostics.age_mass);
point = struct('distance', distance, 'totalvote', totalvote, 'debtstock', debtstock, ...
    'mass', mass, 'vote_per_mass', totalvote / max(mass, 1e-12), 'debt_per_mass', debtstock / max(mass, 1e-12));
end

function point = evaluate_five_year_point(a_price, rbPos)
distance = SolveSS_function([a_price, rbPos]);
upstream = load('SS_function.mat');
point = struct();
point.distance = distance;
point.totalvote = sum(upstream.dens4 .* upstream.pref4, 'all');
point.debtstock = sum(upstream.bbbb .* upstream.dens4, 'all');
point.mass = sum(upstream.dens4, 'all');
point.vote_per_mass = point.totalvote / max(point.mass, 1e-12);
point.debt_per_mass = point.debtstock / max(point.mass, 1e-12);
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

function write_report(report_path, cfg, settings, eval_table, comparison_table, annual_crossing, five_year_crossing)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual NIMBY vs 5-year NIMBY comparison\n\n');
fprintf(fid, 'This report compares the annual-period NIMBY shutoff case solved through the project-03 annualized solver to the existing 5-year NIMBY benchmark solved through `SolveSS_function`.\n\n');

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- annual case uses ages `%d-%d` with `dage = 1`\n', cfg.annual_ages(1), cfg.annual_ages(end));
fprintf(fid, '- annual case uses annualized `rbPos` and annualized flow/discount primitives from the 5-year benchmark.\n');
fprintf(fid, '- 5-year case uses the existing upstream benchmark path at the native `rbPos = %.2f` convention.\n\n', cfg.rbPos_five_year);

fprintf(fid, '## Eval-price comparison near `a_price = %.2f`\n\n', cfg.eval_price);
fprintf(fid, '| House price | Annual vote/mass | 5-year vote/mass | Gap | Annual debt/mass | 5-year debt/mass | Gap |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|\n');
fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n\n', ...
    eval_table.a_price, eval_table.annual_vote_per_mass, eval_table.five_year_vote_per_mass, ...
    eval_table.vote_per_mass_gap_annual_minus_five_year, eval_table.annual_debt_per_mass, ...
    eval_table.five_year_debt_per_mass, eval_table.debt_per_mass_gap_annual_minus_five_year);

fprintf(fid, 'Raw levels are still saved in the CSV, but the mass-normalized comparison is the cleaner object because the stationary mass differs across the annual and 5-year discretizations.\n\n');

fprintf(fid, '## Common price grid\n\n');
fprintf(fid, '| House price | Annual vote/mass | 5-year vote/mass | Annual debt/mass | 5-year debt/mass | Annual mass | 5-year mass |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(comparison_table)
    fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n', ...
        comparison_table.a_price(i), comparison_table.annual_vote_per_mass(i), comparison_table.five_year_vote_per_mass(i), ...
        comparison_table.annual_debt_per_mass(i), comparison_table.five_year_debt_per_mass(i), ...
        comparison_table.annual_mass(i), comparison_table.five_year_mass(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Raw levels\n\n');
fprintf(fid, '| House price | Annual vote | 5-year vote | Annual debt | 5-year debt |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|\n');
for i = 1:height(comparison_table)
    fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` | `%.6f` |\n', ...
        comparison_table.a_price(i), comparison_table.annual_vote(i), comparison_table.five_year_vote(i), ...
        comparison_table.annual_debt(i), comparison_table.five_year_debt(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Crossing summary\n\n');
write_crossing_block(fid, 'Annual NIMBY', annual_crossing);
write_crossing_block(fid, '5-year NIMBY', five_year_crossing);

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
