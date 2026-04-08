function cfg = fertility_benchmark_config()
% Canonical benchmark settings for the corrected-code household fertility block.

cfg.eval_price = 2.0;
cfg.eval_age = 50;
cfg.rbPos = 0.03;
cfg.full_price_grid = [1.5, 2.0, 2.5, 3.0];
cfg.market_price_grid = 1.5:0.25:3.5;
cfg.home_report_ages = [40, 50];
cfg.target_parity = [0.165, 0.193, 0.357, 0.285];

% Fast screening grid used only for stage-1 calibration passes.
cfg.stage1_solver_overrides = struct('I', 20, 'J', 6);

% Active benchmark calibration after the numerical-resolution check.
cfg.overrides = struct( ...
    'I', 60, ...
    'J', 14, ...
    'birth_utility_by_parity', [0.85, 1.10, 1.20], ...
    'child_utility', 0.02, ...
    'birth_cost', 0.06, ...
    'birth_price_coeff', 0.24, ...
    'lambda_crowd', 0.18);
end
