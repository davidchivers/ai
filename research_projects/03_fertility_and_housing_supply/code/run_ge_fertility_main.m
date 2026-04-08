function run_ge_fertility_main()
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

benchmark_cfg = fertility_benchmark_config();
benchmark_overrides = benchmark_cfg.overrides;

repro_overrides = struct( ...
    'C', 1, ...
    'birth_utility', 0, ...
    'child_utility', 0, ...
    'birth_cost', 0, ...
    'lambda_crowd', 0, ...
    'psi_crowd', 0, ...
    'p_leave', 0, ...
    'logit_scale', 0.15, ...
    'I', benchmark_overrides.I, ...
    'J', benchmark_overrides.J);

x_repro = [2.0, 0.03];
distance_upstream = SolveSS_function(x_repro);
upstream = load('SS_function.mat');
vote_upstream = sum(upstream.dens4 .* upstream.pref4, 'all');
debt_upstream = sum(upstream.bbbb .* upstream.dens4, 'all');
[distance_fertility, ~, ~, totalvote_fertility, debtstock_fertility] = SolveSS_fertility(x_repro, repro_overrides);
fertility_repro = load('SS_fertility.mat');

repro_table = table( ...
    distance_upstream, distance_fertility, distance_fertility - distance_upstream, ...
    vote_upstream, totalvote_fertility, totalvote_fertility - vote_upstream, ...
    debt_upstream, debtstock_fertility, debtstock_fertility - debt_upstream, ...
    'VariableNames', {'distance_upstream', 'distance_fertility', 'distance_gap', ...
    'vote_upstream', 'vote_fertility', 'vote_gap', ...
    'debt_upstream', 'debt_fertility', 'debt_gap'});

price_grid = benchmark_cfg.full_price_grid;
n = numel(price_grid);
avg_birth_rate = NaN(n, 1);
mass_error = NaN(n, 1);
share_child_0 = NaN(n, 1);
share_child_1 = NaN(n, 1);
share_child_2 = NaN(n, 1);
share_child_3 = NaN(n, 1);
share_parity_0 = NaN(n, 1);
share_parity_1 = NaN(n, 1);
share_parity_2 = NaN(n, 1);
share_parity_3plus = NaN(n, 1);
share_home_any_40 = NaN(n, 1);
share_home_any_50 = NaN(n, 1);
mean_home_children_40 = NaN(n, 1);
mean_home_children_50 = NaN(n, 1);
totalvote = NaN(n, 1);
debtstock = NaN(n, 1);
distance = NaN(n, 1);

for i = 1:n
    [distance(i), ~, ~, totalvote(i), debtstock(i), diagnostics] = SolveSS_fertility([price_grid(i), benchmark_cfg.rbPos], benchmark_overrides);
    avg_birth_rate(i) = diagnostics.avg_birth_rate;
    mass_error(i) = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));
    child_shares = weighted_age_average(diagnostics.child_dist_by_age, diagnostics.age_mass);
    share_child_0(i) = child_shares(1);
    if numel(child_shares) >= 2
        share_child_1(i) = child_shares(2);
    end
    if numel(child_shares) >= 3
        share_child_2(i) = child_shares(3);
    end
    if numel(child_shares) >= 4
        share_child_3(i) = child_shares(4);
    end

    age40 = find(diagnostics.ages == 40, 1);
    age50 = find(diagnostics.ages == 50, 1);
    parity50 = diagnostics.parity_dist_by_age(age50, :);
    home40 = diagnostics.home_dist_by_age(age40, :);
    home50 = diagnostics.home_dist_by_age(age50, :);
    share_parity_0(i) = parity50(1);
    share_parity_1(i) = parity50(2);
    share_parity_2(i) = parity50(3);
    share_parity_3plus(i) = parity50(4);
    share_home_any_40(i) = 1 - home40(1);
    share_home_any_50(i) = 1 - home50(1);
    mean_home_children_40(i) = sum((0:(numel(home40) - 1)) .* home40);
    mean_home_children_50(i) = sum((0:(numel(home50) - 1)) .* home50);
end

price_table = table(price_grid(:), distance, totalvote, debtstock, avg_birth_rate, mass_error, ...
    share_child_0, share_child_1, share_child_2, share_child_3, ...
    share_parity_0, share_parity_1, share_parity_2, share_parity_3plus, ...
    share_home_any_40, share_home_any_50, mean_home_children_40, mean_home_children_50, ...
    'VariableNames', {'a_price', 'distance', 'totalvote', 'debtstock', 'avg_birth_rate', 'mass_error', ...
    'share_child_0', 'share_child_1', 'share_child_2', 'share_child_3', ...
    'share_parity_0', 'share_parity_1', 'share_parity_2', 'share_parity_3plus', ...
    'share_home_any_40', 'share_home_any_50', 'mean_home_children_40', 'mean_home_children_50'});

[market_table, crossing] = ClearMarkets_fertility(benchmark_cfg.market_price_grid, benchmark_cfg.rbPos, benchmark_overrides);
[~, ~, ~, ~, ~, diagnostics_benchmark] = SolveSS_fertility([benchmark_cfg.eval_price, benchmark_cfg.rbPos], benchmark_overrides);
fertility_benchmark = load('SS_fertility.mat');

writetable(repro_table, fullfile(out_dir, 'fertility_reproduction_check.csv'));
writetable(price_table, fullfile(out_dir, 'fertility_price_sweep.csv'));
writetable(market_table, fullfile(out_dir, 'fertility_market_clearing_grid.csv'));
save(fullfile(out_dir, 'fertility_run_ge_results.mat'), 'repro_table', 'price_table', 'market_table', ...
    'crossing', 'fertility_repro', 'fertility_benchmark', 'diagnostics_benchmark');

report_path = fullfile(out_dir, 'fertility_run_ge_report.md');
fid = fopen(report_path, 'w');
fprintf(fid, '# Fertility GE run\n\n');
fprintf(fid, '## Reproduction check\n\n');
fprintf(fid, '- Distance gap: %.12g\n', repro_table.distance_gap);
fprintf(fid, '- Vote gap: %.12g\n', repro_table.vote_gap);
fprintf(fid, '- Debt gap: %.12g\n\n', repro_table.debt_gap);
fprintf(fid, '## Benchmark defaults\n\n');
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', diagnostics_benchmark.params.I, diagnostics_benchmark.params.J);
fprintf(fid, '- birth utilities: `[%.3f, %.3f, %.3f]`\n', diagnostics_benchmark.params.birth_utility_by_parity);
fprintf(fid, '- child utility: `%.3f`\n', diagnostics_benchmark.params.child_utility);
fprintf(fid, '- birth cost: `%.3f`\n', diagnostics_benchmark.params.birth_cost);
fprintf(fid, '- birth price coeff: `%.3f`\n', diagnostics_benchmark.params.birth_price_coeff);
fprintf(fid, '- lambda crowd: `%.3f`\n\n', diagnostics_benchmark.params.lambda_crowd);
fprintf(fid, '## Price sweep\n\n');
for i = 1:n
    fprintf(fid, '- a_price %.2f: avg_birth_rate %.6f, totalvote %.6f, parity50 [%.3f, %.3f, %.3f, %.3f], home-any age40 %.3f, home-any age50 %.3f, mass_error %.3e\n', ...
        price_grid(i), avg_birth_rate(i), totalvote(i), ...
        share_parity_0(i), share_parity_1(i), share_parity_2(i), share_parity_3plus(i), ...
        share_home_any_40(i), share_home_any_50(i), mass_error(i));
end
fprintf(fid, '\n## Market clearing\n\n');
if crossing.exists
    fprintf(fid, '- Sign changes on supplied market grid: %d\n', crossing.sign_change_count);
    if crossing.is_unique
        fprintf(fid, '- Vote crosses zero between %.2f (%.6f) and %.2f (%.6f)\n', ...
            crossing.lower_price, crossing.lower_vote, crossing.upper_price, crossing.upper_vote);
        fprintf(fid, '- Refined equilibrium price estimate: %.6f (%s)\n', ...
            crossing.refined_price, crossing.method);
    else
        fprintf(fid, '- Non-unique zero crossings on the supplied market grid.\n');
        for i = 1:numel(crossing.lower_prices)
            fprintf(fid, '- Crossing bracket %d: %.2f (%.6f) to %.2f (%.6f)\n', ...
                i, crossing.lower_prices(i), crossing.lower_votes(i), ...
                crossing.upper_prices(i), crossing.upper_votes(i));
        end
    end
else
    fprintf(fid, '- No zero crossing found on the supplied price grid.\n');
end
fclose(fid);
end

function weighted_mean = weighted_age_average(values_by_age, age_mass)
weights = age_mass(:);
weights = weights ./ sum(weights);
weighted_mean = weights' * values_by_age;
end
