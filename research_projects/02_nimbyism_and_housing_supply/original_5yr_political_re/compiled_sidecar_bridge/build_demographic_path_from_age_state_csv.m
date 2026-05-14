function demographic_path = build_demographic_path_from_age_state_csv(project_root)
% Bridge for the compiled original-5-year lane.
%
% The compiled-sidecar exporter expects build_demographic_path_from_age_state_csv
% on the MATLAB path. For this lane we intentionally shadow the annual-subsample
% builder and route it to the historical 1950-based 5-year path.

if nargin < 1 || isempty(project_root)
    this_file = mfilename('fullpath');
    this_dir = fileparts(this_file);
    project_root = fileparts(fileparts(this_dir));
end

demographic_path = build_original_5yr_demographic_path_from_historical_age_shares(project_root);
end
