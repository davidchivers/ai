function run_annual_political_comparison_map(varargin)
% Compare political pass-through against hard-sign and exogenous price paths.
%
% This is a cheap saved-grid diagnostic. It uses the annual LOOP price/vote
% map and does not rerun the household Bellman solver or dynamic distribution.

p = inputParser;
p.addParameter('SourceMat', 'C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_IRF\loop101_output_extended.mat');
p.addParameter('RunTag', '');
p.addParameter('T', 80);
p.addParameter('EtaGrid', [0.090, 0.105, 0.120]);
p.addParameter('TauGrid', [0.020]);
p.addParameter('TinyTauGrid', [0.001]);
p.addParameter('RandomDraws', 200);
p.addParameter('RandomSeed', 20260426);
p.addParameter('RandomAmplitudeGrid', [0.03, 0.05, 0.075, 0.10]);
p.addParameter('RandomRho', 0.80);
p.addParameter('RestrictionCap', 0.25);
p.addParameter('MaxAbsLogPriceMove', 0.18);
p.addParameter('PeriodIter', 4);
p.addParameter('UpdateRelaxation', 0.75);
p.parse(varargin{:});
cfg = p.Results;

this_dir = fileparts(mfilename('fullpath'));
out_root = fullfile(this_dir, 'truth', 'annual_political_comparison_map');
if ~exist(out_root, 'dir')
    mkdir(out_root);
end
if isempty(cfg.RunTag)
    cfg.RunTag = ['annual_comparison_map_', datestr(now, 'yyyymmdd_HHMMSS')];
end
out_dir = fullfile(out_root, cfg.RunTag);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
status_path = fullfile(out_root, 'latest_status.json');
write_status(status_path, 'running', 'Loading annual price/vote map.', cfg.RunTag, out_dir);

S = load(cfg.SourceMat, 'VoteBaseline', 'PriceHouse', 'Price_Trend', 'indReference');
VoteBaseline = S.VoteBaseline;
PriceHouse = S.PriceHouse(:)';
if isfield(S, 'indReference') && ~isempty(S.indReference)
    ind_reference = S.indReference;
else
    ind_reference = ceil(numel(PriceHouse) / 2);
end

n_years = size(VoteBaseline, 1);
T = min(cfg.T, n_years);
years = (1950:(1950 + T - 1))';
ref_year_index = min(51, n_years);
target_vote = VoteBaseline(ref_year_index, ind_reference);
reference_price = PriceHouse(ind_reference);
hard_clear_price = get_hard_price(S, T, PriceHouse, VoteBaseline, target_vote);
base_price = reference_price * ones(T, 1);

summary_rows = {};
path_rows = {};
row_ix = 0;
path_ix = 0;

% Constant-price/no-feedback baseline.
[row_ix, summary_rows, path_rows, path_ix] = add_exogenous_path( ...
    row_ix, summary_rows, path_rows, path_ix, 'constant_price', 'constant', ...
    NaN, NaN, NaN, NaN, 0, base_price, years, reference_price, PriceHouse, VoteBaseline, target_vote);
constant_max_abs = summary_rows{row_ix, 8};

% Direct hard-clearing price path. This is an oracle diagnostic, not a model closure.
[row_ix, summary_rows, path_rows, path_ix] = add_exogenous_path( ...
    row_ix, summary_rows, path_rows, path_ix, 'hard_clear_oracle', 'oracle', ...
    NaN, NaN, NaN, NaN, 0, hard_clear_price, years, reference_price, PriceHouse, VoteBaseline, target_vote);

% Endogenous smooth benchmark and near-hard alternatives.
for ie = 1:numel(cfg.EtaGrid)
    eta = cfg.EtaGrid(ie);
    for it = 1:numel(cfg.TauGrid)
        tau = cfg.TauGrid(it);
        [price_path, pressure_path, restriction_path, vote_path, resid_path] = simulate_feedback_path( ...
            eta, tau, 'smooth', cfg, T, reference_price, PriceHouse, VoteBaseline, target_vote);
        label = sprintf('smooth_eta%.3f_tau%.3f', eta, tau);
        [row_ix, summary_rows, path_rows, path_ix] = add_feedback_path( ...
            row_ix, summary_rows, path_rows, path_ix, label, 'endogenous_smooth', eta, tau, ...
            NaN, NaN, 0, price_path, pressure_path, restriction_path, vote_path, resid_path, ...
            years, reference_price, constant_max_abs);
    end

    for it = 1:numel(cfg.TinyTauGrid)
        tau = cfg.TinyTauGrid(it);
        [price_path, pressure_path, restriction_path, vote_path, resid_path] = simulate_feedback_path( ...
            eta, tau, 'smooth', cfg, T, reference_price, PriceHouse, VoteBaseline, target_vote);
        label = sprintf('near_hard_eta%.3f_tau%.4f', eta, tau);
        [row_ix, summary_rows, path_rows, path_ix] = add_feedback_path( ...
            row_ix, summary_rows, path_rows, path_ix, label, 'near_hard_tau', eta, tau, ...
            NaN, NaN, 0, price_path, pressure_path, restriction_path, vote_path, resid_path, ...
            years, reference_price, constant_max_abs);
    end

    [price_path, pressure_path, restriction_path, vote_path, resid_path] = simulate_feedback_path( ...
        eta, 0, 'hard_sign', cfg, T, reference_price, PriceHouse, VoteBaseline, target_vote);
    label = sprintf('hard_sign_eta%.3f_tau0', eta);
    [row_ix, summary_rows, path_rows, path_ix] = add_feedback_path( ...
        row_ix, summary_rows, path_rows, path_ix, label, 'hard_sign_tau0', eta, 0, ...
        NaN, NaN, 0, price_path, pressure_path, restriction_path, vote_path, resid_path, ...
        years, reference_price, constant_max_abs);
end

% Random/exogenous placebo price paths with the same annual vote map.
rng(cfg.RandomSeed);
for ia = 1:numel(cfg.RandomAmplitudeGrid)
    amp = cfg.RandomAmplitudeGrid(ia);
    for draw = 1:cfg.RandomDraws
        log_move = random_log_price_path(T, cfg.RandomRho, amp);
        price_path = reference_price * exp(log_move);
        price_path = clamp_price(price_path, reference_price, PriceHouse, cfg.MaxAbsLogPriceMove);
        label = sprintf('random_ar1_amp%.3f_draw%03d', amp, draw);
        [row_ix, summary_rows, path_rows, path_ix] = add_exogenous_path( ...
            row_ix, summary_rows, path_rows, path_ix, label, 'random_ar1', ...
            NaN, NaN, amp, cfg.RandomRho, draw, price_path, years, reference_price, PriceHouse, VoteBaseline, target_vote, constant_max_abs);
    end
end

summary = cell2table(summary_rows, 'VariableNames', { ...
    'row_id','scenario','scenario_group','eta','tau','random_amplitude','random_rho','max_abs_vote_resid', ...
    'mean_abs_vote_resid','max_abs_log_price_move','improvement_vs_constant','draw','verdict'});
summary = sortrows(summary, {'scenario_group','max_abs_vote_resid','max_abs_log_price_move'});
paths = cell2table(path_rows, 'VariableNames', { ...
    'row_id','scenario','scenario_group','year','period','eta','tau','random_amplitude','draw', ...
    'price','log_price_move','vote','vote_resid','pressure','restriction'});

writetable(summary, fullfile(out_dir, 'summary.csv'));
writetable(paths, fullfile(out_dir, 'paths.csv'));
write_note(fullfile(out_dir, 'note.md'), cfg, target_vote, reference_price, constant_max_abs, summary);
write_status(status_path, 'complete', 'Annual political comparison map complete.', cfg.RunTag, out_dir);
disp('Annual political comparison map complete.');
end

function [price_path, pressure_path, restriction_path, vote_path, resid_path] = simulate_feedback_path(eta, tau, pressure_mode, cfg, T, reference_price, PriceHouse, VoteBaseline, target_vote)
restriction_path = nan(T, 1);
pressure_path = nan(T, 1);
price_path = nan(T, 1);
vote_path = nan(T, 1);
resid_path = nan(T, 1);

for t = 1:T
    restriction = 0;
    for ii = 1:cfg.PeriodIter
        price = reference_price * exp(restriction);
        price = clamp_price(price, reference_price, PriceHouse, cfg.MaxAbsLogPriceMove);
        vote = interp_vote(PriceHouse, VoteBaseline(t, :), price);
        resid = vote - target_vote;
        pressure = compute_pressure(resid, tau, pressure_mode);
        restriction_target = eta * pressure;
        restriction_target = min(max(restriction_target, -cfg.RestrictionCap), cfg.RestrictionCap);
        restriction = (1 - cfg.UpdateRelaxation) * restriction + cfg.UpdateRelaxation * restriction_target;
    end
    price = reference_price * exp(restriction);
    price = clamp_price(price, reference_price, PriceHouse, cfg.MaxAbsLogPriceMove);
    vote = interp_vote(PriceHouse, VoteBaseline(t, :), price);
    resid = vote - target_vote;
    pressure = compute_pressure(resid, tau, pressure_mode);
    restriction_path(t) = restriction;
    pressure_path(t) = pressure;
    price_path(t) = price;
    vote_path(t) = vote;
    resid_path(t) = resid;
end
end

function pressure = compute_pressure(resid, tau, pressure_mode)
switch lower(string(pressure_mode))
    case "smooth"
        pressure = tanh(resid / tau);
    case "hard_sign"
        pressure = sign(resid);
    otherwise
        error('Unknown pressure mode: %s', pressure_mode);
end
end

function [row_ix, summary_rows, path_rows, path_ix] = add_feedback_path(row_ix, summary_rows, path_rows, path_ix, scenario, scenario_group, eta, tau, random_amplitude, random_rho, draw, price_path, pressure_path, restriction_path, vote_path, resid_path, years, reference_price, constant_max_abs)
row_ix = row_ix + 1;
max_abs_vote = max(abs(resid_path));
mean_abs_vote = mean(abs(resid_path));
max_abs_log_price = max(abs(log(price_path(:) ./ reference_price)));
improvement = constant_max_abs - max_abs_vote;
verdict = classify_path(max_abs_vote, max_abs_log_price, improvement);
summary_rows(row_ix, :) = {row_ix, scenario, scenario_group, eta, tau, random_amplitude, random_rho, max_abs_vote, mean_abs_vote, max_abs_log_price, improvement, draw, verdict};
for t = 1:numel(price_path)
    path_ix = path_ix + 1;
    path_rows(path_ix, :) = {row_ix, scenario, scenario_group, years(t), t, eta, tau, random_amplitude, draw, price_path(t), log(price_path(t) ./ reference_price), vote_path(t), resid_path(t), pressure_path(t), restriction_path(t)};
end
end

function [row_ix, summary_rows, path_rows, path_ix] = add_exogenous_path(row_ix, summary_rows, path_rows, path_ix, scenario, scenario_group, eta, tau, random_amplitude, random_rho, draw, price_path, years, reference_price, PriceHouse, VoteBaseline, target_vote, constant_max_abs)
if nargin < 18
    constant_max_abs = NaN;
end
vote_path = nan(numel(price_path), 1);
resid_path = nan(numel(price_path), 1);
for t = 1:numel(price_path)
    vote_path(t) = interp_vote(PriceHouse, VoteBaseline(t, :), price_path(t));
    resid_path(t) = vote_path(t) - target_vote;
end
if isnan(constant_max_abs)
    constant_max_abs = max(abs(resid_path));
end
pressure_path = nan(numel(price_path), 1);
restriction_path = nan(numel(price_path), 1);
[row_ix, summary_rows, path_rows, path_ix] = add_feedback_path(row_ix, summary_rows, path_rows, path_ix, scenario, scenario_group, eta, tau, random_amplitude, random_rho, draw, price_path, pressure_path, restriction_path, vote_path, resid_path, years, reference_price, constant_max_abs);
end

function price = clamp_price(price, reference_price, PriceHouse, max_abs_log_move)
price = min(max(price, reference_price * exp(-max_abs_log_move)), reference_price * exp(max_abs_log_move));
price = min(max(price, min(PriceHouse)), max(PriceHouse));
end

function log_move = random_log_price_path(T, rho, amplitude)
eps = randn(T, 1);
raw = zeros(T, 1);
for t = 2:T
    raw(t) = rho * raw(t - 1) + eps(t);
end
raw = raw - mean(raw);
scale = max(abs(raw));
if scale <= 0
    log_move = zeros(T, 1);
else
    log_move = amplitude * raw ./ scale;
end
end

function y = interp_vote(price_grid, vote_row, price)
[x_unique, ia] = unique(price_grid(:));
v_unique = vote_row(ia);
y = interp1(x_unique, v_unique(:), price, 'linear', 'extrap');
end

function hard_price = get_hard_price(S, T, PriceHouse, VoteBaseline, target_vote)
if isfield(S, 'Price_Trend') && isfield(S.Price_Trend, 'Baseline')
    hard_price = S.Price_Trend.Baseline(:);
    hard_price = hard_price(1:T);
    return
end
hard_price = nan(T, 1);
for t = 1:T
    [~, ix] = min(abs(VoteBaseline(t, :) - target_vote));
    hard_price(t) = PriceHouse(ix);
end
end

function verdict = classify_path(max_abs_vote, max_abs_log_price, improvement)
if max_abs_log_price >= 0.179
    verdict = "dead_price_cap";
elseif max_abs_vote <= 0.015
    verdict = "usable";
elseif max_abs_vote <= 0.035
    verdict = "survivor";
elseif improvement > 0
    verdict = "weak_survivor";
else
    verdict = "dead";
end
end

function write_note(note_path, cfg, target_vote, reference_price, constant_max_abs, summary)
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Annual political comparison map\n\n');
fprintf(fid, 'This is a saved-grid diagnostic. It compares the smoothed political pass-through rule against hard-sign and exogenous/random house-price paths on the same annual price/vote map.\n\n');
fprintf(fid, '## Setup\n\n');
fprintf(fid, '- source: `%s`\n', cfg.SourceMat);
fprintf(fid, '- horizon: `%d` annual periods\n', cfg.T);
fprintf(fid, '- reference price: `%.6f`\n', reference_price);
fprintf(fid, '- target vote share: `%.6f`\n', target_vote);
fprintf(fid, '- constant-price max abs vote residual: `%.6f`\n', constant_max_abs);
fprintf(fid, '- random draws per amplitude: `%d`\n', cfg.RandomDraws);
fprintf(fid, '- random amplitudes: `%s`\n\n', mat2str(cfg.RandomAmplitudeGrid));

fprintf(fid, '## Key rows\n\n');
groups = ["endogenous_smooth", "near_hard_tau", "hard_sign_tau0", "constant", "oracle"];
for g = 1:numel(groups)
    group = groups(g);
    sub = summary(strcmp(string(summary.scenario_group), group), :);
    if isempty(sub)
        continue
    end
    sub = sortrows(sub, {'max_abs_vote_resid','max_abs_log_price_move'});
    top_n = min(6, height(sub));
    fprintf(fid, '### %s\n\n', group);
    fprintf(fid, '| scenario | eta | tau | max abs vote residual | max abs log price move | improvement | verdict |\n');
    fprintf(fid, '|---|---:|---:|---:|---:|---:|---|\n');
    for i = 1:top_n
        fprintf(fid, '| %s | %.3f | %.4f | %.6f | %.6f | %.6f | %s |\n', ...
            string(sub.scenario(i)), sub.eta(i), sub.tau(i), sub.max_abs_vote_resid(i), ...
            sub.max_abs_log_price_move(i), sub.improvement_vs_constant(i), string(sub.verdict(i)));
    end
    fprintf(fid, '\n');
end

random_sub = summary(strcmp(string(summary.scenario_group), "random_ar1"), :);
if ~isempty(random_sub)
    fprintf(fid, '## Random-price distribution\n\n');
    fprintf(fid, '| amplitude | draws | min max residual | median max residual | p10 | p90 | share usable |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|\n');
    amps = unique(random_sub.random_amplitude);
    for ia = 1:numel(amps)
        amp = amps(ia);
        sub = random_sub(abs(random_sub.random_amplitude - amp) < 1.0e-12, :);
        vals = sort(sub.max_abs_vote_resid);
        p10 = vals(max(1, round(0.10 * numel(vals))));
        p50 = median(vals);
        p90 = vals(min(numel(vals), max(1, round(0.90 * numel(vals)))));
        share_usable = mean(strcmp(string(sub.verdict), "usable"));
        fprintf(fid, '| %.3f | %d | %.6f | %.6f | %.6f | %.6f | %.3f |\n', ...
            amp, height(sub), min(vals), p50, p10, p90, share_usable);
    end
end
end

function write_status(status_path, state, message, run_tag, out_dir)
fid = fopen(status_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '{"state":"%s","message":"%s","run_tag":"%s","output_dir":"%s","updated_at":"%s"}\n', ...
    state, escape_json(message), run_tag, strrep(out_dir, '\', '\\'), datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
end

function s = escape_json(s)
s = strrep(s, '\', '\\');
s = strrep(s, '"', '\"');
end
