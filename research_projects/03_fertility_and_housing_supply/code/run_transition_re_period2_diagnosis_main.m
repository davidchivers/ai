function run_transition_re_period2_diagnosis_main()
% run_transition_re_period2_diagnosis_main.m
%
% Diagnose why the period-2 Bellman RE root disappears between the first
% and second outer iterations in the short-horizon T=4 diagnostic.

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

iter_csv = fullfile(out_dir, 'structural_transition_re_t4_iter_iterations.csv');
period_csv = fullfile(out_dir, 'structural_transition_re_t4_iter_periods.csv');
vote_csv = fullfile(out_dir, 'structural_transition_re_t4_iter_vote_grid.csv');
if ~isfile(iter_csv) || ~isfile(period_csv) || ~isfile(vote_csv)
    error(['Missing t4_iter diagnostics. Run run_transition_re_fertility_main(''t4_iter'') ', ...
        'before running this diagnosis.']);
end

iter_rows = readtable(iter_csv);
period_rows = readtable(period_csv);
vote_rows = readtable(vote_csv);

cfg = fertility_benchmark_config();
overrides = struct('I', 8, 'J', 4);
options = struct( ...
    'rbPos_path', cfg.rbPos, ...
    'vote_dp_factor', 1.01, ...
    'vote_dp_scope', "remaining_path");

iter1 = iter_rows(iter_rows.iteration == 1, :);
iter2 = iter_rows(iter_rows.iteration == 2, :);
if isempty(iter1) || isempty(iter2)
    error('Expected both iteration 1 and iteration 2 rows in structural_transition_re_t4_iter_iterations.csv.');
end

guess_high = [iter1.q_guess_t1, iter1.q_guess_t2, iter1.q_guess_t3, iter1.q_guess_t4];
guess_low = [iter2.q_guess_t1, iter2.q_guess_t2, iter2.q_guess_t3, iter2.q_guess_t4];

q1_high = period_rows.implied_q(period_rows.iteration == 1 & period_rows.period == 1);
q1_low = period_rows.implied_q(period_rows.iteration == 2 & period_rows.period == 1);
if isempty(q1_high) || isempty(q1_low)
    error('Could not locate period-1 implied q in t4_iter periods file.');
end

pre2_high = build_period2_cross_section_local(guess_high, q1_high(1), overrides, cfg);
pre2_low = build_period2_cross_section_local(guess_low, q1_low(1), overrides, cfg);

period2_votes = vote_rows(vote_rows.period == 2, :);
q_grid = unique(period2_votes.q_candidate);
q_grid = sort(q_grid(:)');

combos = { ...
    struct('name', "high_pre_high_tail", 'label', "iter1 pre, iter1 tail", 'pre2', {pre2_high}, 'tail', guess_high(3:4)), ...
    struct('name', "high_pre_low_tail", 'label', "iter1 pre, iter2 tail", 'pre2', {pre2_high}, 'tail', guess_low(3:4)), ...
    struct('name', "low_pre_high_tail", 'label', "iter2 pre, iter1 tail", 'pre2', {pre2_low}, 'tail', guess_high(3:4)), ...
    struct('name', "low_pre_low_tail", 'label', "iter2 pre, iter2 tail", 'pre2', {pre2_low}, 'tail', guess_low(3:4))};

grid_rows = table();
summary_rows = table();
for i = 1:numel(combos)
    combo = combos{i};
    evals = evaluate_period_vote_grid_local(combo.pre2, combo.tail, overrides, options, q_grid);
    [sign_changes, first_lower_q, first_upper_q] = count_sign_changes_local(evals);
    [~, best_idx] = min(abs([evals.totalvote]));
    summary_row = struct2table(orderfields(struct( ...
        'case_name', combo.name, ...
        'label', combo.label, ...
        'sign_change_count', sign_changes, ...
        'closest_q', evals(best_idx).q, ...
        'closest_vote', evals(best_idx).totalvote, ...
        'first_lower_q', first_lower_q, ...
        'first_upper_q', first_upper_q)));
    summary_rows = [summary_rows; summary_row]; %#ok<AGROW>

    for j = 1:numel(evals)
        row = struct2table(orderfields(struct( ...
            'case_name', combo.name, ...
            'label', combo.label, ...
            'q_candidate', evals(j).q, ...
            'totalvote', evals(j).totalvote)));
        grid_rows = [grid_rows; row]; %#ok<AGROW>
    end
end

summary_path = fullfile(out_dir, 'structural_transition_re_period2_diagnosis_summary.csv');
grid_path = fullfile(out_dir, 'structural_transition_re_period2_diagnosis_votes.csv');
note_path = fullfile(out_dir, 'structural_transition_re_period2_diagnosis.md');
writetable(summary_rows, summary_path);
writetable(grid_rows, grid_path);
write_note_local(note_path, guess_high, guess_low, q1_high(1), q1_low(1), summary_rows);

disp('Structural transition RE period-2 diagnosis complete.');
end

function pre2 = build_period2_cross_section_local(q_guess, selected_q1, overrides, cfg)
stationary_seed = solve_household_path_fertility(q_guess(1), overrides, ...
    struct('rbPos_path', cfg.rbPos, 'verbose_progress', false));
stationary_sim = forward_distribution_path_fertility(stationary_seed, [], struct('store_cross_section', false));
initial_cross_section = stationary_sim.initial_cross_section;

selected_path = [selected_q1, q_guess(2:4)];
solver_results = solve_household_path_fertility(selected_path, overrides, ...
    struct('rbPos_path', cfg.rbPos, 'verbose_progress', false));
simulation = forward_distribution_path_fertility(solver_results, initial_cross_section, struct('store_cross_section', true));
pre2 = transpose(simulation.pre_policy_cross_section(2, :));
end

function evals = evaluate_period_vote_grid_local(current_pre_cross_section, tail_q, overrides, options, q_grid)
evals = struct('q', {}, 'totalvote', {});
for i = 1:numel(q_grid)
    q_path = [q_grid(i), tail_q];
    q_path_dp = build_dp_path_local(q_path, options);

    base_results = solve_household_path_fertility(q_path, overrides, ...
        struct('rbPos_path', options.rbPos_path, 'verbose_progress', false));
    dp_results = solve_household_path_fertility(q_path_dp, overrides, ...
        struct('rbPos_path', options.rbPos_path, 'verbose_progress', false));
    totalvote = compute_transition_vote_local(current_pre_cross_section, base_results, dp_results);

    evals(end + 1) = struct('q', q_grid(i), 'totalvote', totalvote); %#ok<AGROW>
end
end

function q_path_dp = build_dp_path_local(q_path, options)
q_path_dp = q_path;
switch lower(char(options.vote_dp_scope))
    case 'current_only'
        q_path_dp(1) = q_path_dp(1) * options.vote_dp_factor;
    case 'remaining_path'
        q_path_dp = q_path_dp * options.vote_dp_factor;
    otherwise
        error('Unknown vote_dp_scope "%s".', options.vote_dp_scope);
end
end

function totalvote = compute_transition_vote_local(current_pre_cross_section, base_results, dp_results)
env = base_results.core_env;
totalvote = 0.0;
for age_pos = 1:env.age_n
    density_pre = current_pre_cross_section{age_pos};
    if isempty(density_pre)
        continue;
    end
    density_post = apply_policy_transition_local(density_pre, base_results.path_solution, age_pos, env);
    d_value = dp_results.path_solution.value{1, age_pos} - base_results.path_solution.value{1, age_pos};
    totalvote = totalvote + sum(sign(d_value) .* density_post, 'all');
end
end

function density_raw = apply_policy_transition_local(density_prev, solution, age_pos, env)
policy_age = struct( ...
    'index_a', solution.index_a{1, age_pos}, ...
    'index_b', solution.index_b{1, age_pos}, ...
    'birth_prob', solution.birth_prob{1, age_pos}, ...
    'index_a_birth', solution.index_a_birth{1, age_pos}, ...
    'index_b_birth', solution.index_b_birth{1, age_pos});

density_raw = zeros(env.I, env.J, env.K, env.H, env.P);
leave_prob = env.leave_profile(age_pos);

for ih = 1:env.H
    home_count = env.home_grid(ih);
    ih_keep = ih;
    ih_decay = env.home_index(max(home_count - 1, 0));
    ih_birth_keep = env.home_index(min(home_count + 1, env.H - 1));
    ih_birth_decay = env.home_index(min(max(home_count - 1, 0) + 1, env.H - 1));

    for ip = 1:env.P
        ip_birth = env.parity_index(min(env.parity_grid(ip) + 1, env.P - 1));
        for iz = 1:env.K
            for ij = 1:env.J
                for ii = 1:env.I
                    mass = density_prev(ii, ij, iz, ih, ip);
                    if mass <= 0
                        continue;
                    end

                    prob = policy_age.birth_prob(ii, ij, iz, ih, ip);
                    nb = policy_age.index_b(ii, ij, iz, ih, ip);
                    na = policy_age.index_a(ii, ij, iz, ih, ip);
                    mass_nb = (1 - prob) * mass;
                    density_raw(nb, na, iz, ih_decay, ip) = density_raw(nb, na, iz, ih_decay, ip) + leave_prob * mass_nb;
                    density_raw(nb, na, iz, ih_keep, ip) = density_raw(nb, na, iz, ih_keep, ip) + (1 - leave_prob) * mass_nb;

                    if prob > 0
                        nb_b = policy_age.index_b_birth(ii, ij, iz, ih, ip);
                        na_b = policy_age.index_a_birth(ii, ij, iz, ih, ip);
                        mass_b = prob * mass;
                        density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_decay, ip_birth) + leave_prob * mass_b;
                        density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) = density_raw(nb_b, na_b, iz, ih_birth_keep, ip_birth) + (1 - leave_prob) * mass_b;
                    end
                end
            end
        end
    end
end
end

function [sign_changes, first_lower_q, first_upper_q] = count_sign_changes_local(evals)
votes = [evals.totalvote];
qs = [evals.q];
sign_changes = 0;
first_lower_q = NaN;
first_upper_q = NaN;

for i = 1:(numel(qs) - 1)
    if votes(i) == 0 || votes(i + 1) == 0
        continue;
    end
    if sign(votes(i)) ~= sign(votes(i + 1))
        sign_changes = sign_changes + 1;
        if isnan(first_lower_q)
            first_lower_q = qs(i);
            first_upper_q = qs(i + 1);
        end
    end
end
end

function write_note_local(path, guess_high, guess_low, q1_high, q1_low, summary_rows)
fid = fopen(path, 'w');
if fid == -1
    error('Could not write note: %s', path);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Structural transition RE period-2 diagnosis\n\n');
fprintf(fid, 'This note isolates why the period-2 Bellman RE root disappears between iteration 1 and iteration 2 of `run_transition_re_fertility_main(''t4_iter'')`.\n\n');

fprintf(fid, 'Reference paths:\n\n');
fprintf(fid, '- iteration-1 guess: `%s`\n', format_path_local(guess_high));
fprintf(fid, '- iteration-2 guess: `%s`\n', format_path_local(guess_low));
fprintf(fid, '- selected period-1 q under iteration 1: `%.6f`\n', q1_high);
fprintf(fid, '- selected period-1 q under iteration 2: `%.6f`\n\n', q1_low);

fprintf(fid, 'The table below evaluates the period-2 vote schedule under four combinations:\n\n');
fprintf(fid, '- iteration-1 incoming cross section vs iteration-2 incoming cross section\n');
fprintf(fid, '- iteration-1 future tail vs iteration-2 future tail\n\n');

fprintf(fid, '| case | sign changes | closest q | closest vote | first bracket |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | --- |\n');
for i = 1:height(summary_rows)
    if isnan(summary_rows.first_lower_q(i))
        bracket_label = 'none';
    else
        bracket_label = sprintf('[%.3f, %.3f]', summary_rows.first_lower_q(i), summary_rows.first_upper_q(i));
    end
    fprintf(fid, '| %s | %d | %.3f | %.6f | %s |\n', ...
        char(summary_rows.label(i)), summary_rows.sign_change_count(i), ...
        summary_rows.closest_q(i), summary_rows.closest_vote(i), bracket_label);
end

fprintf(fid, '\n## Read\n\n');
fprintf(fid, '- If `iter1 pre, iter2 tail` already loses the sign change, the main problem is the lower future tail rather than the changed incoming mass.\n');
fprintf(fid, '- If `iter2 pre, iter1 tail` still keeps a sign change, that reinforces the same conclusion.\n');
fprintf(fid, '- If both cross combinations lose the bracket, the outer map is likely too tail-sensitive for a naive damped fixed point.\n');
end

function out = format_path_local(path_values)
parts = strings(1, numel(path_values));
for i = 1:numel(path_values)
    parts(i) = sprintf('%.3f', path_values(i));
end
out = "[" + strjoin(parts, ", ") + "]";
end
