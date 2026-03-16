function [transitionmatrix, z, Zlifecycle, initialdist, source_path] = load_transition_matrix_data()
% Resolve a TransitionMatrix bundle with the fields the extension needs.
% The imported steady-state and Codes_ABB files are not identical, so this
% loader picks a usable transition file first and then fills initialdist.

external_root = strtrim(getenv('ZAC_DAVID_EXTERNAL_ROOT'));
transition_candidates = {};
if ~isempty(external_root)
    transition_candidates{end + 1} = fullfile(external_root, 'Code', 'Codes_ABB', 'TransitionMatrix.mat'); %#ok<AGROW>
    transition_candidates{end + 1} = fullfile(external_root, 'Code', 'SteadyState', 'TransitionMatrix.mat'); %#ok<AGROW>
end
transition_candidates{end + 1} = 'D:\research_data\zac_and_david\Code\Codes_ABB\TransitionMatrix.mat';
transition_candidates{end + 1} = 'D:\research_data\zac_and_david\Code\SteadyState\TransitionMatrix.mat';
transition_candidates{end + 1} = 'C:\Users\Dave_\Dropbox\Zac and David\Code\Codes_ABB\TransitionMatrix.mat';
transition_candidates{end + 1} = 'C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\TransitionMatrix.mat';

source_path = '';
transitionmatrix = [];
z = [];
Zlifecycle = [];

for i = 1:numel(transition_candidates)
    candidate = strtrim(transition_candidates{i});
    if isempty(candidate) || ~isfile(candidate)
        continue;
    end

    vars = {whos('-file', candidate).name};
    if ~ismember('transitionmatrix', vars) || ~ismember('y_mid', vars) || ~ismember('z_lifecycle', vars)
        continue;
    end

    tmp = load(candidate, 'transitionmatrix', 'y_mid', 'z_lifecycle');

    if ndims(tmp.transitionmatrix) ~= 3
        continue;
    end

    if size(tmp.transitionmatrix, 3) ~= numel(tmp.z_lifecycle) - 1
        continue;
    end

    source_path = candidate;
    transitionmatrix = tmp.transitionmatrix;
    z = tmp.y_mid;
    Zlifecycle = tmp.z_lifecycle ./ tmp.z_lifecycle(1);
    break;
end

if isempty(source_path)
    error(['No usable TransitionMatrix.mat found. Need transitionmatrix, y_mid, ', ...
           'and z_lifecycle with consistent lifecycle dimensions.']);
end

initialdist_candidates = {};
if ~isempty(external_root)
    initialdist_candidates{end + 1} = fullfile(external_root, 'Code', 'SteadyState', 'TransitionMatrix.mat'); %#ok<AGROW>
    initialdist_candidates{end + 1} = fullfile(external_root, 'Code', 'Codes_ABB', 'TransitionMatrix.mat'); %#ok<AGROW>
end
initialdist_candidates{end + 1} = 'D:\research_data\zac_and_david\Code\SteadyState\TransitionMatrix.mat';
initialdist_candidates{end + 1} = 'C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\TransitionMatrix.mat';
initialdist_candidates{end + 1} = source_path;

initialdist = [];
for i = 1:numel(initialdist_candidates)
    candidate = strtrim(initialdist_candidates{i});
    if isempty(candidate) || ~isfile(candidate)
        continue;
    end

    vars = {whos('-file', candidate).name};
    if ~ismember('initialdist', vars)
        continue;
    end

    tmp = load(candidate, 'initialdist');
    if isfield(tmp, 'initialdist') && numel(tmp.initialdist) == size(transitionmatrix, 1)
        initialdist = tmp.initialdist;
        break;
    end
end

if isempty(initialdist)
    warning('initialdist not found in compatible form. Reconstructing from transition matrix.');
    initialdist = stationary_dist(transitionmatrix(:, :, 1)');
end
end

function stat = stationary_dist(z_transition)
[vec, ~] = eigs(z_transition', 1, 'largestreal');
stat = real(vec);
stat = max(stat, 0);
stat = stat ./ sum(stat);
end
