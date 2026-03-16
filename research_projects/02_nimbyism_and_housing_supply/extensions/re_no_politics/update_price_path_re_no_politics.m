function [updated_price_path, diagnostics] = update_price_path_re_no_politics(current_price_path, implied_price_path, params)
% Update the guessed RE house-price path using a damped smoothed bounded log update.

if nargin < 3 || isempty(params)
    params = struct();
end
if ~isfield(params, 'damping'), params.damping = 0.25; end
if ~isfield(params, 'max_update_frac'), params.max_update_frac = 0.10; end
if ~isfield(params, 'smoothing_weight'), params.smoothing_weight = 0.50; end
if ~isfield(params, 'terminal_anchor_weight'), params.terminal_anchor_weight = 0.50; end

validateattributes(current_price_path, {'double'}, {'vector', 'nonempty', 'finite', 'real', 'positive'}, mfilename, 'current_price_path');
validateattributes(implied_price_path, {'double'}, {'vector', 'numel', numel(current_price_path), 'finite', 'real', 'positive'}, mfilename, 'implied_price_path');
validateattributes(params.damping, {'double'}, {'scalar', '>', 0, '<=', 1}, mfilename, 'params.damping');
validateattributes(params.max_update_frac, {'double'}, {'scalar', '>', 0, '<', 1}, mfilename, 'params.max_update_frac');
validateattributes(params.smoothing_weight, {'double'}, {'scalar', '>=', 0, '<=', 1}, mfilename, 'params.smoothing_weight');
validateattributes(params.terminal_anchor_weight, {'double'}, {'scalar', '>=', 0, '<=', 1}, mfilename, 'params.terminal_anchor_weight');

current_price_path = current_price_path(:);
implied_price_path = implied_price_path(:);

smoothed_implied_price_path = smooth_price_path(implied_price_path, current_price_path, params);
log_gap = log(smoothed_implied_price_path) - log(current_price_path);
max_log_step = log(1 + params.max_update_frac);
clipped_log_gap = min(max(log_gap, -max_log_step), max_log_step);

updated_price_path = current_price_path .* exp(params.damping .* clipped_log_gap);

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
end

function smoothed_path = smooth_price_path(raw_path, current_path, params)
T = numel(raw_path);
smoothed_path = raw_path;
if T == 1
    return;
end

local_average = raw_path;
for t = 1:T
    left = max(1, t - 1);
    right = min(T, t + 1);
    local_average(t) = mean(raw_path(left:right));
end

smoothed_path = (1 - params.smoothing_weight) .* raw_path + params.smoothing_weight .* local_average;
smoothed_path(end) = (1 - params.terminal_anchor_weight) .* smoothed_path(end) + ...
    params.terminal_anchor_weight .* current_path(end);
smoothed_path = max(smoothed_path, 1e-8);
end
