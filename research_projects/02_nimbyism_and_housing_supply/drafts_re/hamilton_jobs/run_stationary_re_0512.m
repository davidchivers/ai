function run_stationary_re_0512(row_id, varargin)
% Stationary rational-expectations benchmarks for the old NIMBY model.

p = inputParser;
p.addRequired('row_id');
p.addParameter('GridCsv', fullfile(pwd, 'model_stationary_re_0512.csv'));
p.addParameter('RunRoot', fileparts(pwd));
p.parse(row_id, varargin{:});
cfg = p.Results;

if ischar(cfg.row_id) || isstring(cfg.row_id)
    row_id_num = str2double(string(cfg.row_id));
else
    row_id_num = cfg.row_id;
end
if ~isfinite(row_id_num)
    error('Invalid row_id: %s', string(cfg.row_id));
end

opts = detectImportOptions(cfg.GridCsv, 'TextType', 'string');
grid = readtable(cfg.GridCsv, opts);
row = grid(grid.row_id == row_id_num, :);
if height(row) ~= 1
    error('Expected exactly one stationary row for row_id %.0f, found %.0f.', row_id_num, height(row));
end

annual_dir = pwd;
run_tag = row_text(row, 'run_tag');
age_path = write_stationary_age_path(row, annual_dir, cfg.RunRoot);
pass_through = abs(row_number(row, 'pass_through'));

fprintf('Running stationary RE row %.0f: %s\n', row_id_num, run_tag);
run_annual_political_full_re_price_path( ...
    'RunTag', run_tag, ...
    'T', 1, ...
    'TailYears', 0, ...
    'PostReportDemographicMode', 'natural', ...
    'TerminalAnchor', 'terminal_fixed_point', ...
    'TerminalIter', round(row_number_default(row, 'terminal_iter', 500)), ...
    'TerminalRelaxation', row_number_default(row, 'terminal_relaxation', 0.20), ...
    'TerminalBlendWeight', 1.00, ...
    'OuterIter', 1, ...
    'PathRelaxation', 0.00, ...
    'PathUpdateMethod', 'relaxation', ...
    'PoliticalPassThrough', -pass_through, ...
    'VoteScale', row_number_default(row, 'vote_scale', 0.02), ...
    'VoteRule', 'smooth_logit', ...
    'VoteTau', NaN, ...
    'VoteSigma', 0, ...
    'VoteShiftMode', 'block_vote', ...
    'VoteShiftHorizon', 1, ...
    'VoteBlockLength', 1, ...
    'LaggedPassThrough', false, ...
    'PassThroughLagYears', 1, ...
    'MaxAbsLogPriceMove', 0.18, ...
    'SourceMat', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat'), ...
    'DemographicScenario', 'external_age_path', ...
    'DemographicPathMat', age_path, ...
    'DemographicPathVar', 'ageimpulse', ...
    'DemographicShockAmplitude', 0.25, ...
    'ReferenceYear', NaN, ...
    'ModIrfDir', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_IRF'), ...
    'ModFunctionsDir', fullfile(cfg.RunRoot, 'SteadyState', 'Mod_Functions'), ...
    'CompeconDir', fullfile(cfg.RunRoot, 'COMPECON'));
end

function age_path = write_stationary_age_path(row, annual_dir, run_root)
run_tag = row_text(row, 'run_tag');
age_case = lower(string(row_text(row, 'age_case')));
source_path = fullfile(run_root, 'SteadyState', 'Mod_IRF', 'old_paper_source_min.mat');
S = load(source_path, 'agevector');
if ~isfield(S, 'agevector')
    error('old_paper_source_min.mat lacks agevector.');
end
baseline = normalize_agevector(double(S.agevector(:)));

switch age_case
    case "baseline"
        agevector = baseline;
    case "stationary_growth"
        growth_rate = row_number(row, 'growth_rate');
        agevector = stationary_growth_agevector(numel(baseline), growth_rate);
    case "official_projection_year"
        projection_year = round(row_number(row, 'projection_year'));
        P = load(fullfile(annual_dir, 'official_age_path_0512.mat'), 'ageimpulse', 'years');
        years = double(P.years(:));
        idx = find(years == projection_year, 1);
        if isempty(idx)
            error('Projection year %.0f not found in official_age_path_0512.mat.', projection_year);
        end
        agevector = normalize_agevector(double(P.ageimpulse(:, idx)));
    otherwise
        error('Unknown age_case: %s', age_case);
end

out_dir = fullfile(annual_dir, 'truth', 'stationary_re_0512_age_paths');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
ageimpulse = agevector(:); %#ok<NASGU>
model_ages = (25:(25 + numel(agevector) - 1))'; %#ok<NASGU>
age_path = fullfile(out_dir, [run_tag '_age_path.mat']);
save(age_path, 'ageimpulse', 'model_ages');
csv_path = fullfile(out_dir, [run_tag '_age_path.csv']);
writetable(table(model_ages, agevector(:), 'VariableNames', {'model_age','age_share'}), csv_path);
end

function agevector = stationary_growth_agevector(n_ages, growth_rate)
if growth_rate <= -0.05
    error('growth_rate must be above -0.05 for a stable normalized age profile.');
end
survival = default_annual_survival_rates(n_ages);
mass = zeros(n_ages, 1);
mass(1) = 1.0;
for j = 2:n_ages
    mass(j) = mass(j - 1) * survival(j - 1) / (1 + growth_rate);
end
agevector = normalize_agevector(mass);
end

function survival = default_annual_survival_rates(n_ages)
ages = (25:(25 + n_ages - 1))';
survival = 0.995 - 0.00015 * max(ages - 45, 0) - 0.0010 * max(ages - 70, 0);
survival = min(max(survival, 0.80), 0.998);
survival(end) = 0;
end

function agevector = normalize_agevector(agevector)
agevector = agevector(:);
agevector(~isfinite(agevector)) = 0;
agevector(agevector < 0) = 0;
total = sum(agevector);
if total <= 0
    error('Age vector has non-positive mass.');
end
agevector = agevector ./ total;
end

function value = row_text(row, name)
raw = row.(name);
if iscell(raw)
    raw = raw{1};
else
    raw = raw(1);
end
value = char(strtrim(string(raw)));
if strlength(string(value)) == 0
    error('Grid value %s is empty.', name);
end
end

function value = row_number(row, name)
value = row_number_default(row, name, NaN);
if ~isfinite(value)
    error('Grid value %s is not numeric.', name);
end
end

function value = row_number_default(row, name, default)
if ~ismember(name, row.Properties.VariableNames)
    value = default;
    return
end
raw = row.(name);
if iscell(raw)
    raw = raw{1};
else
    raw = raw(1);
end
if isnumeric(raw)
    value = double(raw);
else
    value = str2double(string(raw));
end
if ~isfinite(value)
    value = default;
end
end
