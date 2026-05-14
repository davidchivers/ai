function compare_fertility_annual_political_timing_main(mode)
% compare_fertility_annual_political_timing_main.m
%
% Compare two annual fertility political-timing conventions:
% 1. fully annualized politics (current annual config)
% 2. a 5-year political-review proxy that keeps annual household choices
%    but holds the 5-year vote shock and housing adjustment cost
%
% This is not a full election-cycle state model. It is a focused
% comparability diagnostic.

if nargin < 1 || isempty(mode)
    mode = 'screen_aligned';
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
settings = build_settings(mode, cfg);
ensure_transition_matrix(settings.base_overrides.transition_matrix_file);

candidate_specs = build_candidate_specs(cfg);
variant_specs = build_variant_specs(cfg);

path_table = table();
summary_rows = repmat(empty_summary_row(), numel(candidate_specs) * numel(variant_specs), 1);
summary_idx = 0;

for ic = 1:numel(candidate_specs)
    candidate = candidate_specs(ic);
    for iv = 1:numel(variant_specs)
        variant = variant_specs(iv);
        overrides = settings.base_overrides;
        overrides.birth_utility_by_parity = candidate.birth_utility_by_parity;
        overrides.child_utility = candidate.child_utility;
        overrides.birth_cost = candidate.birth_cost;
        overrides.birth_price_coeff = candidate.birth_price_coeff;
        overrides.lambda_crowd = candidate.lambda_crowd;
        overrides = apply_variant(overrides, variant, cfg);

        grid_table = evaluate_grid(settings.crossing_price_grid, cfg.rbPos, overrides);
        crossing = summarize_crossing(grid_table.a_price, grid_table.vote_per_mass);
        eval_idx = find(abs(grid_table.a_price - cfg.eval_price) < 1e-12, 1);
        if isempty(eval_idx)
            [~, eval_idx] = min(abs(grid_table.a_price - cfg.eval_price));
        end

        tmp_paths = grid_table;
        tmp_paths.candidate_label = repmat(candidate.label, height(tmp_paths), 1);
        tmp_paths.variant_label = repmat(variant.label, height(tmp_paths), 1);
        path_table = [path_table; movevars(tmp_paths, {'candidate_label', 'variant_label'}, 'Before', 1)]; %#ok<AGROW>

        summary_idx = summary_idx + 1;
        summary_rows(summary_idx) = empty_summary_row();
        summary_rows(summary_idx).candidate_label = candidate.label;
        summary_rows(summary_idx).variant_label = variant.label;
        summary_rows(summary_idx).variant_description = variant.description;
        summary_rows(summary_idx).crossing_exists = double(crossing.exists);
        summary_rows(summary_idx).crossing_is_unique = double(crossing.is_unique);
        summary_rows(summary_idx).sign_change_count = crossing.sign_change_count;
        summary_rows(summary_idx).lower_price = crossing.lower_price;
        summary_rows(summary_idx).upper_price = crossing.upper_price;
        summary_rows(summary_idx).refined_price = crossing.refined_price;
        summary_rows(summary_idx).min_vote_per_mass = min(grid_table.vote_per_mass);
        summary_rows(summary_idx).max_vote_per_mass = max(grid_table.vote_per_mass);
        summary_rows(summary_idx).eval_price = grid_table.a_price(eval_idx);
        summary_rows(summary_idx).eval_vote_per_mass = grid_table.vote_per_mass(eval_idx);
        summary_rows(summary_idx).eval_totalvote = grid_table.totalvote(eval_idx);
        summary_rows(summary_idx).eval_debt_per_mass = grid_table.debt_per_mass(eval_idx);
        summary_rows(summary_idx).eval_mean_age_first_birth = grid_table.mean_age_first_birth(eval_idx);
        summary_rows(summary_idx).eval_share_first_birth_30_plus = grid_table.share_first_birth_30_plus(eval_idx);
        summary_rows(summary_idx).eval_avg_first_birth_rate = grid_table.avg_first_birth_rate(eval_idx);
        summary_rows(summary_idx).eval_childless_share_at_50 = grid_table.childless_share_at_50(eval_idx);
    end
end

summary_table = struct2table(summary_rows);
summary_table = sortrows(summary_table, {'candidate_label', 'variant_label'});
path_table = sortrows(path_table, {'candidate_label', 'variant_label', 'a_price'});

writetable(summary_table, fullfile(out_dir, 'fertility_annual_political_timing_comparison_summary.csv'));
writetable(path_table, fullfile(out_dir, 'fertility_annual_political_timing_comparison_paths.csv'));
write_report(fullfile(out_dir, 'fertility_annual_political_timing_comparison.md'), settings, summary_table, path_table);
save(fullfile(out_dir, 'fertility_annual_political_timing_comparison_results.mat'), ...
    'cfg', 'settings', 'candidate_specs', 'variant_specs', 'summary_table', 'path_table');
end

function settings = build_settings(mode, cfg)
settings = struct();
settings.mode = lower(string(mode));
settings.base_overrides = cfg.overrides;

switch char(settings.mode)
    case 'smoke'
        settings.base_overrides.I = 20;
        settings.base_overrides.J = 6;
        settings.crossing_price_grid = [1.50; 2.00; 2.50];
    case 'screen_aligned'
        settings.base_overrides.I = 32;
        settings.base_overrides.J = 10;
        settings.crossing_price_grid = (1.25:0.25:3.25)';
    otherwise
        error('Unknown mode "%s". Use "smoke" or "screen_aligned".', mode);
end

settings.display_price_grid = [1.50; 2.00; 2.50; 3.00];
settings.eval_price = cfg.eval_price;
end

function specs = build_candidate_specs(cfg)
specs = repmat(struct(), 2, 1);

specs(1).label = "current_annualized_benchmark";
specs(1).birth_utility_by_parity = cfg.overrides.birth_utility_by_parity;
specs(1).child_utility = cfg.overrides.child_utility;
specs(1).birth_cost = cfg.overrides.birth_cost;
specs(1).birth_price_coeff = cfg.overrides.birth_price_coeff;
specs(1).lambda_crowd = cfg.overrides.lambda_crowd;

specs(2).label = "partial_best_fast_screen";
specs(2).birth_utility_by_parity = [1.40, 1.52, 1.45];
specs(2).child_utility = 0.02;
specs(2).birth_cost = 0.05;
specs(2).birth_price_coeff = 0.16;
specs(2).lambda_crowd = 0.04;
end

function variants = build_variant_specs(cfg)
variants = repmat(struct(), 2, 1);

variants(1).label = "fully_annualized_politics";
variants(1).description = "Annual household choices with annualized vote shock and annualized housing adjustment cost.";
variants(1).hold_5y_vote_shock = false;
variants(1).hold_5y_ka = false;

variants(2).label = "five_year_review_proxy";
variants(2).description = "Annual household choices with the 5-year vote shock and 5-year housing adjustment cost held fixed as a comparability proxy.";
variants(2).hold_5y_vote_shock = true;
variants(2).hold_5y_ka = true;
variants(2).d_a_price_five_year = cfg.d_a_price_five_year;
variants(2).ka_five_year = cfg.ka_five_year;
end

function overrides = apply_variant(overrides, variant, cfg)
if variant.hold_5y_vote_shock
    overrides.d_a_price = cfg.d_a_price_five_year;
end
if variant.hold_5y_ka
    overrides.ka = cfg.ka_five_year;
end
end

function grid_table = evaluate_grid(price_grid, rbPos, overrides)
n = numel(price_grid);
a_price = price_grid(:);
distance = NaN(n, 1);
totalvote = NaN(n, 1);
mass = NaN(n, 1);
vote_per_mass = NaN(n, 1);
debtstock = NaN(n, 1);
debt_per_mass = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);
childless_share_at_50 = NaN(n, 1);

for i = 1:n
    [distance(i), ~, ~, totalvote(i), debtstock(i), diagnostics] = SolveSS_fertility([a_price(i), rbPos], overrides);
    mass(i) = sum(diagnostics.age_mass);
    vote_per_mass(i) = totalvote(i) / max(mass(i), 1e-12);
    debt_per_mass(i) = debtstock(i) / max(mass(i), 1e-12);
    avg_first_birth_rate(i) = diagnostics.avg_first_birth_rate;
    mean_age_first_birth(i) = diagnostics.mean_age_first_birth;
    share_first_birth_30_plus(i) = diagnostics.share_first_birth_30_plus;

    age50_idx = find(diagnostics.ages == 50, 1);
    if ~isempty(age50_idx)
        childless_share_at_50(i) = diagnostics.parity_dist_by_age(age50_idx, 1);
    end
end

grid_table = table(a_price, distance, totalvote, mass, vote_per_mass, debtstock, debt_per_mass, ...
    avg_first_birth_rate, mean_age_first_birth, share_first_birth_30_plus, childless_share_at_50);
end

function crossing = summarize_crossing(price_grid, votes)
brackets = find_crossing_brackets(price_grid, votes);
crossing = struct( ...
    'exists', ~isempty(brackets.lower_prices), ...
    'is_unique', numel(brackets.lower_prices) == 1, ...
    'sign_change_count', numel(brackets.lower_prices), ...
    'lower_price', NaN, ...
    'upper_price', NaN, ...
    'lower_vote', NaN, ...
    'upper_vote', NaN, ...
    'refined_price', NaN);

if crossing.sign_change_count == 1
    crossing.lower_price = brackets.lower_prices(1);
    crossing.upper_price = brackets.upper_prices(1);
    crossing.lower_vote = brackets.lower_votes(1);
    crossing.upper_vote = brackets.upper_votes(1);
    crossing.refined_price = interp1([crossing.lower_vote, crossing.upper_vote], ...
        [crossing.lower_price, crossing.upper_price], 0);
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

function row = empty_summary_row()
row = struct( ...
    'candidate_label', "", ...
    'variant_label', "", ...
    'variant_description', "", ...
    'crossing_exists', NaN, ...
    'crossing_is_unique', NaN, ...
    'sign_change_count', NaN, ...
    'lower_price', NaN, ...
    'upper_price', NaN, ...
    'refined_price', NaN, ...
    'min_vote_per_mass', NaN, ...
    'max_vote_per_mass', NaN, ...
    'eval_price', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'eval_totalvote', NaN, ...
    'eval_debt_per_mass', NaN, ...
    'eval_mean_age_first_birth', NaN, ...
    'eval_share_first_birth_30_plus', NaN, ...
    'eval_avg_first_birth_rate', NaN, ...
    'eval_childless_share_at_50', NaN);
end

function ensure_transition_matrix(transition_matrix_file)
if exist(transition_matrix_file, 'file')
    return;
end
build_transition_matrix_annual(transition_matrix_file);
end

function write_report(report_path, settings, summary_table, path_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual fertility political-timing comparison\n\n');
fprintf(fid, 'This note compares two annual political-timing conventions while keeping annual household decisions. It is a comparability diagnostic, not a full election-cycle state model.\n\n');

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- crossing grid: `%s`\n', strjoin(compose('%.2f', settings.crossing_price_grid), ', '));
fprintf(fid, '- eval price: `%.2f`\n\n', settings.eval_price);

fprintf(fid, '## Summary\n\n');
fprintf(fid, '| Candidate | Variant | Crossing | Vote/mass min | Vote/mass max | Vote/mass at q=2.00 | Mean age at q=2.00 | Share 30+ at q=2.00 | Childless @50 at q=2.00 |\n');
fprintf(fid, '|---|---|---|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(summary_table)
    crossing_text = "none";
    if summary_table.crossing_exists(i)
        if summary_table.crossing_is_unique(i)
            crossing_text = string(sprintf('%.3f', summary_table.refined_price(i)));
        else
            crossing_text = string(sprintf('%d sign changes', summary_table.sign_change_count(i)));
        end
    end
    fprintf(fid, '| %s | %s | %s | `%.4f` | `%.4f` | `%.4f` | `%.2f` | `%.3f` | `%.3f` |\n', ...
        char(summary_table.candidate_label(i)), char(summary_table.variant_label(i)), char(crossing_text), ...
        summary_table.min_vote_per_mass(i), summary_table.max_vote_per_mass(i), ...
        summary_table.eval_vote_per_mass(i), summary_table.eval_mean_age_first_birth(i), ...
        summary_table.eval_share_first_birth_30_plus(i), summary_table.eval_childless_share_at_50(i));
end
fprintf(fid, '\n');

fprintf(fid, '## Display-grid paths\n\n');
fprintf(fid, '| Candidate | Variant | House price | Vote/mass | First-birth rate | Mean age | Share 30+ | Childless @50 |\n');
fprintf(fid, '|---|---|---:|---:|---:|---:|---:|---:|\n');
display_mask = ismember(round(path_table.a_price, 8), round(settings.display_price_grid, 8));
display_table = path_table(display_mask, :);
display_table = sortrows(display_table, {'candidate_label', 'variant_label', 'a_price'});
for i = 1:height(display_table)
    fprintf(fid, '| %s | %s | %.2f | `%.4f` | `%.4f` | `%.2f` | `%.3f` | `%.3f` |\n', ...
        char(display_table.candidate_label(i)), char(display_table.variant_label(i)), ...
        display_table.a_price(i), display_table.vote_per_mass(i), ...
        display_table.avg_first_birth_rate(i), display_table.mean_age_first_birth(i), ...
        display_table.share_first_birth_30_plus(i), display_table.childless_share_at_50(i));
end
fprintf(fid, '\n');

fprintf(fid, 'The `five_year_review_proxy` keeps annual household choices but replaces the annualized political price shock with the 5-year shock and holds the 5-year housing adjustment cost fixed. It is only a proxy for slower political review, because the model still has no explicit election-cycle state.\n');
fclose(fid);
end
