function mod_path = build_original_5yr_dynare_reduced_path_scaffold(input_mat_path, output_dir)
% Build a first Dynare .mod scaffold for the reduced-path NIMBY RE problem.

if nargin < 1 || isempty(input_mat_path)
    this_dir = fileparts(mfilename('fullpath'));
    input_mat_path = fullfile(this_dir, 'generated', 'nimby_dynare_scaffold_input.mat');
end
if nargin < 2 || isempty(output_dir)
    output_dir = fileparts(input_mat_path);
end

data = load(input_mat_path, 'inputs');
inputs = data.inputs;

T = inputs.max_k;
B = inputs.basis_count;
seed_logp = inputs.log_seed_price_path(:);
basis = inputs.basis;

coeff_names = arrayfun(@(j) sprintf('c%d', j), 1:B, 'UniformOutput', false);
logp_names = arrayfun(@(t) sprintf('logp_%d', t), 1:T, 'UniformOutput', false);
votegap_names = arrayfun(@(t) sprintf('votegap_%d', t), 1:T, 'UniformOutput', false);

param_lines = {};
for j = 1:B
    for t = 1:T
        param_lines{end+1} = sprintf('basis_%d_%d = %.17g;', t, j, basis(t, j));
    end
end
for t = 1:T
    param_lines{end+1} = sprintf('seed_logp_%d = %.17g;', t, seed_logp(t));
end

model_lines = {};
for j = 1:B
    model_lines{end+1} = sprintf('%s = %s(-1);', coeff_names{j}, coeff_names{j});
end
for t = 1:T
    rhs_terms = arrayfun(@(j) sprintf('basis_%d_%d*%s', t, j, coeff_names{j}), 1:B, 'UniformOutput', false);
    model_lines{end+1} = sprintf('%s = %s;', logp_names{t}, strjoin(rhs_terms, ' + '));
end
model_lines{end+1} = '% TODO: Replace the placeholder votegap equations below with a reduced-form equilibrium block.';
model_lines{end+1} = '% The current placeholder simply measures deviations from the incumbent log-price path.';
for t = 1:T
    model_lines{end+1} = sprintf('%s = %s - seed_logp_%d;', votegap_names{t}, logp_names{t}, t);
end

init_lines = {};
for j = 1:B
    init_lines{end+1} = sprintf('%s = 0;', coeff_names{j});
end
for t = 1:T
    init_lines{end+1} = sprintf('%s = seed_logp_%d;', logp_names{t}, t);
    init_lines{end+1} = sprintf('%s = 0;', votegap_names{t});
end

mod_lines = {
    '// Dynare reduced-path scaffold for the original 5-year NIMBY RE problem'
    '// Auto-generated from the incumbent full-horizon seed path and reduced basis.'
    '//'
    '// This file is intentionally a scaffold: it maps coefficient variables into'
    '// the 14-period log-price path, but the true RE residual block still needs'
    '// to be replaced where marked below.'
    ''
    ['var ' strjoin([coeff_names, logp_names, votegap_names], ' ') ';']
    ['parameters ' strjoin([build_param_name_list_local(T, B), build_seed_param_list_local(T)], ' ') ';']
    ''
    strjoin(param_lines, newline)
    ''
    'model;'
    strjoin(model_lines, newline)
    'end;'
    ''
    'initval;'
    strjoin(init_lines, newline)
    'end;'
    ''
    sprintf('perfect_foresight_setup(periods=%d);', T)
    '% perfect_foresight_solver;'
    ''
    '// Suggested next step: replace votegap_t placeholder equations with'
    '// reduced equilibrium conditions and then enable perfect_foresight_solver.'
    ''
    '// Incumbent active periods from MATLAB scaffold:'
    ['// ' strjoin(string(inputs.active_periods(:)'), ', ')]
    ''
};

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
mod_path = fullfile(output_dir, 'nimby_reduced_path_scaffold.mod');
mod_lines = cellfun(@normalize_line_local, mod_lines, 'UniformOutput', false);
write_lines_local(mod_path, mod_lines);
end

function names = build_param_name_list_local(T, B)
names = cell(1, T * B);
idx = 1;
for j = 1:B
    for t = 1:T
        names{idx} = sprintf('basis_%d_%d', t, j);
        idx = idx + 1;
    end
end
end

function names = build_seed_param_list_local(T)
names = arrayfun(@(t) sprintf('seed_logp_%d', t), 1:T, 'UniformOutput', false);
end

function text = normalize_line_local(value)
text = char(string(value));
if size(text, 1) > 1
    text = strjoin(cellstr(text), newline);
end
end

function write_lines_local(path_str, lines)
fid = fopen(path_str, 'w');
if fid < 0
    error('Could not open file for writing: %s', path_str);
end
cleanup_obj = onCleanup(@() fclose(fid));
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
