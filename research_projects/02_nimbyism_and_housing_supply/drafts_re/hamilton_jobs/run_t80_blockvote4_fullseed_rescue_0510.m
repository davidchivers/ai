function run_t80_blockvote4_fullseed_rescue_0510(varargin)
% T80 four-year block-vote RE rescue using full-horizon no-RE or hybrid seeds.
%
% This changes only the initial price path. The solved target remains the same
% four-year block-vote RE T80 model with pass-through -0.006.

p = inputParser;
p.addParameter('RunTag', 'bv80bv4_seed_rescue');
p.addParameter('SourceRunTag', 'bv4p_r25_d18');
p.addParameter('SourceOuter', 6);
p.addParameter('NoReRunTag', 'nore80bv4_006');
p.addParameter('SeedMode', 'hybrid_shifted'); % nore_full | nore_shifted | hybrid_shifted
p.addParameter('HybridSwitchPeriod', 40);
p.addParameter('BasisDim', 8);
p.addParameter('OuterIter', 22);
p.addParameter('BroydenDamping', 0.22);
p.addParameter('BroydenStepCap', 0.0022);
p.addParameter('BasisStepCap', 0.00032);
p.addParameter('BasisTailWeight', 0.12);
p.addParameter('LaggedPassThrough', false);
p.addParameter('PassThroughLagYears', 1);
p.addParameter('RunRoot', fileparts(pwd));
p.parse(varargin{:});
cfg = p.Results;

annual_dir = pwd;
re_root = fullfile(annual_dir, 'truth', 'annual_political_full_re_price_path');
nore_root = fullfile(annual_dir, 'truth', 'annual_political_transition_fail_safe');

source_paths = fullfile(re_root, cfg.SourceRunTag, 'paths_all.csv');
if ~isfile(source_paths)
    error('Source paths not found: %s', source_paths);
end
src = readtable(source_paths);
src = src(src.outer_iter == cfg.SourceOuter, :);
src = sortrows(src, 'period');
if isempty(src)
    error('No outer_iter == %.0f rows found in %s', cfg.SourceOuter, source_paths);
end
if ~ismember('price_generated', src.Properties.VariableNames)
    error('Source paths must contain price_generated: %s', source_paths);
end

nore_paths = fullfile(nore_root, cfg.NoReRunTag, 'paths_T80.csv');
if ~isfile(nore_paths)
    error('No-RE T80 paths not found: %s', nore_paths);
end
nore = readtable(nore_paths);
nore = sortrows(nore, 'period');
if ~ismember('price', nore.Properties.VariableNames)
    error('No-RE paths must contain price: %s', nore_paths);
end

src_period = src.period;
src_price = src.price_generated;
nore_period = nore.period;
nore_price = nore.price;
max_period = max([80; src_period(:); nore_period(:)]);
seed = NaN(max_period, 1);

mode = lower(string(cfg.SeedMode));
switch mode
    case "nore_full"
        seed(nore_period) = nore_price;

    case "nore_shifted"
        seed(nore_period) = shift_series_to_match(nore_period, nore_price, src_period, src_price, 1);

    case "hybrid_shifted"
        switch_period = min(cfg.HybridSwitchPeriod, max(src_period));
        src_keep = src_period <= switch_period;
        seed(src_period(src_keep)) = src_price(src_keep);

        tail_keep = nore_period > switch_period;
        shifted_tail = shift_series_to_match(nore_period, nore_price, src_period, src_price, switch_period);
        seed(nore_period(tail_keep)) = shifted_tail(tail_keep);

    otherwise
        error('Unsupported SeedMode: %s', cfg.SeedMode);
end

if any(~isfinite(seed(1:80))) || any(seed(1:80) <= 0)
    error('Seed has missing or non-positive values in periods 1:80.');
end

seed_dir = fullfile(re_root, 't80_seeds');
if ~exist(seed_dir, 'dir')
    mkdir(seed_dir);
end
seed_path = fullfile(seed_dir, sprintf('%s_%s_%s_from_%s_o%.0f_seed.csv', ...
    cfg.RunTag, char(mode), cfg.NoReRunTag, cfg.SourceRunTag, cfg.SourceOuter));
writetable(table(seed(:), 'VariableNames', {'price'}), seed_path);
fprintf('T80 full-seed rescue written: %s\n', seed_path);
fprintf('Seed mode: %s; no-RE source: %s; RE source: %s outer %.0f\n', ...
    mode, cfg.NoReRunTag, cfg.SourceRunTag, cfg.SourceOuter);

run_annual_political_full_re_price_path( ...
    'RunTag', cfg.RunTag, ...
    'T', 80, ...
    'TailYears', 20, ...
    'TerminalAnchor', 'terminal_fixed_point', ...
    'TerminalIter', 160, ...
    'TerminalRelaxation', 0.12, ...
    'TerminalBlendWeight', 1.00, ...
    'OuterIter', cfg.OuterIter, ...
    'PathRelaxation', 0.02, ...
    'PathUpdateMethod', 'basis_broyden', ...
    'BasisDim', cfg.BasisDim, ...
    'BasisDamping', 0.25, ...
    'BasisStepCap', cfg.BasisStepCap, ...
    'BasisRidge', 1e-8, ...
    'BasisEndWeight', 10, ...
    'BasisTailWeight', cfg.BasisTailWeight, ...
    'BasisFocusStart', 6, ...
    'BasisFocusEnd', 8, ...
    'BasisFocusWeight', 8, ...
    'BroydenDamping', cfg.BroydenDamping, ...
    'BroydenStepCap', cfg.BroydenStepCap, ...
    'PoliticalPassThrough', -0.006, ...
    'VoteScale', 0.02, ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'block_vote', ...
    'VoteShiftHorizon', 4, ...
    'VoteBlockLength', 4, ...
    'LaggedPassThrough', cfg.LaggedPassThrough, ...
    'PassThroughLagYears', cfg.PassThroughLagYears, ...
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

function shifted = shift_series_to_match(period, price, ref_period, ref_price, anchor_period)
idx = find(period == anchor_period, 1);
ref_idx = find(ref_period == anchor_period, 1);
if isempty(idx) || isempty(ref_idx)
    error('Cannot align seed at period %.0f.', anchor_period);
end
scale = ref_price(ref_idx) ./ price(idx);
shifted = price .* scale;
end
