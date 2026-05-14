function run_bb20_basis12_0507(varargin)
% Twelve-hour T20 p0060 rescue workflow for the baby-boom RE price path.
%
% This starts from the best full-p0060 Broyden iterate, then uses controlled
% seeds plus a reduced-basis price-path update that gives extra weight to the
% end of the reported 20-year window.

p = inputParser;
p.addParameter('RunTag', 'rb20');
p.addParameter('SeedMode', 'guess');
p.addParameter('TailYears', 20);
p.addParameter('TerminalAnchor', 'terminal_fixed_point');
p.addParameter('OuterIter', 36);
p.addParameter('BasisDim', 8);
p.addParameter('BasisDamping', 0.35);
p.addParameter('BasisStepCap', 0.0012);
p.addParameter('BasisEndWeight', 8.0);
p.addParameter('BasisTailWeight', 0.20);
p.addParameter('RunRoot', fileparts(pwd));
p.parse(varargin{:});
cfg = p.Results;

annual_dir = pwd;
out_root = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path');
source_dir = fullfile(out_root, 'brh20d80c005_p0060');
source_paths = fullfile(source_dir, 'paths_all.csv');
if ~isfile(source_paths)
    error('Source paths not found: %s', source_paths);
end

paths = readtable(source_paths);
paths = paths(paths.outer_iter == 7, :);
paths = sortrows(paths, 'period');
if isempty(paths)
    error('No outer_iter == 7 rows found in %s', source_paths);
end

seed_price = build_seed(paths, cfg.SeedMode);
seed_dir = fullfile(out_root, 'basis12_seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end
seed_path = fullfile(seed_dir, [cfg.RunTag '_seed.csv']);
writetable(table(seed_price(:), 'VariableNames', {'price'}), seed_path);
fprintf('Wrote seed %s using mode %s\n', seed_path, cfg.SeedMode);

run_annual_political_full_re_price_path( ...
    'RunTag', cfg.RunTag, ...
    'T', 20, ...
    'TailYears', cfg.TailYears, ...
    'TerminalAnchor', cfg.TerminalAnchor, ...
    'TerminalIter', 120, ...
    'TerminalRelaxation', 0.15, ...
    'OuterIter', cfg.OuterIter, ...
    'PathRelaxation', 0.04, ...
    'PathUpdateMethod', 'basis', ...
    'BasisDim', cfg.BasisDim, ...
    'BasisDamping', cfg.BasisDamping, ...
    'BasisStepCap', cfg.BasisStepCap, ...
    'BasisRidge', 1e-8, ...
    'BasisEndWeight', cfg.BasisEndWeight, ...
    'BasisTailWeight', cfg.BasisTailWeight, ...
    'PoliticalPassThrough', -0.006, ...
    'VoteScale', 0.02, ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'path_shift', ...
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

function seed_price = build_seed(paths, seed_mode)
x = log(paths.price_guess);
g = log(paths.price_generated);
r = g - x;
period = paths.period;
report_ix = period <= 20;
end_ix = period >= 16 & period <= 20;
seed_mode = lower(string(seed_mode));

switch seed_mode
    case "guess"
        z = x;
    case "blend25"
        z = x + 0.25 .* r;
    case "blend50"
        z = x + 0.50 .* r;
    case "report25"
        w = zeros(size(x));
        w(report_ix) = 0.25;
        z = x + w .* r;
    case "end50"
        w = zeros(size(x));
        w(end_ix) = 0.50;
        z = x + w .* r;
    case "end75"
        w = zeros(size(x));
        w(end_ix) = 0.75;
        z = x + w .* r;
    case "rampend"
        w = zeros(size(x));
        ramp = [0.20; 0.35; 0.50; 0.65; 0.80];
        ix = find(end_ix);
        w(ix(1:min(numel(ix), numel(ramp)))) = ramp(1:min(numel(ix), numel(ramp)));
        z = x + w .* r;
    otherwise
        error('Unknown SeedMode: %s', seed_mode);
end

seed_price = exp(z);
end
