function results = audit_original_5yr_political_permit_lumpiness_smoke(seed_k, run_tag)
% Smoke-test lumpy permit/supply paths around a corrected smooth seed.
%
% In the current transition code, "permits" enter as a log supply-wedge path
% that scales the housing stock. This diagnostic holds the price seed fixed,
% replaces the continuous wedge path with rounded/blocky alternatives, and
% evaluates the resulting political vote and housing-clearing gaps.

if nargin < 1 || isempty(seed_k)
    seed_k = 8;
end
if nargin < 2 || isempty(run_tag)
    run_tag = sprintf('permit_lumpiness_smoke_k%d', seed_k);
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(this_dir);

addpath(this_dir);
addpath(fullfile(project_root, 'code', 'steadystate'));
addpath(fullfile(project_root, 'extensions', 're_no_politics'));

seed_root = fullfile(this_dir, 'truth', 'joint_supply_wedge', 'local_corrected_s020_flat_k4_10_i1');
[seed_price_csv, seed_wedge_csv] = find_seed_paths_local(seed_root, seed_k);

seed_price = readmatrix(seed_price_csv);
seed_wedge = readmatrix(seed_wedge_csv);
seed_price = seed_price(:);
seed_wedge = seed_wedge(:);
seed_k = min(numel(seed_price), numel(seed_wedge));
seed_price = seed_price(1:seed_k);
seed_wedge = seed_wedge(1:seed_k);

safe_tag = regexprep(lower(char(string(run_tag))), '[^a-z0-9_]+', '_');
output_dir = fullfile(this_dir, 'truth', 'permit_lumpiness_smoke', safe_tag);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

case_specs = build_case_specs_local();
summary_rows = initialize_rows_local();
case_results = cell(numel(case_specs), 1);

for i_case = 1:numel(case_specs)
    spec = case_specs(i_case);
    case_label = char(spec.label);
    fprintf('Permit lumpiness smoke: %s\n', case_label);
    drawnow;

    case_dir = fullfile(output_dir, case_label);
    if ~exist(case_dir, 'dir')
        mkdir(case_dir);
    end

    case_wedge = transform_wedge_local(seed_wedge, spec);
    price_csv = fullfile(case_dir, 'seed_price_path.csv');
    wedge_csv = fullfile(case_dir, 'seed_wedge_path.csv');
    writematrix(seed_price, price_csv);
    writematrix(case_wedge, wedge_csv);

    case_run_tag = sprintf('%s_%s', safe_tag, case_label);
    try
        [case_summary, case_result] = run_original_5yr_transition_joint_supply_wedge_continuation( ...
            seed_k, ...
            1, ...
            seed_k, ...
            price_csv, ...
            case_run_tag, ...
            'historical_1950', ...
            1e-2, ...
            1e-3, ...
            1.0, ...
            0.08, ...
            0.65, ...
            -0.05, ...
            0.05, ...
            seed_k, ...
            4, ...
            'smooth_tanh', ...
            0.20, ...
            wedge_csv, ...
            0, ...
            'stage_init_only', ...
            seed_k);

        case_results{i_case} = case_result;
        summary_rows = append_success_row_local(summary_rows, spec, seed_wedge, case_wedge, case_summary);
    catch err
        warning('permit_lumpiness_smoke:case_failed', ...
            'Case %s failed: %s', case_label, err.message);
        summary_rows = append_failure_row_local(summary_rows, spec, seed_wedge, case_wedge, err);
    end
end

summary = struct2table(summary_rows);
summary_path = fullfile(output_dir, sprintf('%s_summary.csv', safe_tag));
writetable(summary, summary_path);

results = struct();
results.seed_k = seed_k;
results.seed_price_csv = seed_price_csv;
results.seed_wedge_csv = seed_wedge_csv;
results.seed_price = seed_price;
results.seed_wedge = seed_wedge;
results.case_specs = case_specs;
results.case_results = case_results;
results.summary = summary;
results.output_dir = output_dir;
results.summary_path = summary_path;

save(fullfile(output_dir, sprintf('%s_results.mat', safe_tag)), 'results', '-v7.3');

disp('Permit lumpiness smoke complete.')
disp(summary(:, {'case_label', 'status', 'unique_wedge_count', ...
    'max_abs_wedge', 'final_max_abs_vote', 'final_max_abs_gap', 'final_merit'}));
end

function [seed_price_csv, seed_wedge_csv] = find_seed_paths_local(seed_root, seed_k)
seed_dir = fullfile(seed_root, sprintf('k%02d', seed_k));
price_candidates = dir(fullfile(seed_dir, '*_final_price_path.csv'));
wedge_candidates = dir(fullfile(seed_dir, '*_final_wedge_path.csv'));
if isempty(price_candidates) || isempty(wedge_candidates)
    error('No corrected seed price/wedge paths found for k=%d under %s', seed_k, seed_root);
end
seed_price_csv = fullfile(seed_dir, price_candidates(1).name);
seed_wedge_csv = fullfile(seed_dir, wedge_candidates(1).name);
end

function specs = build_case_specs_local()
specs = repmat(struct( ...
    'label', "", ...
    'mode', "", ...
    'step', NaN, ...
    'block_size', NaN, ...
    'deadband', NaN), 6, 1);

specs(1) = struct('label', "continuous_seed", 'mode', "identity", 'step', NaN, 'block_size', NaN, 'deadband', NaN);
specs(2) = struct('label', "round_005pp", 'mode', "round", 'step', 0.005, 'block_size', NaN, 'deadband', 0);
specs(3) = struct('label', "round_010pp", 'mode', "round", 'step', 0.010, 'block_size', NaN, 'deadband', 0);
specs(4) = struct('label', "round_020pp", 'mode', "round", 'step', 0.020, 'block_size', NaN, 'deadband', 0);
specs(5) = struct('label', "binary_020pp", 'mode', "binary", 'step', 0.020, 'block_size', NaN, 'deadband', 0.010);
specs(6) = struct('label', "block2_round010pp", 'mode', "block_round", 'step', 0.010, 'block_size', 2, 'deadband', 0);
end

function wedge = transform_wedge_local(seed_wedge, spec)
seed_wedge = seed_wedge(:);
switch lower(char(spec.mode))
    case 'identity'
        wedge = seed_wedge;
    case 'round'
        wedge = round_with_deadband_local(seed_wedge, spec.step, spec.deadband);
    case 'binary'
        wedge = zeros(size(seed_wedge));
        active = abs(seed_wedge) >= spec.deadband;
        wedge(active) = spec.step .* sign(seed_wedge(active));
    case 'block_round'
        wedge = seed_wedge;
        block_size = max(1, round(spec.block_size));
        for left = 1:block_size:numel(seed_wedge)
            right = min(numel(seed_wedge), left + block_size - 1);
            wedge(left:right) = mean(seed_wedge(left:right));
        end
        wedge = round_with_deadband_local(wedge, spec.step, spec.deadband);
    otherwise
        error('Unknown permit lumpiness mode: %s', spec.mode);
end
wedge = min(max(wedge, -0.05), 0.05);
end

function rounded = round_with_deadband_local(path, step, deadband)
rounded = step .* round(path ./ step);
if ~isnan(deadband) && deadband > 0
    rounded(abs(path) < deadband) = 0;
end
end

function rows = initialize_rows_local()
rows = struct( ...
    'case_label', string.empty(0, 1), ...
    'status', string.empty(0, 1), ...
    'error_message', string.empty(0, 1), ...
    'mode', string.empty(0, 1), ...
    'step', [], ...
    'block_size', [], ...
    'deadband', [], ...
    'max_abs_wedge', [], ...
    'mean_abs_wedge', [], ...
    'unique_wedge_count', [], ...
    'wedge_l2_distance_from_seed', [], ...
    'final_max_abs_vote', [], ...
    'final_reduced_vote_l2', [], ...
    'final_max_abs_gap', [], ...
    'final_residual_norm', [], ...
    'final_merit', []);
end

function rows = append_success_row_local(rows, spec, seed_wedge, case_wedge, case_summary)
row = case_summary(1, :);
rows = append_common_row_local(rows, spec, "ok", "", seed_wedge, case_wedge, ...
    row.final_max_abs_vote, row.final_reduced_vote_l2, row.final_max_abs_gap, ...
    NaN, row.final_merit);
end

function rows = append_failure_row_local(rows, spec, seed_wedge, case_wedge, err)
rows = append_common_row_local(rows, spec, "failed", string(err.message), ...
    seed_wedge, case_wedge, NaN, NaN, NaN, NaN, NaN);
end

function rows = append_common_row_local(rows, spec, status, error_message, seed_wedge, case_wedge, ...
    final_max_abs_vote, final_reduced_vote_l2, final_max_abs_gap, final_residual_norm, final_merit)
rows.case_label(end + 1, 1) = string(spec.label);
rows.status(end + 1, 1) = string(status);
rows.error_message(end + 1, 1) = string(error_message);
rows.mode(end + 1, 1) = string(spec.mode);
rows.step(end + 1, 1) = spec.step;
rows.block_size(end + 1, 1) = spec.block_size;
rows.deadband(end + 1, 1) = spec.deadband;
rows.max_abs_wedge(end + 1, 1) = max(abs(case_wedge));
rows.mean_abs_wedge(end + 1, 1) = mean(abs(case_wedge));
rows.unique_wedge_count(end + 1, 1) = numel(unique(case_wedge));
rows.wedge_l2_distance_from_seed(end + 1, 1) = norm(case_wedge(:) - seed_wedge(:), 2);
rows.final_max_abs_vote(end + 1, 1) = final_max_abs_vote;
rows.final_reduced_vote_l2(end + 1, 1) = final_reduced_vote_l2;
rows.final_max_abs_gap(end + 1, 1) = final_max_abs_gap;
rows.final_residual_norm(end + 1, 1) = final_residual_norm;
rows.final_merit(end + 1, 1) = final_merit;
end
