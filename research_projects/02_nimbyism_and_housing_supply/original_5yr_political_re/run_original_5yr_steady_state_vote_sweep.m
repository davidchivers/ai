function results = run_original_5yr_steady_state_vote_sweep(varargin)
% Run a non-invasive steady-state vote sweep on the original 5-year model.

defaults = struct();
defaults.prices = linspace(1.8, 2.2, 30);
defaults.rb_pos = 0.03;
defaults.output_dir = '';

opts = defaults;
if nargin >= 1 && ~isempty(varargin{1})
    opts.prices = varargin{1};
end
if nargin >= 2 && ~isempty(varargin{2})
    opts.rb_pos = varargin{2};
end
if nargin >= 3 && ~isempty(varargin{3})
    opts.output_dir = varargin{3};
end

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
project_root = fileparts(this_dir);
steadystate_dir = fullfile(project_root, 'code', 'steadystate');
extension_dir = fullfile(project_root, 'extensions', 're_no_politics');

if isempty(opts.output_dir)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    opts.output_dir = fullfile(this_dir, 'truth', ['steady_state_vote_sweep_', timestamp]);
end
if ~exist(opts.output_dir, 'dir')
    mkdir(opts.output_dir);
end

old_dir = pwd;
cleanup_dir = onCleanup(@() cd(old_dir));
cd(opts.output_dir);
addpath(steadystate_dir);
if exist(extension_dir, 'dir')
    addpath(extension_dir);
end
if exist('ensure_external_matlab_data_paths', 'file') == 2
    ensure_external_matlab_data_paths();
end
if exist('load_transition_matrix_data', 'file') ~= 2
    error('Could not find load_transition_matrix_data.m needed to stage TransitionMatrix.mat.');
end
[transitionmatrix, y_mid, z_lifecycle, initialdist] = load_transition_matrix_data();
save('TransitionMatrix.mat', 'transitionmatrix', 'y_mid', 'z_lifecycle', 'initialdist');

n_prices = numel(opts.prices);
price = zeros(n_prices, 1);
distance = zeros(n_prices, 1);
totalvote = zeros(n_prices, 1);
debtstock = zeros(n_prices, 1);

for ip = 1:n_prices
    current_price = opts.prices(ip);
    [distance(ip), price(ip), ~, totalvote(ip), debtstock(ip)] = ...
        solve_original_5yr_political_steady_state([current_price, opts.rb_pos]);
end

[best_distance, best_idx] = min(distance);
[best_vote_abs, best_vote_idx] = min(abs(totalvote));

crossing_idx = find(totalvote(1:end-1) .* totalvote(2:end) <= 0, 1, 'first');
has_bracket = ~isempty(crossing_idx);

results = struct();
results.prices = price;
results.distance = distance;
results.totalvote = totalvote;
results.debtstock = debtstock;
results.rb_pos = opts.rb_pos;
results.best_distance = best_distance;
results.best_distance_price = price(best_idx);
results.best_vote_abs = best_vote_abs;
results.best_vote_abs_price = price(best_vote_idx);
results.has_vote_bracket = has_bracket;
if has_bracket
    results.bracket_low_price = price(crossing_idx);
    results.bracket_high_price = price(crossing_idx + 1);
    results.bracket_low_vote = totalvote(crossing_idx);
    results.bracket_high_vote = totalvote(crossing_idx + 1);
else
    results.bracket_low_price = NaN;
    results.bracket_high_price = NaN;
    results.bracket_low_vote = NaN;
    results.bracket_high_vote = NaN;
end

summary_table = table(price, distance, totalvote, debtstock);
writetable(summary_table, fullfile(opts.output_dir, 'steady_state_vote_sweep.csv'));

summary_scalar = table( ...
    results.rb_pos, ...
    results.best_distance, ...
    results.best_distance_price, ...
    results.best_vote_abs, ...
    results.best_vote_abs_price, ...
    results.has_vote_bracket, ...
    results.bracket_low_price, ...
    results.bracket_high_price, ...
    results.bracket_low_vote, ...
    results.bracket_high_vote, ...
    'VariableNames', { ...
        'rb_pos', ...
        'best_distance', ...
        'best_distance_price', ...
        'best_vote_abs', ...
        'best_vote_abs_price', ...
        'has_vote_bracket', ...
        'bracket_low_price', ...
        'bracket_high_price', ...
        'bracket_low_vote', ...
        'bracket_high_vote'});
writetable(summary_scalar, fullfile(opts.output_dir, 'steady_state_vote_sweep_summary.csv'));

save(fullfile(opts.output_dir, 'steady_state_vote_sweep_results.mat'), 'results');

fprintf('Original 5-year steady-state vote sweep complete.\n');
fprintf('Output directory: %s\n', opts.output_dir);
fprintf('Best |vote| price: %.12f (|vote| = %.12f)\n', results.best_vote_abs_price, results.best_vote_abs);
if has_bracket
    fprintf('Vote sign change bracket: [%.12f, %.12f]\n', results.bracket_low_price, results.bracket_high_price);
else
    fprintf('No sign-change bracket found on supplied price grid.\n');
end
end
