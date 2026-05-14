function results = solve_reduced_form_price_path(operator, k, params, initial_guess)
% Solve the reduced-form bounded RE price path for the first k periods.

if nargin < 4
    initial_guess = [];
end
if nargin < 3 || isempty(params)
    params = struct();
end
if nargin < 2 || isempty(k)
    error('solve_reduced_form_price_path requires a positive horizon k.');
end

T_full = numel(operator.periods);
params = fill_default_params(params, operator);
start_index = params.start_index;
max_horizon = T_full - start_index + 1;
k = min(k, max_horizon);

guess = extend_guess(initial_guess, params.tail_price, k);
iteration_log = repmat(struct( ...
    'iteration', NaN, ...
    'max_abs_gap', NaN, ...
    'max_abs_log_gap', NaN, ...
    'price_min', NaN, ...
    'price_max', NaN), params.max_iter, 1);

converged = false;
iterations_completed = 0;

for iter = 1:params.max_iter
    [implied_unbounded, implied_bounded] = compute_implied_path(guess, operator, k, params, start_index);
    log_guess = log(guess);
    log_implied_bounded = log(implied_bounded);
    updated_log_guess = (1 - params.relaxation_weight) .* log_guess + ...
        params.relaxation_weight .* log_implied_bounded;
    updated_guess = exp(updated_log_guess);

    max_abs_gap = max(abs(implied_bounded - guess));
    max_abs_log_gap = max(abs(log_implied_bounded - log_guess));

    iteration_log(iter) = struct( ...
        'iteration', iter, ...
        'max_abs_gap', max_abs_gap, ...
        'max_abs_log_gap', max_abs_log_gap, ...
        'price_min', min(updated_guess), ...
        'price_max', max(updated_guess));

    guess = updated_guess;
    iterations_completed = iter;

    if max_abs_log_gap < params.tol
        converged = true;
        break;
    end
end

iteration_log = iteration_log(1:iterations_completed);
[implied_unbounded, implied_bounded, next_price_reference] = compute_implied_path(guess, operator, k, params, start_index);

tol = 1e-8;
hits_bound = any(guess <= params.price_min + tol) || any(guess >= params.price_max - tol);
if converged
    status = "converged";
elseif hits_bound
    status = "out_of_bounds";
else
    status = "max_iter";
end

results = struct();
results.status = status;
results.converged = converged;
results.iterations_completed = iterations_completed;
results.k = k;
results.start_index = start_index;
results.re_weight = params.re_weight;
results.relaxation_weight = params.relaxation_weight;
results.price_min = params.price_min;
results.price_max = params.price_max;
results.tail_price = params.tail_price;
results.final_price_path = guess(:);
results.implied_price_path = implied_bounded(:);
results.implied_price_path_unbounded = implied_unbounded(:);
results.next_price_reference = next_price_reference(:);
results.max_abs_gap = max(abs(implied_bounded - guess));
results.max_abs_log_gap = max(abs(log(implied_bounded) - log(guess)));
results.path_span = max(guess) - min(guess);
results.hits_bound = hits_bound;
results.looks_stable = converged && ~hits_bound && results.max_abs_gap < 0.01;
results.pressure_index = operator.pressure_index(start_index:start_index + k - 1);
results.young_share_25_44 = operator.young_share_25_44(start_index:start_index + k - 1);
results.periods = operator.periods(start_index:start_index + k - 1);
results.years = operator.years(start_index:start_index + k - 1);
results.iteration_log = iteration_log;
results.operator = operator;
end

function params = fill_default_params(params, operator)
defaults = struct();
defaults.max_iter = 100;
defaults.tol = 1e-8;
defaults.relaxation_weight = 0.50;
defaults.re_weight = 1.0;
defaults.price_min = 1.75;
defaults.price_max = 2.25;
defaults.tail_price = operator.tail_price;
defaults.start_index = 1;

default_names = fieldnames(defaults);
for i = 1:numel(default_names)
    name = default_names{i};
    if ~isfield(params, name) || isempty(params.(name))
        params.(name) = defaults.(name);
    end
end
end

function guess = extend_guess(initial_guess, tail_price, k)
if isempty(initial_guess)
    guess = tail_price .* ones(k, 1);
    return;
end

guess = initial_guess(:);
if numel(guess) >= k
    guess = guess(1:k);
else
    guess = [guess; tail_price .* ones(k - numel(guess), 1)];
end
end

function [implied_unbounded, implied_bounded, next_price_reference] = compute_implied_path(guess, operator, k, params, start_index)
tail_price = params.tail_price;
if k == 1
    next_price_reference = tail_price;
else
    next_price_reference = [guess(2:end); tail_price];
end

next_log_gap = log(next_price_reference) - operator.log_baseline_price;
implied_log_price = operator.intercept + ...
    operator.pressure_coeff .* operator.pressure_index(start_index:start_index + k - 1) + ...
    params.re_weight .* operator.next_price_coeff .* next_log_gap;

implied_unbounded = exp(implied_log_price);
implied_bounded = min(max(implied_unbounded, params.price_min), params.price_max);
end
