function scores = score_annual_homeownership_support_targets(target_ranges, owner_shares)
% score_annual_homeownership_support_targets.m
%
% Loose support scoring for annual homeownership targets. This is a light
% diagnostic layer, not a primary calibration gate.

scores = struct();

target_names = [ ...
    "owner_share_25_34", ...
    "owner_share_35_44", ...
    "owner_share_45_54"];

targets = cell(1, numel(target_names));
for i = 1:numel(target_names)
    targets{i} = find_target(target_ranges, target_names(i));
end

scores.excesses = zeros(1, numel(target_names));
for i = 1:numel(target_names)
    scores.excesses(i) = normalized_band_excess(owner_shares(i), targets{i});
end
scores.score = mean(scores.excesses);
scores.pass = all(scores.excesses == 0);
end

function target = find_target(ranges, name)
all_targets = [ranges.support(:); ranges.validation(:)];
idx = find(strcmp(string({all_targets.name}), string(name)), 1);
if isempty(idx)
    error('Could not find homeownership target range "%s".', name);
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
