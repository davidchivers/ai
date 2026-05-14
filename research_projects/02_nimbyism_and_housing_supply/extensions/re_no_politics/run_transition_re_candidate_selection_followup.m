function results_table = run_transition_re_candidate_selection_followup()
% Narrow follow-up around config 11 and aggressive_p2_b8, targeting
% candidate-selection rules rather than broader damping/pass sweeps.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(fileparts(this_dir));
baseline_dir = fullfile(project_root, 'code', 'steadystate');
summary_path = fullfile(this_dir, 'transition_re_candidate_selection_summary.csv');
results_path = fullfile(this_dir, 'transition_re_candidate_selection_results.mat');
live_summary_path = fullfile(this_dir, 'transition_re_candidate_selection_summary_live.csv');
live_results_path = fullfile(this_dir, 'transition_re_candidate_selection_results_live.mat');

addpath(baseline_dir);
addpath(this_dir);

cases = build_cases();
raw_results = initialize_raw_results(cases);
detailed_results = cell(numel(cases), 1);

if isfile(live_results_path)
    resume_data = load(live_results_path, 'raw_results', 'cases', 'detailed_results');
    if isfield(resume_data, 'raw_results') && isfield(resume_data, 'cases') && ...
            numel(resume_data.raw_results) == numel(cases) && isequaln(resume_data.cases, cases)
        raw_results = resume_data.raw_results;
        if isfield(resume_data, 'detailed_results') && numel(resume_data.detailed_results) == numel(cases)
            detailed_results = resume_data.detailed_results;
        end
        completed_count = sum(arrayfun(@(s) string(s.status) ~= "pending", raw_results));
        fprintf('Resuming candidate-selection checkpoint: %d / %d cases already have results.\n', ...
            completed_count, numel(cases));
    else
        fprintf('Ignoring incompatible candidate-selection checkpoint and starting fresh.\n');
    end
end

demographic_path = build_demographic_path_from_age_state_csv(project_root);
price_path_guess = 2.0 .* ones(numel(demographic_path.periods), 1);

fprintf('=== Transition RE Candidate-Selection Follow-Up ===\n');
fprintf('Cases: %d\n', numel(cases));

for i = 1:numel(cases)
    if string(raw_results(i).status) ~= "pending"
        fprintf('\nCase %d / %d already completed with status %s, skipping.\n', ...
            i, numel(cases), string(raw_results(i).status));
        continue;
    end

    case_info = cases(i);
    params = build_params(case_info);

    tic;
    try
        fprintf('\nCase %d / %d\n', i, numel(cases));
        fprintf('  name = %s\n', case_info.case_name);
        fprintf('  profile = %s, mode = %s, greedy = %d\n', ...
            case_info.base_profile, string(case_info.candidate_selection_mode), case_info.greedy_block_accept);
        fprintf('  residual slack = %.6g, focus slack = %.6g\n', ...
            case_info.candidate_residual_slack, case_info.focus_residual_slack);

        results = solve_transition_re_no_politics(price_path_guess, demographic_path, params);

        accepted_updates = string({results.iteration_log.accepted_update});
        nontrivial_mask = accepted_updates ~= "current_path";
        nontrivial_count = sum(nontrivial_mask);
        if any(nontrivial_mask)
            last_nontrivial_iter = find(nontrivial_mask, 1, 'last');
        else
            last_nontrivial_iter = 0;
        end

        raw_results(i).case_id = i;
        raw_results(i).case_name = string(case_info.case_name);
        raw_results(i).base_profile = string(case_info.base_profile);
        raw_results(i).status = "ok";
        raw_results(i).max_iter = params.max_iter;
        raw_results(i).iterations_completed = results.iterations;
        raw_results(i).converged = results.converged;
        raw_results(i).residual_norm = results.iteration_log(end).residual_norm;
        raw_results(i).max_abs_gap = results.iteration_log(end).max_abs_gap;
        raw_results(i).max_abs_update = results.iteration_log(end).max_abs_update;
        raw_results(i).accepted_update = string(results.iteration_log(end).accepted_update);
        raw_results(i).worst_gap_period = results.iteration_log(end).worst_gap_period;
        raw_results(i).worst_excess_demand_period = results.iteration_log(end).worst_excess_demand_period;
        raw_results(i).worst_excess_demand = results.iteration_log(end).worst_excess_demand;
        raw_results(i).price_min = min(results.final_price_path);
        raw_results(i).price_max = max(results.final_price_path);
        raw_results(i).nontrivial_update_count = nontrivial_count;
        raw_results(i).last_nontrivial_iter = last_nontrivial_iter;
        detailed_results{i} = compact_result_snapshot(results, case_info);
    catch err
        raw_results(i).case_id = i;
        raw_results(i).case_name = string(case_info.case_name);
        raw_results(i).base_profile = string(case_info.base_profile);
        raw_results(i).status = "error";
        raw_results(i).max_iter = case_info.max_iter;
        raw_results(i).accepted_update = string(err.message);
        detailed_results{i} = struct([]);
    end

    raw_results(i).damping = params.damping;
    raw_results(i).smoothing_weight = params.smoothing_weight;
    raw_results(i).targeted_correction_weight = params.targeted_correction_weight;
    raw_results(i).line_search_scales = string(mat2str(params.line_search_scales));
    raw_results(i).block_sweep_passes = params.block_sweep_passes;
    raw_results(i).max_blocks_per_pass = params.max_blocks_per_pass;
    raw_results(i).candidate_selection_mode = string(params.candidate_selection_mode);
    raw_results(i).greedy_block_accept = params.greedy_block_accept;
    raw_results(i).candidate_residual_slack = params.candidate_residual_slack;
    raw_results(i).focus_residual_slack = params.focus_residual_slack;
    raw_results(i).elapsed_seconds = toc;

    results_table = build_results_table(raw_results);
    writetable(results_table, live_summary_path);
    save(live_results_path, 'results_table', 'raw_results', 'cases', 'detailed_results');
end

results_table = build_results_table(raw_results);
writetable(results_table, summary_path);
save(results_path, 'results_table', 'raw_results', 'cases', 'detailed_results');

if isfile(live_summary_path)
    delete(live_summary_path);
end
if isfile(live_results_path)
    delete(live_results_path);
end

fprintf('\nSaved %s\n', summary_path);
fprintf('Saved %s\n', results_path);
end

function params = build_params(case_info)
params = struct();
params.max_iter = case_info.max_iter;
params.tol = 1e-4;
params.damping = 0.15;
params.max_update_frac = 0.10;
params.smoothing_weight = 8.0;
params.terminal_anchor_weight = 0.50;
params.targeted_correction_weight = 0.20;
params.max_targeted_periods = 3;
params.target_block_half_width = 1;
params.terminal_price_rule = 'flat_tail';
params.update_scheme = 'sequential_blocks';
params.sequential_block_size = 3;
params.block_sweep_passes = case_info.block_sweep_passes;
params.max_blocks_per_pass = case_info.max_blocks_per_pass;
params.greedy_block_accept = case_info.greedy_block_accept;
params.candidate_improvement_tol = 1e-6;
params.candidate_gap_improvement_tol = 1e-6;
params.candidate_residual_slack = case_info.candidate_residual_slack;
params.candidate_selection_mode = case_info.candidate_selection_mode;
params.focus_gap_improvement_tol = 1e-4;
params.focus_excess_improvement_tol = 1e-5;
params.focus_residual_slack = case_info.focus_residual_slack;
params.line_search_scales = case_info.line_search_scales;
params.save_candidate_history = true;
end

function snapshot = compact_result_snapshot(results, case_info)
snapshot = struct();
snapshot.case_name = string(case_info.case_name);
snapshot.base_profile = string(case_info.base_profile);
snapshot.iteration_log = results.iteration_log;
snapshot.selection_diagnostics = results.selection_diagnostics;
snapshot.final_price_path = results.final_price_path;
snapshot.implied_price_path = results.implied_price_path;
snapshot.log_price_residual_raw = results.log_price_residual_raw;
snapshot.excess_demand_guess_path = results.excess_demand_guess_path;
snapshot.period_diagnostics = struct( ...
    'targeted_periods', results.period_diagnostics.targeted_periods, ...
    'targeted_blocks', results.period_diagnostics.targeted_blocks, ...
    'log_price_residual_raw', results.period_diagnostics.log_price_residual_raw, ...
    'excess_demand_guess_path', results.period_diagnostics.excess_demand_guess_path);
end

function cases = build_cases()
max_iter = 6;
cases = [ ...
    struct('case_name', "config11_global_control", 'base_profile', "config11_p2_b4", 'line_search_scales', [0.10 0.05 0.02 0.01], 'block_sweep_passes', 2, 'max_blocks_per_pass', 4, 'max_iter', max_iter, 'candidate_selection_mode', "global", 'greedy_block_accept', true, 'candidate_residual_slack', 5e-5, 'focus_residual_slack', 2e-4)
    struct('case_name', "config11_hybrid_focus", 'base_profile', "config11_p2_b4", 'line_search_scales', [0.10 0.05 0.02 0.01], 'block_sweep_passes', 2, 'max_blocks_per_pass', 4, 'max_iter', max_iter, 'candidate_selection_mode', "hybrid_focus", 'greedy_block_accept', true, 'candidate_residual_slack', 5e-5, 'focus_residual_slack', 2e-4)
    struct('case_name', "config11_focus_nongreedy", 'base_profile', "config11_p2_b4", 'line_search_scales', [0.10 0.05 0.02 0.01], 'block_sweep_passes', 2, 'max_blocks_per_pass', 4, 'max_iter', max_iter, 'candidate_selection_mode', "focus", 'greedy_block_accept', false, 'candidate_residual_slack', 5e-5, 'focus_residual_slack', 2e-4)
    struct('case_name', "config11_hybrid_relaxed", 'base_profile', "config11_p2_b4", 'line_search_scales', [0.10 0.05 0.02 0.01], 'block_sweep_passes', 2, 'max_blocks_per_pass', 4, 'max_iter', max_iter, 'candidate_selection_mode', "hybrid_focus", 'greedy_block_accept', false, 'candidate_residual_slack', 2e-4, 'focus_residual_slack', 5e-4)
    struct('case_name', "aggressive_p2_b8_global_control", 'base_profile', "aggressive_p2_b8", 'line_search_scales', [0.20 0.10 0.05 0.02], 'block_sweep_passes', 2, 'max_blocks_per_pass', 8, 'max_iter', max_iter, 'candidate_selection_mode', "global", 'greedy_block_accept', true, 'candidate_residual_slack', 5e-5, 'focus_residual_slack', 2e-4)
    struct('case_name', "aggressive_p2_b8_hybrid_focus", 'base_profile', "aggressive_p2_b8", 'line_search_scales', [0.20 0.10 0.05 0.02], 'block_sweep_passes', 2, 'max_blocks_per_pass', 8, 'max_iter', max_iter, 'candidate_selection_mode', "hybrid_focus", 'greedy_block_accept', true, 'candidate_residual_slack', 5e-5, 'focus_residual_slack', 2e-4)
    struct('case_name', "aggressive_p2_b8_focus_nongreedy", 'base_profile', "aggressive_p2_b8", 'line_search_scales', [0.20 0.10 0.05 0.02], 'block_sweep_passes', 2, 'max_blocks_per_pass', 8, 'max_iter', max_iter, 'candidate_selection_mode', "focus", 'greedy_block_accept', false, 'candidate_residual_slack', 5e-5, 'focus_residual_slack', 2e-4)
    struct('case_name', "aggressive_p2_b8_hybrid_relaxed", 'base_profile', "aggressive_p2_b8", 'line_search_scales', [0.20 0.10 0.05 0.02], 'block_sweep_passes', 2, 'max_blocks_per_pass', 8, 'max_iter', max_iter, 'candidate_selection_mode', "hybrid_focus", 'greedy_block_accept', false, 'candidate_residual_slack', 2e-4, 'focus_residual_slack', 5e-4)
    ];
end

function raw_results = initialize_raw_results(cases)
raw_results = repmat(struct( ...
    'case_id', NaN, ...
    'case_name', "", ...
    'base_profile', "", ...
    'status', "pending", ...
    'max_iter', NaN, ...
    'iterations_completed', NaN, ...
    'converged', false, ...
    'residual_norm', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_update', NaN, ...
    'accepted_update', "", ...
    'worst_gap_period', NaN, ...
    'worst_excess_demand_period', NaN, ...
    'worst_excess_demand', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'nontrivial_update_count', NaN, ...
    'last_nontrivial_iter', NaN, ...
    'damping', NaN, ...
    'smoothing_weight', NaN, ...
    'targeted_correction_weight', NaN, ...
    'line_search_scales', "", ...
    'block_sweep_passes', NaN, ...
    'max_blocks_per_pass', NaN, ...
    'candidate_selection_mode', "", ...
    'greedy_block_accept', false, ...
    'candidate_residual_slack', NaN, ...
    'focus_residual_slack', NaN, ...
    'elapsed_seconds', NaN), numel(cases), 1);
end

function results_table = build_results_table(raw_results)
results_table = struct2table(raw_results);
results_table = sortrows(results_table, ...
    {'status', 'residual_norm', 'max_abs_gap', 'last_nontrivial_iter', 'nontrivial_update_count', 'case_id'}, ...
    {'ascend', 'ascend', 'ascend', 'descend', 'descend', 'ascend'});
end
