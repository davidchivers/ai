function write_transition_re_objective_tradeoff_report()
% Summarize the control-vs-challenger tradeoff from the completed
% candidate-selection and validation runs.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
candidate_results_path = fullfile(this_dir, 'transition_re_candidate_selection_results.mat');
validation_results_path = fullfile(this_dir, 'transition_re_validation_results.mat');
report_path = fullfile(this_dir, 'transition_re_objective_tradeoff_report.md');

if ~isfile(candidate_results_path)
    error('Candidate-selection results not found: %s', candidate_results_path);
end
if ~isfile(validation_results_path)
    error('Validation results not found: %s', validation_results_path);
end

candidate_data = load(candidate_results_path, 'results_table', 'detailed_results');
validation_data = load(validation_results_path, 'results_table');

control_name = "config11_global_control";
best_name = "aggressive_p2_b8_hybrid_relaxed";
control_idx = find(strcmp(string(candidate_data.results_table.case_name), control_name), 1);
best_idx = find(strcmp(string(candidate_data.results_table.case_name), best_name), 1);
if isempty(control_idx) || isempty(best_idx)
    error('Required comparison rows not found in %s', candidate_results_path);
end

control_row = candidate_data.results_table(control_idx, :);
best_row = candidate_data.results_table(best_idx, :);
control_detail = find_detail_by_case_name(candidate_data.detailed_results, control_name);
best_detail = find_detail_by_case_name(candidate_data.detailed_results, best_name);

validation_best_idx = find(strcmp(string(validation_data.results_table.case_name), "best_variant_validation"), 1);
validation_control_idx = find(strcmp(string(validation_data.results_table.case_name), "baseline_control_validation"), 1);
if isempty(validation_best_idx) || isempty(validation_control_idx)
    error('Validation comparison rows not found in %s', validation_results_path);
end
validation_best_row = validation_data.results_table(validation_best_idx, :);
validation_control_row = validation_data.results_table(validation_control_idx, :);

control_reason_counts = summarize_reason_counts(control_detail.selection_diagnostics);
best_reason_counts = summarize_reason_counts(best_detail.selection_diagnostics);

control_updates = string({control_detail.iteration_log.accepted_update});
best_updates = string({best_detail.iteration_log.accepted_update});

lines = strings(0, 1);
lines(end + 1) = "# Transition RE objective tradeoff report";
lines(end + 1) = "";
lines(end + 1) = "Generated: " + string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
lines(end + 1) = "";
lines(end + 1) = "## Recommendation";
lines(end + 1) = "";
lines(end + 1) = "- Keep `config11_global_control` as the canonical benchmark.";
lines(end + 1) = "- Treat `aggressive_p2_b8_hybrid_relaxed` as the challenger that reveals the tradeoff, not the new default.";
lines(end + 1) = "- Next search should optimize the worst-period / focus-region objective explicitly, because the challenger's wins are coming from the global residual rule rather than focus-region improvement.";
lines(end + 1) = "";
lines(end + 1) = "## Headline comparison";
lines(end + 1) = "";
lines(end + 1) = sprintf("- Control `%s`: residual norm %.12f, max gap %.12f, last nontrivial iteration %d, nontrivial update count %d.", ...
    control_name, control_row.residual_norm, control_row.max_abs_gap, control_row.last_nontrivial_iter, control_row.nontrivial_update_count);
lines(end + 1) = sprintf("- Challenger `%s`: residual norm %.12f, max gap %.12f, last nontrivial iteration %d, nontrivial update count %d.", ...
    best_name, best_row.residual_norm, best_row.max_abs_gap, best_row.last_nontrivial_iter, best_row.nontrivial_update_count);
lines(end + 1) = sprintf("- Tradeoff: challenger improves residual norm by %.12f and extends persistence by %d iteration, but worsens max gap by %.12f.", ...
    control_row.residual_norm - best_row.residual_norm, best_row.last_nontrivial_iter - control_row.last_nontrivial_iter, best_row.max_abs_gap - control_row.max_abs_gap);
lines(end + 1) = "";
lines(end + 1) = "## Why the challenger wins";
lines(end + 1) = "";
lines(end + 1) = sprintf("- Control accepted updates: `%s`.", strjoin(control_updates, "`, `"));
lines(end + 1) = sprintf("- Challenger accepted updates: `%s`.", strjoin(best_updates, "`, `"));
lines(end + 1) = "- The control's accepted moves concentrate on blocks `1-3` and `4-6`.";
lines(end + 1) = "- The challenger shifts accepted moves later in the path, first to `6-8` and then `5-7`.";
lines(end + 1) = sprintf("- Control decisive-candidate counts: focus-only winners %d, global-only winners %d, both %d.", ...
    control_reason_counts.focus_only_selected, control_reason_counts.global_only_selected, control_reason_counts.focus_and_global_selected);
lines(end + 1) = sprintf("- Challenger decisive-candidate counts: focus-only winners %d, global-only winners %d, both %d.", ...
    best_reason_counts.focus_only_selected, best_reason_counts.global_only_selected, best_reason_counts.focus_and_global_selected);
lines(end + 1) = "- In the challenger, every selected improvement came from the global residual/gap rule; there were no focus-only selected wins.";
lines(end + 1) = "";
lines(end + 1) = "## What changed economically";
lines(end + 1) = "";
lines(end + 1) = sprintf("- Control final prices: `%s`.", mat2str(control_detail.final_price_path', 6));
lines(end + 1) = sprintf("- Challenger final prices: `%s`.", mat2str(best_detail.final_price_path', 6));
lines(end + 1) = sprintf("- Control raw log-price residuals: `%s`.", mat2str(control_detail.log_price_residual_raw', 6));
lines(end + 1) = sprintf("- Challenger raw log-price residuals: `%s`.", mat2str(best_detail.log_price_residual_raw', 6));
lines(end + 1) = sprintf("- Control excess-demand path: `%s`.", mat2str(control_detail.excess_demand_guess_path', 6));
lines(end + 1) = sprintf("- Challenger excess-demand path: `%s`.", mat2str(best_detail.excess_demand_guess_path', 6));
lines(end + 1) = "- Interpretation: the challenger slightly redistributes the path, especially in later periods, but does not materially improve the peak problem around period `3`.";
lines(end + 1) = "";
lines(end + 1) = "## Validation";
lines(end + 1) = "";
lines(end + 1) = sprintf("- `baseline_control_validation`: residual norm %.12f, max gap %.12f, last nontrivial iteration %d.", ...
    validation_control_row.residual_norm, validation_control_row.max_abs_gap, validation_control_row.last_nontrivial_iter);
lines(end + 1) = sprintf("- `best_variant_validation`: residual norm %.12f, max gap %.12f, last nontrivial iteration %d.", ...
    validation_best_row.residual_norm, validation_best_row.max_abs_gap, validation_best_row.last_nontrivial_iter);
lines(end + 1) = "- The longer-horizon validation reproduces the same tradeoff instead of overturning it.";
lines(end + 1) = "";
lines(end + 1) = "## Next workflow";
lines(end + 1) = "";
lines(end + 1) = "- Run a narrow focus-objective follow-up around the control/challenger region.";
lines(end + 1) = "- Prioritize cases where candidate selection can win on the focus metric itself, not only on the global residual rule.";
lines(end + 1) = "- Keep the run bounded: a small case set, one summary CSV, one results MAT file, and one refreshed report.";
lines(end + 1) = "";

write_lines(report_path, lines);
fprintf('Wrote %s\n', report_path);
end

function counts = summarize_reason_counts(selection_diagnostics)
counts = struct( ...
    'focus_only_selected', 0, ...
    'global_only_selected', 0, ...
    'focus_and_global_selected', 0, ...
    'selected_total', 0);

for iter = 1:numel(selection_diagnostics)
    sd = selection_diagnostics{iter};
    if ~isstruct(sd) || ~isfield(sd, 'sequential') || isempty(sd.sequential)
        continue;
    end

    for pass = 1:numel(sd.sequential.passes)
        pe = sd.sequential.passes(pass).candidate_evaluations;
        selected_label = string(sd.sequential.passes(pass).selected_label);
        if selected_label == "current_path" || isempty(pe)
            continue;
        end

        match_idx = find(strcmp(string({pe.candidate_label}), selected_label), 1, 'last');
        if isempty(match_idx)
            continue;
        end

        counts.selected_total = counts.selected_total + 1;
        winner = pe(match_idx);
        if winner.wins_focus && winner.wins_global
            counts.focus_and_global_selected = counts.focus_and_global_selected + 1;
        elseif winner.wins_focus
            counts.focus_only_selected = counts.focus_only_selected + 1;
        elseif winner.wins_global
            counts.global_only_selected = counts.global_only_selected + 1;
        end
    end
end
end

function detail = find_detail_by_case_name(details, case_name)
detail = struct([]);
for i = 1:numel(details)
    if isstruct(details{i}) && isfield(details{i}, 'case_name') && string(details{i}.case_name) == case_name
        detail = details{i};
        return;
    end
end
error('Detailed result not found for case %s.', case_name);
end

function write_lines(pathstr, lines)
fid = fopen(pathstr, 'w');
if fid == -1
    error('Could not open report for writing: %s', pathstr);
end
cleaner = onCleanup(@() fclose(fid));
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines(i));
end
end
