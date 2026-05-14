function mod_path = build_original_5yr_dynare_reduced_system_mod(input_mat_path, output_dir)
% Build a real Dynare reduced-path system from the exported normal equations.

if nargin < 1 || isempty(input_mat_path)
    this_dir = fileparts(mfilename('fullpath'));
    input_mat_path = fullfile(this_dir, 'generated', 'nimby_dynare_reduced_system_input.mat');
end
if nargin < 2 || isempty(output_dir)
    output_dir = fileparts(input_mat_path);
end

data = load(input_mat_path, 'system');
system = data.system;

B = system.basis_count;
T = system.max_k;
coeff_names = arrayfun(@(j) sprintf('c%d', j), 1:B, 'UniformOutput', false);
normal_rhs_names = arrayfun(@(j) sprintf('rhs_%d', j), 1:B, 'UniformOutput', false);
matrix_names = cell(B, B);
for j = 1:B
    for k = 1:B
        matrix_names{j, k} = sprintf('n_%d_%d', j, k);
    end
end

param_names = [normal_rhs_names, reshape(matrix_names', 1, [])];

param_lines = {};
for j = 1:B
    param_lines{end + 1} = sprintf('rhs_%d = %.17g;', j, system.normal_rhs(j));
end
for j = 1:B
    for k = 1:B
        param_lines{end + 1} = sprintf('n_%d_%d = %.17g;', j, k, system.regularized_normal_matrix(j, k));
    end
end

comment_lines = {};
for t = 1:T
    basis_terms = arrayfun(@(j) sprintf('%.8g*c%d', system.basis(t, j), j), 1:B, 'UniformOutput', false);
    comment_lines{end + 1} = sprintf('// logp_%d = %.17g + %s', t, system.log_seed_price_path(t), strjoin(basis_terms, ' + '));
end

model_lines = {};
for j = 1:B
    rhs_terms = arrayfun(@(k) sprintf('n_%d_%d*%s', j, k, coeff_names{k}), 1:B, 'UniformOutput', false);
    % Dynare treats a bare expression in the model block as "= 0".
    model_lines{end + 1} = sprintf('rhs_%d + %s;', j, strjoin(rhs_terms, ' + '));
end

init_lines = arrayfun(@(j) sprintf('c%d = 0;', j), 1:B, 'UniformOutput', false);

mod_lines = {
    '// Dynare reduced-path normal-equation system for the original 5-year NIMBY RE problem'
    '// Auto-generated from the incumbent seed path, active residual vector, and finite-difference reduced Jacobian.'
    '// Dynare solves the regularized normal equations for the reduced coefficient update.'
    ''
    ['var ' strjoin(coeff_names, ' ') ';']
    ['parameters ' strjoin(param_names, ' ') ';']
    ''
    strjoin(param_lines, newline)
    ''
    '// Implied log-price path from the reduced coefficients:'
    strjoin(comment_lines, newline)
    ''
    'model;'
    strjoin(model_lines, newline)
    'end;'
    ''
    'initval;'
    strjoin(init_lines, newline)
    'end;'
    ''
    'steady(maxit=100, solve_algo=4);'
    ''
};

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
mod_path = fullfile(output_dir, 'nimby_reduced_path_system.mod');
mod_lines = cellfun(@normalize_line_local, mod_lines, 'UniformOutput', false);
write_lines_local(mod_path, mod_lines);
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
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
