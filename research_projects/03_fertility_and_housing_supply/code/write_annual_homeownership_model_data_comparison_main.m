function write_annual_homeownership_model_data_comparison_main()
% write_annual_homeownership_model_data_comparison_main.m
%
% Build age-profile owner-share comparisons for the annual model against
% pooled ACS B25007 age bins. This is a diagnostic figure only: the ACS
% object is by age of householder, so it should be read as a loose support
% comparison rather than an exact female-age target.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

this_code_dir = fullfile(project_root, 'code');
project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end
cd(this_code_dir);
clear SolveSS_function SolveSS_fertility ClearMarkets_fertility

ensure_external_matlab_data_paths();
cfg = fertility_benchmark_annual_config();

baseline_overrides = build_anchor_overrides(cfg);
[~, ~, ~, baseline_vote, ~, baseline_diag] = SolveSS_fertility([cfg.eval_price, cfg.rbPos], baseline_overrides);

drift_overrides = baseline_overrides;
drift_overrides.anticipated_price_drift_weight = 0.50;
drift_overrides.d_a_price = 1.05;
[~, ~, ~, drift_vote, ~, drift_diag] = SolveSS_fertility([cfg.eval_price, cfg.rbPos], drift_overrides);

ages = baseline_diag.ages(:);
baseline_owner_share = owner_share_by_age(baseline_diag);
drift_owner_share = owner_share_by_age(drift_diag);

age_profile_table = table(ages, baseline_owner_share, drift_owner_share, ...
    'VariableNames', {'age', 'baseline_owner_share', 'drift_owner_share'});
writetable(age_profile_table, fullfile(out_dir, 'annual_homeownership_model_age_profile.csv'));

bin_starts = [25; 35; 45; 55; 65];
bin_ends = [34; 44; 54; 64; 74];
baseline_bin_share = NaN(numel(bin_starts), 1);
drift_bin_share = NaN(numel(bin_starts), 1);
for i = 1:numel(bin_starts)
    baseline_bin_share(i) = weighted_bin_owner_share(baseline_diag, bin_starts(i), bin_ends(i));
    drift_bin_share(i) = weighted_bin_owner_share(drift_diag, bin_starts(i), bin_ends(i));
end

bin_table = table(bin_starts, bin_ends, baseline_bin_share, drift_bin_share, ...
    'VariableNames', {'bin_start', 'bin_end', 'baseline_bin_share', 'drift_bin_share'});
writetable(bin_table, fullfile(out_dir, 'annual_homeownership_model_binned_profile.csv'));

summary_path = fullfile(out_dir, 'annual_homeownership_model_profile_summary.txt');
fid = fopen(summary_path, 'w');
fprintf(fid, 'eval_price=%.2f\n', cfg.eval_price);
fprintf(fid, 'baseline_vote=%.6f\n', baseline_vote);
fprintf(fid, 'drift_vote=%.6f\n', drift_vote);
fprintf(fid, 'drift_weight=0.50\n');
fprintf(fid, 'future_price_factor=1.05\n');
fclose(fid);
end

function overrides = build_anchor_overrides(cfg)
overrides = cfg.overrides;
overrides.I = 16;
overrides.J = 4;
overrides.birth_utility_by_parity = [1.120, 1.240, 1.170];
overrides.child_utility = 0.020;
overrides.birth_cost = 0.050;
overrides.birth_price_coeff = 0.16;
overrides.lambda_crowd = 0.10;
overrides.theta_r = 0.85;
overrides.theta_r_child_penalty = 0.0;
overrides.housingmax = 15.0;
overrides.birth_age_weights = cfg.target_first_birth_age_share_annual;
overrides.realized_birth_weights = ones(size(cfg.target_first_birth_age_share_annual));
overrides.first_birth_realized_weights = repelem([1.00, 0.25, 0.040, 0.008], 5);
overrides.anticipated_price_drift_weight = 0.0;
overrides.d_a_price = 1.01;
end

function shares = owner_share_by_age(diagnostics)
ages = diagnostics.ages(:);
dens4 = diagnostics.dens4;
shares = NaN(numel(ages), 1);
for i = 1:numel(ages)
    age_slice = dens4(:, :, :, i);
    age_mass = sum(age_slice, 'all');
    renter_mass = sum(age_slice(:, 1, :), 'all');
    shares(i) = 1 - renter_mass / max(age_mass, 1e-12);
end
end

function value = weighted_bin_owner_share(diagnostics, age_lo, age_hi)
ages = diagnostics.ages(:);
dens4 = diagnostics.dens4;
mask = ages >= age_lo & ages <= age_hi;
idx = find(mask);
owner_mass = 0;
total_mass = 0;
for k = 1:numel(idx)
    i = idx(k);
    age_slice = dens4(:, :, :, i);
    age_mass = sum(age_slice, 'all');
    renter_mass = sum(age_slice(:, 1, :), 'all');
    owner_mass = owner_mass + (age_mass - renter_mass);
    total_mass = total_mass + age_mass;
end
value = owner_mass / max(total_mass, 1e-12);
end
