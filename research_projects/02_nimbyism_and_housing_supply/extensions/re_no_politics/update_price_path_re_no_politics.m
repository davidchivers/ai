function [updated_price_path, diagnostics] = update_price_path_re_no_politics(current_price_path, implied_price_path, params)
% Update the guessed RE house-price path using a damped regularized log update.

if nargin < 3 || isempty(params)
    params = struct();
end
if ~isfield(params, 'damping'), params.damping = 0.25; end
if ~isfield(params, 'max_update_frac'), params.max_update_frac = 0.10; end
if ~isfield(params, 'smoothing_weight'), params.smoothing_weight = 5.00; end
if ~isfield(params, 'terminal_anchor_weight'), params.terminal_anchor_weight = 0.50; end
if ~isfield(params, 'targeted_correction_weight'), params.targeted_correction_weight = 0.35; end
if ~isfield(params, 'max_targeted_periods'), params.max_targeted_periods = 3; end

validateattributes(current_price_path, {'double'}, {'vector', 'nonempty', 'finite', 'real', 'positive'}, mfilename, 'current_price_path');
validateattributes(implied_price_path, {'double'}, {'vector', 'numel', numel(current_price_path), 'finite', 'real', 'positive'}, mfilename, 'implied_price_path');
validateattributes(params.damping, {'double'}, {'scalar', '>', 0, '<=', 1}, mfilename, 'params.damping');
validateattributes(params.max_update_frac, {'double'}, {'scalar', '>', 0, '<', 1}, mfilename, 'params.max_update_frac');
validateattributes(params.smoothing_weight, {'double'}, {'scalar', '>=', 0}, mfilename, 'params.smoothing_weight');
validateattributes(params.terminal_anchor_weight, {'double'}, {'scalar', '>=', 0, '<=', 1}, mfilename, 'params.terminal_anchor_weight');
validateattributes(params.targeted_correction_weight, {'double'}, {'scalar', '>=', 0, '<=', 1}, mfilename, 'params.targeted_correction_weight');
validateattributes(params.max_targeted_periods, {'double'}, {'scalar', 'integer', '>=', 0}, mfilename, 'params.max_targeted_periods');

current_price_path = current_price_path(:);
implied_price_path = implied_price_path(:);

smoothed_implied_price_path = smooth_price_path(implied_price_path, current_price_path, params);
log_current_price_path = log(current_price_path);
log_smoothed_implied = log(smoothed_implied_price_path);
log_gap = log_smoothed_implied - log_current_price_path;
max_log_step = log(1 + params.max_update_frac);
clipped_log_gap = min(max(log_gap, -max_log_step), max_log_step);
target_log_path = log_current_price_path + params.damping .* clipped_log_gap;
proposed_log_path = solve_regularized_log_update(log_current_price_path, clipped_log_gap, params);
proposed_log_path = apply_targeted_residual_correction(proposed_log_path, target_log_path, clipped_log_gap, params);
updated_price_path = exp(proposed_log_path);

diagnostics = struct();
diagnostics.max_abs_update = max(abs(updated_price_path - current_price_path));
diagnostics.max_abs_gap = max(abs(implied_price_path - current_price_path));
diagnostics.max_abs_smoothed_gap = max(abs(smoothed_implied_price_path - current_price_path));
diagnostics.damping = params.damping;
diagnostics.max_update_frac = params.max_update_frac;
diagnostics.max_abs_log_gap = max(abs(log_gap));
diagnostics.max_abs_clipped_log_gap = max(abs(clipped_log_gap));
diagnostics.smoothed_implied_price_path = smoothed_implied_price_path;
diagnostics.raw_implied_price_path = implied_price_path;
diagnostics.smoothing_weight = params.smoothing_weight;
diagnostics.terminal_anchor_weight = params.terminal_anchor_weight;
diagnostics.log_update_step = proposed_log_path - log_current_price_path;
diagnostics.targeted_periods = find_targeted_periods(clipped_log_gap, params.max_targeted_periods);
diagnostics.targeted_correction_weight = params.targeted_correction_weight;
end

function smoothed_path = smooth_price_path(raw_path, current_path, params)
T = numel(raw_path);
log_raw_path = log(raw_path);
log_current_path = log(current_path);
smoothed_log_path = log_raw_path;
if T == 1
    smoothed_path = raw_path;
    return;
end

local_average = log_raw_path;
for t = 1:T
    left = max(1, t - 1);
    right = min(T, t + 1);
    local_average(t) = mean(log_raw_path(left:right));
end

mix_weight = params.smoothing_weight ./ (1 + params.smoothing_weight);
smoothed_log_path = (1 - mix_weight) .* log_raw_path + mix_weight .* local_average;
smoothed_log_path(end) = (1 - params.terminal_anchor_weight) .* smoothed_log_path(end) + ...
    params.terminal_anchor_weight .* log_current_path(end);
smoothed_path = exp(smoothed_log_path);
smoothed_path = max(smoothed_path, 1e-8);
end

function updated_log_path = solve_regularized_log_update(log_current_path, clipped_log_gap, params)
T = numel(log_current_path);
target_log_path = log_current_path + params.damping .* clipped_log_gap;

system_matrix = speye(T);
rhs = target_log_path;

if T >= 3 && params.smoothing_weight > 0
    second_diff = spdiags([ones(T, 1), -2 .* ones(T, 1), ones(T, 1)], [0, 1, 2], T - 2, T);
    system_matrix = system_matrix + params.smoothing_weight .* (second_diff' * second_diff);
end

if params.terminal_anchor_weight > 0
    terminal_selector = sparse(T, T);
    terminal_selector(T, T) = 1;
    system_matrix = system_matrix + params.terminal_anchor_weight .* terminal_selector;
    rhs(T) = rhs(T) + params.terminal_anchor_weight .* log_current_path(T);
end

updated_log_path = full(system_matrix \ rhs);
end

function adjusted_log_path = apply_targeted_residual_correction(updated_log_path, target_log_path, clipped_log_gap, params)
adjusted_log_path = updated_log_path;
targeted_periods = find_targeted_periods(clipped_log_gap, params.max_targeted_periods);

for idx = 1:numel(targeted_periods)
    t = targeted_periods(idx);
    left = max(1, t - 1);
    right = min(numel(updated_log_path), t + 1);
    local_anchor = mean(updated_log_path(left:right));
    blended_target = (1 - params.targeted_correction_weight) .* updated_log_path(t) + ...
        params.targeted_correction_weight .* (0.5 .* target_log_path(t) + 0.5 .* local_anchor);
    adjusted_log_path(t) = blended_target;
end
end

function targeted_periods = find_targeted_periods(clipped_log_gap, max_targeted_periods)
if max_targeted_periods == 0
    targeted_periods = zeros(0, 1);
    return;
end

[~, order] = sort(abs(clipped_log_gap), 'descend');
num_keep = min(max_targeted_periods, numel(order));
targeted_periods = sort(order(1:num_keep));
end
