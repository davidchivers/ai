function run_re_lm_0513(varargin)
% Black-box Levenberg-Marquardt polish for the full-T80 RE price path.
%
% This is a future fallback if the safeguarded packet 17145335 misses. It is
% intentionally sequential and small: each trial path is evaluated by the same
% full annual RE solver for one outer iteration, and only actual residual
% improvements are accepted.

p = inputParser;
p.addParameter('RunRoot', fileparts(pwd));
p.addParameter('RunTag', 'lm80_from_w80_b60hold_o4');
p.addParameter('SourceRunTag', 'w80_b60hold_bl70');
p.addParameter('SourceOuter', 4);
p.addParameter('SourcePriceColumn', 'price_guess');
p.addParameter('MaxLmIter', 3);
p.addParameter('FiniteDiffStep', 1e-4);
p.addParameter('TrustRadius', 3e-4);
p.addParameter('LmLambda', 1e-3);
p.addParameter('OutputDir', fullfile(pwd, 'truth', 're_lm_0513'));
p.parse(varargin{:});
cfg = p.Results;

annual_dir = pwd;
re_root = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path');
if ~exist(cfg.OutputDir, 'dir')
    mkdir(cfg.OutputDir);
end

base_price = read_source_price(re_root, cfg.SourceRunTag, cfg.SourceOuter, cfg.SourcePriceColumn);
T = 80;
tail_years = 40;
internal_T = T + tail_years;
base_price = extend_seed(base_price, internal_T);
ref_price = base_price(1);
x0 = log(base_price ./ ref_price);
B = build_lm_basis(internal_T, T);
c = zeros(size(B, 2), 1);

lambda = cfg.LmLambda;
trust_radius = cfg.TrustRadius;
ledger = table();

for iter = 1:cfg.MaxLmIter
    [r0, gap0, run0] = evaluate_coeff(cfg, B, c, x0, ref_price, iter, 0);
    append_ledger(iter, 0, run0, gap0, true, 0);
    if gap0 <= 0.001
        write_lm_note(cfg, ledger, 'usable');
        return
    end

    J = zeros(numel(r0), size(B, 2));
    for j = 1:size(B, 2)
        cj = c;
        cj(j) = cj(j) + cfg.FiniteDiffStep;
        [rj, gapj, runj] = evaluate_coeff(cfg, B, cj, x0, ref_price, iter, j);
        append_ledger(iter, j, runj, gapj, false, 0);
        J(:, j) = (rj - r0) ./ cfg.FiniteDiffStep;
    end

    W = residual_weights(numel(r0));
    A = J' * (W .* J) + lambda .* eye(size(J, 2));
    b = -J' * (W .* r0);
    step = A \ b;
    step_norm = norm(step);
    if step_norm > trust_radius
        step = step .* (trust_radius ./ step_norm);
    end

    c_trial = c + step;
    [r_trial, gap_trial, run_trial] = evaluate_coeff(cfg, B, c_trial, x0, ref_price, iter, 99);
    accepted = gap_trial < gap0;
    append_ledger(iter, 99, run_trial, gap_trial, accepted, norm(step));
    if accepted
        c = c_trial;
        lambda = max(lambda / 3, 1e-6);
        trust_radius = min(trust_radius * 1.4, 1.5e-3);
        if gap_trial <= 0.001
            write_lm_note(cfg, ledger, 'usable');
            return
        end
    else
        lambda = min(lambda * 5, 1e3);
        trust_radius = max(trust_radius / 2, 2e-5);
    end
end

write_lm_note(cfg, ledger, 'stopped');

    function append_ledger(iter_id, eval_id, run_tag, gap, accepted, step_norm)
        row = table(iter_id, eval_id, string(run_tag), gap, accepted, step_norm, ...
            'VariableNames', {'lm_iter','eval_id','run_tag','max_abs_path_gap','accepted','step_norm'});
        ledger = [ledger; row]; %#ok<AGROW>
        writetable(ledger, fullfile(cfg.OutputDir, [cfg.RunTag '_ledger.csv']));
    end
end

function [r, gap, run_tag] = evaluate_coeff(cfg, B, c, x0, ref_price, iter, eval_id)
x = x0 + B * c;
price = ref_price .* exp(x);
seed_dir = fullfile(cfg.OutputDir, 'seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end
run_tag = sprintf('%s_i%02d_e%02d', cfg.RunTag, iter, eval_id);
append_lm_grid_row(cfg, run_tag);
seed_path = fullfile(seed_dir, [run_tag '_seed.csv']);
writetable(table(price(:), 'VariableNames', {'price'}), seed_path);

run_annual_political_full_re_price_path( ...
    'RunTag', run_tag, ...
    'T', 80, ...
    'TailYears', 40, ...
    'PostReportDemographicMode', 'hold_report_end', ...
    'TerminalAnchor', 'terminal_fixed_point', ...
    'TerminalIter', 260, ...
    'TerminalRelaxation', 0.08, ...
    'OuterIter', 1, ...
    'PathUpdateMethod', 'trust_region_relaxation', ...
    'PathRelaxation', 0.0, ...
    'BasisStepCap', 1e-7, ...
    'PoliticalPassThrough', -0.006, ...
    'VoteScale', 0.02, ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'block_vote', ...
    'VoteShiftHorizon', 4, ...
    'VoteBlockLength', 4, ...
    'LaggedPassThrough', true, ...
    'PassThroughLagYears', 4, ...
    'MaxAbsLogPriceMove', 0.18, ...
    'SourceMat', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat'), ...
    'DemographicScenario', 'published_baby_boom', ...
    'DemographicPathMat', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF', 'irfs_100.mat'), ...
    'DemographicPathVar', 'ageimpulse', ...
    'DemographicShockAmplitude', 0.25, ...
    'ReferenceYear', NaN, ...
    'InitialPathCsv', seed_path, ...
    'ModIrfDir', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF'), ...
    'ModFunctionsDir', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_Functions'), ...
    'CompeconDir', fullfile(cfg.RunRoot, 'COMPECON'));

paths = readtable(fullfile(pwd, 'truth', 'annual_political_full_re_price_path', run_tag, 'paths_all.csv'));
paths = paths(paths.outer_iter == 1 & paths.is_report_period == 1, :);
paths = sortrows(paths, 'period');
r = log(paths.price_generated ./ paths.price_guess);
gap = max(abs(r));
end

function append_lm_grid_row(cfg, run_tag)
grid_path = fullfile(cfg.OutputDir, [cfg.RunTag '_grid.csv']);
row = table( ...
    string(run_tag), ...
    string('re'), ...
    string('full_t80_lm_residual_minimization'), ...
    string('published_baby_boom'), ...
    80, ...
    40, ...
    0.25, ...
    0.006, ...
    string('black_box_lm_from_full_t80_survivor'), ...
    'VariableNames', { ...
        'run_tag', 'family', 'route', 'demographic_scenario', 'horizon_t', ...
        'tail_years', 'shock_amplitude', 'pass_through', 'notes' ...
    });
if exist(grid_path, 'file')
    prior = readtable(grid_path, 'TextType', 'string');
    prior = prior(prior.run_tag ~= string(run_tag), :);
    row = [prior; row];
end
writetable(row, grid_path);
end

function price = read_source_price(re_root, run_tag, outer, price_col)
paths = readtable(fullfile(re_root, run_tag, 'paths_all.csv'));
paths = paths(paths.outer_iter == outer, :);
paths = sortrows(paths, 'period');
if ~ismember(price_col, paths.Properties.VariableNames)
    error('Source price column not found: %s', price_col);
end
price = paths.(price_col);
end

function seed = extend_seed(price, n)
seed = price(:);
if numel(seed) < n
    seed = [seed; seed(end) .* ones(n - numel(seed), 1)];
else
    seed = seed(1:n);
end
end

function B = build_lm_basis(n, report_T)
t = ((1:n)' - 1) ./ max(1, report_T - 1);
B = [];
B = [B, ones(n, 1)];
B = [B, t];
early_knots = [1, 3, 5, 8, 12];
for k = early_knots
    center = (k - 1) ./ max(1, report_T - 1);
    width = 2.0 ./ report_T;
    B = [B, exp(-0.5 .* ((t - center) ./ width).^2)]; %#ok<AGROW>
end
B = [B, exp(-0.5 .* ((t - 0.35) ./ 0.12).^2)];
B = [B, exp(-0.5 .* ((t - 0.55) ./ 0.16).^2)];
tail = zeros(n, 1);
tail((report_T + 1):end) = linspace(0, 1, n - report_T)';
B = [B, tail];
B = B ./ max(1e-12, sqrt(sum(B.^2, 1)));
end

function W = residual_weights(n)
W = ones(n, 1);
W(1:min(12, n)) = 4;
W(max(1, n-4):n) = 2;
end

function write_lm_note(cfg, ledger, status)
note_path = fullfile(cfg.OutputDir, [cfg.RunTag '_note.md']);
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Full-T80 RE LM Closeout\n\n');
fprintf(fid, '- Status: `%s`\n', status);
fprintf(fid, '- Source: `%s` outer `%d`\n', cfg.SourceRunTag, cfg.SourceOuter);
if ~isempty(ledger)
    [best_gap, idx] = min(ledger.max_abs_path_gap);
    fprintf(fid, '- Best run: `%s`\n', char(ledger.run_tag(idx)));
    fprintf(fid, '- Best gap: `%.15g`\n', best_gap);
end
end
