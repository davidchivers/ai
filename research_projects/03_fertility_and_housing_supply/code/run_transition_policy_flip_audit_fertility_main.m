function run_transition_policy_flip_audit_fertility_main()
% run_transition_policy_flip_audit_fertility_main.m
%
% Compare the age-25 renter policy map at t=1 under a flat path and a
% step-up path to identify exactly which states flip into ownership.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

this_code_dir = fullfile(project_root, 'code');
project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end

ensure_external_matlab_data_paths();

cfg = fertility_benchmark_config();
target_age = 25;
overrides = cfg.overrides;
overrides.I = 30;
overrides.J = 14;
overrides.return_transition_objects = true;

flat_q = [2.0, 2.0, 2.0, 2.0];
step_q = [2.0, 2.1, 2.1, 2.1];

[~, ~, ~, ~, ~, diagnostics] = SolveSS_fertility([cfg.eval_price, cfg.rbPos], overrides);
age_idx = find(diagnostics.ages == target_age, 1);
if isempty(age_idx)
    error('Target age %d not found in diagnostics age grid.', target_age);
end

policy_overrides = overrides;
policy_overrides = rmfield(policy_overrides, 'return_transition_objects');

flat_results = solve_household_path_fertility(flat_q, policy_overrides, struct('rbPos_path', cfg.rbPos));
step_results = solve_household_path_fertility(step_q, policy_overrides, struct('rbPos_path', cfg.rbPos));

state_rows = build_state_rows(diagnostics, flat_results, step_results, age_idx);
summary_table = build_summary_table(state_rows, target_age, overrides.I, overrides.J);
z_summary = build_z_summary(state_rows);

writetable(state_rows, fullfile(out_dir, 'structural_transition_policy_flip_audit_states.csv'));
writetable(summary_table, fullfile(out_dir, 'structural_transition_policy_flip_audit_summary.csv'));
writetable(z_summary, fullfile(out_dir, 'structural_transition_policy_flip_audit_z_summary.csv'));
write_note(fullfile(out_dir, 'structural_transition_policy_flip_audit.md'), summary_table, z_summary, state_rows, target_age, overrides.I, overrides.J, flat_q, step_q);

disp('Structural transition policy-flip audit complete.');
end

function state_rows = build_state_rows(diagnostics, flat_results, step_results, age_idx)
pre_density = diagnostics.density_pre_policy_ages{age_idx};
flat_policy = get_policy_block(flat_results.path_solution, 1, age_idx);
step_policy = get_policy_block(step_results.path_solution, 1, age_idx);

state_rows = table();
renter_j = 1;
for ip = 1:numel(diagnostics.parity_grid)
    for ih = 1:numel(diagnostics.home_grid)
        for iz = 1:numel(diagnostics.z_grid)
            current_income = exp(diagnostics.z_grid(iz)) * diagnostics.z_lifecycle(age_idx);
            for ii = 1:numel(diagnostics.b_grid)
                current_mass = pre_density(ii, renter_j, iz, ih, ip);
                if current_mass <= 0
                    continue;
                end

                flat_a_idx = flat_policy.index_a(ii, renter_j, iz, ih, ip);
                flat_b_idx = flat_policy.index_b(ii, renter_j, iz, ih, ip);
                step_a_idx = step_policy.index_a(ii, renter_j, iz, ih, ip);
                step_b_idx = step_policy.index_b(ii, renter_j, iz, ih, ip);

                flat_owner = double(flat_a_idx > 1);
                step_owner = double(step_a_idx > 1);

                row = struct2table(orderfields(struct( ...
                    'z_index', iz, ...
                    'z_value', diagnostics.z_grid(iz), ...
                    'current_income', current_income, ...
                    'current_b', diagnostics.b_grid(ii), ...
                    'current_home_count', diagnostics.home_grid(ih), ...
                    'current_parity', diagnostics.parity_grid(ip), ...
                    'current_mass', current_mass, ...
                    'flat_birth_prob', flat_policy.birth_prob(ii, renter_j, iz, ih, ip), ...
                    'step_birth_prob', step_policy.birth_prob(ii, renter_j, iz, ih, ip), ...
                    'flat_owner', flat_owner, ...
                    'flat_a', diagnostics.a_grid(flat_a_idx), ...
                    'flat_b', diagnostics.b_grid(flat_b_idx), ...
                    'step_owner', step_owner, ...
                    'step_a', diagnostics.a_grid(step_a_idx), ...
                    'step_b', diagnostics.b_grid(step_b_idx), ...
                    'flip_renter_to_owner', double(flat_owner == 0 && step_owner == 1), ...
                    'flip_owner_to_renter', double(flat_owner == 1 && step_owner == 0), ...
                    'stay_owner', double(flat_owner == 1 && step_owner == 1), ...
                    'stay_renter', double(flat_owner == 0 && step_owner == 0))));
                state_rows = [state_rows; row]; %#ok<AGROW>
            end
        end
    end
end
end

function summary_table = build_summary_table(state_rows, target_age, I, J)
total_mass = sum(state_rows.current_mass);
summary_table = struct2table(orderfields(struct( ...
    'age', target_age, ...
    'I', I, ...
    'J', J, ...
    'total_mass', total_mass, ...
    'flat_owner_mass_share', sum(state_rows.current_mass .* state_rows.flat_owner) / max(total_mass, 1e-12), ...
    'step_owner_mass_share', sum(state_rows.current_mass .* state_rows.step_owner) / max(total_mass, 1e-12), ...
    'flip_renter_to_owner_mass_share', sum(state_rows.current_mass .* state_rows.flip_renter_to_owner) / max(total_mass, 1e-12), ...
    'flip_owner_to_renter_mass_share', sum(state_rows.current_mass .* state_rows.flip_owner_to_renter) / max(total_mass, 1e-12), ...
    'stay_owner_mass_share', sum(state_rows.current_mass .* state_rows.stay_owner) / max(total_mass, 1e-12), ...
    'stay_renter_mass_share', sum(state_rows.current_mass .* state_rows.stay_renter) / max(total_mass, 1e-12), ...
    'flip_renter_to_owner_mean_income', weighted_mean(state_rows.current_income, state_rows.current_mass .* state_rows.flip_renter_to_owner), ...
    'flip_renter_to_owner_mean_b', weighted_mean(state_rows.current_b, state_rows.current_mass .* state_rows.flip_renter_to_owner), ...
    'step_owner_mean_a_among_flips', weighted_mean(state_rows.step_a, state_rows.current_mass .* state_rows.flip_renter_to_owner), ...
    'step_owner_mean_b_among_flips', weighted_mean(state_rows.step_b, state_rows.current_mass .* state_rows.flip_renter_to_owner))));
end

function z_summary = build_z_summary(state_rows)
z_vals = unique(state_rows.z_index);
z_summary = table();
total_mass = sum(state_rows.current_mass);
for i = 1:numel(z_vals)
    mask = state_rows.z_index == z_vals(i);
    row_mass = sum(state_rows.current_mass(mask));
    row = struct2table(orderfields(struct( ...
        'z_index', z_vals(i), ...
        'z_value', state_rows.z_value(find(mask, 1)), ...
        'mass_share', row_mass / max(total_mass, 1e-12), ...
        'flat_owner_mass_share', sum(state_rows.current_mass(mask) .* state_rows.flat_owner(mask)) / max(total_mass, 1e-12), ...
        'step_owner_mass_share', sum(state_rows.current_mass(mask) .* state_rows.step_owner(mask)) / max(total_mass, 1e-12), ...
        'flip_renter_to_owner_mass_share', sum(state_rows.current_mass(mask) .* state_rows.flip_renter_to_owner(mask)) / max(total_mass, 1e-12), ...
        'flip_owner_to_renter_mass_share', sum(state_rows.current_mass(mask) .* state_rows.flip_owner_to_renter(mask)) / max(total_mass, 1e-12))));
    z_summary = [z_summary; row]; %#ok<AGROW>
end
end

function out = weighted_mean(values, weights)
weights = weights(:);
values = values(:);
total_weight = sum(weights);
if total_weight <= 0
    out = NaN;
    return;
end
out = sum(values .* weights) / total_weight;
end

function policy_age = get_policy_block(solution, t, age_pos)
policy_age = struct( ...
    'index_a', solution.index_a{t, age_pos}, ...
    'index_b', solution.index_b{t, age_pos}, ...
    'birth_prob', solution.birth_prob{t, age_pos});
end

function write_note(path, summary_table, z_summary, state_rows, target_age, I, J, flat_q, step_q)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural transition policy-flip audit\n\n');
fprintf(fid, 'This note compares the age-%d renter policy map at `t = 1` under a flat path and a step-up path.\n\n', target_age);
fprintf(fid, 'Setup:\n\n');
fprintf(fid, '- grid: `I = %d`, `J = %d`\n', I, J);
fprintf(fid, '- flat path: `[%s]`\n', join(string(compose('%.1f', flat_q)), ', '));
fprintf(fid, '- step-up path: `[%s]`\n\n', join(string(compose('%.1f', step_q)), ', '));

fprintf(fid, '## Summary\n\n');
fprintf(fid, '- flat owner mass share at age `%d`: `%.3f`\n', target_age, summary_table.flat_owner_mass_share);
fprintf(fid, '- step owner mass share at age `%d`: `%.3f`\n', target_age, summary_table.step_owner_mass_share);
fprintf(fid, '- renter-to-owner flip mass share: `%.3f`\n', summary_table.flip_renter_to_owner_mass_share);
fprintf(fid, '- owner-to-renter flip mass share: `%.3f`\n', summary_table.flip_owner_to_renter_mass_share);
fprintf(fid, '- stay-owner mass share: `%.3f`\n', summary_table.stay_owner_mass_share);
fprintf(fid, '- stay-renter mass share: `%.3f`\n', summary_table.stay_renter_mass_share);
fprintf(fid, '- mean income among renter-to-owner flips: `%.3f`\n', summary_table.flip_renter_to_owner_mean_income);
fprintf(fid, '- mean liquid wealth among renter-to-owner flips: `%.3f`\n', summary_table.flip_renter_to_owner_mean_b);
fprintf(fid, '- mean chosen owner housing among flips: `%.3f`\n', summary_table.step_owner_mean_a_among_flips);
fprintf(fid, '- mean chosen owner liquid asset among flips: `%.3f`\n\n', summary_table.step_owner_mean_b_among_flips);

fprintf(fid, '## Flip mass by income state\n\n');
fprintf(fid, '| z index | z value | mass share | flat owner share | step owner share | renter-to-owner flip share | owner-to-renter flip share |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(z_summary)
    fprintf(fid, '| %d | %.4f | %.3f | %.3f | %.3f | %.3f | %.3f |\n', ...
        z_summary.z_index(i), z_summary.z_value(i), z_summary.mass_share(i), ...
        z_summary.flat_owner_mass_share(i), z_summary.step_owner_mass_share(i), ...
        z_summary.flip_renter_to_owner_mass_share(i), z_summary.flip_owner_to_renter_mass_share(i));
end

fprintf(fid, '\n## State map\n\n');
fprintf(fid, '| z index | income | current b | mass | flat owner? | flat a'' | flat b'' | step owner? | step a'' | step b'' | renter->owner? |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(state_rows)
    fprintf(fid, '| %d | %.3f | %.3f | %.6f | %d | %.3f | %.3f | %d | %.3f | %.3f | %d |\n', ...
        state_rows.z_index(i), state_rows.current_income(i), state_rows.current_b(i), state_rows.current_mass(i), ...
        state_rows.flat_owner(i), state_rows.flat_a(i), state_rows.flat_b(i), ...
        state_rows.step_owner(i), state_rows.step_a(i), state_rows.step_b(i), state_rows.flip_renter_to_owner(i));
end

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- This audit is designed to answer a single question: is the `t = 1` ownership surge broad-based, or does it come from a small set of marginal entrant states?\n');
fprintf(fid, '- The answer from this run is encoded in the renter-to-owner flip mass share and the `z` decomposition above.\n');
fprintf(fid, '- If the flip mass is concentrated in one or two high-income `z` states, then the remaining PE issue is a marginal-state amplification problem.\n');
fprintf(fid, '- If the flip mass is broad-based, then anticipated higher future `q` is making ownership too attractive for a wide entrant region even after the feasibility fix.\n');
end
