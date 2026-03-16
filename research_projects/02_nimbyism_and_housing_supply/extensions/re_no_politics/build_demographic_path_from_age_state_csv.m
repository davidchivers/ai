function demographic_path = build_demographic_path_from_age_state_csv(project_root)
% Build a model-aligned demographic path from the project's age-state CSV.

if nargin < 1 || isempty(project_root)
    this_file = mfilename('fullpath');
    this_dir = fileparts(this_file);
    project_root = fileparts(fileparts(this_dir));
end

csv_path = fullfile(project_root, 'code', 'data', 'age state.csv');
if ~isfile(csv_path)
    error('Demographic input file not found: %s', csv_path);
end

tbl = readtable(csv_path, 'VariableNamingRule', 'preserve');

% Keep state-level rows only and aggregate to a US-level path.
state_rows = startsWith(string(tbl.("GEO.id")), "0400000US");
tbl = tbl(state_rows, :);

years = (2010:2018)';
age_labels = {
    'age25to29'
    'age30to34'
    'age35to39'
    'age40to44'
    'age45to49'
    'age50to54'
    'age55to59'
    'age60to64'
    'age65to69'
    'age70to74'
    'age75to79'
    'age80to84'
    'age85plus'
};

n_years = numel(years);
n_model_ages = 14;
cohort_scale_by_age = zeros(n_years, n_model_ages);
population_by_age = zeros(n_years, n_model_ages);

for iy = 1:n_years
    year = years(iy);
    year_prefix = sprintf('est7%dsex0_', year);

    raw_counts = zeros(1, numel(age_labels));
    for ia = 1:numel(age_labels)
        col = [year_prefix, age_labels{ia}];
        if ~ismember(col, tbl.Properties.VariableNames)
            error('Expected demographic column %s not found in %s', col, csv_path);
        end
        raw_counts(ia) = sum(tbl.(col), 'omitnan');
    end

    % The CSV ends at 85+, while the model has separate 85 and 90 bins.
    mapped_counts = [raw_counts(1:end-1), raw_counts(end), raw_counts(end)];
    population_by_age(iy, :) = mapped_counts;
end

baseline = population_by_age(1, :);
cohort_scale_by_age = population_by_age ./ baseline;

demographic_path = struct();
demographic_path.periods = years;
demographic_path.years = years;
demographic_path.cohort_scale = mean(cohort_scale_by_age, 2);
demographic_path.cohort_scale_by_age = cohort_scale_by_age;
demographic_path.population_by_age = population_by_age;
demographic_path.age_bins_model = (25:5:90)';
demographic_path.source_path = csv_path;
demographic_path.description = ['US state-aggregated age path from age state.csv, ', ...
    'mapped to model ages 25:5:90 with the final 85+ bin duplicated for ages 85 and 90.'];
end
