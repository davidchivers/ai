function [distance, a_price, rbPos, Hdemand, Hsupply, debtstock] = solve_ss_no_politics(x, supply_params)
% No-politics rational-expectations steady-state solver.
% Replaces the median-voter equilibrium condition in SolveSS_iter.m with
% a housing market clearing condition: Hdemand = Hsupply.
%
% In steady state the price is constant, so RE is trivially satisfied.
% The Bellman problem is now solved through solve_household_path_nimby.m,
% which is shared with the transition-path RE code.

if nargin < 2 || isempty(supply_params)
    supply_params = struct();
end
if ~isfield(supply_params, 'Hbar'),  supply_params.Hbar  = 5.0; end
if ~isfield(supply_params, 'Pbar'),  supply_params.Pbar  = 2.0; end
if ~isfield(supply_params, 'eta_s'), supply_params.eta_s = 1.0; end

a_price = x(1);
rbPos = x(2);
Hbar = supply_params.Hbar;
Pbar = supply_params.Pbar;
eta_s = supply_params.eta_s;

household_results = solve_household_path_nimby( ...
    a_price, ...
    struct(), ...
    struct('rbPos_path', rbPos, 'return_path_solution', false, 'return_tail_solution', true));
env = household_results.core_env;
cross_section = build_stationary_cross_section_nimby(household_results.tail_solution, env, true);

dens4 = cross_section.dens4;
totaldensity = cross_section.totaldensity;

aaaa = repmat(env.aa, 1, 1, env.K, env.age_n);
bbbb = repmat(env.bb, 1, 1, env.K, env.age_n);
zzzz = zeros(env.I, env.J, env.K, env.age_n);
for age_idx = 1:env.age_n
    zzzz(:, :, :, age_idx) = repmat(reshape(exp(env.z), 1, 1, env.K), env.I, env.J, 1) .* env.Zlifecycle(age_idx);
end

Hdemand = sum(aaaa .* dens4, 'all');
Hsupply = Hbar .* (a_price / Pbar) .^ eta_s;
distance = (Hdemand - Hsupply) ^ 2;
debtstock = sum(bbbb .* dens4, 'all');

save_payload = struct();
save_payload.a_price = a_price;
save_payload.rbPos = rbPos;
save_payload.Hdemand = Hdemand;
save_payload.Hsupply = Hsupply;
save_payload.distance = distance;
save_payload.debtstock = debtstock;
save_payload.dens4 = dens4;
save_payload.totaldensity = totaldensity;
save_payload.aaaa = aaaa;
save_payload.bbbb = bbbb;
save_payload.zzzz = zzzz;
save_payload.transition_matrix_path = household_results.transition_matrix_path;

for age_idx = 1:env.age_n
    age = env.ages(age_idx);
    save_payload.(sprintf('valuefunction_%d', age)) = household_results.tail_solution.value{age_idx};
    save_payload.(sprintf('index_a_%d', age)) = household_results.tail_solution.index_a{age_idx};
    save_payload.(sprintf('index_b_%d', age)) = household_results.tail_solution.index_b{age_idx};
end

save SS_no_politics_iter -struct save_payload;

disp(['House Price  = ', num2str(a_price)])
disp(['Hdemand = ', num2str(Hdemand), '  Hsupply = ', num2str(Hsupply)])
disp(['Rent Share = ', num2str(sum(dens4(:, 1, :, :), 'all'))])
disp(['Market clearing distance = ', num2str(distance)])
end
