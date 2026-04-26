function [summary, results] = run_original_5yr_smoothed_tail_freezeprefix( ...
    political_response_sigma, run_label, run_tag_override, max_k, k_schedule, ...
    prefix_lock_length, basis_count, housing_clear_max_iter, seed_price_csv_override, ...
    seed_wedge_csv_override, max_outer_iter)
% Robust launcher for the frozen-prefix smoothed political tail diagnostic.

if nargin < 1 || isempty(political_response_sigma)
    political_response_sigma = 0.20;
end
if nargin < 2
    run_label = '';
end
if nargin < 3
    run_tag_override = '';
end
if nargin < 4 || isempty(max_k)
    max_k = 12;
end
if nargin < 5 || isempty(k_schedule)
    k_schedule = [11; 12];
end
if nargin < 6 || isempty(prefix_lock_length)
    prefix_lock_length = 10;
end
if nargin < 7 || isempty(basis_count)
    basis_count = 2;
end
if nargin < 8 || isempty(housing_clear_max_iter)
    housing_clear_max_iter = 2;
end
if nargin < 9
    seed_price_csv_override = '';
end
if nargin < 10
    seed_wedge_csv_override = '';
end
if nargin < 11 || isempty(max_outer_iter)
    max_outer_iter = 1;
end

script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir);

if ~isempty(run_tag_override)
    run_tag = char(string(run_tag_override));
elseif strcmpi(char(string(run_label)), 'tailactive') && abs(political_response_sigma - 0.20) < 1e-10
    run_tag = 'local_smoothtail_tailactive_s020_k11_12_b2_i1';
elseif strcmpi(char(string(run_label)), 'tailactive') && abs(political_response_sigma - 0.40) < 1e-10
    run_tag = 'local_smoothtail_tailactive_s040_k11_12_b2_i1';
elseif abs(political_response_sigma - 0.20) < 1e-10
    run_tag = 'local_smoothtail_freezeprefix_s020_k11_12_b2_i1';
elseif abs(political_response_sigma - 0.40) < 1e-10
    run_tag = 'local_smoothtail_freezeprefix_s040_k11_12_b2_i1';
else
    run_tag = sprintf('local_smoothtail_freezeprefix_s%03d_k11_12_b2_i1', round(100 .* political_response_sigma));
end

startup_log = fullfile(script_dir, 'truth', 'joint_supply_wedge', [run_tag '_startup.log']);
if exist(startup_log, 'file')
    delete(startup_log);
end
diary(startup_log);
cleanup_diary = onCleanup(@() diary('off'));

seed_price_csv = fullfile(script_dir, 'truth', 'joint_supply_wedge', ...
    'local_smoothk14_full_s020_relaxed', 'k10', ...
    'local_smoothk14_full_s020_relaxed_k10_final_price_path.csv');
seed_wedge_csv = fullfile(script_dir, 'truth', 'joint_supply_wedge', ...
    'local_smoothk14_full_s020_relaxed', 'k10', ...
    'local_smoothk14_full_s020_relaxed_k10_final_wedge_path.csv');
if ~isempty(seed_price_csv_override)
    seed_price_csv = char(string(seed_price_csv_override));
end
if ~isempty(seed_wedge_csv_override)
    seed_wedge_csv = char(string(seed_wedge_csv_override));
end

[summary, results] = run_original_5yr_joint_wedge_smoothed( ...
    max_k, max_outer_iter, basis_count, seed_price_csv, run_tag, 'historical_1950', ...
    0.01, 0.001, [0.5; 0.1], 0.08, 0.65, ...
    -0.5, 0.5, k_schedule(:), housing_clear_max_iter, political_response_sigma, ...
    seed_wedge_csv, prefix_lock_length);

disp(summary);
end
