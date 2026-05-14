function inputs = export_original_5yr_dynare_scaffold_inputs(max_k, basis_count, demographic_source_mode, ...
    seed_price_csv_path, vote_path_csv_path, summary_csv_path, output_dir)
% Export a small Dynare-ready scaffold input pack for the original 5-year RE problem.

if nargin < 1 || isempty(max_k)
    max_k = 14;
end
if nargin < 2 || isempty(basis_count)
    basis_count = 4;
end
if nargin < 3 || isempty(demographic_source_mode)
    demographic_source_mode = 'historical_1950';
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_dir = fileparts(this_dir);
if nargin < 4 || isempty(seed_price_csv_path)
    seed_price_csv_path = fullfile(project_dir, ...
        'original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv');
end
if nargin < 5 || isempty(vote_path_csv_path)
    vote_path_csv_path = fullfile(project_dir, ...
        'original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_vote_path.csv');
end
if nargin < 6 || isempty(summary_csv_path)
    summary_csv_path = fullfile(project_dir, ...
        'original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_summary.csv');
end
if nargin < 7 || isempty(output_dir)
    output_dir = fullfile(this_dir, 'generated');
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

seed_price_path = read_vector_csv_local(seed_price_csv_path);
if numel(seed_price_path) < max_k
    error('Seed price path has length %d but max_k=%d.', numel(seed_price_path), max_k);
end
seed_price_path = seed_price_path(1:max_k);

vote_path = read_vector_csv_local(vote_path_csv_path);
if numel(vote_path) < max_k
    error('Vote path has length %d but max_k=%d.', numel(vote_path), max_k);
end
vote_path = vote_path(1:max_k);

demographic_path = build_demographic_path_local(project_dir, demographic_source_mode, max_k);
basis = build_piecewise_linear_basis_local(max_k, basis_count);
active_periods = find_active_periods_local(vote_path, 0.65);
incumbent_metrics = read_summary_metrics_local(summary_csv_path);

inputs = struct();
inputs.generated_at = char(datetime('now', 'TimeZone', 'Europe/London', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));
inputs.max_k = max_k;
inputs.basis_count = basis_count;
inputs.demographic_source_mode = demographic_source_mode;
inputs.seed_price_csv_path = seed_price_csv_path;
inputs.vote_path_csv_path = vote_path_csv_path;
inputs.summary_csv_path = summary_csv_path;
inputs.seed_price_path = seed_price_path(:);
inputs.log_seed_price_path = log(seed_price_path(:));
inputs.vote_path = vote_path(:);
inputs.active_periods = active_periods(:);
inputs.basis = basis;
inputs.periods = demographic_path.periods(:);
inputs.years = demographic_path.years(:);
inputs.cohort_scale = demographic_path.cohort_scale(:);
inputs.cohort_scale_by_age = demographic_path.cohort_scale_by_age;
inputs.age_bins_model = demographic_path.age_bins_model(:);
inputs.incumbent_metrics = incumbent_metrics;

save(fullfile(output_dir, 'nimby_dynare_scaffold_input.mat'), 'inputs');
writematrix(inputs.seed_price_path, fullfile(output_dir, 'nimby_dynare_seed_price_path.csv'));
writematrix(inputs.vote_path, fullfile(output_dir, 'nimby_dynare_vote_path.csv'));
writematrix(inputs.basis, fullfile(output_dir, 'nimby_dynare_basis.csv'));

manifest = struct();
manifest.generated_at = inputs.generated_at;
manifest.max_k = inputs.max_k;
manifest.basis_count = inputs.basis_count;
manifest.demographic_source_mode = inputs.demographic_source_mode;
manifest.seed_price_csv_path = inputs.seed_price_csv_path;
manifest.vote_path_csv_path = inputs.vote_path_csv_path;
manifest.summary_csv_path = inputs.summary_csv_path;
manifest.active_periods = inputs.active_periods(:)';
manifest.incumbent_metrics = incumbent_metrics;
write_text_local(fullfile(output_dir, 'nimby_dynare_scaffold_manifest.json'), jsonencode(manifest, PrettyPrint=true));
end

function demographic_path = build_demographic_path_local(project_dir, demographic_source_mode, max_k)
switch lower(string(demographic_source_mode))
    case "historical_1950"
        demographic_path = build_original_5yr_demographic_path_from_historical_age_shares(project_root_local(project_dir));
    case "age_state_csv"
        demographic_path = build_original_5yr_demographic_path_from_age_state_csv(project_root_local(project_dir));
    otherwise
        error('Unsupported demographic_source_mode: %s', demographic_source_mode);
end

fields_to_truncate = {'periods', 'years', 'cohort_scale', 'population_by_age'};
for i = 1:numel(fields_to_truncate)
    field_name = fields_to_truncate{i};
    if isfield(demographic_path, field_name)
        demographic_path.(field_name) = demographic_path.(field_name)(1:max_k, :);
    end
end
if isfield(demographic_path, 'cohort_scale_by_age')
    demographic_path.cohort_scale_by_age = demographic_path.cohort_scale_by_age(1:max_k, :);
end
end

function root = project_root_local(project_dir)
root = fileparts(project_dir);
end

function values = read_vector_csv_local(csv_path)
if ~isfile(csv_path)
    error('Required CSV not found: %s', csv_path);
end
raw = readmatrix(csv_path);
if isempty(raw)
    error('CSV is empty: %s', csv_path);
end
values = raw(:);
values = values(isfinite(values));
if isempty(values)
    error('CSV contained no finite values: %s', csv_path);
end
end

function basis = build_piecewise_linear_basis_local(T, basis_count)
if basis_count < 2
    error('basis_count must be at least 2.');
end

anchors = round(linspace(1, T, basis_count));
anchors = unique(max(1, min(T, anchors)));
if numel(anchors) < basis_count
    anchors = unique(round(linspace(1, T, basis_count + 1)));
    anchors = anchors(1:basis_count);
end

grid = (1:T)';
basis = zeros(T, numel(anchors));
for j = 1:numel(anchors)
    if j == 1
        left = anchors(j);
    else
        left = anchors(j - 1);
    end
    center = anchors(j);
    if j == numel(anchors)
        right = anchors(j);
    else
        right = anchors(j + 1);
    end

    for t = 1:T
        x = grid(t);
        if x < left || x > right
            continue;
        end
        if x <= center
            denom = max(center - left, 1);
            basis(t, j) = (x - left) / denom;
        else
            denom = max(right - center, 1);
            basis(t, j) = (right - x) / denom;
        end
        if x == center
            basis(t, j) = 1;
        end
    end
end
end

function active_periods = find_active_periods_local(vote_path, threshold_frac)
abs_vote = abs(vote_path(:));
if all(abs_vote == 0)
    active_periods = (1:numel(vote_path))';
    return;
end
threshold = threshold_frac * max(abs_vote);
active_periods = find(abs_vote >= threshold);
if isempty(active_periods)
    [~, idx] = max(abs_vote);
    active_periods = idx;
end
end

function metrics = read_summary_metrics_local(summary_csv_path)
metrics = struct('max_abs_vote', NaN, 'vote_l2', NaN, 'merit', NaN, 'max_abs_gap', NaN, 'residual_norm', NaN);
if ~isfile(summary_csv_path)
    return;
end
tbl = readtable(summary_csv_path, TextType='string');
if isempty(tbl)
    return;
end
row = tbl(1, :);
if ismember('max_abs_vote', tbl.Properties.VariableNames), metrics.max_abs_vote = row.max_abs_vote; end
if ismember('vote_l2', tbl.Properties.VariableNames), metrics.vote_l2 = row.vote_l2; end
if ismember('merit', tbl.Properties.VariableNames), metrics.merit = row.merit; end
if ismember('max_abs_gap', tbl.Properties.VariableNames), metrics.max_abs_gap = row.max_abs_gap; end
if ismember('residual_norm', tbl.Properties.VariableNames), metrics.residual_norm = row.residual_norm; end
end

function write_text_local(path_str, text_str)
fid = fopen(path_str, 'w');
if fid < 0
    error('Could not open file for writing: %s', path_str);
end
cleanup_obj = onCleanup(@() fclose(fid));
fprintf(fid, '%s', text_str);
end
