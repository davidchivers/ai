function demographic_path = build_original_5yr_demographic_entrant_survival_path(project_root, selected_years, scenario, entrant_scale, survival_rates)
% Build a parsimonious demographic path from entrants and fixed survival.
%
% The primitive demographic object is the age-25 entrant path. Older cohorts
% evolve mechanically by aging forward with fixed five-year survival rates.

if nargin < 1 || isempty(project_root)
    this_file = mfilename('fullpath');
    this_dir = fileparts(this_file);
    project_root = fileparts(this_dir);
end
if nargin < 2
    selected_years = [];
end
if nargin < 3 || isempty(scenario)
    scenario = 'baby_boom';
end
[scenario, terminal_survival_override] = parse_scenario_options_local(scenario);

base_path = build_original_5yr_demographic_path_from_historical_age_shares(project_root, selected_years);
age_bins = base_path.age_bins_model(:);
baseline_population = base_path.population_by_age(1, :);
n_periods = numel(base_path.periods);
n_ages = numel(age_bins);

if nargin < 4 || isempty(entrant_scale)
    entrant_scale = build_entrant_scale_local(n_periods, scenario);
end
entrant_scale = fit_row_vector_local(entrant_scale, n_periods, 1.0);

if nargin < 5 || isempty(survival_rates)
    survival_rates = default_five_year_survival_local(age_bins);
end
survival_rates = fit_row_vector_local(survival_rates, n_ages, 0.98);
survival_rates = min(max(survival_rates, 0), 1);
if ~isnan(terminal_survival_override)
    survival_rates(end) = terminal_survival_override;
end

population_by_age = zeros(n_periods, n_ages);
population_by_age(1, :) = baseline_population;

for t = 2:n_periods
    population_by_age(t, 1) = baseline_population(1) .* entrant_scale(t);
    for ia = 1:(n_ages - 1)
        population_by_age(t, ia + 1) = population_by_age(t, ia + 1) + ...
            survival_rates(ia) .* population_by_age(t - 1, ia);
    end
    population_by_age(t, n_ages) = population_by_age(t, n_ages) + ...
        survival_rates(n_ages) .* population_by_age(t - 1, n_ages);
end

cohort_scale_by_age = population_by_age ./ baseline_population;

demographic_path = base_path;
demographic_path.population_by_age = population_by_age;
demographic_path.cohort_scale_by_age = cohort_scale_by_age;
demographic_path.cohort_scale = mean(cohort_scale_by_age, 2);
demographic_path.entrant_survival_path = true;
demographic_path.entrant_scenario = char(string(scenario));
demographic_path.entrant_scale = entrant_scale(:);
demographic_path.five_year_survival_rates = survival_rates(:);
demographic_path.terminal_survival_override = terminal_survival_override;
demographic_path.description = sprintf([ ...
    'Entrant-survival demographic path. Age-25 entrants follow scenario %s; ', ...
    'older cohorts age forward mechanically using fixed five-year survival rates. ', ...
    'Baseline age masses come from %s.'], ...
    char(string(scenario)), base_path.description);
end

function [scenario, terminal_survival_override] = parse_scenario_options_local(scenario)
scenario = lower(string(scenario));
terminal_survival_override = NaN;

if endsWith(scenario, "_terminal_exit") || endsWith(scenario, "_no_terminal_survival")
    scenario = regexprep(scenario, '(_terminal_exit|_no_terminal_survival)$', '');
    terminal_survival_override = 0.0;
    return;
end

tokens = regexp(char(scenario), '^(.*)_terminal_s([0-9]+)$', 'tokens', 'once');
if ~isempty(tokens)
    scenario = string(tokens{1});
    terminal_survival_override = str2double(tokens{2}) ./ 100.0;
    terminal_survival_override = min(max(terminal_survival_override, 0), 1);
end
end

function entrant_scale = build_entrant_scale_local(n_periods, scenario)
scenario = lower(string(scenario));
x = (1:n_periods)';
switch scenario
    case {"flat", "baseline", "constant"}
        entrant_scale = ones(n_periods, 1);
    case {"baby_boom", "boom", "temporary_boom"}
        center = max(2, min(n_periods, round(0.35 .* n_periods)));
        width = max(1.0, 0.12 .* n_periods);
        entrant_scale = 1.0 + 0.25 .* exp(-0.5 .* ((x - center) ./ width).^2);
    case {"secular_decline", "decline", "birth_decline"}
        entrant_scale = linspace(1.0, 0.75, n_periods)';
    otherwise
        error('Unsupported entrant-survival scenario: %s', scenario);
end
end

function survival_rates = default_five_year_survival_local(age_bins)
% Conservative five-year survival profile for model age bins 25:5:90.
survival_rates = ones(numel(age_bins), 1);
for i = 1:numel(age_bins)
    age = age_bins(i);
    if age < 50
        survival_rates(i) = 0.990;
    elseif age < 65
        survival_rates(i) = 0.975;
    elseif age < 75
        survival_rates(i) = 0.940;
    elseif age < 85
        survival_rates(i) = 0.850;
    elseif age < 90
        survival_rates(i) = 0.700;
    else
        survival_rates(i) = 0.500;
    end
end
end

function values = fit_row_vector_local(values, n, fallback)
if isempty(values)
    values = fallback .* ones(1, n);
    return;
end
values = values(:)';
if isscalar(values)
    values = values .* ones(1, n);
elseif numel(values) < n
    values = [values, values(end) .* ones(1, n - numel(values))];
elseif numel(values) > n
    values = values(1:n);
end
end
