function run_bb20_av_homotopy_chain_0509(varargin)
% Annual-vote fresh-seed chain for the T20 baby-boom RE path.
%
% This is deliberately different from continuing the failed h6 branch. It
% solves the annual-vote object at smaller political pass-through first, then
% carries the best annual-vote seed forward to the target pass-through.

p = inputParser;
p.addParameter('RunTagStem', 'avseed_h5');
p.addParameter('SourceRunTag', 'rbr20end100_k8');
p.addParameter('SourceOuter', 1);
p.addParameter('SeedMode', 'guess');
p.addParameter('VoteShiftHorizon', 5);
p.addParameter('VoteShiftMode', 'finite_horizon');
p.addParameter('VoteBlockLength', 5);
p.addParameter('TailYears', 20);
p.addParameter('BasisDim', 8);
p.addParameter('RunRoot', fileparts(pwd));
p.parse(varargin{:});
cfg = p.Results;

stages = [-0.0030, -0.0045, -0.0060];
stage_labels = ["p0030", "p0045", "p0060"];
stage_iters = [8, 10, 14];
stage_damp = [0.30, 0.26, 0.22];
stage_broyden_cap = [0.0040, 0.0035, 0.0028];
stage_basis_cap = [0.00055, 0.00045, 0.00032];

source_tag = cfg.SourceRunTag;
source_outer = cfg.SourceOuter;
seed_mode = cfg.SeedMode;

for ii = 1:numel(stages)
    run_tag = sprintf('%s_%s', cfg.RunTagStem, char(stage_labels(ii)));
    fprintf('Annual-vote chain stage %d/%d: %s from %s outer %.0f\n', ...
        ii, numel(stages), run_tag, source_tag, source_outer);

    run_bb20_basis_root_0508( ...
        'RunTag', run_tag, ...
        'SourceRunTag', source_tag, ...
        'SourceOuter', source_outer, ...
        'SeedMode', seed_mode, ...
        'TailYears', cfg.TailYears, ...
        'TerminalAnchor', 'terminal_fixed_point', ...
        'TerminalBlendWeight', 1.00, ...
        'OuterIter', stage_iters(ii), ...
        'BasisDim', cfg.BasisDim, ...
        'BroydenDamping', stage_damp(ii), ...
        'BroydenStepCap', stage_broyden_cap(ii), ...
        'BasisStepCap', stage_basis_cap(ii), ...
        'BasisEndWeight', 10, ...
        'BasisTailWeight', 0.12, ...
        'BasisFocusStart', 6, ...
        'BasisFocusEnd', 8, ...
        'BasisFocusWeight', 8, ...
        'PoliticalPassThrough', stages(ii), ...
        'VoteShiftMode', cfg.VoteShiftMode, ...
        'VoteShiftHorizon', cfg.VoteShiftHorizon, ...
        'VoteBlockLength', cfg.VoteBlockLength, ...
        'RunRoot', cfg.RunRoot);

    [source_tag, source_outer] = best_outer_for_run(run_tag);
    seed_mode = 'guess';
end
end

function [run_tag, best_outer] = best_outer_for_run(run_tag)
summary_path = fullfile(pwd, 'truth', 'annual_political_full_re_price_path', run_tag, 'summary_all.csv');
if ~isfile(summary_path)
    error('No summary found for %s', run_tag);
end
summary = readtable(summary_path);
if isempty(summary)
    error('Empty summary for %s', run_tag);
end
[best_gap, ix] = min(summary.max_abs_path_gap);
best_outer = summary.outer_iter(ix);
fprintf('Best stage row for %s: outer %.0f, gap %.8g\n', run_tag, best_outer, best_gap);
end
