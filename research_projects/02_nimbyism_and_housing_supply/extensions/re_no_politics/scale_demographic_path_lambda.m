function scaled_path = scale_demographic_path_lambda(demographic_path, lambda)
% Interpolate the demographic transition toward the baseline year.
%
% lambda = 0 collapses the path to the baseline (no demographic transition).
% lambda = 1 returns the original demographic path.

validateattributes(demographic_path, {'struct'}, {'scalar', 'nonempty'}, mfilename, 'demographic_path');
validateattributes(lambda, {'double'}, {'scalar', 'finite', 'real', '>=', 0, '<=', 1}, mfilename, 'lambda');

if ~isfield(demographic_path, 'cohort_scale_by_age') || ~isfield(demographic_path, 'population_by_age')
    error('demographic_path must contain cohort_scale_by_age and population_by_age.');
end

baseline_population = demographic_path.population_by_age(1, :);
baseline_scale = ones(size(demographic_path.cohort_scale_by_age));
scaled_scale_by_age = baseline_scale + lambda .* (demographic_path.cohort_scale_by_age - baseline_scale);
scaled_population_by_age = baseline_population .* scaled_scale_by_age;

scaled_path = demographic_path;
scaled_path.lambda = lambda;
scaled_path.cohort_scale_by_age = scaled_scale_by_age;
scaled_path.population_by_age = scaled_population_by_age;
scaled_path.cohort_scale = mean(scaled_scale_by_age, 2);
scaled_path.description = sprintf('%s Lambda-scaled toward baseline with lambda = %.2f.', ...
    demographic_path.description, lambda);
end
