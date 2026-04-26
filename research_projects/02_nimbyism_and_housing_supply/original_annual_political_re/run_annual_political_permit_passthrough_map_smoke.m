function run_annual_political_permit_passthrough_map_smoke(varargin)
% Reduced-form annual map smoke for political pressure -> permits -> prices.
%
% This deliberately uses the saved annual price/vote grid from the upstream
% Mod_IRF LOOP output. It does not rerun the household Bellman solver.

p = inputParser;
p.addParameter('SourceMat', 'C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_IRF\loop101_output_extended.mat');
p.addParameter('RunTag', '');
p.addParameter('T', 80);
p.addParameter('VoteScale', 0.02);
p.addParameter('RestrictionCap', 0.35);
p.addParameter('PhiGrid', [0, 0.01, 0.03, 0.06, 0.10, 0.20]);
p.addParameter('GammaGrid', [0.25, 0.50, 1.00, 1.50]);
p.addParameter('RhoGrid', [0, 0.50, 0.85]);
p.parse(varargin{:});
cfg = p.Results;

this_dir = fileparts(mfilename('fullpath'));
out_root = fullfile(this_dir, 'truth', 'annual_political_permit_passthrough_map');
if ~exist(out_root, 'dir')
    mkdir(out_root);
end
if isempty(cfg.RunTag)
    cfg.RunTag = ['annual_map_', datestr(now, 'yyyymmdd_HHMMSS')];
end
out_dir = fullfile(out_root, cfg.RunTag);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
status_path = fullfile(out_root, 'latest_status.json');
write_status(status_path, 'running', 'Loading saved annual price/vote map.', cfg.RunTag, out_dir);

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
year = (1950:(1950 + T - 1))';
ref_year_index = min(51, n_years);
target_vote = VoteBaseline(ref_year_index, ind_reference);
reference_price = PriceHouse(ind_reference);
hard_price = get_hard_price(S, T, PriceHouse, VoteBaseline, target_vote);

base_vote = nan(T, 1);
base_resid = nan(T, 1);
for t = 1:T
    base_vote(t) = interp_vote(PriceHouse, VoteBaseline(t, :), reference_price);
    base_resid(t) = base_vote(t) - target_vote;
end
base_max_abs_resid = max(abs(base_resid));
base_mean_abs_resid = mean(abs(base_resid));
hard_max_log_move = max(abs(log(hard_price(:) ./ reference_price)));

rows = {};
path_rows = {};
row_ix = 0;
path_ix = 0;
for ir = 1:numel(cfg.RhoGrid)
    rho = cfg.RhoGrid(ir);
    for ip = 1:numel(cfg.PhiGrid)
        phi = cfg.PhiGrid(ip);
        for ig = 1:numel(cfg.GammaGrid)
            gamma = cfg.GammaGrid(ig);
            row_ix = row_ix + 1;
            restriction = 0;
            adj_price = nan(T, 1);
            adj_vote = nan(T, 1);
            adj_resid = nan(T, 1);
            pressure = nan(T, 1);
            hit_grid = false(T, 1);
            restriction_path = nan(T, 1);
            for t = 1:T
                current_vote = interp_vote(PriceHouse, VoteBaseline(t, :), reference_price);
                current_resid = current_vote - target_vote;
                pressure(t) = tanh(current_resid / cfg.VoteScale);
                restriction = rho * restriction + phi * pressure(t);
                restriction = min(max(restriction, -cfg.RestrictionCap), cfg.RestrictionCap);
                restriction_path(t) = restriction;

                raw_price = reference_price * exp(gamma * restriction);
                adj_price(t) = min(max(raw_price, min(PriceHouse)), max(PriceHouse));
                hit_grid(t) = abs(adj_price(t) - raw_price) > 1.0e-10;
                adj_vote(t) = interp_vote(PriceHouse, VoteBaseline(t, :), adj_price(t));
                adj_resid(t) = adj_vote(t) - target_vote;

                path_ix = path_ix + 1;
                path_rows(path_ix, :) = {row_ix, year(t), rho, phi, gamma, base_resid(t), pressure(t), restriction_path(t), adj_price(t), adj_resid(t), hard_price(t), hit_grid(t)};
            end
            max_abs_resid = max(abs(adj_resid));
            mean_abs_resid = mean(abs(adj_resid));
            improvement = base_max_abs_resid - max_abs_resid;
            max_log_price_move = max(abs(log(adj_price ./ reference_price)));
            hard_distance = max(abs(log(adj_price ./ hard_price(:))));
            grid_hit_share = mean(hit_grid);
            [verdict, verdict_rank] = classify_row(max_abs_resid, improvement, max_log_price_move, grid_hit_share, base_max_abs_resid);
            rows(row_ix, :) = {row_ix, rho, phi, gamma, max_abs_resid, mean_abs_resid, improvement, max_log_price_move, hard_distance, max(abs(restriction_path)), grid_hit_share, verdict, verdict_rank};
        end
    end
end

summary = cell2table(rows, 'VariableNames', {'row_id','rho','phi','gamma','max_abs_vote_resid','mean_abs_vote_resid','improvement_vs_constant','max_abs_log_price_move','max_abs_log_gap_to_hard_clear','max_abs_restriction','grid_hit_share','verdict','verdict_rank'});
summary = sortrows(summary, {'verdict_rank','max_abs_vote_resid','max_abs_log_price_move'});
paths = cell2table(path_rows, 'VariableNames', {'row_id','year','rho','phi','gamma','base_vote_resid','pressure','restriction','price','vote_resid','hard_clear_price','hit_grid'});

writetable(summary, fullfile(out_dir, 'summary.csv'));
writetable(paths, fullfile(out_dir, 'paths.csv'));
write_note(fullfile(out_dir, 'note.md'), cfg, target_vote, reference_price, base_max_abs_resid, base_mean_abs_resid, hard_max_log_move, summary);
write_status(status_path, 'complete', 'Annual saved-grid political pass-through smoke complete.', cfg.RunTag, out_dir);
disp('Annual political permit pass-through map smoke complete.');
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

function [verdict, verdict_rank] = classify_row(max_abs_resid, improvement, max_log_price_move, grid_hit_share, base_max_abs_resid)
if improvement <= 0
    verdict = "dead";
    verdict_rank = 4;
elseif max_abs_resid <= min(0.03, 0.60 * base_max_abs_resid) && max_log_price_move <= 0.30
    verdict = "usable";
    verdict_rank = 1;
elseif grid_hit_share > 0.05 && max_abs_resid <= 0.06 && max_log_price_move <= 0.30
    verdict = "grid_limited_survivor";
    verdict_rank = 2;
elseif max_abs_resid <= min(0.04, 0.95 * base_max_abs_resid) && max_log_price_move <= 0.30
    verdict = "survivor";
    verdict_rank = 2;
elseif max_abs_resid < base_max_abs_resid && max_log_price_move <= 0.45
    verdict = "weak_survivor";
    verdict_rank = 3;
else
    verdict = "dead";
    verdict_rank = 4;
end
end

function write_note(note_path, cfg, target_vote, reference_price, base_max_abs_resid, base_mean_abs_resid, hard_max_log_move, summary)
fid = fopen(note_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Annual political permit pass-through map smoke\n\n');
fprintf(fid, 'This is a reduced-form saved-grid smoke. It does not rerun the household Bellman solver.\n\n');
fprintf(fid, '## Baseline\n\n');
fprintf(fid, '- source: `%s`\n', cfg.SourceMat);
fprintf(fid, '- horizon: `%d` annual periods\n', cfg.T);
fprintf(fid, '- reference price: `%.6f`\n', reference_price);
fprintf(fid, '- target vote share: `%.6f`\n', target_vote);
fprintf(fid, '- constant-price max abs vote residual: `%.6f`\n', base_max_abs_resid);
fprintf(fid, '- constant-price mean abs vote residual: `%.6f`\n', base_mean_abs_resid);
fprintf(fid, '- hard-clear max abs log price move from reference: `%.6f`\n\n', hard_max_log_move);
fprintf(fid, '## Top rows\n\n');
fprintf(fid, '| verdict | rho | phi | gamma | max abs vote residual | improvement | max abs log price move | grid hit share |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|\n');
top_n = min(12, height(summary));
for i = 1:top_n
    fprintf(fid, '| %s | %.3f | %.3f | %.3f | %.6f | %.6f | %.6f | %.3f |\n', ...
        string(summary.verdict(i)), summary.rho(i), summary.phi(i), summary.gamma(i), ...
        summary.max_abs_vote_resid(i), summary.improvement_vs_constant(i), ...
        summary.max_abs_log_price_move(i), summary.grid_hit_share(i));
end
fprintf(fid, '\n## Read\n\n');
fprintf(fid, 'Rows marked `usable` or `survivor` are candidates for a real annual `T = 4` transition smoke. ');
fprintf(fid, '`Grid_limited_survivor` means the sign is promising but the saved price grid is too narrow for that strength. ');
fprintf(fid, 'Rows marked `dead` should not be sent to Hamilton; they either do not improve the vote residual or require implausible price movement.\n');
end

function write_status(status_path, state, message, run_tag, out_dir)
fid = fopen(status_path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '{"state":"%s","message":"%s","run_tag":"%s","output_dir":"%s","updated_at":"%s"}\n', ...
    state, message, run_tag, strrep(out_dir, '\', '\\'), datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
end
