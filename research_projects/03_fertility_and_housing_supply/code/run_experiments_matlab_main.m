function run_experiments_matlab_main()
% Run fertility experiments in MATLAB with a NIMBY-style baby-boom shock.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

p = default_params();
cfg.damping = 0.25;
cfg.boom_amp = 0.60;      % 60% temporary increase in births
cfg.boom_start = 15;      % shock starts at t=15
cfg.boom_end = 24;        % shock ends at t=24
cfg.post_start = 40;      % evaluate medium-run after shock fades

new_baseline = simulate_new_model(p, cfg.damping, 0.0, cfg.boom_start, cfg.boom_end);
new_policy = simulate_new_model(p, cfg.damping, cfg.boom_amp, cfg.boom_start, cfg.boom_end);
old_baseline = simulate_old_proxy(p, cfg.damping, 0.0, cfg.boom_start, cfg.boom_end);
old_policy = simulate_old_proxy(p, cfg.damping, cfg.boom_amp, cfg.boom_start, cfg.boom_end);
structural_baseline = simulate_structural_model(p, cfg.damping, 0.0, cfg.boom_start, cfg.boom_end);
structural_policy = simulate_structural_model(p, cfg.damping, cfg.boom_amp, cfg.boom_start, cfg.boom_end);

no_damp = simulate_new_model(p, 1.0, 0.0, cfg.boom_start, cfg.boom_end);
damped = new_baseline;
policy = new_policy;

writetable(struct2table(no_damp), fullfile(out_dir, 'model_experiment_no_damping.csv'));
writetable(struct2table(damped), fullfile(out_dir, 'model_experiment_damped.csv'));
writetable(struct2table(policy), fullfile(out_dir, 'model_experiment_policy.csv'));

model_summary = [...
    summarize(no_damp, "no_damping");
    summarize(damped, "damped");
    summarize(policy, "damped_baby_boom")];
writetable(struct2table(model_summary), fullfile(out_dir, 'model_experiment_summary.csv'));

writetable(struct2table(new_baseline), fullfile(out_dir, 'comparison_new_baseline.csv'));
writetable(struct2table(new_policy), fullfile(out_dir, 'comparison_new_policy.csv'));
writetable(struct2table(old_baseline), fullfile(out_dir, 'comparison_old_baseline.csv'));
writetable(struct2table(old_policy), fullfile(out_dir, 'comparison_old_policy.csv'));
writetable(struct2table(structural_baseline), fullfile(out_dir, 'comparison_structural_baseline.csv'));
writetable(struct2table(structural_policy), fullfile(out_dir, 'comparison_structural_policy.csv'));

summary = [...
    summarize(new_baseline, "new_baseline");
    summarize(old_baseline, "old_baseline_proxy");
    summarize(new_policy, "new_baby_boom");
    summarize(old_policy, "old_baby_boom_proxy");
    summarize(structural_baseline, "structural_baseline");
    summarize(structural_policy, "structural_baby_boom")];
writetable(struct2table(summary), fullfile(out_dir, 'comparison_summary_old_vs_new.csv'));

phase_summary = phase_deltas_three(new_baseline, new_policy, old_baseline, old_policy, structural_baseline, structural_policy, cfg);
writetable(struct2table(phase_summary), fullfile(out_dir, 'comparison_phase_summary.csv'));

t = new_baseline.t;
fig1 = figure('Visible', 'off', 'Position', [100, 100, 1200, 820]);
subplot(2,2,1); hold on;
plot(t, new_baseline.price, 'LineWidth', 1.5);
plot(t, old_baseline.price, 'LineWidth', 1.5);
plot(t, structural_baseline.price, 'LineWidth', 1.5, 'LineStyle', '--');
xline(cfg.boom_start, '--k'); xline(cfg.boom_end, '--k');
title('Price path (baseline)'); xlabel('t'); ylabel('log price index');
legend('Reduced-form', 'Old proxy', 'Structural FOC', 'Location', 'best'); grid on;

subplot(2,2,2); hold on;
plot(t, new_baseline.fertility_rate, 'LineWidth', 1.5);
plot(t, old_baseline.fertility_rate, 'LineWidth', 1.5);
plot(t, structural_baseline.fertility_rate, 'LineWidth', 1.5, 'LineStyle', '--');
xline(cfg.boom_start, '--k'); xline(cfg.boom_end, '--k');
title('Fertility rate (baseline)'); xlabel('t'); ylabel('fertility rate');
legend('Reduced-form', 'Old proxy', 'Structural FOC', 'Location', 'best'); grid on;

subplot(2,2,3); hold on;
plot(t, new_policy.price, 'LineWidth', 1.5);
plot(t, old_policy.price, 'LineWidth', 1.5);
plot(t, structural_policy.price, 'LineWidth', 1.5, 'LineStyle', '--');
xline(cfg.boom_start, '--k'); xline(cfg.boom_end, '--k');
title('Price path (baby boom shock)'); xlabel('t'); ylabel('log price index');
legend('Reduced-form', 'Old proxy', 'Structural FOC', 'Location', 'best'); grid on;

subplot(2,2,4); hold on;
plot(t, new_policy.fertility_rate, 'LineWidth', 1.5);
plot(t, old_policy.fertility_rate, 'LineWidth', 1.5);
plot(t, structural_policy.fertility_rate, 'LineWidth', 1.5, 'LineStyle', '--');
xline(cfg.boom_start, '--k'); xline(cfg.boom_end, '--k');
title('Fertility rate (baby boom shock)'); xlabel('t'); ylabel('fertility rate');
legend('Reduced-form', 'Old proxy', 'Structural FOC', 'Location', 'best'); grid on;

exportgraphics(fig1, fullfile(out_dir, 'old_vs_new_paths.png'), 'Resolution', 200);
close(fig1);

fig2 = figure('Visible', 'off', 'Position', [100, 100, 1200, 450]);
subplot(1,2,1); hold on;
plot(t, new_policy.fertility_rate - new_baseline.fertility_rate, 'LineWidth', 1.5);
plot(t, old_policy.fertility_rate - old_baseline.fertility_rate, 'LineWidth', 1.5);
plot(t, structural_policy.fertility_rate - structural_baseline.fertility_rate, 'LineWidth', 1.5, 'LineStyle', '--');
xline(cfg.boom_start, '--k'); xline(cfg.boom_end, '--k');
yline(0, '--k');
title('Baby-boom effect on fertility'); xlabel('t'); ylabel('shock - baseline');
legend('Reduced-form', 'Old proxy', 'Structural FOC', 'Location', 'best'); grid on;

subplot(1,2,2); hold on;
plot(t, new_policy.price - new_baseline.price, 'LineWidth', 1.5);
plot(t, old_policy.price - old_baseline.price, 'LineWidth', 1.5);
plot(t, structural_policy.price - structural_baseline.price, 'LineWidth', 1.5, 'LineStyle', '--');
xline(cfg.boom_start, '--k'); xline(cfg.boom_end, '--k');
yline(0, '--k');
title('Baby-boom effect on price'); xlabel('t'); ylabel('shock - baseline');
legend('Reduced-form', 'Old proxy', 'Structural FOC', 'Location', 'best'); grid on;

exportgraphics(fig2, fullfile(out_dir, 'old_vs_new_policy_effects.png'), 'Resolution', 200);
close(fig2);

fig3 = figure('Visible', 'off', 'Position', [100, 100, 1000, 430]);
subplot(1,2,1); hold on;
plot(no_damp.t, no_damp.price, 'LineWidth', 1.5);
plot(damped.t, damped.price, 'LineWidth', 1.5);
title('Price path: damping test'); xlabel('t'); ylabel('log price index');
legend('No damping', 'Damping 0.25', 'Location', 'best'); grid on;

subplot(1,2,2); hold on;
plot(damped.t, damped.fertility_rate, 'LineWidth', 1.5);
plot(policy.t, policy.fertility_rate, 'LineWidth', 1.5);
xline(cfg.boom_start, '--k'); xline(cfg.boom_end, '--k');
title('Fertility rate: baby-boom experiment'); xlabel('t'); ylabel('fertility rate');
legend('Baseline', 'Baby boom shock', 'Location', 'best'); grid on;

exportgraphics(fig3, fullfile(out_dir, 'model_experiment_paths.png'), 'Resolution', 200);
close(fig3);

write_text_report(out_dir, cfg, summary, phase_summary);
disp('MATLAB fertility experiments complete (baby-boom design).');
end

function p = default_params()
p.T = 80;
p.J = 8;
p.fertile_idx = [3,4,5];
p.leave_home_lag = 2;
p.surv = [0.98, 0.995, 0.995, 0.992, 0.99, 0.985, 0.97];
p.f_level = 0.22;
p.f_price_semi_elasticity = 0.20;
p.theta0 = 0.20;
p.theta_old = 0.90;
p.theta_young = 0.15;
p.theta_boom_nimby = 4.00;
p.nimby_lag = 18;
p.nimby_window = 10;
p.eps0 = 0.90;
p.d0 = 0.95;
p.d_young = 1.00;
p.d_birth = 0.30;
p.s0 = 1.00;
p.price_gain = 0.35;
% structural crowding-utility parameters (project-03 extension)
p.zeta = 0.20;        % housing share in Cobb-Douglas utility
p.gamma_risk = 2.0;   % risk aversion / IES
p.chi = 0.15;         % weight on child utility
p.eta_child = 0.50;   % curvature on child utility (< 1 for concavity)
p.lambda_crowd = 0.30;% crowding sensitivity per child
p.psi_crowd = 0.60;   % crowding exponent
p.y_mean = 1.0;       % normalised mean income
end

function out = simulate_new_model(p, damping, boom_amp, boom_start, boom_end)
M = zeros(p.T + 1, p.J);
M(1,:) = [0.14, 0.13, 0.14, 0.14, 0.13, 0.12, 0.11, 0.09];
M(1,:) = M(1,:) / sum(M(1,:));

prices = zeros(p.T + 1, 1);
births = zeros(p.T, 1);
fert = zeros(p.T, 1);
theta = zeros(p.T, 1);
young = zeros(p.T, 1);
old = zeros(p.T, 1);
lagged_births = zeros(p.leave_home_lag + 1, 1);
nimby_birth_hist = zeros(p.nimby_lag + p.nimby_window, 1);

for t = 1:p.T
    tt = t - 1;
    young(t) = M(t,1) + M(t,2);
    old(t) = M(t,6) + M(t,7) + M(t,8);

    n_home_proxy = sum(lagged_births(1:end-1));
    fertile_mass = max(sum(M(t, p.fertile_idx)), 1e-9);

    f_arg = max(-20.0, min(20.0, -p.f_price_semi_elasticity * prices(t)));
    desired_f = max(0.05, min(0.85, p.f_level * exp(f_arg)));

    if tt >= boom_start && tt <= boom_end
        boom_mult = 1.0 + boom_amp;
    else
        boom_mult = 1.0;
    end
    births(t) = desired_f * fertile_mass * boom_mult;
    fert(t) = births(t) / fertile_mass;

    nimby_entrants = mean(nimby_birth_hist((p.nimby_lag + 1):(p.nimby_lag + p.nimby_window)));
    theta_raw = p.theta0 + p.theta_old * old(t) - p.theta_young * young(t) + p.theta_boom_nimby * nimby_entrants;
    theta(t) = max(0.0, min(0.95, theta_raw));
    demand = p.d0 + p.d_young * young(t) + p.d_birth * births(t) + 0.15 * n_home_proxy;
    s_arg = max(-20.0, min(20.0, -prices(t)));
    supply = p.s0 + p.eps0 * (1.0 - theta(t)) * exp(s_arg);
    desired = prices(t) + p.price_gain * (demand - supply);

    prices(t + 1) = (1.0 - damping) * prices(t) + damping * desired;
    prices(t + 1) = max(-6.0, min(6.0, prices(t + 1)));

    M(t + 1, 1) = births(t);
    for j = 2:p.J
        M(t + 1, j) = p.surv(j - 1) * M(t, j - 1);
    end
    row_sum = sum(M(t + 1, :));
    if row_sum > 0
        M(t + 1, :) = M(t + 1, :) / row_sum;
    end

    lagged_births = [births(t); lagged_births(1:end-1)];
    nimby_birth_hist = [births(t); nimby_birth_hist(1:end-1)];
end

out.t = (0:(p.T - 1))';
out.price = prices(1:p.T);
out.births = births;
out.fertility_rate = fert;
out.young_share = young;
out.old_share = old;
out.theta = theta;
end

function out = simulate_old_proxy(p, damping, boom_amp, boom_start, boom_end)
M = zeros(p.T + 1, p.J);
M(1,:) = [0.14, 0.13, 0.14, 0.14, 0.13, 0.12, 0.11, 0.09];
M(1,:) = M(1,:) / sum(M(1,:));

prices = zeros(p.T + 1, 1);
births = zeros(p.T, 1);
fert = zeros(p.T, 1);
theta = zeros(p.T, 1);
young = zeros(p.T, 1);
old = zeros(p.T, 1);
nimby_birth_hist = zeros(p.nimby_lag + p.nimby_window, 1);

fertile0 = max(sum(M(1, p.fertile_idx)), 1e-9);
fixed_births = p.f_level * fertile0;

for t = 1:p.T
    tt = t - 1;
    young(t) = M(t,1) + M(t,2);
    old(t) = M(t,6) + M(t,7) + M(t,8);
    fertile_mass = max(sum(M(t, p.fertile_idx)), 1e-9);

    if tt >= boom_start && tt <= boom_end
        boom_mult = 1.0 + boom_amp;
    else
        boom_mult = 1.0;
    end

    births(t) = fixed_births * boom_mult;
    fert(t) = births(t) / fertile_mass;

    nimby_entrants = mean(nimby_birth_hist((p.nimby_lag + 1):(p.nimby_lag + p.nimby_window)));
    theta_raw = p.theta0 + p.theta_old * old(t) - p.theta_young * young(t) + p.theta_boom_nimby * nimby_entrants;
    theta(t) = max(0.0, min(0.95, theta_raw));
    demand = p.d0 + p.d_young * young(t);
    supply = p.s0 + p.eps0 * (1.0 - theta(t)) * exp(max(-20.0, min(20.0, -prices(t))));
    desired = prices(t) + p.price_gain * (demand - supply);

    prices(t + 1) = (1.0 - damping) * prices(t) + damping * desired;
    prices(t + 1) = max(-6.0, min(6.0, prices(t + 1)));

    M(t + 1, 1) = births(t);
    for j = 2:p.J
        M(t + 1, j) = p.surv(j - 1) * M(t, j - 1);
    end
    row_sum = sum(M(t + 1, :));
    if row_sum > 0
        M(t + 1, :) = M(t + 1, :) / row_sum;
    end
    nimby_birth_hist = [births(t); nimby_birth_hist(1:end-1)];
end

out.t = (0:(p.T - 1))';
out.price = prices(1:p.T);
out.births = births;
out.fertility_rate = fert;
out.young_share = young;
out.old_share = old;
out.theta = theta;
end

function out = simulate_structural_model(p, damping, boom_amp, boom_start, boom_end)
% Structural crowding-utility fertility model.
% Fertility is derived from the FOC of the paper's utility function:
%   u = (c^(1-zeta) * h_eff^zeta)^(1-gamma)/(1-gamma) + chi*n^(1-eta)/(1-eta)
%   h_eff = h / (1 + lambda*n)^psi
% FOC w.r.t. n:
%   chi * n^(-eta) = zeta*psi*lambda/(1+lambda*n) * [c^(1-zeta)*h_eff^zeta]^(1-gamma)

M = zeros(p.T + 1, p.J);
M(1,:) = [0.14, 0.13, 0.14, 0.14, 0.13, 0.12, 0.11, 0.09];
M(1,:) = M(1,:) / sum(M(1,:));

prices = zeros(p.T + 1, 1);
births = zeros(p.T, 1);
fert = zeros(p.T, 1);
theta = zeros(p.T, 1);
young = zeros(p.T, 1);
old = zeros(p.T, 1);
n_home_series = zeros(p.T, 1);
lagged_births = zeros(p.leave_home_lag + 1, 1);
nimby_birth_hist = zeros(p.nimby_lag + p.nimby_window, 1);

for t = 1:p.T
    tt = t - 1;
    young(t) = M(t,1) + M(t,2);
    old(t) = M(t,6) + M(t,7) + M(t,8);

    n_home_proxy = sum(lagged_births(1:end-1));
    n_home_series(t) = n_home_proxy;
    fertile_mass = max(sum(M(t, p.fertile_idx)), 1e-9);

    % Representative fertile household allocation given price
    ph = exp(prices(t));  % price level (prices stored in logs)
    y = p.y_mean;
    % Cobb-Douglas demand: housing share zeta of income
    h_demanded = max(p.zeta * y / max(ph, 0.01), 0.01);
    c_demanded = max((1 - p.zeta) * y, 0.01);

    % Solve structural FOC for optimal n
    desired_n = solve_fertility_foc(p, c_demanded, h_demanded, n_home_proxy);

    if tt >= boom_start && tt <= boom_end
        boom_mult = 1.0 + boom_amp;
    else
        boom_mult = 1.0;
    end
    births(t) = desired_n * fertile_mass * boom_mult;
    fert(t) = births(t) / fertile_mass;

    % Political tightness (same as reduced-form model)
    nimby_entrants = mean(nimby_birth_hist((p.nimby_lag + 1):(p.nimby_lag + p.nimby_window)));
    theta_raw = p.theta0 + p.theta_old * old(t) - p.theta_young * young(t) + p.theta_boom_nimby * nimby_entrants;
    theta(t) = max(0.0, min(0.95, theta_raw));

    % Housing market clearing (same as reduced-form model)
    demand = p.d0 + p.d_young * young(t) + p.d_birth * births(t) + 0.15 * n_home_proxy;
    s_arg = max(-20.0, min(20.0, -prices(t)));
    supply = p.s0 + p.eps0 * (1.0 - theta(t)) * exp(s_arg);
    desired = prices(t) + p.price_gain * (demand - supply);

    prices(t + 1) = (1.0 - damping) * prices(t) + damping * desired;
    prices(t + 1) = max(-6.0, min(6.0, prices(t + 1)));

    % Demographics transition
    M(t + 1, 1) = births(t);
    for j = 2:p.J
        M(t + 1, j) = p.surv(j - 1) * M(t, j - 1);
    end
    row_sum = sum(M(t + 1, :));
    if row_sum > 0
        M(t + 1, :) = M(t + 1, :) / row_sum;
    end

    lagged_births = [births(t); lagged_births(1:end-1)];
    nimby_birth_hist = [births(t); nimby_birth_hist(1:end-1)];
end

out.t = (0:(p.T - 1))';
out.price = prices(1:p.T);
out.births = births;
out.fertility_rate = fert;
out.young_share = young;
out.old_share = old;
out.theta = theta;
out.n_home = n_home_series;
end

function n_star = solve_fertility_foc(p, c, h, n_home_current)
% Solve the crowding-utility FOC for optimal fertility rate n.
%
% FOC: chi * n^(-eta) = zeta*psi*lambda/(1+lambda*n_total) * X^(1-gamma)
% where n_total = n_home_current + n (existing + new children),
%       h_eff = h / (1 + lambda*n_total)^psi,
%       X = c^(1-zeta) * h_eff^zeta.
%
% We solve by bisection on the net benefit:
%   G(n) = chi * n^(-eta) - zeta*psi*lambda/(1+lambda*n_total) * X^(1-gamma)
% G > 0 means marginal child utility exceeds crowding cost -> want more children.

n_lo = 0.01;
n_hi = 0.95;

for iter = 1:60
    n_mid = 0.5 * (n_lo + n_hi);
    g = foc_residual(p, c, h, n_home_current, n_mid);
    if g > 0
        n_lo = n_mid;  % child utility still exceeds cost, push n up
    else
        n_hi = n_mid;  % cost exceeds child utility, push n down
    end
    if (n_hi - n_lo) < 1e-8
        break;
    end
end
n_star = max(0.05, min(0.85, 0.5 * (n_lo + n_hi)));
end

function g = foc_residual(p, c, h, n_home_current, n)
% Evaluate G(n) = marginal child utility - marginal crowding cost.
n_total = n_home_current + n;
h_eff = h / (1 + p.lambda_crowd * n_total)^p.psi_crowd;
X = c^(1 - p.zeta) * h_eff^p.zeta;
X_pow = X^(1 - p.gamma_risk);

marginal_child = p.chi * n^(-p.eta_child);
marginal_crowd = p.zeta * p.psi_crowd * p.lambda_crowd / (1 + p.lambda_crowd * n_total) * X_pow;
g = marginal_child - marginal_crowd;
end

function s = summarize(df, label)
mask = (df.t >= 10);
price_diff = abs(diff(df.price));
s.scenario = string(label);
s.avg_price_t10_79 = mean(df.price(mask));
s.avg_fertility_t10_79 = mean(df.fertility_rate(mask));
s.avg_births_t10_79 = mean(df.births(mask));
s.final_price = df.price(end);
s.final_fertility = df.fertility_rate(end);
s.max_abs_price_change = max(price_diff);
end

function out = phase_deltas_three(new_b, new_s, old_b, old_s, str_b, str_s, cfg)
pre = (new_b.t < cfg.boom_start);
boom = (new_b.t >= cfg.boom_start) & (new_b.t <= cfg.boom_end);
post = (new_b.t >= cfg.post_start);

out = repmat(struct( ...
    'model', "", ...
    'delta_fertility_pre', 0.0, ...
    'delta_fertility_boom', 0.0, ...
    'delta_fertility_post', 0.0, ...
    'delta_price_pre', 0.0, ...
    'delta_price_boom', 0.0, ...
    'delta_price_post', 0.0), 3, 1);

out(1).model = "reduced_form";
out(1).delta_fertility_pre = mean(new_s.fertility_rate(pre) - new_b.fertility_rate(pre));
out(1).delta_fertility_boom = mean(new_s.fertility_rate(boom) - new_b.fertility_rate(boom));
out(1).delta_fertility_post = mean(new_s.fertility_rate(post) - new_b.fertility_rate(post));
out(1).delta_price_pre = mean(new_s.price(pre) - new_b.price(pre));
out(1).delta_price_boom = mean(new_s.price(boom) - new_b.price(boom));
out(1).delta_price_post = mean(new_s.price(post) - new_b.price(post));

out(2).model = "old_proxy";
out(2).delta_fertility_pre = mean(old_s.fertility_rate(pre) - old_b.fertility_rate(pre));
out(2).delta_fertility_boom = mean(old_s.fertility_rate(boom) - old_b.fertility_rate(boom));
out(2).delta_fertility_post = mean(old_s.fertility_rate(post) - old_b.fertility_rate(post));
out(2).delta_price_pre = mean(old_s.price(pre) - old_b.price(pre));
out(2).delta_price_boom = mean(old_s.price(boom) - old_b.price(boom));
out(2).delta_price_post = mean(old_s.price(post) - old_b.price(post));

out(3).model = "structural_foc";
out(3).delta_fertility_pre = mean(str_s.fertility_rate(pre) - str_b.fertility_rate(pre));
out(3).delta_fertility_boom = mean(str_s.fertility_rate(boom) - str_b.fertility_rate(boom));
out(3).delta_fertility_post = mean(str_s.fertility_rate(post) - str_b.fertility_rate(post));
out(3).delta_price_pre = mean(str_s.price(pre) - str_b.price(pre));
out(3).delta_price_boom = mean(str_s.price(boom) - str_b.price(boom));
out(3).delta_price_post = mean(str_s.price(post) - str_b.price(post));
end

function write_text_report(out_dir, cfg, summary, phase_summary)
report_file = fullfile(out_dir, 'old_vs_new_model_comparison_report.md');
fid = fopen(report_file, 'w');
if fid == -1
    error('Could not write report file: %s', report_file);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Old vs new fertility model comparison (MATLAB)\n\n');
fprintf(fid, '- Generated (local time): %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '- Design: temporary baby-boom shock (NIMBY-style), not family-supply shock\n');
fprintf(fid, '- Damping: %.2f\n', cfg.damping);
fprintf(fid, '- Baby-boom multiplier: +%.0f%% (t=%d to t=%d)\n', 100*cfg.boom_amp, cfg.boom_start, cfg.boom_end);
fprintf(fid, '- Post window starts at t=%d\n\n', cfg.post_start);

fprintf(fid, '## Summary metrics\n\n');
fprintf(fid, '| scenario | avg_price_t10_79 | avg_fertility_t10_79 | avg_births_t10_79 | final_price | final_fertility | max_abs_price_change |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:numel(summary)
    fprintf(fid, '| %s | %.6f | %.6f | %.6f | %.6f | %.6f | %.6f |\n', ...
        summary(i).scenario, summary(i).avg_price_t10_79, summary(i).avg_fertility_t10_79, ...
        summary(i).avg_births_t10_79, summary(i).final_price, summary(i).final_fertility, summary(i).max_abs_price_change);
end

fprintf(fid, '\n## Phase deltas (shock - baseline)\n\n');
fprintf(fid, '| model | delta_fertility_pre | delta_fertility_boom | delta_fertility_post | delta_price_pre | delta_price_boom | delta_price_post |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:numel(phase_summary)
    fprintf(fid, '| %s | %.6f | %.6f | %.6f | %.6f | %.6f | %.6f |\n', ...
        phase_summary(i).model, phase_summary(i).delta_fertility_pre, phase_summary(i).delta_fertility_boom, ...
        phase_summary(i).delta_fertility_post, phase_summary(i).delta_price_pre, ...
        phase_summary(i).delta_price_boom, phase_summary(i).delta_price_post);
end

fprintf(fid, '\n## Notes\n\n');
fprintf(fid, '- The full upstream project-02 MATLAB steady-state run still needs missing external `.mat` inputs in this repo copy.\n');
fprintf(fid, '- Old-model series here is the pre-fertility-channel proxy with the same exogenous baby-boom shock.\n');
end
