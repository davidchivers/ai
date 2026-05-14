function scores = score_annual_wealth_support_targets(target_ranges, metrics)
% score_annual_wealth_support_targets.m
%
% SCF age-profile balance-sheet support layer for the annual entrant-
% mixture branch. The preferred objects are share moments the normalized
% model can map to directly.

scores = struct();

support_names = [ ...
    "debt_holder_share_under_35", ...
    "debt_holder_share_35_44", ...
    "mortgaged_owner_share_under_35", ...
    "mortgaged_owner_share_35_44"];
support_values = [ ...
    metrics.debt_holder_share_under_35, ...
    metrics.debt_holder_share_35_44, ...
    metrics.mortgaged_owner_share_under_35, ...
    metrics.mortgaged_owner_share_35_44];

validation_names = [ ...
    "mortgaged_owner_share_45_54", ...
    "mortgaged_owner_share_55_64"];
validation_values = [ ...
    metrics.mortgaged_owner_share_45_54, ...
    metrics.mortgaged_owner_share_55_64];

scores.support_excesses = zeros(1, numel(support_names));
for i = 1:numel(support_names)
    scores.support_excesses(i) = normalized_band_excess(support_values(i), find_target(target_ranges, support_names(i)));
end

scores.validation_excesses = zeros(1, numel(validation_names));
for i = 1:numel(validation_names)
    scores.validation_excesses(i) = normalized_band_excess(validation_values(i), find_target(target_ranges, validation_names(i)));
end

scores.support_score = mean(scores.support_excesses);
scores.validation_score = mean(scores.validation_excesses);
scores.score = scores.support_score + 0.25 * scores.validation_score;
scores.pass = all(scores.support_excesses == 0);
scores.validation_pass = all(scores.validation_excesses == 0);
end

function target = find_target(ranges, name)
all_targets = [ranges.support(:); ranges.validation(:)];
idx = find(strcmp(string({all_targets.name}), string(name)), 1);
if isempty(idx)
    error('Could not find wealth target range "%s".', name);
end
target = all_targets(idx);
end

function value = normalized_band_excess(x, target)
if isnan(x)
    value = 1e6;
    return;
end
if x < target.lower
    excess = target.lower - x;
elseif x > target.upper
    excess = x - target.upper;
else
    excess = 0;
end
width = max(target.upper - target.lower, 1e-8);
value = excess / width;
end
