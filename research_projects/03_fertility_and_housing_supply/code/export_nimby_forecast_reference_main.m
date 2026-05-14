function export_nimby_forecast_reference_main()
project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

ensure_external_matlab_data_paths();
source_file = resolve_zac_david_external_path('Code', 'SteadyState', 'Mod_DynamicForecast', 'loopoutput_forecast.mat');
s = load(source_file, 'Price_Trend', 'forecast_lower', 'forecast_median', 'forecast_upper');

years = (2020:2100)';
scenarios = {'low_immigration', 'medium_immigration', 'high_immigration'};
price_matrix = [s.Price_Trend.Forecast1(:), s.Price_Trend.Forecast2(:), s.Price_Trend.Forecast3(:)];

scenario_col = strings(numel(years) * numel(scenarios), 1);
year_col = zeros(numel(years) * numel(scenarios), 1);
price_col = zeros(numel(years) * numel(scenarios), 1);
index_col = zeros(numel(years) * numel(scenarios), 1);

row = 1;
for k = 1:numel(scenarios)
    level = price_matrix(:, k);
    idx = level ./ level(1);
    n = numel(years);
    scenario_col(row:(row+n-1)) = string(scenarios{k});
    year_col(row:(row+n-1)) = years;
    price_col(row:(row+n-1)) = level;
    index_col(row:(row+n-1)) = idx;
    row = row + n;
end

tbl_price = table(year_col, scenario_col, price_col, index_col, ...
    'VariableNames', {'year', 'scenario', 'house_price_level', 'house_price_index'});
writetable(tbl_price, fullfile(out_dir, 'nimby_projection_reference.csv'));

ages = (25:80)';
forecast_struct = struct( ...
    'low_immigration', s.forecast_lower, ...
    'medium_immigration', s.forecast_median, ...
    'high_immigration', s.forecast_upper);

scenario_age = strings(numel(years) * numel(scenarios), 1);
year_age = zeros(numel(years) * numel(scenarios), 1);
share_25_39 = zeros(numel(years) * numel(scenarios), 1);
share_40_59 = zeros(numel(years) * numel(scenarios), 1);
share_60_79 = zeros(numel(years) * numel(scenarios), 1);
share_80 = zeros(numel(years) * numel(scenarios), 1);
average_age = zeros(numel(years) * numel(scenarios), 1);

row = 1;
for k = 1:numel(scenarios)
    scenario_name = scenarios{k};
    weights = forecast_struct.(scenario_name);
    n = numel(years);
    scenario_age(row:(row+n-1)) = string(scenario_name);
    year_age(row:(row+n-1)) = years;
    share_25_39(row:(row+n-1)) = sum(weights(ages >= 25 & ages <= 39, :), 1)';
    share_40_59(row:(row+n-1)) = sum(weights(ages >= 40 & ages <= 59, :), 1)';
    share_60_79(row:(row+n-1)) = sum(weights(ages >= 60 & ages <= 79, :), 1)';
    share_80(row:(row+n-1)) = sum(weights(ages == 80, :), 1)';
    average_age(row:(row+n-1)) = (ages' * weights)';
    row = row + n;
end

tbl_age = table(year_age, scenario_age, share_25_39, share_40_59, share_60_79, share_80, average_age, ...
    'VariableNames', {'year', 'scenario', 'share_25_39', 'share_40_59', 'share_60_79', 'share_80', 'average_age'});
writetable(tbl_age, fullfile(out_dir, 'nimby_projection_age_groups_all_scenarios.csv'));

fid = fopen(fullfile(out_dir, 'nimby_projection_reference_source.txt'), 'w');
if fid == -1
    error('Could not write source note.');
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'Source MAT file: %s\n', source_file);
fprintf(fid, 'Price paths exported from Price_Trend.Forecast1/2/3.\n');
fprintf(fid, 'Age weights exported from forecast_lower/median/upper over ages 25:80.\n');
end
