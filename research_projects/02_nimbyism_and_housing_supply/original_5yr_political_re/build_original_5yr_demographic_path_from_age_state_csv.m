function demographic_path = build_original_5yr_demographic_path_from_age_state_csv(project_root, selected_years)
% Build a 5-year-timing demographic path from the annual age-state CSV.
%
% The original model moves in 5-year periods, so this helper subsamples the
% annual demographic path onto 5-year checkpoints. With the current input data,
% the default path is 2010 -> 2015.

if nargin < 1 || isempty(project_root)
    this_file = mfilename('fullpath');
    this_dir = fileparts(this_file);
    project_root = fileparts(this_dir);
end

extension_dir = fullfile(project_root, 'extensions', 're_no_politics');
if exist(extension_dir, 'dir')
    addpath(extension_dir, '-begin');
end

annual_path = build_demographic_path_from_age_state_csv(project_root);
available_years = annual_path.years(:);

if nargin < 2 || isempty(selected_years)
    first_year = available_years(1);
    last_year = available_years(end);
    selected_years = (first_year:5:last_year)';
    selected_years = selected_years(ismember(selected_years, available_years));
end

selected_years = selected_years(:);
if isempty(selected_years)
    error('No selected_years supplied for the original 5-year demographic path.');
end

[is_present, year_idx] = ismember(selected_years, available_years);
if ~all(is_present)
    missing_years = selected_years(~is_present);
    error('Selected 5-year years are unavailable in the annual demographic path: %s', mat2str(missing_years'));
end

demographic_path = annual_path;
demographic_path.periods = selected_years;
demographic_path.years = selected_years;
demographic_path.cohort_scale = annual_path.cohort_scale(year_idx, :);
demographic_path.cohort_scale_by_age = annual_path.cohort_scale_by_age(year_idx, :);
demographic_path.population_by_age = annual_path.population_by_age(year_idx, :);
demographic_path.description = sprintf([ ...
    '%s Subsampled to original 5-year timing checkpoints: %s.'], ...
    annual_path.description, mat2str(selected_years'));
end
