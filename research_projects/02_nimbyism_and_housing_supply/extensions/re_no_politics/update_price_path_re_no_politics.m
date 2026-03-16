function [updated_price_path, diagnostics] = update_price_path_re_no_politics(current_price_path, implied_price_path, params)
% Update the guessed RE house-price path using simple damped iteration.

if nargin < 3 || isempty(params)
    params = struct();
end
if ~isfield(params, 'damping'), params.damping = 0.25; end

validateattributes(current_price_path, {'double'}, {'vector', 'nonempty', 'finite', 'real'}, mfilename, 'current_price_path');
validateattributes(implied_price_path, {'double'}, {'vector', 'numel', numel(current_price_path), 'finite', 'real'}, mfilename, 'implied_price_path');
validateattributes(params.damping, {'double'}, {'scalar', '>', 0, '<=', 1}, mfilename, 'params.damping');

current_price_path = current_price_path(:);
implied_price_path = implied_price_path(:);

updated_price_path = params.damping .* implied_price_path + (1 - params.damping) .* current_price_path;

diagnostics = struct();
diagnostics.max_abs_update = max(abs(updated_price_path - current_price_path));
diagnostics.max_abs_gap = max(abs(implied_price_path - current_price_path));
diagnostics.damping = params.damping;
end
