function results = solve_transition_re_fertility(initial_q_path, overrides, options)
% solve_transition_re_fertility.m
%
% Short-horizon outer fixed point for the structural five-year Bellman
% transition object. The path update keeps the project's political-support
% equilibrium concept: at each date, solve for the current q_t that makes
% the transition vote object locally cross zero, holding the later tail at
% the current guess.

if nargin < 1 || isempty(initial_q_path)
    cfg = fertility_benchmark_config();
    initial_q_path = repmat(cfg.eval_price, 1, 4);
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

cfg = fertility_benchmark_config();
[q_guess, options] = apply_default_options_re_local(initial_q_path, options, cfg);
T = numel(q_guess);

iteration_rows = table();
vote_rows = table();
period_rows = table();
converged = false;
[active_damping_path, active_max_q_update_step] = initialize_outer_update_control_local(options);
prev_abs_residual = [];
prev_implied_q_path = [];
best_q_guess = [];
best_implied_q_path = [];
best_abs_residual = [];
best_max_abs_residual = inf;
best_active_damping_path = [];
best_active_max_q_update_step = [];
rollback_count = 0;
backtracking_stall_count = 0;
last_backtracking_stall_q_guess = [];
last_backtracking_stall_implied_q_path = [];
stalled = false;

for iter = 1:options.max_iter
    if options.verbose_progress
        fprintf('Bellman RE iteration %d of %d...\n', iter, options.max_iter);
        drawnow;
    end

    [implied_q_path, iter_vote_rows, iter_period_rows] = build_implied_q_path_local(q_guess, prev_implied_q_path, overrides, options);
    residual = implied_q_path - q_guess;
    max_abs_residual = max(abs(residual));
    [active_damping_path, active_max_q_update_step, tightened_mask] = ...
        adapt_outer_update_control_local(active_damping_path, active_max_q_update_step, abs(residual), prev_abs_residual, options);
    [best_q_guess, best_implied_q_path, best_abs_residual, best_max_abs_residual, ...
        best_active_damping_path, best_active_max_q_update_step] = ...
        update_best_iterate_local(q_guess, implied_q_path, abs(residual), max_abs_residual, ...
        active_damping_path, active_max_q_update_step, best_q_guess, best_implied_q_path, ...
        best_abs_residual, best_max_abs_residual, best_active_damping_path, best_active_max_q_update_step);
    [backtracking_used, backtracking_coordinate_used, backtracking_accepted, ...
        backtracking_rounds, backtracking_trial_max_abs_residual, ...
        q_next_backtracked, implied_q_next_backtracked, abs_residual_next_backtracked, ...
        active_damping_path, active_max_q_update_step] = ...
        attempt_backtracking_step_local(q_guess, implied_q_path, max_abs_residual, ...
        active_damping_path, active_max_q_update_step, overrides, options);
    rollback_applied = false;
    rollback_target_q = q_guess;
    rollback_target_prev_implied = [];
    rollback_target_abs_residual = [];
    if ~backtracking_used
        [rollback_applied, rollback_count, rollback_target_q, rollback_target_prev_implied, ...
            rollback_target_abs_residual, active_damping_path, active_max_q_update_step] = ...
            maybe_prepare_rollback_local(q_guess, max_abs_residual, best_q_guess, best_implied_q_path, ...
            best_abs_residual, best_max_abs_residual, best_active_damping_path, ...
            best_active_max_q_update_step, active_damping_path, active_max_q_update_step, ...
            rollback_count, options);
    end

    iter_row = make_iteration_row_local(iter, q_guess, implied_q_path, residual, ...
        active_damping_path, active_max_q_update_step, tightened_mask, rollback_applied, rollback_count, ...
        backtracking_used, backtracking_coordinate_used, backtracking_accepted, ...
        backtracking_rounds, backtracking_trial_max_abs_residual);
    iter_row.max_abs_residual = max_abs_residual;
    iteration_rows = [iteration_rows; iter_row]; %#ok<AGROW>

    if ~isempty(iter_vote_rows)
        iter_vote_rows.iteration = repmat(iter, height(iter_vote_rows), 1);
        vote_rows = [vote_rows; iter_vote_rows]; %#ok<AGROW>
    end

    if ~isempty(iter_period_rows)
        iter_period_rows.iteration = repmat(iter, height(iter_period_rows), 1);
        period_rows = [period_rows; iter_period_rows]; %#ok<AGROW>
    end

    if options.verbose_progress
        fprintf('  max |implied - guess| = %.6f\n', max_abs_residual);
        drawnow;
    end

    if max_abs_residual < options.tolerance
        q_guess = implied_q_path;
        converged = true;
        break;
    end

    if backtracking_accepted
        if options.verbose_progress
            fprintf('  accepted backtracking step after %d trial(s): %.6f -> %.6f\n', ...
                backtracking_rounds, max_abs_residual, backtracking_trial_max_abs_residual);
            drawnow;
        end
        [best_q_guess, best_implied_q_path, best_abs_residual, best_max_abs_residual, ...
            best_active_damping_path, best_active_max_q_update_step] = ...
            update_best_iterate_local(q_next_backtracked, implied_q_next_backtracked, abs_residual_next_backtracked, ...
            backtracking_trial_max_abs_residual, active_damping_path, active_max_q_update_step, ...
            best_q_guess, best_implied_q_path, best_abs_residual, best_max_abs_residual, ...
            best_active_damping_path, best_active_max_q_update_step);
        q_guess = q_next_backtracked;
        prev_abs_residual = abs_residual_next_backtracked;
        prev_implied_q_path = implied_q_next_backtracked;
        backtracking_stall_count = 0;
        last_backtracking_stall_q_guess = [];
        last_backtracking_stall_implied_q_path = [];
        continue;
    end

    if backtracking_used
        [backtracking_stall_count, last_backtracking_stall_q_guess, last_backtracking_stall_implied_q_path, stalled] = ...
            update_backtracking_stall_local(q_guess, implied_q_path, backtracking_accepted, ...
            backtracking_stall_count, last_backtracking_stall_q_guess, last_backtracking_stall_implied_q_path, options);
        if options.verbose_progress
            fprintf('  rejected late-stage step after %d trial(s); keeping current iterate under tighter controls.\n', backtracking_rounds);
            drawnow;
        end
        if stalled
            if options.verbose_progress
                fprintf('  stopping on repeated backtracking stall at residual %.6f\n', max_abs_residual);
                drawnow;
            end
            break;
        end
        prev_abs_residual = abs(residual);
        prev_implied_q_path = implied_q_path;
        continue;
    end

    if rollback_applied
        if options.verbose_progress
            fprintf('  rollback to best iterate after residual jump: %.6f -> %.6f\n', max_abs_residual, best_max_abs_residual);
            drawnow;
        end
        q_guess = rollback_target_q;
        prev_abs_residual = rollback_target_abs_residual;
        prev_implied_q_path = rollback_target_prev_implied;
        continue;
    end

    q_guess = apply_outer_update_local(q_guess, implied_q_path, active_damping_path, active_max_q_update_step, options);
    prev_abs_residual = abs(residual);
    prev_implied_q_path = implied_q_path;
    backtracking_stall_count = 0;
    last_backtracking_stall_q_guess = [];
    last_backtracking_stall_implied_q_path = [];
end

results = struct();
results.q_path = q_guess(:)';
results.converged = converged;
results.options = options;
results.overrides = overrides;
results.iteration_history = iteration_rows;
results.vote_grid_history = vote_rows;
results.period_history = period_rows;
results.solver_results = [];
results.simulation = [];
results.summary = struct();
results.final_damping_path = active_damping_path;
results.final_max_q_update_step = active_max_q_update_step;
results.rollback_count = rollback_count;
results.stalled = stalled;
if options.compute_final_summary
    final_solver_results = solve_household_path_fertility(q_guess, overrides, ...
        build_solver_options_re_local(options, options.rbPos_path, false));
    final_simulation = forward_distribution_path_fertility(final_solver_results, [], struct('store_cross_section', true));
    final_summary = summarize_transition_path_fertility(final_solver_results, final_simulation);
    results.solver_results = final_solver_results;
    results.simulation = final_simulation;
    results.summary = final_summary;
end
results.max_abs_residual = NaN;
if ~isempty(iteration_rows)
    results.max_abs_residual = iteration_rows.max_abs_residual(end);
end
end

function q_next = apply_outer_update_local(q_guess, implied_q_path, damping_path, max_q_update_step, options)
q_next = apply_outer_update_with_mask_local(q_guess, implied_q_path, damping_path, max_q_update_step, true(size(q_guess)), options);
end

function q_next = apply_outer_update_with_mask_local(q_guess, implied_q_path, damping_path, max_q_update_step, update_mask, options)
residual = implied_q_path - q_guess;
update_mask = logical(update_mask(:)');
if numel(update_mask) ~= numel(q_guess)
    error('update_mask must match q_guess length.');
end
update_step = damping_path .* residual;
finite_mask = isfinite(max_q_update_step);
if any(finite_mask)
    update_step(finite_mask) = max(min(update_step(finite_mask), max_q_update_step(finite_mask)), -max_q_update_step(finite_mask));
end
update_step(~update_mask) = 0;
q_next = q_guess + update_step;
q_next = min(max(q_next, options.q_min), options.q_max);
end

function [active_damping_path, active_max_q_update_step] = initialize_outer_update_control_local(options)
active_damping_path = options.damping_path;
active_max_q_update_step = options.max_q_update_step;
end

function [active_damping_path, active_max_q_update_step, tightened_mask] = ...
    adapt_outer_update_control_local(active_damping_path, active_max_q_update_step, abs_residual, prev_abs_residual, options)
tightened_mask = false(size(abs_residual));
if ~options.adaptive_update_control || isempty(prev_abs_residual)
    return;
end

worsen_threshold = max(options.adaptive_worsen_ratio .* prev_abs_residual, ...
    prev_abs_residual + options.adaptive_worsen_abs_tol);
tightened_mask = isfinite(abs_residual) & isfinite(worsen_threshold) & (abs_residual > worsen_threshold);
if ~any(tightened_mask)
    return;
end

active_damping_path(tightened_mask) = max(options.min_damping_path(tightened_mask), ...
    active_damping_path(tightened_mask) .* options.adaptive_shrink_factor);

finite_cap_mask = tightened_mask & isfinite(active_max_q_update_step);
if any(finite_cap_mask)
    active_max_q_update_step(finite_cap_mask) = max(options.min_max_q_update_step(finite_cap_mask), ...
        active_max_q_update_step(finite_cap_mask) .* options.adaptive_shrink_factor);
end
end

function [best_q_guess, best_implied_q_path, best_abs_residual, best_max_abs_residual, ...
    best_active_damping_path, best_active_max_q_update_step] = ...
    update_best_iterate_local(q_guess, implied_q_path, abs_residual, max_abs_residual, ...
    active_damping_path, active_max_q_update_step, best_q_guess, best_implied_q_path, ...
    best_abs_residual, best_max_abs_residual, best_active_damping_path, best_active_max_q_update_step)
if isempty(best_q_guess) || max_abs_residual < best_max_abs_residual
    best_q_guess = q_guess;
    best_implied_q_path = implied_q_path;
    best_abs_residual = abs_residual;
    best_max_abs_residual = max_abs_residual;
    best_active_damping_path = active_damping_path;
    best_active_max_q_update_step = active_max_q_update_step;
end
end

function [backtracking_used, backtracking_coordinate_used, backtracking_accepted, ...
    backtracking_rounds, backtracking_trial_max_abs_residual, ...
    q_next, implied_q_next, abs_residual_next, active_damping_path, active_max_q_update_step] = ...
    attempt_backtracking_step_local(q_guess, implied_q_path, max_abs_residual, ...
    active_damping_path, active_max_q_update_step, overrides, options)
backtracking_used = false;
backtracking_coordinate_used = false;
backtracking_accepted = false;
backtracking_rounds = 0;
backtracking_trial_max_abs_residual = NaN;
q_next = q_guess;
implied_q_next = [];
abs_residual_next = [];
if ~options.backtracking_line_search || max_abs_residual > options.backtracking_activate_residual
    return;
end

base_damping_path = active_damping_path;
base_max_q_update_step = active_max_q_update_step;
trial_damping_path = active_damping_path;
trial_max_q_update_step = active_max_q_update_step;
trial_options = options;
trial_options.verbose_progress = false;
accept_threshold = max(options.backtracking_accept_worsen_ratio * max_abs_residual, ...
    max_abs_residual + options.backtracking_accept_worsen_abs_tol);
best_trial_max_abs_residual = inf;

for round_idx = 1:options.max_backtracking_rounds
    q_trial = apply_outer_update_local(q_guess, implied_q_path, trial_damping_path, trial_max_q_update_step, options);
    if max(abs(q_trial - q_guess)) <= 1e-12
        break;
    end

    backtracking_used = true;
    backtracking_rounds = round_idx;
    [implied_q_trial, ~, ~] = build_implied_q_path_local(q_trial, implied_q_path, overrides, trial_options);
    residual_trial = implied_q_trial - q_trial;
    trial_max_abs_residual = max(abs(residual_trial));
    best_trial_max_abs_residual = min(best_trial_max_abs_residual, trial_max_abs_residual);

    if trial_max_abs_residual <= accept_threshold
        backtracking_accepted = true;
        backtracking_trial_max_abs_residual = trial_max_abs_residual;
        q_next = q_trial;
        implied_q_next = implied_q_trial;
        abs_residual_next = abs(residual_trial);
        active_damping_path = trial_damping_path;
        active_max_q_update_step = trial_max_q_update_step;
        return;
    end

    trial_damping_path = max(options.min_damping_path, trial_damping_path .* options.backtracking_shrink_factor);
    finite_cap_mask = isfinite(trial_max_q_update_step);
    if any(finite_cap_mask)
        trial_max_q_update_step(finite_cap_mask) = max(options.min_max_q_update_step(finite_cap_mask), ...
            trial_max_q_update_step(finite_cap_mask) .* options.backtracking_shrink_factor);
    end
end

if backtracking_used
    backtracking_trial_max_abs_residual = best_trial_max_abs_residual;
    active_damping_path = trial_damping_path;
    active_max_q_update_step = trial_max_q_update_step;
end

if options.coordinate_backtracking_line_search && max_abs_residual <= options.coordinate_backtracking_activate_residual
    [coordinate_used, coordinate_accepted, coordinate_rounds, coordinate_trial_max_abs_residual, ...
        q_next_coordinate, implied_q_next_coordinate, abs_residual_next_coordinate] = ...
        attempt_coordinate_backtracking_local(q_guess, implied_q_path, max_abs_residual, ...
        base_damping_path, base_max_q_update_step, overrides, trial_options, options);
    backtracking_used = backtracking_used || coordinate_used;
    if coordinate_used
        if ~isfinite(backtracking_trial_max_abs_residual)
            backtracking_trial_max_abs_residual = coordinate_trial_max_abs_residual;
        else
            backtracking_trial_max_abs_residual = min(backtracking_trial_max_abs_residual, coordinate_trial_max_abs_residual);
        end
    end
    if coordinate_accepted
        backtracking_coordinate_used = true;
        backtracking_accepted = true;
        backtracking_rounds = coordinate_rounds;
        backtracking_trial_max_abs_residual = coordinate_trial_max_abs_residual;
        q_next = q_next_coordinate;
        implied_q_next = implied_q_next_coordinate;
        abs_residual_next = abs_residual_next_coordinate;
        active_damping_path = base_damping_path;
        active_max_q_update_step = base_max_q_update_step;
    end
end
end

function [coordinate_used, coordinate_accepted, coordinate_rounds, coordinate_trial_max_abs_residual, ...
    q_next, implied_q_next, abs_residual_next] = ...
    attempt_coordinate_backtracking_local(q_guess, implied_q_path, max_abs_residual, ...
    base_damping_path, base_max_q_update_step, overrides, trial_options, options)
coordinate_used = false;
coordinate_accepted = false;
coordinate_rounds = 0;
coordinate_trial_max_abs_residual = inf;
q_next = q_guess;
implied_q_next = [];
abs_residual_next = [];

residual = implied_q_path - q_guess;
[~, order] = sort(abs(residual), 'descend');
order = order(isfinite(residual(order)));
if isempty(order)
    return;
end
order = order(1:min(options.max_coordinate_backtracking_periods, numel(order)));
accept_threshold = max(options.backtracking_accept_worsen_ratio * max_abs_residual, ...
    max_abs_residual + options.backtracking_accept_worsen_abs_tol);

for order_idx = 1:numel(order)
    period_idx = order(order_idx);
    update_mask = false(size(q_guess));
    update_mask(period_idx) = true;
    trial_damping_path = base_damping_path;
    trial_max_q_update_step = base_max_q_update_step;
    continuity_target_q = NaN;
    if logical(options.coordinate_branch_continuity_mask(period_idx)) && isfinite(implied_q_path(period_idx))
        continuity_target_q = implied_q_path(period_idx);
    end
    for round_idx = 1:options.max_coordinate_backtracking_rounds
        q_trial = apply_outer_update_with_mask_local(q_guess, implied_q_path, trial_damping_path, ...
            trial_max_q_update_step, update_mask, options);
        if max(abs(q_trial - q_guess)) <= 1e-12
            break;
        end
        coordinate_used = true;
        [implied_q_trial, ~, ~] = build_implied_q_path_local(q_trial, implied_q_path, overrides, trial_options);
        residual_trial = implied_q_trial - q_trial;
        trial_max_abs_residual = max(abs(residual_trial));
        coordinate_trial_max_abs_residual = min(coordinate_trial_max_abs_residual, trial_max_abs_residual);

        accept_trial = trial_max_abs_residual <= accept_threshold;
        continuity_gap = NaN;
        if isfinite(continuity_target_q)
            continuity_gap = abs(implied_q_trial(period_idx) - continuity_target_q);
            accept_trial = accept_trial && ...
                (continuity_gap <= options.coordinate_branch_continuity_q_tolerance);
        end
        if options.coordinate_backtracking_require_improvement
            accept_trial = accept_trial && ...
                (trial_max_abs_residual < (max_abs_residual - options.coordinate_backtracking_improve_tol));
        end
        if options.debug_coordinate_backtracking
            fprintf('      coordinate trial period %d round %d: q=%.12f implied=%.12f maxres=%.12f continuity_gap=%.12f accept=%d\n', ...
                period_idx, round_idx, q_trial(period_idx), implied_q_trial(period_idx), ...
                trial_max_abs_residual, continuity_gap, accept_trial);
            drawnow;
        end
        if accept_trial && (~coordinate_accepted || trial_max_abs_residual < coordinate_trial_max_abs_residual)
            coordinate_accepted = true;
            coordinate_rounds = round_idx;
            coordinate_trial_max_abs_residual = trial_max_abs_residual;
            q_next = q_trial;
            implied_q_next = implied_q_trial;
            abs_residual_next = abs(residual_trial);
        end

        trial_damping_path(period_idx) = max(options.coordinate_min_damping_path(period_idx), ...
            trial_damping_path(period_idx) .* options.backtracking_shrink_factor);
        if isfinite(trial_max_q_update_step(period_idx))
            trial_max_q_update_step(period_idx) = max(options.coordinate_min_max_q_update_step(period_idx), ...
                trial_max_q_update_step(period_idx) .* options.backtracking_shrink_factor);
        end
    end
end
end

function [rollback_applied, rollback_count, rollback_target_q, rollback_target_prev_implied, ...
    rollback_target_abs_residual, active_damping_path, active_max_q_update_step] = ...
    maybe_prepare_rollback_local(q_guess, max_abs_residual, best_q_guess, best_implied_q_path, ...
    best_abs_residual, best_max_abs_residual, best_active_damping_path, ...
    best_active_max_q_update_step, active_damping_path, active_max_q_update_step, ...
    rollback_count, options)
rollback_applied = false;
rollback_target_q = q_guess;
rollback_target_prev_implied = [];
rollback_target_abs_residual = [];
if ~options.rollback_to_best_on_jump || isempty(best_q_guess) || rollback_count >= options.max_rollbacks
    return;
end

worsen_threshold = max(options.rollback_worsen_ratio * best_max_abs_residual, ...
    best_max_abs_residual + options.rollback_worsen_abs_tol);
if ~(isfinite(max_abs_residual) && isfinite(worsen_threshold) && max_abs_residual > worsen_threshold)
    return;
end

rollback_applied = true;
rollback_count = rollback_count + 1;
rollback_target_q = best_q_guess;
rollback_target_prev_implied = best_implied_q_path;
rollback_target_abs_residual = best_abs_residual;

if isempty(best_active_damping_path)
    best_active_damping_path = active_damping_path;
end
active_damping_path = max(options.min_damping_path, best_active_damping_path .* options.rollback_shrink_factor);

if isempty(best_active_max_q_update_step)
    best_active_max_q_update_step = active_max_q_update_step;
end
finite_cap_mask = isfinite(best_active_max_q_update_step);
if any(finite_cap_mask)
    active_max_q_update_step(finite_cap_mask) = max(options.min_max_q_update_step(finite_cap_mask), ...
        best_active_max_q_update_step(finite_cap_mask) .* options.rollback_shrink_factor);
end
end

function [stall_count, last_stall_q_guess, last_stall_implied_q_path, stalled] = ...
    update_backtracking_stall_local(q_guess, implied_q_path, backtracking_accepted, ...
    stall_count, last_stall_q_guess, last_stall_implied_q_path, options)
stalled = false;
if backtracking_accepted
    stall_count = 0;
    last_stall_q_guess = [];
    last_stall_implied_q_path = [];
    return;
end

same_q = false;
same_implied = false;
tol = options.backtracking_stall_q_tolerance;
if ~isempty(last_stall_q_guess) && numel(last_stall_q_guess) == numel(q_guess)
    same_q = all(abs(q_guess - last_stall_q_guess) <= tol);
end
if ~isempty(last_stall_implied_q_path) && numel(last_stall_implied_q_path) == numel(implied_q_path)
    same_implied = all(abs(implied_q_path - last_stall_implied_q_path) <= tol);
end

if same_q && same_implied
    stall_count = stall_count + 1;
else
    stall_count = 1;
    last_stall_q_guess = q_guess;
    last_stall_implied_q_path = implied_q_path;
end

if options.stop_on_backtracking_stall && stall_count >= options.max_backtracking_stall_iters
    stalled = true;
end
end

function [q_guess, options] = apply_default_options_re_local(initial_q_path, options, cfg)
q_guess = initial_q_path(:)';
if isempty(q_guess)
    error('initial_q_path must contain at least one element.');
end

if ~isfield(options, 'rbPos_path') || isempty(options.rbPos_path)
    options.rbPos_path = cfg.rbPos;
end
if isscalar(options.rbPos_path)
    options.rbPos_path = repmat(options.rbPos_path, size(q_guess));
else
    options.rbPos_path = options.rbPos_path(:)';
    if numel(options.rbPos_path) ~= numel(q_guess)
        error('rbPos_path must be scalar or match initial_q_path length.');
    end
end

if ~isfield(options, 'damping') || isempty(options.damping)
    options.damping = 0.20;
end
if ~isfield(options, 'damping_path') || isempty(options.damping_path)
    options.damping_path = repmat(options.damping, size(q_guess));
elseif isscalar(options.damping_path)
    options.damping_path = repmat(options.damping_path, size(q_guess));
else
    options.damping_path = options.damping_path(:)';
    if numel(options.damping_path) ~= numel(q_guess)
        error('damping_path must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'tolerance') || isempty(options.tolerance)
    options.tolerance = 1.0e-3;
end
if ~isfield(options, 'max_iter') || isempty(options.max_iter)
    options.max_iter = 10;
end
if ~isfield(options, 'vote_dp_factor') || isempty(options.vote_dp_factor)
    options.vote_dp_factor = 1.01;
end
if ~isfield(options, 'vote_dp_scope') || isempty(options.vote_dp_scope)
    options.vote_dp_scope = "remaining_path";
else
    options.vote_dp_scope = string(options.vote_dp_scope);
end
if ~isfield(options, 'root_selection_anchor') || isempty(options.root_selection_anchor)
    options.root_selection_anchor = "current_guess";
else
    options.root_selection_anchor = string(options.root_selection_anchor);
end
if ~isfield(options, 'root_selection_previous_implied_mask') || isempty(options.root_selection_previous_implied_mask)
    options.root_selection_previous_implied_mask = false(size(q_guess));
elseif isscalar(options.root_selection_previous_implied_mask)
    options.root_selection_previous_implied_mask = logical(repmat(options.root_selection_previous_implied_mask, size(q_guess)));
else
    options.root_selection_previous_implied_mask = logical(options.root_selection_previous_implied_mask(:)');
    if numel(options.root_selection_previous_implied_mask) ~= numel(q_guess)
        error('root_selection_previous_implied_mask must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'branch_hysteresis_mask') || isempty(options.branch_hysteresis_mask)
    options.branch_hysteresis_mask = false(size(q_guess));
elseif isscalar(options.branch_hysteresis_mask)
    options.branch_hysteresis_mask = logical(repmat(options.branch_hysteresis_mask, size(q_guess)));
else
    options.branch_hysteresis_mask = logical(options.branch_hysteresis_mask(:)');
    if numel(options.branch_hysteresis_mask) ~= numel(q_guess)
        error('branch_hysteresis_mask must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'branch_hysteresis_q_tolerance') || isempty(options.branch_hysteresis_q_tolerance)
    options.branch_hysteresis_q_tolerance = 0.20;
end
if ~isfield(options, 'branch_tie_break_mask') || isempty(options.branch_tie_break_mask)
    options.branch_tie_break_mask = false(size(q_guess));
elseif isscalar(options.branch_tie_break_mask)
    options.branch_tie_break_mask = logical(repmat(options.branch_tie_break_mask, size(q_guess)));
else
    options.branch_tie_break_mask = logical(options.branch_tie_break_mask(:)');
    if numel(options.branch_tie_break_mask) ~= numel(q_guess)
        error('branch_tie_break_mask must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'branch_tie_break_q_tolerance') || isempty(options.branch_tie_break_q_tolerance)
    options.branch_tie_break_q_tolerance = 0.01;
end
if ~isfield(options, 'q_search_grid') || isempty(options.q_search_grid)
    options.q_search_grid = 1.5:0.25:2.5;
end
if ~isfield(options, 'q_refine_points') || isempty(options.q_refine_points)
    options.q_refine_points = 7;
end
if ~isfield(options, 'q_min') || isempty(options.q_min)
    options.q_min = 1.0;
end
if ~isfield(options, 'q_max') || isempty(options.q_max)
    options.q_max = 3.5;
end
if ~isfield(options, 'q_expand_step') || isempty(options.q_expand_step)
    options.q_expand_step = median(diff(unique(sort(options.q_search_grid(:)))));
    if ~isfinite(options.q_expand_step) || options.q_expand_step <= 0
        options.q_expand_step = 0.25;
    end
end
if ~isfield(options, 'q_fill_step') || isempty(options.q_fill_step)
    options.q_fill_step = min(0.125, options.q_expand_step / 4);
    if ~isfinite(options.q_fill_step) || options.q_fill_step <= 0
        options.q_fill_step = 0.125;
    end
end
if ~isfield(options, 'max_fill_rounds') || isempty(options.max_fill_rounds)
    options.max_fill_rounds = 3;
end
if ~isfield(options, 'max_expand_rounds') || isempty(options.max_expand_rounds)
    options.max_expand_rounds = 6;
end
if ~isfield(options, 'max_q_update_step') || isempty(options.max_q_update_step)
    options.max_q_update_step = inf(size(q_guess));
elseif isscalar(options.max_q_update_step)
    options.max_q_update_step = repmat(options.max_q_update_step, size(q_guess));
else
    options.max_q_update_step = options.max_q_update_step(:)';
    if numel(options.max_q_update_step) ~= numel(q_guess)
        error('max_q_update_step must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'adaptive_update_control') || isempty(options.adaptive_update_control)
    options.adaptive_update_control = false;
end
if ~isfield(options, 'adaptive_worsen_ratio') || isempty(options.adaptive_worsen_ratio)
    options.adaptive_worsen_ratio = 1.05;
end
if ~isfield(options, 'adaptive_worsen_abs_tol') || isempty(options.adaptive_worsen_abs_tol)
    options.adaptive_worsen_abs_tol = 0.01;
end
if ~isfield(options, 'adaptive_shrink_factor') || isempty(options.adaptive_shrink_factor)
    options.adaptive_shrink_factor = 0.75;
end
if ~isfield(options, 'backtracking_line_search') || isempty(options.backtracking_line_search)
    options.backtracking_line_search = false;
end
if ~isfield(options, 'backtracking_activate_residual') || isempty(options.backtracking_activate_residual)
    options.backtracking_activate_residual = inf;
end
if ~isfield(options, 'backtracking_shrink_factor') || isempty(options.backtracking_shrink_factor)
    options.backtracking_shrink_factor = 0.50;
end
if ~isfield(options, 'backtracking_accept_worsen_ratio') || isempty(options.backtracking_accept_worsen_ratio)
    options.backtracking_accept_worsen_ratio = 1.00;
end
if ~isfield(options, 'backtracking_accept_worsen_abs_tol') || isempty(options.backtracking_accept_worsen_abs_tol)
    options.backtracking_accept_worsen_abs_tol = 0.0;
end
if ~isfield(options, 'max_backtracking_rounds') || isempty(options.max_backtracking_rounds)
    options.max_backtracking_rounds = 3;
end
if ~isfield(options, 'stop_on_backtracking_stall') || isempty(options.stop_on_backtracking_stall)
    options.stop_on_backtracking_stall = false;
end
if ~isfield(options, 'max_backtracking_stall_iters') || isempty(options.max_backtracking_stall_iters)
    options.max_backtracking_stall_iters = 2;
end
if ~isfield(options, 'backtracking_stall_q_tolerance') || isempty(options.backtracking_stall_q_tolerance)
    options.backtracking_stall_q_tolerance = 1.0e-6;
end
if ~isfield(options, 'coordinate_backtracking_line_search') || isempty(options.coordinate_backtracking_line_search)
    options.coordinate_backtracking_line_search = false;
end
if ~isfield(options, 'coordinate_backtracking_activate_residual') || isempty(options.coordinate_backtracking_activate_residual)
    options.coordinate_backtracking_activate_residual = inf;
end
if ~isfield(options, 'max_coordinate_backtracking_periods') || isempty(options.max_coordinate_backtracking_periods)
    options.max_coordinate_backtracking_periods = 1;
end
if ~isfield(options, 'max_coordinate_backtracking_rounds') || isempty(options.max_coordinate_backtracking_rounds)
    options.max_coordinate_backtracking_rounds = options.max_backtracking_rounds;
end
if ~isfield(options, 'coordinate_backtracking_require_improvement') || isempty(options.coordinate_backtracking_require_improvement)
    options.coordinate_backtracking_require_improvement = true;
end
if ~isfield(options, 'coordinate_backtracking_improve_tol') || isempty(options.coordinate_backtracking_improve_tol)
    options.coordinate_backtracking_improve_tol = 0.0;
end
if ~isfield(options, 'debug_coordinate_backtracking') || isempty(options.debug_coordinate_backtracking)
    options.debug_coordinate_backtracking = false;
end
if ~isfield(options, 'coordinate_min_damping_path') || isempty(options.coordinate_min_damping_path)
    options.coordinate_min_damping_path = options.min_damping_path;
elseif isscalar(options.coordinate_min_damping_path)
    options.coordinate_min_damping_path = repmat(options.coordinate_min_damping_path, size(q_guess));
else
    options.coordinate_min_damping_path = options.coordinate_min_damping_path(:)';
    if numel(options.coordinate_min_damping_path) ~= numel(q_guess)
        error('coordinate_min_damping_path must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'coordinate_min_max_q_update_step') || isempty(options.coordinate_min_max_q_update_step)
    options.coordinate_min_max_q_update_step = options.min_max_q_update_step;
elseif isscalar(options.coordinate_min_max_q_update_step)
    options.coordinate_min_max_q_update_step = repmat(options.coordinate_min_max_q_update_step, size(q_guess));
else
    options.coordinate_min_max_q_update_step = options.coordinate_min_max_q_update_step(:)';
    if numel(options.coordinate_min_max_q_update_step) ~= numel(q_guess)
        error('coordinate_min_max_q_update_step must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'coordinate_branch_continuity_mask') || isempty(options.coordinate_branch_continuity_mask)
    options.coordinate_branch_continuity_mask = false(size(q_guess));
elseif isscalar(options.coordinate_branch_continuity_mask)
    options.coordinate_branch_continuity_mask = logical(repmat(options.coordinate_branch_continuity_mask, size(q_guess)));
else
    options.coordinate_branch_continuity_mask = logical(options.coordinate_branch_continuity_mask(:)');
    if numel(options.coordinate_branch_continuity_mask) ~= numel(q_guess)
        error('coordinate_branch_continuity_mask must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'coordinate_branch_continuity_q_tolerance') || isempty(options.coordinate_branch_continuity_q_tolerance)
    options.coordinate_branch_continuity_q_tolerance = 0.03;
end
if ~isfield(options, 'rollback_to_best_on_jump') || isempty(options.rollback_to_best_on_jump)
    options.rollback_to_best_on_jump = false;
end
if ~isfield(options, 'rollback_worsen_ratio') || isempty(options.rollback_worsen_ratio)
    options.rollback_worsen_ratio = 1.50;
end
if ~isfield(options, 'rollback_worsen_abs_tol') || isempty(options.rollback_worsen_abs_tol)
    options.rollback_worsen_abs_tol = 0.05;
end
if ~isfield(options, 'rollback_shrink_factor') || isempty(options.rollback_shrink_factor)
    options.rollback_shrink_factor = 0.50;
end
if ~isfield(options, 'max_rollbacks') || isempty(options.max_rollbacks)
    options.max_rollbacks = 3;
end
if ~isfield(options, 'min_damping_path') || isempty(options.min_damping_path)
    options.min_damping_path = 0.25 .* options.damping_path;
elseif isscalar(options.min_damping_path)
    options.min_damping_path = repmat(options.min_damping_path, size(q_guess));
else
    options.min_damping_path = options.min_damping_path(:)';
    if numel(options.min_damping_path) ~= numel(q_guess)
        error('min_damping_path must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'min_max_q_update_step') || isempty(options.min_max_q_update_step)
    options.min_max_q_update_step = options.max_q_update_step;
    finite_min_mask = isfinite(options.min_max_q_update_step);
    options.min_max_q_update_step(finite_min_mask) = 0.25 .* options.max_q_update_step(finite_min_mask);
elseif isscalar(options.min_max_q_update_step)
    options.min_max_q_update_step = repmat(options.min_max_q_update_step, size(q_guess));
else
    options.min_max_q_update_step = options.min_max_q_update_step(:)';
    if numel(options.min_max_q_update_step) ~= numel(q_guess)
        error('min_max_q_update_step must be scalar or match initial_q_path length.');
    end
end
if ~isfield(options, 'root_polish_rounds') || isempty(options.root_polish_rounds)
    options.root_polish_rounds = 5;
end
if ~isfield(options, 'root_vote_tolerance') || isempty(options.root_vote_tolerance)
    options.root_vote_tolerance = 1.0e-3;
end
if ~isfield(options, 'root_q_tolerance') || isempty(options.root_q_tolerance)
    options.root_q_tolerance = 1.0e-2;
end
if ~isfield(options, 'verbose_progress') || isempty(options.verbose_progress)
    options.verbose_progress = false;
end
if ~isfield(options, 'compute_final_summary') || isempty(options.compute_final_summary)
    options.compute_final_summary = true;
end
if ~isfield(options, 'transition_backend') || isempty(options.transition_backend)
    options.transition_backend = 'matlab';
end
if ~isfield(options, 'sidecar_mex_toolchain_root') || isempty(options.sidecar_mex_toolchain_root)
    options.sidecar_mex_toolchain_root = "D:/codex_tools/winlibs-posix-ucrt/mingw64";
end
if ~isfield(options, 'sidecar_mex_force_rebuild') || isempty(options.sidecar_mex_force_rebuild)
    options.sidecar_mex_force_rebuild = false;
end
if ~isfield(options, 'transition_front_row_cache') || isempty(options.transition_front_row_cache)
    options.transition_front_row_cache = strcmpi(char(options.transition_backend), 'sidecar_mex');
end
if ~isfield(options, 'transition_vote_row_sidecar') || isempty(options.transition_vote_row_sidecar)
    options.transition_vote_row_sidecar = strcmpi(char(options.transition_backend), 'sidecar_mex');
end
end

function [implied_q_path, vote_rows, period_rows] = build_implied_q_path_local(q_guess, prev_implied_q_path, overrides, options)
T = numel(q_guess);
vote_rows = table();
period_rows = table();
implied_q_path = NaN(1, T);
iteration_cache = [];
if should_use_iteration_front_row_cache_local(options, q_guess)
    if options.verbose_progress
        fprintf('  building iteration cache...\n');
        drawnow;
    end
    iteration_cache = build_iteration_front_row_cache_local(q_guess, overrides, options);
    if options.verbose_progress
        fprintf('  iteration cache ready.\n');
        drawnow;
    end
end

if options.verbose_progress
    fprintf('  solving stationary seed at q_1...\n');
    drawnow;
end
stationary_seed = solve_household_path_fertility(q_guess(1), overrides, ...
    configure_solver_output_local( ...
        build_solver_options_re_local(options, options.rbPos_path(1), false), ...
        true, false, 'full'));
stationary_cross_section = build_stationary_cross_section_fertility( ...
    stationary_seed.tail_solution, stationary_seed.params, stationary_seed.core_env, true);
current_pre_cross_section = stationary_cross_section.pre;
entrant_density = current_pre_cross_section{1};
if options.verbose_progress
    fprintf('  stationary seed ready.\n');
    drawnow;
end

for t = 1:T
    if options.verbose_progress
        fprintf('  solving implied q_%d...\n', t);
        drawnow;
    end

    selection_anchor_q = q_guess(t);
    use_previous_anchor = strcmpi(char(options.root_selection_anchor), 'previous_implied');
    use_previous_anchor = use_previous_anchor || logical(options.root_selection_previous_implied_mask(t));
    hysteresis_anchor_q = NaN;
    tie_break_anchor_q = NaN;
    if use_previous_anchor && ...
            ~isempty(prev_implied_q_path) && numel(prev_implied_q_path) >= t && isfinite(prev_implied_q_path(t))
        selection_anchor_q = prev_implied_q_path(t);
    end
    if logical(options.branch_hysteresis_mask(t)) && ...
            ~isempty(prev_implied_q_path) && numel(prev_implied_q_path) >= t && isfinite(prev_implied_q_path(t))
        hysteresis_anchor_q = prev_implied_q_path(t);
    end
    if logical(options.branch_tie_break_mask(t)) && ...
            ~isempty(prev_implied_q_path) && numel(prev_implied_q_path) >= t && isfinite(prev_implied_q_path(t))
        tie_break_anchor_q = prev_implied_q_path(t);
    end

    [period_result, period_vote_rows] = solve_period_root_local( ...
        t, current_pre_cross_section, q_guess, selection_anchor_q, ...
        hysteresis_anchor_q, tie_break_anchor_q, overrides, options, iteration_cache);
    implied_q_path(t) = period_result.implied_q;

    if ~isempty(period_vote_rows)
        vote_rows = [vote_rows; period_vote_rows]; %#ok<AGROW>
    end
    period_rows = [period_rows; struct2table(orderfields(rmfield(period_result, 'selected_solver_results')))]; %#ok<AGROW>

    if t < T
        current_pre_cross_section = advance_one_period_local(current_pre_cross_section, entrant_density, period_result.selected_solver_results);
    end
end
end

function [period_result, vote_rows] = solve_period_root_local(period_idx, current_pre_cross_section, q_guess, selection_anchor_q, hysteresis_anchor_q, tie_break_anchor_q, overrides, options, iteration_cache)
T = numel(q_guess);
tail_q = q_guess((period_idx + 1):T);
rb_tail = options.rbPos_path(period_idx:T);
coarse_grid = sort(unique([options.q_search_grid(:); q_guess(period_idx)]));
future_cache = [];
if ~isempty(iteration_cache) && period_idx < T
    future_cache = extract_period_future_cache_local(iteration_cache, period_idx);
elseif should_use_front_row_cache_local(options, tail_q)
    future_cache = build_transition_future_cache_local(tail_q, rb_tail, overrides, options);
end

evals = evaluate_grid_local(coarse_grid, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);
brackets = find_vote_brackets_local(evals);
if isempty(brackets.lower_q)
    [evals, brackets] = expand_search_until_bracket_local(evals, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);
end
if isempty(brackets.lower_q)
    [evals, brackets] = fill_search_interval_local(evals, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);
end

if numel(brackets.lower_q) == 1 && options.q_refine_points >= 3
    refine_grid = linspace(brackets.lower_q(1), brackets.upper_q(1), options.q_refine_points);
    evals = evaluate_grid_local(refine_grid, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache, evals);
    brackets = find_vote_brackets_local(evals);
end

[implied_q, method, lower_q, upper_q, lower_vote, upper_vote, selected_eval] = ...
    select_root_local(evals, brackets, selection_anchor_q, hysteresis_anchor_q, tie_break_anchor_q, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);
selected_eval = ensure_selected_base_results_local(selected_eval, tail_q, rb_tail, overrides, options, future_cache);

period_result = struct();
period_result.period = period_idx;
period_result.implied_q = implied_q;
period_result.selection_anchor_q = selection_anchor_q;
period_result.hysteresis_anchor_q = hysteresis_anchor_q;
period_result.tie_break_anchor_q = tie_break_anchor_q;
period_result.root_method = string(method);
period_result.sign_change_count = numel(brackets.lower_q);
period_result.lower_q = lower_q;
period_result.upper_q = upper_q;
period_result.lower_vote = lower_vote;
period_result.upper_vote = upper_vote;
period_result.selected_vote = selected_eval.totalvote;
period_result.current_mass = selected_eval.total_mass;
period_result.selected_solver_results = selected_eval.base_results;

vote_rows = table();
for i = 1:numel(evals)
    row = struct2table(orderfields(struct( ...
        'period', period_idx, ...
        'q_candidate', evals(i).q, ...
        'totalvote', evals(i).totalvote, ...
        'total_mass', evals(i).total_mass)));
    vote_rows = [vote_rows; row]; %#ok<AGROW>
end
end

function evals = evaluate_grid_local(q_grid, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache, existing_evals)
if nargin < 8 || isempty(existing_evals)
    existing_evals = struct('q', {}, 'totalvote', {}, 'total_mass', {}, 'base_results', {});
end

evals = existing_evals;

for i = 1:numel(q_grid)
    q_value = q_grid(i);
    if any(abs([evals.q] - q_value) < 1e-12)
        continue;
    end

    [totalvote, total_mass, base_results] = evaluate_candidate_vote_local( ...
        q_value, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);

    evals(end + 1) = struct( ... %#ok<AGROW>
        'q', q_value, ...
        'totalvote', totalvote, ...
        'total_mass', total_mass, ...
        'base_results', base_results);
end

[~, order] = sort([evals.q]);
evals = evals(order);
end

function [evals, brackets] = expand_search_until_bracket_local(evals, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache)
brackets = find_vote_brackets_local(evals);
for round_idx = 1:options.max_expand_rounds
    if ~isempty(brackets.lower_q)
        return;
    end

    q_existing = [evals.q];
    left_candidate = max(options.q_min, min(q_existing) - options.q_expand_step);
    right_candidate = min(options.q_max, max(q_existing) + options.q_expand_step);
    add_grid = [];
    if left_candidate < min(q_existing) - 1e-12
        add_grid(end + 1) = left_candidate; %#ok<AGROW>
    end
    if right_candidate > max(q_existing) + 1e-12
        add_grid(end + 1) = right_candidate; %#ok<AGROW>
    end
    if isempty(add_grid)
        return;
    end

    evals = evaluate_grid_local(add_grid, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache, evals);
    brackets = find_vote_brackets_local(evals);
    if options.verbose_progress
        fprintf('    expanded root grid round %d: [%.3f, %.3f]\n', round_idx, min([evals.q]), max([evals.q]));
        drawnow;
    end
end
end

function [evals, brackets] = fill_search_interval_local(evals, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache)
brackets = find_vote_brackets_local(evals);
if ~isempty(brackets.lower_q)
    return;
end

for round_idx = 1:options.max_fill_rounds
    qs = sort(unique([evals.q]));
    gaps = diff(qs);
    add_grid = [];
    for i = 1:numel(gaps)
        if gaps(i) > options.q_fill_step + 1e-12
            add_grid(end + 1) = 0.5 * (qs(i) + qs(i + 1)); %#ok<AGROW>
        end
    end
    add_grid = unique(add_grid);
    if isempty(add_grid)
        return;
    end

    evals = evaluate_grid_local(add_grid, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache, evals);
    brackets = find_vote_brackets_local(evals);
    if options.verbose_progress
        fprintf('    bisected root grid round %d: %d new interior points\n', round_idx, numel(add_grid));
        drawnow;
    end
    if ~isempty(brackets.lower_q)
        return;
    end
end
end

function solver_options = build_solver_options_re_local(options, rb_pos_path, verbose_progress)
solver_options = struct( ...
    'rbPos_path', rb_pos_path, ...
    'verbose_progress', verbose_progress, ...
    'transition_backend', options.transition_backend, ...
    'sidecar_mex_toolchain_root', options.sidecar_mex_toolchain_root, ...
    'sidecar_mex_force_rebuild', options.sidecar_mex_force_rebuild);
end

function solver_options = configure_solver_output_local(solver_options, return_tail_solution, return_path_solution, path_solution_scope)
solver_options.return_tail_solution = logical(return_tail_solution);
solver_options.return_path_solution = logical(return_path_solution);
solver_options.path_solution_scope = char(string(path_solution_scope));
end

function use_cache = should_use_iteration_front_row_cache_local(options, q_guess)
use_cache = options.transition_front_row_cache && ...
    strcmpi(char(options.transition_backend), 'sidecar_mex') && ...
    numel(q_guess) > 1;
end

function iteration_cache = build_iteration_front_row_cache_local(q_guess, overrides, options)
solver_options = configure_solver_output_local( ...
    build_solver_options_re_local(options, options.rbPos_path, false), ...
    false, true, 'value_only');
iteration_cache = struct();
iteration_cache.base_full = solve_household_path_fertility(q_guess, overrides, solver_options);

switch lower(char(options.vote_dp_scope))
    case 'current_only'
        iteration_cache.dp_full = iteration_cache.base_full;
    case 'remaining_path'
        iteration_cache.dp_full = solve_household_path_fertility(q_guess * options.vote_dp_factor, overrides, solver_options);
    otherwise
        error('Unknown vote_dp_scope "%s".', options.vote_dp_scope);
end
end

function future_cache = extract_period_future_cache_local(iteration_cache, period_idx)
future_cache = struct();
future_cache.base_future = extract_future_results_row_local(iteration_cache.base_full, period_idx + 1);
future_cache.dp_future = extract_future_results_row_local(iteration_cache.dp_full, period_idx + 1);
end

function future_results = extract_future_results_row_local(full_results, next_t_idx)
future_results = struct();
future_results.params = full_results.params;
future_results.core_env = full_results.core_env;
future_results.path_solution = struct();
future_results.path_solution.value = full_results.path_solution.value(next_t_idx, :);
end

function use_cache = should_use_front_row_cache_local(options, tail_q)
use_cache = options.transition_front_row_cache && ...
    strcmpi(char(options.transition_backend), 'sidecar_mex') && ...
    ~isempty(tail_q);
end

function future_cache = build_transition_future_cache_local(tail_q, rb_tail, overrides, options)
future_solver_options = configure_solver_output_local( ...
    build_solver_options_re_local(options, rb_tail(2:end), false), ...
    false, true, 'value_only');
future_cache = struct();
future_cache.base_future = solve_household_path_fertility(tail_q, overrides, future_solver_options);

switch lower(char(options.vote_dp_scope))
    case 'current_only'
        future_cache.dp_future = future_cache.base_future;
    case 'remaining_path'
        future_cache.dp_future = solve_household_path_fertility(tail_q * options.vote_dp_factor, overrides, future_solver_options);
    otherwise
        error('Unknown vote_dp_scope "%s".', options.vote_dp_scope);
end
end

function [base_results, dp_results] = evaluate_candidate_solver_results_local(q_value, tail_q, rb_tail, overrides, options, future_cache)
q_path = [q_value, tail_q];
q_path_dp = build_dp_path_local(q_path, options);

if ~isempty(future_cache)
    base_results = run_transition_front_row_sidecar_local(q_value, rb_tail(1), future_cache.base_future, options);
    dp_results = run_transition_front_row_sidecar_local(q_path_dp(1), rb_tail(1), future_cache.dp_future, options);
    return;
end

base_results = solve_household_path_fertility(q_path, overrides, ...
    configure_solver_output_local( ...
        build_solver_options_re_local(options, rb_tail, false), ...
        false, true, 'full'));
dp_results = solve_household_path_fertility(q_path_dp, overrides, ...
    configure_solver_output_local( ...
        build_solver_options_re_local(options, rb_tail, false), ...
        false, true, 'full'));
end

function [totalvote, total_mass, base_results] = evaluate_candidate_vote_local(q_value, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache)
q_path = [q_value, tail_q];
q_path_dp = build_dp_path_local(q_path, options);

if should_use_front_row_vote_sidecar_local(options, future_cache)
    mex_result = run_transition_front_row_vote_sidecar_local( ...
        current_pre_cross_section, q_value, q_path_dp(1), rb_tail(1), ...
        future_cache.base_future, future_cache.dp_future, options);
    totalvote = mex_result.totalvote;
    total_mass = mex_result.total_mass;
    base_results = [];
    return;
end

[base_results, dp_results] = evaluate_candidate_solver_results_local(q_value, tail_q, rb_tail, overrides, options, future_cache);
[totalvote, total_mass] = compute_transition_vote_local(current_pre_cross_section, base_results, dp_results, options);
base_results = [];
end

function use_sidecar = should_use_front_row_vote_sidecar_local(options, future_cache)
use_sidecar = options.transition_vote_row_sidecar && ...
    strcmpi(char(options.transition_backend), 'sidecar_mex') && ...
    ~isempty(future_cache) && ...
    isfield(future_cache, 'base_future') && ~isempty(future_cache.base_future) && ...
    isfield(future_cache, 'dp_future') && ~isempty(future_cache.dp_future);
end

function selected_eval = ensure_selected_base_results_local(selected_eval, tail_q, rb_tail, overrides, options, future_cache)
if ~isempty(selected_eval.base_results)
    return;
end
selected_eval.base_results = solve_selected_candidate_results_local(selected_eval.q, tail_q, rb_tail, overrides, options, future_cache);
end

function base_results = solve_selected_candidate_results_local(q_value, tail_q, rb_tail, overrides, options, future_cache)
q_path = [q_value, tail_q];
if ~isempty(future_cache)
    base_results = run_transition_front_row_sidecar_local(q_value, rb_tail(1), future_cache.base_future, options);
    return;
end
base_results = solve_household_path_fertility(q_path, overrides, ...
    configure_solver_output_local( ...
        build_solver_options_re_local(options, rb_tail, false), ...
        false, true, 'full'));
end

function solver_results = run_transition_front_row_sidecar_local(q_current, rb_pos_current, future_results, options)
ensure_transition_sidecar_ready_local(options);

path_case = build_transition_front_row_case_struct(q_current, rb_pos_current, ...
    future_results.params, future_results.core_env, future_results, ...
    sprintf('front_row_q_%0.6f', q_current));
mex_result = fertility_transition_path_mex(path_case, 'front_row');

solver_results = struct();
solver_results.q_path = q_current;
solver_results.rb_pos_path = rb_pos_current;
solver_results.params = future_results.params;
solver_results.core_env = future_results.core_env;
solver_results.path_solution = mex_result.path_solution;
solver_results.transition_backend = 'sidecar_mex_front_row';
solver_results.backend_summary = rmfield(mex_result, {'tail_solution', 'path_solution'});
end

function mex_result = run_transition_vote_row_sidecar_local(current_pre_cross_section, base_results, dp_results, options)
ensure_transition_sidecar_ready_local(options);
vote_case = build_transition_vote_row_case_struct(current_pre_cross_section, base_results, dp_results);
mex_result = fertility_transition_path_mex(vote_case, 'vote_row');
end

function mex_result = run_transition_front_row_vote_sidecar_local(current_pre_cross_section, q_current, q_dp_current, rb_pos_current, base_future_results, dp_future_results, options)
ensure_transition_sidecar_ready_local(options);
vote_case = build_transition_front_row_vote_case_struct( ...
    current_pre_cross_section, q_current, q_dp_current, rb_pos_current, ...
    base_future_results, dp_future_results);
mex_result = fertility_transition_path_mex(vote_case, 'front_row_vote');
end

function ensure_transition_sidecar_ready_local(options)
persistent sidecar_ready

if isempty(sidecar_ready)
    project_root = fileparts(fileparts(mfilename('fullpath')));
    sidecar_matlab_dir = fullfile(project_root, 'compiled_sidecar', 'matlab');
    if ~exist(sidecar_matlab_dir, 'dir')
        error('Compiled sidecar MATLAB directory not found: %s', sidecar_matlab_dir);
    end

    if ~contains(path, sidecar_matlab_dir, 'IgnoreCase', ispc)
        addpath(sidecar_matlab_dir);
    end

    mex_path = build_transition_path_mex(options.sidecar_mex_toolchain_root, options.sidecar_mex_force_rebuild);
    bin_dir = fileparts(mex_path);
    if ~contains(path, bin_dir, 'IgnoreCase', ispc)
        addpath(bin_dir);
    end
    sidecar_ready = true;
end
end

function [totalvote, total_mass] = compute_transition_vote_local(current_pre_cross_section, base_results, dp_results, options)
if options.transition_vote_row_sidecar && strcmpi(char(options.transition_backend), 'sidecar_mex')
    mex_result = run_transition_vote_row_sidecar_local(current_pre_cross_section, base_results, dp_results, options);
    totalvote = mex_result.totalvote;
    total_mass = mex_result.total_mass;
    return;
end

env = base_results.core_env;
totalvote = 0.0;
total_mass = 0.0;
for age_pos = 1:env.age_n
    density_pre = current_pre_cross_section{age_pos};
    if isempty(density_pre)
        continue;
    end
    density_post = apply_policy_transition_local(density_pre, base_results.path_solution, age_pos, env);
    d_value = dp_results.path_solution.value{1, age_pos} - base_results.path_solution.value{1, age_pos};
    % The simulated transition cross sections already carry cohort weights.
    % Applying env.cohortsize / age_n again would double-weight ages and
    % shrink the total vote mass away from the steady-state normalization.
    totalvote = totalvote + sum(sign(d_value) .* density_post, 'all');
    total_mass = total_mass + sum(density_post(:));
end
end

function brackets = find_vote_brackets_local(evals)
lower_q = [];
upper_q = [];
lower_vote = [];
upper_vote = [];
votes = [evals.totalvote];
qs = [evals.q];

for i = 1:numel(qs)
    if votes(i) == 0
        lower_q(end + 1, 1) = qs(i); %#ok<AGROW>
        upper_q(end + 1, 1) = qs(i); %#ok<AGROW>
        lower_vote(end + 1, 1) = votes(i); %#ok<AGROW>
        upper_vote(end + 1, 1) = votes(i); %#ok<AGROW>
    end
end

for i = 1:(numel(qs) - 1)
    if votes(i) == 0 || votes(i + 1) == 0
        continue;
    end
    if sign(votes(i)) ~= sign(votes(i + 1))
        lower_q(end + 1, 1) = qs(i); %#ok<AGROW>
        upper_q(end + 1, 1) = qs(i + 1); %#ok<AGROW>
        lower_vote(end + 1, 1) = votes(i); %#ok<AGROW>
        upper_vote(end + 1, 1) = votes(i + 1); %#ok<AGROW>
    end
end

brackets = struct( ...
    'lower_q', lower_q, ...
    'upper_q', upper_q, ...
    'lower_vote', lower_vote, ...
    'upper_vote', upper_vote);
end

function [implied_q, method, lower_q, upper_q, lower_vote, upper_vote, selected_eval] = ...
    select_root_local(evals, brackets, selection_anchor_q, hysteresis_anchor_q, tie_break_anchor_q, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache)
lower_q = NaN;
upper_q = NaN;
lower_vote = NaN;
upper_vote = NaN;
used_hysteresis = false;
used_tie_break = false;

if ~isempty(brackets.lower_q)
    if numel(brackets.lower_q) == 1
        bracket_idx = 1;
    else
        root_estimates = estimate_bracket_roots_local(brackets);
        anchor_gaps = abs(root_estimates - selection_anchor_q);
        [~, anchor_idx] = min(anchor_gaps);
        bracket_idx = NaN;
        if isfinite(hysteresis_anchor_q)
            [best_hysteresis_gap, hysteresis_idx] = min(abs(root_estimates - hysteresis_anchor_q));
            if best_hysteresis_gap <= options.branch_hysteresis_q_tolerance
                bracket_idx = hysteresis_idx;
                used_hysteresis = true;
            end
        end
        if ~isfinite(bracket_idx)
            bracket_idx = anchor_idx;
            if isfinite(tie_break_anchor_q)
                near_mask = anchor_gaps <= anchor_gaps(anchor_idx) + options.branch_tie_break_q_tolerance;
                if nnz(near_mask) > 1
                    near_idx = find(near_mask);
                    [~, rel_idx] = min(abs(root_estimates(near_idx) - tie_break_anchor_q));
                    tie_break_idx = near_idx(rel_idx);
                    if tie_break_idx ~= anchor_idx
                        bracket_idx = tie_break_idx;
                        used_tie_break = true;
                    end
                end
            end
        end
    end

    lower_q = brackets.lower_q(bracket_idx);
    upper_q = brackets.upper_q(bracket_idx);
    lower_vote = brackets.lower_vote(bracket_idx);
    upper_vote = brackets.upper_vote(bracket_idx);
    if lower_q == upper_q || lower_vote == upper_vote
        implied_q = lower_q;
        method = 'exact_grid_zero';
    selected_eval = find_eval_by_q_local(evals, implied_q);
    return;
end
    lower_eval = find_eval_by_q_local(evals, lower_q);
    upper_eval = find_eval_by_q_local(evals, upper_q);
    [selected_eval, lower_eval, upper_eval] = polish_bracket_root_local( ...
        lower_eval, upper_eval, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);
    implied_q = selected_eval.q;
    lower_q = lower_eval.q;
    upper_q = upper_eval.q;
    lower_vote = lower_eval.totalvote;
    upper_vote = upper_eval.totalvote;
    if used_hysteresis
        method = 'bracket_polished_hysteresis';
    elseif used_tie_break
        method = 'bracket_polished_tiebreak';
    else
        method = 'bracket_polished';
    end
    return;
end

[~, idx] = min(abs([evals.totalvote]));
selected_eval = evals(idx);
implied_q = selected_eval.q;
if isempty(brackets.lower_q)
    method = 'closest_no_bracket';
else
    method = 'closest_multiple_brackets';
end
end

function root_estimates = estimate_bracket_roots_local(brackets)
root_estimates = 0.5 * (brackets.lower_q + brackets.upper_q);

for i = 1:numel(root_estimates)
    lower_q = brackets.lower_q(i);
    upper_q = brackets.upper_q(i);
    lower_vote = brackets.lower_vote(i);
    upper_vote = brackets.upper_vote(i);

    if ~isfinite(lower_vote) || ~isfinite(upper_vote) || abs(upper_vote - lower_vote) < 1e-12
        continue;
    end

    candidate = lower_q - lower_vote * (upper_q - lower_q) / (upper_vote - lower_vote);
    root_estimates(i) = min(max(candidate, lower_q), upper_q);
end
end

function selected_eval = find_eval_by_q_local(evals, q_value)
selected_eval = [];
for i = 1:numel(evals)
    if abs(evals(i).q - q_value) < 1e-10
        selected_eval = evals(i);
        return;
    end
end

[~, idx] = min(abs([evals.q] - q_value));
if abs(evals(idx).q - q_value) < 1e-6
    selected_eval = evals(idx);
end
end

function [best_eval, lower_eval, upper_eval] = polish_bracket_root_local(lower_eval, upper_eval, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache)
best_eval = lower_eval;
if abs(upper_eval.totalvote) < abs(best_eval.totalvote)
    best_eval = upper_eval;
end

for round_idx = 1:options.root_polish_rounds
    if abs(best_eval.totalvote) <= options.root_vote_tolerance
        return;
    end
    if upper_eval.q - lower_eval.q <= options.root_q_tolerance
        return;
    end

    candidate_q = 0.5 * (lower_eval.q + upper_eval.q);

    candidate_eval = evaluate_point_local(candidate_q, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);
    if abs(candidate_eval.totalvote) < abs(best_eval.totalvote)
        best_eval = candidate_eval;
    end
    if candidate_eval.totalvote == 0
        best_eval = candidate_eval;
        lower_eval = candidate_eval;
        upper_eval = candidate_eval;
        return;
    end

    if sign(candidate_eval.totalvote) == sign(lower_eval.totalvote)
        lower_eval = candidate_eval;
    else
        upper_eval = candidate_eval;
    end

    if options.verbose_progress
        fprintf('      root polish round %d: q=%.6f, vote=%.6f\n', round_idx, candidate_eval.q, candidate_eval.totalvote);
        drawnow;
    end
end
end

function eval_point = evaluate_point_local(q_value, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache)
[totalvote, total_mass, base_results] = evaluate_candidate_vote_local( ...
    q_value, tail_q, rb_tail, current_pre_cross_section, overrides, options, future_cache);

eval_point = struct( ...
    'q', q_value, ...
    'totalvote', totalvote, ...
    'total_mass', total_mass, ...
    'base_results', base_results);
end

function q_path_dp = build_dp_path_local(q_path, options)
q_path_dp = q_path;
switch lower(char(options.vote_dp_scope))
    case 'current_only'
        q_path_dp(1) = q_path_dp(1) * options.vote_dp_factor;
    case 'remaining_path'
        q_path_dp = q_path_dp * options.vote_dp_factor;
    otherwise
        error('Unknown vote_dp_scope "%s".', options.vote_dp_scope);
end
end

function next_pre_cross_section = advance_one_period_local(current_pre_cross_section, entrant_density, solver_results)
env = solver_results.core_env;
policy_solution = solver_results.path_solution;

next_pre_cross_section = cell(env.age_n, 1);
next_pre_cross_section{1} = entrant_density;
for age_pos = 2:env.age_n
    next_pre_cross_section{age_pos} = zeros(env.I, env.J, env.K, env.H, env.P);
end

for age_pos = 1:(env.age_n - 1)
    density_age = current_pre_cross_section{age_pos};
    if sum(density_age(:)) <= 0
        continue;
    end
    density_raw = apply_policy_transition_local(density_age, policy_solution, age_pos, env);
    density_next = apply_z_transition_local(density_raw, env.transitionmatrix(:, :, age_pos));
    age_scale = env.cohortsize(age_pos + 1) / env.cohortsize(age_pos);
    next_pre_cross_section{age_pos + 1} = next_pre_cross_section{age_pos + 1} + age_scale * density_next;
end
end

function density_raw = apply_policy_transition_local(density_prev, solution, age_pos, env)
policy_age = struct( ...
    'index_a', solution.index_a{1, age_pos}, ...
    'index_b', solution.index_b{1, age_pos}, ...
    'birth_prob', solution.birth_prob{1, age_pos}, ...
    'index_a_birth', solution.index_a_birth{1, age_pos}, ...
    'index_b_birth', solution.index_b_birth{1, age_pos});

density_raw = zeros(env.I, env.J, env.K, env.H, env.P);
leave_prob = env.leave_profile(age_pos);

for ih = 1:env.H
    home_count = env.home_grid(ih);
    ih_keep = ih;
    ih_decay = env.home_index(max(home_count - 1, 0));
    ih_birth_keep = env.home_index(min(home_count + 1, env.H - 1));
    ih_birth_decay = env.home_index(min(max(home_count - 1, 0) + 1, env.H - 1));

    for ip = 1:env.P
        ip_birth = env.parity_index(min(env.parity_grid(ip) + 1, env.P - 1));
        for iz = 1:env.K
            for ij = 1:env.J
                for ii = 1:env.I
                    mass = density_prev(ii, ij, iz, ih, ip);
                    if mass <= 0
                        continue;
                    end

                    prob = policy_age.birth_prob(ii, ij, iz, ih, ip);
                    nb = policy_age.index_b(ii, ij, iz, ih, ip);
                    na = policy_age.index_a(ii, ij, iz, ih, ip);
                    mass_nb = (1 - prob) * mass;
                    density_raw(nb, na, iz, ih_decay, ip) = density_raw(nb, na, iz, ih_decay, ip) + leave_prob * mass_nb;
                    density_raw(nb, na, iz, ih_keep, ip) = density_raw(nb, na, iz, ih_keep, ip) + (1 - leave_prob) * mass_nb;

                    if prob > 0
                        nb_b = policy_age.index_b_birth(ii, ij, iz, ih, ip);
                        na_b = policy_age.index_a_birth(ii, ij, iz, ih, ip);
                        mass_b = prob * mass;
                        density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) + leave_prob * mass_b;
                        density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) + (1 - leave_prob) * mass_b;
                    end
                end
            end
        end
    end
end
end

function density_next = apply_z_transition_local(density_current, z_transition)
[I, J, K, H, P] = size(density_current);
density_next = zeros(I, J, K, H, P);
for ih = 1:H
    for ip = 1:P
        for iz = 1:K
            for iz_next = 1:K
                density_next(:, :, iz_next, ih, ip) = density_next(:, :, iz_next, ih, ip) ...
                    + z_transition(iz, iz_next) * density_current(:, :, iz, ih, ip);
            end
        end
    end
end
end

function row = make_iteration_row_local(iteration, q_guess, implied_q_path, residual, damping_path, max_q_update_step, tightened_mask, rollback_applied, rollback_count, backtracking_used, backtracking_coordinate_used, backtracking_accepted, backtracking_rounds, backtracking_trial_max_abs_residual)
row_struct = struct('iteration', iteration);
row_struct.outer_tightened_any = any(tightened_mask);
row_struct.outer_tightened_count = sum(tightened_mask);
row_struct.rollback_applied = logical(rollback_applied);
row_struct.rollback_count = rollback_count;
row_struct.backtracking_used = logical(backtracking_used);
row_struct.backtracking_coordinate_used = logical(backtracking_coordinate_used);
row_struct.backtracking_accepted = logical(backtracking_accepted);
row_struct.backtracking_rounds = backtracking_rounds;
row_struct.backtracking_trial_max_abs_residual = backtracking_trial_max_abs_residual;
for t = 1:numel(q_guess)
    row_struct.(sprintf('q_guess_t%d', t)) = q_guess(t);
    row_struct.(sprintf('q_implied_t%d', t)) = implied_q_path(t);
    row_struct.(sprintf('q_residual_t%d', t)) = residual(t);
    row_struct.(sprintf('update_damping_t%d', t)) = damping_path(t);
    row_struct.(sprintf('update_cap_t%d', t)) = max_q_update_step(t);
    row_struct.(sprintf('tightened_t%d', t)) = tightened_mask(t);
end
row = struct2table(orderfields(row_struct));
end
