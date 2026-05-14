function ensure_external_matlab_data_paths()
% Prefer large external MATLAB asset folders on D:, with Dropbox fallback.

persistent configured;
if ~isempty(configured) && configured
    return;
end

base_candidates = {
    getenv('ZAC_DAVID_EXTERNAL_ROOT')
    'D:\research_data\zac_and_david'
    'C:\Users\Dave_\Dropbox\Zac and David'
};

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
