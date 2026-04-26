function cf = audit_original_5yr_political_preference_shift_counterfactual(audit_mat_path, run_tag)
% Counterfactual additive political-preference shift needed to clear votes.
%
% This keeps a saved transition path fixed and asks, period by period, what
% additive shift in the smoothed voting index would make the equal-weight
% political residual equal zero:
%
%   vote_t(delta) = sum_s mu_t(s) * tanh((dV_t(s) + delta) / (2 * tau)).
%
% The output is a diagnostic, not an equilibrium solve.

if nargin < 1 || isempty(audit_mat_path)
    this_dir = fileparts(mfilename('fullpath'));
    audit_mat_path = fullfile(this_dir, 'truth', 'political_vote_audit', ...
        'vote_audit_probe_k10_s020_popweights', ...
        'vote_audit_probe_k10_s020_popweights_results.mat');
end
if nargin < 2 || isempty(run_tag)
    run_tag = 'preference_shift_cf_k10_s020_popweights';
end

loaded = load(audit_mat_path, 'solve_results', 'demographic_path', 'params');
solve_results = loaded.solve_results;
demographic_path = loaded.demographic_path;
params = loaded.params;

if ~isfield(solve_results, 'current_path_pass') || ~isfield(solve_results.current_path_pass, 'sim')
    error('Audit MAT does not contain solve_results.current_path_pass.sim.');
end
if ~isfield(params, 'political_response_sigma') || isempty(params.political_response_sigma)
    tau = 0.20;
else
    tau = params.political_response_sigma;
end

sim = solve_results.current_path_pass.sim;
political = sim.political;
density_by_period_age = sim.density_by_period_age;
value_by_period_age = political.preference_value_by_period_age;

T = size(density_by_period_age, 1);
periods = demographic_path.periods(:);
if numel(periods) < T
    periods = (1:T)';
end

period_index = (1:T)';
period_year = periods(1:T);
actual_vote = political.equal_weight_vote_path(:);
zero_vote_shift = NaN(T, 1);
vote_at_minus_010 = NaN(T, 1);
vote_at_minus_005 = NaN(T, 1);
vote_at_plus_005 = NaN(T, 1);
vote_at_plus_010 = NaN(T, 1);
weighted_mean_value = NaN(T, 1);
weighted_median_value = NaN(T, 1);
value_p25 = NaN(T, 1);
value_p75 = NaN(T, 1);

for t = 1:T
    [value_vec, weight_vec] = collect_period_values_local(density_by_period_age, value_by_period_age, t);
    if isempty(value_vec)
        continue;
    end

    weighted_mean_value(t) = sum(weight_vec .* value_vec);
    weighted_median_value(t) = weighted_quantile_local(value_vec, weight_vec, 0.50);
    value_p25(t) = weighted_quantile_local(value_vec, weight_vec, 0.25);
    value_p75(t) = weighted_quantile_local(value_vec, weight_vec, 0.75);

    vote_at_minus_010(t) = shifted_vote_local(value_vec, weight_vec, tau, -0.10);
    vote_at_minus_005(t) = shifted_vote_local(value_vec, weight_vec, tau, -0.05);
    vote_at_plus_005(t) = shifted_vote_local(value_vec, weight_vec, tau, 0.05);
    vote_at_plus_010(t) = shifted_vote_local(value_vec, weight_vec, tau, 0.10);
    zero_vote_shift(t) = find_zero_shift_local(value_vec, weight_vec, tau);
end

period_table = table(period_index, period_year, actual_vote, zero_vote_shift, ...
    vote_at_minus_010, vote_at_minus_005, vote_at_plus_005, vote_at_plus_010, ...
    weighted_mean_value, weighted_median_value, value_p25, value_p75);

this_dir = fileparts(mfilename('fullpath'));
safe_tag = char(regexprep(string(run_tag), '[^A-Za-z0-9_]+', '_'));
output_dir = fullfile(this_dir, 'truth', 'political_vote_audit', safe_tag);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

period_csv = fullfile(output_dir, sprintf('%s_by_period.csv', safe_tag));
writetable(period_table, period_csv);
mat_path = fullfile(output_dir, sprintf('%s_results.mat', safe_tag));
if isfile(mat_path)
    delete(mat_path);
end
save(mat_path, 'period_table', 'audit_mat_path', 'tau', '-v7');

cf = struct();
cf.output_dir = output_dir;
cf.period_csv = period_csv;
cf.mat_path = mat_path;
cf.tau = tau;
cf.max_abs_actual_vote = max(abs(actual_vote));
cf.max_abs_zero_vote_shift = max(abs(zero_vote_shift), [], 'omitnan');
cf.mean_zero_vote_shift = mean(zero_vote_shift, 'omitnan');
cf.message = 'Political preference-shift counterfactual completed.';

fprintf('Preference-shift counterfactual written to %s\n', output_dir);
fprintf('tau=%0.6g max_abs_vote=%0.12g max_abs_zero_shift=%0.12g mean_zero_shift=%0.12g\n', ...
    tau, cf.max_abs_actual_vote, cf.max_abs_zero_vote_shift, cf.mean_zero_vote_shift);
end

function [value_vec, weight_vec] = collect_period_values_local(density_by_period_age, value_by_period_age, t)
age_n = size(density_by_period_age, 2);
value_vec = [];
weight_vec = [];
for age_idx = 1:age_n
    density = density_by_period_age{t, age_idx};
    values = value_by_period_age{t, age_idx};
    if isempty(density) || isempty(values)
        continue;
    end
    density = density(:);
    values = values(:);
    keep = isfinite(density) & isfinite(values) & density > 0;
    value_vec = [value_vec; values(keep)]; %#ok<AGROW>
    weight_vec = [weight_vec; density(keep)]; %#ok<AGROW>
end
total = sum(weight_vec);
if total > 0
    weight_vec = weight_vec ./ total;
else
    value_vec = [];
    weight_vec = [];
end
end

function vote = shifted_vote_local(value_vec, weight_vec, tau, shift)
vote = sum(weight_vec .* tanh((value_vec + shift) ./ (2 .* tau)));
end

function shift = find_zero_shift_local(value_vec, weight_vec, tau)
lo = -5 .* tau;
hi = 5 .* tau;
vlo = shifted_vote_local(value_vec, weight_vec, tau, lo);
vhi = shifted_vote_local(value_vec, weight_vec, tau, hi);

expand_count = 0;
while sign(vlo) == sign(vhi) && expand_count < 8
    lo = 2 .* lo;
    hi = 2 .* hi;
    vlo = shifted_vote_local(value_vec, weight_vec, tau, lo);
    vhi = shifted_vote_local(value_vec, weight_vec, tau, hi);
    expand_count = expand_count + 1;
end

if sign(vlo) == sign(vhi)
    shift = NaN;
    return;
end

for iter = 1:80
    mid = 0.5 .* (lo + hi);
    vmid = shifted_vote_local(value_vec, weight_vec, tau, mid);
    if abs(vmid) <= 1e-10
        shift = mid;
        return;
    end
    if sign(vmid) == sign(vlo)
        lo = mid;
        vlo = vmid;
    else
        hi = mid;
    end
end
shift = 0.5 .* (lo + hi);
end

function q = weighted_quantile_local(x, w, p)
[x, order] = sort(x(:));
w = w(order);
cdf = cumsum(w(:)) ./ sum(w);
idx = find(cdf >= p, 1, 'first');
if isempty(idx)
    q = NaN;
else
    q = x(idx);
end
end
