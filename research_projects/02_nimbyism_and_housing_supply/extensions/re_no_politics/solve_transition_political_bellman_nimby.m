function results = solve_transition_political_bellman_nimby(price_path_guess, demographic_path, params)
% Bounded political-Bellman transition wrapper for the NIMBY project.
%
% This uses the shared transition Bellman block plus the path-level
% political preference object to iterate directly on a political update
% rule, rather than treating politics only as a diagnostic layered on top
% of the housing-clearing update.

if nargin < 3 || isempty(params)
    params = struct();
end

if ~isfield(params, 'max_iter'), params.max_iter = 3; end
if ~isfield(params, 'tol_vote'), params.tol_vote = 1e-3; end
if ~isfield(params, 'political_target'), params.political_target = 'equal_weight_vote'; end
if ~isfield(params, 'price_update_mode'), params.price_update_mode = 'political_only'; end
if ~isfield(params, 'political_update_space'), params.political_update_space = 'log'; end
if ~isfield(params, 'political_update_rule'), params.political_update_rule = 'fixed_step'; end
if ~isfield(params, 'political_update_weight'), params.political_update_weight = 0.005; end
if ~isfield(params, 'max_update_frac'), params.max_update_frac = 0.02; end
if ~isfield(params, 'price_floor'), params.price_floor = 0.40; end
if ~isfield(params, 'price_cap'), params.price_cap = 5.00; end
if ~isfield(params, 'secant_damping'), params.secant_damping = 0.75; end
if ~isfield(params, 'secant_min_abs_slope'), params.secant_min_abs_slope = 1e-3; end
if ~isfield(params, 'outer_line_search_scales'), params.outer_line_search_scales = [1.00; 0.50; 0.25; 0.10; 0.05; 0.01]; end
if ~isfield(params, 'outer_line_search_tol'), params.outer_line_search_tol = 1e-4; end
if ~isfield(params, 'outer_gap_weight'), params.outer_gap_weight = 0.25; end
if ~isfield(params, 'outer_vote_guard_abs'), params.outer_vote_guard_abs = 1e-4; end
if ~isfield(params, 'outer_gap_guard_abs'), params.outer_gap_guard_abs = 1e-4; end
if ~isfield(params, 'allow_probe_accept'), params.allow_probe_accept = true; end
if ~isfield(params, 'pass_params') || isempty(params.pass_params), params.pass_params = struct(); end

validateattributes(price_path_guess, {'double'}, {'vector', 'nonempty', 'finite', 'real', 'positive'}, mfilename, 'price_path_guess');
validateattributes(params.max_iter, {'double'}, {'scalar', 'integer', '>=', 1}, mfilename, 'params.max_iter');
validateattributes(params.tol_vote, {'double'}, {'scalar', 'positive'}, mfilename, 'params.tol_vote');
validateattributes(params.political_update_weight, {'double'}, {'scalar', 'finite', 'real', '>=', 0}, mfilename, 'params.political_update_weight');
validateattributes(params.max_update_frac, {'double'}, {'scalar', 'finite', 'real', '>', 0, '<', 1}, mfilename, 'params.max_update_frac');
validateattributes(params.price_floor, {'double'}, {'scalar', 'finite', 'real', 'positive'}, mfilename, 'params.price_floor');
validateattributes(params.price_cap, {'double'}, {'scalar', 'finite', 'real', 'positive'}, mfilename, 'params.price_cap');
validateattributes(params.secant_damping, {'double'}, {'scalar', 'finite', 'real', '>', 0}, mfilename, 'params.secant_damping');
validateattributes(params.secant_min_abs_slope, {'double'}, {'scalar', 'finite', 'real', '>', 0}, mfilename, 'params.secant_min_abs_slope');
validateattributes(params.outer_line_search_scales, {'double'}, {'vector', 'nonempty', 'finite', 'real', '>', 0}, mfilename, 'params.outer_line_search_scales');
validateattributes(params.outer_line_search_tol, {'double'}, {'scalar', 'finite', 'real', '>=', 0}, mfilename, 'params.outer_line_search_tol');
validateattributes(params.outer_gap_weight, {'double'}, {'scalar', 'finite', 'real', '>=', 0}, mfilename, 'params.outer_gap_weight');
validateattributes(params.outer_vote_guard_abs, {'double'}, {'scalar', 'finite', 'real', '>=', 0}, mfilename, 'params.outer_vote_guard_abs');
validateattributes(params.outer_gap_guard_abs, {'double'}, {'scalar', 'finite', 'real', '>=', 0}, mfilename, 'params.outer_gap_guard_abs');
if params.price_cap <= params.price_floor
    error('params.price_cap must exceed params.price_floor.');
end

current_price_path = price_path_guess(:);
iteration_log = repmat(struct( ...
    'iteration', NaN, ...
    'political_target', "", ...
    'price_update_mode', "", ...
    'political_update_rule', "", ...
    'max_abs_vote', NaN, ...
    'vote_l2', NaN, ...
    'merit', NaN, ...
    'mean_vote', NaN, ...
    'max_abs_gap', NaN, ...
    'residual_norm', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN, ...
    'housing_anchor_min', NaN, ...
    'housing_anchor_max', NaN, ...
    'max_abs_political_step', NaN, ...
    'num_secant_periods', NaN, ...
    'accepted_step_scale', NaN, ...
    'accepted_update_mask', "", ...
    'line_search_used', false, ...
    'line_search_improved', false, ...
    'probe_accepted', false, ...
    'vote_path', [], ...
    'current_price_path', [], ...
    'updated_price_path', []), params.max_iter, 1);

last_pass_results = struct();
last_current_pass = struct();
last_vote_path = [];
last_anchor_path = [];
previous_price_path = [];
previous_vote_path = [];

for iter = 1:params.max_iter
    pass_params = build_pass_params_local(params.pass_params);
    solve_results = solve_transition_re_no_politics(current_price_path, demographic_path, pass_params);
    current_pass = solve_results.current_path_pass;
    [vote_path, political_target_label] = extract_political_target_local(current_pass, params.political_target);
    anchor_path = choose_anchor_path_local(current_price_path, solve_results.updated_price_path(:), params.price_update_mode);
    current_metrics = summarize_metrics_local(current_pass, vote_path, params);
    if uses_line_search_local(params.political_update_rule)
        [updated_price_path, update_meta] = choose_political_price_update_with_line_search_local( ...
            anchor_path, current_price_path, vote_path, previous_price_path, previous_vote_path, params, demographic_path, current_metrics);
    else
        [updated_price_path, update_meta] = build_political_price_update_local( ...
            anchor_path, current_price_path, vote_path, previous_price_path, previous_vote_path, params);
    end

    iteration_log(iter).iteration = iter;
    iteration_log(iter).political_target = political_target_label;
    iteration_log(iter).price_update_mode = string(params.price_update_mode);
    iteration_log(iter).political_update_rule = string(update_meta.rule_used);
    iteration_log(iter).max_abs_vote = max(abs(vote_path));
    iteration_log(iter).vote_l2 = current_metrics.vote_l2;
    iteration_log(iter).merit = current_metrics.merit;
    iteration_log(iter).mean_vote = mean(vote_path);
    iteration_log(iter).max_abs_gap = current_pass.max_abs_gap;
    iteration_log(iter).residual_norm = current_pass.residual_norm;
    iteration_log(iter).price_min = min(updated_price_path);
    iteration_log(iter).price_max = max(updated_price_path);
    iteration_log(iter).housing_anchor_min = min(anchor_path);
    iteration_log(iter).housing_anchor_max = max(anchor_path);
    iteration_log(iter).max_abs_political_step = max(abs(updated_price_path - anchor_path));
    iteration_log(iter).num_secant_periods = update_meta.num_secant_periods;
    iteration_log(iter).accepted_step_scale = update_meta.accepted_step_scale;
    iteration_log(iter).accepted_update_mask = update_meta.accepted_update_mask;
    iteration_log(iter).line_search_used = update_meta.line_search_used;
    iteration_log(iter).line_search_improved = update_meta.line_search_improved;
    iteration_log(iter).probe_accepted = update_meta.probe_accepted;
    iteration_log(iter).vote_path = vote_path(:)';
    iteration_log(iter).current_price_path = current_price_path(:)';
    iteration_log(iter).updated_price_path = updated_price_path(:)';

    last_pass_results = solve_results;
    last_current_pass = current_pass;
    last_vote_path = vote_path;
    last_anchor_path = anchor_path;
    previous_price_path = current_price_path;
    previous_vote_path = vote_path;
    current_price_path = updated_price_path;

    if max(abs(vote_path)) < params.tol_vote
        break;
    end
    if update_meta.line_search_used && ~update_meta.line_search_improved && ~update_meta.probe_accepted
        break;
    end
end

completed = find(~isnan([iteration_log.iteration]), 1, 'last');

results = struct();
results.converged_political = max(abs(last_vote_path)) < params.tol_vote;
results.iterations = completed;
results.price_path_guess = price_path_guess(:);
results.final_vote_path = last_vote_path;
results.final_anchor_path = last_anchor_path;
results.political_target = string(political_target_label);
results.price_update_mode = string(params.price_update_mode);
results.political_update_rule = string(params.political_update_rule);
results.params = params;
results.demographic_path = demographic_path;
results.iteration_log = iteration_log(1:completed);
results.current_path_pass = last_current_pass;
results.last_transition_results = last_pass_results;
results.final_price_path = iteration_log(completed).current_price_path(:);
results.final_updated_price_path = current_price_path;
results.implied_price_path = last_current_pass.implied_price_path;
results.political = last_current_pass.sim.political;
results.policy_idx_b = last_current_pass.policy_idx_b;
results.policy_idx_a = last_current_pass.policy_idx_a;
results.valuefunctions = last_current_pass.valuefunctions;
results.message = 'Bounded political Bellman wrapper completed using the current-path political residual as the outer update target.';
end

function pass_params = build_pass_params_local(base_params)
pass_params = base_params;
pass_params.max_iter = 1;
pass_params.compute_political_path = true;
pass_params.save_current_path_pass = true;
pass_params.save_period_details = true;
if ~isfield(pass_params, 'transition_policy_mode') || isempty(pass_params.transition_policy_mode)
    pass_params.transition_policy_mode = 'full_backward';
end
if ~strcmpi(string(pass_params.transition_policy_mode), "full_backward")
    error('solve_transition_political_bellman_nimby currently requires pass_params.transition_policy_mode = ''full_backward''.');
end
end

function [vote_path, label] = extract_political_target_local(current_pass, target_name)
political = current_pass.sim.political;
target_name = lower(string(target_name));

switch target_name
    case "equal_weight_vote"
        vote_path = political.equal_weight_vote_path(:);
        label = "equal_weight_vote";
    case "weighted_vote"
        vote_path = political.weighted_vote_path(:);
        label = "weighted_vote";
    case "weighted_vote_share"
        vote_path = political.weighted_vote_share_path(:);
        label = "weighted_vote_share";
    otherwise
        error('Unknown political_target "%s".', target_name);
end
end

function anchor_path = choose_anchor_path_local(current_price_path, housing_candidate_price_path, update_mode)
update_mode = lower(string(update_mode));
switch update_mode
    case "political_only"
        anchor_path = current_price_path(:);
    case "joint_housing_political"
        anchor_path = housing_candidate_price_path(:);
    otherwise
        error('Unknown price_update_mode "%s".', update_mode);
end
end

function [updated_price_path, meta] = build_political_price_update_local(anchor_path, current_price_path, vote_path, previous_price_path, previous_vote_path, params, step_scale)
anchor_path = anchor_path(:);
current_price_path = current_price_path(:);
vote_path = vote_path(:);
if nargin < 7 || isempty(step_scale)
    step_scale = 1.0;
end

switch lower(string(params.political_update_space))
    case "log"
        [step_shift, meta] = build_log_shift_local(current_price_path, vote_path, previous_price_path, previous_vote_path, params, step_scale);
        max_log_step = log(1 + params.max_update_frac);
        step_shift = min(max(step_shift, -max_log_step), max_log_step);
        updated_price_path = anchor_path .* exp(step_shift);
    case "level"
        [step_shift, meta] = build_level_shift_local(current_price_path, vote_path, previous_price_path, previous_vote_path, params, step_scale);
        max_level_step = params.max_update_frac .* anchor_path;
        step_shift = min(max(step_shift, -max_level_step), max_level_step);
        updated_price_path = anchor_path + step_shift;
    otherwise
        error('Unknown political_update_space "%s".', params.political_update_space);
end

updated_price_path = min(max(updated_price_path, params.price_floor), params.price_cap);
end

function [log_shift, meta] = build_log_shift_local(current_price_path, vote_path, previous_price_path, previous_vote_path, params, step_scale)
fallback_shift = step_scale .* params.political_update_weight .* vote_path;
[secant_shift, valid_secant] = build_secant_shift_local(log(current_price_path), vote_path, ...
    log(previous_price_path), previous_vote_path, params);
secant_shift = step_scale .* secant_shift;

rule_name = lower(strip_line_search_suffix_local(string(params.political_update_rule)));
switch rule_name
    case "fixed_step"
        log_shift = fallback_shift;
        rule_used = "fixed_step";
    case "fixed_step_targeted"
        log_shift = fallback_shift;
        rule_used = "fixed_step_targeted";
    case "diagonal_secant"
        log_shift = fallback_shift;
        if any(valid_secant)
            log_shift(valid_secant) = secant_shift(valid_secant);
            rule_used = "diagonal_secant";
        else
            rule_used = "diagonal_secant_fallback";
        end
    case "diagonal_secant_targeted"
        log_shift = fallback_shift;
        if any(valid_secant)
            log_shift(valid_secant) = secant_shift(valid_secant);
            rule_used = "diagonal_secant_targeted";
        else
            rule_used = "diagonal_secant_targeted_fallback";
        end
    otherwise
        error('Unknown political_update_rule "%s".', rule_name);
end

meta = struct( ...
    'rule_used', string(rule_used), ...
    'num_secant_periods', sum(valid_secant), ...
    'accepted_step_scale', step_scale, ...
    'accepted_update_mask', "full_path", ...
    'line_search_used', false, ...
    'line_search_improved', true, ...
    'probe_accepted', false);
end

function [level_shift, meta] = build_level_shift_local(current_price_path, vote_path, previous_price_path, previous_vote_path, params, step_scale)
fallback_shift = step_scale .* params.political_update_weight .* vote_path;
[secant_shift, valid_secant] = build_secant_shift_local(current_price_path, vote_path, previous_price_path, previous_vote_path, params);
secant_shift = step_scale .* secant_shift;

rule_name = lower(strip_line_search_suffix_local(string(params.political_update_rule)));
switch rule_name
    case "fixed_step"
        level_shift = fallback_shift;
        rule_used = "fixed_step";
    case "fixed_step_targeted"
        level_shift = fallback_shift;
        rule_used = "fixed_step_targeted";
    case "diagonal_secant"
        level_shift = fallback_shift;
        if any(valid_secant)
            level_shift(valid_secant) = secant_shift(valid_secant);
            rule_used = "diagonal_secant";
        else
            rule_used = "diagonal_secant_fallback";
        end
    case "diagonal_secant_targeted"
        level_shift = fallback_shift;
        if any(valid_secant)
            level_shift(valid_secant) = secant_shift(valid_secant);
            rule_used = "diagonal_secant_targeted";
        else
            rule_used = "diagonal_secant_targeted_fallback";
        end
    otherwise
        error('Unknown political_update_rule "%s".', rule_name);
end

meta = struct( ...
    'rule_used', string(rule_used), ...
    'num_secant_periods', sum(valid_secant), ...
    'accepted_step_scale', step_scale, ...
    'accepted_update_mask', "full_path", ...
    'line_search_used', false, ...
    'line_search_improved', true, ...
    'probe_accepted', false);
end

function [secant_shift, valid_secant] = build_secant_shift_local(current_state, vote_path, previous_state, previous_vote_path, params)
secant_shift = nan(size(vote_path));
valid_secant = false(size(vote_path));

if isempty(previous_state) || isempty(previous_vote_path)
    return;
end

previous_state = previous_state(:);
previous_vote_path = previous_vote_path(:);
if numel(previous_state) ~= numel(current_state) || numel(previous_vote_path) ~= numel(vote_path)
    return;
end

delta_state = current_state - previous_state;
delta_vote = vote_path - previous_vote_path;
slope = delta_vote ./ delta_state;

valid_secant = isfinite(delta_state) & isfinite(delta_vote) & isfinite(slope) & ...
    abs(delta_state) > 1e-8 & abs(slope) >= params.secant_min_abs_slope;
secant_shift(valid_secant) = -params.secant_damping .* (vote_path(valid_secant) ./ slope(valid_secant));
valid_secant = valid_secant & isfinite(secant_shift);
end

function [updated_price_path, meta] = choose_political_price_update_with_line_search_local(anchor_path, current_price_path, vote_path, previous_price_path, previous_vote_path, params, demographic_path, current_metrics)
scales = unique(params.outer_line_search_scales(:)', 'stable');
if uses_targeted_line_search_local(params.political_update_rule)
    mask_specs = build_targeted_line_search_masks_local(vote_path, params.pass_params);
else
    mask_specs = struct('label', "full_path", 'mask', true(size(vote_path(:))));
end

best_metrics = current_metrics;
best_updated_price_path = current_price_path(:);
best_meta = struct( ...
    'rule_used', string(strip_line_search_suffix_local(string(params.political_update_rule))) + "_linesearch_reject", ...
    'num_secant_periods', 0, ...
    'accepted_step_scale', 0.0, ...
    'accepted_update_mask', "reject", ...
    'line_search_used', true, ...
    'line_search_improved', false, ...
    'probe_accepted', false);
best_probe_metrics = [];
best_probe_updated_price_path = current_price_path(:);
best_probe_meta = best_meta;
best_probe_step_norm = inf;

for scale_idx = 1:numel(scales)
    step_scale = scales(scale_idx);
    [full_candidate_price_path, candidate_meta] = build_political_price_update_local( ...
        anchor_path, current_price_path, vote_path, previous_price_path, previous_vote_path, params, step_scale);
    for mask_idx = 1:numel(mask_specs)
        candidate_price_path = apply_update_mask_local(current_price_path, full_candidate_price_path, mask_specs(mask_idx).mask);
        if max(abs(candidate_price_path - current_price_path(:))) < 1e-12
            continue;
        end

        pass_params = build_pass_params_local(params.pass_params);
        candidate_results = solve_transition_re_no_politics(candidate_price_path, demographic_path, pass_params);
        candidate_pass = candidate_results.current_path_pass;
        [candidate_vote_path, ~] = extract_political_target_local(candidate_pass, params.political_target);
        candidate_metrics = summarize_metrics_local(candidate_pass, candidate_vote_path, params);
        [accept_candidate, probe_ok] = evaluate_candidate_acceptance_local(candidate_metrics, current_metrics, params);
        step_norm = max(abs(candidate_price_path - current_price_path(:)));

        if accept_candidate && is_candidate_metrics_better_local(candidate_metrics, best_metrics, params)
            best_metrics = candidate_metrics;
            best_updated_price_path = candidate_price_path;
            best_meta = candidate_meta;
            best_meta.rule_used = string(best_meta.rule_used) + "_linesearch";
            best_meta.accepted_step_scale = step_scale;
            best_meta.accepted_update_mask = string(mask_specs(mask_idx).label);
            best_meta.line_search_used = true;
            best_meta.line_search_improved = true;
            best_meta.probe_accepted = false;
        elseif probe_ok && ...
                (isempty(best_probe_metrics) || ...
                 step_norm < (best_probe_step_norm - 1e-12) || ...
                 (abs(step_norm - best_probe_step_norm) <= 1e-12 && ...
                  is_candidate_metrics_better_local(candidate_metrics, best_probe_metrics, params)))
            best_probe_metrics = candidate_metrics;
            best_probe_updated_price_path = candidate_price_path;
            best_probe_meta = candidate_meta;
            best_probe_meta.rule_used = string(best_probe_meta.rule_used) + "_linesearch_probe";
            best_probe_meta.accepted_step_scale = step_scale;
            best_probe_meta.accepted_update_mask = string(mask_specs(mask_idx).label);
            best_probe_meta.line_search_used = true;
            best_probe_meta.line_search_improved = false;
            best_probe_meta.probe_accepted = true;
            best_probe_step_norm = step_norm;
        end
    end
end

if best_meta.line_search_improved
    updated_price_path = best_updated_price_path;
    meta = best_meta;
elseif ~isempty(best_probe_metrics)
    updated_price_path = best_probe_updated_price_path;
    meta = best_probe_meta;
else
    updated_price_path = best_updated_price_path;
    meta = best_meta;
end
end

function metrics = summarize_metrics_local(current_pass, vote_path, params)
vote_path = vote_path(:);
metrics = struct();
metrics.max_abs_vote = max(abs(vote_path));
metrics.vote_l2 = norm(vote_path, 2);
metrics.mean_abs_vote = mean(abs(vote_path));
metrics.residual_norm = current_pass.residual_norm;
metrics.max_abs_gap = current_pass.max_abs_gap;
metrics.merit = metrics.vote_l2^2 + params.outer_gap_weight * metrics.max_abs_gap^2;
end

function [accept_candidate, probe_ok] = evaluate_candidate_acceptance_local(candidate_metrics, incumbent_metrics, params)
vote_guard = max(params.outer_vote_guard_abs, 0.01 * incumbent_metrics.max_abs_vote);
gap_guard = max(params.outer_gap_guard_abs, 0.01 * incumbent_metrics.max_abs_gap);

if incumbent_metrics.max_abs_vote > 5 * params.tol_vote
    primary_current = incumbent_metrics.merit;
    primary_candidate = candidate_metrics.merit;
else
    primary_current = incumbent_metrics.max_abs_vote;
    primary_candidate = candidate_metrics.max_abs_vote;
end

accept_candidate = ...
    (primary_candidate < (primary_current - params.outer_line_search_tol)) && ...
    (candidate_metrics.max_abs_vote <= incumbent_metrics.max_abs_vote + vote_guard) && ...
    (candidate_metrics.max_abs_gap <= incumbent_metrics.max_abs_gap + gap_guard);

probe_ok = params.allow_probe_accept && ...
    (candidate_metrics.max_abs_vote <= incumbent_metrics.max_abs_vote + vote_guard) && ...
    (candidate_metrics.max_abs_gap <= incumbent_metrics.max_abs_gap + gap_guard) && ...
    (candidate_metrics.merit <= incumbent_metrics.merit + params.outer_line_search_tol);
end

function is_better = is_candidate_metrics_better_local(candidate_metrics, incumbent_metrics, params)
if candidate_metrics.max_abs_vote > 5 * params.tol_vote || incumbent_metrics.max_abs_vote > 5 * params.tol_vote
    candidate_primary = candidate_metrics.merit;
    incumbent_primary = incumbent_metrics.merit;
else
    candidate_primary = candidate_metrics.max_abs_vote;
    incumbent_primary = incumbent_metrics.max_abs_vote;
end

if candidate_primary < (incumbent_primary - params.outer_line_search_tol)
    is_better = true;
    return;
end

if abs(candidate_primary - incumbent_primary) <= params.outer_line_search_tol
    if candidate_metrics.max_abs_vote < (incumbent_metrics.max_abs_vote - params.outer_line_search_tol)
        is_better = true;
        return;
    end
    if abs(candidate_metrics.max_abs_vote - incumbent_metrics.max_abs_vote) <= params.outer_line_search_tol
        if candidate_metrics.merit < (incumbent_metrics.merit - params.outer_line_search_tol)
            is_better = true;
            return;
        end
        if abs(candidate_metrics.merit - incumbent_metrics.merit) <= params.outer_line_search_tol
            is_better = candidate_metrics.max_abs_gap < (incumbent_metrics.max_abs_gap - params.outer_line_search_tol);
            return;
        end
    end
end

is_better = false;
end

function tf = uses_line_search_local(rule_name)
tf = endsWith(lower(string(rule_name)), "_linesearch");
end

function tf = uses_targeted_line_search_local(rule_name)
tf = contains(lower(string(rule_name)), "targeted");
end

function base_rule = strip_line_search_suffix_local(rule_name)
base_rule = string(rule_name);
if uses_line_search_local(base_rule)
    base_rule = extractBefore(base_rule, strlength(base_rule) - strlength("_linesearch") + 1);
end
end

function candidate_price_path = apply_update_mask_local(current_price_path, full_candidate_price_path, mask)
candidate_price_path = current_price_path(:);
mask = logical(mask(:));
candidate_price_path(mask) = full_candidate_price_path(mask);
end

function mask_specs = build_targeted_line_search_masks_local(vote_path, pass_params)
vote_path = vote_path(:);
T = numel(vote_path);
mask_specs = struct('label', {}, 'mask', {});

if T <= 1
    mask_specs = append_mask_spec_local(mask_specs, "full_path", true(T, 1));
    return;
end

if ~isfield(pass_params, 'max_targeted_periods') || isempty(pass_params.max_targeted_periods)
    max_targeted_periods = min(3, T);
else
    max_targeted_periods = min(T, max(1, round(pass_params.max_targeted_periods)));
end

if ~isfield(pass_params, 'target_block_half_width') || isempty(pass_params.target_block_half_width)
    block_half_width = 1;
else
    block_half_width = max(0, round(pass_params.target_block_half_width));
end

if ~isfield(pass_params, 'target_mask_mode') || isempty(pass_params.target_mask_mode)
    target_mask_mode = "full_library";
else
    target_mask_mode = lower(string(pass_params.target_mask_mode));
end

positive_mask = vote_path > 0;
negative_mask = vote_path < 0;

[~, order] = sort(abs(vote_path), 'descend');
top_periods = unique(order(1:max_targeted_periods), 'stable');
joint_top_mask = false(T, 1);
joint_top_mask(top_periods) = true;
joint_block_mask = false(T, 1);
for idx = reshape(top_periods, 1, [])
    left_idx = max(1, idx - block_half_width);
    right_idx = min(T, idx + block_half_width);
    joint_block_mask(left_idx:right_idx) = true;
end

switch target_mask_mode
    case "union_only"
        mask_specs = append_mask_spec_local(mask_specs, "topk_union", joint_top_mask);
        return;
    case "union_and_block"
        mask_specs = append_mask_spec_local(mask_specs, "topk_union", joint_top_mask);
        mask_specs = append_mask_spec_local(mask_specs, "topk_union_block", joint_block_mask);
        return;
    case "sign_split"
        if any(positive_mask) && ~all(positive_mask)
            mask_specs = append_mask_spec_local(mask_specs, "positive_vote_periods", positive_mask);
        end
        if any(negative_mask) && ~all(negative_mask)
            mask_specs = append_mask_spec_local(mask_specs, "negative_vote_periods", negative_mask);
        end
        if isempty(mask_specs)
            mask_specs = append_mask_spec_local(mask_specs, "topk_union", joint_top_mask);
        end
        return;
    case "half_split"
        split_idx = ceil(T / 2);
        front_half_mask = false(T, 1);
        front_half_mask(1:split_idx) = true;
        back_half_mask = false(T, 1);
        back_half_mask((split_idx + 1):T) = true;
        mask_specs = append_mask_spec_local(mask_specs, "front_half", front_half_mask);
        mask_specs = append_mask_spec_local(mask_specs, "back_half", back_half_mask);
        return;
    case "active_clusters"
        active_threshold = 0.75 * max(abs(vote_path));
        active_mask = abs(vote_path) >= active_threshold;
        in_cluster = false;
        cluster_start = 1;
        for idx = 1:T
            if active_mask(idx) && ~in_cluster
                in_cluster = true;
                cluster_start = idx;
            end
            cluster_ends_here = in_cluster && (~active_mask(idx) || idx == T);
            if cluster_ends_here
                cluster_end = idx;
                if ~active_mask(idx)
                    cluster_end = idx - 1;
                end
                cluster_mask = false(T, 1);
                cluster_mask(cluster_start:cluster_end) = true;
                mask_specs = append_mask_spec_local(mask_specs, "active_cluster_" + string(cluster_start) + "_" + string(cluster_end), cluster_mask);
                in_cluster = false;
            end
        end
        mask_specs = append_mask_spec_local(mask_specs, "topk_union", joint_top_mask);
        if isempty(mask_specs)
            mask_specs = append_mask_spec_local(mask_specs, "topk_union_block", joint_block_mask);
        end
        return;
    case "full_library"
        mask_specs = append_mask_spec_local(mask_specs, "full_path", true(T, 1));
    otherwise
        error('Unknown target_mask_mode "%s".', target_mask_mode);
end

if any(positive_mask) && ~all(positive_mask)
    mask_specs = append_mask_spec_local(mask_specs, "positive_vote_periods", positive_mask);
end
if any(negative_mask) && ~all(negative_mask)
    mask_specs = append_mask_spec_local(mask_specs, "negative_vote_periods", negative_mask);
end

mask_specs = append_mask_spec_local(mask_specs, "topk_union", joint_top_mask);

active90_mask = abs(vote_path) >= 0.90 * max(abs(vote_path));
mask_specs = append_mask_spec_local(mask_specs, "active90pct", active90_mask);

for idx = reshape(top_periods, 1, [])
    singleton_mask = false(T, 1);
    singleton_mask(idx) = true;
    mask_specs = append_mask_spec_local(mask_specs, "single_t" + string(idx), singleton_mask);

    left_idx = max(1, idx - block_half_width);
    right_idx = min(T, idx + block_half_width);
    block_mask = false(T, 1);
    block_mask(left_idx:right_idx) = true;
    mask_specs = append_mask_spec_local(mask_specs, "block_t" + string(idx) + "_" + string(left_idx) + "_" + string(right_idx), block_mask);
    joint_block_mask(left_idx:right_idx) = true;
end
mask_specs = append_mask_spec_local(mask_specs, "topk_union_block", joint_block_mask);
end

function mask_specs = append_mask_spec_local(mask_specs, label, mask)
mask = logical(mask(:));
if ~any(mask)
    return;
end

for idx = 1:numel(mask_specs)
    if isequal(mask_specs(idx).mask, mask)
        return;
    end
end

mask_specs(end + 1).label = string(label);
mask_specs(end).mask = mask;
end
