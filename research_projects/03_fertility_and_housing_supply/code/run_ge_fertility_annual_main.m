function run_ge_fertility_annual_main(mode)
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
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end

cfg = fertility_benchmark_annual_config();
settings = select_mode_settings(cfg, mode);
ensure_transition_matrix(settings.overrides.transition_matrix_file);
fertility_overrides = settings.overrides;
nimby_overrides = build_nimby_shutoff_overrides(fertility_overrides);

fertility_eval = evaluate_point(cfg.eval_price, cfg.rbPos, fertility_overrides);
nimby_eval = evaluate_point(cfg.eval_price, cfg.rbPos, nimby_overrides);

comparison_table = table( ...
    ["annual_fertility"; "annual_nimby_shutoff"], ...
    repmat(string(settings.mode), 2, 1), ...
    [fertility_eval.params.dage; nimby_eval.params.dage], ...
    [fertility_eval.params.agemin; nimby_eval.params.agemin], ...
    [fertility_eval.params.agemax; nimby_eval.params.agemax], ...
    [fertility_eval.params.I; nimby_eval.params.I], ...
    [fertility_eval.params.J; nimby_eval.params.J], ...
    [fertility_eval.distance; nimby_eval.distance], ...
    [fertility_eval.totalvote; nimby_eval.totalvote], ...
    [fertility_eval.debtstock; nimby_eval.debtstock], ...
    [fertility_eval.avg_birth_rate; nimby_eval.avg_birth_rate], ...
    [fertility_eval.mean_age_first_birth; nimby_eval.mean_age_first_birth], ...
    [fertility_eval.share_first_birth_30_plus; nimby_eval.share_first_birth_30_plus], ...
    'VariableNames', {'model', 'mode', 'dage', 'agemin', 'agemax', 'I', 'J', ...
    'distance', 'totalvote', 'debtstock', 'avg_birth_rate', 'mean_age_first_birth', ...
    'share_first_birth_30_plus'});

price_grid = settings.full_price_grid;
n = numel(price_grid);
distance = NaN(n, 1);
totalvote = NaN(n, 1);
debtstock = NaN(n, 1);
avg_birth_rate = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
median_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
mass_error = NaN(n, 1);

for i = 1:n
    point = evaluate_point(price_grid(i), cfg.rbPos, fertility_overrides);
    distance(i) = point.distance;
    totalvote(i) = point.totalvote;
    debtstock(i) = point.debtstock;
    avg_birth_rate(i) = point.avg_birth_rate;
    avg_first_birth_rate(i) = point.avg_first_birth_rate;
    mean_age_first_birth(i) = point.mean_age_first_birth;
    median_age_first_birth(i) = point.median_age_first_birth;
    share_first_birth_30_plus(i) = point.share_first_birth_30_plus;
    mass_error(i) = max(abs(point.mass_post_policy - point.mass_pre_policy));
end

price_table = table( ...
    price_grid(:), distance, totalvote, debtstock, avg_birth_rate, avg_first_birth_rate, ...
    mean_age_first_birth, median_age_first_birth, share_first_birth_30_plus, mass_error, ...
    'VariableNames', {'a_price', 'distance', 'totalvote', 'debtstock', 'avg_birth_rate', ...
    'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'mass_error'});

[market_table, market_crossing] = ClearMarkets_fertility(settings.market_price_grid, cfg.rbPos, fertility_overrides);
[local_market_table, local_crossing] = ClearMarkets_fertility(settings.local_market_price_grid, cfg.rbPos, fertility_overrides);

writetable(comparison_table, fullfile(out_dir, 'fertility_annual_eval_comparison.csv'));
writetable(price_table, fullfile(out_dir, 'fertility_price_sweep_annual.csv'));
writetable(market_table, fullfile(out_dir, 'fertility_market_clearing_grid_annual.csv'));
writetable(local_market_table, fullfile(out_dir, 'fertility_local_benchmark_search_annual.csv'));
save(fullfile(out_dir, 'fertility_run_ge_annual_results.mat'), 'comparison_table', 'price_table', ...
    'market_table', 'local_market_table', 'market_crossing', 'local_crossing', ...
    'fertility_eval', 'nimby_eval', 'settings');

write_report(fullfile(out_dir, 'fertility_run_ge_annual_report.md'), cfg, settings, ...
    comparison_table, price_table, market_crossing, local_crossing);
end

function settings = select_mode_settings(cfg, mode)
settings = struct();
settings.mode = lower(string(mode));
switch char(settings.mode)
    case 'benchmark'
        settings.overrides = cfg.overrides;
        settings.full_price_grid = cfg.full_price_grid;
        settings.market_price_grid = cfg.market_price_grid;
        settings.local_market_price_grid = cfg.local_market_price_grid;
    case 'smoke'
        settings.overrides = cfg.smoke_overrides;
        settings.full_price_grid = cfg.smoke_full_price_grid;
        settings.market_price_grid = cfg.smoke_market_price_grid;
        settings.local_market_price_grid = cfg.smoke_local_market_price_grid;
    otherwise
        error('Unknown annual solver mode "%s". Use "smoke" or "benchmark".', mode);
end
end

function overrides = build_nimby_shutoff_overrides(base_overrides)
overrides = base_overrides;
overrides.C = 1;
overrides.P = 1;
overrides.birth_utility = 0;
overrides.birth_utility_by_parity = 0;
overrides.child_utility = 0;
overrides.birth_cost = 0;
overrides.birth_price_coeff = 0;
overrides.lambda_crowd = 0;
overrides.psi_crowd = 0;
overrides.p_leave = 0;
overrides.birth_ages = [];
overrides.birth_age_weights = [];
overrides.realized_birth_weights = [];
overrides.first_birth_realized_weights = [];
overrides.leave_home_age_bins = [];
overrides.leave_home_bin_probs = [];
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
point.params = diagnostics.params;
end

function write_report(report_path, cfg, settings, comparison_table, price_table, market_crossing, local_crossing)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual fertility benchmark prototype\n\n');
fprintf(fid, 'This report runs the fertility benchmark on an annual age grid and evaluates the nested annual NIMBY shutoff case through the same solver.\n\n');

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- annual age range: `%d-%d`\n', comparison_table.agemin(1), comparison_table.agemax(1));
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', comparison_table.I(1), comparison_table.J(1));
fprintf(fid, '- annual birth ages: `%d-%d`\n', cfg.annual_birth_ages(1), cfg.annual_birth_ages(end));
fprintf(fid, '- annual financial block is annualized from the 5-year benchmark (`rbPos_5y = %.2f`, `rbPos_1y = %.6f`).\n', ...
    cfg.rbPos_five_year, cfg.rbPos);
fprintf(fid, '- annual first-birth timing target is built by spreading the four CDC 5-year-bin shares uniformly within ages `25-29`, `30-34`, `35-39`, and `40-44`.\n\n');

fprintf(fid, '## Eval-price comparison at `a_price = %.2f`\n\n', cfg.eval_price);
fprintf(fid, '| Model | Vote | Debt | Avg birth rate | Mean age first birth | Share first births 30+ |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|\n');
for i = 1:height(comparison_table)
    fprintf(fid, '| %s | `%.6f` | `%.6f` | `%.6f` | `%.2f` | `%.3f` |\n', ...
        char(comparison_table.model(i)), comparison_table.totalvote(i), comparison_table.debtstock(i), ...
        comparison_table.avg_birth_rate(i), comparison_table.mean_age_first_birth(i), ...
        comparison_table.share_first_birth_30_plus(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Fertility annual price sweep\n\n');
fprintf(fid, '| House price | Vote | Debt | Avg birth rate | Avg first-birth rate | Mean age first birth | Share first births 30+ | Mass error |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(price_table)
    fprintf(fid, '| %.2f | `%.6f` | `%.6f` | `%.6f` | `%.6f` | `%.2f` | `%.3f` | `%.3e` |\n', ...
        price_table.a_price(i), price_table.totalvote(i), price_table.debtstock(i), ...
        price_table.avg_birth_rate(i), price_table.avg_first_birth_rate(i), ...
        price_table.mean_age_first_birth(i), price_table.share_first_birth_30_plus(i), ...
        price_table.mass_error(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Market-clearing scan\n\n');
write_crossing_block(fid, 'Common market grid', market_crossing);
write_crossing_block(fid, 'Local market grid', local_crossing);

fclose(fid);
end

function write_crossing_block(fid, label, crossing)
fprintf(fid, '### %s\n\n', label);
if ~crossing.exists
    fprintf(fid, '- No sign change found on this grid.\n\n');
    return;
end
fprintf(fid, '- Sign changes: `%d`\n', crossing.sign_change_count);
if crossing.is_unique
    fprintf(fid, '- Bracket: `%.3f` (`%.6f`) to `%.3f` (`%.6f`)\n', ...
        crossing.lower_price, crossing.lower_vote, crossing.upper_price, crossing.upper_vote);
    fprintf(fid, '- Refined price: `%.6f` via `%s`\n\n', crossing.refined_price, crossing.method);
else
    fprintf(fid, '- Multiple sign changes found; inspect the saved CSV grids before treating this as the benchmark.\n\n');
end
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end
