function run_nimby_annual_recalibration_stage2(mode)
% run_nimby_annual_recalibration_stage2.m -- Second-stage annual NIMBY
% screen built around the best stage-1 annual candidate.
%
% This stage only varies the knobs that moved the annual vote object in
% quick sensitivity checks:
%   1. cohort weighting profile
%   2. annual asset/housing bounds
%   3. discount-block anchor
%
% Usage:
%   run_nimby_annual_recalibration_stage2          % fast stage-2 screen
%   run_nimby_annual_recalibration_stage2('full')  % fuller price grids
%
% Outputs:
%   notes/build/nimby_annual_recalibration_stage2_candidates.csv
%   notes/build/nimby_annual_recalibration_stage2_candidate_paths.csv
%   notes/build/nimby_annual_recalibration_stage2_target_grid.csv
%   notes/build/nimby_annual_recalibration_stage2.md

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

candidate_specs = build_candidate_specs(settings);
nc = numel(candidate_specs);
candidate_rows = repmat(empty_candidate_row(), nc, 1);
path_table = table();

for i = 1:nc
    spec = candidate_specs(i);
    fprintf('\n=== annual stage-2 candidate %d: %s ===\n', spec.candidate_id, spec.label);
    ov = build_annual_candidate_overrides(settings, spec);
    grid = evaluate_grid(settings.compare_price_grid, settings.rbPos_annual, ov);
    [~, crossing] = ClearMarkets_fertility(settings.crossing_price_grid, settings.rbPos_annual, ov);
    eval_point = evaluate_point(settings.eval_price, settings.rbPos_annual, ov);

    candidate_rows(i) = score_candidate(spec, grid, crossing, eval_point, target_grid, target_crossing, target_eval);

    tmp = table( ...
        repmat(spec.candidate_id, height(grid), 1), ...
        repmat(string(spec.label), height(grid), 1), ...
        repmat(string(spec.cohort_code), height(grid), 1), ...
        repmat(string(spec.bounds_code), height(grid), 1), ...
        repmat(string(spec.discount_code), height(grid), 1), ...
        grid.a_price, ...
        grid.vote_per_mass, ...
        grid.debt_per_mass, ...
        grid.mass, ...
        'VariableNames', {'candidate_id', 'label', 'cohort_code', 'bounds_code', 'discount_code', ...
        'a_price', 'vote_per_mass', 'debt_per_mass', 'mass'});
    path_table = [path_table; tmp]; %#ok<AGROW>
end

candidates_table = struct2table(candidate_rows);
candidates_table = sortrows(candidates_table, {'score', 'vote_rmse', 'crossing_gap'}, {'ascend', 'ascend', 'ascend'});

writetable(target_grid(:, {'a_price', 'vote_per_mass', 'debt_per_mass', 'mass'}), ...
    fullfile(out_dir, 'nimby_annual_recalibration_stage2_target_grid.csv'));
writetable(candidates_table, fullfile(out_dir, 'nimby_annual_recalibration_stage2_candidates.csv'));
writetable(path_table, fullfile(out_dir, 'nimby_annual_recalibration_stage2_candidate_paths.csv'));
write_report(fullfile(out_dir, 'nimby_annual_recalibration_stage2.md'), ...
    settings, target_grid, target_crossing, target_eval, candidates_table);
end

function settings = build_settings(mode, project_root)
cfg = fertility_benchmark_config();
settings = struct();
settings.mode = lower(string(mode));
settings.agemin = 25;
settings.agemax = 80;
settings.eval_price = cfg.eval_price;
settings.beta_five_year = 0.98;
settings.bequestweight_five_year = 0.98;
settings.rbPos_five_year = cfg.rbPos;
settings.rb_spread_five_year = 0.02;
settings.ra_five_year = -0.03;
settings.rent_markup_five_year = 0.02;
settings.ka_five_year = 0.06;
settings.d_a_price_five_year = 1.01;
settings.annual_transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_annual.mat');

settings.beta_annual = annualize_discount(settings.beta_five_year, 5);
settings.bequestweight_annual = annualize_discount(settings.bequestweight_five_year, 5);
settings.rbPos_annual = annualize_net_rate(settings.rbPos_five_year, 5);
settings.rspread_annual = annualize_spread(settings.rbPos_five_year, settings.rb_spread_five_year, 5);
settings.ra_annual = annualize_net_rate(settings.ra_five_year, 5);
settings.rent_markup_annual = annualize_net_rate(settings.rent_markup_five_year, 5);

settings.beta_legacy_annual = 0.80;
settings.bequestweight_legacy_annual = 0.72;

base_overrides = build_nimby_shutoff_overrides(cfg.overrides);
switch char(settings.mode)
    case 'full'
        solver_I = cfg.overrides.I;
        solver_J = cfg.overrides.J;
        settings.compare_price_grid = [1.25, 1.50, 1.75, 2.00, 2.25, 2.50, 2.75];
        settings.crossing_price_grid = 0.75:0.125:3.00;
    case 'fast'
        solver_I = cfg.stage1_solver_overrides.I;
        solver_J = cfg.stage1_solver_overrides.J;
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
settings.five_year_overrides.ka = settings.ka_five_year;
settings.five_year_overrides.bequestweight = settings.bequestweight_five_year;
settings.five_year_overrides.d_a_price = settings.d_a_price_five_year;
settings.five_year_overrides.cohort_weights_by_age = expand_cohort_profile(settings.agemin:5:settings.agemax);
settings.five_year_overrides.transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_5y_25_80.mat');
end

function specs = build_candidate_specs(settings)
cohort_specs = [ ...
    struct('code', "expanded_5y", 'label', "expanded 5y cohorts"), ...
    struct('code', "uniform", 'label', "uniform cohorts")];
bounds_specs = [ ...
    struct('code', "benchmark_bounds", 'label', "benchmark annual bounds"), ...
    struct('code', "legacy_annual_bounds", 'label', "legacy annual bounds")];
discount_specs = [ ...
    struct('code', "annualized_5y", 'label', "annualized 5y discount block", ...
        'beta', settings.beta_annual, 'bequestweight', settings.bequestweight_annual), ...
    struct('code', "legacy_annual", 'label', "legacy annual discount block", ...
        'beta', settings.beta_legacy_annual, 'bequestweight', settings.bequestweight_legacy_annual)];

specs = repmat(struct(), numel(cohort_specs) * numel(bounds_specs) * numel(discount_specs), 1);
idx = 0;
for ic = 1:numel(cohort_specs)
    for ib = 1:numel(bounds_specs)
        for id = 1:numel(discount_specs)
            idx = idx + 1;
            specs(idx).candidate_id = idx;
            specs(idx).cohort_code = cohort_specs(ic).code;
            specs(idx).cohort_label = cohort_specs(ic).label;
            specs(idx).bounds_code = bounds_specs(ib).code;
            specs(idx).bounds_label = bounds_specs(ib).label;
            specs(idx).discount_code = discount_specs(id).code;
            specs(idx).discount_label = discount_specs(id).label;
            specs(idx).beta_value = discount_specs(id).beta;
            specs(idx).bequestweight_value = discount_specs(id).bequestweight;
            specs(idx).label = sprintf('%s + %s + %s', ...
                cohort_specs(ic).label, bounds_specs(ib).label, discount_specs(id).label);
        end
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
ov.transition_matrix_file = settings.annual_transition_matrix_file;
ov.beta = spec.beta_value;
ov.ra = settings.ra_annual;
ov.rspread = settings.rspread_annual;
ov.rent_markup = settings.rent_markup_annual;
ov.ka = settings.ka_five_year;
ov.bequestweight = spec.bequestweight_value;
ov.d_a_price = settings.d_a_price_five_year;

switch char(spec.cohort_code)
    case 'expanded_5y'
        ov.cohort_weights_by_age = expand_cohort_profile(settings.agemin:1:settings.agemax);
    case 'uniform'
        ov.cohort_weights_by_age = ones(1, numel(settings.agemin:1:settings.agemax));
    otherwise
        error('Unknown cohort code "%s".', spec.cohort_code);
end

switch char(spec.bounds_code)
    case 'benchmark_bounds'
        % Keep benchmark fertility-solver bounds.
    case 'legacy_annual_bounds'
        ov.bmin = -10;
        ov.bmax = 12;
        ov.housingmax = 14;
    otherwise
        error('Unknown bounds code "%s".', spec.bounds_code);
end
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
end

function row = score_candidate(spec, grid, crossing, eval_point, target_grid, target_crossing, target_eval)
target_vote = target_grid.vote_per_mass;
target_debt = target_grid.debt_per_mass;
candidate_vote = grid.vote_per_mass;
candidate_debt = grid.debt_per_mass;

vote_rmse = sqrt(mean((candidate_vote - target_vote).^2));
debt_rmse = sqrt(mean((candidate_debt - target_debt).^2));
eval_vote_gap = eval_point.vote_per_mass - target_eval.vote_per_mass;
eval_debt_gap = eval_point.debt_per_mass - target_eval.debt_per_mass;

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
score = vote_rmse + 0.25 * debt_rmse + crossing_penalty + no_cross_penalty;

row = empty_candidate_row();
row.candidate_id = spec.candidate_id;
row.label = string(spec.label);
row.cohort_code = string(spec.cohort_code);
row.bounds_code = string(spec.bounds_code);
row.discount_code = string(spec.discount_code);
row.beta_value = spec.beta_value;
row.bequestweight_value = spec.bequestweight_value;
row.vote_rmse = vote_rmse;
row.debt_rmse = debt_rmse;
row.eval_vote_per_mass = eval_point.vote_per_mass;
row.eval_debt_per_mass = eval_point.debt_per_mass;
row.eval_vote_gap = eval_vote_gap;
row.eval_debt_gap = eval_debt_gap;
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
    'cohort_code', "", ...
    'bounds_code', "", ...
    'discount_code', "", ...
    'beta_value', NaN, ...
    'bequestweight_value', NaN, ...
    'vote_rmse', NaN, ...
    'debt_rmse', NaN, ...
    'eval_vote_per_mass', NaN, ...
    'eval_debt_per_mass', NaN, ...
    'eval_vote_gap', NaN, ...
    'eval_debt_gap', NaN, ...
    'crossing_exists', NaN, ...
    'crossing_is_unique', NaN, ...
    'crossing_sign_changes', NaN, ...
    'crossing_refined_price', NaN, ...
    'crossing_gap', NaN, ...
    'score', NaN);
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

function write_report(report_path, settings, target_grid, target_crossing, target_eval, candidates_table)
fid = fopen(report_path, 'w');
fprintf(fid, '# Annual NIMBY recalibration screen: stage 2\n\n');
fprintf(fid, 'This workflow extends the stage-1 annual NIMBY screen by holding the best stage-1 price-side choices fixed (`ka = 0.06`, `d\\_a\\_price = 1.01`) and varying only the candidate blocks that moved the annual vote object in quick sensitivity checks.\n\n');

fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- mode: `%s`\n', char(settings.mode));
fprintf(fid, '- local target age range: `%d-%d`\n', settings.agemin, settings.agemax);
fprintf(fid, '- solver grids: `I = %d`, `J = %d`\n', settings.solver_I, settings.solver_J);
fprintf(fid, '- fixed annual price-side block: annualized `ra`, `rspread`, `rent_markup`; hold-5y `ka`; hold-5y vote shock\n');
fprintf(fid, '- stage-2 candidate axes: cohort weights, annual bounds, discount block\n');
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

fprintf(fid, '## Candidate ranking\n\n');
fprintf(fid, 'Score is heuristic: vote RMSE + 0.25 * debt RMSE + crossing penalties. Lower is better.\n\n');
fprintf(fid, '| Rank | Candidate | Cohorts | Bounds | Discount block | Eval vote/mass | Eval debt/mass | Vote RMSE | Debt RMSE | Crossing | Score |\n');
fprintf(fid, '|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(candidates_table)
    crossing_text = "none";
    if candidates_table.crossing_exists(i) == 1 && candidates_table.crossing_is_unique(i) == 1 && ~isnan(candidates_table.crossing_refined_price(i))
        crossing_text = string(sprintf('%.4f', candidates_table.crossing_refined_price(i)));
    end
    fprintf(fid, '| %d | %s | `%s` | `%s` | `%s` | `%.6f` | `%.6f` | `%.6f` | `%.6f` | %s | `%.6f` |\n', ...
        i, char(candidates_table.label(i)), char(candidates_table.cohort_code(i)), ...
        char(candidates_table.bounds_code(i)), char(candidates_table.discount_code(i)), ...
        candidates_table.eval_vote_per_mass(i), candidates_table.eval_debt_per_mass(i), ...
        candidates_table.vote_rmse(i), candidates_table.debt_rmse(i), char(crossing_text), ...
        candidates_table.score(i));
end
fprintf(fid, '\n');
fclose(fid);
end
