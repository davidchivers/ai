% run_sensitivity_table.m — One-at-a-time sensitivity of mechanism parameters.
% Produces Appendix C table: crossing price and fertility outcomes under
% perturbations of kappa_q, lambda_c, sigma, and phi(0).
%
% Usage:
%   run_sensitivity_table          % full-resolution (I=60, J=14)
%   run_sensitivity_table('fast')  % stage-1 screen  (I=20, J=6)
%
% Outputs:
%   notes/build/sensitivity_mechanism_parameters.csv
%   notes/build/sensitivity_mechanism_parameters.md

function run_sensitivity_table(mode)

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

% Define perturbation grid: {field_name, display_name, [low, mid, high]}
perturbations = {
    'birth_price_coeff',          'kappa_q',   [0.18, 0.24, 0.30];
    'lambda_crowd',               'lambda_c',  [0.12, 0.18, 0.24];
    'logit_scale',                'sigma',     [0.10, 0.15, 0.20];
    'birth_utility_by_parity_1',  'phi_0',     [0.90, 1.05, 1.20];
};

% Use the local grid around the benchmark crossing for speed
price_grid = cfg.local_market_price_grid;
rbPos = cfg.rbPos;

% Preallocate results
nrows = 0;
for p = 1:size(perturbations, 1)
    nrows = nrows + numel(perturbations{p, 3});
end

param_name   = cell(nrows, 1);
param_value  = NaN(nrows, 1);
crossing_q   = NaN(nrows, 1);
mean_fb_age  = NaN(nrows, 1);
childless_50 = NaN(nrows, 1);
fb_rate      = NaN(nrows, 1);
avg_br       = NaN(nrows, 1);

row = 0;
for p = 1:size(perturbations, 1)
    field = perturbations{p, 1};
    label = perturbations{p, 2};
    values = perturbations{p, 3};

    for v = 1:numel(values)
        row = row + 1;
        param_name{row} = label;
        param_value(row) = values(v);

        % Build overrides with this perturbation
        ov = base_overrides;
        if strcmp(field, 'birth_utility_by_parity_1')
            % Perturb only the first element of birth_utility_by_parity
            bup = ov.birth_utility_by_parity;
            bup(1) = values(v);
            ov.birth_utility_by_parity = bup;
        elseif strcmp(field, 'logit_scale')
            % logit_scale is not in the standard overrides; pass directly
            ov.logit_scale = values(v);
        else
            ov.(field) = values(v);
        end

        fprintf('\n=== %s = %.2f ===\n', label, values(v));

        % Run market clearing on the local grid
        [~, crossing] = ClearMarkets_fertility(price_grid, rbPos, ov);

        if crossing.exists && ~isnan(crossing.refined_price)
            crossing_q(row) = crossing.refined_price;

            % Evaluate diagnostics at the crossing price
            [~, ~, ~, ~, ~, diag] = SolveSS_fertility([crossing.refined_price, rbPos], ov);
            mean_fb_age(row)  = diag.mean_age_first_birth;
            childless_50(row) = get_parity0_at_50(diag);
            fb_rate(row)      = diag.avg_first_birth_rate;
            avg_br(row)       = diag.avg_birth_rate;
        else
            fprintf('  WARNING: no unique crossing found.\n');
        end

        fprintf('  crossing=%.3f, mean_fb_age=%.2f, childless=%.3f, fb_rate=%.3f, avg_br=%.3f\n', ...
            crossing_q(row), mean_fb_age(row), childless_50(row), fb_rate(row), avg_br(row));
    end
end

% Build and save results table
T = table(param_name, param_value, crossing_q, mean_fb_age, childless_50, fb_rate, avg_br, ...
    'VariableNames', {'parameter', 'value', 'crossing_price', 'mean_first_birth_age', ...
    'childless_share_50', 'first_birth_rate', 'avg_birth_rate'});

outdir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'notes', 'build');
if ~exist(outdir, 'dir'), mkdir(outdir); end

csv_path = fullfile(outdir, 'sensitivity_mechanism_parameters.csv');
writetable(T, csv_path);
fprintf('\nResults saved to %s\n', csv_path);

% Write markdown summary
md_path = fullfile(outdir, 'sensitivity_mechanism_parameters.md');
fid = fopen(md_path, 'w');
fprintf(fid, '# Mechanism Parameter Sensitivity\n\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM'));
fprintf(fid, 'Mode: %s (I=%d, J=%d)\n\n', mode, base_overrides.I, base_overrides.J);
fprintf(fid, '| Parameter | Value | Crossing q | Mean FB age | Childless %% | FB rate | Avg BR |\n');
fprintf(fid, '|-----------|-------|-----------|-------------|-------------|---------|--------|\n');
for i = 1:height(T)
    fprintf(fid, '| %s | %.2f | %.3f | %.2f | %.3f | %.3f | %.3f |\n', ...
        T.parameter{i}, T.value(i), T.crossing_price(i), T.mean_first_birth_age(i), ...
        T.childless_share_50(i), T.first_birth_rate(i), T.avg_birth_rate(i));
end
fclose(fid);
fprintf('Summary saved to %s\n', md_path);

end

function p0 = get_parity0_at_50(diag)
age50 = find(diag.ages == 50, 1);
if isempty(age50)
    p0 = NaN;
    return;
end
pshares = diag.parity_dist_by_age(age50, :);
if numel(pshares) >= 1
    p0 = pshares(1);
else
    p0 = NaN;
end
end
