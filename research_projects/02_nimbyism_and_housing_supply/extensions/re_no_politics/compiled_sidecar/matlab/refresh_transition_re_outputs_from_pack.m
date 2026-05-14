function results = refresh_transition_re_outputs_from_pack(pack_dir, project_root)
% Refresh only the MATLAB outer-RE truth outputs for an existing pack.

if nargin < 1 || isempty(pack_dir)
    this_dir = fileparts(mfilename('fullpath'));
    pack_dir = fullfile(fileparts(this_dir), 'truth', 'transition_re_t4_fixed_terminal');
end
if nargin < 2 || isempty(project_root)
    this_dir = fileparts(mfilename('fullpath'));
    sidecar_dir = fileparts(this_dir);
    extension_dir = fileparts(sidecar_dir);
    project_root = fileparts(fileparts(extension_dir));
end

this_dir = fileparts(mfilename('fullpath'));
sidecar_dir = fileparts(this_dir);
extension_dir = fileparts(sidecar_dir);
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(extension_dir);
addpath(baseline_dir);

re_scalars = read_named_scalar_csv(fullfile(pack_dir, 're_params_scalars.csv'));
re_strings = read_named_string_csv(fullfile(pack_dir, 're_params_strings.csv'));
meta_scalars = read_named_scalar_csv(fullfile(pack_dir, 'meta_scalars.csv'));
meta_strings = read_named_string_csv(fullfile(pack_dir, 'meta_strings.csv'));

price_path_guess = readmatrix(fullfile(pack_dir, 're_initial_price_path.csv'));
horizon = numel(price_path_guess);

demographic_path = build_demographic_path_from_age_state_csv(project_root);
demographic_path.periods = demographic_path.periods(1:horizon);
demographic_path.years = demographic_path.years(1:horizon);
demographic_path.cohort_scale = demographic_path.cohort_scale(1:horizon);
demographic_path.cohort_scale_by_age = demographic_path.cohort_scale_by_age(1:horizon, :);
demographic_path.population_by_age = demographic_path.population_by_age(1:horizon, :);

params = struct();
params.rbPos = get_scalar_with_default(meta_scalars, 'rb_pos', 0.03);
params.supply_params = struct();
params.supply_params.eta_s = get_scalar_with_default(meta_scalars, 'supply_eta_s', 1.0);

supply_hbar = decode_optional_scalar(get_scalar_with_default(meta_scalars, 'supply_Hbar', NaN));
if ~isnan(supply_hbar)
    params.supply_params.Hbar = supply_hbar;
end

supply_pbar = decode_optional_scalar(get_scalar_with_default(meta_scalars, 'supply_Pbar', NaN));
if ~isnan(supply_pbar)
    params.supply_params.Pbar = supply_pbar;
end

params.candidate_selection_mode = get_string_with_default(re_strings, 'candidate_selection_mode', 'global');
params.update_scheme = get_string_with_default(re_strings, 'update_scheme', 'sequential_blocks');
params.outer_iteration_mode = get_string_with_default(re_strings, 'outer_iteration_mode', 'candidate_search');
params.fixed_point_relaxation_space = get_string_with_default(re_strings, 'fixed_point_relaxation_space', 'level');

params.max_iter = round(get_scalar_with_default(re_scalars, 'max_iter', 3));
params.tol = get_scalar_with_default(re_scalars, 'tol', 1e-3);
params.damping = get_scalar_with_default(re_scalars, 'damping', 0.25);
params.max_update_frac = get_scalar_with_default(re_scalars, 'max_update_frac', 0.10);
params.smoothing_weight = get_scalar_with_default(re_scalars, 'smoothing_weight', 5.0);
params.terminal_anchor_weight = get_scalar_with_default(re_scalars, 'terminal_anchor_weight', 0.50);
params.fixed_point_relaxation_weight = get_scalar_with_default(re_scalars, 'fixed_point_relaxation_weight', 0.40);
params.fixed_point_price_min = get_scalar_with_default(re_scalars, 'fixed_point_price_min', 0.40);
params.fixed_point_price_max = get_scalar_with_default(re_scalars, 'fixed_point_price_max', 5.00);
params.targeted_correction_weight = get_scalar_with_default(re_scalars, 'targeted_correction_weight', 0.35);
params.max_targeted_periods = round(get_scalar_with_default(re_scalars, 'max_targeted_periods', 3));
params.target_block_half_width = round(get_scalar_with_default(re_scalars, 'target_block_half_width', 1));
params.sequential_block_size = round(get_scalar_with_default(re_scalars, 'sequential_block_size', 3));
params.block_sweep_passes = round(get_scalar_with_default(re_scalars, 'block_sweep_passes', 2));
params.max_blocks_per_pass = round(get_scalar_with_default(re_scalars, 'max_blocks_per_pass', 4));
params.greedy_block_accept = get_scalar_with_default(re_scalars, 'greedy_block_accept', 1) ~= 0;
params.candidate_improvement_tol = get_scalar_with_default(re_scalars, 'candidate_improvement_tol', 1e-6);
params.candidate_gap_improvement_tol = get_scalar_with_default(re_scalars, 'candidate_gap_improvement_tol', 1e-6);
params.candidate_residual_slack = get_scalar_with_default(re_scalars, 'candidate_residual_slack', 5e-5);
params.focus_gap_improvement_tol = get_scalar_with_default(re_scalars, 'focus_gap_improvement_tol', 1e-4);
params.focus_excess_improvement_tol = get_scalar_with_default(re_scalars, 'focus_excess_improvement_tol', 1e-5);
params.focus_residual_slack = get_scalar_with_default(re_scalars, 'focus_residual_slack', 2e-4);
params.sequential_return_endpoint = get_scalar_with_default(re_scalars, 'sequential_return_endpoint', 0) ~= 0;
params.save_candidate_history = get_scalar_with_default(re_scalars, 'save_candidate_history', 0) ~= 0;
params.save_period_details = get_scalar_with_default(re_scalars, 'save_period_details', 0) ~= 0;
params.save_outer_iteration_paths = get_scalar_with_default(re_scalars, 'save_outer_iteration_paths', 0) ~= 0;

line_search_path = fullfile(pack_dir, 'line_search_scales.csv');
if exist(line_search_path, 'file')
    params.line_search_scales = readmatrix(line_search_path)';
end

params.terminal_reference_mode = get_string_with_default(meta_strings, 'terminal_reference_mode', 'fixed_price');
params.transition_policy_mode = get_string_with_default(meta_strings, 'transition_policy_mode', 'full_backward');
params.policy_reference_mode = get_string_with_default(meta_strings, 'policy_reference_mode', 'path_current_prices');
params.terminal_reference_price = decode_optional_scalar(get_scalar_with_default(meta_scalars, 'terminal_reference_price', NaN));
params.policy_reference_price = decode_optional_scalar(get_scalar_with_default(meta_scalars, 'policy_reference_price', NaN));
params.policy_reference_blend_weight = decode_optional_scalar(get_scalar_with_default(meta_scalars, 'policy_reference_blend_weight', NaN));
params.policy_reference_price_floor = decode_optional_scalar(get_scalar_with_default(meta_scalars, 'policy_reference_price_floor', NaN));
params.policy_reference_price_cap = decode_optional_scalar(get_scalar_with_default(meta_scalars, 'policy_reference_price_cap', NaN));

results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);

writematrix(results.final_price_path(:), fullfile(pack_dir, 'matlab_re_final_price_path.csv'));
writematrix(results.implied_price_path(:), fullfile(pack_dir, 'matlab_re_implied_price_path.csv'));
writematrix(results.Hdemand_path(:), fullfile(pack_dir, 'matlab_re_Hdemand_path.csv'));
writematrix(results.Hsupply_path(:), fullfile(pack_dir, 'matlab_re_Hsupply_path.csv'));
writematrix(results.excess_demand_path(:), fullfile(pack_dir, 'matlab_re_excess_demand_path.csv'));
writematrix(results.log_price_residual_raw(:), fullfile(pack_dir, 'matlab_re_log_price_residual_raw.csv'));

iter_table = struct2table(results.iteration_log);
writetable(iter_table, fullfile(pack_dir, 'matlab_re_iteration_log.csv'));

if params.save_period_details && isfield(results, 'density_by_period_age')
    writematrix(pack_density_by_period_age(results.density_by_period_age), fullfile(pack_dir, 'matlab_re_density_by_period_age.csv'));
end
if params.save_outer_iteration_paths && isfield(results, 'iteration_current_price_paths')
    writematrix(results.iteration_current_price_paths, fullfile(pack_dir, 'matlab_re_iteration_current_price_paths.csv'));
    writematrix(results.iteration_base_implied_price_paths, fullfile(pack_dir, 'matlab_re_iteration_implied_price_paths.csv'));
    writematrix(results.iteration_selected_price_paths, fullfile(pack_dir, 'matlab_re_iteration_selected_price_paths.csv'));
end
if params.save_candidate_history && isfield(results, 'selection_diagnostics')
    write_selection_diagnostics_tables(pack_dir, results.selection_diagnostics);
end

write_named_scalars(fullfile(pack_dir, 'matlab_re_summary.csv'), {
    'converged', double(results.converged);
    'iterations', results.iterations;
    'final_max_abs_gap', results.update_diagnostics.max_abs_gap;
    'final_residual_norm', results.iteration_log(end).residual_norm});
end

function values = read_named_scalar_csv(path)
values = containers.Map('KeyType', 'char', 'ValueType', 'double');
rows = readcell(path, 'TextType', 'string');
for i = 2:size(rows, 1)
    values(char(string(rows{i, 1}))) = double(rows{i, 2});
end
end

function values = read_named_string_csv(path)
values = containers.Map('KeyType', 'char', 'ValueType', 'char');
rows = readcell(path, 'TextType', 'string');
for i = 2:size(rows, 1)
    values(char(string(rows{i, 1}))) = char(string(rows{i, 2}));
end
end

function value = get_scalar_with_default(values, key, default_value)
if isKey(values, key)
    value = values(key);
else
    value = default_value;
end
end

function value = get_string_with_default(values, key, default_value)
if isKey(values, key)
    value = values(key);
else
    value = default_value;
end
end

function value = decode_optional_scalar(value)
if ~isfinite(value) || value <= -9.87654321e307 / 2
    value = NaN;
end
end

function write_named_scalars(path, rows)
writetable(cell2table(rows, 'VariableNames', {'name', 'value'}), path);
end

function write_selection_diagnostics_tables(output_dir, selection_diagnostics)
iteration_rows = cell(0, 16);
pass_rows = cell(0, 12);
candidate_rows = cell(0, 26);

for iter_idx = 1:numel(selection_diagnostics)
    sd = selection_diagnostics{iter_idx};
    has_sequential = ~isempty(sd.sequential);
    if has_sequential
        sequential_selection_mode = string(sd.sequential.selection_mode);
        sequential_start_label = string(sd.sequential.start_label);
        sequential_final_label = string(sd.sequential.final_label);
        sequential_final_residual_norm = sd.sequential.final_residual_norm;
        sequential_final_max_abs_gap = sd.sequential.final_max_abs_gap;
    else
        sequential_selection_mode = "";
        sequential_start_label = "";
        sequential_final_label = "";
        sequential_final_residual_norm = NaN;
        sequential_final_max_abs_gap = NaN;
    end

    iteration_rows(end + 1, :) = { ...
        sd.iteration, ...
        string(sd.candidate_selection_mode), ...
        string(sd.current_label), ...
        sd.current_residual_norm, ...
        sd.current_max_abs_gap, ...
        serialize_int_list(sd.targeted_periods), ...
        serialize_block_list(sd.targeted_blocks), ...
        double(has_sequential), ...
        sequential_selection_mode, ...
        sequential_start_label, ...
        sequential_final_label, ...
        sequential_final_residual_norm, ...
        sequential_final_max_abs_gap, ...
        string(sd.final_selected_label), ...
        sd.final_residual_norm, ...
        sd.final_max_abs_gap};

    candidate_rows = append_candidate_rows(candidate_rows, sd.iteration, sd.initial_candidates);

    if has_sequential
        for pass_idx = 1:numel(sd.sequential.passes)
            pass_detail = sd.sequential.passes(pass_idx);
            pass_rows(end + 1, :) = { ...
                sd.iteration, ...
                pass_detail.pass, ...
                string(pass_detail.start_label), ...
                serialize_int_list(pass_detail.focus_periods), ...
                serialize_int_list(pass_detail.targeted_periods), ...
                serialize_block_list(pass_detail.targeted_blocks), ...
                serialize_int_list(pass_detail.block_starts), ...
                string(pass_detail.selected_label), ...
                pass_detail.selected_residual_norm, ...
                pass_detail.selected_max_abs_gap, ...
                double(pass_detail.accepted_in_pass), ...
                string(pass_detail.greedy_accept_label)};
            candidate_rows = append_candidate_rows(candidate_rows, sd.iteration, pass_detail.candidate_evaluations);
        end
    end
end

iteration_table = cell2table(iteration_rows, 'VariableNames', { ...
    'iteration', 'candidate_selection_mode', 'current_label', 'current_residual_norm', 'current_max_abs_gap', ...
    'targeted_periods', 'targeted_blocks', 'has_sequential', 'sequential_selection_mode', 'sequential_start_label', ...
    'sequential_final_label', 'sequential_final_residual_norm', 'sequential_final_max_abs_gap', ...
    'final_selected_label', 'final_residual_norm', 'final_max_abs_gap'});
pass_table = cell2table(pass_rows, 'VariableNames', { ...
    'iteration', 'pass', 'start_label', 'focus_periods', 'targeted_periods', 'targeted_blocks', 'block_starts', ...
    'selected_label', 'selected_residual_norm', 'selected_max_abs_gap', 'accepted_in_pass', 'greedy_accept_label'});
candidate_table = cell2table(candidate_rows, 'VariableNames', { ...
    'iteration', 'stage', 'pass', 'candidate_label', 'incumbent_label', 'block_start', 'block_stop', 'scale', ...
    'focus_periods', 'candidate_residual_norm', 'candidate_max_abs_gap', 'candidate_focus_gap', ...
    'candidate_focus_excess', 'incumbent_residual_norm', 'incumbent_max_abs_gap', 'incumbent_focus_gap', ...
    'incumbent_focus_excess', 'wins_focus', 'wins_global', 'wins_sequential', 'greedy_global', ...
    'greedy_sequential', 'selection_reason', 'greedy_reason', 'became_best', 'accepted_greedily'});

writetable(iteration_table, fullfile(output_dir, 'matlab_re_selection_iterations.csv'));
writetable(pass_table, fullfile(output_dir, 'matlab_re_selection_passes.csv'));
writetable(candidate_table, fullfile(output_dir, 'matlab_re_selection_candidates.csv'));
end

function rows = append_candidate_rows(rows, iteration, candidate_structs)
for idx = 1:numel(candidate_structs)
    entry = candidate_structs(idx);
    rows(end + 1, :) = { ...
        iteration, ...
        string(entry.stage), ...
        entry.pass, ...
        string(entry.candidate_label), ...
        string(entry.incumbent_label), ...
        entry.block_start, ...
        entry.block_stop, ...
        entry.scale, ...
        serialize_int_list(entry.focus_periods), ...
        entry.candidate_residual_norm, ...
        entry.candidate_max_abs_gap, ...
        entry.candidate_focus_gap, ...
        entry.candidate_focus_excess, ...
        entry.incumbent_residual_norm, ...
        entry.incumbent_max_abs_gap, ...
        entry.incumbent_focus_gap, ...
        entry.incumbent_focus_excess, ...
        double(entry.wins_focus), ...
        double(entry.wins_global), ...
        double(entry.wins_sequential), ...
        double(entry.greedy_global), ...
        double(entry.greedy_sequential), ...
        string(entry.selection_reason), ...
        string(entry.greedy_reason), ...
        double(entry.became_best), ...
        double(entry.accepted_greedily)};
end
end

function value = serialize_int_list(values)
if isempty(values)
    value = "";
    return;
end
value = join(string(values(:)'), ';');
value = value{1};
end

function value = serialize_block_list(blocks)
if isempty(blocks)
    value = "";
    return;
end
parts = strings(size(blocks, 1), 1);
for row = 1:size(blocks, 1)
    parts(row) = sprintf('%d-%d', blocks(row, 1), blocks(row, 2));
end
value = join(parts, ';');
value = value{1};
end

function packed = pack_density_by_period_age(density_by_period_age)
[T, age_n] = size(density_by_period_age);
sample = density_by_period_age{1, 1};
[I, J, K] = size(sample);
packed = zeros(T * age_n * I * J * K, 1);
cursor = 1;
for t = 1:T
    for age_idx = 1:age_n
        density = density_by_period_age{t, age_idx};
        block = density(:);
        packed(cursor:(cursor + numel(block) - 1)) = block;
        cursor = cursor + numel(block);
    end
end
end
