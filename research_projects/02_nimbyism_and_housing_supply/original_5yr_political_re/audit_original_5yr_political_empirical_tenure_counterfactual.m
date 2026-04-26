function cf = audit_original_5yr_political_empirical_tenure_counterfactual(audit_mat_path, run_tag)
% Counterfactual vote audit with empirical age-tenure owner shares.
%
% This is not a new equilibrium solve. It keeps the saved value-function
% responses and age masses fixed, then mechanically replaces owner/renter
% shares by empirical homeownership rates to test whether the political
% residual is mainly a tenure-composition artifact.

if nargin < 1 || isempty(audit_mat_path)
    this_dir = fileparts(mfilename('fullpath'));
    audit_mat_path = fullfile(this_dir, 'truth', 'political_vote_audit', ...
        'vote_audit_probe_k10_s020_popweights', ...
        'vote_audit_probe_k10_s020_popweights_results.mat');
end
if nargin < 2 || isempty(run_tag)
    run_tag = 'empirical_tenure_cf_k10_s020_popweights';
end

this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
baseline_dir = fullfile(project_root, 'code', 'steadystate');
extension_dir = fullfile(project_root, 'extensions', 're_no_politics');
addpath(this_dir);
addpath(baseline_dir);
addpath(extension_dir);

loaded = load(audit_mat_path, 'solve_results', 'demographic_path', 'price_path', 'params');
solve_results = loaded.solve_results;
demographic_path = loaded.demographic_path;
price_path = loaded.price_path;
params = loaded.params;

if ~isfield(solve_results, 'current_path_pass') || ~isfield(solve_results.current_path_pass, 'sim')
    error('Audit MAT does not contain solve_results.current_path_pass.sim.');
end

household_seed = solve_household_path_nimby( ...
    price_path(1), struct(), ...
    struct('rbPos_path', params.rbPos, 'return_path_solution', false, 'return_tail_solution', false));
env = household_seed.core_env;

sim = solve_results.current_path_pass.sim;
political = sim.political;
density_by_period_age = sim.density_by_period_age;
target_age_masses = solve_results.target_age_masses;

[period_table, age_table] = build_empirical_tenure_cf_tables_local( ...
    density_by_period_age, political, target_age_masses, demographic_path, env);

safe_tag = char(regexprep(string(run_tag), '[^A-Za-z0-9_]+', '_'));
output_dir = fullfile(this_dir, 'truth', 'political_vote_audit', safe_tag);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

period_csv = fullfile(output_dir, sprintf('%s_by_period.csv', safe_tag));
age_csv = fullfile(output_dir, sprintf('%s_by_period_age.csv', safe_tag));
writetable(period_table, period_csv);
writetable(age_table, age_csv);

mat_path = fullfile(output_dir, sprintf('%s_results.mat', safe_tag));
if isfile(mat_path)
    delete(mat_path);
end
save(mat_path, 'period_table', 'age_table', 'audit_mat_path', '-v7');

cf = struct();
cf.output_dir = output_dir;
cf.period_csv = period_csv;
cf.age_csv = age_csv;
cf.mat_path = mat_path;
cf.actual_max_abs_vote = max(abs(period_table.actual_vote));
cf.empirical_all_max_abs_vote = max(abs(period_table.empirical_all_vote));
cf.empirical_65plus_max_abs_vote = max(abs(period_table.empirical_65plus_vote));
cf.empirical_75plus_max_abs_vote = max(abs(period_table.empirical_75plus_vote));
cf.message = 'Empirical tenure counterfactual vote audit completed.';

fprintf('Empirical tenure counterfactual written to %s\n', output_dir);
fprintf('max_abs_vote: actual=%0.12g, all=%0.12g, 65plus=%0.12g, 75plus=%0.12g\n', ...
    cf.actual_max_abs_vote, cf.empirical_all_max_abs_vote, ...
    cf.empirical_65plus_max_abs_vote, cf.empirical_75plus_max_abs_vote);
end

function [period_table, age_table] = build_empirical_tenure_cf_tables_local(density_by_period_age, political, target_age_masses, demographic_path, env)
T = size(density_by_period_age, 1);
age_n = size(density_by_period_age, 2);
ages = env.ages(:);
periods = demographic_path.periods(:);
if numel(periods) < T
    periods = (1:T)';
end

period_index = (1:T)';
period_year = periods(1:T);
actual_vote = political.equal_weight_vote_path(:);
reconstructed_vote = zeros(T, 1);
empirical_all_vote = zeros(T, 1);
empirical_65plus_vote = zeros(T, 1);
empirical_75plus_vote = zeros(T, 1);
empirical_all_owner_share = zeros(T, 1);
empirical_65plus_owner_share = zeros(T, 1);
empirical_75plus_owner_share = zeros(T, 1);
synthetic_renter_mass_all = zeros(T, 1);
synthetic_renter_mass_65plus = zeros(T, 1);
synthetic_renter_mass_75plus = zeros(T, 1);

age_rows = initialize_age_rows_local();

for t = 1:T
    total_mass = 0;
    all_owner_mass = 0;
    plus65_owner_mass = 0;
    plus75_owner_mass = 0;

    for age_idx = 1:age_n
        age = ages(age_idx);
        density = density_by_period_age{t, age_idx};
        response = political.preference_response_by_period_age{t, age_idx};
        [owner_mask, renter_mask] = owner_masks_local(density, env);

        actual_mass = sum(density, 'all');
        if ~isnumeric(target_age_masses) || size(target_age_masses, 1) < t || size(target_age_masses, 2) < age_idx
            age_mass = actual_mass;
        else
            age_mass = target_age_masses(t, age_idx);
            if ~isfinite(age_mass) || age_mass <= 0
                age_mass = actual_mass;
            end
        end
        total_mass = total_mass + age_mass;

        owner_mass = sum(density(owner_mask), 'all');
        renter_mass = sum(density(renter_mask), 'all');
        current_owner_share = safe_divide_local(owner_mass, actual_mass);
        if ~isfinite(current_owner_share)
            current_owner_share = 0;
        end

        owner_response = conditional_response_local(density, response, owner_mask);
        renter_response = conditional_response_local(density, response, renter_mask);
        if ~isfinite(owner_response)
            owner_response = grid_response_local(response, owner_mask);
        end
        if ~isfinite(renter_response)
            renter_response = grid_response_local(response, renter_mask);
        end

        data_owner_share = empirical_owner_share_by_age_local(age);
        share_all = data_owner_share;
        share_65plus = current_owner_share;
        share_75plus = current_owner_share;
        if age >= 65
            share_65plus = data_owner_share;
        end
        if age >= 75
            share_75plus = data_owner_share;
        end

        reconstructed_age_vote = age_mass .* tenure_vote_local(current_owner_share, owner_response, renter_response);
        all_age_vote = age_mass .* tenure_vote_local(share_all, owner_response, renter_response);
        plus65_age_vote = age_mass .* tenure_vote_local(share_65plus, owner_response, renter_response);
        plus75_age_vote = age_mass .* tenure_vote_local(share_75plus, owner_response, renter_response);

        reconstructed_vote(t) = reconstructed_vote(t) + reconstructed_age_vote;
        empirical_all_vote(t) = empirical_all_vote(t) + all_age_vote;
        empirical_65plus_vote(t) = empirical_65plus_vote(t) + plus65_age_vote;
        empirical_75plus_vote(t) = empirical_75plus_vote(t) + plus75_age_vote;

        all_owner_mass = all_owner_mass + age_mass .* share_all;
        plus65_owner_mass = plus65_owner_mass + age_mass .* share_65plus;
        plus75_owner_mass = plus75_owner_mass + age_mass .* share_75plus;
        synthetic_renter_mass_all(t) = synthetic_renter_mass_all(t) + max(0, age_mass .* ((1 - share_all) - safe_share_local(renter_mass, actual_mass)));
        synthetic_renter_mass_65plus(t) = synthetic_renter_mass_65plus(t) + max(0, age_mass .* ((1 - share_65plus) - safe_share_local(renter_mass, actual_mass)));
        synthetic_renter_mass_75plus(t) = synthetic_renter_mass_75plus(t) + max(0, age_mass .* ((1 - share_75plus) - safe_share_local(renter_mass, actual_mass)));

        age_rows = append_age_row_local(age_rows, t, period_year(t), age, age_mass, ...
            current_owner_share, data_owner_share, owner_response, renter_response, ...
            reconstructed_age_vote, all_age_vote, plus65_age_vote, plus75_age_vote, ...
            owner_mass, renter_mass);
    end

    empirical_all_owner_share(t) = safe_divide_local(all_owner_mass, total_mass);
    empirical_65plus_owner_share(t) = safe_divide_local(plus65_owner_mass, total_mass);
    empirical_75plus_owner_share(t) = safe_divide_local(plus75_owner_mass, total_mass);
end

period_table = table(period_index, period_year, actual_vote, reconstructed_vote, ...
    empirical_all_vote, empirical_65plus_vote, empirical_75plus_vote, ...
    empirical_all_owner_share, empirical_65plus_owner_share, empirical_75plus_owner_share, ...
    synthetic_renter_mass_all, synthetic_renter_mass_65plus, synthetic_renter_mass_75plus);
age_table = struct2table(age_rows);
end

function value = empirical_owner_share_by_age_local(age)
% Census 2017 wealth table, "Percent holding equity in own home";
% age < 35 is replaced by the paper's 25-35 data moment, 0.40.
if age < 35
    value = 0.40;
elseif age < 45
    value = 0.574;
elseif age < 55
    value = 0.661;
elseif age < 65
    value = 0.726;
elseif age < 70
    value = 0.760;
elseif age < 75
    value = 0.795;
else
    value = 0.751;
end
end

function vote = tenure_vote_local(owner_share, owner_response, renter_response)
owner_share = min(1, max(0, owner_share));
vote = owner_share .* owner_response + (1 - owner_share) .* renter_response;
end

function value = conditional_response_local(density, response, mask)
local_density = density(mask);
local_response = response(mask);
mass = sum(local_density, 'all');
if mass <= 1e-14
    value = NaN;
else
    value = sum(local_density .* local_response, 'all') ./ mass;
end
end

function value = grid_response_local(response, mask)
values = response(mask);
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = mean(values, 'all');
end
end

function [owner_mask, renter_mask] = owner_masks_local(density, env)
owner_grid = env.aa > 1e-8;
if ~isequal(size(owner_grid), size(density))
    reps = ones(1, ndims(density));
    for dim = 1:ndims(density)
        if dim <= ndims(owner_grid)
            reps(dim) = size(density, dim) ./ size(owner_grid, dim);
        else
            reps(dim) = size(density, dim);
        end
    end
    owner_grid = repmat(owner_grid, reps);
end
owner_mask = logical(owner_grid);
renter_mask = ~owner_mask;
end

function rows = initialize_age_rows_local()
rows = struct();
rows.period_index = [];
rows.period_year = [];
rows.age = [];
rows.age_mass = [];
rows.current_owner_share = [];
rows.empirical_owner_share = [];
rows.owner_response = [];
rows.renter_response = [];
rows.reconstructed_vote = [];
rows.empirical_all_vote = [];
rows.empirical_65plus_vote = [];
rows.empirical_75plus_vote = [];
rows.actual_owner_mass = [];
rows.actual_renter_mass = [];
end

function rows = append_age_row_local(rows, period_index, period_year, age, age_mass, current_owner_share, empirical_owner_share, owner_response, renter_response, reconstructed_vote, empirical_all_vote, empirical_65plus_vote, empirical_75plus_vote, actual_owner_mass, actual_renter_mass)
rows.period_index(end + 1, 1) = period_index;
rows.period_year(end + 1, 1) = period_year;
rows.age(end + 1, 1) = age;
rows.age_mass(end + 1, 1) = age_mass;
rows.current_owner_share(end + 1, 1) = current_owner_share;
rows.empirical_owner_share(end + 1, 1) = empirical_owner_share;
rows.owner_response(end + 1, 1) = owner_response;
rows.renter_response(end + 1, 1) = renter_response;
rows.reconstructed_vote(end + 1, 1) = reconstructed_vote;
rows.empirical_all_vote(end + 1, 1) = empirical_all_vote;
rows.empirical_65plus_vote(end + 1, 1) = empirical_65plus_vote;
rows.empirical_75plus_vote(end + 1, 1) = empirical_75plus_vote;
rows.actual_owner_mass(end + 1, 1) = actual_owner_mass;
rows.actual_renter_mass(end + 1, 1) = actual_renter_mass;
end

function value = safe_divide_local(num, den)
if isempty(den) || abs(den) <= 1e-14
    value = NaN;
else
    value = num ./ den;
end
end

function value = safe_share_local(num, den)
value = safe_divide_local(num, den);
if ~isfinite(value)
    value = 0;
end
end
