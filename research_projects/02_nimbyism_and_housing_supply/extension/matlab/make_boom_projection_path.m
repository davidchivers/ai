function demo = make_boom_projection_path(age_bins, num_periods, baseline_mass, boom_scale)
%MAKE_BOOM_PROJECTION_PATH Build a stylized boom cohort path across age bins.

age_bins = age_bins(:);
baseline_mass = baseline_mass(:);

if numel(age_bins) ~= numel(baseline_mass)
    error('age_bins and baseline_mass must have the same length.');
end

baseline_mass = baseline_mass ./ sum(baseline_mass);

num_ages = numel(age_bins);
mass_by_age = zeros(num_ages, num_periods);
boom_mass_by_age = zeros(num_ages, num_periods);
boom_age_bin = zeros(num_periods, 1);

for t = 1:num_periods
    peak_idx = min(t, num_ages);
    boom_age_bin(t) = age_bins(peak_idx);

    boom_profile = zeros(num_ages, 1);
    boom_profile(peak_idx) = 1.00;

    if peak_idx > 1
        boom_profile(peak_idx - 1) = 0.20;
    end
    if peak_idx < num_ages
        boom_profile(peak_idx + 1) = 0.35;
    end

    boom_profile = boom_scale * boom_profile;
    mass_t = baseline_mass + boom_profile;

    mass_by_age(:, t) = mass_t ./ sum(mass_t);
    boom_mass_by_age(:, t) = boom_profile ./ max(sum(boom_profile), eps);
end

demo = struct();
demo.age_bins = age_bins;
demo.num_periods = num_periods;
demo.baseline_mass = baseline_mass;
demo.mass_by_age = mass_by_age;
demo.boom_mass_by_age = boom_mass_by_age;
demo.boom_age_bin = boom_age_bin;
end
