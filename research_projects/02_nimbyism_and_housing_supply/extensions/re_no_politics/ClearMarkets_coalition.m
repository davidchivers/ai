function [Results, Stats_all] = ClearMarkets_coalition(coalition_params)
% Grid search driver for the coalition-weighted voting steady state.
% Searches over house prices to find the coalition-weighted median-voter
% equilibrium price.
%
% Usage:
%   [Results, Stats_all] = ClearMarkets_coalition();
%   [Results, Stats_all] = ClearMarkets_coalition(coalition_params);

if nargin < 1 || isempty(coalition_params)
    coalition_params = struct();
end
if ~isfield(coalition_params, 'alpha_owner'),     coalition_params.alpha_owner     = 0.50; end
if ~isfield(coalition_params, 'alpha_old_owner'), coalition_params.alpha_old_owner = 0.50; end
if ~isfield(coalition_params, 'alpha_leverage'),  coalition_params.alpha_leverage  = 0.25; end
if ~isfield(coalition_params, 'alpha_bighouse'),  coalition_params.alpha_bighouse  = 0.10; end

%% Search grid
tic

X1 = linspace(-1,1,30)*0.2 + 2;   % House price grid (centred around 2)
X2 = 0.03;                         % Interest rate (fixed for now)

ix = 0;
Results = [];
Stats_all = cell(1, length(X1)*length(X2));

for x1 = 1:length(X1)
    for x2 = 1:length(X2)
        ix = 1 + ix;
        [distance, a_price, rbPos, totalvote, debtstock, stats] = ...
            solve_ss_coalition([X1(x1), X2(x2)], coalition_params);
        Results(:,ix) = [distance; a_price; rbPos; totalvote; debtstock; ...
                         stats.equal_weight_vote; stats.owner_share];
        Stats_all{ix} = stats;
    end
end

disp('Grid search complete.')

%% Find best price
[min_dist, min_idx] = min(Results(1,:));
best_price = Results(2, min_idx);

fprintf('\n=== Coalition-Weighted Voting Steady State ===\n');
fprintf('Best price:              %.4f\n', best_price);
fprintf('Min distance:            %.6e\n', min_dist);
fprintf('Coalition weighted vote: %.6f\n', Results(4, min_idx));
fprintf('Equal-weight vote:       %.6f\n', Results(6, min_idx));
fprintf('Owner share:             %.4f\n', Results(7, min_idx));
fprintf('Debt stock:              %.4f\n', Results(5, min_idx));

%% Plot vote comparison
figure
subplot(2,1,1)
plot(X1, Results(4,:), 'b-', 'LineWidth', 1.5); hold on;
plot(X1, Results(6,:), 'r--', 'LineWidth', 1.5);
yline(0, '--', 'Color', [0.5 0.5 0.5]);
xlabel('House Price'); ylabel('Vote');
legend('Coalition-weighted', 'Equal-weight', 'Location', 'best');
title('Voting Equilibrium: Coalition vs Equal Weight');
grid on;

subplot(2,1,2)
plot(X1, sqrt(Results(1,:)), 'k-', 'LineWidth', 1.5);
xlabel('House Price'); ylabel('|Weighted Vote|');
title(sprintf('Coalition equilibrium at p = %.3f', best_price));
grid on;

toc

%% Nesting test: all alphas = 0 should reproduce baseline
if 0
    baseline_params = struct();
    baseline_params.alpha_owner     = 0;
    baseline_params.alpha_old_owner = 0;
    baseline_params.alpha_leverage  = 0;
    baseline_params.alpha_bighouse  = 0;

    ix = 0;
    R_nest = [];
    for x1 = 1:length(X1)
        ix = ix + 1;
        [d, ~, ~, tv, ds, st] = solve_ss_coalition([X1(x1), X2], baseline_params); %#ok<ASGLU>
        R_nest(:,ix) = [d; tv; st.equal_weight_vote];
    end

    figure
    plot(X1, R_nest(2,:), 'b-', 'LineWidth', 1.5); hold on;
    plot(X1, R_nest(3,:), 'r--', 'LineWidth', 1.5);
    yline(0, '--', 'Color', [0.5 0.5 0.5]);
    xlabel('House Price'); ylabel('Vote');
    legend('Coalition (alpha=0)', 'Equal-weight', 'Location', 'best');
    title('Nesting Test: Coalition with zero alphas = baseline');
    grid on;

    max_diff = max(abs(R_nest(2,:) - R_nest(3,:)));
    fprintf('Nesting test max |difference|: %.2e\n', max_diff);
end

end
