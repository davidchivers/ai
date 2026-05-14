function output_file = build_transition_matrix_periodized(output_file, dage, agemin, agemax)
project_root = fileparts(fileparts(mfilename('fullpath')));
this_code_dir = fullfile(project_root, 'code');
project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end

if nargin < 2 || isempty(dage)
    dage = 1;
end
if nargin < 3 || isempty(agemin)
    agemin = 25;
end
if nargin < 4 || isempty(agemax)
    agemax = 80;
end
if nargin < 1 || isempty(output_file)
    out_dir = fullfile(project_root, 'notes', 'build');
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    suffix = sprintf('TransitionMatrix_%dy_%d_%d.mat', dage, agemin, agemax);
    output_file = fullfile(out_dir, suffix);
else
    out_dir = fileparts(output_file);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
end

ensure_external_matlab_data_paths();
source_file = which('nl_zbl.mat');
if isempty(source_file)
    error('Could not find nl_zbl.mat on the MATLAB path while building the %d-year transition matrix.', dage);
end

tmp = load(source_file, 'ysim');
if ~isfield(tmp, 'ysim')
    error('Transition-matrix source file %s does not contain ysim.', source_file);
end
ysim = tmp.ysim;
n = size(ysim, 1);

y_lifecycle = mean(ysim);
y_idiosyn = ysim ./ y_lifecycle;
y_transformed = log(y_idiosyn);

age_disvec = agemin:dage:agemax;
y_vector = [-1e2, -1.5, -0.875, -0.25, 0.375, 1.0, 1e2];
raw_ages = 25:94;

y_mid = zeros(1, numel(y_vector) - 1);
y_mid(2:end-1) = mean([y_vector(3:end-1); y_vector(2:end-2)]);
y_mid(1) = 2 * y_mid(2) - y_mid(3);
y_mid(end) = 2 * y_mid(end - 1) - y_mid(end - 2);

[~, age_mapping] = min((age_disvec' - raw_ages).^2);
average_y = zeros(size(ysim, 1), numel(age_disvec));
z_lifecycle = zeros(1, numel(age_disvec));
for i = 1:numel(age_disvec)
    mask = age_mapping == i;
    if ~any(mask)
        error('No raw annual ages were mapped into age bin %d while building %s.', age_disvec(i), output_file);
    end
    average_y(:, i) = mean(y_transformed(:, mask), 2);
    z_lifecycle(i) = mean(y_lifecycle(:, mask), 2);
end

y_discrete = discretize(average_y, y_vector);
gridsize = numel(y_vector) - 1;
initialdist = sum((y_discrete(:, 1) == (1:gridsize)), 1);
initialdist = initialdist ./ sum(initialdist);

transitioncount = ones(gridsize, gridsize, numel(age_disvec) - 1);
for i = 1:(numel(age_disvec) - 1)
    transitioncount(:, :, i) = ones(gridsize, gridsize);
    for j = 1:n
        transitioncount(y_discrete(j, i), y_discrete(j, i + 1), i) = transitioncount(y_discrete(j, i), y_discrete(j, i + 1), i) + 1;
    end
end

transitioncount_all = sum(transitioncount, 3);
transitionmatrix_all = transitioncount_all ./ sum(transitioncount_all, 2);
transitionmatrix = transitioncount ./ sum(transitioncount, 2);
transitionmatrix(isnan(transitionmatrix)) = 0;

save(output_file, 'transitionmatrix', 'transitionmatrix_all', 'initialdist', 'y_mid', 'z_lifecycle');
fprintf('Saved %d-year transition matrix to %s\n', dage, output_file);
end
