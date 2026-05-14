% run_childlessness_recalibration.m — Recalibration of phi(0) to address
% the childlessness overprediction (referee comment 1).
%
% Holds all parameters at benchmark except phi(0) (first-birth utility).
% For each phi(0) value, finds the crossing price and reports the parity
% distribution, first-birth timing, and scarcity fertility gap.
%
% Usage:
%   run_childlessness_recalibration          % full-resolution
%   run_childlessness_recalibration('fast')  % stage-1 screen
%
% Outputs:
%   notes/build/childlessness_recalibration.csv
%   notes/build/childlessness_recalibration.md

function run_childlessness_recalibration(mode)

if nargin < 1, mode = 'full'; end

cfg = fertility_benchmark_config();

if strcmpi(mode, 'fast')
    base_overrides = cfg.stage1_solver_overrides;
    fnames = fieldnames(cfg.overrides);
    for k = 1:numel(fnames)
        if ~isfield(base_overrides, fnames{k})
            base_overrides.(fnames{k}) = cfg.overrides.(fnames{k});
        end
    end
    fprintf('Running in FAST mode (I=%d, J=%d)\n', base_overrides.I, base_overrides.J);
else
    base_overrides = cfg.overrides;
    fprintf('Running in FULL mode (I=%d, J=%d)\n', base_overrides.I, base_overrides.J);
end

% phi(0) grid — benchmark is 1.05, try higher values to reduce childlessness
phi0_grid = [1.05, 1.25, 1.45, 1.65, 1.85, 2.05, 2.25];

price_grid = cfg.local_market_price_grid;
rbPos = cfg.rbPos;

nruns = numel(phi0_grid);
crossing_q   = NaN(nruns, 1);
mean_fb_age  = NaN(nruns, 1);
fb_rate      = NaN(nruns, 1);
avg_br       = NaN(nruns, 1);
parity0      = NaN(nruns, 1);
parity1      = NaN(nruns, 1);
parity2      = NaN(nruns, 1);
parity3plus  = NaN(nruns, 1);
scarcity_gap = NaN(nruns, 1);

for i = 1:nruns
    phi0 = phi0_grid(i);
    fprintf('\n=== phi(0) = %.2f ===\n', phi0);

    % Build overrides with this phi(0)
    ov = base_overrides;
    bup = ov.birth_utility_by_parity;
    bup(1) = phi0;
    ov.birth_utility_by_parity = bup;

    % Find crossing
    [~, crossing] = ClearMarkets_fertility(price_grid, rbPos, ov);

    if crossing.exists && ~isnan(crossing.refined_price)
        crossing_q(i) = crossing.refined_price;

        % Diagnostics at crossing
        [~, ~, ~, ~, ~, diag] = SolveSS_fertility([crossing.refined_price, rbPos], ov);
        mean_fb_age(i) = diag.mean_age_first_birth;
        fb_rate(i)     = diag.avg_first_birth_rate;
        avg_br(i)      = diag.avg_birth_rate;

        age50 = find(diag.ages == 50, 1);
        pshares = diag.parity_dist_by_age(age50, :);
        parity0(i) = pshares(1);
        parity1(i) = pshares(2);
        parity2(i) = pshares(3);
        if numel(pshares) >= 4
            parity3plus(i) = pshares(4);
        end

        % Scarcity gap: evaluate at 15% higher price
        shock_price = crossing.refined_price * 1.15;
        [~, ~, ~, ~, ~, diag_shock] = SolveSS_fertility([shock_price, rbPos], ov);
        scarcity_gap(i) = avg_br(i) - diag_shock.avg_birth_rate;

        fprintf('  crossing=%.3f, childless=%.3f, scarcity_gap=%.4f\n', ...
            crossing_q(i), parity0(i), scarcity_gap(i));
    else
        fprintf('  WARNING: no unique crossing found.\n');
    end
end

% Save results
T = table(phi0_grid(:), crossing_q, mean_fb_age, fb_rate, avg_br, ...
    parity0, parity1, parity2, parity3plus, scarcity_gap, ...
    'VariableNames', {'phi_0', 'crossing_price', 'mean_first_birth_age', ...
    'first_birth_rate', 'avg_birth_rate', ...
    'parity0_at_50', 'parity1_at_50', 'parity2_at_50', 'parity3plus_at_50', ...
    'scarcity_fertility_gap'});

outdir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'notes', 'build');
if ~exist(outdir, 'dir'), mkdir(outdir); end

csv_path = fullfile(outdir, 'childlessness_recalibration.csv');
writetable(T, csv_path);
fprintf('\nResults saved to %s\n', csv_path);

% Write markdown summary
md_path = fullfile(outdir, 'childlessness_recalibration.md');
fid = fopen(md_path, 'w');
fprintf(fid, '# Childlessness Recalibration: phi(0) Sweep\n\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM'));
fprintf(fid, 'Mode: %s\n\n', mode);
fprintf(fid, 'US Census target childless share at 50: 0.165\n\n');
fprintf(fid, '| phi(0) | Crossing q | Childless | 1 child | 2 children | 3+ | Mean FB age | Scarcity gap |\n');
fprintf(fid, '|--------|-----------|-----------|---------|------------|-----|-------------|-------------|\n');
for i = 1:height(T)
    fprintf(fid, '| %.2f | %.3f | %.3f | %.3f | %.3f | %.3f | %.2f | %.4f |\n', ...
        T.phi_0(i), T.crossing_price(i), T.parity0_at_50(i), T.parity1_at_50(i), ...
        T.parity2_at_50(i), T.parity3plus_at_50(i), T.mean_first_birth_age(i), ...
        T.scarcity_fertility_gap(i));
end
fclose(fid);
fprintf('Summary saved to %s\n', md_path);

end
