function ensure_external_matlab_data_paths()
% Prefer explicit/D: external asset folders, with user Dropbox fallback.

persistent configured;
if ~isempty(configured) && configured
    return;
end

base_candidates = {
    getenv('ZAC_DAVID_EXTERNAL_ROOT')
    'D:\research_data\zac_and_david'
};

user_profile = getenv('USERPROFILE');
if ~isempty(user_profile)
    base_candidates{end + 1} = fullfile(user_profile, 'Dropbox', 'Zac and David');
end

home_dir = getenv('HOME');
if ~isempty(home_dir)
    base_candidates{end + 1} = fullfile(home_dir, 'Dropbox', 'Zac and David');
end

% Legacy Dave machine fallback. Keep last so collaborators do not need this path.
base_candidates{end + 1} = 'C:\Users\Dave_\Dropbox\Zac and David';

subdirs = {
    fullfile('Code', 'SteadyState')
    fullfile('Code', 'Codes_ABB')
};

for i = 1:numel(base_candidates)
    base_dir = strtrim(base_candidates{i});
    if isempty(base_dir)
        continue;
    end
    for j = 1:numel(subdirs)
        candidate = fullfile(base_dir, subdirs{j});
        if exist(candidate, 'dir')
            addpath(candidate);
        end
    end
end

configured = true;
end
