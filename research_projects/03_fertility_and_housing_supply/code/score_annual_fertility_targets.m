function scores = score_annual_fertility_targets(target_ranges, mean_age_value, share30_value, childless_value, shape_shares)
% score_annual_fertility_targets.m
%
% Central annual target scoring rule.
% The pooled 25+ first-birth timing shape is the main annual timing target,
% but it is judged roughly rather than bin-by-bin. The rough curve checks
% focus on:
%   1. enough late mass after age 35
%   2. not too much piling into ages 25-29 relative to 30-34
% Mean age and share 30+ remain lighter summary checks.
% Childlessness remains the separate stock-fertility target.

scores = struct();

mean_age_target = find_target(target_ranges, "mean_age_first_birth");
share30_target = find_target(target_ranges, "share_first_birth_30_plus");
childless_target = find_target(target_ranges, "childless_share_at_50");
shape_target_names = [ ...
    "share_first_birth_25_29", ...
    "share_first_birth_30_34", ...
    "share_first_birth_35_39", ...
    "share_first_birth_40_44_plus"];

shape_targets = cell(1, numel(shape_target_names));
for i = 1:numel(shape_target_names)
    shape_targets{i} = find_target(target_ranges, shape_target_names(i));
end

share_25_29 = shape_shares(1);
share_30_34 = shape_shares(2);
share_35_39 = shape_shares(3);
share_40_44_plus = shape_shares(4);

scores.late_mass_value = share_35_39 + share_40_44_plus;
scores.frontload_tilt_value = share_25_29 - share_30_34;
scores.top_tail_value = share_40_44_plus;

late_mass_target = shape_targets{3}.reference + shape_targets{4}.reference;
frontload_tilt_target = shape_targets{1}.reference - shape_targets{2}.reference;

% Rough-shape bands: broad enough to accept a curve that looks right,
% not an exact bin-by-bin fit.
late_mass_band = make_band(max(0.10, late_mass_target - 0.09), min(0.30, late_mass_target + 0.11));
frontload_tilt_band = make_band(frontload_tilt_target - 0.10, frontload_tilt_target + 0.20);

scores.shape_excesses = [ ...
    normalized_band_excess(scores.late_mass_value, late_mass_band), ...
    normalized_band_excess(scores.frontload_tilt_value, frontload_tilt_band)];

scores.mean_age_excess = normalized_band_excess(mean_age_value, mean_age_target);
scores.share30_excess = normalized_band_excess(share30_value, share30_target);
scores.childless_excess = normalized_band_excess(childless_value, childless_target);
scores.shape_score = mean(scores.shape_excesses);
scores.summary_timing_score = 0.25 * (scores.mean_age_excess + scores.share30_excess);
scores.timing_primary_score = scores.shape_score;
scores.primary_score = scores.shape_score + scores.summary_timing_score + scores.childless_excess;
scores.shape_pass = all(scores.shape_excesses == 0);
scores.summary_timing_pass = scores.mean_age_excess == 0 && scores.share30_excess == 0;
scores.timing_primary_pass = scores.shape_pass;
scores.primary_pass = scores.shape_pass && scores.childless_excess == 0;
end

function target = find_target(ranges, name)
all_targets = [ranges.primary(:); ranges.support(:); ranges.validation];
idx = find(strcmp(string({all_targets.name}), string(name)), 1);
if isempty(idx)
    error('Could not find target range "%s".', name);
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

function target = make_band(lower, upper)
target = struct('lower', lower, 'upper', upper);
end
