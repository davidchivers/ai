function write_fertility_first_birth_timing_main()
project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

this_code_dir = fullfile(project_root, 'code');
addpath(this_code_dir, '-begin');
project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end
cd(this_code_dir);

ensure_external_matlab_data_paths();

cfg = fertility_benchmark_config();
price_grid = sort(unique([cfg.full_price_grid, 1.75]));
n = numel(price_grid);

avg_birth_rate = NaN(n, 1);
avg_first_birth_rate = NaN(n, 1);
mean_age_first_birth = NaN(n, 1);
median_age_first_birth = NaN(n, 1);
share_first_birth_30_plus = NaN(n, 1);

profile_table = table();

for i = 1:n
    point = evaluate_timing_point(price_grid(i), cfg.rbPos, cfg.overrides);
    avg_birth_rate(i) = point.avg_birth_rate;
    avg_first_birth_rate(i) = point.avg_first_birth_rate;
    mean_age_first_birth(i) = point.mean_age_first_birth;
    median_age_first_birth(i) = point.median_age_first_birth;
    share_first_birth_30_plus(i) = point.share_first_birth_30_plus;

    n_age = numel(point.ages);
    tmp = table( ...
        repmat(price_grid(i), n_age, 1), ...
        repmat(string(sprintf('a_price=%.2f', price_grid(i))), n_age, 1), ...
        point.ages, ...
        point.birth_rate_by_age, ...
        point.first_birth_rate_by_age, ...
        point.first_birth_hazard_by_age, ...
        point.first_birth_age_dist, ...
        point.childless_share_by_age, ...
        'VariableNames', {'a_price', 'price_label', 'age', 'birth_rate', 'first_birth_rate', ...
        'first_birth_hazard', 'first_birth_age_share', 'childless_share'});
    profile_table = [profile_table; tmp]; %#ok<AGROW>
end

summary_table = table( ...
    price_grid(:), avg_birth_rate, avg_first_birth_rate, mean_age_first_birth, ...
    median_age_first_birth, share_first_birth_30_plus, ...
    'VariableNames', {'a_price', 'avg_birth_rate', 'avg_first_birth_rate', ...
    'mean_age_first_birth', 'median_age_first_birth', 'share_first_birth_30_plus'});

writetable(summary_table, fullfile(out_dir, 'fertility_first_birth_timing_summary.csv'));
writetable(profile_table, fullfile(out_dir, 'fertility_first_birth_timing_profiles.csv'));
write_report(fullfile(out_dir, 'fertility_first_birth_timing.md'), summary_table, profile_table, cfg);
end

function point = evaluate_timing_point(a_price, rbPos, overrides)
[~, ~, ~, ~, ~, diagnostics] = SolveSS_fertility([a_price, rbPos], overrides);

point = struct();
point.avg_birth_rate = diagnostics.avg_birth_rate;
point.avg_first_birth_rate = diagnostics.avg_first_birth_rate;
point.mean_age_first_birth = diagnostics.mean_age_first_birth;
point.median_age_first_birth = diagnostics.median_age_first_birth;
point.share_first_birth_30_plus = diagnostics.share_first_birth_30_plus;
point.ages = diagnostics.ages(:);
point.birth_rate_by_age = diagnostics.birth_rate_by_age(:);
point.first_birth_rate_by_age = diagnostics.first_birth_rate_by_age(:);
point.first_birth_hazard_by_age = diagnostics.first_birth_hazard_by_age(:);
point.first_birth_age_dist = diagnostics.first_birth_age_dist(:);
point.childless_share_by_age = diagnostics.childless_share_by_age(:);
end

function write_report(report_path, summary_table, profile_table, cfg)
fid = fopen(report_path, 'w');
fprintf(fid, '# First-birth timing in the fertility benchmark\n\n');
fprintf(fid, 'This note isolates the first-birth timing object in the corrected household fertility benchmark.\n\n');

low = summary_table(1, :);
high = summary_table(end, :);
birth_ages = [25 30 35 40];
benchmark_mask = abs(profile_table.a_price - cfg.eval_price) < 1e-12 & ismember(profile_table.age, birth_ages);
benchmark_profile = profile_table(benchmark_mask, {'age', 'first_birth_age_share'});

fprintf(fid, '## Main read\n\n');
fprintf(fid, '- Moving from `a_price = %.2f` to `a_price = %.2f`, mean age at first birth rises from `%.2f` to `%.2f`.\n', ...
    low.a_price, high.a_price, low.mean_age_first_birth, high.mean_age_first_birth);
fprintf(fid, '- Over the same range, the share of first births at age `30+` rises from `%.3f` to `%.3f`.\n', ...
    low.share_first_birth_30_plus, high.share_first_birth_30_plus);
fprintf(fid, '- The average first-birth rate falls from `%.3f` to `%.3f`.\n\n', ...
    low.avg_first_birth_rate, high.avg_first_birth_rate);

fprintf(fid, 'So the model shows delay, not just lower completed fertility: high house prices move first births to older ages and reduce the flow of births from childless households.\n\n');
fprintf(fid, '## Benchmark calibration target\n\n');
fprintf(fid, 'The benchmark now replaces the old equal-weight timing block with parity-zero realized-birth shifters calibrated to the pooled recent U.S. first-birth distribution for ages `25+` from CDC WONDER.\n\n');
fprintf(fid, '- target shares by age `25, 30, 35, 40`: `[%.3f, %.3f, %.3f, %.3f]`\n', cfg.target_first_birth_age_share_25plus);
fprintf(fid, '- model shares at benchmark `a_price = %.2f`: `[%.3f, %.3f, %.3f, %.3f]`\n\n', ...
    cfg.eval_price, benchmark_profile.first_birth_age_share(1), benchmark_profile.first_birth_age_share(2), ...
    benchmark_profile.first_birth_age_share(3), benchmark_profile.first_birth_age_share(4));
fprintf(fid, '## Summary table\n\n');
fprintf(fid, '| House price | Avg birth rate | Avg first-birth rate | Mean age first birth | Median age first birth | Share first births 30+ |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(summary_table)
    fprintf(fid, '| %.2f | `%.4f` | `%.4f` | `%.2f` | `%.0f` | `%.3f` |\n', ...
        summary_table.a_price(i), summary_table.avg_birth_rate(i), summary_table.avg_first_birth_rate(i), ...
        summary_table.mean_age_first_birth(i), summary_table.median_age_first_birth(i), ...
        summary_table.share_first_birth_30_plus(i));
end
fprintf(fid, '\n');
fclose(fid);
end
