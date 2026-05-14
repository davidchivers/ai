function pack = export_steady_state_input_pack(output_dir, price_level, rb_pos, project_root, steady_state_mode)
% Export a steady-state reference pack plus MATLAB truth.

if nargin < 1 || isempty(output_dir)
    this_dir = fileparts(mfilename('fullpath'));
    output_dir = fullfile(fileparts(this_dir), 'truth', 'steady_state_p2_rb0_03');
end
if nargin < 2 || isempty(price_level)
    price_level = 2.0;
end
if nargin < 3 || isempty(rb_pos)
    rb_pos = 0.03;
end
if nargin < 4 || isempty(project_root)
    this_dir = fileparts(mfilename('fullpath'));
    sidecar_dir = fileparts(this_dir);
    extension_dir = fileparts(sidecar_dir);
    project_root = fileparts(fileparts(extension_dir));
end
if nargin < 5 || isempty(steady_state_mode)
    steady_state_mode = 're_no_politics';
end

this_dir = fileparts(mfilename('fullpath'));
sidecar_dir = fileparts(this_dir);
extension_dir = fileparts(sidecar_dir);
baseline_dir = fullfile(project_root, 'code', 'steadystate');

addpath(extension_dir);
addpath(baseline_dir);

[transitionmatrix, z, Zlifecycle, initialdist] = load_transition_matrix_data();
model = setup_model_objects_local(z, Zlifecycle, rb_pos);
supply_params = struct('eta_s', 1.0);

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

reference = load_ss_reference_local( ...
    price_level, rb_pos, supply_params, steady_state_mode, output_dir, ...
    transitionmatrix, z, Zlifecycle, initialdist);
supply_params = normalize_supply_params_local(supply_params, price_level, reference.Hdemand);
if strcmpi(steady_state_mode, 're_no_politics')
    reference = load_ss_reference_local( ...
        price_level, rb_pos, supply_params, steady_state_mode, output_dir, ...
        transitionmatrix, z, Zlifecycle, initialdist);
end
Hsupply = supply_params.Hbar * (price_level / supply_params.Pbar) ^ supply_params.eta_s;
debtstock = compute_debt_from_density_local(reference.dens4, model.b);

write_named_scalars(fullfile(output_dir, 'meta_scalars.csv'), {
    'age_n', model.age_n;
    'I', model.I;
    'J', model.J;
    'K', model.K;
    'bzero', model.bzero - 1;
    'a_price', price_level;
    'rb_pos', model.rbPos;
    'rb_neg', model.rbNeg;
    'ra', model.ra;
    'r_price', model.r_price;
    'omega', model.omega;
    'theta_r', model.theta_r;
    'beta', model.beta;
    'eta', model.eta;
    'ka', model.ka;
    'bequestweight1', model.bequestweight1;
    'bequestweight2', model.bequestweight2;
    'CC', model.CC;
    'penalty', model.penalty;
    'supply_Hbar', supply_params.Hbar;
    'supply_Pbar', supply_params.Pbar;
    'supply_eta_s', supply_params.eta_s});
write_named_strings(fullfile(output_dir, 'meta_strings.csv'), {
    'steady_state_mode', char(string(steady_state_mode))});

writematrix(model.a(:), fullfile(output_dir, 'a.csv'));
writematrix(model.b(:), fullfile(output_dir, 'b.csv'));
writematrix(model.z(:), fullfile(output_dir, 'z.csv'));
writematrix(model.Zlifecycle(:), fullfile(output_dir, 'Zlifecycle.csv'));
writematrix(initialdist(:), fullfile(output_dir, 'initialdist.csv'));
writematrix(transitionmatrix(:), fullfile(output_dir, 'transitionmatrix.csv'));
writematrix(pack_age_cell(reference.age_policy_idx_b), fullfile(output_dir, 'matlab_age_policy_idx_b.csv'));
writematrix(pack_age_cell(reference.age_policy_idx_a), fullfile(output_dir, 'matlab_age_policy_idx_a.csv'));
writematrix(pack_age_cell(reference.age_valuefunctions), fullfile(output_dir, 'matlab_age_valuefunctions.csv'));
writematrix(reference.dens4(:), fullfile(output_dir, 'matlab_dens4.csv'));
if isfield(reference, 'age_valuefunctions_dp')
    writematrix(pack_age_cell(reference.age_valuefunctions_dp), fullfile(output_dir, 'matlab_age_valuefunctions_dp.csv'));
end
if isfield(reference, 'preference_sign')
    writematrix(reference.preference_sign(:), fullfile(output_dir, 'matlab_age_preference_sign.csv'));
end
write_named_scalars(fullfile(output_dir, 'matlab_summary.csv'), {
    'Hdemand', reference.Hdemand;
    'Hsupply', Hsupply;
    'debtstock', debtstock});
if isfield(reference, 'totalvote')
    write_named_scalars(fullfile(output_dir, 'matlab_political_summary.csv'), {
        'totalvote', reference.totalvote;
        'distance', reference.distance;
        'debtstock', reference.debtstock;
        'Hdemand', reference.Hdemand;
        'Hsupply', Hsupply});
end

pack = struct();
pack.output_dir = output_dir;
pack.reference = reference;
pack.price_level = price_level;
pack.rb_pos = rb_pos;
pack.supply_params = supply_params;
pack.steady_state_mode = steady_state_mode;
end

function model = setup_model_objects_local(z, Zlifecycle, rbPos)
model.agemin = 25;
model.agemax = 90;
model.dage = 5;
model.ageline = model.agemin:model.dage:model.agemax;
model.age_n = numel(model.ageline);

model.rspread = 0.02;
model.rbPos = rbPos;
model.rbNeg = rbPos + model.rspread;
model.ra = -0.03;
model.r_price = model.rbNeg - model.ra + 0.02;

model.omega = 0.5;
model.theta_r = 0.9;
model.beta = 0.8;
model.eta = 2;
model.ka = 0.07;
model.bequestweight1 = 0.9 * model.beta;
model.bequestweight2 = 0.9 * model.beta;
model.CC = 0.9;
model.penalty = 1e6;

model.z = z(:)';
model.K = numel(model.z);
model.Zlifecycle = Zlifecycle(:)';

model.J = 20;
model.a = linspace(0, 25, model.J);
model.I = 50;
model.b = linspace(-15, 15, model.I);

model.bzero = find(model.b >= 0, 1, 'first');
if isempty(model.bzero)
    [~, model.bzero] = min(abs(model.b));
end
end

function reference = load_ss_reference_local( ...
    price, rbPos, supply_params, steady_state_mode, output_dir, ...
    transitionmatrix, z, Zlifecycle, initialdist)
mode = char(string(steady_state_mode));
if strcmpi(mode, 'original_solve_ss_iter')
    reference = load_original_ss_reference_local(price, rbPos, output_dir, transitionmatrix, z, Zlifecycle, initialdist);
    return
end

solve_ss_no_politics([price, rbPos], supply_params); %#ok<NASGU>
ss = load('SS_no_politics_iter.mat');

reference = struct();
reference.dens4 = ss.dens4;
reference.Hdemand = compute_housing_demand_from_density_local(ss.dens4);
reference.age_valuefunctions = cell(1, size(ss.dens4, 4));
reference.age_policy_idx_a = cell(1, size(ss.dens4, 4));
reference.age_policy_idx_b = cell(1, size(ss.dens4, 4));
for age_idx = 1:size(ss.dens4, 4)
    age = 25 + 5 * (age_idx - 1);
    reference.age_valuefunctions{age_idx} = ss.(sprintf('valuefunction_%d', age));
    reference.age_policy_idx_a{age_idx} = ss.(sprintf('index_a_%d', age));
    reference.age_policy_idx_b{age_idx} = ss.(sprintf('index_b_%d', age));
end
end

function reference = load_original_ss_reference_local(price, rbPos, output_dir, transitionmatrix, z, Zlifecycle, initialdist)
old_dir = pwd;
cleanup_dir = onCleanup(@() cd(old_dir));
cd(output_dir);

y_mid = z;
z_lifecycle = Zlifecycle;
save('TransitionMatrix.mat', 'transitionmatrix', 'y_mid', 'z_lifecycle', 'initialdist');
options = struct();
options.save_ss_iter = false;
[~, ~, ~, ~, ~, ss] = solve_original_5yr_political_steady_state([price, rbPos], options);

reference = struct();
reference.dens4 = ss.dens4;
reference.Hdemand = compute_housing_demand_from_density_local(ss.dens4);
reference.debtstock = ss.debtstock;
reference.distance = ss.distance;
reference.totalvote = ss.totalvote;
reference.preference_sign = ss.pref4;
reference.age_valuefunctions = ss.age_valuefunctions;
reference.age_valuefunctions_dp = ss.age_valuefunctions_dp;
reference.age_policy_idx_a = ss.age_policy_idx_a;
reference.age_policy_idx_b = ss.age_policy_idx_b;
end

function supply_params = normalize_supply_params_local(supply_params, reference_price, reference_Hdemand)
if ~isfield(supply_params, 'Pbar') || isempty(supply_params.Pbar)
    supply_params.Pbar = reference_price;
end
if ~isfield(supply_params, 'Hbar') || isempty(supply_params.Hbar)
    supply_params.Hbar = max(reference_Hdemand, 1e-8);
end
if ~isfield(supply_params, 'eta_s') || isempty(supply_params.eta_s)
    supply_params.eta_s = 1.0;
end
end

function Hdemand = compute_housing_demand_from_density_local(dens4)
a = linspace(0, 25, size(dens4, 2));
aa = ones(size(dens4, 1), 1) * a;
aaaa = repmat(aa, 1, 1, size(dens4, 3), size(dens4, 4));
Hdemand = sum(aaaa .* dens4, 'all');
end

function debtstock = compute_debt_from_density_local(dens4, b)
bb = b(:) * ones(1, size(dens4, 2));
bbbb = repmat(bb, 1, 1, size(dens4, 3), size(dens4, 4));
debtstock = sum(bbbb .* dens4, 'all');
end

function packed = pack_age_cell(age_cell)
age_n = numel(age_cell);
[I, J, K] = size(age_cell{1});
packed_array = zeros(I, J, K, age_n);
for age_idx = 1:age_n
    packed_array(:, :, :, age_idx) = age_cell{age_idx};
end
packed = packed_array(:);
end

function write_named_scalars(path, rows)
writetable(cell2table(rows, 'VariableNames', {'name', 'value'}), path);
end

function write_named_strings(path, rows)
writetable(cell2table(rows, 'VariableNames', {'name', 'value'}), path);
end
