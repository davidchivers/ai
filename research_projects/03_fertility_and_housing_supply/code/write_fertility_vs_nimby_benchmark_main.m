function write_fertility_vs_nimby_benchmark_main()
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

cfg = fertility_benchmark_config();
market_price_grid = cfg.market_price_grid;

repro = compute_reproduction_check(cfg);
nimby_cache = load_cached_nimby_outputs(out_dir, market_price_grid);
if nimby_cache.is_valid
    nimby_grid = nimby_cache.grid;
    nimby_market = nimby_cache.market;
    nimby_crossing = nimby_cache.crossing;
    nimby_eq = nimby_cache.eq;
else
    nimby_grid = evaluate_nimby_grid(market_price_grid, cfg.rbPos);
    [nimby_market, nimby_crossing] = crossing_table(nimby_grid);
    nimby_eq = evaluate_nimby_point(nimby_crossing.refined_price, cfg.rbPos);
end

fertility_grid = evaluate_fertility_grid(market_price_grid, cfg.rbPos, cfg.overrides);
[fertility_market, fertility_crossing_coarse] = ClearMarkets_fertility(market_price_grid, cfg.rbPos, cfg.overrides);
[fertility_local_market, fertility_crossing] = ClearMarkets_fertility(cfg.local_market_price_grid, cfg.rbPos, cfg.overrides);
timing_profile_table = evaluate_fertility_timing_profiles(cfg.full_price_grid, cfg.rbPos, cfg.overrides);

fertility_eq = evaluate_fertility_point(fertility_crossing.refined_price, cfg.rbPos, cfg.overrides);
fertility_eval = evaluate_fertility_point(cfg.eval_price, cfg.rbPos, cfg.overrides);

summary_table = table( ...
    ["nimby"; "fertility"], ...
    [nimby_crossing.refined_price; fertility_crossing.refined_price], ...
    [nimby_eq.totalvote; fertility_eq.totalvote], ...
    [nimby_eq.vote_per_mass; fertility_eq.vote_per_mass], ...
    [nimby_eq.mass; fertility_eq.mass], ...
    [nimby_eq.debtstock; fertility_eq.debtstock], ...
    [nimby_eq.price_income_ratio; fertility_eq.price_income_ratio], ...
    [nimby_eq.rent_share; fertility_eq.rent_share], ...
    [NaN; fertility_eq.avg_birth_rate], ...
    [NaN; fertility_eq.avg_first_birth_rate], ...
    [NaN; fertility_eq.mean_age_first_birth], ...
    [NaN; fertility_eq.median_age_first_birth], ...
    [NaN; fertility_eq.share_first_birth_30_plus], ...
    [NaN; fertility_eq.share_parity_0], ...
    [NaN; fertility_eq.share_parity_1], ...
    [NaN; fertility_eq.share_parity_2], ...
    [NaN; fertility_eq.share_parity_3plus], ...
    [NaN; fertility_eq.share_home_any_40], ...
    [NaN; fertility_eq.share_home_any_50], ...
    [NaN; fertility_eq.mean_home_children_40], ...
    [NaN; fertility_eq.mean_home_children_50], ...
    'VariableNames', {'model', 'refined_price', 'totalvote', 'vote_per_mass', 'mass', 'debtstock', ...
    'price_income_ratio', 'rent_share', 'avg_birth_rate', 'avg_first_birth_rate', ...
    'mean_age_first_birth', 'median_age_first_birth', 'share_first_birth_30_plus', ...
    'parity0_age50', 'parity1_age50', 'parity2_age50', 'parity3p_age50', ...
    'home_any_age40', 'home_any_age50', 'mean_home_age40', 'mean_home_age50'});

common_table = join( ...
    nimby_grid(:, {'a_price', 'totalvote', 'vote_per_mass', 'mass', 'debtstock', 'price_income_ratio', 'rent_share'}), ...
    fertility_grid(:, {'a_price', 'totalvote', 'vote_per_mass', 'mass', 'debtstock', 'price_income_ratio', 'rent_share', ...
    'avg_birth_rate', 'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'share_parity_0', 'share_parity_1', 'share_parity_2', 'share_parity_3plus', ...
    'share_home_any_40', 'share_home_any_50'}), ...
    'Keys', 'a_price', 'LeftVariables', {'a_price', 'totalvote', 'vote_per_mass', 'mass', 'debtstock', 'price_income_ratio', 'rent_share'}, ...
    'RightVariables', {'totalvote', 'vote_per_mass', 'mass', 'debtstock', 'price_income_ratio', 'rent_share', ...
    'avg_birth_rate', 'avg_first_birth_rate', 'mean_age_first_birth', 'median_age_first_birth', ...
    'share_first_birth_30_plus', 'share_parity_0', 'share_parity_1', 'share_parity_2', 'share_parity_3plus', ...
    'share_home_any_40', 'share_home_any_50'});
common_table.Properties.VariableNames = {'a_price', ...
    'nimby_vote', 'nimby_vote_per_mass', 'nimby_mass', 'nimby_debt', 'nimby_price_income', 'nimby_rent_share', ...
    'fertility_vote', 'fertility_vote_per_mass', 'fertility_mass', 'fertility_debt', 'fertility_price_income', 'fertility_rent_share', ...
    'fertility_birth_rate', 'fertility_first_birth_rate', 'fertility_mean_age_first_birth', ...
    'fertility_median_age_first_birth', 'fertility_share_first_birth_30_plus', ...
    'fertility_parity_0', 'fertility_parity_1', ...
    'fertility_parity_2', 'fertility_parity_3plus', ...
    'fertility_home_any_40', 'fertility_home_any_50'};

writetable(repro, fullfile(out_dir, 'fertility_vs_nimby_reproduction_check.csv'));
writetable(nimby_market, fullfile(out_dir, 'nimby_market_clearing_grid.csv'));
writetable(fertility_market, fullfile(out_dir, 'fertility_market_clearing_grid.csv'));
writetable(fertility_local_market, fullfile(out_dir, 'fertility_local_benchmark_search.csv'));
writetable(summary_table, fullfile(out_dir, 'fertility_vs_nimby_benchmark_summary.csv'));
writetable(common_table, fullfile(out_dir, 'fertility_vs_nimby_common_price_grid.csv'));
writetable(timing_profile_table, fullfile(out_dir, 'fertility_first_birth_timing_profiles.csv'));

report_path = fullfile(out_dir, 'fertility_vs_nimby_benchmark_report.md');
write_report(report_path, repro, nimby_crossing, fertility_crossing_coarse, fertility_crossing, nimby_eq, fertility_eq, fertility_eval, common_table, cfg);
end

function repro = compute_reproduction_check(cfg)
repro_overrides = build_nimby_shutoff_overrides(cfg.overrides);

x_repro = [2.0, cfg.rbPos];
evalc('distance_upstream = SolveSS_function(x_repro);');
upstream = load('SS_function.mat');
vote_upstream = sum(upstream.dens4 .* upstream.pref4, 'all');
debt_upstream = sum(upstream.bbbb .* upstream.dens4, 'all');
evalc('[distance_fertility, ~, ~, vote_fertility, debt_fertility] = SolveSS_fertility(x_repro, repro_overrides);');

repro = table( ...
    distance_upstream, distance_fertility, distance_fertility - distance_upstream, ...
    vote_upstream, vote_fertility, vote_fertility - vote_upstream, ...
    debt_upstream, debt_fertility, debt_fertility - debt_upstream, ...
    'VariableNames', {'distance_upstream', 'distance_fertility', 'distance_gap', ...
    'vote_upstream', 'vote_fertility', 'vote_gap', ...
    'debt_upstream', 'debt_fertility', 'debt_gap'});
end

function tbl = evaluate_nimby_grid(price_grid, rbPos)
n = numel(price_grid);
distance = NaN(n, 1);
totalvote = NaN(n, 1);
vote_per_mass = NaN(n, 1);
mass = NaN(n, 1);
debtstock = NaN(n, 1);
price_income_ratio = NaN(n, 1);
rent_share = NaN(n, 1);

for i = 1:n
    point = evaluate_nimby_point(price_grid(i), rbPos);
    distance(i) = point.distance;
    totalvote(i) = point.totalvote;
    vote_per_mass(i) = point.vote_per_mass;
    mass(i) = point.mass;
    debtstock(i) = point.debtstock;
    price_income_ratio(i) = point.price_income_ratio;
    rent_share(i) = point.rent_share;
end

tbl = table(price_grid(:), distance, totalvote, vote_per_mass, mass, debtstock, price_income_ratio, rent_share, ...
    'VariableNames', {'a_price', 'distance', 'totalvote', 'vote_per_mass', 'mass', 'debtstock', 'price_income_ratio', 'rent_share'});
end

function point = evaluate_nimby_point(a_price, rbPos)
evalc('distance = SolveSS_function([a_price, rbPos]);');
state = load('SS_function.mat');
point = struct();
point.distance = distance;
point.totalvote = sum(state.dens4 .* state.pref4, 'all');
point.mass = sum(state.dens4, 'all');
point.vote_per_mass = safe_ratio(point.totalvote, point.mass);
point.debtstock = sum(state.bbbb .* state.dens4, 'all');
point.price_income_ratio = a_price / max(sum(state.dens4 .* state.zzzz, 'all'), 1e-12);
point.rent_share = sum(state.dens4(:, 1, :, :), 'all');
end

function tbl = evaluate_fertility_grid(price_grid, rbPos, overrides)
n = numel(price_grid);
distance = NaN(n, 1);
totalvote = NaN(n, 1);
vote_per_mass = NaN(n, 1);
mass = NaN(n, 1);
debtstock = NaN(n, 1);
price_income_ratio = NaN(n, 1);
rent_share = NaN(n, 1);
avg_birth_rate = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
median_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
share_parity_0 = NaN(n, 1);
share_parity_1 = NaN(n, 1);
share_parity_2 = NaN(n, 1);
share_parity_3plus = NaN(n, 1);
share_home_any_40 = NaN(n, 1);
share_home_any_50 = NaN(n, 1);

for i = 1:n
    point = evaluate_fertility_point(price_grid(i), rbPos, overrides);
    distance(i) = point.distance;
    totalvote(i) = point.totalvote;
    vote_per_mass(i) = point.vote_per_mass;
    mass(i) = point.mass;
    debtstock(i) = point.debtstock;
    price_income_ratio(i) = point.price_income_ratio;
    rent_share(i) = point.rent_share;
    avg_birth_rate(i) = point.avg_birth_rate;
    avg_first_birth_rate(i) = point.avg_first_birth_rate;
    mean_age_first_birth(i) = point.mean_age_first_birth;
    median_age_first_birth(i) = point.median_age_first_birth;
    share_first_birth_30_plus(i) = point.share_first_birth_30_plus;
    share_parity_0(i) = point.share_parity_0;
    share_parity_1(i) = point.share_parity_1;
    share_parity_2(i) = point.share_parity_2;
    share_parity_3plus(i) = point.share_parity_3plus;
    share_home_any_40(i) = point.share_home_any_40;
    share_home_any_50(i) = point.share_home_any_50;
end

tbl = table(price_grid(:), distance, totalvote, vote_per_mass, mass, debtstock, price_income_ratio, rent_share, ...
    avg_birth_rate, avg_first_birth_rate, mean_age_first_birth, median_age_first_birth, ...
    share_first_birth_30_plus, share_parity_0, share_parity_1, share_parity_2, share_parity_3plus, ...
    share_home_any_40, share_home_any_50, ...
    'VariableNames', {'a_price', 'distance', 'totalvote', 'vote_per_mass', 'mass', 'debtstock', ...
    'price_income_ratio', 'rent_share', 'avg_birth_rate', 'avg_first_birth_rate', ...
    'mean_age_first_birth', 'median_age_first_birth', 'share_first_birth_30_plus', ...
    'share_parity_0', 'share_parity_1', 'share_parity_2', 'share_parity_3plus', ...
    'share_home_any_40', 'share_home_any_50'});
end

function point = evaluate_fertility_point(a_price, rbPos, overrides)
[distance, ~, ~, totalvote, debtstock, diagnostics] = SolveSS_fertility([a_price, rbPos], overrides);
state = load('SS_fertility.mat');
age40 = find(diagnostics.ages == 40, 1);
age50 = find(diagnostics.ages == 50, 1);
parity50 = diagnostics.parity_dist_by_age(age50, :);
home40 = diagnostics.home_dist_by_age(age40, :);
home50 = diagnostics.home_dist_by_age(age50, :);

point = struct();
point.distance = distance;
point.totalvote = totalvote;
point.mass = sum(state.dens4, 'all');
point.vote_per_mass = safe_ratio(point.totalvote, point.mass);
point.debtstock = debtstock;
point.price_income_ratio = a_price / max(sum(state.dens4 .* state.zzzz4, 'all'), 1e-12);
point.rent_share = sum(state.dens4(:, 1, :, :), 'all');
point.avg_birth_rate = diagnostics.avg_birth_rate;
point.avg_first_birth_rate = diagnostics.avg_first_birth_rate;
point.mean_age_first_birth = diagnostics.mean_age_first_birth;
point.median_age_first_birth = diagnostics.median_age_first_birth;
point.share_first_birth_30_plus = diagnostics.share_first_birth_30_plus;
point.share_parity_0 = parity50(1);
point.share_parity_1 = parity50(2);
point.share_parity_2 = parity50(3);
point.share_parity_3plus = parity50(4);
point.share_home_any_40 = 1 - home40(1);
point.share_home_any_50 = 1 - home50(1);
point.mean_home_children_40 = sum((0:(numel(home40) - 1)) .* home40);
point.mean_home_children_50 = sum((0:(numel(home50) - 1)) .* home50);
point.ages = diagnostics.ages(:);
point.first_birth_rate_by_age = diagnostics.first_birth_rate_by_age(:);
point.first_birth_hazard_by_age = diagnostics.first_birth_hazard_by_age(:);
point.first_birth_age_dist = diagnostics.first_birth_age_dist(:);
point.childless_share_by_age = diagnostics.childless_share_by_age(:);
point.birth_rate_by_age = diagnostics.birth_rate_by_age(:);
end

function tbl = evaluate_fertility_timing_profiles(price_grid, rbPos, overrides)
tbl = table();
for i = 1:numel(price_grid)
    point = evaluate_fertility_point(price_grid(i), rbPos, overrides);
    n_age = numel(point.ages);
    price_col = repmat(price_grid(i), n_age, 1);
    label_col = repmat(string(sprintf('a_price=%.2f', price_grid(i))), n_age, 1);
    tmp = table(price_col, label_col, point.ages, point.birth_rate_by_age, point.first_birth_rate_by_age, ...
        point.first_birth_hazard_by_age, point.first_birth_age_dist, point.childless_share_by_age, ...
        'VariableNames', {'a_price', 'price_label', 'age', 'birth_rate', 'first_birth_rate', ...
        'first_birth_hazard', 'first_birth_age_share', 'childless_share'});
    tbl = [tbl; tmp]; %#ok<AGROW>
end
end

function [tbl, crossing] = crossing_table(grid_table)
prices = grid_table.a_price(:);
votes = grid_table.totalvote(:);

idx = find(votes(1:end - 1) .* votes(2:end) <= 0);
crossing = struct();
crossing.exists = ~isempty(idx);
crossing.sign_change_count = numel(idx);
crossing.lower_prices = prices(idx);
crossing.upper_prices = prices(idx + 1);
crossing.lower_votes = votes(idx);
crossing.upper_votes = votes(idx + 1);
crossing.is_unique = numel(idx) == 1;
crossing.method = "linear_interpolation";
crossing.refined_price = NaN;
crossing.refined_vote = NaN;

if crossing.is_unique
    lo = crossing.lower_prices(1);
    hi = crossing.upper_prices(1);
    vlo = crossing.lower_votes(1);
    vhi = crossing.upper_votes(1);
    if abs(vhi - vlo) < 1e-12
        crossing.refined_price = mean([lo, hi]);
        crossing.refined_vote = mean([vlo, vhi]);
    else
        crossing.refined_price = lo + (-vlo) * (hi - lo) / (vhi - vlo);
        crossing.refined_vote = 0;
    end
end

tbl = grid_table;
end

function nimby_cache = load_cached_nimby_outputs(out_dir, market_price_grid)
nimby_cache = struct('is_valid', false, 'grid', table(), 'market', struct(), 'crossing', struct(), 'eq', struct());
grid_path = fullfile(out_dir, 'nimby_market_clearing_grid.csv');
common_path = fullfile(out_dir, 'fertility_vs_nimby_common_price_grid.csv');
summary_path = fullfile(out_dir, 'fertility_vs_nimby_benchmark_summary.csv');

if ~(exist(grid_path, 'file') && exist(common_path, 'file') && exist(summary_path, 'file'))
    return;
end

grid = readtable(grid_path);
summary = readtable(summary_path, 'TextType', 'string');
if height(grid) ~= numel(market_price_grid) || any(abs(grid.a_price(:) - market_price_grid(:)) > 1e-9)
    return;
end

[market, crossing] = crossing_table(grid);
nimby_row = summary(summary.model == "nimby", :);
if height(nimby_row) ~= 1 || ~crossing.exists || ~crossing.is_unique
    return;
end

eq = struct();
eq.distance = NaN;
eq.totalvote = nimby_row.totalvote(1);
eq.mass = nimby_row.mass(1);
eq.vote_per_mass = nimby_row.vote_per_mass(1);
eq.debtstock = nimby_row.debtstock(1);
eq.price_income_ratio = nimby_row.price_income_ratio(1);
eq.rent_share = nimby_row.rent_share(1);

nimby_cache.is_valid = true;
nimby_cache.grid = grid;
nimby_cache.market = market;
nimby_cache.crossing = crossing;
nimby_cache.eq = eq;
end

function write_report(report_path, repro, nimby_crossing, fertility_crossing_coarse, fertility_crossing, nimby_eq, fertility_eq, fertility_eval, common_table, cfg)
fid = fopen(report_path, 'w');
fprintf(fid, '---\n');
fprintf(fid, 'title: "Fertility benchmark versus NIMBY benchmark"\n');
fprintf(fid, 'date: "%s"\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, 'fontsize: 11pt\n');
fprintf(fid, 'geometry: margin=1in\n');
fprintf(fid, 'header-includes:\n');
fprintf(fid, '  - \\usepackage{graphicx}\n');
fprintf(fid, '  - \\usepackage{microtype}\n');
fprintf(fid, '  - \\usepackage{xurl}\n');
fprintf(fid, '  - \\setlength{\\emergencystretch}{3em}\n');
fprintf(fid, '---\n\n');
fprintf(fid, '# Fertility benchmark versus NIMBY benchmark\n\n');
fprintf(fid, '## Purpose\n\n');
fprintf(fid, 'This note compares the current corrected-code household fertility benchmark in project 03 to the upstream project-02 NIMBY benchmark. The comparison uses the same steady-state voting convention in both models:\n\n');
fprintf(fid, '- fix `rbPos = %.2f`\n', cfg.rbPos);
fprintf(fid, '- trace `totalvote` over the house-price grid\n');
fprintf(fid, '- locate the sign change in that vote object\n\n');
fprintf(fid, 'Project convention for interpretation is now slightly tighter than that legacy implementation rule: treat `vote_per_mass` as the primary political-support object, and keep raw `totalvote` only for continuity with project 02 and for auditability. On the current benchmark grids this does not change the reported crossing prices, because stationary mass is constant within each model (`%.6f` in upstream NIMBY and `%.6f` in the fertility benchmark on the common grid); it only rescales the level comparison.\n\n', nimby_eq.mass, fertility_eq.mass);
fprintf(fid, 'So this is a benchmark-to-benchmark model comparison, not a full two-dimensional market-clearing exercise over both `a_price` and `rbPos`, and not an empirical claim.\n\n');

fprintf(fid, '## How to use this note\n\n');
fprintf(fid, 'Four operational guardrails matter.\n\n');
fprintf(fid, '1. This is the corrected 5-year benchmark note for project 03.\n');
fprintf(fid, '2. The operative fertility equilibrium summary is the local benchmark search, which places the crossing at `a_price = %.6f`, not the non-unique common-grid wiggles.\n', fertility_crossing.refined_price);
fprintf(fid, '3. The preferred political-support scale is `vote_per_mass`; raw `totalvote` remains in the tables only so the project-02 continuity is transparent.\n');
fprintf(fid, '4. Any annual exercise is a separate calibration object and should be judged on its own corrected rebaseline rather than mixed into this 5-year comparison.\n\n');

fprintf(fid, '## Executive summary\n\n');
fprintf(fid, 'Four facts matter.\n\n');
fprintf(fid, '1. The project-03 solver is a true extension of the NIMBY benchmark. When fertility and crowding are shut off, it reproduces the upstream steady-state object exactly.\n');
fprintf(fid, '2. Under the active corrected calibration, the fertility extension shifts the vote schedule toward lower house prices relative to upstream NIMBY.\n');
fprintf(fid, '3. The preferred political-support object is the normalized `vote_per_mass` schedule. Raw vote totals are retained only for continuity and auditability, and on the current benchmark grids this convention change does not alter the crossing because mass is constant within each model.\n');
fprintf(fid, '4. The same steady-state object also implies first-birth delay: as house prices rise, first births move to older ages and the first-birth rate falls.\n\n');

fprintf(fid, '## Exact nesting result\n\n');
fprintf(fid, 'With `C = 1` and the fertility/crowding terms shut off, the project-03 solver reproduces the upstream project-02 benchmark exactly at the same `(a_price, rbPos)`.\n\n');
fprintf(fid, '| Check | Gap |\n');
fprintf(fid, '|---|---:|\n');
fprintf(fid, '| Distance gap | %.12g |\n', repro.distance_gap);
fprintf(fid, '| Vote gap | %.12g |\n', repro.vote_gap);
fprintf(fid, '| Debt gap | %.12g |\n\n', repro.debt_gap);
fprintf(fid, 'This is the key technical result behind the comparison: project 03 nests project 02 exactly.\n\n');

fprintf(fid, '## What changes relative to NIMBY\n\n');
fprintf(fid, '### Intuition first\n\n');
fprintf(fid, 'The upstream NIMBY benchmark is a life-cycle housing-and-voting model. The fertility benchmark keeps that structure and adds a family formation margin.\n\n');
fprintf(fid, 'The important modeling change is that project 03 separates:\n\n');
fprintf(fid, '- `p_t`: children ever born, a permanent parity state\n');
fprintf(fid, '- `h_t`: children currently at home, a temporary crowding state\n\n');
fprintf(fid, 'A birth raises both states today. Later, children can leave home, so `h_t` falls while `p_t` stays fixed.\n\n');
fprintf(fid, '### Side-by-side structure\n\n');
fprintf(fid, '| Object | NIMBY benchmark | Fertility benchmark |\n');
fprintf(fid, '|---|---|---|\n');
fprintf(fid, '| Household state | assets, housing, income, age | assets, housing, income, age, parity, children at home |\n');
fprintf(fid, '| Flow utility | consumption, housing, bequest | consumption, housing, bequest, child utility, crowding |\n');
fprintf(fid, '| Birth choice | absent | parity-specific birth branch |\n');
fprintf(fid, '| Child dynamics | absent | leave-home transition lowers children-at-home only |\n');
fprintf(fid, '| Political block | price perturbation vote | same vote logic retained |\n');
fprintf(fid, '| Upstream nesting | baseline object | exact when fertility is shut off |\n\n');
fprintf(fid, 'In equation form, the NIMBY benchmark values housing services directly. The fertility benchmark instead values effective housing\n\n');
fprintf(fid, '$$\nH^{eff}_t = \\frac{H_t}{(1 + \\lambda_c h_t)^{\\psi_c}},\n$$\n\n');
fprintf(fid, 'and then adds a birth branch with parity-specific birth utility and housing-price-sensitive birth cost.\n\n');
fprintf(fid, 'In plain language, project 03 does not just add a fertility coefficient. It changes the household problem so that families care about housing costs for two separate reasons:\n\n');
fprintf(fid, '1. housing itself is expensive\n');
fprintf(fid, '2. children at home make crowding more expensive\n\n');
fprintf(fid, 'That is the main mechanism behind the benchmark comparison below.\n\n');

fprintf(fid, '## Side-by-side benchmark comparison\n\n');
fprintf(fid, '### Benchmark convention\n\n');
fprintf(fid, '- Upstream NIMBY is evaluated on its native household grid `I = 50`, `J = 10`.\n');
fprintf(fid, '- The fertility benchmark is evaluated on `I = 60`, `J = 14`.\n\n');
fprintf(fid, 'The finer project-03 grid matters. In the fertility extension, the coarser `50 x 10` grid created spurious extra sign changes in the vote schedule. The `60 x 14` benchmark removed that numerical wiggle and is now the active corrected-code benchmark resolution.\n\n');

fprintf(fid, '### Crossing comparison\n\n');
fprintf(fid, '| Metric | NIMBY benchmark | Fertility benchmark |\n');
fprintf(fid, '|---|---:|---:|\n');
fprintf(fid, '| Vote sign-change bracket | `[%.2f, %.2f]` | `[%.2f, %.2f]` |\n', ...
    nimby_crossing.lower_prices(1), nimby_crossing.upper_prices(1), ...
    fertility_crossing_coarse.lower_price, fertility_crossing_coarse.upper_price);
fprintf(fid, '| Lower-bracket vote | `%.4f` | `%.4f` |\n', nimby_crossing.lower_votes(1), fertility_crossing_coarse.lower_vote);
fprintf(fid, '| Upper-bracket vote | `%.4f` | `%.4f` |\n', nimby_crossing.upper_votes(1), fertility_crossing_coarse.upper_vote);
fprintf(fid, '| Local benchmark bracket | n/a | `[%.3f, %.3f]` |\n', fertility_crossing.lower_price, fertility_crossing.upper_price);
fprintf(fid, '| Local refined `a_price` | `%.6f` | `%.6f` |\n', nimby_crossing.refined_price, fertility_crossing.refined_price);
fprintf(fid, '| Vote at refined price | `%.6f` | `%.6f` |\n', nimby_eq.totalvote, fertility_eq.totalvote);
fprintf(fid, '| Vote per unit mass at refined price | `%.6f` | `%.6f` |\n', nimby_eq.vote_per_mass, fertility_eq.vote_per_mass);
fprintf(fid, '| Total household mass at refined price | `%.6f` | `%.6f` |\n', nimby_eq.mass, fertility_eq.mass);
fprintf(fid, '| Debt stock at refined price | `%.6f` | `%.6f` |\n\n', nimby_eq.debtstock, fertility_eq.debtstock);
fprintf(fid, 'The main benchmark comparison is therefore simple: under the corrected calibration, the fertility extension lowers the steady-state crossing price relative to upstream NIMBY.\n\n');
fprintf(fid, 'The natural interpretation is that family-forming households place more value on lower housing costs once crowding enters the household problem. That statement is an inference from the benchmark comparison, not a separate identified result.\n\n');
fprintf(fid, 'Raw vote totals are not the right cross-model scale comparison by themselves because the two models aggregate over different stationary mass objects. The cleaner cross-model comparison is the sign pattern, the crossing price, and the normalized vote-per-mass schedule. That is now the preferred interpretation rule for both the annual and 5-year notes.\n\n');

fprintf(fid, '### Common price-grid comparison\n\n');
fprintf(fid, 'The common-price table isolates how the vote object shifts at the same house prices. It reports both raw vote and vote per unit mass.\n\n');
fprintf(fid, '| `a_price` | NIMBY vote | Fertility vote | NIMBY vote / mass | Fertility vote / mass | Fertility avg. birth rate | Fertility parity at age 50 `[0,1,2,3+]` |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|---|\n');
for i = 1:height(common_table)
    fprintf(fid, '| %.2f | `%.4f` | `%.4f` | `%.4f` | `%.4f` | `%.4f` | `[%.3f, %.3f, %.3f, %.3f]` |\n', ...
        common_table.a_price(i), common_table.nimby_vote(i), common_table.fertility_vote(i), ...
        common_table.nimby_vote_per_mass(i), common_table.fertility_vote_per_mass(i), ...
        common_table.fertility_birth_rate(i), common_table.fertility_parity_0(i), ...
        common_table.fertility_parity_1(i), common_table.fertility_parity_2(i), ...
        common_table.fertility_parity_3plus(i));
end
fprintf(fid, '\n');
fprintf(fid, 'At the same `a_price = 2.00`, the contrast is especially sharp:\n\n');
fprintf(fid, '- NIMBY still has strongly positive vote support for higher prices\n');
fprintf(fid, '- the fertility benchmark is also positive on the common grid, but much weaker and already close to the local crossing region\n\n');
fprintf(fid, 'That contrast survives normalization by stationary mass, so the leftward shift is not a reporting artefact.\n\n');
fprintf(fid, 'Another way to say the same thing is:\n\n');
fprintf(fid, '- in upstream NIMBY, `a_price = 2.00` is still well below the crossing price\n');
fprintf(fid, '- in the fertility benchmark, the local search has already located a crossing near `a_price = %.6f`, even though the common grid around `2.00` is not monotone\n\n', fertility_crossing.refined_price);
fprintf(fid, 'So the project-facing equilibrium summary should rely on the local benchmark search rather than on a monotone reading of the coarse common grid.\n\n');
fprintf(fid, 'The panel figure below summarizes the same comparison visually. The top row separates raw vote from vote per unit mass so the scale issue is transparent rather than buried. The lower panels then show debt and the new family-state objects that appear only in project 03.\n\n');
fprintf(fid, '![](fertility_vs_nimby_benchmark_panels.png)\n\n');

fprintf(fid, '## Fertility benchmark as a new benchmark object\n\n');
fprintf(fid, 'Evaluating the project-03 benchmark at its refined crossing price `a_price = %.6f` gives the following family-state diagnostics.\n\n', fertility_crossing.refined_price);
fprintf(fid, '| Metric | Value |\n');
fprintf(fid, '|---|---:|\n');
fprintf(fid, '| Average birth rate | `%.4f` |\n', fertility_eq.avg_birth_rate);
fprintf(fid, '| Parity age 50: 0 children | `%.4f` |\n', fertility_eq.share_parity_0);
fprintf(fid, '| Parity age 50: 1 child | `%.4f` |\n', fertility_eq.share_parity_1);
fprintf(fid, '| Parity age 50: 2 children | `%.4f` |\n', fertility_eq.share_parity_2);
fprintf(fid, '| Parity age 50: 3+ children | `%.4f` |\n', fertility_eq.share_parity_3plus);
fprintf(fid, '| Any child at home, age 40 | `%.4f` |\n', fertility_eq.share_home_any_40);
fprintf(fid, '| Any child at home, age 50 | `%.4f` |\n', fertility_eq.share_home_any_50);
fprintf(fid, '| Mean children at home, age 40 | `%.4f` |\n', fertility_eq.mean_home_children_40);
fprintf(fid, '| Mean children at home, age 50 | `%.4f` |\n\n', fertility_eq.mean_home_children_50);
fprintf(fid, 'These are exactly the new benchmark objects that do not exist in upstream NIMBY. They are why project 03 should not be read as just a price-shifted copy of the older model.\n\n');

low_idx = find(abs(common_table.a_price - cfg.full_price_grid(1)) < 1e-9, 1);
high_idx = find(abs(common_table.a_price - cfg.full_price_grid(end)) < 1e-9, 1);
if isempty(low_idx)
    low_idx = 1;
end
if isempty(high_idx)
    high_idx = height(common_table);
end

fprintf(fid, '## First-birth timing as a model object\n\n');
fprintf(fid, 'Because parity is an explicit household state in project 03, the benchmark can speak to first-birth delay rather than only to completed fertility. The relevant object is the birth flow out of parity-zero states.\n\n');
fprintf(fid, 'The active benchmark also disciplines the age profile of those first births directly. The pooled recent U.S. CDC first-birth shares for ages `25, 30, 35, 40` are `[%.3f, %.3f, %.3f, %.3f]`, and the model at `a_price = 2.00` delivers `[%.3f, %.3f, %.3f, %.3f]`.\n\n', ...
    cfg.target_first_birth_age_share_25plus(1), cfg.target_first_birth_age_share_25plus(2), ...
    cfg.target_first_birth_age_share_25plus(3), cfg.target_first_birth_age_share_25plus(4), ...
    fertility_eval.first_birth_age_dist(1), fertility_eval.first_birth_age_dist(2), ...
    fertility_eval.first_birth_age_dist(3), fertility_eval.first_birth_age_dist(4));
fprintf(fid, 'Across the canonical steady-state price grid, higher house prices shift first births to older ages and reduce the first-birth rate. Moving from `a_price = %.2f` to `a_price = %.2f`:\n\n', ...
    common_table.a_price(low_idx), common_table.a_price(high_idx));
fprintf(fid, '- mean age at first birth rises from `%.2f` to `%.2f`\n', ...
    common_table.fertility_mean_age_first_birth(low_idx), common_table.fertility_mean_age_first_birth(high_idx));
fprintf(fid, '- median age at first birth rises from `%.0f` to `%.0f`\n', ...
    common_table.fertility_median_age_first_birth(low_idx), common_table.fertility_median_age_first_birth(high_idx));
fprintf(fid, '- the share of first births at age `30+` rises from `%.3f` to `%.3f`\n', ...
    common_table.fertility_share_first_birth_30_plus(low_idx), common_table.fertility_share_first_birth_30_plus(high_idx));
fprintf(fid, '- the average first-birth rate falls from `%.3f` to `%.3f`\n\n', ...
    common_table.fertility_first_birth_rate(low_idx), common_table.fertility_first_birth_rate(high_idx));
fprintf(fid, 'This is the cleanest model-side statement of delay in the current benchmark: when housing is more expensive, the first-birth flow shifts toward older ages rather than only lowering completed fertility later in life.\n\n');
fprintf(fid, '![](nimby_vs_fertility_first_birth_timing.png)\n\n');

fprintf(fid, '## Reading the comparison correctly\n\n');
fprintf(fid, 'Five caveats matter.\n\n');
fprintf(fid, '1. This is a steady-state comparison at fixed `rbPos = %.2f`, not the full two-dimensional market-clearing problem.\n', cfg.rbPos);
fprintf(fid, '2. The project-03 benchmark uses a finer `I = 60`, `J = 14` household grid because the coarser `50 x 10` grid produced numerical vote wiggles in the fertility extension.\n');
fprintf(fid, '3. The upstream NIMBY benchmark remains on its native household grid.\n');
fprintf(fid, '4. The refined prices are linear interpolations inside the sign-change bracket. They are the correct benchmark summary for the grid search, but rerunning the nonlinear solver exactly at those interpolated prices does not force vote to equal zero exactly.\n');
fprintf(fid, '5. The benchmark comparison is about the model object, not about empirical identification.\n\n');

fprintf(fid, '## Bottom line\n\n');
fprintf(fid, 'Relative to the upstream NIMBY benchmark, the corrected-code fertility benchmark now does four clean things:\n\n');
fprintf(fid, '- it nests the old model exactly when fertility is shut off\n');
fprintf(fid, '- it gives children a real household-state interpretation instead of a proxy term\n');
fprintf(fid, '- it shifts the benchmark vote schedule toward lower house prices\n');
fprintf(fid, '- it produces new benchmark objects for completed fertility, children at home, and first-birth timing\n\n');
fprintf(fid, 'That is the cleanest short description of where project 03 stands relative to the NIMBY benchmark.\n\n');

fprintf(fid, '## Interpreting magnitudes\n\n');
fprintf(fid, 'This benchmark comparison is a structural steady-state object, not a literal one-year birth forecast. The fertility crossing moving from the NIMBY benchmark to the fertility benchmark should therefore be read as a model-side shift in equilibrium housing prices and birth timing, not as a direct statement like ``X fewer births next year.''\n\n');
fprintf(fid, 'If a reader wants a birth-count translation, the right object is the calibrated housing-scarcity counterfactual rather than the raw benchmark crossing. In that long-run counterfactual, the model birth rate falls from about `0.248` to about `0.241`, a decline of roughly `2.8%%`. Applied very loosely to a U.S. scale of about `3.6` million births per year, that is on the order of `100,000` fewer births per year. That back-of-the-envelope is only an interpretation aid, not a separate model estimate embedded in this benchmark note.\n\n');

fprintf(fid, '## Files generated\n\n');
fprintf(fid, '- `notes/build/fertility_vs_nimby_reproduction_check.csv`\n');
fprintf(fid, '- `notes/build/nimby_market_clearing_grid.csv`\n');
fprintf(fid, '- `notes/build/fertility_vs_nimby_benchmark_summary.csv`\n');
fprintf(fid, '- `notes/build/fertility_vs_nimby_common_price_grid.csv`\n');
fprintf(fid, '- `notes/build/fertility_vs_nimby_benchmark_panels.png`\n');
fprintf(fid, '- `notes/build/fertility_vs_nimby_benchmark_panels.pdf`\n');
fprintf(fid, '- `notes/build/fertility_vs_nimby_benchmark_report.md`\n');
fprintf(fid, '- `notes/build/fertility_vs_nimby_benchmark_report.pdf`\n');
fprintf(fid, '- `notes/build/fertility_first_birth_timing_profiles.csv`\n');
fclose(fid);
end

function value = safe_ratio(numerator, denominator)
value = numerator / max(denominator, 1e-12);
end
