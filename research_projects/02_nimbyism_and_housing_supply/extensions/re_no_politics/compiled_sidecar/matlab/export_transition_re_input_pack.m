function pack = export_transition_re_input_pack( ...
    output_dir, horizon, price_level, project_root, candidate_selection_mode, ...
    focus_gap_improvement_tol, focus_excess_improvement_tol, focus_residual_slack, ...
    transition_policy_mode, policy_reference_price, terminal_reference_mode, ...
    terminal_reference_price, policy_reference_mode, policy_reference_blend_weight, ...
    policy_reference_price_floor, policy_reference_price_cap, outer_iteration_mode, ...
    fixed_point_relaxation_weight, fixed_point_relaxation_space, fixed_point_price_min, fixed_point_price_max, ...
    solver_profile, initial_price_path, save_candidate_history, save_period_details, save_outer_iteration_paths)
% Export a bounded outer-RE NIMBY truth pack with a fixed terminal reference.

if nargin < 1 || isempty(output_dir)
    this_dir = fileparts(mfilename('fullpath'));
    output_dir = fullfile(fileparts(this_dir), 'truth', 'transition_re_t4_fixed_terminal');
end
if nargin < 2 || isempty(horizon)
    horizon = 4;
end
if nargin < 3 || isempty(price_level)
    price_level = 2.0;
end
if nargin < 4 || isempty(project_root)
    this_dir = fileparts(mfilename('fullpath'));
    sidecar_dir = fileparts(this_dir);
    extension_dir = fileparts(sidecar_dir);
    project_root = fileparts(fileparts(extension_dir));
end
if nargin < 5 || isempty(candidate_selection_mode)
    candidate_selection_mode = 'global';
end
if nargin < 6 || isempty(focus_gap_improvement_tol)
    focus_gap_improvement_tol = 1e-4;
end
if nargin < 7 || isempty(focus_excess_improvement_tol)
    focus_excess_improvement_tol = 1e-5;
end
if nargin < 8 || isempty(focus_residual_slack)
    focus_residual_slack = 2e-4;
end
if nargin < 9 || isempty(transition_policy_mode)
    transition_policy_mode = 'full_backward';
end
if nargin < 10 || isempty(policy_reference_price)
    policy_reference_price = price_level;
end
if nargin < 11 || isempty(terminal_reference_mode)
    terminal_reference_mode = 'fixed_price';
end
if nargin < 12 || isempty(terminal_reference_price)
    terminal_reference_price = price_level;
end
if nargin < 13 || isempty(policy_reference_mode)
    if strcmpi(transition_policy_mode, 'steady_state_fixed_price')
        policy_reference_mode = 'fixed_price';
    else
        policy_reference_mode = 'path_current_prices';
    end
end
if nargin < 14 || isempty(policy_reference_blend_weight)
    policy_reference_blend_weight = NaN;
end
if nargin < 15 || isempty(policy_reference_price_floor)
    policy_reference_price_floor = NaN;
end
if nargin < 16 || isempty(policy_reference_price_cap)
    policy_reference_price_cap = NaN;
end
if nargin < 17 || isempty(outer_iteration_mode)
    outer_iteration_mode = 'candidate_search';
end
if nargin < 18 || isempty(fixed_point_relaxation_weight)
    fixed_point_relaxation_weight = 0.40;
end
if nargin < 19 || isempty(fixed_point_relaxation_space)
    fixed_point_relaxation_space = 'level';
end
if nargin < 20 || isempty(fixed_point_price_min)
    fixed_point_price_min = 0.40;
end
if nargin < 21 || isempty(fixed_point_price_max)
    fixed_point_price_max = 5.00;
end
if nargin < 22 || isempty(solver_profile)
    solver_profile = 'bounded_candidate_search';
end
if nargin < 23
    initial_price_path = [];
end
if nargin < 24 || isempty(save_candidate_history)
    save_candidate_history = false;
end
if nargin < 25 || isempty(save_period_details)
    save_period_details = false;
end
if nargin < 26 || isempty(save_outer_iteration_paths)
    save_outer_iteration_paths = false;
end

export_transition_pass_input_pack( ...
    output_dir, horizon, price_level, project_root, transition_policy_mode, policy_reference_price, ...
    terminal_reference_mode, terminal_reference_price, policy_reference_mode, ...
    policy_reference_blend_weight, policy_reference_price_floor, policy_reference_price_cap, save_period_details, initial_price_path);

this_dir = fileparts(mfilename('fullpath'));
sidecar_dir = fileparts(this_dir);
extension_dir = fileparts(sidecar_dir);
addpath(extension_dir);

demographic_path = build_demographic_path_from_age_state_csv(project_root);
demographic_path.periods = demographic_path.periods(1:horizon);
demographic_path.years = demographic_path.years(1:horizon);
demographic_path.cohort_scale = demographic_path.cohort_scale(1:horizon);
demographic_path.cohort_scale_by_age = demographic_path.cohort_scale_by_age(1:horizon, :);
demographic_path.population_by_age = demographic_path.population_by_age(1:horizon, :);

params = build_transition_re_export_params( ...
    price_level, candidate_selection_mode, focus_gap_improvement_tol, ...
    focus_excess_improvement_tol, focus_residual_slack, solver_profile);
params.terminal_reference_mode = char(string(terminal_reference_mode));
params.terminal_reference_price = terminal_reference_price;
params.transition_policy_mode = char(string(transition_policy_mode));
params.policy_reference_mode = char(string(policy_reference_mode));
params.policy_reference_price = policy_reference_price;
params.policy_reference_blend_weight = policy_reference_blend_weight;
params.policy_reference_price_floor = policy_reference_price_floor;
params.policy_reference_price_cap = policy_reference_price_cap;

if ~isempty(outer_iteration_mode)
    params.outer_iteration_mode = char(string(outer_iteration_mode));
end
if ~isnan(fixed_point_relaxation_weight)
    params.fixed_point_relaxation_weight = fixed_point_relaxation_weight;
end
if ~isempty(fixed_point_relaxation_space)
    params.fixed_point_relaxation_space = char(string(fixed_point_relaxation_space));
end
if ~isnan(fixed_point_price_min)
    params.fixed_point_price_min = fixed_point_price_min;
end
if ~isnan(fixed_point_price_max)
    params.fixed_point_price_max = fixed_point_price_max;
end
params.save_candidate_history = logical(save_candidate_history);
params.save_period_details = logical(save_period_details);
params.save_outer_iteration_paths = logical(save_outer_iteration_paths);

if isempty(initial_price_path)
    price_path_guess = price_level .* ones(horizon, 1);
else
    price_path_guess = initial_price_path(:);
    if numel(price_path_guess) ~= horizon
        error('initial_price_path length must equal horizon.');
    end
end

results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);

write_named_scalars(fullfile(output_dir, 're_params_scalars.csv'), {
    'max_iter', params.max_iter;
    'tol', params.tol;
    'damping', params.damping;
    'max_update_frac', params.max_update_frac;
    'smoothing_weight', params.smoothing_weight;
    'terminal_anchor_weight', params.terminal_anchor_weight;
    'fixed_point_relaxation_weight', params.fixed_point_relaxation_weight;
    'fixed_point_price_min', params.fixed_point_price_min;
    'fixed_point_price_max', params.fixed_point_price_max;
    'targeted_correction_weight', params.targeted_correction_weight;
    'max_targeted_periods', params.max_targeted_periods;
    'target_block_half_width', params.target_block_half_width;
    'sequential_block_size', params.sequential_block_size;
    'block_sweep_passes', params.block_sweep_passes;
    'max_blocks_per_pass', params.max_blocks_per_pass;
    'greedy_block_accept', double(params.greedy_block_accept);
    'candidate_improvement_tol', params.candidate_improvement_tol;
    'candidate_gap_improvement_tol', params.candidate_gap_improvement_tol;
    'candidate_residual_slack', params.candidate_residual_slack;
    'focus_gap_improvement_tol', params.focus_gap_improvement_tol;
    'focus_excess_improvement_tol', params.focus_excess_improvement_tol;
    'focus_residual_slack', params.focus_residual_slack;
    'sequential_return_endpoint', double(params.sequential_return_endpoint);
    'save_candidate_history', double(params.save_candidate_history);
    'save_period_details', double(params.save_period_details);
    'save_outer_iteration_paths', double(params.save_outer_iteration_paths)});

write_named_strings(fullfile(output_dir, 're_params_strings.csv'), {
    'candidate_selection_mode', params.candidate_selection_mode;
    'update_scheme', params.update_scheme;
    'outer_iteration_mode', params.outer_iteration_mode;
    'fixed_point_relaxation_space', params.fixed_point_relaxation_space});

writematrix(params.line_search_scales(:), fullfile(output_dir, 'line_search_scales.csv'));
writematrix(price_path_guess(:), fullfile(output_dir, 're_initial_price_path.csv'));
writematrix(results.final_price_path(:), fullfile(output_dir, 'matlab_re_final_price_path.csv'));
writematrix(results.implied_price_path(:), fullfile(output_dir, 'matlab_re_implied_price_path.csv'));
writematrix(results.Hdemand_path(:), fullfile(output_dir, 'matlab_re_Hdemand_path.csv'));
writematrix(results.Hsupply_path(:), fullfile(output_dir, 'matlab_re_Hsupply_path.csv'));
writematrix(results.excess_demand_path(:), fullfile(output_dir, 'matlab_re_excess_demand_path.csv'));
writematrix(results.log_price_residual_raw(:), fullfile(output_dir, 'matlab_re_log_price_residual_raw.csv'));
if params.save_period_details
    writematrix(pack_density_by_period_age(results.density_by_period_age), fullfile(output_dir, 'matlab_re_density_by_period_age.csv'));
end

iter_table = struct2table(results.iteration_log);
writetable(iter_table, fullfile(output_dir, 'matlab_re_iteration_log.csv'));

if params.save_outer_iteration_paths
    writematrix(results.iteration_current_price_paths, fullfile(output_dir, 'matlab_re_iteration_current_price_paths.csv'));
    writematrix(results.iteration_base_implied_price_paths, fullfile(output_dir, 'matlab_re_iteration_implied_price_paths.csv'));
    writematrix(results.iteration_selected_price_paths, fullfile(output_dir, 'matlab_re_iteration_selected_price_paths.csv'));
end

if params.save_candidate_history
    write_selection_diagnostics_tables(output_dir, results.selection_diagnostics);
end

write_named_scalars(fullfile(output_dir, 'matlab_re_summary.csv'), {
    'converged', double(results.converged);
    'iterations', results.iterations;
    'final_max_abs_gap', results.update_diagnostics.max_abs_gap;
    'final_residual_norm', results.iteration_log(end).residual_norm});

save(fullfile(output_dir, 'matlab_re_truth.mat'), 'results', 'params', 'price_path_guess', 'demographic_path');

pack = struct();
pack.output_dir = output_dir;
pack.results = results;
pack.params = params;
end

function write_named_scalars(path, rows)
writetable(cell2table(rows, 'VariableNames', {'name', 'value'}), path);
end

function write_named_strings(path, rows)
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
first = density_by_period_age{1, 1};
[I, J, K] = size(first);
packed = zeros(I * J * K * age_n * T, 1);
for t = 1:T
    for age_idx = 1:age_n
        offset = (t - 1) * age_n * I * J * K + (age_idx - 1) * I * J * K;
        packed(offset + (1:(I * J * K))) = density_by_period_age{t, age_idx}(:);
    end
end
end

function params = build_transition_re_export_params( ...
    price_level, candidate_selection_mode, focus_gap_improvement_tol, ...
    focus_excess_improvement_tol, focus_residual_slack, solver_profile)
params = struct();
params.rbPos = 0.03;
params.supply_params = struct('eta_s', 1.0);
params.candidate_selection_mode = char(string(candidate_selection_mode));
params.focus_gap_improvement_tol = focus_gap_improvement_tol;
params.focus_excess_improvement_tol = focus_excess_improvement_tol;
params.focus_residual_slack = focus_residual_slack;
params.sequential_return_endpoint = false;
params.save_candidate_history = false;
params.save_period_details = false;

profile = lower(string(solver_profile));
switch profile
    case "frontier_fertility_style"
        params.max_iter = 25;
        params.tol = 1e-4;
        params.damping = 0.25;
        params.max_update_frac = 0.10;
        params.smoothing_weight = 5.00;
        params.terminal_anchor_weight = 0.50;
        params.targeted_correction_weight = 0.35;
        params.max_targeted_periods = 3;
        params.target_block_half_width = 1;
        params.line_search_scales = [0.01, 0.02, 0.05];
        params.update_scheme = 'sequential_blocks';
        params.outer_iteration_mode = 'fertility_style';
        params.fixed_point_relaxation_weight = 0.10;
        params.fixed_point_relaxation_space = 'log';
        params.fixed_point_price_min = 0.40;
        params.fixed_point_price_max = 5.00;
        params.sequential_block_size = 3;
        params.block_sweep_passes = 2;
        params.max_blocks_per_pass = 4;
        params.greedy_block_accept = true;
        params.candidate_improvement_tol = 1e-6;
        params.candidate_gap_improvement_tol = 1e-6;
        params.candidate_residual_slack = 5e-5;
    case "bounded_candidate_search"
        params.max_iter = 3;
        params.tol = 1e-3;
        params.damping = 0.25;
        params.max_update_frac = 0.10;
        params.smoothing_weight = 5.00;
        params.terminal_anchor_weight = 0.50;
        params.targeted_correction_weight = 0.35;
        params.max_targeted_periods = 3;
        params.target_block_half_width = 1;
        params.line_search_scales = [0.01, 0.02, 0.05, 0.10];
        params.update_scheme = 'sequential_blocks';
        params.outer_iteration_mode = 'candidate_search';
        params.fixed_point_relaxation_weight = 0.40;
        params.fixed_point_relaxation_space = 'level';
        params.fixed_point_price_min = 0.40;
        params.fixed_point_price_max = 5.00;
        params.sequential_block_size = 3;
        params.block_sweep_passes = 2;
        params.max_blocks_per_pass = 4;
        params.greedy_block_accept = true;
        params.candidate_improvement_tol = 1e-6;
        params.candidate_gap_improvement_tol = 1e-6;
        params.candidate_residual_slack = 5e-5;
    otherwise
        error('Unsupported solver_profile: %s', solver_profile);
end
params.terminal_reference_mode = 'fixed_price';
params.terminal_reference_price = price_level;
params.transition_policy_mode = 'full_backward';
params.policy_reference_mode = 'path_current_prices';
params.policy_reference_price = price_level;
params.policy_reference_blend_weight = NaN;
params.policy_reference_price_floor = NaN;
params.policy_reference_price_cap = NaN;
end
