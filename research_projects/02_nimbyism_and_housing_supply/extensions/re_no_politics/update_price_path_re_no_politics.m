function [updated_price_path, diagnostics] = update_price_path_re_no_politics(current_price_path, implied_price_path, params)
% Update the guessed RE house-price path using a damped bounded log update.

if nargin < 3 || isempty(params)
    params = struct();
end
if ~isfield(params, 'damping'), params.damping = 0.25; end
if ~isfield(params, 'max_update_frac'), params.max_update_frac = 0.10; end

validateattributes(current_price_path, {'double'}, {'vector', 'nonempty', 'finite', 'real', 'positive'}, mfilename, 'current_price_path');
validateattributes(implied_price_path, {'double'}, {'vector', 'numel', numel(current_price_path), 'finite', 'real', 'positive'}, mfilename, 'implied_price_path');
validateattributes(params.damping, {'double'}, {'scalar', '>', 0, '<=', 1}, mfilename, 'params.damping');
validateattributes(params.max_update_frac, {'double'}, {'scalar', '>', 0, '<', 1}, mfilename, 'params.max_update_frac');

current_price_path = current_price_path(:);
implied_price_path = implied_price_path(:);

log_gap = log(implied_price_path) - log(current_price_path);
max_log_step = log(1 + params.max_update_frac);
clipped_log_gap = min(max(log_gap, -max_log_step), max_log_step);

updated_price_path = current_price_path .* exp(params.damping .* clipped_log_gap);

diagnostics = struct();
diagnostics.max_abs_update = max(abs(updated_price_path - current_price_path));
diagnostics.max_abs_gap = max(abs(implied_price_path - current_price_path));
diagnostics.damping = params.damping;
diagnostics.max_update_frac = params.max_update_frac;
diagnostics.max_abs_log_gap = max(abs(log_gap));
diagnostics.max_abs_clipped_log_gap = max(abs(clipped_log_gap));
end
