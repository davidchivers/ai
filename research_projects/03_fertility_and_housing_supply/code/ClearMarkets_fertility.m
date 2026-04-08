function [results_table, crossing] = ClearMarkets_fertility(price_grid, rbPos, overrides)
% Grid-search market clearing for the fertility extension.

if nargin < 1 || isempty(price_grid)
    price_grid = 1.5:0.25:3.5;
end
if nargin < 2 || isempty(rbPos)
    rbPos = 0.03;
end
if nargin < 3
    overrides = struct();
end

n = numel(price_grid);
distance = NaN(n, 1);
totalvote = NaN(n, 1);
debtstock = NaN(n, 1);
avg_birth_rate = NaN(n, 1);
mass_error = NaN(n, 1);
child0 = NaN(n, 1);
child1 = NaN(n, 1);
child2 = NaN(n, 1);
child3 = NaN(n, 1);
parity0 = NaN(n, 1);
parity1 = NaN(n, 1);
parity2 = NaN(n, 1);
parity3plus = NaN(n, 1);
home_any_50 = NaN(n, 1);
mean_home_children_50 = NaN(n, 1);

for i = 1:n
    [distance(i), ~, ~, totalvote(i), debtstock(i), diagnostics] = SolveSS_fertility([price_grid(i), rbPos], overrides);
    avg_birth_rate(i) = diagnostics.avg_birth_rate;
    mass_error(i) = max(abs(diagnostics.mass_post_policy - diagnostics.mass_pre_policy));
    child_shares = weighted_age_average(diagnostics.child_dist_by_age, diagnostics.age_mass);
    child0(i) = get_child_share(child_shares, 1);
    child1(i) = get_child_share(child_shares, 2);
    child2(i) = get_child_share(child_shares, 3);
    child3(i) = get_child_share(child_shares, 4);

    age50 = find(diagnostics.ages == 50, 1);
    parity_shares = diagnostics.parity_dist_by_age(age50, :);
    home_shares_50 = diagnostics.home_dist_by_age(age50, :);
    parity0(i) = get_child_share(parity_shares, 1);
    parity1(i) = get_child_share(parity_shares, 2);
    parity2(i) = get_child_share(parity_shares, 3);
    parity3plus(i) = get_child_share(parity_shares, 4);
    home_any_50(i) = 1 - home_shares_50(1);
    mean_home_children_50(i) = sum((0:(numel(home_shares_50) - 1)) .* home_shares_50);
end

results_table = table(price_grid(:), distance, totalvote, debtstock, avg_birth_rate, mass_error, ...
    child0, child1, child2, child3, ...
    parity0, parity1, parity2, parity3plus, home_any_50, mean_home_children_50, ...
    'VariableNames', {'a_price', 'distance', 'totalvote', 'debtstock', 'avg_birth_rate', ...
    'mass_error', 'share_child_0', 'share_child_1', 'share_child_2', 'share_child_3', ...
    'share_parity_0', 'share_parity_1', 'share_parity_2', 'share_parity_3plus', ...
    'share_home_any_50', 'mean_home_children_50'});

brackets = find_crossing_brackets(price_grid, totalvote);
crossing = struct( ...
    'exists', ~isempty(brackets.lower_prices), ...
    'is_unique', numel(brackets.lower_prices) == 1, ...
    'lower_price', NaN, ...
    'upper_price', NaN, ...
    'lower_vote', NaN, ...
    'upper_vote', NaN, ...
    'lower_prices', brackets.lower_prices, ...
    'upper_prices', brackets.upper_prices, ...
    'lower_votes', brackets.lower_votes, ...
    'upper_votes', brackets.upper_votes, ...
    'refined_price', NaN, ...
    'refined_vote', NaN, ...
    'method', '', ...
    'sign_change_count', numel(brackets.lower_prices));

if crossing.sign_change_count == 1
    crossing.lower_price = brackets.lower_prices(1);
    crossing.upper_price = brackets.upper_prices(1);
    crossing.lower_vote = brackets.lower_votes(1);
    crossing.upper_vote = brackets.upper_votes(1);
    crossing = refine_crossing(crossing, rbPos, overrides);
elseif crossing.sign_change_count > 1
    crossing.method = 'nonunique_multiple_crossings';
end

save('ClearMarkets_fertility.mat', 'results_table', 'crossing');
end

function crossing = refine_crossing(crossing, rbPos, overrides)
refine_grid = linspace(crossing.lower_price, crossing.upper_price, 7);
votes = NaN(numel(refine_grid), 1);
for i = 1:numel(refine_grid)
    [~, ~, ~, votes(i)] = SolveSS_fertility([refine_grid(i), rbPos], overrides);
end

for i = 1:(numel(refine_grid) - 1)
    if votes(i) == 0
        crossing.refined_price = refine_grid(i);
        crossing.refined_vote = votes(i);
        crossing.method = 'refined_grid_exact';
        return;
    end
    if sign(votes(i)) ~= sign(votes(i + 1))
        crossing.refined_price = interp1([votes(i), votes(i + 1)], [refine_grid(i), refine_grid(i + 1)], 0);
        crossing.refined_vote = 0;
        crossing.method = 'linear_interpolation';
        return;
    end
end

[~, idx] = min(abs(votes));
crossing.refined_price = refine_grid(idx);
crossing.refined_vote = votes(idx);
crossing.method = 'closest_refined_grid';
end

function share = get_child_share(child_shares, idx)
if numel(child_shares) >= idx
    share = child_shares(idx);
else
    share = NaN;
end
end

function weighted_mean = weighted_age_average(values_by_age, age_mass)
weights = age_mass(:);
weights = weights ./ sum(weights);
weighted_mean = weights' * values_by_age;
end

function brackets = find_crossing_brackets(price_grid, votes)
lower_prices = [];
upper_prices = [];
lower_votes = [];
upper_votes = [];

for i = 1:numel(price_grid)
    if votes(i) == 0
        lower_prices(end + 1, 1) = price_grid(i); %#ok<AGROW>
        upper_prices(end + 1, 1) = price_grid(i); %#ok<AGROW>
        lower_votes(end + 1, 1) = votes(i); %#ok<AGROW>
        upper_votes(end + 1, 1) = votes(i); %#ok<AGROW>
    end
end

for i = 1:(numel(price_grid) - 1)
    if votes(i) == 0 || votes(i + 1) == 0
        continue;
    end
    if sign(votes(i)) ~= sign(votes(i + 1))
        lower_prices(end + 1, 1) = price_grid(i); %#ok<AGROW>
        upper_prices(end + 1, 1) = price_grid(i + 1); %#ok<AGROW>
        lower_votes(end + 1, 1) = votes(i); %#ok<AGROW>
        upper_votes(end + 1, 1) = votes(i + 1); %#ok<AGROW>
    end
end

brackets = struct('lower_prices', lower_prices, 'upper_prices', upper_prices, ...
    'lower_votes', lower_votes, 'upper_votes', upper_votes);
end
