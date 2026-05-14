function resolved_path = resolve_zac_david_external_path(varargin)
% Resolve a Zac and David external asset path with D:-first fallback order.

base_candidates = {
    getenv('ZAC_DAVID_EXTERNAL_ROOT')
    'D:\research_data\zac_and_david'
    fullfile(getenv('USERPROFILE'), 'Dropbox', 'Zac and David')
};

relative_path = '';
if nargin > 0
    relative_path = fullfile(varargin{:});
end

for i = 1:numel(base_candidates)
    base_dir = strtrim(base_candidates{i});
    if isempty(base_dir)
        continue;
    end

    if isempty(relative_path)
        candidate = base_dir;
    else
        candidate = fullfile(base_dir, relative_path);
    end

    if exist(candidate, 'file') || exist(candidate, 'dir')
        resolved_path = candidate;
        return;
    end
end

if isempty(relative_path)
    error('Could not find a Zac and David external root in the configured search paths.');
end

error('Could not find external asset: %s', relative_path);
end
