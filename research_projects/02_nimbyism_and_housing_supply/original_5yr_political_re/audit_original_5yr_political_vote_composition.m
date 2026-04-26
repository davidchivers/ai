function audit = audit_original_5yr_political_vote_composition(k, price_csv_path, wedge_csv_path, run_tag, demographic_source_mode, political_response_sigma)
% Audit which cohorts and owner groups drive the transition political residual.

if nargin < 1 || isempty(k)
    k = 10;
end
if nargin < 4 || isempty(run_tag)
    run_tag = sprintf('vote_audit_k%02d', k);
end
if nargin < 5 || isempty(demographic_source_mode)
    demographic_source_mode = 'entrant_survival_flat';
end
if nargin < 6 || isempty(political_response_sigma)
    political_response_sigma = 0.20;
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(this_dir);
extension_dir = fullfile(project_root, 'extensions', 're_no_politics');
baseline_dir = fullfile(project_root, 'code', 'steadystate');
addpath(this_dir);
addpath(extension_dir);
addpath(baseline_dir);

if nargin < 2 || isempty(price_csv_path)
    price_csv_path = fullfile(this_dir, 'truth', 'joint_supply_wedge', ...
        'local_entsurv_smooth_probe_s020_flat_k4_14', 'k10', ...
        'local_entsurv_smooth_probe_s020_flat_k4_14_k10_final_price_path.csv');
end
if nargin < 3 || isempty(wedge_csv_path)
    wedge_csv_path = fullfile(this_dir, 'truth', 'joint_supply_wedge', ...
        'local_entsurv_smooth_probe_s020_flat_k4_14', 'k10', ...
        'local_entsurv_smooth_probe_s020_flat_k4_14_k10_final_wedge_path.csv');
end

price_path = fit_path_to_horizon_local(readmatrix(price_csv_path), k, NaN);
wedge_path = fit_path_to_horizon_local(readmatrix(wedge_csv_path), k, 0.0);
if any(~isfinite(price_path)) || any(price_path <= 0)
    error('Price path must contain finite positive entries.');
end
if any(~isfinite(wedge_path))
    error('Wedge path must contain finite entries.');
end

demographic_path_full = build_demographic_path_local(project_root, demographic_source_mode);
demographic_path = truncate_demographic_path_local(demographic_path_full, k);

output_dir = fullfile(this_dir, 'truth', 'political_vote_audit', char(regexprep(string(run_tag), '[^A-Za-z0-9_]+', '_')));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

params = default_audit_params_local();
params.max_iter = 1;
params.compute_political_path = true;
params.save_period_details = true;
params.save_political_details = true;
params.save_current_path_pass = true;
params.supply_wedge_path = wedge_path(:);
params.supply_wedge_space = 'log';
params.political_response_mode = 'smooth_tanh';
params.political_response_sigma = political_response_sigma;
params.trace_log_path = fullfile(output_dir, sprintf('%s_trace.log', char(run_tag)));
params.trace_label = sprintf('%s_inner', char(run_tag));

solve_results = solve_transition_re_no_politics(price_path(:), demographic_path, params);
if ~isfield(solve_results, 'current_path_pass') || ~isfield(solve_results.current_path_pass, 'sim')
    error('Detailed current-path pass was not saved.');
end

household_seed = solve_household_path_nimby( ...
    price_path(1), struct(), ...
    struct('rbPos_path', params.rbPos, 'return_path_solution', false, 'return_tail_solution', false));
env = household_seed.core_env;
sim = solve_results.current_path_pass.sim;
political = sim.political;

[period_table, age_table, group_table] = build_vote_audit_tables_local( ...
    sim.density_by_period_age, political, solve_results.target_age_masses, ...
    demographic_path, env);

period_csv = fullfile(output_dir, sprintf('%s_by_period.csv', char(run_tag)));
age_csv = fullfile(output_dir, sprintf('%s_by_period_age.csv', char(run_tag)));
group_csv = fullfile(output_dir, sprintf('%s_by_period_group.csv', char(run_tag)));
writetable(period_table, period_csv);
writetable(age_table, age_csv);
writetable(group_table, group_csv);

mat_path = fullfile(output_dir, sprintf('%s_results.mat', char(run_tag)));
if isfile(mat_path)
    delete(mat_path);
end
save(mat_path, 'solve_results', 'period_table', 'age_table', 'group_table', ...
    'price_path', 'wedge_path', 'demographic_path', 'params', '-v7');

audit = struct();
audit.output_dir = output_dir;
audit.period_csv = period_csv;
audit.age_csv = age_csv;
audit.group_csv = group_csv;
audit.mat_path = mat_path;
audit.max_abs_vote = max(abs(period_table.equal_weight_vote));
audit.max_vote_period = period_table.period_index(find(abs(period_table.equal_weight_vote) == audit.max_abs_vote, 1, 'first'));
audit.message = 'Political vote composition audit completed.';

fprintf('Political vote audit written to %s\n', output_dir);
fprintf('max_abs_vote=%0.12g at period %d\n', audit.max_abs_vote, audit.max_vote_period);
end

function params = default_audit_params_local()
params = struct();
params.max_iter = 1;
params.tol = 1e-4;
params.damping = 0.25;
params.max_update_frac = 0.10;
params.smoothing_weight = 5.00;
params.terminal_anchor_weight = 0.50;
params.targeted_correction_weight = 0.35;
params.max_targeted_periods = 0;
params.target_block_half_width = 1;
params.line_search_scales = [];
params.update_scheme = 'audit_current_path';
params.transition_policy_mode = 'full_backward';
params.terminal_price_rule = 'flat_tail';
params.terminal_reference_mode = 'path_end_price';
params.rbPos = 0.03;
params.compute_political_path = true;
params.save_political_details = true;
params.save_period_details = true;
params.save_current_path_pass = true;
params.fixed_point_price_min = 0.05;
params.fixed_point_price_max = 5.00;
params.steady_state_reference_mode = 'original_5yr_political';
params.candidate_improvement_tol = 1e9;
params.candidate_gap_improvement_tol = 1e9;
params.candidate_residual_slack = -1e9;
params.coalition_params = struct( ...
    'alpha_owner', 0.0, ...
    'alpha_old_owner', 0.0, ...
    'alpha_leverage', 0.0, ...
    'alpha_bighouse', 0.0);
end

function [period_table, age_table, group_table] = build_vote_audit_tables_local(density_by_period_age, political, target_age_masses, demographic_path, env)
T = size(density_by_period_age, 1);
age_n = size(density_by_period_age, 2);
ages = env.ages(:);
periods = demographic_path.periods(:);
if numel(periods) < T
    periods = (1:T)';
end

age_rows = initialize_row_collector_local();
group_rows = initialize_row_collector_local();

period_index = (1:T)';
period_year = periods(1:T);
equal_weight_vote = political.equal_weight_vote_path(:);
equal_weight_support = political.equal_weight_support_path(:);
owner_share = political.owner_share_path(:);
old_owner_share = political.old_owner_share_path(:);
leveraged_owner_share = political.leveraged_owner_share_path(:);
owner_vote = zeros(T, 1);
renter_vote = zeros(T, 1);
old_owner_vote = zeros(T, 1);
young_renter_vote = zeros(T, 1);
max_abs_age_contribution = zeros(T, 1);
max_abs_age = zeros(T, 1);

for t = 1:T
    age_vote_contrib = zeros(age_n, 1);
    period_owner_vote = 0;
    period_renter_vote = 0;
    period_old_owner_vote = 0;
    period_young_renter_vote = 0;

    for age_idx = 1:age_n
        density = density_by_period_age{t, age_idx};
        response = political.preference_response_by_period_age{t, age_idx};
        value_diff = political.preference_value_by_period_age{t, age_idx};
        [owner_mask, renter_mask] = owner_masks_local(density, env);

        mass = sum(density, 'all');
        vote = sum(density .* response, 'all');
        support = 0.5 .* (mass + vote);
        owner_mass = sum(density(owner_mask), 'all');
        renter_mass = sum(density(renter_mask), 'all');
        owner_vote_age = sum(density(owner_mask) .* response(owner_mask), 'all');
        renter_vote_age = sum(density(renter_mask) .* response(renter_mask), 'all');
        old_owner_vote_age = double(ages(age_idx) >= 65) .* owner_vote_age;
        young_renter_vote_age = double(ages(age_idx) < 45) .* renter_vote_age;

        period_owner_vote = period_owner_vote + owner_vote_age;
        period_renter_vote = period_renter_vote + renter_vote_age;
        period_old_owner_vote = period_old_owner_vote + old_owner_vote_age;
        period_young_renter_vote = period_young_renter_vote + young_renter_vote_age;
        age_vote_contrib(age_idx) = vote;

        age_rows = append_row_local(age_rows, ...
            t, period_year(t), ages(age_idx), target_age_masses(t, age_idx), ...
            "age", mass, vote, safe_divide_local(vote, mass), safe_divide_local(support, mass), ...
            owner_mass, safe_divide_local(owner_mass, mass), owner_vote_age, safe_divide_local(owner_vote_age, owner_mass), ...
            renter_mass, safe_divide_local(renter_vote_age, renter_mass), renter_vote_age, ...
            safe_median_local(abs(value_diff(:))), safe_mean_local(abs(response(:))));
    end

    [max_abs_age_contribution(t), max_idx] = max(abs(age_vote_contrib));
    max_abs_age(t) = ages(max_idx);
    owner_vote(t) = period_owner_vote;
    renter_vote(t) = period_renter_vote;
    old_owner_vote(t) = period_old_owner_vote;
    young_renter_vote(t) = period_young_renter_vote;

    group_rows = append_group_rows_local(group_rows, t, period_year(t), density_by_period_age, political, env);
end

period_table = table(period_index, period_year, equal_weight_vote, equal_weight_support, ...
    owner_share, old_owner_share, leveraged_owner_share, owner_vote, renter_vote, ...
    old_owner_vote, young_renter_vote, max_abs_age, max_abs_age_contribution);
age_table = rows_to_table_local(age_rows);
group_table = rows_to_table_local(group_rows);
end

function rows = append_group_rows_local(rows, t, period_year, density_by_period_age, political, env)
ages = env.ages(:);
specs = {
    "young_renter", ages < 45, false
    "young_owner", ages < 45, true
    "middle_renter", ages >= 45 & ages < 65, false
    "middle_owner", ages >= 45 & ages < 65, true
    "old_renter", ages >= 65, false
    "old_owner", ages >= 65, true
    "very_old_owner", ages >= 75, true
    };

for s = 1:size(specs, 1)
    label = specs{s, 1};
    age_keep = specs{s, 2};
    keep_owner = specs{s, 3};
    mass = 0;
    vote = 0;
    support = 0;
    owner_mass = 0;
    owner_vote = 0;
    renter_mass = 0;
    renter_vote = 0;
    abs_value = [];
    abs_response = [];

    for age_idx = find(age_keep(:))'
        density = density_by_period_age{t, age_idx};
        response = political.preference_response_by_period_age{t, age_idx};
        value_diff = political.preference_value_by_period_age{t, age_idx};
        [owner_mask, renter_mask] = owner_masks_local(density, env);
        if keep_owner
            mask = owner_mask;
        else
            mask = renter_mask;
        end
        local_density = density(mask);
        local_response = response(mask);
        local_value = value_diff(mask);
        local_mass = sum(local_density, 'all');
        local_vote = sum(local_density .* local_response, 'all');
        mass = mass + local_mass;
        vote = vote + local_vote;
        support = support + 0.5 .* (local_mass + local_vote);
        if keep_owner
            owner_mass = owner_mass + local_mass;
            owner_vote = owner_vote + local_vote;
        else
            renter_mass = renter_mass + local_mass;
            renter_vote = renter_vote + local_vote;
        end
        abs_value = [abs_value; abs(local_value(:))]; %#ok<AGROW>
        abs_response = [abs_response; abs(local_response(:))]; %#ok<AGROW>
    end

    rows = append_row_local(rows, ...
        t, period_year, NaN, NaN, label, mass, vote, safe_divide_local(vote, mass), ...
        safe_divide_local(support, mass), owner_mass, safe_divide_local(owner_mass, mass), ...
        owner_vote, safe_divide_local(owner_vote, owner_mass), renter_mass, ...
        safe_divide_local(renter_vote, renter_mass), renter_vote, ...
        safe_median_local(abs_value), safe_mean_local(abs_response));
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

function rows = initialize_row_collector_local()
rows = struct();
rows.period_index = [];
rows.period_year = [];
rows.age = [];
rows.target_age_mass = [];
rows.group = strings(0, 1);
rows.mass = [];
rows.vote_contribution = [];
rows.vote_share = [];
rows.support_share = [];
rows.owner_mass = [];
rows.owner_share = [];
rows.owner_vote = [];
rows.owner_vote_share = [];
rows.renter_mass = [];
rows.renter_vote_share = [];
rows.renter_vote = [];
rows.median_abs_value_diff = [];
rows.mean_abs_response = [];
end

function rows = append_row_local(rows, period_index, period_year, age, target_age_mass, group, mass, vote_contribution, vote_share, support_share, owner_mass, owner_share, owner_vote, owner_vote_share, renter_mass, renter_vote_share, renter_vote, median_abs_value_diff, mean_abs_response)
rows.period_index(end + 1, 1) = period_index;
rows.period_year(end + 1, 1) = period_year;
rows.age(end + 1, 1) = age;
rows.target_age_mass(end + 1, 1) = target_age_mass;
rows.group(end + 1, 1) = string(group);
rows.mass(end + 1, 1) = mass;
rows.vote_contribution(end + 1, 1) = vote_contribution;
rows.vote_share(end + 1, 1) = vote_share;
rows.support_share(end + 1, 1) = support_share;
rows.owner_mass(end + 1, 1) = owner_mass;
rows.owner_share(end + 1, 1) = owner_share;
rows.owner_vote(end + 1, 1) = owner_vote;
rows.owner_vote_share(end + 1, 1) = owner_vote_share;
rows.renter_mass(end + 1, 1) = renter_mass;
rows.renter_vote_share(end + 1, 1) = renter_vote_share;
rows.renter_vote(end + 1, 1) = renter_vote;
rows.median_abs_value_diff(end + 1, 1) = median_abs_value_diff;
rows.mean_abs_response(end + 1, 1) = mean_abs_response;
end

function tbl = rows_to_table_local(rows)
tbl = table(rows.period_index, rows.period_year, rows.age, rows.target_age_mass, rows.group, ...
    rows.mass, rows.vote_contribution, rows.vote_share, rows.support_share, ...
    rows.owner_mass, rows.owner_share, rows.owner_vote, rows.owner_vote_share, ...
    rows.renter_mass, rows.renter_vote_share, rows.renter_vote, ...
    rows.median_abs_value_diff, rows.mean_abs_response, ...
    'VariableNames', {'period_index', 'period_year', 'age', 'target_age_mass', 'group', ...
    'mass', 'vote_contribution', 'vote_share', 'support_share', ...
    'owner_mass', 'owner_share', 'owner_vote', 'owner_vote_share', ...
    'renter_mass', 'renter_vote_share', 'renter_vote', ...
    'median_abs_value_diff', 'mean_abs_response'});
end

function value = safe_divide_local(num, den)
if isempty(den) || abs(den) <= 1e-14
    value = NaN;
else
    value = num ./ den;
end
end

function value = safe_median_local(x)
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = median(x);
end
end

function value = safe_mean_local(x)
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = mean(x);
end
end

function demographic_path_full = build_demographic_path_local(project_root, demographic_source_mode)
mode = lower(string(demographic_source_mode));
entrant_prefix = "entrant_survival_";
if startsWith(mode, entrant_prefix)
    scenario = extractAfter(mode, strlength(entrant_prefix));
    demographic_path_full = build_original_5yr_demographic_entrant_survival_path(project_root, [], scenario);
    return;
end
switch mode
    case "annual_subsampled"
        demographic_path_full = build_original_5yr_demographic_path_from_age_state_csv(project_root);
    case "historical_1950"
        demographic_path_full = build_original_5yr_demographic_path_from_historical_age_shares(project_root);
    case {"historical_1950_two_group", "historical_1950_old_young_proxy"}
        demographic_path_full = build_original_5yr_demographic_two_group_proxy(project_root);
    otherwise
        error('Unsupported demographic_source_mode: %s', demographic_source_mode);
end
end

function demographic_path = truncate_demographic_path_local(demographic_path_full, k)
demographic_path = demographic_path_full;
fields = fieldnames(demographic_path_full);
for i = 1:numel(fields)
    name = fields{i};
    value = demographic_path_full.(name);
    if isnumeric(value) || islogical(value)
        if size(value, 1) >= k && size(value, 1) == numel(demographic_path_full.periods)
            demographic_path.(name) = value(1:k, :);
        end
    elseif iscell(value)
        if size(value, 1) >= k && size(value, 1) == numel(demographic_path_full.periods)
            demographic_path.(name) = value(1:k, :);
        end
    end
end
demographic_path.periods = demographic_path_full.periods(1:k);
end

function fitted = fit_path_to_horizon_local(path_like, k, fallback)
path_like = path_like(:);
if isempty(path_like)
    fitted = fallback .* ones(k, 1);
elseif isscalar(path_like)
    fitted = path_like .* ones(k, 1);
elseif numel(path_like) < k
    fitted = [path_like; path_like(end) .* ones(k - numel(path_like), 1)];
else
    fitted = path_like(1:k);
end
end
