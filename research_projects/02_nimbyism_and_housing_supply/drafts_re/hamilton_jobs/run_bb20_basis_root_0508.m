function run_bb20_basis_root_0508(varargin)
% T20 p0060 reduced-basis quasi-Newton rescue for the baby-boom RE path.
%
% This restarts from the best completed reduced-basis branches and updates the
% low-dimensional path coefficients directly. It is a root-solve attempt in the
% reduced path space, not another full-path relaxation sweep.

p = inputParser;
p.addParameter('RunTag', 'rbroot20');
p.addParameter('SourceRunTag', 'rb20end50_k8');
p.addParameter('SourceOuter', 4);
p.addParameter('SeedMode', 'guess');
p.addParameter('TailYears', 20);
p.addParameter('TerminalAnchor', 'terminal_fixed_point');
p.addParameter('TerminalBlendWeight', 0.50);
p.addParameter('OuterIter', 28);
p.addParameter('BasisDim', 8);
p.addParameter('BroydenDamping', 0.40);
p.addParameter('BroydenStepCap', 0.006);
p.addParameter('BasisStepCap', 0.0008);
p.addParameter('BasisEndWeight', 14.0);
p.addParameter('BasisTailWeight', 0.15);
p.addParameter('BasisFocusStart', NaN);
p.addParameter('BasisFocusEnd', NaN);
p.addParameter('BasisFocusWeight', 1.0);
p.addParameter('PoliticalPassThrough', -0.006);
p.addParameter('VoteScale', 0.02);
p.addParameter('VoteShiftMode', 'path_shift');
p.addParameter('VoteShiftHorizon', 5);
p.addParameter('VoteBlockLength', 5);
p.addParameter('RunRoot', fileparts(pwd));
p.parse(varargin{:});
cfg = p.Results;

annual_dir = pwd;
out_root = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path');
source_dir = fullfile(out_root, cfg.SourceRunTag);
source_paths = fullfile(source_dir, 'paths_all.csv');
if ~isfile(source_paths)
    error('Source paths not found: %s', source_paths);
end

paths = readtable(source_paths);
paths = paths(paths.outer_iter == cfg.SourceOuter, :);
paths = sortrows(paths, 'period');
if isempty(paths)
    error('No outer_iter == %.0f rows found in %s', cfg.SourceOuter, source_paths);
end

seed_price = build_root_seed(paths, cfg.SeedMode);
seed_dir = fullfile(out_root, 'basis_root_seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end
seed_path = fullfile(seed_dir, [cfg.RunTag '_seed.csv']);
writetable(table(seed_price(:), 'VariableNames', {'price'}), seed_path);
fprintf('Wrote seed %s using %s outer %.0f mode %s\n', seed_path, cfg.SourceRunTag, cfg.SourceOuter, cfg.SeedMode);

run_annual_political_full_re_price_path( ...
    'RunTag', cfg.RunTag, ...
    'T', 20, ...
    'TailYears', cfg.TailYears, ...
    'TerminalAnchor', cfg.TerminalAnchor, ...
    'TerminalIter', 140, ...
    'TerminalRelaxation', 0.12, ...
    'TerminalBlendWeight', cfg.TerminalBlendWeight, ...
    'OuterIter', cfg.OuterIter, ...
    'PathRelaxation', 0.03, ...
    'PathUpdateMethod', 'basis_broyden', ...
    'BasisDim', cfg.BasisDim, ...
    'BasisDamping', 0.25, ...
    'BasisStepCap', cfg.BasisStepCap, ...
    'BasisRidge', 1e-8, ...
    'BasisEndWeight', cfg.BasisEndWeight, ...
    'BasisTailWeight', cfg.BasisTailWeight, ...
    'BasisFocusStart', cfg.BasisFocusStart, ...
    'BasisFocusEnd', cfg.BasisFocusEnd, ...
    'BasisFocusWeight', cfg.BasisFocusWeight, ...
    'BroydenDamping', cfg.BroydenDamping, ...
    'BroydenStepCap', cfg.BroydenStepCap, ...
    'PoliticalPassThrough', cfg.PoliticalPassThrough, ...
    'VoteScale', cfg.VoteScale, ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', cfg.VoteShiftMode, ...
    'VoteShiftHorizon', cfg.VoteShiftHorizon, ...
    'VoteBlockLength', cfg.VoteBlockLength, ...
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
end

function seed_price = build_root_seed(paths, seed_mode)
x = log(paths.price_guess);
g = log(paths.price_generated);
r = g - x;
period = paths.period;
report_ix = period <= 20;
end_ix = period >= 16 & period <= 20;
mid_ix = period >= 5 & period <= 12;
critical_ix = period >= 6 & period <= 8;
seed_mode = lower(string(seed_mode));

switch seed_mode
    case "guess"
        z = x;
    case "report25"
        w = zeros(size(x));
        w(report_ix) = 0.25;
        z = x + w .* r;
    case "report50"
        w = zeros(size(x));
        w(report_ix) = 0.50;
        z = x + w .* r;
    case "end50"
        w = zeros(size(x));
        w(end_ix) = 0.50;
        z = x + w .* r;
    case "end100"
        w = zeros(size(x));
        w(end_ix) = 1.00;
        z = x + w .* r;
    case "midend50"
        w = zeros(size(x));
        w(mid_ix | end_ix) = 0.50;
        z = x + w .* r;
    case "critical7"
        w = zeros(size(x));
        ix = find(critical_ix);
        local_w = [0.35; 0.80; 0.35];
        w(ix(1:min(numel(ix), numel(local_w)))) = local_w(1:min(numel(ix), numel(local_w)));
        z = x + w .* r;
    case "critical7end50"
        w = zeros(size(x));
        w(end_ix) = 0.50;
        ix = find(critical_ix);
        local_w = [0.35; 0.80; 0.35];
        w(ix(1:min(numel(ix), numel(local_w)))) = local_w(1:min(numel(ix), numel(local_w)));
        z = x + w .* r;
    case "critical7end100"
        w = zeros(size(x));
        w(end_ix) = 1.00;
        ix = find(critical_ix);
        local_w = [0.35; 0.80; 0.35];
        w(ix(1:min(numel(ix), numel(local_w)))) = local_w(1:min(numel(ix), numel(local_w)));
        z = x + w .* r;
    otherwise
        error('Unknown SeedMode: %s', seed_mode);
end

seed_price = exp(z);
end
