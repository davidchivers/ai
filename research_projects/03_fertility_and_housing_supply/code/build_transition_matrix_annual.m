function output_file = build_transition_matrix_annual(output_file)
if nargin < 1 || isempty(output_file)
    project_root = fileparts(fileparts(mfilename('fullpath')));
    output_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_annual.mat');
end
output_file = build_transition_matrix_periodized(output_file, 1, 25, 80);
end
