function demographic_path = build_original_5yr_demographic_path_from_historical_age_shares(project_root, selected_years)
% Build the original 5-year demographic path from the historical US age-share workbook.
%
% Uses US Age Share Fine Grained.xlsx, which contains annual single-year age
% shares from 1950 onward. We aggregate those into the model's 5-year adult
% bins: 25-29, 30-34, ..., 85-89, and 90+.

if nargin < 1 || isempty(project_root)
    this_file = mfilename('fullpath');
    this_dir = fileparts(this_file);
    project_root = fileparts(this_dir);
end

workbook_path = fullfile(project_root, 'US Age Share Fine Grained.xlsx');
if ~isfile(workbook_path)
    error('Historical demographic workbook not found: %s', workbook_path);
end

sheet_cells = readcell(workbook_path, 'Sheet', 'Share');
header = sheet_cells(1, :);
header_text = cellfun(@header_to_string_local, header, 'UniformOutput', false);

year_col = find(strcmp(header_text, 'Year'), 1, 'first');
adult_total_col = find(strcmp(header_text, 'Adult Total'), 1, 'first');
if isempty(year_col) || isempty(adult_total_col)
    error('Expected Year / Adult Total columns not found in %s sheet Share.', workbook_path);
end

data = sheet_cells(2:end, :);
year_values = cellfun(@numeric_value_local, data(:, year_col));
valid_rows = ~isnan(year_values);
available_years = year_values(valid_rows);
if nargin < 2 || isempty(selected_years)
    selected_years = (1950:5:2015)';
end
selected_years = selected_years(:);

[is_present, row_idx] = ismember(selected_years, available_years);
if ~all(is_present)
    missing_years = selected_years(~is_present);
    error('Selected historical years are unavailable in %s: %s', workbook_path, mat2str(missing_years'));
end

age_bins_model = (25:5:90)';
age_ranges = cell(numel(age_bins_model), 1);
for i = 1:numel(age_bins_model)
    age_start = age_bins_model(i);
    if age_start < 90
        age_ranges{i} = age_start:(age_start + 4);
    else
        age_ranges{i} = 90:100;
    end
end

share_by_age = zeros(numel(selected_years), numel(age_bins_model));
for iy = 1:numel(selected_years)
    row = data(valid_rows, :);
    row = row(row_idx(iy), :);
    for ia = 1:numel(age_bins_model)
        ages = age_ranges{ia};
        share_sum = 0.0;
        for age = ages
            age_label = char(string(age));
            rel_idx = find(strcmp(header_text(adult_total_col + 1:end), age_label), 1, 'first');
            if isempty(rel_idx)
                error('Expected adult-share age column %s not found in %s sheet Share.', age_label, workbook_path);
            end
            share_col = adult_total_col + rel_idx;
            share_sum = share_sum + numeric_value_local(row{1, share_col});
        end
        share_by_age(iy, ia) = share_sum;
    end
end

baseline = share_by_age(1, :);
cohort_scale_by_age = share_by_age ./ baseline;

demographic_path = struct();
demographic_path.periods = selected_years;
demographic_path.years = selected_years;
demographic_path.cohort_scale = mean(cohort_scale_by_age, 2);
demographic_path.cohort_scale_by_age = cohort_scale_by_age;
demographic_path.population_by_age = share_by_age;
demographic_path.age_bins_model = age_bins_model;
demographic_path.source_path = workbook_path;
demographic_path.source_sheet = 'Share';
demographic_path.description = ['Historical US age-share path from US Age Share Fine Grained.xlsx ', ...
    '(sheet Share), aggregated into model bins 25:5:90 and sampled on 5-year checkpoints.'];
end

function text = header_to_string_local(value)
if isempty(value)
    text = '';
elseif (isstring(value) || ischar(value))
    text = char(string(value));
elseif isnumeric(value)
    if isscalar(value) && isnan(value)
        text = '';
    else
        text = char(string(value));
    end
else
    text = char(string(value));
end
end

function value = numeric_value_local(cell_value)
if isnumeric(cell_value)
    value = double(cell_value);
elseif ischar(cell_value) || isstring(cell_value)
    value = str2double(cell_value);
else
    value = NaN;
end
end
