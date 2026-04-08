function Results = ClearMarkets_no_politics(supply_params)
% Grid search driver for the no-politics RE steady state.
% Searches over house prices to find the market-clearing equilibrium.
%
% Usage:
%   Results = ClearMarkets_no_politics();
%   Results = ClearMarkets_no_politics(supply_params);

if nargin < 1 || isempty(supply_params)
    supply_params = struct();
end
if ~isfield(supply_params, 'Hbar'),  supply_params.Hbar  = 5.0; end
if ~isfield(supply_params, 'Pbar'),  supply_params.Pbar  = 2.0; end
if ~isfield(supply_params, 'eta_s'), supply_params.eta_s = 1.0; end

%% Search grid
tic

X1 = linspace(-1,1,30)*0.2 + 2;   % House price grid (centred around 2)
X2 = 0.03;                         % Interest rate (fixed for now)

ix = 0;
Results = [];

for x1 = 1:length(X1)
    for x2 = 1:length(X2)
        ix = 1 + ix;
        [distance, a_price, rbPos, Hdemand, Hsupply, debtstock] = ...
            solve_ss_no_politics([X1(x1), X2(x2)], supply_params);
        Results(:,ix) = [distance; a_price; rbPos; Hdemand; Hsupply; debtstock];
    end
end

disp('Grid search complete.')

%% Find best price
[min_dist, min_idx] = min(Results(1,:));
best_price = Results(2, min_idx);
best_Hdemand = Results(4, min_idx);
best_Hsupply = Results(5, min_idx);

fprintf('\n=== No-Politics RE Steady State ===\n');
fprintf('Best price:    %.4f\n', best_price);
fprintf('Min distance:  %.6e\n', min_dist);
fprintf('Hdemand:       %.4f\n', best_Hdemand);
fprintf('Hsupply:       %.4f\n', best_Hsupply);
fprintf('Debt stock:    %.4f\n', Results(6, min_idx));

%% Plot excess demand
figure
subplot(2,1,1)
plot(X1, Results(4,:), 'b-', 'LineWidth', 1.5); hold on;
plot(X1, Results(5,:), 'r--', 'LineWidth', 1.5);
xlabel('House Price'); ylabel('Housing Units');
legend('H^{demand}', 'H^{supply}', 'Location', 'best');
title('Housing Market Clearing');
grid on;

subplot(2,1,2)
plot(X1, Results(4,:) - Results(5,:), 'k-', 'LineWidth', 1.5);
hold on;
yline(0, '--', 'Color', [0.5 0.5 0.5]);
plot(best_price, 0, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
xlabel('House Price'); ylabel('Excess Demand');
title(sprintf('Excess Demand (equilibrium at p = %.3f)', best_price));
grid on;

toc

%% Supply elasticity sensitivity (optional)
if 0
    eta_values = [0.5, 1.0, 2.0, 10.0];
    figure; hold on;
    for ie = 1:length(eta_values)
        sp = supply_params;
        sp.eta_s = eta_values(ie);
        ix = 0;
        R_sens = [];
        for x1 = 1:length(X1)
            ix = ix + 1;
            [d, ~, ~, Hd, Hs, ~] = solve_ss_no_politics([X1(x1), X2], sp);
            R_sens(:,ix) = [d; Hd; Hs];
        end
        plot(X1, R_sens(2,:) - R_sens(3,:), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('\\eta_s = %.1f', eta_values(ie)));
    end
    yline(0, '--', 'Color', [0.5 0.5 0.5]);
    xlabel('House Price'); ylabel('Excess Demand');
    title('Supply Elasticity Sensitivity');
    legend('Location', 'best');
    grid on;
end

end
