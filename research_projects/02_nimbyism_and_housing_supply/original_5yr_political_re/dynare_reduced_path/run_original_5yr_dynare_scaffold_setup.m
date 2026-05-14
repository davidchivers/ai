function setup = run_original_5yr_dynare_scaffold_setup(max_k, basis_count, demographic_source_mode)
% Build the Dynare reduced-path scaffold inputs and .mod template.

if nargin < 1 || isempty(max_k)
    max_k = 14;
end
if nargin < 2 || isempty(basis_count)
    basis_count = 4;
end
if nargin < 3 || isempty(demographic_source_mode)
    demographic_source_mode = 'historical_1950';
end

this_dir = fileparts(mfilename('fullpath'));
generated_dir = fullfile(this_dir, 'generated');

inputs = export_original_5yr_dynare_scaffold_inputs(max_k, basis_count, demographic_source_mode, ...
    '', '', '', generated_dir);
mod_path = build_original_5yr_dynare_reduced_path_scaffold( ...
    fullfile(generated_dir, 'nimby_dynare_scaffold_input.mat'), generated_dir);

setup = struct();
setup.generated_dir = generated_dir;
setup.input_mat_path = fullfile(generated_dir, 'nimby_dynare_scaffold_input.mat');
setup.manifest_json_path = fullfile(generated_dir, 'nimby_dynare_scaffold_manifest.json');
setup.seed_csv_path = fullfile(generated_dir, 'nimby_dynare_seed_price_path.csv');
setup.vote_csv_path = fullfile(generated_dir, 'nimby_dynare_vote_path.csv');
setup.basis_csv_path = fullfile(generated_dir, 'nimby_dynare_basis.csv');
setup.mod_path = mod_path;
setup.active_periods = inputs.active_periods(:)';
setup.max_k = inputs.max_k;
setup.basis_count = inputs.basis_count;
setup.seed_price_csv_path = inputs.seed_price_csv_path;

disp(setup);
end
