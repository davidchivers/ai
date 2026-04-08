function results = run_anticipated_demographics_re_structural()
%RUN_ANTICIPATED_DEMOGRAPHICS_RE_STRUCTURAL
% Endpoint-interpolation scaffold for the same benchmark using baseline and
% boom endpoint files from the original project when they are available.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
extension_dir = fileparts(this_dir);
project_dir = fileparts(extension_dir);
results_dir = fullfile(extension_dir, 'results');

if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

[baseline, baseline_path] = load_endpoint(project_dir, extension_dir, 'baseline');
[boom, boom_path] = load_endpoint(project_dir, extension_dir, 'boom');

if isempty(baseline) || isempty(boom)
    results = struct();
    results.status = 'missing_inputs';
    results.message = [ ...
        'No structural endpoint files were found. Expected either ' ...
        'extension/input/{baseline,boom}_endpoint.mat or raw ' ...
        'code/steadystate/SS_iter(.mat) style files copied into extension/input/.' ...
    ];

    disp(results.message);
    return;
end

params = struct();
params.age_bins = (25:5:90)';
params.num_periods = 18;
params.beta = 0.80;
params.lambda_re = 0.65;
params.kappa_price = 0.35;
params.boom_scale = 0.55;
params.baseline_mass = ones(numel(params.age_bins), 1);

demo = make_boom_projection_path( ...
    params.age_bins, ...
    params.num_periods, ...
    params.baseline_mass, ...
    params.boom_scale);

age_span = max(params.age_bins) - min(params.age_bins);
boom_weight = (demo.boom_age_bin - min(params.age_bins)) ./ max(age_span, eps);
boom_weight = min(max(boom_weight, 0), 1);

theta_demographic = baseline.vote_support + boom_weight .* (boom.vote_support - baseline.vote_support);
theta_re = theta_demographic;

for t = 1:params.num_periods
    future_gap = theta_demographic((t + 1):end) - baseline.vote_support;
    horizon = (1:numel(future_gap))';
    theta_re(t) = theta_demographic(t) + params.lambda_re * sum((params.beta .^ horizon) .* future_gap);
end

price_demographic = baseline.price + boom_weight .* (boom.price - baseline.price);
price_re = price_demographic .* exp(params.kappa_price .* (theta_re - theta_demographic));

results_table = table( ...
    (0:(params.num_periods - 1))', ...
    demo.boom_age_bin, ...
    boom_weight, ...
    theta_demographic, ...
    theta_re, ...
    price_demographic, ...
    price_re, ...
    'VariableNames', { ...
        'period', ...
        'boom_age_bin', ...
        'boom_weight', ...
        'theta_demographic', ...
        'theta_re', ...
        'price_demographic', ...
        'price_re' ...
    });

writetable(results_table, fullfile(results_dir, 'anticipated_demographics_re_structural.csv'));

results = struct();
results.status = 'ok';
results.params = params;
results.baseline = baseline;
results.boom = boom;
results.baseline_path = baseline_path;
results.boom_path = boom_path;
results.table = results_table;

disp('Structural anticipated-demographics scaffold saved to extension/results/.');

end

function [endpoint, source_path] = load_endpoint(project_dir, extension_dir, label)
endpoint = [];
source_path = '';

input_dir = fullfile(extension_dir, 'input');
named_path = fullfile(input_dir, [label '_endpoint.mat']);
raw_path = fullfile(input_dir, ['SS_iter' suffix_from_label(label) '.mat']);

candidate_paths = {named_path, raw_path};

for i = 1:numel(candidate_paths)
    if exist(candidate_paths{i}, 'file')
        raw = load(candidate_paths{i});
        [endpoint, ok] = parse_endpoint(raw, label);
        if ok
            source_path = candidate_paths{i};
            return;
        end
    end
end

% Keep the project root out of automatic writes, but allow local manual copies.
project_candidate = fullfile(project_dir, 'code', 'steadystate', ['SS_iter' suffix_from_label(label) '.mat']);
if exist(project_candidate, 'file')
    raw = load(project_candidate);
    [endpoint, ok] = parse_endpoint(raw, label);
    if ok
        source_path = project_candidate;
    end
end
end

function [endpoint, ok] = parse_endpoint(raw, label)
endpoint = [];
ok = false;

if isfield(raw, 'price') && isfield(raw, 'vote_support')
    endpoint = struct('label', label, 'price', raw.price, 'vote_support', raw.vote_support);
    ok = true;
    return;
end

if isfield(raw, 'a_price') && isfield(raw, 'totalvote')
    endpoint = struct('label', label, 'price', raw.a_price, 'vote_support', raw.totalvote);
    ok = true;
end
end

function suffix = suffix_from_label(label)
if strcmpi(label, 'boom')
    suffix = '_boom';
else
    suffix = '';
end
end
