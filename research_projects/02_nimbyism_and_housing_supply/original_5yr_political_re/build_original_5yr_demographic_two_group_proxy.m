function demographic_path = build_original_5yr_demographic_two_group_proxy(project_root, selected_years, young_max_age)
% Build a two-group demographic proxy from the historical age-share path.
%
% This is a diagnostic approximation, not a replacement for the full model.
% We keep the model's original age bins but collapse all time variation into
% two broad blocks:
%   young: 25-young_max_age
%   old:   young_max_age+5 and above
%
% Within each block, the within-group age composition is held fixed at the
% baseline year. Only the total group mass moves over time.

if nargin < 1 || isempty(project_root)
    this_file = mfilename('fullpath');
    this_dir = fileparts(this_file);
    project_root = fileparts(this_dir);
end
if nargin < 2
    selected_years = [];
end
if nargin < 3 || isempty(young_max_age)
    young_max_age = 50;
end

base_path = build_original_5yr_demographic_path_from_historical_age_shares(project_root, selected_years);
age_bins = base_path.age_bins_model(:);

young_mask = age_bins <= young_max_age;
old_mask = ~young_mask;
if ~any(young_mask) || ~any(old_mask)
    error('Two-group proxy split failed. Check young_max_age=%g against model age bins.', young_max_age);
end

baseline_population = base_path.population_by_age(1, :);
proxy_population = zeros(size(base_path.population_by_age));

young_baseline_total = sum(baseline_population(young_mask));
old_baseline_total = sum(baseline_population(old_mask));

if young_baseline_total <= 0 || old_baseline_total <= 0
    error('Two-group proxy baseline group totals must be positive.');
end

for t = 1:size(base_path.population_by_age, 1)
    current_population = base_path.population_by_age(t, :);
    current_young_total = sum(current_population(young_mask));
    current_old_total = sum(current_population(old_mask));

    proxy_population(t, young_mask) = baseline_population(young_mask) .* (current_young_total ./ young_baseline_total);
    proxy_population(t, old_mask) = baseline_population(old_mask) .* (current_old_total ./ old_baseline_total);
end

proxy_scale_by_age = proxy_population ./ baseline_population;

demographic_path = base_path;
demographic_path.population_by_age = proxy_population;
demographic_path.cohort_scale_by_age = proxy_scale_by_age;
demographic_path.cohort_scale = mean(proxy_scale_by_age, 2);
demographic_path.two_group_proxy = true;
demographic_path.two_group_labels = ["young", "old"];
demographic_path.two_group_age_ranges = { ...
    sprintf('%d-%d', age_bins(find(young_mask, 1, 'first')), young_max_age), ...
    sprintf('%d+', age_bins(find(old_mask, 1, 'first'))) ...
    };
demographic_path.two_group_scale = [ ...
    sum(proxy_population(:, young_mask), 2) ./ young_baseline_total, ...
    sum(proxy_population(:, old_mask), 2) ./ old_baseline_total ...
    ];
demographic_path.description = [ ...
    base_path.description, ...
    sprintf(' Two-group diagnostic proxy with young bins up to %d and old bins above that; within-group composition fixed at the baseline year.', young_max_age) ...
    ];
end
