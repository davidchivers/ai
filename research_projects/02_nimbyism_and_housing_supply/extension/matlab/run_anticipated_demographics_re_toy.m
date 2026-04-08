function results = run_anticipated_demographics_re_toy()
%RUN_ANTICIPATED_DEMOGRAPHICS_RE_TOY
% Reduced-form aggregate benchmark for forward-looking voting under an
% exogenous boom-driven electorate forecast.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
extension_dir = fileparts(this_dir);
results_dir = fullfile(extension_dir, 'results');

if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

params = struct();
params.age_bins = (25:5:90)';
params.num_periods = 18;
params.beta = 0.80;
params.lambda_re = 0.65;
params.kappa_price = 0.35;
params.boom_scale = 0.55;
params.baseline_mass = ones(numel(params.age_bins), 1);

% Younger cohorts are more pro-supply; older cohorts are more pro-price.
params.vote_kernel = tanh((params.age_bins - 52.5) ./ 12.0);
params.vote_kernel = params.vote_kernel ./ max(abs(params.vote_kernel));

demo = make_boom_projection_path( ...
    params.age_bins, ...
    params.num_periods, ...
    params.baseline_mass, ...
    params.boom_scale);

baseline_mass = params.baseline_mass ./ sum(params.baseline_mass);
theta_ss = params.vote_kernel' * baseline_mass;
theta_myopic = (params.vote_kernel' * demo.mass_by_age)';

theta_re = theta_myopic;
for t = 1:params.num_periods
    future_gap = theta_myopic((t + 1):end) - theta_ss;
    horizon = (1:numel(future_gap))';
    theta_re(t) = theta_myopic(t) + params.lambda_re * sum((params.beta .^ horizon) .* future_gap);
end

price_myopic = exp(params.kappa_price * (theta_myopic - theta_ss));
price_re = exp(params.kappa_price * (theta_re - theta_ss));

young_share = sum(demo.mass_by_age(params.age_bins <= 40, :), 1)';
old_share = sum(demo.mass_by_age(params.age_bins >= 60, :), 1)';

results_table = table( ...
    (0:(params.num_periods - 1))', ...
    demo.boom_age_bin, ...
    young_share, ...
    old_share, ...
    theta_myopic, ...
    theta_re, ...
    price_myopic, ...
    price_re, ...
    'VariableNames', { ...
        'period', ...
        'boom_age_bin', ...
        'young_share', ...
        'old_share', ...
        'theta_myopic', ...
        'theta_re', ...
        'price_index_myopic', ...
        'price_index_re' ...
    });

writetable(results_table, fullfile(results_dir, 'anticipated_demographics_re_toy.csv'));

fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(2, 1);

nexttile;
plot(results_table.period, results_table.theta_myopic, 'LineWidth', 2);
hold on;
plot(results_table.period, results_table.theta_re, '--', 'LineWidth', 2);
yline(theta_ss, ':', 'LineWidth', 1.2);
xlabel('Period');
ylabel('Support index');
title('Anticipated-demographics voting benchmark');
legend({'Myopic', 'Forward-looking', 'Steady state'}, 'Location', 'best');
box on;

nexttile;
plot(results_table.period, results_table.price_index_myopic, 'LineWidth', 2);
hold on;
plot(results_table.period, results_table.price_index_re, '--', 'LineWidth', 2);
yline(1.0, ':', 'LineWidth', 1.2);
xlabel('Period');
ylabel('Price index');
title('Price path implied by demographic-only electorate forecasts');
legend({'Myopic', 'Forward-looking', 'Steady state'}, 'Location', 'best');
box on;

exportgraphics(fig, fullfile(results_dir, 'anticipated_demographics_re_toy.png'));
close(fig);

results = struct();
results.params = params;
results.demo = demo;
results.table = results_table;
results.summary = struct( ...
    'theta_ss', theta_ss, ...
    'peak_price_myopic', max(price_myopic), ...
    'peak_price_re', max(price_re), ...
    'max_price_gap_re_minus_myopic', max(price_re - price_myopic));

disp('Toy anticipated-demographics RE experiment saved to extension/results/.');
disp(results.summary);
end
